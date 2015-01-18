
# # Notifications

config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		'$timeout', 'shrub-ui/notifications'
		($timeout, notifications) ->
		
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

<div class="popover popover-#{attr.queueName}" role="tooltip">
	<div class="arrow"></div>
	<h3 class="popover-title"></h3>
	<div class="popover-content"></div>
</div>

"""

				# Wait for the new queue to be compiled into the DOM, and then
				# reposition the popover, since the new content may shift it.
				scope.$watch 'queue', (queue) -> scope.$$postDigest ->
					return unless (pop = $button.data 'bs.popover').$tip?
					pop.applyPlacement(
						pop.getCalculatedOffset(
							'bottom', pop.getPosition()
							pop.$tip[0].offsetWidth, pop.$tip[0].offsetHeight
						)
						'bottom'
					)
								
				# Hide the popover when any notification is clicked. Feel free
				# to override this in your skinLink implementation.
				scope.notificationClicked = (notification) ->
					$button.popover 'hide'
					
					# Angular doesn't like when you return DOM elements.
					return
			
			directive.scope = {}
			
			directive.template = """

<div
	data-ng-show="!!queue.length"
>

	<button>!</button>
	
	<div
		class="notifications-container"
		data-ng-hide="true"
	>
		
		<div
			class="notifications"
			data-ng-class="classes"
		>
	
			<div
				class="title"
				data-shrub-ui-notifications-title
			></div>
			
			<ul>
				<li
					data-ng-repeat="notification in queue"
				>
					<a
						data-shrub-ui-notifications-item
						data-notification="notification"
						data-ng-href="{{notification.path}}"
						data-ng-click="notificationClicked(notification)"
					>
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
			service.queue = (queue) -> _notifications[queue] ?= []
				
			# ## notifications.loadMore
			# 
			# Load more notifications
			service.loadMore = (queue, skip) ->
				rpc.call(
					'shrub.ui.notifications'
					queue: queue
					skip: skip
				
				).then (notifications) ->
					addNotifications queue, notifications
				
			# Accept notifications from the server.
			socket.on 'shrub.ui.notifications', (data) ->
				addNotifications data.queue, data.notifications
				
			# Add notifications into a queue.
			addNotifications = (queue, notifications) ->
				_notifications[queue] ?= []
				
				for notification in notifications
					_notifications[queue].unshift notification
					
				return
			
			# Add in initial notifications from config.
			for queue, notifications of config.get(
				'packageConfig:shrub-ui:notifications'
			)
				addNotifications queue, notifications
			
			service
			
	]

	registrar.recur [
		'item', 'title'
	]
