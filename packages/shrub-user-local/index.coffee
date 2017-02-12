# Local user authentication.

clientModule = require './client'

# *ORM collection and passport strategy for local authentication.*

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubUserRedactors`.
  registrar.registerHook 'shrubUserRedactors', ->

    'shrub-user-local': [

      (object, user) ->

        crypto = require 'server/crypto'

        delete object.iname
        delete object.plaintext if object.plaintext?
        delete object.salt
        delete object.passwordHash
        delete object.resetPasswordToken

        Promise.resolve().then ->
          return unless object.email?

          # Different redacted means full email redaction.
          if user.id isnt object.user
            delete object.email
            return

          # Decrypt the e-mail if redacting for the same user.
          crypto.decrypt(object.email).then (email) ->
            object.email = email

    ]

  # #### Implements hook `shrubOrmCollections`.
  registrar.registerHook 'shrubOrmCollections', ->

    crypto = require 'server/crypto'

    autoIname = (values, cb) ->
      values.iname = values.name.toLowerCase()
      cb()

    # Invoke the client hook implementation.
    collections = clientModule.shrubOrmCollections()

    {
      'shrub-user-local': UserLocal
    } = collections

    UserLocal.beforeCreate = autoIname
    UserLocal.beforeUpdate = autoIname

    # Case-insensitivized name.
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

    UserLocal.attributes.toJSON = ->
      O = @toObject()
      O.groups = @groups
      O.permissions = @permission
      O

    # ## UserLocal#register
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

    UserLocal.redactors = [(redactFor) ->
      self = this

      delete self.iname
      delete self.plaintext if self.plaintext?
      delete self.salt
      delete self.passwordHash
      delete self.resetPasswordToken

      Promise.resolve().then ->
        return unless self.email?

        # Different user means full email redaction.
        if redactFor.id isnt self.id
          delete self.email
          return

        # Decrypt the e-mail if redacting for the same user.
        crypto.decrypt(self.email).then (email) ->
          self.email = email

    ]

    collections

  registrar.recur [
    'forgot', 'login', 'register', 'reset'
  ]
