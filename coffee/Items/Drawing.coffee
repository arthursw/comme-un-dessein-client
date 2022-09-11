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

		@getDraft: ()->
			return @draft

		constructor: (@rectangle, @data=null, @id=null, @pk=null, @owner=null, @date, @title, @description, @status='pending', pathList=[], svg=null, bounds=null) ->

			super(@data, @id, @pk)

			if @pk?
				@constructor.pkToId[@pk] = @id
			
			if bounds?
				@rectangle = new P.Rectangle(bounds)

			R.drawings.push(@)

			@setPkToDrawing(@pk)

			@paths = []

			@group.remove()

			@votes = [] # { positive: boolean, author: string, authorPk: pk }

			@addToListItem()
			@addToLayer()
			
			if @status == 'draft'
				@constructor.draft = @
				@group.shadowColor = 'lightblue'
				@group.shadowBlur = 10
				@group.shadowOffset = new P.Point(0, 0)

			if (@status == 'draft' or @status == 'flagged_pending' or @status == 'flagged') and pathList
				if @status == 'flagged_pending' or @status == 'flagged' and pathList.length == 0
					@loadPathList()
					@loadSVG()
				else
					@addPathsFromPathList(pathList)
			else if @pk? and R.useSVG
				@loadSVG()

			if @status == 'pending' and @owner != R.me
				@drawVoteFlag()

			if @status == 'flagged_pending'
				@drawVoteFlag(true)

			return
		
		scale: (newScale)=>
			@loadPathList(()=>
				for p in @paths
					p.scale(newScale, @rectangle.center)
				@updatePaths(true)
				return)
			return
		
		flipX: ()=>
			@scale(new P.Point(-1,1))
			return

		flipY: ()=>
			@scale(new P.Point(-1,1))
			return

		selectPaths: ()=>
			if (not @paths?) or @paths.length == 0
				return @loadPathList(()=>if @paths? then @selectPaths() else null)
			for path in @paths
				path.selected = true
			return
		
		deselectPaths: ()->
			if not @paths? then return
			for path in @paths
				path.selected = false
			return

		drawVoteFlag: (flagged=false)->
			if R.useSVG then return

			bounds = @getBounds()

			@voteFlag = new P.Raster(if not flagged then '/static/images/icons/envelope.png' else '/static/images/icons/flagged.png')

			@voteFlag.position = bounds.center
			@voteFlag.opacity = 0.75
			R.voteFlags ?= []
			R.voteFlags.push(@voteFlag)
			
			@group.addChild(@voteFlag)
			
			if R.selectedTool != R.tools.select
				@hideVoteFlag()
			return

		hideVoteFlag: ()->
			@voteFlag?.visible = false
			return

		showVoteFlag: ()->
			flagged = @status == 'flagged_pending' or @status == 'flagged'
			if @id? and R.loader.userVotes.get(@id)? and not flagged then return
			@voteFlag?.visible = true
			return

		setPkToDrawing: (pk)->
			R.pkToDrawing ?= new Map()
			R.pkToDrawing.set(@pk, @)
			return

		setPK: (pk)->
			super(pk)
			@setPkToDrawing(pk)
			return

		getPathPoints: (path)->
			points = []
			for segment in path.segments
				# points.push(Utils.CS.projectToPosOnPlanet(segment.point))
				points.push(R.view.grid.projectToGeoJSON(segment.point)) # Utils.CS.projectToPosOnPlanet(segment.point))
				points.push(Utils.CS.pointToObj(segment.handleIn))
				points.push(Utils.CS.pointToObj(segment.handleOut))
				points.push(segment.rtype)
			return points

		getPointLists: ()->
			pointLists = []
			for path in @paths
				pointLists.push({ points: @getPathPoints(path), data: { strokeColor: path.strokeColor.toCSS() } })
			return pointLists

		createPath: (points, strokeColor, planet=null)->
			if not planet?
				planet = new P.Point(0, 0)
			path = new P.Path()
			for point, i in points by 4
				path.add(R.view.grid.geoJSONToProject(point))
				# path.add(Utils.CS.posOnPlanetToProject(point, planet))
				path.lastSegment.handleIn = new P.Point(points[i+1])
				path.lastSegment.handleOut = new P.Point(points[i+2])
				path.lastSegment.rtype = points[i+3]
			path.strokeWidth = Item.Path.strokeWidth
			path.strokeColor = strokeColor
			path.strokeCap = 'round'
			path.strokeJoin = 'round'
			@addChild(path)
			return path

		addPathsFromPathList: (pathList, parseJSON=true, highlight=false)->
			for p in pathList
				pJSON = if parseJSON then JSON.parse(p) else p
				points = pJSON.points
				strokeColor = if pJSON.data? then pJSON.data.strokeColor else null
				if not points?
					points = pJSON
				if not strokeColor?
					strokeColor = new P.Color('grey')

				path = @createPath(points, strokeColor)

			@computeRectangle()
			return
		
		# Used to warn admin that the drawing has been flagged by websocket (in DrawingPanel.onDrawingChange() => status changed)
		loadPathList: (callback, force=false)->
			
			if @paths.length > 0 and not force then return

			args =
				pk: @pk
				loadPathList: true
			
			R.loader.showLoadingBar()
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawing', args: args } ).done((result)=>
				drawingData = JSON.parse(result.drawing)
				# @setSVG(drawing.svg, true, callback)
				@addPathsFromPathList(drawingData.pathList)
				R.loader.hideLoadingBar()
				callback?()
			)

			return

		createSVG: ()->
			@setSVG({ documentElement: @getSVG(false) }, false)
			return

		loadSVG: (callback)->
			jqxhr = $.get( location.origin + '/static/drawings/' + @pk + '.svg?v=1', ((result)=>
				@setSVG(result, false, callback)
			))
			.fail(()=>
				console.log('load drawing svg failed')
				# @loadPathList()
			)

			return

		# loadSVGToPrint: (callback)->
		# 	jqxhr = $.get( location.origin + '/static/drawings/' + @pk + '.svg', ((result)=>
		# 		callback(result)
		# 		return
		# 	))
		# 	.fail(()=>

		# 		if @svg? then return

		# 		args =
		# 			pk: @pk
		# 			svgOnly: true
		# 		$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawing', args: args } ).done((result)=>
		# 			drawing = JSON.parse(result.drawing)
		# 			if drawing.svg?
		# 				callback(drawing.svg)
		# 		)
		# 	)

		# 	return

		setPathZIndex: (path, pathIndex, zIndex)->
			@paths.pop()
			@paths.splice(pathIndex, 0, path)
			path.parent.insertChild(zIndex, path)
			return

		setSVGRasterMode: (svg, parse=true, callback=null)->
			parser = new DOMParser()
			doc = null
			if parse
				parser = new DOMParser()
				doc = parser.parseFromString(svg, "image/svg+xml")
			else
				doc = svg
			doc.documentElement.removeAttribute('visibility')
			doc.documentElement.removeAttribute('xmlns')
			@svg = doc.documentElement
			callback?(@svg)
			return

		setSVG: (svg, parse=true, callback=null, hide=false)->

			if not R.useSVG then return @setSVGRasterMode(svg, parse, callback)

			if @svg then @svg.remove()
			layerName = @getLayerName()
			layer = document.getElementById(layerName)
			# layer = document.createElement('div')
			doc = null
			if not layer then return
			# layer.insertAdjacentHTML('afterbegin', svg)
			if parse
				parser = new DOMParser()
				doc = parser.parseFromString(svg, "image/svg+xml")
			else
				doc = svg
			if doc.documentElement?
				doc.documentElement.removeAttribute('visibility')
				doc.documentElement.removeAttribute('xmlns')
				# doc.documentElement.removeAttribute('stroke')
				# doc.documentElement.removeAttribute('stroke-width')
				if @status == 'draft'
					doc.documentElement.setAttribute('id', 'draftDrawing')
			
				# @svg = doc.documentElement

				@svg = layer.appendChild(doc.documentElement)
				
				@svg.addEventListener("click",  ((event) => 
					R.tools.select.deselectAll()
					@select()
					event.stopPropagation()
					return -1
				))

				if hide
					@svg.setAttribute('visibility', 'hidden')

				@setStrokeColorFromStatus()
			callback?(@svg)

			return

		setStrokeColorFromVote: (positive)->
			# @svg?.setAttribute('stroke', if positive then "url(#pattern-validate)" else 'url(#pattern-reject)')
			# @svg?.setAttribute('stroke-dasharray', if positive then '.9' else '0.5')

			# color = new P.Color(R.Path.colorMap[@status])
			# color.lightness += if positive then 0.15 else -0.15
			# @svg?.setAttribute('stroke', color.toCSS())

			if R.useSVG
				if @status == 'pending'
					@svg?.setAttribute('stroke', if positive then Item.Path.colorMap.pendingVotedPositive else Item.Path.colorMap.pendingVotedNegative)

			colorClass = if positive then 'drawing-color' else 'rejected-color'
			spanJ = $('<span class="badge ' + colorClass + '"></span>')
			spanJ.text(i18next.t(if positive then 'voted for' else 'voted against'))
			$('#RItems li[data-id="'+@id+'"] .badge-container').append(spanJ)
			return

		setStrokeColorFromStatus: ()->
			if not R.useSVG then return
			@svg?.setAttribute('stroke', Item.Path.colorMap[@status])
			return

		# getPathIds: ()->
		# 	pathIds = []
		# 	for child in @paths
		# 		pathIds.push(child.id)
		# 	return pathIds

		getDuplicateData: ()->
			data = 
				pointLists: @getPointLists()
			return data

		setData: (data)->
			@removePaths()

			@addPathsFromPathList(data.pointLists, false)
			
			@updatePaths()

			if @status == 'draft'
				R.toolManager.updateButtonsVisibility(@)
				R.tools['Precise path'].showDraftLimits()

			return

		getListItem: ()->

			itemListJ = null
			switch @status
				when 'pending', 'emailNotConfirmed', 'notConfirmed'
					itemListJ = R.view.pendingListJ
				when 'drawing', 'validated'
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
				when 'flagged', 'flagged_pending'
					# R.view.mainLayer.addChild(@group)
					itemListJ = R.view.flaggedListJ
				# when 'test'
				# 	# R.view.mainLayer.addChild(@group)
				# 	itemListJ = R.view.testListJ
				else
					@group.visible = false
					if @svg?
						$(@svg).hide()
					# R.alertManager.alert "Error: drawing status is invalid", "error"

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

		addToLayer: ()->
			@getLayer().addChild(@group)
			return

		addToListItem: (@itemListJ=@getListItem())->

			title = '' + @title + ' <span data-i18n="by">' + i18next.t('by') + '</span> ' + @owner
			@liJ = $("<li>")
			@liJ.html(title)

			divJ = $("<div class='cd-row cd-end badge-container'>")
			# showBtnJ = $('<button type="button" class="btn btn-default show-btn" aria-label="Show">')
			# @eyeIconJ = $('<span class="glyphicon eye glyphicon-eye-open" aria-hidden="true"></span>')
			# showBtnJ.append(@eyeIconJ)
			# showBtnJ.click (event)=>
			# 	@toggleVisibility()
			# 	event.preventDefault()
			# 	event.stopPropagation()
			# 	return -1

			# divJ.append(showBtnJ)
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
				nChildren = @itemListJ.find('.rPath-list').children('li[data-id]').length
				nItemsJ.html(nChildren)

			return

		removeFromListItem: ()->
			@liJ.remove()
			nItemsJ = @itemListJ?.find(".n-items")
			if nItemsJ? and nItemsJ.length>0
				nChildren = @itemListJ.find('.rPath-list').children('li[data-id]').length
				nItemsJ.html(nChildren)
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
			for path in @paths
				bounds = path.bounds.expand(2 * Item.Path.strokeWidth)
				if bounds?
					@rectangle ?= bounds.clone()
					@rectangle = @rectangle.unite(bounds)
			return

		# computeRectangle: ()->
		# 	if @status == 'draft'
		# 		console.log('computeRectangle draft')

		# 	@rectangle = null

		# 	if @bounds? 
		# 		@rectangle = @bounds.clone()
		# 		return @rectangle

		# 	if @svg?
		# 		if @svg.getBBox?
		# 			@rectangle = new P.Rectangle(@svg.getBBox())
		# 			return @rectangle
			
		# 	if @group.children.length >= @paths.length && @group.bounds.area > 0
		# 		@rectangle = @group.bounds.expand(2*R.Path.strokeWidth)
		# 		if @rectangle? and @rectangle.area > 0
		# 			return @rectangle

		# 	for path in @paths
		# 		bounds = path.getDrawingBounds()
		# 		if bounds?
		# 			@rectangle ?= bounds.clone()
		# 			@rectangle = @rectangle.unite(bounds)

		# 	return @rectangle

		getLayer: ()->
			return R.view[@getLayerName()]

		isVisible: ()->
			return @getLayer()?.visible

		# addPathToProperLayer: (path)->
		# 	@group.addChild(path.path)
		# 	# switch @status
		# 	# 	when 'pending'
		# 	# 		R.view.pendingLayer.addChild(path.group)
		# 	# 	when 'drawing'
		# 	# 		R.view.drawingLayer.addChild(path.group)
		# 	# 	when 'drawn'
		# 	# 		R.view.drawnLayer.addChild(path.group)
		# 	# 	when 'rejected'
		# 	# 		R.view.rejectedLayer.addChild(path.group)
		# 	return

		convertToGroup: ()->
			item = P.project.importSVG(@svg, (item, svg)=>
				console.log(item.bounds)
				return)
			return item

		# addPaths: ()->
		# 	for path in @paths
		# 		@group.addChild(path.path)
		# 		console.log(path.path)
		# 	return

		# @addPaths: ()->
		# 	for drawing in R.drawings
		# 		drawing.addPaths()
		# 	return

		addChild: (path, save=false, computeRectangle=true)->
			if @paths.indexOf(path) >= 0
				console.log('path already in drawing')
				return
			@paths.push(path)
			
			@group.addChild(path)

			path.data.drawingId = @id
			# path.group.visible = true # can be hidden by rasterizer, must be shown here to update @drawing.bounds
			# @pathPks ?= []
			# if not path.pk?
			# 	R.alertManager.alert 'Error: a path has not been saved yet, please wait until the path is saved before creating the drawing', 'error'
			# 	return
			# @pathPks.push(path.pk)

			# @addPathToProperLayer(path)
			# @group.addChild(path.path)

			# @drawing.addChild(path.group)
			
			if computeRectangle
				@computeRectangle()



			# if path.drawn
			# 	path.drawn = false
			# 	path.draw()
			# 	path.rasterize()
			# @drawn = false
			# if @raster? and @raster.parent != null 	# if this was rasterized: clear raster and replace by drawing to be able to re-rasterize with the new path
				# @replaceDrawing()

			if save
				@savePath(path)
			return

		savePath: (path)->
			args = 
				clientId: @id
				pk: @pk
				points: @getPathPoints(path)
				data: { strokeColor: path.strokeColor.toCSS() }
				bounds: @getBounds()
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'addPathToDrawing', args: args } ).done(@saveCallback)
			return
		
		savePathCallback: (result)=>
			R.loader.checkError(result)
			return

		removeChild: (path, updateRectangle=false, removeID=true)->
			path.data.drawingId = null

			pathIndex = @paths.indexOf(path)
			if pathIndex >= 0
				@paths.splice(pathIndex, 1)
			
			path.remove()
			
			return

		getLayerName: () ->
			statusName = if @status == 'flagged_pending' or @status == 'flagged' then 'flagged' else @status
			return statusName + 'Layer'

		getBounds: ()->
			# @computeRectangle()
			# if not @svg? and @paths.length == 0
			# 	return null
			return @rectangle

		getBoundsWithFlag: ()->
			# @computeRectangle()
			return if @voteFlag? then @rectangle.unite(@voteFlag.bounds) else @rectangle

		getSVG: (asString=true) ->
			if @paths? and @paths.length > 0
				for path in @paths
					@group.addChild(path)
				return @group.exportSVG( asString: asString )
			else
				return @svg

		submit: () ->
			bounds = @getBounds()

			svg = @getSVG()
			@svgString = svg

			imageData = R.view.getThumbnail(@, bounds.width, bounds.height, true, false)

			args = {
				pk: @pk
				clientId: @id
				date: Date.now()
				title: @title
				description: @description
				svg: svg
				png: imageData
				bounds: bounds
			}
			R.loader.showLoadingBar()
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'submitDrawing', args: args } ).done(@submitCallback)

			return

		removePaths: (addCommand=false)->
			if addCommand
				R.commandManager.add(new R.Command.ModifyDrawing(@))
			for path in @paths
				path.remove()
			if @svg? and R.useSVG
				@svg.remove()
			@paths = []
			if @status == 'draft'
				R.toolManager.updateButtonsVisibility(@)
			if addCommand
				@updatePaths()
			return

		# check if the save was successful and set @pk if it is
		submitCallback: (result)=>
			R.loader.hideLoadingBar()
			if not R.loader.checkError(result)
				return

			R.loader.createDrawing(result.draft)

			R.tools['Precise path'].hideDraftLimits()

			R.loader.reloadRasters(@rectangle)

			R.commandManager.clearHistory()

			@updateStatus(result.status)
			
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
				submit: ( ()=> return ), 
				# postSubmit: 'load', 
				# submitButtonText: 'Share on Facebook', 
				submitButtonText: 'No thanks', 
				# submitButtonIcon: 'glyphicon-user', 
				# cancelButtonText: 'No thanks', 
				# cancelButtonIcon: 'glyphicon-sunglasses' 
				)
			modal.addButton( type: 'info', name: 'Tweet', submit: (()=> R.drawingPanel.shareOnTwitter(null, @)) )
			modal.addButton( type: 'primary', name: 'Share on Facebook', submit: (()=> R.drawingPanel.shareOnFacebook(null, @) ) )
			modal.modalJ.find('[name="cancel"]').hide()
			modal.modalJ.find('[name="submit"]').removeClass('btn-primary').addClass('btn-default')
			
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
		
		updateBox: () ->
			bounds = @getBounds()

			args = {
				pk: @pk
				clientId: @id
				bounds: bounds
			}
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'updateDrawingBox', args: args } ).done((result)->
				R.loader.checkError(result)
				return)

			return
		
		updateSVG: ()->
			args = 
				pk: @pk
				svg: @getSVG()
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'updateDrawingSVG', args: args } ).done(R.loader.checkError)
		
		updatePaths: (svg=false)->
			@computeRectangle()

			args = {
				clientId: @id
				pk: @pk
				pointLists: @getPointLists()
				bounds: @getBounds()
			}
			if svg
				args.svg = @getSVG()

			R.loader.showLoadingBar(500)
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'setPathsToDrawing', args: args } ).done((result)->
				R.loader.hideLoadingBar()
				R.loader.checkError(result)
				return)

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

			R.loader.showLoadingBar(500)
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'updateDrawing', args: args } ).done(@updateCallback)

			return

		updateCallback: (result)=>
			R.loader.hideLoadingBar()
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

		deleteFromDatabaseCallback: ()=>
			R.loader.hideLoadingBar()
			id = @id
			if not R.loader.checkError()
				# if @pathIdsBeforeRemove?
				# 	for id in @pathIdsBeforeRemove
				# 		if R.items[id]?
				# 			@addChild(R.items[id])
				# 	@rasterize()
				# 	R.rasterizer.rasterize(@, false)
				return
			super()
			R.alertManager.alert "Drawing successfully cancelled", "success"
			# R.socket.emit "drawing change", type: 'delete', drawingId: id
			return

		delete: ()->
			# @pathIdsBeforeRemove = @getPathIds()
			# @removeChildren()
			deffered = super
			return deffered

		# called when user deletes the item by pressing delete key or from the gui
		# @delete() removes the item and delete it in the database
		# @remove() just removes visually
		deleteFromDatabase: () ->
			R.loader.showLoadingBar(500)
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'deleteDrawing', args: { 'pk': @pk } } ).done(@deleteFromDatabaseCallback())
			return

		cancel: ()->
			R.loader.showLoadingBar(500)
			@cancelling = true
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'cancelDrawing', args: { 'pk': @pk } } ).done( (result)=> @cancelCallback(result) )
			return

		cancelCallback: (result)->
			R.loader.hideLoadingBar()
			if not R.loader.checkError(result) then return

			if R.administrator and @owner != R.me then return

			R.commandManager.clearHistory()


			# we will add them with result.pathList
			
			draft = Drawing.getDraft()
			if draft?
				
				for path in @paths
					draft.addChild(path)
				draft.addPathsFromPathList(result.pathList)
				for path in @paths.slice()
					@removeChild(path)

				draft.updateStatus(result.status)
			
			@remove()
			
			draft.setPK(result.pk)
			R.items[result.clientId] = draft

			R.loader.reloadRasters(@rectangle)
			
			return

		setRectangle: (rectangle, update=true)->
			super(rectangle, update)
			return

		updateDrawingPanel: ()->
			args =
				pk: @pk
				loadSVG: R.loadSVG

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawing', args: args } ).done((result)=>
				R.drawingPanel.setDrawing(@, result)
			)
			return

		updateStatus: (status)->
			if @status == status then return
			@status = status
			# we could just move liJ but we would have to update the number of items anyway
			@removeFromListItem()
			@addToListItem()
			@addToLayer()
			
			if @svg? and R.useSVG
				@svg.remove()
				layerName = @getLayerName()
				layer = document.getElementById(layerName)
				@svg = layer.appendChild(@svg)

			voteFlagWasVisible = @voteFlag?.visible

			@voteFlag?.remove()

			if @status == 'pending' and @owner != R.me
				@drawVoteFlag()

			if @status == 'flagged_pending'
				@drawVoteFlag(true)

			if voteFlagWasVisible
				@showVoteFlag()

			@setStrokeColorFromStatus()
			return

		# can not select a drawing which the user does not own
		select: (updateOptions=true, showPanelAndLoad=true, force=false) =>
			if not @group.visible then return false
			if not super(updateOptions, force) then return false

			if showPanelAndLoad
				R.drawingPanel.selectionChanged()

			for drawing in R.drawings
				if drawing.getBoundsWithFlag()?.intersects(@rectangle) and drawing.isVisible()
					drawing.hideVoteFlag()

			draft = Drawing.getDraft()
			if R.administrator and @ == draft
				@selectPaths()
			
			return true
		
		deselect: (updateOptions=true)->
			if not super(updateOptions) then return false
			R.drawingPanel.deselectDrawing(@)
			@showVoteFlag()
			@deselectPaths()
			return true

		# removeChildren: () ->
		# 	for path in @paths
		# 		@removeChild(path, false)
		# 	return

		remove: () ->
			for path in @paths.slice()
				@removeChild(path)
			@svg?.remove()
			R.pkToDrawing.delete(@pk)
			@removeFromListItem()

			super

			R.drawings.splice(R.drawings.indexOf(@), 1)

			return

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


	Item.Drawing = Drawing
	R.Drawing = Drawing
	return Drawing
