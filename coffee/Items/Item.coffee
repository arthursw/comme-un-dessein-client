define ['paper', 'R', 'Utils/Utils', 'Commands/Command', 'Tools/ItemTool' ], (P, R, Utils, Command, ItemTool) ->
	console.log 'Item'

	class Item

		# @indexToName =
		# 	0: 'bottomLeft'
		# 	1: 'left'
		# 	2: 'topLeft'
		# 	3: 'top'
		# 	4: 'topRight'
		# 	5: 'right'
		# 	6: 'bottomRight'
		# 	7: 'bottom'

		# @oppositeName =
		# 	'top': 'bottom'
		# 	'bottom': 'top'
		# 	'left': 'right'
		# 	'right': 'left'
		# 	'topLeft': 'bottomRight'
		# 	'topRight':  'bottomLeft'
		# 	'bottomRight':  'topLeft'
		# 	'bottomLeft':  'topRight'

		# @cornersNames = ['topLeft', 'topRight', 'bottomRight', 'bottomLeft']
		# @sidesNames = ['left', 'right', 'top', 'bottom']

		# @valueFromName: (point, name)->
		# 	switch name
		# 		when 'left', 'right'
		# 			return point.x
		# 		when 'top', 'bottom'
		# 			return point.y
		# 		else
		# 			return point

		# Paper hitOptions for hitTest function to check which items (corresponding to those criterias) are under a point
		@hitOptions =
			segments: true
			stroke: true
			fill: true
			selected: true
			tolerance: 5

		@zIndexSortStop: (event, ui)->
			previouslySelectedItems = R.selectedItems
			R.tools.select.deselectAll()
			rItem = R.items[ui.item.attr("data-id")]
			nextItemJ = ui.item.next()
			if nextItemJ.length>0
				rItem.insertAbove(R.items[nextItemJ.attr("data-id")], null, true)
			else
				previousItemJ = ui.item.prev()
				if previousItemJ.length>0
					rItem.insertBelow(R.items[previousItemJ.attr("data-id")], null, true)
			for item in previouslySelectedItems
				item.select()
			return

		@addItemToStage: (item)->
			Item.addItemTo(item)
			return

		@addItemTo: (item, lock=null)->
			wasSelected = item.isSelected()
			if wasSelected then item.deselect()
			group = if lock then lock.group else R.view.mainLayer
			group.addChild(item.group)
			item.lock = lock
			Utils.Array.remove(item.sortedItems, item)
			parent = lock or R.sidebar
			if Item.Div.prototype.isPrototypeOf(item)
				item.sortedItems = parent.sortedDivs
				# parent.itemListsJ.find(".rDiv-list").append(item.liJ)
			else if Item.Path.prototype.isPrototypeOf(item)
				item.sortedItems = parent.sortedPaths
				# parent.itemListsJ.find(".rPath-list").append(item.liJ)
			else
				console.error "Error: the item is neither an Div nor an RPath"
			item.updateZindex()
			if wasSelected then item.select()
			return

		# @onPositionFinishChange: (value)->
		# 	# -------------------------------------------------------------------- #
		# 	# !!! Problem: moveToCommand will move depending on the given item !!! #
		# 	# -------------------------------------------------------------------- #

		# 	value = value.split(':')

		# 	if value.length>1
		# 		switch value[0]
		# 			when 'x'
		# 				x = parseFloat(value[1])
		# 				if not R.isNumber(x)
		# 					R.alertManager.alert 'Position invalid.', 'Warning'
		# 					return
		# 				for item in R.selectedItems
		# 					y = item.rectangle.center.y
		# 					item.moveToCommand(new P.Point(x, y))
		# 			when 'y'
		# 				y = parseFloat(value[1])
		# 				if not R.isNumber(y)
		# 					R.alertManager.alert 'Position invalid.', 'Warning'
		# 					return
		# 				for item in R.selectedItems
		# 					x = item.rectangle.center.x
		# 					item.moveToCommand(new P.Point(x, y))
		# 			else
		# 				R.alertManager.alert 'Position invalid.', 'Warning'
		# 		return

		# 	value = value.split(',')

		# 	x = parseFloat(value[0])
		# 	y = parseFloat(value[1])

		# 	if not ( R.isNumber(x) and R.isNumber(y) )
		# 		R.alertManager.alert 'Position invalid.', 'Warning'
		# 		return

		# 	point = new P.Point(x, y)

		# 	for item in R.selectedItems
		# 		item.moveToCommand(point)

		# 	return

		# @onSizeFinishChange: (value)->
		# 	value = value.split(',')

		# 	if value.length==1
		# 		value = value.split(':')
		# 		switch value[0]
		# 			when 'width'
		# 				width = parseFloat(value[1])
		# 				if not R.isNumber(width)
		# 					R.alertManager.alert 'Size invalid', 'Warning'
		# 					return
		# 				for item in R.selectedItems
		# 					height = item.rectangle.size.height
		# 					item.resizeCommand(new P.Rectangle(item.rectangle.point, new P.Size(width, height)))
		# 	return

		@updatePositionAndSizeControllers: (position, size)->
			R.controllerManager.getController('Position & size', 'position')?.setValue(Utils.pointToString(position))
			R.controllerManager.getController('Position & size', 'size')?.setValue(Utils.pointToString(size))
			return

		@onPositionFinishChange: (position)->
			R.tools.select?.selectionRectangle?.setPosition(Utils.stringToPoint(position))
			return

		@onSizeFinishChange: (size)->
			R.tools.select?.selectionRectangle?.setSize(Utils.stringToPoint(size))
			return

		@initializeParameters: ()->
			console.log 'Item.initializeParameters'
			parameters =
				'Items':
					# align: R.parameters.align
					# distribute: R.parameters.distribute
					delete: R.parameters.delete
				# 'Style':
				# 	strokeWidth: R.parameters.strokeWidth
				# 	strokeColor: R.parameters.strokeColor
				# 	fillColor: R.parameters.fillColor
				# 'Position & size':
				# 	position:
				# 		default: ''
				# 		initializeController: (controller)->
				# 			averagePosition = new P.Point()
				# 			n = 0
				# 			for item in R.selectedItems
				# 				if item.rectangle?
				# 					averagePosition = averagePosition.add(item.rectangle.topLeft)
				# 					n++
				# 			averagePosition = averagePosition.divide(n)
				# 			controller.setValue('' + averagePosition.x.toFixed(2) + ', ' + averagePosition.y.toFixed(2))
				# 			return
				# 		label: 'Position'
				# 		onChange: ()-> return
				# 		onFinishChange: @onPositionFinishChange
				# 	size:
				# 		default: ''
				# 		initializeController: (controller)->
				# 			averageSize = new P.Point()
				# 			n = 0
				# 			for item in R.selectedItems
				# 				if item.rectangle?
				# 					averageSize = averageSize.add(item.rectangle.size)
				# 					n++
				# 			averageSize = averageSize.divide(n)
				# 			controller.setValue('' + averageSize.x.toFixed(2) + ', ' + averageSize.y.toFixed(2))
				# 			return
				# 		label: 'Size'
				# 		onChange: ()-> return
				# 		onFinishChange: @onSizeFinishChange

			return parameters

		@parameters = @initializeParameters()

		# always overloaded
		@create: (duplicateData)->
			copy = new @(duplicateData, duplicateData.id)
			if not @socketAction
				copy.save(false)
				R.socket.emit "bounce", itemClass: @name, function: "create", arguments: [duplicateData]
			return copy

		constructor: (@data, @id, @pk)->

			@id ?= Utils.createId()
			
			R.items[@id] = @

			# if the RPath is being loaded: directly set pk and load path
			if @pk?
				@setPK(@pk, true)
				R.commandManager.loadItem(@)
			
			# creation of a new object by the user: set @data to R.gui values
			if @data?
				@secureData()
			else
				@data = new Object()
				R.controllerManager.updateItemData(@)

			@rectangle ?= null

			@selectionState = null
			# @selectionRectangle = null

			@group = new P.Group()
			@group.name = "group"
			@group.controller = @


			return

		containingLayer: ()->
			return @group?.parent

		isVisible: ()->
			# WARNING: returns true even if @group is not visible since it can be rasterized (in which case @group.visible == false)
			return @containingLayer().visible

		secureData: ()->
			for name, parameter of @constructor.parameters
				if parameter.secure?
					@data[name] = parameter.secure(@data, parameter)
				else
					value = @data[name]
					if value? and parameter.min? and parameter.max?
						if value < parameter.min or value > parameter.max
							@data[name] = Utils.clamp(parameter.min, value, parameter.max)
			return

		# setParameterCommand: (controller, value)->
		# 	@deferredAction(Command.SetParameter, controller, value)
		# 	# if @data[name] == value then return
		# 	# @setCurrentCommand(new SetParameterCommand(@, name))
		# 	# @setParameter(name, value)
		# 	# Utils.deferredExecution(@addCurrentCommand, 'addCurrentCommand-' + (@id or @pk) )
		# 	return

		# @param name [String] the name of the value to change
		# @param value [Anything] the new value
		setParameter: (name, value, update)->
			if @data[name] is 'undefined' then return
			@data[name] = value
			@changed = name
			if not @socketAction
				if update
					@update(name)
				R.socket.emit "bounce", itemId: @id, function: "setParameter", arguments: [name, value, false, false]
			return

		# # set path items (control path, drawing, etc.) to the right state before performing hitTest
		# # store the current state of items, and change their state (the original states will be restored in @finishHitTest())
		# # @param fullySelected [Boolean] (optional) whether the control path must be fully selected before performing the hit test (it must be if we want to test over control path handles)
		# # @param strokeWidth [Number] (optional) contorl path width will be set to *strokeWidth* if it is provided
		prepareHitTest: ()->
			return

		# # restore path items orginial states (same as before @prepareHitTest())
		# # @param fullySelected [Boolean] (optional) whether the control path must be fully selected before performing the hit test (it must be if we want to test over control path handles)
		finishHitTest: ()->
			return

		performHitTest: (point)->
			return if @rectangle.contains(point) then true else null

		hitTest: (event)->

			hitResult = @performHitTest(event.point)
			if hitResult? and not @selected
				if not event.event.shiftKey or R.tools.select.isDrawingSelected()
					R.tools.select.deselectAll()
				R.commandManager.add(new Command.Select([@]), true)
			return hitResult

		# # perform hit test to check if the point hits the selection rectangle
		# # @param point [P.Point] the point to test
		# # @param hitOptions [Object] the [paper hit test options](http://paperjs.org/reference/item/#hittest-point)
		# performHitTest: (point, hitOptions)->
		# 	return @group.hitTest(point)

		# # when hit through websocket, must be (fully)Selected to hitTest
		# # perform hit test on control path and selection rectangle with a stroke width of 1
		# # to manipulate points on the control path or selection rectangle
		# # since @hitTest() will be overridden by children RPath, it is necessary to @prepareHitTest() and @finishHitTest()
		# # @param point [P.Point] the point to test
		# # @param hitOptions [Object] the [paper hit test options](http://paperjs.org/reference/item/#hittest-point)
		# # @param fullySelected [Boolean] (optional) whether the control path must be fully selected before performing the hit test (it must be if we want to test over control path handles)
		# # @return [Paper HitResult] the paper hit result
		# hitTest: (point, hitOptions, fullySelected=true)->
		# 	@prepareHitTest(fullySelected, 1)
		# 	hitResult = @performHitTest(point, hitOptions)
		# 	@finishHitTest(fullySelected)
		# 	return hitResult

		# intialize the selection:
		# determine which action to perform depending on the the *hitResult* (move by default, edit point if segment from contorl path, etc.)
		# set @selectionState which will be used during the selection process (select begin, update, end)
		# @param event [Paper event] the mouse event
		# @param hitResult [Paper HitResult] [paper hit result](http://paperjs.org/reference/hitresult/) form the hit test
		# initializeSelection: (event, hitResult) ->
		# 	if hitResult.item == @selectionRectangle
		# 		@selectionState = move: true
		# 		if hitResult?.type == 'stroke'
		# 			selectionBounds = @rectangle.clone().expand(10)
		# 			# for sideName in @constructor.sidesNames
		# 			# 	if Math.abs( selectionBounds[sideName] - @constructor.valueFromName(hitResult.point, sideName) ) < @constructor.hitOptions.tolerance
		# 			# 		@selectionState.move = sideName
		# 			minDistance = Infinity
		# 			for cornerName in @constructor.cornersNames
		# 				distance = selectionBounds[cornerName].getDistance(hitResult.point, true)
		# 				if distance < minDistance
		# 					@selectionState.move = cornerName
		# 					minDistance = distance
		# 		else if hitResult?.type == 'segment'
		# 			@selectionState = resize: { index: hitResult.segment.index }
		# 	return

		# # begin select action:
		# # - initialize selection (reset selection state)
		# # - select
		# # - hit test and initialize selection
		# # @param event [Paper event] the mouse event
		# beginSelect: (event) ->

		# 	@selectionState = move: true
		# 	if not @isSelected()
		# 		R.commandManager.add(updateAction, R.SelectCommand([@]), true)
		# 	else
		# 		hitResult = @performHitTest(event.point, @constructor.hitOptions)
		# 		if hitResult? then @initializeSelection(event, hitResult)

		# 	if @selectionState.move?
		# 		@beginAction(new R.MoveCommand(@))
		# 	else if @selectionState.resize?
		# 		@beginAction(new R.ResizeCommand(@))

		# 	return

		# # depending on the selected item, updateSelect will:
		# # - rotate the group,
		# # - scale the group,
		# # - or move the group.
		# # @param event [Paper event] the mouse event
		# updateSelect: (event)->
		# 	@updateAction(event)
		# 	return

		# # end the selection action:
		# # - nullify selectionState
		# # - redraw in normal mode (not fast mode)
		# # - update select command
		# endSelect: (event)->
		# 	@endAction()
		# 	return

		# beginAction: (command)->
		# 	if @currentCommand
		# 		@endAction()
		# 		clearTimeout(R.updateTimeout['addCurrentCommand-' + (@id or @pk)])
		# 	@currentCommand = command
		# 	return

		# updateAction: ()->
		# 	@currentCommand.update.apply(@currentCommand, arguments)
		# 	return

		# endAction: ()=>

		# 	positionIsValid = if @currentCommand.constructor.needValidPosition then Lock.validatePosition(@) else true

		# 	commandChanged = @currentCommand.end(positionIsValid)
		# 	if positionIsValid
		# 		if commandChanged then R.commandManager.add(@currentCommand)
		# 	else
		# 		@currentCommand.undo()

		# 	@currentCommand = null
		# 	return

		# deferredAction: (ActionCommand, args...)->
		# 	if not ActionCommand.prototype.isPrototypeOf(@currentCommand)
		# 		@beginAction(new ActionCommand(@, args))
		# 	@updateAction.apply(@, args)
		# 	Utils.deferredExecution(@endAction, 'addCurrentCommand-' + (@id or @pk) )
		# 	return

		# doAction: (ActionCommand, args)->
		# 	@beginAction(new ActionCommand(@))
		# 	@updateAction.apply(@, args)
		# 	@endAction()
		# 	return

		# # create the selection rectangle (path used to rotate and scale the RPath)
		# # @param bounds [Paper P.Rectangle] the bounds of the selection rectangle
		# createSelectionRectangle: (bounds)->
		# 	@selectionRectangle.insert(1, new P.Point(bounds.left, bounds.center.y))
		# 	@selectionRectangle.insert(3, new P.Point(bounds.center.x, bounds.top))
		# 	@selectionRectangle.insert(5, new P.Point(bounds.right, bounds.center.y))
		# 	@selectionRectangle.insert(7, new P.Point(bounds.center.x, bounds.bottom))
		# 	return

		# # add or update the selection rectangle (path used to rotate and scale the RPath)
		# # redefined by RShape# the selection rectangle is slightly different for a shape since it is never reset (rotation and scale are stored in database)
		# updateSelectionRectangle: ()->
		# 	bounds = @rectangle.clone().expand(10)

		# 	# create the selection rectangle: rectangle path + handle at the top used for rotations
		# 	@selectionRectangle?.remove()
		# 	@selectionRectangle = new P.Path.Rectangle(bounds)
		# 	@group.addChild(@selectionRectangle)
		# 	@selectionRectangle.name = "selection rectangle"
		# 	@selectionRectangle.pivot = bounds.center

		# 	@createSelectionRectangle(bounds)

		# 	@selectionRectangle.selected = true
		# 	@selectionRectangle.controller = @

		# 	return

		setRectangle: (rectangle, update)->
			if not P.Rectangle.prototype.isPrototypeOf(rectangle) then rectangle = new P.Rectangle(rectangle)
			@rectangle = rectangle
			# if @selectionRectangle then @updateSelectionRectangle()
			if not @socketAction
				if update then @update('rectangle')
				R.socket.emit "bounce", itemId: @id, function: "setRectangle", arguments: [rectangle, false]
			return

		validatePosition: ()->
			return true # Item.Lock.validatePosition(@)
		# updateSetRectangle: (event)->

		# 	event.point = Utils.Snap.snap2D(event.point)

		# 	rotation = @rotation or 0
		# 	rectangle = @rectangle.clone()
		# 	delta = event.point.subtract(@rectangle.center)
		# 	x = new P.Point(1,0)
		# 	x.angle += rotation
		# 	dx = x.dot(delta)
		# 	y = new P.Point(0,1)
		# 	y.angle += rotation
		# 	dy = y.dot(delta)

		# 	index = @selectionState.resize.index
		# 	name = @constructor.indexToName[index]

		# 	# if shift is not pressed and a corner is selected: keep aspect ratio (rectangle must have width and height greater than 0 to keep aspect ratio)
		# 	if not event.modifiers.shift and name in @constructor.cornersNames and rectangle.width > 0 and rectangle.height > 0
		# 		if Math.abs(dx / rectangle.width) > Math.abs(dy / rectangle.height)
		# 			dx = Utils.sign(dx) * Math.abs(rectangle.width * dy / rectangle.height)
		# 		else
		# 			dy = Utils.sign(dy) * Math.abs(rectangle.height * dx / rectangle.width)

		# 	center = rectangle.center.clone()
		# 	rectangle[name] = @constructor.valueFromName(center.add(dx, dy), name)

		# 	if not R.specialKey(event)
		# 		rectangle[@constructor.oppositeName[name]] = @constructor.valueFromName(center.subtract(dx, dy), name)
		# 	else
		# 		# the center of the rectangle changes when moving only one side
		# 		# the center must be repositionned with the previous center as pivot point (necessary when rotation > 0)
		# 		rectangle.center = center.add(rectangle.center.subtract(center).rotate(rotation))

		# 	if rectangle.width < 0
		# 		rectangle.width = Math.abs(rectangle.width)
		# 		rectangle.center.x = center.x
		# 	if rectangle.height < 0
		# 		rectangle.height = Math.abs(rectangle.height)
		# 		rectangle.center.y = center.y

		# 	@setRectangle(rectangle, false)
		# 	Lock.highlightValidity(@)
		# 	return

		# endSetRectangle: (update)->
		# 	if update then @update('rectangle')
		# 	return

		moveTo: (position, update)->
			if not P.Point.prototype.isPrototypeOf(position) then position = new P.Point(position)
			delta = position.subtract(@rectangle.center)
			@rectangle.center = position
			@group.translate(delta)

			if not @socketAction
				if update then @update('position')
				R.socket.emit "bounce", itemId: @id, function: "moveTo", arguments: [position, false]
			return

		translate: (delta, update)->
			@moveTo(@rectangle.center.add(delta), update)
			return

		scale: (scale, center, update)->
			@setRectangle(@rectangle.scaleFromCenter(scale, center), update)
			return

		# updateMove: (event)->
		# 	if Utils.Snap.getSnap() > 1
		# 		if @selectionState.move != true
		# 			cornerName = @selectionState.move
		# 			rectangle = @rectangle.clone()
		# 			@dragOffset ?= rectangle[cornerName].subtract(event.downPoint)
		# 			destination = Utils.Snap.snap2D(event.point.add(@dragOffset))
		# 			rectangle.moveCorner(cornerName, destination)
		# 			@moveTo(rectangle.center)
		# 		else
		# 			@dragOffset ?= @rectangle.center.subtract(event.downPoint)
		# 			destination = Utils.Snap.snap2D(event.point.add(@dragOffset))
		# 			@moveTo(destination)
		# 	else
		# 		@moveBy(event.delta)
		# 	Lock.highlightValidity(@)
		# 	return

		# endMove: (update)->
		# 	@dragOffset = null
		# 	if update then @update('position')
		# 	return

		# moveToCommand: (position)->
		# 	R.commandManager.add(new R.MoveCommand(@, position), true)
		# 	return

		# resizeCommand: (rectangle)->
		# 	R.commandManager.add(new R.ResizeCommand(@, rectangle), true)
		# 	return

		# moveByCommand: (delta)->
		# 	@moveToCommand(@rectangle.center.add(delta), true)
		# 	return

		# @return [Object] @data along with @rectangle and @rotation
		getData: ()->
			@data.id = @id
			data = jQuery.extend({}, @data)
			data.rectangle = @rectangle.toJSON()
			data.rotation = @rotation
			return data

		# @return [String] the stringified data
		getStringifiedData: ()->
			return JSON.stringify(@getData())

		getBounds: ()->
			return @rectangle

		getDrawingBounds: ()->
			return @rectangle.expand(if @data.strokeWidth then @data.strokeWidth else 10)

		# highlight this Item by drawing a blue rectangle around it
		highlight: ()->
			bounds = @getBounds()
			if not bounds? then return
			if @highlightRectangle?
				Utils.Rectangle.updatePathRectangle(@highlightRectangle, bounds)
				return
			@highlightRectangle = new P.Path.Rectangle(@getBounds())
			@highlightRectangle.strokeColor = R.selectionBlue
			@highlightRectangle.strokeScaling = false
			@highlightRectangle.dashArray = [4, 10]
			R.view.selectionLayer.addChild(@highlightRectangle)
			return

		# common to all RItems
		# hide highlight rectangle
		unhighlight: ()->
			if not @highlightRectangle? then return
			@highlightRectangle.remove()
			@highlightRectangle = null
			return

		setPK: (@pk, loading=false)->
			R.commandManager.itemSaved(@)

		# 	# if @id? then R.commandManager.setItemPk(@id, @pk)
		# 	# R.items[@pk] = @
		# 	# delete R.items[@id]
		# 	if not loading and not @socketAction then R.socket.emit "bounce", itemId: @id, function: "setPK", arguments: [@pk]
			return

		deleteFromDatabaseCallback: ()=>
			if not R.loader.checkError() then return
			console.log('deleteFromDatabaseCallback')
			R.commandManager.itemDeleted(@)
			return

		# @return true if Item is selected
		isSelected: ()->
			return @selectionRectangle?

		isDraft: ()->
			return false
		
		# select the Item: (only if it has no selection rectangle i.e. not already selected)
		# - update the selection rectangle,
		# - (optionally) update controller in the gui accordingly
		# @return whether the ritem was selected or not
		select: (updateOptions=true, force=false)->
			if force
				@selected = false
				Utils.Array.remove(R.selectedItems, @)
			if @selected then return false
			@selected = true

			@lock?.deselect()

			# create or update the selection rectangle
			@selectionState = move: true

			R.s = @

			# @updateSelectionRectangle(true)
			R.selectedItems.push(@)
			R.tools.select.updateSelectionRectangle()
			
			if updateOptions
				R.controllerManager.updateParametersForSelectedItems()

			R.rasterizer.selectItem(@)

			@zindex = @group.index

			if @group.parent != R.view.selectionLayer or not @parentBeforeSelection? 	# when force selected, do not set @parentBeforeSelection to R.selectionLayer
																						# otherwise item will be put back to selection layer when deselecting
				@parentBeforeSelection = @group.parent
			R.view.selectionLayer.addChild(@group)

			return true

		deselect: (updateOptions=true)->
			if not @selected then return false
			@selected = false

			# @selectionRectangle?.remove()
			# @selectionRectangle = null
			Utils.Array.remove(R.selectedItems, @)

			R.tools.select.updateSelectionRectangle()
			
			if updateOptions
				R.controllerManager.updateParametersForSelectedItems()

			if @group? 	# @group is null when item is removed (called from @remove())

				R.rasterizer.deselectItem(@)

				@parentBeforeSelection?.insertChild(@zindex, @group)

			return true

		remove: ()->
			R.commandManager.unloadItem(@)
			@deselect()
			
			if not @group then return

			@group.remove()
			@group = null
			
			@highlightRectangle?.remove()
			
			delete R.items[@id]

			# @pk = null 	# pk is required to delete the path!!
			# @id = null
			return

		finish: ()->
			if @rectangle.width == 0 and @rectangle.height == 0
				# @remove()
				# return false
				@rectangle = @rectangle.expand(2)
			return true

		save: (addCreateCommand)->
			if addCreateCommand then R.commandManager.add(new Command.CreateItem(@))
			return

		saveCallback: ()->
			return

		addUpdateFunctionAndArguments: (args, type)->
			args.push( function: @getUpdateFunction(type), arguments: @getUpdateArguments(type) )
			return

		deleteFromDatabase: ()->
			return

		delete: ()->
			@remove()
			if not @pk? then return false
			@pk = null
			if not @socketAction
				@deleteFromDatabase()
				R.socket.emit "bounce", itemId: @id, function: "delete", arguments: []
				return true
			return false

		deleteCommand: ()->
			R.commandManager.add(new Command.DeleteItem(@), true)
			return

		getDuplicateData: ()->
			return data: @getData(), rectangle: @rectangle, id: @id, owner: @owner

		duplicateCommand: ()->
			R.commandManager.add(new Command.DuplicateItem(@), true)
			return

		removeDrawing: ()->
			# if not @drawing?.parent? then return
			# @drawingRelativePosition = @drawing.position.subtract(@rectangle.center)
			# # @drawing.data.rectangle.remove()
			# @drawing.remove()
			return

		replaceDrawing: ()->
			# if not @drawing? or not @drawingRelativePosition? then return
			# @raster?.remove()
			# @raster = null
			# @group.addChild(@drawing)
			# @drawing.position = @rectangle.center.add(@drawingRelativePosition)
			# @drawingRelativePosition = null
			return

		rasterize: ()->
			# if @drawingId? then return
			# if @raster? or not @drawing? then return
			# if not R.rasterizer.rasterizeItems then return
			# if @drawing.bounds.width == 0 and @drawing.bounds.height == 0 then return

			# if @drawing.data.rectangle?
			# 	@drawing.data.rectangle.remove()
			
			# if not @drawing.data.rectangle
			# 	@drawing.data.rectangle = new P.Path.Rectangle(@drawing.bounds.expand(2*Item.Path.strokeWidth))	
			# 	# @drawing.data.rectangle.fillColor = new P.Color(Math.random(), Math.random(), Math.random())
			# 	@drawing.addChild(@drawing.data.rectangle)
			# 	@drawing.data.rectangle.sendToBack()

			# @raster = @drawing.rasterize()

			# @group.addChild(@raster)
			# @raster.sendToBack() 	# the raster (of a lock) must be send behind other items
			# @removeDrawing()
			return

	ItemTool.Item = Item
	R.Item = Item
	return Item
