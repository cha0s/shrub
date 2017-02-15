# Crypto

*Cryptographic helper functions.*
```coffeescript
crypto = require 'crypto'
config = require 'config'
Promise = require 'bluebird'
```
## crypto.encrypt

* (string) `message` - The message to encrypt.

* (optional string) `password` - The password to use to encrypt the message.

Defaults to the site's global crypto key. *AES encrypt a message with a
password.*
```coffeescript
exports.encrypt = (message, password) ->

  new Promise (resolve, reject) ->

    cipher = crypto.createCipher(
      'aes256'
      password ? config.get 'packageSettings:shrub-core:cryptoKey'
    )

    cipherText = []
    cipherText.push cipher.update message, 'binary', 'hex'
    cipherText.push cipher.final 'hex'
    resolve cipherText.join ''
```
## crypto.decrypt

* (string) `message` - The message to decrypt.

* (optional string) `password` - The password to use to decrypt the message.

Defaults to the site's global crypto key. *AES decrypt a message with a
password.*
```coffeescript
exports.decrypt = (message, password) ->

  new Promise (resolve, reject) ->

    decipher = crypto.createDecipher(
      'aes256'
      password ? config.get 'packageSettings:shrub-core:cryptoKey'
    )
    decipher.setAutoPadding false

    decipherText = []
    decipherText.push decipher.update message, 'hex', 'binary'
    decipherText.push decipher.final 'binary'
    decipherText = decipherText.join ''
```
Slice off any padding.
```coffeescript
    if 16 >= code = decipherText.charCodeAt decipherText.length - 1
      decipherText = decipherText.slice 0, -code

    resolve decipherText
```
## crypto.hasher

CREDIT:
[https://gist.github.com/boronine/3548196](https://gist.github.com/boronine/3548196)
cha0s promisify'd it and made it work with Buffer objects.

* (object) `options` - The options to use. The options object may include
the following values:

    * `digest`: The cryptographic digest function to use to generate the
      hash. Defaults to 'sha1'.

    * `plaintext`: The plaintext password to hash and return as `key`. If
      none is provided, an 8-character random plaintext password will be
      generated.

    * `salt`: The salt to hash the password with. If none is provided, a
      512-bit salt will be generated.

    * `iterations`: The number of iterations to use for the PBKDF. Defaults
      to 10000\. **NOTE:** This ***must*** be the same number when
      generating and verifying hashes, otherwise verification will fail.
```coffeescript
```
*Cryptographic authentication functionality.*
```coffeescript
exports.hasher = (options = {}) ->
```
Generate random 8-character base64 password if none provided
```coffeescript
  unless options.plaintext?

    return exports.randomBytes(6).then((buffer) ->
      options.plaintext = buffer.toString 'base64'
      exports.hasher options
    )
```
Generate random 512-bit salt if no salt provided
```coffeescript
  unless options.salt?

    return exports.randomBytes(64).then((buffer) ->
      options.salt = buffer
      exports.hasher options
    )

  options.digest ?= 'sha1'
  options.iterations ?= 10000

  exports.pbkdf2(
    options.plaintext, options.salt, options.iterations, 64, options.digest

  ).then (key) ->
    options.key = new Buffer key
    options
```
Promisify some useful node.js crypto functions.
```coffeescript
exports.pbkdf2 = Promise.promisify crypto.pbkdf2, crypto
exports.randomBytes = Promise.promisify crypto.randomBytes, crypto
```
