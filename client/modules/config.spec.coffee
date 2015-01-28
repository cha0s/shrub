
config = require './config'

describe 'config', ->

	beforeEach ->

		config.from(
			test: 69
			another:
				foo:
					420
				bar:
					null
		)

	it "gets variables", ->

		expect(config.get 'test').toBe 69
		expect(config.get 'another:foo').toBe 420

	it "checks variables", ->

		expect(config.has 'test').toBe true
		expect(config.has 'sd').toBe false
		expect(config.has 'another:foo').toBe true
		expect(config.has 'another:bar').toBe true

	it "sets variables", ->

		config.set 'test', 'blah'
		expect(config.get 'test').toBe 'blah'

		config.set 'another:foo', 421
		expect(config.get 'another:foo').toBe 421

		config.set 'another:baz:blah', 311
		expect(config.get 'another:baz:blah').toBe 311

