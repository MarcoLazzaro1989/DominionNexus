extends Control
signal request_forge  # segnale per informare PlanetScreen

@onready var result_label           = $MainPanel/MarginContainer/VBoxContainer/ResultLabel
@onready var cost_label             = $MainPanel/MarginContainer/VBoxContainer/CostLabel
@onready var forge_button           = $MainPanel/MarginContainer/VBoxContainer/ButtonsBox/ForgeButton
@onready var close_button           = $MainPanel/MarginContainer/VBoxContainer/ButtonsBox/ChiudiButton
@onready var object_type_selector   = $MainPanel/MarginContainer/VBoxContainer/ObjectTypeSelector

func _ready():
	_update_cost_display()
	forge_button.pressed.connect(_on_forge_pressed)
	close_button.pressed.connect(_on_close_pressed)
	update_result_label("")

func _update_cost_display() -> void:
	# Prendo i costi dal bilanciatore
	var cost = GameManager.balancing.get("forge_cost", {})
	var s = cost.get("stone", 0)
	var w = cost.get("wood", 0)
	var v = cost.get("velarite", 0)

	# Aggiorno la label dei costi
	cost_label.text = "Cost: %d Stone, %d Wood, %d Velarite" % [s, w, v]

	# Abilito/disabilito il bottone Forge
	forge_button.disabled = not (
		GameManager.get_resource("stone")   >= s and
		GameManager.get_resource("wood")    >= w and
		GameManager.get_resource("velarite")>= v
	)

func _on_forge_pressed() -> void:
	# Verifica risorse
	var cost = GameManager.balancing.get("forge_cost", {})
	if not _has_required_resources(cost):
		update_result_label("❌ Risorse insufficienti.")
		return

	# Rimuovo le risorse
	for key in cost.keys():
		GameManager.remove_resource(key, cost[key])

	# Determino il tipo selezionato
	var idx   = object_type_selector.get_selected_id()
	var typ   = object_type_selector.get_item_text(idx).to_lower()

	# Genero l'oggetto
	var biome    = GameManager.planet_biome
	var generator = ItemGenerator.new()
	var new_item  = generator.generate_random_item(biome, typ)

	# Aggiungo all'inventario
	GameManager.add_forged_item(new_item)

	# Assegno XP
	GameManager.add_xp(10)

	# Mostro risultato
	update_result_label("✅ Created:\n" + new_item.describe())

	# Notifico PlanetScreen
	request_forge.emit()

	# Aggiorna costi (potrebbero essere cambiati)
	_update_cost_display()

func _has_required_resources(cost: Dictionary) -> bool:
	for key in cost.keys():
		if GameManager.get_resource(key) < cost[key]:
			return false
	return true

func _on_close_pressed() -> void:
	visible = false

func update_result_label(text: String) -> void:
	result_label.text = text
