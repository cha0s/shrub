
# # Notifications

errors = require 'errors'

# ## Implements hook `directive`
exports.$directive = -> [
	'$timeout', 'ui/notifications'
	($timeout, {count, removeTop, top}) ->
	
		link: (scope, elm, attr) ->
			
			activeNotification = null
			
			$notificationWrapper = elm.find '.notification-wrapper'
			
			# User closed the notification.
			scope.close = ->
				$timeout.cancel activeNotification
				$notificationWrapper.fadeOut '2000', -> scope.$apply ->
					removeTop()
					
				return
			
			scope.$watch(
				-> top()
				->
					
					# When we get a new notification, make it our active
					# notification.
					scope.notification = top()
					return if count() is 0
					
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

# ## Implements hook `rpcCall`
exports.$rpcCall = -> [
	'ui/notifications', 'result'
	(notifications, result) ->

		# Add a notification with the error text.
		result.catch (error) -> notifications.add(
			class: 'alert-danger', text: errors.message error
		)

] 

# ## Implements hook `service`
exports.$service = -> [
	'socket'
	(socket) ->
	
		service = {}
		
		_notifications = []
		
		# ## notifications.add
		# 
		# Add a notification to be displayed.
		service.add = (notification) ->
			
			notification.class ?= 'alert-info'
			
			_notifications.push notification
		
		# ## notifications.top
		# 
		# Get the top notification.
		service.top = -> _notifications[0]
		
		# ## notifications.removeTop
		# 
		# Remove the top notification.
		service.removeTop = -> _notifications.shift()
		
		# ## notifications.count
		# 
		# The number of notifications to show.
		service.count = -> _notifications.length

		# Accept notifications from the server.
		socket.on 'notifications', (data) ->
			
			service.add notification for notification in data.notifications
			
		service
		
]
