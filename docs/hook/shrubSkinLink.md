*Register a link function to run on all directives.*

This hook allows packages to run additional link functions for directives. The
link functions are run every time skin or attribute changes result in directive
recompilation.

<h3>Implementations must return</h3>

An [annotated function](guide/concepts#annotated-functions). The following
locals are injected:

* (Scope) `$scope` - Angular scope object for this directive.
* (jqLite element) `$element`: Directive DOM element.
* (Attributes) `$attr`: Directive attributes object.
* (Function or Function Array or null) `$controller`: Directive controller(s), if
  any.
* (Function or null) `$transclude`: Transclusion function, if any.
