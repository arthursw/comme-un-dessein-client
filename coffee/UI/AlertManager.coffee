define ['paper', 'R', 'Utils/Utils', 'i18next'], (P, R, Utils, i18next) ->

	class AlertManager

		@hideDelay = 10000

		constructor: ()->
			@alertsContainer = $("#CommeUnDessein_alerts")
			# @alertsContainer.on( "blur", ()=> @hide() ) # not working... done in window.mouseup event in view
			
			@alertsContainer.find('button.show').click @show
			@alertsContainer.on( touchstart: @show )
			# @alertsContainer.mouseleave @hideDeferred

			@alerts = []
			@currentAlert = -1
			@alertTimeOut = null
			@alertsContainer.find(".btn-up").click( ()=> @showAlert(@currentAlert-1) )
			@alertsContainer.find(".btn-down").click( ()=> @showAlert(@currentAlert+1) )
			@alertsContainer.find(".btn-close").click( ()=> 
				R.ignoreNextAlert = true
				localStorage.setItem('showWelcomMessage', R.me)
				console.log(localStorage.getItem('showWelcomMessage'))
				@hide()
				return
			)
			
			return

		showAlert: (index)->
			if @alerts.length<=0 || index<0 || index>=@alerts.length then return  	# check that index is valid

			previousType = @alerts[@currentAlert]?.type
			@currentAlert = index

			alertData = @alerts[@currentAlert]

			alertJ = @alertsContainer.find(".alert")

			messageOptions = ''
			if alertData.messageOptions? and not alertData.messageOptions.html?
				messageOptions = "data-i18n-options='" + JSON.stringify(alertData.messageOptions) + "'"
			
			newAlertJ = $("<div class='alert fade in' data-i18n='" + alertData.message + "' " + messageOptions + ">")
			newAlertJ.addClass(alertData.type)
			
			if alertData.messageOptions?.html?
				newAlertJ.append(alertData.messageOptions.html)
			else
				text = if alertData.messageOptions? then i18next.t(alertData.message.replace(/\./g, ''), alertData.messageOptions) else i18next.t(alertData.message)
				newAlertJ.text(text)

			newAlertJ.insertAfter(alertJ)
			alertJ.remove()

			@alertsContainer.find(".alert-number").text(@currentAlert+1)
			return

		alert: (message, type="", delay=@constructor.hideDelay, messageOptions=null) ->
			# set type ('info' to default, 'error' == 'danger')
			if type.length==0
				type = "info"
			else if type == "error"
				type = "danger"

			type = " alert-" + type

			# find and show the alert box
			alertJ = @alertsContainer.find(".alert")
			@alertsContainer.removeClass("r-hidden")

			# append alert to alert array
			@alerts.push( { type: type, message: message, messageOptions: messageOptions } )

			if @alerts.length>0 		# activate alert box (required for the first time)
				@alertsContainer.addClass("activated")
				$('body').addClass("alert-activated")

			@showAlert(@alerts.length-1)

			# show and hide in *delay* milliseconds
			@show()
			@hideDeferred(delay)

			return

		show: ()=>
			if @alertTimeOut?
				clearTimeout(@alertTimeOut)
				@alertTimeOut = null
			
			alertJ = @alertsContainer.find(".alert")
			alertJ.css('background-color': null)

			@alertsContainer.addClass('show')
			setTimeout((()=> @alertsContainer.find('.show-btn-container').hide()), 250)

			R.sidebar.sidebarJ.addClass('r-alert')
			suffix = if @alertsContainer.hasClass('top') then '-top' else ''
			R.drawingPanel.drawingPanelJ.addClass('r-alert' + suffix)
			$('#timeline').addClass('r-alert' + suffix)
			$('#submit-drawing-button').addClass('r-alert' + suffix)
			@openning = true
			setTimeout((()=> @openning = null), 500)

			@nBlinks = 0

			if @blinkIntervalID?
				clearInterval(@blinkIntervalID)
				@blinkIntervalID = null

			blink = ()=>
				@nBlinks++
				if @nBlinks > 4
					clearInterval(@blinkIntervalID)
					@blinkIntervalID = null

				backgroundColor = alertJ.css('background-color')
				alertJ.css('background-color': 'white')
				alertJ.animate('background-color': backgroundColor, 250)
				return
			
			blink()

			@blinkIntervalID = setInterval(blink, 300)

			return

		hideDeferred: (delay=@constructor.hideDelay)=>
			if delay!=0
				if @alertTimeOut?
					clearTimeout(@alertTimeOut)
					@alertTimeOut = null
				@alertTimeOut = setTimeout(@hide, delay )
			return

		hideIfNoTimeout: ()->
			if not @alertTimeOut? and not @openning
				@hide()
			return

		hide: ()=>
			if @alertTimeOut?
				clearTimeout(@alertTimeOut)
				@alertTimeOut = null

			if @alertsContainer.hasClass('show')
				@alertsContainer.find('.show-btn-container').show().css( opacity: 0 ).animate( { opacity: 1 }, 250 )
			@alertsContainer.removeClass("show")
			R.sidebar.sidebarJ.removeClass('r-alert')
			suffix = if R.alertManager.alertsContainer.hasClass('top') then '-top' else ''
			R.drawingPanel.drawingPanelJ.removeClass('r-alert' + suffix)
			$('#timeline').removeClass('r-alert' + suffix)
			$('#submit-drawing-button').removeClass('r-alert' + suffix)
			return

	return AlertManager
