define ['paper', 'R', 'Utils/Utils', 'Tools/PathTool', 'Commands/Command', 'UI/Button', 'i18next' ], (P, R, Utils, PathTool, Command, Button, i18next) ->

	class ExquisiteCorpseTool extends PathTool

		constructor: (@Path, justCreated=false) ->
			super(@Path, justCreated)
			@ignoreMouseMoves = false
			return
		
		select: (deselectItems=false, updateParameters=true, forceSelect=false, selectedBy='default')->
			super(deselectItems, updateParameters, forceSelect, selectedBy)
			return

		deselect: ()->
			super()
			return
		
		begin: (event, from=R.me, data=null) ->

			if P.view.zoom < 0.5
				R.alertManager.alert 'Please zoom before drawing', 'info'
				return
			
			canDraw = R.view.exquisiteCorpseMask.mouseBegin(event)
			
			if not canDraw then return

			super(event, from, data)
			
			return

		update: (event, from) ->
			if not @currentPath? then return
			canDraw = R.view.exquisiteCorpseMask.mouseUpdate(event)
			if not canDraw
				R.alertManager.alert 'Your path must fit in a single of your tiles', 'error'
				@showPathError(event, from)
				return
			super(event)
			return

		move: (event) =>
			if @ignoreMouseMoves then return
			# R.tools.choose.move(event)
			canvas = document.getElementById('canvas')
			eventTarget = event.originalEvent?.target or event.event?.target
			if eventTarget != canvas then return

			R.view.exquisiteCorpseMask.mouseMove(event)
			return

		end: (event, from=R.me) ->
			super(event, from)
			return

		hideOddLines: ()->
			return

		showOddLines: ()->
			return

	R.Tools.ExquisiteCorpse = ExquisiteCorpseTool
	return ExquisiteCorpseTool
