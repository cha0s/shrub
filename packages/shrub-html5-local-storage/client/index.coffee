
exports.pkgmanRegister = (registrar) ->

  # ## Implements hook `appConfig`
  registrar.registerHook 'appConfig', -> [
    'shrub-html5-local-storageProvider'
    (localStorageProvider) ->

      localStorageProvider.setPrefix 'shrub'
      localStorageProvider.setNotify false, false

  ]

  # ## Implements hook `provider`
  registrar.registerHook 'provider', -> [
    'localStorageServiceProvider'
    (localStorageServiceProvider) ->

      provider = {}

      # Forward.
      for staticMethod in [
        'setPrefix', 'setStorageType', 'setStorageCookie'
        'setStorageCookieDomain', 'setNotify'
      ]
        do (staticMethod) -> provider[staticMethod] = ->
          localStorageServiceProvider[staticMethod] arguments...

      # Forward all the methods.
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
