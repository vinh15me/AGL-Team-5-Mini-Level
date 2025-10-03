extends Node2D

const blackjackGame = preload("res://cards.gd")
var game = blackjackGame.Game.new()

signal send_data_to_player(suit: String, rank: String)
signal send_data_to_dealer(suit: String, rank: String)

func _ready():
	game.send_data_to_main.connect(_send_to_display)
	
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
		print("game ended in draw")
		return "the game continues"
	
	if (outcome == blackjackGame.RoundOutcome.Draw):
		print("game ended in draw")
		return "game ended in draw"
	
	var was_natural = game.currentRound.turns == 0
	if (outcome == blackjackGame.RoundOutcome.PlayerWin):
		var dealer_hand_status = game.currentRound.dealer_hand.analyze()
		historyEntry = "Player won "
		if (dealer_hand_status == blackjackGame.HandStatus.Bust):
			historyEntry += "because Dealer busted."
		else:
			if (was_natural):
				historyEntry += "natural "
			historyEntry += "blackjack."
	elif (outcome == blackjackGame.RoundOutcome.DealerWin):
		var player_hand_status = game.currentRound.player_hand.analyze()
		historyEntry = "Dealer won "
		if (player_hand_status == blackjackGame.HandStatus.Bust):
			historyEntry += "because Player busted."
		else:
			if (was_natural):
				historyEntry += "natural "
			historyEntry += "blackjack."
	print(historyEntry)
	return historyEntry

func _on_start_button_pressed() -> void:
	var outcome = game.start()
	append_history(win_translator(outcome))
	update_turn()
	$Control/StartButton.visible = false
