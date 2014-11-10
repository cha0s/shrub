
# # Configuration
# 
# Manages server and package configuration.

debug = require('debug') 'shrub:config'
nconf = require 'nconf'
fs = require 'fs'

pkgman = require 'pkgman'

{Config} = require 'client/modules/config'

# ### get
# 
# *Get a configuration value by key.*
exports.get = (key) -> nconf.get key

# ### has
# 
# *Check if a configuration value exists by key.*
exports.has = (key) -> nconf.has key

# ### load
# 
# *Load configuration from the settings file and package defaults.*
exports.load = ->

	# } Ensure the configuration file exists.
	unless fs.existsSync settingsFilename = "./config/settings.json"
		throw new Error "Settings file not found! You should copy config/settings.default.json to config/settings.json"
	
	nconf.argv().env().file settingsFilename
	
	nconf.defaults path: "#{__dirname}/.."
		
	return

# ### loadPackageSettings
# 
# *Load package settings as defaults in the configuration*
exports.loadPackageSettings = ->

	# } Register packages.
	debug "Registering packages..."
	
	pkgman.registerPackageList nconf.get 'packageList'
	
	debug "Packages registered."
	
	packageSettings = new Config()
	for key, value of pkgman.invoke 'packageSettings'
		packageSettings.set key.replace(/\//g, ':'), value
		
	nconf.defaults
		
		# Invoke hook `packageSettings`.
		# Invoked when the server application is loading configuration. Allows
		# packages to define their own default settings.
		packageSettings: packageSettings.toJSON()
		
		path: "#{__dirname}/.."
		
	return
		
# ### set
# 
# *Set a configuration value by key.*
exports.set = (key, value) -> nconf.set key, value
