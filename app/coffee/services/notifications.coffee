
$module.service 'notifications', [
	'comm/socket'
	(socket) ->
	
		_notifications = []
		
# Add a notification to be displayed.
		
		@add = (notification) -> _notifications.push notification
		
# Get the top notification.
		
		@top = -> _notifications[0]
		
# Remove the top notification.
		
		@removeTop = -> _notifications.shift()
		
# The number of notifications to show.
		
		@count = -> _notifications.length

# Accept notifications from the server.
		
		socket.on 'notifications', (data) ->
			
			_notifications.push.apply _notifications, data.notifications
			
		return
		
]
