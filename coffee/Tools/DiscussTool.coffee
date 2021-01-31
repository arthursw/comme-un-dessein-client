define ['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'Items/Item', 'Items/Discussion', 'Commands/Command', 'UI/Modal', 'i18next', 'moment' ], (P, R, Utils, Tool, Item, Discussion, Command, Modal, i18next, moment) ->

	class DiscussTool extends Tool

		@label = 'Discuss'
		@popover = false
		# @description = ''
		# @iconURL = 'glyphicon-envelope'
		# @iconURL = 'cursor.png'
		# @iconURL = if R.style == 'line' then 'chooser3.png' else if R.style == 'hand' then 'chooser3.png' else 'chooser3.png'
		@iconURL = 'new 1/Discuss.svg'
		@buttonClasses = 'displayName'

		@cursor =
			position:
				x: 0, y: 0
			name: 'pointer'


		constructor: () ->
			if not R.isCommeUnDessein
				super(true)

			@discussions = new Map()
			@currentDiscussion = null

			return

		select: (deselectItems=false, updateParameters=true, forceSelect=false, selectedBy='default')->
			if R.isCommeUnDessein then return
			if R.city?.finished
				R.alertManager.alert "Cette édition est terminée, vous ne pouvez plus discuter.", 'info'
				return

			if not R.userAuthenticated and not forceSelect
				R.alertManager.alert 'Log in before discussing', 'info'
				return

			R.tracer?.hide()

			super(false, updateParameters, selectedBy)
			R.tools.select.deselectAll()
			return

		deselect: ()->
			if R.isCommeUnDessein then return
			super

			# Delete current discussion if it was not submitted and close panel
			if @currentDiscussion? and @currentDiscussion.status == 'draft'
				@removeCurrentDiscussion()
				R.drawingPanel.close()
			return

		begin: (event) ->
			if not R.view.grid.limitCDRectangle.contains(event.point) then return

			discussions = R.view.discussionLayer.getItems( match: (item)-> return item.data.type == 'discussion' and item.bounds.contains(event.point))

			@clickedDiscussions = null
			if discussions? and discussions.length > 0
				@clickedDiscussions = discussions
				return

			@currentDiscussion = new Discussion(event.point)
			@discussions.set(@currentDiscussion.id, @currentDiscussion)

			return

		update: (event) ->
			@currentDiscussion?.setPosition(event.point)
			return

		move: (event) ->
			if R.isCommeUnDessein then return
			if event.originalEvent?.target != document.getElementById('canvas') then return
			return

		end: (event) ->
			if R.isCommeUnDessein then return
			if not R.view.grid.limitCDRectangle.contains(event.point) then return
			
			if @clickedDiscussions? and event.point.equals(event.downPoint)
				@currentDiscussion = Utils.Array.random(@clickedDiscussions).data.discussion
				if @clickedDiscussions.length > 1
					R.alertManager.alert "Click again to select other discussion at this point", 'info'
				@clickedDiscussions = null
				# R.drawingPanel.loadDiscussion(@currentDiscussion)
				R.drawingPanel.openDiscussion(@currentDiscussion)
				return

			@clickedDiscussions = null

			R.drawingPanel.addDiscussionClicked()

			return

		updateCurrentDiscussion: (text)->
			@currentDiscussion?.updateTitle(text)
			return

		centerOnDiscussion: ()->
			if not @currentDiscussion? then return
			R.view.fitRectangle(@currentDiscussion.rectangle.bounds, true)
			return

		doubleClick: (event) ->
			return

		keyUp: (event)->
			return

		removeCurrentDiscussion: ()->
			@currentDiscussion.delete()
			@discussions.delete(@currentDiscussion.clientId)
			@currentDiscussion = null
			return

		removeDisucssionsInRectangle: (rectangle)->
			if R.isCommeUnDessein then return
			console.log('remove discussions')

			@discussions.forEach (discussion, id) =>
				if rectangle.contains(discussion.rectangle.bounds)
					console.log('delete: ' + discussion.pointText.content)
					discussion.remove()
					@discussions.delete(discussion.id)
			return

		createDiscussion: (data)->
			bounds = R.view.grid.boundsFromBox(data.box)
			pk = data._id.$oid
			discussion = new Discussion(bounds.center, data.title, data.clientId, pk, data.owner, 'loaded')
			console.log('create: ' + discussion.pointText.content)
			@discussions.set(discussion.id, discussion)
			return

	R.Tools.Discuss = DiscussTool
	return DiscussTool


			# document.addEventListener('input', ((event) => 
			# 	if not $(event.target).hasClass('autoExpand') then return
			# 	@autoExpand(event.target)
			# ), false)


			# rectangle = @rectangle.clone()
			# rectangle.fillColor = 'black'
			# rectangle.opacity = 0.7
			# rectangle.position.x = rectangle.bounds.width / 2
			# rectangle.position.y = rectangle.bounds.height / 2
			# rectangleSvg = rectangle.exportSVG( asString: false )
			# rectangle.remove()

			# x = @rectangle.bounds.left
			# y = @rectangle.bounds.top
			
			# # # svg.setAttribute( 'fill', 'black')
			
			# # textJ = $("""
			# # <foreignObject x="0" y="0">
			# # 	<textarea xmlns="http://www.w3.org/1999/xhtml" style="width: 200px;height: 300px">Enter the title of your discussion here</textarea>
			# # </foreignObject>
			# # """)

			# svgNS = 'http://www.w3.org/2000/svg'

			# # g = document.createElementNS(svgNS, 'g')
			# # g.setAttribute( 'transform', 'translate(' + x + ' ' + y + ')')
			# # g.appendChild(rectangleSvg)

			# # foreignObject = document.createElementNS(svgNS, 'foreignObject')
			# g = document.createElementNS(svgNS, 'g')
			# textarea = document.createElement('input')
			# # foreignObject.setAttribute('type', 'text')

			# g.setAttribute('x', 0)
			# g.setAttribute('y', 0)
			# # foreignObject.setAttribute('width', @rectangle.bounds.width)
			# # foreignObject.setAttribute('height', @rectangle.bounds.height)
			# $(g).css('background-color': 'white', 'border': '3px solid ' + R.selectionBlue)
			# textarea.setAttribute('xmlns', 'http://www.w3.org/1999/xhtml')
			# # textarea.setAttribute('rows', '10')
			# # textarea.setAttribute('cols', '50')
			# # textarea.textContent = 'Enter your text'
			# foreignObject.appendChild(textarea)

			# # text = document.createElementNS(svgNS, 'text')
			# # text.setAttribute('x', 0)
			# # text.setAttribute('y', 0)
			# # text.setAttribute('contentEditable', 'true')
			# # text.setAttribute('width', @rectangle.bounds.width)
			# # text.setAttribute('height', @rectangle.bounds.height)
			
			# # $(text).css({ 'font-family': 'Patrick Hand', 'font-size': '90px', 'color': 'black' })
			# textareaJ = $(textarea)
			# textareaJ.css({ 'font-family': 'Patrick Hand', 'font-size': '90px', 'color': 'black', 'width': '100%' })
			# textareaJ.addClass('autoExpand')

			# # text.textContent = 'Enter your text'

			# # svg.setAttribute('transform', 'translate(' + x + ' ' + y + ')')
			# foreignObject.setAttribute('transform', 'translate(' + x + ' ' + y + ')')
			# # svg.appendChild(text)
			# # svg.appendChild(foreignObject)
			# setTimeout((()->textarea.focus()), 100)

			# # textJ = $('<text x="0" y="0">Enter the title of your discussion here</text>')

			# # textJ.attr('width', @rectangle.bounds.width)
			# # textJ.attr('height', @rectangle.bounds.height)
			# # textJ.attr( 'transform', 'translate(' + x + ' ' + y + ')')

			# # textJ.find('textarea').css({ 'font-family': 'Patrick Hand', 'font-size': '90px', 'color': 'black' })

			# # textJ = $('<textarea>').append(i18next.t('Enter the title of your discussion here')).css({ 'font-family': 'Patrick Hand', 'font-size': '90px', 'color': 'black' })
			
			# # textJ.attr('x', @rectangle.bounds.left)
			# # textJ.attr('y', @rectangle.bounds.top)
			# # textJ.attr('width', @rectangle.bounds.width)
			# # textJ.attr('height', @rectangle.bounds.height)
			
			# # textJ.css( 'transform': 'translate(' + @rectangle.bounds.left + 'px, ' + @rectangle.bounds.top + 'px)' )

			# # document.getElementById('discussionLayer').appendChild($(svg).clone().get(0))
			# # document.getElementById('discussionLayer').appendChild(textJ.clone().get(0))

			# # svg.appendChild(textJ.get(0))
			# # document.getElementById('discussionLayer').appendChild(svg)
			# # document.getElementById('discussionLayer').appendChild(textJ)
			# # R.discussionJ.find('g:first').append(svg)
			# R.discussionJ.find('g:first').get(0).appendChild(foreignObject)
			# @rectangle.remove()

			# @autoExpand(textarea)


		# autoExpand: (field) ->

		# 	# Reset field height
		# 	field.style.height = 'inherit'
		# 	field.parentElement.style.height = 'inherit'

		# 	# Get the computed styles for the element
		# 	computed = window.getComputedStyle(field)

		# 	# Calculate the height
		# 	borderTopWidth = parseInt(computed.getPropertyValue('border-top-width'), 10)
		# 	paddingTop = parseInt(computed.getPropertyValue('padding-top'), 10)
		# 	paddingBottom = parseInt(computed.getPropertyValue('padding-bottom'), 10)
		# 	borderBottomWidth = parseInt(computed.getPropertyValue('border-bottom-width'), 10)

		# 	height = borderTopWidth + paddingTop + field.scrollHeight + paddingBottom + borderBottomWidth

		# 	field.style.height = height + 'px'
		# 	field.parentElement.style.height = height + 'px'

		# 	return

		# createTextArea: (bounds)->
		# 	console.log("createTextArea")
		# 	console.log(bounds)
		# 	rectangle = new P.Rectangle(bounds)
			
		# 	textareaJ = $('<textarea>')
		# 	textareaJ.text('Enter your text here...')
		# 	textareaJ.css({
		# 		position: 'absolute'
		# 		top: rectangle.top
		# 		left: rectangle.left
		# 		width: rectangle.width
		# 		height: rectangle.height
		# 		'z-index': 100
		# 		})

		# 	$('body').append(textareaJ)
		# 	textareaJ.focus()

		# 	return