# # Server configuration
#
# *Manages server and package configuration.*
#
# ###### TODO: Rename all config `key` uses to `path`.
debug = require('debug') 'shrub:config'
nconf = require 'nconf'
fs = require 'fs'

yaml = require 'js-yaml'

pkgman = require 'pkgman'

{Config} = require 'client/modules/config'

# ## config.get
#
# * (string) `key` - The key whose value to get.
#
# *Get a configuration value.*
exports.get = (key) -> nconf.get key

# ## config.has
#
# * (string) `key` - The key to check.
#
# *Check if a configuration key exists.*
exports.has = (key) -> nconf.has key

# ## config.load
#
# *Load configuration from the settings file and set package defaults.*
exports.load = ->

  # Ensure the configuration file exists.
  unless fs.existsSync settingsFilename = './config/settings.yml'
    throw new Error 'Settings file not found! You should copy config/default.settings.yml to config/settings.yml'

  settings = yaml.safeLoad fs.readFileSync settingsFilename, 'utf8'
  settings.path = "#{__dirname}/.."

  nconf.argv().env().overrides settings

  return

# ## config.loadPackageSettings
#
# *Load package settings as defaults in the configuration.*
exports.loadPackageSettings = ->

  # Register packages.
  debug 'Registering packages...'

  pkgman.registerPackageList nconf.get 'packageList'

  debug 'Packages registered.'

  # ###### TODO: Unify config key on `'packages'`.
  packageSettings = new Config()
  for key, value of pkgman.invoke 'shrubConfigServer'
    packageSettings.set key.replace(/\//g, ':'), value

  nconf.defaults

    # #### Invoke hook `shrubConfigServer`.
    packageSettings: packageSettings.toJSON()

    path: "#{__dirname}/.."

  return

# ## config.set
#
# * (string) `key` - The key whose value to set.
#
# *Set a configuration value.*
exports.set = (key, value) -> nconf.set key, value