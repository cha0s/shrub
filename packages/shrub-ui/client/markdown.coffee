
# # Markdown filter

marked = require 'marked'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `filter`
	registrar.registerHook 'filter', -> ->
		
		(input, sanitize = true) -> marked input, sanitize: sanitize
