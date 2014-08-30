
# # Form processing.
# 
# Handle form and method parsing, and submission of POST'ed data into the
# Angular sandbox.

express = require 'express'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `angularNavigationMiddleware`
	# 
	# If the client made a POST request, inject that request into the Angular
	# sandbox and let it do its thing.
	registrar.registerHook 'angularNavigationMiddleware', ->
	
		label: 'Handle form submission'
		middleware: [
		
			(req, res, next) ->
				
				{body, sandbox} = req
				
				# Make sure there's a formKey in the submission.
				# `TODO`: CRSF check needed here.
				return next() unless body.formKey?
	
				# Lookup the cached form.
				formService = null
				
				sandbox.inject [
					'shrub-form'
					(form) -> formService = form
				]
			
				return next() unless (formCache = formService.forms[body.formKey])?
					
				{element, scope} = formCache
				widgets = formService.widgets
				
				form = scope.form
				for k, v of body
					continue if 'formKey' is k
					
					element = element.find "[name='#{k}']"
					
					formService.widgets[form.fields[k].type].assignToElement(
						element
						v
					)
					
					element.trigger 'change'
					
				# Submit the form into Angular.
				scope.$digest()
				scope.$apply ->
					scope.$shrubSubmit[body.formKey]().finally => next()
	
		]
	
	# ## Implements hook `httpMiddleware`
	# 
	# Parse POST submissions, and allow arbitrary method form attribute.
	registrar.registerHook 'httpMiddleware', (http) ->
		
		label: 'Parse form submissions'
		middleware: [
			express.bodyParser()
			express.methodOverride()
		]
