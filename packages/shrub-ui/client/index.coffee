
# # User Interface
# 
# Define user interface components.

exports.pkgmanRegister = (registrar) ->

	registrar.recur [
		'attributes', 'body', 'list', 'markdown', 'menu', 'nav'
		'notifications', 'window-title'
	]
