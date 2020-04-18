define ['paper', 'R', 'Utils/Utils', 'Items/Item', 'UI/Modal', 'i18next' ], (P, R, Utils, Item, Modal, i18next) ->

	class Discussion

		@discussionMargin = 20

		constructor: (point, title='Enter the title of your discussion', @id=null, @pk=null, @owner=R.me, @status='draft') ->
			@id ?= Utils.createId()

			@pointText = new P.PointText(point)
			@pointText.content = title
			@pointText.justification = 'center'
			@pointText.fontSize = '24px'
			@pointText.fontFamily = 'Open Sans'
			# @pointText.fontFamily = 'Patrick Hand'

			@rectangle = new P.Path.Rectangle(@pointText.bounds.expand(@constructor.discussionMargin))
			@rectangle.strokeColor = R.selectionBlue
			@rectangle.strokeScaling = false
			@rectangle.fillColor = 'white'
			@rectangle.opacity = 0.8
			# @rectangle.dashArray = [10, 4]

			@group = new P.Group()
			@group.addChild(@rectangle)
			@group.addChild(@pointText)
			@group.data.type = 'discussion'

			R.view.discussionLayer.addChild(@group)

			@group.data.discussion = @

			# if discussion is being loaded: adjust position so that center fits the point
			if @pk
				@group.position = point

			return

		setPosition: (point)->
			@group.position = point
			return

		defaultCallback: (result)->
			R.loader.hideLoadingBar()
			if not R.loader.checkError(result)
				return false
			return true

		update: (data)->
			@updateTitle(data.title)

			args = {
				pk: @pk
				title: @pointText.content
				bounds: @rectangle.bounds
			}
			R.loader.showLoadingBar()
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'updateDiscussion', args: args } ).done(@defaultCallback)

			return

		updateTitle: (text)->
			@pointText.content = text
			Utils.Rectangle.updatePathRectangle(@rectangle, @pointText.bounds.expand(@constructor.discussionMargin))
			return
		
		submit: () ->

			args = {
				clientId: @id
				title: @pointText.content
				bounds: @rectangle.bounds
				cityName: R.city.name
			}
			R.loader.showLoadingBar()
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'submitDiscussion', args: args } ).done(@submitCallback)

			return

		submitCallback: (result)=>
			if not @defaultCallback(result) then return

			@pk = result.pk
			# Used by DiscussTool to track if this was just created and must be deleted on DiscussTool.deselect()
			# Also used by drawing panel
			@status = 'submitted'

			return

		remove: ()->
			@group.remove()
			return

		delete: ()->
			@remove()

			args = {
				pk: @pk
			}
			R.loader.showLoadingBar()
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'deleteDiscussion', args: args } ).done(@defaultCallback)

			return

	R.Discussion = Discussion
	return Discussion

# TODO: https://stackoverflow.com/questions/30731290/how-to-set-x-frame-options-allow-from-in-nginx-correctly