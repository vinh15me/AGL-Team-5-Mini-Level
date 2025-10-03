extends Node2D

@onready var root_scene: Node = get_tree().current_scene

var dealer_index: int = 0

func _ready():
	root_scene.send_data_to_dealer.connect(_test)

func _test(suit:String ,rank:String):
	
	print("suit " + suit)
	print("rank " + rank)
	print("in dealer")
	var path := "res://Asset-Scripts/Card/Card Assets/%s of %s.png" % [rank, suit]
	_set_sprite_player(path)

func _set_sprite_player(path: String):
	var child := get_child(dealer_index)
	child.show()
	dealer_index += 1
	var tex: Texture2D = load(path)
	child.texture = tex
	
