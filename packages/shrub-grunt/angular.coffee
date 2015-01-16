
pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
	
		{grunt} = gruntConfig
		
		gruntConfig.clean ?= {}
		gruntConfig.coffee ?= {}
		gruntConfig.concat ?= {}
		gruntConfig.watch ?= {}
		
		gruntConfig.clean.angular = [
			'build/js/app.js'
			'build/js/app-dependencies.js'
			'build/js/app-bundled.js'
		]
		
		gruntConfig.coffee.angular =
		
			files: [
				src: [
					'client/app.coffee'
				]
				dest: 'build/js/app.js'
			]
			expand: true
			ext: '.js'
			
			options:
				bare: true
		
		gruntConfig.concat.angular =
			
			files: [
				src: [
					'build/js/app-dependencies.js'
					'build/js/app.js'
				]
				dest: 'build/js/app-bundled.js'
			]
			
			options:
				
				banner: """

(function() {

"""
				
				footer: """

})();

"""
		gruntConfig.watch.angular =

			files: [
				'client/app.coffee'
				'client/app-dependencies.coffee'
			]
			tasks: [
				'build:angular', 'build:shrub'
			]
			options: livereload: true
		
		gruntConfig.shrub.tasks['angularCoreDependencies:angular'] = ->
			
			dependencies = []
			
			# Invoke hook `angularAppDependencies`.
			for dependenciesList in pkgman.invokeFlat 'angularCoreDependencies'
				
				dependencies.push.apply dependencies, dependenciesList
				
			js = """

var dependencies = [];


"""
				
			js += "dependencies.push('#{
				dependencies.join "');\ndependencies.push('"
			}');\n" if dependencies.length > 0
				
			grunt.file.write 'build/js/app-dependencies.js', js
		
		gruntConfig.shrub.tasks['build:angular'] = [
			'newer:coffee:angular'
			'angularCoreDependencies:angular'
			'concat:angular'
		]
		
		gruntConfig.shrub.tasks['build'].push 'build:angular'
	