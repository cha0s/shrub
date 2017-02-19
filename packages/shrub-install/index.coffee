# # Installation
#
# *Install shrub if it hasn't been done so yet. This is essentially a hack for
# now, but will be fleshed out as we go.*

{defaultLogger} = require 'logging'
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubCoreBootstrapMiddleware`.
  registrar.registerHook 'shrubCoreBootstrapMiddleware', (context) ->

    orm = require 'shrub-orm'

    label: 'Installation'
    middleware: [

      (next) ->

        # No superuser? Install...
        #
        # ###### TODO: There should be a more robust check than just 'is there a superuser?'.
        User = orm.collection 'shrub-user'
        User.findOne(id: 1).then((user) ->
          return if user?

          reinstall()

        ).then(-> next()).catch next

    ]

  # #### Implements hook `shrubReplContext`.
  registrar.registerHook 'shrubReplContext', (context) ->

    context.install = reinstall

reinstall = (name = 'admin', email = 'admin@example.com', password = 'admin') ->

  Promise = require 'bluebird'

  orm = require 'shrub-orm'

  # Refresh all collections.
  Promise.all(

    # Drop all collections and data.
    for identity, collection of orm.collections()
      new Promise (resolve, reject) ->
        collection.drop (error) ->
          return reject error if error?
          resolve()

  ).then(->

    # Teardown the schema.
    new Promise (resolve, reject) ->
      orm.teardown (error) ->
        return reject error if error?
        resolve()

  ).then(->

    # Rebuild the schema.
    new Promise (resolve, reject) ->
      orm.initialize (error) ->
        return reject error if error?
        resolve()

  ).then(->

    {
      'shrub-group': Group
      'shrub-user': User
      'shrub-user-local': UserLocal
    } = orm.collections()

    Promise.all [

      # Create groups.
      Group.create name: 'Anonymous'
      Group.create name: 'Authenticated'
      Group.create name: 'Administrator'

      # Create superuser.
      UserLocal.register(name, email, password).bind({}).then((@localUser) ->

        User.create()

      ).then (user) ->

        user.instances.add(
          model: 'shrub-user-local'
          modelId: @localUser.id
        )

        return user

    ]

  ).then(([groups..., user]) ->

    user.groups.add group: groups[2].id
    user.save()

  ).then(->

    defaultLogger.error "No site installed, so installed one."

  ).catch console.error
