# # Configuration
#
# *Gathers configuration and serves it as an Angular module for clients.*
_ = require 'lodash'
Promise = require 'bluebird'
url = require 'url'

config = require 'config'
pkgman = require 'pkgman'

{Config} = require 'client/modules/config'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAssetsMiddleware`.
  registrar.registerHook 'shrubAssetsMiddleware', ->

    label: 'Config'
    middleware: [

      (assets, next) ->

        assets.scripts.push '/js/config.js'

        next()

    ]

  # #### Implements hook `shrubHttpMiddleware`.
  registrar.registerHook 'shrubHttpMiddleware', (http) ->

    label: 'Serve package configuration'
    middleware: [

      # Serve the configuration module.
      (req, res, next) ->

        # Only if the path matches.
        return next() unless req.url is '/js/config.js'

        exports.renderPackageConfig(req).then((code) ->

          # Emit the configuration module.
          res.setHeader 'Content-Type', 'text/javascript'
          res.send code

        ).catch next

    ]

# ## shrub-config.renderPackageConfig
#
# * (http.IncomingRequest) `req` - The request object.
#
# Use a client's request object to render configuration.
exports.renderPackageConfig = (req) ->

  # #### Invoke hook `shrubConfigClient`.
  #
  # Allows packages to specify configuration that will be sent to the client.
  # Implementations may return an object, or a promise that resolves to an
  # object.
  subconfigs = pkgman.invoke 'shrubConfigClient', req

  Promise.all(

    promise for path, promise of subconfigs

  ).then (fulfilledSubconfigs) ->

    config_ = new Config()

    # Package-independent...
    config_.set 'packageList', config.get 'packageList'

    # Merge in the subconfigs.
    index = 0
    for path of subconfigs

      subconfig = fulfilledSubconfigs[index++]
      for key, value of subconfig
        continue unless value?

        config_.set "packageConfig:#{
          path.replace /\//g, ':'
        }:#{
          key.replace /\//g, ':'
        }", value

    # #### Invoke hook `shrubConfigClientAlter`.
    pkgman.invoke 'shrubConfigClientAlter', req, config_

    # Format the configuration to look nice.
    prettyPrintConfig = ->

      jsonArgs = [config_]

      if 'production' isnt config.get 'NODE_ENV'
        jsonArgs = jsonArgs.concat [null, '  ']

      stringified = JSON.stringify jsonArgs...
      [first, rest...] = stringified.split '\n'
      ([first].concat rest.map (line) -> '    ' + line).join '\n'

    """
angular.module('shrub.config', ['shrub.require']).config([
  'shrub-requireProvider', function(requireProvider) {
    requireProvider.require('config').from(#{prettyPrintConfig()});
  }
]);
  """