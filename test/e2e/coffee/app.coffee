beforeEach ->
	
	browser().navigateTo '../../app/index.html'

it 'should automatically redirect to /home when location hash/fragment is empty', ->

	expect(browser().location().path()).toBe '/home'
