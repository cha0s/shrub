
# # [Object-relational mapping](http://en.wikipedia.org/wiki/Object-relational_mapping) using Waterline.
#
# Tools for working with [Waterline](https://github.com/balderdashy/waterline).

config = require 'config'

clientModule = require './client'

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

				clientModule.initialize(waterlineConfig).then(->
					next()
				).catch next

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

		context.orm = clientModule

exports.collection = clientModule.collection

exports.collections = clientModule.collections

exports.connections = clientModule.connections

exports.waterline = clientModule.waterline
