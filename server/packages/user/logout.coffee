
# # User logout

i8n = require 'inflection'
config = require 'config'
Promise = require 'bluebird'

middleware = require 'middleware'

{defaultLogger} = require 'logging'

# ## Implements hook `endpoint`
exports.$endpoint = -> (req, fn) ->
	
	# Log out.
	req.logout().nodeify fn

# ## Implements hook `initialize`
# Monkey patch http.IncomingMessage.prototype.logout to run our middleware,
# and return a promise.
exports.$initialize = (config) ->
	
	{IncomingMessage} = require 'http'
	
	req = IncomingMessage.prototype
	
	# DRY helper.
	buildMiddleware = (type) ->
		
		defaultLogger.info "Loading user #{type} middleware..."
		
		builtMiddleware = middleware.fromHook(
			"user#{i8n.camelize type.replace ' ', '_'}Middleware"
			config.get "packageSettings:user:#{
				i8n.camelize type.replace(' ', '_'), true
			}Middleware"
		)
		
		defaultLogger.info "User #{type} middleware loaded."
		
		builtMiddleware
	
	# Invoke hook `userBeforeLogoutMiddleware`.
	# Invoked before a user logs out.
	userBeforeLogoutMiddleware = buildMiddleware 'before logout'

	# Invoke hook `userAfterLogoutMiddleware`.
	# Invoked after a user logs out.
	userAfterLogoutMiddleware = buildMiddleware 'after logout'
	
	logout = req.logout
	req.logout = req.logOut = ->
		
		new Promise (resolve, reject) =>
	
			logoutReq = req: this, user: @user
			
			userBeforeLogoutMiddleware.dispatch logoutReq, null, (error) =>
				return reject error if error?
				
				logout.call this
				
				userAfterLogoutMiddleware.dispatch logoutReq, null, (error) ->
					return reject error if error?
					
					resolve()
