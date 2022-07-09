# CommeUnDessein-client-code

The client code of CommeUnDessein - a collaborative application experiment

Compile: 

`coffee --watch --compile -o js/ coffee/`

WARNING: Does not compile with coffeescript v2 ; to re-install coffeescript v1 `npm uninstall coffeescript` and `npm install coffeescript@1.12`

Build:

Install requirejs if necessary: `npm install -g requirejs`

`cd js/`
`r.js -o build.js`

Libs must be defined in build.js

See https://requirejs.org/docs/optimization.html for more info