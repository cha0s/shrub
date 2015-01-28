# # Notifications title

_ = require 'lodash'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		'shrub-ui/notifications', 'shrub-rpc'
		(notifications, rpc) ->

			directive = {}

			directive.candidateKeys = [
				'queueName'
			]

			directive.link = (scope) ->

				# Mark all notifications as read.
				scope.markAllRead = ->
					notAlreadyRead = _.filter scope.queue, (notification) ->
						not notification.markedAsRead

					return if notAlreadyRead.length is 0

					rpc.call(
						'shrub.ui.notifications.markAsRead'
						ids: _.map(
							notAlreadyRead, (notification) -> notification.id
						)
						markedAsRead: true

					).then ->

						for notification in scope.queue
							notification.markedAsRead = true

						return

			directive.scope = true

			directive.template = """

<a
	class="mark-all-read"
	data-ng-click="markAllRead()"
>Mark all read</a>

<p
	class="title"
>Notifications</p>

"""

			directive

	]

