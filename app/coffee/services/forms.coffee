$module.service 'forms', [
	'$rootScope', 'config'
	($rootScope, config) ->
		
		forms = {}
		
		$rootScope.registerForm = ($element, key, form) ->
			
			form.$element = $element
			form.$scope = this
			
			forms[form.key = key] = form
			
		@lookup = (key) -> forms[key]
		
		return

]
