extends Control

@onready var grid = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
const ITEM_SCENE = preload("res://scenes/ui/InventoryItem.tscn")

var item_nodes := {}

func _ready():
	update_inventory()

func update_inventory():
	# Svuota griglia
	for c in grid.get_children():
		c.queue_free()
	item_nodes.clear()

	# Mostra risorse classiche
	for res_name in GameManager.resources.keys():
		var quantity = GameManager.get_resource(res_name)
		var item = ITEM_SCENE.instantiate()
		grid.add_child(item)
		item.call_deferred("set_item", res_name, quantity)
		item_nodes[res_name] = item

	# Mostra oggetti forgiati
	for item_data in GameManager.item_inventory:
		var node = ITEM_SCENE.instantiate()
		grid.add_child(node)

		var icon_path = get_icon_for_item(item_data)
		node.set_item_from_instance(item_data, icon_path)

		node.equip_requested.connect(_on_item_equip_requested)
		node.unequip_requested.connect(_on_item_unequip_requested)

func equip_item(item: Item):
	if GameManager.equip_item(item):
		print("✅ Equipaggiato:", item.name)
		update_inventory()
		_notify_gear_ui()

func unequip_item(item_type: String):
	GameManager.equipped_items[item_type] = null
	print("❎ Rimosso equipaggiamento da slot:", item_type)
	update_inventory()
	_notify_gear_ui()

func get_icon_for_item(item: Item) -> String:
	match item.item_type:
		"weapon": return "res://assets/icons/weapon.png"
		"armor": return "res://assets/icons/armor.png"
		"relic": return "res://assets/icons/relic.png"
		_: return "res://assets/icons/item_generic.png"

func _on_chiudi_pressed():
	visible = false

func _on_item_equip_requested(item: Item):
	equip_item(item)

func _on_item_unequip_requested(item_type: String):
	unequip_item(item_type)

func _notify_gear_ui():
	if get_tree().has_group("GearUI"):
		get_tree().call_group("GearUI", "update_gear_display")
