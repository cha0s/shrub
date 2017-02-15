# # User - Forgot password
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubRpcRoutes`.
  registrar.registerHook 'shrubRpcRoutes', ->

    Promise = require 'bluebird'

    config = require 'config'

    nodemailer = require 'shrub-nodemailer'
    orm = require 'shrub-orm'

    crypto = require 'server/crypto'

    {Limiter, LimiterMiddleware} = require 'shrub-limiter'

    routes = []

    routes.push

      path: 'shrub-user/local/forgot'

      middleware: [

        'shrub-http-express/session'
        'shrub-villiany'

        new LimiterMiddleware(
          threshold: Limiter.threshold(1).every(30).seconds()
        )

        (req, res, next) ->

          # Cancel promise flow if the user doesn't exist.
          class NoSuchUser extends Error
            constructor: (@message) ->

          # Look up the user.
          Promise.resolve().then(->

            # Search for username or encrypted email.
            if -1 is req.body.usernameOrEmail.indexOf '@'

              iname: req.body.usernameOrEmail.toLowerCase()

            else

              crypto.encrypt(
                req.body.usernameOrEmail.toLowerCase()

              ).then (encryptedEmail) -> email: encryptedEmail

          ).then((filter) ->

            # Find the local user.
            orm.collection('shrub-user-local').findOne filter

          ).then((@localUser) ->
            throw new NoSuchUser unless @localUser?

            # Generate a one-time login token.
            crypto.randomBytes 24

          ).then((token) ->

            @localUser.resetPasswordToken = token.toString 'hex'

            # Decrypt the user's email address.
            crypto.decrypt @localUser.email

          ).then((email) ->

            # Send an email to the user's email with a one-time login link.
            siteHostname = config.get 'packageSettings:shrub-core:siteHostname'
            siteUrl = "http://#{siteHostname}"

            scope =

              email: email

              # ###### TODO: HTTPS
              loginUrl: "#{siteUrl}/user/reset/#{localUser.resetPasswordToken}"

              siteUrl: siteUrl

              user: @localUser

            nodemailer.sendMail(
              'shrub-user-local-email-forgot'
            ,
              to: email
              subject: 'Password recovery request'
            ,
              scope
            )

            @localUser.save()

          ).then(-> res.end()).catch(NoSuchUser, -> res.end()).catch next

      ]

    return routes