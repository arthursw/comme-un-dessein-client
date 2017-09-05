define ['paper', 'R', 'Utils/Utils', 'Items/Item', 'UI/Modal', 'Commands/Command', 'i18next', 'moment' ], (P, R, Utils, Item, Modal, Command, i18next, moment) -> 			# 'ace/ext-language_tools', required?

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
			@deleteBtnJ = @drawingPanelJ.find('.action-buttons button.delete')

			@submitBtnJ.click(@submitDrawing)
			@modifyBtnJ.click(@modifyDrawing)
			@cancelBtnJ.click(@cancelDrawing)
			@deleteBtnJ.click(@deleteDrawing)

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
			# $("body").css( 'user-select': 'none' )
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
			# $("body").css('user-select': 'text')
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

			else if R.selectedItems.length > 0
				@showSelectedDrawings()

				@open()

			return

		selectionChanged: ()->
			Utils.callNextFrame(@updateSelection, 'update drawing selection')
			return

		deselectDrawing: (drawing)->
			if R.selectedItems.length == 0
				@close()
			if drawing == @currentDrawing
				@currentDrawing = null
			return

		### open close ###

		isOpened: ()->
			return @drawingPanelJ.hasClass('visible')

		open: ()->
			@drawingPanelJ.show()
			@drawingPanelJ.addClass('visible')
			return

		close: (removeDrawingIfNotSaved=true)=>
			if @currentDrawing? and not @currentDrawing.pk?
				if removeDrawingIfNotSaved
					@showSubmitDrawing()
					@currentDrawing.removeChildren()
					@currentDrawing.remove()
					

				# @showBeginDrawing()
			@drawingPanelJ.hide()
			@drawingPanelJ.removeClass('visible')
			if R.selectedItems.length > 0
				@currentDrawing = null
				R.tools.select.deselectAll()
			return

		### set drawing ###
		
		createSelectionLi: (selectedDrawingsJ, listJ, item)->
			liJ = $('<li>')
			liJ.addClass('drawing-selection cd-button')
			liJ.addClass('cd-row')

			contentJ = $('<div>')
			contentJ.addClass('cd-column cd-grow')

			titleJ = $('<h4>')
			titleJ.addClass('cd-grow cd-center')
			titleJ.html(item.title)

			thumbnailJ = $('<div>')
			thumbnailJ.addClass('thumbnail drawing-thumbnail')
			thumbnailJ.append(@getDrawingImage(item))
			
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
			
			contentJ.append(titleJ)
			contentJ.append(thumbnailJ)

			liJ.append(contentJ)

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
			@drawingPanelTitleJ.attr('data-i18n', 'Select a single drawing').text(i18next.t('Select a single drawing'))

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
			
			# @submitDrawingBtnJ.removeClass('hidden')
			# @submitDrawingBtnJ.show()
			
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

			image = new Image()
			raster = drawing.getRaster()
			if raster?
				image.src = raster.toDataURL()
				return image
			else
				return $('<span>').addClass('badge label-default').attr('data-i18n', 'No path loaded').text(i18next.t('No path loaded'))

		setDrawingThumbnail: ()->
			# @currentDrawing.rasterize()
			# R.rasterizer.rasterize(@currentDrawing, false)

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

			R.rasterizer.rasterizeRectangle(@currentDrawing.rectangle)

			R.view.fitRectangle(@currentDrawing.rectangle, true)

			@setDrawingThumbnail()

			@currentDrawing.select(true, false) # Important to deselect (for example when selecting a tool) and close the drawing panel
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

			if itemIds.length == 0
				R.alertManager.alert 'You must draw something before submitting', 'error'
				@close()
				return

			if R.Tools.Path.draftIsTooBig(items)
				R.Tools.Path.displayDraftIsTooBigError()
				@close()
				return

			@createDrawingFromItems(items)

			R.commandManager.clearHistory()

			return

		checkPathToSubmit: ()->
			for id, item of R.items
				if item instanceof Item.Path and item.owner == R.me and item.group.parent == R.view.mainLayer
					return true
			return false

		submitDrawingClicked: ()=>
			# if not @checkPathToSubmit()
			# 	R.alertManager.alert 'You must draw something before submitting', 'error'
			# 	return
			R.tools.select.deselectAll()

			R.toolManager.leaveDrawingMode(true)
			# @submitDrawingBtnJ.hide()
			@drawingPanelTitleJ.attr('data-i18n', 'Create drawing').text(i18next.t('Create drawing'))
			# @showBeginDrawing()
			@open()
			@showContent()
			@currentDrawing = null

			@contentJ.find('#drawing-author').val(R.me)
			@contentJ.find('#drawing-title').val('')
			@contentJ.find('#drawing-description').val('')
			@submitBtnJ.show()
			@modifyBtnJ.hide()
			@cancelBtnJ.show()
			@cancelBtnJ.find('span.text').attr('data-i18n', 'Cancel').text(i18next.t('Cancel'))
			@deleteBtnJ.show()

			@contentJ.find('#drawing-title').removeAttr('readonly')
			@contentJ.find('#drawing-description').removeAttr('readonly')

			@votesJ.hide()

			@currentDrawing = null
			@submitBtnJ.find('span.glyphicon').removeClass('glyphicon-ok').addClass('glyphicon-refresh glyphicon-refresh-animate')
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'getDrafts', args: { city: R.city } } ).done(@submitDrawingClickedCallback)

			return

		# cancelDrawingClicked: ()=>
		# 	# @showBeginDrawing()
		# 	if R.toolManager.drawingMode
		# 		R.toolManager.leaveDrawingMode()
		# 		@cancelDrawing()
		# 	return

		setVotes: ()->

			@votesJ.show()
			@voteUpBtnJ.removeClass('voted')
			@voteDownBtnJ.removeClass('voted')
			positiveVoteListJ = @drawingPanelJ.find('.vote-list.positive')
			negativeVoteListJ = @drawingPanelJ.find('.vote-list.negative')
			positiveVoteListJ.empty()
			negativeVoteListJ.empty()
			nPositiveVotes = 0
			nNegativeVotes = 0
			for vote in @currentDrawing.votes
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
			
			@votesJ.find('.status').html(@currentDrawing.status)

			@voteUpBtnJ.removeClass('disabled')
			@voteDownBtnJ.removeClass('disabled')
			if @currentDrawing.owner == R.me || R.administrator
				if @currentDrawing.status == 'pending'
					@voteUpBtnJ.removeClass('disabled')
					@voteDownBtnJ.removeClass('disabled')

			return

		setDrawing: (@currentDrawing, drawingData)->
			@drawingPanelTitleJ.attr('data-i18n', 'Drawing info').text(i18next.t('Drawing info'))
			@open()
			@showContent()
			
			latestDrawing = JSON.parse(drawingData.drawing)

			@currentDrawing.votes = drawingData.votes
			@currentDrawing.status = latestDrawing.status

			@submitBtnJ.hide()
			@modifyBtnJ.hide()
			@cancelBtnJ.hide()
			@deleteBtnJ.hide()

			@contentJ.find('#drawing-author').val(@currentDrawing.owner)
			@contentJ.find('#drawing-title').val(@currentDrawing.title)
			@contentJ.find('#drawing-description').val(@currentDrawing.description)

			if @currentDrawing.owner == R.me || R.administrator
				if latestDrawing.status == 'pending'
					@modifyBtnJ.show()
					@cancelBtnJ.show()
					@cancelBtnJ.find('span.text').attr('data-i18n', 'Cancel vote').text(i18next.t('Cancel vote'))
				@contentJ.find('#drawing-title').removeAttr('readonly')
				@contentJ.find('#drawing-description').removeAttr('readonly')
			else
				@contentJ.find('#drawing-title').attr('readonly', true)
				@contentJ.find('#drawing-description').attr('readonly', true)


			@setVotes()

			# load missing paths
			pathsToLoad = []
			for p in drawingData.paths
				path = JSON.parse(p)
				if not R.items[path.clientId]
					pathsToLoad.push(path)

			R.loader.createNewItems(pathsToLoad)

			@setDrawingThumbnail()
			return

		onDrawingChange: (data)->

			switch data.type
				when 'votes'
					drawing = R.items[data.drawingId]
					if drawing?
						drawing.votes = data.votes
						if @currentDrawing == drawing
							@setVotes()
				when 'new'
					# ok if both are undefined: corresponds to CommeUnDessein
					if data.city.name != R.city.name then return
					args = {
						itemsToLoad: [
							{
								itemType: 'Drawing'
								pks: [data.pk]
							},
							{
								itemType: 'Path'
								pks: data.pathPks
							}
						]
					}
					$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadItems', args: args } ).done((results)->
						R.loader.loadCallback(results, true)
						return)
				when 'description'
					drawing = R.items[data.drawingId]
					if drawing?
						drawing.title = data.title
						drawing.description = data.description
						if @currentDrawing == drawing
							@contentJ.find('#drawing-title').val(data.title)
							@contentJ.find('#drawing-description').val(data.description)
				when 'status'
					drawing = R.items[data.drawingId]
					if drawing?
						drawing.updateStatus(data.status)
				when 'delete'
					drawing = R.items[data.drawingId]
					if drawing?
						drawing.remove()
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

			@currentDrawing.votes = result.votes
			
			delay = moment.duration(result.delay, 'seconds').humanize()

			suffix = ''
			if result.validates
				suffix = ', the drawing will be validated'

			else if result.rejects
				suffix = ', the drawing will be rejected'

			R.alertManager.alert 'You successfully voted' + suffix, 'success', null, {duration: delay}

			R.socket.emit "drawing change", type: 'votes', votes: @currentDrawing.votes, drawingId: @currentDrawing.id
			return

		vote: (positive)=>
			if @currentDrawing.owner == R.me
				R.alertManager.alert 'You cannot vote for your own drawing', 'error'
				return
			
			if @currentDrawing.status != 'pending'
				R.alertManager.alert 'The drawing is already validated', 'error'
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
				R.alertManager.alert "You must be logged in to submit a drawing", "error"
				return
			
			title = @contentJ.find('#drawing-title').val()
			description = @contentJ.find('#drawing-description').val()
			
			if title.length == 0
				R.alertManager.alert "You must enter a title", "error"
				return

			if description.length == 0
				R.alertManager.alert "You must enter a description", "error"
				return

			@currentDrawing.title = title
			@currentDrawing.description = description

			@currentDrawing.save()
			@close(false)

			return

		modifyDrawing: ()=>

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to modify a drawing", "error"
				return

			if not @currentDrawing?
				R.alertManager.alert "You must select a drawing first", "error"
				return

			if @currentDrawing.status != 'pending'
				R.alertManager.alert "The drawing is already validated, it cannot be modified anymore", "error"
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
				R.alertManager.alert "The drawing is already validated, it cannot be cancelled anymore", "error"
				return	

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to cancel a drawing", "error"
				return

			@currentDrawing.deleteCommand()
			@close()
			return

		deleteGivenPaths: (paths)->
			pathsToDelete = []
			pathsToDeleteResurectors = {}

			for path in paths
				if path.pk?
					pathsToDelete.push(path)
					pathsToDeleteResurectors[path.id] = data: path.getDuplicateData(), constructor: path.constructor
				else
					path.remove()

			if pathsToDelete.length > 0
				deleteCommand = new Command.DeleteItems(pathsToDelete, pathsToDeleteResurectors)
				R.commandManager.add(deleteCommand, true)
			return

		deletePaths: ()=>
			paths = @currentDrawing.paths.slice()
			@currentDrawing.removeChildren()
			@currentDrawing.remove()

			@deleteGivenPaths(paths)
			return

		deleteDrawing: ()=>

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to delete a drawing", "error"
				return

			if not @currentDrawing?
				@close()
				return

			if @currentDrawing.pk?
				R.alertManager.alert "Please cancel the drawing before deleting its paths", "error"
				@close()
				return

			modal = Modal.createModal( title: 'Delete all paths', submit: @deletePaths, postSubmit: 'hide' )
			modal.addText('Do you really want to delete the selected paths?')
			modal.show()

			return

	return DrawingPanel
