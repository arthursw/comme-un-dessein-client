
# window.XMLHttpRequest = window.RXMLHttpRequest

libs = '../../libs/'
console.log('libs', libs)

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
	waitSeconds: 300
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
		# 'facebook': ['//connect.facebook.net/en_US/sdk']
		# 'twitter': ['//platform.twitter.com/widgets']

		# 'domReady': [libs + 'domReady']
		'i18next': [libs + 'i18next.min']
		'potrace': [libs + 'potrace']
		# 'tui-image-editor': [libs + 'tui-image-editor.min']
		# 'imagetracer': [libs + 'imagetracer_v1.2.5']
		'i18nextXHRBackendID': [libs + 'i18nextXHRBackend']
		'i18nextBrowserLanguageDetectorID': [libs + 'i18nextBrowserLanguageDetector']
		'moment': [libs + 'moment.min']
		'jqueryI18next': [libs + 'jquery-i18next.min']
		'hammerjs': [libs + 'hammer.min']
		'jquery-hammer': [libs + 'jquery.hammer']
		# 'ace': [libs + 'ace']
		# 'aceTools': [libs + 'ace/ext-language_tools']
		'underscore': [libs + 'underscore-min']
		'jquery': [libs + 'jquery-2.1.3.min']
		'jqueryUi': [libs + 'jquery-ui.min']
		'mousewheel': [libs + 'jquery.mousewheel.min']
		# 'scrollbar': [libs + 'jquery.mCustomScrollbar.min']
		'tinycolor2': [ libs + 'tinycolor']
		# 'socketio': '//cdn.socket.io/socket.io-1.3.4'
		# 'socketio': '//cdnjs.cloudflare.com/ajax/libs/socket.io/1.3.5/socket.io'
		# 'prefix': ['//cdnjs.cloudflare.com/ajax/libs/prefixfree/1.0.7/prefixfree.min']
		'bootstrap': [libs + 'bootstrap.min']
		# 'modal': ['//cdnjs.cloudflare.com/ajax/libs/bootstrap-modal/2.2.5/js/bootstrap-modal.min', libs + 'bootstrap-modal.min']
		# 'modalManager': ['//cdnjs.cloudflare.com/ajax/libs/bootstrap-modal/2.2.5/js/bootstrap-modalmanager.min', libs + 'bootstrap-modalmanager.min']
		# 'paper': ['//cdnjs.cloudflare.com/ajax/libs/paper.js/0.9.22/paper-full.min', libs + 'paper-full.min']
		'paper': [libs + 'paper-full']
		# 'raphael': [libs + 'raphael.min']
		# 'three': [libs + 'three']
		'gui': [libs + 'dat.gui']
		# 'typeahead': [libs + 'typeahead.bundle.min']
		# 'pinit': [libs + 'pinit']
		# 'howler': [libs + 'howler']
		# 'spin': [libs + 'spin.min']

		'zeroClipboard': [libs + 'ZeroClipboard.min']

		# 'diffMatch': libs + 'AceDiff/diff_match_patch'
		# 'aceDiff': libs + 'AceDiff/ace-diff'
		# 'colorpickersliders': libs + 'bootstrap-colorpickersliders/bootstrap.colorpickersliders.nocielch'
		# 'requestAnimationFrame': libs + 'RequestAnimationFrame'
		# 'coffeescript-compiler': libs + 'coffee-script'
		# 'tween': libs + 'tween.min'
		'socket.ioID': libs + 'socket.io'
		# 'oembed': libs + 'jquery.oembed'
		# 'jqtree': libs + 'jqtree/tree.jquery'
		'js-cookie': libs + 'js.cookie'
		# 'octokat': libs + 'octokat'
		# 'spacebrew': libs + 'sb-1.4.1.min'
		# 'jszip': libs + 'jszip/jszip'
		'fileSaver': libs + 'FileSaver.min'
		# 'color-classifier': libs + 'color-classifier'
		'cropper': libs + 'cropper/cropper.min'
		'three': libs + 'three/build/three.min'
		'EffectComposer': libs + 'three/examples/js/postprocessing/EffectComposer'
		'CopyShader': libs + 'three/examples/js/shaders/CopyShader'
		'RenderPass': libs + 'three/examples/js/postprocessing/RenderPass'
		'ShaderPass': libs + 'three/examples/js/postprocessing/ShaderPass'
		'grayscaleShader': libs + 'three/shaders/grayscale'
		'paletteShader': libs + 'three/shaders/palette'
		'separateColorsShader': libs + 'three/shaders/separateColors'
		'stripesShader': libs + 'three/shaders/stripes'
		'erodeShader': libs + 'three/shaders/erode'
		'adaptiveThresholdShader': libs + 'three/shaders/adaptiveThreshold'
		'vertexShader': libs + 'three/shaders/vertex'

	shim:
		'mousewheel': ['jquery']
		# 'scrollbar': ['jquery']
		'jqueryUi': ['jquery']
		'bootstrap': ['jquery']
		'js-cookie': ['jquery']
		'i18nextXHRBackendID': ['i18next']
		'i18nextBrowserLanguageDetectorID': ['i18next']
		'jqueryI18next': ['i18next']
		'underscore':
			exports: '_'
		'jquery':
			exports: '$'
		'three':
			exports: 'THREE'
		'EffectComposer': ['three', 'CopyShader']
		'RenderPass': ['three', 'EffectComposer']
		'ShaderPass': ['three', 'EffectComposer']
		
# Load the main app module to start the app
requirejs [ 'R', 'jquery', 'underscore' ], (R) ->

	R.defaultColors = []
	R.city = {}
	canvasJ = $('#canvas')
	R.city.strokeWidth = canvasJ.attr('data-city-stroke-width')
	if _.isString(R.city.strokeWidth)
		R.city.strokeWidth = parseFloat(R.city.strokeWidth.replace(',', '.'))
	else
		R.city.strokeWidth = null

	R.city.width = canvasJ.attr('data-city-width')
	if _.isString(R.city.width)
		R.city.width = parseFloat(R.city.width.replace(',', '.'))
	else
		R.city.width = null
	
	R.city.height = canvasJ.attr('data-city-height')
	if _.isString(R.city.height)
		R.city.height = parseFloat(R.city.height.replace(',', '.'))
	else
		R.city.height = null

	R.city.tileWidth = canvasJ.attr('data-city-tile-width')
	if _.isString(R.city.tileWidth)
		R.city.tileWidth = parseFloat(R.city.tileWidth.replace(',', '.'))
	else
		R.city.tileWidth = null
	
	R.city.tileHeight = canvasJ.attr('data-city-tile-height')
	if _.isString(R.city.tileHeight)
		R.city.tileHeight = parseFloat(R.city.tileHeight.replace(',', '.'))
	else
		R.city.tileHeight = null

	R.city.nTilesMax = canvasJ.attr('data-city-n-tiles-max')
	if _.isString(R.city.nTilesMax)
		R.city.nTilesMax = parseInt(R.city.nTilesMax)
	else
		R.city.nTilesMax = null

	R.city.pixelPerMm = canvasJ.attr('data-city-pixel-per-mm')
	if _.isString(R.city.pixelPerMm)
		R.city.pixelPerMm = parseFloat(R.city.pixelPerMm.replace(',', '.'))
		if isNaN(R.city.pixelPerMm)
			console.error('City pixelPerMm is Nan', R.city.pixelPerMm, canvasJ.attr('data-city-pixel-per-mm'))
	else
		R.city.pixelPerMm = null

	R.polygonMode = false					# whether to draw in polygon mode or not (in polygon mode: each time the user clicks a point
											# will be created, in default mode: each time the user moves the mouse a point will be created)
	R.selectionBlue = '#2fa1d6'

	R.parameters = {}
	R.parameters['General'] = {}
	R.parameters['General'].location =
		type: 'string'
		label: 'Location'
		default: '0.0, 0.0'
		permanent: true

	R.parameters.default = {}
	R.parameters.strokeWidth =
		type: 'slider'
		label: 'Stroke width'
		min: 1
		max: 100
		default: 5
	R.parameters.strokeColor =
		type: 'color'
		label: 'Stroke color'
	R.parameters.fillColor =
		type: 'color'
		label: 'Fill color'
	R.strokeColor = 'black'
	R.fillColor = "rgb(255,255,255,255)"
	R.displayGrid = false

	R.repository = repository
	R.tipibot = parameters['tipibot']
	R.style = parameters['style'] or 'line'
	R.initialZoom = parameters['zoom']
	R.getParameters = getParameters
	R.administrator = parameters['administrator']
	requirejs [ 'Main' ]
	return
