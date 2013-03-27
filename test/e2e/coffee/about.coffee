describe 'about', ->

	beforeEach ->
		
		browser().navigateTo '#/about'

	it 'should render about when user navigates to /about', ->
		
		expect(element('[data-ng-view] h2:first').text()).not().toBe 'Weird, loading the about page failed. Try refreshing.'
