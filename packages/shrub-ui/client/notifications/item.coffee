
# # Notification item

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		'shrub-ui/notifications'
		(notifications) ->
		
			directive = {}
			
			directive.candidateKeys = [
				['queueName', 'notification.type']
				'notification.type'
				'queueName'
			]
			
			directive.scope = true
				
			directive.template = """

<div
	data-ng-bind="notification.variables | json"
></div>

"""
			
			directive
			
	]
		
