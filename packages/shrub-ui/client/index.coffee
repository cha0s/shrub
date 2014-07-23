
# # User Interface
# 
# Define user interface components.

exports.pkgmanRegister = (registrar) ->

	registrar.recur [
		'body', 'markdown', 'menu', 'nav', 'notifications', 'title', 'window'
	]
