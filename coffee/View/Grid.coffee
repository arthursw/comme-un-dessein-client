define ['paper', 'R', 'Utils/Utils', 'i18next'], (P, R, Utils, i18next) ->

	class Grid

		constructor: ()->
			@layer = new P.Layer()
			@layer.name = "grid"

			@grid = new P.Group() 					# Paper P.Layer to append all grid items
			@grid.name = 'grid group'
			@layer.addChild(@grid)
			
			@size = new P.Size(R.city.pixelPerMm * (R.city.width or 100000), R.city.pixelPerMm * (R.city.height or 100000))

			@frameSize = @size.multiply(10)
			@frameRectangle = new P.Rectangle(@frameSize.multiply(-0.5), @frameSize)
			@limitCDRectangle = new P.Rectangle(@size.multiply(-0.5), @size)

			if R.city.name != 'world'
				@createFrame()

			@limitCD = new P.Path.Rectangle(@limitCDRectangle)
			@limitCD.strokeColor = '#33383e'
			@limitCD.strokeWidth = 1
			# @limitCD.strokeCap = 'square'
			# @limitCD.fillColor = 'white'
			# @limitCD.dashArray = [10, 14]
			
			@layer.addChild(@limitCD)
			@layer.sendToBack()

			@continueDrawingsText = new P.PointText(@limitCDRectangle.bottomCenter.add(0,250))
			@continueDrawingsText.fillColor = 'white'
			@continueDrawingsText.content = i18next.t("N'hésitez pas à continuer les dessins existants, ou à les augmenter ;-)")
			@continueDrawingsText.fontSize = 200
			@continueDrawingsText.justification = 'center'
			@layer.addChild(@continueDrawingsText)

			@update()

			return

		projectToGeoJSON: (point)->
			return new P.Point(Utils.CS.PlanetWidth * point.x / @size.width, Utils.CS.PlanetHeight * point.y / @size.height)

		projectToGeoJSONRectangle: (rectangle)->
			topLeft = @projectToGeoJSON(rectangle.topLeft)
			bottomRight = @projectToGeoJSON(rectangle.bottomRight)
			return new P.Rectangle(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y)

		geoJSONToProject: (point)->
			return new P.Point(@size.width * point.x / Utils.CS.PlanetWidth, @size.height * point.y / Utils.CS.PlanetHeight)

		boundsFromBox: (box)->
			left = @size.width * box['coordinates'][0][0][0] / Utils.CS.PlanetWidth
			top = @size.height * box['coordinates'][0][0][1] / Utils.CS.PlanetHeight
			right = @size.width * box['coordinates'][0][2][0] / Utils.CS.PlanetWidth
			bottom = @size.height * box['coordinates'][0][2][1] / Utils.CS.PlanetHeight
			return new P.Rectangle(left, top, right-left, bottom-top)

		createFrame: ()->
			@frame?.remove()
			@frame = new P.Group()
			@frame.fillColor = '#252525'
			@frame.strokeColor = '#252525'
			@frame.strokeWidth = 2

			l1 = new P.Path.Rectangle(@frameRectangle.topLeft, new P.Point(@frameRectangle.right, @limitCDRectangle.top))
			l2 = new P.Path.Rectangle(new P.Point(@frameRectangle.left, @limitCDRectangle.top), new P.Point(@limitCDRectangle.left, @limitCDRectangle.bottom))
			l3 = new P.Path.Rectangle(new P.Point(@limitCDRectangle.right, @limitCDRectangle.top), new P.Point(@frameRectangle.right, @limitCDRectangle.bottom))
			l4 = new P.Path.Rectangle(new P.Point(@frameRectangle.left, @limitCDRectangle.bottom), @frameRectangle.bottomRight)

			@frame.addChild(l1)
			@frame.addChild(l2)
			@frame.addChild(l3)
			@frame.addChild(l4)

			for child in @frame.children
				child.fillColor = '#252525'
				child.strokeColor = '#252525'
				child.strokeWidth = 2

			@layer.addChild(@frame)
			
			return

		## Manage limits between planets
		# Test if *rectangle* overlaps two planets
		#
		# @param rectangle [P.Rectangle] rectangle to test
		# @return [Boolean] true if overlaps
		rectangleOverlapsTwoPlanets: (rectangle, tolerance=50)->
			return not @limitCD.bounds.expand(-tolerance).contains(rectangle)
			# limit = Utils.CS.getLimit()
			# if ( rectangle.left < limit.x && rectangle.right > limit.x ) || ( rectangle.top < limit.y && rectangle.bottom > limit.y )
			# 	return true
			# return false

		contains: (item, tolerance=50)->
			return @limitCD.bounds.expand(-tolerance).contains(item)


		updateLimitPaths: ()->
			
			limit = Utils.CS.getLimit()

			@limitPathV = null
			@limitPathH = null

			if limit.x >= P.view.bounds.left and limit.x <= P.view.bounds.right
				@limitPathV = new P.Path()
				@limitPathV.name = 'limitPathV'
				@limitPathV.strokeColor = '#252525'
				@limitPathV.strokeWidth = 1
				@limitPathV.add(limit.x, P.view.bounds.top)
				@limitPathV.add(limit.x, P.view.bounds.bottom)
				@grid.addChild(@limitPathV)

			if limit.y >= P.view.bounds.top and limit.y <= P.view.bounds.bottom
				@limitPathH = new P.Path()
				@limitPathH.name = 'limitPathH'
				@limitPathH.strokeColor = '#252525'
				@limitPathH.strokeWidth = 1
				@limitPathH.add(P.view.bounds.left, limit.y)
				@limitPathH.add(P.view.bounds.right, limit.y)
				@grid.addChild(@limitPathH)

			return

		# Draw planet limits, and draw the grid if *R.displayGrid*
		# The grid size is equal to the snap, except when snap < 15, then it is set to 25
		# one line every 4 lines is thick and darker
		update: ()->

			# draw planet limits (thick green lines)
			@grid.removeChildren()

			@updateLimitPaths()

			if P.view.bounds.width > window.innerWidth or P.view.bounds.height > window.innerHeight
				halfSize = new P.Point(window.innerWidth*0.5, window.innerHeight*0.5)
				bounds = new P.Rectangle(P.view.center.subtract(halfSize), P.view.center.add(halfSize))
				path = new P.Path.Rectangle(bounds)
				path.strokeColor = 'rgba(0, 0, 0, 0.1)'
				path.strokeWidth = 0.1
				path.dashArray = [10, 4]
				# boundsCompoundPath = new P.CompoundPath( children: [ new P.Path.Rectangle(P.view.bounds), new P.Path.Rectangle(bounds) ] )
				# boundsCompoundPath.strokeScaling = false
				# boundsCompoundPath.fillColor = 'rgba(0,0,0,0.1)'
				@grid.addChild(path)

			if not R.displayGrid
				return

			# draw grid
			snap = Utils.Snap.getSnap()
			bounds = Utils.Rectangle.expandRectangleToMultiple(P.view.bounds, snap)

			left = bounds.left
			top = bounds.top

			while left < bounds.right or top < bounds.bottom

				px = new P.Path()
				px.name = "grid px"
				py = new P.Path()
				px.name = "grid py"

				px.strokeColor = "#666666"
				if ( left / snap ) % 4 == 0
					px.strokeColor = "#000000"
					px.strokeWidth = 2

				py.strokeColor = "#666666"
				if ( top / snap ) % 4 == 0
					py.strokeColor = "#000000"
					py.strokeWidth = 2

				px.add(new P.Point(left, P.view.bounds.top))
				px.add(new P.Point(left, P.view.bounds.bottom))

				py.add(new P.Point(P.view.bounds.left, top))
				py.add(new P.Point(P.view.bounds.right, top))

				@grid.addChild(px)
				@grid.addChild(py)

				left += snap
				top += snap

			return

	return Grid
