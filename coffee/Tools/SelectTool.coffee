define ['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'Items/Lock', 'Items/Item', 'Commands/Command', 'View/SelectionRectangle' ], (P, R, Utils, Tool, Lock, Item, Command, SelectionRectangle) ->

	# Enables to select RItems
	class SelectTool extends Tool

		@SelectionRectangle = SelectionRectangle

		@label = 'Select'
		@description = ''
		# @iconURL = 'glyphicon-envelope'
		@iconURL = 'cursor.png'
		@cursor =
			position:
				x: 0, y: 0
			name: 'default'
		@drawItems = false
		@order = 1

		# Paper hitOptions for hitTest function to check which items (corresponding to those criterias) are under a point
		@hitOptions =
			stroke: true
			fill: true
			handles: true
			selected: true

		constructor: () ->
			super(true)
			@selectedItem = null 		# should be deprecated
			@selectionRectangle = null
			return

		# Deselect all RItems (and paper items)
		deselectAll: (updateOptions=true)->
			if R.selectedItems.length>0
				R.commandManager.add(new Command.Deselect(undefined, updateOptions), true)
				@selectionRectangle?.remove()
				@selectionRectangle = null
			P.project.activeLayer.selected = false
			return

		setSelectionRectangleVisibility: (value)=>
			@selectionRectangle?.setVisibility(value)
			return

		updateSelectionRectangle: (rotation)->
			Utils.callNextFrame(@updateSelectionRectangleCallback, 'updateSelectionRectangleCallback', [rotation])
			return

		updateSelectionRectangleCallback: ()=>
			if R.selectedItems.length > 0
				@selectionRectangle ?= SelectionRectangle.create()
				@selectionRectangle.update()
				$(@).trigger('selectionRectangleUpdated')
			else
				@selectionRectangle?.remove()
				@selectionRectangle = null
			return

		select: (deselectItems=false, updateParameters=true, forceSelect=false)->
			# R.sidebar.favoriteToolsJ.find("[data-name='Precise path']").hide()
			# R.rasterizer.drawItems() 		# must not draw all items here since user can just wish to use an Media
			super(false, updateParameters)
			return

		updateParameters: ()->
			R.controllerManager.updateParametersForSelectedItems()
			return

		highlightItemsUnderRectangle: (rectangle)->
			itemsToHighlight = []

			# Add all items which have bounds intersecting with the selection rectangle (1st version)
			for name, item of R.items
				if item instanceof Item.Drawing
					item.unhighlight()
					bounds = item.getBounds()
					if bounds.intersects(rectangle)
						item.highlight()
					# if the user just clicked (not dragged a selection rectangle): just select the first item
					if rectangle.area == 0
						break
			return

		unhighlightItems: ()->
			for name, item of R.items
				if item instanceof Item.Drawing
					item.unhighlight()
			return

		# Create selection rectangle path (remove if existed)
		# @param [Paper event] event containing down and current positions to draw the rectangle
		createSelectionHighlight: (event)->
			rectangle = new P.Rectangle(event.downPoint, event.point)

			# R.currentPaths[R.me] = new P.Group()
			highlightPath = new P.Path.Rectangle(rectangle)
			highlightPath.name = 'select tool selection rectangle'
			highlightPath.strokeColor = R.selectionBlue
			highlightPath.strokeScaling = false
			highlightPath.dashArray = [10, 4]

			R.view.selectionLayer.addChild(highlightPath)
			R.currentPaths[R.me] = highlightPath
			@highlightItemsUnderRectangle(rectangle)
			return

		updateSelectionHighlight: (event)->
			rectangle = new P.Rectangle(event.downPoint, event.point)
			Utils.Rectangle.updatePathRectangle(R.currentPaths[R.me], rectangle)
			@highlightItemsUnderRectangle(rectangle)
			return

		populateItemsToSelect: (itemsToSelect, locksToSelect, rectangle)->
			justClicked = rectangle.area == 0
			if justClicked
				rectangle = rectangle.expand(5)

			
			allDrawingsInRectangleBox = []

			# Add all items which have bounds intersecting with the selection rectangle (1st version)
			for name, item of R.items
				if item.getBounds().intersects(rectangle) and item.isVisible()
					if item instanceof Item.Drawing
						allDrawingsInRectangleBox.push(item)
					else
						# if Item.Drawing.prototype.isPrototypeOf(item)
						# 	itemsToSelect.length = 0
						# 	itemsToSelect.push(item)
						# 	return true
						# else
						# 	itemsToSelect.push(item)

						# if the user just clicked (not dragged a selection rectangle): select all items which match perfectly (perfectly under the mouse)
						if justClicked
							if item instanceof Item.Path
								hitResult = item.performHitTest(rectangle.center, { segments: true, stroke: true, handles: false, tolerance: 5})
								if hitResult?	
									itemsToSelect.push(item)
						else
							itemsToSelect.push(item)

			if allDrawingsInRectangleBox.length == 1
				itemsToSelect.length = 0
				itemsToSelect.push(allDrawingsInRectangleBox[0])

			if justClicked and allDrawingsInRectangleBox.length > 0 and itemsToSelect.length == 0
				for drawing in allDrawingsInRectangleBox
					itemsToSelect.push(drawing)
			return false

		# check if items all have the same parent
		itemsAreSiblings: (itemsToSelect)->
			itemsAreSiblings = true
			parent = itemsToSelect[0].group.parent
			for item in itemsToSelect
				if item.group.parent != parent
					itemsAreSiblings = false
					break
			return itemsAreSiblings

		# remove all lock children from itemsToSelect
		removeLocksChildren: (itemsToSelect, locksToSelect)->
			for lock in locksToSelect
				for child in lock.children()
					Utils.Array.remove(itemsToSelect, child)
			return

		isDrawingSelected: ()->
			for item in R.selectedItems
				if Item.Drawing.prototype.isPrototypeOf(item)
					return true
			return false

		selectItems: (event)->
			rectangle = new P.Rectangle(event.downPoint, event.point)

			itemsToSelect = []
			locksToSelect = []

			selectDrawing = @populateItemsToSelect(itemsToSelect, locksToSelect, rectangle)

			if selectDrawing
				@deselectAll()

			if itemsToSelect.length == 0
				itemsToSelect = locksToSelect

			if itemsToSelect.length > 0

				# # if items have different parents, remove children from itemsToSelect and add locks
				# if not @itemsAreSiblings(itemsToSelect)
				# 	@removeLocksChildren(itemsToSelect, locksToSelect)

				# 	# add locks to itemsToSelect
				# 	itemsToSelect = itemsToSelect.concat(locksToSelect)

				R.commandManager.add(new Command.Select(itemsToSelect), true)
			return

		# Begin selection:
		# - perform hit test to see if there is any item under the mouse
		# - if user hits a path (not in selection group): begin select action (deselect other items by default (= remove selection group), or add to selection if shift pressed)
		# - otherwise: deselect other items (= remove selection group) and create selection rectangle
		# must be reshaped (right not impossible to add a group of RItems to the current selection group)
		begin: (event) ->
			if event.event.which == 2 then return 		# if the wheel button was clicked: return

			itemWasHit = false

			if @selectionRectangle?
				itemWasHit = @selectionRectangle.hitTest(event)

			if not itemWasHit and R.administrator
				path.prepareHitTest() for name, path of R.paths
				hitResult = P.project.hitTest(event.point, @constructor.hitOptions)
				path.finishHitTest() for name, path of R.paths
				controller = hitResult?.item.controller
				controller?.hitTest(event)
				itemWasHit = controller?

			if not itemWasHit
				if not event.event.shiftKey or @isDrawingSelected()
					@deselectAll()
				else
					@selectionRectangle?.remove()
					@selectionRectangle = null
				@createSelectionHighlight(event)
			return


			# # project = if R.view.selectionLayer.children.length == 0 then R.project else R.selectionProject

			# # perform hit test to see if there is any item under the mouse
			# path.prepareHitTest() for name, path of R.paths
			# hitResult = P.project.hitTest(event.point, @constructor.hitOptions)
			# path.finishHitTest() for name, path of R.paths

			# if hitResult and hitResult.item.controller? 		# if user hits a path: select it
			# 	@selectedItem = hitResult.item.controller

			# 	if not event.modifiers.shift 	# if shift is not pressed: deselect previous items
			# 		if R.selectedItems.length>0
			# 			if R.selectedItems.indexOf(hitResult.item?.controller)<0
			# 				R.commandManager.add(new R.DeselectCommand(), true)
			# 		# else
			# 		# 	if R.selectedDivs.length>0 then SelectTool.deselectAll()
			# 	else
			# 		R.Tools['Screenshot'].checkRemoveScreenshotRectangle(hitResult.item.controller)

			# 	hitResult.item.controller.beginSelect?(event)
			# else 												# otherwise: remove selection group and create selection rectangle
			# 	SelectTool.deselectAll()
			# 	@createSelectionRectangle(event)

			# Utils.logElapsedTime()

			# return

		# Update selection:
		# - update selected RItems if there is no selection rectangle
		# - update selection rectangle if there is one
		update: (event) ->
			if @selectionRectangle?
				R.commandManager.updateAction(event)
			else if R.currentPaths[R.me]?
				@updateSelectionHighlight(event)

			# if not R.currentPaths[R.me] and @selectedItem? 			# update selected RItems if there is no selection rectangle
			# 	@selectedItem.updateSelect(event)
			# 	# selectedItems = R.selectedItems
			# 	# if selectedItems.length == 1
			# 	# 	selectedItems[0].updateSelect(event)
			# 	# else
			# 	# 	for item in selectedItems
			# 	# 		item.updateMoveBy?(event)
			# else 									# update selection rectangle if there is one
			# 	@createSelectionRectangle(event)
			return

		# End selection:
		# - end selection action on selected RItems if there is no selection rectangle
		# - create selection group is there is a selection rectangle
		#   update parameters from selected RItems and remove selection rectangle
		end: (event) ->
			if @selectionRectangle?
				R.commandManager.endAction(event)
			else if R.currentPaths[R.me]?
				@selectItems(event)
				R.currentPaths[R.me].remove()
				delete R.currentPaths[R.me]
				@unhighlightItems()

			return

			# if not R.currentPaths[R.me] 		# end selection action on selected RItems if there is no selection rectangle
			# 	# selectedItems = R.selectedItems
			# 	# if selectedItems.length == 1
			# 	@selectedItem.endSelect(event)
			# 	@selectedItem = null
			# else 								# create selection group is there is a selection rectangle

			# 	rectangle = new P.Rectangle(event.downPoint, event.point)

			# 	itemsToSelect = []
			# 	locksToSelect = []

			# 	# Add all items which have bounds intersecting with the selection rectangle (1st version)
			# 	for name, item of R.items
			# 		if item.getBounds().intersects(rectangle)
			# 			if Lock.prototype.isPrototypeOf(item)
			# 				locksToSelect.push(item)
			# 			else
			# 				itemsToSelect.push(item)

			# 	if itemsToSelect.length == 0
			# 		itemsToSelect = locksToSelect

			# 	if itemsToSelect.length > 0

			# 		# check if items all have the same parent
			# 		itemsAreSiblings = true
			# 		parent = itemsToSelect[0].group.parent
			# 		for item in itemsToSelect
			# 			if item.group.parent != parent
			# 				itemsAreSiblings = false
			# 				break

			# 		# if items have different parents, remove children from itemsToSelect and add locks
			# 		if not itemsAreSiblings
			# 			# remove all lock children from itemsToSelect
			# 			for lock in locksToSelect
			# 				for child in lock.children()
			# 					Utils.Array.remove(itemsToSelect, child)

			# 			# add locks to itemsToSelect
			# 			itemsToSelect = itemsToSelect.concat(locksToSelect)

			# 		# if the user just clicked (not dragged a selection rectangle): just select the first item
			# 		if rectangle.area == 0 then itemsToSelect = [itemsToSelect[0]]

			# 		R.commandManager.add(new R.SelectCommand(itemsToSelect), true)

			# 		i = itemsToSelect.length-1
			# 		while i>=0
			# 			item = itemsToSelect[i]
			# 			if not item.isSelected()
			# 				Utils.Array.remove(itemsToSelect, item)
			# 			i--

			# 	# Add all items which intersect with the selection rectangle (2nd version)

			# 	# for item in P.project.activeLayer.children
			# 	# 	bounds = item.bounds
			# 	# 	if item.controller? and (rectangle.contains(bounds) or ( rectangle.intersects(bounds) and item.controller.controlPath?.getIntersections(R.currentPaths[R.me]).length>0 ))
			# 	# 	# if item.controller? and rectangle.intersects(bounds)
			# 	# 		Utils.Array.pushIfAbsent(itemsToSelect, item.controller)

			# 	# for item in itemsToSelect
			# 	# 	item.select(false)

			# 	# # update parameters
			# 	# itemsToSelect = itemsToSelect.map( (item)-> return { tool: item.constructor, item: item } )
			# 	# R.updateParameters(itemsToSelect)

			# 	# for div in R.divs
			# 	# 	if div.getBounds().intersects(rectangle)
			# 	# 		div.select()

			# 	# remove selection rectangle
			# 	R.currentPaths[R.me].remove()
			# 	delete R.currentPaths[R.me]
			# 	for name, item of R.items
			# 		item.unhighlight()

			# console.log 'end select'
			# Utils.logElapsedTime()
			# return

		# Double click handler: send event to selected RItems
		doubleClick: (event) ->
			for item in R.selectedItems
				item.doubleClick?(event)
			return

		# Disable snap while drawnig a selection rectangle
		disableSnap: ()->
			return R.currentPaths[R.me]?

		keyUp: (event)->
			# - move selected Item by delta if an arrow key was pressed (delta is function of special keys press)
			# - finish current path (if in polygon mode) if 'enter' or 'escape' was pressed
			# - select previous tool on space key up
			# - select 'Select' tool if key == 'v'
			# - delete selected item on 'delete' or 'backspace'
			if event.key in ['left', 'right', 'up', 'down']
				delta = if event.modifiers.shift then 50 else if event.modifiers.option then 5 else 1
			switch event.key
				# when 'right'
				# 	item.moveBy(new P.Point(delta,0), true) for item in R.selectedItems
				# when 'left'
				# 	item.moveBy(new P.Point(-delta,0), true) for item in R.selectedItems
				# when 'up'
				# 	item.moveBy(new P.Point(0,-delta), true) for item in R.selectedItems
				# when 'down'
				# 	item.moveBy(new P.Point(0,delta), true) for item in R.selectedItems
				when 'escape'
					@deselectAll()
				when 'delete', 'backspace'
					selectedItems = R.selectedItems.slice()
					for item in selectedItems
						if item.selectionState?.segment?
							item.deletePointCommand()
						else
							item.deleteCommand()

			return

	R.Tools.Select = SelectTool
	return SelectTool
