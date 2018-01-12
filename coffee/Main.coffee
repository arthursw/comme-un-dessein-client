define [
	'R'
	'Utils/Utils'
	'Loader'
	'Socket'
	'City'
	'Rasterizers/RasterizerManager'
	'UI/Sidebar'
	'UI/Toolbar'
	'UI/DrawingPanel'
	'UI/Modal'
	'UI/Button'
	'UI/AlertManager'
	# 'UI/Controllers/ControllerManager'
	'Commands/CommandManager'
	'View/View'
	'View/Timelapse'
	'Tools/ToolManager'
	'RasterizerBot'
	'i18next'
	'i18nextXHRBackendID'
	'i18nextBrowserLanguageDetectorID'
	'jqueryI18next'
	'moment'
], (R, Utils, Loader, Socket, CityManager, RasterizerManager, Sidebar, Toolbar, DrawingPanel, Modal, Button, AlertManager, CommandManager, View, Timelapse, ToolManager, RasterizerBot, i18next, i18nextXHRBackend, i18nextBrowserLanguageDetector, jqueryI18next, moment) ->

	showEndModal = (message)->

		# endTextJ = $('#end-text')
		

		modal = Modal.createModal( 
			title: 'Comme un Dessein is over', 
			submit: ( ()=> 
				R.timelapse.activate()
				return),
			submitButtonText: 'Watch timelapse', 
			submitButtonIcon: 'glyphicon-film',
			cancelButtonText: 'Just visit', 
			cancelButtonIcon: 'glyphicon-sunglasses',
			postSubmit: 'hide')

		modal.addCustomContent(divJ: $(message), name: 'end-text')
		# modal.modalJ.find('[name="cancel"]').hide()
		modal.show()
		return

	# loadCity = (cityName)->
	# 	R.city.name = cityName

	# 	R.loader.showLoadingBar()
	# 	R.tools.select.btn.cloneJ.show()
	# 	$('[data-name="Precise path"]').show()
	# 	$('#timeline').show()
	# 	$('#drawingPanel').show()
	# 	R.view.loadCity(cityName)

	# 	require(['Items/Paths/PrecisePaths/PrecisePath'], ()-> R.loader.loadSVG() )

	# 	return

	# loadCitySVGs = ()->
	# 	cities = ['Maintenant', 'EcosystemeUrbain']
	# 	layer = document.getElementById('html-view')
	# 	for city in cities
	# 		doc = $('<img href="http://localhost:8000/static/images/' + city + '.png" x="0" y="0" width="1024px" height="768px"/>')
	# 		svgElement = layer.appendChild(doc.get(0))
		
	# 		svgElement.addEventListener("click",  ((event) => 
	# 			loadCity(city)
	# 			event.stopPropagation()
	# 			return -1
	# 		))
	# 	return

	# Initialize CommeUnDessein and handlers
	$(document).ready () ->
		
		canvasJ = $('#canvas')

		R.administrator = canvasJ.attr('data-is-admin') == 'True'
		
		R.city = 
			owner: null
			# name: 'EcosystemeUrbain'
			site: null
			finished: false

		cityName = canvasJ.attr('data-city')
		cityFinished = canvasJ.attr('data-city-finished')
		cityMessage = canvasJ.attr('data-city-message')

		if cityName.length > 0
			R.city.name = cityName

		R.city.finished = cityFinished == 'True'
			
		if R.city.finished
			showEndModal(cityMessage)

		# chooseRandomMode = false

		# if window.location.pathname == '/' || window.location.pathname == '/debug'
		# 	chooseRandomMode = true
		# 	welcomeTextJ = $('#beta-text')
		# 	modal = Modal.createModal( 
		# 		id: 'choose-mode',
		# 		title: 'Welcome to Comme Un Dessein', 
		# 		submit: ( ()=> 
		# 			modes = ['line', 'line-ortho-diag', 'pen', 'ortho-diag']
		# 			return window.location.pathname = modes[Math.floor(Math.random()*modes.length)] ),
		# 		submitButtonText: 'Choose random mode', 
		# 		submitButtonIcon: 'glyphicon-random',
		# 		cancelButtonText: 'Just visit', 
		# 		cancelButtonIcon: 'glyphicon-sunglasses',
		# 		)

		# 	modal.addCustomContent(divJ: welcomeTextJ.clone(), name: 'beta-text')
		# 	modal.modalJ.find('[name="cancel"]').removeClass('btn-default').addClass('btn-warning')

		# 	# modal.modalJ.find('[name="cancel"]').hide()
		# 	modal.show()

		# mode = canvasJ.attr('data-drawing-mode')

		# if mode == 'None'
		# 	mode = canvasJ.attr('data-city')

		# if mode == 'pen'
		# 	mode = 'CommeUnDessein'

		# if mode == 'None' or mode == '' and chooseRandomMode
		# 	modes = ['line', 'lineOrthoDiag', 'CommeUnDessein', 'orthoDiag']
		# 	mode = modes[Math.floor(Math.random()*modes.length)]

		# console.log(mode)

		# if mode != 'None'
		# 	R.city =
		# 			owner: null
		# 			name: mode
		# 			site: null
		# 	R.drawingMode = if mode in ['pixel', 'ortho', 'orthoDiag', 'image', 'line', 'lineOrthoDiag', 'dot', 'cross'] then mode else null

		# just set some content and react to language changes
		updateContent = ()->
			$("body").localize()
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
		
		username = canvasJ.attr("data-username")
		R.me = if username.length > 0 then username else null
		userAuthenticated = canvasJ.attr("data-is-authenticated")
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
		R.drawings = []
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
		R.toolbar = new Toolbar()
		
		if R.CommeUnDesseinIsNotOver
			userWhoClosedLastTime = localStorage.getItem('showWelcomMessage')
			
			if (not R.me) or userWhoClosedLastTime != R.me
				setTimeout (()=>
					R.alertManager.alert 'Welcome to Comme un Dessein', 'info'
					return), 1000

				setTimeout (()=>
					if R.ignoreNextAlert 
						R.ignoreNextAlert = null
						return
					R.alertManager.alert 'You can discuss about drawings', 'info', null, {html: 'Venez discuter sur <a style="color: #2196f3;text-decoration: underline;" href="http://discussion.commeundessein.co/">http://discussion.commeundessein.co/</a> pour que l\'on crée ensemble une oeuvre collective !'}
					return), 4000

		# if document?		
		# 	# R.controllerManager = new ControllerManager()
		# 	# R.controllerManager.createGlobalControllers()
		
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

		R.toolManager.createDeleteButton()
		R.toolManager.createSubmitButton()
		
		if R.city.name == 'world'
			R.loader.hideLoadingBar()
			R.tools.select.btn.cloneJ.hide()
			$('[data-name="Precise path"]').hide()
			$('#timeline').hide()
			$('#drawingPanel').hide()

		# R.tools['Precise Path'].btn.cloneJ.hide()

		if R.city.finished
			R.timelapse = new Timelapse()
		else
			$('#timeline').hide()
		
		# if not R.userAuthenticated
			
		# 	# voteMinDuration = $('#canvas').attr("data-voteMinDuration")
		# 	# negativeVoteThreshold = $('#canvas').attr("data-negativeVoteThreshold")
		# 	# positiveVoteThreshold = $('#canvas').attr("data-positiveVoteThreshold")

		# 	welcomeTextJ = $('#welcome-text')

		# 	modal = Modal.createModal( 
		# 		title: 'Welcome to Comme Un Dessein', 
		# 		submit: ( ()-> return location.pathname = '/accounts/signup/' ), 
		# 		postSubmit: 'load', 
		# 		submitButtonText: 'Sign up', 
		# 		submitButtonIcon: 'glyphicon-user', 
		# 		cancelButtonText: 'Just visit', 
		# 		cancelButtonIcon: 'glyphicon-sunglasses' )
		# 	# modal.addText('''
		# 	# 	Comme un dessein is a participative piece created by the french collective IDLV (Indiens dans la Ville). 
		# 	# 	With the help of a simple web interface and a monumental plotter, everyone can submit a drawing which takes part of a larger pictural composition, thus compose a collective utopian artwork.
		# 	# ''', 'welcome message 1', false)
		# 	# modal.addText('', 'welcome message 2', false)
		# 	# modal.addText('', 'welcome message 3', false)
		# 	modal.addCustomContent(divJ: welcomeTextJ, name: 'welcome-text')
		# 	modal.modalJ.find('[name="cancel"]').removeClass('btn-default').addClass('btn-warning')
		# 	# modal.addButton( type: 'info', name: 'Sign in', submit: (()-> return location.pathname = '/accounts/login/'), icon: 'glyphicon-log-in' )
		# 	modal.addButton( type: 'info', name: 'Sign in', icon: 'glyphicon-log-in' )

		# 	modal.modalJ.find('[name="Sign in"]').attr('data-toggle', 'dropdown').after($('#user-profile').find('.dropdown-menu').clone())
		# 	modal.modalJ.find('.dropdown-menu').find('li.sign-up').hide()

		# 	modal.show()
		
		R.commandManager.updateButtons()

		window?.setPageFullyLoaded?(true)
		
		# R.raph = Raphael($('#stage')[0], 4000, 3000)
		# rect = R.raph.rect(-2000, -1500, 4000, 3000)
		# rect.attr("fill", "#f00")

		if not R.initialZoom?
			R.view.fitRectangle(R.view.grid.limitCD.bounds.expand(0), true)

		if R.city.name != 'world'
			require(['Items/Paths/PrecisePaths/PrecisePath'], ()-> R.loader.loadSVG() )

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

		if R.city.name == 'world'
			loadCitySVGs()

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
