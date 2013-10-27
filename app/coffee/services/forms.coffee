$module.service 'forms', [
	'$rootScope', 'config'
	($rootScope, config) ->
		
		forms = {}
		
		@create = (key, scope, element) ->
			forms[key] =
				scope: scope
				element: element
					
		@lookup = (key) ->
			console.log key
			console.log forms
			forms[key]
		
		return

]
