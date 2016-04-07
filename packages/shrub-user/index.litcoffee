# User

*User operations.*

    passport = null
    Promise = null

    {Middleware} = require 'middleware'

    {monkeyPatchLogin} = require './login'

    orm = null

    clientModule = require './client'

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubCorePreBootstrap`.

      registrar.registerHook 'shrubCorePreBootstrap', ->

        passport = require 'passport'
        Promise = require 'bluebird'

        orm = require 'shrub-orm'

#### Implements hook `shrubConfigClient`.

      registrar.registerHook 'shrubConfigClient', (req) ->

Send a redacted version of the request user.

        req.user.redactFor req.user if req.user?

#### Implements hook `shrubAuditFingerprint`.

      registrar.registerHook 'shrubAuditFingerprint', (req) ->

User (ID).

        user: if req?.user?.id? then req.user.id

#### Implements hook `shrubHttpMiddleware`.

      registrar.registerHook 'shrubHttpMiddleware', ->

        label: 'Load user using passport'
        middleware: userMiddleware()

#### Implements hook `shrubOrmCollections`.

      registrar.registerHook 'shrubOrmCollections', ->

        crypto = require 'server/crypto'

        autoIname = (values, cb) ->
          values.iname = values.name.toLowerCase()
          cb()

Invoke the client hook implementation.

        collections = clientModule.shrubOrmCollections()

        {
          'shrub-group': Group
          'shrub-group-permission': GroupPermission
          'shrub-user': User
          'shrub-user-group': UserGroup
          'shrub-user-permission': UserPermission
        } = collections

###### TODO: Finish collections doc.

Case-insensitivized name.

        Group.attributes.iname =
          type: 'string'
          size: 24
          index: true

        Group.autoCreatedAt = false
        Group.autoUpdatedAt = false

        Group.beforeCreate = autoIname
        Group.beforeUpdate = autoIname

        GroupPermission.autoCreatedAt = false
        GroupPermission.autoUpdatedAt = false

        User.beforeCreate = autoIname
        User.beforeUpdate = autoIname

Case-insensitivized name.

        User.attributes.iname =
          type: 'string'
          size: 24
          index: true

Hash of the plaintext password.

        User.attributes.passwordHash =
          type: 'string'

A token which can be used to reset the user's password (once).

        User.attributes.resetPasswordToken =
          type: 'string'
          size: 48
          index: true

A 512-bit salt used to cryptographically hash the user's password.

        User.attributes.salt =
          type: 'string'
          size: 128

Update a user's last accessed time. Return the user for chaining.

        User.attributes.touch = ->
          @lastAccessed = (new Date()).toISOString()
          this

        User.attributes.populateAll = ->
          self = this

          Group_ = orm.collection 'shrub-group'

          @permissions = @permissions.map ({permission}) -> permission

          promises = for {group}, index in @groups
            do (group, index) ->
              Group_.findOne(id: group).populateAll().then (group_) ->
                self.groups[index] = group_

          Promise.all(promises).then -> self

        User.attributes.toJSON = ->
          O = @toObject()
          O.groups = @groups
          O.permissions = @permission
          O

## User#register

* (string) `name` - Name of the new user.
* (string) `email` - Email address of the new user.
* (string) `password` - The new user's password.

*Register a user in the system.*

        User.register = (name, email, password) ->

          @create(name: name).then((user) ->

Encrypt the email.

            crypto.encrypt(email.toLowerCase()).then((encryptedEmail) ->

              user.email = encryptedEmail

Set the password encryption details.

              crypto.hasher plaintext: password

            ).then((hashed) ->

              user.plaintext = hashed.plaintext
              user.salt = hashed.salt.toString 'hex'
              user.passwordHash = hashed.key.toString 'hex'

Generate a one-time login token.

              crypto.randomBytes 24

            ).then (token) ->

              user.resetPasswordToken = token.toString 'hex'

              user.save()
          )

        User.redactors = [(redactFor) ->
          self = this

          delete self.iname
          delete self.plaintext if self.plaintext?
          delete self.salt
          delete self.passwordHash
          delete self.resetPasswordToken

          for group in self.groups

            for permission in group.permissions ? []

              delete permission.group
              delete permission.id

            delete group.iname
            delete group.id

          Promise.resolve().then ->
            return unless self.email?

Different redacted means full email redaction.

            if redactFor.id isnt self.id
              delete self.email
              return

Decrypt the e-mail if redacting for the same user.

            crypto.decrypt(self.email).then (email) ->
              self.email = email

        ]

        UserGroup.autoCreatedAt = false
        UserGroup.autoUpdatedAt = false

        UserGroup.attributes.populateAll = ->
          self = this

          Group_ = orm.collection 'shrub-group'
          Group_.findOne(id: self.group).populateAll().then (group_) ->
            self.group = group_

            return self

        UserGroup.attributes.depopulateAll = ->
          @group = @group.id

          return this

        UserPermission.autoCreatedAt = false
        UserPermission.autoUpdatedAt = false

        collections

#### Implements hook `shrubOrmCollectionsAlter`.

      registrar.registerHook 'shrubOrmCollectionsAlter', (collections) ->
        clientModule.shrubOrmCollectionsAlter collections

        for identity, collection of collections
          do (identity, collection) ->

            collection.redactors ?= []
            collection.attributes.redactFor = (user) ->
              redacted = @toJSON()
              redacted.toJSON = undefined

              Promise.all(
                for redactor in collection.redactors
                  redactor.call redacted, user
              ).then -> redacted

#### Implements hook `shrubConfigServer`.

      registrar.registerHook 'shrubConfigServer', ->

        beforeLoginMiddleware: []

        afterLoginMiddleware: []

        beforeLogoutMiddleware: [
          'shrub-user'
        ]

        afterLogoutMiddleware: [
          'shrub-user'
        ]

#### Implements hook `shrubRpcRoutesAlter`.

      registrar.registerHook 'shrubRpcRoutesAlter', (routes) ->

        {spliceRouteMiddleware} = require 'shrub-rpc'

        loadUserMiddleware = (req, res, next) ->

          req.loadUser = (done) -> req.loadSession ->

            userMiddleware_ = new Middleware()
            for fn in userMiddleware()
              userMiddleware_.use fn

            userMiddleware_.dispatch req, res, (error) ->
              return next error if error?
              done()

          next()

        loadUserMiddleware.weight = -4999

        for path, route of routes
          route.middleware.unshift loadUserMiddleware
          spliceRouteMiddleware route, 'shrub-user', userMiddleware()

        return

#### Implements hook `shrubSocketConnectionMiddleware`.

      registrar.registerHook 'shrubSocketConnectionMiddleware', ->

        label: 'Load user using passport'

Join a channel for the username.

        middleware: userMiddleware().concat (req, res, next) ->

          return req.socket.join req.user.name, next if req.user.id?

          next()

#### Implements hook `shrubUserBeforeLogoutMiddleware`.

      registrar.registerHook 'shrubUserBeforeLogoutMiddleware', ->

        label: 'Tell client to log out, and leave the user channel'
        middleware: [

          (req, next) ->

            return next() unless req.socket?

Tell client to log out.

            req.socket.emit 'shrub-user/logout'

Leave the user channel.

            if req.user.id?
              req.socket.leave req.user.name, next
            else
              next()

        ]

#### Implements hook `shrubUserAfterLogoutMiddleware`.

      registrar.registerHook 'shrubUserAfterLogoutMiddleware', ->

        label: 'Instantiate anonymous user'
        middleware: [

          (req, next) ->
            req.instantiateAnonymous().then(-> next()).catch next

        ]

      registrar.recur [
        'forgot', 'login', 'logout', 'register', 'reset'
      ]

## loadByName

(string) `name` - The name of the user to load.

*Load a user by name.*

    exports.loadByName = (name) ->

      User = orm.collection 'shrub-user'
      User.findOne(iname: name.toLowerCase()).populateAll()

    userMiddleware = -> [

      (req, res, next) ->

        req.instantiateAnonymous = ->

          @user = orm.collection('shrub-user').instantiate()

Add to anonymous group.

          @user.groups = [
            orm.collection('shrub-user-group').instantiate group: 2
          ]

          @user.populateAll()

        next()

Passport middleware.

      passport.initialize()
      passport.session()

Monkey patch.

      monkeyPatchLogin

Set the user into the request.

      (req, res, next) ->
        promise = if req.user?
          Promise.resolve()
        else
          req.instantiateAnonymous()

        promise.then(-> next()).catch next

Save the user at the end of the request.

      (req, res, next) ->

        end = res.end
        res.end = (data, encoding) ->
          res.end = end

          return res.end data, encoding unless req.user.id

          req.user.save().finally -> res.end data, encoding

        next()

    ]
