
# # User logout

# ## Implements hook `endpoint`
exports.$endpoint = -> (req, fn) ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	# Log out.
	req.logout()
	req.user = new User()
	
	fn()
