# # User - Registration
orm = null

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubCorePreBootstrap`.
  registrar.registerHook 'shrubCorePreBootstrap', ->

    orm = require 'shrub-orm'

  # #### Implements hook `shrubRpcRoutes`.
  registrar.registerHook 'shrubRpcRoutes', ->

    config = require 'config'

    nodemailer = require 'shrub-nodemailer'

    {Limiter, LimiterMiddleware} = require 'shrub-limiter'

    routes = []

    routes.push

      path: 'shrub-user/local/register'

      middleware: [

        'shrub-http-express/session'
        'shrub-villiany'

        new LimiterMiddleware(
          message: 'You are trying to register too much.'
          threshold: Limiter.threshold(5).every(2).minutes()
        )

        (req, res, next) ->

          {body} = req
          {email, password, username} = body

          {
            'shrub-ui-notification': Notification
            'shrub-user-local': UserLocal
          } = orm.collections()

          # Register a new user.
          UserLocal.register(username, email, password).then((localUser) ->

            # Send an email to the new user's email with a one-time login
            # link.
            siteHostname = config.get 'packageConfig:shrub-core:siteHostname'
            siteUrl = "http://#{siteHostname}"

            scope =

              email: email

              # ###### TODO: HTTPS
              loginUrl: "#{siteUrl}/user/reset/#{user.resetPasswordToken}"

              siteUrl: siteUrl

              user: localUser

            Notification.createFromRequest(
              req, 'shrubExampleGeneral'
              type: 'register'
              name: localUser.name
              email: email
            ).done()

            nodemailer.sendMail(
              'shrub-user-local-email-register'
            ,
              to: email
              subject: 'Registration details'
            ,
              scope
            ).done()

            return

          ).then(-> res.end()).catch next
      ]

    return routes

    # #### Implements hook `shrubReplContext`.
    registrar.registerHook 'shrubReplContext', (context) ->
      orm = require 'shrub-orm'
      User = orm.collection 'shrub-user'
      context.registerUser = -> User.register arguments...