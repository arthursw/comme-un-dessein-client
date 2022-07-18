define ['paper', 'R', 'Utils/Utils', 'UI/Modal', 'i18next'], (P, R, Utils, Modal, i18next) ->

	class ExquisiteCorpseMask
		
		@margin = 100 * R.city.pixelPerMm

		constructor: (@grid)->
			@tiles = new Map()
			@tilePks = []
			return

		getTileXYAt: (point)->
			tileWidth = R.city.tileWidth * R.city.pixelPerMm
			tileHeight = R.city.tileHeight * R.city.pixelPerMm

			nx = Math.floor((point.x - @grid.limitCDRectangle.left) / tileWidth)
			ny = Math.floor((point.y - @grid.limitCDRectangle.top) / tileHeight)
			return new P.Point(nx, ny)

		getTileAt: (point)->
			pointN = @getTileXYAt(point)
			return @tiles.get(pointN.y)?.get(pointN.x)
		
		createMask: ()->
			@group = new P.Group()
			@tileGroup = new P.Group()
			@group.addChild(@tileGroup)
			
			@group.name = 'exquisiteCorpseGroup'
			@tileGroup.name = 'exquisiteCorpseTileGroup'

			tileWidth = R.city.tileWidth * R.city.pixelPerMm
			tileHeight = R.city.tileHeight * R.city.pixelPerMm
			x = @grid.limitCDRectangle.left
			nx = 0
			y = @grid.limitCDRectangle.top
			ny = 0
			n = 1
			while y < @grid.limitCDRectangle.bottom
				nx = 0
				x = @grid.limitCDRectangle.left
				while x < @grid.limitCDRectangle.right

					tw = Math.min(tileWidth, @grid.limitCDRectangle.right - x)
					th = Math.min(tileHeight, @grid.limitCDRectangle.bottom - y)
					rectangle = new P.Rectangle(x, y, tw, th)
					tile = new P.Path.Rectangle(rectangle.expand(-@constructor.margin))
					tile.fillColor = R.selectionBlue
					tile.data.rectangle = rectangle
					
					if R.city.finished
						tile.visible = false

					line = new P.Path.Rectangle(rectangle)
					line.strokeColor = 'black'
					line.opacity = 0.25
					line.strokeWidth = 1

					tile.data.x = nx
					tile.data.y = ny
					tile.data.number = n
					n++

					tilesRow = @tiles.get(ny)
					
					if not tilesRow?
						tilesRow = new Map()
						@tiles.set(ny, tilesRow)

					@tileGroup.addChild(tile)
					@group.addChild(line)
					
					tilesRow.set(nx, tile)
					
					x += tileWidth
					nx++
				y += tileHeight
				ny++

			return

		hideTile: (tile)->
			@tiles.get(tile.y)?.get(tile.x)?.visible = false
			return

		createTile: (tile)->
			@hideTile(tile)
			return tile

		removeTile: (tileInfo, tile)->
			return
		
		removeTiles: (limits)->
			return
		
		resetTilesHighlight: (event)->
			for tile in @tileGroup.children
				tile.fillColor = R.selectionBlue

		mouseMove: (event)->
			
			@resetTilesHighlight()

			tile = @getTileAt(event.point)

			sb = new P.Color(R.selectionBlue)
			sb.setLightness(sb.getLightness() + 0.3)
			tile?.fillColor = sb
			
			# R.canvasJ.css({cursor: 'pointer'})
			# R.canvasJ.css({cursor: 'auto'})

			return

		mouseBegin: (event)=>
			tile = @getTileAt(event.point)
			if tile?.visible
				@createChooseTileModal(event, tile)
			return not tile?.visible
		
		isDraftOnBounds: ()->
			bounds = R.Drawing.getDraft()?.getBounds()
			if not bounds? then return true
			tile = @getTileAt(bounds.topLeft)
			return tile? and tile.data.rectangle.contains(bounds)

		isTileAtPointRevealed: (event)->
			tile = @getTileAt(event.point)
			return not tile.visible

		mouseUpdate: (event)->
			tile = @getTileAt(event.point)
			bounds = R.Drawing.getDraft()?.getBounds()
			draftInTile = not bounds? or tile.data.rectangle.contains(bounds)
			return not tile.visible and draftInTile
		
		createChooseTileModal: (event, tile)=>
			nTiles = R.userProfile?.nTiles or 0
			nTilesLeft = R.city.nTilesMax - R.userProfile.nTiles
			
			if nTilesLeft <= 0

				modal = Modal.createModal( 
					id: 'choose-tile',
					title: "Maximum number of tiles revealed",
					submit: ()=> @ignoreMouseMoves = false
					)

				modal.addText('You cannot reveal more than n tiles', 'You_cannot_reveal_more_than_n_tiles', false, { count: R.city.nTilesMax })
				modal.show()
				@ignoreMouseMoves = true
				return

			tile ?= @getTileAt(event.point)

			modal = Modal.createModal( 
				id: 'choose-tile',
				title: "Choose tile", 
				submit: ( ()=> @chooseTile(tile.data.number, tile.data.x, tile.data.y, tile.data.rectangle) ),
				)

			modal.addText('Do you really want to reveal this tile?', 'Do you want to reveal this tile', false, { tileNumber: tile.data.number })

			divJ = modal.addText('You can still reveal n tiles.', 'You can still reveal n tiles', false, { count: nTilesLeft })
			divJ.text(divJ.text())
			
			modal.modalJ.on('hidden.bs.modal', ()=> @ignoreMouseMoves = false )

			modal.show()

			@ignoreMouseMoves = true

			return

		chooseTile: (number, x, y, bounds)=> 

			@ignoreMouseMoves = false
			
			R.loader.showLoadingBar(500)
			R.userProfile.nTiles++

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
			if not R.loader.checkError(result)
				R.userProfile.nTiles--
				return

			result.tile = JSON.parse(result.tile)
			@createTile(result.tile)
			
			return

	return ExquisiteCorpseMask
