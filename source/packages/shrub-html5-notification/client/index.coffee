# HTML5 notifications

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubAngularAppConfig`](../../../hooks#shrubangularappconfig)

```coffeescript
  registrar.registerHook 'shrubAngularAppConfig', -> [
    'shrub-html5-notificationProvider'
    (notificationProvider) ->
```

Shrub defaults.

```coffeescript
      notificationProvider.setOptions(
        icon: '/img/shrub.png'
        lang: 'en'
      )

  ]
```

#### Implements hook [`shrubAngularProvider`](../../../hooks#shrubangularprovider)

```coffeescript
  registrar.registerHook 'shrubAngularProvider', -> [
    'NotificationProvider'
    (NotificationProvider) ->

      provider = {}
```

Forward.

```coffeescript
      provider.setOptions = (options) ->
        NotificationProvider.setOptions options
```

I am not really a fan of using new as an API here.

```coffeescript
      provider.$get = [
        'Notification'
        (Notification) ->

          service = {}

          service.create = (title, options) ->
            new Notification title, options

          service
      ]

      provider

  ]
```
