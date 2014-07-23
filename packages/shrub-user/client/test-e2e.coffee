
describe 'user', ->
	
	it 'should show user pages', ->
		
		for [route, className] in [
			['/user/login', 'userLogin']
			['/user/forgot', 'userForgot']
			['/user/register', 'userRegister']
		]
			browser.get route
			expect(shrub.count ".#{className}").toBe 1
		
	it 'should show a password reset page, but only if a token is provided', ->
		
		browser.get '/user/reset'
		expect(shrub.count ".userReset").toBe 0
		
		browser.get '/user/reset/token'
		expect(shrub.count ".userReset").toBe 1
	
	it 'should redirect from certain pages when the user is logged in', ->
		
		for destination in ['forgot', 'login', 'register'] 
		
			browser.get "/e2e/user/login/#{destination}"
			expect(browser.getCurrentUrl()).not.toContain "#{destination}"
