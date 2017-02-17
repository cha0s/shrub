
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubUserLoginStrategies`.
  registrar.registerHook 'shrubUserLoginStrategies', ->

    exports.shrubUserLoginStrategies()

exports.shrubUserLoginStrategies = ->

  methodLabel: 'Reddit'

  fields:

    forgot:
      type: 'markup'
      value: '<a target="_self" class="btn btn-default" href="/user/reddit/auth">Authenticate with reddit</a>'

exports.shrubOrmCollections = ->

  UserReddit =

    attributes:

      # reddit ID.
      redditId:
        type: 'string'
        required: true

      # reddit username.
      name:
        type: 'string'
        required: true

      # OAuth2 access token.
      accessToken:
        type: 'longtext'

      # OAuth2 refresh token.
      refreshToken:
        type: 'longtext'

  'shrub-user-reddit': UserReddit
