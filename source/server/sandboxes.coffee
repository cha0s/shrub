# Sandboxes

This module provides a method for creating sandboxed DOMs (using
[jsdom](https://github.com/tmpvar/jsdom)). It augments the DOM with a
functional [WebSocket](http://en.wikipedia.org/wiki/WebSocket) using
[ws](https://github.com/einaros/ws/), and generally makes spinning up
arbitrary DOM contexts a pleasant breeze.
```coffeescript
config = require 'config'
Promise = require 'bluebird'
WebSocket = require 'ws/lib/WebSocket'

errors = require 'errors'
logging = require 'logging'

{jsdom} = require 'jsdom'
```
Hax: Fix document.domain since jsdom has a stub here.
```coffeescript
{HTMLDocument} = require 'jsdom/lib/jsdom/living'
Object.defineProperties(
  HTMLDocument.prototype
  domain: get: -> 'localhost'
)
```
This class is responsible for creating and cleaning up DOMs, and provides
some methods to inspect the state of the document.
```coffeescript
exports.Sandbox = class Sandbox
```
## *constructor*

*Spin up a DOM.*
```coffeescript
  constructor: ->

    @_cleanupFunctions = []
    @_window = null
```
## Sandbox#close

*Close a DOM.*
```coffeescript
  close: ->
```
If the window is already gone, nope out.
```coffeescript
    return Promise.resolve() unless @_window?
```
Run all the registered cleanup functions.
```coffeescript
    Promise.all(
      fn() for fn in @_cleanupFunctions
```
Suppress cleanup errors.
```coffeescript
    ).catch(->
```
Actually close the window and null it out.
```coffeescript
    ).finally =>

      @_window.close()
      @_window = null
```
## Sandbox#createDocument

* (string) `html` - The HTML document.

* (object) `options` - An options object which may contain the following

values:
    * (string) `cookie` - Cookie string.
    * (string) `cookieDomain` - The domain the cookie applies to.
    * (string) `url` - The canonical URL of the HTML document.
```coffeescript
```
*Create a DOM from an HTML document.*
```coffeescript
  createDocument: (html, options = {}) ->
```
Set up a DOM, forwarding our cookie.
```coffeescript
    document = jsdom(
      html

      cookie: options.cookie
      cookieDomain: options.cookieDomain ? 'localhost'

      url: options.url ? "http://localhost:#{config.get 'packageSettings:shrub-http:port'}/"
    )
    @_window = window = document.defaultView

    @_window.addEventListener 'error', startupErrorHandler = (errorEvent) ->
      (window.__shrubStartupErrors ?= []).push errorEvent.error
```
Capture "client" console logs.
```coffeescript
    for level in ['info', 'log', 'debug', 'warn', 'error']
      do (level) -> window.console[level] = (args...) ->
```
Make errors as detailed as possible.
```coffeescript
        for arg, i in args
          if arg instanceof Error
            args[i] = errors.stack arg
          else
            arg

        console[level] args...
```
Hack in WebSocket.
```coffeescript
    window.WebSocket = WebSocket

    sandbox = this
    new Promise (resolve, reject) ->
```
When the window is loaded, we'll reject with any error, or resolve.
```coffeescript
      window.onload = ->

        unless window.__shrubStartupErrors?
          window.removeEventListener 'error', startupErrorHandler
          return resolve sandbox
```
Just emit the first error.

###### TODO: How can we collapse multiple errors into one?
```coffeescript
        reject window.__shrubStartupErrors[0]
```
## Sandbox#emitHtml

*Emit the document as HTML.*
```coffeescript
  emitHtml: -> """
<!doctype html>
```
@_window.document.innerHTML}
```coffeescript
"""
```
## Sandbox#registerCleanupFunction

* (function) `fn` - The function to run when the sandbox is closing.

*Register a function to run when the sandbox is closing.*
```coffeescript
  registerCleanupFunction: (fn) -> @_cleanupFunctions.push fn
```
## Sandbox#url

*The current URL the sandbox is at.*
```coffeescript
  url: -> @_window.location.href
```
