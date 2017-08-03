
# window.XMLHttpRequest = window.RXMLHttpRequest

libs = '../../libs/'

getParameters = (hash)->
	# queryString = queryString.split('+').join(' ')
	hash = hash.replace('#', '')
	parameters = {}
	re = /[?&]?([^=]+)=([^&]*)/g
	while tokens = re.exec(hash)
		key = decodeURIComponent(tokens[1])
		value = decodeURIComponent(tokens[2])
		parameters[key] = if value == 'true' then true else if value == 'false' then false else value
	return parameters

parameters = if document? then getParameters(document.location.hash) else null

repository = owner: 'arthursw', commit: null

if parameters? and parameters['repository-owner']? and parameters['repository-commit']?
	prefix = if parameters['repository-use-cdn']? then '//cdn.' else '//'
	baseUrl = prefix + 'rawgit.com/' + parameters['repository-owner'] + '/comme-un-dessein-client/' + parameters['repository-commit'] + '/js'
	repository = owner: parameters['repository-owner'], commit: parameters['repository-commit']
	libs = location.origin + '/static/libs/'
else
	baseUrl = '../static/comme-un-dessein-client/js'

# Place third party dependencies in the lib folder
#
# Configure loading modules from the lib directory,
# except 'app' ones,
requirejs.config
	baseUrl: baseUrl

	# enforceDefine: true 	# to make fallback work?? but throws Uncaught Error: No define call for app
	paths:
		# 'domReady': ['//cdnjs.cloudflare.com/ajax/libs/require-domReady/2.0.1/domReady.min', libs + 'domReady']
		# 'ace': ['//cdnjs.cloudflare.com/ajax/libs/ace/1.1.9/', libs + 'ace/src-min-noconflict/']
		# # 'ace': [libs + 'ace/src-min-noconflict/']
		# 'underscore': ['//cdnjs.cloudflare.com/ajax/libs/underscore.js/1.8.3/underscore-min', libs + 'underscore-min']
		# 'jquery': ['//code.jquery.com/jquery-2.1.3.min', 'libs/jquery-2.1.3.min']
		# 'jqueryUi': ['//code.jquery.com/ui/1.11.4/jquery-ui.min', libs + 'jquery-ui.min']
		# 'mousewheel': ['//cdnjs.cloudflare.com/ajax/libs/jquery-mousewheel/3.1.12/jquery.mousewheel.min', libs + 'jquery.mousewheel.min']
		# 'scrollbar': ['//cdnjs.cloudflare.com/ajax/libs/malihu-custom-scrollbar-plugin/3.0.8/jquery.mCustomScrollbar.min', libs + 'jquery.mCustomScrollbar.min']
		# 'tinycolor': ['//cdnjs.cloudflare.com/ajax/libs/tinycolor/1.1.2/tinycolor.min', libs + 'tinycolor.min']
		#
		# # 'socketio': '//cdn.socket.io/socket.io-1.3.4'
		# # 'socketio': '//cdnjs.cloudflare.com/ajax/libs/socket.io/1.3.5/socket.io'
		# 'prefix': ['//cdnjs.cloudflare.com/ajax/libs/prefixfree/1.0.7/prefixfree.min']
		# 'bootstrap': ['//maxcdn.bootstrapcdn.com/bootstrap/3.3.4/js/bootstrap.min', libs + 'bootstrap.min']
		# # 'modal': ['//cdnjs.cloudflare.com/ajax/libs/bootstrap-modal/2.2.5/js/bootstrap-modal.min', 'libs/bootstrap-modal.min']
		# # 'modalManager': ['//cdnjs.cloudflare.com/ajax/libs/bootstrap-modal/2.2.5/js/bootstrap-modalmanager.min', 'libs/bootstrap-modalmanager.min']
		# # 'paper': ['//cdnjs.cloudflare.com/ajax/libs/paper.js/0.9.22/paper-full.min', 'libs/paper-full.min']
		# 'paper': ['//cdnjs.cloudflare.com/ajax/libs/paper.js/0.9.22/paper-full', libs + 'paper-full']
		# 'gui': ['//cdnjs.cloudflare.com/ajax/libs/dat-gui/0.5/dat.gui', libs + 'dat.gui.min']
		# 'typeahead': ['//cdnjs.cloudflare.com/ajax/libs/typeahead.js/0.10.4/typeahead.bundle.min', libs + 'typeahead.bundle.min']
		# 'howler': ['//cdnjs.cloudflare.com/ajax/libs/howler/1.1.26/howler.min', libs + 'howler']
		# 'spin': ['//cdnjs.cloudflare.com/ajax/libs/spin.js/2.0.1/spin.min', libs + 'spin.min']
		# 'pinit': ['//assets.pinterest.com/js/pinit', libs + 'pinit']
		# 'table': ['//cdnjs.cloudflare.com/ajax/libs/bootstrap-table/1.8.1/bootstrap-table.min', libs + 'table/bootstrap-table.min']
		# 'zeroClipboard': ['//cdnjs.cloudflare.com/ajax/libs/zeroclipboard/2.2.0/ZeroClipboard.min', libs + 'ZeroClipboard.min']


		'domReady': [libs + 'domReady']
		'hammer': [libs + 'hammer.min']
		# 'ace': [libs + 'ace']
		'aceTools': [libs + 'ace/ext-language_tools']
		'underscore': [libs + 'underscore-min']
		'jquery': [libs + 'jquery-2.1.3.min']
		'jqueryUi': [libs + 'jquery-ui.min']
		'mousewheel': [libs + 'jquery.mousewheel.min']
		'scrollbar': [libs + 'jquery.mCustomScrollbar.min']
		'tinycolor2': [ libs + 'tinycolor']
		# 'socketio': '//cdn.socket.io/socket.io-1.3.4'
		# 'socketio': '//cdnjs.cloudflare.com/ajax/libs/socket.io/1.3.5/socket.io'
		# 'prefix': ['//cdnjs.cloudflare.com/ajax/libs/prefixfree/1.0.7/prefixfree.min']
		'bootstrap': [libs + 'bootstrap.min']
		# 'modal': ['//cdnjs.cloudflare.com/ajax/libs/bootstrap-modal/2.2.5/js/bootstrap-modal.min', libs + 'bootstrap-modal.min']
		# 'modalManager': ['//cdnjs.cloudflare.com/ajax/libs/bootstrap-modal/2.2.5/js/bootstrap-modalmanager.min', libs + 'bootstrap-modalmanager.min']
		# 'paper': ['//cdnjs.cloudflare.com/ajax/libs/paper.js/0.9.22/paper-full.min', libs + 'paper-full.min']
		'paper': [libs + 'paper-full']
		'three': [libs + 'three']
		'gui': [libs + 'dat.gui']
		'typeahead': [libs + 'typeahead.bundle.min']
		'pinit': [libs + 'pinit']
		'howler': [libs + 'howler']
		# 'spin': [libs + 'spin.min']

		'zeroClipboard': [libs + 'ZeroClipboard.min']

		'diffMatch': libs + 'AceDiff/diff_match_patch'
		'aceDiff': libs + 'AceDiff/ace-diff'
		'colorpickersliders': libs + 'bootstrap-colorpickersliders/bootstrap.colorpickersliders.nocielch'
		'requestAnimationFrame': libs + 'RequestAnimationFrame'
		'coffeescript-compiler': libs + 'coffee-script'
		'tween': libs + 'tween.min'
		'socket.io': libs + 'socket.io'
		'oembed': libs + 'jquery.oembed'
		'jqtree': libs + 'jqtree/tree.jquery'
		'js-cookie': libs + 'js.cookie'
		'octokat': libs + 'octokat'
		'spacebrew': libs + 'sb-1.4.1.min'
		'jszip': libs + 'jszip/jszip'
		'fileSaver': libs + 'FileSaver.min'
		'color-classifier': libs + 'color-classifier'

	shim:
		'oembed': ['jquery']
		'mousewheel': ['jquery']
		'scrollbar': ['jquery']
		'jqueryUi': ['jquery']
		'bootstrap': ['jquery']
		'typeahead': ['jquery']
		'js-cookie': ['jquery']
		'jqtree': ['jquery']
		'aceDiff': ['jquery', 'diffMatch', 'ace/ace']
		# 'modal': ['bootstrap', 'modalManager']
		'colorpickersliders':
			deps: ['jquery', 'tinycolor2']
		# 'ace': ['aceTools']
		'underscore':
			exports: '_'
		'jquery':
			exports: '$'

# Load the main app module to start the app
requirejs [ 'R' ], (R) ->
	R.repository = repository
	R.tipibot = parameters['tipibot']
	R.getParameters = getParameters
	requirejs [ 'Main' ]
	return
