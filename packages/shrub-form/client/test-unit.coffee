
describe 'form', ->

	it 'should automagically register a form when compiling a directive', ->

		inject [
			'$compile', '$rootScope', 'shrub-form'
			($compile, $rootScope, shrubForm) ->

				# Sanity
				expect(shrubForm.forms.test).not.toBeDefined()

				element = angular.element(
					'<div data-shrub-form data-form="testAuto"></div>'
				)

				scope = $rootScope.$new()
				scope['testAuto'] = {}

				$compile(element)(scope)
				scope.$digest()

				# Registered.
				expect(shrubForm.forms.testAuto).toBeDefined()

		]

	it 'should generate correct form elements when compiled', ->

		inject [
			'$compile', '$rootScope'
			($compile, $rootScope) ->

				element = angular.element(
					'<div data-shrub-form data-form="testElements"></div>'
				)

				scope = $rootScope.$new()

				scope['testElements'] =

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

				$compile(element)(scope)
				scope.$digest()

				$form = element.find 'form'

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
					if scope['testElements'].fields[name]?.required
						expect($input.attr 'required').toBeDefined()
					else
						expect($input.attr 'required').not.toBeDefined()

					# Check default values.
					if scope['testElements'].fields[name]?.value?
						expect(scope['testElements'].fields[name].value).toBe input.value

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

				tpl = $compile '<div data-shrub-form data-form="testSubmit"></div>'

				scope = $rootScope.$new()

				submissionCleared = false

				scope['testSubmit'] =

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

				scope['testSubmit'].fields['text'].value = 'test'

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

				rpcSubmission = ''
				submissionCleared = false

				socket.catchEmit 'rpc://test.rpc', (data, fn) ->
					rpcSubmission = data.text

					fn result: 420

				element = angular.element(
					'<div data-shrub-form data-form="testRpc"></div>'
				)

				scope = $rootScope.$new()
				scope['testRpc'] =

					fields:

						text:
							type: 'text'
							label: "text"
							value: 'test'

						submit:
							type: 'submit'
							label: "Submit"

					submits: [

						rpc.formSubmitHandler (error, result) ->
							return if error?

							submissionCleared = result is 420

					]

				$compile(element)(scope)
				scope.$digest()

				$form = element.find 'form'

				for input in $form.find 'input'
					$input = angular.element input

					input.click() if 'submit' is input.type

				$timeout.flush()

				# RPC received correct data.
				expect(rpcSubmission).toBe 'test'

				# Form was submitted with correct values.
				expect(submissionCleared).toBe true

		]
