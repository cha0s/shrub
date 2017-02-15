# Limiter

*Define a TransmittableError for the limiter.*
```coffeescript
{TransmittableError} = require 'errors'
```
Implement a TransmittableError to inform the user of limiter threshold
passing.
```coffeescript
class LimiterThresholdError extends TransmittableError

  constructor: (message, @time) -> super

  key: 'limiterThreshold'
  template: ':message You may try again :time.'
  toJSON: -> [@key, @message, @time]

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubTransmittableErrors`.
```coffeescript
  registrar.registerHook 'shrubTransmittableErrors', exports.shrubTransmittableErrors

exports.shrubTransmittableErrors = -> [
  LimiterThresholdError
]
```
