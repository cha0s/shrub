
describe 'home', ->
	
	beforeEach ->
		
		browser.get '/home'

	it 'should render home when user navigates to /home', ->
		
		tag = (element `by`.css '[data-ng-view] h1')
		expect(tag.getText()).toBe 'Shrub'

describe 'about', ->
	
	beforeEach ->
		
		browser.get '/about'

	it 'should render about when user navigates to /about', ->
		
		tag = (element `by`.css '[data-ng-view] h1')
		expect(tag.getText()).toBe 'Shrub'
