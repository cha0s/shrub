# Session

*Manage sessions across HTTP and socket connections.*

```coffeescript
config = require 'config'

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubOrmCollections`](../../hooks#shrubormcollections)

```coffeescript
  registrar.registerHook 'shrubOrmCollections', ->

    Session =
```

Skip the numeric primary key, we'll use the session ID.

```coffeescript
      autoPK: false

      attributes:
```

Store the session data as a blob of data.

```coffeescript
        blob: 'string'
```

When this session expires.

```coffeescript
        expires: 'datetime'
```

The session ID, used as the primary key.

```coffeescript
        sid:
          type: 'string'
          primaryKey: true

    'shrub-session': Session
```

#### Implements hook [`shrubAuditFingerprint`](../../hooks#shrubauditfingerprint)

```coffeescript
  registrar.registerHook 'shrubAuditFingerprint', (req) ->
```

Session ID.

```coffeescript
    session: if req?.session? then req.session.id
```

#### Implements hook [`shrubConfigServer`](../../hooks#shrubconfigserver)

```coffeescript
  registrar.registerHook 'shrubConfigServer', ->
```

Key within the cookie where the session is stored.

```coffeescript
    key: 'connect.sid'
```

Cookie information.

```coffeescript
    cookie:
```

The crypto key we encrypt the cookie with.

```coffeescript
      cryptoKey: '***CHANGE THIS***'
```

The max age of this session. Defaults to two weeks.

```coffeescript
      maxAge: 1000 * 60 * 60 * 24 * 14
```

#### Implements hook [`shrubSocketConnectionMiddleware`](../../hooks#shrubsocketconnectionmiddleware)

```coffeescript
  registrar.registerHook 'shrubSocketConnectionMiddleware', ->

    label: 'Join channel for session'
    middleware: [

      (req, res, next) ->

        return req.socket.join "session/#{req.session.id}", next if req.session?

        next()

    ]
```
