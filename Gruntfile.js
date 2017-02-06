// This is just an ugly shim since Grunt doesn't support CoffeeScript
// Gruntfiles anymore apparently... Jerks.

require('coffee-script/register');
module.exports = require('./Gruntfile.coffee');
