define ['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'Items/Item', 'Commands/Command', 'UI/Modal', 'i18next', 'moment' ], (P, R, Utils, Tool, Item, Command, Modal, i18next, moment) ->

	class ChooseTool extends Tool

		@paperMargins = 16
		@paperWidth = 210 - @paperMargins
		@paperHeight = 297 - @paperMargins
		@nSheetsPerTile = 2
		@nSecondsPerTile = 0.25

		@label = 'Choose a tile'
		@popover = false
		# @description = ''
		# @iconURL = 'glyphicon-envelope'
		# @iconURL = 'cursor.png'
		@iconURL = if R.style == 'line' then 'chooser3.png' else if R.style == 'hand' then 'chooser3.png' else 'chooser3.png'
		@buttonClasses = 'displayName'

		@cursor =
			position:
				x: 0, y: 0
			name: 'pointer'


		constructor: () ->
			super(true)

			activeLayer = P.project.activeLayer
			@tileRectangles = new P.Layer()
			@tileRectangles.bringToFront()
			@tileRectangles.visible = false
			activeLayer.activate()

			@tiles = new Map()
			@tilePks = []
			@idToTile = new Map()
			return

		hideOddLines: ()=>
			@oddLines?.visible = false
			return

		showOddLines: ()=>
			@oddLines?.visible = @lines?.visible
			return

		showGrid: ()=>
			@tileRectangles.visible = true

			if @lines?
				@lines.visible = true
				@oddLines.visible = Math.floor( Math.log(P.view.zoom) / Math.log(2) ) >= -3
				return
			else
				@lines = new P.Group()
				@oddLines = new P.Group()
			
			rectangle = R.view.grid.limitCDRectangle
			x = rectangle.left
			n = 0
			while x < rectangle.right
				line = new P.Path()
				line.add(x, rectangle.top)
				line.add(x, rectangle.bottom)
				line.strokeWidth = 1
				line.strokeColor = 'black'
				line.strokeColor.opacity = 0.75
				line.strokeScaling = false
				if n%@constructor.nSheetsPerTile != 0
					line.dashArray = [2, 2]
					@oddLines.addChild(line)
				else
					@lines.addChild(line)
				x += @constructor.paperWidth
				n++
			y = rectangle.top
			n = 0
			while y < rectangle.bottom
				line = new P.Path()
				line.add(rectangle.left, y)
				line.add(rectangle.right, y)
				line.strokeWidth = 1
				line.strokeColor = 'black'
				line.strokeColor.opacity = 0.75
				line.strokeScaling = false
				if n%@constructor.nSheetsPerTile != 0
					line.dashArray = [2, 2]
					@oddLines.addChild(line)
				else
					@lines.addChild(line)
				y += @constructor.paperHeight
				n++
			return

		hideGrid: ()->
			@lines?.visible = false
			@oddLines?.visible = false
			@tileRectangles.visible = false
			return

		select: (deselectItems=false, updateParameters=true, forceSelect=false, selectedBy='default')->
			if R.city?.finished
				R.alertManager.alert "Cette édition est terminée, vous ne pouvez plus dessiner.", 'info'
				return

			if not R.userAuthenticated and not forceSelect
				R.alertManager.alert 'Log in before choosing a tile', 'info'
				return

			R.tracer?.hide()

			super(false, updateParameters, selectedBy)
			R.tools.select.deselectAll()
			@showGrid()
			return

		deselect: ()->
			super
			@hideGrid()
			@deselectTile()
			@highlight?.visible = false
			return

		begin: (event) ->
			return

		update: (event) ->
			return

		move: (event) ->
			if event.originalEvent?.target != document.getElementById('canvas') then return

			if @ignoreMouseMoves then return

			width = @constructor.paperWidth * @constructor.nSheetsPerTile
			height = @constructor.paperHeight * @constructor.nSheetsPerTile

			if not @highlight?
				margin = 5
				@highlight = new P.Path.Rectangle(margin, margin, width - margin, height - margin)
				@highlight.strokeWidth = 5
				@highlight.strokeScaling = false
				@highlight.strokeColor = R.selectionBlue
				@highlight.dashArray = [8, 5]
				# @highlight.fillColor = R.selectionBlue
				# @highlight.fillColor.alpha = 0.25
				# @highlight.strokeColor.alpha = 0.25

			left = R.view.grid.limitCDRectangle.left
			top = R.view.grid.limitCDRectangle.top
			right = R.view.grid.limitCDRectangle.right
			bottom = R.view.grid.limitCDRectangle.bottom

			@highlight.position.x = left + (Math.floor( (event.point.x - left) / width) + 0.5) * width
			@highlight.position.y = top + (Math.floor( (event.point.y - top) / height) + 0.5) * height

			@highlight.visible = true
			if event.point.x < left or event.point.x > right or event.point.y < top or event.point.y > bottom
				@highlight.visible = false

			return

		projectToXY: (point)->
			width = @constructor.paperWidth * @constructor.nSheetsPerTile
			height = @constructor.paperHeight * @constructor.nSheetsPerTile

			left = R.view.grid.limitCDRectangle.left
			top = R.view.grid.limitCDRectangle.top

			tileX = Math.floor( (point.x - left) / width )
			tileY = Math.floor( (point.y - top) / height )
			return new P.Point(tileX, tileY)

		end: (event) ->
			if not R.view.grid.limitCDRectangle.contains(event.point) then return

			width = @constructor.paperWidth * @constructor.nSheetsPerTile
			height = @constructor.paperHeight * @constructor.nSheetsPerTile

			left = R.view.grid.limitCDRectangle.left
			top = R.view.grid.limitCDRectangle.top
			right = R.view.grid.limitCDRectangle.right
			bottom = R.view.grid.limitCDRectangle.bottom

			nTilesPerRow = Math.ceil( (right - left) / width )
			nTilesPerColumn = Math.ceil( (bottom - top) / height )
			console.log('num tiles: ' + (nTilesPerColumn * nTilesPerRow))

			tileX = Math.floor( (event.point.x - left) / width )
			tileY = Math.floor( (event.point.y - top) / height )

			tile = @tiles.get(tileY)?.get(tileX)

			tileNumber = Math.max(0, tileY - 1) * nTilesPerRow + tileX

			tileLeft = left + tileX * width
			tileTop = top + tileY * height

			@currentTile = { rectangle: new P.Rectangle(tileLeft, tileTop, width, height), x: tileX, y: tileY, number: tileNumber+1 }

			if tile?
				
				# R.drawingPanel.showSelectedTiles(tiles, @currentTile.rectangle)
				@selectTile(tile)
				@loadTile(tile._id.$oid)

				return

			nDrawingsOnTile = 0
			for drawing in R.drawings
				if drawing.status != 'draft' and drawing.getBounds()?.intersects(@currentTile.rectangle)
					nDrawingsOnTile++

			@createChooseTileModal(tileNumber, tileX, tileY)
			return

		createChooseTileModal: (tileNumber, tileX, tileY)=>

			date = $('#canvas').attr('data-city-event-date')
			dueTime = moment(date).add(tileNumber * @constructor.nSecondsPerTile, 'seconds')
			# placementTime = moment(Date.now()).add(1, 'days') # dueTime.clone().subtract(5, 'days')

			modal = Modal.createModal( 
				id: 'choose-tile',
				title: "Choose tile", 
				submit: ( ()=> @chooseTile(tileNumber+1, tileX, tileY, @currentTile.rectangle) ),
				)

			modal.addText('Do you really want to paint this tile?', 'Do you want to paint this tile', false, { tileNumber: tileNumber + 1 })

			hours = i18next.t('hours')
			minutes = i18next.t('minutes')
			seconds = i18next.t('seconds')
			andText = i18next.t('and')

			divJ = modal.addText(i18next.t( 'This tile must be placed'))
			divJ.text(divJ.text() + ' :')
			divJ = modal.addText(i18next.t('on the') + dueTime.format(' dddd D MMMM'))
			divJ.css('text-align': 'center')
			divJ = modal.addText(i18next.t('at precisely'))
			divJ.css( { 'text-align': 'center', 'font-weight': 900, 'font-style': 'italic' } )
			divJ = modal.addText(dueTime.format('H [' + hours + '], m [' + minutes + ' ' + andText + '] s [' + seconds + '.]'))
			divJ.css('text-align': 'center')
			
			modal.modalJ.on('hidden.bs.modal', ()=> @ignoreMouseMoves = false )

			modal.show()


			@ignoreMouseMoves = true

			return

		getTileColorFromStatus: (tile)->
			statusToColor = {
				'pending': 'gray',
				'created': '#03a9f4',
				'validated': 'rgb(139, 195, 74)',
				'rejected': 'darkRed',
				'flagged': 'red'
			}
			color = statusToColor[tile.status]
			color ?= 'gray'
			return color

		createTile: (tile)->
			
			tilesRow = @tiles.get(tile.y)
			if tilesRow? and tilesRow.get(tile.x)
				return

			width = @constructor.paperWidth * @constructor.nSheetsPerTile
			height = @constructor.paperHeight * @constructor.nSheetsPerTile

			left = R.view.grid.limitCDRectangle.left
			top = R.view.grid.limitCDRectangle.top

			tileRectangle = P.Path.Rectangle(left + tile.x * width, top + tile.y * height, width, height)
			tileRectangle.fillColor = @getTileColorFromStatus(tile)
			tileRectangle.fillColor.alpha = 0.25

			@tileRectangles.addChild(tileRectangle)

			if not tilesRow?
				tilesRow = new Map()
				@tiles.set(tile.y, tilesRow)

			tile.rectangle = tileRectangle

			tilesRow.set(tile.x, tile)
			@tilePks.push(tile._id.$oid)
			@idToTile.set(tile.clientId, tile)

			# tileList = tilesRow.get(tile.x)
			# if not tileList?
			# 	tilesRow.set(tile.x, [tile])
			# else
			# 	tileList.push(tile)

			return tile

		updateTileStatus: (tile, status=null)->
			t = @tiles.get(tile.y)?.get(tile.x)
			if t?
				t.status = if status? then status else tile.status
				t.rectangle.fillColor = @getTileColorFromStatus(tile)
				t.rectangle.fillColor.alpha = 0.25

			return

		selectTile: (tile)->
			if @selectedTile? and @selectedTile != tile
				@deselectTile()
			tile.rectangle.strokeColor = R.selectionBlue
			tile.rectangle.strokeWidth = 4
			tile.rectangle.strokeScaling = false
			@selectedTile = tile
			return

		deselectTile: (updateDrawingPanel=true)->
			if updateDrawingPanel
				R.drawingPanel.deselectTile()
			@selectedTile?.rectangle?.strokeWidth = null
			@selectedTile = null
			return

		loadTile: (pk, rectangle=@currentTile.rectangle, setViewToTile=false)->
			args =
				pk: pk
			
			# tile.rectangle.strokeColor = 'black'
			# tile.rectangle.strokeWidth = 5
			# tile.rectangle.dashArray = [5, 5]

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadTile', args: args } ).done((result)=>
				if not R.loader.checkError(result) then return
				R.drawingPanel.setTile(result, rectangle)
				if setViewToTile
					R.view.fitRectangle(rectangle, true)
			)
			return

		removeTile: (tileInfo, tile)->
			tile ?= @tiles.get(tileInfo.y)?.get(tileInfo.x)
			
			if tile?
				if tileInfo.clientId == tile.clientId
					tile.rectangle.remove()
					@tiles.get(tileInfo.y).delete(tileInfo.x)
					@tilePks.splice(@tilePks.indexOf(tile.pk))
					@idToTile.delete(tile.clientId)

			return

		removeTiles: (limits)->
			topLeft = @projectToXY(limits.topLeft)
			bottomRight = @projectToXY(limits.bottomRight)
			@tiles.forEach (tileRow, y) =>
				if y < topLeft.y or y > bottomRight.y then return
				tileRow.forEach (tile, x) =>
					if x < topLeft.x or x > bottomRight.x then return
					if not tile.rectangle.bounds.intersects(limits)
						return @removeTile(tile)
			return

		chooseTile: (number, x, y, bounds)=> 
			@ignoreMouseMoves = false
			
			R.loader.showLoadingBar(500)

			args =
				number: number, 
				x: x, 
				y: y, 
				bounds: bounds
				# dueDate: dueDate.unix(), 
				# placementDate: placementDate.unix(), 
				cityName: R.city.name
				clientId: Utils.createId()
			
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'submitTile', args: args } ).done(@submitCallback)

			return

		submitCallback: (result)=>
			R.loader.hideLoadingBar()
			if not R.loader.checkError(result) then return

			result.tile = JSON.parse(result.tile)
			tile = @createTile(result.tile)
			@selectTile(tile)
			R.drawingPanel.setTile(result, @currentTile.rectangle)
			

			
			return

		doubleClick: (event) ->
			return

		keyUp: (event)->
			return

	R.Tools.Choose = ChooseTool
	return ChooseTool
