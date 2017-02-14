# Local user authentication.

orm = null
Promise = null

clientModule = require './client'

# *ORM collection and passport strategy for local authentication.*

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubCorePreBootstrap`.
  registrar.registerHook 'shrubCorePreBootstrap', ->

    orm = require 'shrub-orm'
    Promise = require 'bluebird'

  # #### Implements hook `shrubUserLoginStrategies`.
  registrar.registerHook 'shrubUserLoginStrategies', ->
    strategy = clientModule.shrubUserLoginStrategies()

    LocalStrategy = require('passport-local').Strategy
    UserLocal = orm.collection 'shrub-user-local'

    # Implement a local passport strategy.
    options = passReqToCallback: true

    verifyCallback = (req, username, password, done) ->

      crypto = require 'server/crypto'
      errors = require 'errors'

      # Find a local user and compare the hashed password.
      Promise.cast(
        UserLocal.findOne iname: username
      ).bind({}).then((@localUser) ->

        # Not found? Generic login error.
        throw errors.instantiate 'shrub-user-local-login' unless @localUser

        # ###### TODO: Any way to automate this?
        @localUser.model = 'shrub-user-local'

        # Hash the input password for comparison.
        crypto.hasher(
          plaintext: password
          salt: new Buffer @localUser.salt, 'hex'
        )

      ).then((hashed) ->

        # Hash mismatch (wrong password)? Generic login error.
        throw errors.instantiate(
          'shrub-user-local-login'
        ) if @localUser.passwordHash isnt hashed.key.toString 'hex'

        # Return the local user instance.
        return @localUser

      ).nodeify done

    # Implement a [Passport](http://passportjs.org/) login strategy.
    passportStrategy = new LocalStrategy options, verifyCallback
    passportStrategy.name = 'shrub-user-local'
    strategy.passportStrategy = passportStrategy

    return strategy

  # #### Implements hook `shrubUserRedactors`.
  registrar.registerHook 'shrubUserRedactors', ->

    'shrub-user-local': [

      (object, user) ->

        redacted =
          model: object.model
          createdAt: object.createdAt
          updatedAt: object.updatedAt
          name: object.name

        # Different user means full email redaction.
        return redacted if user.id isnt object.user

        # Decrypt the e-mail if redacting for the same user.
        require('server/crypto').decrypt(object.email).then (email) ->
          redacted.email = email
          return redacted

    ]

  # #### Implements hook `shrubOrmCollections`.
  registrar.registerHook 'shrubOrmCollections', ->

    crypto = require 'server/crypto'

    # Invoke the client hook implementation.
    collections = clientModule.shrubOrmCollections()

    {
      'shrub-user-local': UserLocal
    } = collections

    # Store case-insensitive name.
    autoIname = (values, cb) ->
      values.iname = values.name.toLowerCase()
      cb()

    UserLocal.beforeCreate = autoIname
    UserLocal.beforeUpdate = autoIname

    # Case-insensitive name.
    UserLocal.attributes.iname =
      type: 'string'
      size: 24
      index: true

    # Hash of the plaintext password.
    UserLocal.attributes.passwordHash =
      type: 'string'

    # A token which can be used to reset the user's password (once).
    UserLocal.attributes.resetPasswordToken =
      type: 'string'
      size: 48
      index: true

    # A 512-bit salt used to cryptographically hash the user's password.
    UserLocal.attributes.salt =
      type: 'string'
      size: 128

    # ## UserLocal#associatedUser
    #
    # ###### TODO: This should be in a superclass.
    #
    # *Get the user (if any) associated with this instance.*
    UserLocal.attributes.associatedUser = ->
      {
        'shrub-user-instance': UserInstance
        'shrub-user': User
      } = orm.collections()

      UserInstance.findOne(
        model: 'shrub-user-local'
        modelId: @id
      ).then (userInstance) -> User.findOnePopulated id: userInstance?.user

    # ## UserLocal.register
    #
    # * (string) `name` - Name of the new user.
    #
    # * (string) `email` - Email address of the new user.
    #
    # * (string) `password` - The new user's password.
    #
    # *Register a user in the system.*
    UserLocal.register = (name, email, password) ->

      @create(name: name).then((localUser) ->

        # Encrypt the email.
        crypto.encrypt(email.toLowerCase()).then((encryptedEmail) ->

          localUser.email = encryptedEmail

          # Set the password encryption details.
          crypto.hasher plaintext: password

        ).then((hashed) ->

          localUser.plaintext = hashed.plaintext
          localUser.salt = hashed.salt.toString 'hex'
          localUser.passwordHash = hashed.key.toString 'hex'

          # Generate a one-time login token.
          crypto.randomBytes 24

        ).then((token) ->

          localUser.resetPasswordToken = token.toString 'hex'
          localUser.save()

        ).then -> return localUser
      )

    collections

  # #### Implements hook `shrubTransmittableErrors`.
  registrar.registerHook 'shrubTransmittableErrors', clientModule.shrubTransmittableErrors

  registrar.recur [
    'forgot', 'register', 'reset'
  ]
