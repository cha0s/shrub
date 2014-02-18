
describe 'core', ->
	
	it 'should be running the server in E2E mode', ->
		
		browser().navigateTo '/e2e/sanity-check'
		expect(browser().location().url()).toBe '/e2e/sanity-check'
