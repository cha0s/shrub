
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `notificationQueue`
	registrar.registerHook 'general', 'notificationQueue', ->

		channelFromRequest: (req) -> req.session?.id

	registrar.recur [
		'about'
	]
