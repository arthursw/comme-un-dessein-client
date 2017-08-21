define ['paper', 'R', 'Utils/Utils', 'Tools/Tool' ], (P, R, Utils, Tool) ->

	# MoveTool to scroll the view in the project space
	class MoveTool extends Tool

		@label = 'Move'
		@description = ''
		# @iconURL = 'hand.png'
		# @iconURL = 'glyphicon-move'
		@iconURL = if R.style == 'line' then 'icones_icon_hand.png' else if R.style == 'hand' then 'a-hand1.png' else 'hand.png'

		@favorite = true
		@category = ''
		@cursor =
			position:
				x: 32, y: 32
			name: 'default'
			icon: if R.style == 'line' then 'icones_hand_mouse' else 'hand'
		@order = 0

		constructor: () ->
			super(true)
			@prevPoint = { x: 0, y: 0 } 	# the previous point the mouse was at
			@dragging = false 				# a boolean to see if user is dragging mouse
			return

		# Select tool and disable Div interactions (to be able to scroll even when user clicks on them, for exmaple disable textarea default behaviour)
		select: (deselectItems=false, updateParameters=true)->
			super(deselectItems, updateParameters)
			R.stageJ.addClass("moveTool")
			for div in R.divs
				div.disableInteraction()
			return

		# Reactivate Div interactions
		deselect: ()->
			super()
			R.stageJ.removeClass("moveTool")
			for div in R.divs
				div.enableInteraction()
			return

		begin: (event) ->
			# @dragging = true
			return

		update: (event) ->
			# if @dragging
			# 	R.view.moveBy(event.delta)
			return

		end: (moved) ->
			# if moved
			# 	R.commandManager.add(new MoveViewCommand())
			# @dragging = false
			return

		# begin with jQuery event
		# note: we could use R.eventToObject to convert the Native event into Paper.ToolEvent, however onMouseDown/Drag/Up also fire begin/update/end
		beginNative: (event) ->
			@dragging = true
			point = Utils.Event.GetPoint(event)
			@initialPosition = point
			@prevPoint = point
			return

		# update with jQuery event
		updateNative: (event) ->
			if @dragging
				point = Utils.Event.GetPoint(event)
				R.view.moveBy({ x: (@prevPoint.x-point.x)/P.view.zoom, y: (@prevPoint.y-point.y)/P.view.zoom })
				@prevPoint = point
			return

		# end with jQuery event
		endNative: (event) ->
			# if @initialPosition? and ( @initialPosition.x != event.pageX or @initialPosition.y != event.pageY )
			# 	R.commandManager.add(new MoveViewCommand())
			@dragging = false
			return

	R.Tools.Move = MoveTool
	return MoveTool
