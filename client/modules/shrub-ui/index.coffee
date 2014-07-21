
# # User Interface
# 
# Define user interface components.

exports.pkgmanRegister = (registrar) ->

	registrar.recur [
		'body', 'head', 'markdown', 'nav', 'notifications', 'title', 'window'
	]
