How could Shrub be complete without an implementation of a simple TODO list? It
would be unthinkable! So that's exactly what this document is going to
describe.

If you haven't yet, read the [getting started guide](guide/getting-started/)
and get yourself a working copy of Shrub. I'll wait.

!!! note "Can't contain your excitement?"
    If you would like to skip all this and just get to trying out a fully
    formed TODO list, [check out the TL;DR](examples/todo-list/#tldr)

The TODO list will be implemented as a Shrub package. This means we're going to
create a package and enable it.

Your Shrub installation includes a `custom` directory. Within it we will create
our TODO package. Create a directory and file structure like this:

```bash
YOUR_SHRUB_DIRECTORY/custom/todo-list/index.js
YOUR_SHRUB_DIRECTORY/custom/todo-list/client/index.js
YOUR_SHRUB_DIRECTORY/custom/todo-list/client/item.js
YOUR_SHRUB_DIRECTORY/custom/todo-list/client/list.js
YOUR_SHRUB_DIRECTORY/custom/todo-list/client/new.js
```

We'll go through one at a time and talk about what goes in these files. I will
Mostly show the source code, punctuated by commentary when necessary.

Lets start with the top-level index.js file. This is the code that will run on
the server. In fact, everything except files in the `client` directory are only
available on the server. The `client` directory is available to the server as
well, but the reverse doesn't apply: **the client has no access to anything
outside the `client` directory.**

First off, we'll start with the package manager's entry point. This is defined
for every package file which implements hooks.

```javascript

// Entry point for package management. Every package defining hooks does so
// through the registrar passed to `exports.pkgmanRegister`.
exports.pkgmanRegister = function(registrar) {

```

`pkgman` will pass in a registrar which is used to register hooks and point to
subpackage files. More on the latter to come.

Let's implement a model that will represent our TODO list items. See
[the documentation for `shrubOrmCollections`](hooks/#shrubormcollections) for
details.

```javascript

  // Implements hook `shrubOrmCollections`.
  registrar.registerHook('shrubOrmCollections', function() {

    // Return an object whose keys determine the name of the collection in the
    // system, and whose values are Waterline configuration.
    return {

      // We're only defining a TODO list item model since we only have one
      // global list in this example. It'd be possible to create a `todo-list`
      // model and associate the `todo-list-item`s with it, but we opt for
      // simplicity.
      'todo-list-item': {

        attributes: {

          // Whether the item is marked as completed.
          isCompleted: {
            type: 'boolean',
            defaultsTo: false
          },

          // The item text, e.g. "Make a TODO example for Shrub".
          text: {
            type: 'string'
          }
        }
      }
    };
  });

```

This registers a model named `todo-list-item` in the ORM so we can create,
read, update, and delete instances.

Finally, we'll create some RPC routes. These are the endpoints that the client
communicates with. We'll create RPC routes for retrieving all TODO items,
creating an item, updating an item, and deleting an item.

```javascript

  // Implements hook `shrubRpcRoutes`.
  registrar.registerHook('shrubRpcRoutes', function() {

    var routes = [];

    // Get our collection.
    var TodoListItem = require('shrub-orm').collection('todo-list-item');

```

First, the route to retrieve all items.

```javascript

    // This route will be hit when a client first connects, to give them a
    // snapshot of the current TODO list.
    routes.push({
      path: 'todo-list',

      // Route middleware can be a single function. It will be normalized into
      // array form internally by the time shrubRpcRoutesAlter is invoked.
      middleware: function(req, res, next) {

        // Get the TODO list items, sorted by when they were created.
        TodoListItem.find().sort('createdAt DESC').then(function(items) {

          // Send the client the items.
          res.end(items);
        });
      }
    });

```

Next, the route when an item is to be created.

```javascript

    // This route will be hit when a client wants to create a new item.
    routes.push({
      path: 'todo-list-item/create',

      // Route middleware can also be defined as an array. In this route, we
      // will handle validation before the main creation function is invoked.
      middleware: [

        // Validator. If next(error) is called here, the main creation function
        // will never be invoked.
        function(req, res, next) {

          // Text must not be empty.
          if (!req.body.text) {

            // Passing an error to next will return it to the client.
            return next(new Error("Item text must not be empty!"));
          }

          // Continue on normally to the next middleware function.
          next();
        },

        function(req, res, next) {

          var item = {text: req.body.text};

          TodoListItem.create(item).then(function(item) {

```

Here we work around a quirk in Waterline: when sending any models over the wire
to the client, the `toJSON` method must be stripped out of the model, or else
the message won't be sent and a nasty exception will be raised.

```javascript

            // Work around waterline weirdness. You must remove the toJSON
            // method from all models returned from Waterline before sending
            // over a socket to prevent a stack overflow, because
            // model.toJSON() returns an object that also has a toJSON method,
            // and msgpack (used by socket.io) will recur until stack space
            // is exhausted.
            item.toJSON = undefined;

            // Send the client the new item.
            res.end(item);

            // Notify other clients of the creation.
            req.socket.broadcast.to('$global').emit(
              'todo-list-item/create', item
            );
          }).catch(next);
        }
      ]
    });

```

When an item is to be updated.

```javascript

    // This route will be hit when a client wants to update an item.
    routes.push({
      path: 'todo-list-item/update',
      middleware: [

        // Validator.
        function(req, res, next) {

          // ID must be set.
          if (!req.body.id) {
            return next(new Error("ID must be supplied when updating a TODO item!"));
          }

          // Either text or isCompleted must be set.
          if (!req.body.text && !req.body.isCompleted) {
            return next(new Error("Item text or isCompleted must be set when updating a TODO item!"));
          }

          next();
        },

        function(req, res, next) {

          // Update the item with the values in the request body.
          TodoListItem.update({id: req.body.id}, req.body).then(function(items) {
            items[0].toJSON = undefined;

            // Send the client the updated item.
            res.end(items[0]);

            // Notify other clients of the update.
            req.socket.broadcast.to('$global').emit(
              'todo-list-item/update', items[0]
            );
          }).catch(next);
        }
      ]
    });

```

Finally, when an item is to be deleted.

```javascript

    // This route will be hit when a client wants to delete an item.
    routes.push({
      path: 'todo-list-item/delete',
      middleware: [

        // Validator.
        function(req, res, next) {

          // ID must be set.
          if (!req.body.id) {
            return next(new Error("ID must be supplied when deleting a TODO item!"));
          }

          next();
        },

        function(req, res, next) {

          // Destroy by ID.
          TodoListItem.destroy({id: req.body.id}, req.body).then(function() {

            // Finish the request.
            res.end();

            // Notify other clients of the deletion.
            req.socket.broadcast.to('$global').emit(
              'todo-list-item/delete', {id: req.body.id}
            );
          }).catch(next);
        }
      ]
    });

    return routes;
  });
};
```

That's it for the server code. Next, we'll go over the client code. Let's start
with client/index.js.

# TL;DR

A repository containing the TODO list package can be found at
[https://github.com/cha0s/shrub-todo-list](https://github.com/cha0s/shrub-todo-list).
You may clone it into the `custom` directory like so:

```bash
cd YOUR_SHRUB_DIRECTORY/custom
git clone https://github.com/cha0s/shrub-todo-list.git todo-list
```

After you do so, edit config/settings.json like so:

```json
...
    "shrub-user",
    "shrub-villiany",
    "todo-list"
  ],
  "packageSettings": {
...
```

You're good to go now, just the usual rigamarole for running in development
mode:

```bash
DEBUG=shrub:* grunt execute
```

Enjoy! Come on back and read more thoroughly afterward if you'd like.
