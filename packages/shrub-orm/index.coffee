
# # [Object-relational mapping](http://en.wikipedia.org/wiki/Object-relational_mapping) using Waterline.
#
# Tools for working with [Waterline](https://github.com/balderdashy/waterline).

config = require 'config'
pkgman = require 'pkgman'

Waterline = null

collections = {}
connections = {}

waterline = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `preBootstrap`
	registrar.registerHook 'preBootstrap', ->

		Waterline = require 'waterline'

	# ## Implements hook `bootstrapMiddleware`
	registrar.registerHook 'bootstrapMiddleware', ->

		waterline = new Waterline()

		label: 'Bootstrap ORM'
		middleware: [

			(next) -> exports.initialize next

		]

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->

		gruntConfig.configureTask 'copy', 'shrub-orm', files: [
			src: '**/*'
			dest: 'app'
			expand: true
			cwd: "#{__dirname}/app"
		]

		gruntConfig.configureTask(
			'watch', 'shrub-orm'

			files: [
				"#{__dirname}/app/**/*"
			]
			tasks: 'build:shrub-orm'
		)

		gruntConfig.registerTask 'build:shrub-orm', [
			'newer:copy:shrub-orm'
		]

		gruntConfig.registerTask 'build', ['build:shrub-orm']

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

exports.initialize = (fn) ->

	config_ = config.get 'packageSettings:shrub-orm'

	waterlineConfig = adapters: {}, connections: {}

	for adapter in config_.adapters
		waterlineConfig.adapters[adapter] = require adapter

	waterlineConfig.connections = config_.connections

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

	# Invoke hook `collectionsAlter`.
	# Allows packages to alter any Waterline collections defined.
	pkgman.invoke 'collectionsAlter', collections_, waterline

	# Load the collections into Waterline.
	waterlineConfig.collections = for i, collection of collections_
		Waterline.Collection.extend collection

	waterline.initialize waterlineConfig, (error, data) ->
		return fn error if error?

		collections = data.collections
		connections = data.connections

		fn()

exports.collection = (identity) -> collections[identity]

exports.collections = -> collections

exports.connections = -> connections

exports.teardown = (fn) -> waterline.teardown fn

exports.waterline = -> waterline
