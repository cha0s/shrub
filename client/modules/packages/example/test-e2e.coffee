
describe 'home', ->

	beforeEach ->
		
		browser().navigateTo '/home'

	it 'should render home when user navigates to /home', ->
		
		expect(element('[data-ng-view] h1:first').text()).toBe 'Shrub'

describe 'about', ->

	beforeEach ->
		
		browser().navigateTo '/about'

	it 'should render about when user navigates to /about', ->
		
		expect(element('[data-ng-view] h1:first').text()).toBe 'Shrub'
