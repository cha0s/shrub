*Define form widgets for use when defining
[form definition objects](guide/forms/#form-definition-objects).*

<h3>Implementations must return</h3>

An array of objects structured like:

* (String) `type` - The widget type, used in form definition objects.
* (String) `directive` - The directive used to render the widget.
* (Optional Function) `assignToElement` - A function which can be used to apply
  complex widget values to the widget element. The function takes two
  parameters:
    * (jqLite/jQuery object) `element` - The widget's wrapped DOM element.
    * (Any) `value` - The value to apply to the widget element.
