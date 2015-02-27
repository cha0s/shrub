# Strapped - Notifications

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubSkinLink--DIRECTIVE`.

      registrar.registerHook 'shrubSkinLink--shrubUiNotifications', -> [
        '$compile', '$scope', '$element', '$attr'
        ($compile, scope, element, attr) ->

Initialize the popover.

          ($button = element.find 'button').popover

            container: 'body'
            content: -> element.find '.notifications'
            html: true
            placement: 'bottom'
            template: """

    <div class="popover popover-notifications popover-#{attr.queueName}" role="tooltip">
      <div class="arrow"></div>
      <div class="popover-title"></div>
      <div class="popover-content"></div>
    </div>

    """
            title: ->

              tpl = '''

    <div
      class="title"
      data-shrub-ui-notifications-title
    ></div>

    '''

              $compile(tpl)(scope)


When the notifications are opened, acknowledge them.

          $button.on 'show.bs.popover', -> scope.$emit 'shrub.ui.notifications.acknowledged'

Wait for the new queue to be compiled into the DOM, and then reposition the
popover, since the new content may shift it.

          scope.$watch(
            'queue.notifications()', -> scope.$$postDigest ->
              return unless (pop = $button.data 'bs.popover').$tip?
              return unless pop.$tip.hasClass 'in'
              pop.applyPlacement(
                pop.getCalculatedOffset(
                  'bottom', pop.getPosition()
                  pop.$tip[0].offsetWidth
                  pop.$tip[0].offsetHeight
                )
                'bottom'
              )
            true
          )

Hide the popover if any notification is clicked.

          scope.$on 'shrub.ui.notification.clicked', -> $button.popover 'hide'

      ]

