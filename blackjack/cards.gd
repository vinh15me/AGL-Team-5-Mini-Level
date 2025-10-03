
enum Suit { Hearts, Diamonds, Clubs, Spades }
enum Rank { Ace, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King }
enum HandStatus { Playing, Bust, Blackjack }
enum RoundOutcome { PlayerWin, DealerWin, Draw, InProgress }


class Card extends RefCounted:
	var rank: Rank
	var suit: Suit
	
	func _init(s: Suit, r: Rank) -> void:
		rank = r
		suit = s
		
	func _check_card() -> void:
		print_debug(Suit.keys()[suit])
		print_debug(Rank.keys()[rank])
	
		
class Deck extends RefCounted:
	var cards: Array[Card]
	
	func _generate_cards():
		var deck: Array[Card] = []
		for s in Suit.values():
			for r in Rank.values():
				var card = Card.new(s, r)
				deck.append(card)		
		return deck
	
	func _init():
		self.cards = self._generate_cards()
		
	func shuffle():
		self.cards.shuffle()
		
	func remaining():
		return cards
		
	func draw():
		return cards.pop_back()

class Hand extends RefCounted:
	var cards: Array[Card]
	
	func _calc_value(card: Card, count_ace: bool = true):
		# need to handle whether Ace is 11 or 1 
		if card.rank == 0 and count_ace:
			return 11
		elif card.rank > 9:
			return 10
		else:
			return card.rank + 1
	
	func _init():
		self.cards = []
		
	func value():
		var val: int = 0
		for card in cards:
			val += self._calc_value(card)
		return val
		
	func analyze():
		var val = self.value()
		print_debug("a hand is being analyzed: " + str(val))
		
		if val < 21:
			return HandStatus.Playing
		elif val > 21:
			return HandStatus.Bust
		else:
			return HandStatus.Blackjack
		
	func push_card(card: Card):
		cards.append(card)
		
#class Player extends RefCounted:
	#var hand: Hand
	#
	#func _init():
		#self.hand = Hand.new()
#
#class User extends Player:
	#
#
#class House extends Player:

class Round extends RefCounted:
	
	signal player_card_drawn(suit, rank, index)
	var player_or_dealer: int = 0
	
	var deck: Deck
	var player_hand: Hand
	var dealer_hand: Hand
	
	var playing_hand: Hand
	var is_player_turn: bool = false
	var is_game_won: bool = false
	var turns: int = 0 # need to check natural blackjack
	
	func _init() -> void:
		self.deck = Deck.new()
		self.deck.shuffle()
		self.player_hand = Hand.new()
		self.dealer_hand = Hand.new()
	
	func start() -> void:
		var give_cards_player = func (hand: Hand) -> void:
			for i in range(0, 2):
				var card = self.deck.draw()
				card._check_card()
				hand.push_card(card)
				player_card_drawn.emit( Suit.keys()[card.suit],Rank.keys()[card.rank],player_or_dealer)
		give_cards_player.call(player_hand)
		player_or_dealer = 1
		var give_cards_dealer = func (hand: Hand) -> void:
			var card = self.deck.draw()
			card._check_card()
			hand.push_card(card)
			player_card_drawn.emit( Suit.keys()[card.suit],Rank.keys()[card.rank],player_or_dealer)
		give_cards_dealer.call(dealer_hand)
		player_or_dealer = 0
		
		self.playing_hand = self.dealer_hand
	
	func eval_action() -> RoundOutcome:
		# natural blackjack check
		if turns == 0:
			var player_val = player_hand.value()
			var dealer_val = dealer_hand.value()
			
			if (player_val == 21 and dealer_val == 21):
				return RoundOutcome.Draw
			elif (player_val == 21):
				return RoundOutcome.PlayerWin
			elif (dealer_val == 21):
				return RoundOutcome.DealerWin
			else:
				return RoundOutcome.InProgress
		else:
			var peek = self.playing_hand.analyze()
			if (peek == HandStatus.Bust):
				if (self.is_player_turn):
					return RoundOutcome.DealerWin
				else:
					return RoundOutcome.PlayerWin
			elif (peek == HandStatus.Blackjack):
				if (self.is_player_turn):
					return RoundOutcome.PlayerWin
				else:
					return RoundOutcome.DealerWin
			else:
				return RoundOutcome.InProgress

	func stand():
		self.is_player_turn = not self.is_player_turn
		if (self.is_player_turn):
			print_debug("the player is now playing")
			self.playing_hand = self.player_hand
		else:
			print_debug("the dealer is now playing")
			self.playing_hand = self.dealer_hand
		turns = turns + 1
		
	func hit() -> RoundOutcome:
		var card = self.deck.draw()
		self.playing_hand.push_card(card)
		card._check_card()
		player_card_drawn.emit(Suit.keys()[card.suit],Rank.keys()[card.rank],player_or_dealer)
		return self.eval_action()
	
	# repeat until hit >=17
	func dealer_play() -> RoundOutcome:
		player_or_dealer = 1;
		var val = self.playing_hand.value()
		if (val < 17): # <= 17 depending on house rules
			var outcome = self.hit()
			print_debug("the dealer is hit for " + str(dealer_hand.value()))
			return outcome
		else:
			print_debug("the dealer is now standing at " + str(val))
			self.stand()
			var player_val = player_hand.value()
			if (val > player_val):
				return RoundOutcome.DealerWin
			elif (val < player_val):
				return RoundOutcome.PlayerWin
			else:
				return RoundOutcome.Draw

class Game extends RefCounted:
	var currentRound: Round
	
	signal send_data_to_main(suit: String, rank: String, player_or_dealer: int)

	func _init():
		currentRound = Round.new()
		currentRound.player_card_drawn.connect(_sending_to_main)
		print_debug("round is starting")
		
	func _sending_to_main(suit: String, rank: String, player_or_dealer: int):
		send_data_to_main.emit(suit,rank,player_or_dealer)
		
		
	func can_player_play():
		return currentRound.is_player_turn
	
	func start():
		print_debug("game started")
		self.currentRound.start()
		var game_status = self.currentRound.eval_action()
		self.currentRound.stand()
		return game_status
		
	func hit():
		print_debug("the player hit")
		return self.currentRound.hit()
		
	func stand():
		print_debug("the player stood")
		self.currentRound.stand()
		self.currentRound.dealer_play()
