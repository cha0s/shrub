# # Grunt build process - Tests
#
# *Build and run the tests.*
exports.pkgmanRegister = (registrar) ->

  registrar.recur [
    'build', 'run'
  ]