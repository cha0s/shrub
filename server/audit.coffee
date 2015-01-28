
# # Audit

pkgman = require 'pkgman'

# ### fingerprint
#
# *Get the fingerprint for a request.*
#
# * (request) `req` - The request object to gather keys on.
exports.fingerprint = (req) ->

	fingerprint = {}

	# Remove null values.
	for key, value of exports.fingerprintRaw req
		continue unless value?
		fingerprint[key] = value

	fingerprint

# ### fingerprintKeys
#
# *Get the fingerprint keys for a request.*
#
# * (request) `req` - The request object to gather keys on.
exports.fingerprintKeys = (req) -> Object.keys exports.fingerprintRaw req

# ### fingerprintRaw
#
# *Get the raw fingerprint for a request.*
#
# * (request) `req` - The request object to gather keys on.
exports.fingerprintRaw = (req) ->

	fingerprint = {}

	# Invoke hook `fingerprint`.
	# Allows a package to specify unique keys for this request, e.g. IP
	# address, session ID, etc. Implementations take a request object as the
	# only parameter. The request parameter may be null.
	for keys in pkgman.invokeFlat 'fingerprint', req
		continue unless keys?
		fingerprint[key] = value for key, value of keys

	fingerprint
