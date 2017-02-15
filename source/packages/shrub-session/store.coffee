# Session store

*An implementation of express's [Session
Store](https://www.npmjs.com/package/express-session#session-store-implementation)
API.
```coffeescript
ExpressSession = require 'express-session'

orm = null

module.exports = (connect) ->

  Store = ExpressSession.Store

  class OrmStore extends Store
```
## *constructor*

*Lazy-load ORM so as not to bog down the build process (and we have no
way to implement hook `shrubCorePreBootstrap` at this point).
```coffeescript
    constructor: ->

      orm = require 'shrub-orm'
```
## OrmStore#get

* (String) `sid` - Session ID.

* (Function) `fn` - Nodeback called with the retrieved session (if any).

*Get a session by ID.*
```coffeescript
    get: (sid, fn) ->
      self = this

      Session = orm.collection 'shrub-session'

      Session.findOne(sid: sid).then((session) ->
        return fn() unless session?
```
Expired?
```coffeescript
        if Date.now >= session.expires.getTime()
          return self.destroy sid, (error) ->
            return fn error if error?
            fn()

        fn null, JSON.parse session.blob

      ).catch fn
```
## OrmStore#set

* (String) `sid` - Session ID.

* (Object) `sess` - Session data.

* (Function) `fn` - Nodeback called with the created/updated session.

*Get a session by ID.*
```coffeescript
    set: (sid, sess, fn) ->

      Session = orm.collection 'shrub-session'
```
Use the cookie expiration if it exists, otherwise default to one day.
```coffeescript
      ttl = @ttl ? if 'number' is typeof maxAge = sess.cookie.maxAge
        maxAge / 1000 or 0
      else
        86400

      Session.findOrCreate(
        sid: sid
      ,
        sid: sid
        expires: new Date Date.now() + ttl * 1000
      ).then((session) ->
        session.blob = JSON.stringify sess
        session.save()
      ).then((session) -> fn null, session).catch fn

    touch: @::['set']
```
## OrmStore#destroy

* (String) `sid` - Session ID.

* (Function) `fn` - Nodeback called after the session is destroyed.

*Destroy a session by ID.*
```coffeescript
    destroy: (sid, fn) ->

      Session = orm.collection 'shrub-session'

      Session.destroy(sid: sid).exec fn
```
