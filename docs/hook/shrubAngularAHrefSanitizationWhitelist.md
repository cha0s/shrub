*Allow packages to define whitelisted patterns for ngHref attributes.*

By default, Angular filters 'unsafe' URLs passed to the ngHref attribute. This
behavior is normally configured through
[$compileProvider.aHrefSanitizationWhitelist](https://docs.angularjs.org/api/ng/provider/$compileProvider#aHrefSanitizationWhitelist)
so Shrub provides this hook to make it easy to add your own whitelisted
patterns.

Implementations of this hook should return an array of strings. The strings
are compiled into a regular expression which determines whether the href is
allowed or not. For instance, `shrub-angular` provides two patterns by default:

`'(?:https?|ftp|mailto|tel|file):'`

which allows the usage of http, https, ftp mailto, tel, and file
protocols, and

`'javascript:void(?:%20)*\\((?:%20)*0(?:%20)*\\)'`

which allows the usage of `javascript:void(0)` as an href.

Shrub combines all patterns into a regular expression and automatically
enforces that the pattern will occur at the beginning of the string. For
example, if we have two patterns, like:

`['foo', 'bar']`

the resulting regular expression will be equivalent to:

`/^\s*(?:foo|bar)/`

This hook should be used sparingly, as the reason there is a whitelist in the
first place is because there are security implications to allowing just any
href in a dynamic directive. **Use caution**.

### Answer with

An array of strings to be compiled into a regular expression.
