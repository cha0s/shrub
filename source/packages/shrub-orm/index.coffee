# Object-relational mapping

*Tools for working with
[Waterline](https://github.com/balderdashy/waterline).*

```coffeescript
require('events').EventEmitter.prototype._maxListeners = 100

config = require 'config'
pkgman = require 'pkgman'

Waterline = null

collections = {}
connections = {}

waterline = null

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubCorePreBootstrap`](../../../hooks#shrubcoreprebootstrap)

```coffeescript
  registrar.registerHook 'shrubCorePreBootstrap', ->

    Waterline = require 'waterline'
```

#### Implements hook [`shrubCoreBootstrapMiddleware`](../../../hooks#shrubcorebootstrapmiddleware)

```coffeescript
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    waterline = new Waterline()

    label: 'Bootstrap ORM'
    middleware: [

      (next) -> exports.initialize next

    ]
```

#### Implements hook [`shrubGruntConfig`](../../../hooks#shrubgruntconfig)

```coffeescript
  registrar.registerHook 'shrubGruntConfig', (gruntConfig) ->

    gruntConfig.copyAppFiles "#{__dirname}/app", 'shrub-orm'

    gruntConfig.registerTask 'build:shrub-orm', [
      'newer:copy:shrub-orm'
    ]

    gruntConfig.registerTask 'build', ['build:shrub-orm']
```

#### Implements hook [`shrubConfigServer`](../../../hooks#shrubconfigserver)

```coffeescript
  registrar.registerHook 'shrubConfigServer', ->
```

The available adapters. This is a list of module names. We provide
sails-redis by default.

```coffeescript
    adapters: [
      'sails-redis'
    ]
```

The available connnections. This is a keyed list of available
connections which are defined as an adapter and the configuration for
the adapter. The entries in the `adapters` list are available for use
here. We provide a `shrub` connection by default, which uses the
sails-redis adapter with defaults.

```coffeescript
    connections:

      shrub:

        adapter: 'sails-redis'
        port: 6379
        host: 'localhost'
        password: null
        database: null
```

#### Implements hook [`shrubReplContext`](../../../hooks#shrubreplcontext)

Provide ORM to the REPL context.

```coffeescript
  registrar.registerHook 'shrubReplContext', (context) -> context.orm = exports
```

## orm.initialize

* (Function) `fn` - Nodeback called when initialization completes.

*Spin up Waterline with our configuration.*

```coffeescript
exports.initialize = (fn) ->

  config_ = config.get 'packageConfig:shrub-orm'

  waterlineConfig = adapters: {}, connections: {}
```

`require` all the adapter modules.

```coffeescript
  for adapter in config_.adapters
    waterlineConfig.adapters[adapter] = require adapter

  waterlineConfig.connections = config_.connections
```

#### Invoke hook [`shrubOrmCollections`](../../../hooks#shrubormcollections)

```coffeescript
  collections_ = {}
  for collectionList in pkgman.invokeFlat 'shrubOrmCollections', waterline
    for identity, collection of collectionList
```

Set collection defaults.

```coffeescript
      collection.connection ?= 'shrub'
      collection.identity ?= identity
      collection.migrate ?= 'create'
      collections_[collection.identity] = collection
```

## Collection#instantiate.

* (Object) `values` - An object with values to populate the model
properties.

*Instantiate a model with defaults supplied.*

```coffeescript
      collection.instantiate = (values = {}) ->

        for key, value of @attributes
          continue unless value.defaultsTo?
```

Set any model defaults.

```coffeescript
          values[key] ?= if 'function' is typeof value.defaultsTo
            value.defaultsTo.call values
          else
            JSON.parse JSON.stringify value.defaultsTo
```

Reach into Waterline a bit, hackish but they simply don't provide us
with a sane API for this.

```coffeescript
        new @_model @_schema.cleanValues @_transformer.serialize values
```

#### Invoke hook [`shrubOrmCollectionsAlter`](../../../hooks#shrubormcollectionsalter)

```coffeescript
  pkgman.invoke 'shrubOrmCollectionsAlter', collections_, waterline
```

Load the collections into Waterline.

```coffeescript
  for i, collection of collections_
    waterline.loadCollection Waterline.Collection.extend collection

  waterline.initialize waterlineConfig, (error, data) ->
    return fn error if error?

    collections = data.collections
    connections = data.connections

    fn()
```

## orm.collection

* (String) `identity` - Collection identity. e.g. `'shrub-user'`

*Get a collection by identity.*

```coffeescript
exports.collection = (identity) -> collections[identity]
```

## orm.collections

*Get all collections.*

```coffeescript
exports.collections = -> collections
```

## orm.connections

*Get all connections.*

```coffeescript
exports.connections = -> connections
```

## orm.teardown

* (Function) `fn` - Nodeback called after teardown.

*Tear down Waterline.*

```coffeescript
exports.teardown = (fn) -> waterline.teardown fn
```

## orm.waterline

*Get the Waterline instance.*

```coffeescript
exports.waterline = -> waterline
```
