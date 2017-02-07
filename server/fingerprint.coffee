# # Fingerprint class
pkgman = require 'pkgman'

# Gather and transform fingerprint data.
module.exports = class Fingerprint

  # ## *constructor*
  #
  # * (http.IncomingMessage) `_req` - The request.
  #
  # Store the request in the instance.
  constructor: (@_req) ->

  # ## Fingerprint#get
  #
  # See [Fingerprint.get](#fingerprintget_1)
  get: (excluded) -> Fingerprint.get @_req, excluded

  # ## Fingerprint#inlineKeys
  #
  # See [Fingerprint.inlineKeys](#fingerprintinlinekeys_1)
  inlineKeys: (excluded) -> Fingerprint.inlineKeys @_req, excluded

  # ## Fingerprint#keys
  #
  # See [Fingerprint.keys](#fingerprintkeys_1)
  keys: (excluded) -> Fingerprint.keys @_req, excluded

  # ## Fingerprint#raw
  #
  # See [Fingerprint.raw](#fingerprintraw_1)
  raw: (excluded) -> Fingerprint.raw @_req, excluded

  # ## Fingerprint.get
  #
  # * (http.IncomingMessage) `req` - The request.
  #
  # * (string array) `excluded` - Keys to exclude from the result.
  #
  # *Get the raw fingerprint and filter out null values.*
  @get: (req, excluded = []) ->
    fingerprint = {}

    for key, value of @raw req, excluded
      continue unless value?
      fingerprint[key] = value

    fingerprint

  # ## Fingerprint.inlineKeys
  #
  # * (http.IncomingMessage) `req` - The request.
  #
  # * (string array) `excluded` - Keys to exclude from the result.
  #
  # *Get the filtered fingerprint and map it to key/value pairs.*
  @inlineKeys: (req, excluded = []) ->
    "#{key}:#{value}" for key, value of @get req, excluded

  # ## Fingerprint.keys
  #
  # * (http.IncomingMessage) `req` - The request.
  #
  # * (string array) `excluded` - Keys to exclude from the result.
  #
  # *Get the keys from the raw fingerprint.*
  @keys: (req, excluded = []) -> Object.keys @raw req, excluded

  # ## Fingerprint.raw
  #
  # * (http.IncomingMessage) `req` - The request.
  #
  # * (string array) `excluded` - Keys to exclude from the result.
  #
  # *Get the raw fingerprint.*
  @raw: (req, excluded = []) ->
    raw = {}

    _excluded = {}
    _excluded[key] = true for key in excluded

    # #### Invoke hook `shrubAuditFingerprint`.
    for keys in pkgman.invokeFlat 'shrubAuditFingerprint', req
      for key, value of keys ? {}
        continue if _excluded[key]
        raw[key] = value

    raw