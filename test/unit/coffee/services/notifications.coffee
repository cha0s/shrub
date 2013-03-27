describe 'notifications', ->
	
	notifications = null
	
	beforeEach ->
		
		inject (_notifications_) -> notifications = _notifications_
		
	it 'should allow adding and removing notifications', ->
		
		notifications.addNotification text: 'Testing'
		expect(notifications.topNotification().text).toBe 'Testing'
		expect(notifications.count()).toBe 1
		
		notifications.removeTopNotification()
		expect(notifications.topNotification()).toBe undefined
		expect(notifications.count()).toBe 0
		
	it 'should accept notification batches from the socket', ->
		
		inject ($timeout, socket) ->
			
			socket.stimulateOn(
				'notifications'
				notifications: [
					text: 'Testing'
				,
					text: 'Testing'
				,
					text: 'Testing'
				,
					text: 'Testing'
				]
			)
			$timeout.flush()

			expect(notifications.count()).toBe 4
