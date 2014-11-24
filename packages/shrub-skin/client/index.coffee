
# # Skinning
# 
# Define skinning components.

config = require 'config'

cache = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `augmentDirective`
	registrar.registerHook 'augmentDirective', (directive, path) -> [
	
		'$cacheFactory', '$compile', '$http', '$q'
		($cacheFactory, $compile, $http, $q) ->
			
			cache = $cacheFactory 'shrub-skin' unless cache?
			
			# Proxy link function to add our own directive retrieval and
			# compilation step.
			link = directive.link
			directive.link = (scope, element) ->
				topLevelArgs = arguments
				
				# Call original link function if one exists.
				link.apply null, topLevelArgs if link?
				
				# Kick off relinking.
				do relink = ->
					
					# Check the cache before hitting the server.
					# `TODO`: This will become active, not default.
					skinKey = config.get 'packageConfig:shrub-skin:default'
					uri = "#{path}.html"
					
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
						
						if -1 is data.templates.indexOf uri
							cacheData.templates[uri] ?= $q.when data: false
						else
							cacheData.templates[uri] = $http.get(
								"/skin/#{skinKey}/#{uri}"
							) unless cacheData.templates[uri]?
							
						cache.put skinKey, cacheData
						
						templatePromise = $q.when cacheData.templates[uri]
							
						templatePromise.then ({data}) ->
							return unless data
							
							element.html data
							$compile(element.contents())(scope)
							
							# Call original link function if one exists.
							link.apply null, topLevelArgs if link?
							
						# Uncloak the element when finished.
						templatePromise.finally ->
							element.removeClass 'shrub-skin-cloak'
						
				# Relink again every time the skin changes.
				scope.$on 'shrub.skin.update', relink
				
	]
	
	# ## Implements hook `provider`
	registrar.registerHook 'provider', -> [
	
		'$injector', '$provide', 'shrub-pkgmanProvider', 'shrub-requireProvider'
		($injector, $provide, pkgman, {require}) ->
			
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
