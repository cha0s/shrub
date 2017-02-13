# # User

# *User operations.*
Promise = null

{Middleware} = require 'middleware'

orm = null

clientModule = require './client'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubCorePreBootstrap`.
  registrar.registerHook 'shrubCorePreBootstrap', ->

    Promise = require 'bluebird'

    orm = require 'shrub-orm'

  # #### Implements hook `shrubConfigClient`.
  registrar.registerHook 'shrubConfigClient', (req) ->

    # Send a redacted version of the request user.
    req.user.redactObject 'shrub-user', req.user if req.user?

  # #### Implements hook `shrubConfigServer`.
  registrar.registerHook 'shrubConfigServer', ->

    beforeLoginMiddleware: []

    afterLoginMiddleware: []

    beforeLogoutMiddleware: [
      'shrub-passport'
    ]

    afterLogoutMiddleware: [
    ]

  # #### Implements hook `shrubUserRedactors`.
  registrar.registerHook 'shrubUserRedactors', ->

    'shrub-user': [
      (object, user) ->

        redacted =
          id: object.id

        # ###### TODO: Include/merge permissions.

        for group in object.groups

          (redacted.groups ?= []).push group.name

        # Redact instances.
        return Promise.all(

          for instance in object.instances
            user.redactObject instance.model, instance

        ).then (instances) ->

          redacted.instances = instances

          return redacted

    ]

  # #### Implements hook `shrubAuditFingerprint`.
  registrar.registerHook 'shrubAuditFingerprint', (req) ->

    # User (ID).
    user: if req?.user?.id? then req.user.id

  # #### Implements hook `shrubOrmCollections`.
  registrar.registerHook 'shrubOrmCollections', ->

    autoIname = (values, cb) ->
      values.iname = values.name.toLowerCase()
      cb()

    # Invoke the client hook implementation.
    collections = clientModule.shrubOrmCollections()

    {
      'shrub-group': Group
      'shrub-group-permission': GroupPermission
      'shrub-user': User
      'shrub-user-group': UserGroup
      'shrub-user-permission': UserPermission
    } = collections

    # ###### TODO: Finish collections doc.
    #
    # Case-insensitivized name.
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

    User.findOnePopulated = (where) ->
      @findOne(where).populateAll().then (user) -> user.populateAll()

    User.instantiateAnonymous = ->
      user = @instantiate()

      # Add to anonymous group.
      user.groups = [
        orm.collection('shrub-user-group').instantiate group: 2
      ]

      user.populateAll()

    User.attributes.populateAll = ->
      self = this

      Group_ = orm.collection 'shrub-group'

      @permissions = @permissions.map ({permission}) -> permission

      groupPromises = Promise.all(

        Group_.findOne(id: group).populateAll() for {group}, index in @groups

      ).then (groups) -> self.groups[index] = group for group, index in groups

      instancePromises = Promise.all(

        for instance, index in @instances
          Model = orm.collection instance.model
          Model.findOne id: instance.modelId

      ).then (models) ->

        for model, index in models
          model.user = self.id
          model.model = self.instances[index].model
          self.instances[index] = model

      Promise.all(groupPromises, instancePromises).then -> self

    redactors = null
    User.attributes.redactObject = (type, object) ->
      self = this

      pkgman = require 'pkgman'

      # Collect redactors.
      #
      # ###### TODO: Caching.
      unless redactors?
        redactors = {}
        for redactorTypes in pkgman.invokeFlat 'shrubUserRedactors'
          for type_, redactors_ of redactorTypes
            (redactors[type_] ?= []).push redactors_...

      # No redactors? Just promise the original object.
      return Promise.resolve object if redactors[type].length is 0

      promise = Promise.resolve object

      for redactor in redactors[type]
        promise = do (redactor) -> promise.then (redacted) ->
          Promise.cast redactor object, self

      return promise

    User.attributes.toJSON = ->
      O = @toObject()

      O.groups = @groups
      O.permissions = @permissions
      O.instances = @instances

      O

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

  registrar.recur [
    'login'
  ]
