# # Form - Text
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAngularDirective`.
  registrar.registerHook 'shrubAngularDirective', -> [
    ->

      scope: field: '=', form: '='

      link: (scope) ->

        scope.$watch 'field', (field) ->

          field.minLength ?= 0
          field.maxLength ?= Infinity
          field.pattern ?= /.*/
          field.model ?= 'field.value'

          field.syncModel scope

      template: '''

<label
  data-ng-if="!!field.label"
  data-ng-bind="field.label"
></label>

<textarea
  class="form-control"
  name="{{field.name}}"
  type="{{field.type}}"

  data-shrub-ui-attributes="field.attributes"
  data-ng-keypress="field.keyPress($event)"
  data-ng-model="field.value"
  data-ng-required="field.required"
  data-ng-minlength="{{field.minlength}}"
  data-ng-maxlength="{{field.maxlength}}"
  data-ng-pattern="field.pattern"
  data-ng-trim="{{field.trim}}"
></textarea>

'''

  ]

  assignToElement = (element, value) -> element.val value

  # #### Implements hook `shrubFormWidgets`.
  registrar.registerHook 'shrubFormWidgets', ->

    widgets = []

    widgets.push

      type: 'textarea'
      assignToElement: assignToElement
      directive: 'shrub-form-widget-textarea'

    widgets