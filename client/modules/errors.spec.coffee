errors = require 'errors'

describe 'errors', ->
	
	error = null
	
	beforeEach ->
	
		error = errors.instantiate 'unknown', 'Test'
		
	it "instantiates errors", ->
	
		expect(error instanceof Error).toBe true
		
	it "handles (even abstract errors') messages", ->
		
		expect(errors.message error).toBe "Unknown error: Test"

		expect(errors.message new Error "Foo").toBe "Unknown error: Foo"

		expect(errors.message "Blah").toBe "Unknown error: Blah"
		
	it "serializes (even abstract) errors", ->
		
		O = errors.serialize error
		expect(O.key).toBe error.key
		expect(O.message).toBe error.message
		
		O = errors.serialize new Error "Foobar"
		expect(O.key).not.toBeDefined()
		expect(O.message).toBe "Foobar"

		O = errors.serialize "Hmm"
		expect(O.key).not.toBeDefined()
		expect(O.message).toBe "Hmm"

	it "unserializes (even abstract) errors", ->
		
		O = errors.serialize error
		expect(errors.message errors.unserialize O).toBe errors.message error
		
		O = message: 'Blah'
		expect(errors.message errors.unserialize O).toBe "Unknown error: Blah"
