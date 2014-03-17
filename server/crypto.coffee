
crypto = require 'crypto'
nconf = require 'nconf'
Promise = require 'bluebird'

exports.encrypt = (message, password) ->
	
	new Promise (resolve, reject) ->
	
		cipher = crypto.createCipher 'aes256', password ? nconf.get 'cryptoKey'
		
		cipherText = []
		cipherText.push cipher.update message, 'binary', 'hex'
		cipherText.push cipher.final 'hex'
		resolve cipherText.join ''
	
exports.decrypt = (message, password) ->
	
	new Promise (resolve, reject) ->
	
		decipher = crypto.createDecipher 'aes256', password ? nconf.get 'cryptoKey'
		decipher.setAutoPadding false
		
		decipherText = []
		decipherText.push decipher.update message, 'hex', 'binary'
		decipherText.push decipher.final 'binary'
		decipherText = decipherText.join ''
		
		# Slice off the padding.
		if 16 >= code = decipherText.charCodeAt decipherText.length - 1
			decipherText = decipherText.slice 0, -code
			
		resolve decipherText

crypto = require 'crypto'

# CREDIT: https://gist.github.com/boronine/3548196
# cha0s promisify'd it.
exports.hasher = (opts = {}) ->
	
	# Generate random 8-character base64 password if none provided
	unless opts.plaintext?
		
		return exports.randomBytes(6).then((buffer) ->
			opts.plaintext = buffer.toString 'base64'
			exports.hasher opts
		)
	
	# Generate random 512-bit salt if no salt provided
	unless opts.salt?
	
		return exports.randomBytes(64).then((buffer) ->
			opts.salt = buffer
			exports.hasher opts
		)
	
	# Node.js PBKDF2 forces sha1
	opts.hash = 'sha1'
	opts.iterations = opts.iterations ? 10000
	
	exports.pbkdf2(
		opts.plaintext, opts.salt, opts.iterations, 64
	
	).then((key) ->
		opts.key = new Buffer(key)
		opts
	)

exports.pbkdf2 = Promise.promisify crypto.pbkdf2, crypto

exports.randomBytes = Promise.promisify crypto.randomBytes, crypto
