*Clear out cached data.*

Shrub provides a primitive way to clear caches held by packages. You might
define a variable at the module scope to hold the result of some expensive
calculation and skip the calculation in the future. Implementing this hook
provides a consistent way to clear that cache at runtime.

**NOTE:** This hook is admittedly under-utilized in shrub's core packages, and
probably isn't very useful for the time being. It's never even invoked by any
packages by default.
