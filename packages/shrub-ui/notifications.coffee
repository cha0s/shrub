
Promise = require 'bluebird'

pkgman = require 'pkgman'

orm = require 'shrub-orm'

notificationQueues = {}

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `bootstrapMiddleware`
	registrar.registerHook 'bootstrapMiddleware', ->
	
		label: 'Register notification queues'
		middleware: [
		
			(next) ->
				
				for path, queue of pkgman.invoke 'notificationQueue'
					notificationQueues[pkgman.normalizePath path] = queue
			
				next()
				
		]
	
	# ## Implements hook `collections`
	registrar.registerHook 'collections', ->
		
		Notification =
		
			attributes:
			
				# Has the notification been read?
				markedAsRead:
					type: 'boolean'
					defaultsTo: false
				
				# Who owns this notification? Built by the queue.
				owner: 'string'
				
				# To where does this notification link?
				path: 'string'
				
				# To which queue does this notification belong?
				queue:
					type: 'string'
					notEmpty: true
				
				# Variables, can be any type.
				variables: 'json'
				
			createFromRequest: (req, queueName, variables, path) ->
				
				# Check that the queue is valid.
				unless queue = notificationQueues[queueName]
					return Promise.reject new Error(
						"Notification queue `#{queue}' doesn't exist."
					)
				
				# Defaults.
				path ?= 'javascript:void(0)'
				variables ?= {}
				
				# Get the owner from the request.
				owner = queue.ownerFromRequest req
				
				# Create the notification.
				@create(
					owner: owner
					path: path
					queue: queueName
					variables: variables
				
				).then (notification) ->
					return unless req.socket?
					
					req.socket.emit(
						'shrub.ui.notifications'
						queue: queueName
						notifications: [notification]
					) 
				
			# Get a queue's notifications from a request.
			queueFromRequest: (req) ->
				
				# Empty queue if none was defined.
				unless queue = notificationQueues[req.body.queue]
					return Promise.resolve []
				
				# Return the 20 newest notifications from the queue for the
				# request's owner, skipping as many records as requested.
				query = @find()
				query = query.where(owner: queue.ownerFromRequest req)
				query = query.where(queue: req.body.queue)
				query = query.skip(req.body.skip ? 0)
				query = query.limit(20)
				query.sort('createdAt DESC')

				# Redact the notifications before sending them over the wire.
				query.then (notifications) ->
					Promise.all(
						notifications.map (notification) -> 
							notification.redactFor req.user
					).then -> notifications
			
			# Remove unnecessary details.	
			redactors: [(redacted) ->
				
				delete redacted.owner
				delete redacted.queue
				delete redacted.updatedAt
				
			]
				
		'shrub-ui-notification': Notification

	# ## Implements hook `config`
	registrar.registerHook 'config', (req) ->
		
		# Make sure ORM is up (it won't be when grunt is running).
		return unless Notification = orm.collection 'shrub-ui-notification'
		
		# Get all the notification queues.
		promiseKeys = []
		promises = for key, queue of notificationQueues
			promiseKeys.push key
			
			req.body.queue = key
			Notification.queueFromRequest req
			
		# Load any queues into the config.
		Promise.all(promises).then (notificationsList) ->
			queuesConfig = null
			
			for notifications, index in notificationsList
				continue if notifications.length is 0
				
				# Reverse the notifications because the client will prepend new
				# notifications, not append.
				queuesConfig ?= {}
				queuesConfig[promiseKeys[index]] = notifications.reverse()
				
			queuesConfig
		
	# ## Implements hook `endpoint`
	registrar.registerHook 'markAsRead', 'endpoint', ->
		
		route: 'shrub.ui.notifications.markAsRead'
		
		receiver: (req, fn) ->
			
			Notification = orm.collection 'shrub-ui-notification'
			Notification.findOne(id: req.body.id).then((notification) ->
				
				notification.markedAsRead = req.body.markedAsRead
				notification.save -> fn()
			
			).catch fn
		
	# ## Implements hook `endpoint`
	registrar.registerHook 'endpoint', ->
		
		route: 'shrub.ui.notifications'
		
		receiver: (req, fn) ->
			
			Notification = orm.collection 'shrub-ui-notification'
			Notification.queueFromRequest(req).then((notifications) ->
				
				fn null, notifications
			
			).catch fn
