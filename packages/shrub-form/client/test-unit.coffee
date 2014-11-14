
describe 'form', ->
	
	it 'should automagically register a form when compiling a directive', ->

		inject [
			'$compile', '$rootScope', 'shrub-form'
			($compile, $rootScope, shrubForm) ->
				
				# Sanity
				expect(shrubForm.forms.test).not.toBeDefined()
				
				tpl = $compile '<div data-shrub-form data-form="test"></div>'
				
				scope = $rootScope.$new()
				scope.test = {}
				
				tpl scope
				
				# Registered.
				expect(shrubForm.forms.test).toBeDefined()
				
		]

	it 'should generate correct form elements when compiled', ->

		inject [
			'$compile', '$rootScope'
			($compile, $rootScope) ->
				
				tpl = $compile '<div data-shrub-form data-form="test"></div>'
				
				scope = $rootScope.$new()
				
				scope.test =
				
					fields:
					
						email:
							type: 'email'
							label: "email"
						password:
							type: 'password'
							label: "password"
							required: true
						text:
							value: 'test'
							type: 'text'
							label: "text"
					
				elm = tpl scope
				scope.$digest()
				
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
					if scope.test.fields[name]?.required
						expect($input.attr 'required').toBeDefined()
					else
						expect($input.attr 'required').not.toBeDefined()
					
					# Check default values.
					if scope.test.fields[name]?.value?
						expect(scope.test.fields[name].value).toBe input.value
						
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
				
				tpl = $compile '<div data-shrub-form data-form="test"></div>'
				
				scope = $rootScope.$new()
				
				submissionCleared = false
				
				scope.test =
					
					fields:
					
						text:
							type: 'text'
							label: "text"

						submit:
							type: 'submit'
							label: "Submit"
							handler: ->
								submissionCleared = scope.text is 'test'
								
					submits: [
					
						(values) ->
							
							submissionCleared = values.text is 'test'
							
					]
						
				elm = tpl scope
				
				scope.test.fields['text'].value = 'test'
				
				scope.$apply()
				
				$form = elm.find 'form'
				
				for input in $form.find 'input'
					$input = angular.element input
					input.click() if 'submit' is input.type
				
				# Form was submitted with correct values.
				expect(submissionCleared).toBe true
				
		]

	it 'should handle rpc submission', ->

		inject [
			'$compile', '$rootScope', '$timeout', 'shrub-rpc', 'shrub-socket'
			($compile, $rootScope, $timeout, rpc, socket) ->
				
				tpl = $compile '<div data-shrub-form data-form="test"></div>'
				
				scope = $rootScope.$new()
				
				rpcSubmission = ''
				submissionCleared = false
				
				socket.catchEmit 'rpc://test', (data, fn) ->
					rpcSubmission = data.text
					
					fn result: 420
				
				scope.test =
					
					fields:

						text:
							type: 'text'
							label: "text"
							
						submit:
							type: 'submit'
							label: "Submit"
								
					submits: [
					
						rpc.formSubmitHandler (error, result) ->
							return if error?
							
							submissionCleared = result is 420
							
					]
					
				elm = tpl scope
				
				scope.test.fields['text'].value = 'test'
				
				scope.$apply()
				
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
