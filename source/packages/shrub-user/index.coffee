# User
```coffeescript
```
*User operations.*
```coffeescript
Promise = null

{Middleware} = require 'middleware'

orm = null

clientModule = require './client'

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubCorePreBootstrap`.
```coffeescript
  registrar.registerHook 'shrubCorePreBootstrap', ->

    Promise = require 'bluebird'

    orm = require 'shrub-orm'
```
#### Implements hook `shrubConfigClient`.
```coffeescript
  registrar.registerHook 'shrubConfigClient', (req) ->
```
Send a redacted version of the request user.
```coffeescript
    req.user.redactObject 'shrub-user', req.user if req.user?
```
#### Implements hook `shrubConfigServer`.
```coffeescript
  registrar.registerHook 'shrubConfigServer', ->

    beforeLoginMiddleware: [
      'shrub-user'
    ]

    afterLoginMiddleware: [
    ]

    beforeLogoutMiddleware: [
      'shrub-user'
    ]

    afterLogoutMiddleware: [
    ]
```
#### Implements hook `shrubUserRedactors`.
```coffeescript
  registrar.registerHook 'shrubUserRedactors', ->

    'shrub-user': [
      (object, user) ->

        redacted =
          id: object.id
```
###### TODO: Include/merge permissions.
```coffeescript
        for group in object.groups

          (redacted.groups ?= []).push group.name
```
Redact instances.
```coffeescript
        return Promise.all(

          for instance in object.instances
            user.redactObject instance.model, instance

        ).then (instances) ->

          redacted.instances = instances

          return redacted

    ]
```
#### Implements hook `shrubAuditFingerprint`.
```coffeescript
  registrar.registerHook 'shrubAuditFingerprint', (req) ->
```
User (ID).
```coffeescript
    user: if req?.user?.id? then req.user.id
```
#### Implements hook `shrubOrmCollections`.
```coffeescript
  registrar.registerHook 'shrubOrmCollections', ->
```
Invoke the client hook implementation.
```coffeescript
    collections = clientModule.shrubOrmCollections()

    {
      'shrub-group': Group
      'shrub-group-permission': GroupPermission
      'shrub-user': User
      'shrub-user-group': UserGroup
      'shrub-user-permission': UserPermission
    } = collections
```
Store case-insensitive name.
```coffeescript
    autoIname = (values, cb) ->
      values.iname = values.name.toLowerCase()
      cb()

    Group.beforeCreate = autoIname
    Group.beforeUpdate = autoIname
```
Case-insensitive name.
```coffeescript
    Group.attributes.iname =
      type: 'string'
      size: 24
      index: true
```
Disable the default createdAt/updatedAt attributes.
```coffeescript
    Group.autoCreatedAt = false
    Group.autoUpdatedAt = false
```
Disable the default createdAt/updatedAt attributes.
```coffeescript
    GroupPermission.autoCreatedAt = false
    GroupPermission.autoUpdatedAt = false
```
## User.findOnePopulated

* (object) `where` - Query conditions.

*Find a user in the system and fully populate it.*
```coffeescript
    User.findOnePopulated = (where) ->
      @findOne(where).populateAll().then (user) -> user?.populateAll()
```
## User#populateAll

*Fully populate a user.*
```coffeescript
    User.attributes.populateAll = ->
      self = this
```
Populate permissions.
```coffeescript
      @permissions = @permissions.map ({permission}) -> permission
```
Load and populate groups.
```coffeescript
      Group_ = orm.collection 'shrub-group'

      groupsPromise = Promise.all(

        Group_.findOne(id: group).populateAll() for {group}, index in @groups

      ).then (groups) -> self.groups[index] = group for group, index in groups
```
Load and populate user instances.
```coffeescript
      instancesPromise = Promise.all(

        for instance, index in @instances
          Model = orm.collection instance.model
          Model.findOne id: instance.modelId

      ).then (models) ->

        for model, index in models
          model.user = self.id
          model.model = self.instances[index].model
          self.instances[index] = model

      Promise.all([
        groupsPromise
        instancesPromise
      ]).then -> self

    redactors = null
```
## User#redactObject

* (string) `type` - The type of object to redact.

* (object) `object` - The object to redact.

*Redact an object based on a user's permission.*
```coffeescript
    User.attributes.redactObject = (type, object) ->
      self = this

      pkgman = require 'pkgman'
```
Collect redactors.

###### TODO: Caching.
```coffeescript
      unless redactors?
        redactors = {}
```
#### Invoke hook `shrubUserRedactors`.
```coffeescript
        for redactorTypes in pkgman.invokeFlat 'shrubUserRedactors'
          for type_, redactors_ of redactorTypes
            (redactors[type_] ?= []).push redactors_...
```
No redactors? Just promise the original object.
```coffeescript
      return Promise.resolve object if redactors[type].length is 0
```
Walk down the list of redactors promising and returning them serially.
```coffeescript
      promise = Promise.resolve object
      for redactor in redactors[type]
        promise = do (redactor) -> promise.then (redacted) ->
          Promise.cast redactor object, self

      return promise
```
## User#toJSON

*Render the user as a POD object.*
```coffeescript
    User.attributes.toJSON = ->
      O = @toObject()

      O.groups = @groups
      O.permissions = @permissions
      O.instances = @instances

      O
```
Disable the default createdAt/updatedAt attributes.
```coffeescript
    UserGroup.autoCreatedAt = false
    UserGroup.autoUpdatedAt = false
```
## UserGroup#populateAll

*Fully populate a user group.*
```coffeescript
    UserGroup.attributes.populateAll = ->
      self = this

      Group_ = orm.collection 'shrub-group'
      Group_.findOne(id: self.group).populateAll().then (group_) ->
        self.group = group_

        return self
```
Disable the default createdAt/updatedAt attributes.
```coffeescript
    UserPermission.autoCreatedAt = false
    UserPermission.autoUpdatedAt = false

    collections
```
#### Implements hook `shrubTransmittableErrors`.
```coffeescript
  registrar.registerHook 'shrubTransmittableErrors', clientModule.shrubTransmittableErrors
```
#### Implements hook `shrubUserBeforeLoginMiddleware`.
```coffeescript
  registrar.registerHook 'shrubUserBeforeLoginMiddleware', ->

    label: 'Join user channel'
    middleware: [
      (req, next) ->
        return next() unless req.socket.join?
        req.socket.join "user/#{req.loggingInUser.id}", next
    ]
```
#### Implements hook `shrubUserBeforeLogoutMiddleware`.
```coffeescript
  registrar.registerHook 'shrubUserBeforeLogoutMiddleware', ->

    label: 'Tell client to log out, and leave the user channel'
    middleware: [

      (req, next) ->
        return next() unless req.socket.emit?
```
Tell client to log out.
```coffeescript
        req.socket.emit 'shrub-user/logout'
        next()

      (req, next) ->
        return next() unless req.socket.leave?
```
Leave the user channel.
```coffeescript
        if req.user.id?
          req.socket.leave "user/#{req.loggingOutUser.id}", next
        else
          next()

    ]

  registrar.recur [
    'login'
  ]
```
