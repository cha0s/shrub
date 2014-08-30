
# # User logout

i8n = require 'inflection'
Promise = require 'bluebird'

middleware = require 'middleware'

exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `endpoint`
	registrar.registerHook 'endpoint', ->
		
		route: 'shrub.user.logout'
		
		receiver: (req, fn) ->
		
			# Log out.
			req.logOut().nodeify fn
	
	# ## Implements hook `initialize`
	# Monkey patch http.IncomingMessage.prototype.logout to run our middleware,
	# and return a promise.
	registrar.registerHook 'initialize', ->
		
		{IncomingMessage} = require 'http'
		
		req = IncomingMessage.prototype
		
		# Invoke hook `userBeforeLogoutMiddleware`.
		# Invoked before a user logs out.
		userBeforeLogoutMiddleware = middleware.fromShortName(
			'user before logout'
			'shrub-user'
		)
	
		# Invoke hook `userAfterLogoutMiddleware`.
		# Invoked after a user logs out.
		userAfterLogoutMiddleware = middleware.fromShortName(
			'user after logout'
			'shrub-user'
		)
		
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
