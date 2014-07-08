
describe 'form', ->
	
	it 'should automagically register a form when compiling a directive', ->

		inject [
			'$compile', '$rootScope', 'form'
			($compile, $rootScope, {forms}) ->
				
				# Sanity
				expect(forms.test).not.toBeDefined()
				
				tpl = $compile '<div data-form="test"></div>'
				
				scope = $rootScope.$new()
				scope.test = {}
				
				tpl scope
				
				# Registered.
				expect(forms.test).toBeDefined()
				
		]

	it 'should generate correct form elements when compiled', ->

		inject [
			'$compile', '$rootScope'
			($compile, $rootScope) ->
				
				tpl = $compile '<div data-form="test"></div>'
				
				scope = $rootScope.$new()
				
				scope.test =
					email:
						type: 'email'
						label: "email"
					password:
						type: 'password'
						label: "password"
						required: true
					text:
						defaultValue: 'test'
						type: 'text'
						label: "text"
					
				elm = tpl scope
				
				$form = elm.find 'form'

				# <form> exists
				expect($form.length).toBe 1
				
				childrenCount = 0
				hasFormKey = false
				
				for input in $form.find 'input'
					$input = angular.element input
					
					name = input.name
					
					if -1 isnt ['email', 'password', 'text'].indexOf name
						childrenCount += 1
						
						# Assert actual input type.
						expect(input.type).toBe input.name
					
					# Check required fields.
					if scope.test[name]?.required
						expect($input.attr 'required').toBeDefined()
					else
						expect($input.attr 'required').not.toBeDefined()
					
					# Check default values.
					if scope.test[name]?.defaultValue?
						expect(scope.test[name].defaultValue).toBe input.value
						
					hasFormKey = true if name is 'formKey'
				
				# All children present.	
				expect(childrenCount).toBe 3
				
				# Form key generated.
				expect(hasFormKey).toBe true
				
		]

	it 'should handle form modification and submission', ->

		inject [
			'$compile', '$rootScope'
			($compile, $rootScope) ->
				
				tpl = $compile '<div data-form="test"></div>'
				
				scope = $rootScope.$new()
				
				submissionCleared = false
				
				scope.test =
					text:
						type: 'text'
						label: "text"
					submit:
						type: 'submit'
						label: "Submit"
						handler: ->
							submissionCleared = scope.text is 'test'
					
				elm = tpl scope
				
				scope.text = 'test'
				
				scope.$digest()
				
				$form = elm.find 'form'
				
				for input in $form.find 'input'
					$input = angular.element input
					
					input.click() if 'submit' is input.type
				
				# Form was submitted with correct values.
				expect(submissionCleared).toBe true
				
		]

	it 'should handle rpc submission', ->

		inject [
			'$compile', '$rootScope', '$timeout', 'socket'
			($compile, $rootScope, $timeout, socket) ->
				
				tpl = $compile '<div data-form="test"></div>'
				
				scope = $rootScope.$new()
				
				rpcSubmission = ''
				submissionCleared = false
				
				socket.catchEmit 'rpc://test', (data, fn) ->
					rpcSubmission = data.text
					
					fn result: 420
				
				scope.test =
					text:
						type: 'text'
						label: "text"
					submit:
						rpc: true
						type: 'submit'
						label: "Submit"
						handler: (error, result) ->
							submissionCleared = result is 420
					
				elm = tpl scope
				
				scope.text = 'test'
				
				scope.$digest()
				
				$form = elm.find 'form'
				
				for input in $form.find 'input'
					$input = angular.element input
					
					input.click() if 'submit' is input.type
				
				$timeout.flush()
				$rootScope.$apply()
				
				# RPC received correct data.
				expect(rpcSubmission).toBe 'test'
				
				# Form was submitted with correct values.
				expect(submissionCleared).toBe true
				
		]
