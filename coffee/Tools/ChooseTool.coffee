define ['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'Items/Item', 'Commands/Command' ], (P, R, Utils, Tool, Item, Command) ->

	class ChooseTool extends Tool

		@paperMargins = 16
		@paperWidth = 210 - @paperMargins
		@paperHeight = 297 - @paperMargins
		@nSheetsPerTile = 2

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
			return

		drawGrid: ()=>
			@lines ?= new P.Group()

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
				if n%@constructor.nSheetsPerTile != 0
					line.dashArray = [2, 2]
				line.strokeScaling = false
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
				if n%@constructor.nSheetsPerTile != 0
					line.dashArray = [2, 2]
				line.strokeScaling = false
				@lines.addChild(line)
				y += @constructor.paperHeight
				n++
			return

		select: (deselectItems=false, updateParameters=true, forceSelect=false, buttonClicked=false)->
			super(false, updateParameters)
			@drawGrid()
			return

		deselect: ()->
			super
			return

		begin: (event) ->
			return

		update: (event) ->
			return

		move: (event) ->

			width = @constructor.paperWidth * @constructor.nSheetsPerTile
			height = @constructor.paperHeight * @constructor.nSheetsPerTile

			if not @highlight?
				@highlight = new P.Path.Rectangle(0, 0, width, height)
				@highlight.strokeWidth = 5
				@highlight.strokeScaling = false
				@highlight.strokeColor = 'rgb(139, 195, 74)'

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

		end: (event) ->
			return

		doubleClick: (event) ->
			return

		keyUp: (event)->
			return

	R.Tools.Choose = ChooseTool
	return ChooseTool
