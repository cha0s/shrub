# # User
#
# *User operations, model, etc.*

{TransmittableError} = require 'errors'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubOrmCollections`.
  registrar.registerHook 'shrubOrmCollections', exports.shrubOrmCollections

  # #### Implements hook `shrubOrmCollectionsAlter`.
  registrar.registerHook 'shrubOrmCollectionsAlter', exports.shrubOrmCollectionsAlter

  # #### Implements hook `shrubAngularDirective`.
  registrar.registerHook 'actions', 'shrubAngularDirective', -> [
    'shrub-user'
    (user) ->

      directive = {}

      directive.link = (scope) ->

        scope.user = user

        scope.username = -> user.instance()?.instances?[0]?.name or 'Anonymous'

      directive.scope = {}

      directive.template = '''

<span class="user">
  <span
    class="username"
    data-ng-bind="username()"
  ></span>

  <span
    class="actions"
    data-ng-if="!user.isLoggedIn()"
  >
    [<a href="/user/login">Log in</a> · <a href="/user/register">Register</a>]
  </span>

  <span
    class="actions"
    data-ng-if="user.isLoggedIn()"
  >
    [<a href="/user/logout">Log out</a>]
  </span>

</span>

'''

      return directive

  ]

  # #### Implements hook `shrubAngularService`.
  registrar.registerHook 'shrubAngularService', -> [
    'shrub-orm', 'shrub-rpc', 'shrub-socket'
    (orm, rpc, socket) ->

      config = require 'config'

      User = orm.collection 'shrub-user'

      service = {}

      _instance = {}
      _instance[k] = v for k, v of User.instantiate(
        config.get 'packageConfig:shrub-user'
      )

      # Log a user out if we get a socket call.
      logout = ->

        blank = User.instantiate()
        delete _instance[k] for k of _instance
        _instance[k] = v for k, v of blank

        return

      socket.on 'shrub-user/logout', logout

      # ## user.isLoggedIn
      #
      # *Whether the current application user is logged in.*
      service.isLoggedIn = -> _instance.id?

      # ## user.login
      #
      # *Log in with strategy values.*
      service.login = (values) ->

        rpc.call('shrub-user/login', values).then (O) ->
          _instance[k] = v for k, v of O
          return

      # ## user.logout
      #
      # *Log out.*
      service.logout = ->

        rpc.call(
          'shrub-user/logout'

        ).then logout

      # ## user.instance
      #
      # *Retrieve the user instance.*
      service.instance = -> _instance

      return service

  ]

  # #### Implements hook `shrubTransmittableErrors`.
  registrar.registerHook 'shrubTransmittableErrors', exports.shrubTransmittableErrors

  registrar.recur [
    'login', 'logout'
  ]

exports.shrubOrmCollections = ->

  # ###### TODO: Finish these docs.
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

# Transmittable login conflict error.
class LoginConflictError extends TransmittableError

  errorType: 'shrub-user-login-conflict'
  template: 'That account already belongs to another user. First log out and then log in with that account.'

# Transmittable redundant login error.
class RedundantLoginError extends TransmittableError

  errorType: 'shrub-user-login-redundant'
  template: 'You are already logged in with that account.'

exports.shrubTransmittableErrors = -> [
  LoginConflictError
  RedundantLoginError
]
