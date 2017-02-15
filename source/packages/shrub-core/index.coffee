# Core server functionality

*Coordinate various core functionality.*
```coffeescript
config = require 'config'

pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubConfigClient`.
```coffeescript
  registrar.registerHook 'shrubConfigClient', (req) ->
```
The URL that the site was accessed at.
```coffeescript
    hostname: if req.headers?.host?
      "//#{req.headers.host}"
    else
      "//#{config.get 'packageSettings:shrub-core:siteHostname'}"
```
Is the server running in test mode?
```coffeescript
    testMode: if (config.get 'E2E')? then 'e2e' else false
```
The process ID of this worker.
```coffeescript
    pid: process.pid if 'production' isnt config.get 'NODE_ENV'
```
Execution environment, `production`, or...
```coffeescript
    environment: config.get 'NODE_ENV'
```
The user-visible site name.
```coffeescript
    siteName: config.get 'packageSettings:shrub-core:siteName'
```
#### Implements hook `shrubAuditFingerprint`.
```coffeescript
  registrar.registerHook 'shrubAuditFingerprint', (req) ->
```
The IP address.
```coffeescript
    ip: req?.normalizedIp
```
#### Implements hook `shrubHttpMiddleware`.
```coffeescript
  registrar.registerHook 'shrubHttpMiddleware', (http) ->

    label: 'Normalize request variables'
    middleware: [
```
Normalize IP address.
```coffeescript
      (req, res, next) ->

        req.normalizedIp = trustedAddress(
          req.connection.remoteAddress
          req.headers['x-forwarded-for']
        )

        next()

    ]
```
#### Implements hook `shrubConfigServer`.
```coffeescript
  registrar.registerHook 'shrubConfigServer', ->
```
Middleware for server bootstrap phase.
```coffeescript
    bootstrapMiddleware: [
      'shrub-orm'
      'shrub-install'
      'shrub-http-express/session'
      'shrub-http'
      'shrub-socket'
      'shrub-rpc'
      'shrub-passport'
      'shrub-angular'
      'shrub-ui/notifications'
      'shrub-nodemailer'
      'shrub-repl'
    ]
```
Global site crypto key.
```coffeescript
    cryptoKey: '***CHANGE THIS***'
```
The default hostname of this application. Includes port if any.
```coffeescript
    siteHostname: 'localhost:4201'
```
The name of the site, used in various places.
```coffeescript
    siteName: 'Shrub example application'
```
A list of the IP addresses of trusted proxies between clients.
```coffeescript
    trustedProxies: []
```
The amount of workers to create. Defaults to 0 meaning no workers, only
the master.
```coffeescript
    workers: 0
```
#### Implements hook `shrubRpcRoutesAlter`.

Patch in express-specific variables that will be required by middleware.
```coffeescript
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
```
#### Implements hook `shrubSocketConnectionMiddleware`.
```coffeescript
  registrar.registerHook 'shrubSocketConnectionMiddleware', ->

    label: 'Normalize request variables'
    middleware: [
```
Normalize IP address.
```coffeescript
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
```
Walk up the X-Forwarded-For header until we hit an untrusted address.
```coffeescript
resolveAddress = (trustedProxies, address, forwardedFor) ->
  return address unless forwardedFor?
  return address if trustedProxies.length is 0

  split = forwardedFor.split /\s*, */
  index = split.length - 1
  address = split[index--] while ~trustedProxies.indexOf address

  address
```
