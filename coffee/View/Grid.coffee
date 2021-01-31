define ['paper', 'R', 'Utils/Utils'], (P, R, Utils) ->

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

			@update()

			return

		projectToGeoJSON: (point)->
			return new P.Point(Utils.CS.PlanetWidth * point.x / @size.width, Utils.CS.PlanetHeight * point.y / @size.height)

		projectToGeoJSONRectangle: (rectangle)->
			topLeft = @projectToGeoJSON(rectangle.topLeft)
			return new P.Rectangle(topLeft.x, topLeft.y, Utils.CS.PlanetWidth * rectangle.width / @size.width, Utils.CS.PlanetHeight * rectangle.height / @size.height)

		geoJSONToProject: (point)->
			return new P.Point(@size.width * point.x / Utils.CS.PlanetWidth, @size.height * point.y / Utils.CS.PlanetHeight)

		boundsFromBox: (box)->
			left = @size.width * box['coordinates'][0][0][0] / Utils.CS.PlanetWidth
			top = @size.height * box['coordinates'][0][0][1] / Utils.CS.PlanetHeight
			right = @size.width * box['coordinates'][0][2][0] / Utils.CS.PlanetWidth
			bottom = @size.height * box['coordinates'][0][2][1] / Utils.CS.PlanetHeight
			return new P.Rectangle(left, top, right-left, bottom-top)

		createFrame: ()->

			@frame = new P.Group()
			@frame.fillColor = '#252525'

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

		# Test if *path* overlaps two planets
		#
		# @param path [Paper path] path to test
		# @return [Boolean] true if overlaps
		# R.pathOverlapsTwoPlanets = (path)->
		# 	limitPaths = Utils.CS.getLimitPaths()
		# 	limitPathV = limitPaths.vertical
		# 	limitPathH = limitPaths.horizontal

		# 	if limitPathV?
		# 		intersections = path.getIntersections(limitPathV)
		# 		limitPathV.remove()
		# 		if intersections.length>0
		# 			return true

		# 	if limitPathH?
		# 		intersections = path.getIntersections(limitPathH)
		# 		limitPathH.remove()
		# 		if intersections.length>0
		# 			return true

		# 	return false


		updateLimitPaths: ()->
			limit = Utils.CS.getLimit()

			@limitPathV = null
			@limitPathH = null

			if limit.x >= P.view.bounds.left and limit.x <= P.view.bounds.right
				@limitPathV = new P.Path()
				@limitPathV.name = 'limitPathV'
				@limitPathV.strokeColor = 'green'
				@limitPathV.strokeWidth = 5
				@limitPathV.add(limit.x, P.view.bounds.top)
				@limitPathV.add(limit.x, P.view.bounds.bottom)
				@grid.addChild(@limitPathV)

			if limit.y >= P.view.bounds.top and limit.y <= P.view.bounds.bottom
				@limitPathH = new P.Path()
				@limitPathH.name = 'limitPathH'
				@limitPathH.strokeColor = 'green'
				@limitPathH.strokeWidth = 5
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

			# t = Math.floor(P.view.bounds.top / R.scale)
			# l = Math.floor(P.view.bounds.left / R.scale)
			# b = Math.floor(P.view.bounds.bottom / R.scale)
			# r = Math.floor(P.view.bounds.right / R.scale)

			# pos = getTopLeftCorner()

			# planet = projectToPlanet( pos )
			# posOnPlanet = projectToPosOnPlanet( pos )

			# debug = false

			# snap = Utils.Snap.getSnap()
			# if snap < 15 then snap = 15
			# if debug then snap = 250

			# # draw lines
			# n = 1
			# i = l
			# j = t
			# while i<r+1 or j<b+1

			# 	px = new P.Path()
			# 	px.name = "grid px"
			# 	py = new P.Path()
			# 	px.name = "grid py"

			# 	ijOnPlanet = projectToPosOnPlanet(new P.Point(i*R.scale,j*R.scale))

			# 	if ijOnPlanet.x == -Utils.CS.PlanetHeight
			# 		px.strokeColor = "#00FF00"
			# 		px.strokeWidth = 5
			# 	else if n<4 # i-Math.floor(i)>0.0
			# 		px.strokeColor = "#666666"
			# 	else
			# 		px.strokeColor = "#000000"
			# 		px.strokeWidth = 2

			# 	if ijOnPlanet.y == -90
			# 		py.strokeColor = "#00FF00"
			# 		py.strokeWidth = 5
			# 	else if n<4 # j-Math.floor(j)>0.0
			# 		py.strokeColor = "#666666"
			# 	else
			# 		py.strokeColor = "#000000"
			# 		py.strokeWidth = 2

			# 	px.add(new P.Point(i*R.scale, P.view.bounds.top))
			# 	px.add(new P.Point(i*R.scale, P.view.bounds.bottom))

			# 	py.add(new P.Point(P.view.bounds.left, j*R.scale))
			# 	py.add(new P.Point(P.view.bounds.right, j*R.scale))

			# 	@grid.addChild(px)
			# 	@grid.addChild(py)

			# 	i += snap/R.scale
			# 	j += snap/R.scale

			# 	if n==4 then n=0
			# 	n++

			# if not debug then return

			# # draw position text if debug
			# i = l
			# while i<r+1
			# 	j = t
			# 	while j<b+1
			# 		x = i*R.scale
			# 		y = j*R.scale

			# 		planetText = new P.PointText(new P.Point(x-10,y-40))
			# 		planetText.justification = 'right'
			# 		planetText.fillColor = 'black'
			# 		p = projectToPlanet(new P.Point(i*R.scale,j*R.scale))
			# 		planetText.content = 'px: ' + Math.floor(p.x) + ', py: ' + Math.floor(p.y)
			# 		@grid.addChild(planetText)
			# 		posText = new P.PointText(new P.Point(x-10,y-20))
			# 		posText.justification = 'right'
			# 		posText.fillColor = 'black'
			# 		p = projectToPosOnPlanet(new P.Point(i*R.scale,j*R.scale))
			# 		posText.content = 'x: ' + p.x.toFixed(2) + ', y: ' + p.y.toFixed(2)
			# 		@grid.addChild(posText)


			# 		j += snap/R.scale

			# 	i += snap/R.scale
			return

	return Grid
