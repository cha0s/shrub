$module.service 'forms', [
	'$rootScope', 'config'
	($rootScope, config) ->
		
		forms = {}
		
		@register = (key, scope, element) ->
			forms[key] =
				scope: scope
				element: element
					
		@lookup = (key) ->
			console.log key
			console.log forms
			forms[key]
		
		return

]
