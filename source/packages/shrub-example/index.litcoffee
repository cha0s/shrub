# Example package

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `notificationQueue`.

Implement the `general` queue, used to show some notifications.

      registrar.registerHook 'general', 'notificationQueue', ->

        channelFromRequest: (req) -> req.session?.id

      registrar.recur [
        'about'
      ]
