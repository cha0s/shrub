
exports.pkgmanRegister = (registrar) ->

  registrar.recur [
    'email', 'forgot', 'login', 'register', 'reset'
  ]

exports.shrubOrmCollections = ->

  UserLocal =

    attributes:

      # Email address.
      email:
        type: 'string'
        index: true

      # Name.
      name:
        type: 'string'
        size: 24
        maxLength: 24

  'shrub-user-local': UserLocal
