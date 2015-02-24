*Hook into the Grunt build process.*

This hook allows packages to define Grunt tasks, configure existing tasks, and
load NPM tasks. This is achieved through the first implementation parameter
which is an instance of the class
[`GruntConfiguration`](source/Gruntfile/#gruntconfiguration). The
`grunt` object is passed in through the second parameter in case it's needed.

One of the most common uses of this hook is to copy any asset files your
package may include to the `app` directory, where they can be served to
clients.
