
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
	pkgman.registerPackages nconf.get 'packageList'

	nconf.defaults
		
		# Invoke hook `settings`.
		# Invoked when the server application is loading configuration. Allows
		# packages to define their own default settings.
		# 
		# `TODO`: This should be renamed to `defaultSettings`.
		packageSettings: pkgman.invoke 'settings'
		
		path: "#{__dirname}/.."
		
# ## Config
# 
# *Configuration traversal.*
# 
# This class allows us to wrap and subsequently get, set, and check the
# existence of values in a configuration tree. The configuration tree may be
# traversed with colons, e.g. `parent:child:grandchild`. Supposing we have a
# configuration structure:
# 
#     configuration =
#         visible: true
#         child:
#             id: 200
#             tag: null
# 
# We may wrap and interact with it as follows:
# 
#     wrapped = new Config configuration
#     wrapped.get 'visible'
# 
# `true`
#     
#     wrapped.set 'child:name', 'Billy'
#     wrapped.get 'child'
# 
# `{ id: 200, name: 'Billy' }`
#     
#     wrapped.has 'child:id'
# 
# `true`
#     
#     wrapped.has 'child:thing'
# 
# `false`
#     
#     # Works with null values.
#     wrapped.has 'child:tag'
# 
# `true`
#     
exports.Config = -> class Config
	
	# ### *constructor*
	# 
	# *Create a configuration wrapper.*
	# 
	# * (object) `config` - The configuration tree.
	constructor: (@config) ->
	
	# ### .get
	# 
	# *Get a value by key.*
	# 
	# * (string) `key` - The key to look up, e.g. parent:child:grandchild
	get: (key) ->
	
		current = @config
		current = current?[part] for part in key.split ':'
		current
	
	# ### .has
	# 
	# *Check whether a key exists.*
	# 
	# * (string) `key` - The key to look up, e.g. parent:child:grandchild
	has: (key) ->
	
		current = @config
		for part in key.split ':'
			return false unless part of current
			current = current[part]
		
		return true
	
	# ### .set
	# 
	# *Set a value by key.*
	# 
	# * (string) `key` - The key to look up, e.g. parent:child:grandchild
	# * (any) `value` - The value to store at the key location.
	set: (key, value) ->
		
		[parts..., last] = key.split ':'
		current = @config
		for part in parts
			current = (current[part] ?= {})
		
		current[last] = value
	
	# `TODO`: This is Angular-specific. Move it to where it belongs.	
	$get: -> this
	