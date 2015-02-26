# HTML5 notifications

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubAngularAppConfig`.

      registrar.registerHook 'shrubAngularAppConfig', -> [
        'shrub-html5-notificationProvider'
        (notificationProvider) ->

Shrub defaults.

          notificationProvider.setOptions(
            icon: '/img/shrub.png'
            lang: 'en'
          )

      ]

#### Implements hook `shrubAngularProvider`.

      registrar.registerHook 'shrubAngularProvider', -> [
        'NotificationProvider'
        (NotificationProvider) ->

          provider = {}

Forward.

          provider.setOptions = (options) ->
            NotificationProvider.setOptions options

I am not really a fan of using new as an API here.

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
