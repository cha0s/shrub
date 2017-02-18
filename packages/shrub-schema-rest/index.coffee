
# # REST API for database schema
#
# Serve the database schema over a REST API.

i8n = require 'inflection'

config = require 'config'

exports.pkgmanRegister = (registrar) ->

  # ## Implements hook `shrubConfigClient`
  registrar.registerHook 'shrubConfigClient', ->

    apiRoot: config.get 'packageConfig:shrub-schema:apiRoot'

  # ## Implements hook `shrubHttpRoutes`
  #
  # Serve the database schema as an authenticated REST API.
  registrar.registerHook 'shrubHttpRoutes', (http) ->
    routes = []

    # } DRY.
    interceptError = (res) ->
      (error) -> serveJson res, error.code ? 500, message: error.message

    # } DRY.
    serveJson = (res, code, data) ->

      # CORS policy enforcement.
      corsHeaders = config.get 'packageConfig:shrub-schema:corsHeaders'
      res.set corsHeaders if corsHeaders?

      # Serve JSON manually, breaking it to protect against XSRF.
      # See: [http://docs.angularjs.org/api/ng/service/$http#json-vulnerability-protection](http://docs.angularjs.org/api/ng/service/$http#json-vulnerability-protection)
      res.set 'Content-Type', 'application/json'
      res.statusCode = code
      res.send ")]}',\n#{JSON.stringify data}"

    # Serve the models. For each model, we'll define REST paths to allow
    # interaction with a model, or set of models.
    for name, Model of schema.models

      do (Model) ->

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
        apiRoot = config.get 'packageConfig:shrub-schema:apiRoot'
        collectionPath = "#{apiRoot}/#{collection}"
        resourcePath = "#{apiRoot}/#{resource}/:id"

        # Get the entire collection.
        # GET `/api/users`
        routes.push
          path: collectionPath
          receiver: (req, res) ->

            query = if Object.keys(req.query).length then req.query

            Model.authenticatedAll(
              req.user, query
            ).then((models) ->
              serveJson res, 200, keyify collection, models
            ).catch interceptError res

        # Get how many resources are in the collection.
        # GET `/api/users/count`
        routes.push
          path: "#{collectionPath}/count"
          receiver: (req, res) ->

            Model.authenticatedCount(
              req.user
            ).then((count) ->
              serveJson res, 200, keyify 'count', count
            ).catch interceptError res

        # Create a new resource in the collection.
        # POST `/api/users`
        routes.push
          verb: 'post'
          path: collectionPath
          receiver: (req, res) ->

            Model.authenticatedCreate(
              req.user, req.body
            ).then((model) ->
              serveJson res, 201, keyify resource, model
            ).catch interceptError res

        # Delete all resources in a collection.
        # DELETE `/api/users`
        routes.push
          verb: 'delete'
          path: collectionPath
          receiver: (req, res) ->

            Model.authenticatedDestroyAll(
              req.user
            ).then(->
              serveJson res, 200, message: 'Collection deleted.'
            ).catch interceptError res

        # Get a resource.
        # GET `/api/user/1`
        routes.push
          path: resourcePath
          receiver: (req, res) ->

            Model.authenticatedFind(
              req.user
              req.params.id
            ).then((model) ->
              serveJson res, 200, keyify resource, model
            ).catch interceptError res

        # Update a resource.
        # PUT `/api/user/1`
        routes.push
          verb: 'put'
          path: resourcePath
          receiver: (req, res) ->

            Model.authenticatedUpdate(
              req.user
              req.params.id
              req.body
            ).then(->
              serveJson res, 200, message: 'Resource updated.'
            ).catch interceptError res

        # Delete a resource.
        # DELETE `/api/user/1`
        routes.push
          verb: 'delete'
          path: resourcePath
          receiver: (req, res) ->

            Model.authenticatedDestroy(
              req.user
              req.params.id
            ).then(->
              serveJson res, 200, message: 'Resource deleted.'
            ).catch interceptError res

    routes

  # ## Implements hook `shrubConfigServer`
  registrar.registerHook 'shrubConfigServer', ->

    # } The URL root where the schema REST API is served.
    apiRoot: '/api'

    # [CORS](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing)
    # headers.
    corsHeaders: null


exports.resourcePaths = (name) ->

  resource = i8n.dasherize(i8n.underscore name).toLowerCase()

  resource: resource
  collection: i8n.pluralize resource
