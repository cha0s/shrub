<h1>Form handling</h1>

Forms are created by passing a form definition object to the
[`shrub-form` directive](source/packages/shrub-form/client#implements-hook-shrubangulardirective).

A form definition object is defined like:

* (Optional String) `key` - The form hey included on the form as a hidden
  value, also used to generate an HTML class. Defaults to the scope key (See
  below).
* (Function Array) `submits` - An array of functions to be invoked when the
  form is submitted. The functions take a single `values` parameter containing
  a keyed object of all field values in the form.
* (Object) `fields` - A keyed object of all form fields. Each field is defined
  like:
    * (String) `type` - The [widget](hooks/#shrubformwidgets) type.
    * (Optional String) `label` - The human-readable label. Defaults to no
      label.
    * (Optional Boolean) `required` - Whether this field is required for
      submission. Defaults to `false`.
    * (Optional Any) `value` - The default value of this field.
    * Widgets can define arbitrary parameters, see the documentation for the
      specific widget to learn any extra parameters.

The following builtin widgets and their extra parameters are:

`checkboxes`:

  * (Array) `checkboxes` - An array of checkbox field definitions.

`radio`:

  * (Any) `selectedValue` - What `value` will be populated with when this
    radio is selected.

`radios`:

  * (Array) `radios` - An array of radio field definitions.

`select`:

  * (String) `options` - An options expression. See
    [the Angular documentation](https://docs.angularjs.org/api/ng/directive/ngOptions)
    for more information.

`text`:

  * (Number) `minlength` - The minimum length of the text field.
  * (Number) `maxlength` - The maximum length of the text field.
  * (String) `pattern` - An expression that evaluates to a RegExp to test
    for validity. See
    [the Angular documentation](https://docs.angularjs.org/api/ng/input/input[text]#example)
    for more information.
  * (Boolean) `trim` - Whether to trim the input.

If you define a form definition object like:

```javascript
  $scope.someFormThing =
    submits: [
      ->
    ]
    fields:
      foo:
        type: 'text'
```

You can include it into a directive under the scope like:

```html
<div
  data-shrub-form
  data-form="someFormThing"
></div>
```

In this case, the form key will default to `someFormThing`.

