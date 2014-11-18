
{fork} = require 'child_process'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
		
		{grunt} = gruntConfig
		
		gruntConfig.shrub.tasks['dox:prepareDirectory'] = ->
		
			grunt.file.mkdir 'gh-pages'
	
		gruntConfig.shrub.tasks['dox:dynamic'] = ->
		
			done = @async()
		
			child = fork "#{__dirname}/dynamic.coffee"
			
			child.on 'close', (code) ->
			
				return done() if code is 0
				
				grunt.fail.fatal "Dynamic documentation generation failed", code

		gruntConfig.shrub.tasks['dox:groc'] = ->
			
			done = @async()
			
			child = fork "#{__dirname}/../../../node_modules/groc/bin/groc"
			
			child.on 'close', (code) ->
			
				return done() if code is 0
				
				grunt.fail.fatal "Groc failed", code

		gruntConfig.shrub.tasks['dox'] = [
			 'dox:prepareDirectory'
			 'dox:dynamic'
			 'dox:groc'
		]
