# Example package

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubUiNotificationQueues`.

Implement the `general` queue, used to show some notifications.

      registrar.registerHook 'shrubUiNotificationQueues', ->

        general:

          channelFromRequest: (req) -> req.session?.id

      registrar.recur [
        'about'
      ]
