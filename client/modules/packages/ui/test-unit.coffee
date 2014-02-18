
describe 'md', ->
	
	markdown = null
	
	beforeEach ->
		
		inject (uiMarkdownFilter) -> markdown = uiMarkdownFilter
		
	it 'should be able to parse markdown into HTML', ->
		
		expect(markdown('Oh, *hello*')).toEqual('<p>Oh, <em>hello</em></p>\n');

	it 'should sanitize HTML by default', ->
		
		expect(markdown('Oh, <div>hello</div>')).toEqual('<p>Oh, &lt;div&gt;hello&lt;/div&gt;</p>\n');

	it 'should allow unsanitized HTML, if requested', ->
		
		expect(markdown('Oh, <div>hello</div>', false)).toEqual('<p>Oh, <div>hello</div></p>\n');

describe 'notifications', ->
	
	notifications = null
	
	beforeEach ->
		
		inject [
			'ui/notifications'
			(_notifications_) -> notifications = _notifications_
		]
		
	it 'should allow adding and removing notifications', ->
		
		notifications.add text: 'Testing'
		expect(notifications.top().text).toBe 'Testing'
		expect(notifications.count()).toBe 1
		
		notifications.removeTop()
		expect(notifications.top()).toBe undefined
		expect(notifications.count()).toBe 0
		
	it 'should accept notification batches from the socket', ->
		
		inject [
			'$timeout', 'comm/socket'
			($timeout, socket) ->
			
				socket.stimulateOn(
					'notifications'
					notifications: [
						text: 'Testing'
					,
						text: 'Testing'
					,
						text: 'Testing'
					,
						text: 'Testing'
					]
				)
				
				$timeout.flush()
				
				expect(notifications.count()).toBe 4
		]

describe 'title', ->
	
	title = null
	
	beforeEach ->
		
		inject [
			'ui/title'
			(_title_) -> title = _title_
		]
		
	it 'should set window title to site title by default', ->
		
		expect(title.window()).toBe title.site()

	it 'should set window title to page title [separator] site title by default when the page title is set', ->
		
		title.setPage 'Home'
		
		expect(title.window()).toBe "#{title.page()}#{title.separator()}#{title.site()}"

	it 'should allow page title to be set without altering the window title', ->
		
		title.setPage 'Home', false
		
		expect(title.window()).toBe title.site()
		