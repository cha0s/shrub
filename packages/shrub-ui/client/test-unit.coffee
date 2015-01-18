
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

describe 'messages', ->
	
	messages = null
	
	beforeEach ->
		
		inject [
			'shrub-ui/messages'
			(_messages_) -> messages = _messages_
		]
		
	it 'should allow adding and removing messages', ->
		
		messages.add text: 'Testing'
		expect(messages.top().text).toBe 'Testing'
		expect(messages.count()).toBe 1
		
		messages.removeTop()
		expect(messages.top()).toBe undefined
		expect(messages.count()).toBe 0
		
	it 'should accept message batches from the socket', ->
		
		inject [
			'$timeout', 'shrub-socket'
			($timeout, socket) ->
			
				socket.stimulateOn(
					'shrub.ui.messages'
					messages: [
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
				
				expect(messages.count()).toBe 4
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
		