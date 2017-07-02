define [ 'Items/Item' ], (Item) ->

	class Content extends Item

		# @indexToName =
		# 	0: 'bottomLeft'
		# 	1: 'left'
		# 	2: 'topLeft'
		# 	3: 'top'
		# 	4: 'rotation-handle'
		# 	5: 'top'
		# 	6: 'topRight'
		# 	7: 'right'
		# 	8: 'bottomRight'
		# 	9: 'bottom'

		@initializeParameters: ()->
			parameters = super()
			delete parameters['Items'].align
			parameters['Items'].duplicate = R.parameters.duplicate
			return parameters

		@parameters = @initializeParameters()

		constructor: (@data, @pk, @date, itemListJ, @sortedItems)->
			super(@data, @pk)
			@date ?= Date.now()

			@rotation = @data.rotation or 0

			# @liJ = $("<li>")
			# @liJ.attr("data-pk", @pk)
			# @liJ.click(@onLiClick)
			# @liJ.mouseover (event)=>
			# 	@highlight()
			# 	return
			# @liJ.mouseout (event)=>
			# 	@unhighlight()
			# 	return
			# @liJ.rItem = @
			# itemListJ.prepend(@liJ)
			$("#RItems .mCustomScrollbar").mCustomScrollbar("scrollTo", "bottom")

			@updateZindex()

			return

		getDuplicateData: ()->
			data = super()
			data.lock = @lock?.getPk()
			return data

		onLiClick: (event)=>
			if not event.shiftKey
				R.tools.select.deselectAll()
				bounds = @getBounds()
				if not P.view.bounds.intersects(bounds)
					R.view.moveTo(bounds.center, 1000)
			@select()
			return

		# addToParent: ()->
		# 	bounds = @getBounds()
		# 	lock = Lock.getLockWhichContains(bounds)
		# 	if lock? and lock.owner == R.me
		# 		lock.addItem(@)
		# 	else
		# 		Item.addItemToStage(@)
		# 	return

		# initializeSelection: (event, hitResult) ->
		# 	super(event, hitResult)

		# 	if hitResult?.type == 'segment'
		# 		if hitResult.item == @selectionRectangle 			# if the segment belongs to the selection rectangle: initialize rotation or scaling
		# 			if @constructor.indexToName[hitResult.segment.index] == 'rotation-handle'
		# 				@selectionState = rotation: true
		# 	return

		# # begin select action:
		# # - initialize selection (reset selection state)
		# # - select
		# # - hit test and initialize selection
		# # @param event [Paper event] the mouse event
		# beginSelect: (event) ->
		# 	super(event)
		# 	if @selectionState.rotation?
		# 		@beginAction(new R.RotationCommand(@))
		# 	return

		# # @param bounds [Paper P.Rectangle] the bounds of the selection rectangle
		# createSelectionRectangle: (bounds)->
		# 	@selectionRectangle.insert(1, new P.Point(bounds.left, bounds.center.y))
		# 	@selectionRectangle.insert(3, new P.Point(bounds.center.x, bounds.top))
		# 	@selectionRectangle.insert(3, new P.Point(bounds.center.x, bounds.top-25))
		# 	@selectionRectangle.insert(3, new P.Point(bounds.center.x, bounds.top))
		# 	@selectionRectangle.insert(7, new P.Point(bounds.right, bounds.center.y))
		# 	@selectionRectangle.insert(9, new P.Point(bounds.center.x, bounds.bottom))
		# 	return

		# updateSelectionRectangle: ()->
		# 	super()
		# 	@selectionRectangle.rotation = @rotation
		# 	return

		rotate: (rotation, center, update)->
			@setRotation(@rotation+rotation, center, update)
			return

		setRotation: (rotation, center, update)->

			deltaRotation = rotation-@rotation
			@rotation = rotation
			@group.rotate(deltaRotation, center)

			delta = @rectangle.center.subtract(center)
			@rectangle.center = center.add(delta.rotate(deltaRotation))

			# @rotation = rotation
			# @selectionRectangle.rotation = rotation
			if not @socketAction
				if update then @update('rotation')
				R.socket.emit "bounce", itemPk: @pk, function: "setRotation", arguments: [rotation, center, false]
			return

		# updateSetRotation: (event)->
		# 	rotation = event.point.subtract(@rectangle.center).angle + 90
		# 	if event.modifiers.shift or R.specialKey(event) or Utils.Snap.getSnap() > 1
		# 		rotation = Utils.roundToMultiple(rotation, if event.modifiers.shift then 10 else 5)
		# 	@setRotation(rotation)
		# 	Lock.highlightValidity(@)
		# 	return

		# endSetRotation: (update)->
		# 	if update then @update('rotation')
		# 	return

		# @return [Object] @data along with @rectangle and @rotation
		getData: ()->
			data = jQuery.extend({}, super())
			data.rotation = @rotation
			return data

		getBounds: ()->
			if @rotation == 0 then return @rectangle
			return Utils.Rectangle.getRotatedBounds(@rectangle, @rotation)

		setZindex: ()->
			dateLabel = '' + @date
			dateLabel = dateLabel.substring(dateLabel.length-7, dateLabel.length-3)
			zindexLabel = @constructor.label
			if dateLabel.length>0 then zindexLabel += ' - ' + dateLabel
			# @liJ.text(zindexLabel)
			return

		# update the z index (i.e. move the item to the right position)
		# - RItems are kept sorted by z-index in *R.sortedPaths* and *R.sortedDivs*
		# - z-index are initialized to the current date (this is a way to provide a global z index even with RItems which are not loaded)
		updateZindex: ()->
			if not @date? then return

			if @sortedItems.length==0
				@sortedItems.push(@)
				@setZindex()
				return

			#insert item at the right place
			for item, i in @sortedItems
				if @date < item.date
					@insertBelow(item, i)
					return

			@insertAbove(_.last(@sortedItems))
			return

		# insert above given *item*
		# @param item [Item] item on which to insert this
		# @param index [Number] the index at which to add the item in @sortedItems
		insertAbove: (item, index=null, update=false)->
			@group.insertAbove(item.group)
			if not index
				Utils.Array.remove(@sortedItems, @)
				index = @sortedItems.indexOf(item) + 1
			@sortedItems.splice(index, 0, @)
			# @liJ.insertBefore(item.liJ)
			if update
				if not @sortedItems[index+1]?
					@date = Date.now()
				else
					previousDate = @sortedItems[index-1].date
					nextDate = @sortedItems[index+1].date
					@date = (previousDate + nextDate) / 2
				@update('z-index')
			@setZindex()
			return

		# insert below given *item*
		# @param item [Item] item under which to insert this
		# @param index [Number] the index at which to add the item in @sortedItems
		insertBelow: (item, index=null, update=false)->
			@group.insertBelow(item.group)
			if not index
				Utils.Array.remove(@sortedItems, @)
				index = @sortedItems.indexOf(item)
			@sortedItems.splice(index, 0, @)
			# @liJ.insertAfter(item.liJ)
			if update
				if not @sortedItems[index-1]?
					@date = @sortedItems[index+1].date - 1000
				else
					previousDate = @sortedItems[index-1].date
					nextDate = @sortedItems[index+1].date
					@date = (previousDate + nextDate) / 2
				@update('z-index')
			@setZindex()
			return

		setPK: (pk)->
			super
			# @liJ?.attr("data-pk", @pk)
			return

		# select the Item: (only if it has no selection rectangle i.e. not already selected)
		# @return whether the ritem was selected or not
		select: (updateOptions=true)->
			if not super(updateOptions) then return false

			# @liJ.addClass('selected')

			# update the global selection group (i.e. add this RPath to the group)
			# if @group.parent != R.view.selectionLayer then @zindex = @group.index
			# R.view.selectionLayer.addChild(@group)

			return true

		deselect: (updateOptions=true)->
			if not super(updateOptions) then return false

			# @liJ.removeClass('selected')

			# if @group?
			# 	if not @lock
			# 		R.view.mainLayer.insertChild(@zindex, @group)
			# 	else
			# 		@lock.group.insertChild(@zindex, @group)

			return true

		finish: ()->
			if not super() then return false

			bounds = @getBounds()
			if bounds.area > R.rasterizer.maxArea()
				R.alertManager.alert("The item is too big", "Warning")
				@remove()
				return false

			locks = Item.Lock.getLocksWhichIntersect(bounds)

			for lock in locks
				if lock.rectangle.intersects(bounds)
					if lock.rectangle.contains(bounds) and lock.owner == R.me
						lock.addItem(@)
					else if lock.owner != R.me
						R.alertManager.alert("The item intersects with a lock", "Warning")
						@remove()
						return false

			return true

		remove: ()->
			super()
			if @sortedItems? then Utils.Array.remove(@sortedItems, @)
			# @liJ?.remove()
			return

		delete: ()->
			if @lock? and @lock.owner != R.me then return
			super()
			return

		update: ()->
			return

	Item.Content = Content
	return Content
