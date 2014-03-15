
pkgman = require 'pkgman'

exports.keys = (req) ->
		
	auditKeys = pkgman.invoke 'auditKeys', req 
	
	keys = []
	for path, suffixes of auditKeys
		keys.push "#{path}:#{suffix}" for suffix in suffixes
	
	keys
