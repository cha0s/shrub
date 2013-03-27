
$module.service 'nav', ->
	
# This API allows you to dynamically change the navigation links.
	
	_links = []
	
# Get and set the navigation links. The links are objects structured like so:
# 
# * pattern: A string or regex containing the path to match to set this item
# active.
# * href: Target navigation path when this item is clicked.
# * name: Human readable name for the item.
# 
# e.g.
# 
#     item =
#         pattern: '/home'
#         href: '#/home'
#         name: 'Home'
	
	@links = -> _links
	@setLinks = (links) -> _links = links
	
	return
