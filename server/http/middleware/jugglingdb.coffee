
i8n = require 'jugglingdb/node_modules/inflection'
schema = require 'server/jugglingdb' 
url = require 'url'

exports.middleware = (http) ->
	
	# DRY.
	interceptErrors = (res, fn) ->
		(error, result) ->
			if error?
				serveJson res, error.code ? 500, message: error.toString()
			else
				fn result
	
	serveJson = (res, code, data) ->
		
		# http://en.wikipedia.org/wiki/Cross-origin_resource_sharing
		res.set
			'Access-Control-Allow-Origin': '*'
			'Access-Control-Allow-Headers': 'X-Requested-With'
			
		res.json code, data
	
	app = http._app # Yeah, this is hackish. NFG
	root = schema.root
	routes = {}
	
	for name, Model of schema.models
		
		do (Model) ->
		
			{resource, collection} = schema.resourcePaths name
			
			collectionPath = "#{root}/#{collection}"
			
			get = (req, res, type) ->
				params = if Object.keys(req.query).length
					req.query
				else
					null
				Model.access "get #{type} #{collection}", req.user, params, interceptErrors res, (models) ->
					if models.length
						serveJson res, 200, models
					else
						serveJson res, 404, message: "Collection not found."
			
			app.get collectionPath, (req, res) -> get req, res, 'all'
			
			app.get "#{collectionPath}/own", (req, res) -> get req, res, 'own'
			
			app.get "#{collectionPath}/count", (req, res) ->
				Model.access "count #{collection}", req.user, interceptErrors res, (count) ->
					serveJson res, 200, count: count
			
			app.post collectionPath, (req, res) ->
				Model.access "create a #{resource}", req.user, req.body, interceptErrors res, (model) ->
					serveJson res, 201, model

			app.delete collectionPath, (req, res) ->
				Model.access "delete all #{collection}", req.user, interceptErrors res, ->
					serveJson res, 200, message: "Collection deleted."
			
			resourcePath = "#{root}/#{resource}/:id"
			
			app.get resourcePath, (req, res) ->
				Model.access "get a #{resource}", req.user, req.params.id, interceptErrors res, (model) ->
					if model?
						serveJson res, 200, model
					else
						serveJson res, 404, message: "Resource not found."
	
			app.put resourcePath, (req, res) ->
				Model.access "update a #{resource}", req.user, req.params.id, req.body, interceptErrors res, (model) ->
					serveJson res, 200, message: "Resource updated."
							
			app.delete resourcePath, (req, res) ->
				Model.access "delete a #{resource}", req.user, req.params.id, interceptErrors res, (result) ->
					serveJson res, 200, message: "Resource deleted."
	
			app.get "#{resourcePath}/exists", (req, res) ->
				Model.access "check a #{resource}'s existence", req.user, req.params.id, interceptErrors res, (exists) ->
					if exists
						serveJson res, 200, message: "Resource exists."
					else
						serveJson res, 404, message: "Resource not found."
	
	app.router
