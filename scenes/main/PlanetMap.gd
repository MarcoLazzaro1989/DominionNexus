extends Control

@onready var tile_grid = $TileGrid
@onready var poi_dialog = $POIDialog

var tile_scene = preload("res://scenes/ui/TileButton.tscn") # percorso corretto

var explored_tiles := []
var poi_pool := ["University", "Deposit", "Metropolis", "Nothing"]

func _ready():
	for i in range(9):
		var tile = tile_scene.instantiate()
		tile.text = "?"
		tile_grid.add_child(tile)
		tile.pressed.connect(func(): _on_tile_pressed(tile))
		
	# Collega ogni bottone
	for tile in tile_grid.get_children():
		tile.pressed.connect(func():
			_on_tile_pressed(tile))

func _on_tile_pressed(tile):
	if tile in explored_tiles:
		return

	if GameManager.get_resource("stone") < 1:
		print("Non hai abbastanza Pietra")
		return

	var success = GameManager.remove_resource("stone", 1)
	if success:
		var content = generate_tile_content()
		tile.text = content
		explored_tiles.append(tile)

		# Mostra un dialogo se il POI non è "Niente"
		if content != "Nothing":
			var message := ""
			match content:
				"University":
					GameManager.unlock_poi("universita")
					message = "You have discovered an ancient University. From here, you can research new abilities."
				"Deposit":
					GameManager.unlock_poi("giacimento")
					message = "You have found a Velarite deposit. You can now begin extraction."
				"Metropolis":
					GameManager.unlock_poi("metropoli")
					message = "You have discovered an abandoned Metropolis. The ancient classes are emerging."
			GameManager.save_game() 
			poi_dialog.dialog_text = message
			poi_dialog.popup_centered()
		
func generate_tile_content() -> String:
	if poi_pool.is_empty():
		return "Nothing"
	var index = randi() % poi_pool.size()
	var selected = poi_pool[index]
	poi_pool.remove_at(index)
	return selected


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main/PlanetScreen.tscn")
