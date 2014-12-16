
# # [Object-relational mapping](http://en.wikipedia.org/wiki/Object-relational_mapping) using Waterline.
#
# browserify -r waterline-browser -x util -x assert -x events -x bluebird -x async -x lodash -x buffer -x anchor -x validator -x waterline-criteria -x waterline-schema > waterline-browser.js
# 
# Provide the ORM as an Angular service.

Promise = require 'bluebird'
Waterline = require 'waterline'

config = require 'config'
pkgman = require 'pkgman'

collections = null
connections = null

waterline = new Waterline()

exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `collectionsAlter`
#	registrar.registerHook 'collectionsAlter', (collections_) ->
#	
#		collection.connection = 'socket' for collection in collections_
	
	# ## Implements hook `service`
	registrar.registerHook 'service', -> [
		'$http'
		($http) ->
		
			service = {}
			
			initializedPromise = exports.initialize
			
				adapters:
				
					socket: require './adapter'
				
				connections:
				
					shrub:
		
						adapter: 'socket'
			
			service.collection = ->
				args = arguments
				initializedPromise.then ->
					exports.collection args...
			
			service.collections = ->
				args = arguments
				initializedPromise.then ->
					exports.collections args...
			
			service.connections = ->
				args = arguments
				initializedPromise.then ->
					exports.connections args...
			
			service.waterline = exports.waterline
			
			service.initialized = -> initializedPromise
			
			service
	
	]

exports.initialize = (config) -> new Promise (resolve) ->

	# Invoke hook `collections`.
	# Allows packages to create Waterline collections.
	collections_ = {}
	for collectionList in pkgman.invokeFlat 'collections', waterline
		for identity, collection of collectionList
			
			# Collection defaults.
			collection.connection ?= 'shrub'
			collection.identity ?= identity
			collections_[collection.identity] = collection

	# Invoke hook `collectionsAlter`.
	# Allows packages to alter any Waterline collections defined.
	pkgman.invoke 'collectionsAlter', collections_, waterline
	
	# Load the collections into Waterline.
	for i, collection of collections_
			
		collection.instantiate = (values = {}) ->
		
			for key, value of @attributes
				continue unless value.defaultsTo?
					
				values[key] ?= if 'function' is typeof value.defaultsTo
					value.defaultsTo.call values
				else
					JSON.parse JSON.stringify value.defaultsTo
			
			new @_model @_schema.cleanValues @_transformer.serialize values
				
		Collection = Waterline.Collection.extend collection
		waterline.loadCollection Collection
	
	waterline.initialize config, (error, data) ->
		
		return reject error if error?
		
		collections = data.collections
		connections = data.connections
		
		resolve()

exports.collection = (identity) -> collections[identity]

exports.collections = -> collections

exports.connections = -> connections

exports.waterline = -> waterline
