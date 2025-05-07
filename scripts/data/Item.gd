extends Resource
class_name Item

@export var name: String = ""
@export var item_type: String = "generic"
@export var rarity: String = "common"
@export var biome: String = ""

@export var stats := {
	"attack": 0,
	"defense": 0,
	"magic": 0,
	"speed": 0,
	"burn_chance": 0.0,
	"freeze_chance": 0.0
}

@export var effects: Array[String] = []

func describe() -> String:
	var s = "[%s] %s (%s)" % [rarity.capitalize(), name, item_type]
	if stats.size() > 0:
		s += "\nStats: "
		for key in stats.keys():
			if stats[key] != 0:
				s += "%s: %s  " % [key, stats[key]]
	if effects.size() > 0:
		s += "\nEffects: %s" % ", ".join(effects)
	return s
	
func to_dict() -> Dictionary:
	return {
		"name": name,
		"stats": stats,
		"biome": biome,
		"item_type": item_type
	}

static func from_dict(data: Dictionary) -> Item:
	var i = Item.new()
	i.name = data.get("name", "")
	i.stats = data.get("stats", {})
	i.biome = data.get("biome", "")
	i.item_type = data.get("item_type", "")
	return i
