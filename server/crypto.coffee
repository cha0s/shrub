
crypto = require 'crypto'
nconf = require 'nconf'
Q = require 'bluebird'

exports.encrypt = (message, password) ->
	
	deferred = Q.defer()
	
	try
		
		cipher = crypto.createCipher 'aes256', password ? nconf.get 'cryptoKey'
		
		cipherText = []
		cipherText.push cipher.update message, 'binary', 'hex'
		cipherText.push cipher.final 'hex'
		deferred.resolve cipherText.join ''
		
	catch error
		
		deferred.reject error
	
	deferred.promise
	
exports.decrypt = (message, password) ->

	deferred = Q.defer()
	
	try
	
		decipher = crypto.createDecipher 'aes256', password ? nconf.get 'cryptoKey'
		decipher.setAutoPadding false
		
		decipherText = []
		decipherText.push decipher.update message, 'hex', 'binary'
		decipherText.push decipher.final 'binary'
		decipherText = decipherText.join ''
		
		# Slice off the padding.
		if 16 > code = decipherText.charCodeAt decipherText.length - 1
			decipherText = decipherText.slice 0, -code
			
		deferred.resolve decipherText
		
	catch error
		
		deferred.reject error
	
	deferred.promise
