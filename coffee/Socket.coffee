define ['paper', 'R', 'Utils/Utils', 'socket.ioID', 'i18next' ], (P, R, Utils, ioo, i18next) ->

	class Socket 

		constructor: ()->
			@initialize()
			return

		emit: ()->
			@socket.emit.apply(@socket, arguments)
			return
		# websocket communication
		# websockets are only used to transfer user actions in real time, however every request which will change the database are made with ajax (at a lower frequency)
		# this is due to historical and security reasons

		# todo: add a "n new messages" message at the bottom of the chat box when a user has new messages and he does not focus the chat
		# initialize socket:
		initialize: ()->

			@userToPaths = new Map()
			@userToColor = new Map()
			@fadeTailsIntervalID = null

			# initialize jQuery objects
			@chatJ = $("#chatContent")
			@chatMainJ = @chatJ.find("#chatMain")
			@chatRoomJ = @chatMainJ.find("#chatRoom")
			@chatUsernamesJ = @chatMainJ.find("#chatUserNames")
			@chatMessagesJ = @chatMainJ.find("#chatMessages")
			# R.chatMessagesScrollJ = @chatMainJ.find("#chatMessagesScroll")
			@chatMessageJ = @chatMainJ.find("#chatSendMessageInput")
			@chatMessageJ.blur()
			# R.chatMessagesScrollJ.nanoScroller()

			# add message to chat message box
			# scroll sidebar and message box to bottom (depending on who is talking)
			# @param [String] message to add
			# @param [String] (optional) username of the author of the message
			# 				  if *from* is set to R.me, "me" is append before the message,
			# 				  if *from* is set to another user, *from* is append before the message,
			# 				  if *from* is not set, nothing is append before the message

			if R.offline
				@socket =
					emit: ()-> return
				return

			@socket = io.connect("/chat")

			# on connect: update room (join the room "x: X, y: Y")
			@socket.on "connect", @updateRoom

			# on annoucement:
			@socket.on "announcement", @addMessage

			# on nicknames:
			@socket.on "nicknames", (nicknames) =>
				console.log 'nicknames'
				@chatUsernamesJ.empty().append("<span data-i18n='Online'>"+i18next.t('Online')+"</span>: ")
				for i of nicknames
					@chatUsernamesJ.append $("<b>").text( if i>0 then ', ' + nicknames[i] else nicknames[i] )
				return

			# on message to room
			@socket.on "msg_to_room", (from, msg) =>
				@addMessage(msg, from)
				return

			@socket.on "reconnect", =>
				console.log 'reconnect'
				@chatMessagesJ.remove()
				@addMessage("Reconnected to the server", "System")
				return

			@socket.on "reconnecting", =>
				console.log 'reconnecting'
				@addMessage("Attempting to re-connect to the server", "System")
				return

			@socket.on "error", (e) =>
				console.log 'error'
				console.log e
				@addMessage((if e then e else "A unknown error occurred"), "System")
				return

			@chatMainJ.find("#chatSendMessageSubmit").click(@sendMessage)

			# on key press: send message if key is return
			@chatMessageJ.keypress(@onKeyPress)

			@chatConnectionTimeout = setTimeout(@onConnectionError, 2000)

			
			if R.userAuthenticated
				@startChatting(R.me)
			else 						# if user not logged: set a random name
				@initializeUserName()

			## Tool creation websocket messages
			# on begin, update and end: call *tool*.begin(objectToEvent(*event*), *from*, *data*)

			# @socket.on "begin", (from, event, tool, data) ->
			# 	# if from == R.me then return	# should not be necessary since "emit_to_room" from gevent socektio's Room mixin send it to everybody except the sender
			# 	console.log "begin"
			# 	R.tools[tool].begin(objectToEvent(event), from, data)
			# 	return

			# @socket.on "update", (from, event, tool) ->
			# 	console.log "update"
			# 	R.tools[tool].update(objectToEvent(event), from)
			# 	P.view.update()
			# 	return

			# @socket.on "end", (from, event, tool) ->
			# 	console.log "end"
			# 	R.tools[tool].end(objectToEvent(event), from)
			# 	P.view.update()
			# 	return

			# @socket.on "setPK", (from, pid, pk) ->
			# 	console.log "setPK"
			# 	R.items[pid]?.setPK(pk, false)
			# 	return

			# @socket.on "delete", (pk) ->
			# 	console.log "delete"
			# 	R.items[pk]?.remove()
			# 	P.view.update()
			# 	return

			# @socket.on "beginSelect", (from, pk, event) ->
			# 	console.log "beginSelect"
			# 	R.items[pk].beginSelect(objectToEvent(event), false)
			# 	P.view.update()
			# 	return

			# @socket.on "updateSelect", (from, pk, event) ->
			# 	console.log "updateSelect"
			# 	R.items[pk].updateSelect(objectToEvent(event), false)
			# 	P.view.update()
			# 	return

			# @socket.on "doubleClick", (from, pk, event) ->
			# 	console.log "doubleClick"
			# 	R.items[pk].doubleClick(objectToEvent(event), false)
			# 	P.view.update()
			# 	return

			# @socket.on "endSelect", (from, pk, event) ->
			# 	console.log "endSelect"
			# 	R.items[pk].endSelect(objectToEvent(event), false)
			# 	P.view.update()
			# 	return

			# @socket.on "createDiv", (data) ->
			# 	console.log "createDiv"
			# 	Div.saveCallback(data, false)

			# @socket.on "deleteDiv", (pk) ->
			# 	console.log "deleteDiv"
			# 	R.items[pk]?.remove()
			# 	P.view.update()
			# 	return

			# # on parameter change:
			# # set items[pk].data[name] to value and call parameterChanged
			# # experimental *type* == 'rFunction' to call a custom function of the item
			# @socket.on "parameterChange", (from, pk, name, value, type=null) ->
			# 	if type != "rFunction"
			# 		R.items[pk].setParameter(name, value)
			# 	else
			# 		R.items[pk][name]?(false, value)
			# 	P.view.update()
			# 	return

			@socket.on "bounce", @onBounce

			@socket.on "drawing change", @onDrawingChange

			@socket.on "draw begin", @onDrawBegin
			@socket.on "draw update", @onDrawUpdate
			@socket.on "draw end", @onDrawEnd

			if R.tipibot
				setTimeout(@connectToTipibot, 3000)

			return

		connectToTipibot: ()=>
			console.log('connect to tipibot...')
			@tipibotSocket = new WebSocket("ws://localhost:8026/tipibot")

			@tipibotSocket.onopen = (event) ->
				console.log('tipibotSocket.onopen', event)
				return

			@tipibotSocket.onmessage = (event) =>
				console.log(event.data)
				message = JSON.parse(event.data)
				switch message.type
					when 'getNextValidatedDrawing'
						if R.loader.drawingPaths.length == 0
							if not @requestedNextDrawing
								args = 
									cityName: R.city.name
								$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'getNextValidatedDrawing', args: args } ).done((results)=>
									@requestedNextDrawing = false
									if results.message == 'no path' then return
									R.loader.loadCallbackTipibot(results)
									return
								)
								@requestedNextDrawing = true
						else
							R.loader.sendNextPathsToTipibot()
					when 'setDrawingStatusDrawn'
						if R.loader.drawingPaths.length == 0
							args = 
								pk: message.pk
								secret: message.secret
							$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'setDrawingStatusDrawn', args: args } ).done((results)=>
								if not R.loader.checkError(results) then return
								R.socket.tipibotSocket.send(JSON.stringify( type: 'drawingStatusSetToDrawn', drawingPk: results.pk ))
								return
							)
						else
							R.socket.tipibotSocket.send(JSON.stringify( type: 'drawingStatusSetToDrawn', drawingPk: message.pk ))
				return
			return

		initializeUserName: ()->
			@chatJ.find("a.sign-in").click(@onSignInClick)

			@chatJ.find("a.change-username").click(@onChangeUserNameClick)

			usernameJ = @chatJ.find("#chatUserName")

			usernameJ.find('#chatUserNameInput').keypress(@onUserNameInputKeypress)

			usernameJ.find("#chatUserNameSubmit").submit(@submitChatUserName)

			adjectives = ["Cool","Masked","Bloody","Super","Mega","Giga","Ultra","Big","Blue","Black","White",
			"Red","Purple","Golden","Silver","Dangerous","Crazy","Fast","Quick","Little","Funny","Extreme",
			"Awsome","Outstanding","Crunchy","Vicious","Zombie","Funky","Sweet"]

			things = ["Hamster","Moose","Lama","Duck","Bear","Eagle","Tiger","Rocket","Bullet","Knee",
			"Foot","Hand","Fox","Lion","King","Queen","Wizard","Elephant","Thunder","Storm","Lumberjack",
			"Pistol","Banana","Orange","Pinapple","Sugar","Leek","Blade"]

			username = Utils.Array.random(adjectives) + " " + Utils.Array.random(things)

			@submitChatUserName(username, false)
			return

		addMessage: (message, from=null) =>
			if from?
				author = if from == R.me then "me" else from
				@chatMessagesJ.append( $("<p>").append($("<b>").text(author + ": "), message) )
			else
				@chatMessagesJ.append( $("<p data-i18n='#{message}'>").append(i18next.t(message)) )
			@chatMessageJ.val('')

			# if I am the one talking: scroll both sidebar and chat box to bottom
			# if from == R.me
			# 	$("#chatMessagesScroll").mCustomScrollbar("scrollTo","bottom")
			# 	# $(".sidebar-scrollbar.chatMessagesScroll").mCustomScrollbar("scrollTo","bottom")
			# # else if anything in the chat is active: scroll the chat box to bottom
			# else if $(document.activeElement).parents("#Chat").length>0
			# 	$("#chatMessagesScroll").mCustomScrollbar("scrollTo","bottom")
			return

		onKeyPress: (event) =>
			if event.which == 13
				event.preventDefault()
				@sendMessage()
			return

		onConnectionError: ()=>
			error = "Impossible to connect to chat"
			@chatMainJ.find("#chatConnectingMessage").attr('data-i18n', error).text(i18next.t(error))
			return

		onSignInClick: (event)->
			$("#user-login-group > button").click()
			event.preventDefault()
			return false

		onChangeUserNameClick: (event)->
			$("#chatUserName").show()
			$("#chatUserNameInput").focus()
			event.preventDefault()
			return false

		onUserNameInputKeypress: (event) ->
			if event.which == 13
				event.preventDefault()
				@submitChatUserName()
			return

		submitChatUserName: (username, focusOnChat=true)=>
			$("#chatUserName").hide()
			username ?= usernameJ.find('#chatUserNameInput').val()
			@startChatting( username, false, focusOnChat )
			return

		# emit "user message" and add message to chat box
		sendMessage: ()=>
			@socket.emit( "user message", @chatMessageJ.val() )
			@addMessage( @chatMessageJ.val(), R.me)
			return

		# get room (string following the format: 'x: X, y: Y' X and Y being the coordinates of the view in project coordinates quantized by R.scale)
		# if current room is different: emit "join" room
		updateRoom: ()=>
			room = @getChatRoom()
			if R.room != room
				@chatRoomJ.empty().append("<span><span data-i18n='Room'>#{i18next.t('Room')}</span>: </span>" + room)
				@socket.emit("join", room)
				R.room = room

		# initialize chat: emit "nickname" (username) and on callback: initialize chat or show error
		startChatting: (username, realUsername=true, focusOnChat=true)=>
			@socket.emit("nickname", username, @onSetUserName)
			if focusOnChat then @chatMessageJ.focus()
			if realUsername
				@chatJ.find("#chatLogin").addClass("hidden")
			else
				@chatJ.find("#chatLogin p.default-username-message").html("<span data-i18n='You are logged as'>#{i18next.t('You are logged as')}</span> <strong>" + username + "</strong>")
			return

		onSetUserName: (set)=>
			if set
				clearTimeout(@chatConnectionTimeout)
				@chatMainJ.removeClass("hidden")
				@chatMainJ.find("#chatConnectingMessage").addClass("hidden")
				@chatJ.find("#chatUserNameError").addClass("hidden")
			else
				@chatJ.find("#chatUserNameError").removeClass("hidden")
			return

		onDrawingChange: (data) ->
			R.drawingPanel.onDrawingChange(data)
			return

		fadeTailsInterval: ()=>
			nAlivePaths = 0
			@userToPaths.forEach (paths, user) =>
				for path in paths.slice()
					path.scale(0.9)
					path.position = path.position.add(path.data.direction)
					path.data.lives--
					path.strokeColor.alpha -= 0.1
					path.fillColor.alpha -= 0.1
					if path.data.lives == 0
						path.remove()
						paths.splice(paths.indexOf(path), 1)
					else
						nAlivePaths++
			if nAlivePaths == 0
				clearInterval(@fadeTailsIntervalID)
				@fadeTailsIntervalID = null
			return

		createPath: (point, color)->
			# path = new P.Path()
			path = new P.Path.Circle(point, 3)
			# path.strokeWidth = 0.5 # R.Item.Path.strokeWidth
			# path.strokeColor = R.selectionBlue
			# path.fillColor = R.selectionBlue
			path.strokeColor = color
			path.fillColor = color
			path.strokeColor.alpha = 1
			path.fillColor.alpha = 1
			path.data.direction = P.Point.random().subtract(0.5).multiply(3)
			path.strokeCap = 'round'
			path.strokeJoin = 'round'
			path.data.lives = 10
			# path.add(point)
			return path

		onDrawBegin: (user, point)=>
			if user == R.me then return
			paths = @userToPaths.get(user)
			if not paths?
				paths = []
				@userToPaths.set(user, paths)

			color = @userToColor.get(user)
			if not color?
			    color = new P.Color({hue: Math.floor(Math.random()*360/10)*10, saturation: 0.35, brightness: 0.95});
				@userToColor.set(user, color)

			path = @createPath(point, color)
			paths.push(path)
			if not @fadeTailsIntervalID
				@fadeTailsIntervalID = setInterval(@fadeTailsInterval, 100)
			return

		onDrawUpdate: (user, point)=>
			if user == R.me then return
			paths = @userToPaths.get(user)
			if paths?
				# paths[paths.length - 1].add(point)
				path = @createPath(point, @userToColor.get(user))
				paths.push(path)
			return

		onDrawEnd: (user, point)=>
			if user == R.me then return
			# paths = @userToPaths.get(user)
			# if paths?
			# 	paths[paths.length - 1].add(point)
			return

		onBounce: (data) ->
			if R.ignoreSockets then return
			if data.function? and data.arguments?
				if data.tool?
					tool = R.tools[data.tool]
					if data.function not in ['begin', 'update', 'end', 'createPath']
						console.log 'Error: not authorized to call' + data.function
						return
					rFunction = tool?[data.function]
					if rFunction?
						# data.arguments[0] = Event.prototype.fromJSON(data.arguments[0])
						rFunction.apply(tool, data.arguments)
				else if data.itemId?
					item = R.items[data.itemId]
					if item? and not item.currentCommand?
						allowedFunctions =
							['setRectangle', 'setRotation', 'moveTo', 'setParameter', 'modifyPoint', 'modifyPointType',
							'modifySpeed', 'setPK', 'delete', 'create', 'addPoint', 'deletePoint', 'modifyControlPath', 'setText']
						if data.function not in allowedFunctions
							console.log 'Error: not authorized to call: ' + data.function
							return
						rFunction = item[data.function]
						if not rFunction?
							console.log 'Error: function is not valid: ' + data.function
							return

						id = 'rasterizeItem-'+item.od

						itemMustBeRasterized = data.function not in ['setPK', 'create'] and not item.drawing.visible

						# if not R.updateTimeout[id]? and itemMustBeRasterized
						# 	# R.rasterizer.drawItems()
						# 	# R.rasterizer.rasterize(item, true)

						item.drawing.visible = true

						item.socketAction = true
						rFunction.apply(item, data.arguments)
						delete item.socketAction

						if itemMustBeRasterized and data.function not in ['delete']
							Utils.deferredExecution(@rasterizeItem, id, 1000)
				else if data.itemClass and data.function == 'create'
					itemClass = g[data.itemClass]
					if Item.prototype.isPrototypeOf(itemClass)
						itemClass.socketAction = true
						itemClass.create.apply(itemClass, data.arguments)
				P.view.update()
			return

		rasterizeItem: ()->
			# if not item.currentCommand then R.rasterizer.rasterize(item)
			return

		getChatRoom: ()->
			return 'Comme un dessein' # 'x: ' + Math.round(P.view.center.x / R.scale) + ', y: ' + Math.round(P.view.center.y / R.scale)

	return Socket
