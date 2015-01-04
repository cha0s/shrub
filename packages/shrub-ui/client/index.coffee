
# # User Interface
# 
# Define user interface components.

exports.pkgmanRegister = (registrar) ->

	registrar.recur [
		'body', 'list', 'markdown', 'nav', 'notifications', 'window-title'
	]
