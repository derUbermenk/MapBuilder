extends Node2D

signal paint_mode_switch
signal update_hovered_tile_details

var tile_scene = load("res://Scenes/MapSupport/Tile.tscn")

# represents number of tiles
var world_size = 5 

var hovered_tile
var paint_mode = false

onready var tiles = get_node("Tiles")
onready var map_builder = get_parent() 

func _ready():
	draw_map()

# add process for checking current mouse pointer location
func _process(delta):
	pass

func draw_map(): 
	var last_row_cube_coord = Vector3() # instantiate a cube coord x == q, y == r, z == s

	for row in world_size:   # y

		# the cube coord of the first tile in this row
		var initial_tile_cube_coord= Vector3(last_row_cube_coord.x, last_row_cube_coord.y, last_row_cube_coord.z)

		for col in world_size: # x
			instance_tile(col, row, initial_tile_cube_coord)
			initial_tile_cube_coord += Vector3(1, 0, -1)
		
		last_row_cube_coord = compute_next_row_cube_coord(row, last_row_cube_coord)
	
	# calculate the neighbor of the tile once the tiles have been placed
	for tile in tiles.get_children():
		tile.get_neighbors()


func compute_next_row_cube_coord(row: int, last_cube_coord: Vector3) -> Vector3:
	var next_cube_coord = last_cube_coord + Vector3(
		-1 if (row == 0 or even(row)) else 0,
		1,
		-1 if !even(row) else 0
	)
	
	return next_cube_coord

func instance_tile(col: int, row: int, initial_tile_cube_coord: Vector3):
		var cartesian_coordinate = Vector2(
			col - 0.5 if !even(row) else col + 0.0, 
			row
		)
		var cube_coord = initial_tile_cube_coord 

		var tile = tile_scene.instance()

		tile.init(cartesian_coordinate, cube_coord, self)
		tiles.add_child(tile)

# reset the color of the hovered tile if there is any
func reset_hover_hightlight():
	if hovered_tile != null:
		hovered_tile.unhighlight_self()
	pass

func highlight_neighbors():
	pass

func track_mouse_loc():
	var mouse_pos = get_global_mouse_position()
	print(mouse_pos)

# function code for assigning cube coordinate to tiles
	# wrote this only as reference for the cube coordinate assignment in 
	# draw_map
func hexgrid_cube_coords():
	var q = 0
	var r = 0
	var s = 0

	for row in world_size:
		# start with the values set after last row or the origin depending on the case
		var row_q = q
		var row_s = s
		var row_r = r
		for col in world_size:
			# row_r does not change
			# assign the column values
			row_q += 1
			row_s -= 1
			row_r

		if row == 0 or row % 2 == 0: q -= 1
		if row % 2 != 0: s -= 1
		r += 1

func even(number) -> bool:
	# a number is even if the remainder of it
	# being divided by 2 is 0
	return number % 2 == 0
