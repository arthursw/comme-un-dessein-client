define ['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'UI/Button', 'Commands/Command', 'Items/Drawing', 'i18next' ], (P, R, Utils, Tool, Button, Command, Drawing, i18next) ->

	# EraseTool: the mother class of all drawing tools
	# doctodo: P.Path are created with three steps:
	# - begin: initialize RPath: create the group, controlPath etc., and initialize the drawing
	# - update: update the drawing
	# - end: finish the drawing and finish RPath initialization
	# doctodo: explain polygon mode
	# begin, update, and end handlers are called by onMouseDown handler (then from == R.me, data == null) and by socket.on "begin" signal (then from == author of the signal, data == Item initial data)
	# begin, update, and end handlers emit the events to websocket
	class EraserTool extends Tool

		@label = 'Eraser'
		@description = 'Erase paths'
		
		# @iconURL = 'eraser.png'
		# @iconURL = 'glyphicon-erase'
		# @iconURL = 'icones_icon_rubber.png'
		@iconURL = if R.style == 'line' then 'icones_icon_rubber.png' else if R.style == 'romanesco' then 'eraser.png' else if R.style == 'hand' then 'a-eraser.png' else 'glyphicon-erase'
		
		@cursor =
			position:
				x: 0, y: 0
			name: 'crosshair'
		@drawItems = true

		@emitSocket = false

		# Find or create a button for the tool in the sidebar (if the button is created, add it default or favorite tool list depending on the user settings stored in local storage, and whether the tool was just created in a newly created script)
		# set its name and icon if an icon url is provided, or create an icon with the letters of the name otherwise
		# the icon will be made with the first two letters of the name if the name is in one word, or the first letter of each words of the name otherwise
		constructor: (@Path, justCreated=false) ->
			@name = @constructor.label
			@radius = 15
			R.tools[@name] = @

			# check if a button already exists (when created fom a module)
			# @btnJ = R.sidebar.allToolsJ.find('li[data-name="'+@name+'"]')
			@btnJ = R.sidebar.favoriteToolsJ.find('li[data-name="'+@name+'"]')
			
			# create button only if it does not exist
			super(@btnJ.length==0)

			@pathsToDelete = []
			@pathsToCreate = []

			return

		# Remove tool button, useful when user create a tool which already existed (overwrite the tool)
		remove: () ->
			@btnJ.remove()
			return

		setButtonEraseAll: ()->
			newName = i18next.t('Erase all')
			@btnJ.addClass('displayName')
			@btnJ.find('.tool-name').show().attr('data-i18n', newName).text(newName)
			@btnJ.find('img').attr('src', '/static/images/icons/inverted/icones_cancel.png')
			return
		
		setButtonErase: ()->
			@btnJ.removeClass('displayName')
			return

		deleteAllPaths: ()->
			paths = R.Drawing.getDraft()?.paths or []
			
			# for id, path of R.paths
			# 	if path.isDraft()
			# 		paths.push(path)

			R.drawingPanel.deleteGivenPaths(paths)
			@setButtonErase()
			return

		# Select: add the mouse move listener on the tool (userful when creating a path in polygon mode)
		# todo: move this to main, have a global onMouseMove handler like other handlers
		select: (deselectItems=true, updateParameters=true)->

			# if R.selectedTool != @
			# 	@setButtonEraseAll()
			# else
			# 	@deleteAllPaths()
			# 	return

			# R.rasterizer.drawItems()

			draft = Drawing.getDraft()
			if draft?
				for path in draft.paths
					path.drawOnPaper()

			$('#draftDrawing').remove()

			super

			R.view.tool.onMouseMove = @move
			return

		updateParameters: ()->
			# R.controllerManager.setSelectedTool(@Path)
			return

		# Deselect: remove the mouse move listener
		deselect: ()->

			draft = Drawing.getDraft()
			if draft?
				for path in draft.paths
					path.drawOnSVG()

			# @setButtonErase()
			super()
			@finish()
			if @circle?
				@circle.remove()
				@circle = null
			R.view.tool.onMouseMove = null
			return

		isPathInCircle: (path)->
			for segment in path.segments
				segmentWasFromSplit = segment.data? and segment.data.split
				circleContainsPoint = segmentWasFromSplit or @circle.contains(segment.point)
				if not circleContainsPoint
					return false
			return true

		erase: ()->

			# refreshRasterizer = false

			draft = R.Drawing.getDraft()
			if not draft?
				return
			
			for item in draft.paths.slice()

					if item.getBounds().intersects(@circle.bounds)

						intersections = @circle.getCrossings(item.controlPath)
						
						if intersections.length > 0

							paths = [item.controlPath]
							console.log(intersections)
							
							# @pathsToDeleteResurectors[item.id] = data: item.getDuplicateData(), constructor: item.constructor

							for intersection in intersections
								for p in paths
									location = p.getLocationOf(intersection.point)
									if location?
										console.log('split: ' + location.point)
										newP = p.split(location)
										p.lastSegment.handleOut = null
										p.lastSegment.data = split: true
										if newP?
											paths.push(newP)
											newP.firstSegment.handleIn = null
											newP.firstSegment.data = split: true

							# refreshRasterizer = true
							
							item.remove()
							# @pathsToDelete.push(item)

							for p in paths
								if @isPathInCircle(p)
									console.log('remove a path')
									p.remove()
								else
									data = R.Tools.Item.Item.PrecisePath.getDataFromPath(p)
									points = R.Tools.Item.Item.Path.pathOnPlanetFromPath(p)
									path = new R.Tools.Item.Item.PrecisePath(Date.now(), data, null, null, points, null, R.me, draft.id)
									path.draw(false, true, false)
									# @pathsToCreate.push(path)
						else
							if @isPathInCircle(item.controlPath)
								# @pathsToDeleteResurectors[item.id] = data: item.getDuplicateData(), constructor: item.constructor
								item.remove()
								# @pathsToDelete.push(item)
								# refreshRasterizer = true

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

			@updateCircle(event.point)

			draft = R.Drawing.getDraft()
			@duplicateData = draft?.getDuplicateData()

			# @pathsToDelete = []
			# @pathsToCreate = []
			# @pathsToDeleteResurectors = {}


			# R.rasterizer.disableRasterization()

			if @constructor.emitSocket and R.me? and from==R.me
				# data = R.currentPaths[from].data
				# data.id = R.currentPaths[from].id
				R.socket.emit "bounce", tool: @name, function: "begin", arguments: [event, R.me, null]

			return

		# Update path action:
		# update path action and emit event on websocket (if user is the author of the event)
		# @param [Paper event or REvent] (usually) mouse drag event
		# @param [String] author (username) of the event
		update: (event, from=R.me) ->
			console.log("update")

			@circle.position = event.point

			@erase()

			# R.currentPaths[from].group.visible = true
			# if R.me? and from==R.me then R.socket.emit( "update", R.me, R.eventToObject(event), @name)
			if @constructor.emitSocket and R.me? and from==R.me then R.socket.emit "bounce", tool: @name, function: "update", arguments: [event, R.me]
			return

		createCircle: (point)->
			@circle = new P.Path.Circle(point, @radius)
			@circle.strokeWidth = 1
			@circle.strokeColor = '#2fa1d6'
			@circle.strokeScaling = false
			R.view.selectionLayer.addChild(@circle)
			return

		updateCircle: (point)->
			# if R.currentPaths[R.me]?.data?.polygonMode then R.currentPaths[R.me].createMove?(event)
			if not @circle?
				@createCircle(point)
			else
				@circle.position = point
			return

		# Update path action (usually from a mouse move event, necessary for the polygon mode):
		# @param [Paper event or REvent] (usually) mouse move event
		move: (event) ->
			console.log("move")
			R.tools.eraser.updateCircle(event.point)
			return

		# End path action:
		# - end path action
		# - if not in polygon mode: select and save path and emit event on websocket (if user is the author of the event), (remove path from R.currentPaths)
		# @param [Paper event or REvent] (usually) mouse up event
		# @param [String] author (username) of the event
		end: (event, from=R.me) ->
			@circle.position = event.point
			@erase()

			draft = R.Drawing.getDraft()
			
			if draft?
				
				if @duplicateData?
					modifyDrawingCommand = new Command.ModifyDrawing(draft, @duplicateData)
					R.commandManager.add(modifyDrawingCommand, false)

				draft.updatePaths()
				R.Button.updateSubmitButtonVisibility(draft)
			

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

	R.Tools.Eraser = EraserTool
	return EraserTool
