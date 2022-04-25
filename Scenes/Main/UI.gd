extends CanvasLayer

export(ButtonGroup) var terrain_tools
export(ButtonGroup) var district_builder_tools

signal start_terraform(mode_index, terrain_type)
signal start_district_build(mode_index, district_type)
signal start_view(mode_index, type) 

func _ready():
	connect_tools(terrain_tools, "_on_terra_form_pressed")
	connect_tools(district_builder_tools, "_on_district_builder_pressed")

# updates the mode indicator in the bottom left
# only for debugging
func update_debug_mode_indicator(mode, type, painting_indicator):
	var is_painting = 'false'
	if painting_indicator:
		is_painting = 'true' 

	get_node("ModeDebugger/Mode").text = "Mode: " + mode
	get_node("ModeDebugger/Type").text = "Type: " + type 
	get_node("ModeDebugger/PaintingIndicator").text = "Painting: " + is_painting 

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			_on_view_mode_pressed()

# mode switches
	# build modes as defined in mapbuilder
	# 0 - View
	# 1 - TerraForm
	# 2 - DistrictBuilder
func _on_view_mode_pressed():
	unpress(terrain_tools)
	unpress(district_builder_tools)
	emit_signal("start_view", 0, "None")

func _on_terra_form_pressed(terrain_type: String):
	unpress(district_builder_tools)
	emit_signal("start_terraform", 1, terrain_type)

func _on_district_builder_pressed(district_type: String):
	unpress(terrain_tools)
	emit_signal("start_district_build", 2, district_type)

# unpresses all buttons in the given button group
func unpress(button_group: ButtonGroup):
	for button in button_group.get_buttons():
		button.pressed = false

# connect the given set of tools(aka button group to the given function)
# also makes use of the tool name (aka button) as a binding for the receiving function
func connect_tools(button_group: ButtonGroup, receiving_function: String):
	for _tool in button_group.get_buttons(): 
		# the bind is used by the receiving function as the first or any number of arguments
		# for their params.
		_tool.connect("pressed", self, receiving_function, [_tool.get_name()])
	
func update_hovered_tile(tile: Tile):
	get_node("TileDetails/Type").text = "Terrain Type: %s" % tile.terrain_type
	get_node("TileDetails/CubeCoord").text = "Cube Coordinate: %s" % tile.cube_coord
	get_node("TileDetails/CartesianCoord").text = "Cartesian Coordinate %s" % Vector2(tile.x, tile.y)
	get_node("TileDetails/Neighbors").text = format_array(tile.neighbor_names, "Neighbors")

# formats an array to be more readable
func format_array(collection, collection_name: String) -> String:
	var formatted_output: String = "%s: \n" % collection_name
	for item in collection:
		var formatted_item = "\t %s \n" % item
		formatted_output += formatted_item

	return formatted_output