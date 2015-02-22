This page explains various concepts and conventions used in Shrub.

# Middleware hook specification

Shrub invokes various hooks ([`httpMiddleware`](hooks#httpmiddleware),
[`bootstrapMiddleware`](hooks#bootstrapmiddleware), and more...) which allow
packages to define middleware to be dispatched during various processes.

Middleware hooks return a specification that looks like:

```javascript
{
  label: 'What the middleware functions do',
  middleware: [

    function(args..., next) {

      // Do stuff with args...
      next();
    },

    function(args..., next) {

      // Do stuff with args...
      next();
    }
  ]
}
```

The `label` exists only to provide debugging information so you can see if any
of your middleware are having problems by checking the debug console logs.

The `middleware` are applied serially, meaning the first function in the array
is dispatched first, followed by the second, etc.

# Annotated functions

Annotated functions are an Angular convention, but are used widely throughout
Shrub on the client-side. Annotated functions allow dependency injection. You
can read more about annotated functions in
[the Angular documentation](http://docs.angularjs.org/guide/di#dependency-annotation).
