# # UI - Notifications title
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAngularDirective`.
  registrar.registerHook 'shrubAngularDirective', -> [
    'shrub-ui/notifications', 'shrub-rpc'
    (notifications, rpc) ->

      directive = {}

      directive.candidateKeys = [
        'queueName'
      ]

      directive.link = (scope) ->

        _ = require 'lodash'

        # Mark all notifications as read.
        scope.markAllRead = ->
          notAlreadyRead = _.filter(
            scope.queue.notifications()
            (notification) -> not notification.markedAsRead
          )

          # Early out if there's nothing to do.
          return if notAlreadyRead.length is 0

          # Mark notifications as read, and tell the server.
          scope.queue.markAsRead ids = _.map(
            notAlreadyRead, (notification) -> notification.id
          )

          rpc.call(
            'shrub-ui/notifications/markAsRead'
            ids: ids
            markedAsRead: true

          )

      directive.scope = true

      directive.template = '''

<a
  class="mark-all-read"
  data-ng-click="markAllRead()"
>Mark all read</a>

<p
  class="title"
>Notifications</p>

'''

      directive

  ]
