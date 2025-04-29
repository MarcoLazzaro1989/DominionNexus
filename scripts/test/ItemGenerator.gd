extends Node
class_name ItemGenerator

const ItemType = preload("res://scripts/data/Item.gd")
const BALANCING_PATH := "res://config/balancing.json"

# nomi base per tipo (puoi anche estrarli dal JSON se vuoi)
var base_names_by_type = {
	"weapon": ["Sword","Mace","Dagger","Axe","Bow","Flail","Spear"],
	"armor":  ["Helmet","Chestplate","Greaves","Shield","Cuirass"],
	"relic":  ["Talisman","Amulet","Orb","Crystal","Rune"]
}

# qui salviamo i dati letti da JSON
var biome_modifiers := {}
var biome_tags      := {}

func _init():
	_load_balancing()

func _load_balancing() -> void:
	var path = "res://config/balancing.json"
	if not FileAccess.file_exists(path):
		push_error("Missing balancing.json!")
		return

	var f = FileAccess.open(path, FileAccess.READ)
	var text = f.get_as_text()
	f.close()

	# JSON.parse_string restituisce il tuo Dictionary
	var cfg = JSON.parse_string(text)

	# Popola le tabelle
	biome_modifiers = cfg.get("biome_modifiers", {})
	biome_tags      = cfg.get("biome_tags", {})
	for key in biome_tags.keys():
		var v = biome_tags[key]
		if typeof(v) == TYPE_STRING:
			biome_tags[key] = [v]

func generate_random_item(biome: String, desired_type: String = "") -> Item:
	var item = Item.new()

	# 1) Tipo
	var types = ["weapon","armor","relic"]
	item.item_type = desired_type if desired_type != "" else types[randi() % types.size()]


	# 2) Bioma
	item.biome = biome

	# 3) Nome base
	var names = base_names_by_type.get(item.item_type, ["Item"])
	var base_name = names[randi() % names.size()]

	# 4) Rarità
	item.rarity = ["common","rare","epic"].pick_random()

	# 5) Stats di base casuali
	item.stats.attack  = randi_range(1,5)
	item.stats.defense = randi_range(0,3)
	item.stats.magic   = randi_range(0,4)
	item.stats.speed   = randi_range(0,2)

	# 6) Applichiamo i modificatori di bioma letti dal JSON
	var mod = biome_modifiers.get(biome, {})
	item.stats.attack      += mod.get("attack_bonus",  0)
	item.stats.defense     += mod.get("defense_bonus", 0)
	item.stats.magic       += mod.get("magic_bonus",   0)
	item.stats.burn_chance  = mod.get("burn_chance",  0.0)
	item.stats.freeze_chance= mod.get("freeze_chance",0.0)

	# 7) Scegliamo un tag casuale dal JSON
	var tag_list = biome_tags.get(biome, [])
	var suffix = ""
	if tag_list.size() > 0:
		suffix = tag_list[randi() % tag_list.size()]

	# 8) Assemblaggio nome finale
	# es. "Sword of the Dunes" oppure "Crystal Forged"
	if suffix != "":
		item.name = "%s %s" % [base_name, suffix]
	else:
		item.name = base_name

	return item
