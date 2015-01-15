
# # Skinning
# 
# Define skinning components.

config = require 'config'
pkgman = require 'pkgman'

cache = null

loadCacheData = (skinKey) ->

	cacheData = cache.get skinKey
	cacheData ?= {}
	cacheData.templates ?= {}
	cacheData.styleSheets ?= []
	
	cacheData

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `augmentDirective`
	registrar.registerHook 'augmentDirective', (directive, path) -> [
	
		'$cacheFactory', '$compile', '$http', '$interpolate', '$q', '$rootScope'
		($cacheFactory, $compile, $http, $interpolate, $q, $rootScope) ->
			
			# Ensure ID is a candidate.
			directive.candidateKeys ?= []
			directive.candidateKeys.unshift 'id'
			
			cache = $cacheFactory 'shrub-skin' unless cache?
			
			# Proxy link function to add our own directive retrieval and
			# compilation step.
			link = directive.link
			directive.link = (scope, element, attrs, controller) ->
			
				# Save top-level arguments for later calls to link functions.
				topLevelArgs = arguments
				
				# Current template candidate.
				candidate = null
				
				# Check the cache before hitting the server.
				# `TODO`: This will become active, not default.
				skinKey = config.get 'packageConfig:shrub-skin:default'
				cacheData = loadCacheData skinKey
				
				# Fetch assets.
				# `TODO`: This should be sent along through config.
				unless cacheData.assets?
					cacheData.assets = $http.get "/skin/#{skinKey}/assets.json"
					cache.put skinKey, cacheData
				
				$q.when(cacheData.assets).then ({data}) ->
				
					candidateHooksInvoked = {}
				
					recalculateCandidate = ->
					
						# Track changes to the current template candidate.
						oldCandidate = candidate
						
						# Build a list of all candidates by first attempting to
						# interpolate candidate keys, and falling back to
						# attribute values, if any. Candidate arrays are
						# joined by single dashes.
						candidateList = do (scope, attrs) ->
							list = []
							
							for keys in directive.candidateKeys
								keys = [keys] unless angular.isArray keys
								
								item = []
								for key in keys
									specific = $interpolate("{{#{key}}}")(scope)
									specific ?= attrs[key]
									
									item.push specific if specific
								
								item = item.join '-'
								list.push item if item
								
							list
					
						# Map the candidate list to template filenames and
						# add the base path template candidate.
						candidateTemplates = for candidate_ in candidateList
							"#{path}--#{candidate_}.html"
						candidateTemplates.push "#{path}.html"
						
						# Return the first existing template. The asset
						# templates are already sorted by descending
						# specificity.
						candidate = do ->
							for uri in candidateTemplates
								if -1 isnt data.templates.indexOf uri
									return uri
							
							return
							
						# Load the template if necessary, or stub it out to
						# denote no available candidate.
						unless cacheData.templates[candidate]?
							cacheData.templates[candidate] = if candidate?
								$http.get "/skin/#{skinKey}/#{candidate}"
							else
								false
							
						cache.put skinKey, cacheData
						
						# Invoke a skinLink hook once for every candidate.
						invokeHooks = ->
						
							invocations = [
								'skinLink'
								"skinLink--#{directive.name}"
							]
							
							# Add the candidates in reverse order, so they
							# ascend in specificity.
							invocations.push(
								"skinLink--#{directive.name}--#{c}"
							) for c in candidateList.reverse()
							
							for hook in invocations
								continue if candidateHooksInvoked[hook]
								candidateHooksInvoked[hook] = true
								for f in pkgman.invokeFlat hook
									f topLevelArgs... 
							
							return
					
						# If the candidate changed, clear the hook invocation
						# cache and relink, followed by invoking the
						# candidate link hooks. 
						if candidate isnt oldCandidate
							candidateHooksInvoked = {}
							if linkPromise = relink()
								linkPromise.then invokeHooks
							else
								invokeHooks()
						else
							invokeHooks()
							
					# Set watches for all candidate-related values.
					keysSeen = {}
					watchers = []
					for keys in directive.candidateKeys
	
						keys = [keys] unless angular.isArray keys
						for key in keys
							continue if keysSeen[key]
							keysSeen[key] = true
							
							watchers.push -> scope[attrs[key]]
							watchers.push -> $interpolate("{{#{key}}}")(scope)
							
					scope.$watchGroup watchers, recalculateCandidate
							
					# Relink again every time the skin changes.
					$rootScope.$on 'shrub.skin.update', recalculateCandidate
					
				# Kick off relinking.
				relink = ->
					
					# Call directive link function.
					executeRelink = -> link topLevelArgs... if link?
					
					# Uncloak the element when finished.
					uncloak = -> element.removeClass 'shrub-skin-cloak'
				
					# No template...
					unless cacheData.templates[candidate]
					
						executeRelink()
						uncloak()
						
						return

					# Wait for the template to be loaded.
					templatePromise = $q.when(
						
						cacheData.templates[candidate]
					
					).then(({data}) ->

						# Insert and compile HTML.
						element.html data
						$compile(element.contents())(scope)

						executeRelink()
						
					).finally uncloak
					
	]
	
	# ## Implements hook `provider`
	registrar.registerHook 'provider', -> [
	
		'$injector', '$provide'
		($injector, $provide) ->
			
			provider = {}
			
			provider.$get = [
				'$http', '$interval', '$q', '$rootScope', '$window'
				($http, $interval, $q, $rootScope, $window) ->
					
					service = {}
					
					service.addStylesheet = (href) ->
						
						deferred = $q.defer()
						
						styleSheets = $window.document.styleSheets
						index = styleSheets.length
						
						element = $window.document.createElement 'link'
						element.type = 'text/css'
						element.rel = 'stylesheet'
						element.href = "/skin/shrub-skin-strapped/#{href}"
						element.className = 'skin'
						document.getElementsByTagName('head')[0].appendChild element
						
						resolve = -> deferred.resolve()
						
						wasParsed = ->
							
							try
		
								styleSheet = styleSheets[index]
								
								return true if styleSheet.cssRules
								return true if styleSheet.rules?.length
								
								return false
							
							catch error
								
								return false
								
						# A rare case where IE actually does the right thing!
						# (and Opera).
						if $window.opera or -1 isnt $window.navigator.userAgent.indexOf 'MSIE'
							
							element.onload = resolve
							element.onreadystatechange = ->
								switch @readyState
									when 'loaded', 'complete'
										resolve()
						
						# Everyone else needs to resort to polling.
						else
						
							poll = $interval ->
									
								if wasParsed()
									
									$interval.cancel poll
									resolve()
									
								return
								
							, 10
						
						deferred.promise
					
					service.addStylesheets = (hrefs) ->
						$q.all (service.addStylesheet href for href in hrefs)
					
					addBodyCloak = ->
					
						$body = angular.element 'body'
						$body.addClass 'shrub-skin-cloak'
					
					removeBodyCloak = ->

						$body = angular.element 'body'
						$body.removeClass 'shrub-skin-cloak'
						
					removeSkinStylesheets = ->
					
						head = window.document.getElementsByTagName('head')[0]
						
						node = head.firstChild
						while node
							
							nextNode = node.nextSibling
							
							if 'LINK' is node.tagName
								if -1 isnt node.className.split(' ').indexOf 'skin'
									head.removeChild node
					
							node = nextNode
							
						return
							
					environmentKey = if 'production' is cache.get 'environment'
						'production'
					else
						'default'
					
					service.change = (key) ->
						
						# Check the cache before hitting the server.
						# `TODO`: This will become active, not default.
						skinKey = config.get 'packageConfig:shrub-skin:default'
						
						cacheData = loadCacheData skinKey
						
						cacheData.assets = $http.get(
							"/skin/#{skinKey}/assets.json"
						) unless cacheData.assets?
						
						cache.put skinKey, cacheData
						
						assetsPromise = $q.when cacheData.assets
						
						assetsPromise.then ({data}) ->
							cacheData = cache.get skinKey
							
							cacheData.styleSheets = data.styleSheets[environmentKey]
							cache.put skinKey, cacheData
							
							# Cloak the body.
							addBodyCloak()
							removeSkinStylesheets()
							
							# Uncloak and notify when finished.
							service.addStylesheets(
								cacheData.styleSheets
							).finally ->
								removeBodyCloak()
								
								$rootScope.$broadcast 'shrub.skin.changed'
						
					service
				
			]
			
			provider
		
	]
