extends Control

var auto_collect_time := 2.0
var bar_fill := 0.0

@onready var tabs := $MainTabs
@onready var xp_ring = $MainTabs/AvatarTab/AvatarSection/PortraitVBox/PortraitPane/XPRing
# Header
@onready var stone_label    : Label = $TopBar/HBoxContainer/ResourceScroll/ResourceCarousel/StoneLabel
@onready var wood_label     : Label = $TopBar/HBoxContainer/ResourceScroll/ResourceCarousel/WoodLabel
@onready var velarite_label : Label = $TopBar/HBoxContainer/ResourceScroll/ResourceCarousel/VelariteLabel
@onready var biome_label    : Label = $TopBar/HBoxContainer/ResourceScroll/ResourceCarousel/BiomeLabel

# Pulsanti e progress bar
@onready var collect_button = $MainTabs/AvatarTab/AvatarSection/AvatarInfo/ResourceButtons/CollectButton
@onready var auto_collect_bar = $MainTabs/AvatarTab/AvatarSection/AvatarInfo/ResourceButtons/AutoCollectBar
@onready var velarite_button = $MainTabs/AvatarTab/AvatarSection/AvatarInfo/ResourceButtons/VelariteButton
@onready var build_button = $MainTabs/AvatarTab/AvatarSection/AvatarInfo/ResourceButtons/BuildSanctumButton
@onready var open_map_button = $MainTabs/AvatarTab/AvatarSection/AvatarInfo/ResourceButtons/OpenMapButton
@onready var travel_button = $MainTabs/AvatarTab/AvatarSection/AvatarInfo/ResourceButtons/InterdimensionalTravelButton
@onready var inventory_button = $BottomBar/FooterButtons/InventoryButton
@onready var open_forge_button = $BottomBar/FooterButtons/OpenForgeButton
@onready var open_sanctum_button = $BottomBar/FooterButtons/OpenSanctumButton
@onready var open_gear_button = $BottomBar/FooterButtons/OpenGearButton

# Overlay panels (spostati fuori dalla scroll area)
@onready var sanctum_panel = $SanctumPanel
@onready var inventory_panel = $InventoryPanel
@onready var forge_panel = $ForgePanel
@onready var gear_panel = $GearPanel

# Sanctum inner elements
@onready var sanctum_label = sanctum_panel.get_node("Panel/MarginContainer/VBoxContainer/SanctumLabel")
@onready var research_label = sanctum_panel.get_node("Panel/MarginContainer/VBoxContainer/ResearchLabel")
@onready var research_button = sanctum_panel.get_node("Panel/MarginContainer/VBoxContainer/ResearchButton")
@onready var velarite_research_label = sanctum_panel.get_node("Panel/MarginContainer/VBoxContainer/VelariteResearchLabel")
@onready var velarite_research_button = sanctum_panel.get_node("Panel/MarginContainer/VBoxContainer/VelariteResearchButton")

# Timers
@onready var auto_timer = $AutoCollectTimer
@onready var progress_timer = $ProgressTickTimer

@onready var level_label = $MainTabs/AvatarTab/AvatarSection/PortraitVBox/PortraitPane/LevelLabel

func _ready():
	tabs.set_tab_title(0, "Avatar")
	tabs.set_tab_title(1, "Hunters")
	tabs.set_tab_title(2, "Raiders")
	GameManager.load_game()
	GameManager.calculate_offline_production()
	update_biome_label()
	update_xp_display()	

	hide_all_overlays()
	forge_panel.request_forge.connect(_on_forge_requested)

	# Connessioni pulsanti
	collect_button.pressed.connect(_on_collect_button_pressed)
	build_button.pressed.connect(_on_build_button_pressed)
	research_button.pressed.connect(_on_research_button_pressed)
	velarite_button.pressed.connect(_on_extract_velarite_button_pressed)
	velarite_research_button.pressed.connect(_on_velarite_research_button_pressed)
	travel_button.pressed.connect(_on_travel_button_pressed)
	open_map_button.pressed.connect(_on_open_map_button_pressed)
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	open_forge_button.pressed.connect(_on_open_forge_pressed)
	open_sanctum_button.pressed.connect(_on_open_sanctum_pressed)
	open_gear_button.pressed.connect(_on_open_gear_pressed)

	# Timer
	auto_timer.timeout.connect(_on_AutoCollectTimer_timeout)
	progress_timer.timeout.connect(_on_ProgressTickTimer_timeout)

	# Defer UI init per assicurare che tutti i nodi siano pronti
	call_deferred("_initialize_ui")


func hide_all_overlays():
	sanctum_panel.visible = false
	inventory_panel.visible = false
	forge_panel.visible = false
	gear_panel.visible = false

func show_overlay(POI_type: String):
	hide_all_overlays()
	match POI_type:
		"sanctum":
			sanctum_panel.visible = true
			sanctum_panel.update_ui()
		"inventory":
			inventory_panel.visible = true
			inventory_panel.update_inventory()
		"forge":
			forge_panel.visible = true
			forge_panel._update_cost_display()
		"gear":
			gear_panel.visible = true
			gear_panel.update_gear_display()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		hide_all_overlays()

func update_biome_label():
	biome_label.text = "Biome: " + GameManager.planet_biome

func update_resource_labels():
	stone_label.text = str(GameManager.get_resource("stone"))
	wood_label.text = str(GameManager.get_resource("wood"))
	velarite_label.text = str(GameManager.get_resource("velarite"))

	build_button.disabled = GameManager.get_resource("stone") < 10 or GameManager.sanctum_built
	research_button.disabled = (
		GameManager.get_resource("stone") < 15 or
		GameManager.tech_unlocked or
		not GameManager.sanctum_built
	)

func _on_collect_button_pressed():
	GameManager.add_resource("stone", 1)
	update_resource_labels()

func _on_build_button_pressed():
	if GameManager.sanctum_built:
		return
	if GameManager.remove_resource("stone", 10):
		GameManager.sanctum_built = true
		show_overlay("sanctum")
		build_button.visible = false
	update_resource_labels()

func _on_research_button_pressed():
	if GameManager.tech_unlocked:
		return
	if GameManager.remove_resource("stone", 15):
		GameManager.tech_unlocked = true
		research_label.text = "✅ Search completed: automatic collection activated!"
		research_button.disabled = true
		auto_timer.start()
		progress_timer.start()
		bar_fill = 0.0
		auto_collect_bar.value = 0
	update_resource_labels()

func _on_AutoCollectTimer_timeout():
	if GameManager.tech_unlocked:
		GameManager.add_resource("stone", 2)
		GameManager.add_resource("wood", 1)
		update_resource_labels()
		bar_fill = 0.0
		auto_collect_bar.value = 0

func _on_ProgressTickTimer_timeout():
	if GameManager.tech_unlocked:
		bar_fill += (0.1 / auto_collect_time) * 100.0
		if bar_fill >= 100.0:
			bar_fill = 0.0
		auto_collect_bar.value = bar_fill

func _on_extract_velarite_button_pressed():
	GameManager.add_resource("velarite", 1)
	update_resource_labels()

func _on_velarite_research_button_pressed():
	if GameManager.interdimensional_unlocked:
		return
	if GameManager.remove_resource("velarite", 10):
		GameManager.interdimensional_unlocked = true
		velarite_research_label.text = "✅ Interdimensional Travel Unlocked!"
		velarite_research_button.disabled = true
		print("Ora puoi effettuare viaggi interdimensionali!")
	update_resource_labels()

func _on_travel_button_pressed():
	print("✨ Hai iniziato un viaggio interdimensionale! (in sviluppo...) ✨")

func _on_open_map_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main/PlanetMap.tscn")

func _on_inventory_button_pressed():
	show_overlay("inventory")

func _on_open_forge_pressed():
	show_overlay("forge")
	
func _on_open_gear_pressed():
	show_overlay("gear")

func _on_forge_requested():
	print("🔥 Ricevuto segnale di forgiatura!")

func check_unlocks():
	travel_button.visible = GameManager.interdimensional_unlocked
	travel_button.disabled = not GameManager.interdimensional_unlocked

	var giacimento = GameManager.is_poi_unlocked("giacimento")
	velarite_button.visible = giacimento
	velarite_button.disabled = not giacimento
	velarite_research_button.disabled = not giacimento

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameManager.save_game()

		
func _on_open_sanctum_pressed():
	show_overlay("sanctum")
	research_button.disabled = not GameManager.is_poi_unlocked("universita")


func _initialize_ui():
	update_resource_labels()
	check_unlocks()
	if GameManager.tech_unlocked:
		research_label.text = "✅ Search completed: automatic collection activated!"
		research_button.disabled = true
		research_button.visible = false
		auto_timer.start()
		progress_timer.start()
		bar_fill = 0.0
		auto_collect_bar.value = 0

	if GameManager.sanctum_built:
		build_button.visible = false


func show_level_up_popup():
	$MainTabs/AvatarTab/AvatarSection/PortraitVBox/AnimAvatar.play("LevelUpFlash")

func update_xp_display():
	var required_xp = GameManager.get_required_xp(GameManager.player_level)
	var current_xp = GameManager.player_xp
	var xp_fill_ratio = float(current_xp) / float(required_xp)
	level_label.text = "Level: " + str(GameManager.player_level)
	xp_ring.material.set_shader_parameter("fill_amount", xp_fill_ratio)
