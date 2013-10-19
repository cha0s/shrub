
exports.errorTemplates = (code) -> (
	
	null: "Unknown error: :attempted"
	401: "Not authorized to :attempted"

)[code]
	
exports.formatErrors = (errors) ->
	
	message = ''
	
	for error in errors#.reverse()
		message = " <- #{message}" if message
		message = exports.formatError(error) + message
		
	message

exports.formatError = (error) ->
	
	template = exports.errorTemplates error.code
	
	for key, value of error
		template = template.replace ":#{key}", value
		
	template

