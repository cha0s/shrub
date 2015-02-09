
exports.pkgmanRegister = (registrar) ->

  # ## Implements hook `appConfig`
  registrar.registerHook 'appConfig', -> [
    'shrub-html5-notificationProvider'
    (notificationProvider) ->

      # Shrub defaults.
      notificationProvider.setOptions(
        icon: '/img/shrub.png'
        lang: 'en'
      )

  ]

  # ## Implements hook `provider`
  registrar.registerHook 'provider', -> [
    'NotificationProvider'
    (NotificationProvider) ->

      provider = {}

      # Forward.
      provider.setOptions = (options) ->
        NotificationProvider.setOptions options

      # I am not really a fan of using new as an API here.
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
