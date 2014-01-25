
exports.$endpoint = 

	(req, data, fn) ->
		
		{models: User: User} = require 'server/jugglingdb'
	
		fn null, if req.user?
			req.user
		else
			new User()

exports.forgot = require 'packages/user/forgot'
exports.login = require 'packages/user/login'
exports.logout = require 'packages/user/logout'
exports.register = require 'packages/user/register'
exports.reset = require 'packages/user/reset'
