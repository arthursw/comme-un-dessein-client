define ['paper', 'R', 'Utils/Utils', 'UI/Button', 'UI/Modal', 'Tools/Vectorizer', 'Tools/ImageProcessor', 'Tools/Camera', 'Tools/PathTool', 'Commands/Command', 'i18next', 'cropper' ], (P, R, Utils, Button, Modal, Vectorizer, ImageProcessor, Camera, PathTool, Command, i18next, Cropper) ->

	class Tracer
		
		@handleColor = '#42b3f4'
		@maxRasterSize = 1500
		@defaultSize = ()=> 210 * R.city.pixelPerMm

		constructor: ()->
			@tracerGroup = null
			@tracerBtn = null
			@vectorizer = new Vectorizer()
			@createTracerButton()
			@initializeGlobalDragAndDrop()
			@imageProcessor = new ImageProcessor()
			@traceAutomatically = false
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
				if not @dropImageAlertTimeout?
					R.alertManager.alert 'Drop your image here to trace it', 'info'
					@dropImageAlertTimeout = setTimeout (()->@dropImageAlertTimeout = null), 1000
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

			@tracerBtn.btnJ.click @restoreImageOrOpenModal
			return
		
		restoreImageOrOpenModal: ()=>
			# if @tracerGroup?.visible
			# 	@openTraceTypeModal(false, true)
			# 	return

			@imageURL = localStorage.getItem('rater-url')
			@openTraceTypeModal(true)
			# closedRaster = localStorage.getItem('closed-raster') == 'true'
			# if !closedRaster and @imageURL? and @imageURL != ''
			# 	rasterBoundsJSON = localStorage.getItem('rater-bounds')
			# 	if rasterBoundsJSON?
			# 		rasterBounds = JSON.parse(rasterBoundsJSON)
			# 		@createRasterController(new P.Rectangle(rasterBounds))
			# 	else
			# 		@openTraceTypeModal(closedRaster)
			# else
			# 	@openTraceTypeModal(closedRaster)
			return
		
		# onTraceTypeModalSubmit: ()=>
		# 	return

		hideDraftButtons: ()=>
			@removeDraftTextJ.hide()
			@svgJ.hide()
			# @validateDraftButtonJ.hide()
			@keepDraftButtonJ.hide()
			@removeDraftButtonJ.hide()
			return

		openTraceTypeModal: (closedRaster, keepRaster=false, imageDropped=false)=>
			
			@modal = Modal.createModal( 
				id: 'trace-type',
				title: "Trace"
				# submit: @onTraceTypeModalSubmit, 
				# submitButtonText: 'Trace'
				)

			autoTraceLabel = i18next.t('Trace automatically')
			
			# autoTraceInputJ = $('''
			# <button class="trace-type-btn cd-row cd-center btn-success">

			autoTraceInputJ = $('''
			<button class="trace-type-btn cd-row cd-center btn-primary">
				<label>'''+autoTraceLabel+'''</label>
				<video autoplay loop width="200">

					<source src="/static/videos/AutoTrace.webm"
							type="video/webm">

					<source src="/static/videos/AutoTrace.mp4"
							type="video/mp4">
				</video>
			</button>
			''')
			@modal.addCustomContent( { name: 'autotrace-choice', divJ: autoTraceInputJ } )

			autoTraceInputJ.click ()=>
				# @modal.hide()
				@traceAutomatically = true
				if imageDropped
					@onModalSubmit()
				else
					autoTraceInputJ.hide()
					manualTraceInputJ.hide()
					@openImageModal(closedRaster, keepRaster)
				return
			
			manualTraceLabel = i18next.t('Trace manually')

			manualTraceInputJ = $('''
			<button class="trace-type-btn cd-row cd-center btn-primary">
				<label>'''+manualTraceLabel+'''</label>
				<video autoplay loop width="200">

					<source src="/static/videos/ManualTrace.webm"
							type="video/webm">

					<source src="/static/videos/ManualTrace.mp4"
							type="video/mp4">
				</video>
			</button>
			''')
			@modal.addCustomContent( { name: 'manual-choice', divJ: manualTraceInputJ } )
			manualTraceInputJ.click ()=>
				@traceAutomatically = false
				# @modal.hide()
				if imageDropped
					@onModalSubmit()
				else
					autoTraceInputJ.hide()
					manualTraceInputJ.hide()
					@openImageModal(closedRaster, keepRaster)
				return

			if R.Drawing.draft?.paths?.length > 0
				autoTraceInputJ.hide()
				manualTraceInputJ.hide()
				@removeDraftTextJ = @modal.addText('Do you want to keep current drawing?')
				divJ = $('<div>')
				divJ.css('display': 'flex', 'flex-direction': 'row', 'margin': '10px', 'align-items': 'center', 'justify-content': 'center')
				svg = R.view.getThumbnail(R.Drawing.draft)
				svg.setAttribute('viewBox', '0 0 300 300')
				svg.setAttribute('width', '250')
				svg.setAttribute('height', '250')
				divJ.append(svg)
				@svgJ = @modal.addCustomContent( name: 'svg', divJ: divJ)
				# @validateDraftButtonJ = @modal.addButton( addToBody: true, type: 'success', name: 'Yes, validate drawing', submit: (()=> 
				# 	R.toolManager.submitButton.click()) )
				@removeDraftButtonJ = @modal.addButton( addToBody: true, type: 'danger', name: 'No', preventDefaultSubmit: true, submit: (()=>
					@hideDraftButtons()
					autoTraceInputJ.show()
					manualTraceInputJ.show()
					R.toolManager.deleteButton.click()) )
				@keepDraftButtonJ = @modal.addButton( addToBody: true, type: 'primary', name: 'Yes', preventDefaultSubmit: true, submit: (()=>
					@hideDraftButtons()
					autoTraceInputJ.show()
					manualTraceInputJ.show()) )
				for elemJ in [@removeDraftButtonJ, @keepDraftButtonJ]
					if not elemJ? then continue
					elemJ.css( 'margin-bottom': '10px', 'font-size': 'large' ).find('.glyphicon').css( 'padding-right': '10px' )
					elemJ.addClass('btn-lg')
			@modal.modalBodyJ.css( 'display': 'flex', 'flex-direction': 'column' )
			@modal.modalJ.find(".modal-footer").hide()

			@modal.show()
			
			return
		
		onModalSubmit: ()=>	
			# if @filterCanvas?
			# 	@imageURL ?= @filterCanvas.toDataURL()
			@createRasterController()
			return

		openImageModal: (closedRaster, keepRaster=false)=>
			if not keepRaster
				@removeRaster()
			@imageFile = null
			@imageURL = null
			# @modal = Modal.createModal( 
			# 	id: 'import-image',
			# 	title: "Import image to trace", 
			# 	submit: @onModalSubmit, 
			# 	submitButtonText: 'Trace'
			# 	)

			inputJ = $('<input type="file" multiple accept="image/*">')
			@modal.addCustomContent( { name: 'tracerFileInput', divJ: inputJ } )
			inputJ.css(margin: 'auto')
			inputJ.get(0).addEventListener('change', @handleFiles, false)
			inputJ.hide()
			
			deviceType = Utils.getDeviceType()
			@photoFromCameraButtonJ = @modal.addButton( addToBody: true, type: 'primary', name: 'Take a photo with the camera', icon: 'glyphicon-facetime-video' ) # 'glyphicon-camera' )
			@photoFromCameraButtonJ.click Camera.initialize
			@imageFromComputerButtonJ = @modal.addButton( addToBody: true, type: 'primary', name: 'Choose an image on your ' + deviceType, icon: 'glyphicon-folder-open' )
			@imageFromComputerButtonJ.click ()=> 
				inputJ.click()
				# @photoFromCameraButtonJ.hide()
				# @imageFromComputerButtonJ.hide()
				# @imageFromURLButtonJ.hide()
				# @dragDropTextJ.hide()
				# @modal.modalJ.find(".modal-footer").show()
				# @modal.hide()
				return
			
			# if not @traceAutomatically
			# 	@imageFromURLButtonJ = @modal.addButton( addToBody: true, type: 'info', name: 'Import image from URL', icon: 'glyphicon-link' )
			
			if closedRaster
				@reloadPreviousImageButtonJ = @modal.addButton( addToBody: true, type: 'primary', name: 'Reload previous image', icon: 'glyphicon-picture' )
				@reloadPreviousImageButtonJ.click ()=>
					# localStorage.setItem('closed-raster', 'false')
					# @restoreImageOrOpenModal()
					rasterBoundsJSON = localStorage.getItem('rater-bounds')
					@imageURL = localStorage.getItem('rater-url')
					if rasterBoundsJSON?
						rasterBounds = JSON.parse(rasterBoundsJSON)
						@createRasterController(new P.Rectangle(rasterBounds))
					return

			@dragDropTextJ = @modal.addText('or drop an image on this page', 'or drop an image on this page')
			@dragDropTextJ.css( 'text-align': 'center' )

			for elemJ in [@photoFromCameraButtonJ, @imageFromComputerButtonJ, @imageFromURLButtonJ, @reloadPreviousImageButtonJ]
				if not elemJ? then continue
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

			@imageFromURLButtonJ?.click ()=> 
				@urlInputJ.show()
				@photoFromCameraButtonJ.hide()
				@imageFromComputerButtonJ.hide()
				@imageFromURLButtonJ.hide()
				@reloadPreviousImageButtonJ?.hide()
				@dragDropTextJ.hide()
				@modal.modalJ.find(".modal-footer").show()
				return

			# TODO: Validate URL when URL field changes, then enable submit buttons if URL is valid
			# something like
			# @urlInputJ.change ()=>
			#	@enableSubmitButtons()
			# 	return

			@urlInputJ.find('input').change(@updateImageURLfromInputDeferred).bind("paste",  @updateImageURLfromInputDeferred).keyup(@updateImageURLfromInputDeferred)

			# @adaptiveThresholdCJ = @modal.addCustomContent({ divJ: $('<div><label for="adaptive-threshold-c">Adaptive threshold C:</label> <input type="number" id="adaptive-threshold-c" step="1" value="10"></div>') })
			# @adaptiveThresholdWindowSizeJ = @modal.addCustomContent({ divJ: $('<div><label for="adaptive-threshold-window-size">Adaptive threshold window size:</label> <input type="number" id="adaptive-threshold-window-size" step="1" value="10"></div>') })
			
			@imageContainerJ = @modal.addCustomContent({ divJ: $('<div id="processed-image">') })
			marginContainerJ = $('<div class="margin-container">')
			marginContainerJ.css(
				'max-width': '100%'
				'max-height': '100%'
				'display': 'flex'
				'flex': 'auto'
				'min-height': '0px'
			)
			@imageContainerJ.append(marginContainerJ)

			# @svgContainerJ = @modal.addCustomContent({ divJ: $('<div id="vectorizer-svg">') })

			# @autoTraceButtonJ = @modal.addButton({ type: 'success', name: 'Trace automatically' })
			# @autoTraceButtonJ.click @submitTraceAutomatically

			@ignoreCropButtonJ = @modal.addButton({ type: 'info', name: 'Use full size image' })
			@cropButtonJ = @modal.addButton({ type: 'success', name: 'Crop image' })

			@cropButtonJ.click @cropImage
			@ignoreCropButtonJ.click @ignoreCropImage

			@cropButtonJ.hide()
			@ignoreCropButtonJ.hide()

			# @manualTraceButtonJ = @modal.modalJ.find('.modal-footer .btn-primary[name="submit"]')
			
			

			# @disableSubmitButtons()

			# @modal.show()

			# @modal.modalJ.find(".modal-footer").hide()
			
			return

		updateImageURLfromInput: ()=>
			@imageURL = @urlInputJ.find('input').val()
			console.log(@imageURL)
			@createImagePreview()
			return
		
		updateImageURLfromInputDeferred: ()=>
			Utils.deferredExecution(@updateImageURLfromInput, 'updateImageURLfromInput', 200)
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
		
		saveBoundsToLocalStorage: ()->
			localStorage.setItem('rater-bounds', JSON.stringify(@raster.bounds.toJSON()))
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
						@saveBoundsToLocalStorage()
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
		
		closeRaster: ()->
			@removeRaster()
			localStorage.setItem('closed-raster', 'true')
			@draggingImage = false
			@traceAutomatically = false
			@tracingAutomatically = false
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
						@closeRaster()
						@draggingImage = true
						return)
					handle.on('mouseup', ()=>
						@draggingImage = false
						return
					)
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
						# @rasterCropCenter = center
						@drawMoves(bounds, size, sign, signRotations, signOffsets)
						# @drawButtons(bounds, size)

						@raster.scaling = @raster.scaling.multiply(newLength / previousLength)
						for pos, i in ['topLeft', 'topRight', 'bottomRight', 'bottomLeft']
							@raster.data[pos].position = bounds[pos]
						@corners.bringToFront()
						
						# if @rasterParts?
						# 	@createRasterParts()
						@createRasterCrop(true)
						# @updateValidationButtons()
						@saveBoundsToLocalStorage()
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
			
			@createRasterCrop(true)
			# @updateValidationButtons()
			@saveBoundsToLocalStorage()
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
		
		# setImagePosition: ()=>
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
		
		# updateValidationButtons: ()=>
		# 	if @raster.bounds.width > R.Tools.Path.maxDraftSize or @raster.bounds.height > R.Tools.Path.maxDraftSize
		# 		R.toolManager?.autoTraceButton.hide()
		# 		R.toolManager?.setImagePositionButton.show()
		# 	else
		# 		R.toolManager?.autoTraceButton.show()
		# 		R.toolManager?.setImagePositionButton.hide()
		# 	return

		rasterOnLoad: (bounds=null)->

			R.loader.hideLoadingBar()

			if bounds?
				@raster.fitBounds(bounds)
			else
				viewBounds = R.view.grid.limitCDRectangle.intersect(R.view.getViewBounds())
				# viewBounds = R.view.getViewBounds()

				@raster.position = viewBounds.center

				@raster.scaling = @raster.scaling.multiply(@constructor.defaultSize() / Math.min(@raster.bounds.width, @raster.bounds.height))

				# if @raster.bounds.width > viewBounds.width
				# 	@raster.scaling = new paper.Point(viewBounds.width / (@raster.bounds.width + @raster.bounds.width * 0.25) )
				# if @raster.bounds.height > viewBounds.height
				# 	@raster.scaling = @raster.scaling.multiply( viewBounds.height / (@raster.bounds.height + @raster.bounds.height * 0.25) )

			@raster.applyMatrix = false

			localStorage.setItem('rater-url', @raster.source)
			@saveBoundsToLocalStorage()
			@rasterCropCenter = @raster.bounds.center
			@drawHandles()
			if @traceAutomatically
				# @updateValidationButtons()
				R.toolManager?.showTracerButtons()
			
			if not @unzoomToFitRaster()
				@unzoomToFitRaster(false)
				
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
				overflow: 'auto'
			)
			@modal.modalJ.find('.modal-body').css(
				display: 'flex'
				height: '100%'
				flex: '1 1 auto'
				'overflow-y': 'auto'
				'min-height': '0px'
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
		
		createImagePreview: ()=>

			@image = new Image()
			@image.src = @imageURL
			
			@imageContainerJ.css(
				'margin': 'auto'
				'max-height': '100%'
				'max-width': '100%'
				'flex': '1 1 auto'
				'overflow-y': 'auto'
				'min-height': '0px'
				'padding': '20px'
			)
			@imageContainerJ.find('.margin-container').append(@image)
			
			return
		
		setEditImageMode: ()=>
			@modal.modalJ.find('.modal-footer button[name="submit"]').hide()

			@setFullscreen()
			@addRasterCropControls()

			@photoFromCameraButtonJ.hide()
			@imageFromComputerButtonJ.hide()
			@imageFromURLButtonJ?.hide()
			@reloadPreviousImageButtonJ?.hide()
			@dragDropTextJ.hide()
			@modal.modalJ.find(".modal-footer").show()

			# @onModalSubmit()

			@createImagePreview()

			@imageURL = null
			@image.onload = ()=>
				$(@image).css( 
					display: 'block', 
					'max-width': '100%', 
					'max-height': '100%', 
					display: 'flex'
					'object-fit': 'contain'
				)
				@cropper = new Cropper(@image)
				@cropButtonJ.show()
				@ignoreCropButtonJ.show()
			return
		
		# not used anymore
		cropImage: (cropData=null)=>
			if cropData
				@cropper.setData(cropData)
			
			cropOptions = 
				minWidth: 200
				minHeight: 200
				# maxWidth: 1500
				# maxHeight: 1500
				maxWidth: 750
				maxHeight: 750
				fillColor: '#fff'
				imageSmoothingEnabled: true
				imageSmoothingQuality: 'high'
			
			@filterCanvas = @cropper.getCroppedCanvas(cropOptions)

			@filterImage()
			return

		# not used anymore
		ignoreCropImage: ()=>
			# canvas = document.createElement('canvas')
			# ratio = @image.naturalWidth / @image.naturalHeight
			# if ratio > 0.5
			# 	if @image.naturalWidth > 750
			# 		canvas.width = 750
			# 		canvas.height = canvas.width / ratio
			# else
			# 	if @image.naturalHeight > 750
			# 		canvas.height = 750
			# 		canvas.width = canvas.width * ratio
			# context = canvas.getContext('2d')
			# context.drawImage(@image, 0, 0, @image.naturalWidth, @image.naturalHeight, 0, 0, canvas.width, canvas.height)
			# @filterCanvas = canvas
			# imageData = @cropper.getImageData()
			imageData = @cropper.getCanvasData()
			@cropper.setCropBoxData( { left: imageData.left, top: imageData.top, width: imageData.width, height: imageData.height } )
			@cropImage()
			@filterImage()
			return
		
		# not used anymore
		filterImage: ()=>

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

			@imageProcessor.processImage(@filterCanvas)
			
			@onModalSubmit()
			return

		unzoomToFitRaster: (snap=true)->
			previousZoom = null

			while not P.view.bounds.contains(@raster.bounds.expand(100)) and previousZoom != P.view.zoom
				previousZoom = P.view.zoom
				R.toolManager.zoom(-1, snap)
			
			return P.view.bounds.contains(@raster.bounds.expand(100))
		
		createRasterController: (bounds=null)=>
			@modal?.hide()
			if not @imageURL? then return
			
			if @traceAutomatically
				@tracingAutomatically = true
			
			@imageFile = null

			@removeRaster()

			@tracerGroup = new P.Group()
			# @tracerGroup.opacity = 0.5
			@raster = new P.Raster(@imageURL)
			@raster.opacity = 0.5
			@tracerGroup.addChild(@raster)
			if bounds?
				@raster.position = bounds.center
			else
				@raster.position = R.view.getViewBounds().center

			R.loader.showLoadingBar()

			# @raster.source = data.imageURL
			R.view.selectionLayer.addChild(@tracerGroup)

			@raster.onError = @rasterOnError

			@raster.onLoad = ()=> @rasterOnLoad(bounds)

			R.view.moveTo(@raster.bounds.center)

			return

		appendSVG: (svgstr)=>
			svgContainer = @svgContainerJ.get(0)
			svgContainer.style.display = 'inline-block'
			svgContainer.innerHTML = svgstr
			return
		
		setRasterCrop: (event)=>
			@rasterCropCenter = event.point
			@createRasterCrop()
			return

		getRasterCropRectangle: ()->
			maxDraftSize = R.Tools.Path.maxDraftSize * R.city.pixelPerMm
			if @raster.bounds.width < maxDraftSize and @raster.bounds.height < maxDraftSize
				return null
			width = Math.min(maxDraftSize, @raster.bounds.width)
			height = Math.min(maxDraftSize, @raster.bounds.height)
			rectangle = new P.Rectangle(@rasterCropCenter.subtract(width/2, height/2), new P.Size(width, height))
			return rectangle
		
		createRasterCrop: (warnIfTooBig=false)->
			if not @traceAutomatically
				return
			
			@rasterParts?.remove()
			maxDraftSize = R.Tools.Path.maxDraftSize * R.city.pixelPerMm
			if @raster.bounds.width < maxDraftSize and @raster.bounds.height < maxDraftSize
				return
			
			if warnIfTooBig and not @cropPositionAlertTimeout?
				# delay = 10000
				# @cropPositionAlertTimeout = setTimeout (()=> @cropPositionAlertTimeout = null), 1200000
				@cropPositionAlertTimeout = true
				R.alertManager.alert('Click on the image where you want to crop it', "info")
			
			@rasterParts = new P.Group()

			bounds = new P.Path.Rectangle(@raster.bounds)
			@rasterCropCenter ?= @raster.bounds.center
			rectangle = new P.Path.Rectangle(@getRasterCropRectangle())
			frame = bounds.subtract(rectangle)
			frame.strokeWidth = 1
			frame.fillColor = @constructor.handleColor
			frame.strokeColor = 'white'
			frame.opacity = 0.8
			@rasterParts.addChild(frame)
			bounds.fillColor = 'black'
			bounds.opacity = 0
			bounds.on('mouseenter', (event)=>
				R.stageJ.css('cursor', 'pointer')
				return
			)
			bounds.on('mouseleave', (event)=>
				R.selectedTool?.updateCursor()
				return
			)
			R.stageJ.css('cursor', 'pointer')
			bounds.on('mousedown', @setRasterCrop)
			bounds.on('mousedrag', @setRasterCrop)
			@rasterParts.addChild(bounds)
			rectangle.remove()

			@tracerGroup.addChild(@rasterParts)
			return

		# createRasterParts: ()->
		# 	maxDraftSize = R.Tools.Path.maxDraftSize
		# 	nRectanglesWidth = Math.floor(@raster.bounds.width / maxDraftSize) + 1
		# 	nRectanglesHeight = Math.floor(@raster.bounds.height / maxDraftSize) + 1

		# 	totalRectangle = new P.Rectangle(@raster.bounds.left, @raster.bounds.top, nRectanglesWidth * maxDraftSize, nRectanglesHeight * maxDraftSize)
		# 	totalRectangle.center = @raster.bounds.center

		# 	@rasterParts?.remove()
		# 	@rasterParts = new P.Group()

		# 	for nx in [0 .. nRectanglesWidth-1]
		# 		for ny in [0 .. nRectanglesHeight-1]
		# 			rectangle = new P.Rectangle(totalRectangle.left + nx * maxDraftSize, totalRectangle.top + ny * maxDraftSize, maxDraftSize, maxDraftSize)
		# 			rectangle = @raster.bounds.intersect(rectangle)
		# 			rectanglePath = P.Path.Rectangle(rectangle)
		# 			rectanglePath.fillColor = @constructor.handleColor
		# 			rectanglePath.strokeColor = 'white'
		# 			rectanglePath.opacity = 0.8
		# 			rectanglePath.on('mouseenter', (event)=>
		# 				event.target.opacity = 0.05
		# 				R.stageJ.css('cursor', 'pointer')
		# 				return
		# 			)
		# 			rectanglePath.on('mouseleave', (event)=>
		# 				R.selectedTool?.updateCursor()
		# 				event.target.opacity = 0.8
		# 				return
		# 			)
		# 			rectanglePath.on('mousedown', (event)=>
		# 				@draggingImage = true
		# 				return
		# 			)
		# 			rectanglePath.on('click', (event)=>
		# 				@autoTraceSized(event.target.bounds)
		# 				@rasterParts.remove()
		# 				@draggingImage = false
		# 				return
		# 			)
		# 			@rasterParts.addChild(rectanglePath)

		# 	@tracerGroup.addChild(@rasterParts)

		# 	return
		
		autoTrace: ()=>

			# C = parseInt(@adaptiveThresholdCJ.find('input').val())
			# windowSize = parseInt(@adaptiveThresholdWindowSizeJ.find('input').val())

			# @modal.modalJ.find('.modal-dialog').width(window.innerWidth)
			# @vectorizer.vectorize(@imageFile, @imageURL, C, windowSize)

			# if @raster.bounds.width > R.Tools.Path.maxDraftSize or @raster.bounds.height > R.Tools.Path.maxDraftSize
			# 	R.alertManager.alert 'The image is too big to fit in one drawing', 'info'
			# 	@createRasterParts()
			# 	return
			rectangle = @getRasterCropRectangle()
			if rectangle?
				rectangle = @raster.bounds.intersect(rectangle)
			@autoTraceSized(rectangle)
			return

		autoTraceSized: (bounds=null)=>
			
			@rasterPartRectangle = if bounds? then bounds else @raster.bounds

			@subRasterRectangle = new P.Rectangle(0, 0, @raster.width, @raster.height)
			
			if bounds?
				@subRasterRectangle = new P.Rectangle(bounds.topLeft.subtract(@raster.bounds.topLeft).divide(@raster.scaling), 
														bounds.bottomRight.subtract(@raster.bounds.topLeft).divide(@raster.scaling))

			if R.tools["Precise path"].draftLimit? and not R.tools["Precise path"].draftLimit.contains(@subRasterRectangle)
				R.tools["Precise path"].constructor.displayDraftIsTooBigError()
				return

			@rasterPart = null
			try
				@rasterPart = @raster.getSubRaster(@subRasterRectangle)
				
				maxRasterSize = @constructor.maxRasterSize

				if @rasterPart.width > maxRasterSize or @rasterPart.height > maxRasterSize
					@scaleRatio = if @rasterPart.width > @rasterPart.height then maxRasterSize/@rasterPart.width else maxRasterSize/@rasterPart.height
				else
					@scaleRatio = 1
				@rasterPart.width *= @scaleRatio
				@rasterPart.height *= @scaleRatio

				# @rasterPart.smoothing = false
				# @rasterPart.width *= 2
				# @rasterPart.height *= 2

				console.log(@rasterPart.width)
				png = @rasterPart.toDataURL()
				@rasterPart.remove()
				@rasterPart = null
				colors = []
				if R.useColors
					for color in R.toolManager.colors
						c = new paper.Color(color)
						colors.push([Math.round(c.red*255), Math.round(c.green*255), Math.round(c.blue*255), 255])
				args = {
					png: png,
					colors: colors
				}
				
				R.loader.showLoadingBar()
				$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'autoTrace', args: args } ).done(@autoTraceCallback)
				
			catch err
				@rasterPart?.remove()
				@rasterPart = null
				if err.code == 18
					modal = Modal.createModal( 
						id: 'import-image-cross-origin-issue',
						title: "Autotrace does not work with image URL", 
						submitButtonText: "Download image",
						submit: ()-> return window.location = @imageURL
					)
					modal.addText('You cannot trace automatically an image from an URL. Please make sure the image copyright allows reusing the image, then download the image on your computer and choose the image from your computer.', 'You cannot trace automatically an image from an URL')
					modal.show()
				return

			return
		
		autoTraceCallback: (result)=>
			R.loader.hideLoadingBar()
			if result.state == "error"
				@modal?.hide()
				# @rasterPart?.remove()
				# @rasterPart = null
				R.alertManager.alert(result.message, "error")
				return
			@modal?.hide()
			@addSvgToDraft(result.svg, result.colors)
			@closeRaster()
			return
		
		addPathsToDraft: (item, draft)->
			foundPath = false
			for child in item.children.slice()
				if child instanceof P.Path
					foundPath = true
					child.strokeWidth = R.Path.strokeWidth
					if item.strokeColor? and not child.strokeColor?
						child.strokeColor = item.strokeColor
					child.strokeCap = 'round'
					child.strokeJoin = 'round'
					child.fillColor = null
					if item.strokeColor?.equals('white')
						console.log('WARNING: ignoring white stroke')
						continue
					# draft.computeRectangle()
					# console.log(child.strokeColor, child.strokeWidth)
					draft.addChild(child, false, false)
				else if child.children?
					foundPath = foundPath or @addPathsToDraft(child, draft)
			return foundPath

		setStrokeColor: (item, rasterPart)->
			if item.className == 'Shape'
				path = item.toPath()
				item.remove()
				item = path
			if item.className == 'Path'
				point = rasterPart.globalToLocal(item.getPointAt(item.length/2))
				item.strokeColor = rasterPart.getPixel(point)
			else
				console.log(item.children)
				for child in item.children
					@setStrokeColor(child, rasterPart)
			return

		addSvgToDraft: (svg, colors)->
			# svgsPaper = new paper.Group()
			
			# svg = svg.replace(new RegExp('stroke:', 'g'), 'stroke-width: ' + R.Path.strokeWidth + 'px; stroke-color:')
			svg = svg.replace('<?xml version="1.0" standalone="yes"?>\n', '')

			regex = /style="stroke:([#\d\w]+); fill:none;"/gm
			# subst = 'style="stroke:$1; fill:none;" stroke="$1" stroke-width="' + R.Path.strokeWidth + '"'
			subst = 'stroke="$1" stroke-width="' + R.Path.strokeWidth + '"'

			# // The substituted value will be contained in the result variable
			svg = svg.replace(regex, subst)
			
			svgPaper = P.project.importSVG(svg, {insert: false})
			# console.log(svgPaper.exportSVG( string: true ))

			# @setStrokeColor(svgPaper, @rasterPart)
			# @rasterPart?.remove()
			# @rasterPart = null

			# svgPaper.remove()
			# svgsPaper.addChild(svgPaper)
			
			svgPaper.translate(@rasterPartRectangle.topLeft)
			svgPaper.scale(1/@scaleRatio, @rasterPartRectangle.topLeft)
			svgPaper.scale(@rasterPartRectangle.width / @subRasterRectangle.width, @rasterPartRectangle.topLeft)
			# svgPaper.fitBounds(@rasterPartRectangle)

			svgPaper.strokeCap = 'round'
			svgPaper.strokeJoin = 'round'
			svgPaper.strokeWidth = R.Path.strokeWidth
			
			draft = R.Item.Drawing.getDraft()
			R.commandManager.add(new Command.ModifyDrawing(draft))

			foundPath = @addPathsToDraft(svgPaper, draft)
			if not foundPath
				R.alertManager.alert 'The traced image is empty, please retry with a contrasted black and white image', 'error'
			draft.computeRectangle()
			
			draft.updatePaths()

			svgPaper.remove()
			R.svgPaper = svgPaper
			R.toolManager.updateButtonsVisibility()
			
			R.tools["Precise path"].showDraftLimits()

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
						# @urlInputJ.val(@imageURL)
						# @enableSubmitButtons()
						# @setEditImageMode()
						# @onModalSubmit()
						@openTraceTypeModal(true, false, true)
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
						# @urlInputJ.val(@imageURL)
						# @enableSubmitButtons()
						# @image = new Image()
						# @image.src = @imageURL
						# @imageContainerJ.append(@image)
						# $(@image).css( 'max-width': '500px', display: 'block', margin: 'auto' )
						# @submitURL(imageURL: readerEvent.target.result)
						@setEditImageMode()
						# @onModalSubmit()
						return
					reader.readAsDataURL(file)

					return

			return

		showButton: ()->
			@tracerBtn?.show()
			if @tracerGroup? and @traceAutomatically
				R.toolManager?.showTracerButtons()
				# @updateValidationButtons()
			return
		
		hideButton: ()->
			@tracerBtn?.hide()
			R.toolManager?.hideTracerButtons()
			return

		hide: ()->
			@tracerGroup?.visible = false
			return
		
		show: ()->
			@tracerGroup?.visible = true
			return
		
		isVisible: ()->
			return @tracerGroup?.visible and @tracerGroup.parent?

		mouseUp: (event)->
			@draggingImage = false
			@scalingImage = false
			if not @traceAutomatically
				R.selectedTool?.updateCursor()
			return
		
		update: ()->
			@drawHandles()
			return

	return Tracer
