
fs = require 'fs'
nconf = require 'nconf'
nodemailer = require 'nodemailer'
Promise = require 'bluebird'

pkgman = require 'pkgman'
sandboxes = require 'sandboxes'

{handlebars} = require 'hbs'

readFile = Promise.promisify fs.readFile, fs

sandbox = null
templateCache = {}
transport = null

exports.$clearCaches = ->
	
	templateCache = {}
	
exports.$httpListening = (http) ->
	
	settings = nconf.get 'packageSettings:nodemailer'
		
	transport = nodemailer.createTransport(
		settings.transport.type
		settings.transport.options
	)
	
	# All we'll need is jQuery.
	locals =
		assets:
			js: [
				"/lib/jquery/jquery-1.11.0.js"
			]
	
	# Render the app HTML and create a sandbox with it.
	http.renderAppHtml(locals).then((html) ->
		
		sandboxes.create html
		
	).then((_sandbox_) ->
		
		augmentSandbox sandbox = _sandbox_
		
	)

exports.$settings = ->
	
	transport:
		type: 'sendmail'
		options: {}
	
exports.sendMail = (type, mail) ->
	
	path = nconf.get 'path'
	siteEmail = nconf.get 'siteEmail'
	
	sandboxId = null
	
	# Allow other packages to make changes to the mail.
	promises = for _, promise of pkgman.invoke 'mail', type, mail
		promise
	
	Promise.all(promises).then(->
		return mail.html if mail.html
		
		# Search for a template filename.
		return unless mail.template
		
		filename = "#{path}/#{template}.email.html"
		
		new Promise (resolve) ->
			fs.exists filename, (exists) ->
				return resolve() unless exists
				resolve readFile filename
				
	).then((html) ->
		return html if html?
		
		# Search for a default template based on `type`. For instance, the user
		# package defines a mail type `user/register`, which means that there
		# is a template at `path`/server/packages/user/register.email.html
		filename = "#{path}/server/packages/#{type}.email.html"
		
		new Promise (resolve) ->
			fs.exists filename, (exists) ->
				return resolve() unless exists
				resolve readFile filename

	).then((html) ->
		
		return unless html?
		
		html = if templateCache[type]?
		
			templateCache[type]
			
		else
		
			# Prepare the HTML to be sent as email.
			templateCache[type] = sandbox.prepareHtmlForEmail html.toString()
	
		# Compile it with Handlebars.
		mail.tokens ?= {}
		html = handlebars.compile(html) mail.tokens
			
	).then((html) ->
		
		mail.html = html if html?
		
	).then(->
		
		# If the from field wasn't specified, look it up in the configuration.
		unless mail.from
			unless siteEmail.address
				throw new Error "Email sent without `from` field, and no site email address is defined!"
			
			# Use the address by default.
			mail.from = siteEmail.address
			
			# Format if there is a site email name
			mail.from = "#{siteEmail.name} <#{mail.from}>" if siteEmail.name
		
		# Parse the HTML to plain text as a default if no plain text was
		# provided.
		mail.text ?= sandbox.text mail.html if mail.html?
		
		# Send the mail.
		deferred = Promise.defer()
		transport.sendMail mail, deferred.callback
		deferred.promise
			
	)
	
# Augment the sandbox with the ability to rewrite HTML for email, and emit HTML
# as text.
augmentSandbox = (sandbox) ->

	new Promise (resolve, reject) -> 
		
		sandbox.on 'ready', (error) ->
			return reject error if error?
			
			# Convenience.
			$ = sandbox._window.$
			
			selectors = {}
			
			htmlCssText = ''
			bodyCssText = ''
			
			# Gather all CSS selectors and rules ahead of time.
			for stylesheet in @_window.document.styleSheets
				for rule in stylesheet.cssRules
					continue unless rule.selectorText?
					
					# Split into individual selectors.
					parts = rule.selectorText.split(
						
						','
					
					).map((selector) ->
						
						# Trim whitespace.
						selector.trim()
						
					).filter (selector) ->
						
						# Filter pseudo selectors.
						return false if selector.match /[:@]/
						
						# Collect html and body rules manually.
						if selector is 'html'
							htmlCssText += rule.style.cssText
							return false
						
						if selector is 'body'
							bodyCssText += rule.style.cssText
							return false
						
						true
						
					# Rejoin the selectors.
					selector = parts.join ','
					
					# Normalize the rule(s).
					selectors[selector] ?= ''
					selectors[selector] += rule.style.cssText.split(
					
						';'
					
					).filter((rule) ->
						
						rule isnt ''
					
					).map((rule) ->
						
						rule.trim()
						
					).sort().join '; '
					selectors[selector] += ';'
				
			# Merge as many rules as we can, so we'll have less work to do for
			# each application.
			cssTextCache = {}
			for selector, cssText of selectors
				(cssTextCache[cssText] ?= []).push selector
				
			selectors = {}
			for cssText, selectors_ of cssTextCache
				selectors[selectors_.join ','] = cssText
					
			# CREDIT: http://devintorr.es/blog/2010/05/26/turn-css-rules-into-inline-style-attributes-using-jquery/
			# With some improvements, of course.
			sandbox.inlineCss = (html) ->
				
				for selector, cssText of selectors
					for element in $(selector, $(html))
						element.style.cssText += cssText
						
			# Prepare HTML for email; inject all CSS inline and insert niceties
			# like a nav on top.
			sandbox.prepareHtmlForEmail = (html) ->
				
				# Clone the body and insert the HTML into the main application
				# area.
				$body = $('body').clone()
				$(html).appendTo $('.main', $body)

				# Inject a minimally-built nav.
				# TODO this kind of thing should be configurable and handled
				# by the theme/skin when we get to that point.
				$('[data-ui-nav]', $body).html """
<nav role="navigation" class="navbar navbar-default">
	<div class="container-fluid">
		
		<div class="navbar-header">
			<a href="#" class="navbar-brand"><span data-ng-bind="pageTitle" class="ng-binding">{{title}}</span></a>
		</div>
		
		<div data-ng-class="navClass" class="navbar-collapse collapse ui-nav">
		</div>
	</div>
</nav>
"""
				
				# Inject all the styles inline.
				sandbox.inlineCss $body
				
				# Return a valid HTML document.
				"""
<!doctype html>
<html style=#{htmlCssText}">
<body style=#{bodyCssText}">
#{$body.html()}
</body>
</html>
"""
			
			# Convert HTML to text.
			sandbox.text = (html) ->
				
				text = $(html).text()
				
				# Remove tab characters.
				text = text.replace /\t/g, ''
				
				# Remove excessive empty lines.
				emptyLines = 0
				text = text.split('').reduce(
					(l, r) ->
						
						if (l.slice -1) is '\n' and r is '\n'
							emptyLines += 1
						else
							emptyLines = 0
						
						if emptyLines > 1
							l
						else
							l + r
						
					''
				)
			
			resolve()
