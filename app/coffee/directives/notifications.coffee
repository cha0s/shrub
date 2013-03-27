
$module.directive 'asNotifications', [
	'$timeout', 'notifications'
	($timeout, notifications) ->
	
		templateUrl: '/partials/notifications.html'
		
		link: (scope, elm, attr) ->
			
			activeNotification = null
			
			$notificationWrapper = elm.find '.notification-wrapper'
			
# User closed the notification.
			
			scope.close = ->
				$timeout.cancel activeNotification
				$notificationWrapper.fadeOut '2000', -> scope.$apply ->
					notifications.removeTopNotification()
			
			scope.$watch(
				-> notifications.topNotification()
				->
					
# When we get a new notification, make it our active notification.

					scope.notification = notifications.topNotification()
					
					return if notifications.count() is 0
					
# Fade it in and keep it on the screen for 15 seconds.
						
					$notificationWrapper.fadeIn '2000'
							
					activeNotification = $timeout(
						-> scope.close()
						15000
					)
					
			)
			
]
