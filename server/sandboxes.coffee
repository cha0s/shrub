
_ = require 'underscore'
nconf = require 'nconf'
Promise = require 'bluebird'
WebSocket = require 'socket.io/node_modules/socket.io-client/node_modules/ws/lib/WebSocket'
winston = require 'winston'

errors = require 'errors'

{EventEmitter} = require 'events'
{jsdom} = require 'jsdom'

logger = new winston.Logger
	transports: [
		new winston.transports.Console level: 'silly', colorize: true
		new winston.transports.File level: 'debug', filename: 'logs/client.log'
	]

module.exports = new class SandboxFactory
	
	constructor: ->
		
		@_sandboxes = {}
	
	create: (html, cookie, id = null) ->
		
		new Promise (resolve) =>
			
			sandbox = new Sandbox html, cookie, id
			
			@_sandboxes[id] = sandbox if id?
			
			resolve sandbox.touch()
	
	lookup: (id) ->
		
		if (sandbox = @_sandboxes[id]?.touch())?
			sandbox.isNew = (-> false)
			
		sandbox
	
	lookupOrCreate: (html, cookie, id = null) ->
		
		promise = if (sandbox = @lookup id)?
			
			Promise.resolve sandbox
			
		else
			
			@create html, cookie, id
	
	remove: (id) -> @_sandboxes = null

class Sandbox extends EventEmitter
	
	constructor: (html, cookie, @_id = null) ->
		EventEmitter.call this
		
		unless html?
			throw new ReferenceError(
				"Sandbox expects to be constructed with HTML."
			)
			
		@_busy = null
		@_cleanupFunctions = []
		@_window = null

		# Reset the TTL if this sandbox has an ID, otherwise it's a nop.
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
		document = jsdom(
			html, jsdom.defaultLevel
			
			cookie: cookie
			cookieDomain: 'localhost'
			url: "http://localhost:#{
				nconf.get 'services:http:port'
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
				
				logger[level] args... 
				
		# Hack in WebSocket.
		window.WebSocket = WebSocket
		
		window.onload = =>
			
			# Catch any errors in the client.
			for error in window.document.errors
				if error.data?.error?
					return reject error.data.error
			
			@emit 'ready'
			
	close: ->
		return Promise.resolve() unless @_window?
		
		module.exports.remove @_id
		Promise.cast(
			@_busy
		
		).bind(this).then(->
		
			Promise.all (fn() for fn in @_cleanupFunctions)
			
		).then =>
			
			@_window.close()
			@_window = null
			
	emitHtml: -> """
<!doctype html>
#{@_window.document.innerHTML}
"""
	
	isNew: -> true
	
	registerCleanupFunction: (fn) -> @_cleanupFunctions.push fn
	
	setBusy: (@_busy) ->
	
	url: -> @_window.location.href
