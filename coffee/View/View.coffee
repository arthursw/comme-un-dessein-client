dependencies = ['paper', 'R',  'Utils/Utils', 'View/Grid', 'Commands/Command', 'Items/Paths/Path', 'Items/Divs/Div' ]
if document?
	dependencies.push('i18next')
	dependencies.push('hammer')
	dependencies.push('tween')
	dependencies.push('mousewheel')

define 'View/View', dependencies, (P, R, Utils, Grid, Command, Path, Div, i18next, Hammer, tw, mousewheel) ->

	class View
		
		@thumbnailSize = 300

		constructor: ()->

			R.stageJ = $("#stage")

			R.canvasJ = R.stageJ.find("#canvas")
			R.canvas = R.canvasJ[0]

			R.canvas.width = if window? then R.stageJ.innerWidth() else R.canvasWidth
			R.canvas.height = if window? then R.stageJ.innerHeight() else R.canvasHeight
			R.context = R.canvas.getContext('2d')

			paper.setup(R.canvas)
			R.project = P.project

			@mainLayer = P.project.activeLayer
			@mainLayer.name = 'mainLayer'

			@createLayers()

			@debugLayer = new P.Layer()				# Paper layer to append debug items
			@debugLayer.name = 'debugLayer'
			# @carLayer = new P.Layer() 				# Paper layer to append all cars
			# @carLayer.name = 'carLayer'
			# @lockLayer = new P.Layer()	 			# Paper layer to keep all locked items
			# @lockLayer.name = 'lockLayer'
			@selectionLayer = new P.Layer() 			# Paper layer to keep all selected items
			# R.view.selectionLayer = R.selectionProject.activeLayer
			@selectionLayer.name = 'selectionLayer'
			@areasToUpdateLayer = new P.Layer() 		# Paper layer to show areas to update
			@areasToUpdateLayer.name = 'areasToUpdateLayer'

			@backgroundRectangle = null 			# the rectangle to highlight the stage when dragging an RContent over it

			@areasToUpdateLayer.visible = false
			
			paper.settings.hitTolerance = 5

			R.scale = 1000.0
			P.view.zoom = 1 # 0.01
			@previousPosition = P.view.center

			@restrictedArea = null 				# area in which the user position will be constrained (in a website with restrictedArea == true)
			@entireArea = null 					# entire area to be kept loaded, it is a paper P.Rectangle
			@entireAreas = [] 						# array of RDivs which have data.loadEntireArea==true

			@grid = new Grid()

			@mainLayer.activate()
			
			R.canvasJ.dblclick( (event) -> R.selectedTool?.doubleClick?(event) )
			# cancel default delete key behaviour (not really working)
			R.canvasJ.keydown( (event) -> if event.key == 46 then event.preventDefault(); return false )


			@tool = new P.Tool()
			@tool.onMouseDown = @onMouseDown
			@tool.onMouseDrag = @onMouseDrag
			@tool.onMouseUp = @onMouseUp
			@tool.onKeyDown = @onKeyDown
			@tool.onKeyUp = @onKeyUp
			P.view.onFrame = @onFrame

			R.stageJ.mousewheel( @mousewheel )
			R.stageJ.mousedown( @mousedown )
			R.stageJ.on( touchstart: @mousedown )
			# R.stageJ[0].addEventListener('touchstart', @mousedown, false)

			if window?
				$(window).mousemove( @mousemove )
				$(window).on( touchmove: @mousemove )

				$(window).mouseup( @mouseup )

				$(window).on( touchend: @mouseup )
				$(window).on( touchleave: @mouseup )
				$(window).on( touchcancel: @mouseup )

				$(window).resize(@onWindowResize)

				window.onhashchange = @onHashChange

				hammertime = new Hammer(R.canvas)
				hammertime.get('pinch').set({ enable: true })
				hammertime.on 'pinch', (event)=>
					console.log(event.scale)
					R.toolManager.zoom(event.scale, false)
					return

			@mousePosition = new P.Point() 			# the mouse position in window coordinates (updated everytime the mouse moves)
			@previousMousePosition = null 			# the previous position of the mouse in the mousedown/move/up
			@initialMousePosition = null 			# the initial position of the mouse in the mousedown/move/up

			@firstHashChange = true

			@createThumbnailProject()
			return
		
		createThumbnailProject: ()->

			@thumbnailCanvas = document.createElement('canvas')
			@thumbnailCanvas.width = @constructor.thumbnailSize
			@thumbnailCanvas.height = @constructor.thumbnailSize
			$('body').append(@thumbnailCanvas)
			@thumbnailProject = new P.Project(@thumbnailCanvas)
			paper.projects[0].activate()
			return

		getThumbnail: (drawing, sizeX=@constructor.thumbnailSize, sizeY=@constructor.thumbnailSize, toDataURL=false, blackStroke=false)->
			@thumbnailProject.activate()
			@thumbnailProject.view.viewSize = new P.Size(sizeX, sizeY)
			@thumbnailCanvas.width = sizeX
			@thumbnailCanvas.height = sizeY
			rectangle = drawing.getBounds()

			if not rectangle? then return null

			viewRatio = 1
			rectangleRatio = rectangle.width / rectangle.height
			
			if drawing.svg?
				@thumbnailProject.importSVG(drawing.svg)
			else if drawing.paths? and drawing.paths.length > 0
				for path in drawing.paths
					@thumbnailProject.activeLayer.addChild(path.path)
			else
				console.error('drawing is empty')

			if viewRatio < rectangleRatio
				@thumbnailProject.view.zoom = Math.min(sizeX / rectangle.width, 1)
			else
				@thumbnailProject.view.zoom = Math.min(sizeY / rectangle.height, 1)

			@thumbnailProject.view.setCenter(rectangle.center)
			@thumbnailProject.activeLayer.strokeColor = if blackStroke then 'black' else R.Path.colorMap[drawing.status]
			if blackStroke
				@thumbnailProject.activeLayer.strokeWidth = 3
			@thumbnailProject.view.update()
			@thumbnailProject.view.draw()
			result = if toDataURL then @thumbnailCanvas.toDataURL() else @thumbnailProject.exportSVG()
			# drawing.group.remove()
			@thumbnailProject.clear()
			paper.projects[0].activate()
			return result

		createBackground: ()->
			if R.drawingMode == 'image' and not @backgroundImage?
				@backgroundImage = new P.Raster('static/images/rennes.jpg')
				@backgroundImage.onLoad = ()=>
					@backgroundImage.width = @grid.limitCD.bounds.width
					@backgroundImage.height = @grid.limitCD.bounds.height
					return
				@backgroundImage.opacity = 0.5
				P.project.layers[1].addChild(@backgroundImage)
				@backgroundImage.sendToBack()
				@backgroundListJ = @createLayerListItem('Background', @backgroundImage, true, false, false)
			else if R.drawingMode != 'image' and @backgroundImage?
				@backgroundImage.remove()
				@backgroundImage = null
				@backgroundListJ.remove()
			return

		createLayerListItem: (title, item, noArrow=false, prepend=true, badge=true)->
			itemListJ = R.templatesJ.find(".layer").clone()

			itemListJ.attr('data-name', item.name)

			nItemsJ = itemListJ.find(".n-items")
			nItemsJ.addClass(title.toLowerCase() + '-color')

			titleJ = itemListJ.find(".title")
			titleJ.attr('data-i18n', title)
			titleJ.text(i18next.t(title))
			
			if noArrow
				titleJ.addClass('no-arrow')

			if not noArrow
				titleJ.click (event)=>
					itemListJ.toggleClass('closed')
					if not event.shiftKey
						R.tools.select.deselectAll()
					return

			showBtnJ = itemListJ.find(".show-btn")
			
			item.data.setVisibility = (visible)=>
				R.tools.select.deselectAll()

				item.visible = visible
				
				for child in item.children
					if child.controller? and child.controller instanceof Path and not child.controller.drawing?
						child.controller.draw?()
						child.controller.rasterize?()

				R.rasterizer.refresh()

				SVGLayerJ = document.getElementById(item.name)
				SVGLayerJ.setAttribute('visibility', if visible then 'visible' else 'hidden')

				eyeIconJ = itemListJ.find("span.eye")
				if item.visible
					eyeIconJ.removeClass('glyphicon-eye-close').addClass('glyphicon-eye-open')
				else
					eyeIconJ.removeClass('glyphicon-eye-open').addClass('glyphicon-eye-close')
				return

			if not item.visible
				itemListJ.find("span.eye").removeClass('glyphicon-eye-open').addClass('glyphicon-eye-close')

			showBtnJ.mousedown (event)=>
				item.data.setVisibility(!item.visible)
				event.preventDefault()
				event.stopPropagation()
				return -1

			if prepend
				R.sidebar.itemListsJ.prepend(itemListJ)
			else
				R.sidebar.itemListsJ.append(itemListJ)

			if not badge
				itemListJ.find('span.badge').hide()

			return itemListJ
		
		hideDraftLayer: ()=>
			@mainLayer.data.setVisibility(false)
			return

		showDraftLayer: ()=>
			@mainLayer.data.setVisibility(true)
			return

		createLayers: ()->

			@rejectedLayer = new P.Layer()
			@rejectedLayer.name  = 'rejectedLayer'
			@rejectedLayer.visible = false
			@rejectedLayer.strokeColor = Path.colorMap['rejected']
			@pendingLayer = new P.Layer()
			@pendingLayer.name  = 'pendingLayer'
			@pendingLayer.strokeColor = Path.colorMap['pending']
			@drawingLayer = new P.Layer()
			@drawingLayer.name  = 'drawingLayer'
			@drawingLayer.strokeColor = Path.colorMap['drawing']
			@drawnLayer = new P.Layer()
			@drawnLayer.name  = 'drawnLayer'
			@drawnLayer.strokeColor = Path.colorMap['drawn']
			@draftLayer = new P.Layer()
			@draftLayer.name  = 'draftLayer'
			@draftLayer.strokeColor = Path.colorMap['draft']

			@draftListJ = @createLayerListItem('Draft', @draftLayer, true)
			@pendingListJ = @createLayerListItem('Pending', @pendingLayer)
			@drawingListJ = @createLayerListItem('Drawing', @drawingLayer)
			@drawnListJ = @createLayerListItem('Drawn', @drawnLayer)
			@rejectedListJ = @createLayerListItem('Rejected', @rejectedLayer)

			return

		getViewBounds: (considerPanels)->
			if window.innerWidth < 600
				considerPanels = false
			if considerPanels
				sidebarWidth = if R.sidebar.isOpened() then R.sidebar.sidebarJ.outerWidth() else 0
				drawingPanelWidth = if R.drawingPanel.isOpened() then R.drawingPanel.drawingPanelJ.outerWidth() else 0

				topLeft = P.view.viewToProject(new P.Point(sidebarWidth, 0))
				bottomRight = P.view.viewToProject(new P.Point(window.innerWidth - drawingPanelWidth, window.innerHeight-50))

				return new P.Rectangle(topLeft, bottomRight)
			return P.view.bounds

		## Move/scroll the commeUnDessein view

		# Move the commeUnDessein view to *pos*
		# @param pos [P.Point] destination
		# @param delay [Number] time of the animation to go to destination in millisecond
		moveTo: (pos, delay=null, addCommand=true, preventLoad=false, updateHash=true) ->
			pos ?= new P.Point()
			if not delay?
				somethingToLoad = @moveBy(pos.subtract(P.view.center), addCommand, preventLoad, updateHash)
			else
				# console.log pos
				# console.log delay
				initialPosition = P.view.center
				tween = new TWEEN.Tween( initialPosition )
				.to( pos, delay )
				.easing( TWEEN.Easing.Exponential.InOut )
				.onUpdate( ()-> @moveTo(this, addCommand, preventLoad) )
				.start()
			return somethingToLoad

		# Move the commeUnDessein view from *delta*
		# if user is in a restricted area (a website or videogame with restrictedArea), the move will be constrained in this area
		# This method does:
		# - scroll the paper view
		# - update RDivs' positions
		# - update grid
		# - update @entireArea (the area which must be kept loaded, in a video game or website)
		# - load entire area if we have a new entire area
		# - update websocket room
		# - update hash in 0.5 seconds
		# - set location in the general options
		# @param delta [P.Point]
		moveBy: (delta, addCommand=true, preventLoad=false, updateHash=true) ->

			# if user is in a restricted area (a website or videogame with restrictedArea), the move will be constrained in this area
			if @restrictedArea?

				# check if the restricted area contains P.view.center (if not, move to center)
				if not @restrictedArea.contains(P.view.center)
					# delta = @restrictedArea.center.subtract(P.view.size.multiply(0.5)).subtract(P.view.bounds.topLeft)
					delta = @restrictedArea.center.subtract(P.view.center)
				else
					newView = @getViewBounds(true)
					previousCenter = newView.center.clone()
					# test if new pos is still in restricted area
					newView.center.x += delta.x
					newView.center.y += delta.y

					# if it does not contain the view, change delta so that it contains it
					if not @restrictedArea.contains(newView)

						restrictedAreaShrinked = @restrictedArea.expand(newView.size.multiply(-1)) # restricted area shrinked by P.view.size

						if restrictedAreaShrinked.width<0
							restrictedAreaShrinked.left = restrictedAreaShrinked.right = @restrictedArea.center.x
						if restrictedAreaShrinked.height<0
							restrictedAreaShrinked.top = restrictedAreaShrinked.bottom = @restrictedArea.center.y

						newView.center.x = Utils.clamp(restrictedAreaShrinked.left, newView.center.x, restrictedAreaShrinked.right)
						newView.center.y = Utils.clamp(restrictedAreaShrinked.top, newView.center.y, restrictedAreaShrinked.bottom)
						delta = newView.center.subtract(previousCenter)

			@previousPosition ?= P.view.center

			# scroll the paper views
			P.view.scrollBy(new P.Point(delta.x, delta.y))
			# R.selectionProject.P.view.scrollBy(new P.Point(delta.x, delta.y))
			
			@updateSVG()

			for div in R.divs 										# update RDivs' positions
				div.updateTransform()

			R.rasterizer.move()
			@grid.update() 											# update grid

			# update @entireArea (the area which must be kept loaded, in a video game or website)
			# if the loaded entire areas contain the center of the view, it is the current entire area
			# @entireArea [P.Rectangle]
			# @entireAreas [array of Div] the array is updated when we load the RDivs (in ajax.coffee)
			# get the new entire area
			newEntireArea = null
			for area in @entireAreas
				if area.getBounds()?.contains(P.view.center)
					newEntireArea = area
					break

			# update @entireArea
			if not @entireArea? and newEntireArea?
				@entireArea = newEntireArea.getBounds()
			else if @entireArea? and not newEntireArea?
				@entireArea = null

			somethingToLoad = false
			
			# if preventLoad
			# 	somethingToLoad = false
			# else	
			# 	somethingToLoad = if newEntireArea? then R.loader.load(@entireArea) else R.loader.load()

			R.socket.updateRoom() 											# update websocket room
			
			if updateHash
				Utils.deferredExecution(@updateHash, 'updateHash', 500) 					# update hash in 500 milliseconds

			# if addCommand
			# 	Utils.deferredExecution(@addMoveCommand, 'add move command')

			# R.willUpdateAreasToUpdate = true
			# Utils.deferredExecution(R.updateAreasToUpdate, 'updateAreasToUpdate', 500) 					# update areas to update in 500 milliseconds

			# for pk, rectangle of R.areasToUpdate
			# 	if rectangle.intersects(P.view.bounds)
			# 		R.updateView()
			# 		break

			# update location in sidebar
			R.controllerManager.folders['General'].controllers['location'].setValue('' + P.view.center.x.toFixed(2) + ',' + P.view.center.y.toFixed(2))

			return somethingToLoad


		fitRectangle: (rectangle, considerPanels=false, zoom=null, updateHash=true)->
			windowSize = new P.Size(window.innerWidth, window.innerHeight)
			
			# WARNING: on small screen, the drawing panel takes the whole width, that would make window.width negative
			if window.innerWidth < 600
				considerPanels = false

			sidebarWidth = if considerPanels and R.sidebar.isOpened() then R.sidebar.sidebarJ.outerWidth() else 0
			drawingPanelWidth = if considerPanels and R.drawingPanel.isOpened() then R.drawingPanel.drawingPanelJ.outerWidth() else 0
			windowSize.width = windowSize.width - sidebarWidth - drawingPanelWidth
			
			viewRatio = windowSize.width / windowSize.height
			rectangleRatio = rectangle.width / rectangle.height

			if not zoom?
				if viewRatio < rectangleRatio
					P.view.zoom = Math.min(windowSize.width / rectangle.width, 1)
				else
					P.view.zoom = Math.min(windowSize.height / rectangle.height, 1)
			else
				P.view.zoom = zoom

			# R.toolManager.enableDrawingButton(P.view.zoom >= 1)

			if considerPanels
				windowCenterInView = P.view.viewToProject(new P.Point(window.innerWidth / 2, window.innerHeight / 2))
				visibleViewCenterInView = P.view.viewToProject(new P.Point(sidebarWidth + windowSize.width / 2, window.innerHeight / 2))
				offset = visibleViewCenterInView.subtract(windowCenterInView)
				@moveTo(rectangle.center.subtract(offset), null, true, false, updateHash)
			else
				@moveTo(rectangle.center, null, true, false, updateHash)

			# R.raph.setViewBox(P.view.bounds.left, P.view.bounds.top, P.view.bounds.width, P.view.bounds.height, false)

			@updateSVG()
			return

		updateSVG: ()->
			if R.svgJ?
				transform = Utils.getSVGTransform(P.view.matrix)
				R.svgJ.find('g:first').attr('transform', transform.transform)
			return

		addMoveCommand: ()=>
			R.commandManager.add(new Command.MoveView(@previousPosition, P.view.center))
			@previousPosition = null
			return

		## Hash

		# Update hash (the string after '#' in the url bar) according to the location of the (center of the) view
		# set *@ignoreHashChange* flag to ignore this change in *window.onhashchange* callback
		updateHash: ()=>
			hashParameters = {}
			if R.repository.commit?
				hashParameters['repository-owner'] = R.repository.owner
				hashParameters['repository-commit'] = R.repository.commit
			# if R.city.owner? and R.city.name? and R.city.owner != 'CommeUnDesseinOrg' and R.city.name != 'CommeUnDessein'
			# if R.city.name? and R.city.name != 'CommeUnDessein'
				# hashParameters['mode'] = R.city.name
			hashParameters['location'] = Utils.pointToString(P.view.center)
			hashParameters['zoom'] = P.view.zoom.toFixed(3).replace(/\.?0+$/, '')
			if R.tipibot?
				hashParameters['tipibot'] = true
			# if R.style?
				# hashParameters['style'] = R.style

			@ignoreHashChange = true
			location.hash = Utils.URL.setParameters(hashParameters)

			return

		setPositionFromString: (positionString)->
			@moveTo(Utils.stringToPoint(positionString))
			return

		# Update hash (the string after '#' in the url bar) according to the location of the (center of the) view
		# set *@ignoreHashChange* flag to ignore this change in *window.onhashchange* callback
		onHashChange: (event, reloadIfNecessary=true)=>
			if @ignoreHashChange
				@ignoreHashChange = false
				return

			parameters = Utils.URL.getParameters(document.location.hash)

			if R.repository.commit? and ( R.repository.owner != parameters['repository-owner'] or R.repository.commit != parameters['repository-commit'] )
				location.reload()
				return

			if parameters['location']?
				p = Utils.stringToPoint(parameters['location'])

			if parameters['zoom']?
				zoom = parseFloat(parameters['zoom'])
				if zoom? and Number.isFinite(zoom)
					P.view.zoom = Math.max(0.125, Math.min(4, zoom))

			mustReload = false
			
			# if parameters['mode']?
			# 	mustReload = parameters['mode'] != R.city.name
			# 	R.city.name = parameters['mode']

			R.tipibot = parameters['tipibot']

			mustReload |= parameters['style'] != R.style
			R.style = parameters['style']

			# if R.city.name != parameters['city-name'] or R.city.owner != parameters['city-owner']
			# 	R.cityManager.loadCity(parameters['city-name'], parameters['city-owner'], p)
			# 	return
			
			drawingPrefix = if location.pathname.indexOf('/drawing-') == 0 then '/drawing-' else if location.pathname.indexOf('/debug-drawing-') == 0 then '/debug-drawing-' else null
			if drawingPrefix?
				drawingPk = location.pathname.substring(drawingPrefix.length)
				R.loader.focusOnDrawing = drawingPk
			
			@moveTo(p, null, !@firstHashChange, @firstHashChange, false)

			@firstHashChange = true

			if reloadIfNecessary and mustReload
				window.location.reload()
			return

		## Init position
		# initialize the view position according to the 'data-box' of the canvas (when loading a website or video game)
		# update @entireArea and @restrictedArea according to site settings
		# update sidebar according to site settings
		initializePosition: ()->

			# R.githubLogin = R.canvasJ.attr("data-github-login")
			R.city ?= {}
			R.city.city = if R.canvasJ.attr("data-city") != '' then R.canvasJ.attr("data-city") else undefined
			
			# R.city =
			# 	owner: if R.canvasJ.attr("data-owner") != '' then R.canvasJ.attr("data-owner") else undefined
			# 	city: if R.canvasJ.attr("data-city") != '' then R.canvasJ.attr("data-city") else undefined
			# 	site: if R.canvasJ.attr("data-site") != '' then R.canvasJ.attr("data-site") else undefined

			@restrictedArea = @grid.limitCD.bounds.expand(100)

			# add arbitrary transform to generate the transform svg element
			P.view.zoom = 0.5
			P.view.scrollBy(1, 1)
			svg = P.project.exportSVG()
			R.svgJ = $(svg)
			R.svgJ.insertAfter(R.canvasJ)
			defsJ = $('<defs>')
			patternValidateJ = $("<pattern id='pattern-validate' width='8' height='8' patternUnits='userSpaceOnUse'>")
			patternValidateJ.append("<path d='M-2 10L10 -2ZM10 6L6 10ZM-2 2L2 -2' stroke='green' stroke-width='4.5'/>")
			patternRejectsJ = $("<pattern id='pattern-reject' width='8' height='8' patternUnits='userSpaceOnUse'>")
			patternRejectsJ.append("<path d='M-2 10L10 -2ZM10 6L6 10ZM-2 2L2 -2' stroke='red' stroke-width='4.5'/>")

			defsJ.append(patternValidateJ)
			defsJ.append(patternRejectsJ)
			R.svgJ.prepend(defsJ)
			
			R.svgJ.click((event)=>
				
				point = Utils.Event.GetPoint(event)
				point.y -= 62 # the stage is at 62 pixel
				point = P.view.viewToProject(point)
				rectangle = new P.Rectangle(point, point)
				rectangle = rectangle.expand(5)
				
				drawingsToSelect = []
				for drawing in R.drawings
					if drawing.getBounds()?.intersects(rectangle) and drawing.isVisible()
						drawingsToSelect.push(drawing)

				R.tools.select.deselectAll()
				for drawing in drawingsToSelect
					drawing.select()

				return
			)

			# check if canvas has an attribute 'data-box'
			# boxString = R.canvasJ.attr("data-box")
			#
			# if not boxString or boxString.length==0
			if not R.loadedBox?
				window?.onhashchange(null, false)
				return

			# initialize the area rectangle *boxRectangle* from 'data-box' attr and move to the center of the box
			# box = JSON.parse( boxString )

			planet = new P.Point(R.loadedBox.planetX, R.loadedBox.planetY)

			tl = Utils.CS.posOnPlanetToProject(R.loadedBox.box.coordinates[0][0], planet)
			br = Utils.CS.posOnPlanetToProject(R.loadedBox.box.coordinates[0][2], planet)

			boxRectangle = new P.Rectangle(tl, br)
			pos = boxRectangle.center

			@moveTo(pos)

			# load the entire area if 'data-load-entire-area' is set to true, and set @entireArea
			# loadEntireArea = R.canvasJ.attr("data-load-entire-area")

			if R.loadEntireArea
				@entireArea = boxRectangle
				R.loader.load(boxRectangle)

			# boxData = if box.data? and box.data.length>0 then JSON.parse(box.data) else null
			# console.log boxData

			# init @restrictedArea
			siteString = R.canvasJ.attr("data-site")
			site = JSON.parse( siteString )
			
			if site.restrictedArea
				@restrictedArea = boxRectangle

			R.tools.select.select() 		# select 'Select' tool by default when loading a website
											# since a click on an Lock will activate the drag (temporarily select the 'Move' tool)
											# and the user must be able to select text

			# update sidebar according to site settings
			if site.disableToolbar
				# just hide the sidebar
				R.sidebar.hide()
			else
				# remove all panels except the chat
				R.sidebar.sidebarJ.find("div.panel.panel-default:not(:last)").hide()

				# remove all controllers and folder except zoom in General.
				for folderName, folder of R.gui.__folders
					for controller in folder.__controllers
						if controller.name != 'Zoom'
							folder.remove(controller)
							folder.__controllers.remove(controller)
					if folder.__controllers.length==0
						R.gui.removeFolder(folderName)

				R.sidebar.handleJ.click()

			return

		contains: (item, tolerance=25)->
			return @grid.contains(item, tolerance)

		## mouse and key listeners


		focusIsOnCanvas: ()->
			return $(document.activeElement).is("body")
			# activeElementIsOnSidebar = $(document.activeElement).parents(".sidebar").length>0
			# activeElementIsTextarea = $(document.activeElement).is("textarea")
			# activeElementIsOnParameterBar = $(document.activeElement).parents(".dat-gui").length
			# return not activeElementIsOnSidebar and not activeElementIsTextarea and not activeElementIsOnParameterBar


		# Paper listeners
		onMouseDown: (event) =>

			if R.wacomPenAPI?.isEraser
				@tool.onKeyUp( key: 'delete' )
				return
			$(document.activeElement).blur() # prevent to keep focus on the chat when we interact with the canvas
			# event = Utils.Snap.snap(event) 		# snapping mouseDown event causes some problems
			R.selectedTool?.begin(event)
			return

		onMouseDrag: (event) =>
			if R.wacomPenAPI?.isEraser then return
			if R.currentDiv? then return
			# event = Utils.Snap.snap(event)
			R.selectedTool?.update(event)
			return

		# @tool.onMouseMove = (event) ->
		# 	if R.selectedTool.name == 'Select'
		# 		event.item?.controller?.highlight()
		# 	return

		onMouseUp: (event) =>
			if R.wacomPenAPI?.isEraser then return
			if R.currentDiv? then return
			# event = Utils.Snap.snap(event)
			R.selectedTool?.end(event)
			return

		onKeyDown: (event) =>

			# if the focus is on anything in the sidebar or is a textarea or in parameters bar: ignore the event
			if not @focusIsOnCanvas() then return

			if event.key == 'delete' 									# prevent default delete behaviour (not working)
				event.preventDefault()
				return false

			# select 'Move' tool when user press space key (and reselect previous tool after)
			if event.key == 'space' and R.selectedTool?.name != 'Move'
				R.tools.move.select()

			if event.key == 'z' and (event.modifiers.control or event.modifiers.meta)
				R.commandManager.undo()
				event.event.preventDefault()
				event.event.stopPropagation()
				return -1

			if event.key == 'y' and (event.modifiers.control or event.modifiers.meta)
				R.commandManager.do()
				event.event.preventDefault()
				event.event.stopPropagation()
				return -1
			
			return

		onKeyUp: (event) =>
			# if the focus is on anything in the sidebar or is a textarea or in parameters bar: ignore the event
			if not @focusIsOnCanvas() then return

			R.selectedTool?.keyUp(event)

			switch event.key
				when 'space'
					R.previousTool?.select()
				when 'v'
					R.tools.select.select()
				when 't'
					R.showToolBox()
				when 'r'
					# if R.specialKey(event) # Ctrl + R is already used to reload the page
					if event.modifiers.shift
						R.rasterizer.rasterizeImmediately()

			event.preventDefault()
			return

		# on frame event:
		# - update animatedItems
		# - update cars positions
		onFrame: (event)=>
			TWEEN.update(event.time)

			R.rasterizer?.updateLoadingBar?(event.time)

			R.selectedTool?.onFrame?(event)

			for item in R.animatedItems
				item.onFrame(event)

			return

		onWindowResize: (event)=>
			# update grid and mCustomScrollbar when window is resized
			# R.backgroundCanvas.width = window.innerWidth
			# R.backgroundCanvas.height = window.innerHeight
			# R.backgroundCanvasJ.width(window.innerWidth)
			# R.backgroundCanvasJ.height(window.innerHeight)
			@grid.update()
			$(".mCustomScrollbar").mCustomScrollbar("update")
			@moveBy(new P.Point())

			# R.canvasJ.width(window.innerWidth)
			# R.canvasJ.height(window.innerHeight-50)
			P.view.viewSize = new P.Size(R.stageJ.innerWidth(), R.stageJ.innerHeight())
			R.svgJ.attr('width', R.stageJ.innerWidth())
			R.svgJ.attr('height', R.stageJ.innerHeight())
			# R.selectionCanvasJ.width(window.innerWidth)
			# R.selectionCanvasJ.height(window.innerHeight)
			# R.selectionProject.P.view.viewSize = new P.Size(window.innerWidth, window.innerHeight)

			R.toolbar.updateArrowsVisibility()
			R.drawingPanel.onWindowResize()
			return

		# mousedown event listener
		mousedown: (event) =>

			moveButton = if event instanceof MouseEvent then 2 else if (TouchEvent? and event instanceof TouchEvent) then 0 else 2

			switch event.which						# switch on mouse button number (left, middle or right click)
				when moveButton
					R.tools.move.select(false, true, true)		# select move tool if middle mouse button
				when 3
					R.selectedTool?.finish?() 	# finish current path (in polygon mode) if right click

			if R.selectedTool?.name == 'Move' 		# update 'Move' tool if it is the one selected, and return
				# @initialMousePosition = Utils.Event.GetPoint(event)
				# @previousMousePosition = @initialMousePosition.clone()
				# R.selectedTool.begin()
				R.selectedTool?.beginNative(event)
				return

			@initialMousePosition = Utils.Event.jEventToPoint(event)
			@previousMousePosition = @initialMousePosition.clone()

			return

		# mousemove event listener
		mousemove: (event) =>

			@mousePosition.set(Utils.Event.GetPoint(event))

			if R.selectedTool?.name == 'Move' and R.selectedTool.dragging
				# mousePosition.set(Utils.Event.GetPoint(event))
				# simpleEvent = delta: @previousMousePosition.subtract(mousePosition)
				# @previousMousePosition = mousePosition
				# console.log simpleEvent.delta.toString()
				# R.selectedTool.update(simpleEvent) 	# update 'Move' tool if it is the one selected
				R.selectedTool.updateNative(event)
				return

			if R.selectedTool?.name == 'Select'
				paperEvent = Utils.Event.jEventToPaperEvent(event, @previousMousePosition, @initialMousePosition, 'mousemove')
				R.selectedTool?.move?(paperEvent)

			Div.updateHiddenDivs(event)

			# update selected RDivs
			# if R.previousPoint?
			#	point = Utils.Event.GetPoint(event)
			# 	event.delta = new P.Point(point.x-R.previousPoint.x, point.y-R.previousPoint.y)
			# 	R.previousPoint = new P.Point(event.pageX, event.pageY)

			# 	for item in R.selectedItems
			# 		item.updateSelect?(event)

			# update code editor width
			R.codeEditor?.onMouseMove(event)
			R.drawingPanel?.onMouseMove(event)

			if R.currentDiv?
				paperEvent = Utils.Event.jEventToPaperEvent(event, @previousMousePosition, @initialMousePosition, 'mousemove')
				R.currentDiv.updateSelect?(paperEvent)
				@previousMousePosition = paperEvent.point

			return

		# mouseup event listener
		mouseup: (event) =>

			if R.stageJ.hasClass("has-tool-box") and not $(event.target).parents('.tool-box').length>0
				R.hideToolBox()

			if not $(event.target).parents('#CommeUnDessein_alerts').length > 0
				R.alertManager.hideIfNoTimeout()

			R.codeEditor?.onMouseUp(event)
			R.drawingPanel?.onMouseUp(event)

			if R.selectedTool?.name == 'Move'
				# R.selectedTool.end(@previousMousePosition.equals(@initialMousePosition))
				R.selectedTool.endNative(event)

				# deselect move tool and select previous tool if middle mouse button
				if event.which == 2 # middle mouse button
					R.previousTool?.select(null, null, null, true)
				return


			if R.currentDiv?
				paperEvent = Utils.Event.jEventToPaperEvent(event, @previousMousePosition, @initialMousePosition, 'mouseup')
				R.currentDiv.endSelect?(paperEvent)
				@previousMousePosition = paperEvent.point

			# drag handles
			# R.mousemove(event)
			# selectedDiv.endSelect(event) for selectedDiv in R.selectedDivs

			# # update selected RDivs
			# if R.previousPoint?
			# point = Utils.Event.GetPoint(event)
			# 	event.delta = new P.Point(point.x-R.previousPoint.x, point.y-R.previousPoint.y)
			# 	R.previousPoint = null
			# 	for item in R.selectedItems
			# 		item.endSelect?(event)


			return

		mousewheel: (event)=>
			@moveBy(new P.Point(-event.deltaX, event.deltaY))
			return

		# hash format: [repo-owner=repo-owner-name&commit-hash=commit-hash][&city-owner=city-owner&city-name=city-name][&location=location-x,location-y]
		# default values: repo=arthursw:main&city-owner=CommeUnDesseinOrg&city-name=CommeUnDessein&location=0.0,0.0
		# examples: repo-owner=arthursw:247c64eae291e6551646f8785fd19d92333969de&city-owner=John&city-name=Paris&location=100.0,-9850.0


	return View
