
nconf = require 'nconf'
fs = require 'fs'
winston = require 'winston'

pkgman = require 'pkgman'

# Log errors to the console, the rest will go into logs/shrub.log by default.
winston.remove winston.transports.Console
winston.add winston.transports.Console, level: 'silly'
winston.add winston.transports.File, filename: 'logs/shrub.log'

exports.loadSettings = ->

	settingsFilename = "./config/settings.json"
	
	# Ensure the configuration file exists.
	unless fs.existsSync settingsFilename
		throw new Error "Settings file not found! You should copy config/settings.default.json to config/settings.json"
	
	nconf.argv().env().file settingsFilename
	
	nconf.defaults
		
		path: "#{__dirname}/.."
		
	# Always disable sandbox rendering in end-to-end testing mode.
	nconf.set 'packageSettings:angular:render', false if nconf.get 'E2E'
		
	# Register packages.
	pkgman.registerPackages nconf.get 'packageList'

exports.loadPackageSettings = ->
	nconf.defaults packageSettings: pkgman.invoke 'settings'
		
exports.Config = -> class Config
	
	constructor: (@config) ->
	
	get: (key) ->
	
		current = @config
		current = current?[part] for part in key.split ':'
		current
	
	has: (key) ->
	
		current = @config
		for part in key.split ':'
			return false unless part of current
			current = current[part]
		
		return true
	
	set: (key, value) ->
		
		[parts..., last] = key.split ':'
		current = @config
		for part in parts
			current = (current[part] ?= {})
		
		current[last] = value
		
	$get: -> this
	