
# # User Interface
#
# Define user interface components.

exports.pkgmanRegister = (registrar) ->

	registrar.recur [
		'attributes', 'list', 'markdown', 'menu', 'messages', 'notifications'
		'window-title'
	]
