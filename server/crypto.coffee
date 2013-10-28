
crypto = require 'crypto'
nconf = require 'nconf'

exports.encrypt = (message, password, fn) ->
	unless fn?
		fn = password
		password = null
		
	cipher = crypto.createCipher 'aes256', password ? nconf.get 'cryptoKey'
	
	cipherText = []
	cipherText.push cipher.update message, 'binary', 'hex'
	cipherText.push cipher.final 'hex'
	fn null, cipherText.join ''
	
exports.decrypt = (message, password, fn) ->
	unless fn?
		fn = password
		password = null

	decipher = crypto.createDecipher 'aes256', password ? nconf.get 'cryptoKey'
	decipher.setAutoPadding false
	
	decipherText = []
	decipherText.push decipher.update message, 'hex', 'binary'
	decipherText.push decipher.final 'binary'
	decipherText = decipherText.join ''
	
	# Slice off the padding.
	if 16 > code = decipherText.charCodeAt decipherText.length - 1
		decipherText = decipherText.slice 0, -code
		
	fn null, decipherText
