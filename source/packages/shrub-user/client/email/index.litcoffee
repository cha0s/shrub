# User - email

    exports.pkgmanRegister = (registrar) ->

      registrar.recur [
        'forgot', 'register'
      ]
