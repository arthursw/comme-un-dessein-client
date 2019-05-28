define ['paper', 'R', 'Utils/Utils' ], (P, R, Utils) ->

	class Toolbar

		constructor: ()->
			@intervalID = null

			@dragging = false
			@draggingPosition = null
			@draggingSpeed = null
			@dragTimeoutID = null

			@toolListJ = $('#FavoriteTools .tool-list')

			@leftArrowJ = $('#FavoriteTools button.arrow.left')
			@rightArrowJ = $('#FavoriteTools button.arrow.right')

			@leftArrowJ
			.mousedown(@moveToolbarLeft)
			.mouseleave( @stopMove )
			.mouseup( @stopMove )
			.on( touchstart: @moveToolbarLeft )
			.on( touchleave: @stopMove )
			.on( touchend: @stopMove )
			.on( touchcancel: @stopMove )

			@rightArrowJ
			.mousedown(@moveToolbarRight)
			.mouseleave( @stopMove )
			.mouseup( @stopMove )
			.on( touchstart: @moveToolbarRight )
			.on( touchleave: @stopMove )
			.on( touchend: @stopMove )
			.on( touchcancel: @stopMove )

			requestAnimationFrame(@animate)

			@toolListJ.mousedown(@startDrag).on( touchstart: @startDrag )
			$(document).mousemove(@drag)
			.mouseup(@stopDrag)
			.on( touchmove: @drag )
			.on( touchleave: @stopDrag )
			.on( touchend: @stopDrag )
			.on( touchcancel: @stopDrag )

			@updateArrowsVisibility()
			return
		
		startDrag: (event)=>
			@dragging = true
			@draggingPosition = event.pageX or event.originalEvent.touches[0].pageX
			return

		nullifySpeedIfNotMoved: ()=>
			if @dragging
				@draggingSpeed = null
			@dragTimeoutID = null
			return

		drag: (event)=>
			if @dragging
				position = event.pageX or event.originalEvent.touches[0].pageX
				@draggingSpeed = position - @draggingPosition
				@moveToolbar(@draggingSpeed)
				@draggingPosition = position
				if @dragTimeoutID?
					clearTimeout(@dragTimeoutID)
					@dragTimeoutID = null
				@dragTimeoutID = setTimeout(@nullifySpeedIfNotMoved, 100)
			return

		animate: ()=>
			requestAnimationFrame(@animate)
			if @dragging
				return
			if @draggingSpeed != null
				@draggingSpeed *= 0.9
				@moveToolbar(@draggingSpeed)
			if Math.abs(@draggingSpeed) < 0.1
				@draggingSpeed = null
			return
		
		stopDrag: (event)=>
			if @dragTimeoutID?
				clearTimeout(@dragTimeoutID)
				@dragTimeoutID = null
			@dragging = false
			@draggingStart = null
			@stopMove(event)
			return

		updateArrowsVisibility: (toollistWidth=null, windowWidth=null, positionX=null)=>
			toollistWidth ?= @toolListJ.outerWidth()
			# windowWidth ?= @rightArrowJ.offset().left + @rightArrowJ.outerWidth()
			windowWidth ?= window.innerWidth
			positionX ?= Math.floor(@toolListJ.offset().left)
			
			if positionX >= 0
				@leftArrowJ.css( opacity: 0 )
			else
				@leftArrowJ.css( opacity: 0.8 ).show()

			if positionX + toollistWidth <= windowWidth
				@rightArrowJ.css( opacity: 0 )
			else
				@rightArrowJ.css( opacity: 0.8 ).show()

			if positionX + toollistWidth < windowWidth
				if toollistWidth > windowWidth
					positionX = windowWidth - toollistWidth
				else
					positionX = 0
				@toolListJ.css('left', positionX)
			return

		moveToolbar: (offset)=>
			toollistWidth = @toolListJ.outerWidth()
			windowWidth = window.innerWidth
			positionX = @toolListJ.offset().left
			positionX += offset
			if positionX > 0
				positionX = 0
			if positionX < -(toollistWidth - windowWidth)
				positionX = -(toollistWidth - windowWidth)
			@toolListJ.css('left', positionX)
			@updateArrowsVisibility(toollistWidth, windowWidth, positionX)
			return

		clearInterval: ()=>
			if @intervalID?
				clearInterval(@intervalID)
				@intervalID = null
			return

		moveToolbarLeft: ()=>
			@moveToolbar(5)
			@clearInterval()
			@intervalID = setInterval((()=>@moveToolbar(5)), 10)
			return

		moveToolbarRight: ()=>
			@moveToolbar(-5)
			@clearInterval()
			@intervalID = setInterval((()=>@moveToolbar(-5)), 10)
			return
		
		hideButtons: ()=>
			if @rightArrowJ.css( 'opacity' ) == '0'
				@rightArrowJ.hide()
			if @leftArrowJ.css( 'opacity' ) == '0'
				@leftArrowJ.hide()
			return

		stopMove: (event)=>
			@clearInterval()
			setTimeout(@hideButtons, 500)
			return
		