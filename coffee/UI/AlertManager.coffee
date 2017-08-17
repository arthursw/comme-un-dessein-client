define ['paper', 'R', 'Utils/Utils', 'i18next'], (P, R, Utils, i18next) ->

	class AlertManager

		@hideDelay = 5000

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
			return

		showAlert: (index)->
			if @alerts.length<=0 || index<0 || index>=@alerts.length then return  	# check that index is valid

			previousType = @alerts[@currentAlert]?.type
			@currentAlert = index

			alertData = @alerts[@currentAlert]

			alertJ = @alertsContainer.find(".alert")

			messageOptions = ''
			if alertData.messageOptions?
				messageOptions = "data-i18n-options='" + JSON.stringify(alertData.messageOptions) + "'"
			newAlertJ = $("<div class='alert fade in' data-i18n='" + alertData.message + "' " + messageOptions + ">")
			newAlertJ.addClass(alertData.type)
			
			text = if alertData.messageOptions? then i18next.t(alertData.message, alertData.messageOptions) else i18next.t(alertData.message)
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

			if @alerts.length>0 then @alertsContainer.addClass("activated") 		# activate alert box (required for the first time)

			@showAlert(@alerts.length-1)

			# show and hide in *delay* milliseconds
			@show()
			@hideDeferred(delay)

			return

		show: ()=>
			if @alertTimeOut?
				clearTimeout(@alertTimeOut)
				@alertTimeOut = null
			R.alertManager.alertsContainer.addClass('show')
			R.sidebar.sidebarJ.addClass('r-alert')
			R.drawingPanel.drawingPanelJ.addClass('r-alert')
			@openning = true
			setTimeout((()=> @openning = null), 500)
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
			@alertsContainer.removeClass("show")
			R.sidebar.sidebarJ.removeClass('r-alert')
			R.drawingPanel.drawingPanelJ.removeClass('r-alert')
			return

	return AlertManager
