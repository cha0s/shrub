# Installation

*Install shrub if it hasn't been done so yet. This is essentially a hack for
now, but will be fleshed out as we go.*

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubCoreBootstrapMiddleware`.

      registrar.registerHook 'shrubCoreBootstrapMiddleware', (context) ->

        orm = require 'shrub-orm'

        label: 'Installation'
        middleware: [

          (next) ->

No superuser? Install...

###### TODO: There should be a more robust check than just 'is there a superuser'.

            User = orm.collection 'shrub-user'
            User.findOne(id: 1).then((user) ->
              return if user?

              reinstall()

            ).then(-> next()).catch next

        ]

#### Implements hook `shrubReplContext`.

      registrar.registerHook 'shrubReplContext', (context) ->

        context.install = reinstall

    reinstall = (name = 'admin', email = 'admin@example.com', password = 'admin') ->

      Promise = require 'bluebird'

      orm = require 'shrub-orm'

Refresh all collections.

      Promise.all(

Drop all collections and data.

        for identity, collection of orm.collections()
          new Promise (resolve, reject) ->
            collection.drop (error) ->
              return reject error if error?
              resolve()

      ).then(->

Teardown and rebuild the schema.

        new Promise (resolve, reject) ->
          orm.teardown (error) ->
            return reject error if error?
            orm.initialize (error) ->
              return reject error if error?
              resolve()

      ).then(->

        Group = orm.collection 'shrub-group'
        User = orm.collection 'shrub-user'

        Promise.all [

Create groups.

          Group.create name: 'Anonymous'
          Group.create name: 'Authenticated'
          Group.create name: 'Administrator'

Create superuser.

          User.register name, email, password
        ]

      ).then(([groups..., user]) ->

        user.groups.add group: groups[2].id
        user.save().then()

      ).catch console.error
