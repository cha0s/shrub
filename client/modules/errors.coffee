
_ = require 'underscore'
pkgman = require 'pkgman'

exports.BaseError = class BaseError extends Error
	
	constructor: (@message) ->
	@template: "Unknown error: :message"
	
	caught: ->
	key: 'unknown'
	template: BaseError.template
		
	toJSON: -> [@key, @message]
		
exports.errorTypes = ->
	
	collected = [BaseError]
	collected.push Type for _, Type of pkgman.invoke 'errorType'
		
	types = {}
	types[Type::key] = Type for Type in collected
	types

exports.serialize = (error) ->
	
	if error instanceof BaseError
		error.toJSON()
	else if error instanceof Error
		[undefined, error.message]
	else
		[undefined, error]
	
exports.unserialize = (data) -> exports.instantiate.apply null, data
	
exports.message = (error) ->

	output = if error instanceof BaseError
		error.template
	else if error instanceof Error
		BaseError.template.replace ":message", error.message
	else
		BaseError.template.replace ":message", error.toString()
	
	output = output.replace ":#{key}", value for key, value of error
	output
	
exports.stack = (error) ->
	formatStack = error.stack
	formatStack = formatStack.split '\n'
	formatStack.shift()
	"#{@message error}\n#{formatStack.join '\n'}"
	
exports.instantiate = (key, args...) ->
	
	Types = exports.errorTypes()
	Type = if Types[key]? then Types[key] else BaseError
	
	Type = do (Type) ->
		
		F = (args) -> Type.apply this, args
		F.prototype = Type.prototype
		
		(args) -> new F args
	
	Type args
	
exports.caught = (error) ->
	return error unless error instanceof BaseError
	
	error.caught exports.message error
	
	error
