define ['paper', 'R', 'Utils/Utils', 'Items/Item', 'i18next', 'moment' ], (P, R, Utils, Item, i18next, moment) ->

	class Timelapse

		@duration = 2 * 60 * 1000

		constructor: ()->
			@sortedEvents = []
			@timelineJ = $('#timeline')
			@timelineJ.find('.btn.show').click @activate
			@timelineJ.find('.btn-play').click @play
			@timelineJ.find('.btn-step-backward').click @goToPreviousEvent
			@timelineJ.find('.btn-step-forward').click @goToNextEvent
			@timelineJ.find('.btn-close').click @close
			return

		play: ()=>
			if @playing
				@stop()
				return
			@playing = true
			@timelineJ.find('.btn-play span').removeClass('glyphicon-play').addClass('glyphicon-pause')
			
			if @time >= 1
				@time = 0

			@startTime = Date.now()
			@lastAnimateTime = @startTime

			requestAnimationFrame(@animate)
			return

		stop: ()->
			@playing = false
			@timelineJ.find('.btn-play span').removeClass('glyphicon-pause').addClass('glyphicon-play')
			return

		close: ()=>
			for drawing in R.drawings
				drawing.show()
				if drawing.svg?
					drawing.svg.removeAttribute('stroke')

			@stop()

			@timelineJ.removeClass('active')
			$('body').removeClass('timeline-active')

			R.stageJ.height(window.innerHeight - R.stageJ.offset().top)
			R.view.onWindowResize()
			R.view.fitRectangle(R.view.grid.limitCD.bounds.expand(40), true)
			@activated = false

			if not @rejectedDrawingsWereVisible
				R.view.rejectedLayer.data.setVisibility(false)
			return

		activate: ()=>
			if @activated then return
			@activated = true

			@rejectedDrawingsWereVisible = R.view.rejectedLayer.visible

			@timelineJ.addClass('active')
			$('body').addClass('timeline-active')

			setTimeout (()=>
				R.stageJ.height(window.innerHeight - R.stageJ.offset().top - @timelineJ.outerHeight())
				R.view.onWindowResize()
				R.view.fitRectangle(R.view.grid.limitCD.bounds.expand(40), true)
				return), 250

			@load()
			return

		begin: ()=>

			# R.view.mainLayer.data.setVisibility(true)
			R.view.pendingLayer.data.setVisibility(true)
			R.view.drawingLayer.data.setVisibility(true)
			R.view.drawnLayer.data.setVisibility(true)
			# R.view.rejectedLayer.data.setVisibility(true)


			for drawing in R.drawings
				drawing.hide()

			duration = 120
			
			events = []
			
			sortByDate = (a, b)=>
				return a.date - b.date

			for drawing in R.drawings
				
				votes = []
				nNegativeVotes = 0
				nPositiveVotes = 0

				for vote in drawing.votes
					
					if not vote.emailConfirmed then continue

					v = JSON.parse(vote.vote)

					v.date = v.date.$date
					if v.positive
						nPositiveVotes++
					else
						nNegativeVotes++
					prefix = if v.positive then 'positive' else 'negative'

					events.push( date: v.date, type: prefix + ' vote', drawing: drawing)
					votes.push(v)
				
				if votes.length > 0
					events.push( date: drawing.date, type: 'create drawing', drawing: drawing)

					sortedVotes = votes.sort(sortByDate)
					
					date = sortedVotes[sortedVotes.length-1].date
					if drawing.status == 'rejected'
						events.push( date: date, type: 'drawing rejected', drawing: drawing)
						events.push( date: date + 3600 * 1000, type: 'drawing rejected ignore', drawing: drawing)
					else if drawing.status == 'drawing' or drawing.status == 'drawn'
						events.push( date: date, type: 'drawing validated', drawing: drawing)
						events.push( date: date + 3600 * 1000, type: 'drawing drawn', drawing: drawing)

			@sortedEvents = events.sort(sortByDate)

			currentDrawings = new Map()
			for event in @sortedEvents

				switch event.type
					when 'create drawing'
						currentDrawings.set(event.drawing, 'pending')
					when 'drawing validated'
						currentDrawings.set(event.drawing, 'drawing')
					when 'drawing rejected'
						currentDrawings.set(event.drawing, 'rejected')
					when 'drawing drawn'
						currentDrawings.set(event.drawing, 'drawn')
					when 'drawing rejected ignore'
						currentDrawings.set(event.drawing, 'rejected ignore')

				event.currentDrawings = new Map(currentDrawings)
				
				if event.type == 'drawing rejected ignore'
					currentDrawings.delete(event.drawing)

			@beginDate = @sortedEvents[0].date - 3600 * 1000
			@duration = @sortedEvents[@sortedEvents.length-1].date - @beginDate

			@currentDrawings = []
			
			@createTimeline(@duration, @beginDate)

			@startTime = Date.now()
			@lastAnimateTime = @startTime
			@time = 0
			
			@play()
			return

		animate: ()=>
			if @time >= 1 or not @playing
				@stop()
				return
			animateTime = Date.now()
			deltaTime = animateTime - @lastAnimateTime
			time = @time + deltaTime / @constructor.duration
			if time < 1
				@update(time)
				requestAnimationFrame(@animate)
			else
				@update(1)
				@stop()
			@lastAnimateTime = animateTime
			return

		setFrame: (i, computeTime=true, updateThumb=true)->

			@eventIndex = i
			event = @sortedEvents[i]
			
			if computeTime
				@time = (event.date - @beginDate) / @duration

			if updateThumb
				@thumb.position.x = @time * @canvas.width

			date = @time * @duration + @beginDate

			@timelineJ.find('.info .date').text( moment(date).format('l - LT') )

			@currentDrawings.forEach (drawing) =>
				drawing.hide()

			@currentDrawings = []

			message = ''
			switch event.type
				when 'create drawing'
					message = 'Le dessin "' + event.drawing.title + '" a été créé'
				when 'drawing validated'
					message = 'Le dessin "' + event.drawing.title + '" a été validé'
				when 'drawing rejected', 'drawing rejected ignore'
					message = 'Le dessin "' + event.drawing.title + '" a été rejeté'
				when 'drawing drawn'
					message = 'Le dessin "' + event.drawing.title + '" a été dessiné'
				when 'positive vote'
					message = 'Quelqu\'un a voté pour le dessin "' + event.drawing.title + '"'
				when 'negative vote'
					message = 'Quelqu\'un a voté contre le dessin "' + event.drawing.title + '"'

			@timelineJ.find('.info .events').text( message )

			event.currentDrawings.forEach (status, drawing) =>

				if status != 'rejected ignore'
					@currentDrawings.push(drawing)
					drawing.show()
					drawing.svg.setAttribute('stroke', R.Path.colorMap[status])
				else
					drawing.hide()
			return

		goToPreviousEvent: ()=>
			if @eventIndex <= 0 then return
			@setFrame(@eventIndex - 1)
			return
		
		goToNextEvent: ()=>
			if @eventIndex >= @sortedEvents.length - 1 then return
			@setFrame(@eventIndex + 1)
			return

		update: (@time, updateThumb=true)=>

			if @time >= 1
				@setFrame(@sortedEvents.length-1, false, updateThumb)
				return

			date = @time * @duration + @beginDate

			for event, i in @sortedEvents
				if i + 1 < @sortedEvents.length && @sortedEvents[i+1].date > date
					@setFrame(i, false, updateThumb)
					break

			return

		mouseDown: (event)=>
			@dragging = true
			@mouseMove(event)
			return

		mouseMove: (event)=>
			if @dragging
				canvasOffset = @canvasJ.offset()
				point = Utils.Event.GetPoint(event).subtract(new P.Point(canvasOffset.left, canvasOffset.top))
				@thumb.position.x = point.x - @thumb.bounds.width / 2
				@update(@thumb.position.x / @canvas.width, false)
			return
			
		mouseUp: (event)=>
			@dragging = false
			return

		onWindowResize: ()->
			@canvasJ?.width(window.innerWidth - 3 * 38)
			return

		createTimeline: (durationInMilliseconds, beginDate)=>

			durationInHours = durationInMilliseconds / ( 3600 * 1000 )
			
			@timelineJ.removeClass('hidden')

			timelineHeight = 100 - 26

			if not @canvas?
				@canvasJ = @timelineJ.find('#timeline-canvas')
				@canvas = @canvasJ.get(0)
				@project = new P.Project(@canvas)

				# todo: handle window resize and change "canvas.width" in "onMouseDrag" accordingly

				@canvasJ.on( touchstart: @mouseDown )
				@canvasJ.on( touchmove: @mouseMove )
				@canvasJ.on( touchend: @mouseUp )
				@canvasJ.on( touchleave: @mouseUp )
				@canvasJ.on( touchcancel: @mouseUp )

				@canvasJ.mousedown( @mouseDown )
				@canvasJ.mousemove( @mouseMove )
				$(window).mouseup( @mouseUp )
				$(window).keydown (event)=>
					if Utils.specialKeys[event.keyCode] == 'space'
						@play()
						event.stopPropagation()
						event.preventDefault()
						return -1
					else if Utils.specialKeys[event.keyCode] == 'left'
						if event.shiftKey or event.ctrlKey or event.altKey
							amount = if event.shiftKey then 0.1 else 0.025
							@update(Math.max(0, @time - amount))
						else
							@goToPreviousEvent()
					else if Utils.specialKeys[event.keyCode] == 'right'
						if event.shiftKey or event.ctrlKey or event.altKey
							amount = if event.shiftKey then 0.1 else 0.025
							@update(Math.min(@time + amount, 1))
						else
							@goToNextEvent()
					return
			
			@project.activate()
			@project.clear()

			@project.view.viewSize = new P.Size(@canvasJ.innerWidth(), timelineHeight)
			@canvas.width = @project.view.viewSize.width
			@canvas.height = @project.view.viewSize.height

			@thumb = new P.Path.Rectangle(0, 0, 1, timelineHeight)
			@thumb.fillColor = 'white'

			# draw hours

			step = @canvas.width / durationInHours
			
			for i in [1 .. durationInHours]
				x = durationInHours * step
				path = new P.Path()
				path.add(x, 0)
				path.add(x, if i%24 == 0 then timelineHeight else timelineHeight / 3)
				path.strokeWidth = 1
				path.strokeColor = 'black'

			# draw events
			for event in @sortedEvents
				if event.type == 'drawing rejected ignore' then continue
				x = @canvas.width * ( event.date - beginDate ) / durationInMilliseconds
				path = new P.Path()
				
				yBegin = 0
				yEnd = timelineHeight

				path.strokeWidth = 1
				switch event.type
					when 'create drawing'
						path.strokeColor = R.Path.colorMap.pending
						yEnd = timelineHeight / 4
					when 'positive vote'
						path.strokeColor = R.Path.colorMap.drawing
						yBegin = timelineHeight / 4
						yEnd = 2 * timelineHeight / 4
					when 'negative vote'
						path.strokeColor = R.Path.colorMap.rejected
						yBegin = timelineHeight / 4
						yEnd = 2 * timelineHeight / 4
					when 'drawing validated'
						path.strokeColor = R.Path.colorMap.drawing
						yBegin = 2 * timelineHeight / 4
						yEnd = 3 * timelineHeight / 4
					when 'drawing rejected'
						path.strokeColor = R.Path.colorMap.rejected
						yBegin = 2 * timelineHeight / 4
						yEnd = 3 * timelineHeight / 4
					when 'drawing drawn'
						path.strokeColor = R.Path.colorMap.drawing
						yBegin = 3 * timelineHeight / 4
						yEnd = timelineHeight

				path.add(x, yBegin)
				path.add(x, yEnd)

			@thumb.bringToFront()

			paper.projects[0].activate()

			return

		loadOneByOne: ()=>
			nDrawingsToLoad = R.drawings.length

			for drawing in R.drawings
				args =
					pk: drawing.pk

				$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadDrawing', args: args } ).done((result)=>
					if not R.loader.checkError(result) then return
					
					latestDrawing = JSON.parse(result.drawing)
					drawing = R.pkToDrawing[latestDrawing._id.$oid]
					drawing.votes = result.votes
					drawing.status = latestDrawing.status

					nDrawingsToLoad--
					if nDrawingsToLoad == 0
						@begin()
				)
			return

		handleTimelapseData: (results)=>
			@loaded = true

			R.loader.hideLoadingBar()
			if not R.loader.checkError(results) then return
			
			for result in results.results
				
				drawing = R.pkToDrawing[result.pk]
				if drawing?
					drawing.votes = result.votes
					drawing.status = result.status

			@begin()
			return

		loadTimelapseDataFromDatabase: ()=>

			pks = []
			for drawing in R.drawings
				if drawing.isVisible() and (not drawing.votes? or drawing.votes.length == 0)
					pks.push(drawing.pk)

			args =
				pks: pks
			$.ajax( method: "POST", url: "ajaxCall/", data: data: JSON.stringify { function: 'loadTimelapse', args: args } ).done(@handleTimelapseData)
			return

		load: (loadRejectedDrawings = true)=>

			if loadRejectedDrawings
				R.view.loadRejectedDrawings()
				R.view.rejectedLayer.data.setVisibility(true)

			if not @loaded
				R.loader.showLoadingBar()

				jqxhr = $.get( location.origin + '/static/timelapse/timelapse.json', ((results)=>
					if results?
						@handleTimelapseData(results)
					else
						@loadTimelapseDataFromDatabase()
					return
				))
				.fail(@loadTimelapseDataFromDatabase)
			else
				@begin()
			return
