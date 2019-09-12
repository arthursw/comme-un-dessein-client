define ['paper', 'R', 'Utils/Utils', 'Commands/Command', 'Items/Item', 'UI/ModuleLoader', 'Items/Drawing', 'Items/Divs/Text' ], (P, R, Utils, Command, Item, ModuleLoader, Drawing, Text) ->
# define ['paper', 'R', 'Utils/Utils', 'Commands/Command', 'Items/Item', 'UI/ModuleLoader', 'Items/Lock', 'Items/Divs/Div', 'Items/Divs/Media', 'Items/Drawing', 'Items/Divs/Text' ], (P, R, Utils, Command, Item, ModuleLoader, Lock, Div, Media, Drawing, Text) ->
	# --- load --- #

	class Loader
		
		@maxNumPoints = 1000
		@scaleRatio = 4

		constructor: ()->
			@loadingType = 'tiles'

			@loadedAreas = []
			@debug = false
			@pathsToCreate = {}
			@initializeLoadingBar()
			@showLoadingBar()

			@drawingPaths = []
			@drawingPk = null

			# @focusOnDrawing = null
			@rasters = new Map()
			return

		initializeLoadingBar: ()->
			opts =
				lines: 17
				length: 13
				width: 8
				radius: 0
				scale: 1.5
				corners: 0
				color: '#ccc'
				opacity: 0.15
				rotate: 0
				direction: 1
				speed: 1
				trail: 38
				fps: 20
				zIndex: 2e9
				className: 'spinner'
				top: '50%'
				left: '130px'
				shadow: false
				hwaccel: false
				position: 'relative'
			target = document.getElementById('spinner')
			# @spinner = new Spinner(opts).spin(target)
			return

		initializeGroups: (rasterLayer)->
			@activeRasterGroup = new P.Group()
			@inactiveRasterGroup = new P.Group()
			
			rasterLayer.addChild(@activeRasterGroup)
			rasterLayer.addChild(@inactiveRasterGroup)
			return

		showDrawingBar: ()->
			$("#drawingBar").show()
			return

		hideDrawingBar: ()->
			$("#drawingBar").hide()
			return

		showLoadingBarCallback: ()=>
			$("#loadingBar").show().css( opacity: 1 )
			return

		showLoadingBar: (timeout)=>
			if timeout? and timeout>0
				clearTimeout(@showLoadingBarTimeoutId)
				$("#loadingBar").show().css( opacity: 0 )
				@showLoadingBarTimeoutId = setTimeout(@showLoadingBarCallback, timeout)
			else
				@showLoadingBarCallback()
			return

		hideLoadingBar: ()=>
			clearTimeout(@showLoadingBarTimeoutId)
			$("#loadingBar").hide()
			# @spinner.stop()
			return

		# @return [Boolean] true if the area was already loaded, false otherwise
		areaIsLoaded: (pos, planet, qZoom) ->
			for area in @loadedAreas
				if area.planet.x == planet.x && area.planet.y == planet.y
					if area.pos.x == pos.x && area.pos.y == pos.y
						if not qZoom? or area.zoom == qZoom
							return true
			return false

		# this.areaIsQuickLoaded = (area) ->
		# 	for a in @loadedAreas
		# 		if a.x == area.x && a.y == area.y
		# 			return true
		# 	return false
		unload: () ->
			@loadedAreas = []
			for own id, item of R.items
				item.remove()
			R.items = {}
			R.rasterizer.clearRasters()
			@previousLoadPosition = null
			return


		# loadRequired: ()->
		# 	if @previousLoadPosition?
		# 		if @previousLoadPosition.position.subtract(P.view.center).length<50
		# 			if Math.abs(1-@previousLoadPosition.zoom/P.view.zoom)<0.2
		# 				return false
		# 	return true

		getLoadingBounds: (area)->
			if not area?
				# if P.view.bounds.width <= window.innerWidth and P.view.bounds.height <= window.innerHeight
				# 	return P.view.bounds
				# else
				# 	halfSize = new P.Point(window.innerWidth*0.5, window.innerHeight*0.5)
				# 	return new P.Rectangle(P.view.center.subtract(halfSize), P.view.center.add(halfSize))
				return P.view.bounds
			return area

		# unloadAreas: (area, limit, qZoom)->

		# 	itemsOutsideLimit = []

		# 	# remove RItems which are not within limit anymore AND in area which must be unloaded
		# 	# (do not remove items on an area which is not unloaded, otherwise they wont be reloaded if user comes back on it)
		# 	for own id, item of R.items
		# 		if (not item.getBounds()?.intersects(limit)) and (not item.isDraft())
		# 			itemsOutsideLimit.push(item)

		# 	i = @loadedAreas.length
		# 	while i--
		# 		area = @loadedAreas[i]
		# 		pos = Utils.CS.posOnPlanetToProject(area.pos, area.planet)
		# 		rectangle = new P.Rectangle(pos.x, pos.y, R.scale * area.zoom, R.scale * area.zoom)

		# 		if not rectangle.intersects(limit) or area.zoom != qZoom

		# 			if @debug then @updateDebugArea(area)

		# 			# # remove raster corresponding to the area
		# 			# x = area.x*1000 	# should be equal to pos.x
		# 			# y = area.y*1000		# should be equal to pos.y

		# 			# if R.rasters[x]?[y]?
		# 			# 	R.rasters[x][y].remove()
		# 			# 	delete R.rasters[x][y]
		# 			# 	if Utils.isEmpty(R.rasters[x]) then delete R.rasters[x]

		# 			# remove area from loaded areas
		# 			@loadedAreas.splice(i,1)

		# 			# remove items on this area
		# 			# items to remove must not intersect with the limit, and can overlap two areas:
		# 			j = itemsOutsideLimit.length
		# 			while j--
		# 				item = itemsOutsideLimit[j]
		# 				if item.getBounds()?.intersects(rectangle)
		# 					item.remove()
		# 					itemsOutsideLimit.splice(j,1)
		# 	return

		# getAreaToLoad: (areasToLoad, pos, planet, x, y, scale, qZoom)->
		# 	if not @areaIsLoaded(pos, planet, qZoom)
		# 		area = { pos: pos, planet: planet }

		# 		areasToLoad.push(area)

		# 		area.zoom = qZoom

		# 		if @debug then @createAreaDebugRectangle(x, y, scale)

		# 		@loadedAreas.push(area)
		# 	return

		# getAreasToLoad: (scale, qZoom, t, l, b, r)->
		# 	areasToLoad = []
		# 	for x in [l .. r] by scale
		# 		for y in [t .. b] by scale
		# 			planet = Utils.CS.projectToPlanet(new P.Point(x,y))
		# 			pos = Utils.CS.projectToPosOnPlanet(new P.Point(x,y))
		# 			# rasterizer always add all areas since it must check if it is up-to-date
		# 			# (items which are loaded could need to be updated)
		# 			@getAreaToLoad(areasToLoad, pos, planet, x, y, scale, qZoom)
		# 	return areasToLoad

		# nothingToLoad: (areasToLoad)->
		# 	return areasToLoad.length<=0

# 		requestAreas: (rectangle, areasToLoad, qZoom)->
# #			Dajaxice.draw.load(@loadCallback, { rectangle: rectangle, areasToLoad: areasToLoad, qZoom: qZoom, city: R.city })
# 			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'load', args: { rectangle: rectangle, areasToLoad: areasToLoad, qZoom: qZoom, cityName: R.city.name } } ).done(@loadCallback)
# 			return

		# loadAll: ()->
		# 	$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadAll', args: { cityName: R.city.name } } ).done((results)=> 
		# 		if not R.loader.checkError(results) then return

		# 		R.view.fitRectangle(R.view.grid.limitCD.bounds.expand(400), true)
				
		# 		for drawing in R.drawings
		# 			drawing.remove()

		# 		draft = R.Drawing.getDraft()
		# 		if not draft?
		# 			draft = new Item.Drawing(null, null, null, null, R.me, Date.now(), null, null, 'draft')

		# 		i=0
		# 		# R.svgJ.hide()
		# 		showDrawing = ()=>
		# 			item = results.items[i++]
		# 			if not item? then return
					
		# 			draft.removePaths()

		# 			draft = new Item.Drawing(null, null, null, null, R.me, Date.now(), null, null, 'draft')

		# 			drawing = JSON.parse(item)
		# 			console.log(drawing.pathList)
		# 			# args = 
		# 			# 	pk: item._id.$oid
		# 			# 	loadPathList: true

		# 			# $.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawing', args: args } ).done (results)=>
		# 			# if not R.loader.checkError(results) then return

		# 			# drawing = JSON.parse(results.drawing)
		# 			# layer = draft.group.parent
		# 			# layer.removeChildren()
		# 			# layer.addChild(draft.group)
					
		# 			# $(@currentDrawing.svg).parent().parent().hide()
					

		# 			draft.addPathsFromPathList(drawing.pathList, true, true)

		# 			setTimeout(showDrawing, 200)
		# 			return

		# 		showDrawing()
				
		# 		return)

		# 	return

		# loadSVG: ()->
		# 	if P.view.zoom < 0.125
		# 		return
		# 	args = 
		# 		cityName: R.city.name
		# 		bounds: P.view.bounds
		# 	$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadSVG', args: args } ).done(@loadSVGCallback)
		# 	return

		createDrawing: (itemString, reloadUnderneathRasters=false)->
			item = JSON.parse(itemString)

			if R.pkToDrawing?.get(item._id.$oid)?
				return
			# bounds = null
			# bounds = if item.bounds? then JSON.parse(item.bounds) else null
			bounds = if item.box? then R.view.grid.boundsFromBox(item.box) else null
			date = item.date?.$date
			drawing = new Item.Drawing(null, null, item.clientId, item._id.$oid, item.owner, date, item.title, null, item.status, item.pathList, item.svg, bounds)
			if reloadUnderneathRasters
				@reloadRasters(drawing.rectangle)
			return

		createDrawings: (results)=>
			for itemString in results.items
				
				# if item.status == 'rejected'
				# 	R.rejectedDrawings ?= []
				# 	R.rejectedDrawings.push(item)
				# 	R.nRejectedDrawings++
				# 	continue
				@createDrawing(itemString)
				
			return 

		# loadSVGCallback: (results)=>
		# 	if not @checkError(results) then return
		# 	if results.user?
		# 		@setMe(results.user)
		# 	R.nRejectedDrawings = 0
			
		# 	@createDrawings(results)

		# 	# setTimeout((()=>R.rasterizer.refresh()), 1000)
		# 	if R.view.rejectedListJ?
		# 		R.view.rejectedListJ.find(".n-items").html(R.nRejectedDrawings)
		# 	@endLoading()
		# 	R.toolManager.updateButtonsVisibility()
		# 	if @focusOnDrawing?
		# 		drawingPk = @focusOnDrawing
		# 		for drawing in R.drawings
		# 			if drawing.pk == drawingPk
		# 				bounds = drawing.getBounds()
		# 				if bounds?
		# 					R.view.fitRectangle(bounds, true)
		# 				break
		# 		@focusOnDrawing = null
			

		# 	@loadVotes()
		# 	return

		loadDraft: ()->
			args = 
				cityName: R.city.name
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDraft', args: args } ).done(@loadDraftCallback)
			return

		loadDraftCallback: (results)=>
			if not @checkError(results) then return
			if results.user?
				@setMe(results.user)

			@createDrawings(results)
			@endLoading()
			R.toolManager.updateButtonsVisibility()
			return

		loadDrawingsAndTiles: (bounds, callback=null)->
			grid = R.view.grid
			args = 
				cityName: R.city.name
				# xMin: Math.floor(bounds.left / 1000)
				# xMax: Math.ceil(bounds.right / 1000)
				# yMin: Math.floor(bounds.top / 1000)
				# yMax: Math.ceil(bounds.bottom / 1000)
				bounds: bounds
				rejected: R.loadRejectedDrawings

			if @loadingType == 'screen-ignore-loaded' or @loadingType == 'tiles-ignore-loaded'
				args.drawingsToIgnore = Array.from( R.pkToDrawing.keys() )
				args.tilesToIgnore = R.tools.choose.tilePks

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawingsAndTilesFromBounds', args: args } ).done((results)=>
				@loadDrawingsAndTilesCallback(results)
				callback?())
			return

		loadDrawingsAndTilesCallback: (results)=>
			if not @checkError(results) then return

			@createDrawings(results)

			tiles = JSON.parse(results.tiles)
			
			for tile in tiles
				R.tools.choose.createTile(tile)

			return

		# loadTiles: (bounds)->
		# 	Choose = R.Tools.Choose

		# 	width = Choose.paperWidth * Choose.nSheetsPerTile
		# 	height = Choose.paperHeight * Choose.nSheetsPerTile

		# 	left = R.view.grid.limitCDRectangle.left
		# 	top = R.view.grid.limitCDRectangle.top

		# 	args = 
		# 		city: R.city
		# 		xMin: Math.floor( (bounds.left - left) / width )
		# 		xMax: Math.ceil( (bounds.right - left) / width )
		# 		yMin: Math.floor( (bounds.top - top) / height )
		# 		yMax: Math.ceil( (bounds.bottom - top) / height )

		# 	console.log(bounds, args)
		# 	$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadTilesFromBounds', args: args } ).done(@loadTilesCallback)
		# 	return

		# loadTilesCallback: (results)=>
		# 	if not @checkError(results) then return
			
		# 	tiles = JSON.parse(results.tiles)
		# 	for tile in tiles

		# 		R.tools.choose.createTile(tile)

		# 	return

		clearRasters: ()->

			@rasters.forEach (rastersOfScale, s)=>
				rastersOfScale.forEach (rastersY, y)=>
					rastersY.forEach (rs, x)=>
						while rs.length > 0
							rs.pop().remove()
						return
			return

		reloadRasters: (bounds)->

			# Remove rasters
			@rasters.forEach (rastersOfScale, s)=>
				rastersOfScale.forEach (rastersY, y)=>						
					rastersY.forEach (rs, x)=>
						if rs.length > 0 and rs[0].data.bounds.intersects(bounds)
							while rs.length > 0
								rs.pop().remove()
							# console.log('remove rasters in bounds: ', x, ', ', y, ', bounds:', bounds)
						return

			@loadRasters(bounds, false)
			return

		getScaleNumber: ()->
			ln4 = Math.log(@constructor.scaleRatio)
			return Math.max(0, Math.floor(Math.log(1 / P.view.zoom) / ln4))

		getScale: (scaleNumber)->
			return Math.pow(@constructor.scaleRatio, scaleNumber)

		getQuantizedBounds: (bounds, scaleNumber, scale)->
			if not (bounds instanceof P.Rectangle)
				bounds = new P.Rectangle(bounds)

			scaleNumber ?= @getScaleNumber()
			scale ?= @getScale(scaleNumber)
			nPixelsPerTile = scale * 1000

			quantizedBounds =
				t: Math.floor(bounds.top / nPixelsPerTile)
				l: Math.floor(bounds.left / nPixelsPerTile)
				b: Math.ceil(bounds.bottom / nPixelsPerTile)
				r: Math.ceil(bounds.right / nPixelsPerTile)

			return quantizedBounds

		# getLoadingBounds: ()->
		# 	bounds = P.view.bounds
		# 	scaleNumber = @getScaleNumber()
		# 	scale = @getScale(scaleNumber)
		# 	nPixelsPerTile = scale * 1000
		# 	return	bounds.expand(nPixelsPerTile)

		removeRaster: (rx, ry)->
			@rasters.forEach (rastersOfScale, s)=>
				rastersOfScale.forEach (rastersY, y)=>						
					rastersY.forEach (rs, x)=>
						if x == rx and y == ry
							while rs.length > 0
								rs.pop().remove()
			return

		loadRasters: (bounds=P.view.bounds, alsoLoadDrawingsAndTiles=true, callback=null)->
			
			if R.useSVG
				if alsoLoadDrawingsAndTiles
					@loadDrawingsAndTiles(bounds, callback)
				return

			# @rectangle ?= new P.Path.Rectangle(P.view.bounds.expand(-P.view.bounds.width / 3, -P.view.bounds.height / 3))
			# @rectangle.position = P.view.bounds.center
			# @rectangle.strokeColor = 'red'
			# @rectangle.strokeWidth = 1

			# if not @texts?
			# 	@texts = []
			# 	for n in [0 .. 3]
			# 		text = new P.PointText(new P.Point(0, 0))
			# 		text.justification = 'center'
			# 		text.fillColor = 'black'
			# 		@texts.push(text)

			# margin = 10
			# @texts[0].position.x = bounds.center.x
			# @texts[0].position.y = bounds.top + margin
			# @texts[1].position.x = bounds.left + margin
			# @texts[1].position.y = bounds.center.y
			# @texts[2].position.x = bounds.center.x
			# @texts[2].position.y = bounds.bottom - margin
			# @texts[3].position.x = bounds.right - margin
			# @texts[3].position.y = bounds.center.y

			scaleNumber = @getScaleNumber()
			scale = @getScale(scaleNumber)
			nPixelsPerTile = scale * 1000
			quantizedBounds = @getQuantizedBounds(bounds, scaleNumber, scale)
			quantizedViewBounds = @getQuantizedBounds(P.view.bounds, scaleNumber, scale)

			# @texts[0].content = '' + quantizedBounds.t
			# @texts[1].content = '' + quantizedBounds.l
			# @texts[2].content = '' + quantizedBounds.b
			# @texts[3].content = '' + quantizedBounds.r

			rastersOfScale = @rasters.get(scaleNumber)
			
			if not rastersOfScale?
				rastersOfScale = new Map()
				@rasters.set(scaleNumber, rastersOfScale)

			# Remove drawings and tiles
			limits = P.view.bounds.expand(nPixelsPerTile)

			R.pkToDrawing?.forEach (drawing, pk)=>
				drawingBounds = drawing.getBounds()
				if drawing.status != 'draft' and drawing.status != 'flagged_pending' and drawingBounds? and not drawingBounds.intersects(limits)
					drawing.remove()

			R.tools.choose.removeTiles(limits)

			# Remove rasters
			@rasters.forEach (rastersOfScale, s)=>

				if s != scaleNumber 						# Remove rasters of other scales
					rastersOfScale.forEach (rastersY, y)=>
						rastersY.forEach (rs, x)=>
							# console.log('remove other scale: ', x, ', ', y)
							while rs.length > 0
								rs.pop().remove()
							return

					@rasters.delete(s)

				else  											# Remove rasters of current scale
					rastersOfScale.forEach (rastersY, y)=>						
						rastersY.forEach (rs, x)=>
							if y < quantizedViewBounds.t or y > quantizedViewBounds.b or x < quantizedViewBounds.l or x > quantizedViewBounds.r
								# console.log('remove not in view bounds: ', x, ', ', y)
								while rs.length > 0
									rs.pop().remove()
								rastersY.delete(x)
							return

			for n in [quantizedBounds.t .. quantizedBounds.b - 1]
				for m in [quantizedBounds.l .. quantizedBounds.r - 1]
					rs = rastersOfScale?.get(n)?.get(m)
					if not rs? or rs.length == 0

						drawingsToLoad = []
						if R.loadRejectedDrawings
							drawingsToLoad.push('inactive')
						if R.loadActiveDrawings
							drawingsToLoad.push('active')

						rs = []
						for layerName in drawingsToLoad
							
							# console.log('load: ', m, ', ', n)

							group = new P.Group()

							raster = new P.Raster(location.origin + '/static/rasters/' + layerName + '/zoom' + scaleNumber + '/' + m + ','  + n + '.png' + '?version=' + Math.random())
							raster.position.x = (m + 0.5) * nPixelsPerTile
							raster.position.y = (n + 0.5) * nPixelsPerTile
							raster.scale(scale * 1.001)
							# raster.scale(scale)
							
							rasterBounds = new P.Rectangle(m * nPixelsPerTile, n * nPixelsPerTile, nPixelsPerTile, nPixelsPerTile)
							raster.data.bounds = rasterBounds

							rs.push(raster)
							group.addChild(raster)

							# rectangle = new P.Path.Rectangle(rasterBounds.expand(-10))
							# rectangle.strokeColor = 'blue'
							# rectangle.strokeWidth = 5
							# group.addChild(rectangle)

							if alsoLoadDrawingsAndTiles and P.project.view.zoom >= 0.125 and ( @loadingType == 'tiles' or @loadingType == 'tiles-ignore-loaded' )
								# rectangle.strokeColor = 'red'
								@loadDrawingsAndTiles(rasterBounds)

							# text = new P.PointText(raster.position)
							# text.justification = 'center'
							# text.fillColor = 'black'
							# text.content = '' + m + ', ' + n
							# group.addChild(text)

							if layerName == 'active'
								# @activeRasterGroup.addChild(raster)
								@activeRasterGroup.addChild(group)
							else
								@inactiveRasterGroup.addChild(group)

						rastersY = rastersOfScale.get(n)
						if not rastersY?
							rastersY = new Map()
							rastersOfScale.set(n, rastersY)
						rastersY.set(m, rs)

			if alsoLoadDrawingsAndTiles and @loadingType == 'screen' or @loadingType == 'screen-ignore-loaded'
				@loadDrawingsAndTiles(bounds)

			return

		loadVotes: ()=>
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadVotes', args: { cityName: R.city.name } } ).done(@loadVotesCallback)
			return

		loadVotesCallback: (results)=>
			if results.state != 'not_logged_in'
				if not @checkError(results) then return
			
			@userVotes ?= new Map()

			if results.votes?
				for vote in results.votes
					if vote.emailConfirmed
						@userVotes.set(vote.pk, vote.positive)
						R.items[vote.pk]?.setStrokeColorFromVote(vote.positive)

			return

		# load an area from the server
		# the project coordinate system is divided into square cells of size *R.scale*
		# an Area is an object { pos: P.Point, planet: P.Point } corresponding to a cell (pos is the top left corner of the cell, the server consider the cells to be 1 unit wide (1000 pixels))
		# a load does:
		# - build a list of Area overlapping *area* and not already loaded
		# - define a load limit rectangle equels to *area* expanded to 2 x R.scale
		# - remove RItems which are not within this limit anymore AND in an area which must be unloaded
		#   (do not remove items on an area which is not unloaded, otherwise they wont be reloaded if user comes back on it)
		# - remove loaded areas which where unloaded
		# - load areas
		# @param [P.Rectangle] (optional) the area to load, *area* equals the bounds of the view if not defined
		# load: (area=null) ->

		# 	if not @loadRequired() then return false
		# 	debugger
		# 	if area? then console.log area.toString()

		# 	# R.startLoadingBar()

		# 	@previousLoadPosition = position: P.view.center, zoom: P.view.zoom

		# 	bounds = @getLoadingBounds(area)

		# 	unloadDist = Math.round(R.scale / P.view.zoom)

		# 	limit = R.view.entireArea or bounds.expand(unloadDist)

		# 	# remove rasters which are outside the limit
		# 	R.rasterizer.unload(limit)

		# 	qZoom = Utils.CS.quantizeZoom(1.0 / P.view.zoom)

		# 	# remove areas which are outside the limit
		# 	@unloadAreas(area, limit, qZoom)

		# 	scale = R.scale * qZoom

		# 	# find top, left, bottom and right positions of the area in the quantized space
		# 	t = Utils.floorToMultiple(bounds.top, scale)
		# 	l = Utils.floorToMultiple(bounds.left, scale)
		# 	b = Utils.floorToMultiple(bounds.bottom, scale)
		# 	r = Utils.floorToMultiple(bounds.right, scale)

		# 	if @debug then @updateDebugPaths(limit, bounds, t, l, b, r)

		# 	# add areas to load
		# 	areasToLoad = @getAreasToLoad(scale, qZoom, t, l, b, r)

		# 	if @nothingToLoad(areasToLoad) then return false

		# 	# load areas
		# 	@showDrawingBar()
		# 	@showLoadingBar(500)

		# 	rectangle = { left: l / 1000.0, top: t / 1000.0, right: r / 1000.0, bottom: b / 1000.0 }
		# 	@requestAreas(rectangle, areasToLoad, qZoom)
		# 	return true

		dispatchLoadFinished: ()->
			# console.log "dispatch command executed"
			commandEvent = document.createEvent('Event')
			commandEvent.initEvent('command executed', true, true)
			document.dispatchEvent(commandEvent)
			return

		# set R.me (the server sends the username at each load)
		# user can be an integer, when he is not connected (it's the number of logged off users who have connected)
		setMe: (user)->
			if not R.me? and user?
				R.me = user
				if R.socket.chatJ? and R.socket.chatJ.find("#chatUserNameInput").length==0
					R.socket.startChatting( R.me )
			return

		removeDeletedItems: (deletedItems)->
			if not deletedItems? then return
			for id, deletedItemLastUpdate of deletedItems
				R.items[id]?.remove()
			return

		mustLoadItem: (item)->
			return not R.items[item.clientId]?

		unloadItem: (item)->
			return

		parseNewItems: (items)->
			itemsToLoad = []

			for i in items
				item = JSON.parse(i)

				if not @mustLoadItem(item) then continue
				@unloadItem(item)

				if item.rType == 'Box' or item.rType == 'Drawing'
					itemsToLoad.unshift(item)
				else
					itemsToLoad.push(item)

			return itemsToLoad

		moduleLoaded: (args)->
			@createPath(args)
			delete @pathsToCreate[args.id]
			if Utils.isEmpty(@pathsToCreate)
				@hideDrawingBar()
				@hideLoadingBar()
				R.rasterizer.checkRasterizeAreasToUpdate?(true)
			return

		loadModuleAndCreatePath: (args)->
			@pathsToCreate[args.id] = true
			ModuleLoader.load(args.path.object_type, ()=> @moduleLoaded(args))
			# ModuleLoader.load(args.path.object_type, ()=> setTimeout((()=> @moduleLoaded(args)), 0))
			return

		createPath: (args)->
			drawingPk = args.drawing?.$oid
			drawingId = if drawingPk? then (Item.Drawing.pkToId[drawingPk] or drawingPk) else null
			path = new R.tools[args.path.object_type].Path(args.date, args.data, args.id, args.pk, args.points, args.lock, args.owner, drawingId)
			path.lastUpdateDate = args.path.lastUpdate?.$date
			return path

		createNewItems: (itemsToLoad)->
			newItems = []
			for item in itemsToLoad

				pk = item._id.$oid
				id = item.clientId
				date = item.date?.$date
				data = if item.data? and item.data.length>0 then JSON.parse(item.data) else null
				lock = if item.lock? then R.items[item.lock] else null

				switch item.rType
					# when 'Box'
					# 	box = item
					# 	if box.box.coordinates[0].length<5
					# 		console.log "Error: box has less than 5 points"

					# 	lock = null
					# 	switch box.object_type
					# 		when 'lock'
					# 			lock = new Item.Lock(Utils.CS.rectangleFromBox(box), data, id, box._id.$oid, box.owner, date, box.module?.$oid)
					# 		when 'link'
					# 			lock = new Item.Link(Utils.CS.rectangleFromBox(box), data, id, box._id.$oid, box.owner, date, box.module?.$oid)
					# 		when 'website'
					# 			lock = new Item.Website(Utils.CS.rectangleFromBox(box), data, id, box._id.$oid, box.owner, date, box.module?.$oid)
					# 		when 'video-game'
					# 			lock = new Item.VideoGame(Utils.CS.rectangleFromBox(box), data, id, box._id.$oid, box.owner, date, box.module?.$oid)

					# 	lock.lastUpdateDate = box.lastUpdate.$date
						
					# 	if lock?
					# 		newItems.push(lock)

					# when 'Div'			# add RDivs (Text and Media)
					# 	div = item
					# 	if div.box.coordinates[0].length<5
					# 		console.log "Error: box has less than 5 points"

					# 	# rdiv = new R.g[div.object_type](Utils.CS.rectangleFromBox(box), data, div._id.$oid, date, div.lock)

					# 	switch div.object_type
					# 		when 'text'
					# 			rdiv = new Item.Text(Utils.CS.rectangleFromBox(div), data, id, pk, date, lock)
					# 		when 'media'
					# 			rdiv = new Item.Media(Utils.CS.rectangleFromBox(div), data, id, pk, date, lock)

					# 	rdiv.lastUpdateDate = div.lastUpdate.$date
						
					# 	if rdiv?
					# 		newItems.push(rdiv)
							
					when 'Path' 		# add RPaths
						path = item
						if not path.owner?
							console.error('A path does not have any owner!')
							continue

						planet = new P.Point(path.planetX, path.planetY)
						data?.planet = planet

						points = []

						# convert points from planet coordinates to project coordinates
						for point in path.points.coordinates
							points.push( Utils.CS.posOnPlanetToProject(point, planet) )

						# create the RPath with the corresponding RTool
						rpath = null
						newPath = null
						args =
							path: path
							date: date
							data: data
							id: id
							pk: pk
							points: points
							lock: lock
							owner: path.owner
							drawing: path.drawing
						if R.tools[path.object_type]?
							newPath = @createPath(args)
						else
							@loadModuleAndCreatePath(args)

						if newPath?
							newItems.push(newPath)

					when 'AreaToUpdate'
						R.rasterizer.addAreaToUpdate(Utils.CS.rectangleFromBox(item).expand(5)) # expand because of stroke path

						# areaToUpdate = new P.Path.Rectangle(Utils.CS.rectangleFromBox(item))
						# areaToUpdate.fillColor = 'rgba(255,50,50,0.25)'
						# areaToUpdate.strokeColor = 'rgba(255,50,50,0.5)'
						# areaToUpdate.strokeWidth = 3
						# areaToUpdate.getBounds = ()-> return areaToUpdate.bounds
						# R.view.areasToUpdateLayer.addChild(areaToUpdate)
						# R.view.mainLayer.activate()

					when 'Drawing'
						# if item.box.coordinates[0].length<5
						# 	console.log "Error: drawing has less than 5 points"

						# drawing = new Item.Drawing(Utils.CS.rectangleFromBox(item), data, id, item._id.$oid, item.owner, date, item.title, item.description, item.status, item.pathList)
						drawing = new Item.Drawing(null, data, id, item._id.$oid, item.owner, date, item.title, item.description, item.status, item.pathList, item.svg)

						if drawing?
							newItems.push(drawing)
					else
						continue
			return newItems

		endLoading: ()->
			if Utils.isEmpty(@pathsToCreate)
				@hideLoadingBar()
				@hideDrawingBar()
			@dispatchLoadFinished()
			return

		# load callback: add loaded RItems
		loadCallback: (results, rasterizeItems=false, rasterizeAreasToUpdate=true)=>
			console.log "load callback"
			console.log P.project.activeLayer.name

			if not @checkError(results) then return

			if results.hasOwnProperty('message') && results.message == 'no_paths'
				@dispatchLoadFinished()
				return

			@setMe(results.user)

			if not results.qZoom?
				results.qZoom = 1

			if results.rasters? then R.rasterizer.load(results.rasters, results.qZoom)

			# if R.rasterizerMode then R.removeItemsToUpdate(results.itemsToUpdate)

			@removeDeletedItems(results.deletedItems)

			itemsToLoad = @parseNewItems(results.items)

			newItems = @createNewItems(itemsToLoad)

			R.rasterizer.setQZoomToUpdate(results.qZoom)

			if rasterizeItems
				R.rasterizer.rasterize(newItems)
				R.rasterizer.rasterizeRectangle()

			if rasterizeAreasToUpdate
				if not results.rasters? or results.rasters.length==0
					R.rasterizer.checkRasterizeAreasToUpdate()

			Item.Div.updateZindex(R.sortedDivs)

			@endLoading()
			return

		loadCallbackTipibot: (results)=>
			if not @checkError(results) then return
			itemsToLoad = []

			@drawingPaths = []
			@drawingPk = results.pk

			nPoints = 0

			# parse items and remove them if they are on stage (they must be updated)
			for i in results.items
				item = JSON.parse(i)

				pk = item._id.$oid
				id = item.clientId
				date = item.date?.$date
				data = if item.data? and item.data.length>0 then JSON.parse(item.data) else null

				points = data.points
				planet = data.planet

				controlPath = new P.Path()

				for point, i in points by 4
					controlPath.add(Utils.CS.posOnPlanetToProject(point, planet))
					controlPath.lastSegment.handleIn = new P.Point(points[i+1])
					controlPath.lastSegment.handleOut = new P.Point(points[i+2])
					controlPath.lastSegment.rtype = points[i+3]

				controlPath.flatten(5)

				path = []

				for segment in controlPath.segments
					if nPoints < @constructor.maxNumPoints
						path.push(segment.point)
					else
						@drawingPaths.push(path)
						path.length = 0
						path.push(segment.point)
					nPoints++

				if path.length > 1
					@drawingPaths.push(path)

				controlPath.remove()

			@sendNextPathsToTipibot()
			return

		sendNextPathsToTipibot: ()->
			bounds = R.view.grid.limitCD.bounds
			paths = []

			nPoints = 0

			while @drawingPaths.length > 0
				path = @drawingPaths.shift()
				paths.push(path)
				nPoints += path.length
				if nPoints >= @constructor.maxNumPoints
					break

			R.socket.tipibotSocket.send(JSON.stringify( bounds: bounds, paths: paths, type: 'setNextDrawing', drawingPk: @drawingPk ))
			return

		displayError: (error)=>
			R.alertManager.alert("An error occured, the page will reload in 2 seconds", "error")
			@showLoadingBar(1000)
			setTimeout( (()-> window.location.reload()) , 2000)
			return

		# check for any error in an ajax callback and display the appropriate error message
		# @return [Boolean] true if there was no error, false otherwise
		checkError: (result)=>
			# console.log result
			if not result? then return true
			if result.state == 'not_logged_in'
				R.alertManager.alert("You must be logged in to update drawings to the database", "info")
				@hideLoadingBar()
				return false
			if result.state == 'error' or result.status == 'error'
				if result.message == 'invalid_url'
					R.alertManager.alert("Your URL is invalid or does not point to an existing page", "error")
				else
					options = []
					if result.messageOptions?
						for option in result.messageOptions
							options[option] = result[option]
					R.alertManager.alert(result.message, "error", null, options)
				@hideLoadingBar()
				return false
			else if result.state == 'system_error' or result.status == 'system_error'
				console.log result.message
				@hideLoadingBar()
				return false
			return true

		### Debug methods ###

		updateDebugPaths: (limit, bounds, t, l, b, r)->
			@unloadRectangle?.remove()
			@unloadRectangle = new P.Path.Rectangle(limit)
			@unloadRectangle.name = '@debug load unload rectangle'
			@unloadRectangle.strokeWidth = 1
			@unloadRectangle.strokeColor = 'red'
			@unloadRectangle.dashArray = [10, 4]
			R.view.debugLayer.addChild(@unloadRectangle)

			@viewRectangle?.remove()
			@viewRectangle = new P.Path.Rectangle(bounds)
			@viewRectangle.name = '@debug load view rectangle'
			@viewRectangle.strokeWidth = 1
			@viewRectangle.strokeColor = 'blue'
			R.view.debugLayer.addChild(@viewRectangle)

			@limitRectangle?.remove()
			@limitRectangle = new P.Path.Rectangle(new P.Point(l, t), new P.Point(r, b))
			@limitRectangle.name = '@debug load limit rectangle'
			@limitRectangle.strokeWidth = 2
			@limitRectangle.strokeColor = 'blue'
			@limitRectangle.dashArray = [10, 4]
			R.view.debugLayer.addChild(@limitRectangle)
			return

		updateDebugArea: (area)->
			area.rectangle.strokeColor = 'red'
			@removeDebugRectangle(area.rectangle)
			return

		removeDebugRectangle: (rectangle)->
			removeRect = ()-> rectangle.remove()
			setTimeout(removeRect, 1500)
			return

		createAreaDebugRectangle: (x, y, scale)->
			areaRectangle = new P.Path.Rectangle(x, y, scale, scale)
			areaRectangle.name = '@debug load area rectangle'
			areaRectangle.strokeWidth = 1
			areaRectangle.strokeColor = 'green'
			R.view.debugLayer.addChild(areaRectangle)
			area.rectangle = areaRectangle
			return

		# this.benchmark_load = ()->
		# 	bounds = P.view.bounds
		# 	scale = R.scale
		# 	t = Utils.floorToMultiple(bounds.top, scale)
		# 	l = Utils.floorToMultiple(bounds.left, scale)
		# 	b = Utils.floorToMultiple(bounds.bottom, scale)
		# 	r = Utils.floorToMultiple(bounds.right, scale)

		# 	# add areas to load
		# 	areasToLoad = []

		# 	for x in [l .. r] by scale
		# 		for y in [t .. b] by scale
		# 			planet = projectToPlanet(new P.Point(x,y))
		# 			pos = projectToPosOnPlanet(new P.Point(x,y))

		# 			area = { pos: pos, planet: planet, x: x/1000, y: y/1000 }

		# 			areasToLoad.push(area)

		# 	console.log "areasToLoad: "
		# 	console.log areasToLoad

#		# 	Dajaxice.draw.benchmark_load(R.loader.checkError, { areasToLoad: areasToLoad })
		# 	$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'benchmark_load', args: { areasToLoad: areasToLoad } } ).done(R.loader.checkError))
		# 	return

	# class RasterizerLoader extends Loader

	# 	loadRequired: ()->
	# 		return true

	# 	nothingToLoad: (areasToLoad)->
	# 		return false

	# 	getAreaToLoad: (areasToLoad, pos, planet, x, y, scale, qZoom)->
	# 		area = { pos: pos, planet: planet }

	# 		areasToLoad.push(area)

	# 		if @debug then @createAreaDebugRectangle(x, y, scale)

	# 		if not @areaIsLoaded(pos, planet)
	# 			@loadedAreas.push(area)
	# 		return

	# 	createItemsDates: ()->
	# 		itemsDates = {}
	# 		for id, item of R.items
	# 			# if bounds.contains(item.getBounds())
	# 			# type = ''
	# 			# if Lock.prototype.isPrototypeOf(item)
	# 			# 	type = 'Box'
	# 			# else if Div.prototype.isPrototypeOf(item)
	# 			# 	type = 'Div'
	# 			# else if Path.prototype.isPrototypeOf(item)
	# 			# 	type = 'Path'
	# 			itemsDates[id] = item.lastUpdateDate
	# 			# itemsDates.push( id: id, lastUpdate: item.lastUpdateDate, type: type )
	# 		return itemsDates

	# 	# requestAreas: (rectangle, areasToLoad, qZoom)->
	# 	# 	itemsDates = @createItemsDates()
	# 	# 	$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadRasterizer', args: { areasToLoad: areasToLoad, itemsDates: itemsDates, city: R.city } } ).done(@loadCallback)
	# 	# 	return

	# 	mustLoadItem: ()->
	# 		return true

	# 	unloadItem: (item)->
	# 		itemToReplace = R.items[item._id.$oid]
	# 		if itemToReplace?
	# 			console.log "itemToReplace: " + itemToReplace.id
	# 			itemToReplace.remove() 	# if item is loaded: remove it (it must be updated)
	# 		return

	# 	endLoading: ()->
	# 		if typeof window.saveOnServer == "function"
	# 			R.rasterizerBot.rasterizeAndSaveOnServer()
	# 		return

	# Loader.RasterizerLoader = RasterizerLoader

	return Loader
