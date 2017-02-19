Local user authentication.

```coffeescript
orm = null
Promise = null

clientModule = require './client'
```

*ORM collection and passport strategy for local authentication.*

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubCorePreBootstrap`](../../hooks#shrubcoreprebootstrap)

```coffeescript
  registrar.registerHook 'shrubCorePreBootstrap', ->

    orm = require 'shrub-orm'
    Promise = require 'bluebird'
```

#### Implements hook [`shrubUserLoginStrategies`](../../hooks#shrubuserloginstrategies)

```coffeescript
  registrar.registerHook 'shrubUserLoginStrategies', ->
    strategy = clientModule.shrubUserLoginStrategies()

    LocalStrategy = require('passport-local').Strategy
    UserLocal = orm.collection 'shrub-user-local'
```

Implement a local passport strategy.

```coffeescript
    options = passReqToCallback: true

    verifyCallback = (req, username, password, done) ->

      crypto = require 'server/crypto'
      errors = require 'errors'
```

Find a local user and compare the hashed password.

```coffeescript
      Promise.cast(
        UserLocal.findOne iname: username
      ).bind({}).then((@localUser) ->
```

Not found? Generic login error.

```coffeescript
        throw errors.instantiate 'shrub-user-local-login' unless @localUser
```

###### TODO: Any way to automate this?

```coffeescript
        @localUser.model = 'shrub-user-local'
```

Hash the input password for comparison.

```coffeescript
        crypto.hasher(
          plaintext: password
          salt: new Buffer @localUser.salt, 'hex'
        )

      ).then((hashed) ->
```

Hash mismatch (wrong password)? Generic login error.

```coffeescript
        throw errors.instantiate(
          'shrub-user-local-login'
        ) if @localUser.passwordHash isnt hashed.key.toString 'hex'
```

Return the local user instance.

```coffeescript
        return @localUser

      ).nodeify done
```

Implement a [Passport](http://passportjs.org/) login strategy.

```coffeescript
    passportStrategy = new LocalStrategy options, verifyCallback
    passportStrategy.name = 'shrub-user-local'
    strategy.passportStrategy = passportStrategy

    return strategy
```

#### Implements hook [`shrubUserRedactors`](../../hooks#shrubuserredactors)

```coffeescript
  registrar.registerHook 'shrubUserRedactors', ->

    'shrub-user-local': [

      (object, user) ->

        redacted =
          model: object.model
          createdAt: object.createdAt
          updatedAt: object.updatedAt
          name: object.name
```

Different user means full email redaction.

```coffeescript
        return redacted if user.id isnt object.user
```

Decrypt the e-mail if redacting for the same user.

```coffeescript
        require('server/crypto').decrypt(object.email).then (email) ->
          redacted.email = email
          return redacted

    ]
```

#### Implements hook [`shrubOrmCollections`](../../hooks#shrubormcollections)

```coffeescript
  registrar.registerHook 'shrubOrmCollections', ->

    crypto = require 'server/crypto'
```

Invoke the client hook implementation.

```coffeescript
    collections = clientModule.shrubOrmCollections()

    {
      'shrub-user-local': UserLocal
    } = collections
```

Store case-insensitive name.

```coffeescript
    autoIname = (values, cb) ->
      values.iname = values.name.toLowerCase()
      cb()

    UserLocal.beforeCreate = autoIname
    UserLocal.beforeUpdate = autoIname
```

Case-insensitive name.

```coffeescript
    UserLocal.attributes.iname =
      type: 'string'
      size: 24
      index: true
```

Hash of the plaintext password.

```coffeescript
    UserLocal.attributes.passwordHash =
      type: 'string'
```

A token which can be used to reset the user's password (once).

```coffeescript
    UserLocal.attributes.resetPasswordToken =
      type: 'string'
      size: 48
      index: true
```

A 512-bit salt used to cryptographically hash the user's password.

```coffeescript
    UserLocal.attributes.salt =
      type: 'string'
      size: 128
```

## UserLocal#associatedUser

###### TODO: This should be in a superclass.

*Get the user (if any) associated with this instance.*

```coffeescript
    UserLocal.attributes.associatedUser = ->
      {
        'shrub-user-instance': UserInstance
        'shrub-user': User
      } = orm.collections()

      UserInstance.findOne(
        model: 'shrub-user-local'
        modelId: @id
      ).then (userInstance) -> User.findOnePopulated id: userInstance?.user
```

## UserLocal.register

* (string) `name` - Name of the new user.

* (string) `email` - Email address of the new user.

* (string) `password` - The new user's password.

*Register a user in the system.*

```coffeescript
    UserLocal.register = (name, email, password) ->

      @create(name: name).then((localUser) ->
```

Encrypt the email.

```coffeescript
        crypto.encrypt(email.toLowerCase()).then((encryptedEmail) ->

          localUser.email = encryptedEmail
```

Set the password encryption details.

```coffeescript
          crypto.hasher plaintext: password

        ).then((hashed) ->

          localUser.plaintext = hashed.plaintext
          localUser.salt = hashed.salt.toString 'hex'
          localUser.passwordHash = hashed.key.toString 'hex'
```

Generate a one-time login token.

```coffeescript
          crypto.randomBytes 24

        ).then((token) ->

          localUser.resetPasswordToken = token.toString 'hex'
          localUser.save()

        ).then -> return localUser
      )

    collections
```

#### Implements hook [`shrubTransmittableErrors`](../../hooks#shrubtransmittableerrors)

```coffeescript
  registrar.registerHook 'shrubTransmittableErrors', clientModule.shrubTransmittableErrors

  registrar.recur [
    'forgot', 'register', 'reset'
  ]
```
