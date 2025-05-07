extends Control

# UI References
@onready var sanctum_label = $Panel/MarginContainer/VBoxContainer/SanctumLabel
@onready var research_label = $Panel/MarginContainer/VBoxContainer/ResearchLabel
@onready var research_button = $Panel/MarginContainer/VBoxContainer/ResearchButton
@onready var velarite_research_label = $Panel/MarginContainer/VBoxContainer/VelariteResearchLabel
@onready var velarite_research_button = $Panel/MarginContainer/VBoxContainer/VelariteResearchButton

func _ready():
	update_ui()

	# Connect buttons
	research_button.pressed.connect(_on_research_button_pressed)
	velarite_research_button.pressed.connect(_on_velarite_research_button_pressed)

func update_ui():
	# Ricerca automatica
	if GameManager.tech_unlocked:
		research_label.text = "✅ Auto-Collection Active!"
		research_button.disabled = true
	else:
		research_label.text = "Research: Enables Auto-Collection"
		research_button.disabled = GameManager.get_resource("stone") < 15

	# Ricerca viaggi interdimensionali
	if GameManager.interdimensional_unlocked:
		velarite_research_label.text = "✅ Interdimensional Travel Unlocked!"
		velarite_research_button.disabled = true
	else:
		velarite_research_label.text = "Research: Unlocks Interdimensional Travel"
		velarite_research_button.disabled = GameManager.get_resource("velarite") < 10

func _on_research_button_pressed():
	if GameManager.tech_unlocked:
		return

	var success = GameManager.remove_resource("stone", 15)
	if success:
		GameManager.tech_unlocked = true
		GameManager.start_auto_collect()
		update_ui()

func _on_velarite_research_button_pressed():
	if GameManager.interdimensional_unlocked:
		return

	var success = GameManager.remove_resource("velarite", 10)
	if success:
		GameManager.interdimensional_unlocked = true
		update_ui()
		print("✨ Viaggi interdimensionali sbloccati!")
