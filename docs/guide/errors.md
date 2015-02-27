Shrub provides a mechanism to define errors that can be transmitted over the
wire.

This is accomplished by subclassing
[`TransmittableError`](source/client/modules/errors/#transmittableerror). Let's
look at an example.

Say we'd like to implement an error saying that one user can't add another
user as a friend. We might implement that like so:

```javascript
var TransmittableError = require('errors').TransmittableError;

function FriendRequestError(message, addingUserName, addedUserName) {
  TransmittableError.apply(this, arguments);

  this.addingUserName = addingUserName;
  this.addedUserName = addedUserName;
}

FriendRequestError.prototype = new TransmittableError();
FriendRequestError.prototype.key = 'friendRequest';
FriendRequestError.prototype.template = ':message :addingUserName cannot add :addedUserName as a friend!';
FriendRequestError.prototype.toJSON = function() {
  return {
    key: this.key,
    message: this.message,
    addingUserName: this.addingUserName,
    addedUserName: this.addedUserName
  };
};
```

We now have our friend request error! You'll want to return it (in an array)
from your package's implementation of
[`shrubTransmittableErrors`](hooks/#shrubtransmittableerrors).

You can instantiate one of these errors:

```javascript
var errors = require('errors');
var error = errors.instantiate('friendRequest', 'Friend request error!', 'Alice', 'Bob');
```

Notice the arguments to `errors.instantiate` are first the key, followed by
the arguments defined by your subclass constructor.

To see the error output you could do something like:

```javascript
var errors = require('errors');
console.error(errors.message(error));
```

which would output:

```markdown
Friend request error! Alice cannot add Bob as a friend!
```

You might be wondering, why is the 'message' formatting function on `errors`
instead of a method on `TransmittableError`? The reason is because
`errors.message` is designed to work not only if you pass it an instance of
`TransmittableError`, but also instances of `Error`, as well as primitive
types.

You can view the stack of any error in a similar way:

```javascript
var errors = require('errors');
console.error(errors.stack(error));
```

The real joy of `TransmittableError` subclasses comes from the fact that you
can throw or return them from an implementation of
[`shrubRpcRoutes`](hooks/#shrubrpcroutes) and they will be automatically
serialized and reified on the client side so they can be presented to the
user in a meaningful way.
