
describe 'user', ->
	
	it 'should show user pages', ->
		
		for [route, form] in [
			['/user/login', 'userLogin']
			['/user/forgot', 'userForgot']
			['/user/register', 'userRegister']
		]
			browser().navigateTo route
			expect(element("form.#{form}").count()).toBe 1
		
	it 'should show a password reset page, but only if a token is provided', ->
		
		browser().navigateTo '/user/reset'
		expect(element('form.userReset').count()).toBe 0
		
		browser().navigateTo '/user/reset/token'
		expect(element('form.userReset').count()).toBe 1
	
	it 'should redirect from certain pages when the user is logged in', ->
		
		for destination in ['forgot', 'login', 'register'] 
		
			browser().navigateTo "/e2e/user/login/#{destination}"
			sleep .2
			expect(browser().location().url()).toBe '/home'
