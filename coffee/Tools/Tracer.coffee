define ['paper', 'R', 'Utils/Utils', 'UI/Button', 'UI/Modal', 'i18next' ], (P, R, Utils, Button, Modal, i18next) ->

	class Tracer

		constructor: ()->
			@tracerGroup = null
			@tracerBtn = null
			@createTracerButton()
			return

		createTracerButton: ()->

			@tracerBtn = new Button(
				name: 'Trace'
				iconURL: if R.style == 'line' then 'image.png' else if R.style == 'hand' then 'image.png' else 'glyphicon-picture'
				classes: 'dark'
				favorite: true
				category: null
				disableHover: true
				# description: 'Undo'
				popover: true
				order: null
			)

			@tracerBtn.hide()

			@tracerBtn.btnJ.click ()=> 
				@removeRaster()
				@modal = Modal.createModal( 
					id: 'import-image',
					title: "Import image to trace", 
					submit: @submitURL, 
					)




				dropZoneJ = $("""<div id="modal-dropZone" style="min-height: 200px; white-space: pre; border: 3px dashed gray; text-align: center; padding-top: 85px; margin-bottom: 15px;"
								ondragenter="document.getElementById('modal-dropZone').textContent = ''; event.stopPropagation(); event.preventDefault();"
								ondragover="event.stopPropagation(); event.preventDefault();">
								""" + i18next.t( 'Drop image here' ) + """
								</div>""")

				dropZoneJ.get(0).addEventListener('drop', @fileDropped, false)

				@modal.addCustomContent( { name: 'dropZone', divJ: dropZoneJ } )

				orText = @modal.addText('or')
				orText.css('text-align': 'center', 'margin': 10)

				inputJ = $('<input type="file" multiple accept="image/*">')
				@modal.addCustomContent( { name: 'tracerFileInput', divJ: inputJ } )
				inputJ.css(margin: 'auto')
				inputJ.get(0).addEventListener('change', @handleFiles, false)

				orText = @modal.addText('or')
				orText.css('text-align': 'center', 'margin': 10)

				@modal.addTextInput({name: 'imageURL', placeholder: 'http://exemple.fr/belle-image.png', type: 'url', submitShortcut: true, label: 'Import image from URL', required: true, errorMessage: i18next.t( 'The URL is invalid' ) })



				@modal.show()

				return
			
		removeRaster: ()=>
			if @moves?
				@moves.remove()
			if @corners?
				@corners.remove()
			@raster?.remove()
			@tracerGroup?.remove()
			return

		drawMoves: (bounds, size, sign, signRotations, signOffsets)=>
			
			if @moves?
				@moves.remove()
			@moves = new P.Group()
			@tracerGroup.addChild(@moves)

			for pos in ['topCenter', 'rightCenter', 'bottomCenter', 'leftCenter']
				handle = new P.Group()
				handle.name = 'handle-move-' + pos
				handleSize = size.clone()
				if pos == 'topCenter' or pos == 'bottomCenter'
					handleSize.width = bounds.width
				else
					handleSize.height = bounds.height

				handlePos = bounds[pos].subtract(handleSize.divide(2))
				handlePath = new P.Path.Rectangle(handlePos, handleSize)
				handlePath.fillColor = '#42b3f4'
				handlePath.strokeColor = 'white'
				handlePath.strokeWidth = 1
				handlePath.strokeScaling = false
				handle.addChild(handlePath)

				arrow = sign.clone()
				arrow.position = bounds[pos].add(signOffsets[pos])
				arrow.rotation = signRotations[pos]
				handle.addChild(arrow)

				@raster.data ?= {}
				@raster.data[pos] = handle
				handle.applyMatrix = false
				handle.on('mousedown', (event)=>
					@draggingImage = true
					return)
				handle.on('mousedrag', (event)=>
					if not @draggingImage then return
					if not @scalingImage
						@tracerGroup.position = @tracerGroup.position.add(event.delta)
						@draggingImage = true
					return)

				handle.on('mouseup', (event)=>
					@draggingImage = false
					return)
				handle.on('mouseenter', (event)=>
					if not R.selectedTool?.using
						R.stageJ.css('cursor', 'move')
					return)
				handle.on('mouseleave', (event)=>
					R.selectedTool?.updateCursor()
					return)
				@moves.addChild(handle)
			return
		
		drawCorners: (bounds, size, sign, signRotations, signOffsets)=>

			if @corners?
				@corners.remove()
			@corners = new P.Group()
			@tracerGroup.addChild(@corners)

			for pos in ['topLeft', 'topRight', 'bottomLeft', 'bottomRight']
				handle = new P.Group()
				handle.name = 'handle-corner-' + pos
				handlePos = bounds[pos].subtract(size.divide(2))
				handlePath = new P.Path.Rectangle(handlePos, size)
				handlePath.fillColor = '#42b3f4'
				handlePath.strokeColor = 'white'
				handlePath.strokeWidth = 1
				handlePath.strokeScaling = false
				handle.addChild(handlePath)

				box = handlePath.bounds.expand(-15 / P.view.zoom)

				@raster.data ?= {}
				@raster.data[pos] = handle
				if pos == 'topRight'
					
					cross1 = new P.Path()
					cross1.add(box.topLeft)
					cross1.add(box.bottomRight)
					cross1.strokeWidth = 2
					cross1.strokeScaling = false
					cross1.strokeColor = 'black'
					handle.addChild(cross1)
					cross2 = new P.Path()
					cross2.add(box.topRight)
					cross2.add(box.bottomLeft)
					cross2.strokeWidth = 2
					cross2.strokeScaling = false
					cross2.strokeColor = 'black'
					handle.addChild(cross2)
					handle.on('mousedown', ()=>
						@draggingImage = true
						@removeRaster()
						return)
					handle.on('mouseenter', (event)=>
						if not R.selectedTool?.using
							R.stageJ.css('cursor', 'default')
						return)
					handle.on('mouseleave', (event)=>
						R.selectedTool?.updateCursor()
						return)
				else

					arrow = sign.clone()
					arrow.position = bounds[pos]
					arrow.rotation = signRotations[pos]
					handle.addChild(arrow)
					
					

					handle.on('mousedown', (event)=>
						@draggingImage = true
						@scalingImage = true
						return)

					handle.on('mousedrag', (event)=>
						if not @draggingImage then return

						center = bounds.center

						previousLength = event.point.subtract(event.delta).getDistance(center)
						newLength = event.point.getDistance(center)

						bounds = @raster.bounds.expand(size)
						@drawMoves(bounds, size, sign, signRotations, signOffsets)

						@raster.scaling = @raster.scaling.multiply(newLength / previousLength)
						for pos, i in ['topLeft', 'topRight', 'bottomRight', 'bottomLeft']
							@raster.data[pos].position = bounds[pos]
						@corners.bringToFront()

						return)
					handle.on('mouseup', (event)=>
						@draggingImage = false
						@scalingImage = false
						return)
					handle.on('mouseenter', (event)=>
						if not R.selectedTool?.using
							vector = bounds.center.subtract(event.point)
							R.stageJ.css('cursor', if vector.x > 0 and vector.y < 0 then 'nesw-resize' else 'nwse-resize')
						return)
					handle.on('mouseleave', (event)=>
						R.selectedTool?.updateCursor()
						return)
				
				@corners.addChild(handle)
			return

		drawHandles: ()=>
			if not @tracerGroup? then return

			size = new paper.Size(30 / P.view.zoom, 30 / P.view.zoom)
			bounds = @raster.bounds.expand(size)

			sign = new P.Path()
			sign.add(12 / P.view.zoom, 0)
			sign.add(0, 0)
			sign.add(0, 12 / P.view.zoom)
			sign.strokeWidth = 2
			sign.strokeColor = 'black'
			sign.strokeScaling = false
			sign.pivot = new paper.Point(6 / P.view.zoom, 6 / P.view.zoom)
			sign.remove()

			signRotations = {
				'topCenter': 45,
				'rightCenter': 45+90,
				'bottomCenter': 45+90+90,
				'leftCenter': -45,
				'topRight': 90,
				'topLeft': 0,
				'bottomLeft': -90,
				'bottomRight': 180,
			}

			signOffsets = {
				'topCenter': new paper.Point(0, 4 / P.view.zoom),
				'rightCenter': new paper.Point(-4 / P.view.zoom, 0),
				'bottomCenter': new paper.Point(0, -4 / P.view.zoom),
				'leftCenter': new paper.Point(4 / P.view.zoom, 0),
			}
			@drawMoves(bounds, size, sign, signRotations, signOffsets)
			@drawCorners(bounds, size, sign, signRotations, signOffsets)
			return

		rasterOnLoad: (event)=>
			R.loader.hideLoadingBar()

			viewBounds = R.view.getViewBounds()

			@raster.position = viewBounds.center
			if @raster.bounds.width > viewBounds.width
				@raster.scaling = new paper.Point(viewBounds.width / (@raster.bounds.width + @raster.bounds.width * 0.25) )
			if @raster.bounds.height > viewBounds.height
				@raster.scaling = @raster.scaling.multiply( viewBounds.height / (@raster.bounds.height + @raster.bounds.height * 0.25) )

			@raster.applyMatrix = false

			@drawHandles()
			return

		rasterOnError: (event)=>
			R.loader.hideLoadingBar()
			@removeRaster()
			R.alertManager.alert 'Could not load the image', 'error'
			return

		submitURL: (data)=>
			
			@removeRaster()

			@tracerGroup = new P.Group()
			@tracerGroup.opacity = 0.5
			@raster = new P.Raster(data.imageURL)
			@tracerGroup.addChild(@raster)
			@raster.position = R.view.getViewBounds().center
			R.loader.showLoadingBar()

			# @raster.source = data.imageURL
			R.view.selectionLayer.addChild(@tracerGroup)

			@raster.onError = @rasterOnError

			@raster.onLoad = @rasterOnLoad


			return

		fileDropped: (event)=>
			event.stopPropagation()
			event.preventDefault()
			for file in event.dataTransfer.files
				if file.type.match(/image.*/)

					reader = new FileReader()
					@modal.hide()
					reader.onload = (readerEvent)=>
						@submitURL(imageURL: readerEvent.target.result)
						return
					reader.readAsDataURL(file)
			return

		handleFiles: (event)=>
			for file in event.target.files

				if file.type.match(/image.*/)

					reader = new FileReader()
					@modal.hide()
					reader.onload = (readerEvent)=>
						@submitURL(imageURL: readerEvent.target.result)
						return
					reader.readAsDataURL(file)
				return

			return

		showButton: ()->
			@tracerBtn?.show()
		
		hideButton: ()->
			@tracerBtn?.hide()

		hide: ()->
			@tracerGroup?.visible = false
		
		show: ()->
			@tracerGroup?.visible = true

		mouseUp: (event)->
			@draggingImage = false
			@scalingImage = false
			R.selectedTool?.updateCursor()
			return
		
		update: ()->
			@drawHandles()
			return

	return Tracer
