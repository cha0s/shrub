
# # User emails

exports.pkgmanRegister = (registrar) ->

  registrar.recur [
    'forgot', 'register'
  ]
