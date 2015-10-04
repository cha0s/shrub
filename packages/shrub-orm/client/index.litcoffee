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

            if not @autoCreatedAt? or @autoCreatedAt is true
              model.createdAt = new Date values.createdAt ? Date.now()

            if not @autoUpdatedAt? or @autoUpdatedAt is true
              model.updatedAt = new Date values.updatedAt ? Date.now()

            for key, value of @attributes

Set functions.

              model[key] = value if 'function' is typeof value

Set any model defaults.

              if value.defaultsTo?
                model[key] ?= if 'function' is typeof value.defaultsTo
                  value.defaultsTo.call model
                else
                  JSON.parse JSON.stringify value.defaultsTo

Handle dates.

              if model[key]? and 'date' is value or 'date' is value.type
                model[key] = new Date model[key]

            model

#### Invoke hook `shrubOrmCollectionsAlter`.

      pkgman.invoke 'shrubOrmCollectionsAlter', collections_

      collections = collections_
