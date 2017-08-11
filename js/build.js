({
    baseUrl: ".",	    
    paths: {
      'requirejs': '../../comme-un-dessein-server/CommeUnDessein/static/libs/require.min',
      'domReady': '../../comme-un-dessein-server/CommeUnDessein/static/libs/domReady',
      'i18next': '../../comme-un-dessein-server/CommeUnDessein/static/libs/i18next.min',
      'i18nextXHRBackend': '../../comme-un-dessein-server/CommeUnDessein/static/libs/i18nextXHRBackend',
      'i18nextBrowserLanguageDetector': '../../comme-un-dessein-server/CommeUnDessein/static/libs/i18nextBrowserLanguageDetector',
      'jqueryI18next': '../../comme-un-dessein-server/CommeUnDessein/static/libs/jquery-i18next.min',
      'hammer': '../../comme-un-dessein-server/CommeUnDessein/static/libs/hammer.min',
      'aceTools': '../../comme-un-dessein-server/CommeUnDessein/static/libs/ace/ext-language_tools',
      'underscore': '../../comme-un-dessein-server/CommeUnDessein/static/libs/underscore-min',
      'jquery': '../../comme-un-dessein-server/CommeUnDessein/static/libs/jquery-2.1.3.min',
      'jqueryUi': '../../comme-un-dessein-server/CommeUnDessein/static/libs/jquery-ui.min',
      'mousewheel': '../../comme-un-dessein-server/CommeUnDessein/static/libs/jquery.mousewheel.min',
      'scrollbar': '../../comme-un-dessein-server/CommeUnDessein/static/libs/jquery.mCustomScrollbar.min',
      'tinycolor2': '../../comme-un-dessein-server/CommeUnDessein/static/libs/tinycolor',
      'bootstrap': '../../comme-un-dessein-server/CommeUnDessein/static/libs/bootstrap.min',
      'paper': '../../comme-un-dessein-server/CommeUnDessein/static/libs/paper-full',
      'three': '../../comme-un-dessein-server/CommeUnDessein/static/libs/three',
      'gui': '../../comme-un-dessein-server/CommeUnDessein/static/libs/dat.gui',
      'typeahead': '../../comme-un-dessein-server/CommeUnDessein/static/libs/typeahead.bundle.min',
      'pinit': '../../comme-un-dessein-server/CommeUnDessein/static/libs/pinit',
      'howler': '../../comme-un-dessein-server/CommeUnDessein/static/libs/howler',
      'zeroClipboard': '../../comme-un-dessein-server/CommeUnDessein/static/libs/ZeroClipboard.min',
      'diffMatch': '../../comme-un-dessein-server/CommeUnDessein/static/libs/AceDiff/diff_match_patch',
      'aceDiff': '../../comme-un-dessein-server/CommeUnDessein/static/libs/AceDiff/ace-diff',
      'colorpickersliders': '../../comme-un-dessein-server/CommeUnDessein/static/libs/bootstrap-colorpickersliders/bootstrap.colorpickersliders.nocielch',
      'requestAnimationFrame': '../../comme-un-dessein-server/CommeUnDessein/static/libs/RequestAnimationFrame',
      'coffeescript-compiler': '../../comme-un-dessein-server/CommeUnDessein/static/libs/coffee-script',
      'tween': '../../comme-un-dessein-server/CommeUnDessein/static/libs/tween.min',
      'socket.io': '../../comme-un-dessein-server/CommeUnDessein/static/libs/socket.io',
      'oembed': '../../comme-un-dessein-server/CommeUnDessein/static/libs/jquery.oembed',
      'jqtree': '../../comme-un-dessein-server/CommeUnDessein/static/libs/jqtree/tree.jquery',
      'js-cookie': '../../comme-un-dessein-server/CommeUnDessein/static/libs/js.cookie',
      'octokat': '../../comme-un-dessein-server/CommeUnDessein/static/libs/octokat',
      'spacebrew': '../../comme-un-dessein-server/CommeUnDessein/static/libs/sb-1.4.1.min',
      'jszip': '../../comme-un-dessein-server/CommeUnDessein/static/libs/jszip/jszip',
      'fileSaver': '../../comme-un-dessein-server/CommeUnDessein/static/libs/FileSaver.min',
      'color-classifier': '../../comme-un-dessein-server/CommeUnDessein/static/libs/color-classifier'
    },
    shim: {
      'oembed': ['jquery'],
      'mousewheel': ['jquery'],
      'scrollbar': ['jquery'],
      'jqueryUi': ['jquery'],
      'bootstrap': ['jquery'],
      'typeahead': ['jquery'],
      'js-cookie': ['jquery'],
      'jqtree': ['jquery'],
      'aceDiff': ['jquery', 'diffMatch', 'ace/ace'],
      'i18nextXHRBackend': ['i18next'],
      'i18nextBrowserLanguageDetector': ['i18next'],
      'jqueryI18next': ['i18next'],
      'colorpickersliders': {
        deps: ['jquery', 'tinycolor2']
      },
      'underscore': {
        exports: '_'
      },
      'jquery': {
        exports: '$'
      }
    },
    include: ["requirejs", "js-cookie", "Main"],
    name: "App",
    out: "App-built.js"
})