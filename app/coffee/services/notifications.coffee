
$module.service 'notifications', [
	'socket'
	(socket) ->
	
		_notifications = []
		
# Add a notification to be displayed.
		
		@addNotification = (notification) -> _notifications.push notification
		
# Get the top notification.
		
		@topNotification = -> _notifications[0]
		
# Remove the top notification.
		
		@removeTopNotification = -> _notifications.shift()
		
# The number of notifications to show.
		
		@count = -> _notifications.length

# Accept notifications from the server.
		
		socket.on 'notifications', (data) ->
			
			_notifications.push.apply _notifications, data.notifications
			
		return
		
]
