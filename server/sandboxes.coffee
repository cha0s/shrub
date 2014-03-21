
# # Sandboxes
# 
# This module provides a method for creating sandboxed DOMs (using
# [jsdom](https://github.com/tmpvar/jsdom)). It augments the DOM with a
# functional [WebSocket](http://en.wikipedia.org/wiki/WebSocket) using
# [ws](https://github.com/einaros/ws/), and generally makes spinning up
# arbitrary DOM contexts a pleasant breeze.

_ = require 'underscore'
nconf = require 'nconf'
Promise = require 'bluebird'
WebSocket = require 'socket.io/node_modules/socket.io-client/node_modules/ws/lib/WebSocket'

errors = require 'errors'
logging = require 'logging'

{EventEmitter} = require 'events'
{jsdom} = require 'jsdom'

# We'll keep our own logs.
logger = logging.create 'logs/sandbox.log'

# ## SandboxFactory
# This class handles instantiation of new sandboxes, as well as providing a
# mechanism for registering and looking up persistent sandboxes using an id.
# 
# `TODO`: This is probably more of an `angular` package-specific need. It
# should probably be moved there and this module should solely provide Sandbox.
module.exports = new class SandboxFactory
	
	# ### *constructor*
	# 
	# *Initialize the persistent store.*
	constructor: -> @_sandboxes = {}
	
	# ### .create
	# 
	# *Create a sandbox.*
	# 
	# * (string) `html` - The HTML to use as the sandbox document.
	# * (string) `cookie` - The cookie to use for the document.
	# * (string) `id`? - An ID for looking up this sandbox later.
	create: (html, cookie, id = null) ->
		
		new Promise (resolve) =>
			
			sandbox = new Sandbox html, cookie, id
			
			@_sandboxes[id] = sandbox if id?
			
			resolve sandbox.touch()
	
	# ### .lookup
	# 
	# *Look up a sandbox by ID.*
	# 
	# * (string) `id` - An ID for looking up this sandbox later.
	lookup: (id) ->
		
		# Mark the sandbox as no longer new (yuck).
		sandbox.isNew = (-> false) if (sandbox = @_sandboxes[id]?.touch())?
		sandbox
	
	# ### .lookupOrCreate
	# 
	# *Look up a sandbox by ID, or create one if none is registered for this
	# ID.*
	# 
	# * (string) `html` - The HTML to use as the sandbox document if creating.
	# * (string) `cookie` - The cookie to use for the document if creating.
	# * (string) `id`? - An ID either for looking up later (if creating), or
	#   as a search now.
	lookupOrCreate: (html, cookie, id = null) ->
		
		promise = if (sandbox = @lookup id)?
			
			Promise.resolve sandbox
			
		else
			
			@create html, cookie, id
	
	# ### .remove
	# 
	# *Remove a sandbox by ID.*
	# 
	# * (string) `id` - The ID of the sandbox to remove.
	# 
	# Note this doesn't actually close the sandbox, just removes it from the
	# persistent list, allowing it to be GC'd
	remove: (id) -> @_sandboxes[id] = null

# ## Sandbox
# This class is responsible for creating and cleaning up DOMs, and provides
# some methods to inspect the state of the document.
class Sandbox extends EventEmitter
	
	# ### *constructor*
	# 
	# *Spin up a DOM.*
	# 
	# * (string) `html` - The HTML to use as the sandbox document if creating.
	# * (string) `cookie` - The cookie to use for the document if creating.
	# * (string) `id`? - An ID for looking up later.
	# 
	# `TODO`: Move ID to SandboxFactory.
	constructor: (html, cookie, @_id = null) ->
		EventEmitter.call this
		
		# Ensure HTML was passed in. 
		unless html?
			throw new ReferenceError(
				"Sandbox expects to be constructed with HTML."
			)
			
		@_busy = null
		@_cleanupFunctions = []
		@_window = null

		# Reset the TTL if this sandbox has an ID, otherwise it's a nop.
		# 
		# `TODO`: Move to SandboxFactory.
		toucher = if @_id?
			_.debounce (=> @close()), nconf.get 'sandboxes:ttl'
		else
			->
		
		@touch = ->
			toucher()
			this
		
		# Hax: Fix document.domain since jsdom has a stub here.
		level2Html = require 'jsdom/lib/jsdom/level2/html'
		Object.defineProperties(
			level2Html.dom.level2.html.HTMLDocument.prototype
			domain: get: -> 'localhost'
		)
		
		# Set up a DOM, forwarding our cookie and navigating to the entry
		# point.
		# 
		# `TODO`: "Entry point" is an `angular` package-specific idiom.
		document = jsdom(
			html, jsdom.defaultLevel
			
			cookie: cookie
			cookieDomain: 'localhost'
			url: "http://localhost:#{
				nconf.get 'packageSettings:express:port'
			}/shrub-entry-point"
		)
		@_window = window = document.createWindow()
		
		# Capture "client" console logs.
		for level in ['info', 'log', 'debug', 'warn', 'error']
			do (level) -> window.console[level] = (args...) ->
				
				# Make errors as detailed as possible.
				for arg, i in args
					if arg instanceof Error
						args[i] = errors.stack arg
					else
						arg
				
				# Let our logger log them.
				logger[level] args... 
				
		# Hack in WebSocket.
		window.WebSocket = WebSocket
		
		# When the window is loaded, we'll capture any errors, and emit the
		# `ready` event (with any error we caught). 
		window.onload = =>

			for documentError in window.document.errors ? []
				if documentError.data?.error?
					error = new Error "#{
						documentError.message
					}\n#{
						errors.stack documentError.data.error
					}"

			@emit 'ready', error
			
	# ### .close
	# 
	# *Close a DOM.*
	close: ->
		
		# If the window is already gone, nope out.
		return Promise.resolve() unless @_window?
		
		# Remove from persistent list.
		# 
		# `TODO`: Move to SandboxFactory.
		module.exports.remove @_id
		
		# Wait if the sandbox is busy.
		# 
		# `TODO`: There should be a worker queue, not a single 'busy' promise.
		Promise.cast(
			@_busy
		
		# Run all the registered cleanup functions.
		).bind(this).then(->
		
			Promise.all (fn() for fn in @_cleanupFunctions)
			
		# Suppress cleanup errors.
		).catch(->
			
		# Actually close the window and null it out.
		).finally ->
			
			@_window.close()
			@_window = null
			
	
	# ### .emitHtml
	# 
	# *Emit the document as HTML.*
	emitHtml: -> """
<!doctype html>
#{@_window.document.innerHTML}
"""
	
	# ### .isNew
	# 
	# *Is this sandbox 'new'?*
	# 
	# `TODO`: Move to SandboxFactory.
	isNew: -> true
	
	# ### .registerCleanupFunction
	# 
	# *Register a function to run when the sandbox is closing.*
	# 
	# * (function) `fn` - The function to run when the sandbox is closing.
	registerCleanupFunction: (fn) -> @_cleanupFunctions.push fn
	
	# ### .setBusy
	# 
	# *Mark this sandbox as busy.*
	# 
	# * (promise) `busy` - A promise, which upon fulfillment will denote this
	#   sandbox as no longer 'busy'.
	# 
	# `TODO`: This is a sloppy interface.
	setBusy: (@_busy) ->
	
	# ### .url
	# 
	# *The current URL the sandbox is at.*
	url: -> @_window.location.href
