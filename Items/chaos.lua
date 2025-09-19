local sprite_chaos = Resources.sprite_load(NAMESPACE, "Chaos", path.combine(PATH, "Sprites/Items/chaos.png"), 1, 15, 15)
local sprite_effect = Resources.sprite_load(NAMESPACE, "ChaosEffect", path.combine(PATH, "Sprites/Items/Effects/chaos.png"), 1, 4, 21)

local chaos = Item.new(NAMESPACE, "chaosDrive")
chaos:set_sprite(sprite_chaos)
chaos:set_tier(Item.TIER.common)
chaos:set_loot_tags(Item.LOOT_TAG.category_healing)
chaos:clear_callbacks()

chaos:onAcquire(function(actor, stack)
	if not actor:get_data().chaos_sound_played then
		actor:get_data().chaos_sound_played = 0
	end
	if not actor:get_data().chaos_using_skills then
		actor:get_data().chaos_using_skills = 0
	end
	if not actor:get_data().chaos_count then
		actor:get_data().chaos_count = 0
	end
	if not actor:get_data().charging then
		actor:get_data().charging = 1
	end
end)

chaos:onRemove(function(actor, stack)
	if stack <= 1 then
		actor:get_data().chaos_sound_played = nil
		actor:get_data().chaos_using_skills = nil
		actor:get_data().chaos_count = nil
		actor:get_data().charging = nil
	end
end)

chaos:onPrimaryUse(function(actor, stack, active_skill)
	actor:get_data().chaos_using_skills = 30
end)
chaos:onSecondaryUse(function(actor, stack, active_skill)
	actor:get_data().chaos_using_skills = 30
end)
chaos:onUtilityUse(function(actor, stack, active_skill)
	actor:get_data().chaos_using_skills = 30
end)
chaos:onSpecialUse(function(actor, stack, active_skill)
	actor:get_data().chaos_using_skills = 30
end)

chaos:onPostStep(function(actor, stack)
	local chaos_count_max = ((45 + 15 * stack) / 400) / (((45 + 15 * stack) / 400) + 0.85) * 400
	
	actor:get_data().chaos_using_skills = math.max(0, actor:get_data().chaos_using_skills - 1)
	
	if actor.hp <= actor.maxhp * 0.25 and actor:get_data().chaos_count > 0 and actor:get_data().charging == 1 then
		actor:get_data().charging = 0
	elseif actor.hp > actor.maxhp * 0.25 and actor:get_data().chaos_count <= 0 and actor:get_data().charging == 0 then 
		actor:get_data().charging = 1
		actor:get_data().chaos_sound_played = 0
	end
	
	if actor:get_data().charging == 1 then
		if actor:get_data().chaos_using_skills > 0 then
			actor:get_data().chaos_count = math.min(chaos_count_max, actor:get_data().chaos_count + 1 / 12)
		end
	elseif actor:get_data().charging == 0 then
		if actor:get_data().chaos_count > 0 then
			actor:set_barrier(math.min(actor.maxbarrier, actor.barrier + (actor.barrier / actor.maxbarrier * 0.3) + (actor.maxbarrier / 400)))
			actor:get_data().chaos_count = math.max(0, actor:get_data().chaos_count - 1)
		end
	end
	
	if actor:get_data().chaos_sound_played == 0 and actor:get_data().chaos_count == chaos_count_max then
		actor:get_data().chaos_sound_played = 1
		actor:sound_play(gm.constants.wMedallion, 1.5, 0.8 + math.random() * 0.2)
	end
end)

chaos:onPostDraw(function(actor, stack)
	local chaos_count_max = ((45 + 15 * stack) / 400) / (((45 + 15 * stack) / 400) + 0.85) * 400
	
	if actor:get_data().chaos_count == chaos_count_max then
		gm.draw_set_colour(Color.from_hsv(0, 85, 92))
		gm.draw_set_alpha(math.sin(Global._current_frame / 20))
		gm.draw_rectangle(actor.x - 31, actor.y - 39, actor.x - 25, actor.y - 2, false)
		gm.draw_rectangle(actor.x - 32, actor.y - 42, actor.x - 24, actor.y - 39, false)
		gm.draw_rectangle(actor.x - 32, actor.y - 3, actor.x - 24, actor.y, false)
		gm.draw_set_alpha(1)
	else
		gm.draw_set_colour(Color.from_hsv(24, 100, 100))
	end
	gm.draw_sprite(sprite_effect, 0, actor.x - 27, actor.y - 20)
	gm.draw_rectangle(actor.x - 29, actor.y - 2 - 37 * (actor:get_data().chaos_count / chaos_count_max), actor.x - 27, actor.y - 2, false)
	gm.draw_set_colour(Color.WHITE)
end)