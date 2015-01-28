
# # Notifications

config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		'$compile', '$timeout', 'shrub-rpc', 'shrub-ui/notifications'
		($compile, $timeout, rpc, notifications) ->
		
			directive = {}
			
			directive.candidateKeys = [
				'queueName'
			]
			
			directive.link = (scope, element, attr) ->
				
				# Put the queue name into the scope.
				scope.queueName = attr.queueName
				scope.queue = notifications.queue scope.queueName
					
				# Initialize the popover.
				($button = element.find 'button').popover
					
					container: 'body'
					content: -> element.find '.notifications'
					html: true	
					placement: 'bottom'
					template: """

<div class="popover popover-notifications popover-#{attr.queueName}" role="tooltip">
	<div class="arrow"></div>
	<div class="popover-title"></div>
	<div class="popover-content"></div>
</div>

"""
					title: ->
						
						tpl = """

<div
	class="title"
	data-shrub-ui-notifications-title
></div>

"""

						$compile(tpl)(scope)
						
				# When the notifications are opened, acknowledge them.
				$button.on 'click', ->

				# When the notifications are opened, acknowledge them.
				$button.on 'show.bs.popover', ->
					return unless scope.unacknowledged

					# Tell the server.
					rpc.call(
						'shrub.ui.notifications.acknowledged'
						queue: attr.queueName
					)
					
					# Mark client notifications as acknowledged.
					for notification in scope.queue
						notification.acknowledged = true
						
					return

				# Wait for the new queue to be compiled into the DOM, and then
				# reposition the popover, since the new content may shift it.
				scope.$watch(
					'queue'
					(queue) -> scope.$$postDigest ->
						return unless (pop = $button.data 'bs.popover').$tip?
						return unless pop.$tip.hasClass 'in'
						pop.applyPlacement(
							pop.getCalculatedOffset(
								'bottom', pop.getPosition()
								pop.$tip[0].offsetWidth
								pop.$tip[0].offsetHeight
							)
							'bottom'
						)
					true
				)
				
				# Mark the notification as read.				
				scope.markAsRead = (notification, markedAsRead) ->
					return if markedAsRead is notification.markedAsRead
					
					notification.markedAsRead = markedAsRead
					
					rpc.call(
						'shrub.ui.notifications.markAsRead'
						ids: [notification.id]
						markedAsRead: markedAsRead
					
					)
					
				# Hide the popover when any notification is clicked. Feel free
				# to catch the `shrub.ui.notification.clicked` event in your
				# skinLink implementation.
				scope.notificationClicked = ($event, notification) ->
					
					scope.$emit(
						'shrub.ui.notification.clicked'
						$event, notification
					)
					
					# Angular doesn't like when you return DOM elements.
					return
					
				# Close the popover.
				scope.close = -> $button.popover 'hide'
						
				# Set up default behavior on a click event, and provide the
				# deregistration function to any skinLink consumers.
				scope.$deregisterDefaultClickHandler = scope.$on(
					'shrub.ui.notification.clicked'
					($event, $clickEvent, notification) ->
						
						# Close the popover.
						scope.close()
					
						# Mark the notification as read.
						scope.markAsRead notification, true
				)
				
				# Keep track of unread items.
				scope.$watch 'queue', (queue) ->
					unacknowledged = queue.filter (notification) ->
						not notification.acknowledged
						
					scope.unacknowledged = if unacknowledged.length > 0
						unacknowledged.length
					else
						undefined
				, true
			
			directive.scope = {}
			
			directive.template = """

<div
	class="notifications-container"
>

	<button>
		!
		<span
			class="unacknowledged"
			data-ng-bind="unacknowledged"
			data-ng-if="unacknowledged > 0"
		></span>
	</button>
	
	<div
		data-ng-hide="true"
	>
		
		<div
			class="notifications"
			data-ng-class="classes"
		>
	
			<ul>
			
				<li
					data-ng-if="!!queue.length"
					data-ng-repeat="notification in queue"
				>
					<a
						data-shrub-ui-notifications-item
						data-notification="notification"
						data-ng-href="{{notification.path}}"
						data-ng-click="notificationClicked($event, notification)"
					>
					</a>
				</li>
				
				<li
					data-ng-if="!queue.length"
				>
					<a
						href="javascript:void(0)"
					>
						There's nothing here yet...
					</a>
				</li>
			</ul>
		</div>
	</div>
</div>

"""
			
			directive
			
	]
	
	# ## Implements hook `service`
	registrar.registerHook 'service', -> [
		'$q', 'shrub-rpc', 'shrub-socket'
		($q, rpc, socket) ->
		
			service = {}
			
			_notifications = {}
			
			# ## notifications.list
			# 
			# Get a queue of notifications.
			service.queue = (queue) ->
				
				_notifications[queue] ?= new NotificationQueue()
				_notifications[queue].notifications()
				
			# ## notifications.loadMore
			# 
			# Load more notifications
			service.loadMore = (queue, skip) ->
				
				rpc.call(
					'shrub.ui.notifications'
					queue: queue
					skip: skip
				
				).then (notifications) ->
					
					_notifications[queue] ?= new NotificationQueue()
					_notifications[queue].add notifications
				
			# Add in initial notifications from config.
			for queue, notifications of config.get(
				'packageConfig:shrub-ui:notifications'
			)
				_notifications[queue] ?= new NotificationQueue()
				_notifications[queue].add notifications
			
			# Accept notifications from the server.
			socket.on 'shrub.ui.notifications', (data) ->
				{queue, notifications} = data
				
				_notifications[queue] ?= new NotificationQueue()
				_notifications[queue].add notifications
				
			# Remove notifications.
			socket.on 'shrub.ui.notifications.remove', (data) ->
				{queue, ids} = data
				
				_notifications[queue] ?= new NotificationQueue()
				_notifications[queue].remove ids
				
			# Mark notifications as read.
			socket.on 'shrub.ui.notifications.markAsRead', (data) ->
				{queue, ids, markedAsRead} = data
				
				_notifications[queue] ?= new NotificationQueue()
				_notifications[queue].markAsRead ids, markedAsRead
				
			service
			
	]

	registrar.recur [
		'item', 'title'
	]

class NotificationQueue

	constructor: ->
		
		@_notifications = []
		@_notificationsIndex = {}
	
	add: (notifications) ->
	
		for notification in notifications
			
			@_notifications.unshift notification
			@_notificationsIndex[notification.id] = notification
			
		return
		
	remove: (ids) ->
	
		for id in ids
			continue unless notification = @_notificationsIndex[id]
			
			index = @_notifications.indexOf notification
			@_notifications.splice index, 1
			delete @_notificationsIndex[id]
		
		return
	
	notifications: -> @_notifications
	
	markAsRead: (ids, markedAsRead) ->

		for id in ids
			continue unless notification = @_notificationsIndex[id]
			notification.markAsRead = markedAsRead
		
		return
	
