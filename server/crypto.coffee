
# # Crypto
# 
# Cryptographic helper functions.

crypto = require 'crypto'
nconf = require 'nconf'
Promise = require 'bluebird'

# ### encrypt
# 
# *AES encrypt a message with a password.*
# 
# * (string) `message` - The message to encrypt.
# 
# * (string) `password`? - The password to use to encrypt the message. Defaults
#   to the site's global crypto key.
exports.encrypt = (message, password) ->
	
	new Promise (resolve, reject) ->
	
		cipher = crypto.createCipher 'aes256', password ? nconf.get 'cryptoKey'
		
		cipherText = []
		cipherText.push cipher.update message, 'binary', 'hex'
		cipherText.push cipher.final 'hex'
		resolve cipherText.join ''
	
# ### decrypt
# 
# *AES decrypt a message with a password.*
# 
# * (string) `message` - The message to decrypt.
# 
# * (string) `password`? - The password to use to decrypt the message. Defaults
#   to the site's global crypto key.
exports.decrypt = (message, password) ->
	
	new Promise (resolve, reject) ->
	
		decipher = crypto.createDecipher 'aes256', password ? nconf.get 'cryptoKey'
		decipher.setAutoPadding false
		
		decipherText = []
		decipherText.push decipher.update message, 'hex', 'binary'
		decipherText.push decipher.final 'binary'
		decipherText = decipherText.join ''
		
		# } Slice off the padding.
		if 16 >= code = decipherText.charCodeAt decipherText.length - 1
			decipherText = decipherText.slice 0, -code
			
		resolve decipherText

# ### hasher
# 
# *Cryptographic hash functionality.*
# 
# CREDIT: [https://gist.github.com/boronine/3548196](https://gist.github.com/boronine/3548196)
# cha0s promisify'd it.
#
# * (object) `options` - The options to use.
#   
#   The options object may include the following values:
#   
#   * `plaintext`: The plaintext password to hash and return as `key`. If none
#     is provided, an 8-character random plaintext password will be generated.
#   
#   * `salt`: The salt to hash the password with. If none is provided, a
#     512-bit salt will be generated.
#   
#   * `iterations`: The number of iterations to use for the PBKDF. Defaults to
#     10000\.
#     **NOTE**: This ***must*** be the same number when generating and
#     verifying hashes, otherwise verification will fail.
exports.hasher = (options = {}) ->
	
	# Generate random 8-character base64 password if none provided
	unless options.plaintext?
		
		return exports.randomBytes(6).then((buffer) ->
			options.plaintext = buffer.toString 'base64'
			exports.hasher options
		)
	
	# Generate random 512-bit salt if no salt provided
	unless options.salt?
	
		return exports.randomBytes(64).then((buffer) ->
			options.salt = buffer
			exports.hasher options
		)
	
	# } Node.js PBKDF2 forces sha1
	options.hash = 'sha1'
	options.iterations = options.iterations ? 10000
	
	exports.pbkdf2(
		options.plaintext, options.salt, options.iterations, 64
	
	).then (key) ->
		options.key = new Buffer key
		options

# Promisify some useful node.js crypto functions.
exports.pbkdf2 = Promise.promisify crypto.pbkdf2, crypto
exports.randomBytes = Promise.promisify crypto.randomBytes, crypto
