describe 'home', ->

	beforeEach ->
		
		browser().navigateTo '#/home'

	it 'should render home when user navigates to /home', ->
		
		expect(element('[data-ng-view] h1:first').text()).toBe 'Shrub'
