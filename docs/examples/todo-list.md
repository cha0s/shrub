How could Shrub be complete without an implementation of a simple TODO list? It
would be unthinkable! So that's exactly what this document is going to
describe.

If you haven't yet, read the [getting started guide](guide/getting-started/)
and get yourself a working copy of Shrub. I'll wait.

!!! note "Can't contain your excitement?"
    If you would like to skip all this and just get to trying out a fully
    formed TODO list,
    [check out the executive summary](examples/todo-list/#executive-summary)

# Create the package

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

<h1>The source</h1>

## index.js

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

        // Create an item.
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

        // Update an item.
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

        // Delete an item.
        function(req, res, next) {

          // Destroy by ID.
          TodoListItem.destroy({id: req.body.id}).then(function() {

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

That's it for the server code.

## client/index.js

Next, we'll go over the client code. Let's start with client/index.js.

As before, we register with the package manager.

```javascript

exports.pkgmanRegister = function(registrar) {

```

Similar to the server, we define routes on the client. These are called
Angular routes and they represent the paths that a user can visit in their
browser. We create a path for /todo and specify the template HTML to render.

```javascript

  // Define a route in our Angular app for the TODO list.
  registrar.registerHook('shrubAngularRoutes', function() {
    var routes = [];

    // This is our main /todo path.
    routes.push({
      path: 'todo',

      // The window title shown for this path.
      title: 'TODO',

      // Show our top-level directives. Directive names default to reflect the
      // package structure, with the 'client' path removed and all non-word
      // characters converted to dashes. So the directive defined at
      // todo-list/client/list.js will default to todo-list-list, and the
      // directive defined at todo-list/client/new.js will default to
      // todo-list-new.
      //
      // We prepend the data- prefix to all custom attributes as a best
      // practice -- though it isn't strictly necessary, it ensures the HTML
      // is valid.
      template: '                       \
        <div data-todo-list-list></div> \
        <div data-todo-list-new></div>  \
      '
    });

    return routes;
  });

```

Shrub lets us write code for angular without having to worry about boilerplate.
We're now going to implement an Angular service to manage our TODO list.

```javascript

  // Define a service to manage our TODO list. Service names are derived from
  // the path, similar to directives  (explained above). The difference is,
  // slashes are not removed from the service name. In other words, a package
  // with a structure like some-package/client/system/things.js would provide
  // a service named some-package/system/things
  registrar.registerHook('shrubAngularService', function() {

    // We return an annotated function, just like if we were using Angular
    // directly. In this case we are using array notation.
    return [

      // We communicate with the server over RPC.
      'shrub-rpc',

      function(rpc) {

        var service = {

          // The array of TODO items.
          items: []
        };

```

Implement the service's methods.

```javascript

        // Create a TODO item.
        service.create = function(text) {

          // RPC calls return a promise.
          rpc.call('todo-list-item/create', {text: text}).then(function(item) {
            service.items.push(item);
          });
        };

        // Update a TODO item.
        service.update = function(item) {
          rpc.call('todo-list-item/update', item).then(function(updated) {
            item.text = updated.text;
            item.isCompleted = updated.isCompleted;
          });
        };

        // Delete a TODO item.
        service.delete = function(item) {
          rpc.call('todo-list-item/delete', {id: item.id}).then(function() {
            var index = service.items.indexOf(item);
            if (~index) service.items.splice(index, 1);
          });
        };

```

Set up event listeners. The server will communicate with us to let us know when
other clients have created, updated, or deleted TODO items.

```javascript

        // Server told us to create an item.
        rpc.on('todo-list-item/create', function(item) {
          service.items.push(item);
        });

        // Server told us to update an item.
        rpc.on('todo-list-item/update', function(item) {
          for (var i in service.items) {
            if (item.id === service.items[i].id) {
              service.items[i].text = item.text;
              service.items[i].isCompleted = item.isCompleted;
            }
          }
        });

        // Server told us to delete an item.
        rpc.on('todo-list-item/delete', function(item) {
          for (var i in service.items) {
            if (item.id === service.items[i].id) {
              return service.items.splice(i, 1);
            }
          }
        });

```

Finally, we will load all the TODO items from the server when the service is
first instantiated. In other words, when the user visits /todo for the first
time.

```javascript

        // Immediately retrieve the TODO items and populate the list.
        rpc.call('todo-list').then(function(items) {
          items.forEach(function(item) {
            service.items.push(item);
          });
        });

        return service;
      }
    ];
  });

```

The following is not ideal, however Shrub has yet to implement a menu API. This
is a temporary situation where we need to hook directly into the skin's
navigation directive link function and add our route to the navigation menu.

I know it's ugly and there will be a menu API that is skin-agnostic eventually.

```javascript

  // Hook into the main navigation and add our path. This is admittedly not
  // ideal, in lieu of a proper menu API.
  registrar.registerHook('shrubSkinLink--shrubSkinStrappedMainNav', function() {
    return [
      '$scope', function($scope) {
        $scope.menu.items.push({path: 'todo', label: 'TODO'})
      }
    ];
  });

```

Our first encounter with `registrar.recur`. By default, Shrub does not
traverse all files in your package for inclusion as this is inefficient and
removes your decision whether some files should be included and some not.

To notify the package manager which other files should be included, use
`registrar.recur`. In this case we will be including all other files in the
client directory.

```javascript

  // Recur into subpackages.
  registrar.recur([
    'item', 'list', 'new'
  ]);
};
```

## client/item.js

Moving on to client/item.js, the file that manages the display of an individual
TODO item. This is where the meat of the user interaction occurs.

```javascript

exports.pkgmanRegister = function(registrar) {

```

Just as with services, we can define Angular directives. We define one to show
a TODO item.

```javascript

  // Define a directive to display a TODO item. This is where most of the user
  // interaction occurs.
  registrar.registerHook('shrubAngularDirective', function() {

    return [

      // Inject the window object so we can focus the input when editing.
      '$window',

      // Inject our TODO list service.
      'todo-list',

      function ($window, todoList) {

        var directive = {};

```

Although Shrub augments directives with additional functionality, the
definition object is the same one you know and love. Here we set the scope
and link function just as in Angular directly.

```javascript

        // Require an item to be passed in.
        directive.scope = {
          item: '='
        };

        // Define link function just how you would in Angular directly.
        directive.link = function(scope) {

          // Keep track of the original text value when editing, to check
          // whether we need to update the server or not.
          var originalText = '';

```

Here we use the form API to create the form for viewing an item.

```javascript

          // The form displayed when the user is viewing a TODO item.
          scope.viewingForm = {

            // Store the item in the form so fields can access it.
            item: scope.item,

            // The fields object defines all the form fields for this form.
            // By default, the fields' names are derived from the key, unless
            // explicitly overridden.
            fields: {

              // The TODO item text. This is a markup field, its value is
              // markup which goes through Angular's $compile and is linked
              // against the field scope.
              text: {
                type: 'markup',

                // Keep a style object in the field for applying dynamic CSS.
                style: {},

                // Bind the markup to the TODO item's text field, and apply
                // styles based on our style object (above).
                value: '                          \
                  <span                           \
                    data-ng-bind="form.item.text" \
                    data-ng-style="field.style"   \
                  ></span>                        \
                ',
              },

              // Below each TODO item text are actions to manipulate the item.
              // This is a group field, meaning all fields under this field
              // will be displayed inline.
              actions: {
                type: 'group',
                fields: {

                  // Submit button to edit the TODO item.
                  edit: {
                    type: 'submit',
                    value: 'Edit'
                  },

                  // Submit button to delete the TODO item.
                  'delete': {
                    type: 'submit',
                    value: 'Delete'
                  },

                  // A checkbox displaying and controlling whether the TODO
                  // item has been completed.
                  isCompleted: {
                    type: 'checkbox',
                    label: 'Completed',

                    // Link its value directly to the TODO item's isCompleted
                    // property.
                    model: 'form.item.isCompleted',

                    // This function is invoked when the field's value changes.
                    // By the time change() is called, the scope digest is
                    // completed, so the value will be propagated to the model.
                    change: function(isCompleted) {
                      todoList.update(scope.item);
                    }
                  }
                }
              }
            },

            // Form submission function. submits can be an array as well, with
            // each function being invoked upon form submission. Internally
            // it will always be normalized to an array before invoking
            // shrubFormAlter.
            submits: function(values, form) {

              // The special value form.$submitted will be populated with the
              // field that stimulated the submission. In other words, if you
              // click 'edit', form.$submitted will be the edit button's field
              // instance.
              switch (form.$submitted.name) {

                // User wants to edit the item. Change the editing state.
                case 'edit':
                  scope.isEditing = true;
                  break;

                // User wants to delete the TODO item. Just do it.
                case 'delete':
                  todoList.delete(scope.item);
                  break;
              }
            }
          };

```

We create a form for editing an item.

```javascript

          // The form displayed when the user is editing a TODO item.
          scope.editingForm = {
            item: scope.item,
            fields: {

              // A textfield where the user will type in the updated item text.
              text: {
                type: 'text',
                label: 'Update',

                // Link its value directly to the item text.
                model: 'form.item.text',

                // You can specify arbitrary HTML attributes. In this case, we
                // will set a unique ID for each item's text field, so we can
                // target it for focus when initiating the edit process for an
                // item.
                attributes: {
                  id: 'edit-text-' + scope.item.id
                }
              },

              // Submit button for updating the item once editing is complete.
              update: {
                type: 'submit',
                value: 'Update'
              },
            },

            // Here we use the array form for submits just to prove that it can
            // be done.
            submits: [

              // Values is an object which has field names as keys and field
              // values as values.
              function(values) {

                // Check the new item text against the original text. If it
                // changed, update the item.
                if (values.text !== originalText) {
                  todoList.update(scope.item);
                }

                // Change the editing state.
                scope.isEditing = false;
              }
            ]
          };

```

Everything inside the link function is as you would expect, the scope is
Angular's scope object, so we can do everything we're used to, like watching
for changes.

```javascript

          // Watch the editing state for changes.
          scope.$watch('isEditing', function (isEditing) {

            // We only care if we're editing.
            if (!isEditing) return;

            // Remember the item's original text.
            originalText = scope.item.text;

            // The moment isEditing updates, the DOM won't be fully
            // transformed, meaning the edit form will not be visible yet.
            //
            // scope.$$postDigest is a little Angular hack that lets you
            // register a function to run after the scope digest cycle is
            // completed. This is exactly what we have to wait for to ensure
            // that the DOM is mutated and the edit form is visible.
            scope.$$postDigest(function() {

              // Look up our edit control and focus/select the text
              // automatically.
              $window.document.getElementById(
                'edit-text-' + scope.item.id
              ).select();
            });
          });

          // Watch the item's isCompleted property.
          scope.$watch('item.isCompleted', function (isCompleted) {

            // Make the text really big. We could of course use CSS to do this
            // and should, but this is just a demo and I'm lazy.
            var style = {'font-size': '30px'};

            // If the item was completed, strike a line through the text.
            if (isCompleted) {
              style['text-decoration'] = 'line-through';
            }

            // Set the style into the form field's style object.
            scope.viewingForm.fields.text.style = style;
          });
        };

```

We define the output HTML for our directive, switching between the two forms
based on the state of `isEditing`.

```javascript

        // We control which form is showing by using the ngIf directive. Forms
        // are displayed with the shrub-form directive, and the form definition
        // object is passed in through the form attribute on each directive.
        directive.template = '        \
          <div                        \
            data-ng-if="!isEditing"   \
          >                           \
            <div                      \
              data-shrub-form         \
              data-form="viewingForm" \
            ></div>                   \
          </div>                      \
          <div                        \
            data-ng-if="isEditing"    \
          >                           \
            <div                      \
              data-shrub-form         \
              data-form="editingForm" \
            ></div>                   \
          </div>                      \
        ';

        return directive;
      }
    ];
  });
};
```

## client/list.js

Next we will look at client/list.js, where we will define a directive that
wraps the TODO list and renders a list of items. This one is pretty simple.

```javascript

exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('shrubAngularDirective', function() {

    return [

      'todo-list',

      function(todoList) {

        var directive = {};

        directive.scope = {};

        // Make the TODO list accessible to our directive.
        directive.link = function(scope) {
          scope.todoList = todoList;
        };

        // Use the TODO list items to build an unordered list. Each list item
        // receives the corresponding TODO item.
        directive.template = '                                       \
          <ul                                                        \
            data-ng-repeat="item in todoList.items track by item.id" \
          >                                                          \
            <li                                                      \
              data-todo-list-item                                    \
              data-item="item"                                       \
            ></li>                                                   \
          </ul>                                                      \
        ';

        return directive;
      }

    ];
  });
};
```

## client/new.js

Finally, we'll define the directive for creating a new TODO item. Everything
here is rehashing concepts we have reviewed earlier, so it should be easy to
follow.

```javascript

exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('shrubAngularDirective', function() {

    return [

      'todo-list',

      function(todoList) {

        var directive = {};

        directive.scope = {};

        directive.link = function(scope) {

          // The form to add a new item.
          scope.form = {
            fields: {
              group: {
                type: 'group',
                fields: {

                  // The textfield for the new item's text.
                  text: {
                    type: 'text',
                    label: 'Create a new TODO item'
                  },

                  // Submit button to create the item.
                  submit: {
                    type: 'submit',
                    value: 'Create new item'
                  }
                }
              }
            },
            submits: function (values, form) {

              // Create the TODO item.
              todoList.create(values.text);

              // Blank out the text field.
              form.fields.group.fields.text.value = '';
            }
          };
        };

        directive.template = ' \
          <div                 \
            data-shrub-form    \
            data-form="form"   \
          ></div>              \
        '

        return directive;
      }

    ];
  });
};
```

# Executive summary

If you'd rather not type or copy/paste all the code here manually, a repository
containing the TODO list package can be found at
[https://github.com/cha0s/shrub-todo-list](https://github.com/cha0s/shrub-todo-list).

## Clone the repository

You may clone it into the `custom` directory like so:

```bash
cd YOUR_SHRUB_DIRECTORY/custom
git clone https://github.com/cha0s/shrub-todo-list.git todo-list
```

## Add the package to the configuration settings.

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

## Spin it up

You're good to go now, just the usual rigamarole for running in development
mode:

```bash
DEBUG=shrub:* grunt execute
```

Enjoy!
