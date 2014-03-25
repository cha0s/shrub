
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
	
	collected = [BaseError].concat pkgman.invokeFlat 'errorType'
	
	Types = {}
	Types[Type::key] = Type for Type in collected
	Types

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
	formatStack = if formatStack?
		formatStack = formatStack.split '\n'
		formatStack.shift()
		'\n' + formatStack.join '\n'
	else
		''
	"#{@message error}#{formatStack}"
	
exports.instantiate = (key, args...) ->
	
	Types = exports.errorTypes()
	Type = if Types[key]? then Types[key] else BaseError
	
	IType = do (Type) ->
		
		F = (args) -> Type.apply this, args
		F.prototype = Type.prototype
		
		(args) -> new F args
	
	# Throw so we have a meaningful stack.
	try
		throw new Error()
	catch error
		stack = error.stack
	
	error = IType args
	error.stack = stack
	error
	
exports.caught = (error) ->
	return error unless error instanceof BaseError
	
	error.caught exports.message error
	
	error
