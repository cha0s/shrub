
$module.filter 'md', [
	'require'
	(require) ->
	
		marked = require 'marked'
		
		(input, sanitize = true) -> marked input, sanitize: sanitize
	
]
