# # Core server functionality
#
# *Coordinate various core functionality.*
config = require 'config'

pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubConfigClient`.
  registrar.registerHook 'shrubConfigClient', (req) ->

    # The URL that the site was accessed at.
    hostname: if req.headers?.host?
      "//#{req.headers.host}"
    else
      "//#{config.get 'packageSettings:shrub-core:siteHostname'}"

    # Is the server running in test mode?
    testMode: if (config.get 'E2E')? then 'e2e' else false

    # The process ID of this worker.
    pid: process.pid if 'production' isnt config.get 'NODE_ENV'

    # Execution environment, `production`, or...
    environment: config.get 'NODE_ENV'

    # The user-visible site name.
    siteName: config.get 'packageSettings:shrub-core:siteName'

  # #### Implements hook `shrubAuditFingerprint`.
  registrar.registerHook 'shrubAuditFingerprint', (req) ->

    # The IP address.
    ip: req?.normalizedIp

  # #### Implements hook `shrubHttpMiddleware`.
  registrar.registerHook 'shrubHttpMiddleware', (http) ->

    label: 'Normalize request variables'
    middleware: [

      # Normalize IP address.
      (req, res, next) ->

        req.normalizedIp = trustedAddress(
          req.connection.remoteAddress
          req.headers['x-forwarded-for']
        )

        next()

    ]

  # #### Implements hook `shrubConfigServer`.
  registrar.registerHook 'shrubConfigServer', ->

    # Middleware for server bootstrap phase.
    bootstrapMiddleware: [
      'shrub-orm'
      'shrub-install'
      'shrub-http-express/session'
      'shrub-http'
      'shrub-socket'
      'shrub-rpc'
      'shrub-passport'
      'shrub-passport/logout'
      'shrub-angular'
      'shrub-ui/notifications'
      'shrub-nodemailer'
      'shrub-repl'
    ]

    # Global site crypto key.
    cryptoKey: '***CHANGE THIS***'

    # The default hostname of this application. Includes port if any.
    siteHostname: 'localhost:4201'

    # The name of the site, used in various places.
    siteName: 'Shrub example application'

    # A list of the IP addresses of trusted proxies between clients.
    trustedProxies: []

    # The amount of workers to create. Defaults to 0 meaning no workers, only
    # the master.
    workers: 0

  # #### Implements hook `shrubRpcRoutesAlter`.
  #
  # Patch in express-specific variables that will be required by middleware.
  registrar.registerHook 'shrubRpcRoutesAlter', (routes) ->

    coreMiddleware = (req, res, next) ->

      req.headers = req.socket.request.headers

      req.normalizedIp = trustedAddress(
        req.socket.client.conn.remoteAddress
        req.headers['x-forwarded-for']
      )

      next()

    coreMiddleware.weight = -10000

    route.middleware.unshift coreMiddleware for path, route of routes

    return

  # #### Implements hook `shrubSocketConnectionMiddleware`.
  registrar.registerHook 'shrubSocketConnectionMiddleware', ->

    label: 'Normalize request variables'
    middleware: [

      # Normalize IP address.
      (req, res, next) ->

        req.normalizedIp = trustedAddress(
          req.socket.client.conn.remoteAddress
          req.headers['x-forwarded-for']
        )

        next()

    ]

trustedAddress = (address, forwardedFor) -> resolveAddress(
  config.get 'packageSettings:shrub-core:trustedProxies'
  address
  forwardedFor
)

# Walk up the X-Forwarded-For header until we hit an untrusted address.
resolveAddress = (trustedProxies, address, forwardedFor) ->
  return address unless forwardedFor?
  return address if trustedProxies.length is 0

  split = forwardedFor.split /\s*, */
  index = split.length - 1
  address = split[index--] while ~trustedProxies.indexOf address

  address