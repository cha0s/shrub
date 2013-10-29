$module.service 'forms', [
	'$rootScope', 'config'
	($rootScope, config) ->
		
		forms = {}
		
		@register = (key, scope, element) ->
			forms[key] =
				scope: scope
				element: element
					
		@lookup = (key) -> forms[key]
		
		return

]
