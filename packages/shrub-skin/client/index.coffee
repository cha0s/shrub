
# # Skinning
# 
# Define skinning components.

config = require 'config'
pkgman = require 'pkgman'

cache = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `augmentDirective`
	registrar.registerHook 'augmentDirective', (directive, path) -> [
	
		'$cacheFactory', '$compile', '$http', '$q'
		($cacheFactory, $compile, $http, $q) ->
			
			# Ensure ID is a candidate.
			directive.candidateKeys ?= []
			directive.candidateKeys.unshift 'id'
			
			cache = $cacheFactory 'shrub-skin' unless cache?
			
			# Proxy link function to add our own directive retrieval and
			# compilation step.
			link = directive.link
			directive.link = (scope, element, attr, controller) ->
				
				topLevelArgs = arguments
				
				# Kick off relinking.
				do relink = ->
					
					# Check the cache before hitting the server.
					# `TODO`: This will become active, not default.
					skinKey = config.get 'packageConfig:shrub-skin:default'
					
					cacheData = cache.get skinKey
					cacheData ?= {}
					cacheData.templates ?= {}
					cacheData.styleSheets ?= []
					
					cacheData.assets = $http.get(
						"/skin/#{skinKey}/assets.json"
					) unless cacheData.assets?
					
					cache.put skinKey, cacheData
					
					assetsPromise = $q.when cacheData.assets
					
					assetsPromise.then ({data}) ->
						cacheData = cache.get skinKey
						
						# Cloak the element.
						element.addClass 'shrub-skin-cloak'
						
						# Gather candidates.
						candidateList = do ->
							list = []
							
							for key in directive.candidateKeys
								if specific = scope[key] ? attr[key]
									list.push specific
								
							list
						
						candidateTemplates = for candidate in candidateList
							"#{path}--#{candidate}.html"
						candidateTemplates.push "#{path}.html"
						
						candidate = do firstCandidate = ->
							for uri in candidateTemplates
								if -1 isnt data.templates.indexOf uri
									return uri
							
							return
						
						unless cacheData.templates[candidate]?
							cacheData.templates[candidate] = if candidate?
								$http.get "/skin/#{skinKey}/#{candidate}"
							else
								$q.when data: false
							
						cache.put skinKey, cacheData
						
						templatePromise = $q.when(
							
							cacheData.templates[candidate]
						
						).then(({data}) ->
							
							# If we got any HTML, insert and compile it.
							if data
								element.html data
								$compile(element.contents())(scope)
							
							hookInvoke = (key) ->
								invocations = [
									key
									"#{key}--#{directive.name}"
								]
								
								invocations.push(
									"#{key}--#{directive.name}--#{c}"
								) for c in candidateList
								
								for hook in invocations
									for f in pkgman.invokeFlat hook
										f topLevelArgs... 
								
								return
							
							# Link.
							hookInvoke 'skinPreLink'
							link topLevelArgs... if link?
							hookInvoke 'skinPostLink'

						# Uncloak the element when finished.
						).finally -> element.removeClass 'shrub-skin-cloak'
						
				# Relink again every time the skin changes.
				scope.$on 'shrub.skin.update', relink
				
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
						
							poll = $interval(
								->
									
									if wasParsed()
										
										$interval.cancel poll
										resolve()
										
									return
									
								10
							)
						
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
						
						cacheData = cache.get skinKey
						cacheData ?= {}
						cacheData.templates ?= {}
						cacheData.styleSheets ?= []
						
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
