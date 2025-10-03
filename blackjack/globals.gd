extends Node

signal money_changed(amount:int)

@export var starting_money: int = 10
var money: int

func _enter_tree() -> void:
	# init / load once at game boot
	money = _load_money() if _has_save() else starting_money
	money_changed.emit(money)

func earn(amount: int) -> void:
	if amount <= 0: return
	money += amount
	money_changed.emit(money)
	_save_money()

func spend(amount: int) -> bool:
	if amount <= 0: return true
	if money < amount: return false
	money -= amount
	money_changed.emit(money)
	_save_money()
	return true
	
func _ensure_minimum() -> void:
	if money <= 0:
		money = 1  # the “broke → $1” rule

# --- basic persistence (optional) ---
func _save_money() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("wallet", "money", money)
	cfg.save("user://save.cfg")

func _has_save() -> bool:
	return FileAccess.file_exists("user://save.cfg")

func _load_money() -> int:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") != OK:
		return starting_money
	return int(cfg.get_value("wallet", "money", starting_money))
