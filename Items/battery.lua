local sprite_battery		= Resources.sprite_load(NAMESPACE, "Battery", path.combine(PATH, "Sprites/Items/battery.png"), 1, 19, 20)
local sprite_effect			= Resources.sprite_load(NAMESPACE, "BatteryEffect", path.combine(PATH, "Sprites/Items/Effects/battery.png"))

local battery = Item.new(NAMESPACE, "portableBattery")
battery:set_sprite(sprite_battery)
battery:set_tier(Item.TIER.common)
battery:set_loot_tags(Item.LOOT_TAG.category_healing)
battery:clear_callbacks()

battery:onStatRecalc(function(actor, stack)
	if actor:item_stack_count(battery) > 0 and actor:alarm_get(0) == -1 and actor.inventory_equipment ~= nil then
		actor.hp_regen = actor.hp_regen + 0.03 * stack
	end
end)

battery:onPostStep(function(actor, stack)
	local data = actor:get_data()
	
	if actor:item_stack_count(battery) > 0 and actor:alarm_get(0) == -1 and actor.inventory_equipment ~= nil then
		if data.battery_timer == nil then
			data.battery_timer = 0
			GM.actor_queue_dirty(actor) 
		end
		
		if data.battery_timer < 80 then
			data.battery_timer = data.battery_timer + 1
		else
			data.battery_timer = 0
		end
		
		if data.battery_timer == 20 and gm.bool(actor.visible) then
			local outline = Object.find(NAMESPACE, "EfOutline"):create(actor.x, actor.y)
			outline.parent = actor
			outline.image_blend = Color.from_rgb(132, 215, 104)
			outline.pulse_alpha = 0
			outline.rate = 0.1
			outline.mode = 2
		end
	else
		data.battery_timer = nil
	end
end)

battery:onEquipmentUse(function(actor, stack)
	GM.actor_queue_dirty(actor) 
end)

Callback.add(Callback.TYPE.onPlayerHUDDraw, "MNBatteryHudEffect", function(actor, x, y)
	if actor:item_stack_count(battery) > 0 and actor:alarm_get(0) == -1 and actor.inventory_equipment ~= nil then
		gm.draw_sprite(sprite_effect, 0, x + 125, y - 18)
	end
end)
