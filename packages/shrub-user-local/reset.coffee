# # User - Password reset
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubRpcRoutes`.
  registrar.registerHook 'shrubRpcRoutes', ->

    crypto = require 'server/crypto'

    Promise = require 'bluebird'

    {Limiter, LimiterMiddleware} = require 'shrub-limiter'
    orm = require 'shrub-orm'

    routes = []

    routes.push

      path: 'shrub-user/local/reset'

      middleware: [

        'shrub-http-express/session'
        'shrub-villiany'

        new LimiterMiddleware(
          threshold: Limiter.threshold(1).every(5).minutes()
        )

        (req, res, next) ->

          User =

          # Cancel promise flow if the user doesn't exist.
          class NoSuchUser extends Error
            constructor: (@message) ->

          # Look up the user.
          Promise.cast(
            orm.collection('shrub-user-local').findOne(
              resetPasswordToken: req.body.token
            )
          ).bind({}).then((@localUser) ->
            throw new NoSuchUser unless @localUser?

            # Recalculate the password hashing details.
            crypto.hasher plaintext: req.body.password

          ).then((hashed) ->

            @localUser.passwordHash = hashed.key.toString 'hex'
            @localUser.salt = hashed.salt.toString 'hex'
            @localUser.resetPasswordToken = null

            @localUser.save()

          ).then(-> res.end()).catch(NoSuchUser, -> res.end()).catch next
      ]

    return routes