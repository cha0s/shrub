# Server configuration

*Manages server and package configuration.*

```coffeescript
debug = require('debug') 'shrub:config'
nconf = require 'nconf'
fs = require 'fs'

yaml = require 'js-yaml'

pkgman = require 'pkgman'

{Config} = require 'client/modules/config'
```

## config.get

* (string) `path` - The path whose value to get.

*Get a configuration value.*

```coffeescript
exports.get = (path) -> nconf.get path
```

## config.has

* (string) `path` - The path to check.

*Check if a configuration path exists.*

```coffeescript
exports.has = (path) -> nconf.has path
```

## config.load

*Load configuration from the settings file and set package defaults.*

```coffeescript
exports.load = ->
```

Ensure the configuration file exists.

```coffeescript
  unless fs.existsSync settingsFilename = './config/settings.yml'
    throw new Error 'Settings file not found! You should copy config/default.settings.yml to config/settings.yml'

  settings = yaml.safeLoad fs.readFileSync settingsFilename, 'utf8'
  settings.path = "#{__dirname}/.."

  nconf.argv().env().overrides settings

  return
```

## config.loadPackageSettings

*Load package settings as defaults in the configuration.*

```coffeescript
exports.loadPackageSettings = ->
```

Register packages.

```coffeescript
  debug 'Registering packages...'

  pkgman.registerPackageList nconf.get 'packageList'

  debug 'Packages registered.'

  packageConfig = new Config()
  for path, value of pkgman.invoke 'shrubConfigServer'
    packageConfig.set path.replace(/\//g, ':'), value

  nconf.defaults
```

#### Invoke hook [`shrubConfigServer`](../../hooks#shrubconfigserver)

```coffeescript
    packageConfig: packageConfig.toJSON()

    path: "#{__dirname}/.."

  return
```

## config.set

* (string) `path` - The path whose value to set.

*Set a configuration value.*

```coffeescript
exports.set = (path, value) -> nconf.set path, value
```
