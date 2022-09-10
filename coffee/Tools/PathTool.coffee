define ['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'Commands/Command', 'UI/Button', 'i18next' ], (P, R, Utils, Tool, Command, Button, i18next) ->

	# PathTool: the mother class of all drawing tools
	# doctodo: P.Path are created with three steps:
	# - begin: initialize RPath: create the group, controlPath etc., and initialize the drawing
	# - update: update the drawing
	# - end: finish the drawing and finish RPath initialization
	# doctodo: explain polygon mode
	# begin, update, and end handlers are called by onMouseDown handler (then from == R.me, data == null) and by socket.on "begin" signal (then from == author of the signal, data == Item initial data)
	# begin, update, and end handlers emit the events to websocket
	class PathTool extends Tool

		@label = ''
		@description = ''
		@iconURL = ''
		@buttonClasses = 'displayName btn-success'

		@cursor =
			position:
				x: 0, y: 32
			name: 'crosshair'
			icon: if R.style == 'line' then 'mouse_draw' else null

		@drawItems = true

		@emitSocket = false
		@maxDraftSize = 500

		@computeDraftBounds: (paths=null)->
			bounds = R.Drawing.getDraft()?.getBounds()
			# console.log(bounds)
			return bounds

		@draftIsTooBig: (paths=null, tolerance=0)->
			draftBounds = @computeDraftBounds(paths)
			console.log(draftBounds)
			return @draftBoundsIsTooBig(draftBounds, tolerance)

		@draftBoundsIsTooBig: (draftBounds, tolerance=0)->
			return draftBounds? and draftBounds.width > @maxDraftSize * R.city.pixelPerMm - tolerance or draftBounds.height > @maxDraftSize * R.city.pixelPerMm - tolerance

		@displayDraftIsTooBigError: ()->
			R.alertManager.alert 'Your drawing is too big', 'error'
			return

		# Find or create a button for the tool in the sidebar (if the button is created, add it default or favorite tool list depending on the user settings stored in local storage, and whether the tool was just created in a newly created script)
		# set its name and icon if an icon url is provided, or create an icon with the letters of the name otherwise
		# the icon will be made with the first two letters of the name if the name is in one word, or the first letter of each words of the name otherwise
		# @param [RPath constructor] the RPath which will be created by this tool
		# @param [Boolean] whether the tool was just created (with the code editor) or not
		constructor: (@Path, justCreated=false) ->
			@name = @Path.label
			@constructor.label = @name
			
			if @Path.description then @constructor.description = @Path.rdescription
			if @Path.iconURL then @constructor.iconURL = @Path.iconURL
			if @Path.category then @constructor.category = @Path.category
			if @Path.cursor then @constructor.cursor = @Path.cursor

			# delete tool if it already exists (when user creates a tool)
			if justCreated and R.tools[@name]?
				g[@Path.constructor.name] = @Path
				R.tools[@name].remove()
				delete R.tools[@name]
				R.lastPathCreated = @Path

			R.tools[@name] = @

			# check if a button already exists (when created fom a module)
			# @btnJ = R.sidebar.allToolsJ.find('li[data-name="'+@name+'"]')
			@btnJ = R.sidebar.favoriteToolsJ.find('li[data-name="'+@name+'"]')
			
			# create button only if it does not exist
			super(@btnJ.length==0)

			if justCreated
				@select()

			if not R.userAuthenticated?
				R.toolManager.enableDrawingButton(false)
			return

		# Remove tool button, useful when user create a tool which already existed (overwrite the tool)
		remove: () ->
			@btnJ.remove()
			return

		# setButtonValidate: ()->
		# 	newName = i18next.t('Submit drawing')
		# 	@btnJ.find('.tool-name').attr('data-i18n', newName).text(newName)
		# 	@btnJ.find('img').attr('src', '/static/images/icons/inverted/icones_icon_ok.png')
		# 	return
		
		# setButtonDraw: ()->
		# 	newName = i18next.t('Precise path')
		# 	@btnJ.find('.tool-name').attr('data-i18n', newName).text(newName)
		# 	@btnJ.find('img').attr('src', '/static/images/icons/inverted/icones_icon_pen.png')
		# 	return

		# Select: add the mouse move listener on the tool (userful when creating a path in polygon mode)
		# todo: move this to main, have a global onMouseMove handler like other handlers
		select: (deselectItems=true, updateParameters=true, forceSelect=false, selectedBy='default')->
			if R.city?.finished
				R.alertManager.alert "Cette édition est terminée, vous ne pouvez plus dessiner.", 'info'
				return

			if not R.userAuthenticated and not forceSelect
				R.alertManager.alert 'Log in before drawing', 'info'
				return

			# if R.selectedTool != @
			# 	@setButtonValidate()
			# else
			# 	@setButtonDraw()
			# 	R.drawingPanel.submitDrawingClicked()
			# 	return


			# R.rasterizer.drawItems()
			# R.toolbar.toolListJ.addClass('long')

			@showDraftLimits()

			R.tracer?.show()

			super(deselectItems, updateParameters, selectedBy)

			R.view.tool.onMouseMove = @move
			R.toolManager.enterDrawingMode()

			if selectedBy != 'middleMouseButton' and selectedBy != 'spaceKey'

				if @draftLimit?
					if not P.view.bounds.intersects(@draftLimit)
						bounds = R.Drawing.getDraft().getBounds()
						R.view.fitRectangle(bounds, false, if P.view.zoom < 1 then 1 else P.view.zoom)

			if P.view.zoom < 1
				R.alertManager.alert 'You can zoom in to draw more easily', 'info'
			return

		updateParameters: ()->
			# R.controllerManager.setSelectedTool(@Path)
			return

		# Deselect: remove the mouse move listener
		deselect: ()->

			# R.toolbar.toolListJ.removeClass('long')

			# @setButtonDraw()

			super()
			@finish()
			
			# R.tracer?.hide() 			# We need the tracer with the Eraser tool (just guessing)

			@hideDraftLimits()

			R.view.tool.onMouseMove = null
			
			# if R.tracer?.traceAutomatically
			# 	R.tracer.closeRaster()
			
			# R.toolManager.leaveDrawingMode()
			return

		# Begin path action:
		# - deselect all and create new P.Path in all case except in polygonMode (add path to R.currentPaths)
		# - emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse down event
		# @param [String] author (username) of the event
		# @param [Object] Item initial data (strokeWidth, strokeColor, etc.)
		# begin, update, and end handlers are called by onMouseDown handler (then from == R.me, data == null) and by socket.on "begin" signal (then from == author of the signal, data == Item initial data)
		beginBackup: (event, from=R.me, data=null) ->
			if event.event.which == 2 then return 			# if middle mouse button (wheel) pressed: return
			if R.tracer?.draggingImage then return
			
			if P.view.zoom < 0.5
				R.alertManager.alert 'Please zoom before drawing', 'info'
				return

			if @draftLimit? and not @draftLimit.contains(event.point)
				@constructor.displayDraftIsTooBigError()
				bounds = R.Drawing.getDraft()?.getBounds()
				if bounds?
					intersection = R.view.getViewBounds(true).intersect(bounds)
					if intersection.width < 0 || intersection.height < 0 || intersection.area < 10000
						R.view.fitRectangle(bounds, false, if P.view.zoom < 1 then 1 else P.view.zoom)
				return

			# deselect all and create new P.Path in all case except in polygonMode
			if not (R.currentPaths[from]? and R.currentPaths[from].data?.polygonMode) 	# if not in polygon mode
				R.tools.select.deselectAll(false)
				R.currentPaths[from] = new @Path(Date.now(), data, null, null, null, null, R.me)
				# R.currentPaths[from].select(false, false)

				if @circleMode()
					@circlePathRadius = 0.1
					@circlePathCenter = event.point
					if R.drawingMode in R.Path.PrecisePath.snappedModes
						@circlePathCenter = Utils.Snap.snap2D(event.point, if R.drawingMode == 'lineOrthoDiag' then R.Path.PrecisePath.lineOrthoGridSize else R.Path.PrecisePath.orthoGridSize / 2)
					@animateCircle(0, true)
					@animateCircleIntervalID = setInterval(@animateCircle, 150)

			# if event.event.shiftKey
			# 	draft = R.Drawing.getDraft()
			# 	if draft?
			# 		draft.addPaths()
			# 		hitResult = draft.group.hitTest(event.point, { tolerance: 6, segments: true, fill: false, stroke: false, curves: false, handles: false, position: false, bounds: false, guides: false, selected: false })
			# 		if hitResult?.segment?
			# 			@selectedSegment = hitResult.segment
			# 			return

			R.currentPaths[from].beginCreate(event.point, event, false)


			# emit event on websocket (if user is the author of the event)
			# if R.me? and from==R.me then R.socket.emit( "begin", R.me, R.eventToObject(event), @name, R.currentPaths[from].data )

			if @constructor.emitSocket and R.me? and from==R.me
				data = R.currentPaths[from].data
				data.id = R.currentPaths[from].id
				# R.socket.emit "bounce", tool: @name, function: "begin", arguments: [event, R.me, data]

			@using = true
			return

		begin: (event, from=R.me, data=null) ->
			if event.event.which == 2 then return 			# if middle mouse button (wheel) pressed: return
			if R.tracer?.draggingImage then return
			if R.tracer?.tracingAutomatically then return
			
			if P.view.zoom < 0.5
				R.alertManager.alert 'Please zoom before drawing', 'info'
				return
			
			draftIsOutsideFrame = not R.view.contains(event.point)
			if draftIsOutsideFrame
				R.alertManager.alert 'Your path must be in the drawing area', 'error'
				return
			
			if @draftLimit? and not @draftLimit.contains(event.point)
				@constructor.displayDraftIsTooBigError()
				bounds = R.Drawing.getDraft()?.getBounds()
				if bounds?
					intersection = R.view.getViewBounds(true).intersect(bounds)
					if intersection.width < 0 || intersection.height < 0 || intersection.area < 10000
						R.view.fitRectangle(bounds, false, if P.view.zoom < 1 then 1 else P.view.zoom)
				return

			# deselect all and create new P.Path in all case except in polygonMode
			if not @currentPath?
				R.tools.select.deselectAll(false)
				
				@currentPath = new P.Path()
				@currentPath.strokeWidth = @Path.strokeWidth
				@currentPath.strokeColor = R.selectedColor
				@currentPath.strokeCap = 'round'
				@currentPath.strokeJoin = 'round'
				# @currentPath.shadowColor = 'lightblue'
				# @currentPath.shadowBlur = 10
				# @currentPath.shadowOffset = new P.Point(0, 0)
				@currentPath.add(event.point)

			@using = true

			R.socket.emit "draw begin", R.me, event.point
			return

		# circleModeBackup: ()->
		# 	return R.drawingMode == 'line' or R.drawingMode == 'lineOrthoDiag' or R.drawingMode == 'orthoDiag'  or R.drawingMode == 'ortho'

		animateCircleBackup: (time, createCircle=false, from=R.me)=>
			path = R.currentPaths[from]
			if (createCircle or @circlePath?) and path?
				@circlePath?.remove()
				@circlePath = new P.Path.Circle(@circlePathCenter, @circlePathRadius)
				@circlePath.strokeColor = path.data.strokeColor
				@circlePath.strokeWidth = path.data.strokeWidth
				@circlePathRadius += 4
			else
				clearInterval(@animateCircleIntervalID)
				@animateCircleIntervalID = null
			return

		showDraftLimits: ()->
			@hideDraftLimits()

			draftBounds = @constructor.computeDraftBounds()

			path = R.currentPaths[R.me]

			if @currentPath?
				if draftBounds?
					draftBounds = draftBounds.unite(@currentPath.bounds.expand(2 * @Path.strokeWidth))
				else
					draftBounds = @currentPath.bounds.expand(2 * @Path.strokeWidth)
			
			if not draftBounds? or draftBounds.area == 0 then return null

			viewBounds = R.view.grid.frameRectangle
			@draftLimit = draftBounds.expand(2 * (@constructor.maxDraftSize * R.city.pixelPerMm - draftBounds.width), 2 * (@constructor.maxDraftSize  * R.city.pixelPerMm - draftBounds.height))
			
			# draftLimitRectangle = new P.Path.Rectangle(@draftLimit)
			# @limit = R.view.grid.limitCD.clone().subtract(draftLimitRectangle)
			# @limit.fillColor = new P.Color(0,0,0,0.25)

			@limit = new P.Group()

			l1 = new P.Path.Rectangle(viewBounds.topLeft, new P.Point(viewBounds.right, @draftLimit.top))
			l2 = new P.Path.Rectangle(new P.Point(viewBounds.left, @draftLimit.top), new P.Point(@draftLimit.left, @draftLimit.bottom))
			l3 = new P.Path.Rectangle(new P.Point(@draftLimit.right, @draftLimit.top), new P.Point(viewBounds.right, @draftLimit.bottom))
			l4 = new P.Path.Rectangle(new P.Point(viewBounds.left, @draftLimit.bottom), viewBounds.bottomRight)

			@limit.addChild(l1)
			@limit.addChild(l2)
			@limit.addChild(l3)
			@limit.addChild(l4)
			
			for child in @limit.children
				child.fillColor = new P.Color(0,0,0,0.25)

			R.view.selectionLayer.addChild(@limit)
			@limit.sendToBack()

			return @draftLimit
		
		hideDraftLimits: ()->
			if @limit?
				@limit.remove()
			@draftLimit = null
			return

		# Update path action:
		# update path action and emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse drag event
		# @param [String] author (username) of the event
		updateBackup: (event, from=R.me) ->
			
			if @selectedSegment?
				@selectedSegment.point = event.point
				# @selectedSegment.path.controller.path.segments[@selectedSegment.index].point = @selectedSegment.point
				R.selectedPath = @selectedSegment.path.controller
				return

			path = R.currentPaths[from]
			
			if not path? then return 		# when the path has been deleted because too big

			if @circleMode() and @circlePath?
				@circlePath.remove()
				@circlePath = null
				clearInterval(@animateCircleIntervalID)

			draftLimit = @showDraftLimits()

			draftIsTooBig = draftLimit? and not draftLimit.contains(event.point)
			
			draftIsOutsideFrame = not R.view.contains(event.point)

			if draftIsTooBig or draftIsOutsideFrame
				# if path.path?
				# 	@previousPathColor ?= path.path.strokeColor
				# 	path.path.strokeColor = 'red'

				if R.drawingMode != 'line' and R.drawingMode != 'lineOrthoDiag'
					if draftIsTooBig
						@constructor.displayDraftIsTooBigError()
					else if draftIsOutsideFrame
						R.alertManager.alert 'Your path must be in the drawing area', 'error'

					@end(event, from)

					if path.path?
						p = path.path.clone()
						p.strokeColor = 'red'
						R.view.mainLayer.addChild(p)
						setTimeout((()=> p.remove()), 1000)

					@showDraftLimits()

				# lastSegmentToPoint = new P.Path()
				# lastSegmentToPoint.add(path.controlPath.lastSegment)
				# lastSegmentToPoint.add(event.point)
				# draftLimitRectangle = new P.Path.Rectangle(draftLimit.expand(-10))
				# intersections = draftLimitRectangle.getIntersections(lastSegmentToPoint)
				# draftLimitRectangle.remove()
				# lastSegmentToPoint.remove()

				# if intersections.length > 0
				# 	path.updateCreate(intersections[0].point, event, false)
				# 	@constructor.displayDraftIsTooBigError()
				# 	@end(event, from)
				return
			# else if @previousPathColor? and path.path?
			# 	path.path.strokeColor = @previousPathColor

			path.updateCreate(event.point, event, false)

			# R.currentPaths[from].group.visible = true
			# if R.me? and from==R.me then R.socket.emit( "update", R.me, R.eventToObject(event), @name)
			# if @constructor.emitSocket and R.me? and from==R.me then R.socket.emit "bounce", tool: @name, function: "update", arguments: [event, R.me]
			return
		
		showPathError: (event, from=R.me)->

			p = @currentPath.clone()
			p.strokeColor = 'red'
			R.view.mainLayer.addChild(p)
			setTimeout((()=> p.remove()), 1000)

			event.point = @currentPath.lastSegment.point
			@end(event, from)

			@showDraftLimits()

			return
		
		update: (event, from=R.me) ->
			if not @currentPath? then return

			draftLimit = @showDraftLimits()

			draftIsTooBig = draftLimit? and not draftLimit.contains(event.point)
			
			draftIsOutsideFrame = not R.view.contains(event.point)

			if draftIsTooBig or draftIsOutsideFrame

				if draftIsTooBig
					@constructor.displayDraftIsTooBigError()
				else if draftIsOutsideFrame
					R.alertManager.alert 'Your path must be in the drawing area', 'error'
				@showPathError(event, from)

				return

			@currentPath.add(event.point)

			R.socket.emit "draw update", R.me, event.point
			return

		# Update path action (usually from a mouse move event, necessary for the polygon mode):
		# @param [Paper event or REvent] (usually) mouse move event
		moveBackup: (event) ->
			if R.currentPaths[R.me]?.data?.polygonMode then R.currentPaths[R.me].createMove?(event)
			return
		
		move: (event) ->
			return

		# createPath: (event, from)->
		# 	path = R.currentPaths[from]
		# 	if not path? then return 		# when the path has been deleted because too big
		# 	if not path.group then return

		# 	if R.me? and from==R.me 						# if user is the author of the event: select and save path and emit event on websocket

		# 		# if path.rectangle.area == 0
		# 		# 	path.remove()
		# 		# 	delete R.currentPaths[from]
		# 		# 	return

		# 		# bounds = path.getBounds()
		# 		# locks = Lock.getLocksWhichIntersect(bounds)
		# 		# for lock in locks
		# 		# 	if lock.rectangle.contains(bounds)
		# 		# 		if lock.owner == R.me
		# 		# 			lock.addItem(path)
		# 		# 		else
		# 		# 			R.alertManager.alert("The path intersects with a lock", "Warning")
		# 		# 			path.remove()
		# 		# 			delete R.currentPaths[from]
		# 		# 			return
		# 		# if path.getDrawingBounds().area > R.rasterizer.maxArea()
		# 		# 	R.alertManager.alert("The path is too big", "Warning")
		# 		# 	path.remove()
		# 		# 	delete R.currentPaths[from]
		# 		# 	return

		# 		# if @constructor.emitSocket and R.me? and from==R.me then R.socket.emit "bounce", tool: @name, function: "createPath", arguments: [event, R.me]

		# 		if (not R.me?) or not _.isString(R.me)
		# 			R.alertManager.alert("You must log in before drawing, your drawing won't be saved", "Info")
		# 			return


		# 		path.save(true)
		# 		path.rasterize()
		# 		R.rasterizer.rasterize(path)

		# 		R.toolManager.updateButtonsVisibility()

		# 		# path.controlPath.selected = true
		# 	else
		# 		path.endCreate(event.point, event)
		# 	delete R.currentPaths[from]
		# 	return

		# End path action:
		# - end path action
		# - if not in polygon mode: select and save path and emit event on websocket (if user is the author of the event), (remove path from R.currentPaths)
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		# endBackup: (event, from=R.me) ->
		# 	@using = false

		# 	if @selectedSegment?
		# 		@selectedSegment = null
		# 		return

		# 	path = R.currentPaths[from]
		# 	if not path? then return false		# when the path has been deleted because too big
			
		# 	draftLimit = @showDraftLimits()

		# 	if @circlePath?
		# 		R.currentPaths[from].remove()
		# 		delete R.currentPaths[from]
				
		# 		draftIsOutsideFrame = not R.view.contains(@circlePath.bounds)
		# 		draftIsTooBig = @draftLimit? and not @draftLimit.contains(@circlePath.bounds)
				
		# 		if draftIsTooBig
		# 			@constructor.displayDraftIsTooBigError()
		# 			return false
		# 		else if draftIsOutsideFrame
		# 			R.alertManager.alert 'Your path must be in the drawing area', 'error'
		# 			return false
				
		# 		circleLength = @circlePath.getLength()

		# 		path = new @Path(Date.now(), null, null, null, null, null, R.me)
		# 		path.ignoreDrawingMode = true
		# 		path.beginCreate(@circlePath.getPointAt(0), event, false)
		# 		path.controlPath.removeSegments()
		# 		path.controlPath.addSegments(@circlePath.segments)
		# 		path.controlPath.addSegment(@circlePath.firstSegment)
		# 		path.rectangle = path.controlPath.bounds.expand(3*path.data.strokeWidth)
		# 		path.draw()
				
		# 		# step = 10
		# 		# for i in [step .. circleLength] by step
		# 		# 	p = @circlePath.getPointAt(i)
		# 		# 	path.updateCreate(p, event, false)

		# 		# path.endCreate(@circlePath.getPointAt(circleLength), event, false)

		# 		R.currentPaths[from] = path

		# 		@circlePath.remove()
		# 		@circlePath = null
		# 		clearInterval(@animateCircleIntervalID)
		# 		@createPath(event, from)
		# 		R.drawingPanel.showSubmitDrawing()
		# 		return


				

		# 	# if R.view.grid.rectangleOverlapsTwoPlanets(path.controlPath.bounds.expand(path.data.strokeWidth))
		# 	# 	R.alertManager.alert 'Your path must be in the drawing area', 'error'
		# 	# 	R.currentPaths[from].remove()
		# 	# 	delete R.currentPaths[from]
		# 	# 	return false
			
		# 	if @draftLimit? and not @draftLimit.contains(@currentPath.bounds)
		# 		@constructor.displayDraftIsTooBigError()
		# 		@currentPath.remove()
		# 		@currentPath = null
		# 		return false

		# 	path.endCreate(event.point, event, false)

		# 	if not path.data?.polygonMode
		# 		@createPath(event, from)

		# 	R.drawingPanel.showSubmitDrawing()

		# 	return
		
		allPointsAreEqual: (path)->
			firstPoint = path.firstSegment.point
			for segment in path.segments
				if not segment.point.equals(firstPoint)
					return false
			return true
		
		end: (event, from=R.me) ->
			if not @currentPath? then return

			@using = false

			if @currentPath.segments.length > 0
				@currentPath.add(event.point)

			draftLimit = @showDraftLimits()
			
			if @draftLimit? and not @draftLimit.contains(@currentPath.bounds)
				@constructor.displayDraftIsTooBigError()
				@currentPath.remove()
				@currentPath = null
				return false

			draft = R.Item.Drawing.getDraft()

			R.commandManager.add(new Command.ModifyDrawing(draft))

			# Simplify if there is more than one point (a path with twice the same point)	
			if not @allPointsAreEqual(@currentPath)
				@currentPath.simplify(R.simplifyTolerance)

			# @currentPath.smooth()
			draft.addChild(@currentPath, true)

			@currentPath = null

			# R.drawingPanel.showSubmitDrawing()
			R.toolManager.updateButtonsVisibility()

			R.socket.emit "draw end", R.me, event.point
			return

		# Finish path action (necessary in polygon mode):
		# - check that we are in polygon mode (return otherwise)
		# - end path action
		# - select and save path and emit event on websocket (if user is the author of the event), (remove path from R.currentPaths)
		# @param [String] author (username) of the event
		finish: (from=R.me)->
			if not R.currentPaths[R.me]?.data?.polygonMode then return false
			# R.currentPaths[from].finish()
			# @createPath(event, from)
			return true

		keyUp: (event)->
			switch event.key
				when 'enter'
					@finish?()
				when 'escape'
					finishingPath = @finish?()
					if not finishingPath
						R.tools.select.deselectAll()
			return

	R.Tools.Path = PathTool
	
	return PathTool
