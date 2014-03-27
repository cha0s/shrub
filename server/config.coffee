
# # Configuration
# 
# Manages server and package configuration.

nconf = require 'nconf'
fs = require 'fs'

pkgman = require 'pkgman'

# ### load
# 
# *Load configuration from the settings file and package defaults.*
exports.load = ->

	# } Ensure the configuration file exists.
	unless fs.existsSync settingsFilename = "./config/settings.json"
		throw new Error "Settings file not found! You should copy config/settings.default.json to config/settings.json"
	
	nconf.argv().env().file settingsFilename
	
	nconf.defaults path: "#{__dirname}/.."
		
	# } Register packages.
	pkgman.registerPackageList nconf.get 'packageList'

	nconf.defaults
		
		# Invoke hook `packageSettings`.
		# Invoked when the server application is loading configuration. Allows
		# packages to define their own default settings.
		packageSettings: pkgman.invoke 'packageSettings'
		
		path: "#{__dirname}/.."
	