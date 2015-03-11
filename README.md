## Shrub

**See the full documentation at http://cha0s.github.io/shrub**

Shrub is a JavaScript (or CoffeeScript if you prefer) application
framework. [AngularJS](http://angularjs.org/) is used on the client-side, as
well as [Socket.IO](http://socket.io/), enabling real-time communication right
out of the box. The server is an [Express](http://expressjs.com)
[Node.js](http://nodejs.org/) server using
[Waterline](https://github.com/balderdashy/waterline) for storage.

Shrub is organized into [packages](packages) which implement [hooks](hooks),
as a means of communicating between each other and influencing the way the
entire application behaves.

Shrub handles generation (using [Grunt](http://gruntjs.com/)) of all Angular
boilerplate and more, to allow you to structure your application in a very
clean and consistent way. Packages can even implement
[a hook](http://cha0s.github.io/shrub/hooks/#gruntconfig) to define their own
build behavior.

The intention of Shrub is to allow you to build rich, powerful applications in
an elegant and structured way -- without needing to hack on or change Shrub's
core codebase. Everything you need should be doable by creating a new package.
If you find the opposite to be true, feel free to
[open an issue](https://github.com/cha0s/shrub/issues)!

Tutorials in general are a bit lacking at the moment, this will be soon be
remedied!

### Getting started

Here is an excerpt from the
[documentation](http://cha0s.github.io/shrub/guide/getting-started):

First off, you'll need to clone Shrub itself. Fire up your trusty terminal:

`git clone git://github.com/cha0s/shrub.git`

(obviously you can use a git management tool if you fancy that sort of thing,
not that there's anything wrong with that...)

Head into the directory you just cloned and issue:

`npm install`

The next step is to create a configuration file. Look in the `config` directory
and you will see a file called `default.settings.json`. Create a copy of that
file called `settings.json`. Shrub **requires** a configuration file at this
time, so this is not an optional step.

Finally, to build and run the code you can do this:

`DEBUG=shrub:* grunt execute`

You don't strictly need the `DEBUG=shrub:*` part, but we do that so it's easy
to see when the server is up and ready for connections (and preserving the
ability to skip using that and have the server output be silent for
production).

When you see `shrub:http Shrub HTTP server up and running on port 4201!`, that
means you can visit your site in the browser. Go ahead and visit
http://localhost:4201 and see your Shrub instance chugging along!

### TODO

See the [TODO list](http://cha0s.github.io/shrub/todos/).
