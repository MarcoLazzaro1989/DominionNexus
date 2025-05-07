extends Control

# Slot
@onready var weapon_label = $Panel/MarginContainer/MainVBox/GearGrid/WeaponSlot/WeaponItemLabel
@onready var armor_label = $Panel/MarginContainer/MainVBox/GearGrid/ArmorSlot/ArmorItemLabel
@onready var relic_label = $Panel/MarginContainer/MainVBox/GearGrid/RelicSlot/RelicItemLabel

# Bonus
@onready var bonus_text = $Panel/MarginContainer/MainVBox/BonusText
@onready var close_button = $Panel/MarginContainer/MainVBox/CloseButton
@onready var legacy_bonus_text = $Panel/MarginContainer/MainVBox/LegacyBonusText

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	update_gear_display()

func update_gear_display():
	var gear = GameManager.equipped_items
	var total_stats := {}

	# Aggiorna slot e accumula bonus
	_update_slot(weapon_label, gear.weapon)
	if gear.weapon:
		_merge_stats(total_stats, gear.weapon.stats)

	_update_slot(armor_label, gear.armor)
	if gear.armor:
		_merge_stats(total_stats, gear.armor.stats)

	_update_slot(relic_label, gear.relic)
	if gear.relic:
		_merge_stats(total_stats, gear.relic.stats)

	# Mostra bonus formattati
	var ordered_keys = ["attack", "defense", "magic", "speed", "burn_chance", "freeze_chance"]
	var bonus_text_str = "[b]Active Bonuses:[/b]\n"

	var found = false
	for key in ordered_keys:
		if total_stats.has(key) and total_stats[key] != 0:
			found = true
			var label = key.capitalize().replace("_", " ")
			var value = total_stats[key]
			var value_str = str(round(value * 100)) + "%" if typeof(value) == TYPE_FLOAT else str(value)
			bonus_text_str += "• [color=gold]%s[/color]: %s\n" % [label, value_str]

	bonus_text.text = bonus_text_str if found else "[i]No Active Bonuses.[/i]"
	var legacy_display := "Legacy Bonuses:\n"
	var bonus_map = {
		"xp": "+10% XP gain",
		"defense": "+1 base Defense",
		"attack": "+1 base Attack"
	}
	for bonus in GameManager.legacy_bonuses:
		if bonus_map.has(bonus):
			legacy_display += "- %s\n" % bonus_map[bonus]
	legacy_bonus_text.text = legacy_display.strip_edges()

func _update_slot(label: Label, item: Item):
	label.text = item.name if item else "None"

func _merge_stats(target: Dictionary, stats: Dictionary):
	for key in stats:
		if not target.has(key):
			target[key] = 0
		target[key] += stats[key]

func _on_close_pressed():
	visible = false
