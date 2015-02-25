# Form - Submit

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubAngularDirective`.

      registrar.registerHook 'shrubAngularDirective', -> [
        ->

          scope: field: '=?'

          link: (scope) ->

            scope.$watch 'field', (field) ->

              scope.$watch 'field', (field) ->

                field.value ?= 'Submit'

          template: '''

    <div class="form-group">

      <input
        class="btn btn-default"
        name="{{field.name}}"
        type="submit"

        data-ng-value="field.value"
      >

    </div>

    '''

      ]

      assignToElement = (element, value) -> element.val value

#### Implements hook `shrubFormWidgets`.

      registrar.registerHook 'shrubFormWidgets', ->

        widgets = []

        widgets.push

          type: 'submit'
          assignToElement: assignToElement
          directive: 'shrub-form-widget-submit'

        widgets
