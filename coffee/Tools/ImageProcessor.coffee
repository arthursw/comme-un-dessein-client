define ['paper', 'R', 'Utils/Utils', 'UI/Button', 'UI/Modal', 'Tools/Vectorizer', 'Tools/Camera', 'Tools/PathTool', 'Commands/Command', 'i18next', 'cropper' ], (P, R, Utils, Button, Modal, Vectorizer, PathTool, Camera, Command, i18next, Cropper) ->

	class ImageProcessor
		
		constructor: ()->
			return
		
		adaptiveThreshold: ()->
			# adaptive threshold

			# size of the block
			# n = 20 
			# C = 8
			n = 8
			C = 8
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
		
		processImage: (@filterCanvas)=>
			context = @filterCanvas.getContext('2d')
			# if not @initialImage?
			# 	@initialImage = context.getImageData(0, 0, @filterCanvas.width, @filterCanvas.height)
			# else
			# 	context.putImageData(@initialImage, 0, 0)
			@initialImage = context.getImageData(0, 0, @filterCanvas.width, @filterCanvas.height)
			console.log('start grayscale')
			@grayscale()
			@adaptiveThreshold()
			console.log('grayscale finished')
			# @filterCanvas.width *= 2
			# @filterCanvas.height *= 2
			return

	return ImageProcessor
