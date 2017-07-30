define ['paper', 'R', 'Utils/Utils', 'Items/Item', 'UI/Modal' ], (P, R, Utils, Item, Modal) ->

	# Drawing can only be modified by their author

	# There are different Drawings:
	# - Drawing: a simple Drawing which just drawings the area and the items underneath, and displays a popover with a message when the user clicks on it
	# - Link: extends Drawing but works as a link: the one who clicks on it is redirected to the website

	# an Drawing can be set in background mode ({Drawing#updateBackgroundMode}):
	# - this hide the jQuery div and display a equivalent rectangle on the paper project instead (named controlPath in the code)
	# - it is usefull to add and edit items on the area
	#

	class Drawing extends Item
		@label = 'Drawing'
		@object_type = 'drawing'

		@pkToId = {}

		@initialize: (rectangle)->
			return

		@initializeParameters: ()->
			parameters = super()
			delete parameters['Style']
			return parameters

		@parameters = @initializeParameters()

		@create: (duplicateData)->
			copy = new @(null, duplicateData.data, duplicateData.id, null, duplicateData.owner, Date.now(), duplicateData.title, duplicateData.description)
			for id in duplicateData.pathIds
				if R.items[id]?
					copy.addChild(R.items[id])
			copy.rasterize()
			R.rasterizer.rasterize(copy, false)

			# copy.drawChildren()
			if not @socketAction
				copy.save(false)
				R.socket.emit "bounce", itemClass: @name, function: "create", arguments: [duplicateData]
			return copy

		constructor: (@rectangle, @data=null, @id=null, @pk=null, @owner=null, @date, @title, @description, @status='pending') ->
			super(@data, @id, @pk)

			if @pk?
				@constructor.pkToId[@pk] = @id

			@drawing = new P.Group()

			@group.addChild(@drawing)

			@votes = [] # { positive: boolean, author: string, authorPk: pk }

			for id, path of R.paths
				if path.drawingId? and (path.drawingId == @id or path.drawingId == @pk)
					@addChild(path)

			# create special list to contains children paths
			@sortedPaths = []

			@addToListItem(@getListItem())
			
			# @itemListsJ = R.templatesJ.find(".layer").clone()
			# pkString = '' + (@pk or @id)
			# pkString = pkString.substring(pkString.length-3)
			# title = '' + @title + ' by ' + @owner
			# # if @owner then title += " of " + @owner
			# titleJ = @itemListsJ.find(".title")
			# titleJ.text(title)
			# titleJ.click (event)=>
			# 	@itemListsJ.toggleClass('closed')
			# 	if not event.shiftKey
			# 		R.tools.select.deselectAll()
			# 	@select()
			# 	return

			# @itemListsJ.find('.rPath-list').sortable( stop: Item.zIndexSortStop, delay: 250 )

			# @itemListsJ.mouseover (event)=>
			# 	@highlight()
			# 	return
			# @itemListsJ.mouseout (event)=>
			# 	@unhighlight()
			# 	return

			# R.sidebar.itemListsJ.prepend(@itemListsJ)
			# @itemListsJ = R.sidebar.itemListsJ.find(".layer:first")

			return
		
		getPathIds: ()->
			pathIds = []
			for child in @children()
				pathIds.push(child.id)
			return pathIds

		getDuplicateData: ()->
			data = super
			data.title = @title
			data.description = @description
			data.pathIds = @getPathIds()
			return data

		getListItem: ()->

			itemListJ = null
			switch @status
				when 'pending'
					R.view.pendingLayer.addChild(@group)
					itemListJ = R.view.pendingListJ
				when 'drawing'
					R.view.drawingLayer.addChild(@group)
					itemListJ = R.view.drawingListJ
				when 'drawn'
					R.view.drawnLayer.addChild(@group)
					itemListJ = R.view.drawnListJ
				when 'rejected'
					R.view.rejectedLayer.addChild(@group)
					itemListJ = R.view.rejectedListJ
				else
					R.alertManager.alert "Error: drawing status is invalid.", "error"

			return itemListJ

		addToListItem: (@itemListJ)->

			title = '' + @title + ' by ' + @owner
			@liJ = $("<li>")
			@liJ.html(title)
			@liJ.attr("data-id", @id)
			@liJ.click(@onLiClick)
			@liJ.mouseover (event)=>
				@highlight()
				return
			@liJ.mouseout (event)=>
				@unhighlight()
				return
			@liJ.rItem = @

			@itemListJ?.find('.rPath-list').prepend(@liJ)

			nItemsJ = @itemListJ?.find(".n-items")
			
			if nItemsJ? and nItemsJ.length>0
				nItemsJ.html(@itemListJ.find('.rPath-list').children().length)

			return

		removeFromListItem: ()->
			@liJ.remove()
			nItemsJ = @itemListJ?.find(".n-items")
			if nItemsJ? and nItemsJ.length>0
				nItemsJ.html(@itemListJ.find('.rPath-list').children().length)
			return

		onLiClick: (event)=>
			# if not event.shiftKey
			R.tools.select.deselectAll()
			bounds = @getBounds()
			if not P.view.bounds.intersects(bounds)
				R.view.moveTo(bounds.center, 1000)
			@select()
			return

		computeRectangle: ()->
			for child of @drawing.children
				path = child.controller
				if not path? then continue
				bounds = path.getDrawingBounds()
				if bounds?
					@rectangle ?= bounds.clone()
					@rectangle = @rectangle.unite(bounds)
			return

		addChild: (path)->
			path.drawingId = @id
			path.group.visible = true # can be hidden by rasterizer, must be shown here to update @drawing.bounds
			@pathPks ?= []
			if not path.pk?
				R.alertManager.alert 'Error: a path has not been saved yet. Please wait until the path is saved before creating the drawing.', 'error'
				return
			@pathPks.push(path.pk)
			@drawing.addChild(path.group)
			bounds = path.getDrawingBounds()
			if bounds?
				@rectangle ?= bounds.clone()
				@rectangle = @rectangle.unite(bounds)
			path.updateStrokeColor()
			path.removeFromListItem()
			@drawn = false
			if @raster? and @raster.parent != null 	# if this was rasterized: clear raster and replace by drawing to be able to re-rasterize with the new path
				@replaceDrawing()
			return
		
		removeChild: (path, updateRectangle=true, updateRaster=false)->
			path.drawingId = null
			pkIndex = @pathPks.indexOf(path.pk)
			if pkIndex >= 0
				@pathPks.splice(pkIndex, 1)
			R.view.mainLayer.addChild(path.group)
			if updateRectangle
				@computeRectangle()
			path.updateStrokeColor()
			path.addToListItem()
			@drawn = false
			if updateRaster and @raster? and @raster.parent != null 	# if this was rasterized: clear raster and replace by drawing to be able to re-rasterize with the new path
				@replaceDrawing()
			R.rasterizer.rasterize(path, false)
			path.draw?()
			path.rasterize()
			return

		# @param name [String] the name of the value to change
		# @param value [Anything] the new value
		# @param updateGUI [Boolean] (optional, default is false) whether to update the GUI (parameters bar), true when called from SetParameterCommand
		setParameter: (name, value, updateGUI, update)->
			super(name, value, updateGUI, update)
			return

		save: (addCreateCommand=true) ->

			if R.view.grid.rectangleOverlapsTwoPlanets(@rectangle)
  				# R.alertManager.alert 'Your item overlaps with two planets.', 'error'
				return

			if @rectangle.with == 0 and @rectangle.height == 0 or @drawing.children.length == 0
				@remove()
				R.alertManager.alert "Error: The drawing is empty.", "error"
				return

			args = {
				clientId: @id
				date: @date
				pathPks: @pathPks
				title: @title
				description: @description
			}

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'saveDrawing', args: args } ).done(@saveCallback)

			super(addCreateCommand)
			return

		# check if the save was successful and set @pk if it is
		saveCallback: (result)=>

			R.loader.checkError(result)
			if not result.pk?  		# if @pk is null, the path was not saved, do not set pk nor rasterize
				@remove()
				return

			@owner = result.owner
			@setPK(result.pk)

			R.alertManager.alert "Drawing successfully submitted. It will be drawn if it gets 100 votes.", "success"

			if @selectAfterSave?
				@select(true, true, true)

			if @updateAfterSave?
				@update(@updateAfterSave)
			super
			return

		addUpdateFunctionAndArguments: (args, type)->
			for item in @children()
				item.addUpdateFunctionAndArguments(args, type)
			return

		updateCallback: (result)=>
			if not R.loader.checkError(result)
				@title = @previousTitle
				@description = @previousDescription
				contentJ = R.drawingPanel.drawingPanelJ.find('.content')
				contentJ.find('#drawing-title').val(@title)
				contentJ.find('#drawing-description').val(@description)
				return
			R.alertManager.alert "Drawing successfully modified.", "success"
			return

		update: (data) =>
			if not @pk?
				@updateAfterSave = data
				return
			delete @updateAfterSave

			@previousTitle = @title
			@previousDescription = @description

			@title = data.title
			@description = data.description
			
			args = {
				pk: @pk
				title: @title
				description: @description
			}

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'updateDrawing', args: args } ).done(@updateCallback)

			return

		deleteFromDatabaseCallback: ()=>
			if not R.loader.checkError()
				if @pathIdsBeforeRemove?
					for id in @pathIdsBeforeRemove
						if R.items[id]?
							@addChild(R.items[id])
					@rasterize()
					R.rasterizer.rasterize(@, false)
				return
			super()
			R.alertManager.alert "Drawing successfully cancelled.", "success"
			return

		delete: ()->
			@pathIdsBeforeRemove = @getPathIds()
			super
			return

		# called when user deletes the item by pressing delete key or from the gui
		# @delete() removes the item and delete it in the database
		# @remove() just removes visually
		deleteFromDatabase: () ->
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'deleteDrawing', args: { 'pk': @pk } } ).done(@deleteFromDatabaseCallback())
			return

		setRectangle: (rectangle, update=true)->
			super(rectangle, update)
			return

		moveTo: (position, update)->
			delta = position.subtract(@rectangle.center)
			for item in @children()
				item.rectangle.center.x += delta.x
				item.rectangle.center.y += delta.y
				if Item.Div.prototype.isPrototypeOf(item)
					item.updateTransform()
			super(position, update)
			return

		# check if drawing contains its children
		containsChildren: ()->
			for item in @children()
				if not @rectangle.contains(item.getBounds())
					return false
			return true

		showChildren: ()->
			for item in @children()
				item.group?.visible = true
			return

		updateDrawingPanel: ()->
			args =
				pk: @pk

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawing', args: args } ).done((result)=>
				R.drawingPanel.setDrawing(@, result)
			)
			return

		# can not select a drawing which the user does not own
		select: (updateOptions=true, showPanelAndLoad=true, force=false) =>
			if not super(updateOptions, force) then return false
			
			for item in @children()
				item.deselect()

			if showPanelAndLoad
				R.drawingPanel.showLoadAnimation()
				R.drawingPanel.open()

				if @pk?
					delete @selectAfterSave
					@updateDrawingPanel()
				else
					@selectAfterSave = true

			return true
		
		deselect: (updateOptions=true)->
			if not super(updateOptions) then return false
			R.drawingPanel.close()
			R.drawingPanel.hideSubmitDrawing()
			return true

		remove: () ->
			for path in @children()
				@removeChild(path)

			@removeFromListItem()
			super
			return

		children: ()->
			paths = []
			for child in @drawing.children
				paths.push(child.controller)
			return paths

		highlight: (color)->
			super()
			if color
				@highlightRectangle.fillColor = color
				@highlightRectangle.strokeColor = color
				@highlightRectangle.dashArray = []
			return

		drawChildren: ()->
			if @drawing.children.length == 0 then return
			
			for child in @drawing.children
				child.controller.draw?()
			return

		# disable rasterize if no children
		rasterize: ()->	
			if @raster? or not @drawing? then return
			# make sure children are drawn BEFORE this, otherwise this can be rasterized before children are drawn, see Rasterizer.drawItems()
			@drawChildren()
			super()
			return

	Item.Drawing = Drawing
	return Drawing
