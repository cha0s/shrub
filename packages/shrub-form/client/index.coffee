
# # Form
# 
# Define a directive for Angular forms, and a service to cache and look them
# up later.

_ = require 'underscore'
i8n = require 'inflection'

pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		'$compile', '$injector', '$log', '$q', 'shrub-form', 'shrub-require'
		($compile, $injector, $log, $q, formService, require) ->
			
			link: (scope, element, attrs) ->
				return unless (form = scope[attrs.form])?
				
				form.key ?= attrs.form
				
				(scope['$shrubSubmit'] ?= {})[form.key] = ($event) ->
				
					values = {}
					for name, field of form.fields
						values[field.name] = field.value
					
					promises = for submit in form.submits
						submit values, form, $event
					
					$q.all promises
				
				# Create the form element.
				$form = angular.element '<form />'
				$form.addClass form.key
				
				# Default method to POST.
				$form.attr 'method', attrs.method ? 'POST'
				$form.attr 'data-ng-submit', "$shrubSubmit['#{form.key}']($event)"
				
				# Build the form fields.
				for name, field of form.fields
					
					field.name ?= name
					
					unless (widget = formService.widgets[field.type])?
						
						$log.warn "Form `#{
							form.key
						}` contains non-existent field type `#{
							field.type
						}`!"
						continue
					
					$form.append """

<div
	data-#{widget.directive}
	data-field="#{attrs.form}.fields['#{name}']"
></div>

"""

				# Add hidden form key to allow server-side
				# interception/processing.
				$formKeyElement = angular.element '<input type="hidden" />'
				$formKeyElement.attr name: 'formKey', value: form.key
				$form.append $formKeyElement
				
				# Invoke hook `formAlter`.
				pkgman.invokeFlat 'formAlter', form, $form				

				# Invoke hook `formFormIdAlter`.
				hookName = "form#{i8n.camelize i8n.underscore form.key}Alter"
				pkgman.invokeFlat hookName, form, $form
				
				# Insert and compile the form element.
				element.append $form
				$compile($form) scope
				
				# Register the form in the system.
				formService.cache form.key, scope, $form
				
	]
	
	# ## Implements hook `service`
	registrar.registerHook 'service', -> [
		
		->
			
			service = forms: {}, widgets: {}
			
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
						
			# Invoke hook `formWidgets`.
			for formWidgets in pkgman.invokeFlat 'formWidgets'
				formWidgets = [formWidgets] unless _.isArray formWidgets
				
				for formWidget in formWidgets
					continue unless formWidget.directive?
					service.widgets[formWidget.type] = formWidget
					
			service
	
	]

	registrar.recur [
		'widget/checkbox'
		'widget/checkboxes'
		'widget/hidden'
		'widget/radio'
		'widget/radios'
		'widget/submit'
		'widget/select'
		'widget/text'
	]
