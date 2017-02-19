# UI - Notifications item

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubAngularDirective`](../../../../hooks#shrubangulardirective)

```coffeescript
  registrar.registerHook 'shrubAngularDirective', -> [
    'shrub-ui/notifications', 'shrub-rpc'
    (notifications, rpc) ->

      directive = {}

      directive.candidateKeys = [
        ['queueName', 'notification.type']
        'notification.type'
        'queueName'
      ]

      directive.link = (scope, element) ->
```

Remove the notification from the queue.

```coffeescript
        scope.remove = ($event) ->
          $event.stopPropagation()

          ids = [scope.notification.id]
          rpc.call(
            'shrub-ui/notifications/remove'
            ids: ids
          )
          index = scope.queue.remove ids
```

Toggle the notification's marked-as-read state.

```coffeescript
        scope.toggleMarkedAsRead = ($event) ->
          $event.stopPropagation()

          scope.markAsRead(
            scope.notification, not scope.notification.markedAsRead
          )
```

Watch the marked-as-read state and make some changes.

```coffeescript
        scope.$watch 'notification.markedAsRead', (markedAsRead) ->

          if markedAsRead
            element.addClass 'marked-as-read'
            scope.iconClass = 'glyphicon-check'
            scope.title = 'Mark as unread'
          else
            element.removeClass 'marked-as-read'
            scope.iconClass = 'glyphicon-eye-open'
            scope.title = 'Mark as read'

      directive.scope = true

      directive.template = '''

<a
  data-ng-click="remove($event)"
  data-ng-if="notification.mayRemove"
>
  <span
    class="remove glyphicon glyphicon-remove"
    tabindex="0"
    title="Remove"
  ></span>
</a>

<a
  data-ng-click="toggleMarkedAsRead($event)"
>
  <span
    class="mark-as-read glyphicon"
    data-ng-class="iconClass"
    tabindex="0"
    title="{{title}}"
  ></span>
</a>

<div
  data-ng-bind="notification.variables | json"
></div>

'''

      directive

  ]
```
