dependencies = ['paper', 'R',  'Utils/Utils', 'View/Grid', 'View/ExquisiteCorpseMask', 'Commands/Command', 'Items/Paths/Path' ]
if document?
	dependencies.push('i18next')
	dependencies.push('hammerjs')
	dependencies.push('mousewheel')
	# dependencies.push('tween')
	dependencies.push('jquery-hammer')

define 'View/View', dependencies, (P, R, Utils, Grid, ExquisiteCorpseMask, Command, Path, i18next, Hammer, mousewheel) ->

	class View
		
		@thumbnailSize = 300 # in pixels, will be divided by pixelPerMm to get the size in mm, that is in paper projet coordinates

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

			# R.scale = 1000.0
			P.view.zoom = 1 # 0.01
			@previousPosition = P.view.center

			@restrictedArea = null 				# area in which the user position will be constrained (in a website with restrictedArea == true)
			@entireArea = null 					# entire area to be kept loaded, it is a paper P.Rectangle
			@entireAreas = [] 						# array of RDivs which have data.loadEntireArea==true

			@grid = new Grid()

			@mainLayer.activate()
			
			if R.city.mode == 'ExquisiteCorpse'
				@exquisiteCorpseMask = new ExquisiteCorpseMask(@grid)

			R.canvasJ.dblclick( (event) -> R.selectedTool?.doubleClick?(event) )
			# cancel default delete key behaviour (not really working)
			R.canvasJ.keydown( (event) -> if event.key == 46 then event.preventDefault(); return false )


			@tool = new P.Tool()
			@tool.onMouseDown = @onMouseDown
			@tool.onMouseDrag = @onMouseDrag
			@tool.onMouseUp = @onMouseUp
			# @tool.onKeyDown = @onKeyDown
			@tool.onKeyUp = @onKeyUp
			P.view.onFrame = @onFrame

			R.stageJ.mousewheel( @mousewheel )
			R.stageJ.mousedown( @mousedown )
			R.stageJ.on( touchstart: @mousedown )
			R.stageJ.on( touchmove: @mousemove )
			
			$(window).on( touchmove: (event)-> 
				if !$(event.target).parents('.scroll')[0]
					event.stopPropagation()
					event.preventDefault()
					return -1
			)

			# R.stageJ[0].addEventListener('touchstart', @mousedown, false)

			if window?
				$(window).keydown((event)=>@onKeyDown(Utils.Event.jEventToPaperEvent(event)))
				$(window).mousemove( @mousemove )
				# $(window).on( touchmove: @mousemove )

				$(window).mouseup( @mouseup )

				$(window).on( touchend: @mouseup )
				$(window).on( touchleave: @mouseup )
				$(window).on( touchcancel: @mouseup )

				$(window).resize(@onWindowResize)
				document.addEventListener('wheel', ((event)-> 
					if event.target != R.canvasJ.get(0) then return
					if not (event.metaKey or event.shiftKey or event.ctrlKey)
						delta = Math.sign(event.deltaY)
						R.toolManager.zoom(Math.pow(1.02, -delta), false)
						# R.toolManager.zoom(Math.pow(1.005, -event.deltaY), false)
					event.preventDefault()), {passive: false})

				window.onhashchange = @onHashChange

				# hammertime = new Hammer(R.canvas)
				# hammertime.get('pinch').set({ enable: true })

				# # getCenterPoint = (e)->
				# # 	canvasElement = P.view.element
				# # 	box = canvasElement.getBoundingClientRect()
				# # 	offset = new P.Point(box.left, box.top)
				# # 	return new P.Point(e.center.x, e.center.y).subtract(offset)
				
				# # startZoom = P.view.zoom
				# # startMatrix = P.view.matrix.clone()
				# # startMatrixInverted = startMatrix.inverted()
				# # p0 = getCenterPoint(P.view)
				# # p0ProjectCoorpds = P.view.viewToProject(p0)

				# # hammertime.on('pinchstart', (event)=>
				# # 	startZoom = P.view.zoom
				# # 	startMatrix = P.view.matrix.clone()
				# # 	startMatrixInverted = startMatrix.inverted()
				# # 	p0 = getCenterPoint(event)
				# # 	p0ProjectCoorpds = P.view.viewToProject(p0)
				# # )

				# # hammertime.on('pinch', (event) =>
				# # 	# Translate and scale view using pinch event's 'center' and 'scale' properties.
				# # 	# Translation computes center's distance from initial center (considering current scale).
				# # 	p = getCenterPoint(event)
				# # 	pProject0 = p.transform(startMatrixInverted)
				# # 	delta = pProject0.subtract(p0ProjectCoords).divide(event.scale)
				# # 	res = startZoom * event.scale / P.view.zoom
				# # 	R.alertManager.alert('startZoom:'+startZoom.toFixed(2)+',e.scale'+event.scale.toFixed(2)+',zoom:'+P.view.zoom.toFixed(2)+',res:'+res.toFixed(2))
				# # 	R.toolManager.zoom(res, false)
				# # 	@moveBy(delta)
				# # 	# P.view.matrix = startMatrix.clone().scale(e.scale, p0ProjectCoords).translate(delta)
				# # )


				# hammertime.on 'pinch', (event)=>
				# 	# console.log(event.scale)
				# 	# delta = Math.sign(event.scale)
				# 	R.alertManager.alert(''+Objects.keys(event), 'info')
				# 	# R.toolManager.zoom(Math.pow(1.02, delta), false)
				# 	# R.toolManager.zoom(event.scale / 10, false)
				# 	return
				
				# zt = new ZingTouch.Region(R.canvas)

				# zt.bind(R.canvas, new ZingTouch.Distance(), (event)=>
				# 	ratio = event.distance / (event.distance + event.change)
				# 	R.alertManager.alert(''+ratio.toFixed(1)+','+event.distance.toFixed(1)+','+event.change.toFixed(1), 'info')
				# 	return R.toolManager.zoom(ratio, false)
				# )

			@mousePosition = new P.Point() 			# the mouse position in window coordinates (updated everytime the mouse moves)
			@previousMousePosition = null 			# the previous position of the mouse in the mousedown/move/up
			@initialMousePosition = null 			# the initial position of the mouse in the mousedown/move/up

			# @firstHashChange = true

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
			
			# jqxhr = $.get( location.origin + '/static/drawings/' + @pk + '.svg', ((result)=>
			# 	@setSVG(result, false, callback)
			# 	return
			# ))
			# .fail(()=>

			# 	if @svg? then return

			# 	args =
			# 		pk: @pk
			# 		svgOnly: true
			# 	$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawing', args: args } ).done((result)=>
			# 		drawing = JSON.parse(result.drawing)
			# 		if drawing.svg?
			# 			@setSVG(drawing.svg, true, callback)
			# 	)
			# )

			if (not drawing.svg? or toDataURL) and drawing.paths? and drawing.paths.length > 0
				# for path in drawing.paths
				# 	clone = path.clone()
				# 	@thumbnailProject.activeLayer.addChild(clone)
				@thumbnailProject.activeLayer.addChild(drawing.group.clone())

			if viewRatio < rectangleRatio
				@thumbnailProject.view.zoom = Math.min(sizeX / rectangle.width, 1)
			else
				@thumbnailProject.view.zoom = Math.min(sizeY / rectangle.height, 1)

			@thumbnailProject.view.setCenter(rectangle.center)
			@thumbnailProject.activeLayer.name = 'mainLayer'
			# @thumbnailProject.activeLayer.strokeColor = if blackStroke then 'black' else R.Path.colorMap[drawing.status]
			if blackStroke
				@thumbnailProject.activeLayer.strokeWidth = 3
			else
				@thumbnailProject.activeLayer.strokeWidth = R.Path.strokeWidth
			@thumbnailProject.view.update()
			@thumbnailProject.view.draw()
			result = if toDataURL then @thumbnailCanvas.toDataURL() else @thumbnailProject.exportSVG()
			# drawing.group.remove()

			if drawing.svg? and not toDataURL
				svg = drawing.svg.cloneNode(true)
				# console.log("view: ", svg.getAttribute('xmlns'))
				# svg.removeAttribute('xmlns')
				# svg.setAttribute('visibility', 'visible')
				$(result).find('#mainLayer').append(svg)

			@thumbnailProject.clear()
			paper.projects[0].activate()
			return result

		getTileThumbnail: (tileRectangle)->
			# activeLayer = P.project.activeLayer.clone()
			# activeLayer.remove()
			items = P.project.getItems(overlapping: tileRectangle, class: P.Raster )

			@thumbnailProject.activate()
			@thumbnailProject.view.viewSize = new P.Size(tileRectangle.width, tileRectangle.height)
			@thumbnailCanvas.width = tileRectangle.width
			@thumbnailCanvas.height = tileRectangle.height
			rectangle = tileRectangle

			if not rectangle? then return null

			viewRatio = 1
			rectangleRatio = rectangle.width / rectangle.height
			
			for item in items
				if item instanceof P.Raster
					raster = new P.Raster(item.source)
					raster.position = item.position
					@thumbnailProject.activeLayer.addChild(raster)

			# if viewRatio < rectangleRatio
			# 	@thumbnailProject.view.zoom = Math.min(sizeX / rectangle.width, 1)
			# else
			# 	@thumbnailProject.view.zoom = Math.min(sizeY / rectangle.height, 1)

			@thumbnailProject.view.setCenter(rectangle.center)
			@thumbnailProject.activeLayer.name = 'mainLayer'
			# @thumbnailProject.activeLayer.strokeColor = if blackStroke then 'black' else R.Path.colorMap[drawing.status]
			# if blackStroke
			# 	@thumbnailProject.activeLayer.strokeWidth = 3
			# else
			# 	@thumbnailProject.activeLayer.strokeWidth = R.Path.strokeWidth
			@thumbnailProject.view.update()
			@thumbnailProject.view.draw()
			result = @thumbnailCanvas.toDataURL()
			# drawing.group.remove()

			# if drawing.svg? and not toDataURL
			# 	$(result).find('#mainLayer').append(drawing.svg.cloneNode(true))

			# @thumbnailProject.clear()
			# paper.projects[0].activate()
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

				# R.rasterizer.refresh()

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

			@rasterLayer = new P.Layer()
			@rasterLayer.name  = 'rejectedLayer'
			R.loader.initializeGroups(@rasterLayer)

			@rejectedLayer = new P.Layer()
			@rejectedLayer.name  = 'rejectedLayer'
			@rejectedLayer.visible = false
			@rejectedLayer.strokeColor = Path.colorMap['rejected']
			@rejectedLayer.strokeWidth = Path.strokeWidth
			@pendingLayer = new P.Layer()
			@pendingLayer.name  = 'pendingLayer'
			@pendingLayer.strokeColor = Path.colorMap['pending']
			@pendingLayer.strokeWidth = Path.strokeWidth
			@drawingLayer = new P.Layer()
			@drawingLayer.name  = 'validatedLayer'
			@drawingLayer.strokeColor = Path.colorMap['drawing']
			@drawingLayer.strokeWidth = Path.strokeWidth
			@validatedLayer = @drawingLayer
			@drawnLayer = new P.Layer()
			@drawnLayer.name  = 'drawnLayer'
			@drawnLayer.strokeColor = Path.colorMap['drawn']
			@drawnLayer.strokeWidth = Path.strokeWidth
			@draftLayer = new P.Layer()
			@draftLayer.name  = 'draftLayer'
			@draftLayer.strokeColor = Path.colorMap['draft']
			@draftLayer.strokeWidth = Path.strokeWidth
			
			@discussionLayer = new P.Layer()
			@discussionLayer.name  = 'discussionLayer'
			@discussionLayer.strokeWidth = Path.strokeWidth

			@flaggedLayer = new P.Layer()
			@flaggedLayer.name  = 'flaggedLayer'
			@flaggedLayer.strokeWidth = Path.strokeWidth
			@mainLayer.bringToFront()

			if R.city.finished
				@pendingLayer.visible = false
			
			@flaggedLayer.visible = false

			if not R.administrator
				@rejectedLayer.visible = false
			else
				# @testLayer = new P.Layer()
				# @testLayer.name  = 'testLayer'
				# @testLayer.strokeColor = Path.colorMap['test']
				# @testLayer.strokeWidth = Path.strokeWidth
				@flaggedLayer.strokeColor = Path.colorMap['flagged']

			@draftListJ = @createLayerListItem('Draft', @draftLayer, true)
			@pendingListJ = @createLayerListItem('Pending', @pendingLayer)
			@pendingListJ.removeClass('closed')
			@drawingListJ = @createLayerListItem('Drawing', @drawingLayer)
			if R.isCommeUnDessein
				@drawnListJ = @createLayerListItem('Drawn', @drawnLayer)
			@rejectedListJ = @createLayerListItem('Rejected', @rejectedLayer)
			@flaggedListJ = @createLayerListItem('Flagged', @flaggedLayer)
			
			# if R.administrator
			# 	@testListJ = @createLayerListItem('Test', @testLayer)

			@createLoadRejectedDrawingsButton()
			@createHideOtherDrawingsButton()

			# @rejectedListJ.find(".show-btn").click (event)=>
			# 	@loadRejectedDrawings()
			# 	event.preventDefault()
			# 	event.stopPropagation()
			# 	return -1

			if not R.administrator
				@flaggedListJ.hide()

			return

		createLoadRejectedDrawingsButton: ()->
			loadRejectedDrawingsText = 'Show rejected drawings'
			hideRejectedDrawingsText = 'Hide rejected drawings'
			loadRejectedDrawingButtonJ = $('<button class="">').css( color: 'black', height: 25 ).text(loadRejectedDrawingsText)
			loadRejectedDrawingButtonJ.attr('data-i18n', loadRejectedDrawingsText)
			loadRejectedDrawingButtonJ.click (event)=>
				R.loadRejectedDrawings = !R.loadRejectedDrawings
				if R.loadRejectedDrawings
					loadRejectedDrawingButtonJ.text(i18next.t(hideRejectedDrawingsText)).attr('data-i18n', hideRejectedDrawingsText)
					@loadRejectedDrawings()
				else
					loadRejectedDrawingButtonJ.text(i18next.t(loadRejectedDrawingsText)).attr('data-i18n', loadRejectedDrawingsText)
					R.loader.inactiveRasterGroup.visible = false
					R.view.rejectedLayer.visible = false
					document.getElementById('rejectedLayer').setAttribute('visibility', 'hidden')
					@rejectedListJ.find('.rPath-list').addClass('hide-drawings')
				return
			loadRejectedDrawingLiJ = $('<li>').css( 'justify-content': 'center' ).append(loadRejectedDrawingButtonJ)
			@rejectedListJ.find('ul.rPath-list').append(loadRejectedDrawingLiJ)

			return

		createHideOtherDrawingsButton: ()->
			hideOtherDrawingsText = 'Hide other drawings'
			showOtherDrawingsText = 'Show other drawings'
			hideOtherDrawingsButtonJ = $('<button class="">').css( color: 'black', height: 25 ).text(hideOtherDrawingsText)
			hideOtherDrawingsButtonJ.attr('data-i18n', hideOtherDrawingsText)
			hideOtherDrawingsButtonJ.click (event)=>
				activeRasterGroup = R.loader.activeRasterGroup
				activeRasterGroup.visible = !activeRasterGroup.visible
				R.view.pendingLayer.visible = activeRasterGroup.visible
				R.view.draftLayer.visible = activeRasterGroup.visible
				visibility = if activeRasterGroup.visible then 'visible' else 'hidden'
				document.getElementById('pendingLayer').setAttribute('visibility', visibility)
				document.getElementById('validatedLayer').setAttribute('visibility', visibility)
				document.getElementById('drawnLayer').setAttribute('visibility', visibility)
				document.getElementById('draftLayer').setAttribute('visibility', visibility)
				if activeRasterGroup.visible
					@drawingListJ.find('.rPath-list').removeClass('hide-drawings')
					@pendingListJ.find('.rPath-list').removeClass('hide-drawings')
				else
					@drawingListJ.find('.rPath-list').addClass('hide-drawings')
					@pendingListJ.find('.rPath-list').addClass('hide-drawings')

				if !activeRasterGroup.visible
					hideOtherDrawingsButtonJ.text(i18next.t(showOtherDrawingsText)).attr('data-i18n', showOtherDrawingsText)
				else
					hideOtherDrawingsButtonJ.text(i18next.t(hideOtherDrawingsText)).attr('data-i18n', hideOtherDrawingsText)
				return
			hideOtherDrawingsLiJ = $('<li>').css( 'justify-content': 'center' ).append(hideOtherDrawingsButtonJ)
			@rejectedListJ.find('ul.rPath-list').append(hideOtherDrawingsLiJ)

			return

		loadRejectedDrawings: (callback=null)->
			R.loader.inactiveRasterGroup.visible = true
			R.view.rejectedLayer.visible = true
			R.loadRejectedDrawings = true
			document.getElementById('rejectedLayer').setAttribute('visibility', 'visible')
			@rejectedListJ.find('.rPath-list').removeClass('hide-drawings')
			R.loader.clearRasters()
			R.loader.loadRasters(P.view.bounds, true, callback)
			return

		getViewBounds: (considerPanels)->
			if R.stageJ.innerWidth() < 600
				considerPanels = false
			if considerPanels
				sidebarWidth = if R.sidebar.isOpened() then R.sidebar.sidebarJ.outerWidth() else 0
				drawingPanelWidth = if R.drawingPanel.isOpened() then R.drawingPanel.drawingPanelJ.outerWidth() else 0

				topLeft = P.view.viewToProject(new P.Point(sidebarWidth, R.stageJ.offset().top))
				bottomRight = P.view.viewToProject(new P.Point(R.stageJ.innerWidth() - drawingPanelWidth, R.stageJ.innerHeight() - R.stageJ.offset().top))

				return new P.Rectangle(topLeft, bottomRight)
			return P.view.bounds

		## Move/scroll the commeUnDessein view

		# Move the commeUnDessein view to *pos*
		# @param pos [P.Point] destination
		# @param delay [Number] time of the animation to go to destination in millisecond
		moveTo: (pos, delay=null, addCommand=true, preventLoad=false, updateHash=true) ->
			pos ?= new P.Point()
			somethingToLoad = @moveBy(pos.subtract(P.view.center), addCommand, preventLoad, updateHash)
			
			# if not delay?
				
			# else
			# 	# console.log pos
			# 	# console.log delay
			# 	initialPosition = P.view.center
			# 	tween = new TWEEN.Tween( initialPosition )
			# 	.to( pos, delay )
			# 	.easing( TWEEN.Easing.Exponential.InOut )
			# 	.onUpdate( ()-> @moveTo(this, addCommand, preventLoad) )
			# 	.start()
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

						if restrictedAreaShrinked.width < 0
							restrictedAreaShrinked.left = restrictedAreaShrinked.right = @restrictedArea.center.x
						if restrictedAreaShrinked.height < 0
							restrictedAreaShrinked.top = restrictedAreaShrinked.bottom = @restrictedArea.center.y

						newView.center.x = Utils.clamp(restrictedAreaShrinked.left, newView.center.x, restrictedAreaShrinked.right)
						newView.center.y = Utils.clamp(restrictedAreaShrinked.top, newView.center.y, restrictedAreaShrinked.bottom)
						delta = newView.center.subtract(previousCenter)

			@previousPosition ?= P.view.center

			# scroll the paper views
			P.view.scrollBy(new P.Point(delta.x, delta.y))
			# R.selectionProject.P.view.scrollBy(new P.Point(delta.x, delta.y))
			
			@updateSVG()

			for div in R.divs 										# update RDivs positions
				div.updateTransform()

			# R.rasterizer.move()
			@grid.update() 											# update grid
			R.loader.loadRasters()

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
			# R.controllerManager.folders['General'].controllers['location'].setValue('' + P.view.center.x.toFixed(2) + ',' + P.view.center.y.toFixed(2))

			return somethingToLoad


		fitRectangle: (rectangle, considerPanels=false, zoom=null, updateHash=true)->

			windowSize = new P.Size(R.stageJ.innerWidth(), R.stageJ.innerHeight())
			
			# WARNING: on small screen, the drawing panel takes the whole width, that would make window.width negative
			if windowSize.width < 870
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
				windowCenterInView = P.view.viewToProject(new P.Point(R.stageJ.innerWidth() / 2, R.stageJ.innerHeight() / 2))
				visibleViewCenterInView = P.view.viewToProject(new P.Point(sidebarWidth + windowSize.width / 2, windowSize.height / 2))
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
				# transform = Utils.getSVGTransform(P.view.matrix, false, null, 'px')
				# console.log(transform)
				# R.discussionJ.find('#discussion-view').css( 'transform': transform.transform )
				R.discussionJ.find('g:first').attr('transform', transform.transform)
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
			
			if R.administrator
				hashParameters['administrator'] = true

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
					P.view.zoom = R.toolManager.clampZoom(zoom)
					R.tracer?.update()

			mustReload = false
			
			# if parameters['mode']?
			# 	mustReload = parameters['mode'] != R.city.name
			# 	R.city.name = parameters['mode']

			R.tipibot = parameters['tipibot']

			mustReload |= parameters['style'] != R.style
			R.style = parameters['style']

			if parameters['administrator']?
				R.administrator = parameters['administrator']

			# if R.city.name != parameters['city-name'] or R.city.owner != parameters['city-owner']
			# 	R.cityManager.loadCity(parameters['city-name'], parameters['city-owner'], p)
			# 	return
			
			# drawingPrefixIndex = location.pathname.indexOf('/drawing-')
			# if drawingPrefixIndex >= 0
			# 	drawingPk = location.pathname.substring(drawingPrefixIndex  + '/drawing-'.length)
			# 	R.loader.focusOnDrawing = drawingPk
			
			if p?
				@moveTo(p, null, false, true, false)
			else
				loadDrawingOrTile = @initializePositionFromDrawingOrTile()
				if not loadDrawingOrTile
					@moveTo(new P.Point(), null, false, true, false)

			# @moveTo(p, null, !@firstHashChange, @firstHashChange, false)
			# @firstHashChange = true

			if reloadIfNecessary and mustReload
				window.location.reload()

			return

		initializePositionFromDrawingOrTile: ()->
			boundsString = R.canvasJ.attr("data-bounds")
			bounds = if boundsString? and boundsString.length > 0 then JSON.parse(boundsString) else null
			if bounds?
				rectangle = new P.Rectangle(bounds)
				drawingPk = R.canvasJ.attr("data-drawing-pk")
				if drawingPk? and drawingPk.length > 0
					@fitRectangle(rectangle, true)
					# args =
					# 	pk: drawingPk
					# 	loadPathList: true
					# 	# loadSVG: true

					# $.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawing', args: args } ).done((result)=>
					# 	# R.drawingPanel.setDrawing(@, result)
					# )
				tilePk = R.canvasJ.attr("data-tile-pk")
				if tilePk? and tilePk.length > 0
					R.tools.choose.select()
					R.tools.choose.loadTile(tilePk, rectangle, true)
				
				return true

			return false

		# User has choosen a city from world: display @grid.frame (gray background) and update @restrictedArea
		loadCity: ()->
			# @grid.createFrame()
			@initializePosition()
			return

		selectDrawings: (event)->
			point = Utils.Event.GetPoint(event)
			point.y -= 62 # the stage is at 62 pixel
			point = P.view.viewToProject(point)
			event.point = point
			canDrawOrVote = if R.view.exquisiteCorpseMask? then R.view.exquisiteCorpseMask.mouseBegin(event) else true
			if not canDrawOrVote then return

			rectangle = new P.Rectangle(point, point)
			rectangle = rectangle.expand(5)
			
			drawingsToSelect = []
			for drawing in R.drawings
				if drawing.getBoundsWithFlag()?.intersects(rectangle) and drawing.isVisible()
					drawingsToSelect.push(drawing)

			R.tools.select.deselectAll()
			for drawing in drawingsToSelect
				drawing.select()
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

			if R.city.name != 'world'
				@restrictedArea = @grid.limitCD.bounds.expand(100)

			# add arbitrary transform to generate the transform svg element
			P.view.zoom = 0.5
			P.view.scrollBy(1, 1)
			svg = P.project.exportSVG()
			R.svgJ = $(svg)
			R.svgJ.insertAfter(R.canvasJ)
			R.svgJ.find('#grid').remove()
			defsJ = $('<defs>')
			patternValidateJ = $("<pattern id='pattern-validate' width='8' height='8' patternUnits='userSpaceOnUse'>")
			patternValidateJ.append("<path d='M-2 10L10 -2ZM10 6L6 10ZM-2 2L2 -2' stroke='green' stroke-width='4.5'/>")
			patternRejectsJ = $("<pattern id='pattern-reject' width='8' height='8' patternUnits='userSpaceOnUse'>")
			patternRejectsJ.append("<path d='M-2 10L10 -2ZM10 6L6 10ZM-2 2L2 -2' stroke='red' stroke-width='4.5'/>")

			defsJ.append(patternValidateJ)
			defsJ.append(patternRejectsJ)
			R.svgJ.prepend(defsJ)
			
			R.svgJ.click((event)=> @selectDrawings(event))

			svgNS = "http://www.w3.org/2000/svg"
			discussionSVG = document.createElementNS(svgNS, "svg")
			discussionSVG.setAttribute('width', R.svgJ.attr('width'))
			discussionSVG.setAttribute('height', R.svgJ.attr('height'))

			discussionGroup = document.createElementNS(svgNS, "g")
			discussionSVG.appendChild(discussionGroup)

			R.discussionJ = $(discussionSVG)
			R.discussionJ.css('position': 'absolute')
			R.discussionJ.css('z-index': 10)
			R.discussionJ.css('pointer-events': 'none')
			R.discussionJ.insertBefore(R.canvasJ)

			# R.discussionJ.css('position': 'absolute')
			# R.discussionJ.css('top': '0')
			# R.discussionJ.css('left': '0')
			# R.discussionJ.css('right': '0')
			# R.discussionJ.css('bottom': '0')
			# R.discussionJ.append('<div id="discussion-view">')
			
			@exquisiteCorpseMask?.createMask()
			

			# check if canvas has an attribute 'data-box'
			# boxString = R.canvasJ.attr("data-box")
			#
			# if not boxString or boxString.length==0
			if not R.loadedBox?
				if not R.initialZoom?
					R.view.fitRectangle(R.view.grid.limitCD.bounds.expand(0), true)
				window?.onhashchange(null, false)
				return

			# initialize the area rectangle *boxRectangle* from 'data-box' attr and move to the center of the box
			# box = JSON.parse( boxString )

			planet = new P.Point(R.loadedBox.planetX, R.loadedBox.planetY)

			# tl = Utils.CS.posOnPlanetToProject(R.loadedBox.box.coordinates[0][0], planet)
			# br = Utils.CS.posOnPlanetToProject(R.loadedBox.box.coordinates[0][2], planet)
			
			tl = R.view.grid.geoJSONToProject(R.loadedBox.box.coordinates[0][0])
			br = R.view.grid.geoJSONToProject(R.loadedBox.box.coordinates[0][2])

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

		contains: (item, tolerance=0)->
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
			if (event.key == 'space' or event.key == ' ') and R.selectedTool?.name != 'Move'
				R.tools.move.select(null, null, null, 'spaceKey')

			if event.key == 'z' and (event.modifiers.control or event.modifiers.meta or event.modifiers.command)
				R.commandManager.undo()
				event.event.preventDefault()
				event.event.stopPropagation()
				return -1

			if event.key == 'y' and (event.modifiers.control or event.modifiers.meta or event.modifiers.command)
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
				when 'space', ' '
					R.previousTool?.select(null, null, null, 'spaceKey')
				when 'v'
					R.tools.select.select()
				when 't'
					R.showToolBox()
				# when 'r'
				# 	# if R.specialKey(event) # Ctrl + R is already used to reload the page
				# 	if event.modifiers.shift R.rasterizer.rasterizeImmediately()

			event.preventDefault()
			return

		# on frame event:
		# - update animatedItems
		# - update cars positions
		onFrame: (event)=>
			# TWEEN.update(event.time)

			# R.rasterizer?.updateLoadingBar?(event.time)

			R.selectedTool?.onFrame?(event)

			for item in R.animatedItems
				item.onFrame(event)

			return

		onWindowResize: (event)=>
			# centerPosition = P.view.viewToProject(P.view.bounds.center)
			centerPosition = P.view.bounds.center

			width = R.stageJ.innerWidth()
			height = R.stageJ.innerHeight()

			R.svgJ.attr('width', width)
			R.svgJ.attr('height', height)
			R.discussionJ.attr('width', width)
			R.discussionJ.attr('height', height)

			R.svgJ.get(0).setAttribute('viewBox', '0,0,'+width+','+height)
			R.discussionJ.get(0).setAttribute('viewBox', '0,0,'+width+','+height)

			P.view.viewSize = new P.Size(width, height)
			
			# update grid and mCustomScrollbar when window is resized
			# R.backgroundCanvas.width = window.innerWidth
			# R.backgroundCanvas.height = window.innerHeight
			# R.backgroundCanvasJ.width(window.innerWidth)
			# R.backgroundCanvasJ.height(window.innerHeight)
			
			
			@grid.update()
			# $(".mCustomScrollbar").mCustomScrollbar("update")
			
			# newCenterPosition = P.view.viewToProject(P.view.bounds.center)
			newCenterPosition = P.view.bounds.center

			@moveBy(centerPosition.subtract(newCenterPosition))

			# R.canvasJ.width(window.innerWidth)
			# R.canvasJ.height(window.innerHeight-50)
			
			
			# R.selectionCanvasJ.width(window.innerWidth)
			# R.selectionCanvasJ.height(window.innerHeight)
			# R.selectionProject.P.view.viewSize = new P.Size(window.innerWidth, window.innerHeight)

			R.toolbar.updateArrowsVisibility()
			R.drawingPanel.onWindowResize()
			R.timelapse?.onWindowResize()
			return

		# mousedown event listener
		mousedown: (event) =>

			moveButton = if event instanceof MouseEvent then 2 else if (TouchEvent? and event instanceof TouchEvent) then 0 else 2

			switch event.which						# switch on mouse button number (left, middle or right click)
				when moveButton
					R.tools.move.select(false, true, null, 'middleMouseButton')		# select move tool if middle mouse button
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

			if R.selectedTool?.name == 'Select' or R.selectedTool == R.tools.choose
				paperEvent = Utils.Event.jEventToPaperEvent(event, @previousMousePosition, @initialMousePosition, 'mousemove')
				R.selectedTool?.move?(paperEvent)

			# Div.updateHiddenDivs(event)

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
			
			R.tracer?.mouseUp()

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
					R.previousTool?.select(null, null, null, 'middleMouseButton')
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
			if event.shiftKey or event.metaKey or event.ctrlKey
				@moveBy(new P.Point(-event.deltaX, event.deltaY))
			return

		# hash format: [repo-owner=repo-owner-name&commit-hash=commit-hash][&city-owner=city-owner&city-name=city-name][&location=location-x,location-y]
		# default values: repo=arthursw:main&city-owner=CommeUnDesseinOrg&city-name=CommeUnDessein&location=0.0,0.0
		# examples: repo-owner=arthursw:247c64eae291e6551646f8785fd19d92333969de&city-owner=John&city-name=Paris&location=100.0,-9850.0

	return View
