
# # Villiany
# 
# Watch for and punish bad behavior.

moment = require 'moment'
nconf = require 'nconf'
i8n = require 'inflection'
Promise = require 'bluebird'

audit = require 'audit'
logging = require 'logging'

{AuthorizationFailure} = require 'packages/socket/manager'
{Limiter, threshold} = require 'limits'
schema = require 'schema'

logger = logging.create 'logs/villiany.log'
	
# ## Implements hook `endpointAlter`
exports.$endpointAlter = (endpoints) ->
	
	for route, endpoint of endpoints
	
		endpoint.villianyScore ?= 20

# ## Implements hook `models`
exports.$models = (schema) ->
	
	fingerprintKeys = audit.fingerprintKeys()
	
	# Bans.
	model = expires: type: Number
	
	# The structure of a ban is dictated by the fingerprint structure.
	for key in fingerprintKeys
		model[key] =
			index: true
			type: String
	
	Ban = schema.define 'Ban', model
	
	# Generate a test for whether each fingerprint key has been banned.
	fingerprintKeys.forEach (key) ->
		
		# `session` -> `isSessionBanned`
		Ban[i8n.camelize "is_#{key}_banned", true] = (value) ->
			where = {}
			where[key] = value
			
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
							
							if l.expires > r.expires
								l.expires
							else
								r.expires
							
						-Infinity
					
					# It's a timestamp, and it's in ms.
					) - Date.now()) / 1000
				]
	
	# Create a ban from a fingerprint.	
	Ban.createFromFingerprint = (fingerprint, expires) ->
		return unless Object.keys(fingerprint).length > 0
		
		unless expires?
			settings = nconf.get 'packageSettings:villiany:ban'
			expires = settings.defaultExpiration
		
		ban = new Ban expires: Date.now() + expires
		ban[key] = fingerprint[key] for key in fingerprintKeys
			
		ban.save()
		
villianyLimiter = new Limiter(
	"villiany"
	threshold(1000).every(10).minutes()
)

# Define `req.reportVilliany()`.
reporterMiddleware = (req, res, next) ->
	
	{Ban} = schema.models			

	req.reportVilliany = (score, type) ->
		
		fingerprint = audit.fingerprint req
		
		# Terminate the chain if not a villian.
		class NotAVillian extends Error
			constructor: (@message) ->
		
		keys = ("#{key}:#{value}" for key, value of fingerprint)
		villianyLimiter.accrueAndCheckThreshold(
			keys, score
		
		).then((isVillian) ->
			
			# Log this transgression.
			message = "Logged villiany score #{
				score
			} for #{
				type
			}, audit keys: #{
				JSON.stringify fingerprint
			}"
			message += ", which resulted in a ban." if isVillian
			logger[if isVillian then 'error' else 'warn'] message 
			
			throw new NotAVillian unless isVillian
			
			# Ban.
			Ban.createFromFingerprint fingerprint
			villianyLimiter.ttl keys
					
		).then((ttl) ->
			
			# Kick.
			req.villianyKick ttl
		
		).then(-> true
		).catch NotAVillian, -> false
		
	next()

# Enforce bans.
enforcementMiddleware = (req, res, next) ->

	{Ban} = schema.models

	# Terminate the request if a ban is enforced.
	class RequestBanned extends Error
		constructor: (@message) ->
	
	fingerprint = audit.fingerprint req

	banPromises = for enforced in Object.keys fingerprint
	
		method = i8n.camelize "is_#{enforced}_banned", true
		
		Ban[method](fingerprint[enforced]).spread (isBanned, ttl) ->
			return unless isBanned
			
			req.villianyKick(enforced, ttl).then ->
				
				throw new RequestBanned()
			
	Promise.all(banPromises).then(->
		
		next()
	
	).catch(RequestBanned, ->

	).catch (error) -> next error

# Build a nice message for the villian.
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

# ## Implements hook `httpMiddleware`
exports.$httpMiddleware = ->
	
	label: 'Provide villiany management'
	middleware: [
		
		(req, res, next) ->
			
			req.villianyKick = (subject, ttl) ->
		
				# Destroy any session.
				req.session?.destroy()
				
				# Log the user out.
				req.logout().then ->
					
					res.status 401
					res.end buildBanMessage subject, ttl
					
			next()
		
		reporterMiddleware
		
		enforcementMiddleware
			
	]

# ## Implements hook `settings`
exports.$packageSettings = ->
	
	ban:
		
		# 10 minute ban time by default.
		defaultExpiration: 1000 * 60 * 10

# ## Implements hook `socketAuthorizationMiddleware`
exports.$socketAuthorizationMiddleware = ->
	
	label: 'Provide villiany management'
	middleware: [
	
		(req, res, next) ->
			
			req.villianyKick = (subject, ttl) ->
				
				# Destroy any session.
				req.session?.destroy()
				
				# Log the user out.
				req.logout().then ->
					
					# Already authorized?
					if req.socket?
						
						req.socket.emit 'core.reload'
					
					else
						
						throw new AuthorizationFailure
						
		
			next()
		
		reporterMiddleware
		
		enforcementMiddleware
		
	]
