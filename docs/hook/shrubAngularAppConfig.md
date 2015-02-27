*Allow packages to hook into the configuration phase of the Angular
application.*

Packages should implement this hook when they need to run code during the
Angular module configuration phase. See the
[Angular documentation](https://docs.angularjs.org/guide/module#module-loading-dependencies)
on **Configuration blocks** for more explanation.

<h3>Implementations must return</h3>

An [annotated function](guide/concepts#annotated-functions).
