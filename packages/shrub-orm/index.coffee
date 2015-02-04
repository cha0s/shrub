
# # [Object-relational mapping](http://en.wikipedia.org/wiki/Object-relational_mapping) using Waterline.
#
# Tools for working with [Waterline](https://github.com/balderdashy/waterline).

Promise = require 'bluebird'
Waterline = require 'waterline'

config = require 'config'

config = require 'config'
pkgman = require 'pkgman'

collections = {}
connections = {}

waterline = new Waterline()

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `bootstrapMiddleware`
	registrar.registerHook 'bootstrapMiddleware', ->

		label: 'Bootstrap ORM'
		middleware: [

			(next) ->

				waterlineConfig = config.get 'packageSettings:shrub-orm'

				adapters = waterlineConfig.adapters
				waterlineConfig.adapters = {}
				for adapter in adapters
					waterlineConfig.adapters[adapter] = require adapter

				exports.initialize waterlineConfig, next

		]

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->

		gruntConfig.copy ?= {}

		gruntConfig.copy['shrub-orm'] =
			files: [
				src: '**/*'
				dest: 'app'
				expand: true
				cwd: "#{__dirname}/app"
			]

		gruntConfig.watch['shrub-orm'] =

			files: [
				"#{__dirname}/app/**/*"
			]
			tasks: 'build:shrub-orm'

		gruntConfig.shrub.tasks['build:shrub-orm'] = [
			'newer:copy:shrub-orm'
		]

		gruntConfig.shrub.tasks['build'].push 'build:shrub-orm'

	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->

		adapters: [
			'sails-redis'
		]

		connections:

			shrub:

				adapter: 'sails-redis'
				port: 6379
				host: 'localhost'
				password: null
				database: null

	# ## Implements hook `replContext`
	#
	# Provide ORM to the REPL context.
	registrar.registerHook 'replContext', (context) ->

		context.orm = exports

exports.initialize = (config, fn) ->

	# Invoke hook `collections`.
	# Allows packages to create Waterline collections.
	collections_ = {}
	for collectionList in pkgman.invokeFlat 'collections', waterline
		for identity, collection of collectionList

			# Collection defaults.
			collection.connection ?= 'shrub'
			collection.identity ?= identity
			collections_[collection.identity] = collection

			# Instantiate a model with defaults supplied.
			collection.instantiate = (values = {}) ->

				for key, value of @attributes
					continue unless value.defaultsTo?

					values[key] ?= if 'function' is typeof value.defaultsTo
						value.defaultsTo.call values
					else
						JSON.parse JSON.stringify value.defaultsTo

				new @_model @_schema.cleanValues @_transformer.serialize values

			collection.attributes.toJSON ?= ->
				O = @toObject()

				# Remove toJSON return until the following PR makes it in
				# https://github.com/balderdashy/waterline/pull/818
				# This will ignore 'protected' attributes, unfortunately.
				O.toJSON = null

				O

	# Invoke hook `collectionsAlter`.
	# Allows packages to alter any Waterline collections defined.
	pkgman.invoke 'collectionsAlter', collections_, waterline

	# Load the collections into Waterline.
	for i, collection of collections_
		Collection = Waterline.Collection.extend collection
		waterline.loadCollection Collection

	waterline.initialize config, (error, data) ->
		return fn error if error?

		collections = data.collections
		connections = data.connections

		fn()

exports.collection = (identity) -> collections[identity]

exports.collections = -> collections

exports.connections = -> connections

exports.waterline = -> waterline
