
# # User logout

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `endpoint`
	registrar.registerHook 'endpoint', ->

		route: 'shrub.user.logout'

		receiver: (req, fn) ->

			# Log out.
			req.logOut().nodeify fn

	# ## Implements hook `bootstrapMiddleware`
	registrar.registerHook 'bootstrapMiddleware', ->

		Promise = require 'bluebird'

		middleware = require 'middleware'

		label: 'Bootstrap user logout'
		middleware: [

			(next) ->

				{IncomingMessage} = require 'http'

				req = IncomingMessage.prototype

				# Invoke hook `userBeforeLogoutMiddleware`.
				# Invoked before a user logs out.
				userBeforeLogoutMiddleware = middleware.fromShortName(
					'user before logout'
					'shrub-user'
				)

				# Invoke hook `userAfterLogoutMiddleware`.
				# Invoked after a user logs out.
				userAfterLogoutMiddleware = middleware.fromShortName(
					'user after logout'
					'shrub-user'
				)

				logout = req.passportLogOut = req.logout
				req.logout = req.logOut = ->

					new Promise (resolve, reject) =>

						userBeforeLogoutMiddleware.dispatch req, (error) =>
							return reject error if error?

							logout.call this

							userAfterLogoutMiddleware.dispatch req, (error) ->
								return reject error if error?

								resolve()

				next()

		]
