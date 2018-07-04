define ['paper', 'R', 'Utils/Utils', 'Items/Item', 'UI/Modal', 'Commands/Command', 'i18next', 'moment'], (P, R, Utils, Item, Modal, Command, i18next, moment) -> 			# 'ace/ext-language_tools', required?

	class DrawingPanel

		constructor: ()->
			@status = 'closed'

			@drawingPanelJ = $("#drawingPanel")

			@openBtnJ = $('#drawing-panel-handle')
			
			@openBtnJ.click (event)=>
				if @drawingPanelJ.hasClass('opened')
					@close()
				else
					@setGeneralInformation()
				return

			@contentJ = @drawingPanelJ.find('.content-container')

			@contentJ.find('.report-abuse').click @reportAbuse

			@contentJ.find('.copy-link').click @copyLink

			@contentJ.find('.share-facebook').click @shareOnFacebook

			@contentJ.find('button.share-twitter').click @shareOnTwitter

			@startDiscussionBtnJ = @contentJ.find('button.start-discussion')

			@startDiscussionBtnJ.click ()=> @startDiscussion()

			@contentJ.find('.share-buttons button').popover()

			# the button to start drawing
			@beginDrawingBtnJ = $('button.begin-drawing')
			@beginDrawingBtnJ.click(@beginDrawingClicked)


			# the button to open the panel
			@submitDrawingBtnJ = $('button.submit-drawing')
			@submitDrawingBtnJ.click(@submitDrawingClicked)

			# @cancelDrawingBtnJ = $('button.cancel-drawing')
			# @cancelDrawingBtnJ.click(@cancelDrawingClicked)

			# editor
			@drawingPanelJ.bind "transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd", @resize

			@thumbnailFooterTitle = @drawingPanelJ.find(".thumbnail-footer .title")
			@thumbnailFooterAuthor = @drawingPanelJ.find(".thumbnail-footer .author")

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
			closeBtnJ.click ()=>
				fromGeneralInformation = @fromGeneralInformation
				@close()
				if fromGeneralInformation
					@setGeneralInformation()

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
			# @deleteBtnJ = @drawingPanelJ.find('.action-buttons button.delete')

			@submitBtnJ.click(@submitDrawing)
			@modifyBtnJ.click(@modifyDrawing)
			@cancelBtnJ.click(@cancelDrawing)
			# @deleteBtnJ.click(@deleteDrawing)
			
			@opened = false

			titleJ = @contentJ.find('#drawing-title')
			
			onSubmitUp = (event)=>
				if Utils.specialKeys[event.keyCode] == 'enter'
					@submitDrawing()
					event.preventDefault()
					event.stopPropagation()
					return -1
				return

			onSubmitDown = (event)=>
				if Utils.specialKeys[event.keyCode] == 'enter'
					event.preventDefault()
					event.stopPropagation()
					return -1
				return

			titleJ.keydown(onSubmitDown).keyup(onSubmitUp)

			@contentJ.find('.comments-container .comment-area').keydown (event)=>
				if Utils.specialKeys[event.keyCode] == 'enter' and not (event.shiftKey or event.metaKey or event.ctrlKey)
					@submitComment()
					event.preventDefault()
					event.stopPropagation()
					return -1
				return
			@contentJ.find('.comments-container .submit-comment').click @submitComment

			if R.administrator
				adminJ = @contentJ.find('.admin-buttons')
				# adminJ.removeClass('hidden').show()
				adminJ.find('button.delete-drawing').click (event)=>
					modal = Modal.createModal( 
						id: 'delete-drawing',
						title: 'Delete drawing', 
						submit: ( ()=> 
							R.deleteDrawing(R.s.pk, 'confirm')
							return),
						submitButtonText: 'Delete drawing', 
						submitButtonIcon: 'glyphicon-trash',
						)
				
					modal.addText('Are you sure you really want to delete the drawing')
					modal.addText('There is no way to undo this action')
					modal.modalJ.find('[name="submit"]').addClass('btn-danger').removeClass('btn-primary')
					modal.show()
					return

			# @close()
			return

		startDiscussion: (id=null)=>
			id ?= @startDiscussionBtnJ.attr('data-discussion-id')
			if id.length > 0
				window.location.href = 'http://discussion.commeundessein.co/t/' + id
			return

		reportAbuse: ()=>
			if @currentDrawing?
				if @currentDrawing.status == 'flagged' and R.administrator
					$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'cancelAbuse', args: {pk:@currentDrawing.pk} } ).done((results)=>
						if not R.loader.checkError(results) then return
						R.alertManager.alert 'The report was successfully cancelled', 'success'
						return)

				modal = Modal.createModal( 
					id: 'report-abuse',
					title: 'Report abuse', 
					submit: ( ()=> 
						$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'reportAbuse', args: {pk:@currentDrawing.pk} } ).done((results)=>
							if not R.loader.checkError(results) then return
							R.alertManager.alert 'Your report was taken into account', 'success'
							return)
						return),
					submitButtonText: 'Report abuse', 
					submitButtonIcon: 'glyphicon-flag',
					# cancelButtonText: 'Just visit', 
					# cancelButtonIcon: 'glyphicon-sunglasses',
					)
			
				modal.addText('You are about to report an abuse')
				modal.addText('The drawing will be hidden and checked by a moderator')
				modal.addText('Make sure the drawing is really inappropiate, false reports can lead to suspension of account')
				modal.addText(null, 'If you are unsure about what to do plase send an email to idlv', false, {mail: 'idlv.contact@gmail.com'})
				modal.modalJ.find('[name="submit"]').addClass('btn-danger').removeClass('btn-primary')
				modal.show()
			return

		copyLink: ()=>
			textArea = document.createElement('textarea')
			#
			# *** This styling is an extra step which is likely not required. ***
			#
			# Why is it here? To ensure:
			# 1. the element is able to have focus and selection.
			# 2. if element was to flash render it has minimal visual impact.
			# 3. less flakyness with selection and copying which **might** occur if
			#    the textarea element is not visible.
			#
			# The likelihood is the element won't even render, not even a flash,
			# so some of these are just precautions. However in IE the element
			# is visible whilst the popup box asking the user for permission for
			# the web page to copy to the clipboard.
			#
			# Place in top-left corner of screen regardless of scroll position.
			textArea.style.position = 'fixed'
			textArea.style.top = 0
			textArea.style.left = 0
			# Ensure it has a small width and height. Setting to 1px / 1em
			# doesn't work as this gives a negative w/h on some browsers.
			textArea.style.width = '2em'
			textArea.style.height = '2em'
			# We don't need padding, reducing the size if it does flash render.
			textArea.style.padding = 0
			# Clean up any borders.
			textArea.style.border = 'none'
			textArea.style.outline = 'none'
			textArea.style.boxShadow = 'none'
			# Avoid flash of white box if rendered for any reason.
			textArea.style.background = 'transparent'
			textArea.value = @getDrawingLink()
			document.body.appendChild textArea
			textArea.select()

			try
				successful = document.execCommand('copy')
				msg = if successful then 'successful' else 'unsuccessful'
				console.log 'Copying text command was ' + msg
				R.alertManager.alert 'The drawing link was successfully copied to the clipboard', 'success'
			catch err
				console.log 'Oops, unable to copy'
				R.alertManager.alert 'An error occured while copying the drawing link to the clipboard', 'error'

			document.body.removeChild textArea

			return

		submitComment: ()=>
			commentAreaJ = @contentJ.find('.comments-container .comment-area')
			comment = commentAreaJ.get(0).innerText
			if comment.length == 0
				return
			commentAreaJ.get(0).innerText = ''

			args = {
				drawingPk: @currentDrawing.pk
				comment: comment
				date: Date.now()
			}

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'addComment', args: args } ).done((results)=>
				if not R.loader.checkError(results) then return
				c = JSON.parse(results.comment)
				lastId = @addComment(comment, results.commentPk, results.author, c.date.$date)
				
				if not results.emailConfirmed
					modal = Modal.createModal( 
						id: 'vote-feedback',
						title: 'Your comment was received' )
				
					modal.addText('Your comment was successfully received, but you must confirm your email before it is taken into account')
					modal.addText('You received an email to activate your account')
					modal.addText('If you have troubles confirming your account, please email us')
					modal.show()
				else
					R.socket.emit "drawing change", { type: 'addComment', comment: comment, commentPk: results.commentPk, author: results.author, date: c.date.$date, drawingPk: c.drawing.$oid, insertAfter: lastId }
				return)
			return

		addComment: (comment, commentPk, author, date, insertAfter=null, emailConfirmed)->
			divJ = $('<div>').addClass('cd-column cd-grow comment')
			divJ.attr('id', 'comment-'+commentPk)
			headerJ = $('<div>')
			headerJ.addClass('cd-row comment-header').addClass('cd-row cd-grow')
			headerJ.append($('<span>').addClass('author').text(author))
			headerJ.append($('<span>').addClass('date').text(' - ' + moment(date).format('l - LT')))
			if author == R.me or R.administrator
				buttonsJ = $('<div>').addClass('cd-row cd-grow cd-end edit-buttons')

				editBtnJ = $('<button>')
				editBtnJ.addClass('btn btn-default icon-only transparent')
				editIconJ = $('<span>').addClass('glyphicon glyphicon-pencil')

				editBtnJ.click (event)=>
					@exitCommentEditMode(@currentCommentPk)
					@editComment(commentPk)
					event.preventDefault()
					event.stopPropagation()
					return -1
				editBtnJ.append(editIconJ)
				buttonsJ.append(editBtnJ)

				deleteBtnJ = $('<button>')
				deleteBtnJ.addClass('btn btn-default icon-only transparent')
				deleteIconJ = $('<span>').addClass('glyphicon glyphicon-remove')

				deleteBtnJ.click (event)=>
					@deleteComment(commentPk)
					event.preventDefault()
					event.stopPropagation()
					return -1
				deleteBtnJ.append(deleteIconJ)
				buttonsJ.append(deleteBtnJ)
				headerJ.append(buttonsJ)

			divJ.append(headerJ)
			textJ = $('<div>').addClass('cd-grow comment-text')
			textJ.get(0).innerText = comment
			divJ.append(textJ)
			lastId = @contentJ.find('.comments-container .comments .comment:last-child').attr('id')
			if not emailConfirmed
				textJ.addClass('btn-danger')
			if insertAfter?
				divJ.insertAfter(@contentJ.find('#'+insertAfter))
			else
				@contentJ.find('.comments-container .comments').append(divJ)
			return lastId

		emptyComments: ()->
			@contentJ.find('.comments-container .comments').empty()
			return

		addComments: (comments)->
			for comment in comments
				c = JSON.parse(comment.comment)
				author = comment.author
				authorPk = comment.authorPk
				if comment.emailConfirmed or R.administrator
					@addComment(c.text, c._id.$oid, author, c.date.$date, null, comment.emailConfirmed)
			return

		deleteComment: (commentPk)->
			@contentJ.find('.comments-container #comment-'+commentPk).remove()
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'deleteComment', args: {commentPk: commentPk} } ).done((results)->
				if not R.loader.checkError(results) then return
				R.socket.emit "drawing change", { type: 'deleteComment', commentPk: results.commentPk, drawingPk: results.drawingPk }
				return)
			return

		exitCommentEditMode: (commentPk)->
			if not commentPk? then return
			@currentCommentPk = null
			commentJ = @contentJ.find('.comments-container #comment-'+commentPk)
			commentJ.find('.comment-buttons').remove()
			commentJ.find('.edit-buttons').show()
			textJ = commentJ.find('.comment-text')
			textJ.removeAttr('contenteditable')
			return

		validateCommentEdit: (commentPk)->
			commentJ = @contentJ.find('.comments-container #comment-'+commentPk)
			comment = commentJ.find('.comment-text').get(0).innerText
			@exitCommentEditMode(commentPk)
			
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'modifyComment', args: {commentPk: commentPk, comment: comment} } ).done((results)->
				if not R.loader.checkError(results) then return
				R.socket.emit "drawing change", { type: 'modifyComment', comment: comment, commentPk: results.commentPk, drawingPk: results.drawingPk }
				return)
			return

		editComment: (commentPk)->
			@currentCommentPk = commentPk
			commentJ = @contentJ.find('.comments-container #comment-'+commentPk)
			commentJ.find('.edit-buttons').hide()
			textJ = commentJ.find('.comment-text')
			initialComment = textJ.get(0).innerText
			textJ.attr('contenteditable', 'true')

			editButtonsJ = $('<div>').addClass('comment-buttons cd-row cd-end')

			okBtnJ = $('<button>').addClass('comment-button').attr('data-i18n', 'Modify comment').text(i18next.t('Modify comment'))
			okBtnJ.addClass('btn btn-default')
			okBtnJ.click (event)=> 
				@validateCommentEdit(commentPk)
				return

			cancelBtnJ = $('<button>').addClass('comment-button').attr('data-i18n', 'Cancel').text(i18next.t('Cancel'))
			cancelBtnJ.addClass('btn btn-default')
			cancelBtnJ.click (event)=> 
				commentJ.find('.comment-text').get(0).innerText = initialComment
				@exitCommentEditMode(commentPk)
				return

			editButtonsJ.append(cancelBtnJ)
			editButtonsJ.append(okBtnJ)
			commentJ.append(editButtonsJ)

			textJ.focus().select().keydown (event)=>
				if Utils.specialKeys[event.keyCode] == 'enter' and not (event.shiftKey or event.metaKey or event.ctrlKey)
					@validateCommentEdit(commentPk)
					event.preventDefault()
					event.stopPropagation()
					return -1
				return

			textJ.on('blur', (event)=>
				@exitCommentEditMode(commentPk)
				return)
			return

		getDrawingLink: (drawing=@currentDrawing)->
			cityName = if R.city?.name? then '/' + R.city.name else ''
			return location.origin + cityName + '/drawing-' + drawing.pk

		shareOnFacebook: (event, drawing=@currentDrawing)=>
			# FB.init({
			# 	appId      : '263330707483013',
			# 	version    : 'v2.10'
			# })
			
			# FB.getLoginStatus((response) =>
			# 	if response.status == "connected"
			# 		bounds = drawing.getBounds()
			# 		if bounds?
			# 			R.view.fitRectangle(bounds, true)
			# 			R.view.updateHash()

			# 		FB.ui({
			# 			method: 'feed',
			# 			caption: i18next.t('Vote for this drawing on Comme un Dessein', { drawing: drawing.title, author: drawing.owner }),
			# 			link: location.origin + '/drawing-' + drawing.pk,
			# 			mobile_iframe: true
			# 		}, ((response)-> 
			# 			console.log(response)
			# 			return
			# 		))
			# )

			facebookURL = @getDrawingLink(drawing)
			facebookLink = 'https://www.facebook.com/sharer/sharer.php?u=' + facebookURL
			window.open(facebookLink, 'popup', 'width=600, height=400')

			return

		shareOnTwitter: (event, drawing=@currentDrawing)=>
			twitterText = '' + drawing.title + ' ' + i18next.t('by') + ' ' + drawing.owner + ', ' + i18next.t('on') + ' Comme un Dessein'
			twitterURL = @getDrawingLink(drawing)
			twitterHashTags = 'CommeUnDessein,idlv,Maintenant2017'
			twitterLink = 'http://twitter.com/share?text=' + twitterText + '&url=' + twitterURL + '&hashtags=' + twitterHashTags
			window.open(twitterLink, 'popup', 'width=600, height=400')
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

		onWindowResize: ()->
			width = @drawingPanelJ.outerWidth()
			height = @drawingPanelJ.outerHeight()
			if width > height and @status != 'information'
				@drawingPanelJ.find('.cd-column-row').addClass('cd-row').removeClass('cd-column')
			else
				@drawingPanelJ.find('.cd-column-row').addClass('cd-column').removeClass('cd-row')

			@resizeGeneralInformation()
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

				if R.selectedItems[0].status == 'draft'
					@submitDrawingClicked()
					return

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
			return @drawingPanelJ.hasClass('opened')

		open: ()->
			@contentJ.find('.delete-drawing').show()
			$('#submit-drawing-button').addClass('drawingPanel')
			@drawingPanelJ.removeClass('general')
			# @contentJ.find('#drawing-panel-no-selection')
			@onWindowResize()
			# @drawingPanelJ.show()
			@drawingPanelJ.find('#drawing-panel-handle span').removeClass('glyphicon-chevron-left').addClass('glyphicon-chevron-right')
			@drawingPanelJ.addClass('opened')
			@opened = true

			R.toolManager.updateButtonsVisibility()
			return

		close: (removeDrawingIfNotSaved=true)=>
			@fromGeneralInformation = false
			$('#submit-drawing-button').removeClass('drawingPanel')
			@drawingPanelJ.removeClass('general')

			@generalInformation = false
			@drawingPanelJ.find('#drawing-panel-handle span').removeClass('glyphicon-chevron-right').addClass('glyphicon-chevron-left')
			# if @currentDrawing? and not @currentDrawing.pk?
			# 	if removeDrawingIfNotSaved
			# 		@showSubmitDrawing()
			# 		@currentDrawing.removeChildren()
			# 		@currentDrawing.remove()
					

				# @showBeginDrawing()
			# @drawingPanelJ.hide()
			@drawingPanelJ.removeClass('opened')
			@opened = false
			if R.selectedItems.length > 0
				@currentDrawing = null
				R.tools.select.deselectAll()


			R.toolManager.updateButtonsVisibility()
			return

		setGeneralInformation: ()=>
			previousStatus = @status
			@status = 'information'
			@generalInformation = true
			@drawingPanelTitleJ.attr('data-i18n', 'Drawings').text(i18next.t('Drawings'))
			@open()
			@drawingPanelJ.find('.loading-animation').hide()

			if previousStatus == 'select-drawing'
				@drawingPanelJ.find('.content-container').children().show()
				selectedDrawingsJ = @drawingPanelJ.find('.selected-drawings')
				selectedDrawingsJ.hide()

			@resizeGeneralInformation()

			@drawingPanelJ.addClass('general')

			return

		resizeGeneralInformation: ()=>
			if @status == 'information'
				height = @drawingPanelJ.innerHeight() - 350
				@contentJ.find('#drawing-panel-no-selection').show().siblings().hide()
				@contentJ.find('#drawing-panel-no-selection #RItems').height(height)
				# @contentJ.find('#drawing-panel-no-selection #RItems .cd-tree').height(height-200)
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
			svg = R.view.getThumbnail(item)
			svg.setAttribute('viewBox', '0 0 300 300')
			svg.setAttribute('width', '250')
			svg.setAttribute('height', '250')
			thumbnailJ.append(svg)
			
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
			@drawingPanelJ.removeClass('general')
			@status = 'select-drawing'
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
			@generalInformation = false
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
			# @hideBeginDrawing()
			
			# @submitDrawingBtnJ.removeClass('hidden')
			# @submitDrawingBtnJ.show()
			
			# @cancelDrawingBtnJ.removeClass('hidden')
			# @cancelDrawingBtnJ.show()
			# @contentJ.find('#drawing-title').focus()
			return

		hideSubmitDrawing: ()->
			# $('#submit-drawing-button').hide()
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
		
		setDrawingThumbnail: ()->
			thumbnailJ = @contentJ.find('.drawing-thumbnail')
			svg = R.view.getThumbnail(@currentDrawing)
			svg.setAttribute('viewBox', '0 0 300 300')
			svg.setAttribute('width', '250')
			svg.setAttribute('height', '250')
			thumbnailJ.empty().append(svg)
			return

		# createDrawingFromItems: (items)->

		# 	drawingId = Utils.createId()

		# 	for item in items
		# 		if item instanceof Item.Path
		# 			item.drawingId = drawingId


		# 	title = @contentJ.find('#drawing-title').val()
		# 	description = @contentJ.find('#drawing-description').val()
		# 	@currentDrawing = new Item.Drawing(null, null, drawingId, null, R.me, Date.now(), title, description, 'pending')

		# 	R.rasterizer.rasterizeRectangle(@currentDrawing.rectangle)

		# 	R.view.fitRectangle(@currentDrawing.rectangle, true)

		# 	@setDrawingThumbnail()

		# 	@currentDrawing.select(true, false) # Important to deselect (for example when selecting a tool) and close the drawing panel
		# 	return

		# submitDrawingClickedCallback: (results)=>
		# 	@submitBtnJ.find('span.glyphicon').removeClass('glyphicon-refresh glyphicon-refresh-animate').addClass('glyphicon-ok')

		# 	if not R.loader.checkError(results) then return

		# 	itemsToLoad = []
		# 	itemIds = []
		# 	# parse items and remove them if they are on stage (they must be updated)
		# 	for i in results.items
		# 		item = JSON.parse(i)
		# 		itemIds.push(item.clientId)
		# 		if not R.items[item.clientId]?
		# 			itemsToLoad.push(item)

		# 	R.loader.createNewItems(itemsToLoad)

		# 	items = []
		# 	for id in itemIds
		# 		items.push(R.items[id])

		# 	if itemIds.length == 0
		# 		R.alertManager.alert 'You must draw something before submitting', 'error'
		# 		@close()
		# 		return

		# 	if R.Tools.Path.draftIsTooBig(items)
		# 		R.Tools.Path.displayDraftIsTooBigError()
		# 		@close()
		# 		return

		# 	@createDrawingFromItems(items)

		# 	R.commandManager.clearHistory()

		# 	return

		checkPathToSubmit: ()->
			for id, item of R.items
				if item instanceof Item.Path and item.owner == R.me and item.group.parent == R.view.mainLayer
					return true
			return false

		submitDrawingClicked: ()=>
			draft = Item.Drawing.getDraft()
			if not draft? then return

			# Warning:  R.tools.select.deselectAll() and R.toolManager.leaveDrawingMode() can lead to @currentDrawing = null so set currentDrawing afterward
			R.tools.select.deselectAll()
			R.toolManager.leaveDrawingMode(true)

			# set currentDrawing after the two prevous functions
			@currentDrawing = draft

			# @submitDrawingBtnJ.hide()
			@drawingPanelTitleJ.attr('data-i18n', 'Create drawing').text(i18next.t('Create drawing'))

			# @showBeginDrawing()
			@contentJ.find('.comments-container').hide()
			@open()
			@showContent()

			@contentJ.find('.delete-drawing').hide()

			@contentJ.find('#drawing-panel-no-selection').hide().siblings().show()

			setTimeout (() => @contentJ.find('#drawing-title').focus() ), 200

			@contentJ.find('#drawing-author').val(R.me)
			@contentJ.find('.title-group').show()
			@contentJ.find('#drawing-title').val('')

			@thumbnailFooterAuthor.text(R.me)
			@thumbnailFooterTitle.text('')
			
			@contentJ.find('#drawing-description').val('')
			@submitBtnJ.show()
			@modifyBtnJ.hide()
			@cancelBtnJ.show()
			@cancelBtnJ.find('span.text').attr('data-i18n', 'Cancel').text(i18next.t('Cancel'))
			# @deleteBtnJ.show()

			@contentJ.find('#drawing-title').removeAttr('readonly')
			@contentJ.find('#drawing-description').removeAttr('readonly')

			@votesJ.hide()
			@contentJ.find('.share-buttons').hide()

			# @submitBtnJ.find('span.glyphicon').removeClass('glyphicon-ok').addClass('glyphicon-refresh glyphicon-refresh-animate')
			# $.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'getDrafts', args: { city: R.city } } ).done(@submitDrawingClickedCallback)

			bounds = @currentDrawing.getBounds()
			if bounds?
				R.view.fitRectangle(bounds, true)

			@setDrawingThumbnail()

			@currentDrawing.select(true, false) # Important to deselect (for example when selecting a tool) and close the drawing panel

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
			positiveVoteListJ = @drawingPanelJ.find('.vote-list ul.positive')
			negativeVoteListJ = @drawingPanelJ.find('.vote-list ul.negative')
			positiveVoteListJ.empty()
			negativeVoteListJ.empty()
			nPositiveVotes = 0
			nNegativeVotes = 0
			
			@voteUpBtnJ.find('span.text').attr('data-i18n', 'Vote up').text(i18next.t('Vote up'))
			@voteDownBtnJ.find('span.text').attr('data-i18n', 'Vote down').text(i18next.t('Vote down'))

			for vote in @currentDrawing.votes
				v = JSON.parse(vote.vote)
				# liJ = $('<li data-author-pk="'+vote.authorPk+'">'+vote.author+'</li>')
				if v.positive
					if vote.emailConfirmed
						nPositiveVotes++
					# positiveVoteListJ.append(liJ)
					if vote.author == R.me
						@voteUpBtnJ.find('span.text').attr('data-i18n', 'You voted up').text(i18next.t('You voted up'))
						@voteUpBtnJ.addClass('voted')
				else
					if vote.emailConfirmed
						nNegativeVotes++
					# negativeVoteListJ.append(liJ)
					if vote.author == R.me
						@voteDownBtnJ.find('span.text').attr('data-i18n', 'You voted down').text(i18next.t('You voted down'))
						@voteDownBtnJ.addClass('voted')


			@drawingPanelJ.find('.vote-list.positive').addClass('hidden')
			@drawingPanelJ.find('.vote-list.negative').addClass('hidden')
			
			# if nPositiveVotes > 0 then @drawingPanelJ.find('.vote-list.positive').removeClass('hidden') else @drawingPanelJ.find('.vote-list.positive').addClass('hidden')
			# if nNegativeVotes > 0 then @drawingPanelJ.find('.vote-list.negative').removeClass('hidden') else @drawingPanelJ.find('.vote-list.negative').addClass('hidden')

			@votesJ.find('.n-votes.positive').html(nPositiveVotes)
			@votesJ.find('.n-votes.negative').html(nNegativeVotes)
			nVotes = nPositiveVotes+nNegativeVotes
			@votesJ.find('.n-votes.total').html(nVotes)
			@votesJ.find('.percentage-votes').html((if nVotes > 0 then 100*nPositiveVotes/nVotes else 0).toFixed(0))
			
			@votesJ.find('.status').attr('data-i18n', @currentDrawing.status).html(i18next.t(@currentDrawing.status))

			@voteUpBtnJ.removeClass('disabled')
			@voteDownBtnJ.removeClass('disabled')
			if @currentDrawing.owner == R.me || R.administrator
				if @currentDrawing.status == 'pending' or @currentDrawing.status == 'emailNotConfirmed' or @currentDrawing.status == 'notConfirmed'
					@voteUpBtnJ.removeClass('disabled')
					@voteDownBtnJ.removeClass('disabled')

			return

		setDrawing: (@currentDrawing, drawingData)->
			@drawingPanelJ.removeClass('general')

			@status = 'drawing'
			@drawingPanelTitleJ.attr('data-i18n', 'Drawing info').text(i18next.t('Drawing info'))

			@open()
			@contentJ.find('#drawing-panel-no-selection').hide().siblings().show()
			@showContent()
			@contentJ.find('.share-buttons').show()

			if not R.me? or not _.isString(R.me) or R.me.length == 0
				@contentJ.find('.comments-container').hide()
			else
				@contentJ.find('.comments-container').show()

			latestDrawing = JSON.parse(drawingData.drawing)

			@currentDrawing.votes = drawingData.votes
			@currentDrawing.status = latestDrawing.status

			@submitBtnJ.hide()
			@modifyBtnJ.hide()
			@cancelBtnJ.hide()
			# @deleteBtnJ.hide()

			@contentJ.find('#drawing-author').val(@currentDrawing.owner)
			@contentJ.find('.title-group').hide()
			@contentJ.find('#drawing-title').val(@currentDrawing.title)
			
			@thumbnailFooterAuthor.text(@currentDrawing.owner)
			@thumbnailFooterTitle.text(@currentDrawing.title)

			@contentJ.find('#drawing-description').val(@currentDrawing.description)

			if @currentDrawing.owner == R.me || R.administrator
				if latestDrawing.status == 'pending' || latestDrawing.status == 'emailNotConfirmed' || latestDrawing.status == 'notConfirmed'
					@contentJ.find('.title-group').show()
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
			# pathsToLoad = []
			# for p in drawingData.paths
			# 	path = JSON.parse(p)
			# 	if not R.items[path.clientId]
			# 		pathsToLoad.push(path)

			# R.loader.createNewItems(pathsToLoad)

			@setDrawingThumbnail()

			@emptyComments()
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadComments', args: { drawingPk: @currentDrawing.pk } } ).done((results)=>
				if not R.loader.checkError(results) then return
				@addComments(results.comments)
				return)

			if latestDrawing.discussionId?
				@startDiscussionBtnJ.show()
				@startDiscussionBtnJ.attr('data-discussion-id', latestDrawing.discussionId)
			else
				@startDiscussionBtnJ.hide()

			# if @currentDrawing.title and @currentDrawing.pk and @currentDrawing.status != 'draft'
			# 	history.pushState('', 'Drawing ' + @currentDrawing.title, window.location.origin + '/drawing-' + @currentDrawing.pk)

			# window.DiscourseEmbed = { discourseUrl: 'http://discussion.commeundessein.co/', discourseEmbedUrl: @getDrawingLink() }

			# require [DiscourseEmbed.discourseUrl], (discourse)=>
			# 	console.log(discourse + 'javascripts/embed.js')
			# 	return

			# script = document.createElement('script')
			# script.type = 'text/javascript'
			# script.async = true
			# script.src = DiscourseEmbed.discourseUrl + 'javascripts/embed.js'
			# (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(script)

			if R.administrator
				if @currentDrawing.status == 'flagged'
					@contentJ.find('.report-abuse').removeClass('btn-danger').addClass('btn-success')
					@contentJ.find('.report-abuse').attr('data-content', i18next.t('Cancel report')).attr('data-i18n', '[data-content]Cancel report')
				else
					@contentJ.find('.report-abuse').addClass('btn-danger').removeClass('btn-success')
					@contentJ.find('.report-abuse').attr('data-content', i18next.t('Report abuse')).attr('data-i18n', '[data-content]Report abuse')

			return

		notify: (title, body=null, icon=null)->
			options =
				body: body
				icon: icon
			if !('Notification' of window)
				console.log 'This browser does not support desktop notification'
			else if Notification.permission == 'granted'
				# If it's okay let's create a notification
				notification = new Notification(title, options)
			else if Notification.permission != 'denied'
				Notification.requestPermission (permission) ->
					`var notification`
					# If the user accepts, let's create a notification
					if permission == 'granted'
						notification = new Notification(title, options)
			return

		onDrawingChange: (data)->

			switch data.type
				when 'votes'
					if data.author == R.me then return
					
					if R.administrator
						@notify('New vote', 'Author' + data.author + '\n Drawing: ' + data.title + ' - ' + data.drawingId, window.location.origin + '/static/images/icons/vote.png')

					drawing = R.items[data.drawingId]
					if drawing?
						if drawing.owner == R.me
							forOrAgainst = if data.positive then 'for' else 'against'
							R.alertManager.alert 'Someone voted ' + forOrAgainst + ' your drawing', (if data.positive then 'success' else 'warning'), null, { drawingTitle: drawing.title }

						drawing.votes = data.votes
						if @currentDrawing == drawing
							@setVotes()
				when 'new'
					drawingLink = @getDrawingLink(data)
					if R.administrator
						@notify('New drawing', 'drawing url: ' + drawingLink, window.location.origin + '/static/images/icons/plus.png')

					# ok if both are undefined: corresponds to CommeUnDessein
					sameCity = data.city == R.city.name or data.city == 'CommeUnDessein' and ( not R.city.name? or R.city.name == '' )
					
					if not sameCity then return

					# if the drawing is already loaded, no need to load it
					if R.items[data.pk]? or R.items[data.drawingId]? then return

					# R.alertManager.alert 'A new drawing has been created', 'success', null, {drawingLink: drawingLink}
					R.alertManager.alert 'A new drawing has been created', 'info', null, {html: '<a style="color: #2196f3;text-decoration: underline;" href="'+drawingLink+'">Un nouveau dessin</a> a été créé !'}
					# Un nouveau dessin a été créé ! Retrouvez le sur {{drawingLink}}

					$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawing', args: { pk: data.pk, loadSVG: true } } ).done((results)->
						if not R.loader.checkError(results) then return
						results.items = [results.drawing]
						R.loader.loadSVGCallback(results)
						return)
				when 'description', 'title'
					if R.administrator
						@notify('Title modified', 'drawing url: ' + @getDrawingLink(data) + ', title : ' + data.title )

					drawing = R.items[data.drawingId]
					if drawing?
						drawing.title = data.title
						drawing.description = data.description
						if @currentDrawing == drawing
							@contentJ.find('#drawing-title').val(data.title)
							@thumbnailFooterTitle.text(data.title)
							@contentJ.find('#drawing-description').val(data.description)
				when 'status'
					if R.administrator
						@notify('Status changed', 'status : ' + data.status + ', drawing url: ' + @getDrawingLink(data) )

					drawing = R.items[data.drawingId]
					if drawing?

						if drawing.owner == R.me
							if drawing.status == 'drawing'
								R.alertManager.alert 'Your drawing has been validated', 'success', null, { drawingTitle: drawing.title }
							if drawing.status == 'rejected'
								R.alertManager.alert 'Your drawing has been rejected', 'danger', null, { drawingTitle: drawing.title }
							if drawing.status == 'drawn'
								R.alertManager.alert 'Your drawing has been drawn', 'success', null, { drawingTitle: drawing.title }
							if drawing.status == 'flagged'
								R.alertManager.alert 'Your drawing has been flagged', 'danger', null, { drawingTitle: drawing.title }

						drawing.updateStatus(data.status)
				when 'cancel'
					if R.administrator
						@notify('Drawing cancelled', 'drawing url: ' + @getDrawingLink(data))

					drawing = R.items[data.drawingId]
					if drawing? and drawing.owner != R.me
						drawing.remove()
				when 'delete'
					if R.administrator
						@notify('Drawing deleted', 'drawing url: ' + @getDrawingLink(data))

					drawing = R.items[data.drawingId]
					if drawing?
						drawing.remove()
				when 'addComment'
					if R.administrator
						@notify('New comment', 'comment: ' + data.comment + 'drawing url: ' + @getDrawingLink({pk: data.drawingPk}))

					drawing = R.pkToDrawing[data.drawingPk]
					if drawing?
						if drawing.owner == R.me
							R.alertManager.alert 'Someone has commented your drawing', 'info', null, { author: data.author, drawingTitle: drawing.title }

						if @currentDrawing == drawing
							@addComment(data.comment, data.commentPk, data.author, data.date, data.insertAfter)
				when 'modifyComment'
					if R.administrator
						@notify('Comment modified', 'comment: ' + data.comment + ', drawing url: ' + @getDrawingLink({pk: data.drawingPk}))

					drawing = R.pkToDrawing[data.drawingPk]
					if drawing?

						if drawing.owner == R.me
							R.alertManager.alert 'Someone has modified a comment on your drawing', 'info', null, { author: data.author, drawingTitle: drawing.title }

						if @currentDrawing == drawing
							@contentJ.find('#comment-'+data.commentPk).find('.comment-text').get(0).innerText = data.comment
				when 'deleteComment'
					if R.administrator
						@notify('Comment deleted', 'drawing url: ' + @getDrawingLink({pk: data.drawingPk}))

					drawing = R.pkToDrawing[data.drawingPk]
					if drawing?
						
						if drawing.owner == R.me
							R.alertManager.alert 'Someone has deleted a comment on your drawing', 'info', null, { author: data.author, drawingTitle: drawing.title }

						if @currentDrawing == drawing
							@contentJ.find('#comment-'+data.commentPk).remove()
				
				when 'adminMessage'

					if R.administrator
						@notify(data.title, data.description)

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

			# @currentDrawing.votes = result.votes
			
			delay = moment.duration(result.delay, 'seconds').humanize()

			suffix = ''
			if result.validates
				suffix = ', the drawing will be validated'

			else if result.rejects
				suffix = ', the drawing will be rejected'

			if result.emailConfirmed? and not result.emailConfirmed
				suffix = ' but email not confirmed'

			if result.emailConfirmed
				R.alertManager.alert 'You successfully voted' + suffix, 'success', null, { duration: delay }
			else
				modal = Modal.createModal( 
					id: 'vote-feedback',
					title: 'Your vote was received' )
			
				modal.addText('Your vote was successfully received, but you must confirm your email before it is taken into account')
				modal.addText('You received an email to activate your account')
				modal.addText('If you have troubles confirming your account, please email us')
				modal.show()

			# R.socket.emit "drawing change", type: 'votes', votes: @currentDrawing.votes, drawingId: @currentDrawing.id
			return

		vote: (positive)=>
			if R.city?.name == 'Maintenant'
				R.alertManager.alert "L'installation Comme un Dessein est terminée, vous ne pouvez plus voter.", 'info'
				return

			if @currentDrawing.owner == R.me
				R.alertManager.alert 'You cannot vote for your own drawing', 'error'
				return
			
			if @currentDrawing.status != 'pending' and @currentDrawing.status != 'emailNotConfirmed' and @currentDrawing.status != 'notConfirmed' and @currentDrawing.status != 'test'
				R.alertManager.alert 'The drawing is already validated', 'error'
				return
			
			if @hasAlreadyVoted()
				R.alertManager.alert 'You already voted for this drawing', 'error'
				return

			# if R.administrator

			# 	if not @currentDrawing.pathListchecked
			# 		R.alertManager.alert 'Check the drawing', 'info'
				
			# 		for drawing in R.drawings
			# 			if drawing != @currentDrawing
			# 				drawing.remove()
		
			# 		draft = R.Drawing.getDraft()

			# 		args = 
			# 			pk: @currentDrawing.pk
			# 			loadPathList: true

			# 		$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { 'function': 'loadDrawing', args: args } ).done( (results)=> 
			# 			drawing = JSON.parse(results.drawing)

			# 			if draft?
			# 				draft.removePaths()

			# 			draft = new R.Drawing(null, null, null, null, R.me, Date.now(), null, null, 'draft')

			# 			draft.addPathsFromPathList(drawing.pathList, true, true)

			# 			@currentDrawing.pathListchecked = true

			# 			R.view.fitRectangle(R.view.grid.limitCD.bounds.expand(400), true)

			# 			return
			# 		)

			# 		return
			# 	else
			# 		window.location = window.location.origin


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

			# if description.length == 0
			# 	R.alertManager.alert "You must enter a description", "error"
			# 	return

			@currentDrawing.title = title
			@currentDrawing.description = description

			@currentDrawing.submit()
			
			@close(false)

			return

		modifyDrawing: ()=>

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to modify a drawing", "error"
				return

			if not @currentDrawing?
				R.alertManager.alert "You must select a drawing first", "error"
				return

			if @currentDrawing.status != 'pending' and @currentDrawing.status != 'emailNotConfirmed' and @currentDrawing.status != 'notConfirmed'
				R.alertManager.alert "The drawing is already validated, it cannot be modified anymore", "error"
				return				

			@currentDrawing.update( { title: @contentJ.find('#drawing-title').val(), data: @contentJ.find('#drawing-description').val() } )
			
			return

		cancelDrawing: ()=>

			if not @currentDrawing?
				@close()
				return

			if not @currentDrawing.pk? or @currentDrawing.status == 'draft'
				@close()
				return

			if @currentDrawing.status != 'pending' && @currentDrawing.status != 'draft' && @currentDrawing.status != 'emailNotConfirmed' && @currentDrawing.status != 'notConfirmed'
				R.alertManager.alert "The drawing is already validated, it cannot be cancelled anymore", "error"
				return	

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to cancel a drawing", "error"
				return

			draft = Item.Drawing.getDraft()
			if draft? and draft.paths?.length > 0
				R.alertManager.alert "You must submit your draft before cancelling a drawing", "error"
				return

			@currentDrawing.cancel()
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

		# deletePaths: ()=>
		# 	paths = @currentDrawing.paths.slice()
		# 	@currentDrawing.removeChildren()
		# 	@currentDrawing.remove()

		# 	@deleteGivenPaths(paths)
		# 	return

		# deleteDrawing: ()=>

		# 	if not R.me? or not _.isString(R.me)
		# 		R.alertManager.alert "You must be logged in to delete a drawing", "error"
		# 		return

		# 	if not @currentDrawing?
		# 		@close()
		# 		return

		# 	if @currentDrawing.pk?
		# 		R.alertManager.alert "Please cancel the drawing before deleting its paths", "error"
		# 		@close()
		# 		return

		# 	modal = Modal.createModal( title: 'Delete all paths', submit: @deletePaths, postSubmit: 'hide' )
		# 	modal.addText('Do you really want to delete the selected paths?')
		# 	modal.show()

		# 	return

	return DrawingPanel
