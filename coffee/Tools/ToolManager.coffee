dependencies = [
	'R'
	'Utils/Utils'
	'Tools/Tool'
	'UI/Button'
	'Tools/MoveTool'
	'Tools/SelectTool'
	'Tools/PathTool'
	'Tools/EraserTool'
	'Tools/ItemTool'
	'UI/Modal'
	'i18next'
	# 'Tools/TextTool'
	# 'Tools/GradientTool'
]

# if document?
	# dependencies.push('Tools/ScreenshotTool')
	# dependencies.push('Tools/CarTool')

define 'Tools/ToolManager', dependencies, (R, Utils, Tool, Button, MoveTool, SelectTool, PathTool, EraserTool, ItemTool, Modal, i18next) -> # , TextTool, GradientTool, CarTool) ->

	class ToolManager

		constructor: ()->

			# init jQuery elements related to the tools
			R.ToolsJ = $(".tool-list")

			R.favoriteToolsJ = $("#FavoriteTools .tool-list")
			R.allToolsContainerJ = $("#AllTools")
			R.allToolsJ = R.allToolsContainerJ.find(".all-tool-list")

			# init R.favoriteTools to see where to put the tools (in the 'favorite tools' panel or in 'other tools')
			R.favoriteTools = []
			if localStorage?
				try
					R.favoriteTools = JSON.parse(localStorage.favorites)
				catch error
					console.log error

			# R.tools.car = new R.Tools.Car()
			# R.tools.gradient = new R.Tools.Gradient()
			# R.tools.lock = new R.Tools.Lock()
			# R.tools.media = new R.Tools.Media()
			R.tools.move = new R.Tools.Move()
			# R.tools.screenshot = new R.Tools.Screenshot()
			R.tools.select = new R.Tools.Select()
			R.tools.eraser = new R.Tools.Eraser()
			R.tools.eraser.btn.hide()

			# R.tools.text = new R.Tools.Text()

			defaultFavoriteTools = [] # [R.PrecisePath, R.ThicknessPath, R.Meander, R.GeometricLines, R.RectangleShape, R.EllipseShape, R.StarShape, R.SpiralShape]

			while R.favoriteTools.length < 8 and defaultFavoriteTools.length > 0
				Utils.Array.pushIfAbsent(R.favoriteTools, defaultFavoriteTools.pop().label)

			# R.modules = {}
			# path tools
			# for pathClass in R.pathClasses
			# 	pathTool = new R.PathTool(pathClass)
				# R.modules[pathTool.name] = { name: pathTool.name, iconURL: pathTool.RPath.iconURL, source: pathTool.RPath.source, description: pathTool.RPath.description, owner: 'CommeUnDessein', thumbnailURL: pathTool.RPath.thumbnailURL, accepted: true, coreModule: true, category: pathTool.RPath.category }

			# R.initializeModules()

			# # init tool typeahead
			# initToolTypeahead = ()->
			# 	toolValues = []
			# 	toolValues.push( value: $(tool).attr("data-name") ) for tool in R.allToolsJ.children()
			# 	R.typeaheadModuleEngine = new Bloodhound({
			# 		name: 'Tools',
			# 		local: toolValues,
			# 		datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
			# 		queryTokenizer: Bloodhound.tokenizers.whitespace
			# 	})
			# 	promise = R.typeaheadModuleEngine.initialize()

			# 	R.searchToolInputJ = R.allToolsContainerJ.find("input.search-tool")
			# 	R.searchToolInputJ.keyup (event)->
			# 		query = R.searchToolInputJ.val()
			# 		if query == ""
			# 			R.allToolsJ.children().show()
			# 			return
			# 		R.allToolsJ.children().hide()
			# 		R.typeaheadModuleEngine.get( query, (suggestions)->
			# 			for suggestion in suggestions
			# 				console.log(suggestion)
			# 				R.allToolsJ.children("[data-name='" + suggestion.value + "']").show()
			# 		)
			# 		return
			# 	return

			# # get custom tools from the database, and initialize them
			# # ajaxPost '/getTools', {}, (result)->
			# Dajaxice.draw.getTools (result)->
			# 	scripts = JSON.parse(result.tools)

			# 	for script in scripts
			# 		R.runScript(script)

			# 	initToolTypeahead()
			# 	return

			# make the tools draggable between the 'favorite tools' and 'other tools' panels, and update R.typeaheadModuleEngine and R.favoriteTools accordingly


			# sortStart = (event, ui)->
			# 	$( "#sortable1, #sortable2" ).addClass("drag-over")
			# 	return

			# sortStop = (event, ui)->
			# 	$( "#sortable1, #sortable2" ).removeClass("drag-over")
			# 	if not localStorage? then return
			# 	names = []
			# 	for li in R.favoriteToolsJ.children()
			# 		names.push($(li).attr("data-name"))
			# 	localStorage.favorites = JSON.stringify(names)

			# 	toolValues = []
			# 	toolValues.push( value: $(tool).attr("data-name") ) for tool in R.allToolsJ.children()
			# 	R.typeaheadModuleEngine.clear()
			# 	R.typeaheadModuleEngine.add(toolValues)

			# 	return

			# sortableArgs =
			# 	connectWith: ".connectedSortable"
			# 	appendTo: R.sidebarJ
			# 	helper: "clone"
			# 	cancel: '.category'
			# 	start: sortStart
			# 	stop: sortStop
			# 	delay: 250
			# $( "#sortable1, #sortable2" ).sortable( sortableArgs ).disableSelection()

			R.tools.move.select() 		# select the move tool

			# ---  init Wacom tablet API --- #

			R.wacomPlugin = document.getElementById('wacomPlugin')
			if R.wacomPlugin?
				R.wacomPenAPI = wacomPlugin.penAPI
				R.wacomTouchAPI = wacomPlugin.touchAPI
				R.wacomPointerType = { 0: 'Mouse', 1: 'Pen', 2: 'Puck', 3: 'Eraser' }
			# # Wacom API documentation:

			# # penAPI properties:

			# penAPI.isWacom
			# penAPI.isEraser
			# penAPI.pressure
			# penAPI.posX
			# penAPI.posY
			# penAPI.sysX
			# penAPI.sysY
			# penAPI.tabX
			# penAPI.tabY
			# penAPI.rotationDeg
			# penAPI.rotationRad
			# penAPI.tiltX
			# penAPI.tiltY
			# penAPI.tangentialPressure
			# penAPI.version
			# penAPI.pointerType
			# penAPI.tabletModel

			# # add touchAPI event listeners (> IE 11)

			# touchAPI.addEventListener("TouchDataEvent", touchDataEventHandler)
			# touchAPI.addEventListener("TouchDeviceAttachEvent", touchDeviceAttachHandler)
			# touchAPI.addEventListener("TouchDeviceDetachEvent", touchDeviceDetachHandler)

			# # Open / close touch device connection

			# touchAPI.Close(touchDeviceId)
			# error = touchAPI.Open(touchDeviceId, passThrough) # passThrough == true: observe and pass touch data to system
			# if error != 0 then console.log "unable to establish connection to wacom plugin"

			# # touch device capacities:

			# deviceCapacities = touchAPI.TouchDeviceCapabilities(touchDeviceId)
			# deviceCapacities.Version
			# deviceCapacities.DeviceId
			# deviceCapacities.MaxFingers
			# deviceCapacities.ReportedSizeX
			# deviceCapacities.ReportedSizeY
			# deviceCapacities.PhysicalSizeX
			# deviceCapacities.PhysicalSizeY
			# deviceCapacities.LogicalOriginX
			# deviceCapacities.LogicalOriginY
			# deviceCapacities.LogicalWidth
			# deviceCapacities.LogicalHeight

			# # touch state helper map:
			# touchStates = [ 0: 'None', 1: 'Down', 2: 'Hold', 3: 'Up']
			# touchStates[touchState]

			# # Get touch data for as many fingers as supported
			# touchRawFingerData = touchAPI.TouchRawFingerData(touchDeviceId)

			# if touchRawFingerData.Status == -1 	# Bad data
			# 	return

			# touchRawFingerData.NumFingers

			# for finger in touchRawFingerData.FingerList
			# 	finger.FingerId
			# 	finger.PosX
			# 	finger.PosY
			# 	finger.Width
			# 	finger.Height
			# 	finger.Orientation
			# 	finger.Confidence
			# 	finger.Sensitivity
			# 	touchStates[finger.TouchState]


			@createZoombuttons()
			@createUndoRedoButtons()
			@createInfoButton()
			

			# @liveBtn = new Button(
			# 	name: 'Video'
			# 	iconURL: 'glyphicon-facetime-video'
			# 	favorite: true
			# 	category: null
			# 	description: 'Video'
			# 	popover: true
			# 	order: null
			# )

			return

		zoom: (value, snap=true)->
			if P.view.zoom * value < 0.125 or P.view.zoom * value > 4
				return
			bounds = R.view.getViewBounds(true)
			if value < 1 and bounds.contains(R.view.grid.limitCD.bounds)
				return
			if bounds.contains(R.view.grid.limitCD.bounds.scale(value))
				R.view.fitRectangle(R.view.grid.limitCD.bounds.expand(200), true)
				return
			
			if snap
				newZoom = 1
				zoomValues = [0.125, 0.25, 0.5, 1, 2, 4]
				if value < 1
					for v in zoomValues
						if P.view.zoom > v
							newZoom = v
						else
							break
				else
					for v in zoomValues
						if P.view.zoom < v
							newZoom = v
							break
				P.view.zoom = newZoom
			else 
				P.view.zoom *= value
			console.log(P.view.zoom)
			
			# @enableDrawingButton(P.view.zoom >= 1)
			# if P.view.zoom < 1 and R.selectedTool == R.tools['Precise path']
			# 	R.tools.move.select()
			# 	R.alertManager.alert 'Please zoom before drawing', 'info'
			
			R.view.moveBy(new P.Point())
			
			return

		createZoombuttons: ()->


			@zoomInBtn = new Button(
				name: 'Zoom +'
				# iconURL: 'glyphicon-zoom-in'
				# iconURL: 'icones_icon_zoomin.png'
				iconURL: if R.style == 'line' then 'icones_icon_zoomin.png' else if R.style == 'hand' then 'a-zoomIn.png' else 'glyphicon-zoom-in'
				favorite: true
				category: null
				# description: 'Zoom +'
				popover: true
				order: 1
			)

			@zoomInBtn.btnJ.click ()=> @zoom(2)

			@zoomOutBtn = new Button(
				name: 'Zoom -'
				# iconURL: 'glyphicon-zoom-out'
				# iconURL: 'icones_icon_zoomout.png'
				iconURL: if R.style == 'line' then 'icones_icon_zoomout.png' else if R.style == 'hand' then 'a-zoomOut.png' else 'glyphicon-zoom-out'
				favorite: true
				category: null
				# description: 'Zoom -'
				popover: true
				order: 2
			)

			@zoomOutBtn.btnJ.click ()=> @zoom(0.5)

			return

		createUndoRedoButtons: ()->

			@undoBtn = new Button(
				name: 'Undo'
				# iconURL: 'glyphicon-share-alt'
				# iconURL: 'icones_icon_back.png'
				iconURL: if R.style == 'line' then 'icones_icon_back_02.png' else if R.style == 'hand' then 'a-undo.png' else 'glyphicon-share-alt'
				favorite: true
				category: null
				# description: 'Undo'
				popover: true
				order: null
				transform: 'scaleX(-1)'
			)
			@undoBtn.hide()
			@undoBtn.btnJ.click ()-> R.commandManager.undo()

			@redoBtn = new Button(
				name: 'Redo'
				# iconURL: 'glyphicon-share-alt'
				# iconURL: 'icones_icon_forward.png'
				iconURL: if R.style == 'line' then 'icones_icon_forward_02.png' else if R.style == 'hand' then 'a-redo.png' else 'glyphicon-share-alt'
				favorite: true
				category: null
				# description: 'Redo'
				popover: true
				order: null
			)
			@redoBtn.hide()
			@redoBtn.btnJ.click ()-> R.commandManager.do()

			return

		createInfoButton: ()->

			@infoBtn = new Button(
				name: 'Help'
				# iconURL: 'glyphicon-info-sign'
				iconURL: 'icones_info.png'
				favorite: false
				category: null
				# description: 'Info'
				popover: true
				order: 1000
				classes: 'align-end'
				parentJ: $("#user-profile")
				prepend: true
				divType: 'div'
			)

			@infoBtn.btnJ.click ()-> 
				welcomeTextJ = $('#welcome-text')

				liveJ = $("""<iframe width="560" height="315" src="https://www.youtube.com/embed/live_stream?channel=UCRMrTkJJYvGAerb1j-H-Miw" frameborder="0" allowfullscreen></iframe>""")
				welcomeTextJ.find('#tipibot-live').append(liveJ)

				# layersJ = $('#RItems')
				# layersParentJ = layersJ.parent()
				modal = Modal.createModal( 
					id: 'info',
					title: 'Welcome to Comme Un Dessein', 
					submit: ( ()-> return ), 
					# postSubmit: 'load', 
					# submitButtonText: 'Sign up', 
					# submitButtonIcon: 'glyphicon-user', 
					# cancelButtonText: 'Just visit', 
					# cancelButtonIcon: 'glyphicon-sunglasses' 
					)
				# modal.addText('''
				# 	Comme un dessein is a participative piece created by the french collective IDLV (Indiens dans la Ville). 
				# 	With the help of a simple web interface and a monumental plotter, everyone can submit a drawing which takes part of a larger pictural composition, thus compose a collective utopian artwork.
				# ''', 'welcome message 1', false)
				# modal.addText('', 'welcome message 2', false)
				# modal.addText('', 'welcome message 3', false)
				modal.addCustomContent(divJ: welcomeTextJ.clone(), name: 'welcome-text')
				
				# modal.addCustomContent(divJ: layersJ)
				modal.modalJ.find('[name="cancel"]').hide()
				# modal.addButton( type: 'info', name: 'Sign in', submit: (()-> return location.pathname = '/accounts/login/'), icon: 'glyphicon-log-in' )
				# modal.addButton( type: 'info', name: 'Sign in', icon: 'glyphicon-log-in' )

				# modal.modalJ.find('[name="Sign in"]').attr('data-toggle', 'dropdown').after($('#user-profile').find('.dropdown-menu').clone())
				# modal.modalJ.find('.dropdown-menu').find('li.sign-up').hide()

				# modal.modalJ.on 'hide.bs.modal', (event)->
				# 	layersParentJ.append($('#RItems'))
				# 	return

				termsOfServiceJ = $('<div><a id="terms-of-service-link" href="/terms-of-service.html" data-i18n="Terms of Service">'+i18next.t('Terms of Service')+'</a></div>')
				PrivacyPolicyJ = $('<div><a id="privacy-policy-link" href="/privacy-policy.html" data-i18n="Privacy Policy">'+i18next.t('Privacy Policy')+'</a></div>')
                
				modal.addCustomContent(divJ: termsOfServiceJ)
				modal.addCustomContent(divJ: PrivacyPolicyJ)

				modal.show()
				return

			return

		createSubmitButton: ()->
			@submitButton = new Button({
				name: 'Submit drawing'
				# favorite: true
				iconURL: 'icones_icon_proposer_02.png'
				# order: 0
				classes: 'btn-success displayName'
				parentJ: $('#submit-drawing-button')
				ignoreFavorite: true
				onClick: ()=>
					R.drawingPanel.submitDrawingClicked()
					return
			})
			@submitButton.hide()
			return

		createDeleteButton: ()->
			@deleteButton = new Button({
				name: 'Delete draft'
				# favorite: true
				iconURL: 'icones_cancel_02.png'
				# order: 0
				classes: 'btn-danger'
				parentJ: $('#submit-drawing-button')
				ignoreFavorite: true
				onClick: ()=>
					draft = R.Drawing.getDraft()
					if draft?
						draft.removePaths(true)
					R.tools['Precise path'].showDraftLimits()
					return
			})
			@deleteButton.hide()
			return

		updateButtonsVisibility: (draft=null)->
			

			# pathTool = R.tools['Precise path']
			# voteTool = R.tools.select

			# if pathTool.btn? and voteTool.btn?
			# 	if R.selectedTool == R.tools['Precise path']
			# 		pathTool.btn.removeClass('btn-success')
			# 		voteTool.btn.removeClass('btn-info')
			# 		voteTool.btn.removeClass('btn-warning')
			# 		pathTool.btn.addClass('btn-warning')
			# 	else if R.selectedTool == voteTool
			# 		pathTool.btn.removeClass('btn-success')
			# 		pathTool.btn.removeClass('btn-warning')
			# 		voteTool.btn.removeClass('btn-info')
			# 		voteTool.btn.addClass('btn-warning')
			# 	else
			# 		pathTool.btn.removeClass('btn-success')
			# 		voteTool.btn.removeClass('btn-info')
			# 		pathTool.btn.removeClass('btn-warning')
			# 		voteTool.btn.removeClass('btn-warning')

			if R.selectedTool == R.tools['Precise path'] or R.selectedTool == R.tools.eraser
				@redoBtn.show()
				@undoBtn.show()
				@submitButton.show()
				@deleteButton.show()
				R.tools.eraser.btn.show()
			else
				@redoBtn.hide()
				@undoBtn.hide()
				@submitButton.hide()
				@deleteButton.hide()
				R.tools.eraser.btn.hide()

			draft ?= R.Drawing.getDraft()
			if not draft? or not draft.paths? or draft.paths.length == 0 or (R.drawingPanel.opened && R.drawingPanel.status != 'information')
				@submitButton.hide()
				@deleteButton.hide()
			else
				@submitButton.show()
				@deleteButton.show()
			return

		enterDrawingMode: ()->
			if R.selectedTool != R.tools['Precise path']
				R.tools['Precise path'].select()
			# R.sidebar.favoriteToolsJ.find("[data-name='Select']").css( opacity: 0.25 )

			for id, item of R.items
				if R.items[id].owner == R.me
					R.drawingPanel.showSubmitDrawing()
					break
			# @drawingMode = true
			# R.view.showDraftLayer()
			return

		leaveDrawingMode: (selectTool=false)->
			# @drawingMode = false
			# R.sidebar.favoriteToolsJ.find("[data-name='Select']").css( opacity: 1 )
			if selectTool
				R.tools.select.select(false, true, true)
			R.drawingPanel.hideSubmitDrawing()
			# R.view.hideDraftLayer()
			return

		enableDrawingButton: (enable)->
			if enable
				R.sidebar.favoriteToolsJ.find("[data-name='Precise path']").css( opacity: 1 )
			else
				R.sidebar.favoriteToolsJ.find("[data-name='Precise path']").css( opacity: 0.25 )
			return

	# todo: replace update by drag


	# CodeTool is just used as a button to open the code editor, the remaining code is in editor.coffee
	# class CodeTool extends RTool

	# 	constructor: ()->
	# 		super("Script")
	# 		return

	# 	# show code editor on select
	# 	select: (deselectItems=true, updateParameters=true)->
	# 		super
	# 		R.showEditor()
	# 		return

	# R.CodeTool = CodeTool

	## Init tools
	# - init jQuery elements related to the tools
	# - create all tools
	# - init tool typeahead (the algorithm to find the tools from a few letters in the search tool input)
	# - get custom tools from the database, and initialize them
	# - make the tools draggable between the 'favorite tools' and 'other tools' panels, and update R.typeaheadModuleEngine and R.favoriteTools accordingly

	return ToolManager
