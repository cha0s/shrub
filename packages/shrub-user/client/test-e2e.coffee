
describe 'user', ->
	
	it 'should show user pages', ->
		
		for [route, className] in [
			['/user/login', 'shrub-user-login']
			['/user/forgot', 'shrub-user-forgot']
			['/user/register', 'shrub-user-register']
		]
			browser.get route
			expect(shrub.count ".#{className}").toBe 1
		
	it 'should show a password reset page, but only if a token is provided', ->
		
		browser.get '/user/reset'
		expect(shrub.count ".shrub-user-reset").toBe 0
		
		browser.get '/user/reset/token'
		expect(shrub.count ".shrub-user-reset").toBe 1
	
	it 'should redirect from certain pages when the user is logged in', ->
		
		for destination in ['forgot', 'login', 'register'] 
		
			browser.get "/e2e/user/login/#{destination}"
			expect(browser.getCurrentUrl()).not.toContain "#{destination}"
