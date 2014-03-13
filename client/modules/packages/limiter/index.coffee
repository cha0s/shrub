
errors = require 'errors'

exports.$errorType = class LimiterThresholdError extends errors.BaseError
	
	constructor: (message, @time) -> super
	
	key: 'limiterThreshold'
	template: ":message Please wait about :time before trying again."
	
	toJSON: -> [@key, @message, @time]
