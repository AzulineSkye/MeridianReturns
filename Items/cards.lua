local sprite_cards = Resources.sprite_load(NAMESPACE, "Cards", path.combine(PATH, "Sprites/Items/cards.png"), 1, 15, 15)

local cards = Item.new(NAMESPACE, "collectibleCards")
cards:set_sprite(sprite_cards)
cards:set_tier(Item.TIER.uncommon)
cards:set_loot_tags(Item.LOOT_TAG.category_utility)
cards:clear_callbacks()

Callback.add(Callback.TYPE.onSecond, "MNIncreaseCards", function(minute, second)
	if second % 5 ~= 0 then return end
	
	local players = Instance.find_all(gm.constants.oP)
	local stack = 0
	for _, player in ipairs(players) do
		if player:item_stack_count(cards) > 0 then
			stack = stack + 1 * player:item_stack_count(cards)
		end
	end
	
	if stack <= 0 then return end
	
	local enemies = Instance.find_all(gm.constants.pActor)
	for _, enemy in ipairs(enemies) do
		if enemy.team == 2 and enemy.exp_worth and enemy.exp_worth > 0 then
			enemy.exp_worth = enemy.exp_worth + stack * GM._mod_game_getDirector().stage_chest_cost_scale
			enemy.death_blast = true
			enemy.mn_card_coins = true -- not using get_data() because its bad and doesnt work sometimes for some reason
		end
	end
end)

Callback.add(Callback.TYPE.onDeath, "MNCardEffects", function(actor, bounds)
	if not actor.mn_card_coins then return end
	
	actor:sound_play(gm.constants.wCoins, 0.8, 0.8 + math.random() * 0.4)
end)