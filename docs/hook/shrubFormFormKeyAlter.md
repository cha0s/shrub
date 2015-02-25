*Alter any [form definition object](guide/forms/#form-definition-objects) whose
key matches before it's rendered.*

This hook targets a specific form key. The form key is automatically
camelized, e.g. form key `shrub-user-login` will match
`shrubFormShrubUserLoginAlter`.

Packages may implement this hook to modify the form definition object in any
way (although altering the key would probably be confusing at this point).
