
path = require 'path'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
		
		gruntConfig.clean ?= {}
		gruntConfig.copy ?= {}
		gruntConfig.less ?= {}
		gruntConfig.watch ?= {}

		gruntConfig.clean['shrub-skin-strapped'] = [
			'app/skin/shrub-skin-strapped'
		]

		copyFiles = [
			expand: true
			cwd: "#{__dirname}/app/template"
			src: [
				'**/*.html'
				'!app.html'
			]
			dest: 'app/skin/shrub-skin-strapped'
		]
		
		copyFiles.push(
			expand: true
			cwd: "#{__dirname}/app"
			src: ["#{verbatim}/**/*"]
			dest: "app/skin/shrub-skin-strapped"
		) for verbatim in ['css', 'fonts', 'img', 'js', 'lib']

		gruntConfig.copy['shrub-skin-strapped'] =
			
			files: copyFiles
			
		gruntConfig.less['shrub-skin-strapped'] =
			
			files: [
				src: [
					"#{__dirname}/app/less/**/*.less"
				]
				dest: 'app/skin/shrub-skin-strapped/css/style.css'
			]
			
		gruntConfig.watch['shrub-skin-strappedCopy'] =
		
			files: copyFiles.map((copyFile) -> copyFile.src).reduce(
				((l, r) -> l.concat r), []
			)
			tasks: [
				'copy:shrub-skin-strapped'
			]
		
		gruntConfig.watch['shrub-skin-strappedCopy'] =
		
			files: [
				"#{__dirname}/app/less/**/*.less"
			]
			tasks: [
				'less:shrub-skin-strapped'
			]
		
		gruntConfig.shrub.npmTasks.push 'grunt-contrib-less'
		
		gruntConfig.shrub.tasks['assetsJson:shrub-skin-strapped'] = ->
			
			assets =
			
				templates: gruntConfig.grunt.file.expand(
					cwd: "#{__dirname}/app/template"
					[
						'**/*.html'
						'!app.html'
					]
				)
				
				scripts: gruntConfig.grunt.file.expand(
					cwd: "#{__dirname}/app"
					["js/**/*"]
				)
			
				styleSheets: gruntConfig.grunt.file.expand(
					cwd: "#{__dirname}/app"
					["css/**/*"]
				)
				
			assets.styleSheets.push 'css/style.css'
			
			gruntConfig.grunt.file.write(
				'app/skin/shrub-skin-strapped/assets.json'
				JSON.stringify assets, null, '\t'
			) 
		
		gruntConfig.shrub.tasks['build:shrub-skin-strapped'] = [
			'clean:shrub-skin-strapped'
			'copy:shrub-skin-strapped'
			'less:shrub-skin-strapped'
			'assetsJson:shrub-skin-strapped'
		]
		
		gruntConfig.shrub.tasks['build'].push 'build:shrub-skin-strapped'
