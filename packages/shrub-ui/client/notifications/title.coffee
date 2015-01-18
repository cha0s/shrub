# # Notifications title

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		'shrub-ui/notifications'
		(notifications) ->
		
			directive = {}
			
			directive.candidateKeys = [
				'queueName'
			]
			
			directive.scope = true
				
			directive.template = """

<div>Notifications</div>

"""
			
			directive
			
	]
		
