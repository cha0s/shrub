
# # User logout

schema = require 'server/jugglingdb'

# ## Implements hook `endpoint`
exports.$endpoint = -> (req, fn) ->
	
	{User} = schema.models
	
	# Log out.
	req.logout()
	req.user = new User()
	
	fn()
