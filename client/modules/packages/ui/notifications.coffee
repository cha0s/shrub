
exports.$directive = -> [
	'$timeout', 'ui/notifications'
	($timeout, notifications) ->
	
		link: (scope, elm, attr) ->
			
			activeNotification = null
			
			$notificationWrapper = elm.find '.notification-wrapper'
			
# User closed the notification.
			
			scope.close = ->
				$timeout.cancel activeNotification
				$notificationWrapper.fadeOut '2000', -> scope.$apply ->
					notifications.removeTop()
					
				return
			
			scope.$watch(
				-> notifications.top()
				->
					
# When we get a new notification, make it our active notification.

					scope.notification = notifications.top()
					return if notifications.count() is 0
					
# Fade it in and keep it on the screen for 15 seconds.
						
					$notificationWrapper.fadeIn '2000'
							
					activeNotification = $timeout(
						-> scope.close()
						15000
					)
					
			)
			
		template: """

<div class="notification-wrapper">
	
	<div
		data-ng-show="!!notification"
		data-ng-class="notification.class"
		class="alert notification fade in"
	>
		<button
			type="button"
			class="close"
			data-ng-click="close()"
		>&times;</button>
		<span data-ng-bind-html="notification.text"></span>
	</div>
	
</div>

"""
		
]

exports.$service = -> [
	'socket'
	(socket) ->
	
		_notifications = []
		
		service = {}
		
# Add a notification to be displayed.
		
		service.add = (notification) ->
			
			notification.class ?= 'alert-info'
			
			_notifications.push notification
		
# Get the top notification.
		
		service.top = -> _notifications[0]
		
# Remove the top notification.
		
		service.removeTop = -> _notifications.shift()
		
# The number of notifications to show.
		
		service.count = -> _notifications.length

# Accept notifications from the server.
		
		socket.on 'notifications', (data) ->
			
			service.add notification for notification in data.notifications
			
		service
		
]
