
# # Error handling

_ = require 'underscore'
pkgman = require 'pkgman'

# ## TransmittableError
# 
# Extend this class if you'd like to implement an error 
exports.TransmittableError = class TransmittableError extends Error
	
	# See: [https://github.com/jashkenas/coffee-script/issues/2359](https://github.com/jashkenas/coffee-script/issues/2359)
	# `TODO`: Capture all arguments, and make the necessity for implementing
	# toJSON obsolete.
	constructor: (@message) ->
	
	# Invoked when the error is caught.
	# `TODO`: Remove.
	caught: ->
	
	# A unique key for this error.
	key: 'unknown'
	
	# The template used to format the error output.
	template: "Unknown error: :message"
	
	# Implement this if you need to transmit more than just the key and the
	# message.
	toJSON: -> [@key, @message]
		
# ## transmittableErrors
# 
# *Collect the error types implemented by packages.*
exports.transmittableErrors = ->
	
	# Invoke hook `transmittableError`.
	# Allows packages to specify transmittable errors. Implementations should
	# return a subclass of `TransmittableError`.
	collected = [TransmittableError].concat pkgman.invokeFlat 'transmittableError'
	
	Types = {}
	Types[Type::key] = Type for Type in collected
	Types

# ## serialize
# 
# *Serialize an error for transmission.*
exports.serialize = (error) ->
	
	# One of us!
	if error instanceof TransmittableError
		error.toJSON()
	
	# Abstract; Error.
	else if error instanceof Error
		[undefined, error.message]
	
	# Unknown type.
	else
		[undefined, error]
	
# ## unserialize
# 
# *Unserialize an error from the wire.*
exports.unserialize = (data) -> exports.instantiate.apply null, data

# ## message
# 
# *Extract an error message from an error.*
exports.message = (error) ->

	# One of us!
	output = if error instanceof TransmittableError
		error.template
	
	# Abstract; Error.
	else if error instanceof Error
		TransmittableError::template.replace ":message", error.message
	
	# Unknown.
	else
		TransmittableError::template.replace ":message", error.toString()
	
	# Replace placeholders in the template.
	output = output.replace ":#{key}", value for key, value of error
	output
	
# ## stack
# 
# *Extract the stack trace from an error.*
exports.stack = (error) ->
	
	# Does the stack trace exist?
	formatStack = if (formatStack = error.stack)?
		
		# If so, shift off the first line (the message).
		formatStack = formatStack.split '\n'
		formatStack.shift()
		'\n' + formatStack.join '\n'
	else
		''
	
	# Prepend our pretty formatted message before the stack trace.
	"#{@message error}#{formatStack}"
	
# ## instantiate
# 
# *Instantiate an error based on key, passing along args to the error's
# constructor.*
exports.instantiate = (key, args...) ->
	
	Types = exports.transmittableErrors()
	Type = if Types[key]? then Types[key] else TransmittableError
	
	# Trickery to be able to essentially call new with Function::apply.
	IType = do (Type) ->
		F = (args) -> Type.apply this, args
		F.prototype = Type.prototype
		(args) -> new F args
	
	# Throw so we have a(n arguably) meaningful stack.
	try
		throw new Error()
	catch error
		stack = error.stack
	
	error = IType args
	error.stack = stack
	error
	
# ## caught
# 
# *Call any `caught` function on an error.*
# 
# `TODO`: Remove.
exports.caught = (error) ->
	return error unless error instanceof TransmittableError
	
	error.caught exports.message error
	
	error
