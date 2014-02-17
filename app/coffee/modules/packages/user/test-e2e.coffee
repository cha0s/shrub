
describe 'user', ->
	
	it 'should show a login page', ->
		
		browser().navigateTo '/user/login'
		expect(element('form.userLogin').count()).toBe 1
		
	it 'should show a forgot password page', ->
		
		browser().navigateTo '/user/forgot'
		expect(element('form.userForgot').count()).toBe 1
		
	it 'should show a registration page', ->
		
		browser().navigateTo '/user/register'
		expect(element('form.userRegister').count()).toBe 1
		
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
