*Alter configuration variables defined by packages.*

Packages can implement this hook to alter configuration variables defined by
any other (or even the same) package.

Implementations are passed a [`Config`](source/client/modules/config/) object.

See: [`config`](hooks/#config).
