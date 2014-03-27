
# # Database schema
# 
# Tools for working with the database schema.

nconf = require 'nconf'

schema = require 'server/jugglingdb'

# ## Implements hook `config`
exports.$config = (req) ->
	
	apiRoot: nconf.get 'apiRoot'

# ## Implements hook `httpInitializing`
# 
# Serve the database schema as an authenticated REST API.
exports.$httpInitializing = ({_app}) ->
	
	# } DRY.
	interceptError = (res) ->
		(error) -> serveJson res, error.code ? 500, message: error.message
	
	# } DRY,
	serveJson = (res, code, data) ->
		
		# CORS policy enforcement.
		corsHeaders = nconf.get 'packageSettings:schema:corsHeaders'
		res.set corsHeaders if corsHeaders?
			
		res.json code, data
	
	# Gross...
	app = _app
	app._usedRouter = true
	
	# Serve the models. For each model, we'll define REST paths to allow
	# interaction with a model, or set of models.
	for name, Model of schema.models
		
		do (Model) ->
			
			# `TODO`: Generalize and serve "broken" JSON for Angular.
			# See: [Angular JSON vulnerability protection](http://docs.angularjs.org/api/ng/service/$http#json-vulnerability-protection).
			keyify = (key, value) ->
				O = {}
				O[key] = value
				O
			
			{resource, collection} = schema.resourcePaths name
			
			# Supposing we're handling the `User` model, and apiRoot is its
			# default (`/api`), the values will be:
			# 
			# 	collectionPath = "/api/users"
			# 	resourcePath = "/api/user/:id"
			# 
			# We'll assume these defaults for each path's explanation.
			collectionPath = "#{schema.settings.apiRoot}/#{collection}"
			resourcePath = "#{schema.settings.apiRoot}/#{resource}/:id"
			
			# Get the entire collection.
			# GET `/api/users`
			app.get collectionPath, (req, res) ->
				
				query = if Object.keys(req.query).length then req.query
				Model.authenticatedAll(
					req.user, query

				).then(
					(models) -> serveJson res, 200, keyify collection, models
					interceptError res
				).done()
				
			# Get how many resources are in the collection.
			# GET `/api/users/count`
			app.get "#{collectionPath}/count", (req, res) ->
				
				Model.authenticatedCount(
					req.user

				).then(
					(count) -> serveJson res, 200, keyify 'count', count
					interceptError res
				).done()
			
			# Create a new resource in the collection.
			# POST `/api/users`
			app.post collectionPath, (req, res) ->

				Model.authenticatedCreate(
					req.user
					req.body

				).then(
					(model) -> serveJson res, 201, keyify resource, model
					interceptError res
				).done()

			# Delete all resources in a collection.
			# DELETE `/api/users`
			app.delete collectionPath, (req, res) ->
				
				Model.authenticatedDestroyAll(
					req.user
				
				).then(
					-> serveJson res, 200, message: "Collection deleted."
					interceptError res
				).done()
			
			# Get a resource.
			# GET `/api/user/1`
			app.get resourcePath, (req, res) ->
				
				Model.authenticatedFind(
					req.user
					req.params.id
				
				).then(
					(model) -> serveJson res, 200, keyify resource, model
					interceptError res
				).done()
	
			# Update a resource.
			# PUT `/api/user/1`
			app.put resourcePath, (req, res) ->
				
				Model.authenticatedUpdate(
					req.user
					req.params.id
					req.body
				).then(
					-> serveJson res, 200, message: "Resource updated."
					interceptError res
				).done()
							
			# Delete a resource.
			# DELETE `/api/user/1`
			app.delete resourcePath, (req, res) ->
				
				Model.authenticatedDestroy(
					req.user
					req.params.id
				).then(
					-> serveJson res, 200, message: "Resource deleted."
					interceptError res
				).done()
	
# ## Implements hook `packageSettings`
exports.$packageSettings = ->
	
	# [CORS](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing)
	# headers.
	corsHeaders: null
	
# ## Implements hook `replContext`
# 
# Provide the database schema to the REPL context.
exports.$replContext = (context) ->
	
	context.schema = schema
