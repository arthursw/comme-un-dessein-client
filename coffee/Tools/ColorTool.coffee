define ['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'UI/Button', 'Commands/Command', 'Items/Drawing', 'i18next' ], (P, R, Utils, Tool, Button, Command, Drawing, i18next) ->

	# ColorTool: the mother class of all drawing tools
	# doctodo: P.Path are created with three steps:
	# - begin: initialize RPath: create the group, controlPath etc., and initialize the drawing
	# - update: update the drawing
	# - end: finish the drawing and finish RPath initialization
	# doctodo: explain polygon mode
	# begin, update, and end handlers are called by onMouseDown handler (then from == R.me, data == null) and by socket.on "begin" signal (then from == author of the signal, data == Item initial data)
	# begin, update, and end handlers emit the events to websocket
	class ColorTool extends Tool

		@label = 'Color'
		# @description = 'Erase paths'
		
		# @iconURL = 'Color.png'
		# @iconURL = 'glyphicon-erase'
		# @iconURL = 'icones_icon_rubber.png'
		# @iconURL = if R.style == 'line' then 'icones_icon_rubber.png' else if R.style == 'romanesco' then 'Color.png' else if R.style == 'hand' then 'a-Color.png' else 'glyphicon-erase'
		@iconURL = 'new 1/PaintBrush.svg'

		@cursor =
			position:
				x: 0, y: 0
			name: 'crosshair'
		@drawItems = true

		@emitSocket = false
		@buttonClasses = 'dark'

		# Find or create a button for the tool in the sidebar (if the button is created, add it default or favorite tool list depending on the user settings stored in local storage, and whether the tool was just created in a newly created script)
		# set its name and icon if an icon url is provided, or create an icon with the letters of the name otherwise
		# the icon will be made with the first two letters of the name if the name is in one word, or the first letter of each words of the name otherwise
		constructor: (@Path, justCreated=false) ->
			@name = @constructor.label
			@radius = 5
			R.tools[@name] = @

			# check if a button already exists (when created fom a module)
			# @btnJ = R.sidebar.allToolsJ.find('li[data-name="'+@name+'"]')
			@btnJ = R.sidebar.favoriteToolsJ.find('li[data-name="'+@name+'"]')
			
			# create button only if it does not exist
			super(@btnJ.length==0)

			@pathsToDelete = []
			@pathsToCreate = []

			# @sizeButton = new Button(
			# 	name: 'Color size'
			# 	iconURL: 'glyphicon-circle'
			# 	favorite: true
			# 	category: null
			# 	popover: true
			# 	classes: 'dark'
			# 	# prepend: true
			# 	# divType: 'div'
			# )
			# @sizeButton.cloneJ.find('span.glyphicon').css( 'background-color': 'white', 'border-radius': '50%', width: '15px', height: '15px')
			# @sizeButton.hide()

			# sizes = [5, 10, 20, 30]

			# closeSizeMenu = ()->
			# 	$('#size-picker').remove()
			# 	return

			# @sizeButton.cloneJ.find('.glyphicon').css( color: R.selectedColor )

			# @sizeButton.btnJ.click ()=>
			# 	position = @sizeButton.cloneJ.offset()
			# 	height = @sizeButton.cloneJ.outerHeight()
			# 	ulJ = $('<ul>').attr('id', 'size-picker').css( 'background-color': '#33383E', position: 'fixed', top: position.top + height, left: position.left )
			# 	for size in sizes
			# 		liJcss = {
			# 			'width': 50, 
			# 			'height': 50, 
			# 			'cursor': 'pointer', 
			# 			'display': 'flex', 
			# 			'justify-content': 'center',
			# 			'align-items': 'center'
			# 		}
			# 		liJ = $('<li>').attr('data-size', size).css(liJcss)
			# 		liJ.mouseover((event)->
			# 			$(this).css('background-color': '#0079BF')
			# 			return)
			# 		liJ.mouseout((event)->
			# 			$(this).css('background-color': 'transparent')
			# 			return)
			# 		liJ.mousedown((event)=> 
			# 			size = $(event.target).closest('li').attr('data-size')
			# 			@radius = size
			# 			@createCircle()
						
			# 			if R.selectedTool != @
			# 				@select()

			# 			# @sizeButton.cloneJ.find('span.selected-size').css( background: size )
			# 			@sizeButton.cloneJ.find('span.glyphicon').css( width: @radius, height: @radius )
			# 			return)
			# 		iconJ = $('<div>').css( width: size, height: size, 'background-color': 'white', 'border-radius': '50%' )
			# 		liJ.append(iconJ)
			# 		ulJ.append(liJ)
				
			# 	@sizeButton.cloneJ.parent().append(ulJ)
			# 	return
			
			# $(window).mouseup( closeSizeMenu )

			return

		# Remove tool button, useful when user create a tool which already existed (overwrite the tool)
		remove: () ->
			@btnJ.remove()
			return

		setButtonErase: ()->
			@btnJ.removeClass('displayName')
			return

		# Select: add the mouse move listener on the tool (userful when creating a path in polygon mode)
		# todo: move this to main, have a global onMouseMove handler like other handlers
		select: (deselectItems=true, updateParameters=true)->

			# @sizeButton.show()


			$('#draftDrawing').remove()

			super

			R.view.tool.onMouseMove = @move
			return

		updateParameters: ()->
			# # R.controllerManager.setSelectedTool(@Path)
			return

		# Deselect: remove the mouse move listener
		deselect: ()->

			# @sizeButton.hide()

			# draft = Drawing.getDraft()
			# if draft?
			# 	for path in draft.paths
			# 		path.drawOnSVG()

			# @setButtonErase()
			super()
			@finish()
			if @circle?
				@circle.remove()
				@circle = null
				@visualCircle.remove()
				@visualCircle = null
				# clearInterval(@circleIntervalID)
			R.view.tool.onMouseMove = null
			return

		isPathInCircle: (path)->
			for segment in path.segments
				segmentWasFromSplit = segment.data? and segment.data.split
				circleContainsPoint = segmentWasFromSplit or @circle.contains(segment.point)
				if not circleContainsPoint
					return false
			return true

		color: ()->

			# refreshRasterizer = false

			draft = R.Drawing.getDraft()
			if (not draft?) or (not @circle?)
				return
			
			for path in draft.paths.slice()

				if path.bounds.intersects(@circle.bounds)
					intersections = @circle.getCrossings(path)
					
					if intersections.length > 0 or @isPathInCircle(path)
						path.strokeColor = R.selectedColor

			return

		# Begin path action:
		# - deselect all and create new P.Path in all case except in polygonMode (add path to R.currentPaths)
		# - emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse down event
		# @param [String] author (username) of the event
		# @param [Object] Item initial data (strokeWidth, strokeColor, etc.)
		# begin, update, and end handlers are called by onMouseDown handler (then from == R.me, data == null) and by socket.on "begin" signal (then from == author of the signal, data == Item initial data)
		begin: (event, from=R.me, data=null) ->
			if event.event.which == 2 then return 			# if middle mouse button (wheel) pressed: return
			if R.tracer?.draggingImage then return

			@using = true
			@updateCircle(event.point)

			# @circleIntervalID = setInterval(@createCircle, 20)

			draft = R.Drawing.getDraft()
			@duplicateData = draft?.getDuplicateData()

			# @pathsToDelete = []
			# @pathsToCreate = []
			# @pathsToDeleteResurectors = {}


			# R.rasterizer.disableRasterization()

			# if @constructor.emitSocket and R.me? and from==R.me
			# 	# data = R.currentPaths[from].data
			# 	# data.id = R.currentPaths[from].id
			# 	R.socket.emit "bounce", tool: @name, function: "begin", arguments: [event, R.me, null]

			return

		# Update path action:
		# update path action and emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse drag event
		# @param [String] author (username) of the event
		update: (event, from=R.me) ->
			console.log("update")

			@setPosition(event.point)

			if not R.tracer?.draggingImage
				@color()

			# R.currentPaths[from].group.visible = true
			# if R.me? and from==R.me then R.socket.emit( "update", R.me, R.eventToObject(event), @name)
			# if @constructor.emitSocket and R.me? and from==R.me then R.socket.emit "bounce", tool: @name, function: "update", arguments: [event, R.me]
			return

		createCircle: (point)=>
			point ?= @circle?.position
			if not point then return
			@circle?.remove()
			@circle = new P.Path.Circle(point, @radius)
			# @circle.strokeWidth = 1
			# @circle.strokeColor = '#2fa1d6'
			# @circle.strokeScaling = false

			R.view.selectionLayer.addChild(@circle)
			@circle.sendToBack()

			@visualCircle?.remove()
			@visualCircle = new P.Path.Circle(point, @radius - R.Path.strokeWidth / 2)
			@visualCircle.strokeWidth = 1
			@visualCircle.strokeColor = '#2fa1d6'
			@visualCircle.strokeScaling = false

			R.view.selectionLayer.addChild(@visualCircle)
			@visualCircle.sendToBack()
			# if @radius < 15
			# 	@radius += 0.5
			return

		setPosition: (point)->
			if @circle?
				@circle.position = point
				@visualCircle.position = point
			return

		updateCircle: (point)->
			# if R.currentPaths[R.me]?.data?.polygonMode then R.currentPaths[R.me].createMove?(event)
			if not @circle?
				@createCircle(point)
			else
				@setPosition(point)
			return

		# Update path action (usually from a mouse move event, necessary for the polygon mode):
		# @param [Paper event or REvent] (usually) mouse move event
		move: (event) ->
			R.tools.Color.updateCircle(event.point)
			return

		# End path action:
		# - end path action
		# - if not in polygon mode: select and save path and emit event on websocket (if user is the author of the event), (remove path from R.currentPaths)
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		end: (event, from=R.me) ->
			@setPosition(event.point)
			
			if not R.tracer?.draggingImage
				@color()

			# clearInterval(@circleIntervalID)
			# @radius = 0.1

			draft = R.Drawing.getDraft()
			
			if draft?
				
				if @duplicateData?
					modifyDrawingCommand = new Command.ModifyDrawing(draft, @duplicateData)
					R.commandManager.add(modifyDrawingCommand, false)

				draft.updatePaths()
				R.toolManager.updateButtonsVisibility(draft)
			

			# # remove paths to delete from paths to create
			# pathsToCreate = []
			# for path in @pathsToCreate
			# 	if @pathsToDelete.indexOf(path) < 0
			# 		pathsToCreate.push(path)

			# # remove paths which were not saved
			# pathsToDelete = []
			# pathsToDeleteResurectors = {}
			# for path in @pathsToDelete
			# 	if path.pk?
			# 		pathsToDelete.push(path)
			# 		pathsToDeleteResurectors[path.id] = @pathsToDeleteResurectors[path.id]

			# deleteCommand = null
			# if pathsToDelete.length > 0
			# 	deleteCommand = new Command.DeleteItems(pathsToDelete, pathsToDeleteResurectors)
			# 	R.commandManager.add(deleteCommand, false)
			
			# if pathsToCreate.length > 0
			# 	createCommand = new Command.CreateItems(pathsToCreate)
			# 	R.commandManager.add(createCommand, false)
			# 	if deleteCommand?
			# 		deleteCommand.twin = createCommand
			# 		createCommand.twin = deleteCommand

			# for path in pathsToDelete
			# 	path.delete()

			# for path in pathsToCreate
			# 	path.save()
			# 	# if not path.drawing? then path.draw?()
			# 	# if R.rasterizer.rasterizeItems then path.rasterize?()

			# R.rasterizer.enableRasterization(false)

			@using = false
			return

		# Finish path action (necessary in polygon mode):
		# - check that we are in polygon mode (return otherwise)
		# - end path action
		# - select and save path and emit event on websocket (if user is the author of the event), (remove path from R.currentPaths)
		# @param [String] author (username) of the event
		finish: (from=R.me)->

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

	R.Tools.ColorTool = ColorTool
	return ColorTool
