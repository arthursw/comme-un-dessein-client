define ['paper', 'R', 'Utils/Utils', 'Items/Item', 'Items/Paths/Path', 'Commands/Command'], (P, R, Utils, Item, Path, Command) ->

	# PrecisePath extends R.RPath to add precise editing functionalities
	# PrecisePath adds control handles to the control path (which can be hidden):
	# one can edit, add or remove points, to precisely shape the curve.
	# The user can edit the curve with the 'Edit Curve' folder of the gui

	# Points of a PrecisePath can have three states:
	# - smooth (default): the handles of the point are always aligned, they are not necessarly of the same size (although they are equal if the user presses the shift key)
	# - corner: the handles of the point are independent, giving the possibility to make sharp corners
	# - point: the point has no handles, it is simple to manipulate

	# A precise path has two modes:
	# - the default mode: handles are editable
	# - the smooth mode: handles are not editable and the control path is [smoothed](http://paperjs.org/reference/path/#smooth)

	# A precise path has two creation modes:
	# - the default mode: a point is added to the control path when the user drags the mouse (at each drag event), resulting in many close points
	# - the polygon mode: a point is added to the control path when the user clicks the mouse, and the last handle is modified when the user drags the mouse

	# # The drawing

	# The drawing is performed as follows:
	# - the control path is divided into a number of steps of fixed size (giving points along the control path at regular intervals)
	# - the drawing is updated at each of those points
	# - to have better results, the remaining step (which is shorter) is split in half and distributed among the first and last step
	# - the size of the steps is data.step, and can be added in the gui
	# - during the drawing process, the *offset* property corresponds to the current position along the control path where the drawing must be updated
	#   (offset can be seen as the length of the drawing along the path)

	# For example the simplest precise path is as a set of points regularly distributed along the control path;
	# a more complexe precise path would also be function of the normal and the tangent of the control point at each point.

	# The drawing is performed with three methods:
	# - beginDraw() called to initialize the drawing,
	# - updateDraw() called at each update,
	# - endDraw() called at the end of the drawing.

	# There are two cases where precise path is created:
	# - when the user creates the path with the mouse:
	#     - each time a new P.Point is added to the control path:
	#       updateDraw() is called to continue the drawing along the control path until *offset* (the length of the drawing) equals the control path length (minus the remaining step)
	#       this process takes place in {PrecisePath#checkUpdateDrawing} (it is overridden by {SpeedPath#checkUpdateDrawing})
	#       it is part of the beginCreate/Update/End() process
	# - when the path is loaded (or when the control path exists):
	#     - the remaining step (which is shorter) is split in half and distributed among the first and last step
	#     - updateDraw() is called in a loop to draw the whole drawing along the control path at once, in {PrecisePath#draw}

	class PixelPath extends Path
		@label = 'Pixel path'
		@description = "This draws a pattern at each pixel of the path."
		@iconURL = 'glyphicon-pencil'

		@orthoGridSize = 10

		@initializeParameters: ()->

			parameters = super()
			return parameters

		@parameters = @initializeParameters()
		@createTool(@)

		@getPointsFromPath: (path)->
			points = []
			for segment in path.segments
				points.push(Utils.CS.projectToPosOnPlanet(segment.point))
			return points

		@getPointsAndPlanetFromPath: (path)->
			return planet: @getPlanetFromPath(path), points: @getPointsFromPath(path)

		# get data, usually to save the RPath (some information must be added to data)
		# the control path is stored in @data.points and @data.planet
		@getDataFromPath: (path)->
			data = {}
			data.planet = @getPlanetFromPath(path)
			data.points = @getPointsFromPath(path)
			return data

		# overload {RPath#constructor}
		constructor: (@date=null, @data=null, @id=null, @pk=null, points=null, @lock=null, @owner=null, @drawingId=null) ->
			super(@date, @data, @id, @pk, points, @lock, @owner, @drawingId)
			return

		setControlPath: (points, planet)->
			for point, i in points
				@controlPath.add(Utils.CS.posOnPlanetToProject(point, planet))
			return

		# redefine {RPath#loadPath}
		# load control path from @data.points and check if *points* fit to the created control path
		loadPath: (points)->
			# load control path from @data.points

			@addControlPath()
			@setControlPath(@data.points, @data.planet)
			@rectangle = @controlPath.bounds.clone()

			R.rasterizer.loadItem(@)

			if not @constructor.securePath
				return

			return

		performHitTest: (point, options=@constructor.hitOptions)->
			@controlPath.visible = true
			hitResult = @controlPath.hitTest(point, options)
			@controlPath.visible = false
			return hitResult

		# default beginDraw function, will be redefined by children PrecisePath
		# @param redrawing [Boolean] (optional) whether the path is being redrawn or the user draws the path (the path is being loaded/updated or the user is drawing it with the mouse)

		beginDraw: (redrawing=false)->
			@initializeDrawing(false)
			return

		# default updateDraw function, will be redefined by children PrecisePath
		# @param offset [Number] the offset along the control path to begin drawing
		# @param step [Boolean] whether it is a key step or not (we must draw something special or not)
		updateDraw: (segment, step, redrawing)->
			circle = @addPath(new P.Path.Circle(segment.point, @data.strokeWidth/16))
			circle.fillColor = @data.strokeColor
			return

		# default endDraw function, will be redefined by children PrecisePath
		# @param redrawing [Boolean] (optional) whether the path is being redrawn or the user draws the path (the path is being loaded/updated or the user is drawing it with the mouse)
		endDraw: (redrawing=false)->

			# while @path.segments.length > @controlPath.segments.length
				# @path.removeSegment(@path.segments.length-1)
			return

		checkUpdateDrawing: (segment, redrawing=true)->
			@updateDraw(segment)
			return

		# continue drawing the path along the control path if necessary:
		# - the drawing is performed every *@data.step* along the control path
		# - each time the user adds a point to the control path (either by moving the mouse in normal mode, or by clicking in polygon mode)
		#   *checkUpdateDrawing* check by how long the control path was extended, and calls @updateDraw() if some draw step must be performed
		# called when creating the path (by @updateCreate() and @finish()) and in @draw()
		# @param segment [Paper P.Segment] the segment on the control path where we want to updateDraw
		# @param redrawing [Boolean] (optional) whether the path is being redrawn or the user draws the path (the path is being loaded/updated or the user is drawing it with the mouse)
		#
		# checkUpdateDrawing: (segment, redrawing=true)->
		# 	step = @data.step
		# 	controlPathOffset = segment.location.offset
		#
		# 	while @drawingOffset+step<controlPathOffset
		# 		@drawingOffset += step
		# 		@updateDraw(@drawingOffset, true, redrawing)
		#
		# 	if @drawingOffset+step>controlPathOffset 	# we can not make a step between drawingOffset and the controlPathOffset
		# 		@updateDraw(controlPathOffset, false, redrawing)
		#
		# 	return

		# redefine {RPath#beginCreate}
		# begin create action:
		# initialize the control path and draw begin
		# called when user press mouse down, or on loading
		# @param point [P.Point] the point to add
		# @param event [Event] the mouse event
		beginCreate: (point, event)->
			super()
			console.log('beginCreate')

			@addControlPath()
			@controlPath.add(Utils.Snap.snap2D(point, @constructor.orthoGridSize))
			@rectangle = @controlPath.bounds.clone()
			@beginDraw(false)
			return

		# redefine {RPath#updateCreate}
		# update create action:
		# in normal mode:
		# - check if path is not in an Lock
		# - add point
		# - @checkUpdateDrawing() (i.e. continue the draw steps to fit the control path)
		# in polygon mode:
		# - update the [handleIn](http://paperjs.org/reference/segment/#handlein) and handleOut of the last segment
		# - draw in simplified (quick) mode
		# called on mouse drag
		# @param point [P.Point] the point to add
		# @param event [Event] the mouse event
		updateCreate: (point, event)->

			if @controlPath.lastSegment.point.getDistance(point, true) < 20
				return

			console.log('updateCreate')
			target = Utils.Snap.snap2D(point, @constructor.orthoGridSize)
			@controlPath.add(target)

			@checkUpdateDrawing(@controlPath.lastSegment, false)

			return

		# update create action: only used when in polygon mode
		# move the last point of the control path to the mouse position and draw in simple/quick mode
		# called on mouse move
		# @param event [Event] the mouse event
		createMove: (event)->
			@controlPath.lastSegment.point = event.point
			console.log 'create move'
			@draw(true, false)
			return

		# redefine {RPath#endCreate}
		# end create action:
		# - in polygon mode: just finish the path (@finiPath())
		# - in normal mode: compute speed, simplify path and update speed (necessary for SpeedPath) and finish path
		# @param point [P.Point] the point to add
		# @param event [Event] the mouse event
		endCreate: (point, event)->
			if @data.polygonMode then return 	# in polygon mode, finish is called by the path tool

			console.log('endCreate')
			@finish()
			super()

			return

		# finish path creation:
		# @param loading [Boolean] (optional) whether the path is being loaded or being created by user
		finish: ()->

			if @controlPath.segments.length<2
				@updateCreate(@controlPath.firstSegment.point.add(new P.Point(0.25,0.25)), null)
			
			@endDraw()
			
			@draw() # redraw to get clean path

			@drawingOffset = 0

			@rectangle = @controlPath.bounds.clone()

			# if loading and @canvasRaster
			# 	@draw(false, true) 	# enable to have the correct @canvasRaster size and to have the exact same result after a load or a change

			if not super() then return false

			@initialize()

			return true

		processDrawing: (redrawing)->
			@beginDraw(redrawing)

			for segment, i in @controlPath.segments
				if i==0 then continue
				@checkUpdateDrawing(segment, redrawing)

			@endDraw(redrawing)
			return

		# update the appearance of the path (the drawing group)
		# called anytime the path is modified:
		# by beginCreate/Update/End, updateSelect/End, parameterChanged, deletePoint, changePoint etc. and loadPath
		# - begin drawing (@beginDraw())
		# - update drawing (@updateDraw()) every *step* along the control path
		# - end drawing (@endDraw())
		# because the path are rendered on rasters, path are not drawn on load unless they are animated
		# @param simplified [Boolean] whether to draw in simplified mode or not (much faster)
		draw: (simplified=false, redrawing=true)->

			if @drawn then return

			if not R.rasterizer.requestDraw(@, simplified, redrawing) then return
			# if R.rasterizer.disableDrawing then return

			if @controlPath.segments.length < 2 then return

			if simplified then @simplifiedModeOn()

			@drawingOffset = 0

			try 	# catch errors to log them in the code editor console (if user is making a script)
				@processDrawing(redrawing)
			catch error
				console.error error.stack
				console.error error
				throw error

			if simplified
				@simplifiedModeOff()

			@drawn = true

			return

		# @return [Array of Paper point] a list of point from the control path converted in the planet coordinate system
		pathOnPlanet: ()->
			flatennedPath = @controlPath.copyTo(P.project)
			flatennedPath.flatten(@constructor.secureStep)
			flatennedPath.remove()
			return super(flatennedPath.segments)

		getPoints: ()->
			points = []
			for segment in @controlPath.segments
				points.push(Utils.CS.projectToPosOnPlanet(segment.point))
				points.push(Utils.CS.pointToObj(segment.handleIn))
				points.push(Utils.CS.pointToObj(segment.handleOut))
				points.push(segment.rtype)
			return points

		getPointsAndPlanet: ()->
			return planet: @getPlanet(), points: @getPoints()

		# get data, usually to save the RPath (some information must be added to data)
		# the control path is stored in @data.points and @data.planet
		getData: ()->
			@data.planet = @getPlanet()
			@data.points = @getPoints()
			return @data

		# @see RPath.select
		# - bring control path to front and select it
		# - call RPath.select
		# @param updateOptions [Boolean] whether to update gui parameters with this RPath or not
		select: (updateOptions=true)->
			if not super(updateOptions) then return
			@controlPath.selected = true
			if not @data.smooth then @controlPath.fullySelected = true
			return true

		# @see RPath.deselect
		# deselect control path, remove selection highlight (@see PrecisePath.highlightSelectedPoint) and call RPath.deselect
		deselect: (updateOptions=true)->
			if not super(updateOptions) then return false
			# P.project.activeLayer.insertChild(@index, @controlPath)
			# control path can be null if user is removing the path
			@controlPath?.selected = false
			@removeSelectionHighlight()
			return true

		# highlight selection path point:
		# draw a shape behind the selected point to be able to move and modify it
		# the shape is a circle if point is 'smooth', a square if point is a 'corner' and a triangle otherwise
		highlightSelectedPoint: ()->
			if not @controlPath.selected then return
			@removeSelectionHighlight()
			if not @selectedSegment? then return
			point = @selectedSegment.point
			@selectedSegment.rtype ?= 'smooth'
			switch @selectedSegment.rtype
				when 'smooth'
					@selectionHighlight = new P.Path.Circle(point, 5)
				when 'corner'
					offset = new P.Point(5, 5)
					@selectionHighlight = new P.Path.Rectangle(point.subtract(offset), point.add(offset))
				when 'point'
					@selectionHighlight = new P.Path.RegularPolygon(point, 3, 5)
			@selectionHighlight.name = 'selection highlight'
			@selectionHighlight.controller = @
			@selectionHighlight.strokeColor = R.selectionBlue
			@selectionHighlight.strokeWidth = 1
			R.view.selectionLayer.addChild(@selectionHighlight)
			# R.controllerManager.getController('Edit curve', 'pointType')?.setValue(@selectedSegment.rtype)
			# @constructor.parameters['Edit curve'].pointType.controller.setValue(@selectedSegment.rtype)
			return

		updateSelectionHighlight: ()->
			if @selectedSegment? and @selectionHighlight then @selectionHighlight.position = @selectedSegment.point
			# @selectionHighlight.bringToFront()
			return

		removeSelectionHighlight: ()->
			@selectionHighlight?.remove()
			@selectionHighlight = null
			return

		# # redefine {RPath#initializeSelection}
		# # Same functionnalities as {RPath#initializeSelection} (determine which action to perform depending on the the *hitResult*) but:
		# # - adds handle selection initialization, and highlight selected points if any
		# # - properly initialize transformation (rotation and scale) for PrecisePath
		# initializeSelection: (event, hitResult) ->
		# 	super(event, hitResult)
		#
		# 	specialKey = R.specialKey(event)
		#
		# 	if hitResult.type == 'segment'
		#
		# 		if specialKey and hitResult.item == @controlPath
		# 			@selectionState = segment: hitResult.segment
		# 			@deletePointCommand()
		# 		else
		# 			if hitResult.item == @controlPath
		# 				@selectionState = segment: hitResult.segment
		#
		# 	if not @data.smooth
		# 		if hitResult.type is "handle-in"
		# 			@selectionState = segment: hitResult.segment, handle: hitResult.segment.handleIn
		# 		else if hitResult.type is "handle-out"
		# 			@selectionState = segment: hitResult.segment, handle: hitResult.segment.handleOut
		#
		# 	@highlightSelectedPoint()
		#
		# 	return

		# begin select action
		# @param event [Paper event] the mouse event
		# beginSelect: (event) ->
		#
		# 	@selectionHighlight?.remove()
		# 	@selectionHighlight = null
		#
		# 	super(event)
		#
		# 	if @selectedSegment?
		# 		R.commandManager.beginAction(new Command.ModifyPoint(@))
		# 	else if @selectionState.speedHandle?
		# 		R.commandManager.beginAction(new Command.ModifySpeed(@))
		#
		# 	return
		#
		# updateSelect: (event)->
		# 	# if not @drawing then R.updateView()
		# 	super(event)
		# 	return

		# add or update the selection rectangle (path used to rotate and scale the RPath)
		# @param reset [Boolean] (optional) true if must reset the selection rectangle (one of the control path segment has been modified)
		# updateSelectionRectangle: (reset=false)->
		# 	if reset
		# 		# reset transform matrix to have @controlPath.rotation = 0 and @controlPath.scaling = 1,1
		# 		@controlPath.firstSegment.point = @controlPath.firstSegment.point
		# 		@rectangle = @controlPath.bounds.clone()
		# 		@rotation = 0
		#
		# 	super()
		#
		# 	# @controlPath.pivot = @selectionRectangle.pivot
		#
		# 	# @selectionRectangle.selected = @data.showSelectionRectangle
		# 	# @selectionRectangle.visible = @data.showSelectionRectangle
		# 	return
		#
		# scale: (scale, center, update)->
		# 	@controlPath.scale(scale, center)
		# 	return

		moveTo: (position, update)->
			super(position, update)
			@updateSelectionHighlight()
			return

		setRectangle: (rectangle, update)->
			previousRectangle = @rectangle.clone()
			super(rectangle, update)
			@controlPath.pivot = previousRectangle.center
			@controlPath.rotate(-@rotation)
			@controlPath.scale(@rectangle.width/previousRectangle.width, @rectangle.height/previousRectangle.height)
			# @controlPath.position = @selectionRectangle.pivot
			# @controlPath.pivot = @selectionRectangle.pivot
			@controlPath.position = @rectangle.center.clone()
			@controlPath.pivot = @rectangle.center.clone()
			@controlPath.rotate(@rotation)

			@updateSelectionHighlight()
			return

		setRotation: (rotation, center, update)->
			super(rotation, center, update)
			@updateSelectionHighlight()
			return

		# smooth the point of *segment*, i.e. align the handles with the tangent at this point
		# @param segment [Paper P.Segment] the segment to smooth
		# @param offset [Number] (optional) the location of the segment (default is segment.location.offset)
		smoothPoint: (segment, offset)->
			segment.rtype = 'smooth'
			segment.linear = false

			offset ?= segment.location.offset
			tangent = segment.path.getTangentAt(offset)
			if segment.previous? then segment.handleIn = tangent.multiply(-0.25)
			if segment.next? then segment.handleOut = tangent.multiply(+0.25)

			# a second version of the smooth
			# if segment.previous? and segment.next?
			# 	delta = segment.next.point.subtract(segment.previous.point)
			# 	deltaN = delta.normalize()
			# 	previousToSegment = segment.point.subtract(segment.previous.point)
			# 	h = 0.5*deltaN.dot(previousToSegment)/delta.length
			# 	segment.handleIn = delta.multiply(-h)
			# 	segment.handleOut = delta.multiply(0.5-h)
			# else if segment.previous?
			# 	previousToSegment = segment.point.subtract(segment.previous.point)
			# 	segment.handleIn = previousToSegment.multiply(0.5)
			# else if segment.next?
			# 	nextToSegment = segment.point.subtract(segment.next.point)
			# 	segment.handleOut = nextToSegment.multiply(-0.5)
			return

		# double click event handler:
		# if we click on a point:
		# - roll over the three point modes (a 'smooth' point will become 'corner', a 'corner' will become 'point', and a 'point' will be deleted)
		# else if we clicked on the control path:
		# - create a point at *event* position
		# @param event [jQuery or Paper event] the mouse event
		doubleClick: (event)->
			# warning: event can be a jQuery event instead of a paper event

			# check if user clicked on the curve

			point = P.view.viewToProject(Utils.Event.GetPoint(event))
			hitResult = @performHitTest(point)

			# return if user did not click on the curve
			if not hitResult? then return

			switch hitResult.type
				when 'segment' 										# if we click on a point: roll over the three point modes

					segment = hitResult.segment
					@selectedSegment = segment

					switch segment.rtype
						when 'smooth', null, undefined
							@modifySelectedPointType('corner')
						when 'corner'
							@modifySelectedPointType('point')
						when 'point'
							@deletePointCommand()
						else
							console.log "segment.rtype not known."

				when 'stroke', 'curve' 								# else if we clicked on the control path: create a point at *event* position
					@addPointCommand(hitResult.location)

			return

		addPointCommand: (location)->
			R.commandManager.add(new Command.AddPoint(@, location), true)
			return

		addPointAt: (location, update=true)->
			if not P.CurveLocation.prototype.isPrototypeOf(location) then location = @controlPath.getLocationAt(location)
			return @addPoint(location.index, location.point, location.offset, update)

		# add a point according to *hitResult*
		# @param location [Paper Location] the location where to add the point
		# @param update [Boolean] whether update is required
		# @return the new P.Segment
		addPoint: (index, point, offset, update=true)->

			segment = @controlPath.insert(index + 1, new P.Point(point))

			if @data.smooth
				@controlPath.smooth()
			else
				@smoothPoint(segment, offset)

			@draw()
			if not @socketAction
				segment.selected = true
				@selectedSegment = segment
				@highlightSelectedPoint()
				if update then @update('point')
				R.socket.emit "bounce", itemId: @id, function: "addPoint", arguments: [index, point, offset, false]
			return segment

		deletePointCommand: ()->
			if not @selectedSegment? then return
			R.commandManager.add(new Command.DeletePoint(@, @selectedSegment), true)
			return

		# delete the point of *segment* (from curve) and delete curve if there are no points anymore
		# @param segment [Paper P.Segment or segment index] the segment to delete
		# @return the location of the deleted point (to be able to re-add it in case of a undo)
		deletePoint: (segment, update=true)->
			if not segment then return
			if not P.Segment.prototype.isPrototypeOf(segment) then segment = @controlPath.segments[segment]
			@selectedSegment = if segment.next? then segment.next else segment.previous
			if @selectedSegment? then @highlightSelectedPoint()
			location = { index: segment.location.index - 1, point: segment.location.pointÂ }
			segment.remove()
			if @controlPath.segments.length <= 1
				@deleteCommand()
				return
			if @data.smooth then @controlPath.smooth()
			@draw()
			if not @socketAction
				R.tools.select.updateSelectionRectangle()
				if update then @update('point')
				R.socket.emit "bounce", itemId: @id, function: "deletePoint", arguments: [segment.index, false]
			return location

		# delete the selected point (from curve) and delete curve if there are no points anymore
		# emit the action to websocket
		deleteSelectedPoint: ()->
			@deletePoint(@selectedSegment)
			return

		# change selected segment position and handle position
		# @param position [Paper P.Point] the new position
		# @param handleIn [Paper P.Point] the new handle in position
		# @param handleOut [Paper P.Point] the new handle out position
		# @param update [Boolean] whether we must update the path (for example when it is a command) or not
		# @param draw [Boolean] whether we must draw the path or not
		modifySelectedPoint: (position, handleIn, handleOut, fastDraw=true, update=true)->
			@modifyPoint(@selectedSegment, position, handleIn, handleOut, fastDraw, update)
			return

		modifyPoint: (segment, position, handleIn, handleOut, fastDraw=true, update=true)->
			if not P.Segment.prototype.isPrototypeOf(segment) then segment = @controlPath.segments[segment]
			segment.point = new P.Point(position)
			segment.handleIn = new P.Point(handleIn)
			segment.handleOut = new P.Point(handleOut)
			@rectangle = @controlPath.bounds.clone()
			R.tools.select.updateSelectionRectangle()
			@draw(fastDraw)
			if not @selectionHighlight?
				@highlightSelectedPoint()
			else
				@updateSelectionHighlight()

			if not @socketAction
				if update then @update('segment')
				R.socket.emit "bounce", itemId: @id, function: "modifyPoint", arguments: [segment.index, position, handleIn, handleOut, fastDraw, false]
			return

		updateModifyPoint: (event)->
			# segment.rtype == null or 'smooth': handles are aligned, and have the same length if shit
			# segment.rtype == 'corner': handles are not equal
			# segment.rtype == 'point': no handles
			segment = @selectedSegment
			handle = @selectedHandle

			if handle? 									# move the selected handle

				if Utils.Snap.getSnap() >= 1
					point = Utils.Snap.snap2D(event.point)
					handle.x = point.x - segment.point.x
					handle.y = point.y - segment.point.y
				else
					handle.x += event.delta.x
					handle.y += event.delta.y

				if segment.rtype == 'smooth' or not segment.rtype?
					if handle == segment.handleOut and not segment.handleIn.isZero()
						if not event.modifiers.shift
							segment.handleIn = segment.handleOut.normalize().multiply(-segment.handleIn.length)
						else
							segment.handleIn = segment.handleOut.multiply(-1)
					if handle == segment.handleIn and not segment.handleOut.isZero()
						if not event.modifiers.shift
							segment.handleOut = segment.handleIn.normalize().multiply(-segment.handleOut.length)
						else
							segment.handleOut = segment.handleIn.multiply(-1)

			else if segment?								# move the selected point

				if Utils.Snap.getSnap() >= 1
					point = Utils.Snap.snap2D(event.point)
					segment.point.x = point.x
					segment.point.y = point.y
				else
					segment.point.x += event.delta.x
					segment.point.y += event.delta.y

			Item.Lock.highlightValidity(@, null, true)
			@modifyPoint(segment, segment.point, segment.handleIn, segment.handleOut, true, false)

			return

		endModifyPoint: (update)->
			if update
				if @data.smooth then @controlPath.smooth()
				@draw()
				@rasterize()
				@selectionHighlight?.bringToFront()
				@update('points')
			return

		modifyPointTypeCommand: (rtype)->
			R.commandManager.add(new Command.ModifyPointType(@, @selectedSegment, rtype), true)
			return

		modifySelectedPointType: (value, update=true)->
			if not @selectedSegment? then return
			@modifyPointType(@selectedSegment, value, update)
			return

		# - set selected point mode to *rtype*: 'smooth', 'corner' or 'point'
		# - update the selected point highlight
		# - emit action to websocket
		# @param rtype [String] new mode of the point: can be 'smooth', 'corner' or 'point'
		# @param update [Boolean] whether update is required
		modifyPointType: (segment, rtype, update=true)->
			if not P.Segment.prototype.isPrototypeOf(segment) then segment = @controlPath.segments[segment]
			if @data.smooth then return
			@selectedSegment.rtype = rtype
			switch rtype
				when 'corner'
					if @selectedSegment.linear = true
						@selectedSegment.linear = false
						@selectedSegment.handleIn = if @selectedSegment.previous? then @selectedSegment.previous.point.subtract(@selectedSegment.point).multiply(0.5) else null
						@selectedSegment.handleOut = if @selectedSegment.next? then @selectedSegment.next.point.subtract(@selectedSegment.point).multiply(0.5) else null
				when 'point'
					@selectedSegment.linear = true
				when 'smooth'
					@smoothPoint(@selectedSegment)
			@draw()
			@highlightSelectedPoint()
			if not @socketAction
				if update then @update('point')
				R.socket.emit "bounce", itemId: @id, function: "modifyPointType", arguments: [segment.index, rtype, false]
			return

		modifyControlPathCommand: (previousPointsAndPlanet, newPointsAndPlanet)->
			R.commandManager.add(new Command.ModifyControlPath(@, previousPointsAndPlanet, newPointsAndPlanet), false)
			return

		modifyControlPath: (pointsAndPlanet, update=true)->
			selected = @controlPath.selected
			fullySelected = @controlPath.fullySelected
			@controlPath.removeSegments()
			@setControlPath(pointsAndPlanet.points, pointsAndPlanet.planet)
			@controlPath.selected = selected
			if fullySelected then @controlPath.fullySelected = true
			@deselectPoint()
			@draw()
			if not @socketAction
				if update then @update('point')
				R.socket.emit "bounce", itemId: @id, function: "modifyControlPath", arguments: [pointsAndPlanet, false]
			return

		setSmooth: (smooth)->
			@data.smooth = smooth
			if @data.smooth
				previousPointsAndPlanet = @getPointsAndPlanet()
				@controlPath.smooth()
				@controlPath.fullySelected = false
				@controlPath.selected = true
				@deselectPoint()
				for segment in @controlPath.segments
					segment.rtype = 'smooth'
				@draw()
				@modifyControlPathCommand(previousPointsAndPlanet, @getPointsAndPlanet())
			else
				@controlPath.fullySelected = true
				@highlightSelectedPoint()
			return

		simplifyControlPath: ()->
			previousPointsAndPlanet = @getPointsAndPlanet()

			@controlPath?.simplify()
			@draw()
			@update()

			@modifyControlPathCommand(previousPointsAndPlanet, @getPointsAndPlanet())
			return

		# overload {RPath#parameterChanged}, but update the control path state if 'smooth' was changed
		# called when a parameter is changed
		setParameter: (name, value, updateGUI, update)->
			super(name, value, updateGUI, update)
			# switch name
			# 	when 'showSelectionRectangle'
			# 		@selectionRectangle?.selected = @data.showSelectionRectangle
			# 		@selectionRectangle?.visible = @data.showSelectionRectangle
			return

		# overload {RPath#remove}, but in addition: remove the selected point highlight and the canvas raster
		remove: ()->
			console.log("Remove precise path")
			@canvasRaster?.remove()
			@canvasRaster = null
			if @liJ?
				@removeFromListItem()
			super()
			return

	Item.PrecisePath = PrecisePath
	return PrecisePath
