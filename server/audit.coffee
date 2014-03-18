
pkgman = require 'pkgman'

exports.keys = (req) ->
	
	auditKeys = {}
	for path, keys of pkgman.invoke 'auditKeys', req
		continue unless keys?
		
		for key, value of keys
			continue unless value?
			
			auditKeys[key] = value
	
	auditKeys
