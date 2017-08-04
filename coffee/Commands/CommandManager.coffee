define ['paper', 'R', 'Utils/Utils', 'Commands/Command' ], (P, R, Utils, Command) ->

	class CommandManager
		@maxCommandNumber = 20

		constructor: ()->
			@history = []
			@itemToCommands = {}
			@currentCommand = -1
			@historyJ = $("#History ul.history")
			@add(new Command('Loaded CommeUnDessein'), true)
			return

		# twin: see Command.twin
		add: (command, execute=false)->
			if @currentCommand >= @constructor.maxCommandNumber - 1
				firstCommand = @history.shift()
				firstCommand.delete()
				@currentCommand--
			currentLiJ = @history[@currentCommand]?.liJ
			currentLiJ?.nextAll().remove()
			@historyJ.append(command.liJ)
			$("#History .mCustomScrollbar").mCustomScrollbar("scrollTo","bottom")
			@currentCommand++
			@history.splice(@currentCommand, @history.length-@currentCommand, command)

			@mapItemsToCommand(command)

			@updateButtons()

			if execute then command.do()
			return

		toggleCurrentCommand: (event)=>
			if event? and event.detail?
				if event.detail != @waitingCommand then return
				@waitingCommand = null
				$('#loadingMask').css('visibility': 'hidden')

			document.removeEventListener('command executed', @toggleCurrentCommand)

			if @currentCommand == @commandIndex
				@waitingCommand = null

				@updateButtons()

				return
			
			deferred = @history[@currentCommand+@offset].toggle()

			@waitingCommand = @history[@currentCommand+@offset]
			
			@currentCommand += @direction

			if @waitingCommand.twin == @history[@currentCommand+@offset] && @currentCommand == @commandIndex
				@commandIndex += @direction

			if deferred
				$('#loadingMask').css('visibility': 'visible')
				document.addEventListener('command executed', @toggleCurrentCommand)
			else
				@toggleCurrentCommand()

			return

		nullifyWaitingCommand: ()=>
			if event? and event.detail?
				if event.detail != @waitingCommand then return
				@waitingCommand = null
				$('#loadingMask').css('visibility': 'hidden')
			return

		undo: ()->
			if @currentCommand <= 0 then return

			@commandClicked(@history[@currentCommand-1])
			return

		do: ()->
			if @currentCommand >= @history.length-1 then return

			@commandClicked(@history[@currentCommand+1])
			return

		commandClicked: (command)->
			if @waitingCommand? then return

			@commandIndex = @getCommandIndex(command)

			if @currentCommand == @commandIndex then return

			if @currentCommand > @commandIndex
				@direction = -1
				@offset = 0
			else
				@direction = 1
				@offset = 1

			@toggleCurrentCommand()
			return

		getCommandIndex: (command)->
			for c, i in @history
				if c == command then return i
			return -1

		getCurrentCommand: ()->
			return @history[@currentCommand]

		setButton: (name, enable)->
			opacity = if enable then 1 else 0.25
			R.sidebar.favoriteToolsJ.find("[data-name='"+name+"']").css( opacity: opacity )
			return

		setUndoButton: (enable)->
			@setButton('Undo', enable)
			return
		
		setRedoButton: (enable)->
			@setButton('Redo', enable)
			return

		updateButtons: ()->
			if @currentCommand >= @history.length-1
				@setRedoButton(false)
			else 
				@setRedoButton(true)
			
			if @currentCommand == 0
				@setUndoButton(false)
			else 
				@setUndoButton(true)
			return

		clearHistory: ()->
			@historyJ.empty()
			@history = []
			@currentCommand = -1
			@add(new Command("Load CommeUnDessein"), true)
			@updateButtons()
			return

		# manage actions

		beginAction: (command, event)->
			if @actionCommand?
				clearTimeout(R.updateTimeout['addCurrentCommand-' + @actionCommand.id])
				@endAction()
			@actionCommand = command
			@actionCommand.begin(event)
			return

		updateAction: ()->
			@actionCommand?.update.apply(@actionCommand, arguments)
			return

		endAction: (event)=>
			@actionCommand?.end(event)
			@actionCommand = null
			return

		deferredAction: (ActionCommand, items, event, args...)->
			if not ActionCommand.prototype.isPrototypeOf(@actionCommand)
				@beginAction(new ActionCommand(items, args), event)
			@updateAction.apply(@, args)
			Utils.deferredExecution(@endAction, 'addCurrentCommand-' + @actionCommand.id )
			return

		# manage items

		mapItemsToCommand: (command)->
			if not command.items? then return
			for id, item of command.items
				@itemToCommands[id] ?= []
				@itemToCommands[id].push(command)
			return

		# Called exclusively by Item.setPk()
		# setItemPk: (id, pk)->
		# 	console.log('Set item pk: ' + id + ', ' + pk)
		# 	commands = @itemToCommands[id]
		# 	if commands?
		# 		for command in commands
		# 			command.setItemPk(id, pk)
		# 	@itemToCommands[pk] = @itemToCommands[id]
		# 	delete @itemToCommands[id]
		# 	return

		itemSaved: (item)->
			commands = @itemToCommands[item.id]
			if commands?
				for command in commands
					command.itemSaved(item)
			return

		itemDeleted: (item)->
			commands = @itemToCommands[item.id]
			if commands?
				for command in commands
					command.itemDeleted(item)
			return
		
		unloadItem: (item)->
			commands = @itemToCommands[item.id]
			if commands?
				for command in commands
					command.unloadItem(item)
			# do not delete @itemToCommands[item.id], we will need it to resurect the item
			return

		loadItem: (item)->
			commands = @itemToCommands[item.id]
			if commands?
				for command in commands
					command.loadItem(item)
			return

		resurrectItem: (id, item)->
			commands = @itemToCommands[id]
			if commands?
				for command in commands
					command.resurrectItem(item)

			# @itemToCommands[item.id] = commands
			# delete @itemToCommands[id]
			return

	return CommandManager
