describe 'title', ->
	
	title = null
	
	beforeEach ->
		
		inject (_title_) -> title = _title_
		
	it 'should set window title to site title by default', ->
		
		expect(title.window()).toBe title.site()

	it 'should set window title to page title [separator] site title by default when the page title is set', ->
		
		title.setPage 'Home'
		
		expect(title.window()).toBe "#{title.page()}#{title.separator()}#{title.site()}"

	it 'should allow page title to be set without altering the window title', ->
		
		title.setPage 'Home', false
		
		expect(title.window()).toBe title.site()
		