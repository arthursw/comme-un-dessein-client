define [ 'coffee', 'typeahead' ], (CoffeeScript) -> 			# 'ace/ext-language_tools', required?

	class DrawingPanel

		constructor: ()->

			# editor
			@drawingPanelJ = $("#drawingPanel")
			@drawingPanelJ.bind "transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd", @resize

			# if R.sidebar.sidebarJ.hasClass("r-hidden")
				# @drawingPanelJ.addClass("r-hidden")

			# handle
			handleJ = @drawingPanelJ.find(".panel-handle")
			handleJ.mousedown @onHandleDown
			handleJ.find('.handle-right').click(@setHalfSize)
			handleJ.find('.handle-left').click(@setFullSize)

			# header
			@fileNameJ = @drawingPanelJ.find(".header .fileName input")
			@linkFileInputJ = @drawingPanelJ.find("input.link-file")
			@linkFileInputJ.change(@linkFile)
			closeBtnJ = @drawingPanelJ.find("button.close-panel")
			closeBtnJ.click @close

			# footer
			@footerJ = @drawingPanelJ.find(".footer")
			
			runBtnJ = @drawingPanelJ.find("button.submit.run")
			runBtnJ.click @runFile

			return

		### mouse interaction ###

		onHandleDown: ()=>
			@draggingEditor = true
			$("body").css( 'user-select': 'none' )
			return

		setHalfSize: ()=>
			@drawingPanelJ.css(left: '70%')
			@resize()
			return

		setFullSize: ()=>
			@drawingPanelJ.css(left: '265px')
			@resize()
			return

		resize: ()=>
			# @editor.resize()
			return

		onMouseMove: (event)->
			if @draggingEditor
				@drawingPanelJ.css( left: Math.max(265, event.pageX))
			return

		onMouseUp: (event)=>
			@draggingEditor = false
			$("body").css('user-select': 'text')
			return

		### open close ###

		open: ()->
			@drawingPanelJ.show()
			@drawingPanelJ.addClass('visible')
			return

		close: ()=>
			@drawingPanelJ.hide()
			@drawingPanelJ.removeClass('visible')
			return

		### set drawing ###
		
		showLoadAnimation: ()=>
			@drawingPanelJ.find('.content').children().hide()
			@drawingPanelJ.find('.content').children('.loading-animation').show()
			return

		hideLoadAnimation: ()=>
			@drawingPanelJ.find('.content').children().show()
			@drawingPanelJ.find('.content').children('.loading-animation').hide()
			return

		setDrawing: (@currentDrawing, drawingData)=>
			@hideLoadAnimation()
			for vote in drawingData.votes
				vote.vote
				vote.author
				vote.authorPk
			return

	return DrawingPanel
