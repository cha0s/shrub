
# # nodemailer
# 
# Renders and sends email.

nodemailer = require 'nodemailer'
Promise = require 'bluebird'

config = require 'config'
pkgman = require 'pkgman'
{Sandbox} = require 'sandboxes'

skin = require 'shrub-skin'

# Sandbox used to render email as HTML.
sandbox = null

# nodemailer transport. Defaults to sendmail.
transport = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `bootstrapMiddleware`
	registrar.registerHook 'bootstrapMiddleware', ->
	
		label: 'Bootstrap nodemailer'
		middleware: [
		
			(next) ->
			
				settings = config.get 'packageSettings:shrub-nodemailer'
				
				# Instantiate the email transport.
				transport = nodemailer.createTransport(
					require(settings.transport.module)(
						settings.transport.options
					)
				)
				
				# Render the app HTML and create a sandbox with it.
				skin.renderAppHtml().then((html) ->
					
					sandbox = new Sandbox()
					sandbox.createDocument html, url: "http://localhost:#{
						config.get 'packageSettings:shrub-http:port'
					}/home"
					
				).then(->
					
					# Augment it with functionality we'll find useful and
					# convenient.
					augmentSandbox sandbox
					
				).then(-> next()
				
				).catch next
			
		]

	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->
		
		# Default site email information.
		siteEmail:
			address: 'admin@example.com'
			name: 'Site administrator'
		
		# Passed through directly to nodemailer.
		transport:
			module: 'nodemailer-sendmail-transport'
			options: {}
		
# ## sendMail
# 
# *Send an email.*
# 
# * (string) `directive` - The path of the email directive to send.
# 
# * (object) `mail` - See [the nodemailer example](https://github.com/andris9/Nodemailer/blob/master/examples/example_sendmail.js#L9)
#   for an example of the structure of this object.
# 
# * (object) `scope` - Object whose values will be injected into the directive
#   scope when compiling the directive for the email output.
exports.sendMail = (directive, mail, scope) ->
	
	path = config.get 'path'
	siteEmail = config.get 'packageSettings:shrub-nodemailer:siteEmail'
	
	Promise.resolve().then(->
		
		sandbox.inject [
			'$rootScope', '$compile'
			($rootScope, $compile) ->
				
				$scope = $rootScope.$new()
				$scope[key] = value for key, value of scope
				$element = $compile("<div data-#{directive}></div>")($scope)
				
				# Just to be sure :)
				$rootScope.$digest() for i in [0...10]
				
				sandbox.prepareHtmlForEmail $element.html()
				
		]
	
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
		new Promise (resolve, reject) ->
			transport.sendMail mail, (error) ->
				
				return reject error if error?
				resolve() 
			
	)
	
# Augment the sandbox with the ability to rewrite HTML for email, and emit HTML
# as text.
augmentSandbox = (sandbox) ->

	# Convenience.
	$ = sandbox._window.$
	
	selectors = {}
	
	htmlCssText = ''
	bodyCssText = ''
	
	# Gather all CSS selectors and rules ahead of time.
	gatherSelectors = ->
		for stylesheet in sandbox._window.document.styleSheets
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
			
		for cssText, selectors_ of cssTextCache
			selectors[selectors_.join ','] = cssText
		
	# ### sandbox.inject
	# 
	# *Inject an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation) with dependencies.*
	# 
	# * (mixed) `injectable` - An annotated function to inject with
	#   dependencies. 
	sandbox.inject = (injectable) ->
		injector = @_window.angular.element(@_window.document).injector()
		injector.invoke injectable
		
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
		
		# Let the skin manage the mail HTML.
		pkgman.invokePackage skin.activeKey(), 'mailHtml', $body, html, $
		
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
		).trim()
	
	new Promise (resolve) ->
	
		sandbox.inject [
			'$sniffer', 'shrub-socket'
			($sniffer, socket) ->
				
				# } Don't even try HTML 5 history on the server side.
				$sniffer.history = false
				
				# } Let the socket finish initialization.						
				socket.on 'initialized', ->
					
					gatherSelectors()
					
					resolve sandbox
		
		]
