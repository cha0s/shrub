
# # User Interface
# 
# Define user interface components.

exports.pkgmanRegister = (registrar) ->

	registrar.recur [
		'markdown', 'nav', 'notifications', 'title', 'window'
	]	
