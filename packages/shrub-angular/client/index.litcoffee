# Communicate with Angular on the server

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `appRun`.

Hang up any sandbox if we don't need it anymore.

      registrar.registerHook 'appRun', -> [
        '$window', 'shrub-rpc'
        ($window, rpc) ->

Hang up the socket unless it's the local (Node.js) client.

          unless $window.navigator.userAgent.match /^Node\.js .*$/
            rpc.call 'shrub-angular/hangup'

      ]
