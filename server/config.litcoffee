# Server configuration

*Manages server and package configuration.*

###### TODO: Rename all config `key` uses to `path`.

    debug = require('debug') 'shrub:config'
    nconf = require 'nconf'
    fs = require 'fs'

    pkgman = require 'pkgman'

    {Config} = require 'client/modules/config'

## config.get

* (string) `key` - The key whose value to get.

*Get a configuration value.*

    exports.get = (key) -> nconf.get key

## config.has

* (string) `key` - The key to check.

*Check if a configuration key exists.*

    exports.has = (key) -> nconf.has key

## config.load

*Load configuration from the settings file and set package defaults.*

    exports.load = ->

Ensure the configuration file exists.

      unless fs.existsSync settingsFilename = './config/settings.json'
        throw new Error 'Settings file not found! You should copy config/default.settings.json to config/settings.json'

      nconf.argv().env().file settingsFilename

      nconf.defaults path: "#{__dirname}/.."

      return

## config.loadPackageSettings

*Load package settings as defaults in the configuration.*

    exports.loadPackageSettings = ->

Register packages.

      debug 'Registering packages...'

      pkgman.registerPackageList nconf.get 'packageList'

      debug 'Packages registered.'

      packageSettings = new Config()
      for key, value of pkgman.invoke 'packageSettings'
        packageSettings.set key.replace(/\//g, ':'), value

      nconf.defaults

#### Invoke hook `packageSettings`.

Invoked when the server application is loading configuration. Allows
packages to define their own default settings.

        packageSettings: packageSettings.toJSON()

        path: "#{__dirname}/.."

      return

## config.set

* (string) `key` - The key whose value to set.

*Set a configuration value.*

    exports.set = (key, value) -> nconf.set key, value