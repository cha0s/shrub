
# # User Interface
# 
# Define user interface components.

exports.pkgmanRegister = (registrar) ->

	registrar.recur [
		'body', 'markdown', 'nav', 'notifications', 'title', 'window'
	]
