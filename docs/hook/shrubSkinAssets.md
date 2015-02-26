*Allow skins to define extra assets that they include on the page.*

By default, a skin includes an `app` directory containing assets which are
copied to the application's `app` directory. These assets are automatically
included on each page depending on the execution environment. By default,
production includes all stylesheets matching `*.min.css` and scripts matching
`*.min.js`. All other modes include stylesheets matching the pattern `*.css`
(excluding `*.min.css`) and scripts matching `*.js` (excluding `*.min.js`).

This is not always enough, since your skin may do its own building, e.g.
compiling LESS/Sass to CSS, and those resources need to be added to the page
as well. This hook lets you do so.
