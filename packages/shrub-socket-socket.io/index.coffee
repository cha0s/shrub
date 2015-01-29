
# # Socket.IO
#
# SocketManager implementation using [Socket.IO](http://socket.io/).

Promise = require 'bluebird'

config = require 'config'
errors = require 'errors'
logging = require 'logging'
pkgman = require 'pkgman'

logger = new logging.create 'logs/socket.io.log'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `assetMiddleware`
	registrar.registerHook 'assetMiddleware', ->

		label: 'Socket.IO'
		middleware: [

			(assets, next) ->

				if 'production' is config.get 'NODE_ENV'

					assets.scripts.push '/lib/socket.io/socket.io.min.js'

				else

					assets.scripts.push '/lib/socket.io/socket.io.js'

				next()

		]

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->

		gruntConfig.copy ?= {}
		gruntConfig.watch ?= {}

		gruntConfig.copy['shrub-socket.io'] =
			files: [
				src: '**/*'
				dest: 'app'
				expand: true
				cwd: "#{__dirname}/app"
			]

		gruntConfig.watch['shrub-socket.io'] =

			files: [
				"#{__dirname}/app/**/*"
			]
			tasks: 'build:shrub-socket.io'

		gruntConfig.shrub.tasks['build:shrub-socket.io'] = [
			'newer:copy:shrub-socket.io'
		]

		gruntConfig.shrub.tasks['build'].push 'build:shrub-socket.io'

exports.Manager = require './manager'
