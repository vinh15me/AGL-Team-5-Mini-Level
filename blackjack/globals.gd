extends Node

@export var starting_money: int = 10
var money: int
var high_money: int

func _enter_tree() -> void:
	# init / load once at game boot
	money = _load_money() if _has_save() else starting_money
	high_money = _load_high_money() if _has_save() else 1

func earn(amount: int) -> void:
	if amount <= 0: return
	money += amount
	_update_high() 
	_save_money()

func spend(amount: int) -> bool:
	if amount <= 0: return true
	if money < amount: return false
	money -= amount
	_save_money()
	return true
	
func _update_high() -> void:
	if money > high_money:
		high_money = money
	
func _ensure_minimum() -> void:
	if money <= 0:
		money = 1  # the “broke → $1” rule

# --- basic persistence (optional) ---
func _save_money() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("wallet", "money", money)
	cfg.set_value("wallet", "high_money", high_money)
	cfg.save("user://save.cfg")

func _has_save() -> bool:
	return FileAccess.file_exists("user://save.cfg")

func _load_money() -> int:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") != OK:
		return starting_money
	return int(cfg.get_value("wallet", "money", starting_money))

func _load_high_money() -> int:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") != OK:
		return 1
	return int(cfg.get_value("wallet", "high_money", 1))
