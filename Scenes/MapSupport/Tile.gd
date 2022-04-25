extends Node2D

class_name Tile

# for vertical offset effect on mouse hover
var hover_position
var rest_position

# for isometric view distances

# base this from image size
	# isometric boxes have 2:1 width:height ratio
# this values where originally at
	# 256, 128, 0.85 respectively.
	# setting y_off to 0.865 also creates nice borders
	# provided tile width and height are unchanged.
	# 256 is the width of the tile, the square base tile to be specific
	# 128 would be the height as explained from the ratio above.
	# y_offset would be the offset to make each row of tile connect to each other. This value
	# was acquired via trial and error. Increasing it would increase the distance between rows,
	# decreasing otherwise.
	# the values where changed because there were still small offsets between the tiles in the x direction
	# https://www.youtube.com/watch?v=04oQ2jOUjkU&t=212s
var tile_width = 252
var tile_height = 126 
var y_off = 0.8726 # didn't know how I came up with this

var map: Node2D											 # map where the tile belongs 
var x: float 												 # non transformed x position assuming 1 as base height unit
var y: float												 # non transformed y position assuming 1 as base height unit
var cube_coord: Vector3              # the cube coordinates of this tile x=q; y=r; z=s
var terrain_type: String = "ocean"   # ocean is default 
var terrain_texture: Resource  			 # terrain texture associated with the terrain type
var neighbors: Array 
var neighbor_names: PoolStringArray

var valid_build_location: bool                         # 
var invalid_district_locations = ['ocean', 'mountain'] # invalid district build locations

# hover colors
var terraForm_hoverColor =  Color("f1fac3")
var districtBuilder_validColor = Color("8dd983")
var districtBuilder_invalidColor = Color("ffb0b0")
var neighbor_highlight = Color("8be4ff")
var self_view_highlight = Color("fff691")

onready var tile_area = get_node("TileArea") 
onready var terrain_sprite= get_node("Terrain")

func _ready():
	_update_position(x, y)
	_update_terrain(terrain_type)
	pass

func _process(delta):
	pass
	
# initial setup
	# I added the the underscore below the name to prevent overshadowing
	# which in turn causes problem with placing the right value for the node
	# defined variable
	# cube_coord q == x; r == y; s == z
func init(cartesian_coord: Vector2, cube_coord_: Vector3, map_):
	# temporary just want to see if my code works
	x = cartesian_coord.x 
	y = cartesian_coord.y
	map = map_
	cube_coord = cube_coord_

	set_name("%s" % cube_coord)

# set converted tile positions to screen coords from isometric plane
	# and vertical offset values when hovering
func _update_position(x_, y_):
	# resize i_hat and j_hat vectors accoriding to tile width and height	
		# divide tile_width by 2 since original takes more than 2 reference tiles
		# ref tile is 1:1
	var i_hat = Vector2(1 * tile_width / 2, 0.5 * tile_height)
	var j_hat = Vector2(-1 * tile_width / 2, 0.5 * tile_height)
	# note tile position/pivot is in bottom left of sprite

	x = x_
	y = y_
	position = (x_ * i_hat) + (y_ * y_off *  j_hat)
	rest_position = position
	hover_position = Vector2(position.x, position.y - 128 * 0.10)

# set tile terrain type and image texture
func _update_terrain(terrain_type_: String):
	terrain_type = terrain_type_
	terrain_texture = _load_terrain_texture(terrain_type)

	terrain_sprite.texture = terrain_texture 

# load a terrain texture from folder named type
func _load_terrain_texture(type: String) -> Resource:
	return load("res://Assets/Tiles/terrain/" + type + "/" + type + "_1" + ".png")

func _build_district():
	if valid_build_location:
		_update_terrain(map.map_builder.mode_type)
	else:
		pass

# checks and colors if the hovered build location based validity
	# modulates the tile depending on validity and returns
	# the validity
func validate_build_location():
	# set initial value as false. 
		# This is to avoid conflicts in future validations where the value
		# is that of the former validation
	valid_build_location = false

	if terrain_type in invalid_district_locations:
		modulate = districtBuilder_invalidColor
	else:
		valid_build_location = true
		modulate = districtBuilder_validColor 

# Captures events
func _input(event):
	if event is InputEventMouseButton: 
		if event.button_index == 1: _toggle_paint_mode(event)

# Sets values specific during hover
		# like hover color and map painting
		# when paint mode is enabled
func _on_TileArea_mouse_entered():
	map.hovered_tile = self

	match map.map_builder.mode:
		"TerraForm":
			_hover_on_TerraForm()
		"DistrictBuilder":
			_hover_on_DistrictBuilder()
		"View":
			_hover_on_View()
	
	map.emit_signal("update_hovered_tile_details")

func get_neighbors():
	var direction_vectors: PoolVector3Array= [ 
		# all direction as per q r s orientations
		# https://www.redblobgames.com/grids/hexagons/#neighbors

	Vector3(+1, 0, -1), Vector3(+1, -1, 0), Vector3(0, -1, +1), 
	Vector3(-1, 0, +1), Vector3(-1, +1, 0), Vector3(0, +1, -1), 
	]

	# calculate neighbors first
	for direction in direction_vectors:
		var neighbor_coord = "%s" % (cube_coord + direction)
		var neighbor_in_coord = map.tiles.get_node(neighbor_coord)

		if  neighbor_in_coord != null: 
			neighbors.append(neighbor_in_coord)
			neighbor_names.append(neighbor_coord)

# hover response when map builder mode is set to View
func _hover_on_View():
	if map.map_builder.highlight_neighbors:
		highlight_self()
		highlight_neighbors()
	else:
		# position = hover_position # offset position to make it look like the tile was elevated
		# highlight self
		highlight_self()

# hover response when map builder mode is set to TerraForm
func _hover_on_TerraForm():
	modulate = terraForm_hoverColor
	if map.paint_mode: _update_terrain(map.map_builder.mode_type)
	
func _hover_on_DistrictBuilder():
	validate_build_location()
	if map.paint_mode: _build_district()

# Resets values set on hover
	# like the hover color and the map
	# hovered tile
func _on_TileArea_mouse_exited():
	unhighlight_self()
	if map.map_builder.mode == "View": unhighlight_neighbors()

	map.hovered_tile = null 

func highlight_neighbors():
	for neighbor in neighbors: neighbor.highlight_self_as_neighbor()

func unhighlight_neighbors():
	for neighbor in neighbors: neighbor.unhighlight_self()

func highlight_self_as_neighbor():
	modulate = neighbor_highlight

func highlight_self():
	modulate = self_view_highlight

func unhighlight_self():
	modulate = Color("ffffff")

func _on_TileArea_input_event(viewport:Node, event:InputEvent, shape_idx:int):
	var modify_tile_event: bool = event is InputEventMouseButton && event.is_pressed() && event.button_index == 1
	
	if modify_tile_event: 
		match map.map_builder.mode:
			"TerraForm":
				_update_terrain(map.map_builder.mode_type)
			"DistrictBuilder":
				_build_district()
	else:
		pass

# toggle paint mode on or off
	# paint mode allows a tiles terrain to be modified
	# without clicking again, provided that an initial click was made
	# and has not been released
	# event: InputEvent 
		# left mouse button press or otherwis
func _toggle_paint_mode(event: InputEvent):
		map.paint_mode = event.is_pressed()
		map.emit_signal("paint_mode_switch")
