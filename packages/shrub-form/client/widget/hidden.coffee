
exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `formWidgets`
	registrar.registerHook 'formWidgets', ->
		
		widgets = []
		
		widgets.push

			type: 'hidden'
			injected: [
				'name', 'field', 'scope'
				(name, field, scope) ->
				
					scope[name] = field.value
					angular.element('<input type="hidden">').attr name: name
			]
				
		widgets
