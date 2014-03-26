
# # Markdown filter

marked = require 'marked'

# ## Implements hook `filter`
exports.$filter = -> ->
	
	(input, sanitize = true) -> marked input, sanitize: sanitize
