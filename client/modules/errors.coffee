
exports.errorTemplates = (code) -> (
	
	401: "Not authorized to :attempted"
	420: "No such username/password."

)[code]
	
exports.formatErrors = (errors) ->
	
	message = ''
	
	for error in errors#.reverse()
		message = " <- #{message}" if message
		message = exports.formatError(error) + message
		
	message

exports.formatError = (error) ->
	
	template = exports.errorTemplates(error.code) ? "Unknown error: :attempted"
	
	for key, value of error
		template = template.replace ":#{key}", value
		
	template

