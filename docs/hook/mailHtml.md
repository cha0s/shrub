*Compose outgoing email.*

This hook is implemented by skins. Only the active skin's implementation is
called for any email.

Implementations accept the following parameters:

* (cheerio element) `$body` - The body tag of the rendered app HTML, wrapped
  with [cheerio](https://github.com/cheeriojs/cheerio), a lightweight
  server-side implementation of a lot of jQuery's functionality.
* (String) `html` - The mail HTML, generated from the directive.
* (cheerio) `$` - The cheerio instance.

It is the skin's responsibility to inject the email HTML from the second
parameter to where it belongs in the app HTML. The skin should also remove any
trace of dynamic JavaScript-driven functionality as that will surely break
in email where such things are not allowed.
