
express = require 'express'

exports.$angularNavigationMiddleware = ->

	label: 'Handle form submission'
	middleware: [
	
		(req, res, next) ->
			
			{body, sandbox} = req
			
			shrubForm = null
			
			sandbox.inject [
				'form'
				(form) -> shrubForm = form
			]
		
			return next() unless body.formKey?
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

exports.$httpMiddleware = (http) ->
	
	label: 'Parse form submissions'
	middleware: [
		express.bodyParser()
		express.methodOverride()
	]
