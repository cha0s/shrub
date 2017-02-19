# UI - Notifications

```coffeescript
Promise = null

orm = null

notificationQueues = {}

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubCorePreBootstrap`](../../hooks#shrubcoreprebootstrap)

```coffeescript
  registrar.registerHook 'shrubCorePreBootstrap', ->

    Promise = require 'bluebird'

    orm = require 'shrub-orm'
```

#### Implements hook [`shrubCoreBootstrapMiddleware`](../../hooks#shrubcorebootstrapmiddleware)

```coffeescript
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    pkgman = require 'pkgman'

    label: 'Register notification queues'
    middleware: [

      (next) ->
```

#### Invoke hook [`shrubUiNotificationQueues`](../../hooks#shrubuinotificationqueues)

```coffeescript
        for path, queues of pkgman.invoke 'shrubUiNotificationQueues'
          for name, queue of queues
            notificationQueues[pkgman.normalizePath name] = queue

        next()

    ]
```

Broadcast a notification event.

```coffeescript
  broadcastNotificationsEvent = (req, args) ->

    {manager: socketManager} = require 'shrub-socket'

    {data, event, includeSelf, notifications} = args
    data ?= {}
```

Broadcast for each queue.

```coffeescript
    queueMap = {}
    for notification in notifications
      queueMap[notification.queue] ?= []
      queueMap[notification.queue].push notification.id

    for queueName, ids of queueMap
      queue = notificationQueues[queueName]
      channel = queue.channelFromRequest req

      data.ids = ids
      data.queue = queueName

      if includeSelf
        socketManager().broadcast channel, event, data
      else
        req.socket.broadcast.to(channel).emit event, data
```

#### Implements hook [`shrubOrmCollections`](../../hooks#shrubormcollections)

```coffeescript
  registrar.registerHook 'shrubOrmCollections', ->
```

## Notification

```coffeescript
    Notification =

      attributes:
```

## Notification#acknowledged

*Has the notification been acknowledged?*

```coffeescript
        acknowledged:
          type: 'boolean'
          defaultsTo: false
```

## Notification#markedAsRead

*Has the notification been read?*

```coffeescript
        markedAsRead:
          type: 'boolean'
          defaultsTo: false
```

## Notification#mayRemove

*May this notification be removed?*

```coffeescript
        mayRemove:
          type: 'boolean'
          defaultsTo: true
```

## Notification#channel

*Which channel owns this notification? Built by the queue.*

```coffeescript
        channel: 'string'
```

## Notification#path

*To where does this notification link?*

```coffeescript
        path: 'string'
```

## Notification#queue

*To which queue does this notification belong?*

```coffeescript
        queue:
          type: 'string'
          notEmpty: true
```

## Notification#variables

*Variables, can be any type.*

```coffeescript
        variables: 'json'
```

## Notification#createFromRequest

* (http.IncomingMessage) `req` - The request object.

* (String) `queueName` - The name of the queue.

* (Object) `variables` - Arbitrary data. Defaults to `{}`.

* (String) `path` - Path this notification links to. Defaults to

`'javascript:void(0)'`.

* (Boolean) `mayRemove` - May this notification be removed from the
queue by

the user? Defaults to `true`. *Create a notification from a request
object.*

```coffeescript
      createFromRequest: (req, queueName, variables, path, mayRemove) ->
```

Check that the queue is valid.

```coffeescript
        unless queue = notificationQueues[queueName]
          return Promise.reject new Error(
            "Notification queue `#{queue}' doesn't exist."
          )
```

Defaults.

```coffeescript
        mayRemove ?= true
        path ?= 'javascript:void(0)'
        variables ?= {}
```

Get the channel from the request.

```coffeescript
        return unless (channel = queue.channelFromRequest req)?
```

Create the notification.

```coffeescript
        @create(
          mayRemove: mayRemove
          channel: channel
          path: path
          queue: queueName
          variables: variables

        ).then (notification) ->
          return unless req.socket?
```

Broadcast to others.

```coffeescript
          notification.redactFor(req.user).then (notification) ->
            broadcastNotificationsEvent(
              req
              data: notifications: [notification]
              event: 'shrub-ui/notifications'
              includeSelf: true
              notifications: [notification]
            )
```

## Notification#queueFromRequest

* (http.IncomingMessage) `req` - The request object.

*Get a queue's notifications from a request.*

```coffeescript
      queueFromRequest: (req) ->
```

Empty queue if none was defined.

```coffeescript
        unless (queue = notificationQueues[req.body.queue])?
          return Promise.resolve []

        unless (channel = queue.channelFromRequest req)?
          return Promise.resolve []
```

Return the 20 newest notifications from the queue for the request's
channel, skipping as many records as requested.

```coffeescript
        query = @find()
        query = query.where(channel: channel)
        query = query.where(queue: req.body.queue)
        query = query.skip(req.body.skip ? 0)
        query = query.limit(20)
        query.sort('createdAt DESC')
```

Redact the notifications before sending them over the wire.

```coffeescript
        query.then (notifications) ->
          Promise.all(
            notifications.map (notification) ->
              notification.redactFor req.user
          )
```

Remove unnecessary details.

```coffeescript
      redactors: [(redactFor) ->
        self = this

        delete self.channel
        delete self.updatedAt

      ]

    'shrub-ui-notification': Notification
```

#### Implements hook [`shrubConfigClient`](../../hooks#shrubconfigclient)

```coffeescript
  registrar.registerHook 'shrubConfigClient', (req) ->
```

Make sure ORM is up (it won't be when grunt is running).

```coffeescript
    return unless Notification = orm?.collection 'shrub-ui-notification'
```

Get all the notification queues.

```coffeescript
    promiseKeys = []
    promises = for key, queue of notificationQueues
      promiseKeys.push key

      (req.body ?= {}).queue = key
      Notification.queueFromRequest req
```

Load any queues into the config.

```coffeescript
    Promise.all(promises).then (notificationsList) ->
      queuesConfig = null

      for notifications, index in notificationsList
        continue if notifications.length is 0
```

Reverse the notifications because the client will prepend new
notifications, not append.

```coffeescript
        queuesConfig ?= {}
        queuesConfig[promiseKeys[index]] = notifications.reverse()

      queuesConfig
```

Ensure that the requested notification is owned by the request.

```coffeescript
  ensureNotificationsOwnedByRequest = (req, res, next) ->

    Notification = orm.collection 'shrub-ui-notification'
    Notification.findById(req.body.ids).then((notifications) ->

      for notification in notifications
        return next new Error(
          "Notification queue `#{notification.queue}' doesn't exist."
        ) unless queue = notificationQueues[notification.queue]

        return next new Error(
          "You don't own those notifications."
        ) unless notification.channel is queue.channelFromRequest req

      req.notifications = notifications
      next()

    ).catch next
```

#### Implements hook [`shrubRpcRoutes`](../../hooks#shrubrpcroutes)

```coffeescript
  registrar.registerHook 'shrubRpcRoutes', ->

    routes = []

    routes.push

      path: 'shrub-ui/notifications/acknowledged'

      middleware: [
```

Ensure that the queue exists.

```coffeescript
        (req, res, next) ->
          return next new Error(
            "Notification queue `#{req.body.queue}' doesn't exist."
          ) unless queue = notificationQueues[req.body.queue]

          req.queue = queue
          next()

        (req, res, next) ->
```

Mark all notifications in a queue owned by the request as
acknowledged.

```coffeescript
          Notification = orm.collection 'shrub-ui-notification'
          query = Notification.find()
          query = query.where(channel: req.queue.channelFromRequest req)
          query = query.where(queue: req.body.queue)
          query.then((notifications) ->
```

Broadcast to others.

```coffeescript
            broadcastNotificationsEvent(
              req
              event: 'shrub-ui/notifications/acknowledged'
              notifications: notifications
            )

            Promise.all(
              for notification in notifications
                notification.acknowledged = true
                notification.save()
            )

          ).then(-> res.end()).catch next

      ]

    routes.push

      path: 'shrub-ui/notifications/markAsRead'

      middleware: [

        ensureNotificationsOwnedByRequest

        (req, res, next) ->
```

Broadcast to others.

```coffeescript
          broadcastNotificationsEvent(
            req
            data: markedAsRead: req.body.markedAsRead
            event: 'shrub-ui/notifications/markAsRead'
            notifications: req.notifications
          )

          Promise.all(
            for notification in req.notifications
              notification.markedAsRead = req.body.markedAsRead
              notification.save()

          ).then(-> res.end()).catch next

      ]

    routes.push

      path: 'shrub-ui/notifications/remove'

      middleware: [

        ensureNotificationsOwnedByRequest
```

Ensure that the requested notifications may be removed.

```coffeescript
        (req, res, next) ->

          for notification in req.notifications
            return next new Error(
              'Those notifications may not be removed.'
            ) unless notification.mayRemove

          next()

        (req, res, next) ->
```

Broadcast to others.

```coffeescript
          broadcastNotificationsEvent(
            req
            event: 'shrub-ui/notifications/remove'
            notifications: req.notifications
          )

          Promise.all(
            for notification in req.notifications
              notification.destroy()

          ).then(-> res.end()).catch next

      ]

    routes.push

      path: 'shrub-ui/notifications'

      middleware: (req, res, next) ->

        Notification = orm.collection 'shrub-ui-notification'
        Notification.queueFromRequest(req).then((notifications) ->

          res.end notifications

        ).catch next

    return routes
```
