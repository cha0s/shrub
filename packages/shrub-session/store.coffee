
orm = null

module.exports = (connect) ->

	Store = connect.session.Store

	class OrmStore extends Store

		constructor: ->

			orm = require 'shrub-orm'

		get: (sid, fn) ->
			self = this

			Session = orm.collection 'shrub-session'

			Session.findOne(sid: sid).then((session) ->
				return fn() unless session?

				# Expired?
				if Date.now >= session.expires.getTime()
					return self.destroy sid, (error) ->
						return fn error if error?
						fn()

				fn null, JSON.parse session.blob

			).catch fn

		set: (sid, sess, fn) ->

			Session = orm.collection 'shrub-session'

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

		destroy: (sid, fn) ->

			Session = orm.collection 'shrub-session'

			Session.destroy(sid: sid).exec fn
