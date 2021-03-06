# # HTML5 local storage
#
# *Provide an Angular service to consume the HTML5 localStorage API.*
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAngularAppConfig`.
  registrar.registerHook 'shrubAngularAppConfig', -> [
    'shrub-html5-local-storageProvider'
    (localStorageProvider) ->

      # Set a default prefix and turn off all notification.
      localStorageProvider.setPrefix 'shrub'
      localStorageProvider.setNotify false, false

  ]

  # #### Implements hook `shrubAngularProvider`.
  registrar.registerHook 'shrubAngularProvider', -> [
    'localStorageServiceProvider'
    (localStorageServiceProvider) ->

      provider = {}

      # Forward all methods.
      for staticMethod in [
        'setPrefix', 'setStorageType', 'setStorageCookie'
        'setStorageCookieDomain', 'setNotify'
      ]
        do (staticMethod) -> provider[staticMethod] = ->
          localStorageServiceProvider[staticMethod] arguments...

      provider.$get = [
        'localStorageService'
        (localStorageService) ->

          service = {}

          for method in [
            'isSupported', 'getStorageType', 'set', 'add', 'get'
            'keys', 'remove', 'clearAll', 'bind', 'deriveKey'
            'length'
          ]
            do (method) -> service[method] = ->
              localStorageService[method] arguments...

          service.cookie = {}
          for cookieMethod in [
            'isSupported', 'set', 'get', 'add', 'remove'
            'clearAll'
          ]
            do (method) -> service.cookie[method] = ->
              localStorageService.cookie[method] arguments...

          service
      ]

      provider

  ]