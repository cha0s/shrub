# # REPL
#
# *Runs a REPL and allows packages to add values to its context.*
CoffeeScript = require 'coffee-script'
fs = require 'fs'
net = require 'net'
replServer = require 'repl'

config = require 'config'
pkgman = require 'pkgman'

debug = require('debug') 'shrub:repl'

# The socket server.
server = null

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubConfigServer`.
  registrar.registerHook 'shrubConfigServer', ->

    # The prompt display for REPL clients.
    prompt: 'shrub> '

    # The location of the socket.
    socket: "#{__dirname}/socket"

    # Use a CoffeeScript REPL?
    useCoffee: true

  # #### Implements hook `shrubCoreProcessExit`.
  registrar.registerHook 'shrubCoreProcessExit', -> server?.close()

  # #### Implements hook `shrubCoreBootstrapMiddleware`.
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    orm = require 'shrub-orm'

    label: 'REPL'
    middleware: [

      (next) ->

        settings = config.get 'packageConfig:shrub-repl'

        server = net.createServer (socket) ->

          # #### Invoke hook `shrubReplContext`.
          pkgman.invoke 'shrubReplContext', context = {}

          # REPL server options.
          opts =
            prompt: settings.prompt
            input: socket
            output: socket
            ignoreUndefined: true

          # CoffeeScript?
          if settings.useCoffee

            opts.prompt = "(coffee) #{settings.prompt}"

            # Define our own eval function, using CoffeeScript.
            opts.eval = (cmd, context, filename, callback) ->

              # Handle blank lines correctly.
              return callback null, undefined if cmd is '(\n)'

              # Forward the input to CoffeeScript for evalulation.
              try

                callback null, CoffeeScript.eval(
                  cmd
                  sandbox: context
                  filename: filename
                )

              catch error

                callback error

          # Spin up the server, inject the values from `shrubReplContext`, and
          # prepare for later cleanup.
          repl = replServer.start opts
          repl.context[key] = value for key, value of context
          repl.on 'exit', -> socket.end()

        # Try to be tidy about things.
        fs.unlink settings.socket, (error) ->

          # Ignore the error if it's just saying the socket didn't exist.
          return next error if error.code isnt 'ENOENT' if error?

          # Bind the REPL server socket.
          server.listen settings.socket, (error) ->
            return next error if error?
            debug "REPL server listening at #{settings.socket}"
            next()

    ]