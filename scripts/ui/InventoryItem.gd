extends Control

signal equip_requested(item: Item)
signal unequip_requested(item_type: String)

@onready var icon = $Icon
@onready var name_label = $VBoxContainer/NameLabel
@onready var quantity_label = $VBoxContainer/QuantityLabel
@onready var equip_button = $VBoxContainer/EquipButton

var item_ref: Item

func set_item(name: String, quantity: int, icon_path: String = ""):
	name_label.text = name.capitalize()
	quantity_label.text = "x" + str(quantity)
	equip_button.visible = false  # le risorse non sono equipaggiabili

	if icon_path != "":
		var tex = load(icon_path)
		if tex:
			icon.texture = tex

func set_item_from_instance(item: Item, icon_path: String = ""):
	item_ref = item
	name_label.text = item.name.capitalize()
	quantity_label.text = "Tipo: " + item.item_type.capitalize()
	equip_button.visible = item.item_type in ["weapon", "armor", "relic"]

	if icon_path != "":
		var tex = load(icon_path)
		if tex:
			icon.texture = tex

	var equipped = GameManager.equipped_items.get(item.item_type)
	var is_equipped = equipped != null and equipped.name == item.name

	# Cambia colore se equipaggiato
	modulate = Color(0.8, 1.0, 0.8) if is_equipped else Color(1, 1, 1)

	# Cambia testo del pulsante
	equip_button.text = "Remove" if is_equipped else "Equip"

func _on_equip_button_pressed():
	if not item_ref:
		return

	var equipped = GameManager.equipped_items.get(item_ref.item_type)
	var is_equipped = equipped != null and equipped.name == item_ref.name

	if is_equipped:
		emit_signal("unequip_requested", item_ref.item_type)
	else:
		emit_signal("equip_requested", item_ref)
