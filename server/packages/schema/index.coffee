
i8n = require 'jugglingdb/node_modules/inflection'
nconf = require 'nconf'
url = require 'url'

exports.$config = (req) ->
	
	apiRoot: nconf.get 'apiRoot'

exports.$httpMiddleware = (http) ->
	
	schema = require 'server/jugglingdb'
	
	# DRY.
	interceptErrors = (res, fn) ->
		(error, result) ->
			if error?
				serveJson res, error.code ? 500, message: error.toString()
			else
				fn result
	
	checkPermission = (req, res, perm, fn) ->
		
		if req.user.hasPermission perm
			fn()
		else
			serveJson res, 403, message: 'Access denied.'
		
	serveJson = (res, code, data) ->
		
		# http://en.wikipedia.org/wiki/Cross-origin_resource_sharing
		res.set
			'Access-Control-Allow-Origin': '*'
			'Access-Control-Allow-Headers': 'X-Requested-With'
			
		res.json code, data
	
	app = http._app # Yeah, this is hackish. NFG
	routes = {}
	
	# Gross...
	app._usedRouter = true
	
	for name, Model of schema.models
		
		do (Model) ->
			
			{resource, collection} = schema.resourcePaths name
			
			get = (req, res, type) ->
				params = if Object.keys(req.query).length
					req.query
				else
					null
				
				if type is 'own'
					key = if resource is 'user' then 'id' else 'userId'
					(params.where ?= {})[key] = req.user.id
							
				checkPermission req, res, "schema:#{name}:#{type}", ->
					Model[type] params, interceptErrors res, (models) ->
						
						models = models.filter (model) ->
							model.isAccessibleBy req.user
						
						if models.length
							serveJson res, 200, models.map (model) ->
								model.redactFor req.user
						else
							serveJson res, 404, message: "Collection not found."
			
			collectionPath = "#{schema.settings.apiRoot}/#{collection}"
			
			app.get collectionPath, (req, res) -> get req, res, 'all'
				
			app.get "#{collectionPath}/own", (req, res) -> get req, res, 'own'
				
			app.get "#{collectionPath}/count", (req, res) ->
				checkPermission req, res, "schema:#{name}:count", ->
					Model.count interceptErrors res, (count) ->
						serveJson res, 200, count: count
			
			app.post collectionPath, (req, res) ->
				checkPermission req, res, "schema:#{name}:create", ->
					Model.create req.body, interceptErrors res, (model) ->
						serveJson res, 201, model

			app.delete collectionPath, (req, res) ->
				checkPermission req, res, "schema:#{name}:destroyAll", ->
					Model.destroyAll interceptErrors res, ->
						serveJson res, 200, message: "Collection deleted."
			
			resourcePath = "#{schema.settings.apiRoot}/#{resource}/:id"
			
			app.get resourcePath, (req, res) ->
				Model.find req.params.id, interceptErrors res, (model) ->
					if model? and model.isAccessibleBy req.user
						serveJson res, 200, model.redactFor req.user
					else
						serveJson res, 404, message: "Resource not found."
	
			app.put resourcePath, (req, res) ->
				Model.find req.params.id, interceptErrors res, (model) ->
					if model.isEditableBy req.user
						model.updateAttributes req.body, interceptErrors res, (model) ->
							serveJson res, 200, message: "Resource updated."
					else
						if model.isAccessibleBy req.user
							serveJson res, 403, message: 'Access denied.'
						else
							serveJson res, 404, message: 'Resource not found.'
							
			app.delete resourcePath, (req, res) ->
				Model.find req.params.id, interceptErrors res, (model) ->
					if model.isDeletableBy req.user
						schema.adapter.destroy name, req.params.id, interceptErrors res, (result) ->
							serveJson res, 200, message: "Resource deleted."
					else
						if model.isAccessibleBy req.user
							serveJson res, 403, message: 'Access denied.'
						else
							serveJson res, 404, message: 'Resource not found.'
				
	label: 'Serve schema API'
	middleware: [

		app.router
		
	]
