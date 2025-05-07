extends Control

@onready var xp_button = $Panel/VBoxContainer/XpBonusButton
@onready var def_button = $Panel/VBoxContainer/DefenseBonusButton
@onready var atk_button = $Panel/VBoxContainer/AttackBonusButton

func _ready():
	add_to_group("ReincarnationUI")
	hide()
	xp_button.pressed.connect(func(): select_bonus("xp"))
	def_button.pressed.connect(func(): select_bonus("defense"))
	atk_button.pressed.connect(func(): select_bonus("attack"))

func show_reincarnation_screen():
	visible = true

func select_bonus(bonus: String):
	GameManager.apply_reincarnation_bonus(bonus)
	GameManager.reincarnate_player()
	visible = false
