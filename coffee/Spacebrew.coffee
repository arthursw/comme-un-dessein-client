define [ 'spacebrew' ], (SpacebrewLib) ->

	# Spacebrew

	server = "localhost"
	name = "CommeUnDessein"
	description = "Tipibot commands."

	spacebrew = new Spacebrew.Client(server, name, description)

	spacebrew.onOpen = ()->
		console.log "Connected as " + spacebrew.name() + "."
		return

	spacebrew.connect()

	spacebrew.addPublish("commands", "string", "")
	spacebrew.addPublish("command", "string", "")

	R.spacebrew = spacebrew

	return spacebrew
