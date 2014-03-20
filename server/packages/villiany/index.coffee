
moment = require 'moment'
nconf = require 'nconf'
i8n = require 'inflection'
Promise = require 'bluebird'
winston = require 'winston'

audit = require 'audit'

{AuthorizationFailure} = require 'AbstractSocketFactory'

{Limiter, threshold} = require 'limits'

logger = new winston.Logger
	transports: [
		new winston.transports.Console level: 'error', colorize: true
		new winston.transports.File level: 'debug', filename: 'logs/villiany.log'
	]
	
exports.$endpointAlter = (endpoints) ->
	
	for route, endpoint of endpoints
	
		endpoint.villianyScore ?= 20

exports.$models = (schema) ->
	
	# Bans.
	# TODO it'd be nice to be able to generate all of this dynamically from
	# audit keys.
	Ban = schema.define 'Ban',
		
		ip:
			index: true
			type: String
		
		session:
			index: true
			type: String
		
		user:
			index: true
			type: Number
		
		expires:
			type: Number


	banTemplate = (where) ->
	
		Ban.all(where: where).bind({}).then((@bans) ->
			return false if @bans.length is 0
			
			# Destroy all expired bans.
			expired = @bans.filter (ban) -> ban.expires <= Date.now()
			Promise.all expired.map (ban) -> ban.destroy()
			
		).then (expired) ->
			
			active = @bans.filter (ban) -> ban.expires > Date.now()
			
			[
				# More bans than those that expired?
				@bans.length > expired.length
				
				# Ban ttl.
				Math.round (active.reduce(
					(l, r) ->
						
						if l.expires > r.expires then l.expires else r.expires
						
					-Infinity
				
				# It's a timestamp, and it's in ms.
				) - Date.now()) / 1000
			]
	
	Ban.isIpBanned = (ip) -> banTemplate ip: ip
		
	Ban.isSessionBanned = (id) -> banTemplate session: id
		
	Ban.isUserBanned = (id) -> banTemplate user: id
		
	Ban.createFromKeys = (keys, expires) ->
		return unless Object.keys(keys).length > 0
		
		unless expires?
			settings = nconf.get 'packageSettings:villiany:ban'
			expires = settings.defaultExpiration
		
		ban = new Ban()
		ban.expires = Date.now() + expires
		ban[key] = value for key, value of keys
		
		ban.save()
		
villianyLimiter = new Limiter(
	"villiany"
	threshold(1000).every(10).minutes()
)

reporterMiddleware = (req, res, next) ->
				
	{models: Ban: Ban} = require 'server/jugglingdb'

	req.reportVilliany = (score, type) ->
		
		auditKeys = audit.keys req
		
		# Terminate the chain if not a villian.
		class NotAVillian extends Error
			constructor: (@message) ->
		
		keys = ("#{key}:#{value}" for key, value of auditKeys)
		villianyLimiter.addAndCheckThreshold(
			keys, score
		
		).bind({}).then((isVillian) ->
			throw new NotAVillian unless isVillian
			
			logger.error "Logged villiany for #{
				type
			}, audit keys: #{
				JSON.stringify auditKeys
			}"
			
			villianyLimiter.ttl keys
					
		).then((@ttl) ->
			
			# Ban.
			Ban.createFromKeys auditKeys
			
		).then(->

			# Kick.
			req.villianyKick @ttl
		
		).then(-> true
		).catch NotAVillian, -> false
		
	next()

# Enforce bans.
enforcementMiddleware = (req, res, next) ->

	{models: Ban: Ban} = require 'server/jugglingdb'

	# Terminate the request if a ban is enforced.
	class RequestBanned extends Error
		constructor: (@message) ->
	
	auditKeys = audit.keys req

	banPromises = for enforced in Object.keys auditKeys
	
		method = i8n.camelize "is_#{enforced}_banned", true
		
		Ban[method](auditKeys[enforced]).spread (isBanned, ttl) ->
			return unless isBanned
			
			req.villianyKick(enforced, ttl).then ->
				
				throw new RequestBanned()
			
	Promise.all(banPromises).then(->
		
		next()
	
	).catch(RequestBanned, ->

	).catch (error) -> next error

buildBanMessage = (subject, ttl) ->
	
	message = if subject?
		"Your #{subject} is banned."
	else
		"You are banned."
		
	if ttl?
		
		message += " The ban will be lifted #{
			moment().add('seconds', ttl).fromNow()
		}."
		
	message

exports.$httpMiddleware = ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	label: 'Provide villiany management'
	middleware: [
		
		(req, res, next) ->
			
			req.villianyKick = (subject, ttl) ->
		
				# Destroy any session.
				req.session?.destroy()
				
				# Log the user out.
				Promise.cast(req.user.logout?()).then ->
					
					res.status 401
					res.end buildBanMessage subject, ttl
					
			next()
		
		reporterMiddleware
		
		enforcementMiddleware
			
	]

exports.$settings = ->
	
	ban:
		
		# 10 minute ban time by default.
		defaultExpiration: 1000 * 60 * 10

exports.$socketAuthorizationMiddleware = ->
	
	label: 'Provide villiany management'
	middleware: [
	
		(req, res, next) ->
			
			req.villianyKick = (subject, ttl) ->
				
				# Destroy any session.
				req.session?.destroy()
				
				# Log the user out.
				Promise.cast(req.user.logout?()).then ->
					
					new Promise (resolve) ->
						
						# Already authorized?
						if req.socket?
							
							req.socket.emit 'core.reload', null, resolve
						
						else
							
							throw new AuthorizationFailure
						
		
			next()
		
		reporterMiddleware
		
		enforcementMiddleware
		
	]
