define ['paper', 'R', 'Utils/Utils', 'Items/Item', 'Items/Content', 'Tools/PathTool', 'Commands/Command' ], (P, R, Utils, Item, Content, PathTool, Command) ->

	# todo: Actions, undo & redo...
	# todo: strokeWidth min = 0?
	# todo change bounding box selection
	# todo/bug?: if @data? but not @data.id? then @id is not initialized, causing a bug when saving..
	# todo: have a selectPath (simplified version of group to test selection)instead of the group ?
	# todo: replace smooth by rsmooth and rdata in general.

	# important todo: pass args in deferred exec to update 'points' or 'data'

	# RPath: mother of all commeUnDessein paths
	# A commeUnDessein path (RPath) is a path made of the following items:
	# - a control path, with which users will interact
	# - a drawing group (the drawing) containing all visible items built around the control path (it must follow the control path)
	# - a selection group (containing a selection path) when the RPath is selected; it enables user to scale and rotate the RPath
	# - a group (main group or *group*) which contains all of the previous items

	# There are three main RPaths:
	# - PrecisePath adds control handles to the control path (which can be hidden): one can edit, add or remove points, to precisely shape the curve.
	# - SpeedPath which extends StepPath to add speed functionnalities:
	#    - the speed at which the user has drawn the path is stored and has influence on the drawing,
	#    - the speed values are displayed as normals of the path, and can be edited thanks to handles
	#    - when the user drags a handle, it will also influence surrounding speed values depending on how far from the normal the user drags the handle (with a gaussian attenuation)
	#    - the speed path and handles are added to a speed group, which is added to the main group
	#    - the speed group can be shown or hidden
	# - RShape defined by a rectangle in which the drawing should be included (the user draws the rectangle with the mouse)

	# Those three RPaths (PrecisePath, SpeedPath and RShape) provide drawing functionnalities and are meant to be overridden to generate some advanced paths:
	# - in PrecisePath and SpeedPath, three methods are meant to be overridden: beginDraw, updateDraw and endDraw,
	#   see {PrecisePath} to see how those methods are called while drawing.
	# - in RShape, {RShape#createShape} is meant to be overloaded

	# Parameters:
	# - parameters are defined as in RTools
	# - all data related to the parameters (and state) of the RPath is stored under the @data property
	# - dy default, when a parameter is chanegd in the gui, onParameterChange is called

	# tododoc: loadPath will call create begin, update, end
	# todo-doc: explain Id?

	# Notable differences between RPath:
	# - in regular path: when transforming a path, the points of the control path are resaved with their new positions; no transform information is stored
	# - in RShape: the rectangle  is never changed with transformations; instead the rotation and scale are stored in @data and taken into account at each draw

	class Path extends Content
		@label = 'Pen' 										# the name used in the gui (to create the button and for the tooltip/popover)
		@description = "The classic and basic pen tool" 	# the path description
		# @cursor =
		# 	position:
		# 		x: 0, y: 0
		# 	name: 'crosshair'
		@constructor.secureDistance = 2 					# the points of the flattened path must not be 5 pixels away from the recorded points

		@colorMap = {
			draft: '#808080',
			pending: '#005fb8',
			emailNotConfirmed: '#005fb8',
			notConfirmed: '#E91E63',
			drawing: '#11a74f',
			drawn: 'black',
			test: 'purple',
			rejected: '#EB5A46',
			flagged: '#EE2233'
		}

		@strokeWidth = R.strokeWidth or Utils.CS.mmToPixel(7)
		@strokeColor = 'black'

		# parameters are defined as in {RTool}
		# The following parameters are reserved for commeUnDessein: id, polygonMode, points, planet, step, smooth, speeds, showSpeeds
		@initializeParameters: ()->
			parameters = super()
			parameters['Items'].duplicate = R.parameters.duplicate
			# parameters['Items'].editTool =
			# 	type: 'button'
			# 	label: 'Edit tool'
			# 	default: ()=> return #R.codeEditor.setSource(@source)
			delete parameters['Style']
			# parameters['Style'].strokeWidth = Utils.clone(R.parameters.strokeWidth)
			# parameters['Style'].strokeColor = Utils.clone(R.parameters.strokeColor)
			# parameters['Style'].fillColor = Utils.clone(R.parameters.fillColor)
			# parameters['Shadow'] =
			# 	folderIsClosedByDefault: true
			# 	shadowColor:
			# 		type: 'color'
			# 		label: 'Shadow color'
			# 		default: '#000'
			# 		defaultCheck: false
			# 	shadowOffsetX:
			# 		type: 'slider'
			# 		label: 'Shadow offset x'
			# 		min: -25
			# 		max: 25
			# 		default: 0
			# 	shadowOffsetY:
			# 		type: 'slider'
			# 		label: 'Shadow offset y'
			# 		min: -25
			# 		max: 25
			# 		default: 0
			# 	shadowBlur:
			# 		type: 'slider'
			# 		label: 'Shadow blur'
			# 		min: 0
			# 		max: 50
			# 		default: 0
			return parameters

		@parameters = @initializeParameters()

		@createTool: (Path)->
			new R.Tools.Path(Path)
			return

		@create: (duplicateData)->
			duplicateData ?= @getDuplicateData()
			copy = new @(duplicateData.date, duplicateData.data, duplicateData.id, null, duplicateData.points, duplicateData.lock, duplicateData.owner)
			copy.draw()
			if not @socketAction
				copy.save(false)
				# R.socket.emit "bounce", itemClass: @name, function: "create", arguments: [duplicateData]
			return copy
		
		# @return [P.Point] the planet on which the path lies
		@getPlanetFromPath: (path)->
			return Utils.CS.projectToPlanet( path.segments[0].point )
		
		@pathOnPlanetFromPath: (path)->
			points = []
			planet = @getPlanetFromPath(path)
			for segment in path.segments
				p = Utils.CS.projectToPosOnPlanet(segment.point, planet)
				points.push( Utils.CS.pointToArray(p) )
			return points

		# Create the RPath and initialize the drawing creation if a user is creating it, or draw if the path is being loaded
		# When user creates a path, the path is given an identifier (@id); when the path is saved, the servers returns a primary key (@pk) and @id will not be used anymore
		# @param date [Date] (optional) the date at which the path has been crated (will be used as z-index in further versions)
		# @param data [Object] (optional) the data containing information about parameters and state of RPath
		# @param pk [Id] (optional) the primary key of the path in the database
		# @param points [Array of P.Point] (optional) the points of the controlPath, the points must fit on the control path (the control path is stored in @data.points)
		# @param lock [Lock] the lock which contains this RPath (if any)
		constructor: (@date=null, @data=null, @id=null, @pk=null, points=null, @lock=null, @owner=null, @drawingId=null) ->
			if not @lock
				super(@data, @id, @pk, @date, R.sidebar.pathListJ, R.sortedPaths)
			else
				super(@data, @id, @pk, @date, @lock.itemListsJ.find('.rPath-list'), @lock.sortedPaths)

			R.paths[@id] = @
			
			if not @drawingId?
				@addToListItem()
			else

				if R.items[@drawingId]?
					drawing = R.items[@drawingId]
					drawing.addChild(@)

			@selectionHighlight = null

			@data.strokeWidth = @constructor.strokeWidth
			# @data.strokeColor = @constructor.strokeColor
			@data.fillColor = null

			if points?
				@loadPath(points)

			return

		containingLayer: ()->
			drawing = @getDrawing()
			return if drawing? then drawing.containingLayer() else @group.parent

		addToListItem: (@itemListJ=null, name=null)->
			return
			# if not @itemListJ? then @itemListJ = @getListItem()
			# if not name? then name = @id.substring(0, 5)
			# super(@itemListJ, name)
			# return

		getDrawing: ()->
			return if @drawingId? then R.items[@drawingId] else null

		getDuplicateData: ()->
			data = super()
			data.points = @pathOnPlanet()
			data.date = @date
			return data

		# common to all RItems
		# return [P.Rectangle] the bounds of the control path (does not necessarly fit the drawing entirely, but is centered on it)
		# getBounds: ()->
		# 	return @controlPath.strokeBounds

		# return [P.Rectangle] the bounds of the drawing group
		getDrawingBounds: ()->
			if not @canvasRaster and @drawing? and @drawing.strokeBounds.area>0
				if @raster?
					return @raster.bounds
				return @drawing.strokeBounds.expand(@constructor.strokeWidth)
			return @getBounds()?.expand(2*@constructor.strokeWidth)

		# updateMove: (event)->
		# 	if @drawing?
		# 		@drawing.remove()
		# 	super(event)
		# 	return

		# endMove: (update)->
		# 	super(update)
		# 	@group.addChild(@drawing)
		# 	return

		endSetRectangle: ()->
			super()
			@draw()
			@rasterize()
			return

		setRectangle: (rectangle, update)->
			super(rectangle, update)
			@draw(update)
			return

		setRotation: (rotation, center, update)->
			super(rotation, center, update)
			@draw(update)
			return

		# convert a point from project coordinate system to raster coordinate system
		# @param point [Paper point] point to convert
		# @return [Paper point] resulting point
		projectToRaster: (point)->
			return point.subtract(@canvasRaster.bounds.topLeft)

		# set path items (control path, drawing, etc.) to the right state before performing hitTest
		# store the current state of items, and change their state (the original states will be restored in @finishHitTest())
		# @param fullySelected [Boolean] (optional) whether the control path must be fully selected before performing the hit test (it must be if we want to test over control path handles)
		# @param strokeWidth [Number] (optional) control path width will be set to *strokeWidth* if it is provided
		prepareHitTest: (fullySelected, strokeWidth)->
			super()

			@stateBeforeHitTest = {}
			@stateBeforeHitTest.groupWasVisible = @group.visible
			@stateBeforeHitTest.controlPathWasVisible = @controlPath.visible
			@stateBeforeHitTest.controlPathWasSelected = @controlPath.selected
			@stateBeforeHitTest.controlPathWasFullySelected = @controlPath.fullySelected
			@stateBeforeHitTest.controlPathStrokeWidth = @controlPath.strokeWidth

			@group.visible = true
			@controlPath.visible = true
			@controlPath.selected = true
			if strokeWidth then @controlPath.strokeWidth = strokeWidth
			if fullySelected then @controlPath.fullySelected = true

			@speedGroup?.selected = true
			return

		# restore path items orginial states (same as before @prepareHitTest())
		# @param fullySelected [Boolean] (optional) whether the control path must be fully selected before performing the hit test (it must be if we want to test over control path handles)

		finishHitTest: (fullySelected=true)->
			super(fullySelected)
			@group.visible = @stateBeforeHitTest.groupWasVisible
			@controlPath.visible = @stateBeforeHitTest.controlPathWasVisible
			@controlPath.strokeWidth = @stateBeforeHitTest.controlPathStrokeWidth
			@controlPath.fullySelected = @stateBeforeHitTest.controlPathWasFullySelected
			if not @controlPath.fullySelected
				@controlPath.selected = @stateBeforeHitTest.controlPathWasSelected
			@stateBeforeHitTest = null

			@speedGroup?.selected = false
			return

		hitTest: (event)->
			wasSelected = @selected
			hitResult = super(event)
			if not hitResult? then return
			if hitResult.type == 'stroke' or not wasSelected
				hitResult.type = 'stroke'
				if R.tools.select.selectionRectangle?
					R.tools.select.selectionRectangle.beginAction(hitResult, event)
				else
					$(R.tools.select).one 'selectionRectangleUpdated', ()-> return R.tools.select.selectionRectangle.beginAction(hitResult, event)
			return hitResult

		# select the RPath: (only if it has a control path but no selection rectangle i.e. already selected)
		# - create or update the selection rectangle,
		# - create or update the global selection group (i.e. add this RPath to the grouop)
		# - (optionally) update controller in the gui accordingly
		# @param updateOptions [Boolean] whether to update controllers in gui or not
		# @return whether the ritem was selected or not
		select: (updateOptions=true)->
			if R.me != @owner and not @drawingId? and not R.administrator then return false

			if @drawingId? and R.items[@drawingId]?
				R.items[@drawingId].select()
				return null

			if not @drawingId? and not R.administrator
				Utils.callNextFrame((()-> return R.drawingPanel.submitDrawingClicked()), 'select draft')
				return false

			if not R.administrator then return false
			if not super(updateOptions) or not @controlPath? then return false
			# if not @drawing? then @draw()
			R.drawingPanel.showSubmitDrawing()
			return true

		# deselect: remove the selection rectangle (and rasterize)
		deselect: (updateOptions=true)->
			if not super(updateOptions) then return false
			return true
		#
		# beginAction: (command)->
		# 	super(command)
		# 	# if not @selectionState.move?
		# 	# 	R.rasterizer.rasterize(@, true)
		# 	return
		#
		# endAction: ()->
		# 	super()
		# 	# if not @selectionState.move?
		# 	# 	R.rasterizer.rasterizeItem(@)
		# 	return

		# common to all RItems
		# update select action
		# to be overloaded by children classes
		# @param event [Paper event] the mouse event
		updateSelect: (event)->
			# if not @drawing then R.updateView()
			super(event)
			return

		# double click action
		# to be redefined in children classes
		# @param event [Paper event] the mouse event
		doubleClick: (event)->
			return

		# redraw the skeleton (controlPath) of the path,
		# called only when loading a path
		# redefined in PrecisePath, extended by shape (for security checks)
		# @param points [Array of P.Point] (optional) the points of the controlPath
		loadPath: (points)->
			return

		# called when a parameter is changed:
		# - from user action (parameter.onChange)
		# @param name [String] the name of the value to change
		# @param value [Anything] the new value
		# @param updateGUI [Boolean] (optional, default is false) whether to update the GUI (parameters bar), true when called from SetParameterCommand

		setParameter: (name, value, updateGUI, update)->
			super(name, value, updateGUI, update)
			# if not @drawing then R.updateView() 	# update the view if it was rasterized
			@previousBoundingBox ?= @getDrawingBounds()
			@draw()		# if draw in simple mode, then how to see the change of simplified parameters?
			return

		applyStylesToPath: (path)->
			path.strokeColor = @data.strokeColor
			path.strokeWidth = @data.strokeWidth
			path.fillColor = @data.fillColor
			if @data.dashArray?
				path.dashArray = @data.dashArray
			if @data.strokeCap?
				@drawing.strokeCap = @data.strokeCap
			if @data.strokeJoin?
				@drawing.strokeJoin = @data.strokeJoin
			if @data.shadowOffsetY?
				path.shadowOffset = new P.Point(@data.shadowOffsetX, @data.shadowOffsetY)
			if @data.shadowBlur?
				path.shadowBlur = @data.shadowBlur
			if @data.shadowColor?
				path.shadowColor = @data.shadowColor
			return

		# add a path to the drawing group:
		# - create the path
		# - initialize it (stroke width, and colors) with @data
		# - add to the drawing group
		# @param path [Paper path] (optional) the path to add to drawing, create an empty one if not provided
		# @return [Paper path] the resulting path
		addPath: (path, applyStyles=true)->
			path ?= new P.Path()
			# path.name = 'group path'
			path.controller = @
			if applyStyles then @applyStylesToPath(path)
			@drawing.addChild(path)
			return path

		# create the group and the control path
		# @param controlPath [Paper P.Path] (optional) the control path
		addControlPath: (@controlPath)->
			if @lock then @lock.group.addChild(@group)

			@controlPath ?= new P.Path()
			@group.addChild(@controlPath)

			@controlPath.name = "controlPath"
			@controlPath.controller = @
			@controlPath.strokeWidth = 10
			@controlPath.strokeColor = R.selectionBlue
			@controlPath.strokeColor.alpha = 0.25
			@controlPath.strokeCap = 'round'
			@controlPath.strokeJoin = 'round'
			@controlPath.visible = false

			return

		getStrokeColor: ()->
			# d = @getDrawing()
			# color = new P.Color(if d? then @constructor.colorMap[d.status] else @constructor.colorMap.draft)
			# if @owner != R.me
				# color.brightness *= 0.8
			# @data.strokeColor = color
			# @data.dashArray = if @owner != R.me then [1, @constructor.strokeWidth+1] else []
			# @data.strokeCap = if @owner != R.me then 'square' else 'round'
			return @data.strokeColor

		updateStrokeColor: ()->
			@drawing?.strokeColor = @getStrokeColor()
			return

		# initialize the drawing group before drawing:
		# - create drawing group and initialize it with @data (add it to group)
		# - optionally create a child canvas to draw on it (drawn in a raster, add it to group)
		#   - this child canvas is used to speed up drawing operations (bypass paper.js drawing tools) when heavy drawing operations are required
		#   - the advantage is speed, the drawback is that we loose the great benefits of paper.js (ease of use, export to SVG)
		#   - the image drawn on the child canvas can not be exported in svg since it is not taken into account by paper.js
		#   - if there is no control path yet (meaning the user did not even start drawing the RPath, mouse was just pressed)
		#     - create the canvas at the size of the view
		#     else
		#     - create canvas to the dimensions of the control path
		# @param createCanvas [Boolean] (optional, default to true) whether to create a child canavs *@canvasRaster*
		initializeDrawing: (createCanvas=false)->

			@raster?.remove()
			@raster = null

			@controlPath.strokeWidth = 10

			# @data.strokeColor = @getStrokeColor()
			@data.strokeColor ?= R.selectedColor

			# create drawing group and initialize it with @data
			@drawing?.remove()
			@drawing = new P.Group()

			@drawing.name = "drawing"
			@drawing.strokeColor = @data.strokeColor
			@drawing.strokeWidth = @data.strokeWidth
			if @data.dashArray?
				@drawing.dashArray = @data.dashArray
			if @data.strokeCap?
				@drawing.strokeCap = @data.strokeCap
			if @data.strokeJoin?
				@drawing.strokeJoin = @data.strokeJoin
			@drawing.fillColor = @data.fillColor
			@drawing.insertBelow(@controlPath)
			@drawing.controlPath = @controlPath
			@drawing.controller = @
			@group.addChild(@drawing)

			# optionally create a child canvas to draw on it
			if createCanvas
				canvas = document.createElement("canvas")

				# if rectangle has no area yet (meaning the user did not finish drawing the RPath)
				if @rectangle.area < 2
					# create the canvas at the size of the view
					canvas.width = P.view.size.width
					canvas.height = P.view.size.height
					position = P.view.center
				else
					# create canvas to the dimensions of the bounds
					bounds = @getDrawingBounds()
					canvas.width = bounds.width
					canvas.height = bounds.height
					position = bounds.center

				@canvasRaster?.remove()
				@canvasRaster = new P.Raster(canvas, position)
				@drawing.addChild(@canvasRaster)
				@context = @canvasRaster.canvas.getContext("2d")
				@context.strokeStyle = @data.strokeColor
				@context.fillStyle = @data.fillColor
				@context.lineWidth = @data.strokeWidth
			return

		# finishDrawing: ()->
		# 	@rasterize()
		# 	return

		# set animated: push/remove RPath to/from R.animatedItems
		# @param animated [Boolean] whether to set the path as animated or not animated
		setAnimated: (animated)->
			if animated
				Utils.Animation.registerAnimation(@)
			else
				Utils.Animation.deregisterAnimation(@)
			return

		# update the appearance of the path (the drawing group)
		# called anytime the path is modified:
		# by beginCreate/Update/End, updateSelect/End, parameterChanged, deletePoint, changePoint etc. and loadPath
		# must be redefined in children RPath
		# because the path are rendered on rasters, path are not drawn on load unless they are animated
		# @param simplified [Boolean] whether to draw in simplified mode or not (much faster)
		draw: (simplified=false)->
			return

		# called once after endCreate to initialize the path (add it to a game, or to the animated paths)
		# must be redefined in children RPath
		initialize: ()->
			return

		# beginCreate, updateCreate, endCreate
		# called from loadPath (draw the skeleton when path is loaded), then *event* is null
		# called from PathTool.begin, PathTool.update and PathTool.end (when the user draws something), then *event* is the Paper mouse event
		# @param point [P.Point] point to peform the action
		# @param event [Paper event of REvent] the mouse event
		beginCreate: (point, event) ->
			return

		# see beginCreate
		updateCreate: (point, event) ->
			return

		# see beginCreate
		endCreate: (point, event) ->
			# R.rasterizer.rasterizeItem(@)
			return

		# insert above given *path*
		# @param path [RPath] path on which to insert this
		# @param index [Number] the index at which to add the path in R.sortedPaths
		insertAbove: (path, index=null, update=false)->
			@zindex = @group.index
			# if update and not @drawing then R.updateView()
			super(path, index, update)
			return

		# insert below given *path*
		# @param path [RPath] path under which to insert this
		# @param index [Number] the index at which to add the path in R.sortedPaths
		insertBelow: (path, index=null, update=false)->
			@zindex = @group.index
			# if update and not @drawing then R.updateView()
			super(path, index, update)
			return

		# common to all RItems
		# get data, usually to save the RPath (some information must be added to data)
		getData: ()->
			return @data

		# common to all RItems
		# @return [String] the stringified data
		getStringifiedData: ()->
			return JSON.stringify(@getData())

		# @return [P.Point] the planet on which the RPath lies
		getPlanet: ()->
			return Utils.CS.projectToPlanet( @controlPath.segments[0].point )

		# save RPath to server
		save: (addCreateCommand=true)->
			if not @controlPath? then return

			draft = Item.Drawing.getDraft()

			if draft?
				R.commandManager.add(new Command.ModifyDrawing(draft))
				draft.addChild(@)
				if not draft.pk?
					draft.addPathToSave(@)
				else
					args = 
						clientId: draft.id
						pk: draft.pk
						points: @getPoints()
						data: { strokeColor: @data.strokeColor }
						bounds: draft.getBounds()
					$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'addPathToDrawing', args: args } ).done(@saveCallback)
			else
				draft = new Item.Drawing(null, null, null, null, R.me, Date.now(), null, null, 'draft')
				R.commandManager.add(new Command.ModifyDrawing(draft))
				draft.points = @getPoints()
				draft.pathData = { strokeColor: @data.strokeColor }
				draft.addChild(@)
				draft.save()

			# R.paths[@id] = @

			# args =
			# 	clientId: @id
			# 	cityName: R.city.name
			# 	bounds: @getDrawingBounds()
			# 	points: @pathOnPlanet()
			# 	data: @getStringifiedData()
			# 	date: @date
			# 	object_type: @constructor.label

			# $.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'savePath', args: args } ).done(@saveCallback)
			# # Dajaxice.draw.savePath( @saveCallback, args )

			super(false)
			return

		# check if the save was successful and set @pk if it is
		saveCallback: (result)=>
			R.loader.checkError(result)
			if not result.pk? then return 		# if @pk is null, the path was not saved, do not set pk nor rasterize
			@setPK(result.pk)
			@owner = result.owner

			# if not @data?.animate
			# 	R.rasterizeArea(@getDrawingBounds())
			if @updateAfterSave?
				@update(@updateAfterSave)
			super
			return

		getUpdateFunction: ()->
			return 'updatePath'

		getUpdateArguments: (type)->
			switch type
				when 'z-index'
					args = pk: @pk, date: @date
				else
					args =
						pk: @pk
						points: @pathOnPlanet()
						data: @getStringifiedData()
						bounds: @getDrawingBounds()
			return args

		# update the RPath in the database
		# @param type [String] type of change to consider (in further version, could send only the required information to the server to make the update to improve performances)
		update: (type)=>
			# console.log "update: " + @pk
			if not @pk?
				@updateAfterSave = type
				return
			delete @updateAfterSave

#			Dajaxice.draw.updatePath(@updatePathCallback, @getUpdateArguments(type))
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'updatePath', args: @getUpdateArguments(type) }).done(@updatePathCallback)

			# if not @data?.animate

			# 	if not @drawing?
			# 		@draw()

			# 	selectionHighlightVisible = @selectionHighlight?.visible
			# 	@selectionHighlight?.visible = false
			# 	speedGroupVisible = @speedGroup?.visible
			# 	@speedGroup?.visible = false

			# 	rectangle = @getDrawingBounds()

			# 	if @previousBoundingBox?
			# 		union = rectangle.unite(@previousBoundingBox)
			# 		if rectangle.intersects(@previousBoundingBox) and union.area < @previousBoundingBox.area*2
			# 			R.rasterizeArea(union)
			# 		else
			# 			R.rasterizeArea(rectangle)
			# 			R.rasterizeArea(@previousBoundingBox)

			# 		@previousBoundingBox = null
			# 	else
			# 		R.rasterizeArea(rectangle)

			# 	@selectionHighlight?.visible = selectionHighlightVisible
			# 	@speedGroup?.visible = speedGroupVisible

			# if type == 'points'
			# 	# ajaxPost '/updatePath', {'pk': @pk, 'points':@pathOnPlanet(), 'planet': @getPlanet(), 'data': @getStringifiedData() }, @updatePathCallback
			# 	Dajaxice.draw.updatePath( @updatePathCallback, {'pk': @pk, 'points':@pathOnPlanet(), 'planet': @getPlanet(), 'data': @getStringifiedData() } )
			# else
			# 	# ajaxPost '/updatePath', {'pk': @pk, 'data': @getStringifiedData() } , @updatePathCallback
			# 	Dajaxice.draw.updatePath( @updatePathCallback, {'pk': @pk, 'data': @getStringifiedData() } )

			return

		# check if update was successful
		updatePathCallback: (result)->
			R.loader.checkError(result)
			return

		# set @pk, update R.items and emit @pk to other users
		# @param pk [Id] the new pk
		# @param updateRoom [updateRoom] (optional) whether to emit @pk to other users in the room
		setPK: (pk)->
			super
			# R.paths[pk] = @
			# delete R.paths[@id]
			return
		
		isDraft: ()->
			return not @drawingId? or R.items[@drawingId]?.status == 'draft'

		# common to all RItems
		# called by @delete() and to update users view through websockets
		# @delete() removes the path and delete it in the database
		# @remove() just removes visually
		remove: ()->
			if not @group then return
			Utils.Animation.deregisterAnimation()
			@controlPath = null
			@drawing = null
			@raster ?= null
			@canvasRaster ?= null
			
			delete R.paths[@id]
			# R.updateView()
			super()
			return

		delete: ()->
			deffered = super()
			draft = R.Drawing.getDraft()
			if draft?
				draft.updatePaths()
				R.toolManager.updateButtonsVisibility(draft)
				R.tools['Precise path'].showDraftLimits()
			return deffered

		deleteFromDatabase: ()->
			console.log('delete ' + @id + ' from database')
#			Dajaxice.draw.deletePath(R.loader.checkError, { pk: @pk })
			
			if not @pk? or @pk == @id then return 			# the path is not in database
			
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'deletePath', args: { pk: @pk } } ).done(@deleteFromDatabaseCallback)
			return

		# @param controlSegments [Array<Paper P.Segment>] the control path segments to convert in planet coordinates
		# return [Array of Paper point] a list of point from the control path converted in the planet coordinate system
		pathOnPlanet: (controlSegments=@controlPath.segments)->
			points = []
			planet = @getPlanet()
			for segment in controlSegments
				p = Utils.CS.projectToPosOnPlanet(segment.point, planet)
				points.push( Utils.CS.pointToArray(p) )
			return points

		getPathList: (item, paths)->
			switch item.className
				when 'Group', 'CompoundPath'
					for child in item.children
						@getPathList(child, paths)
				when 'Path', 'Shape'
					segments = if item.className == 'Shape' then item.toPath(false).segments else item.segments
					path = []
					for segment in segments
						path.push(segment.point.toJSON())
					if item.closed
						path.push(item.firstSegment.point.toJSON())
					paths.push(path)
			return

		# send path to spacebrew
		requireAndSendToSpacebrew: ()->
			if not spacebrew?
				spacebrewPath = 'Spacebrew'
				require([spacebrewPath], @sendToSpacebrew)
			return

		sendToSpacebrew: (spacebrew)=>
			paths = []
			@getPathList(@drawing, paths)
			linkAllPaths = []
			for path in paths
				for point in path
					linkAllPaths.push(point)
			paths = [linkAllPaths]
			data =
				paths: paths
				bounds: paper.view.bounds.toJSON()
			json = JSON.stringify(data)
			spacebrew.send("commands", "string", json)
			return

		# exportToSVG: (item, filename)->

		# 	item ?= @drawing
		# 	filename ?= "image.svg"
		# 	# export to svg
		# 	drawing = item.clone()
		# 	drawing.position = new P.Point(drawing.rectangle.size.multiply(0.5))
		# 	svg = drawing.exportSVG( asString: true )
		# 	drawing.remove()

		# 	svg = svg.replace(new RegExp('<g', 'g'), '<svg')
		# 	svg = svg.replace(new RegExp('</g', 'g'), '</svg')

		# 	# url = "data:image/svg+xml;utf8," + encodeURIComponent(svg)
		# 	blob = new Blob([svg], {type: 'image/svg+xml'})
		# 	url = URL.createObjectURL(blob)

		# 	link = document.createElement("a")
		# 	document.body.appendChild(link)
		# 	link.href = url
		# 	link.download = filename
		# 	link.text = filename
		# 	link.click()
		# 	document.body.removeChild(link)

		# 	return

	Item.Path = Path
	R.Path = Path
	return Path
