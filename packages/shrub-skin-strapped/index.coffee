
# # Strapped
# 
# The default skin.

path = require 'path'

shrubSkin = require 'shrub-skin'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `mailHtml`
	registrar.registerHook 'mailHtml', ($body, html, $) ->
	
		$('.container > .main', $body).html html
		
		$body.find('.navbar-toggle, .navbar-collapse').remove()
		$body.find('[data-shrub-ui-messages]').remove()
		
		$body.find('script').remove()
		
		$('noscript', $body).remove()

	# ## Implements hook `skinAssets`
	registrar.registerHook 'skinAssets', (assets) ->
		
		# Add our future-compiled LESS style sheets.
		assets.styleSheets.default.push 'css/style.css'
		assets.styleSheets.production.push 'css/style.css'
	
	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
		
		gruntConfig.less ?= {}
		
		shrubSkin.gruntSkin gruntConfig, 'shrub-skin-strapped'
		
		gruntConfig.less['shrub-skin-strapped'] =
			
			files: [
				src: [
					"#{__dirname}/app/less/style.less"
				]
				dest: 'app/skin/shrub-skin-strapped/css/style.css'
			]
			
		gruntConfig.watch['shrub-skin-strappedLess'] =
		
			files: [
				"#{__dirname}/app/less/style.less"
			]
			tasks: [
				'newer:less:shrub-skin-strapped'
			]
		
		gruntConfig.shrub.tasks['build:shrub-skin-strapped'] = [
			'newer:clean:shrub-skin-strapped'
			'newer:copy:shrub-skin-strapped'
			'less:shrub-skin-strapped'
		]
		
		gruntConfig.shrub.tasks['build'].push 'build:shrub-skin-strapped'

		gruntConfig.shrub.npmTasks.push 'grunt-contrib-less'
