
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `replContext`
	registrar.registerHook 'replContext', (context) ->

		Promise = require 'bluebird'

		orm = require 'shrub-orm'

		context.install = (name, email) ->

			Promise.resolve().then(->

				new Promise (resolve, reject) ->

					# Refresh all collections.
					for identity, collection of orm.collections()
						collection.drop (error) ->
							return reject error if error?
							collection.describe (error) ->
								return reject error if error?
								resolve()

				return

			).then(->

				Group = orm.collection 'shrub-group'
				User = orm.collection 'shrub-user'

				Promise.all [

					# Create groups.
					Group.create name: 'Anonymous'
					Group.create name: 'Authenticated'
					Group.create name: 'Administrator'

					# Create superuser.
					context.registerUser name, email
				]

			).then(([groups..., user]) ->

				user.groups.add group: groups[2].id
				user.save().then()

			)


