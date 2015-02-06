
# # Skin
#
# Allows the visual aspects of the site to be controlled by skin packages.

fs = require 'fs'
path = require 'path'

config = null
pkgman = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `preBootstrap`
	registrar.registerHook 'preBootstrap', ->

		config = require 'config'
		pkgman = require 'pkgman'

	# ## Implements hook `config`
	registrar.registerHook 'config', ->

		skinAssets = {}
		for packagePath in pkgman.packagesImplementing 'skinAssets'
			skinAssets[packagePath] = exports.assets packagePath

		default: config.get 'packageSettings:shrub-skin:default'
		assets: skinAssets

	# ## Implements hook `httpMiddleware`
	registrar.registerHook 'path', 'httpMiddleware', (http) ->

		label: 'Skin path handling'
		middleware: [

			(req, res, next) ->

				# If we get here and it's a skin URL, it must be a 404
				# otherwise, express/static would have picked it up already.
				return res.send 404 if req.path.match /^\/skin\//

				next()
		]

	# ## Implements hook `httpMiddleware`
	#
	# If configuration dictates, render the client-side Angular application in a
	# sandbox.
	registrar.registerHook 'render', 'httpMiddleware', (http) ->

		label: 'Render skinned page HTML'
		middleware: [

			(req, res, next) ->

				# } Render app.html
				return exports.renderAppHtml().then((html) ->
					req.delivery = html
					next()
				).catch (error) -> next error

	]

	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->

		# Default skin
		default: 'shrub-skin-strapped'

# ### ::activeKey
#
# *Get the active skin's key*
exports.activeKey = -> config.get 'packageSettings:shrub-skin:default'

exports.gruntSkin = (gruntConfig, key) ->

	{grunt} = gruntConfig

	skinPath = path.dirname require.resolve key

	gruntConfig.clean ?= {}
	gruntConfig.copy ?= {}
	gruntConfig.watch ?= {}

	gruntConfig.clean[key] = [
		"app/skin/#{key}"
	]

	copyFiles = []

	copyFiles.push(
		expand: true
		cwd: "#{skinPath}/app"
		src: ["#{verbatim}/**/*"]
		dest: "app/skin/#{key}"
	) for verbatim in ['css', 'fonts', 'img', 'js', 'lib']

	gruntConfig.copy[key] =

		files: copyFiles

	gruntConfig.watch["#{key}Copy"] =

		files: copyFiles.map((copyFile) -> copyFile.src).reduce(
			((l, r) -> l.concat r), []
		)
		tasks: [
			"newer:copy:#{key}"
		]

# ### ::renderAppHtml
#
# *Render the application HTML.*
exports.renderAppHtml = ->

	Promise = require 'bluebird'

	cheerio = require 'cheerio'

	assets = require 'shrub-assets'

	skinKey = exports.activeKey()
	skinDirectory = exports.skinDirectory skinKey

	environmentKey = if 'production' is process.env.NODE_ENV
		'production'
	else
		'default'

	readFile = Promise.promisify fs.readFile, fs
	readFile(
		"#{skinDirectory}/app/template/app.html", encoding: 'utf8'
	).then (html) ->

		$ = cheerio.load html

		pkgman.invoke 'skinRenderAppHtml', $

		$head = $('head')
		$body = $('body')

		# Inject the application-level assets first.
		appAssets = assets.assets()

		$head.append $('<link />').attr(
			type: 'text/css'
			rel: 'styleSheet'
			href: styleSheet
		) for styleSheet in appAssets.styleSheets

		$body.append $('<script />').attr(
			src: script
		) for script in appAssets.scripts

		# Inject the skin-level assets.
		skinAssets = exports.assets skinKey

		$head.append $('<link />').attr(
			class: 'skin'
			type: 'text/css'
			rel: 'stylesheet'
			href: "/skin/#{skinKey}/#{styleSheet}"
		) for styleSheet in skinAssets.styleSheets[environmentKey] ? []

		$body.append $('<script />').attr(
			class: 'skin'
			src: "/skin/#{skinKey}/#{script}"
		) for script in skinAssets.scripts[environmentKey] ? []

		$.html()

# ### ::skinDirectory
#
# *Get the directory a key'd skin lives within.*
exports.skinDirectory = (key) -> path.dirname require.resolve key

exports.assets = (skinKey) ->

	glob = require 'simple-glob'
	pkgman = require 'pkgman'

	skinPath = path.dirname require.resolve skinKey
	skinModule = require skinKey

	templates = {}
	for templatePath in glob cwd: "#{skinPath}/app/template", [
		'**/*.html', '!app.html'
	]

		templates[templatePath] = fs.readFileSync(
			"#{skinPath}/app/template/#{templatePath}"
		).toString 'utf8'

	skinAssets =

		templates: templates

		scripts:

			default: glob cwd: "#{skinPath}/app", [
				'js/**/*.js', '!js/**/*.min.js'
			]

			production: glob cwd: "#{skinPath}/app", [
				'js/**/*.min.js'
			]

		styleSheets:

			default: glob cwd: "#{skinPath}/app", [
				'css/**/*.css', '!css/**/*.min.css'
			]

			production: glob cwd: "#{skinPath}/app", [
				'css/**/*.min.css'
			]

	pkgman.invokePackage skinKey, 'skinAssets', skinAssets

	skinAssets
