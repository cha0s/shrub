*Augment or modify directive definition objects.*

This hook allows packages to make changes to
[directive definition objects](https://docs.angularjs.org/api/ng/service/$compile#comprehensive-directive-api)
provided by packages' implementations of the [`directive`](hooks/#directive)
hook.

[`shrub-skin`](packages/#shrub-skinclient) uses this hook to provide the
dynamic directive recompilation necessary to implement on-the-fly skin changes.
