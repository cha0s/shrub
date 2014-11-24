
# # Strapped
# 
# The default skin.

path = require 'path'

shrubSkin = require 'shrub-skin'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
		
		gruntConfig.less ?= {}
		
		shrubSkin.gruntSkin gruntConfig, 'shrub-skin-strapped'

		gruntConfig.less['shrub-skin-strapped'] =
			
			files: [
				src: [
					"#{__dirname}/app/less/**/*.less"
				]
				dest: 'app/skin/shrub-skin-strapped/css/style.css'
			]
			
		gruntConfig.watch['shrub-skin-strappedLess'] =
		
			files: [
				"#{__dirname}/app/less/**/*.less"
			]
			tasks: [
				'less:shrub-skin-strapped'
			]
		
		gruntConfig.shrub.tasks['build:shrub-skin-strapped'] = [
			'clean:shrub-skin-strapped'
			'copy:shrub-skin-strapped'
			'less:shrub-skin-strapped'
			'assetsJson:shrub-skin-strapped'
		]
		
		gruntConfig.shrub.tasks['build'].push 'build:shrub-skin-strapped'

		gruntConfig.shrub.npmTasks.push 'grunt-contrib-less'
