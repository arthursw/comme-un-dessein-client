dependencies = [
	'R'
	'Utils/Utils'
	'Tools/Tool'
	'UI/Button'
	'Tools/MoveTool'
	'Tools/SelectTool'
	'Tools/PathTool'
	'Tools/EraserTool'
	'Tools/MoveDrawingTool'
	'Tools/ItemTool'
	'Tools/Tracer'
	'Tools/ChooseTool'
	'Tools/DiscussTool'
	'UI/Modal'
	'i18next'
	# 'Tools/TextTool'
	# 'Tools/GradientTool'
]

# if document?
	# dependencies.push('Tools/ScreenshotTool')
	# dependencies.push('Tools/CarTool')

define 'Tools/ToolManager',  dependencies, (R, Utils, Tool, Button, MoveTool, SelectTool, PathTool, EraserTool, MoveDrawingTool, ItemTool, Tracer, ChooseTool, DiscussTool, Modal, i18next) -> # , TextTool, GradientTool, CarTool) ->

	class ToolManager
		
		@minZoomPow = -7
		@maxZoomPow = 2
		@minZoom = Math.pow(2, @minZoomPow)
		@maxZoom = Math.pow(2, @maxZoomPow)

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
			@createColorButtons()
			
			R.tools.eraser = new R.Tools.Eraser()
			R.tools.eraser.btn.hide()
			
			R.tools.moveDrawing = new R.Tools.MoveDrawing()
			R.tools.moveDrawing.btn.hide()

			R.tracer = new Tracer()

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

			R.tools.choose = new R.Tools.Choose()
			R.tools.discuss = new R.Tools.Discuss()

			# R.chooser = new Chooser()

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

			R.tools.move.select() 		# select the move tool
			
			return

		clampZoom: (zoom)->
			return Math.max(@constructor.minZoom, Math.min(@constructor.maxZoom, zoom))

		zoom: (value, snap=true)->

			zoomPow = Math.floor( Math.log(P.view.zoom) / Math.log(2) )
			zoomPow += value

			if snap
				if value < 0 and zoomPow < @constructor.minZoomPow or value > 0 and zoomPow > @constructor.maxZoomPow
					return
			else if P.view.zoom * value < @constructor.minZoom or P.view.zoom * value > @constructor.maxZoom
				return


			bounds = R.view.getViewBounds(true)
			
			if value < 1 and bounds.contains(R.view.grid.limitCD.bounds)
				return
			
			if value < 1 and bounds.contains(R.view.grid.limitCD.bounds.scale(if snap then Math.pow(value, 2) else value))
				R.view.fitRectangle(R.view.grid.limitCD.bounds.expand(200), true)
				return
			
			if snap
				# newZoom = 1
				# zoomValues = Math.pow(2, n) for n in [minZoomPow .. maxZoomPow]
				# if value < 1
				# 	for v in zoomValues
				# 		if P.view.zoom > v
				# 			newZoom = v
				# 		else
				# 			break
				# else
				# 	for v in zoomValues
				# 		if P.view.zoom < v
				# 			newZoom = v
				# 			break

				P.view.zoom = Math.pow(2, zoomPow)
			else 
				P.view.zoom *= value

			# if R.voteFlags?
			# 	for voteFlag in R.voteFlags
			# 		voteFlag.scaling.x = 1 / P.view.zoom
			# 		voteFlag.scaling.y = 1 / P.view.zoom

			# @enableDrawingButton(P.view.zoom >= 1)
			# if P.view.zoom < 1 and R.selectedTool == R.tools['Precise path']
			# 	R.tools.move.select()
			# 	R.alertManager.alert 'Please zoom before drawing', 'info'
			R.tracer?.update()

			if zoomPow < -3
				R.tools.choose.hideOddLines()
			else
				R.tools.choose.showOddLines()

			R.view.moveBy(new P.Point())
			
			return

		createZoombuttons: ()->

			@zoomInBtn = new Button(
				name: 'Zoom +'
				# iconURL: 'glyphicon-zoom-in'
				# iconURL: 'icones_icon_zoomin.png'
				# iconURL: if R.style == 'line' then 'icones_icon_zoomin.png' else if R.style == 'hand' then 'a-zoomIn.png' else 'glyphicon-zoom-in'
				iconURL: 'new 1/Zoom in.svg'
				favorite: true
				category: null
				# description: 'Zoom +'
				disableHover: true
				popover: true
				order: 1
			)

			@zoomInBtn.btnJ.click ()=> @zoom(1)

			@zoomOutBtn = new Button(
				name: 'Zoom -'
				# iconURL: 'glyphicon-zoom-out'
				# iconURL: 'icones_icon_zoomout.png'
				# iconURL: if R.style == 'line' then 'icones_icon_zoomout.png' else if R.style == 'hand' then 'a-zoomOut.png' else 'glyphicon-zoom-out'
				iconURL: 'new 1/Zoom out.svg'
				favorite: true
				category: null
				disableHover: true
				# description: 'Zoom -'
				popover: true
				order: 2
			)

			@zoomOutBtn.btnJ.click ()=> @zoom(-1)

			return

		createUndoRedoButtons: ()->

			@undoBtn = new Button(
				name: 'Undo'
				classes: 'dark'
				# iconURL: 'glyphicon-share-alt'
				# iconURL: 'icones_icon_back.png'
				# iconURL: if R.style == 'line' then 'icones_icon_back_02.png' else if R.style == 'hand' then 'a-undo.png' else 'glyphicon-share-alt'
				iconURL: 'new 1/Undo.svg'
				favorite: true
				category: null
				disableHover: true
				# description: 'Undo'
				popover: true
				order: null
				transform: 'scaleX(-1)'
			)
			@undoBtn.hide()
			@undoBtn.btnJ.click ()-> R.commandManager.undo()

			@redoBtn = new Button(
				name: 'Redo'
				classes: 'dark'
				# iconURL: 'glyphicon-share-alt'
				# iconURL: 'icones_icon_forward.png'
				# iconURL: if R.style == 'line' then 'icones_icon_forward_02.png' else if R.style == 'hand' then 'a-redo.png' else 'glyphicon-share-alt'
				iconURL: 'new 1/Redo.svg'
				favorite: true
				category: null
				disableHover: true
				# description: 'Redo'
				popover: true
				order: null
			)
			@redoBtn.hide()
			@redoBtn.btnJ.click ()-> R.commandManager.do()

			return

		createColorButtons: ()->

			red = '#F44336'
			blue = '#448AFF'
			green = '#8BC34A'
			yellow = '#FFC107'
			brown = '#795548'
			black = '#000000'
			@colors = [red, blue, green, yellow, brown, black]

			if R.isCommeUnDessein
				R.selectedColor = black
				return

			R.selectedColor = green

			@colorBtn = new Button(
				name: 'Colors'
				# iconURL: 'glyphicon-tint'
				classes: 'dark'
				# iconURL: 'icones_icon_back.png'
				# iconURL: if R.style == 'line' then 'colors2.png' else if R.style == 'hand' then 'colors2.png' else 'glyphicon-tint'
				# iconURL: 'new 1/Drop-1.svg'
				iconSVG: '<svg xmlns="http://www.w3.org/2000/svg" width="43" height="43" viewBox="0 0 43 43" fill="none">
<path class="color" d="M16.7717 20.6433L20.7256 15.5101L23.1807 19.4662L26.4506 24.9596L27.2354 29.8644L25.9928 34.1807L23.7693 36.2734L19.5839 36.6658L16.2789 35.3517L14.352 32.4803V26.7907L16.7717 20.6433Z" fill="#448AFF"/>
<path class="color" d="M10.3885 8.25538L12.7428 5.63947L13.8995 7.01282L15.5423 10.8273L16.0232 13.8324L15.2619 16.477L13.8995 17.7592L10.8463 18.6536L9.27675 17.7592L8.12955 15.4352L8.62277 12.1792L10.3885 8.25538Z" fill="#448AFF"/>
<path class="color" d="M29.9832 12.6312L32.0347 10.0308L33.0426 11.396L34.4742 15.1879L34.8932 18.1753L34.2298 20.8042L33.0426 22.0788L30.3821 22.9679L29.0144 22.0788L28.0147 19.7685L28.4445 16.5318L29.9832 12.6312Z" fill="#448AFF"/>
<path d="M20.603 37.6934H20.5141C19.5791 37.721 18.6483 37.5588 17.7777 37.2168C16.9072 36.8747 16.1149 36.3599 15.4488 35.7032C14.2397 34.4471 13.5235 32.6294 13.3209 30.3007C13.1582 28.3694 13.3882 26.4252 13.9971 24.5853C14.5988 22.9527 15.3956 21.3989 16.3703 19.9576C17.1053 18.8787 17.9088 17.8481 18.7759 16.8722C19.2495 16.3132 19.6965 15.7858 20.0529 15.3268C20.1168 15.2429 20.2 15.1757 20.2955 15.1308C20.3909 15.086 20.4958 15.0648 20.6012 15.0691C20.7064 15.0724 20.8094 15.1006 20.9016 15.1515C20.9937 15.2024 21.0725 15.2745 21.1313 15.3619L21.6849 16.1795C22.6415 17.5898 23.6297 19.0489 24.5602 20.5166C25.6616 22.14 26.5829 23.8787 27.3074 25.7019C27.9169 27.3635 28.1713 29.1345 28.0544 30.9005C28.0217 31.8261 27.8055 32.7361 27.4184 33.5776C27.0314 34.419 26.481 35.1752 25.7994 35.8023C24.3471 37.0302 22.5048 37.7007 20.603 37.6934ZM20.5328 16.8566C20.2995 17.1383 20.0502 17.4342 19.7934 17.7359C18.9673 18.6641 18.2008 19.6436 17.4984 20.6685C16.5828 22.0192 15.8319 23.4745 15.2617 25.0034C14.7098 26.6713 14.5011 28.4336 14.6481 30.1842C14.8258 32.2019 15.4163 33.7478 16.4085 34.7786C16.9561 35.3022 17.6023 35.7117 18.3096 35.9831C19.0168 36.2546 19.7711 36.3827 20.5283 36.36C22.1442 36.3954 23.7164 35.8342 24.9445 34.7835C26.0346 33.7473 26.6737 32.3241 26.724 30.821C26.8292 29.2371 26.601 27.6488 26.054 26.1586C25.3606 24.4273 24.4824 22.7758 23.4347 21.2328C22.5154 19.7821 21.5325 18.3322 20.5816 16.9295L20.5328 16.8566Z" fill="white"/>
<path d="M11.2103 19.5341C10.7702 19.5338 10.3328 19.4651 9.91377 19.3306C9.33791 19.1298 8.82855 18.7741 8.44163 18.3027C8.05472 17.8313 7.80523 17.2624 7.72056 16.6584C7.50129 15.4574 7.56119 14.222 7.89563 13.0478C8.14548 12.0113 8.49471 11.0012 8.93847 10.0317C9.89438 8.15852 11.0409 6.38888 12.3598 4.75087C12.4231 4.66772 12.5054 4.60094 12.5997 4.55611C12.6941 4.51127 12.7979 4.48969 12.9023 4.49316C13.0066 4.49572 13.1087 4.52271 13.2006 4.57194C13.2926 4.62118 13.3716 4.69129 13.4315 4.77664C14.7943 6.71569 16.4627 9.62426 16.6751 12.4684C16.8782 15.2032 15.6132 17.7395 13.4533 18.9289C12.7693 19.3182 11.9973 19.5265 11.2103 19.5341ZM12.8543 6.30113C11.8149 7.65188 10.9043 9.09709 10.1346 10.6178C9.72972 11.5107 9.41088 12.4401 9.1824 13.3935C8.90097 14.3717 8.84822 15.4015 9.02822 16.4034C9.07406 16.77 9.21795 17.1175 9.44473 17.4091C9.67151 17.7008 9.97277 17.9259 10.3168 18.0607C10.7302 18.1865 11.1653 18.2249 11.5944 18.1734C12.0234 18.1219 12.4371 17.9817 12.809 17.7617C14.5139 16.8228 15.5087 14.7847 15.3443 12.5675C15.1826 10.3618 13.994 8.05134 12.8552 6.30113H12.8543Z" fill="white"/>
<path d="M30.5924 23.8139C30.5035 23.8139 30.4146 23.8108 30.3258 23.8033C29.6813 23.7576 29.0686 23.5062 28.5777 23.0862C28.0868 22.6662 27.7437 22.0997 27.5989 21.4701C26.9262 19.1151 27.6833 16.8313 28.3512 14.8172C28.9935 12.9817 29.8823 11.2421 30.9931 9.64606C31.0476 9.56471 31.1194 9.49635 31.2032 9.44586C31.2871 9.39537 31.3811 9.36398 31.4785 9.35393C31.5759 9.34387 31.6743 9.3554 31.7668 9.38769C31.8592 9.41998 31.9434 9.47224 32.0133 9.54076C34.219 11.7011 35.404 13.7054 35.7421 15.8502C36.1807 18.6237 35.3636 21.0933 33.4974 22.6213C32.6962 23.3431 31.6695 23.7646 30.5924 23.8139ZM31.6539 11.075C30.807 12.3737 30.1225 13.7713 29.6157 15.2366C28.9786 17.1574 28.3201 19.1436 28.8799 21.1044C28.9549 21.4708 29.1473 21.8028 29.4279 22.0501C29.7085 22.2974 30.0621 22.4465 30.4351 22.4747C31.2589 22.4671 32.0501 22.1515 32.6532 21.5901C34.1425 20.369 34.789 18.3518 34.426 16.0551C34.1639 14.3946 33.2774 12.7977 31.6539 11.075Z" fill="white"/>
</svg>'
# 				iconSVG: '<svg xmlns="http://www.w3.org/2000/svg" width="43" height="43" viewBox="0 0 43 43" fill="none">
# <path class="color" d="M18.5995 15.9925L22.0117 9.87902L24.6583 14.4752L27.616 20.5315L28.4007 25.4363L27.1582 29.7526L24.9347 31.8453L20.7492 32.2377L17.2881 31.5455L15.5174 28.0522V22.3626L18.5995 15.9925Z" fill="#448AFF"/>
# <path d="M22.9563 9.0315C24.3333 12.1255 26.1435 14.9991 27.5514 18.0777C28.6419 20.4619 30.0162 23.0214 29.9947 25.7018C29.961 29.9653 25.8149 32.9985 21.8614 33.4003C16.7044 33.9239 14.0205 29.4043 13.9243 24.6951C13.8694 22.0067 15.8918 19.1228 17.0955 16.8415C17.9424 15.2371 18.9208 13.7041 19.7556 12.0936C20.3565 10.9338 20.5827 9.69282 21.493 8.70496C22.2679 7.8637 23.5162 9.11851 22.7443 9.95623C22.0661 10.6925 21.8431 11.729 21.4458 12.6231C20.9594 13.7168 20.3075 14.7401 19.7131 15.7778C18.4288 18.0225 17.0829 20.3625 16.1363 22.7745C15.1529 25.2809 16.0198 27.964 17.4259 30.1217C18.3737 31.5765 20.3771 31.8384 21.9496 31.616C25.8358 31.0665 29.008 27.9026 28.0101 23.8308C27.4485 21.5377 26.1521 19.1372 25.094 17.0429C23.8893 14.6587 22.5159 12.3679 21.4281 9.92438C20.9682 8.89168 22.4929 7.99054 22.9563 9.0315Z" fill="white"/>
# <path d="M22.5905 30.1823C19.4413 30.6363 16.4264 27.6196 17.0774 24.4481C17.3066 23.3304 19.0128 23.8045 18.7839 24.9186C18.4255 26.6651 20.3307 28.7337 22.12 28.4759C23.2356 28.3149 23.7164 30.0198 22.5905 30.1823Z" fill="white"/>
# </svg>'
				favorite: true
				category: null
				disableHover: true
				# description: 'Undo'
				popover: true
				order: null
				# transform: 'scaleX(-1)'
			)
			@colorBtn.hide()

			closeColorMenu = ()->
				$('#color-picker').remove()
				return

			# @colorBtn.cloneJ.append($('<span class="selected-color">').css( width: 42, height: 10, position: 'absolute', display: 'block' ))

			@colorBtn.cloneJ.find('.glyphicon').css( color: R.selectedColor )

			@colorBtn.btnJ.click ()=>
				position = @colorBtn.cloneJ.offset()
				height = @colorBtn.cloneJ.outerHeight()
				ulJ = $('<ul>').attr('id', 'color-picker').css( position: 'fixed', top: position.top + height, left: position.left )
				for color in @colors
					liJ = $('<li>').attr('data-color', color).css( background: color, width: 50, height: 50, cursor: 'pointer' ).mousedown((event)=> 
						color = $(event.target).attr('data-color')
						R.selectedColor = color
						
						if R.selectedTool != R.tools["Precise path"]
							R.tools["Precise path"].select()

						# @colorBtn.cloneJ.find('span.selected-color').css( background: color )
						# @colorBtn.cloneJ.find('.glyphicon').css( color: R.selectedColor )
						@colorBtn.cloneJ.find('path.color').attr( fill: R.selectedColor )
						return)

					ulJ.append(liJ)
				
				@colorBtn.cloneJ.parent().append(ulJ)
				return
			
			$(window).mouseup( closeColorMenu )
			return

		createInfoButton: ()->

			@infoBtn = new Button(
				name: 'Help'
				# iconURL: 'glyphicon-info-sign'
				# iconURL: 'icones_info.png'
				iconURL: 'new 1/Info.svg'
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

				# liveJ = $("""<iframe width="560" height="315" src="https://www.youtube.com/embed/live_stream?channel=UCRMrTkJJYvGAerb1j-H-Miw" frameborder="0" allowfullscreen></iframe>""")
				# welcomeTextJ.find('#tipibot-live').append(liveJ)

				# layersJ = $('#RItems')
				# layersParentJ = layersJ.parent()
				modal = Modal.createModal( 
					id: 'info',
					title: 'Welcome to Comme un Dessein', 
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

				# termsOfServiceJ = $('<div><a id="terms-of-service-link" href="/terms-of-service.html" data-i18n="Terms of Service">'+i18next.t('Terms of Service')+'</a></div>')
				# PrivacyPolicyJ = $('<div><a id="privacy-policy-link" href="/privacy-policy.html" data-i18n="Privacy Policy">'+i18next.t('Privacy Policy')+'</a></div>')
                
				# modal.addCustomContent(divJ: termsOfServiceJ)
				# modal.addCustomContent(divJ: PrivacyPolicyJ)
				mailJ = $('<div>'+i18next.t('Contact us at')+' <a href="mailto:idlv.contact@gmail.com">idlv.contact@gmail.com</a></div>')
				modal.addCustomContent(divJ: mailJ)

				modal.show()
				return

			return

		createSubmitButton: ()->
			@submitButton = new Button({
				name: 'Submit drawing'
				# favorite: true
				# iconURL: 'icones_icon_proposer_02.png'
				iconURL: 'new 1/Check.svg'
				# order: 0
				classes: 'btn-success displayName'
				parentJ: $('#submit-drawing-button')
				ignoreFavorite: true
				onClick: ()=>
					R.tracer?.hide()
					R.drawingPanel.submitDrawingClicked()
					return
			})
			@submitButton.hide()
			return

		createDeleteButton: ()->
			@deleteButton = new Button({
				name: 'Delete draft'
				# favorite: true
				# iconURL: 'icones_cancel_02.png'
				iconURL: 'new 1/Cross.svg'
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

		createChangeImageButton: ()->
			@changeImageButton = new Button({
				name: 'Change image'
				iconURL: 'new 1/Image.svg'
				classes: 'btn-info displayName'
				parentJ: $('#submit-drawing-button')
				ignoreFavorite: true
				onClick: ()=>
					R.tracer?.openImageModal(false, true)
					return
			})
			@changeImageButton.hide()
			return
		
		createAutoTraceButton: ()->
			@autoTraceButton = new Button({
				name: 'Trace automatically'
				iconURL: 'new 1/Lightning bolt 1.svg'
				classes: 'btn-warning displayName'
				parentJ: $('#submit-drawing-button')
				ignoreFavorite: true
				onClick: ()=>
					R.tracer?.autoTrace()
					return
			})
			@autoTraceButton.hide()
			return
		
		showTracerButtons: ()->
			if R.tracer.isVisible()
				@changeImageButton.show()
				@autoTraceButton.show()
			return
		
		hideTracerButtons: ()->
			@changeImageButton.hide()
			@autoTraceButton.hide()
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

			if R.selectedTool == R.tools['Precise path'] or R.selectedTool == R.tools.eraser or R.selectedTool == R.tools.moveDrawing
				@colorBtn?.show()
				@redoBtn.show()
				@undoBtn.show()
				@submitButton.show()
				@deleteButton.show()
				R.tracer?.showButton()
				R.tools.eraser.btn.show()
				R.tools.moveDrawing.btn.show()
			else
				@colorBtn?.hide()
				@redoBtn.hide()
				@undoBtn.hide()
				@submitButton.hide()
				@deleteButton.hide()
				R.tracer?.hideButton()
				R.tools.eraser.btn.hide()
				R.tools.moveDrawing.btn.hide()

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

			# for id, item of R.items
			# 	if R.items[id].owner == R.me
			# 		R.drawingPanel.showSubmitDrawing()
			# 		break
			# @drawingMode = true
			# R.view.showDraftLayer()
			return

		leaveDrawingMode: (selectTool=false)->
			# @drawingMode = false
			# R.sidebar.favoriteToolsJ.find("[data-name='Select']").css( opacity: 1 )
			if selectTool
				R.tools.select.select(false, true, true)
			# R.drawingPanel.hideSubmitDrawing()
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
