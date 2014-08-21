
# # Form
# 
# Define a directive for Angular forms, and a service to cache and look them
# up later.

_ = require 'underscore'
i8n = require 'inflection'

pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->
	
	widgets_ = {}
	
	# ## Implements hook `appRun`
	registrar.registerHook 'appRun', -> [
		->

			# Invoke hook `formWidgets`.
			for formWidgets in pkgman.invokeFlat 'formWidgets'
				formWidgets = [formWidgets] unless _.isArray formWidgets
				
				for formWidget in formWidgets
					continue unless formWidget.injected?
					widgets_[formWidget.type] = formWidget
					
			return
					
	]

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		'$compile', '$injector', '$q', 'shrub-form', 'shrub-require'
		($compile, $injector, $q, {cache}, require) ->
			
			link: (scope, element, attrs) ->
				return unless (form = scope[key = attrs.shrubForm])?
				
				# Create the form element.
				$form = angular.element '<form />'
				$form.addClass key
				
				# Default method to POST.
				$form.attr 'method', attrs.method ? 'POST'
				$form.attr 'data-ng-submit', 'shrubFormSubmit($event)'
				
				locals = form: form, key: key
				
				scope.shrubFormSubmit = ($event) ->
					
					submitLocals = angular.copy locals
					submitLocals.$event = $event
					submitLocals.scope = scope
					
					promises = for handler in form.handlers.submit
						$injector.invoke handler, null, submitLocals
						
					$q.all promises
				
				# Build the form fields.
				for name, field of form
					continue unless (widget = widgets_[field.type])?
					
					wrapper = angular.element '<div class="form-group" />'
					
					fieldLocals = angular.copy locals
					fieldLocals.field = field
					fieldLocals.name = name
					fieldLocals.scope = scope
					fieldLocals.wrapper = wrapper
					
					$field = $injector.invoke widget.injected, null, fieldLocals
					
					wrapper.append $field
					
					$form.append wrapper
				
				# Add hidden form key to allow server-side
				# interception/processing.
				$formKeyElement = angular.element '<input type="hidden" />'
				$formKeyElement.attr name: 'formKey', value: key
				$form.append $formKeyElement
				
				# Invoke hook `formAlter`.
				pkgman.invokeFlat 'formAlter', form, $form				

				# Invoke hook `formFormIdAlter`.
				hookName = "form#{i8n.camelize i8n.underscore key}Alter"
				pkgman.invokeFlat hookName, form, $form
				
				# Insert and compile the form element.
				element.append $form
				$compile($form) scope
				
				# Register the form in the system.
				cache key, scope, $form
				
	]
	
	# ## Implements hook `service`
	registrar.registerHook 'service', -> [
		
		->
			
			service = forms: {}
			
			# ## form.cache
			# 
			# Cache a form for later lookup.
			# 
			# * (string) `key` - The form key.
			# 
			# * (Scope) `scope` - The form's Angular scope.
			# 
			# * (Element) `element` - The form's jqLite element.
			service.cache = (key, scope, element) ->
				service.forms[key] = scope: scope, element: element
						
			service
	
	]

	registrar.recur [
		'widget/hidden'
		'widget/submit'
		'widget/select'
		'widget/text'
	]
