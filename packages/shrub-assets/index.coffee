
# # Assets
#
# Serve different JS based on whether the server is running in production mode.

config = require 'config'

assets = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `clearCaches`
	registrar.registerHook 'clearCaches', ->

		assets = null

	# ## Implements hook `assetMiddleware`
	registrar.registerHook 'assetMiddleware', ->

		label: 'Shrub'
		middleware: [

			(assets, next) ->

				if 'production' is config.get 'NODE_ENV'
					assets.scripts.push '/lib/shrub/shrub.min.js'
				else
					assets.scripts.push '/lib/shrub/shrub.js'

				assets.styleSheets.push '/css/shrub.css'

				next()

		]


	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->

		gruntConfig.configureTask 'copy', 'shrub-assets', files: [
			src: '**/*'
			dest: 'app'
			expand: true
			cwd: "#{__dirname}/app"
		]

		gruntConfig.configureTask(
			'watch', 'shrub-assets'

			files: [
				"#{__dirname}/app/**/*"
			]
			tasks: 'build:shrub-assets'
		)

		gruntConfig.registerTask 'build:shrub-assets', [
			'newer:copy:shrub-assets'
		]

		gruntConfig.registerTask 'build', ['build:shrub-assets']

	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->

		assetMiddleware: [
			'shrub-assets/jquery'
			'shrub-socket-socket.io'
			'shrub-assets/angular'
			'shrub-assets'
			'shrub-html5-notification'
			'shrub-html5-local-storage'
			'shrub-config'
		]

	registrar.recur [
		'angular', 'bootstrap', 'jquery', 'ui-bootstrap'
	]

exports.assets = ->
	return assets if assets?

	debug = require('debug') 'shrub-silly:assets:middleware'

	middleware = require 'middleware'

	assets = scripts: [], styleSheets: []

	# Invoke hook `assetMiddleware`.
	# Invoked to gather script assets for requests.
	debug '- Loading asset middleware...'
	assetMiddleware = middleware.fromHook(
		'assetMiddleware'
		config.get 'packageSettings:shrub-assets:assetMiddleware'
	)
	debug '- Asset middleware loaded.'

	assetMiddleware.dispatch assets, (error) -> throw error if error?

	assets
