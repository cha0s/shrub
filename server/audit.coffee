
# # Audit

pkgman = require 'pkgman'

# ### keys
# 
# *Lookup the unique keys for a request.*
# 
# * (request) `req` - The request object to gather keys on.
exports.keys = (req) ->
	
	auditKeys = {}
	
	# Invoke hook `auditKeys`.
	# Get the unique keys for this request, e.g. IP address, session ID, etc.
	for path, keys of pkgman.invoke 'auditKeys', req
		continue unless keys?
		for key, value of keys
			continue unless value?
			
			auditKeys[key] = value
	
	auditKeys