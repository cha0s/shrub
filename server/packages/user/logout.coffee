
# # User logout

i8n = require 'inflection'
Promise = require 'bluebird'

middleware = require 'middleware'

{defaultLogger} = require 'logging'

# ## Implements hook `endpoint`
exports.$endpoint = -> (req, fn) ->
	
	# Log out.
	req.logOut().nodeify fn

# ## Implements hook `initialize`
# Monkey patch http.IncomingMessage.prototype.logout to run our middleware,
# and return a promise.
exports.$initialize = ->
	
	{IncomingMessage} = require 'http'
	
	req = IncomingMessage.prototype
	
	# Invoke hook `userBeforeLogoutMiddleware`.
	# Invoked before a user logs out.
	userBeforeLogoutMiddleware = middleware.fromShortName 'user before logout'

	# Invoke hook `userAfterLogoutMiddleware`.
	# Invoked after a user logs out.
	userAfterLogoutMiddleware = middleware.fromShortName 'user after logout'
	
	logout = req.passportLogOut = req.logout
	req.logout = req.logOut = ->
		
		new Promise (resolve, reject) =>
	
			logoutReq = req: this, user: @user
			
			userBeforeLogoutMiddleware.dispatch logoutReq, null, (error) =>
				return reject error if error?
				
				logout.call this
				
				userAfterLogoutMiddleware.dispatch logoutReq, null, (error) ->
					return reject error if error?
					
					resolve()
