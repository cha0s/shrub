# # Angular sandbox
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAngularAppRun`.
  #
  # Hang up any sandbox if we don't need it anymore.
  registrar.registerHook 'shrubAngularAppRun', -> [
    '$window', 'shrub-rpc'
    ($window, rpc) ->

      # Hang up the socket unless it's the local (Node.js) client.
      unless $window.navigator.userAgent.match /^Node\.js .*$/
        rpc.call 'shrub-angular-sandbox/hangup'

  ]