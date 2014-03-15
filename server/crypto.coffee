
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
