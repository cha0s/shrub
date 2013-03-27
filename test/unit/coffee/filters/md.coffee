describe 'md', ->
	
	it 'should be able to parse markdown into HTML', ->
		
		inject (mdFilter) ->
			
			expect(mdFilter('Oh, *hello*')).toEqual('<p>Oh, <em>hello</em></p>\n');

	it 'should sanitize HTML by default', ->
		
		inject (mdFilter) ->
			
			expect(mdFilter('Oh, <div>hello</div>')).toEqual('<p>Oh, &lt;div&gt;hello&lt;/div&gt;</p>\n');

	it 'should allow unsanitized HTML, if requested', ->
		
		inject (mdFilter) ->
			
			expect(mdFilter('Oh, <div>hello</div>', false)).toEqual('<p>Oh, <div>hello</div></p>\n');
