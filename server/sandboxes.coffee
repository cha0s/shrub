
# # Sandboxes
# 
# This module provides a method for creating sandboxed DOMs (using
# [jsdom](https://github.com/tmpvar/jsdom)). It augments the DOM with a
# functional [WebSocket](http://en.wikipedia.org/wiki/WebSocket) using
# [ws](https://github.com/einaros/ws/), and generally makes spinning up
# arbitrary DOM contexts a pleasant breeze.

config = require 'config'
Promise = require 'bluebird'
WebSocket = require 'socket.io/node_modules/socket.io-client/node_modules/engine.io-client/node_modules/ws/lib/WebSocket'

errors = require 'errors'
logging = require 'logging'

{jsdom} = require 'jsdom'

# } Hax: Fix document.domain since jsdom has a stub here.
level2Html = require 'jsdom/lib/jsdom/level2/html'
Object.defineProperties(
	level2Html.dom.level2.html.HTMLDocument.prototype
	domain: get: -> 'localhost'
)

# ## Sandbox
# This class is responsible for creating and cleaning up DOMs, and provides
# some methods to inspect the state of the document.
exports.Sandbox = class Sandbox
	
	# ### *constructor*
	# 
	# *Spin up a DOM.*
	constructor: ->
		
		@_cleanupFunctions = []
		@_window = null

	# ### .close
	# 
	# *Close a DOM.*
	close: ->
		
		# } If the window is already gone, nope out.
		return Promise.resolve() unless @_window?
		
		# } Run all the registered cleanup functions.
		Promise.all(
			fn() for fn in @_cleanupFunctions
		
		# } Suppress cleanup errors.
		).catch(->
			
		# } Actually close the window and null it out.
		).finally =>
			
			@_window.close()
			@_window = null
			
	createDocument: (html, options = {}) ->
	
		# } Set up a DOM, forwarding our cookie and navigating to the entry
		# } point.
		document = jsdom(
			html, jsdom.defaultLevel
			
			cookie: options.cookie
			cookieDomain: options.cookieDomain ? 'localhost'
			
			url: options.url ? "http://localhost:#{
				config.get 'packageSettings:shrub-http:port'
			}/"
		)
		@_window = window = document.createWindow()
		
		# } Capture "client" console logs.
		for level in ['info', 'log', 'debug', 'warn', 'error']
			do (level) -> window.console[level] = (args...) ->
				
				# } Make errors as detailed as possible.
				for arg, i in args
					if arg instanceof Error
						args[i] = errors.stack arg
					else
						arg
				
				console[level] args... 
				
		# } Hack in WebSocket.
		window.WebSocket = WebSocket
		
		sandbox = this
		new Promise (resolve, reject) ->
		
			# When the window is loaded, we'll reject with any error, or
			# resolve. 
			window.onload = ->
	
				for documentError in window.document.errors ? []
					if documentError.data?.error?
						error = new Error "#{
							documentError.message
						}\n#{
							errors.stack documentError.data.error
						}"
						
				if error?
					reject error
				else
					resolve sandbox
			
	# ### .emitHtml
	# 
	# *Emit the document as HTML.*
	emitHtml: -> """
<!doctype html>
#{@_window.document.innerHTML}
"""
	
	# ### .registerCleanupFunction
	# 
	# *Register a function to run when the sandbox is closing.*
	# 
	# * (function) `fn` - The function to run when the sandbox is closing.
	registerCleanupFunction: (fn) -> @_cleanupFunctions.push fn
	
	# ### .url
	# 
	# *The current URL the sandbox is at.*
	url: -> @_window.location.href
