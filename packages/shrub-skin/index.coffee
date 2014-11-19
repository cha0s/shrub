
# # Skin
# 
# Allows the visual aspects of the site to be controlled by skin packages.

cheerio = require 'cheerio'
fs = require 'fs'
path = require 'path'
Promise = require 'bluebird'

config = require 'config'

assets = require 'shrub-assets'

{handlebars} = require 'hbs'

readFile = Promise.promisify fs.readFile, fs

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `config`
	registrar.registerHook 'config', (req) ->
		
		default: config.get 'packageSettings:shrub-skin:default'
	
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
				
				skinKey = exports.activeKey()
				
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

# ### ::renderAppHtml
# 
# *Render the application HTML.*
exports.renderAppHtml = (locals) ->
	
	skinKey = exports.activeKey()
	skinDirectory = exports.skinDirectory skinKey

	readFile(
		"#{skinDirectory}/app/template/app.html", encoding: 'utf8'
	).then (html) ->
		
		$ = cheerio.load html
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
		readFile(
			"app/skin/#{skinKey}/assets.json", encoding: 'utf8'
		).then (jsonText) ->
			
			skinAssets = JSON.parse jsonText
			
			$head.append $('<link />').attr(
				class: 'skin'
				type: 'text/css'
				rel: 'stylesheet'
				href: "/skin/#{skinKey}/#{styleSheet}"
			) for styleSheet in skinAssets.styleSheets ? []

			$body.append $('<script />').attr(
				class: 'skin'
				src: "/skin/#{skinKey}/#{script}"
			) for script in skinAssets.scripts ? []
			
			$.html()

# ### ::skinDirectory
# 
# *Get the directory a key'd skin lives within.*
exports.skinDirectory = (key) -> path.dirname require.resolve key
