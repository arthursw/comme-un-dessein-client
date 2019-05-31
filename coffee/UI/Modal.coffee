define ['paper', 'R', 'Utils/Utils', 'i18next'], (P, R, Utils, i18next) ->

	class Modal

		@modalJ = $('#customModal')
		@modals = []

		@createModal: (args)->
			modal = new Modal(args)
			if @modals.length>0
				zIndex = parseInt(_.last(@modals).modalJ.css('z-index'))
				modal.modalJ.css('z-index', zIndex + 2)
			@modals.push(modal)
			return modal

		@deleteModal: (modal)->
			modal.delete()
			return

		@getModalByTitle: (title)->
			for modal in @modals
				if modal.title == title
					return modal
			return null

		@getModalByName: (name)->
			for modal in @modals
				if modal.name == name
					return modal
			return null

		# # args: title: 'Title'
		constructor: (args)->
			@data = data: args.data
			@title = args.title
			@name = args.name
			@validation = args.validation
			@postSubmit = args.postSubmit or 'hide'
			@submitCallback = args.submit

			@extractors = [] 				# an array of function used to extract data on the added forms

			@modalJ = @constructor.modalJ.clone()
			@modalJ.attr('id', 'modal-'+args.id)

			R.templatesJ.find('.modals').append(@modalJ)

			@modalBodyJ = @modalJ.find('.modal-body')
			@modalBodyJ.empty()
			
			@modalJ.find(".modal-footer").show().find(".btn").show()

			@modalJ.on 'shown.bs.modal', (event)=>
				@modalJ.find('input.form-control:visible:first').focus()
				zIndex = parseInt(@modalJ.css('z-index'))
				$('body').find('.modal-backdrop:last').css('z-index', zIndex - 1)

			@modalJ.on('hidden.bs.modal', @delete)

			if args.submitButtonText?
				spanJ = $('<span>')
				spanJ.attr('data-i18n', args.submitButtonText).append(i18next.t(args.submitButtonText))
				@modalJ.find('[name="submit"]').removeAttr('data-i18n').html(spanJ)
			
			if args.submitButtonIcon?
				iconJ = $('<span>')
				iconJ.addClass('glyphicon ' + args.submitButtonIcon)
				@modalJ.find('[name="submit"]').prepend(iconJ)

			
			if args.cancelButtonText?
				spanJ = $('<span>')
				spanJ.attr('data-i18n', args.cancelButtonText).append(i18next.t(args.cancelButtonText))
				@modalJ.find('[name="cancel"]').html(spanJ)

			if args.cancelButtonIcon?
				iconJ = $('<span>')
				iconJ.addClass('glyphicon ' + args.cancelButtonIcon)
				@modalJ.find('[name="cancel"]').removeAttr('data-i18n').prepend(iconJ)

			@modalJ.find('.btn-primary').click( (event)=> @modalSubmit() )

			@extractors = {}
			@modalJ.find("h4.modal-title").attr('data-i18n', args.title).html(i18next.t(args.title))

			return

		addText: (text, textKey=null, escapeValue=false, options=null)->
			textKey ?= text
			options ?= {}
			options.interpolation ?= {}
			options.interpolation.escapeValue = escapeValue
			content = i18next.t(textKey, options)
			divJ = $("<p data-i18n-options='#{JSON.stringify(options)}' data-i18n='[html]#{textKey}'>#{content}</p>")
			@modalBodyJ.append(divJ)
			return divJ

		addTextInput: (args)->
			name = args.name
			placeholder = args.placeholder
			type = args.type
			className = args.className
			label = args.label
			submitShortcut = args.submitShortcut
			id = args.id
			required = args.required
			errorMessage = args.errorMessage
			defaultValue = args.defaultValue

			if required
				errorMessage ?= "<em>" + (label or name) + "</em> is invalid."

			submitShortcut = if submitShortcut then 'submit-shortcut' else ''
			inputJ = $("<input type='#{type}' class='#{className} form-control #{submitShortcut}'>")
			if placeholder? and placeholder != ''
				inputJ.attr("placeholder", placeholder)
			inputJ.val(defaultValue)
			args = inputJ

			extractor = (data, inputJ, name, required=false)->
				data[name] = inputJ.val()
				return ( not required ) or ( not inputJ.is(':visible') ) or ( data[name]? and data[name] != '' )

			if label
				inputId = 'modal-' + name + '-' + Math.random().toString()
				inputJ.attr('id', inputId)
				divJ = $("<div id='#{id}' class='form-group #{className}-group'></div>")
				labelJ = $("<label for='#{inputId}'>" + i18next.t(label) + "</label>")
				labelJ.attr('data-i18n', label)
				divJ.append(labelJ)
				divJ.append(inputJ)
				inputJ = divJ

			@addCustomContent( { name: name, divJ: inputJ, extractor: extractor, args: args, required: required, errorMessage: errorMessage } )

			return inputJ

		addCheckbox: (args)->
			name = args.name
			label = args.label
			helpMessage = args.helpMessage
			defaultValue = args.defaultValue

			divJ = $("<div>")
			divJ.addClass('checkbox')

			checkboxJ = $("<label><input type='checkbox' form-control>#{label}</label>")
			if defaultValue
				checkboxJ.find('input').attr('checked', true)
			divJ.append(checkboxJ)

			if helpMessage
				helpMessageJ = $("<p class='help-block'>#{helpMessage}</p>")
				divJ.append(helpMessageJ)

			extractor = (data, checkboxJ, name)->
				data[name] = checkboxJ.find('input').is(':checked')
				return true

			@addCustomContent( { name: name, divJ: divJ, extractor: extractor, args: checkboxJ } )

			return divJ

		addRadioGroup: (args)->
			name = args.name
			radioButtons = args.radioButtons

			divJ = $("<div>")

			for radioButton in radioButtons
				radioJ = $("<div class='radio'>")
				labelJ = $("<label>")
				checked = if radioButton.checked then 'checked' else ''
				submitShortcut = if radioButton.submitShortcut then 'class="submit-shortcut"' else ''
				inputJ = $("<input type='radio' name='#{name}' value='#{radioButton.value}' #{checked} #{submitShortcut}>")
				labelJ.append(inputJ)
				labelJ.append(radioButton.label)
				radioJ.append(labelJ)
				divJ.append(radioJ)

			extractor = (data, divJ, name, required=false)->
				choiceJ = divJ.find("input[type=radio][name=#{name}]:checked")
				data[name] = choiceJ[0]?.value
				return ( not required ) or ( not divJ.is(':visible') ) or ( data[name]? )

			@addCustomContent( { name: name, divJ: divJ, extractor: extractor } )

			return divJ

		addTable: (data)->
			tableJ = $("<table class='.table'>")
			@modalBodyJ.append(tableJ)
			tablePath = 'table'
			require [tablePath], ()->
				tableJ.bootstrapTable(data)
				return
			return tableJ

		addImageSelector: (args)->
			name = args.name or 'image-selector'

			divJ = $("""
				<div class="form-group url-group">
					<label>Add your image</label>
					<input data-name='#{name}-file-selector' type="file" class="form-control" name="file[]"/>
					<div data-name='#{name}-drop-zone' style="border: 2px dashed #bbb;padding: 25px;text-align: center;color: #bbb;">
						<div data-name='#{name}-gallery'></div>
						Drop your image file here.
					</div>
				</div>
			""")

			@data.imageSelector =
				nRasterLoaded: 0
				nRastersLoaded: 0
				rasters: {}
				rastersLoadedCallback: args.rastersLoadedCallback

			handleFileSelect = (event) =>
				event.stopPropagation()
				event.preventDefault()
				files = event.dataTransfer?.files or event.target?.files

				# FileList object
				# Loop through the FileList and render image files as thumbnails.

				@data.imageSelector.nRasterToLoad = files.length

				i = 0
				f = undefined
				while f = files[i]
					if @data.imageSelector.rasters.hasOwnProperty(f) then continue
					# Only process image files.
					if not f.type.match('image.*')
						i++
						continue
					reader = new FileReader
					# Closure to capture the file information.
					reader.onload = ((file, data) ->
						(event)->
							imageSelector = data.imageSelector
							# Render thumbnail.
							span = document.createElement('span')
							span.innerHTML = [ '<img class="thumb" src="' + event.target.result + '" title="' + escape(file.name) + '"/>' ].join('')
							divJ.find('[data-name="'+name+'-gallery"]').append(span)

							if not args.svg
								imageSelector.rasters[file] = new P.Raster(event.target.result)
							else
								span.innerHTML = event.target.result
								svg = span.querySelector('svg')
								SVGLayer = new P.Layer()
								imageSelector.rasters[file] = P.project.importSVG(svg)
								SVGLayer.remove()

							imageSelector.nRasterLoaded++
							if imageSelector.nRasterLoaded == imageSelector.nRasterToLoad
								imageSelector.rastersLoadedCallback(imageSelector.rasters)
							return
					)(f, @data)
					# Read in the image file as a data URL.
					if not args.svg
						reader.readAsDataURL f
					else
						reader.readAsText f
					i++
				return

			handleDragOver = (event) ->
				event.stopPropagation()
				event.preventDefault()
				event.dataTransfer.dropEffect = 'copy'
				return

			divJ.find('[data-name="'+name+'-file-selector"]').change(handleFileSelect)

			dropZone = divJ.find('[data-name="'+name+'-drop-zone"]')[0]
			dropZone.addEventListener 'dragover', handleDragOver, false
			dropZone.addEventListener 'drop', handleFileSelect, false

			@addCustomContent( { name: name, divJ: divJ, extractor: args.extractor or () -> true } )
			return divJ

		addCustomContent: (args)->
			args.args ?= args.divJ
			if args.name?
				args.divJ.attr('id', 'modal-' + args.name)
			@modalBodyJ.append(args.divJ)
			if args.extractor?
				@extractors[args.name] = args
			return

		# args:
		# - type: bootstrap button type / appearance
		# - name: name
		# - submit: submit function
		addButton: (args)->
			args.type ?= 'default'

			icon = if args.icon? then "<span class='glyphicon #{args.icon}'></span>" else ''
			text = "<span data-i18n='#{args.name}'>#{i18next.t(args.name)}</span>"

			buttonJ = $("<button type='button' class='btn btn-#{args.type}' name='#{args.name}'>" + icon + text + "</button>")
			
			if args.submit?
				buttonJ.click (event)=>
					args.submit(@data)
					buttonJ.remove()
					@hide()
					return

			submitButtonJ = @modalJ.find('.modal-footer .btn-primary[name="submit"]')
			if submitButtonJ.length > 0
				submitButtonJ.before(buttonJ)
			else
				@modalJ.find('.modal-footer .btn-primary').before(buttonJ)

			return buttonJ

		show: ()->
			@modalJ.find('.submit-shortcut').keypress (event) => 		# submit modal when enter is pressed
				if event.which == 13 	# enter key
					event.preventDefault()
					@modalSubmit()
				return
			@modalJ.modal('show')
			$('#templates').removeClass('hidden').show()
			return

		# the modal will be delete as soon as it is hidden
		hide: ()->
			@modalJ.modal('hide')
			return

		addProgressBar: ()->
			progressJ = $(""" <div class="progress modal-progress-bar">
				<div class="progress-bar progress-bar-striped active" role="progressbar" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style="width: 100%">
					<span class="sr-only" data-i18n="Loading">Loading...</span>
				</div>
			</div>""")
			@modalBodyJ.append(progressJ)
			return progressJ

		removeProgressBar: ()->
			@modalBodyJ.find('.modal-progress-bar').remove()
			return

		modalSubmit: ()->

			@modalJ.find(".error-message").remove()
			valid = true
			for name, extractor of @extractors
				valid &= extractor.extractor(@data, extractor.args, name, extractor.required)
				if not valid
					errorMessage = extractor.errorMessage
					errorMessage ?= 'The field "' + name + '"" is invalid.'
					@modalBodyJ.append("<div class='error-message'>#{errorMessage}</div>")

			if not valid or @validation? and not @validation(data) then return

			@submitCallback?(@data)
			@extractors = {}

			switch @postSubmit
				when 'hide'
					@modalJ.modal('hide')
				when 'load'
					@modalBodyJ.children().hide()
					@addProgressBar()
			return

		delete: ()=>
			$('#templates').hide()
			@modalJ.remove()
			Utils.Array.remove(@constructor.modals, @)
			return

	return Modal
