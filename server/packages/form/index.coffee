
# # Form processing.
# 
# Handle form and method parsing, and submission of POST'ed data into the
# Angular sandbox.

express = require 'express'

# ## Implements hook `angularNavigationMiddleware`
# 
# If the client made a POST request, inject that request into the Angular
# sandbox and let it do its thing.
exports.$angularNavigationMiddleware = ->

	label: 'Handle form submission'
	middleware: [
	
		(req, res, next) ->
			
			{body, sandbox} = req
			
			# Make sure there's a formKey in the submission.
			# `TODO`: CRSF check needed here.
			return next() unless body.formKey?

			# Lookup the cached form.
			shrubForm = null
			
			sandbox.inject [
				'form'
				(form) -> shrubForm = form
			]
		
			return next() unless (cachedForm = shrubForm.lookup body.formKey)?
				
			{element, scope} = cachedForm
			
			# Assign the scope values from the POST body. (Is this safe?)
			form = scope[body.formKey]
			for named in element.find '[name]'
				continue unless (value = body[named.name])?
				scope[named.name] = value
				
			# Submit the form into Angular.
			scope.$apply => form.submit.handler().finally => next()

	]

# ## Implements hook `httpMiddleware`
# 
# Parse POST submissions, and allow arbitrary method form attribute.
exports.$httpMiddleware = (http) ->
	
	label: 'Parse form submissions'
	middleware: [
		express.bodyParser()
		express.methodOverride()
	]
