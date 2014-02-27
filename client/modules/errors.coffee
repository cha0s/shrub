
_ = require 'underscore'
pkgman = require 'pkgman'

exports.BaseError = class BaseError extends Error
	
	constructor: (@message) ->
	@template: "Unknown error: :message"
	
	key: 'unknown'
	template: BaseError.template
		
	toJSON: ->
		key: @key
		message: @message
		
exports.errorTypes = ->
	
	collected = [BaseError]
	
	pkgman.invoke 'errorType', (path, spec) -> collected.push spec
		
	types = {}
	types[(new Type).key] = Type for Type in collected
	types

exports.serialize = (error) ->
	
	if error instanceof BaseError
		error
	else if error instanceof Error
		message: error.message
	else
		message: error
	
exports.unserialize = (data) -> exports.instantiate data.key, data.message
	
exports.message = (error) ->

	output = if error instanceof BaseError
		error.template
	else if error instanceof Error
		BaseError.template.replace ":message", error.message
	else
		BaseError.template.replace ":message", error.toString()
	
	output = output.replace ":#{key}", value for key, value of error
	output
	
exports.instantiate = (key, message) ->
	
	Types = exports.errorTypes()
	Type = if Types[key]? then Types[key] else BaseError

	new Type message
	
exports.caught = (error) ->
	return error unless error instanceof BaseError
	
	error.caught exports.message error
	
	error
