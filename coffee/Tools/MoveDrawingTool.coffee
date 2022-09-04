define ['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'Commands/Command' ], (P, R, Utils, Tool, Command) ->

	# MoveDrawingTool to scroll the view in the project space
	class MoveDrawingTool extends Tool

		@label = 'Move drawing'
		@description = ''
		# @iconURL = 'hand.png'
		# @iconURL = 'glyphicon-move'
		# @iconURL = if R.style == 'line' then 'icones_icon_hand.png' else if R.style == 'hand' then 'a-hand1.png' else 'hand.png'
		@iconURL = 'new 1/Move.svg'

		@favorite = true
		@category = ''
		@cursor =
			position:
				x: 16, y: 16
			name: 'move'
			# icon: 'move'
		@buttonClasses = 'dark'
		# @order = 0

		constructor: () ->
			super(true)
			@prevPoint = { x: 0, y: 0 } 	# the previous point the mouse was at
			@dragging = false 				# a boolean to see if user is dragging mouse
			return

		# Select tool and disable Div interactions (to be able to scroll even when user clicks on them, for exmaple disable textarea default behaviour)
		select: (deselectItems=false, updateParameters=true, forceSelect=false, selectedBy='default')->
			super(deselectItems, updateParameters, selectedBy)
			R.tracer?.hide()
			# R.stageJ.addClass("moveTool")
			return

		# Reactivate Div interactions
		deselect: ()->
			super()
			# R.stageJ.removeClass("moveTool")
			return

		begin: (event) ->
			# @dragging = true
			draft = R.Drawing.getDraft()
			@duplicateData = draft?.getDuplicateData()
			if draft?
				@dragging = true

			if R.useSVG and draft.svg?
				draft.svg.remove()
				draft.svg = null
			
			return

		update: (event) ->
			if @dragging
				draft = R.Drawing.getDraft()
				if draft? and draft.rectangle? and draft.group?.children.length > 0
					draft.rectangle.x += event.delta.x
					draft.rectangle.y += event.delta.y
					draft.group.position.x += event.delta.x
					draft.group.position.y += event.delta.y
					# for path in draft.paths
					# 	path.position.x += event.delta.x
					# 	path.position.y += event.delta.y
			return

		end: (moved) ->
			# if moved
			# 	R.commandManager.add(new MoveViewCommand())
			@dragging = false

			draft = R.Drawing.getDraft()
			
			if draft?
				
				if @duplicateData?
					modifyDrawingCommand = new Command.ModifyDrawing(draft, @duplicateData)
					R.commandManager.add(modifyDrawingCommand, false)

				draft.updatePaths()
				draft.createSVG()
				# R.tools['Precise path'].showDraftLimits()
				# R.tools['Precise path'].hideDraftLimits()

			return

		# # begin with jQuery event
		# # note: we could use R.eventToObject to convert the Native event into Paper.ToolEvent, however onMouseDown/Drag/Up also fire begin/update/end
		# beginNative: (event) ->
		# 	@dragging = true
		# 	point = Utils.Event.GetPoint(event)
		# 	@initialPosition = point
		# 	@prevPoint = point
		# 	return

		# # update with jQuery event
		# updateNative: (event) ->
		# 	if @dragging
		# 		point = Utils.Event.GetPoint(event)
		# 		R.view.moveBy({ x: (@prevPoint.x-point.x)/P.view.zoom, y: (@prevPoint.y-point.y)/P.view.zoom })
		# 		@prevPoint = point
		# 	return

		# # end with jQuery event
		# endNative: (event) ->
		# 	# if @initialPosition? and ( @initialPosition.x != event.pageX or @initialPosition.y != event.pageY )
		# 	# 	R.commandManager.add(new MoveViewCommand())
		# 	@dragging = false
		# 	return

	R.Tools.MoveDrawing = MoveDrawingTool
	return MoveDrawingTool
