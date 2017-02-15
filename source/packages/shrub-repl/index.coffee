# REPL

*Runs a REPL and allows packages to add values to its context.*
```coffeescript
CoffeeScript = require 'coffee-script'
fs = require 'fs'
net = require 'net'
replServer = require 'repl'

config = require 'config'
pkgman = require 'pkgman'

debug = require('debug') 'shrub:repl'
```
The socket server.
```coffeescript
server = null

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubConfigServer`.
```coffeescript
  registrar.registerHook 'shrubConfigServer', ->
```
The prompt display for REPL clients.
```coffeescript
    prompt: 'shrub> '
```
The location of the socket.
```coffeescript
    socket: "#{__dirname}/socket"
```
Use a CoffeeScript REPL?
```coffeescript
    useCoffee: true
```
#### Implements hook `shrubCoreProcessExit`.
```coffeescript
  registrar.registerHook 'shrubCoreProcessExit', -> server?.close()
```
#### Implements hook `shrubCoreBootstrapMiddleware`.
```coffeescript
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    orm = require 'shrub-orm'

    label: 'REPL'
    middleware: [

      (next) ->

        settings = config.get 'packageSettings:shrub-repl'

        server = net.createServer (socket) ->
```
#### Invoke hook `shrubReplContext`.
```coffeescript
          pkgman.invoke 'shrubReplContext', context = {}
```
REPL server options.
```coffeescript
          opts =
            prompt: settings.prompt
            input: socket
            output: socket
            ignoreUndefined: true
```
CoffeeScript?
```coffeescript
          if settings.useCoffee

            opts.prompt = "(coffee) #{settings.prompt}"
```
Define our own eval function, using CoffeeScript.
```coffeescript
            opts.eval = (cmd, context, filename, callback) ->
```
Handle blank lines correctly.
```coffeescript
              return callback null, undefined if cmd is '(\n)'
```
Forward the input to CoffeeScript for evalulation.
```coffeescript
              try

                callback null, CoffeeScript.eval(
                  cmd
                  sandbox: context
                  filename: filename
                )

              catch error

                callback error
```
Spin up the server, inject the values from `shrubReplContext`, and
prepare for later cleanup.
```coffeescript
          repl = replServer.start opts
          repl.context[key] = value for key, value of context
          repl.on 'exit', -> socket.end()
```
Try to be tidy about things.
```coffeescript
        fs.unlink settings.socket, (error) ->
```
Ignore the error if it's just saying the socket didn't exist.
```coffeescript
          return next error if error.code isnt 'ENOENT' if error?
```
Bind the REPL server socket.
```coffeescript
          server.listen settings.socket, (error) ->
            return next error if error?
            debug "REPL server listening at #{settings.socket}"
            next()

    ]
```
