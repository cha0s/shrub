
###

Socket.IO adapter proxy for [JugglingDB](https://github.com/1602/jugglingdb).

This adapter forwards all adapter commands through a socket, to be run by the
database server.

###

i8n = require 'inflection'

class SocketAdapter
	
	constructor: (@schema, @$http) ->
	
	# DRY.
	promiseCallback = (fn, promise) -> promise.then(
		({data}) -> fn null, data
		({data}) -> fn new Error data.message
	)
		
	# Translate model names to REST resource/collection paths.
	# 'CatalogEntry' -> ['catalog-entry', 'catalog-entries']
	resourcePaths: (name) ->

		resource = i8n.underscore name
		resource = i8n.dasherize resource.toLowerCase()
		
		resource: resource
		collection: i8n.pluralize resource
	
	# Translate a query object into a REST query.
	translateQuery = (query) ->
		
		params = []
		params.push "limit=#{query.limit}" if query.limit?
		params.push "order=#{query.order}" if query.order?
		params.push "skip=#{query.skip}" if query.skip?
		if query.where? and Object.keys(query.where).length
			for key, value of query.where
				params.push "where[#{key}]=#{value}"
		params.join '&'
	
	# Connect/disconnect are nops, gotta invoke the callback though.
	[
		'connect', 'disconnect'
	].forEach (prop) => @::[prop] = (fn) -> fn()
	
	# These adapter methods aren't necessary to run on the client. They are
	# responsible for underlying schema management and only make sense when
	# the adapter is actually touching the database e.g. server-side.
	[
		'define', 'defineForeignKey', 'possibleIndexes', 'updateIndexes'
		
		# and our ugly duckling.
		'transaction'
	].forEach (prop) => @::[prop] = ->
	
	all: (model, query, fn) ->
		
		{collection} = @resourcePaths model
		query = translateQuery query
		
		promiseCallback fn, @$http.get "#{@schema.root}/#{collection}?#{query}"
	
	own: (model, query, fn) ->
		
		{collection} = @resourcePaths model
		query = translateQuery query
		
		promiseCallback fn, @$http.get "#{@schema.root}/#{collection}/own?#{query}"
	
	count: (model, fn) ->
	
		{collection} = @resourcePaths model
		
		promiseCallback fn, @$http.get "#{@schema.root}/#{collection}/count"
	
	create: (model, data, fn) ->
	
		{collection} = @resourcePaths model
		
		promiseCallback fn, @$http.post "#{@schema.root}/#{collection}", data
	
	destroy: (model, id, fn) ->
		
		{resource} = @resourcePaths model
		
		promiseCallback fn, @$http.delete "#{@schema.root}/#{resource}/#{id}"
	
	destroyAll: (model, fn) ->
	
		{collection} = @resourcePaths model
		
		promiseCallback fn, @$http.delete "#{@schema.root}/#{collection}"
	
	exists: (model, id, fn) ->
	
		{resource} = @resourcePaths model
		
		promiseCallback fn, @$http.get "#{@schema.root}/#{resource}/#{id}/exists"
	
	find: ->
	
	save: (model, data, fn) ->
	
		{id} = data
		{resource} = @resourcePaths model
		
		if id?
			promiseCallback fn, @$http.put "#{@schema.root}/#{resource}/#{id}", data
		else
			@create model, data, fn
	
	updateAttributes: (model, id, data, fn) ->
		data.id = id
		@save model, data, fn
	
	updateOrCreate: @::save
	
# Initialization method; instantiate the SocketAdapter.
exports.initialize = (schema) ->
	{$http, inflection} = schema.settings
	schema.adapter = new SocketAdapter schema, $http, inflection
