define ['paper', 'R', 'Utils/Utils', 'Items/Item', 'UI/Modal', 'i18next' ], (P, R, Utils, Item, Modal, i18next) ->

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
		@draft = null

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
				# R.socket.emit "bounce", itemClass: @name, function: "create", arguments: [duplicateData]
			return copy


		@getDraft: ()->
			return @draft

		constructor: (@rectangle, @data=null, @id=null, @pk=null, @owner=null, @date, @title, @description, @status='pending', pathList=[], svg=null, bounds=null) ->
			super(@data, @id, @pk)

			if @pk?
				@constructor.pkToId[@pk] = @id

			if bounds?
				@bounds = new P.Rectangle(bounds)

			R.drawings.push(@)

			R.pkToDrawing ?= {}
			R.pkToDrawing[@pk] = @

			@paths = []
			# @drawing = new P.Group()

			# @group.addChild(@drawing)
			@group.remove()

			@votes = [] # { positive: boolean, author: string, authorPk: pk }
			
			# create special list to contains children paths
			@sortedPaths = []

			@addToListItem(@getListItem())
			
			if @status == 'draft'
				@constructor.draft = @
				@addPathsFromPathList(pathList)
			else if @pk?
				jqxhr = $.get( location.origin + '/static/drawings/' + @pk + '.svg', ((result)=>
					# console.log( "success" )
					# console.log( result )
					@setSVG(result, false)
					return
				))
				# .done(()=>
				# 	console.log("second success" )
				# )
				.fail(()=>

					# console.log("error" )
					if @svg? then return

					args =
						pk: @pk
						svgOnly: true
					$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawing', args: args } ).done((result)=>
						drawing = JSON.parse(result.drawing)
						if drawing.svg?
							@setSVG(drawing.svg)
					)
				)
				# .always(()=>
				# 	console.log("finished" )
				# )
			# if svg?
				# @setSVG(svg)
			
			# path.rasterize()
			# R.rasterizer.rasterize(path)


			# for id, path of R.paths
			# 	if path.drawingId? and (path.drawingId == @id or path.drawingId == @pk)
			# 		@addChild(path)

			
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
		
		setPK: (pk)->
			super(pk)
			R.pkToDrawing ?= {}
			R.pkToDrawing[@pk] = @
			return

		getPointLists: ()->
			pointLists = []
			for path in @paths
				pointLists.push(path.getPoints())
			return pointLists

		addPathsFromPathList: (pathList, parseJSON=true, highlight=false)->
			for p in pathList
				points = if parseJSON then JSON.parse(p) else p
				if not points? then continue
				data = 
					points: points
					planet: new P.Point(0, 0)
					strokeWidth: Item.Path.strokeWidth
				path = new Item.Path.PrecisePath(Date.now(), data, null, null, null, null, R.me, @id)
				path.pk = path.id
				path.loadPath()
				if highlight
					path.data.strokeColor = 'purple'
				path.draw()
			return

		setSVG: (svg, parse=true)->
			layerName = @getLayerName()
			layer = document.getElementById(layerName)
			if not layer then return
			# layer.insertAdjacentHTML('afterbegin', svg)
			if parse
				parser = new DOMParser()
				doc = parser.parseFromString(svg, "image/svg+xml")
			else
				doc = svg
			doc.documentElement.removeAttribute('visibility')
			doc.documentElement.removeAttribute('xmlns')
			doc.documentElement.removeAttribute('stroke')
			doc.documentElement.removeAttribute('stroke-width')
			if @status == 'draft'
				doc.documentElement.setAttribute('id', 'draftDrawing')
			@svg = layer.appendChild(doc.documentElement)
			
			@svg.addEventListener("click",  ((event) => 
				R.tools.select.deselectAll()
				@select()
				event.stopPropagation()
				return -1
			))

			return

		setStrokeColorFromVote: (positive)->
			# @svg?.setAttribute('stroke', if positive then "url(#pattern-validate)" else 'url(#pattern-reject)')
			# @svg?.setAttribute('stroke-dasharray', if positive then '.9' else '0.5')

			# color = new P.Color(R.Path.colorMap[@status])
			# color.lightness += if positive then 0.15 else -0.15
			# @svg?.setAttribute('stroke', color.toCSS())

			if @status == 'pending'
				@svg?.setAttribute('stroke', if positive then '#009688' else '#f44336')

			colorClass = if positive then 'drawing-color' else 'rejected-color'
			spanJ = $('<span class="badge ' + colorClass + '"></span>')
			spanJ.text(i18next.t(if positive then 'voted for' else 'voted against'))
			$('#RItems li[data-id="'+@id+'"] .badge-container').append(spanJ)
			return

		getPathIds: ()->
			pathIds = []
			for child in @children()
				pathIds.push(child.id)
			return pathIds

		getDuplicateData: ()->
			data = 
				pointLists: @getPointLists()
			return data

		setData: (data)->
			@removePaths()

			@addPathsFromPathList(data.pointLists, false)

			if @status == 'draft'
				R.toolManager.updateButtonsVisibility(@)
				R.tools['Precise path'].showDraftLimits()

			@updatePaths()
			return

		getListItem: ()->

			itemListJ = null
			switch @status
				when 'pending', 'emailNotConfirmed', 'notConfirmed'
					# R.view.pendingLayer.addChild(@group)
					itemListJ = R.view.pendingListJ
				when 'drawing'
					# R.view.drawingLayer.addChild(@group)
					itemListJ = R.view.drawingListJ
				when 'drawn'
					# R.view.drawnLayer.addChild(@group)
					itemListJ = R.view.drawnListJ
				when 'rejected'
					# R.view.rejectedLayer.addChild(@group)
					itemListJ = R.view.rejectedListJ
				when 'draft'
					# R.view.mainLayer.addChild(@group)
					itemListJ = R.view.draftListJ
				when 'flagged'
					# R.view.mainLayer.addChild(@group)
					itemListJ = R.view.flaggedListJ
				when 'test'
					# R.view.mainLayer.addChild(@group)
					itemListJ = R.view.testListJ
				else
					R.alertManager.alert "Error: drawing status is invalid", "error"

			return itemListJ

		toggleVisibility: ()->
			@group.visible = !@group.visible
			if @group.visible
				@eyeIconJ.removeClass('glyphicon-eye-close').addClass('glyphicon-eye-open')
			else
				@eyeIconJ.addClass('glyphicon-eye-close').removeClass('glyphicon-eye-open')
			if @svg?
				if @group.visible
					$(@svg).show()
				else
					$(@svg).hide()

			return

		addToListItem: (@itemListJ)->

			title = '' + @title + ' <span data-i18n="by">' + i18next.t('by') + '</span> ' + @owner
			@liJ = $("<li>")
			@liJ.html(title)

			divJ = $("<div class='cd-row cd-end badge-container'>")
			showBtnJ = $('<button type="button" class="btn btn-default show-btn" aria-label="Show">')
			@eyeIconJ = $('<span class="glyphicon eye glyphicon-eye-open" aria-hidden="true"></span>')
			showBtnJ.append(@eyeIconJ)
			showBtnJ.click (event)=>
				@toggleVisibility()
				event.preventDefault()
				event.stopPropagation()
				return -1

			divJ.append(showBtnJ)
			@liJ.append(divJ)

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
			R.drawingPanel.fromGeneralInformation = true
			@select()
			return

		computeRectangle: ()->
			@rectangle = null

			if @bounds? 
				@rectangle = @bounds.clone()
				return @rectangle

			if @svg?
				if @svg.getBBox?
					@rectangle = new P.Rectangle(@svg.getBBox())
					return @rectangle
			
			if @group.children.length == @paths.length && @group.bounds.area > 0
				@rectangle = @group.bounds.expand(2*R.Path.strokeWidth)
				if @rectangle? and @rectangle.area > 0
					return @rectangle

			for path in @paths
				bounds = path.getDrawingBounds()
				if bounds?
					@rectangle ?= bounds.clone()
					@rectangle = @rectangle.unite(bounds)

			return @rectangle

		getLayer: ()->
			return R.view[@getLayerName()]

		isVisible: ()->
			return @getLayer()?.visible

		addPathToProperLayer: (path)->
			@group.addChild(path.path)
			# switch @status
			# 	when 'pending'
			# 		R.view.pendingLayer.addChild(path.group)
			# 	when 'drawing'
			# 		R.view.drawingLayer.addChild(path.group)
			# 	when 'drawn'
			# 		R.view.drawnLayer.addChild(path.group)
			# 	when 'rejected'
			# 		R.view.rejectedLayer.addChild(path.group)
			return

		convertToGroup: ()->
			item = P.project.importSVG(@svg, (item, svg)=>
				console.log(item.bounds)
				return)
			return item

		addPaths: ()->
			for path in @paths
				@group.addChild(path.path)
				console.log(path.path)
			return

		@addPaths: ()->
			for drawing in R.drawings
				drawing.addPaths()
			return

		addChild: (path)->
			if @paths.indexOf(path) >= 0
				console.log('path already in drawing')
				return
			@paths.push(path)
			path.drawingId = @id
			# path.group.visible = true # can be hidden by rasterizer, must be shown here to update @drawing.bounds
			@pathPks ?= []
			# if not path.pk?
			# 	R.alertManager.alert 'Error: a path has not been saved yet, please wait until the path is saved before creating the drawing', 'error'
			# 	return
			@pathPks.push(path.pk)

			# @addPathToProperLayer(path)
			@group.addChild(path.path)

			# @drawing.addChild(path.group)

			bounds = path.getDrawingBounds()
			if bounds?
				@rectangle ?= bounds.clone()
				@rectangle = @rectangle.unite(bounds)
			path.updateStrokeColor()
			path.removeFromListItem()


			# if path.drawn
			# 	path.drawn = false
			# 	path.draw()
			# 	path.rasterize()
			# @drawn = false
			# if @raster? and @raster.parent != null 	# if this was rasterized: clear raster and replace by drawing to be able to re-rasterize with the new path
				# @replaceDrawing()
			return
		
		replaceDrawing: ()->
			if not @drawing? or not @drawingRelativePosition? then return
			for item in @children()
				item.drawn = false
				item.drawing?.remove()
				item.raster?.remove()
			super()
			return

		removeChild: (path, updateRectangle=false, removeID=true)->
			if removeID
				path.drawingId = null

			pathIndex = @paths.indexOf(path)
			if pathIndex >= 0
				@paths.splice(pathIndex, 1)
			
			path.path?.remove()
			
			# if path.svg?
			# 	path.svg.remove()

			path.drawingId = null
			pkIndex = @pathPks.indexOf(path.pk)
			if pkIndex >= 0
				@pathPks.splice(pkIndex, 1)

			# R.view.mainLayer.addChild(path.group)
			
			if updateRectangle
				@computeRectangle()

			path.updateStrokeColor()
			path.addToListItem()
			@drawn = false
			# if path.drawn
			# 	path.drawn = false
			# 	path.draw()
			# 	path.rasterize()
			# if updateRaster and @raster? and @raster.parent != null 	# if this was rasterized: clear raster and replace by drawing to be able to re-rasterize with the new path
				# @replaceDrawing()
			# R.rasterizer.rasterize(path, false)
			# path.draw?()
			# path.rasterize()
			return

		# @param name [String] the name of the value to change
		# @param value [Anything] the new value
		# @param updateGUI [Boolean] (optional, default is false) whether to update the GUI (parameters bar), true when called from SetParameterCommand
		setParameter: (name, value, updateGUI, update)->
			super(name, value, updateGUI, update)
			return

		save: (addCreateCommand=true) ->

			# if R.view.grid.rectangleOverlapsTwoPlanets(@rectangle)
  	# 			# R.alertManager.alert 'Your item overlaps with two planets', 'error'
			# 	return

			# if @rectangle.with == 0 and @rectangle.height == 0 or @paths.length == 0
			# 	@remove()
			# 	R.alertManager.alert "Error: The drawing is empty", "error"
			# 	return

			args = {
				city: R.city
				clientId: @id
				date: Date.now()
				# pathPks: @pathPks
				title: @title or '' + Math.random()
				description: @description or ''
				points: @points 				# added in Path.save()
			}

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'saveDrawing', args: args } ).done(@saveCallback)


			super(false)
			return

		# check if the save was successful and set @pk if it is
		saveCallback: (result)=>

			R.loader.checkError(result)
			if not result.pk?  		# if @pk is null, the path was not saved, do not set pk nor rasterize
				@remove()
				return

			@owner = result.owner
			@setPK(result.pk)

			# R.socket.emit "drawing change", type: 'new', pk: result.pk, pathPks: result.pathPks, city: R.city

			if @selectAfterSave?
				@select(true, true, true)

			if @updateAfterSave?
				@update(@updateAfterSave)

			if @pathsToSave?
				pointLists = []
				for path in @pathsToSave
					pointLists.push(path.getPoints())
				args = 
					clientId: @id
					pk: @pk
					pointLists: pointLists
				@pathsToSave = []
				$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'addPathsToDrawing', args: args } ).done(R.loader.checkError)
			super
			return

		addPathToSave: (path)->
			@pathsToSave ?= []
			@pathsToSave.push(path)
			return

		getLayerName: () ->
			statusName = if @status == 'emailNotConfirmed' or @status == 'notConfirmed' then 'pending' else @status
			return statusName + 'Layer'

		getBounds: ()->
			@computeRectangle()
			# if not @svg? and @paths.length == 0
			# 	return null
			return @rectangle

		getSVG: (asString=true) ->
			if @paths? and @paths.length > 0
				for path in @paths
					@group.addChild(path.path)
				return @group.exportSVG( asString: asString )
			else
				return @svg

		submit: () ->
			bounds = @getBounds()

			svg = @getSVG()
			@svgString = svg

			imageURL = R.view.getThumbnail(@, 1200, 630, true, true)

			args = {
				pk: @pk
				clientId: @id
				date: Date.now()
				title: @title
				description: @description
				svg: svg
				png: imageURL
				bounds: JSON.stringify(bounds)
			}

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'submitDrawing', args: args } ).done(@submitCallback)

			return

		removePaths: (addCommand=false)->
			if addCommand
				R.commandManager.add(new R.Command.ModifyDrawing(@))
			for path in @paths.slice()
				path.remove()
			if @status == 'draft'
				R.toolManager.updateButtonsVisibility(@)
			if addCommand
				@updatePaths()
			return

		# check if the save was successful and set @pk if it is
		submitCallback: (result)=>

			if not R.loader.checkError(result)
				return

			R.commandManager.clearHistory()

			@status = result.status
			
			if @constructor.draft == @
				@constructor.draft = null

			R.toolManager.updateButtonsVisibility()

			@removePaths()

			@setSVG(@svgString)
			@svgString = null

			# if @status == 'emailNotConfirmed'
			# 	R.alertManager.alert "Drawing successfully submitted but email not confirmed", "success", null, {positiveVoteThreshold: result.positiveVoteThreshold}
			# else
			# 	R.alertManager.alert "Drawing successfully submitted", "success", null, {positiveVoteThreshold: result.positiveVoteThreshold}

			@status = result.status
			# R.socket.emit "drawing change", type: 'status', pk: result.pk, status: @status, city: R.city

			modal = Modal.createModal( 
				id: 'share-facebook',
				title: 'Drawing submitted', 
				submit: ( ()=> R.drawingPanel.shareOnFacebook(null, @) ), 
				# postSubmit: 'load', 
				submitButtonText: 'Share on Facebook', 
				# submitButtonIcon: 'glyphicon-user', 
				cancelButtonText: 'No thanks', 
				# cancelButtonIcon: 'glyphicon-sunglasses' 
				)
			modal.addButton( type: 'info', name: 'Tweet', submit: (()=> R.drawingPanel.shareOnTwitter(null, @)) )
			
			# To enable discussion, uncomment following content (and the following text later on):
			# modal.addButton( type: 'success', name: 'See discussion page', submit: (()=> 
				
			# 	$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'getDrawingDiscussionId', args: {pk: @pk} } ).done( (results)=>
			# 		if not R.loader.checkError(results) then return
			# 		drawing = JSON.parse(results.drawing)
			# 		if drawing.discussionId?
			# 			R.drawingPanel.startDiscussion(results.discussionId)
			# 		else
			# 			R.alertManager.alert "The discussion page is not created yet", "error"
			# 		return)
			# 	return) )

			if @status == 'emailNotConfirmed'
				modal.addText("Drawing successfully submitted but email not confirmed", "Drawing successfully submitted but email not confirmed", false, {positiveVoteThreshold: result.positiveVoteThreshold})
			else if @status == 'notConfirmed'
				modal.addText("Drawing successfully submitted but not confirmed", "Drawing successfully submitted but not confirmed", false, {positiveVoteThreshold: result.positiveVoteThreshold})
			else
				modal.addText("Drawing successfully submitted", "Drawing successfully submitted", false, {positiveVoteThreshold: result.positiveVoteThreshold})

			# To enable discussion, uncomment following content:
			# modal.addText('A discussion page for this drawing will be created in a few seconds')

			modal.addText('Would you like to share your drawing on Facebook or Twitter')
			
			modal.show()

			return
		
		updatePaths: ()->
			@computeRectangle()

			args = {
				clientId: @id
				pk: @pk
				pointLists: @getPointLists()
			}

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'setPathsToDrawing', args: args } ).done(R.loader.checkError)

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
			R.alertManager.alert "Drawing successfully modified", "success"
			# R.socket.emit "drawing change", type: 'description', title: @title, description: @description, drawingId: @id
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
			id = @id
			if not R.loader.checkError()
				if @pathIdsBeforeRemove?
					for id in @pathIdsBeforeRemove
						if R.items[id]?
							@addChild(R.items[id])
					@rasterize()
					R.rasterizer.rasterize(@, false)
				return
			super()
			R.alertManager.alert "Drawing successfully cancelled", "success"
			# R.socket.emit "drawing change", type: 'delete', drawingId: id
			return

		delete: ()->
			@pathIdsBeforeRemove = @getPathIds()
			# @removeChildren()
			deffered = super
			return deffered

		# called when user deletes the item by pressing delete key or from the gui
		# @delete() removes the item and delete it in the database
		# @remove() just removes visually
		deleteFromDatabase: () ->
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'deleteDrawing', args: { 'pk': @pk } } ).done(@deleteFromDatabaseCallback())
			return

		cancel: ()->
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'cancelDrawing', args: { 'pk': @pk } } ).done( (result)=> @cancelCallback(result) )
			return

		cancelCallback: (result)->
			if not R.loader.checkError(result) then return

			# we will add them with result.pathList
			for path in @paths.slice()
				@removeChild(path)

			draft = Drawing.getDraft()
			if draft?
				for path in draft.paths
					@addChild(path)
				draft.remove()
			@svg?.remove()
			@svg = null
			@addPathsFromPathList(result.pathList)
			@updateStatus(result.status)
			@constructor.draft = @
			# for path in @paths
			# 	console.log(path.getPoints())
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
			bounds = item.getBounds()
			if not bounds?
				return true
			for item in @children()
				if not @rectangle.contains(bounds)
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

		updateStatus: (status)->
			if @status == status then return
			@status = status
			# we could just move liJ but we would have to update the number of items anyway
			@removeFromListItem()
			@addToListItem(@getListItem())
			
			if @svg?
				@svg.remove()
				layerName = @getLayerName()
				layer = document.getElementById(layerName)
				@svg = layer.appendChild(@svg)

			for path in @paths
				# @addPathToProperLayer(path)
				path.updateStrokeColor()
				# path.drawn = false
				# path.draw()
				# path.rasterize()
				# path.group.visible = true
			# R.rasterizer.rasterizeRectangle(@rectangle)

			return

		# can not select a drawing which the user does not own
		select: (updateOptions=true, showPanelAndLoad=true, force=false) =>
			if not @group.visible then return false
			if not super(updateOptions, force) then return false
			
			for item in @children()
				item.deselect()

			if showPanelAndLoad
				R.drawingPanel.selectionChanged()

			return true
		
		deselect: (updateOptions=true)->
			if not super(updateOptions) then return false
			R.drawingPanel.deselectDrawing(@)
			return true

		# removeChildren: () ->
		# 	for path in @children().slice()
		# 		@removeChild(path, false)
		# 	return

		remove: () ->
			for path in @paths.slice()
				@removeChild(path)
			@svg?.remove()
			@removeFromListItem()
			R.rasterizer.rasterizeRectangle(@rectangle)
			super
			return

		getRaster: ()->
			if @pathRaster? then return @pathRaster
			if @paths.length == 0 then return null

			group = new P.Group()
			for path in @paths
				if path.raster?
					group.addChild(path.raster.clone())
				else
					if not path.drawing?
						path.draw()
					group.addChild(path.drawing.clone())
			@pathRaster = group.rasterize(P.view.resolution, false)
			group.remove()
			return @pathRaster

		children: ()->
			# paths = []
			# for child in @drawing.children
			# 	if child.controller?
			# 		paths.push(child.controller)
			return @paths

		highlight: (color)->
			super()
			if color
				@highlightRectangle.fillColor = color
				@highlightRectangle.strokeColor = color
				@highlightRectangle.dashArray = []
			return

		hide: (SVGonly=true)->
			if @svg?
				@svg.setAttribute('visibility', 'hidden')

			@group?.visible = false

			return

		show: (SVGonly=true)->
			if @svg?
				@svg.setAttribute('visibility', 'show')

			@group?.visible = true
			
			return

		# drawChildren: ()->
		# 	if @drawing.children.length == 0 then return
			
			
		# 	for child in @drawing.children
		# 		child.controller?.draw?()
		# 	return

		# disable rasterize if no children
		rasterize: ()->	
			# if @raster? or not @drawing? then return
			# make sure children are drawn BEFORE this, otherwise this can be rasterized before children are drawn, see Rasterizer.drawItems()

			# @drawChildren()
			# super()
			return

	Item.Drawing = Drawing
	R.Drawing = Drawing
	return Drawing
