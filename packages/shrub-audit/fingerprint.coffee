
pkgman = require 'pkgman'

module.exports = class Fingerprint

	@get: (req, excluded = []) ->
		fingerprint = {}

		for key, value of @raw req, excluded
			continue unless value?
			fingerprint[key] = value

		fingerprint

	@inlineKeys: (req, excluded = []) ->
		"#{key}:#{value}" for key, value of @get req, excluded

	@keys: (req, excluded = []) -> Object.keys @raw req, excluded

	@raw: (req, excluded = []) ->
		raw = {}

		_excluded = {}
		_excluded[key] = true for key in excluded

		# Invoke hook `fingerprint`.
		# Allows a package to specify unique keys for this request, e.g. IP
		# address, session ID, etc. Implementations take a request object as
		# the only parameter. The request parameter may be null.
		for keys in pkgman.invokeFlat 'fingerprint', req
			for key, value of keys ? {}
				continue if _excluded[key]
				raw[key] = value

		raw

	constructor: (@_req) ->

	get: (excluded) -> Fingerprint.get @_req, excluded

	inlineKeys: (excluded) -> Fingerprint.inlineKeys @_req, excluded

	keys: (excluded) -> Fingerprint.keys @_req, excluded

	raw: (excluded) -> Fingerprint.raw @_req, excluded
