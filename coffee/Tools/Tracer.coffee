define ['paper', 'R', 'Utils/Utils', 'UI/Button', 'UI/Modal', 'Tools/Vectorizer', 'Tools/Camera', 'Tools/PathTool', 'Commands/Command', 'i18next', 'cropper' ], (P, R, Utils, Button, Modal, Vectorizer, PathTool, Camera, Command, i18next, Cropper) ->

	class Tracer
		
		@handleColor = '#42b3f4'
		@maxRasterSize = 3 * R.Tools.Path.maxDraftSize

		constructor: ()->
			@tracerGroup = null
			@tracerBtn = null
			@vectorizer = new Vectorizer()
			@createTracerButton()
			@initializeGlobalDragAndDrop()
			return
		
		onDragEnter: ()=>
			event.stopPropagation()
			event.preventDefault()
			return
		
		onDragOver: ()=>
			event.stopPropagation()
			event.preventDefault()
			return

		initializeGlobalDragAndDrop: ()->
			document.body.addEventListener('dragenter', (event)=>
				event.stopPropagation()
				event.preventDefault()
				event.dataTransfer.effectAllowed = "move";
				# $('#dropMessage').addClass('top')
				console.log('dragenter')
				R.alertManager.alert 'Drop your image here to trace it', 'info'
				return)
			document.body.addEventListener('dragover', (event)=>
				event.stopPropagation()
				event.preventDefault()
				# event.dataTransfer.dropEffect = 'move'
				return)
			document.body.addEventListener('dragleave', (event)=>
				event.stopPropagation()
				event.preventDefault()
				# $('#dropMessage').removeClass('top')
				console.log('dragleave')
				return)
			document.body.addEventListener('drop', @fileDropped, false)
			return

		createTracerButton: ()->

			@tracerBtn = new Button(
				name: 'Trace'
				# iconURL: if R.style == 'line' then 'image.png' else if R.style == 'hand' then 'image.png' else 'glyphicon-picture'
				iconURL: 'new 1/Image.svg'
				classes: 'dark'
				favorite: true
				category: null
				disableHover: true
				# description: 'Undo'
				popover: true
				order: null
			)

			@tracerBtn.hide()

			@tracerBtn.btnJ.click @openImageModal
			return
		
		onModalSubmit: ()=>	
			@imageURL = @filterCanvas.toDataURL()
			@createRasterController()
			return

		openImageModal: ()=>
			@removeRaster()
			@imageFile = null
			@imageURL = null
			@modal = Modal.createModal( 
				id: 'import-image',
				title: "Import image to trace", 
				submit: @onModalSubmit, 
				submitButtonText: 'Trace'
				)

			inputJ = $('<input type="file" multiple accept="image/*">')
			@modal.addCustomContent( { name: 'tracerFileInput', divJ: inputJ } )
			inputJ.css(margin: 'auto')
			inputJ.get(0).addEventListener('change', @handleFiles, false)
			inputJ.hide()
			

			@photoFromCameraButtonJ = @modal.addButton( addToBody: true, type: 'success', name: 'Take a photo with the camera', icon: 'glyphicon-facetime-video' ) # 'glyphicon-camera' )
			@photoFromCameraButtonJ.click(Camera.initialize)
			@imageFromComputerButtonJ = @modal.addButton( addToBody: true, type: 'info', name: 'Select an image on your computer', icon: 'glyphicon-folder-open' )
			@imageFromComputerButtonJ.click ()=> 
				inputJ.click()
				# @photoFromCameraButtonJ.hide()
				# @imageFromComputerButtonJ.hide()
				# @imageFromURLButtonJ.hide()
				# @dragDropTextJ.hide()
				# @modal.modalJ.find(".modal-footer").show()
				# @modal.hide()
				return
			@imageFromURLButtonJ = @modal.addButton( addToBody: true, type: 'warning', name: 'Import image from URL', icon: 'glyphicon-link' )

			@dragDropTextJ = @modal.addText('or drop and image on this page', 'or drop and image on this page')
			@dragDropTextJ.css( 'text-align': 'center' )

			for elemJ in [@photoFromCameraButtonJ, @imageFromComputerButtonJ, @imageFromURLButtonJ]
				elemJ.css( 'margin-bottom': '10px', 'font-size': 'large' ).find('.glyphicon').css( 'padding-right': '10px' )
				elemJ.addClass('btn-lg')
			
			# dropZoneJ = $("""<div id="modal-dropZone" style="min-height: 200px; white-space: pre; border: 3px dashed gray; text-align: center; padding-top: 85px; margin-bottom: 15px;"
			# 				ondragenter="document.getElementById('modal-dropZone').textContent = ''; event.stopPropagation(); event.preventDefault();"
			# 				ondragover="event.stopPropagation(); event.preventDefault();">
			# 				""" + i18next.t( 'Drop image here' ) + """
			# 				</div>""")

			# dropZoneJ.get(0).addEventListener('drop', @fileDropped, false)

			# @modal.addCustomContent( { name: 'dropZone', divJ: dropZoneJ } )

			# orText = @modal.addText('or')
			# orText.css('text-align': 'center', 'margin': 10)


			# orText = @modal.addText('or')
			# orText.css('text-align': 'center', 'margin': 10)

			@urlInputJ = @modal.addTextInput({name: 'imageURL', placeholder: 'http://exemple.fr/belle-image.png', type: 'url', submitShortcut: true, label: 'Import image from URL', required: true, errorMessage: i18next.t( 'The URL is invalid' ) })
			@urlInputJ.hide()

			@imageFromURLButtonJ.click ()=> 
				@urlInputJ.show()
				@photoFromCameraButtonJ.hide()
				@imageFromComputerButtonJ.hide()
				@imageFromURLButtonJ.hide()
				@dragDropTextJ.hide()
				@modal.modalJ.find(".modal-footer").show()
				return

			# TODO: Validate URL when URL field changes, then enable submit buttons if URL is valid
			# something like
			# @urlInputJ.change ()=>
			#	@enableSubmitButtons()
			# 	return

			# @adaptiveThresholdCJ = @modal.addCustomContent({ divJ: $('<div><label for="adaptive-threshold-c">Adaptive threshold C:</label> <input type="number" id="adaptive-threshold-c" step="1" value="10"></div>') })
			# @adaptiveThresholdWindowSizeJ = @modal.addCustomContent({ divJ: $('<div><label for="adaptive-threshold-window-size">Adaptive threshold window size:</label> <input type="number" id="adaptive-threshold-window-size" step="1" value="10"></div>') })
			
		
			@imageContainerJ = @modal.addCustomContent({ divJ: $('<div id="processed-image">') })
			# @svgContainerJ = @modal.addCustomContent({ divJ: $('<div id="vectorizer-svg">') })

			# @autoTraceButtonJ = @modal.addButton({ type: 'success', name: 'Trace automatically' })
			# @autoTraceButtonJ.click @submitTraceAutomatically

			@cropButtonJ = @modal.addButton({ type: 'success', name: 'Crop image' })
			@ignoreCropButtonJ = @modal.addButton({ type: 'info', name: 'Use full size image' })


			@cropButtonJ.click @cropImage
			@ignoreCropButtonJ.click @ignoreCropImage

			@cropButtonJ.hide()
			@ignoreCropButtonJ.hide()

			# @manualTraceButtonJ = @modal.modalJ.find('.modal-footer .btn-primary[name="submit"]')
			
			@modal.modalBodyJ.css( 'display': 'flex', 'flex-direction': 'column' )

			# @disableSubmitButtons()

			@modal.show()

			@modal.modalJ.find(".modal-footer").hide()
			
			return
		
		# disableSubmitButtons: ()->
		# 	# @autoTraceButtonJ.attr('disabled', 'true')
		# 	@manualTraceButtonJ.attr('disabled', 'true')
		# 	return

		# enableSubmitButtons: ()->
		# 	# @autoTraceButtonJ.removeAttr('disabled')
		# 	@manualTraceButtonJ.removeAttr('disabled')
		# 	return
			
		removeRaster: ()=>
			if @moves?
				@moves.remove()
			if @corners?
				@corners.remove()
			@raster?.remove()
			@tracerGroup?.remove()
			R.toolManager?.hideTracerButtons()
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
					handleSize.width = bounds.width - size.width
				else
					handleSize.height = bounds.height - size.height

				handlePos = bounds[pos].subtract(handleSize.divide(2))
				handlePath = new P.Path.Rectangle(handlePos, handleSize)
				handlePath.fillColor = @constructor.handleColor
				handlePath.strokeColor = 'white'
				handlePath.strokeWidth = 1
				handlePath.strokeScaling = false
				handlePath.opacity = 0.5
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
				handlePath.fillColor = @constructor.handleColor
				handlePath.strokeColor = 'white'
				handlePath.strokeWidth = 1
				handlePath.strokeScaling = false
				handlePath.opacity = 0.5
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
							R.stageJ.css('cursor', 'pointer')
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
						# @drawButtons(bounds, size)

						@raster.scaling = @raster.scaling.multiply(newLength / previousLength)
						for pos, i in ['topLeft', 'topRight', 'bottomRight', 'bottomLeft']
							@raster.data[pos].position = bounds[pos]
						@corners.bringToFront()
						
						if @rasterParts?
							@createRasterParts()

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

		# createButtonText: (button, text)=>

		# 	pointText = new P.PointText(button.bounds.center.add(0, 4))
		# 	pointText.justification = 'center'
		# 	pointText.fillColor = 'white'
		# 	pointText.fontSize = button.bounds.height + 'px'
		# 	pointText.content = i18next.t(text)
			
		# 	return pointText

		# createButton: (rectangle, color, text, callback)=>
		# 	group = new P.Group()
		# 	button = new P.Path.Rectangle(rectangle)
		# 	button.fillColor = color
		# 	group.addChild(button)
		# 	pointText = @createButtonText(button, text)
		# 	group.addChild(pointText)
		# 	@buttons.addChild(group)
			
		# 	group.on('mouseenter', (event)=>
		# 		if not R.selectedTool?.using
		# 			R.stageJ.css('cursor', 'pointer')
		# 		return)
		# 	group.on('mouseleave', (event)=>
		# 		R.selectedTool?.updateCursor()
		# 		return)
		# 	group.on('mousedown', (event)=>
		# 		@draggingImage = true # to disable pen / prevent drawing path
		# 		callback()
		# 		return)
		# 	return group

		# drawButtons: (bounds, size)=>

		# 	if @buttons?
		# 		@buttons.remove()
		# 	@buttons = new P.Group()
		# 	@tracerGroup.addChild(@buttons)
			
		# 	changeImageRectangle = new P.Rectangle(bounds.bottomLeft.add(-size.width/2, size.height/2), bounds.bottomCenter.add(0, 1.5 * size.height))
		# 	changeImageButtonGroup = @createButton(changeImageRectangle, 'orange', 'Change image', @openImageModal)

		# 	autoTraceRectangle = new P.Rectangle(bounds.bottomCenter.add(0, size.height/2), bounds.bottomRight.add(size.width / 2, 1.5 * size.height))
		# 	autoTraceButtonGroup = @createButton(autoTraceRectangle, 'green', 'Trace automatically', @autoTrace)

		# 	return

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
			# @drawButtons(bounds, size)
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
			R.toolManager?.showTracerButtons()
			return

		rasterOnError: (event)=>
			R.loader.hideLoadingBar()
			@removeRaster()
			R.toolManager?.hideTracerButtons()
			R.alertManager.alert 'Could not load the image', 'error'
			return

		setFullscreen: ()->
			@modal.modalJ.find('.modal-dialog').css(
				position: 'absolute'
				top: '60px'
				bottom: 0
				width: '100%'
			)
			@modal.modalJ.find('.modal-content').css(
				display: 'flex'
				'flex-direction': 'column'
				height: '100%'
			)
			@modal.modalJ.find('.modal-body').css(
				display: 'flex'
				'flex-grow': 1
			)
			return
		
		addRasterCropControls: ()=>
			@rotateImageButtonJ = @modal.addButton( addToBody: true, type: 'info', name: 'Rotate', icon: 'glyphicon-repeat' )
			@flipVImageButtonJ = @modal.addButton( addToBody: true, type: 'info', name: 'Flip Vertical', icon: 'glyphicon-resize-vertical' )
			@flipHImageButtonJ = @modal.addButton( addToBody: true, type: 'info', name: 'Flip Horizontal', icon: 'glyphicon-resize-horizontal' )
			@rotateImageButtonJ.click ()=> @cropper?.rotate(90)
			@flipVImageButtonJ.click ()=> @cropper?.scale(1, -1 * @cropper.getData().scaleY )
			@flipHImageButtonJ.click ()=> @cropper?.scale(-1 * @cropper.getData().scaleX, 1)
			return
		
		setEditImageMode: ()=>
			@modal.modalJ.find('.modal-footer button[name="submit"]').hide()

			@setFullscreen()
			@addRasterCropControls()

			@photoFromCameraButtonJ.hide()
			@imageFromComputerButtonJ.hide()
			@imageFromURLButtonJ.hide()
			@dragDropTextJ.hide()
			@modal.modalJ.find(".modal-footer").show()
			
			image = new Image()
			image.src = @imageURL
			@imageContainerJ.append(image)
			@imageContainerJ.css('max-width': '500px', 'margin': 'auto' )
			
			image.onload = ()=>
				$(image).css( 'max-width': '100%', display: 'block', margin: 'auto' )
				@cropper = new Cropper(image)
				@cropButtonJ.show()
				@ignoreCropButtonJ.show()
			return
		
		cropImage: ()=>
			cropOptions = 
				minWidth: 256
				minHeight: 256
				maxWidth: 1000
				maxHeight: 1000
				fillColor: '#fff'
				imageSmoothingEnabled: true
				imageSmoothingQuality: 'high'
			
			@filterCanvas = @cropper.getCroppedCanvas(cropOptions)
			@cropper.destroy()
			@imageContainerJ.empty()
			@imageContainerJ.append(@filterCanvas)
			$(@filterCanvas).css( 'max-width': '500px' )
			@cropButtonJ.hide()
			@ignoreCropButtonJ.hide()
			
			@rotateImageButtonJ.hide()
			@flipVImageButtonJ.hide()
			@flipHImageButtonJ.hide()

			@modal.modalJ.find('.modal-footer button[name="submit"]').show()

			@filterImage()
			return

		ignoreCropImage: ()=>
			@cropButtonJ.hide()
			@ignoreCropButtonJ.hide()
			@filterImage()
			return

		adaptiveThreshold: ()->
			# adaptive threshold

			# size of the block
			n = 15 
			C = 12
			# C = parseFloat(@adaptiveThresholdButtonJ.find('input').val())
			# if Number.isNaN(C)
			# 	C = parseFloat(@adaptiveThresholdButtonJ.find('input').attr('value'))
			# C *= 255

			width = @filterCanvas.width
			height = @filterCanvas.height

			no2 = Math.floor(n / 2)
			blockSize = 2 * no2 + 1
			nPixelsInBlock = blockSize * blockSize
			finalImageData = new ImageData(width, height)
			context = @filterCanvas.getContext('2d')
			sourceImageData = context.getImageData(0, 0, width, height)
			sourceData = sourceImageData.data
		  
			for y in [0 .. height-1]
				for x in [0 .. width-1]

					average = 0

					for yi in [-no2 .. no2]
						for xi in [-no2 .. no2]
					
							xf = if x + xi < 0 then x - xi else if x + xi >= width then x - xi else x + xi
							yf = if y + yi < 0 then y - yi else if y + yi >= height then y - yi else y + yi
							index = xf + yf * width
							average += sourceData[4 * index + 0]
							
					average /= nPixelsInBlock
					index = x + y * width
					color = if average - C < sourceData[4 * index + 0] then 255 else 0
					for n in [0 .. 2]
						finalImageData.data[4 * index + n] = color
					finalImageData.data[4 * index + 3] = 255
			
			context.putImageData(finalImageData, 0, 0)
			return


		grayscale: (context)->

			brightnessThreshold = parseFloat(@brightnessThresholdButtonJ.find('input').val())
			saturationThreshold = parseFloat(@saturationThresholdButtonJ.find('input').val())

			if Number.isNaN(brightnessThreshold)
				brightnessThreshold = parseFloat(@brightnessThresholdButtonJ.find('input').attr('value'))
			if Number.isNaN(saturationThreshold)
				saturationThreshold = parseFloat(@saturationThresholdButtonJ.find('input').attr('value'))
			
			width = @filterCanvas.width
			height = @filterCanvas.height

			context = @filterCanvas.getContext('2d')
			sourceImageData = context.getImageData(0, 0, width, height)
			sourceData = sourceImageData.data
			for y in [0 .. height-1]
				for x in [0 .. width-1]

					index = x + y * width
					red = sourceData[4 * index + 0]
					green = sourceData[4 * index + 1]
					blue = sourceData[4 * index + 2]
					color = new P.Color(red / 255, green / 255, blue / 255)
					
					# finalColor = color.brightness > brightnessThreshold or color.saturation > 1 - saturationThreshold ? 0 : 1
					
					finalColor = Math.min(color.brightness, 1 - color.saturation)

					for n in [0 .. 2]
						sourceData[4 * index + n] = finalColor * 255
					sourceData[4 * index + 3] = sourceData[4 * index + 3]
			
			context.putImageData(sourceImageData, 0, 0)
			return
		
		processImage: ()=>
			context = @filterCanvas.getContext('2d')
			if not @initialImage?
				@initialImage = context.getImageData(0, 0, @filterCanvas.width, @filterCanvas.height)
			else
				context.putImageData(@initialImage, 0, 0)
			console.log('start grayscale')
			@grayscale()
			@adaptiveThreshold()
			console.log('grayscale finished')
			return
		
		addRasterFilterControls: ()=>


			@brightnessThresholdButtonJ = @modal.addTextInput( type: 'number', name: 'Brightness threshold', label: 'Brigthness threshold', defaultValue: 0.3 )
			@saturationThresholdButtonJ = @modal.addTextInput( type: 'number', name: 'Saturation threshold', label: 'Saturation threshold', defaultValue: 0.3 )
			@adaptiveThresholdButtonJ = @modal.addTextInput( type: 'number', name: 'Adaptive threshold', label: 'Adaptive threshold', defaultValue: 0.05 )
			
			@brightnessThresholdButtonJ.find('input').attr('min', '-1').attr('max', '1').attr('value', '0.3').attr('step', 0.01).on('change', ()=> Utils.deferredExecution(@processImage, 'brightnessThreshold', 500) )
			@saturationThresholdButtonJ.find('input').attr('min', '-1').attr('max', '1').attr('value', '0.3').attr('step', 0.01).on('change', ()=> Utils.deferredExecution(@processImage, 'saturationThreshold', 500) )
			@adaptiveThresholdButtonJ.find('input').attr('min', '-1').attr('max', '1').attr('value', '0.05').attr('step', 0.01).on('change', ()=> Utils.deferredExecution(@processImage, 'adaptiveThreshold', 500) )
			
			@filterControlsContainerJ = $('<div>')
			@filterControlsContainerJ.append(@brightnessThresholdButtonJ)
			@filterControlsContainerJ.append(@saturationThresholdButtonJ)
			@filterControlsContainerJ.append(@adaptiveThresholdButtonJ)
			@modal.modalBodyJ.find('#processed-image').css( 'display': 'flex', 'flex-direction': 'row' ).append(@filterControlsContainerJ)

			return

		filterImage: ()=>
			# @addRasterFilterControls()
			@processImage()
			@onModalSubmit()
			# @filterButtonJ.show()
			return

		createRasterController: ()=>
			@modal.hide()
			if not @imageURL? then return

			@imageFile = null

			@removeRaster()

			@tracerGroup = new P.Group()
			# @tracerGroup.opacity = 0.5
			@raster = new P.Raster(@imageURL)
			@raster.opacity = 0.5
			@tracerGroup.addChild(@raster)
			@raster.position = R.view.getViewBounds().center
			R.loader.showLoadingBar()

			# @raster.source = data.imageURL
			R.view.selectionLayer.addChild(@tracerGroup)

			@raster.onError = @rasterOnError

			@raster.onLoad = @rasterOnLoad

			return

		appendSVG: (svgstr)=>
			svgContainer = @svgContainerJ.get(0)
			svgContainer.style.display = 'inline-block'
			svgContainer.innerHTML = svgstr
			return
		
		createRasterParts: ()->
			maxDraftSize = R.Tools.Path.maxDraftSize
			nRectanglesWidth = Math.floor(@raster.bounds.width / maxDraftSize) + 1
			nRectanglesHeight = Math.floor(@raster.bounds.height / maxDraftSize) + 1

			totalRectangle = new P.Rectangle(@raster.bounds.left, @raster.bounds.top, nRectanglesWidth * maxDraftSize, nRectanglesHeight * maxDraftSize)
			totalRectangle.center = @raster.bounds.center

			@rasterParts?.remove()
			@rasterParts = new P.Group()

			for nx in [0 .. nRectanglesWidth-1]
				for ny in [0 .. nRectanglesHeight-1]
					rectangle = new P.Rectangle(totalRectangle.left + nx * maxDraftSize, totalRectangle.top + ny * maxDraftSize, maxDraftSize, maxDraftSize)
					rectangle = @raster.bounds.intersect(rectangle)
					rectanglePath = P.Path.Rectangle(rectangle)
					rectanglePath.fillColor = @constructor.handleColor
					rectanglePath.strokeColor = 'white'
					rectanglePath.opacity = 0.8
					rectanglePath.on('mouseenter', (event)=>
						event.target.opacity = 0.05
						R.stageJ.css('cursor', 'pointer')
						return
					)
					rectanglePath.on('mouseleave', (event)=>
						R.selectedTool?.updateCursor()
						event.target.opacity = 0.8
						return
					)
					rectanglePath.on('mousedown', (event)=>
						@draggingImage = true
						return
					)
					rectanglePath.on('click', (event)=>
						@autoTraceSized(event.target.bounds)
						@rasterParts.remove()
						@draggingImage = false
						return
					)
					@rasterParts.addChild(rectanglePath)

			@tracerGroup.addChild(@rasterParts)

			return
		
		autoTrace: ()=>

			# C = parseInt(@adaptiveThresholdCJ.find('input').val())
			# windowSize = parseInt(@adaptiveThresholdWindowSizeJ.find('input').val())

			# @modal.modalJ.find('.modal-dialog').width(window.innerWidth)
			# @vectorizer.vectorize(@imageFile, @imageURL, C, windowSize)

			if @raster.bounds.width > R.Tools.Path.maxDraftSize or @raster.bounds.height > R.Tools.Path.maxDraftSize
				R.alertManager.alert 'The image is too big to fit in one drawing', 'info'
				@createRasterParts()
				return
			
			@autoTraceSized()
			return

		autoTraceSized: (bounds=null)=>
			
			png = @imageURL
			@rasterPartRectangle = if bounds? then bounds else @raster.bounds
			@subRasterRectangle = new P.Rectangle(0, 0, @raster.width, @raster.height)

			if bounds?
				# if @raster.bounds.width > @constructor.maxRasterSize or @raster.bounds.height > @constructor.maxRasterSize
				# 	R.alertManager.alert 'The image is too big', 'info'
				# 	return
				
				@subRasterRectangle = new P.Rectangle(bounds.topLeft.subtract(@raster.bounds.topLeft).divide(@raster.scaling), 
														bounds.bottomRight.subtract(@raster.bounds.topLeft).divide(@raster.scaling))
				
				rasterPart = @raster.getSubRaster(@subRasterRectangle)
				png = rasterPart.toDataURL()
				rasterPart.remove()

			args = {
				png: png
			}
			
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'autoTrace', args: args } ).done(@autoTraceCallback)
			
			return
		
		autoTraceCallback: (result)=>
			@modal.hide()
			@addSvgToDraft(result.svg)
			return
		
		addPathsToDraft: (item, draft)->
			for child in item.children.slice()
				if child instanceof P.Path
					child.strokeWidth = R.Path.strokeWidth
					child.strokeColor = 'black'
					child.strokeCap = 'round'
					child.strokeJoin = 'round'
					draft.addChild(child, false)
				else if child.children?
					@addPathsToDraft(child, draft)
			return

		addSvgToDraft: (svg)->
			svgPaper = P.project.importSVG(svg)
			
			svgPaper.translate(@rasterPartRectangle.topLeft)
			svgPaper.scale(@rasterPartRectangle.width / @subRasterRectangle.width, @rasterPartRectangle.topLeft)
			# svgPaper.fitBounds(@rasterPartRectangle)

			draft = R.Item.Drawing.getDraft()
			R.commandManager.add(new Command.ModifyDrawing(draft))

			@addPathsToDraft(svgPaper, draft)
			
			draft.updatePaths()

			svgPaper.remove()

			return

		fileDropped: (event)=>
			event.stopPropagation()
			event.preventDefault()
			if R.selectedTool != R.tools['Precise path']
				R.tools['Precise path'].select()
			if R.selectedTool != R.tools['Precise path'] 	# Check that the path tool is indeed selected: 
															#  - the city is not finished and the user is connecter
															# 	otherwise the trace image will interfere with the move tool
				return
			for file in event.dataTransfer.files
				if file.type.match(/image.*/)

					@imageFile = file

					reader = new FileReader()
					# @modal?.hide()
					reader.onload = (readerEvent)=>
						@imageURL = readerEvent.target.result
						@urlInputJ.val(@imageURL)
						# @enableSubmitButtons()
						@setEditImageMode()
						# @submitURL(imageURL: readerEvent.target.result)
						return
					reader.readAsDataURL(file)
					return
			return

		handleFiles: (event)=>
			for file in event.target.files

				if file.type.match(/image.*/)

					@imageFile = file

					reader = new FileReader()
					# @modal.hide()
					reader.onload = (readerEvent)=>
						@imageURL = readerEvent.target.result
						@urlInputJ.val(@imageURL)
						# @enableSubmitButtons()
						# @image = new Image()
						# @image.src = @imageURL
						# @imageContainerJ.append(@image)
						# $(@image).css( 'max-width': '500px', display: 'block', margin: 'auto' )
						# @submitURL(imageURL: readerEvent.target.result)
						@setEditImageMode()
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
			R.toolManager?.hideTracerButtons()
			return
		
		show: ()->
			@tracerGroup?.visible = true
			if @tracerGroup?
				R.toolManager?.showTracerButtons()
			return

		mouseUp: (event)->
			@draggingImage = false
			@scalingImage = false
			R.selectedTool?.updateCursor()
			return
		
		update: ()->
			@drawHandles()
			return

	return Tracer
