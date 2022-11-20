define ['paper', 'R', 'Utils/Utils', 'Items/Item', 'UI/Modal', 'Commands/Command', 'i18next', 'moment'], (P, R, Utils, Item, Modal, Command, i18next, moment) -> 			# 'ace/ext-language_tools', required?

	class DrawingPanel

		constructor: ()->
			project = P.project
			
			@tileCanvas = document.createElement('canvas')
			@tileProject = new P.Project(@tileCanvas)

			project.activate()

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
			@contentJ.find('.cancel-report').click @cancelReport

			@contentJ.find('.copy-link').click @copyLink
			
			if R.useSVG
				@contentJ.find('.toggle-drawing-visibility').click @toggleDrawingVisibility
			else
				@contentJ.find('.toggle-drawing-visibility').hide()

			@contentJ.find('.share-facebook').click @shareOnFacebook


			@contentJ.find('button.share-twitter').click @shareOnTwitter

			@startDiscussionBtnJ = @contentJ.find('button.start-discussion')

			@startDiscussionBtnJ.click ()=> @startDiscussion()

			@contentJ.find('.share-buttons button').popover()

			# the button to start drawing
			# @beginDrawingBtnJ = $('button.begin-drawing')
			# @beginDrawingBtnJ.click(@beginDrawingClicked)


			# the button to open the panel
			# @submitDrawingBtnJ = $('button.submit-drawing')
			# @submitDrawingBtnJ.click(@submitDrawingClicked)

			tileInfoJ = @contentJ.find('.tile-info')

			@printTileJ = tileInfoJ.find('.print-tile')
			@printTileJ.click(@printTileClicked)

			document.getElementById("fileInput").addEventListener('change', @handleFiles, false)
			
			@submitPhotoJ = tileInfoJ.find('.submit-photo')
			@submitPhotoJ.click(@submitPhotoClicked)

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
			@modifyBtnJ.addClass('hidden')
			@moveBtnJ = @drawingPanelJ.find('.action-buttons button.move')
			if R.administrator
				@moveBtnJ.removeClass('hidden')
			
			@moveBtnJ.click(@moveDrawing)
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
					event.preventDefault()
					event.stopPropagation()
					if not @currentItem? then return 		# When typing enter twice
					if @currentItem.status == 'draft'
						@submitDrawing()
					else
						@modifyDrawing()
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

			@initializeDiscussion()
			# @close()
			return

		startDiscussion: (id=null)=>
			id ?= @startDiscussionBtnJ.attr('data-discussion-id')
			if id.length > 0
				window.location.href = 'http://discussion.commeundessein.co/t/' + id
			return

		cancelReport: ()=>
			if @currentItem?
				type = if @currentItem.itemType == 'tile' then 'tile' else 'drawing'

				if ( @currentItem.status == 'flagged_pending' or @currentItem.status == 'flagged' ) and R.administrator
					R.loader.showLoadingBar(500)
					$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'cancelAbuse', args: { pk: @currentItem.pk, itemType: type } } ).done((results)=>
						R.loader.hideLoadingBar()
						if not R.loader.checkError(results) then return
						R.alertManager.alert 'The report was successfully cancelled', 'success'
						return)

			return

		reportAbuseSubmit: (type)->
			R.loader.showLoadingBar(500)
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'reportAbuse', args: { pk: @currentItem.pk, itemType: type } } ).done((results)=>
				R.loader.hideLoadingBar()
				if not R.loader.checkError(results) then return
				R.alertManager.alert 'Your report was taken into account', 'success'
				return)
			return

		reportAbuse: ()=>
			if @currentItem?
				type = if @currentItem.itemType == 'tile' then 'tile' else 'drawing'

				if R.administrator
					@reportAbuseSubmit(type)
					return

				modal = Modal.createModal( 
					id: 'report-abuse',
					title: 'Report abuse', 
					submit: ( ()=>  @reportAbuseSubmit(type) ),
					submitButtonText: 'Report abuse', 
					submitButtonIcon: 'glyphicon-flag',
					# cancelButtonText: 'Just visit', 
					# cancelButtonIcon: 'glyphicon-sunglasses',
					)
			
				modal.addText('You are about to report an abuse')
				modal.addText('The ' + type + ' will be hidden and checked by a moderator')
				modal.addText('Make sure the ' + type + ' is really inappropiate, false reports can lead to suspension of account')
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
			textArea.value = @getItemLink()
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
			
			type = if @currentItem.itemType == 'tile' then 'tile' else 'drawing'

			args = {
				itemPk: @currentItem.pk
				comment: comment
				date: Date.now()
				itemType: type,
				insertAfter: @contentJ.find('.comments-container .comments .comment:last-child').attr('id')
			}

			R.loader.showLoadingBar(500)
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'addComment', args: args } ).done((results)=>
				R.loader.hideLoadingBar()
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
					
				# itemPk = if type == 'drawing' then c.drawing.$oid else c.tile.$oid
				# R.socket.emit "drawing change", { type: 'addComment', comment: comment, commentPk: results.commentPk, author: results.author, date: c.date.$date, itemPk: itemPk, clientId: results.clientId, insertAfter: lastId, itemType: type }
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
			# if not emailConfirmed
			# 	textJ.addClass('btn-danger')
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
			R.loader.showLoadingBar(500)
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'deleteComment', args: {commentPk: commentPk} } ).done((results)->
				R.loader.hideLoadingBar()
				if not R.loader.checkError(results) then return
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
			R.loader.showLoadingBar(500)
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'modifyComment', args: {commentPk: commentPk, comment: comment} } ).done((results)->
				R.loader.hideLoadingBar()
				if not R.loader.checkError(results) then return
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
				setTimeout((()=>@exitCommentEditMode(commentPk)), 250)
				return)
			return

		getItemLink: (drawing=@currentItem)->
			cityName = if R.city?.name? then '/' + R.city.name else ''
			type = if drawing.itemType == 'tile' then 'tile' else 'drawing'
			return location.origin + cityName + '/' + type + '-' + drawing.pk

		toggleDrawingVisibility: ()=>
			buttonJ = @contentJ.find('.toggle-drawing-visibility')
			eyeIconJ = buttonJ.find('span.glyphicon.eye')
			if @currentItem.group.visible
				eyeIconJ.removeClass('glyphicon-eye-close').addClass('glyphicon-eye-open')
				text = i18next.t('Hide drawing')
			else
				eyeIconJ.addClass('glyphicon-eye-close').removeClass('glyphicon-eye-open')
				text = i18next.t('Show drawing')
			buttonJ.attr('data-i18n', '[data-content]' + text)
			buttonJ.attr('data-content', text)
			@currentItem.toggleVisibility()
			return

		shareOnFacebook: (event, drawing=@currentItem)=>
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

			facebookURL = @getItemLink(drawing)
			facebookLink = 'https://www.facebook.com/sharer/sharer.php?u=' + facebookURL
			window.open(facebookLink, 'popup', 'width=600, height=400')

			return

		shareOnTwitter: (event, drawing=@currentItem)=>
			twitterText = '' + drawing.title + ' ' + i18next.t('by') + ' ' + drawing.owner + ', ' + i18next.t('on') + ' Comme un Dessein'
			twitterURL = @getItemLink(drawing)
			twitterHashTags = 'CommeUnDessein,idlv'
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
			if drawing == @currentItem
				@currentItem = null
			return

		deselectTile: ()->
			if R.selectedItems.length == 0
				@close()
			@currentItem = null
			return

		### open close ###

		isOpened: ()->
			return @drawingPanelJ.hasClass('opened')

		open: ()->
			@contentJ.find('.delete-drawing').show()
			$('#submit-drawing-button').addClass('drawingPanel')
			@drawingPanelJ.removeClass('general')
			@drawingPanelJ.removeClass('discussion')
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
			# if @currentItem? and not @currentItem.pk?
			# 	if removeDrawingIfNotSaved
			# 		@showSubmitDrawing()
			# 		@currentItem.removeChildren()
			# 		@currentItem.remove()
					

				# @showBeginDrawing()
			# @drawingPanelJ.hide()
			@drawingPanelJ.removeClass('opened')
			@opened = false
			if R.selectedItems.length > 0
				@currentItem = null
				R.tools.select.deselectAll()


			R.toolManager.updateButtonsVisibility()
			R.tools.choose.deselectTile(false)

			if @currentItem? and @currentItem.itemType == 'discussion' and @currentItem.draft
				R.tools.discuss.removeCurrentDiscussion()

			return

		setGeneralInformation: ()=>
			previousStatus = @status
			@status = 'information'
			@generalInformation = true
			@drawingPanelTitleJ.attr('data-i18n', 'Drawings').text(i18next.t('Drawings'))
			@open()
			@drawingPanelJ.find('.loading-animation').hide()

			if previousStatus == 'select-drawing' or previousStatus == 'select-tile'
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

			# if item.type == 'tile'
			# 	if item.photoURL?
			# 		thumbnailJ.append(@createTilePhoto(item.photoURL))
			# 	# @appendTileThumbnailCanvas(item.rectangle, thumbnailJ, @tileCanvas)
			# else
			
			if item.svg? or item.paths? and item.paths.length > 0
				@setThumbnail(item, thumbnailJ)
			else

				args =
					pk: item.pk
					svgOnly: true
					# loadPathList: true

				$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawing', args: args } ).done((result)=>
					if not R.loader.checkError(result) then return
					drawingData = JSON.parse(result.drawing)
					item.setSVG(drawingData.svg)
					# item.addPathsFromPathList(drawingData.pathList)
					@setThumbnail(item, thumbnailJ)
				)
			
			deselectBtnJ = $('<button>')
			deselectBtnJ.addClass('btn btn-default icon-only transparent')
			deselectIconJ = $('<span>').addClass('glyphicon glyphicon-remove')

			deselectBtnJ.click (event)->
				item.deselect?()
				liJ.remove()
				event.preventDefault()
				event.stopPropagation()
				return -1
			deselectBtnJ.append(deselectIconJ)
			
			contentJ.append(titleJ)
			contentJ.append(thumbnailJ)

			liJ.append(contentJ)

			liJ.append(deselectBtnJ)
			liJ.click ()=>
				selectedDrawingsJ.hide()
				listJ.empty()
				R.tools.select.deselectAll()
				# if item.type == 'tile'
				# 	R.tools.choose.loadTile(item.pk, item.rectangle)
				# else
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

			# selectedDrawingsJ.find('.tiles-info').hide()

			listJ = selectedDrawingsJ.find('ul.drawing-list')
			listJ.empty()

			for item in R.selectedItems
				if item instanceof Item.Drawing
					@createSelectionLi(selectedDrawingsJ, listJ, item)

			return

		# showSelectedTiles: (tiles, rectangle)->
		# 	@drawingPanelJ.removeClass('general')
		# 	@status = 'select-tile'
		# 	@drawingPanelTitleJ.attr('data-i18n', 'Select a single tile').text(i18next.t('Select a single tile'))

		# 	@drawingPanelJ.find('.content-container').children().hide()
		# 	selectedDrawingsJ = @drawingPanelJ.find('.selected-drawings')
		# 	selectedDrawingsJ.show()
			
		# 	selectedDrawingsJ.find('.tiles-info').show()

		# 	listJ = selectedDrawingsJ.find('ul.drawing-list')
		# 	listJ.empty()

		# 	@createTileThumbnailCanvas(rectangle)
		# 	@appendTileThumbnailCanvas(rectangle, selectedDrawingsJ.find('.tiles-info .drawing-thumbnail'))

		# 	selectedDrawingsJ.find('.tiles-info .title').text(i18next.t('Tile') + ' ' + tiles[0].x + ', ' + tiles[0].y)

		# 	for item in tiles
		# 		item.type = 'tile'
		# 		item.title = i18next.t('Tile') + ' ' + i18next.t('by') + ' ' + item.owner
		# 		item.rectangle = rectangle
		# 		item.pk = item._id.$oid
		# 		@createSelectionLi(selectedDrawingsJ, listJ, item)


		# 	@open()
		# 	return

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

		# showSubmitDrawing: ()->
		# 	# @hideBeginDrawing()
			
		# 	# @submitDrawingBtnJ.removeClass('hidden')
		# 	# @submitDrawingBtnJ.show()
			
		# 	# @cancelDrawingBtnJ.removeClass('hidden')
		# 	# @cancelDrawingBtnJ.show()
		# 	# @contentJ.find('#drawing-title').focus()
		# 	return

		# hideSubmitDrawing: ()->
		# 	# $('#submit-drawing-button').hide()
		# 	# @submitDrawingBtnJ.hide()
		# 	# @cancelDrawingBtnJ.hide()
		# 	return

		# showBeginDrawing: ()->
		# 	# @hideSubmitDrawing()
		# 	@beginDrawingBtnJ.show()
		# 	return

		# hideBeginDrawing: ()->
		# 	@beginDrawingBtnJ.hide()
		# 	return

		# beginDrawingClicked: ()=>
		# 	R.toolManager.enterDrawingMode()
		# 	@beginDrawingBtnJ.hide()

		# 	# if there are already some draft paths: directly show submit button

		# 	for id, item of R.items
		# 		console.log('WARNING, ENTERED DEPRECATED CODE')
		# 		if item instanceof Item.Path
		# 			if item.owner == R.me and item.drawingId == null
		# 				@showSubmitDrawing()
		# 				return
		# 	return
		
		setThumbnail: (item, thumbnailJ)->
			svg = R.view.getThumbnail(item)
			svg.setAttribute('viewBox', '0 0 300 300')
			svg.setAttribute('width', '250')
			svg.setAttribute('height', '250')
			thumbnailJ.empty().append(svg)
			return

		setDrawingThumbnail: ()->
			if @currentItem.itemType == 'tile'
				return

			@contentJ.find('.thumbnail-footer').show()

			drawingThumbnailJ = @contentJ.find('.drawing-thumbnail')

			if @currentItem.svg?
				@setThumbnail(@currentItem, drawingThumbnailJ)
			else
				@currentItem.loadSVG(()=> @setThumbnail(@currentItem, drawingThumbnailJ) )
			
			return

		# createDrawingFromItems: (items)->

		# 	drawingId = Utils.createId()

		# 	for item in items
		# 		if item instanceof Item.Path
		# 			item.drawingId = drawingId


		# 	title = @contentJ.find('#drawing-title').val()
		# 	description = @contentJ.find('#drawing-description').val()
		# 	@currentItem = new Item.Drawing(null, null, drawingId, null, R.me, Date.now(), title, description, 'pending')

		# 	R.rasterizer.rasterizeRectangle(@currentItem.rectangle)

		# 	R.view.fitRectangle(@currentItem.rectangle, true)

		# 	@setDrawingThumbnail()

		# 	@currentItem.select(true, false) # Important to deselect (for example when selecting a tool) and close the drawing panel
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

			# Warning:  R.tools.select.deselectAll() and R.toolManager.leaveDrawingMode() can lead to @currentItem = null so set currentDrawing afterward
			R.tools.select.deselectAll()
			R.toolManager.leaveDrawingMode(true)

			# set currentDrawing after the two previous functions
			@currentItem = draft
			# @currentItem.addPaths()

			@contentJ.find('.tile-info').hide()
			
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
			@contentJ.find('#drawing-title').show().val('')

			@thumbnailFooterAuthor.text(R.me)
			@thumbnailFooterTitle.text('')
			
			@contentJ.find('#drawing-description').val('')
			@submitBtnJ.show()
			@modifyBtnJ.hide()
			# @cancelBtnJ.show()
			@cancelBtnJ.find('span.text').attr('data-i18n', 'Cancel').text(i18next.t('Cancel'))
			# @deleteBtnJ.show()

			@contentJ.find('#drawing-title').removeAttr('readonly')
			@contentJ.find('#drawing-description').removeAttr('readonly')

			@votesJ.hide()
			@contentJ.find('.share-buttons').hide()

			# @submitBtnJ.find('span.glyphicon').removeClass('glyphicon-ok').addClass('glyphicon-refresh glyphicon-refresh-animate')
			# $.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'getDrafts', args: { cityName: R.city.name } } ).done(@submitDrawingClickedCallback)

			bounds = @currentItem.getBounds()
			if bounds?
				R.view.fitRectangle(bounds, true)

			draft.createSVG()

			@setDrawingThumbnail()

			@currentItem.select(true, false) # Important to deselect (for example when selecting a tool) and close the drawing panel

			return

		initializeDiscussion: ()->
			document.getElementById('drawing-title').addEventListener('input', (event)-> R.tools.discuss.updateCurrentDiscussion(event.target.value) )
			return
		
		setPanelForDiscussion: (@currentItem = R.tools.discuss.currentDiscussion)->
			

			@contentJ.find('.tile-info').hide()
			
			@drawingPanelTitleJ.attr('data-i18n', 'Create discussion').text(i18next.t('Create discussion'))

			@open()
			@drawingPanelJ.addClass('discussion')
			@showContent()

			@contentJ.find('.delete-drawing').hide()

			@contentJ.find('#drawing-panel-no-selection').hide().siblings().show()

			setTimeout (() => @contentJ.find('#drawing-title').focus() ), 200

			@contentJ.find('#drawing-thumbnail').hide()
			@contentJ.find('.title-group').show()

			@submitBtnJ.show()
			@modifyBtnJ.hide()
			# @cancelBtnJ.show()
			@cancelBtnJ.find('span.text').attr('data-i18n', 'Cancel').text(i18next.t('Cancel'))

			@votesJ.hide()
			@contentJ.find('.share-buttons').hide()

			@contentJ.find('.comments-container').hide()

			R.tools.discuss.centerOnDiscussion()

			@currentItem.itemType = 'discussion'

			return

		addDiscussionClicked: ()=>
			@setPanelForDiscussion()
			@contentJ.find('#drawing-title').attr('placeholder', i18next.t('Discussion Title')).show().removeAttr('readonly').val('').select()

			$.ajax( method: "GET", url: "http://espero.collectivethinking.co:8080/p/core/new/post/" ).done((result)=>
				$('#discussion-content').append(result.template)
				return).error((result)=> 
				console.log(result))
			return

		openDiscussion: (discussion)=>
			@setPanelForDiscussion(discussion)

			drawingTitleJ = @contentJ.find('#drawing-title')

			drawingTitleJ.show().val(@currentItem.pointText.content)
			if discussion.owner == R.me
				drawingTitleJ.removeAttr('readonly')

				@submitBtnJ.hide()
				# @modifyBtnJ.show()
				# @cancelBtnJ.show()
				@cancelBtnJ.find('span.text').attr('data-i18n', 'Delete discussion').text(i18next.t('Delete discussion'))
			else 
				@submitBtnJ.show()
				@modifyBtnJ.hide()
				drawingTitleJ.attr('readonly')
			
			$.ajax( method: "GET", url: "http://localhost:8080/p/core/296/" ).done((result)=>
				$('#discussion-content').append(result.template)
				return).error((result)=> 
				console.log(result))
			return

		createTilePhoto: (photoURL)->
			return $('<img src="media/images/' + photoURL + '">')

		handleFiles: (event)=> 

			for file in event.target.files

				if file.type.match(/image.*/)

					reader = new FileReader()
					reader.onload = (readerEvent)=>
						image = new Image()
						image.onload = (imageEvent)=>
							canvas = document.createElement('canvas')
							max_size = 1000
							width = image.width
							height = image.height
							if width > height and width > max_size
								height *= max_size / width
								width = max_size
							else if height > width and height > max_size
								width *= max_size / height
								height = max_size
							canvas.width = width
							canvas.height = height
							canvas.getContext('2d').drawImage(image, 0, 0, width, height)
							resizedImage = canvas.toDataURL('image/jpeg')

							R.loader.showLoadingBar(500)
							$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'submitTilePhoto', args: { pk: @currentItem.pk, imageName: R.me + '_' + @currentItem.number, dataURL: resizedImage } } ).done((results)=>
								R.loader.hideLoadingBar()
								if not R.loader.checkError(results) then return
								@submitPhotoJ.hide()
								tileInfoJ = @contentJ.find('.tile-info')
								tileInfoJ.find('.tile-thumbnail').show().empty().append(@createTilePhoto(results.photoURL))
								@setVotes()
								@contentJ.find('.share-buttons').show()

								R.tools.choose.updateTileStatus(results)

								return)

							return
						image.src = readerEvent.target.result
						return
					reader.readAsDataURL(file)

				event.target.value = null
				return

			event.target.value = null
			return

		submitPhotoClicked: ()=>
			fileInputJ = document.getElementById("fileInput")
			fileInputJ.click()
			return

		printTileClicked: ()=>
			modal = Modal.createModal( 
				id: 'print-tile',
				title: "Print tile", 
				submit: @printOnFourSheets, 
				submitButtonText: "On four A4 sheets",
				# submitButtonIcon: 'glyphicon-th-large'
				submitButtonIcon: 'glyphicon-duplicate'
				)
			
			modal.addButton( type: 'info', name: 'On a single A4 sheet', icon: 'glyphicon-file', submit: @printOnASingleSheet )

			modal.addText("How would you like to print this tile ?", "How would you like to print this tile")
			modal.addText("If you choose to print on a single sheet, you will need to paint it twice as big.", "Scale up the tile")

			width = R.Tools.Choose.tileWidth * R.Tools.Choose.nSheetsPerTile
			height = R.Tools.Choose.tileHeight * R.Tools.Choose.nSheetsPerTile

			modal.addText("The tile dimensions must be: " + width + ' x ' + height + 'mm.', "The tile dimensions must be", false, {width: width, height: height})

			modal.show()

			return

		printOnASingleSheet: ()=>
			@printSheets(true)
			return

		printOnFourSheets: ()=>
			@printSheets(false)
			return

		print: (project, rectangles, dashedFrames, tileWidth, tileHeight)=>

			newWindow = window.open("about:blank", "_new")

			print = ()=>
				newWindow.print()
				@createTileThumbnailCanvas(@tileRectangle)
				project.activate()

				return
			
			createDocument = ()=>

				n = 0
				for r in rectangles
					@tileProject.view.scrollBy(r.center.subtract(@tileProject.view.center))

					dashedFrames[n-1]?.visible = false
					dashedFrames[n].visible = true
					svg = @tileProject.exportSVG()

					svg.setAttribute('width', Math.round(tileWidth / R.city.pixelPerMm) + 'mm')
					svg.setAttribute('height', Math.round(tileHeight / R.city.pixelPerMm) + 'mm')
					svg.setAttribute('viewBox', '0 0 ' + tileWidth + ' ' + tileHeight)

					newWindow.document.write(svg.outerHTML)
					if n < rectangles.length - 1
						newWindow.document.write('<p style="page-break-before: always"></p>')
					n++

				newWindow.focus()

				setTimeout(print, 500)
				return

			setTimeout(createDocument, 500)

			return

		printSheets: (singleSheet)=>
			
			# newWindow = window.open(@tileCanvas.toDataURL(), "_blank")
			# newWindow.onload = (()=> return window.print())

			project = P.project
			
			@tileProject.activate()
			@tileProject.activeLayer.removeChildren()

			# scale = 96/2.54/10

			nSheetsPerTile = if singleSheet then 1 else R.Tools.Choose.nSheetsPerTile
			tileWidth = R.Tools.Choose.tileWidth * R.city.pixelPerMm
			tileHeight = R.Tools.Choose.tileHeight * R.city.pixelPerMm
			width = tileWidth * nSheetsPerTile
			height = tileHeight * nSheetsPerTile

			# @tileProject.view.viewSize.width = width * scale / nSheetsPerTile
			# @tileProject.view.viewSize.height = height * scale / nSheetsPerTile
			@tileProject.view.viewSize.width = width / nSheetsPerTile
			@tileProject.view.viewSize.height = height / nSheetsPerTile

			@tileProject.view.scrollBy(@tileRectangle.center.subtract(@tileProject.view.center))
			# @tileProject.view.zoom = scale

			if singleSheet
				@tileProject.view.zoom /= 2

			rectangle = @tileRectangle.clone()
			rectangles = []

			if singleSheet
				rectangles.push(rectangle)
			else
				rectangle.width /= nSheetsPerTile
				rectangle.height /= nSheetsPerTile
				rectangle.left = @tileRectangle.left
				rectangle.top = @tileRectangle.top

				rectangles.push(rectangle.clone())
				rectangle.x = @tileRectangle.left + rectangle.width
				rectangle.y = @tileRectangle.top
				rectangles.push(rectangle.clone())
				rectangle.x = @tileRectangle.left
				rectangle.y = @tileRectangle.top + rectangle.height
				rectangles.push(rectangle.clone())
				rectangle.x = @tileRectangle.left + rectangle.width
				rectangle.y = @tileRectangle.top + rectangle.height
				rectangles.push(rectangle)

			dashedFrames = []
			for r in rectangles
				dashedFrame = new P.Path.Rectangle(r)
				dashedFrame.strokeColor = 'black'
				dashedFrame.strokeWidth = 1
				dashedFrame.dashArray = [3, 1.5]
				dashedFrame.visible = false
				dashedFrames.push(dashedFrame)

			drawingsToLoad = []

			for drawing in R.drawings
				if drawing.status != 'draft' and drawing.getBounds()?.intersects(@tileRectangle)
					drawingsToLoad.push(drawing)

			nDrawingsToLoad = drawingsToLoad.length

			if nDrawingsToLoad == 0
				@print(project, rectangles, dashedFrames, tileWidth, tileHeight)

			for drawing in drawingsToLoad
				drawing.loadSVGToPrint( (svg)=> 
					@tileProject.importSVG(svg)
					nDrawingsToLoad--
					if nDrawingsToLoad <= 0
						@print(project, rectangles, dashedFrames, tileWidth, tileHeight)

					return
					)

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

			for vote in @currentItem.votes
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
			
			@votesJ.find('.status').attr('data-i18n', @currentItem.status).html(i18next.t(@currentItem.status))

			@voteUpBtnJ.removeClass('disabled')
			@voteDownBtnJ.removeClass('disabled')
			if @currentItem.owner == R.me || R.administrator
				if @currentItem.status == 'pending' or @currentItem.status == 'emailNotConfirmed' or @currentItem.status == 'notConfirmed'
					@voteUpBtnJ.removeClass('disabled')
					@voteDownBtnJ.removeClass('disabled')

			return

		setDrawing: (@currentItem, drawingData)->

			@drawingPanelJ.removeClass('general')

			@contentJ.find('.tile-info').hide()

			@status = 'drawing'
			@drawingPanelTitleJ.attr('data-i18n', 'Drawing info').text(i18next.t('Drawing info'))

			@open()
			@contentJ.find('#drawing-panel-no-selection').hide().siblings().show()
			@showContent()
			
			@contentJ.find('.share-buttons').show()

			# if not R.me? or not _.isString(R.me) or R.me.length == 0
			# 	@contentJ.find('.comments-container').hide()
			# else
			@contentJ.find('.comments-container').show()

			latestDrawing = JSON.parse(drawingData.drawing)

			@currentItem.votes = drawingData.votes
			@currentItem.clientId = @currentItem.id
			@currentItem.status = latestDrawing.status
			
			if latestDrawing.svg?
				# @currentItem.setSVG(latestDrawing.svg, true, null, false)
				@currentItem.setSVG(latestDrawing.svg)

			@submitBtnJ.hide()
			@modifyBtnJ.hide()
			@cancelBtnJ.hide()
			# @deleteBtnJ.hide()

			@contentJ.find('#drawing-author').show().val(@currentItem.owner)
			@contentJ.find('.title-group').hide()
			@contentJ.find('#drawing-title').attr('placeholder', i18next.t('Drawing Title')).show().val(@currentItem.title)
			
			@thumbnailFooterAuthor.show().text(@currentItem.owner)
			@thumbnailFooterTitle.show().text(@currentItem.title)

			@contentJ.find('#drawing-description').show().val(@currentItem.description)
			
			if @currentItem.owner == R.me || R.administrator
				if latestDrawing.status == 'pending' || latestDrawing.status == 'emailNotConfirmed' || latestDrawing.status == 'notConfirmed'
					@contentJ.find('.title-group').show()
					# @modifyBtnJ.show()
					# @cancelBtnJ.show()
					@cancelBtnJ.find('span.text').attr('data-i18n', 'Modify drawing').text(i18next.t('Modify drawing'))
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
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadComments', args: { itemPk: @currentItem.pk } } ).done((results)=>
				if not R.loader.checkError(results) then return
				@addComments(results.comments)
				return)

			if latestDrawing.discussionId?
				@startDiscussionBtnJ.show()
				@startDiscussionBtnJ.attr('data-discussion-id', latestDrawing.discussionId)
			else
				@startDiscussionBtnJ.hide()

			# if @currentItem.title and @currentItem.pk and @currentItem.status != 'draft'
			# 	history.pushState('', 'Drawing ' + @currentItem.title, window.location.origin + '/drawing-' + @currentItem.pk)

			# window.DiscourseEmbed = { discourseUrl: 'http://discussion.commeundessein.co/', discourseEmbedUrl: @getItemLink() }

			# require [DiscourseEmbed.discourseUrl], (discourse)=>
			# 	console.log(discourse + 'javascripts/embed.js')
			# 	return

			# script = document.createElement('script')
			# script.type = 'text/javascript'
			# script.async = true
			# script.src = DiscourseEmbed.discourseUrl + 'javascripts/embed.js'
			# (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(script)

			@contentJ.find('.cancel-report').hide()
			if R.administrator and @currentItem.status == 'flagged_pending'
				@contentJ.find('.cancel-report').show()

			return
		
		createTileThumbnailCanvas: (tileRectangle)->

			project = P.project
			
			@tileProject.activate()
			@tileProject.activeLayer.removeChildren()
			@tileProject.view.viewSize = tileRectangle.size
			@tileProject.view.zoom = 1

			scaleNumber = 0
			scale = 1
			nPixelsPerTile = scale * 1000

			quantizedBounds =
				t: Math.floor(tileRectangle.top / nPixelsPerTile)
				l: Math.floor(tileRectangle.left / nPixelsPerTile)
				b: Math.floor(tileRectangle.bottom / nPixelsPerTile)
				r: Math.floor(tileRectangle.right / nPixelsPerTile)

			for n in [quantizedBounds.t .. quantizedBounds.b]
				for m in [quantizedBounds.l .. quantizedBounds.r]

					raster = new P.Raster(location.origin + '/static/rasters/active/zoom' + scaleNumber + '/' + m + ','  + n + '.png')
					raster.position.x = (m + 0.5) * nPixelsPerTile
					raster.position.y = (n + 0.5) * nPixelsPerTile
					raster.scale(scale)

					@tileProject.activeLayer.addChild(raster)

			@tileProject.view.scrollBy(tileRectangle.center.subtract(@tileProject.view.center))

			project.activate()

			return @tileCanvas

		appendTileThumbnailCanvas: (tileRectangle, thumbnailJ, tileCanvas=@tileCanvas)->

			thumbnailJ.empty().append(tileCanvas)
			canvasRatio = tileRectangle.width / tileRectangle.height
			thumbnailJRatio = thumbnailJ.width() / thumbnailJ.height()
			
			if canvasRatio > thumbnailJRatio
				scale = thumbnailJ.width() / tileRectangle.width
				$(tileCanvas).css( transform: 'scale(' + scale + ')')
				thumbnailJ.css(height: $(tileCanvas).height() * scale)

			return

		createTileThumbnail: (tileRectangle, thumbnailJ)->
			@createTileThumbnailCanvas(tileRectangle)
			@appendTileThumbnailCanvas(tileRectangle, thumbnailJ)
			return

		setTile: (tileData, tileRectangle)->
			tile = if _.isString(tileData.tile) then JSON.parse(tileData.tile) else tileData.tile
			tile.pk = tile._id.$oid
			@currentItem = { pk: tile.pk, clientId: tile.clientId, itemType: 'tile', votes: tileData.votes, author: tileData.tile_author, status: tile.status, number: tile.number, x: tile.x, y: tile.y }
			@tileRectangle = tileRectangle
			@drawingPanelJ.removeClass('general')

			tileInfoJ = @contentJ.find('.tile-info')
			tileInfoJ.show()

			tileInfoJ.find('.author').text(tileData.tile_author)
			tileInfoJ.find('.number').text(tile.number)
			tileInfoJ.find('.position').text( 'X : ' + tile.x + ', Y : ' + tile.y)
			tileInfoJ.find('.status').attr('data-i18n', tile.status).text(i18next.t(tile.status))

			hours = i18next.t('hours')
			minutes = i18next.t('minutes')
			seconds = i18next.t('seconds')
			andText = i18next.t('and')

			dueDate = moment(tile.dueDate.$date)
			dueDateString = dueDate.format(' dddd D MMMM ') + i18next.t('at') + dueDate.format(' H [' + hours + '], m [' + minutes + ' ' + andText + '] s [' + seconds + '.]')

			tileWasAchieved = tile.status == 'created' or tile.status == 'validated' or tile.status == 'rejected'
			dueDateTitle = if tileWasAchieved then "This tile was achieved the" else "This tile must be achieved before the"
			tileInfoJ.find('.due-date-title').attr('data-i18n', dueDateTitle).text(i18next.t(dueDateTitle))

			tileInfoJ.find('.due-date').text(dueDateString)
			
			placementDate = moment(tile.placementDate.$date)
			placementDateString = placementDate.format(' dddd D MMMM ') + i18next.t('at') + placementDate.format(' H [' + hours + '], m [' + minutes + ' ' + andText + '] s [' + seconds + '.]')

			tileInfoJ.find('.placement-date').text(placementDateString)

			@submitPhotoJ.hide()
			tileInfoJ.find('.tile-thumbnail').hide()

			if tile.photoURL?
				imageURL = if ( tile.status != 'flagged' and tile.status != 'flagged_pending' ) or R.administrator then 'media/images/' + tile.photoURL else 'static/images/icons/banned.png'
				tileInfoJ.find('.tile-thumbnail').show().empty().append($('<img src="' + imageURL + '">'))
			else if @currentItem.author == R.me
				@submitPhotoJ.show()

			@status = 'tile'

			@drawingPanelTitleJ.attr('data-i18n', 'Tile info').text(i18next.t('Tile info'))

			@open()
			@contentJ.find('#drawing-panel-no-selection').hide().siblings().show()
			@showContent()
			

			if not R.me? or not _.isString(R.me) or R.me.length == 0
				@contentJ.find('.comments-container').hide()
			else
				@contentJ.find('.comments-container').show()

			@submitBtnJ.hide()
			@modifyBtnJ.hide()
			@cancelBtnJ.hide()
			# @deleteBtnJ.hide()

			@contentJ.find('.title-group').hide()
			@contentJ.find('#drawing-title').hide()

			@thumbnailFooterAuthor.hide()
			@thumbnailFooterTitle.hide()

			@contentJ.find('#drawing-description').hide()

			if @currentItem.author == R.me || R.administrator
				# if tile.status == 'pending'
				# @cancelBtnJ.show()
				@cancelBtnJ.find('span.text').attr('data-i18n', 'Cancel tile').text(i18next.t('Cancel tile'))

			if tile.status == 'created'
				@setVotes()
				@contentJ.find('.share-buttons').show()
			else
				@votesJ.hide()
				@contentJ.find('.share-buttons').hide()

			if ( tile.status == 'flagged' or tile.status == 'flagged_pending') and R.administrator
				@contentJ.find('.share-buttons').show()

			@contentJ.find('.thumbnail-footer').hide()
			
			thumbnailJ = @contentJ.find('.drawing-thumbnail')
			@createTileThumbnail(tileRectangle, thumbnailJ)


			@emptyComments()

			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadComments', args: { itemPk: tile.pk, itemType: 'tile' } } ).done((results)=>
				if not R.loader.checkError(results) then return
				@addComments(results.comments)
				return)

			if tile.discussionId?
				@startDiscussionBtnJ.show()
				@startDiscussionBtnJ.attr('data-discussion-id', tile.discussionId)
			else
				@startDiscussionBtnJ.hide()

			@contentJ.find('.cancel-report').hide()
			if R.administrator and @currentItem.status == 'flagged_pending'
				@contentJ.find('.cancel-report').show()

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

		loadDrawing: (pk)->
			args = 
				pk: pk
				loadPathList: true
				# loadSVG: true
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawing', args: args } ).done((result)->
				if not R.loader.checkError(result) then return
				R.loader.createDrawing(result.drawing, true)
				return)
			return

		loadTile: (pk)->
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadTile', args: { pk: pk } } ).done((result)=>
				if not R.loader.checkError(result) then return
				tile = JSON.parse(result.tile)
				R.tools.choose.createTile(tile)
				return)
			return

		loadDiscussion: (discussion)->
			if not discussion.pk? then return
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDiscussion', args: { pk: discussion.pk } } ).done((result)=>
				if not R.loader.checkError(result) then return
				discussion = JSON.parse(result.discussion)
				@openDiscussion(discussion)
				return)
			return

		onDrawingChange: (data)->

			switch data.type
				when 'vote', 'cancel_vote'
					if data.author == R.me then return
					
					if R.administrator
						if data.itemType == 'drawing'
							@notify('New vote', 'Author' + data.author + '\n Drawing: ' + data.title + ' - ' + data.clientId, window.location.origin + '/static/images/icons/vote.png')
						else
							@notify('New vote', 'Author' + data.author + '\n Tile: ' + data.tile + ' - ' + data.clientId, window.location.origin + '/static/images/icons/vote.png')

					item = if data.itemType == 'drawing' then R.items[data.clientId] else R.tools.choose.idToTile.get(data.clientId)
					if item?
						if item.owner == R.me
							forOrAgainst = if data.positive then 'for' else 'against'
							if data.type == 'vote'
								R.alertManager.alert 'Someone voted ' + forOrAgainst + ' your ' + data.itemType, (if data.positive then 'success' else 'warning'), null, { drawingTitle: item.title }
							else if data.type == 'cancel_vote'
								R.alertManager.alert 'Someone cancelled his vote ' + forOrAgainst + ' your ' + data.itemType, 'warning', null, { drawingTitle: item.title }

						item.votes = data.votes
						if @currentItem?
							@currentItem.votes = data.votes
							if @currentItem.clientId == data.clientId
								@setVotes()
				when 'new'
					drawingLink = @getItemLink(data)
					if R.administrator and data.itemType == 'drawing'
						@notify('New drawing', data.itemType + ' url: ' + drawingLink, window.location.origin + '/static/images/icons/plus.png')

					# ok if both are undefined: corresponds to CommeUnDessein
					sameCity = data.city == R.city.name
					
					if not sameCity then return

					if data.itemType == 'drawing'
						# if the drawing is already loaded, no need to load it
						if R.items[data.pk]? or R.items[data.clientId]? then return

						# R.alertManager.alert 'A new drawing has been created', 'success', null, {drawingLink: drawingLink}
						R.alertManager.alert 'A new drawing has been created', 'info', null, {html: '<a style="color: #2196f3;text-decoration: underline;" href="'+drawingLink+'">Un nouveau dessin</a> a été créé !'}
						# Un nouveau dessin a été créé ! Retrouvez le sur {{drawingLink}}

						if R.loader.getLoadingBounds().intersects(data.bounds)
							@loadDrawing(data.pk)
					else if data.itemType == 'tile'

						R.alertManager.alert 'A new tile has been reserved', 'info', null, {html: '<a style="color: #2196f3;text-decoration: underline;" href="'+drawingLink+'">Un nouvelle case</a> a été réservée !'}

						if R.loader.getLoadingBounds().intersects(data.bounds)
							@loadTile(data.pk)

					else if data.itemType == 'discussion'

						if not R.tools.discuss.discussions.get(data.clientId)? and R.loader.getLoadingBounds().intersects(data.bounds)
							R.alertManager.alert 'A new discussion has been created', 'info'
							@loadDiscussion(data.pk)

				when 'description', 'title'
					if R.administrator
						@notify('Title modified', 'drawing url: ' + @getItemLink(data) + ', title : ' + data.title )

					drawing = R.items[data.clientId]
					if drawing?
						drawing.title = data.title
						drawing.description = data.description
						if @currentItem? and @currentItem == drawing
							@contentJ.find('#drawing-title').val(data.title)
							@thumbnailFooterTitle.text(data.title)
							@contentJ.find('#drawing-description').val(data.description)
				when 'status'
					if R.administrator
						@notify('Status changed', 'status : ' + data.status + ', drawing url: ' + @getItemLink(data) )

					if data.itemType == 'drawing'
						drawing = R.items[data.clientId]
						if drawing?
							if drawing.owner == R.me
								if data.status == 'drawing'
									R.alertManager.alert 'Your drawing has been validated', 'success', null, { drawingTitle: drawing.title }
								if data.status == 'rejected'
									R.alertManager.alert 'Your drawing has been rejected', 'danger', null, { drawingTitle: drawing.title }
								if data.status == 'drawn'
									R.alertManager.alert 'Your drawing has been drawn', 'success', null, { drawingTitle: drawing.title }
								if data.status == 'flagged' or data.status == 'flagged_pending'
									R.alertManager.alert 'Your drawing has been flagged', 'danger', null, { drawingTitle: drawing.title }

							wasActive = drawing.status == 'pending' or drawing.status == 'validated' or data.status == 'drawing'
							drawing.updateStatus(data.status)
							iActive = drawing.status == 'pending' or drawing.status == 'validated' or data.status == 'drawing'

							flagDrawing = data.status == 'flagged_pending' or data.status == 'flagged'
							rejectDrawing = data.status == 'rejected'
							
							if wasActive != isActive and data.bounds? and R.loader.getLoadingBounds().intersects(data.bounds)
								R.loader.reloadRasters(data.bounds)

							if @currentItem? and @currentItem == drawing
								@votesJ.find('.status').attr('data-i18n', @currentItem.status).html(i18next.t(@currentItem.status))

							if flagDrawing or (rejectDrawing and !R.loadRejectedDrawings)
								if @currentItem? and @currentItem == drawing
									@close()
									R.alertManager.alert 'The drawing you selected has been reported as abusive', 'info'
								if data.status == 'flagged' or not R.administrator
									drawing.remove()
								if R.administrator and data.status == 'flagged_pending'
									drawing.loadPathList()
						else if data.bounds? and R.loader.getLoadingBounds().intersects(data.bounds)
							isActive = data.status == 'pending' or data.status == 'validated' or data.status == 'drawing'
							rejectedAndShowRejected = data.status == 'rejected' and R.loadRejectedDrawings
							administratorMustSee = R.administrator and ( data.status != 'rejected' or R.loadRejectedDrawings )
							if isActive or rejectedAndShowRejected or administratorMustSee
								if data.pk?
									@loadDrawing(data.pk)

					else if data.itemType == 'tile'
						tile = R.tools.choose.idToTile.get(data.clientId)
						if tile?
							R.tools.choose.updateTileStatus(tile, data.status)
							
							if @currentItem? and @currentItem.clientId == data.clientId
								tileInfoJ = @contentJ.find('.tile-info')
								tileInfoJ.find('.status').attr('data-i18n', tile.status).text(i18next.t(tile.status))
								@setVotes()
								if tile.status == 'created' and data.photoURL?
									tileInfoJ.find('.tile-thumbnail').show().empty().append(@createTilePhoto(data.photoURL))
									@contentJ.find('.share-buttons').show()
						else if data.bounds? and R.loader.getLoadingBounds().intersects(data.bounds)
							if data.status != 'flagged_pending' and data.status != 'flagged' or R.administrator
								@loadTile(data.pk)
				when 'cancel'
					if R.administrator
						@notify(data.itemType + ' cancelled',  data.itemType + ' url: ' + @getItemLink(data))

					if data.itemType == 'drawing'
						drawing = R.items[data.clientId]
						if drawing?
							if drawing.owner != R.me
								R.loader.reloadRasters(drawing.rectangle)
								if @currentItem? and @currentItem == drawing
									@close()
									R.alertManager.alert 'The drawing you selected was cancelled', 'info'
								drawing.remove()
							# else if !drawing.cancelling
							# 	R.alertManager.alert 'One of your drawing was cancelled by an administrator, the page will reload', 'info'
							# 	setTimeout((()->window.location.reload()), 2000)
					else
						tile = R.tools.choose.idToTile.get(data.clientId)
						if tile?
							R.tools.choose.removeTile(tile, tile)
							if @currentItem? and @currentItem.clientId == tile.clientId
								@close()
								R.alertManager.alert 'The tile you selected was cancelled', 'info'
				when 'delete'
					if R.administrator
						@notify('Drawing deleted', 'drawing url: ' + @getItemLink(data))

					drawing = R.items[data.clientId]
					if drawing?
						R.loader.reloadRasters(drawing.rectangle)
						if @currentItem? and @currentItem == drawing
							@close()
							R.alertManager.alert 'The drawing you selected was deleted', 'info'
						drawing.remove()
				when 'addComment'
					if R.administrator
						@notify('New comment', 'comment: ' + data.comment +  ' ' + data.itemType + ' url: ' + @getItemLink({pk: data.itemPk}))

					if data.author == R.me then return

					item = if data.itemType == 'drawing' then R.pkToDrawing.get(data.itemPk) else R.tools.choose.idToTile.get(data.clientId)
					if item?
						if item.owner == R.me
							R.alertManager.alert 'Someone has commented your ' + data.itemType, 'info', null, { author: data.author, drawingTitle: data.title }

						if @currentItem? and @currentItem.clientId == item.clientId
							@addComment(data.comment, data.commentPk, data.author, data.date, data.insertAfter)
				when 'modifyComment'
					if R.administrator
						@notify('Comment modified', 'comment: ' + data.comment + ', ' + data.itemType + ' url: ' + @getItemLink({pk: data.itemPk}))

					item = if data.itemType == 'drawing' then R.pkToDrawing.get(data.itemPk) else  R.tools.choose.idToTile.get(data.clientId)
					if item?

						if item.owner == R.me
							R.alertManager.alert 'Someone has modified a comment on your ' + data.itemType, 'info', null, { author: data.author, drawingTitle: data.title }

						if @currentItem? and @currentItem.clientId == item.clientId
							commentJ = @contentJ.find('#comment-'+data.commentPk)
							if commentJ.length > 0
								commentJ.find('.comment-text').get(0).innerText = data.comment
				when 'deleteComment'
					if R.administrator
						@notify('Comment deleted', 'drawing url: ' + @getItemLink({pk: data.itemPk}))

					item = if data.itemType == 'drawing' then R.pkToDrawing.get(data.itemPk) else  R.tools.choose.idToTile.get(data.clientId)
					if item?

						if item.owner == R.me
							R.alertManager.alert 'Someone has deleted a comment on your ' + data.itemType, 'info', null, { author: data.author, drawingTitle: data.title }

						if @currentItem? and @currentItem.clientId == item.clientId
							commentJ = @contentJ.find('#comment-'+data.commentPk)
							if commentJ.length > 0
								commentJ.remove()
				
				when 'adminMessage'

					if R.administrator
						@notify(data.title, data.description)

			return

		### votes ###

		hasAlreadyVoted: ()->
			for vote in @currentItem.votes
				if vote.vote.author == R.me
					return true
			return false

		voteCallback: (result)=>
			R.loader.hideLoadingBar()
			if not R.loader.checkError(result) then return

			type = if @currentItem.itemType == 'tile' then 'tile' else 'drawing'

			if type == 'drawing'
				@currentItem.updateDrawingPanel()
			else
				R.tools.choose.loadTile(@currentItem.pk)

			if result.cancelled 
				R.alertManager.alert 'Your vote was successfully cancelled', 'success'
				R.loader.userVotes.delete(@currentItem.id)
				return

			R.loader.userVotes.set(@currentItem.id, result.positive)

			# @currentItem.votes = result.votes
			
			delay = moment.duration(result.delay, 'seconds').humanize()

			suffix = ''
			if result.validates
				suffix = ', the ' + type + ' will be validated'

			else if result.rejects
				suffix = ', the ' + type + ' will be rejected'

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

			# R.socket.emit "drawing change", type: 'votes', votes: @currentItem.votes, drawingId: @currentItem.id
			return

		vote: (positive)=>
			if R.city?.name == 'Maintenant'
				R.alertManager.alert "L'installation Espero est terminée, vous ne pouvez plus voter.", 'info'
				return
			
			type = if @currentItem.itemType == 'tile' then 'tile' else 'drawing'

			if @currentItem.owner == R.me
				R.alertManager.alert 'You cannot vote for your own ' + type, 'error'
				return
			
			if (not R.administrator) and type == 'drawing' and @currentItem.status != 'pending' or type == 'tile' and @currentItem.status != 'created'
				R.alertManager.alert 'The ' + type + ' is already validated', 'error'
				return
			
			if @hasAlreadyVoted()
				R.alertManager.alert 'You already voted for this ' + type, 'error'
				return

			args =
				pk: @currentItem.pk
				date: Date.now()
				positive: positive
				itemType: type

			R.loader.showLoadingBar(500)
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'vote', args: args } ).error(R.loader.displayError).done(@voteCallback)

			return

		voteUp: ()=>
			@vote(true)
			return

		voteDown: ()=>
			@vote(false)
			return

		### submit modify cancel drawing ###

		submitDrawing: ()=>

			if not @currentItem?
				return

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to submit a " + @currentItem.itemType, "error"
				return
			
			title = @contentJ.find('#drawing-title').val()
			description = @contentJ.find('#drawing-description').val()
			
			if title.length == 0
				R.alertManager.alert "You must enter a title", "error"
				return

			# if description.length == 0
			# 	R.alertManager.alert "You must enter a description", "error"
			# 	return

			@currentItem.title = title
			@currentItem.description = description

			@currentItem.submit()
			
			@close(false)

			return

		modifyDrawing: ()=>

			if not @currentItem?
				return

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to submit a " + @currentItem.itemType, "error"
				return

			if @currentItem.itemType == 'drawing' and @currentItem.status != 'pending' and @currentItem.status != 'emailNotConfirmed' and @currentItem.status != 'notConfirmed'
				R.alertManager.alert "The drawing is already validated, it cannot be modified anymore", "error"
				return				

			@currentItem.update( { title: @contentJ.find('#drawing-title').val(), data: @contentJ.find('#drawing-description').val() } )
			
			return

		moveDrawing: ()=>
			if not @currentItem? then return
			if not R.administrator then return

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to submit a " + @currentItem.itemType, "error"
				return
			R.s.loadPathList(()=>
				R.tools.moveDrawing.select()
				R.tools.moveDrawing.moveSelectedDrawing = true
			)
			return
		
		cancelDrawing: ()=>
			if @currentItem.itemType == 'discussion'
				@cancelDiscussion()
				return

			if @currentItem.itemType == 'tile'
				@cancelTile()
				return

			if not @currentItem?
				@close()
				return

			if not @currentItem.pk? or @currentItem.status == 'draft'
				@close()
				return

			if @currentItem.status != 'pending' && @currentItem.status != 'draft' && @currentItem.status != 'emailNotConfirmed' && @currentItem.status != 'notConfirmed'
				R.alertManager.alert "The drawing is already validated, it cannot be cancelled anymore", "error"
				return	

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to cancel a drawing", "error"
				return

			draft = Item.Drawing.getDraft()
			if draft? and draft.paths?.length > 0
				R.alertManager.alert "You must submit your draft before cancelling a drawing", "error"
				return

			# if @currentItem.
			# 	return

			modal = Modal.createModal( 
				id: 'modify-drawing',
				title: 'Modify drawing', 
				submit: ( ()=> 
					@currentItem.cancel()
					@close()
					return),
				submitButtonText: 'Modify drawing', 
				submitButtonIcon: 'glyphicon-pencil',
				)
		
			modal.addText('Are you sure you really want to modify the drawing')
			modal.addText('This will reset the votes and comments of the drawing')
			modal.modalJ.find('[name="submit"]').addClass('btn-danger').removeClass('btn-primary')
			modal.show()
			return

		cancelDiscussion: ()->
			R.tools.discuss.removeCurrentDiscussion()
			@close()
			return

		cancelTile: ()=>

			if not @currentItem?
				@close()
				return

			if not @currentItem.pk?
				@close()
				return

			if not R.me? or not _.isString(R.me)
				R.alertManager.alert "You must be logged in to cancel a tile", "error"
				return

			R.loader.showLoadingBar(500)
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'cancelTile', args: { 'pk': @currentItem.pk } } ).error(R.loader.displayError).done( (result)=> @cancelTileCallback(result) )

			@close()

			return

		cancelTileCallback: (result)->
			R.loader.hideLoadingBar()
			if not R.loader.checkError(result) then return
			tile = JSON.parse(result.tile)
			R.tools.choose.removeTile(tile)
			return

		# deleteDrawing: ()=>

		# 	if not R.me? or not _.isString(R.me)
		# 		R.alertManager.alert "You must be logged in to delete a drawing", "error"
		# 		return

		# 	if not @currentItem?
		# 		@close()
		# 		return

		# 	if @currentItem.pk?
		# 		R.alertManager.alert "Please cancel the drawing before deleting its paths", "error"
		# 		@close()
		# 		return

		# 	modal = Modal.createModal( title: 'Delete all paths', submit: @deletePaths, postSubmit: 'hide' )
		# 	modal.addText('Do you really want to delete the selected paths?')
		# 	modal.show()

		# 	return

	return DrawingPanel
