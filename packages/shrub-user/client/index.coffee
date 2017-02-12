# # User
#
# *User operations, model, etc.*
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubOrmCollections`.
  registrar.registerHook 'shrubOrmCollections', exports.shrubOrmCollections

  # #### Implements hook `shrubOrmCollectionsAlter`.
  registrar.registerHook 'shrubOrmCollectionsAlter', exports.shrubOrmCollectionsAlter

exports.shrubOrmCollections = ->

  Group =

    associations: [
      alias: 'permissions'
    ]

    attributes:

      name:
        type: 'string'
        size: 24
        maxLength: 24

      permissions:
        collection: 'shrub-group-permission'
        via: 'group'

  GroupPermission =

    attributes:

      permission: 'string'

      group: model: 'shrub-group'

  # ###### TODO: Finish collection docs.
  User =

    associations: [
      alias: 'groups'
    ,
      alias: 'instances'
    ,
      alias: 'permissions'
    ]

    attributes:

      # Groups this user belongs to.
      groups:
        collection: 'shrub-user-group'
        via: 'user'

      # User instances.
      instances:
        collection: 'shrub-user-instance'
        via: 'user'

      # Groups this user belongs to.
      permissions:
        collection: 'shrub-user-permission'
        via: 'user'

      # Check whether a user has a permission.
      hasPermission: (permission) ->

        # Superuser?
        return true if @id is 1

        # Check group permissions.
        for {permissions} in @groups
          return true if ~permissions.indexOf permission

        # Check inline permissions.
        return ~@permissions.indexOf permission

  UserGroup =

    attributes:

      group: model: 'shrub-group'

      user: model: 'shrub-user'

  UserInstance =

    attributes:

      model:
        type: 'string'
        size: '24'

      modelId:
        type: 'integer'

      user: model: 'shrub-user'

  UserPermission =

    attributes:

      permission: 'string'

      user: model: 'shrub-user'

  'shrub-group': Group
  'shrub-group-permission': GroupPermission
  'shrub-user': User
  'shrub-user-group': UserGroup
  'shrub-user-instance': UserInstance
  'shrub-user-permission': UserPermission
