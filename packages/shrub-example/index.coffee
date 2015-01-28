
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `notificationQueue`
	registrar.registerHook 'general', 'notificationQueue', ->

		ownerFromRequest: (req) -> req.session.id

	registrar.recur [
		'about'
	]
