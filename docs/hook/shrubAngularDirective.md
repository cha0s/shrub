*Define Angular directives.*

Use this hook to define Angular directives for your application.

Shrub augments Angular directives to automate some functionality:

* `directive.link` is proxied to automatically attempt to invoke the `link`
  method of any controllers attached to the directive. Controllers' `link`
  method is invoked **before** the directive link function.
* If `bindToController` is set on the Directive Definition Object, the
  directive defaults to including a controller of the same name. This means if
  you define a controller and a directive in the same package (which will have
  the same name), and you specify `bindToController` on the directive, that
  controller will be automatically attached.

See [the Angular documentation](https://docs.angularjs.org/api/ng/service/$compile#directive-definition-object)
for more information about how to define a directive.

### Answer with

An [annotated function](guide/concepts#annotated-functions).
