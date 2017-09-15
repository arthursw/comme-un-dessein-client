define ['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'UI/Modal', 'i18next' ], (P, R, Utils, Tool, Modal, i18next) ->

	class Button

		@createSubmitButton: ()->
			@submitButton = new Button({
				name: 'Submit drawing'
				favorite: true
				iconURL: 'icones_icon_ok.png'
				# order: 0
				classes: 'btn-success displayName'
				onClick: ()=>
					R.drawingPanel.submitDrawingClicked()
					return
			})
			@submitButton.hide()
			return

		# @clearDrawing: ()->
		# 	draft = R.Drawing.getDraft()
		# 	if draft?
		# 		draft.removePaths()
		# 	return

		@createDeleteButton: ()->
			@deleteButton = new Button({
				name: 'Delete draft'
				favorite: true
				iconURL: 'icones_cancel.png'
				# order: 0
				classes: 'btn-danger'
				onClick: ()=>
					draft = R.Drawing.getDraft()
					if draft?
						draft.removePaths(true)
					return
			})
			@deleteButton.hide()
			return

		@updateSubmitButtonVisibility: (draft=null)->
			draft ?= R.Drawing.getDraft()
			if not draft? or not draft.paths? or draft.paths.length == 0 or R.drawingPanel.visible
				@submitButton.hide()
				@deleteButton.hide()
				R.tools.eraser.btn.hide()
			else
				@submitButton.show()
				@deleteButton.show()
				R.tools.eraser.btn.show()
			return

		constructor: (parameters)->
			@visible = true
			name = parameters.name
			iconURL = parameters.iconURL
			favorite = parameters.favorite
			category = parameters.category
			order = parameters.order
			classes = parameters.classes
			@file = parameters.file
			onClick = parameters.onClick

			parentJ = R.sidebar.allToolsJ
			if category? and category != ""
				# split into sub categories
				categories = category.split("/")

				for category in categories
					# look for category
					ulJ = parentJ.find("li[data-name='#{category}'] > ul")
					if ulJ.length==0
						liJ = $("<li data-name='#{category}'>")
						liJ.addClass('category')
						hJ = $('<h6>')
						hJ.text(category).addClass("title")
						liJ.append(hJ)
						ulJ = $("<ul>")
						ulJ.addClass('folder')
						liJ.append(ulJ)
						hJ.click(@toggleCategory)
						parentJ.append(liJ)

					parentJ = ulJ

			# initialize button
			@btnJ = $("<li>")
			@btnJ.attr("data-name", name)
			# @@btnJ.attr("data-cursor", @cursorDefault)
			@btnJ.attr("alt", name)
			
			if classes? and classes.length > 0
				@btnJ.addClass(classes)

			if iconURL? and iconURL != '' 															# set icon if url is provided
				if iconURL.indexOf('glyphicon') == 0
					@btnJ.append('<span class="glyphicon ' + iconURL + '" alt="' + name + '-icon">')
					if parameters.transform?
						@btnJ.find('span.glyphicon').css( transform: parameters.transform )
				else
					iconRootURL = 'static/images/icons/inverted/'
					if iconURL.indexOf('//') < 0 and iconURL.indexOf(iconRootURL) < 0
						iconURL = iconRootURL + iconURL
					if iconURL.indexOf(iconRootURL) == 0
						iconURL = location.origin + '/' + iconURL
					@btnJ.append('<img src="' + iconURL + '" alt="' + name + '-icon">')
			else 																					# create icon if url is not provided
				@btnJ.addClass("text-btn")
				words = name.split(" ")
				shortName = ""
																# the icon will be made with
				if words.length>1 								# the first letter of each words of the name
					shortName += word.substring(0,1) for word in words
				else 											# or the first two letters of the name (if it has only one word)
					shortName += name.substring(0,2)
				shortNameJ = $('<span class="short-name">').text(shortName + ".")
				@btnJ.append(shortNameJ)

			parentJ.append(@btnJ)

			toolNameJ = $('<span class="tool-name">')
			toolNameJ.attr('data-i18n', name).text(i18next.t(name))
			@btnJ.append(toolNameJ)
			@btnJ.addClass("tool-btn")
			favoriteBtnJ = $("""<button type="button" class="btn btn-default favorite-btn">
	  			<span class="glyphicon glyphicon-star" aria-hidden="true"></span>
			</button>""")
			favoriteBtnJ.click(R.sidebar.toggleToolToFavorite)

			@btnJ.append(favoriteBtnJ)
			@btnJ.attr('data-order': if order? then order else 999)

			if onClick?
				@btnJ.click(onClick)
			else
				@btnJ.click(if @file? then @onClickWhenNotLoaded else @onClickWhenLoaded)


			if favorite
				R.sidebar.toggleToolToFavorite(null, @btnJ, @)

			if parameters.description? or parameters.popover
				@addPopover(parameters)

			if parameters.preload
				@onClickWhenNotLoaded()
			return

		addPopover: (parameters)->
			# initialize the popover (help tooltip)
			# popoverOptions =
			# 	placement: 'right'
			# 	container: 'body'
			# 	trigger: 'hover'
			# 	delay:
			# 		show: 500
			# 		hide: 100

			@btnJ.attr('data-placement', 'bottom')
			@btnJ.attr('data-container', 'body')
			@btnJ.attr('data-trigger', 'hover')
			@btnJ.attr('data-delay', {show: 500, hide: 100})

			if not parameters.description? or parameters.description == ''
				# popoverOptions.content = parameters.name
				@btnJ.attr('data-content', parameters.name)
			else
				# popoverOptions.title = parameters.name
				# popoverOptions.content = parameters.description
				@btnJ.attr('data-title', parameters.name)
				@btnJ.attr('data-content', parameters.description)

			@btnJ.popover()
			return

		toggleCategory: (event)->
			categoryJ = $(this).parent()
			categoryJ.toggleClass('closed')
			categoryJ.children('.folder').children().show()
			return

		fileLoaded: ()=>
			@btnJ.off('click')
			@btnJ.click(@onClickWhenLoaded)
			@onClickWhenLoaded()
			return

		onClickWhenNotLoaded: (event)=>
			require([@file], @fileLoaded)
			return

		onClickWhenLoaded: (event)=>
			toolName = @btnJ.attr("data-name")
			R.tools[toolName]?.select()
			return

		hide: ()->
			@visible = false
			@btnJ.hide()
			if @cloneJ?
				@cloneJ.hide()
			return

		show: ()->
			@visible = true
			@btnJ.show()
			if @cloneJ?
				@cloneJ.show()
			return

	R.Button = Button
	return Button
