# Example package

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `notificationQueues`.

Implement the `general` queue, used to show some notifications.

      registrar.registerHook 'notificationQueues', ->

        general:

          channelFromRequest: (req) -> req.session?.id

      registrar.recur [
        'about'
      ]
