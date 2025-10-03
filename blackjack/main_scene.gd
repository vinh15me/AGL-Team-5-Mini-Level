extends Node2D

const blackjackGame = preload("res://cards.gd")
var game = blackjackGame.Game.new()
var currentBet:int = 1 

signal send_data_to_player(suit: String, rank: String)
signal send_data_to_dealer(suit: String, rank: String)

func _ready():
	game.send_data_to_main.connect(_send_to_display)
	Globals._ensure_minimum()
	$Control/HitButton.visible = false
	$Control/StandButton.visible = false
	update_money()
	
func update_money():
	$Control/CurrentMoney.text = str(Globals.money)
	$Control/HighestMoney.text = str(Globals.high_money)
	
func _send_to_display(suit: String, rank: String, player_or_dealer: int):
	print("suit " + suit)
	print("rank " + rank)
	print("player or dealer " + str(player_or_dealer))
	print("in main")
	if player_or_dealer == 0:
		print("going to player")
		send_data_to_player.emit(suit,rank)
	else:
		print("going to dealer")
		send_data_to_dealer.emit(suit,rank)

func update_turn():
	var turn_text: String
	if (game.currentRound.is_player_turn):
		turn_text = "Player turn"
	else:
		turn_text = "Dealer turn"
	$Control/TurnLabel.text = turn_text
	$Control/DealerHandValue.text = str(game.currentRound.dealer_hand.value())
	$Control/PlayerHandValue.text = str(game.currentRound.player_hand.value())

func _on_increase_bet_pressed() -> void:
	if currentBet < Globals.money:
		currentBet += 1
		$Control/BetLabel.text = str(currentBet)
		

func _on_decrease_bet_pressed() -> void:
	if currentBet > 1:
		currentBet -= 1
		$Control/BetLabel.text = str(currentBet)

func _on_hit_button_pressed() -> void:
	if (game.can_player_play()):
		var outcome = game.hit()
		append_history(win_translator(outcome))
		update_turn()

func _on_stand_button_pressed() -> void:
	if (game.can_player_play()):
		game.stand()
		
	var outcome = blackjackGame.RoundOutcome.InProgress
	while (outcome == blackjackGame.RoundOutcome.InProgress):
		outcome = game.currentRound.dealer_play()
		append_history(win_translator(outcome))
		update_turn()

func append_history(s: String) -> void:
	$Control/History.text += "\n" + s

func win_translator(outcome: blackjackGame.RoundOutcome) -> String:
	var historyEntry: String
	if (outcome == blackjackGame.RoundOutcome.InProgress):
		print("the game continues")
		return "the game continues"
	
	if (outcome == blackjackGame.RoundOutcome.Draw):
		print("game ended in draw")
		Globals.earn(currentBet)
		update_money()
		$Control/TryAgainButton.visible = true
		$Control/HitButton.visible = false
		$Control/StandButton.visible = false
		$Control/YouTied.visible = true
		return "game ended in draw"
	
	var was_natural = game.currentRound.turns == 0
	if (outcome == blackjackGame.RoundOutcome.PlayerWin):
		var dealer_hand_status = game.currentRound.dealer_hand.analyze()
		Globals.earn(currentBet * 2)
		historyEntry = "Player won "
		if (dealer_hand_status == blackjackGame.HandStatus.Bust):
			historyEntry += "because Dealer busted."
		else:
			if (was_natural):
				historyEntry += "natural "
			historyEntry += "blackjack."
		$Control/YouWin.visible = true
	elif (outcome == blackjackGame.RoundOutcome.DealerWin):
		var player_hand_status = game.currentRound.player_hand.analyze()
		historyEntry = "Dealer won "
		if (player_hand_status == blackjackGame.HandStatus.Bust):
			historyEntry += "because Player busted."
		else:
			if (was_natural):
				historyEntry += "natural "
			historyEntry += "blackjack."
		$Control/YouLose.visible = true
	print(historyEntry)
	update_money()
	$Control/TryAgainButton.visible = true
	$Control/HitButton.visible = false
	$Control/StandButton.visible = false
	return historyEntry
	
func _on_try_again_button_pressed() -> void:
	var scene := get_tree().current_scene
	if scene:
		var path := scene.scene_file_path
		get_tree().change_scene_to_file(path)

func _on_start_button_pressed() -> void:
	var outcome = game.start()
	Globals.spend(currentBet)
	append_history(win_translator(outcome))
	update_turn()
	update_money()
	$Control/StartButton.visible = false
	$Control/DecreaseBet.visible = false
	$Control/IncreaseBet.visible = false
	$Control/HitButton.visible = true
	$Control/StandButton.visible = true
