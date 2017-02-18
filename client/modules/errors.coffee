# # Error handling
pkgman = require 'pkgman'

# ## TransmittableError
#
# Extend this class if you'd like to implement an error.
exports.TransmittableError = class TransmittableError extends Error

  # ## TransmittableError#constructor
  #
  # See:
  # [https://github.com/jashkenas/coffee-script/issues/2359](https://github.com/jashkenas/coffee-script/issues/2359)
  constructor: (@message) ->

  # ## TransmittableError#errorType
  #
  # A unique key for this error.
  errorType: 'unknown'

  # ## TransmittableError#template
  #
  # The template used to format the error output.
  template: 'Unknown error: :message'

  # ## TransmittableError#toJSON
  #
  # Implement this if you need to transmit more than just the error type and
  # the message. Shrub uses the result from this function to serialize the
  # error over the wire.
  toJSON: -> [@errorType, @message]

# ## errors.instantiate
#
# * (string) `errorType` - The error type.
#
# * (any) `args...` - Additional arguments to pass to the error type's
#
# constructor. *Instantiate an error based on error type, passing along args
# to the error's constructor.*
exports.instantiate = (errorType, args...) ->

  # Look up the error type and use it. If it's not registered, fall back to
  # the TransmittableError superclass.
  Types = exports.transmittableErrors()
  Type = if Types[errorType]? then Types[errorType] else TransmittableError

  # Trickery to be able to essentially call `new` with `Function::apply`.
  IType = do (Type) ->
    F = (args) -> Type.apply this, args
    F.prototype = Type.prototype
    (args) -> new F args

  # Throw so we have a (possibly) meaningful stack.
  try
    throw new Error()
  catch error
    stack = error.stack

  error = IType args
  error.stack = stack
  error

# ## errors.message
#
# * (Error) `error` - The error object.
#
# *Extract an error message from an error.*
exports.message = (error) ->

  # One of us! One of us!
  output = if error instanceof TransmittableError
    error.template

  # Abstract Error.
  else if error instanceof Error
    TransmittableError::template.replace ':message', error.message

  # Not an instance of `Error`. This probably shouldn't happen, but we deal
  # with it anyway.
  else
    TransmittableError::template.replace ':message', error.toString()

  # Replace placeholders in the template.
  output = output.replace ":#{key}", value for key, value of error
  output

# ## errors.serialize
#
# * (Error) `error` - The error object.
#
# *Serialize an error to send over the wire.*
exports.serialize = (error) ->

  # One of us! One of us!
  if error instanceof TransmittableError
    error.toJSON()

  # Abstract Error.
  else if error instanceof Error
    [undefined, error.message]

  # Not an instance of `Error`. This probably shouldn't happen, but we deal
  # with it anyway.
  else
    [undefined, error]

# ## errors.stack
#
# * (Error) `error` - The error object.
#
# *Extract the stack trace from an error.*
exports.stack = (error) ->

  # Does the stack trace exist?
  formatStack = if (formatStack = error.stack)?

    # If so, shift off the first line (the message).
    formatStack = formatStack.split '\n'
    formatStack.shift()
    '\n' + formatStack.join '\n'

  # Otherwise, we don't have much to work with...
  else
    ''

  # Prepend our pretty formatted message before the stack trace.
  "#{@message error}#{formatStack}"

# ## errors.transmittableErrors
#
# *Collect the error types implemented by packages.*
exports.transmittableErrors = ->

  _ = require 'lodash'

  # #### Invoke hook `shrubTransmittableErrors`.
  #
  # Allows packages to specify transmittable errors. Implementations should
  # return a subclass of `TransmittableError`.
  Types = {}

  Types[Type::errorType] = Type for Type in [TransmittableError].concat(
    _.flatten pkgman.invokeFlat 'shrubTransmittableErrors'
  )

  Types

# ## errors.unserialize
#
# *Unserialize an error from over the wire.*
exports.unserialize = (data) -> exports.instantiate.apply null, data
