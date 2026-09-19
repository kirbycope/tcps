extends GutTest

## Purpose: the board is one node on every peer. Getting on puts it under the rider's feet and hands it to the
## rider's peer; getting off leaves it where they stand, back under the parent it stood under, and hands it to
## the server; a rider who drops out is handed back the same way, and a board somebody else is riding refuses a
## second rider. Offline there is nobody to ask, so the hand-off is immediate, which is what these tests see; the
## two-machine scenario in the game project sees it over Steam.

const PARK_SCENE: PackedScene = preload("res://addons/tcps/scenes/skate_park.tscn")
const RIDER_PEER: int = 7 ## A peer that is not the server, so the hand-off shows.

var park: Node3D
var player: Player
var board: Skateboard
var synchronizer: MultiplayerSynchronizer


## The park without its MountTimer, so the tests get on themselves.
func before_each() -> void:
	park = PARK_SCENE.instantiate()
	(park.get_node("MountTimer") as Timer).autostart = false
	add_child_autofree(park)
	player = park.get_node("Player")
	board = park.get_node("Skateboard")
	synchronizer = board.get_node("BodySynchronizer")


func test_the_board_replicates_its_place_and_its_rider() -> void:
	var replicated: Array[NodePath] = synchronizer.replication_config.get_properties()
	assert_has(replicated, NodePath(".:position"), "The synchronizer carries the board's position")
	assert_has(replicated, NodePath(".:rotation"), "and rotation")
	assert_has(replicated, NodePath(".:rider_peer"), "and who is on it")
	assert_eq(board.rider_peer, 0, "which is nobody to begin with")
	assert_eq(board.get_multiplayer_authority(), Skateboard.SERVER_PEER, "and the server's to begin with")


func test_getting_on_puts_the_board_under_the_riders_feet_and_hands_it_to_their_peer() -> void:
	player.set_multiplayer_authority(RIDER_PEER)
	board.mount(player)
	assert_eq(board.get_parent(), player.player_model, "The board is under the rider's model")
	assert_eq(board.transform, Transform3D.IDENTITY, "at their feet")
	assert_eq(board.rider_peer, RIDER_PEER, "and says who is on it")
	assert_eq(board.get_multiplayer_authority(), RIDER_PEER, "The rider's peer owns the board")
	assert_eq(synchronizer.get_multiplayer_authority(), RIDER_PEER, "synchronizer included")
	assert_eq(board.area.collision_layer, 0, "Nobody is offered a board that is under somebody's feet")


func test_getting_off_leaves_the_board_where_the_rider_stands_and_hands_it_to_the_server() -> void:
	var layer: int = board.area.collision_layer
	player.set_multiplayer_authority(RIDER_PEER)
	board.mount(player)
	player.warp_to(Transform3D(Basis(Vector3.UP, 1.0), Vector3(3.0, 0.1, -4.0)))
	board.dismount(player)
	assert_eq(board.get_parent(), park, "The board is back under the parent it stood under")
	assert_almost_eq(board.global_position, Vector3(3.0, 0.1, -4.0), Vector3.ONE * 0.01, "where the rider got off")
	assert_almost_eq(board.global_basis.y, Vector3.UP, Vector3.ONE * 0.001, "upright")
	assert_almost_eq(board.global_basis.get_euler().y, 1.0, 0.001, "facing the way they faced")
	assert_eq(board.rider_peer, 0, "and free")
	assert_eq(board.get_multiplayer_authority(), Skateboard.SERVER_PEER, "The server has the board again")
	assert_eq(synchronizer.get_multiplayer_authority(), Skateboard.SERVER_PEER, "synchronizer included")
	assert_eq(board.area.collision_layer, layer, "and it can be picked up again")
	assert_null(board.player, "Nobody is on it")


func test_getting_off_puts_the_board_back_under_its_home_parent_not_the_scene() -> void:
	var fresh: Node3D = PARK_SCENE.instantiate()
	(fresh.get_node("MountTimer") as Timer).autostart = false
	var rack: Node3D = Node3D.new()
	rack.name = "Rack"
	var racked: Skateboard = fresh.get_node("Skateboard")
	fresh.remove_child(racked)
	racked.owner = null
	fresh.add_child(rack)
	rack.add_child(racked)
	add_child_autofree(fresh)
	var rider: Player = fresh.get_node("Player")
	rider.set_multiplayer_authority(RIDER_PEER + 1) # not the park's Player from before_each, which is peer 1
	racked.mount(rider)
	assert_eq(racked.get_parent(), rider.player_model, "The board left the rack for the rider's feet")
	racked.dismount(rider)
	assert_eq(racked.get_parent(), rack, "and went back to the rack, not to the scene root")


func test_a_rider_who_drops_out_hands_the_board_back() -> void:
	player.set_multiplayer_authority(RIDER_PEER)
	board.mount(player)
	multiplayer.peer_disconnected.emit(RIDER_PEER)
	assert_eq(board.get_parent(), park, "The board is back where it stood")
	assert_eq(board.rider_peer, 0, "free")
	assert_eq(board.get_multiplayer_authority(), Skateboard.SERVER_PEER, "and the server's")
	board.player = null # the rider never got off through the state
	multiplayer.peer_disconnected.emit(RIDER_PEER + 1)
	assert_eq(board.get_parent(), park, "Somebody else dropping out changes nothing")


func test_a_board_another_peer_rides_refuses_a_second_rider() -> void:
	board.rider_peer = RIDER_PEER
	player.mount(board)
	await wait_physics_frames(3)
	assert_false(player.is_riding, "The Player was put back off")
	assert_eq(board.get_parent(), park, "The board never moved")
	assert_eq(board.rider_peer, RIDER_PEER, "and is still the other rider's")
	assert_eq(board.get_multiplayer_authority(), Skateboard.SERVER_PEER, "with the authority untouched")


## Tony Hawk's Pro Skater 1 + 2 lays the face buttons out its own way, and a board is only worth riding with
## them: A ollies, B grabs, X flips, Y grinds. Those are the actions the board already reads, so the layout is a
## ControlScheme resource rather than anything the board does to the InputMap itself, and the rider's own layout
## comes back the moment they step off.
## Whether [param action] answers to [param button]. Asked this way rather than "which button is it on", because
## one GUT run shares one InputMap across every script in it and an action can be left carrying more than one
## pad button; what matters is that the skating layout put its own button on and took the other one off.
func _has_button(action: StringName, button: JoyButton) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button:
			return true
	return false


func test_riding_lays_the_pad_out_the_way_tony_hawks_does() -> void:
	var walking: ControlScheme = player.control_scheme
	assert_eq(walking.scheme_name, "TotK", "On foot the Player has the game's own layout")

	board.mount(player)
	await wait_physics_frames(2)

	assert_eq(player.control_scheme, board.riding_control_scheme, "Getting on puts the skating layout up")
	assert_eq(player.control_scheme.scheme_name, "THPS")
	assert_true(_has_button(&"jump", JOY_BUTTON_A), "A ollies")
	assert_true(_has_button(&"sprint", JOY_BUTTON_B), "B grabs")
	assert_true(_has_button(&"attack", JOY_BUTTON_X), "X flips")
	assert_true(_has_button(&"action", JOY_BUTTON_Y), "Y grinds")
	assert_false(_has_button(&"jump", JOY_BUTTON_Y), "and jump came off the button it had on foot")

	board.dismount(player)
	await wait_physics_frames(2)

	assert_eq(player.control_scheme, walking, "Stepping off gives the rider their own layout back")
	assert_true(_has_button(&"jump", JOY_BUTTON_Y), "and the pad with it")
	assert_false(_has_button(&"jump", JOY_BUTTON_A), "the ollie button going back to what it was on foot")


func test_a_game_can_keep_one_layout_throughout() -> void:
	board.riding_control_scheme = null
	var walking: ControlScheme = player.control_scheme

	board.mount(player)
	await wait_physics_frames(2)

	assert_eq(player.control_scheme, walking, "No skating layout set, the board leaves the pad alone")
