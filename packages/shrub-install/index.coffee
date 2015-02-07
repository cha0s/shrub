
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `bootstrapMiddleware`
	registrar.registerHook 'bootstrapMiddleware', (context) ->

		orm = require 'shrub-orm'

		label: 'Installation'
		middleware: [

			(next) ->

				# No superuser? Install...
				User = orm.collection 'shrub-user'
				User.findOne(id: 1).then((user) ->
					return if user?

					reinstall 'cha0s', 'cha0s@example.com'

				).then(-> next()).catch next

		]

	# ## Implements hook `replContext`
	registrar.registerHook 'replContext', (context) ->

		context.install = reinstall

reinstall = (name, email) ->

	Promise = require 'bluebird'

	orm = require 'shrub-orm'

	# Refresh all collections.
	Promise.all(

		for identity, collection of orm.collections()
			new Promise (resolve, reject) ->
				collection.drop (error) ->
					return reject error if error?
					resolve()

	).then(->

		new Promise (resolve, reject) ->
			orm.teardown (error) ->
				return reject error if error?
				orm.initialize (error) ->
					return reject error if error?
					resolve()

	).then(->

		Group = orm.collection 'shrub-group'
		User = orm.collection 'shrub-user'

		Promise.all [

			# Create groups.
			Group.create name: 'Anonymous'
			Group.create name: 'Authenticated'
			Group.create name: 'Administrator'

			# Create superuser.
			require('shrub-user/register').register name, email
		]

	).then(([groups..., user]) ->

		user.groups.add group: groups[2].id
		user.save().then()

	).catch console.error
