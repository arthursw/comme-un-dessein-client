define [ 'Items/Item', 'UI/Modal' ], (Item, Modal) ->

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

		@initialize: (rectangle)->
			return

		@initializeParameters: ()->
			parameters = super()
			delete parameters['Style']
			return parameters

		@parameters = @initializeParameters()

		constructor: (@rectangle, @data=null, @pk=null, @owner=null, @date, @title, @description, @status) ->
			super(@data, @pk)

			@drawing = new P.Group()

			@group.addChild(@drawing)

			@votes = [] # { positive: boolean, author: string, authorPk: pk }

			for pk of R.paths
				path = R.paths[pk]
				if path.drawingPk? == @pk
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
			@liJ.attr("data-pk", @pk)
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

		addChild: (path)->
			@drawing.addChild(path.group)
			path.updateStrokeColor()
			@drawn = false
			if @raster? and @raster.parent != null 	# if this was rasterized: clear raster and replace by drawing to be able to re-rasterize with the new path
				@replaceDrawing()
			return

		# @param name [String] the name of the value to change
		# @param value [Anything] the new value
		# @param updateGUI [Boolean] (optional, default is false) whether to update the GUI (parameters bar), true when called from SetParameterCommand
		setParameter: (name, value, updateGUI, update)->
			super(name, value, updateGUI, update)
			return

		save: (addCreateCommand=true) ->

			if R.view.grid.rectangleOverlapsTwoPlanets(@rectangle)
				return

			if @rectangle.area == 0
				@remove()
				R.alertManager.alert "Error: your box is not valid.", "error"
				return

			data = @getData()

			siteData =
				restrictArea: data.restrictArea
				disableToolbar: data.disableToolbar
				loadEntireArea: data.loadEntireArea

			args =
				city: city: R.city
				box: Utils.CS.boxFromRectangle(@rectangle)
				object_type: @constructor.object_type
				data: JSON.stringify(data)
				siteData: JSON.stringify(siteData)
				siteName: data.siteName

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'saveBox', args: args } ).done(@saveCallback)
			# Dajaxice.draw.saveBox( @saveCallback, args)
			super
			return

		# check if the save was successful and set @pk if it is
		saveCallback: (result)=>
			R.loader.checkError(result)
			if not result.pk?  		# if @pk is null, the path was not saved, do not set pk nor rasterize
				@remove()
				return

			@owner = result.owner
			@setPK(result.pk)

			if @updateAfterSave?
				@update(@updateAfterSave)
			super
			return

		addUpdateFunctionAndArguments: (args, type)->
			for item in @children()
				item.addUpdateFunctionAndArguments(args, type)
			return

		update: (type) =>
			if not @pk?
				@updateAfterSave = type
				return
			delete @updateAfterSave

			# check if position is valid
			if R.view.grid.rectangleOverlapsTwoPlanets(@rectangle)
				return

			# initialize data to be saved
			updateBoxArgs =
				box: Utils.CS.boxFromRectangle(@rectangle)
				pk: @pk
				object_type: @object_type
				name: @data.name
				data: @getStringifiedData()
				updateType: type 		# not used anymore
				# message: @data.message

			# Dajaxice.draw.updateBox( @updateCallback, args )
			args = []
			args.push( function: 'updateBox', arguments: updateBoxArgs )

			if type == 'position' or type == 'rectangle'
				itemsToUpdate = if type == 'position' then @children() else []

				for item in itemsToUpdate
					args.push( function: item.getUpdateFunction(), arguments: item.getUpdateArguments() )

			# Dajaxice.draw.multipleCalls( @updateCallback, functionsAndArguments: args)
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'multipleCalls', args: functionsAndArguments: args } ).done(@updateCallback)
			return

		updateCallback: (results)->
			for result in results
				R.loader.checkError(result)
			return

		# called when user deletes the item by pressing delete key or from the gui
		# @delete() removes the item and delete it in the database
		# @remove() just removes visually
		deleteFromDatabase: () ->
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'deleteBox', args: { 'pk': @pk } } ).done(R.loader.checkError)
			# Dajaxice.draw.deleteBox( R.loader.checkError, { 'pk': @pk } )
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

		# can not select a drawing which the user does not own
		select: (updateOptions=true) =>
			if not super(updateOptions) then return false
			for item in @children()
				item.deselect()

			R.drawingPanel.showLoadAnimation()
			R.drawingPanel.open()

			args =
				pk: @pk

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawing', args: args } ).done((result)=>
				R.drawingPanel.setDrawing(@, result)
			)

			return true

		remove: () ->
			for path in @children()
				@removeItem(path)

			# @itemListsJ.remove()
			# @itemListsJ = null
			Utils.Array.remove(R.drawings, @)
			@removeFromListItem()
			super
			return

		children: ()->
			return @sortedPaths

		addItem: (item)->
			Item.addItemTo(item, @)
			item.drawing = @
			return

		removeItem: (item)->
			Item.addItemToStage(item)
			item.drawing = null
			return

		highlight: (color)->
			super()
			if color
				@highlightRectangle.fillColor = color
				@highlightRectangle.strokeColor = color
				@highlightRectangle.dashArray = []
			return

		# disable rasterize if no children
		rasterize: ()->	
			if @drawing.children.length == 0 then return

			# make sure children are drawn BEFORE this, otherwise this can be rasterized before children are drawn, see Rasterizer.drawItems()
			
			for child in @drawing.children
				child.controller.draw?()

			super()
			return
		
		deleteCommand: ()->
			return

	Item.Drawing = Drawing
	return Drawing
