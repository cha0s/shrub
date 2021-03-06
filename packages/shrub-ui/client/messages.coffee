# # UI - Messages
#
# *Manage transient UI messages.*

config = require 'config'
errors = require 'errors'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAngularDirective`.
  registrar.registerHook 'shrubAngularDirective', -> [
    '$timeout', 'shrub-ui/messages'
    ($timeout, {count, removeTop, top}) ->

      link: (scope, elm, attr) ->

        activeNotification = null

        $notificationWrapper = elm.find '.notification-wrapper'

        # User closed the notification.
        scope.close = ->
          $timeout.cancel activeNotification
          $notificationWrapper.fadeOut '2000', -> scope.$apply ->
            removeTop()

          return

        scope.$watch(
          -> top()
          ->

            # When we get a new notification, make it our active notification.
            scope.notification = top()
            return if count() is 0

            # Fade it in and keep it on the screen for 15 seconds.
            $notificationWrapper.fadeIn '2000'

            activeNotification = $timeout(
              -> scope.close()
              15000
            )

        )

      template: '''

<div class="notification-wrapper">

  <div
    data-ng-show="!!notification"
    data-ng-class="notification.class"
    class="alert notification fade in"
  >
    <button
      type="button"
      class="close"
      data-ng-click="close()"
    >&times;</button>
    <span data-ng-bind-html="notification.text"></span>
  </div>

</div>

'''

  ]

  # #### Implements hook `shrubRpcCall`.
  registrar.registerHook 'shrubRpcCall', -> [
    'shrub-ui/messages', 'result'
    (messages, result) ->

      # Add a message with the error text, if any.
      result.catch (error) -> messages.add(
        class: 'alert-danger', text: errors.message error
      )

  ]

  # #### Implements hook `shrubAngularService`.
  registrar.registerHook 'shrubAngularService', -> [
    'shrub-socket'
    (socket) ->

      service = {}

      _messages = []

      # ## messages.add
      #
      # *Add a notification to be displayed.*
      service.add = (notification) ->

        notification.class ?= 'alert-info'

        _messages.push notification

      # ## messages.addError
      #
      # *Add an error notification to be displayed.*
      service.addError = (error) -> @add(
        class: 'alert-danger', text: errors.message error
      )

      # ## messages.top
      #
      # *Get the top notification.*
      service.top = -> _messages[0]

      # ## messages.removeTop
      #
      # *Remove the top notification.*
      service.removeTop = -> _messages.shift()

      # ## messages.count
      #
      # *The number of messages to show.*
      service.count = -> _messages.length

      # Accept messages from the server.
      socket.on 'shrub-ui/messages', (data) ->
        service.add message for message in data.messages

      service

  ]

  # #### Implements hook `shrubAngularAppRun`.
  registrar.registerHook 'shrubAngularAppRun', -> [
    'shrub-ui/messages'
    (messages) ->

      errorMessages = config.get 'packageConfig:shrub-ui:errorMessages'
      for errorMessage in errorMessages ? []
        messages.addError errors.unserialize errorMessage

      return

  ]
