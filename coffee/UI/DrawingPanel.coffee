define ['paper', 'R', 'Utils/Utils', 'Items/Item', 'coffeescript-compiler', 'typeahead' ], (P, R, Utils, Item, CoffeeScript) -> 			# 'ace/ext-language_tools', required?

	class DrawingPanel

		constructor: ()->
			# the button to start drawing
			@beginDrawingBtnJ = $('button.begin-drawing')
			@beginDrawingBtnJ.click(@beginDrawingClicked)


			# the button to open the panel
			@submitDrawingBtnJ = $('button.submit-drawing')
			@submitDrawingBtnJ.click(@submitDrawingClicked)

			# @cancelDrawingBtnJ = $('button.cancel-drawing')
			# @cancelDrawingBtnJ.click(@cancelDrawingClicked)

			# editor
			@drawingPanelJ = $("#drawingPanel")
			@drawingPanelJ.bind "transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd", @resize

			# if R.sidebar.sidebarJ.hasClass("r-hidden")
				# @drawingPanelJ.addClass("r-hidden")

			# handle
			handleJ = @drawingPanelJ.find(".panel-handle")
			handleJ.mousedown @onHandleDown
			# handleJ.on( touchstart: @onHandleDown )
			handleJ.find('.handle-right').click(@setHalfSize)
			handleJ.find('.handle-left').click(@setFullSize)

			@drawingPanelTitleJ = @drawingPanelJ.find('.drawing-panel-title')

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

			@submitBtnJ = @drawingPanelJ.find('.action-buttons button.submit')
			@modifyBtnJ = @drawingPanelJ.find('.action-buttons button.modify')
			@cancelBtnJ = @drawingPanelJ.find('.action-buttons button.cancel')

			@submitBtnJ.click(@submitDrawing)
			@modifyBtnJ.click(@modifyDrawing)
			@cancelBtnJ.click(@cancelDrawing)

			@contentJ = @drawingPanelJ.find('.content-container')
			descriptionJ = @contentJ.find('#drawing-description')
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
				point = Utils.Event.GetPoint(event)
				@drawingPanelJ.css( left: Math.max(265, point.x))
			return

		onMouseUp: (event)=>
			@draggingEditor = false
			$("body").css('user-select': 'text')
			return

		updateSelection: ()=>
			if R.selectedItems.length == 1

				@showLoadAnimation()
				@open()

				drawing = R.selectedItems[0]

				if drawing.pk?
					delete drawing.selectAfterSave
					drawing.updateDrawingPanel()
				else
					drawing.selectAfterSave = true

			else
				@showSelectedDrawings()

				@open()

			return

		selectionChanged: ()->
			Utils.callNextFrame(@updateSelection, 'update drawing selection')
			return

		deselectDrawing: (drawing)->
			if drawing == @currentDrawing
				@currentDrawing = null
			if R.selectedItems.length == 0
				@close()
				# @hideSubmitDrawing()
			return

		### open close ###

		open: ()->
			@drawingPanelJ.show()
			@drawingPanelJ.addClass('visible')
			return

		close: (removeDrawingIfNotSaved=true)=>
			if @currentDrawing? and not @currentDrawing.pk?
				if removeDrawingIfNotSaved
					@currentDrawing.remove()
				# @showBeginDrawing()
			@drawingPanelJ.hide()
			@drawingPanelJ.removeClass('visible')
			if R.selectedItems.length > 0
				R.tools.select.deselectAll()
			return

		### set drawing ###
		
		createSelectionLi: (selectedDrawingsJ, listJ, item)->
			liJ = $('<li>')
			liJ.addClass('drawing-selection cd-button')
			liJ.addClass('cd-row')
			thumbnailJ = $('<div>')
			thumbnailJ.addClass('thumbnail drawing-thumbnail')
			thumbnailJ.append(@getDrawingImage(item))
			titleJ = $('<h4>')
			titleJ.addClass('cd-grow cd-center')
			titleJ.html(item.title)
			deselectBtnJ = $('<button>')
			deselectBtnJ.addClass('btn btn-default icon-only transparent')
			deselectIconJ = $('<span>').addClass('glyphicon glyphicon-remove')
			deselectBtnJ.click (event)->
				item.deselect()
				liJ.remove()
				event.preventDefault()
				event.stopPropagation()
				return -1
			deselectBtnJ.append(deselectIconJ)
			liJ.append(thumbnailJ)
			liJ.append(titleJ)
			liJ.append(deselectBtnJ)
			liJ.click ()->
				selectedDrawingsJ.hide()
				listJ.empty()
				R.tools.select.deselectAll()
				item.select()
				return
			listJ.append(liJ)
			return

		showSelectedDrawings: ()->
			@drawingPanelTitleJ.text('Select a single drawing')

			@drawingPanelJ.find('.content-container').children().hide()
			selectedDrawingsJ = @drawingPanelJ.find('.selected-drawings')
			selectedDrawingsJ.show()
			listJ = selectedDrawingsJ.find('ul.drawing-list')
			listJ.empty()

			for item in R.selectedItems
				if item instanceof Item.Drawing
					@createSelectionLi(selectedDrawingsJ, listJ, item)

			return

		showLoadAnimation: ()=>
			@drawingPanelJ.find('.loading-animation').show()
			@drawingPanelJ.find('.content').hide()
			@drawingPanelJ.find('.selected-drawings').hide()
			return

		showContent: ()=>
			@drawingPanelJ.find('.content').show()
			@drawingPanelJ.find('.selected-drawings').hide()
			@drawingPanelJ.find('.loading-animation').hide()
			return

		showSubmitDrawing: ()->
			@hideBeginDrawing()
			@submitDrawingBtnJ.removeClass('hidden')
			@submitDrawingBtnJ.show()
			# @cancelDrawingBtnJ.removeClass('hidden')
			# @cancelDrawingBtnJ.show()
			@contentJ.find('#drawing-title').focus()
			return

		hideSubmitDrawing: ()->
			@submitDrawingBtnJ.hide()
			# @cancelDrawingBtnJ.hide()
			return

		showBeginDrawing: ()->
			# @hideSubmitDrawing()
			@beginDrawingBtnJ.show()
			return

		hideBeginDrawing: ()->
			@beginDrawingBtnJ.hide()
			return

		beginDrawingClicked: ()=>
			R.toolManager.enterDrawingMode()
			@beginDrawingBtnJ.hide()

			# if there are already some draft paths: directly show submit button
			for id, item of R.items
				if item instanceof Item.Path
					if item.owner == R.me and item.drawingId == null
						@showSubmitDrawing()
						return
			return

		getDrawingImage: (drawing)->
			if not drawing.raster?
				drawing.rasterize()

			image = new Image()
			image.src = drawing.raster.toDataURL()

			return image

		setDrawingThumbnail: ()->
			@currentDrawing.rasterize()
			R.rasterizer.rasterize(@currentDrawing, false)

			thumbnailJ = @contentJ.find('.drawing-thumbnail')
			thumbnailJ.empty().append(@getDrawingImage(@currentDrawing))
			return

		createDrawingFromItems: (items)->

			drawingId = Utils.createId()

			for item in items
				if item instanceof Item.Path
					item.drawingId = drawingId


			title = @contentJ.find('#drawing-title').val()
			description = @contentJ.find('#drawing-description').val()
			@currentDrawing = new Item.Drawing(null, null, drawingId, null, R.me, Date.now(), title, description, 'pending')
			
			@setDrawingThumbnail()

			R.view.fitRectangle(@currentDrawing.rectangle, true)

			return

		submitDrawingClickedCallback: (results)=>
			@submitBtnJ.find('span.glyphicon').removeClass('glyphicon-refresh glyphicon-refresh-animate').addClass('glyphicon-ok')

			if not R.loader.checkError(results) then return
			itemsToLoad = []
			itemIds = []
			# parse items and remove them if they are on stage (they must be updated)
			for i in results.items
				item = JSON.parse(i)
				itemIds.push(item.clientId)
				if not R.items[item.clientId]?
					itemsToLoad.push(item)

			R.loader.createNewItems(itemsToLoad)

			items = []
			for id in itemIds
				items.push(R.items[id])

			@createDrawingFromItems(items)

			return

		submitDrawingClicked: ()=>
			R.toolManager.leaveDrawingMode(true)
			@submitDrawingBtnJ.hide()
			@drawingPanelTitleJ.text('Create drawing')
			# @showBeginDrawing()
			@open()
			@showContent()
			@currentDrawing = null
			@contentJ.find('.read').hide()
			@contentJ.find('.modify').show()
			@contentJ.find('#drawing-title').val('')
			@contentJ.find('#drawing-description').val('')
			@submitBtnJ.show()
			@modifyBtnJ.hide()
			@cancelBtnJ.show()
			@votesJ.hide()

			@currentDrawing = null

			if R.selectedItems.length == 0
				@submitBtnJ.find('span.glyphicon').removeClass('glyphicon-ok').addClass('glyphicon-refresh glyphicon-refresh-animate')
				$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'getDrafts', args: {} } ).done(@submitDrawingClickedCallback)
				return

			@createDrawingFromItems(R.selectedItems)
			return

		# cancelDrawingClicked: ()=>
		# 	# @showBeginDrawing()
		# 	if R.toolManager.drawingMode
		# 		R.toolManager.leaveDrawingMode()
		# 		@cancelDrawing()
		# 	return

		setDrawing: (@currentDrawing, drawingData)->
			@drawingPanelTitleJ.text('Drawing info')
			@open()
			@showContent()
			
			latestDrawing = JSON.parse(drawingData.drawing)

			@currentDrawing.votes = drawingData.votes
			@currentDrawing.status = latestDrawing.status

			@submitBtnJ.hide()
			@modifyBtnJ.hide()
			@cancelBtnJ.hide()

			if @currentDrawing.owner == R.me || R.administrator
				@contentJ.find('.read').hide()
				@contentJ.find('.modify').show()
				@contentJ.find('#drawing-title').val(@currentDrawing.title)
				@contentJ.find('#drawing-description').val(@currentDrawing.description)
				
				if latestDrawing.status == 'pending'
					@modifyBtnJ.show()
					@cancelBtnJ.show()
			else
				@contentJ.find('.read').show()
				@contentJ.find('.modify').hide()
				@contentJ.find('.title').html(@currentDrawing.title)
				@contentJ.find('.description').html(@currentDrawing.description)
				@contentJ.find('.author').html(@currentDrawing.owner)

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

			if nPositiveVotes > 0 then positiveVoteListJ.removeClass('hidden') else positiveVoteListJ.addClass('hidden')
			if nNegativeVotes > 0 then negativeVoteListJ.removeClass('hidden') else negativeVoteListJ.addClass('hidden')

			@votesJ.find('.n-votes.positive').html(nPositiveVotes)
			@votesJ.find('.n-votes.negative').html(nNegativeVotes)
			nVotes = nPositiveVotes+nNegativeVotes
			@votesJ.find('.n-votes.total').html(nVotes)
			@votesJ.find('.percentage-votes').html(if nVotes > 0 then 100*nPositiveVotes/nVotes else 0)

			# load missing paths
			pathsToLoad = []
			for p in drawingData.paths
				path = JSON.parse(p)
				if not R.items[path.clientId]
					pathsToLoad.push(path)

			R.loader.createNewItems(pathsToLoad)

			@setDrawingThumbnail()
			return

		### votes ###

		hasAlreadyVoted: ()->
			for vote in @currentDrawing.votes
				if vote.vote.author == R.me
					return true
			return false

		voteCallback: (result)=>
			if not R.loader.checkError(result) then return

			@currentDrawing.updateDrawingPanel()

			if result.cancelled 
				R.alertManager.alert 'Your vote was successfully cancelled', 'success'
				return

			suffix = ''
			if result.validates
				suffix = ', the drawing will be validated in a minute if nobody cancels its vote!'
			else if result.rejects
				suffix = ', the drawing will be rejected in a minute if nobody cancels its vote!'

			R.alertManager.alert 'You successfully voted' + suffix, 'success'

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
			
			title = @contentJ.find('#drawing-title').val()
			description = @contentJ.find('#drawing-description').val()
			
			if title.length == 0
				R.alertManager.alert "You must enter a title.", "error"
				return

			if description.length == 0
				R.alertManager.alert "You must enter a description.", "error"
				return

			@currentDrawing.title = title
			@currentDrawing.description = description

			@currentDrawing.save()
			@close(false)

			return

		modifyDrawing: ()=>

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to modify a drawing.", "error"
				return

			if not @currentDrawing?
				R.alertManager.alert "You must select a drawing first.", "error"
				return

			if @currentDrawing.status != 'pending'
				R.alertManager.alert "The drawing is already validated, it cannot be modified anymore.", "error"
				return				

			@currentDrawing.update( { title: @contentJ.find('#drawing-title').val(), data: @contentJ.find('#drawing-description').val() } )
			
			return

		cancelDrawing: ()=>

			if not @currentDrawing?
				@close()
				return

			if not @currentDrawing.pk?
				@close()
				return

			if @currentDrawing.status != 'pending'
				R.alertManager.alert "The drawing is already validated, it cannot be cancelled anymore.", "error"
				return	

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to cancel a drawing.", "error"
				return

			@currentDrawing.deleteCommand()
			@close()
			return

	return DrawingPanel
