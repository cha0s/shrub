# # HTML5 audio
config = require 'config'

exports.pkgmanRegister = (registrar) ->

  registrar.registerHook 'shrubAngularProvider', -> [

    ->

      audioFiles = config.get 'packageConfig:shrub-html5-audio:files'

      _deferred = {}

      provider = {}

      provider.isFileDeferred = (filename) -> _deferred[filename]?

      provider.setFileDeferred = (filename) -> _deferred[filename] = true

      provider.$get = [
        '$q', '$window'
        ($q, $window) ->

          service = {}

          # ###### TODO: Configure filetype priorities per browser.
          service.loadFile = (filename) ->

            unless audioFiles[filename]?
              return $q.reject new Error "Tried to load an audio file `#{filename}', but it wasn't registered."

            unless angular.isArray extsOrPromise = audioFiles[filename]
              return extsOrPromise

            audioFiles[filename] = new $q (resolve, reject) ->

              audio = $window.document.createElement 'audio'
              audio.src = "/audio/#{filename}.#{extsOrPromise[0]}"
              audio.onerror = (e) -> reject e ? $window.error
              audio.addEventListener 'loadeddata', -> resolve audio

          service.playFile = (filename) ->
            @loadFile(filename).then (audio) -> audio.play()

          # Load audio files that aren't marked as deferred.
          for filename, extensions of audioFiles
            continue if provider.isFileDeferred filename
            service.loadFile filename

          return service

      ]

      return provider

  ]