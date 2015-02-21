# User - Registration

    orm = null

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `preBootstrap`.

      registrar.registerHook 'preBootstrap', ->

        orm = require 'shrub-orm'

#### Implements hook `endpoint`.

      registrar.registerHook 'endpoint', ->

        config = require 'config'

        nodemailer = require 'shrub-nodemailer'

        {Limiter} = require 'shrub-limiter'

        limiter:
          message: 'You are trying to register too much.'
          threshold: Limiter.threshold(5).every(2).minutes()

        route: 'shrub.user.register'

        receiver: (req, fn) ->

          {body} = req
          {email, password, username} = body

          {
            'shrub-ui-notification': Notification
            'shrub-user': User
          } = orm.collections()

Register a new user.

          User.register(username, email, password).then((user) ->

Send an email to the new user's email with a one-time login link.

            siteHostname = config.get 'packageSettings:shrub-core:siteHostname'
            siteUrl = "http://#{siteHostname}"

            scope =

              email: email

###### TODO: HTTPS

              loginUrl: "#{siteUrl}/user/reset/#{user.resetPasswordToken}"

              siteUrl: siteUrl

              user: user

            Notification.createFromRequest(
              req, 'shrubExampleGeneral'
              type: 'register'
              name: user.name
              email: email
            ).done()

            nodemailer.sendMail(
              'shrub-user-email-register'
            ,
              to: email
              subject: 'Registration details'
            ,
              scope
            ).done()

            return

          ).then(-> fn()).catch fn

#### Implements hook `replContext`.

      registrar.registerHook 'replContext', (context) ->
        orm = require 'shrub-orm'
        User = orm.collection 'shrub-user'
        context.registerUser = -> User.register arguments...
