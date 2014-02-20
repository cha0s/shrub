
describe 'core', ->
	
	ptor = protractor.getInstance()
	
	it 'should be running the server in E2E mode', ->
		
		ptor.get '/e2e/sanity-check'
		expect(browser.getCurrentUrl()).toContain '/e2e/sanity-check'
