
describe 'md', ->
	
	markdown = null
	
	beforeEach ->
		
		inject (shrubUiMarkdownFilter) -> markdown = shrubUiMarkdownFilter
		
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
			'shrub-ui/notifications'
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
			'$timeout', 'shrub-socket'
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
	
	windowTitle = null
	
	beforeEach ->
		
		inject [
			'shrub-ui/window-title'
			(_windowTitle_) -> windowTitle = _windowTitle_
		]
		
	it 'should set window title to page title [separator] site title by default when the page title is set', ->
		
		windowTitle.setPage 'Home'
		
		expect(windowTitle.get()).toBe "#{
			windowTitle.page()
		}#{
			windowTitle.separator()
		}#{
			windowTitle.site()
		}"

	it 'should allow page title to be set without altering the window title', ->
		
		windowTitle.setPage 'Home', false
		
		expect(windowTitle.get()).not.toContain 'Home'
		