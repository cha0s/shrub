
i8n = require 'jugglingdb/node_modules/inflection'
nconf = require 'nconf'
url = require 'url'

exports.$config = (req) ->
	
	apiRoot: nconf.get 'apiRoot'

exports.$httpMiddleware = (http) ->
	
	schema = require 'server/jugglingdb'
	
	# DRY.
	interceptError = (res, fn) ->
		(error, result) ->
			if error?
				serveJson res, error.code ? 500, message: error.message
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
			
			collectionPath = "#{schema.settings.apiRoot}/#{collection}"
			
			app.get collectionPath, (req, res) ->
				Model.authenticatedAll(
					req.user
					if Object.keys(req.query).length
						req.query
					else
						null
					interceptError res, (models) ->
						if models.length
							serveJson res, 200, models
						else
							serveJson res, 404, message: "Collection not found."
				)
				
			app.get "#{collectionPath}/count", (req, res) ->
				Model.authenticatedCount req.user, interceptError res, (count) ->
					serveJson res, 200, count: count
			
			app.post collectionPath, (req, res) ->
				Model.authenticatedCreate req.user, req.body, interceptError res, (model) ->
					serveJson res, 201, model

			app.delete collectionPath, (req, res) ->
				Model.authenticatedDestroyAll req.user, interceptError res, ->
					serveJson res, 200, message: "Collection deleted."
			
			resourcePath = "#{schema.settings.apiRoot}/#{resource}/:id"
			
			app.get resourcePath, (req, res) ->
				Model.authenticatedFind req.user, req.params.id, interceptError res, (model) ->
					if model? and model.isAccessibleBy req.user
						serveJson res, 200, model
					else
						serveJson res, 404, message: "Resource not found."
	
			app.put resourcePath, (req, res) ->
				Model.authenticatedUpdate req.params.id, req.body, interceptError res, (model) ->
					serveJson res, 200, message: "Resource updated."
							
			app.delete resourcePath, (req, res) ->
				Model.authenticatedDestroy req.user, req.params.idinterceptError res, (model) ->
					serveJson res, 200, message: "Resource deleted."
				
	label: 'Serve schema API'
	middleware: [

		app.router
		
	]
