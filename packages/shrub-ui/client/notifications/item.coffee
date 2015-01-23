
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
			
			directive.link = (scope, element) ->
			
				scope.toggleMarkedAsRead = ($event) ->
					$event.stopPropagation()
					
					scope.markAsRead(
						scope.notification, not scope.notification.markedAsRead
					)
				
				scope.$watch 'notification.markedAsRead', (markedAsRead) ->
					
					if markedAsRead
						element.addClass 'was-read'
						scope.iconClass = 'glyphicon-check'
						scope.title = 'Mark as unread' 
					else
						element.removeClass 'was-read'
						scope.iconClass = 'glyphicon-eye-open'
						scope.title = 'Mark as read'
						
			directive.scope = true
				
			directive.template = """

<a
	href="javascript:void(0)"
	data-ng-click="toggleMarkedAsRead($event)"
>
	<span
		class="mark-as-read glyphicon"
		data-ng-class="iconClass"
		tabindex="0"
		title="{{title}}"
	></span>
</a>

<div
	data-ng-bind="notification.variables | json"
></div>

"""
			
			directive
			
	]
		
