# Object-relational mapping

*This is mostly stubbed for the browser. I can't justify sending a 400k ORM
library to the client, even though it would be awesome.*

    Promise = require 'bluebird'

    pkgman = require 'pkgman'

    collections = {}

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubAngularService`.

      registrar.registerHook 'shrubAngularService', -> [
        '$http'
        ($http) ->

          service = {}

          exports.initialize()

## orm.collection

* (String) `identity` - Collection identity. e.g. `'shrub-user'`

*Get a collection by identity.*

          service.collection = (identity) -> collections[identity]

## orm.collections

*Get all collections.*

          service.collections = -> collections

          service

      ]

    exports.initialize = ->

#### Invoke hook `shrubOrmCollections`.

      collections_ = {}
      for collectionList in pkgman.invokeFlat 'shrubOrmCollections'
        for identity, collection of collectionList

Collection defaults.

          collection.identity ?= identity
          collections_[collection.identity] = collection

Instantiate a model with defaults supplied.

          collection.instantiate = (values = {}) ->
            model = JSON.parse JSON.stringify values

            for key, value of @attributes
              continue unless value.defaultsTo?

Set any model defaults.

              model[key] ?= if 'function' is typeof value.defaultsTo
                value.defaultsTo.call model
              else
                JSON.parse JSON.stringify value.defaultsTo

            model

#### Invoke hook `shrubOrmCollectionsAlter`.

      pkgman.invoke 'shrubOrmCollectionsAlter', collections_

      collections = collections_
