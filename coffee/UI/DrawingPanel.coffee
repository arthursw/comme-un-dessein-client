define [ 'Items/Item', 'coffee', 'typeahead' ], (Item, CoffeeScript) -> 			# 'ace/ext-language_tools', required?

	class DrawingPanel

		constructor: ()->
			# the button to open the panel
			@submitDrawingBtnJ = $('button.submit-drawing')
			@submitDrawingBtnJ.click(@submitDrawingClicked)

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
			@votesJ = @drawingPanelJ.find('.votes')
			# @footerJ = @drawingPanelJ.find(".footer")
			
			runBtnJ = @drawingPanelJ.find("button.submit.run")
			runBtnJ.click @runFile

			@voteUpBtnJ = @drawingPanelJ.find('.vote-up')
			@voteUpBtnJ.click(@voteUp)

			@voteDownBtnJ = @drawingPanelJ.find('.vote-down')
			@voteDownBtnJ.click(@voteDown)

			@submitBtnJ = @drawingPanelJ.find('form.create button.submit')
			@modifyBtnJ = @drawingPanelJ.find('form.create button.modify')
			@cancelBtnJ = @drawingPanelJ.find('form.create button.cancel')

			@submitBtnJ.click(@submitDrawing)
			@modifyBtnJ.click(@modifyDrawing)
			@cancelBtnJ.click(@cancelDrawing)

			contentJ = @drawingPanelJ.find('.content')
			descriptionJ = contentJ.find('#drawing-description')
			descriptionJ.keydown (event)=>
				switch Utils.specialKeys[event.keyCode]
					when 'enter'
						if event.metaKey or event.ctrlKey then @submitDrawing()
				return

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

		showSubmitDrawing: ()->
			@submitDrawingBtnJ.removeClass('hidden')
			@submitDrawingBtnJ.show()
			contentJ = @drawingPanelJ.find('.content')
			contentJ.find('#drawing-title').focus()
			return

		hideSubmitDrawing: ()->
			@submitDrawingBtnJ.hide()
			return

		submitDrawingClicked: ()=>
			# @submitDrawingBtnJ.hide()
			@open()
			@hideLoadAnimation()
			@currentDrawing = null
			contentJ = @drawingPanelJ.find('.content')
			contentJ.find('.read').hide()
			contentJ.find('.modify').show()
			contentJ.find('#drawing-title').val('')
			contentJ.find('#drawing-description').val('')
			@submitBtnJ.show()
			@modifyBtnJ.hide()
			@cancelBtnJ.hide()
			@votesJ.hide()
			return

		setDrawing: (@currentDrawing, drawingData)->
			@open()
			@hideLoadAnimation()
			
			contentJ = @drawingPanelJ.find('.content')
			@currentDrawing.votes = drawingData.votes

			if @currentDrawing.owner == R.me
				contentJ.find('.read').hide()
				contentJ.find('.modify').show()
				contentJ.find('#drawing-title').val(@currentDrawing.title)
				contentJ.find('#drawing-description').val(@currentDrawing.description)
				@submitBtnJ.hide()
				@modifyBtnJ.show()
				@cancelBtnJ.show()
			else
				contentJ.find('.read').show()
				contentJ.find('.modify').hide()
				contentJ.find('.title').html(@currentDrawing.title)
				contentJ.find('.description').html(@currentDrawing.description)
				contentJ.find('.author').html(@currentDrawing.owner)

			@votesJ.show()
			@voteUpBtnJ.removeClass('voted')
			@voteDownBtnJ.removeClass('voted')
			positiveVoteListJ = @drawingPanelJ.find('.vote-list.positive')
			negativeVoteListJ = @drawingPanelJ.find('.vote-list.negative')
			positiveVoteListJ.empty()
			negativeVoteListJ.empty()
			nPositiveVotes = 0
			nNegativeVotes = 0
			for vote in drawingData.votes
				v = JSON.parse(vote.vote)
				liJ = $('<li data-author-pk="'+vote.authorPk+'">'+vote.author+'</li>')
				if v.positive
					nPositiveVotes++
					positiveVoteListJ.append(liJ)
					if vote.author == R.me
						@voteUpBtnJ.addClass('voted')
				else
					nNegativeVotes++
					negativeVoteListJ.append(liJ)
					if vote.author == R.me
						@voteDownBtnJ.addClass('voted')

			@votesJ.find('.n-votes.positive').html(nPositiveVotes)
			@votesJ.find('.n-votes.negative').html(nNegativeVotes)
			nVotes = nPositiveVotes+nNegativeVotes
			@votesJ.find('.n-votes.total').html(nVotes)
			@votesJ.find('.percentage-votes').html(if nVotes > 0 then 100*nPositiveVotes/nVotes else 0)
			return

		### votes ###

		hasAlreadyVoted: ()->
			for vote in @currentDrawing.votes
				if vote.vote.author == R.me
					return true
			return false

		voteCallback: (result)=>
			if not R.loader.checkError(result) then return
			R.alertManager.alert 'You successfuly voted', 'success'
			return

		vote: (positive)=>
			if @currentDrawing.owner == R.me
				R.alertManager.alert 'You cannot vote for your own drawing', 'error'
				return

			if @hasAlreadyVoted()
				R.alertManager.alert 'You already voted for this drawing', 'error'
				return

			args =
				pk: @currentDrawing.pk
				date: Date.now()
				positive: positive

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'vote', args: args } ).done(@voteCallback)

			return

		voteUp: ()=>
			@vote(true)
			return

		voteDown: ()=>
			@vote(false)
			return

		### submit modify cancel drawing ###

		submitDrawing: ()=>

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to submit a drawing.", "error"
				return

			if R.selectedItems.length == 0
				R.alertManager.alert "You must select some drawings first.", "error"
				return

			drawingID = Utils.createID()

			for item in R.selectedItems
				item.drawingID = drawingID

			contentJ = @drawingPanelJ.find('.content')

			title = contentJ.find('#drawing-title').val()
			description = contentJ.find('#drawing-description').val()
			drawing = new Item.Drawing(null, null, drawingID, null, R.me, Date.now(), title, description, 'pending')
			drawing.save()
			drawing.rasterize()
			R.rasterizer.rasterize(drawing, false)
			Utils.callNextFrame((()-> return drawing.select(true, false)), 'select drawing')
			
			@close()

			return

		modifyDrawingCallback: (result)=>
			if not R.loader.checkError(result) then return
			R.alertManager.alert "Drawing successfully modified.", "success"
			return

		modifyDrawing: ()=>

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to modify a drawing.", "error"
				return

			if not @currentDrawing?
				R.alertManager.alert "You must select a drawing first.", "error"
				return

			contentJ = @drawingPanelJ.find('.content')

			args = {
				pk: @currentDrawing.pk
				title: contentJ.find('#drawing-title').val()
				description: contentJ.find('#drawing-description').val()
			}

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'updateDrawing', args: args } ).done(@modifyDrawingCallback)

			return

		cancelDrawingCallback: (result)=>
			if not R.loader.checkError(result) then return
			R.alertManager.alert "Drawing successfully cancelled.", "success"
			return

		cancelDrawing: ()=>

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to cancel a drawing.", "error"
				return

			if not @currentDrawing?
				R.alertManager.alert "You must select a drawing first.", "error"
				return

			args = {
				pk: @currentDrawing.pk
			}

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'deleteDrawing', args: args } ).done(@deleteDrawingCallback)

			return

	return DrawingPanel
