# Object-relational mapping

*Tools for working with [Waterline](https://github.com/balderdashy/waterline).*

    config = require 'config'
    pkgman = require 'pkgman'

    Waterline = null

    collections = {}
    connections = {}

    waterline = null

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `preBootstrap`.

      registrar.registerHook 'preBootstrap', ->

        Waterline = require 'waterline'

#### Implements hook `bootstrapMiddleware`.

      registrar.registerHook 'bootstrapMiddleware', ->

        waterline = new Waterline()

        label: 'Bootstrap ORM'
        middleware: [

          (next) -> exports.initialize next

        ]

#### Implements hook `gruntConfig`.

      registrar.registerHook 'gruntConfig', (gruntConfig) ->

        gruntConfig.configureTask 'copy', 'shrub-orm', files: [
          src: '**/*'
          dest: 'app'
          expand: true
          cwd: "#{__dirname}/app"
        ]

        gruntConfig.configureTask(
          'watch', 'shrub-orm'

          files: [
            "#{__dirname}/app/**/*"
          ]
          tasks: 'build:shrub-orm'
        )

        gruntConfig.registerTask 'build:shrub-orm', [
          'newer:copy:shrub-orm'
        ]

        gruntConfig.registerTask 'build', ['build:shrub-orm']

#### Implements hook `packageSettings`.

      registrar.registerHook 'packageSettings', ->

The available adapters. This is a list of module names. We provide sails-redis
by default.

        adapters: [
          'sails-redis'
        ]

The available connnections. This is a keyed list of available connections
which are defined as an adapter and the configuration for the adapter. The
entries in the `adapters` list are available for use here. We provide a `shrub`
connection by default, which uses the sails-redis adapter with defaults.

        connections:

          shrub:

            adapter: 'sails-redis'
            port: 6379
            host: 'localhost'
            password: null
            database: null

#### Implements hook `replContext`.

Provide ORM to the REPL context.

      registrar.registerHook 'replContext', (context) -> context.orm = exports

## initialize

* (Function) `fn` - Nodeback called when initialization completes.

*Spin up Waterline with our configuration.*

    exports.initialize = (fn) ->

      config_ = config.get 'packageSettings:shrub-orm'

      waterlineConfig = adapters: {}, connections: {}

`require` all the adapter modules.

      for adapter in config_.adapters
        waterlineConfig.adapters[adapter] = require adapter

      waterlineConfig.connections = config_.connections

#### Invoke hook `collections`.

      collections_ = {}
      for collectionList in pkgman.invokeFlat 'collections', waterline
        for identity, collection of collectionList

Set collection defaults.

          collection.connection ?= 'shrub'
          collection.identity ?= identity
          collections_[collection.identity] = collection

## Collection#instantiate.

* (Object) `values` - An object with values to populate the model properties.

*Instantiate a model with defaults supplied.*

          collection.instantiate = (values = {}) ->

            for key, value of @attributes
              continue unless value.defaultsTo?

Set any model defaults.

              values[key] ?= if 'function' is typeof value.defaultsTo
                value.defaultsTo.call values
              else
                JSON.parse JSON.stringify value.defaultsTo

Reach into Waterline a bit, hackish but they simply don't provide us with a
sane API for this.

            new @_model @_schema.cleanValues @_transformer.serialize values

#### Invoke hook `collectionsAlter`.

      pkgman.invoke 'collectionsAlter', collections_, waterline

Load the collections into Waterline.

      waterlineConfig.collections = for i, collection of collections_
        Waterline.Collection.extend collection

      waterline.initialize waterlineConfig, (error, data) ->
        return fn error if error?

        collections = data.collections
        connections = data.connections

        fn()

## collection

* (String) `identity` - Collection identity. e.g. `'shrub-user'`

*Get a collection by identity.*

    exports.collection = (identity) -> collections[identity]

## collections

*Get all collections.*

    exports.collections = -> collections

## connections

*Get all connections.*

    exports.connections = -> connections

## teardown

* (Function) `fn` - Nodeback called after teardown.

*Tear down Waterline.*

    exports.teardown = (fn) -> waterline.teardown fn

## waterline

*Get the Waterline instance.*

    exports.waterline = -> waterline
