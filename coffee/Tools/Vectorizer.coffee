define ['paper', 'R', 'Utils/Utils', 'UI/Modal', 'potrace', 'i18next' ], (P, R, Utils, Modal, potrace, i18next) ->

	class Vectorizer

		constructor: ()->
			@strokeWidth = 10
			return

		createPaperProject: ()=>

			svgContainer = document.getElementById('vectorizer-svg')

			svgContainer.style.display = 'inline-block'
			# svgContainer.innerHTML = Potrace.getSVG(1)
			 
			mainProject = P.project

			@width = window.innerWidth
			@height = window.innerHeight

			svgCanvas = document.createElement("canvas")
			svgCanvas.width = @width
			svgCanvas.height = @height
			svgContainer.appendChild(svgCanvas)

			@project = new P.Project(svgCanvas)
			# @project.importSVG(svgContainer.children[0])
			@project.importSVG(Potrace.getSVG(1))
			@project.activeLayer.scale(2)
			# @project.selectAll()
			@project.view.setCenter(@project.activeLayer.bounds.center)
			@project.view.onClick = (event)=>
				hitResult = @project.hitTest(event.point)
				window.item = hitResult.item
				return


			# setTimeout(@startAnimation, 1500)

			@imageData = null

			@compoundPath = @project.activeLayer.firstChild.firstChild

			@strokes = new P.Group()
			for child in @compoundPath.children
				stroke = child.clone()
				stroke.fillColor = null
				stroke.closed = false
				stroke.strokeColor = 'blue'
				stroke.opacity = 0.5
				@strokes.addChild(stroke)
			
			@strokes.strokeWidth = 7
			

			@currentPathIndex = 1
			@currentOffsetOnPath = 0

			@currentLine = null
			@currentLines = new P.Group()
			@currentCircles = []

			return

		setStrokesOpacity: (opacity)->
			for child in @strokes.children
				child.opacity = opacity
			return

		getColorAt: (point, log=false)->
			pointInView = @project.view.projectToView(point).multiply(@project.view.pixelRatio)
			# delta = @raster.bounds.topLeft.subtract(@project.view.bounds.topLeft)
			# pointInView = pointInView.subtract(delta)
			index = Math.floor(pointInView.x + Math.floor(pointInView.y) * @width * @project.view.pixelRatio)
			r = @imageData.data[4 * index + 0]
			g = @imageData.data[4 * index + 1]
			b = @imageData.data[4 * index + 2]
			a = @imageData.data[4 * index + 3]
			if log
				console.log(pointInView, r, g, b, a)
			return a
			# color = @raster.getPixel(pointInView)
			# if log
			# 	console.log(pointInView, color.toCSS())
			# return color

		startAnimation: ()=>
			# context = @project.view.element.getContext('2d')
			# @imageData = context.getImageData(0, 0, @width, @height)
			
			context = @project.view.element.getContext('2d')
			@imageData = context.getImageData(0, 0, @project.view.pixelRatio * @width, @project.view.pixelRatio * @height)
			
			# @raster = @compoundPath.rasterize()
			# @raster.sendToBack()

			@project.view.onFrame = @onFrame

			@project.view.onMouseMove = (event)=>
				@getColorAt(event.point, true)
				return
			@project.view.onMouseUp = (event)=>
				context = @project.view.element.getContext('2d')
				@imageData = context.getImageData(0, 0, @project.view.pixelRatio * @width, @project.view.pixelRatio * @height)
				

				@getColorAt(event.point, true)
				return
			return

		onFrame: ()=>
			if @currentPathIndex >= @compoundPath.children
				return

			path = @compoundPath.children[@currentPathIndex]

			location = path.getLocationAt(@currentOffsetOnPath)

			for strokeWidth in [-@strokeWidth, @strokeWidth]
				
				normalSegment = new P.Path()
				normalSegment.add(location.point)
				normalSegment.add(location.point.add(location.normal.multiply(strokeWidth)))
				normalSegment.strokeColor = 'yellow'
				normalSegment.strokeWidth = 1
				
				crossings = @compoundPath.getCrossings(normalSegment)
				
				normalSegment.remove()

				closestCrossing = null
				minDistance = Number.MAX_VALUE
				for crossing in crossings
					d = crossing.point.getDistance(location.point, true)
					if d > 0 and d < minDistance
						closestCrossing = crossing
						minDistance = d

				if closestCrossing
					
					midPoint = closestCrossing.point.add(location.point).divide(2)
					# c = new P.Path.Circle(midPoint, 3)
					# c.fillColor = 'red'

					if @getColorAt(midPoint) < 128
						if not @currentLine?
							@currentLine = new P.Path()
							@currentLine.strokeColor = 'orange'
							@currentLine.strokeWidth = 5
							@currentLine.strokeCap = 'round'
							@currentLine.strokeJoin = 'round'
							@currentLines.addChild(@currentLine)
						@currentLine.add(midPoint)

						# circle = new P.Path.Circle(midPoint, 5)
						# circle.fillColor = 'red'
						# circle.strokeColor = 'orange'
						# circle.strokeWidth = 2
						# @currentCircles.push(circle)

			@currentOffsetOnPath += 10

			if @currentOffsetOnPath > path.length
				@currentOffsetOnPath = 0
				@currentPathIndex++

				if @currentPathIndex >= @compoundPath.children
					@compoundPath.remove()

				@currentLine = null

			return

		vectorize: (imageFile, imageURL, C, windowSize)->

			console.log(C, windowSize)
			Potrace.setParameter({ adaptiveThresholdC: C, adaptiveThresholdWindowSize: windowSize })

			if imageFile?
				Potrace.loadImageFromFile(imageFile)
			else if imageURL?
				Potrace.loadImageFromUrl(imageURL)
			else
				return
			
			Potrace.process(@createPaperProject)
			return

	return Vectorizer
