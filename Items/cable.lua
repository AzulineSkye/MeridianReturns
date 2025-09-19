local sprite_cable = Resources.sprite_load(NAMESPACE, "Cable", path.combine(PATH, "Sprites/Items/cable.png"), 1, 12, 12)

local cable = Item.new(NAMESPACE, "jumpstartCable")
cable:set_sprite(sprite_cable)
cable:set_tier(Item.TIER.uncommon)
cable:set_loot_tags(Item.LOOT_TAG.category_utility)
cable:clear_callbacks()

local function cable_set_drone_cost_zero()
	local drones = Instance.find_all(gm.constants.pInteractableDrone)
	for _, drone in ipairs(drones) do
		drone:get_data().cable_cost = drone.cost
		drone.cost = 0
	end
end

local function cable_restore_drone_cost()
	local drones = Instance.find_all(gm.constants.pInteractableDrone)
	for _, drone in ipairs(drones) do
		if drone:get_data().cable_cost then
			drone.cost = drone:get_data().cable_cost
		end
	end
end

cable:onAcquire(function(actor, stack)
	local director = GM._mod_game_getDirector()
	director.cable_drones = director.cable_drones + 1
	
	if director.cable_drones > 0 then
		cable_set_drone_cost_zero()
	end
end)

cable:onRemove(function(actor, stack)
	local director = GM._mod_game_getDirector()
	director.cable_drones = director.cable_drones - 1
	
	if director.cable_drones <= 0 then
		cable_restore_drone_cost()
	end
end)

Callback.add(Callback.TYPE.onStageStart, "MNRefreshCable", function()
	local director = GM._mod_game_getDirector()
	director.cable_drones = 0
	
	local players = Instance.find_all(gm.constants.oP)
	for _, player in ipairs(players) do
		if player:item_stack_count(cable) > 0 then
			director.cable_drones = director.cable_drones + 1 * player:item_stack_count(cable)
		end
	end
	
	if director.cable_drones > 0 then
		cable_set_drone_cost_zero()
	end
end)

Callback.add(Callback.TYPE.onInteractableActivate, "MNActivateCable", function(inst, actor)
	local drones = Instance.find_all(gm.constants.pInteractableDrone)
	for _, drone in ipairs(drones) do
		if inst.value == drone.value then
			local director = GM._mod_game_getDirector()
			
			if director.cable_drones > 0 then
				director.cable_drones = director.cable_drones - 1
				Particle.find("ror-Spark"):create(inst.x, inst.y, 20, Particle.SYSTEM.above)
				inst:sound_play(gm.constants.wBubbleShield, 2, 0.8 + math.random() * 0.2)
			end
			
			if director.cable_drones <= 0 then
				cable_restore_drone_cost()
			end
			
			break
		end
	end
end)