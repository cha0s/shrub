# # Session
#
# *Manage sessions across HTTP and socket connections.*
config = require 'config'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubOrmCollections`.
  registrar.registerHook 'shrubOrmCollections', ->

    Session =

      # Skip the numeric primary key, we'll use the session ID.
      autoPK: false

      attributes:

        # Store the session data as a blob of data.
        blob: 'string'

        # When this session expires.
        expires: 'datetime'

        # The session ID, used as the primary key.
        sid:
          type: 'string'
          primaryKey: true

    'shrub-session': Session

  # #### Implements hook `shrubAuditFingerprint`.
  registrar.registerHook 'shrubAuditFingerprint', (req) ->

    # Session ID.
    session: if req?.session? then req.session.id

  # #### Implements hook `shrubConfigServer`.
  registrar.registerHook 'shrubConfigServer', ->

    # Key within the cookie where the session is stored.
    key: 'connect.sid'

    # Cookie information.
    cookie:

      # The crypto key we encrypt the cookie with.
      cryptoKey: '***CHANGE THIS***'

      # The max age of this session. Defaults to two weeks.
      maxAge: 1000 * 60 * 60 * 24 * 14

  # #### Implements hook `shrubSocketConnectionMiddleware`.
  registrar.registerHook 'shrubSocketConnectionMiddleware', ->

    label: 'Join channel for session'
    middleware: [

      (req, res, next) ->

        return req.socket.join req.session.id, next if req.session?

        next()

    ]