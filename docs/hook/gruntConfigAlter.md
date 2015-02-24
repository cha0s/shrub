*Alter the Grunt build process.*

This hook allows packages to alter Grunt configuration specified through
[`gruntConfig`](hooks/#gruntconfig).

The first implementation parameter is an instance of the class
[`GruntConfiguration`](source/Gruntfile/#gruntconfiguration). The `grunt`
object is passed in through the second parameter in case it's needed.
