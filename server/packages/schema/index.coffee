
nconf = require 'nconf'

exports.$config = (req) ->
	
	apiRoot: nconf.get 'apiRoot'

exports.$httpInitializer = -> (req, res, next) ->
	
	schema = require 'server/jugglingdb'
	
	# DRY.
	interceptError = (res) ->
		(error) -> serveJson res, error.code ? 500, message: error.message
	
	serveJson = (res, code, data) ->
		
		# http://en.wikipedia.org/wiki/Cross-origin_resource_sharing
		res.set
			'Access-Control-Allow-Origin': '*'
			'Access-Control-Allow-Headers': 'X-Requested-With'
			
		res.json code, data
	
	app = req.http._app # Yeah, this is hackish. NFG
	routes = {}
	
	# Gross...
	app._usedRouter = true
	
	for name, Model of schema.models
		
		do (Model) ->
			
			{resource, collection} = schema.resourcePaths name
			
			collectionPath = "#{schema.settings.apiRoot}/#{collection}"
			
			keyify = (key, value) ->
				O = {}
				O[key] = value
				O
			
			app.get collectionPath, (req, res) ->
				
				Model.authenticatedAll(
					req.user
					if Object.keys(req.query).length
						req.query
					else
						null
				
				).then(
					(models) -> serveJson res, 200, keyify collection, models
					interceptError res
				).done()
				
			app.get "#{collectionPath}/count", (req, res) ->
				
				Model.authenticatedCount(
					req.user

				).then(
					(count) -> serveJson res, 200, keyify 'count', count
					interceptError res
				).done()
			
			app.post collectionPath, (req, res) ->

				Model.authenticatedCreate(
					req.user
					req.body

				).then(
					(model) -> serveJson res, 201, keyify resource, model
					interceptError res
				).done()

			app.delete collectionPath, (req, res) ->
				
				Model.authenticatedDestroyAll(
					req.user
				
				).then(
					-> serveJson res, 200, message: "Collection deleted."
					interceptError res
				).done()
			
			resourcePath = "#{schema.settings.apiRoot}/#{resource}/:id"
			
			app.get resourcePath, (req, res) ->
				
				Model.authenticatedFind(
					req.user
					req.params.id
				
				).then(
					(model) -> serveJson res, 200, keyify resource, model
					interceptError res
				).done()
	
			app.put resourcePath, (req, res) ->
				
				Model.authenticatedUpdate(
					req.user
					req.params.id
					req.body
				).then(
					-> serveJson res, 200, message: "Resource updated."
					interceptError res
				).done()
							
			app.delete resourcePath, (req, res) ->
				
				Model.authenticatedDestroy(
					req.user
					req.params.id
				).then(
					-> serveJson res, 200, message: "Resource deleted."
					interceptError res
				).done()

	next()
	
exports.$replContext = (context) -> context.schema = require 'server/jugglingdb'
