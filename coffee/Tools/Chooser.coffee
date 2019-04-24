define ['paper', 'R', 'Utils/Utils', 'UI/Button', 'UI/Modal', 'i18next' ], (P, R, Utils, Button, Modal, i18next) ->

	class Chooser

		@cellMargins = 16
		@cellWidth = 210 - @cellMargins
		@cellHeight = 297 - @cellMargins

		constructor: ()->
			@createChooserButton()
			return

		createChooserButton: ()->

			@chooserBtn = new Button(
				name: 'Choose a cell'
				# iconURL: if R.style == 'line' then 'chooser2.png' else if R.style == 'hand' then 'chooser2.png' else 'glyphicon-check'
				# iconURL: 'glyphicon-check'
				iconURL: 'chooser3.png'
				favorite: true
				category: null
				disableHover: true
				# description: 'Choisir'
				# popover: true
				order: null
				classes: 'displayName'
			)


			@chooserBtn.btnJ.click ()=> 
				@drawGrid()
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
				if n%2 == 0
					line.dashArray = [2, 2]
				line.strokeScaling = false
				@lines.addChild(line)
				x += @constructor.cellWidth
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
				if n%2 == 0
					line.dashArray = [2, 2]
				line.strokeScaling = false
				@lines.addChild(line)
				y += @constructor.cellHeight
				n++
			return
		



	return Chooser
