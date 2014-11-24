
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

exports.gruntSkin = (gruntConfig, key) ->
	
	{grunt} = gruntConfig
	
	skinPath = path.dirname require.resolve key
	
	gruntConfig.clean ?= {}
	gruntConfig.copy ?= {}
	gruntConfig.watch ?= {}

	gruntConfig.clean[key] = [
		"app/skin/#{key}"
	]

	copyFiles = [
		expand: true
		cwd: "#{skinPath}/app/template"
		src: [
			'**/*.html'
			'!app.html'
		]
		dest: "app/skin/#{key}"
	]
	
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
			"copy:#{key}"
		]
	
	gruntConfig.shrub.tasks["assetsJson:#{key}"] = ->
		
		assets = {}
		
		{tasks} = require 'grunt/lib/grunt/cli'
		isProduction = -1 isnt tasks.indexOf 'production'
		
		assets.templates = grunt.file.expand(
			cwd: "#{skinPath}/app/template"
			[
				'**/*.html'
				'!app.html'
			]
		)
		
		assets.scripts =
		
			default: grunt.file.expand(
				cwd: "#{skinPath}/app"
				[
					'js/**/*.js'
					'!js/**/*.min.js'
				]
			)
			
			production: grunt.file.expand(
				cwd: "#{skinPath}/app"
				[
					'js/**/*.min.js'
				]
			)
			
		assets.styleSheets =
		
			default: grunt.file.expand(
				cwd: "#{skinPath}/app"
				[
					'css/**/*.css'
					'!css/**/*.min.css'
				]
			).concat [
				'css/style.css'
			]
			
			production: grunt.file.expand(
				cwd: "#{skinPath}/app"
				[
					'css/**/*.min.css'
				]
			).concat [
				'css/style.css'
			]
			
		grunt.file.write(
			"app/skin/#{key}/assets.json"
			JSON.stringify assets, null, '\t'
		) 

# ### ::renderAppHtml
# 
# *Render the application HTML.*
exports.renderAppHtml = (locals) ->
	
	skinKey = exports.activeKey()
	skinDirectory = exports.skinDirectory skinKey
	
	environmentKey = if 'production' is process.env.NODE_ENV
		'production'
	else
		'default'

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
