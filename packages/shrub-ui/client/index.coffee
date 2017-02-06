# # User Interface
#
# *User interface components.*
exports.pkgmanRegister = (registrar) ->

  registrar.recur [
    'attributes', 'list', 'markdown', 'menu', 'messages', 'notifications'
    'window-title'
  ]