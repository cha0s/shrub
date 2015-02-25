Welcome to Shrub, an opinionated full stack JavaScript web application
framework. In this guide, we'll go over how to set up a working Shrub instance
and outline some of the steps forward to build your application.

**NOTE:** Shrub uses a database abstraction layer and presently it defaults
to using Redis as the backend. This is completely configurable, but if you
just punch in the defaults as this guide suggests, you will run into issues if
you don't have a redis server installed on the machine.

## Installing Shrub

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

## Creating your first package

So great, we have Shrub running, but we want to build our own application!

Developing for Shrub means creating packages that implement hooks. Let's create
a simple package to get our hands dirty. You'll see that there is a `custom`
directory in your Shrub installation. This is where we'll put all of the
packages we create.

### Create the package

Head into that directory and create a directory called `my-package`. Head into
that directory and create a file called `index.js`. **NOTE:** you can create
`index.coffee` if you prefer CoffeeScript (as the author does). Open that file
and put in the following code:

```javascript
exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('shrubCorePreBootstrap', function() {
    console.log('I hooked into shrub!');
  });
};
```

(Obviously you will use the equivalent in CoffeeScript if using it, however I
will stick to JavaScript for the examples so we don't scare anyone)

### Add the package to the settings file

Currently to enable a package for shrub, you must add it by hand to the
settings file. We'll open up the `config/settings.json` file we created earlier
and add our package to the `packageList` array:

```json
{
  "packageList": [
    "my-package",
    "shrub-angular",
    "shrub-assets",
    "shrub-audit",
...
```

## Go go go

If your Shrub server is still running, kill it and run the following:

`DEBUG=shrub:* grunt execute`

You'll see a bunch of stuff fly by, but you should also notice this:

`I hooked into shrub!`

This means that our package was hooked into Shrub and the
`shrubCorePreBootstrap` hook was invoked! Hurray, we have our first Shrub
package.
