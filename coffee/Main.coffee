define [
	'R'
	'Utils/Utils'
	'Loader'
	'Socket'
	'City'
	'Rasterizers/RasterizerManager'
	'UI/Sidebar'
	'UI/DrawingPanel'
	'UI/Modal'
	'UI/Button'
	'UI/AlertManager'
	'UI/Controllers/ControllerManager'
	'Commands/CommandManager'
	'View/View'
	'Tools/ToolManager'
	'RasterizerBot'
	'i18next'
	'i18nextXHRBackend'
	'i18nextBrowserLanguageDetector'
	'jqueryI18next'
	'moment'
], (R, Utils, Loader, Socket, CityManager, RasterizerManager, Sidebar, DrawingPanel, Modal, Button, AlertManager, ControllerManager, CommandManager, View, ToolManager, RasterizerBot, i18next, i18nextXHRBackend, i18nextBrowserLanguageDetector, jqueryI18next, moment) ->

	console.log 'Main CommeUnDessein Repository'

	# R.rasterizerMode = window.rasterizerMode



	# TODO: manage items and path in the same way (R.paths and R.items)? make an interface on top of path and div, and use events to update them
	# todo: add else case in switches
	# todo: bug when creating a small div (happened with text)
	# todo: snap div
	# todo: center modal vertically with an event system: http://codepen.io/dimbslmh/pen/mKfCc and http://stackoverflow.com/questions/18422223/bootstrap-3-modal-vertical-position-center

	# doctodo: look for "improve", "improvement", "deprecated", "to be updated" to see each time commeUnDessein must be updated

	###
	# CommeUnDessein documentation #

	CommeUnDessein is an experiment about freedom, creativity and collaboration.

	tododoc
	tododoc: define RItems

	The source code is divided in files:
	 - [main.coffee](http://main.html) which is where the initialization
	 - [path.coffee](http://path.html)
	 - etc

	Notations:
	 - override means that the method extends functionnalities of the inherited method (super is called at some point)
	 - redefine means that it totally replace the method (super is never called)

	###


	# initialize CommeUnDessein
	# all global variables and functions are stored in *g* which is a synonym of *window*
	# all jQuery elements names end with a capital J: elementNameJ
	# init = ()->
		# R.commeUnDesseinURL = 'http://romanesc.co/'




		# R.selectionCanvasJ = R.stageJ.find("#selection-canvas")
		# R.selectionCanvas = R.selectionCanvasJ[0]
		# R.selectionCanvas.width = window.innerWidth
		# R.selectionCanvas.height = window.innerHeight

		# R.backgroundCanvasJ = R.stageJ.find("#background-canvas")
		# R.backgroundCanvas = R.backgroundCanvasJ[0]
		# R.backgroundCanvas.width = window.innerWidth
		# R.backgroundCanvas.height = window.innerHeight
		# R.backgroundCanvasJ.width(window.innerWidth)
		# R.backgroundCanvasJ.height(window.innerHeight)
		# R.backgroundContext = R.backgroundCanvas.getContext('2d')

		# R.fastMode = false 						# fastMode will hide all items except the one being edited (when user edits an item)
		# R.fastModeOn = false					# fastModeOn is true when the user is edditing an item


		# R.draggingEditor = false 				# boolean, true when user is dragging the code editor
		# R.rasters = {}							# map to store rasters (tiles, rasterized version of the view)
		# R.areasToUpdate = {} 					# map of areas to update { pk->rectangle }
												# (areas which are not rasterize on the server, that we must send if we can rasterize them)
		# R.rastersToUpload = [] 					# an array of { data: dataURL, position: position } containing the rasters to upload on the server
		# R.areasToRasterize = [] 				# an array of P.Rectangle to rasterize
		# R.isUpdatingRasters = false 			# true if we are updating rasters (in loopUpdateRasters)
		# R.viewUpdated = false 					# true if the view was updated ( rasters removed and items drawn in R.updateView() )
												# and we don't need to update anymore (until new P.Rasters are added in load_callback)




												# used to get mouse position on a key event



		# R.globalMaskJ = $("#globalMask")
		# R.globalMaskJ.hide()



		# init paper.js
		# paper.setup(R.selectionCanvas)
		# R.selectionProject = project






		# R.sound = new R.RSound(['/static/sounds/space_ship_engine.mp3', '/static/sounds/space_ship_engine.ogg'])


		# R.sound = new Howl(
		# 	urls: ['/static/sounds/viper.ogg']
		# 	onload: ()->
		# 		console.log("sound loaded")
		# 		XMLHttpRequest = R.DajaxiceXMLHttpRequest
		# 		return
		# 	volume: 0.25
		# 	buffer: true
		# 	sprite:
		# 		loop: [2000, 3000, true]
		# )

		# R.sound.plays = (spriteName)->
		# 	return R.sound.spriteName == spriteName # and R.sound.pos()>0

		# R.sound.playAt = (spriteName, time)->
		# 	if time < 0 or time > 1.0 then return
		# 	sprite = R.sound.sprite()[spriteName]
		# 	begin = sprite[0]
		# 	duration = sprite[1]
		# 	looped = sprite[2]
		# 	R.sound.stop()
		# 	R.sound.spriteName = spriteName
		# 	R.sound.play(spriteName)
		# 	R.sound.pos(time*duration/1000)
		# 	callback = ()->
		# 		R.sound.stop()
		# 		if looped then R.sound.play(spriteName)
		# 		return
		# 	clearTimeout(R.sound.rTimeout)
		# 	R.sound.rTimeout = setTimeout(callback, duration-time*duration)
		# 	return false

		# R.sidebarJ.find("#buyCommeUnDesseinCoins").click ()->
		# 	R.templatesJ.find('#commeUnDesseininModal').modal('show')
		# 	paypalFormJ = R.templatesJ.find("#paypalForm")
		# 	paypalFormJ.find("input[name='submit']").click( ()->
		# 		data =
		# 			user: R.me
		# 			location: { x: P.view.center.x, y: P.view.center.y }
		# 		paypalFormJ.find("input[name='custom']").attr("value", JSON.stringify(data) )
		# 	)

		# load path source code

		# xmlhttp = new RXMLHttpRequest()
		# url = R.commeUnDesseinURL + "static/comme-un-dessein-client/coffee/Item/path.coffee"

		# xmlhttp.onreadystatechange = ()->
		# 	if xmlhttp.readyState == 4 and xmlhttp.status == 200
		# 		sources = xmlhttp.responseText

		# 		lines = sources.split(/\n/)
		# 		expressions = CoffeeScript.nodes(sources).expressions

		# 		classMap = {}
		# 		for pathClass in R.pathClasses
		# 			classMap[pathClass.name] = pathClass

		# 		classExpressions = expressions[0].args[1].body.expressions
		# 		for expression in classExpressions
		# 			className = expression.variable?.base?.value
		# 			if className? and classMap[className]? and expression.locationData?
		# 				start = expression.locationData.first_line
		# 				end = expression.locationData.last_line-1
		# 				# remove tab:
		# 				for i in [start .. end]
		# 					lines[i] = lines[i].substring(1)
		# 				source = lines[start .. end].join("\n")
		# 				# automatically create new PathTool
		# 				source += "\ntool = new R.PathTool(#{className}, true)"
		# 				pathClass = classMap[className]
		# 				pathClass.source = source
		# 				R.modules[pathClass.label]?.source = source
		# 	return

		# xmlhttp.open("GET", url, true)
		# xmlhttp.send()

		# not working, because of dajaxice
		# $.ajax( url: R.commeUnDesseinURL + "static/coffee/path.coffee", cache: false )
		# .done (data)->
		# 	console.log "done"
		# 	lines = data.split(/\n/)
		# 	expressions = CoffeeScript.nodes(data).expressions

		# 	classMap = {}
		# 	for pathClass in R.pathClasses
		# 		classMap[pathClass.name] = pathClass

		# 	for expression in expressions
		# 		source = lines[expression.locationData.first_line .. expression.locationData.last_line].join("\n")
		# 		classMap[expression.variable.base.value]?.source = source

		# 	return
		# .success (data)->
		# 	console.log "success"
		# 	return
		# .fail (data)->
		# 	console.log "fail"
		# 	return
		# .error (data)->
		# 	console.log "error"
		# 	return
		# .always (data)->
		# 	console.log "always"
		# 	return

		# R.initializeGlobalParameters()

		# if not R.rasterizerMode


		# else
		# 	R.initToolsRasterizer()

		# return

	# Initialize CommeUnDessein and handlers
	$(document).ready () ->

		# just set some content and react to language changes
		updateContent = ()->
			$("body").localize()
			console.log('i18n tests:')
			console.log(i18next.t('Simple'))
			console.log(i18next.t('You are logged as username', {username: 'username'}))
			console.log(i18next.t('key', { what: 'i18next', how: 'great' }))
			console.log(i18next.t('You successfully voted, the drawing will be rejected', {duration: ' 10 seconds'}))
			return

		i18next
			.use(i18nextXHRBackend)
			.use(i18nextBrowserLanguageDetector)
			.init({
				fallbackLng: 'en',
				debug: true,
				ns: ['special', 'common'],
				defaultNS: 'common',
				backend: {
					loadPath: 'static/locales/{{lng}}/{{ns}}.json',
					crossDomain: true
				}
			}, (err, t)->
				# init set content
				updateContent()
				return
			)

		i18next.on('languageChanged', () => updateContent())

		jqueryI18next.init(i18next, $, {
			tName: 't', 						# --> appends $.t = i18next.t
			i18nName: 'i18n', 					# --> appends $.i18n = i18next
			handleName: 'localize', 			# --> appends $(selector).localize(opts);
			selectorAttr: 'data-i18n', 			# selector for translating elements
			targetAttr: 'i18n-target', 			# data-() attribute to grab target element to translate (if diffrent then itself)
			optionsAttr: 'i18n-options', 		# data-() attribute that contains options, will load/set if useOptionsAttr = true
			useOptionsAttr: false, 				# see optionsAttr
			parseDefaultValueFromContent: true 	# parses default values from content ele.val or ele.text
		});

		i18next.changeLanguage('fr');

		ordinal = (number)->
			return number + (if number == 1 then 'er' else 'e')

		isPM = (input)->
			return input.charAt(0) == 'M'

		meridiem = (hours, minutes, isLower) ->
			return if hours < 12 then 'PD' else 'MD'

		moment.locale('fr', {
			months : 'janvier_février_mars_avril_mai_juin_juillet_août_septembre_octobre_novembre_décembre'.split('_'),
			monthsShort : 'janv._févr._mars_avr._mai_juin_juil._août_sept._oct._nov._déc.'.split('_'),
			monthsParseExact : true,
			weekdays : 'dimanche_lundi_mardi_mercredi_jeudi_vendredi_samedi'.split('_'),
			weekdaysShort : 'dim._lun._mar._mer._jeu._ven._sam.'.split('_'),
			weekdaysMin : 'Di_Lu_Ma_Me_Je_Ve_Sa'.split('_'),
			weekdaysParseExact : true,
			longDateFormat : {
				LT : 'HH:mm',
				LTS : 'HH:mm:ss',
				L : 'DD/MM/YYYY',
				LL : 'D MMMM YYYY',
				LLL : 'D MMMM YYYY HH:mm',
				LLLL : 'dddd D MMMM YYYY HH:mm'
			},
			calendar : {
				sameDay : '[Aujourd’hui à] LT',
				nextDay : '[Demain à] LT',
				nextWeek : 'dddd [à] LT',
				lastDay : '[Hier à] LT',
				lastWeek : 'dddd [dernier à] LT',
				sameElse : 'L'
			},
			relativeTime : {
				future : 'dans %s',
				past : 'il y a %s',
				s : 'quelques secondes',
				m : 'une minute',
				mm : '%d minutes',
				h : 'une heure',
				hh : '%d heures',
				d : 'un jour',
				dd : '%d jours',
				M : 'un mois',
				MM : '%d mois',
				y : 'un an',
				yy : '%d ans'
			},
			dayOfMonthOrdinalParse : /\d{1,2}(er|e)/,
			ordinal: ordinal,
			meridiemParse : /PD|MD/,
			isPM: isPM,
			# In case the meridiem units are not separated around 12, then implement
			# this function (look at locale/id.js for an example).
			# meridiemHour : function (hour, meridiem) {
			#	 return /* 0-23 hour, given meridiem token and hour 1-12 */ ;
			# },
			meridiem : meridiem,
			week : {
				dow : 1, # Monday is the first day of the week.
				doy : 4  # The week that contains Jan 4th is the first week of the year.
			}
		})

		moment.locale('fr')

		# R.me is the username (or ID if not authenticated) of the user (sent by the server in each ajax "load")
		username = $('#canvas').attr("data-username")
		R.me = if username.length > 0 then username else null
		userAuthenticated = $('#canvas').attr("data-is-authenticated")
		R.userAuthenticated = userAuthenticated == 'True'

		if R.style?
			$('body').addClass(R.style)

		# parameters
		R.catchErrors = false 					# the error will not be caught when drawing an RPath (let chrome catch them at the right time)
		R.ignoreSockets = false 				# whether sockets messages are ignored

		# global variables
		R.currentPaths = {} 					# map of username -> path id corresponding to the paths currently being created
		R.paths = new Object() 					# a map of RPath.id -> RPath. RPath are added with their id
												# (as soon as server saved it and responds)
		R.items = new Object() 					# map Item.id -> Item, all loaded RItems. The key is Item.id 
		R.locks = [] 							# array of loaded Locks
		R.divs = [] 							# array of loaded RDivs
		R.sortedPaths = []						# an array where paths are sorted by index (z-index)
		R.sortedDivs = []						# an array where divs are sorted by index (z-index)
		R.animatedItems = [] 					# an array of animated items to be updated each frame
		R.cars = {} 							# a map of username -> cars which will be updated each frame
		R.currentDiv = null 					# the div currently being edited (dragged, moved or resized) used to also send jQuery mouse event to divs
		R.selectedItems = [] 					# the selectedItems
		# R.areasToUpdateRectangles = {} 			# debug map: area to update pk -> rectangle path

		if location.pathname == '/rasterizer/'
			R.rasterizerBot = new RasterizerBot(@)
			R.loader = new Loader.RasterizerLoader()
		else
			R.loader = new Loader()

		R.socket = new Socket()
		R.sidebar = new Sidebar()
		R.cityManager = new CityManager()
		R.view = new View()
		R.alertManager = new AlertManager()
		
		if document?		
			R.controllerManager = new ControllerManager()
			R.controllerManager.createGlobalControllers()
		
		R.rasterizerManager = new RasterizerManager()
		R.rasterizerManager.initializeRasterizers()
		R.view.createBackground()
		
		R.commandManager = new CommandManager()
		R.toolManager = new ToolManager()
		# R.fileManager = new FileManager()
		# R.codeEditor = new CodeEditor()
		R.drawingPanel = new DrawingPanel()
		# R.fontManager = new FontManager()
		R.view.initializePosition()
		R.sidebar.initialize()


		# submitButton = new Button({
		# 	name: 'Submit drawing'
		# 	favorite: true
		# 	iconURL: 'icones_icon_ok.png'
		# 	order: 0
		# 	classes: 'btn-success displayName'
		# 	onClick: ()=>
		# 		R.drawingPanel.submitDrawingClicked()
		# 		return
		# 	})
		
		if not R.userAuthenticated
			
			# voteMinDuration = $('#canvas').attr("data-voteMinDuration")
			# negativeVoteThreshold = $('#canvas').attr("data-negativeVoteThreshold")
			# positiveVoteThreshold = $('#canvas').attr("data-positiveVoteThreshold")

			welcomeTextJ = $('#welcome-text')

			modal = Modal.createModal( 
				title: 'Welcome to Comme Un Dessein', 
				submit: ( ()-> return location.pathname = '/accounts/signup/' ), 
				postSubmit: 'load', 
				submitButtonText: 'Sign up', 
				submitButtonIcon: 'glyphicon-user', 
				cancelButtonText: 'Just visit', 
				cancelButtonIcon: 'glyphicon-sunglasses' )
			# modal.addText('''
			# 	Comme un dessein is a participative piece created by the french collective IDLV (Indiens dans la Ville). 
			# 	With the help of a simple web interface and a monumental plotter, everyone can submit a drawing which takes part of a larger pictural composition, thus compose a collective utopian artwork.
			# ''', 'welcome message 1', false)
			# modal.addText('', 'welcome message 2', false)
			# modal.addText('', 'welcome message 3', false)
			modal.addCustomContent(divJ: welcomeTextJ, name: 'welcome-text')
			modal.modalJ.find('[name="cancel"]').removeClass('btn-default').addClass('btn-warning')
			# modal.addButton( type: 'info', name: 'Sign in', submit: (()-> return location.pathname = '/accounts/login/'), icon: 'glyphicon-log-in' )
			modal.addButton( type: 'info', name: 'Sign in', icon: 'glyphicon-log-in' )

			modal.modalJ.find('[name="Sign in"]').attr('data-toggle', 'dropdown').after($('#user-profile').find('.dropdown-menu').clone())
			modal.modalJ.find('.dropdown-menu').find('li.sign-up').hide()

			modal.show()
		
		R.commandManager.updateButtons()

		window?.setPageFullyLoaded?(true)
		
		# R.raph = Raphael($('#stage')[0], 4000, 3000)
		# rect = R.raph.rect(-2000, -1500, 4000, 3000)
		# rect.attr("fill", "#f00")

		R.view.fitRectangle(R.view.grid.limitCD.bounds, true)

		require(['Items/Paths/PrecisePaths/PrecisePath'], ()-> R.loader.loadAll() )

		# Improve about links

		$('#about-link').click (event)->
			
			modal = Modal.createModal( 
				title: 'About Comme Un Dessein', 
				postSubmit: 'hide', 
				submitButtonText: 'Close', 
				submitButtonIcon: 'glyphicon-remove')
			divJ = $('<iframe>')
			divJ.attr('style', 'width: 100%; border: none;')
			divJ.attr('src', 'about.html')
			divJ.html(i18next.t('welcome message 1', { interpolation: { escapeValue: false } }))
			divJ.html(i18next.t('welcome message 2', { interpolation: { escapeValue: false } }))
			divJ.html(i18next.t('welcome message 3', { interpolation: { escapeValue: false } }))
			modal.addCustomContent(divJ: divJ, name: 'about-page')
			modal.modalJ.find('[name="cancel"]').hide()
			modal.show()

			event.preventDefault()
			event.stopPropagation()
			return -1


		# $('#terms-of-service-link').click (event)->
			
		# 	modal = Modal.createModal( 
		# 		title: 'Terms of Service', 
		# 		postSubmit: 'hide', 
		# 		submitButtonText: 'Close', 
		# 		submitButtonIcon: 'glyphicon-remove')
		# 	divJ = $('<iframe>')
		# 	divJ.attr('style', 'width: 100%; border: none;')
		# 	divJ.attr('src', 'terms-of-service.html')
		# 	modal.addCustomContent(divJ: divJ, name: 'terms-of-service-page')
		# 	modal.modalJ.find('[name="cancel"]').hide()
		# 	modal.show()

		# 	event.preventDefault()
		# 	event.stopPropagation()
		# 	return -1

		# $('#privacy-policy-link').click (event)->
			
		# 	modal = Modal.createModal( 
		# 		title: 'Privacy Policy', 
		# 		postSubmit: 'hide', 
		# 		submitButtonText: 'Close', 
		# 		submitButtonIcon: 'glyphicon-remove')
		# 	divJ = $('<iframe>')
		# 	divJ.attr('style', 'width: 100%; border: none;')
		# 	divJ.attr('src', 'privacy-policy.html')
		# 	modal.addCustomContent(divJ: divJ, name: 'privacy-policy-page')
		# 	modal.modalJ.find('[name="cancel"]').hide()
		# 	modal.show()

		# 	event.preventDefault()
		# 	event.stopPropagation()
		# 	return -1

		# svg = P.project.exportSVG()
		# $('#stage').append(svg)


		return


	R.debugDatabase = ()-> return $.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'debugDatabase', args: {} } )

	R.fsi = ()-> return R.selectedItems?[0]
	R.fi = ()-> 
		if not R.items? then return null
		for itemId of R.items
			return R.items[itemId]

	# R.showCodeEditor = (fileNode)->
	# 	if not R.codeEditor?
	# 		require ['UI/Editor'], (CodeEditor)->
	# 			R.codeEditor = new CodeEditor()
	# 			if fileNode then R.codeEditor.setFile(fileNode)
	# 			R.codeEditor.open()
	# 			return
	# 	else
	# 		if fileNode then R.codeEditor.setFile(fileNode)
	# 		R.codeEditor.open()
	# 	return

	return
