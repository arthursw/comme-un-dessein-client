let libs = '../../comme-un-dessein-server/CommeUnDessein/static/libs/';

({
    baseUrl: ".",	    
    paths: {
      'requirejs': libs+'require.min',
      'domReady': [libs + 'domReady'],
      'i18next': [libs + 'i18next.min'],
      'i18nextXHRBackend': [libs + 'i18nextXHRBackend'],
      'i18nextBrowserLanguageDetector': [libs + 'i18nextBrowserLanguageDetector'],
      'jqueryI18next': [libs + 'jquery-i18next.min'],
      'hammer': [libs + 'hammer.min'],
      'aceTools': [libs + 'ace/ext-language_tools'],
      'underscore': [libs + 'underscore-min'],
      'jquery': [libs + 'jquery-2.1.3.min'],
      'jqueryUi': [libs + 'jquery-ui.min'],
      'mousewheel': [libs + 'jquery.mousewheel.min'],
      'scrollbar': [libs + 'jquery.mCustomScrollbar.min'],
      'tinycolor2': [libs + 'tinycolor'],
      'bootstrap': [libs + 'bootstrap.min'],
      'paper': [libs + 'paper-full'],
      'three': [libs + 'three'],
      'gui': [libs + 'dat.gui'],
      'typeahead': [libs + 'typeahead.bundle.min'],
      'pinit': [libs + 'pinit'],
      'howler': [libs + 'howler'],
      'zeroClipboard': [libs + 'ZeroClipboard.min'],
      'diffMatch': libs + 'AceDiff/diff_match_patch',
      'aceDiff': libs + 'AceDiff/ace-diff',
      'colorpickersliders': libs + 'bootstrap-colorpickersliders/bootstrap.colorpickersliders.nocielch',
      'requestAnimationFrame': libs + 'RequestAnimationFrame',
      'coffeescript-compiler': libs + 'coffee-script',
      'tween': libs + 'tween.min',
      'socket.io': libs + 'socket.io',
      'oembed': libs + 'jquery.oembed',
      'jqtree': libs + 'jqtree/tree.jquery',
      'js-cookie': libs + 'js.cookie',
      'octokat': libs + 'octokat',
      'spacebrew': libs + 'sb-1.4.1.min',
      'jszip': libs + 'jszip/jszip',
      'fileSaver': libs + 'FileSaver.min',
      'color-classifier': libs + 'color-classifier'
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
    include: "requirejs",
    name: "App",
    out: "App-built.js"
})