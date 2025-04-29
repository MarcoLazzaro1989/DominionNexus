extends Node

# —————————————————————————
# CONSTANTS
# —————————————————————————
const RESOURCE_TYPES = ["stone", "wood", "velarite"]
const SAVE_PATH := "user://savegame.json"
const BASE_XP_TO_LEVEL := 100
var balancing := {}

# —————————————————————————
# SIGNALS
# —————————————————————————
signal resource_changed(res_name: String, new_value: int)

# —————————————————————————
# PLAYER STATE
# —————————————————————————
var resources := {}
var item_inventory: Array[Item] = []
var unlocked_poi = {
	"universita": false,
	"giacimento": false,
	"metropoli": false
}
var equipped_items = {"weapon": null, "armor": null, "relic": null}
var player_class := ""
var player_xp := 0
var player_level := 1
var reincarnation_count := 0
var legacy_bonuses = []
var planet_biome := ""
var last_saved_time := 0
var tech_unlocked := false
var interdimensional_unlocked := false
var sanctum_built := false

# —————————————————————————
# LIFECYCLE
# —————————————————————————
func _ready():
	_load_balancing()
	load_game()
	calculate_offline_production()

func _load_balancing() -> void:
	var path = "res://config/balancing.json"
	if not FileAccess.file_exists(path):
		push_error("Missing balancing.json!")
		return

	var f = FileAccess.open(path, FileAccess.READ)
	var text = f.get_as_text()
	f.close()

	# JSON.parse_string restituisce il tuo Dictionary
	balancing = JSON.parse_string(text)

# —————————————————————————
# RESOURCE MANAGEMENT
# —————————————————————————
func add_resource(res_name: String, amount: int) -> void:
	if res_name in RESOURCE_TYPES:
		resources[res_name] += amount
		emit_signal("resource_changed", res_name, resources[res_name])
	else:
		push_error("Unknown resource: %s" % res_name)

func remove_resource(res_name: String, amount: int) -> bool:
	if res_name in RESOURCE_TYPES and resources[res_name] >= amount:
		resources[res_name] -= amount
		emit_signal("resource_changed", res_name, resources[res_name])
		return true
	return false

func get_resource(res_name: String) -> int:
	return resources.get(res_name, 0)

# —————————————————————————
# POINTS OF INTEREST
# —————————————————————————
func unlock_poi(poi_name: String) -> void:
	if poi_name in unlocked_poi:
		unlocked_poi[poi_name] = true

func is_poi_unlocked(poi_name: String) -> bool:
	return unlocked_poi.get(poi_name, false)

# —————————————————————————
# XP & LEVELING
# —————————————————————————
func get_required_xp(level: int) -> int:
	var base = balancing.get("base_xp_to_level", 100)
	var inc  = balancing.get("xp_increment_per_level", 25)
	return base + (level - 1) * inc

func add_xp(amount: int) -> void:
	player_xp += amount
	var req = get_required_xp(player_level)
	if player_xp >= req:
		player_level += 1
		player_xp -= req
		emit_level_up()
		if player_level >= 3:
			trigger_reincarnation()
	else:
		print("Gained %d XP (%d/%d)" % [amount, player_xp, req])
		get_tree().call_group("LevelUI", "update_xp_display")

func emit_level_up() -> void:
	print("Level up! Now at %d" % player_level)
	if get_tree().has_group("LevelUI"):
		get_tree().call_group("LevelUI", "update_xp_display")
		get_tree().call_group("LevelUI", "update_level_label")
		get_tree().call_group("LevelUI", "show_level_up_popup", player_level)

# —————————————————————————
# FORGE & INVENTORY
# —————————————————————————
func add_forged_item(item: Item) -> void:
	item_inventory.append(item)

func equip_item(item: Item) -> bool:
	if item and item.item_type in equipped_items:
		equipped_items[item.item_type] = item
		return true
	return false

func unequip_all() -> void:
	for slot in equipped_items.keys():
		equipped_items[slot] = null

func get_total_stats() -> Dictionary:
	var stats = {
		"attack":0,"defense":0,"magic":0,
		"speed":0,"burn_chance":0.0,"freeze_chance":0.0
	}
	for slot in equipped_items:
		var it = equipped_items[slot]
		if it:
			for k in it.stats.keys():
				stats[k] += it.stats[k]
	return stats

# —————————————————————————
# REINCARNATION
# —————————————————————————
func trigger_reincarnation() -> void:
	print("Character has died, reincarnating…")
	if get_tree().current_scene.has_method("hide_all_overlays"):
		get_tree().current_scene.hide_all_overlays()
	if get_tree().has_group("ReincarnationUI"):
		get_tree().call_group("ReincarnationUI", "show_reincarnation_screen")

func apply_reincarnation_bonus(bonus: String) -> void:
	legacy_bonuses.append(bonus)

func reincarnate_player() -> void:
	reincarnation_count += 1
	assign_random_biome()
	_reset_resources_and_progress()
	print("Reborn on %s" % planet_biome)

func _reset_resources_and_progress() -> void:
	for res in RESOURCE_TYPES:
		resources[res] = 0
	item_inventory.clear()
	unequip_all()
	player_level = 1
	player_xp = 0

# —————————————————————————
# OFFLINE PRODUCTION
# —————————————————————————
func calculate_offline_production() -> void:
	var now = Time.get_unix_time_from_system()
	var dt = now - last_saved_time
	if dt <= 0 or not tech_unlocked:
		return

	var cfg = balancing.get("offline_production", {})
	var cycle_time = cfg.get("cycle_seconds", 2)
	var rates = cfg.get("rates", {})
	var cycles = int(dt / cycle_time)

	for res_name in rates.keys():
		var rate = rates[res_name]
		resources[res_name] = get_resource(res_name) + cycles * rate
		emit_signal("resource_changed", res_name, resources[res_name])

# —————————————————————————
# SAVE & LOAD
# —————————————————————————
func save_game() -> void:
	var data = {
		"resources": resources,
		"planet_biome": planet_biome,
		"timestamp": Time.get_unix_time_from_system(),
		"tech_unlocked": tech_unlocked,
		"interdimensional_unlocked": interdimensional_unlocked,
		"sanctum_built": sanctum_built,
		"unlocked_poi": unlocked_poi,
		"player_class": player_class,
		"legacy_bonuses": legacy_bonuses,
		"item_inventory": item_inventory.map(func(i): return i.to_dict()),
		"equipped_items": {},
		"player_xp": player_xp,
		"player_level": player_level,
		"reincarnation_count": reincarnation_count
	}
	for slot in equipped_items:
		var it = equipped_items[slot]
		data["equipped_items"][slot] = it.to_dict() if it != null else null

	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()

func load_game() -> void:
	# init resources
	for res in RESOURCE_TYPES:
		resources[res] = 0
	if not FileAccess.file_exists(SAVE_PATH):
		assign_random_biome()
		return

	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if not d:
		return

	resources = d.get("resources", resources)
	last_saved_time = d.get("timestamp", Time.get_unix_time_from_system())
	tech_unlocked = d.get("tech_unlocked", false)
	interdimensional_unlocked = d.get("interdimensional_unlocked", false)
	sanctum_built = d.get("sanctum_built", false)
	unlocked_poi = d.get("unlocked_poi", unlocked_poi)
	player_class = d.get("player_class", "")
	player_xp = int(d.get("player_xp", 0))
	player_level = int(d.get("player_level", 1))
	planet_biome = d.get("planet_biome", "")
	reincarnation_count = int(d.get("reincarnation_count", 0))
	legacy_bonuses = d.get("legacy_bonuses", []).map(func(x): return str(x))

	item_inventory.clear()
	for item_data in d.get("item_inventory", []):
		item_inventory.append(Item.from_dict(item_data))

	for slot in equipped_items.keys():
		var ed = d.get("equipped_items", {}).get(slot)
		equipped_items[slot] = Item.from_dict(ed) if (ed and typeof(ed) == TYPE_DICTIONARY) else null

	if planet_biome == "":
		assign_random_biome()

# —————————————————————————
# BIOME ASSIGNMENT
# —————————————————————————
func assign_random_biome() -> void:
	if planet_biome.is_empty():
		var biomes = ["Terrestrial", "Frozen", "Desert", "Iron"]
		planet_biome = biomes[randi() % biomes.size()]
