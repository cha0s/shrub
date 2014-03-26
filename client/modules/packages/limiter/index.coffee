
errors = require 'errors'

class LimiterThresholdError extends errors.TransmittableError
	
	constructor: (message, @time) -> super
	
	key: 'limiterThreshold'
	template: ":message You may try again :time."
	
	toJSON: -> [@key, @message, @time]

exports.$errorType = -> LimiterThresholdError
