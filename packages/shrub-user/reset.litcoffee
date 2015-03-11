# User - Password reset

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubRpcRoutes`.

      registrar.registerHook 'shrubRpcRoutes', ->

        crypto = require 'server/crypto'

        Promise = require 'bluebird'

        {Limiter, LimiterMiddleware} = require 'shrub-limiter'
        orm = require 'shrub-orm'

        routes = []

        routes.push

          path: 'shrub-user/reset'

          middleware: [

            'shrub-http-express/session'
            'shrub-villiany'

            new LimiterMiddleware(
              threshold: Limiter.threshold(1).every(5).minutes()
            )

            (req, res, next) ->

              User = orm.collection 'shrub-user'

Cancel promise flow if the user doesn't exist.

              class NoSuchUser extends Error
                constructor: (@message) ->

Look up the user.

              Promise.cast(
                User.findOne resetPasswordToken: req.body.token
              ).bind({}).then((@user) ->
                throw new NoSuchUser unless @user?

Recalculate the password hashing details.

                crypto.hasher plaintext: req.body.password

              ).then((hashed) ->

                @user.passwordHash = hashed.key.toString 'hex'
                @user.salt = hashed.salt.toString 'hex'
                @user.resetPasswordToken = null

                @user.save()

              ).then(-> res.end()).catch(NoSuchUser, -> res.end()).catch next
          ]

        return routes
