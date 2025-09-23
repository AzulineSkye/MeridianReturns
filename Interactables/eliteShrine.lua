local sprite_shrine = Resources.sprite_load(NAMESPACE, "ShrineElite", path.combine(PATH, "Sprites/Interactables/EliteShrine/shrine.png"), 7, 24, 106)
local sprite_uncharged = Resources.sprite_load(NAMESPACE, "ShrineEliteUncharged", path.combine(PATH, "Sprites/Interactables/EliteShrine/shrine_uncharged.png"), 1, 24, 106)
local sprite_effect	= Resources.sprite_load(NAMESPACE, "ShrineEliteEffect", path.combine(PATH, "Sprites/Interactables/EliteShrine/effect.png"), 6, 52, 112)
local sprite_arrow = Resources.sprite_load(NAMESPACE, "ShrineEliteArrow", path.combine(PATH, "Sprites/Interactables/EliteShrine/arrow.png"), 1, 16, 14)

local blacklist = {
	[gm.constants.oLizardF] = true,
	[gm.constants.oLizardFG] = true,
	[gm.constants.oLizardRL] = true,
}

local shrine = Object.new(NAMESPACE, "shrineBestowal", Object.PARENT.interactable)
shrine.obj_sprite = sprite_uncharged
shrine.obj_depth = 90
shrine:clear_callbacks()

shrine:onCreate(function(self)
	self:interactable_init()
	self.sprite_ping = sprite_shrine
	self.bestowal_targets = Array.new()
	self.bestowal_x = self.y
	self.bestowal_y = self.x
	self.bestowal_activated_fr = false
	self.bestowal_can_activate = false
	self.bestowal_anim_state = false
	self.active = 0
	self:interactable_init_name()
end)

shrine:onStep(function(self)
	local enemy_count = 0
	local enemy_count_max = 3 + gm.round(GM._mod_game_getDirector().stages_passed * 0.4)
	
	local list = List.new()
	
	if self.bestowal_activated_fr == false then
		for _, enemy in ipairs(Instance.find_all(Object.wrap(gm.constants.pActor))) do
			if enemy_count < enemy_count_max then
				if not (GM.actor_is_elite(enemy) or GM.actor_is_boss(enemy) or enemy.ghost == 1 or enemy.team ~= 2 or blacklist[enemy.object_index]) then
					list:add(enemy)
					enemy_count = enemy_count + 1
				end
			else
				break
			end
		end
	end
	
	if self.active == 0 and self.bestowal_activated_fr == false then
		-- check if the shrine can be activated or not
		if enemy_count >= enemy_count_max then
			self.bestowal_can_activate = true
			self.cost = 0
			self.cost_type = 0
		else
			self.bestowal_can_activate = false
			self.cost = math.huge
			self.cost_type = 6
		end
		
		-- activation/deactivation
		if self.bestowal_can_activate == true and self.bestowal_anim_state == false then
			self.sprite_index = sprite_shrine
			self.bestowal_anim_state = true
			self:sound_play(gm.constants.wUI_Trials_Success_WindowPopup, 1, 0.8 + math.random() * 0.2)
			
			local flash = Object.find("ror-EfFlash"):create(self.x, self.y)
			flash.parent = self
			flash.image_blend = Color.WHITE
			flash.rate = 0.1
		elseif self.bestowal_can_activate == false and self.bestowal_anim_state == true then
			self.sprite_index = sprite_uncharged
			self.bestowal_anim_state = false
			self:sound_play(gm.constants.wUI_Trials_Fail_WindowPopup, 1, 0.8 + math.random() * 0.2)
			
			local sparks = gm.instance_create(self.x, self.y, gm.constants.oEfTrail)
			sparks.depth = 89
			sparks.sprite_index = sprite_shrine
			sparks.image_speed = 0
			sparks.image_xscale = self.image_xscale
			sparks.image_yscale = self.image_yscale
		end
	elseif self.active == 2 then
		if not Instance.exists(self.activator) then
			self.active = 3
			return
		end
		
		-- shrine use
		self.image_speed = 0.35
		
		if self.image_index >= 2 and self.bestowal_activated_fr == false then
			
			self:sound_play(gm.constants.wShrine1, 1, 0.8 + math.random() * 0.2)
			
			for _, enemy in ipairs(list) do
				self.bestowal_targets:push(enemy)
				
				if not self.activator:get_data().bestowal_targets then
					self.activator:get_data().bestowal_targets = Array.new()
				end
				
				self.activator:get_data().bestowal_targets:push(enemy)
				
				local elite_type = nil
				
				for _, card in ipairs(Monster_Card.find_all()) do
					if card.object_id == enemy.object_index then
						local elite_list = List.wrap(card.elite_list)
						elite_type = elite_list:get(gm.round(math.random(1, #elite_list)))
					end
				end
				
				-- used as backup if the enemy doesnt have a monster card
				if elite_type == nil then
					local elite_list = List.wrap(Monster_Card.find("ror-lemurian").elite_list)
					elite_type = elite_list:get(gm.round(math.random(1, #elite_list)))
				end

				GM.elite_set(enemy, elite_type)
			end
			
			self.bestowal_activated_fr = true
		end
		
		local targets_remaining = 0
		for _, enemy in ipairs(self.bestowal_targets) do
			if Instance.exists(enemy) then
				self.bestowal_x = enemy.x
				self.bestowal_y = enemy.y
				targets_remaining = targets_remaining + 1
			end
		end
		
		if targets_remaining == 0 and self.bestowal_activated_fr == true then
			self.active = 3
			
			if self.activator:get_data().bestowal_targets then
				if self.activator:get_data().bestowal_targets:size() <= 0 then
					self.activator:get_data().bestowal_targets = nil
				end
			end
			
			local tier_chance = math.random()
			local tier = Item.TIER.common
			if tier_chance <= 0.01 then
				tier = Item.TIER.rare
			elseif tier_chance <= 0.3 then
				tier = Item.TIER.uncommon
			end
			
			if Artifact.find("ror-command").active then
				Item.spawn_crate(self.activator.x, self.activator.y, tier)
			else
				Item.get_random(tier):create(self.bestowal_x, self.bestowal_y, self.activator)
			end
		end
	end
	
	list:destroy()
end)

Callback.add(Callback.TYPE.onDraw, "MNDrawBestowalArrow", function()
	for _, actor in ipairs(Instance.find_all(Object.wrap(gm.constants.oP))) do
		local target = nil
		
		if actor:get_data().bestowal_targets then
			for _, enemy in ipairs(actor:get_data().bestowal_targets) do
				if Instance.exists(enemy) then
					target = enemy
				end
			end
		end
		
		if target then
			local angle = gm.point_direction(actor.x, actor.y, target.x, target.y)
			local xx = math.cos(math.rad(angle)) * 40
			local yy = math.sin(math.rad(angle)) * 40
			
			gm.draw_sprite_ext(sprite_arrow, 0, actor.x + xx, actor.y - yy, 1, 1, angle, Color.WHITE, 1)
		end
	end
end)

local card = Interactable_Card.new(NAMESPACE, "shrineBestowal")
card.object_id = shrine
card.spawn_with_sacrifice = true
card.spawn_cost = 25
card.spawn_weight = 8

Callback.add(Callback.TYPE.onGameStart, "MNAddBestowalShrineAdd", function()
	if Artifact.find("ror-honor").active then return end
	
	local stages = List.new()
	for i = 1, 5 do
		local tier = List.wrap(gm._mod_stage_get_pool_list(i))
		for _, stage in ipairs(tier) do
			stages:add(stage)
		end
	end
	
	for _, stage in ipairs(stages) do
		Stage.wrap(stage):add_interactable(card)
	end
	
	stages:destroy()
end)

Callback.add(Callback.TYPE.onGameEnd, "MNAddBestowalShrineRemove", function()
	local stages = List.new()
	for i = 1, 5 do
		local tier = List.wrap(gm._mod_stage_get_pool_list(i))
		for _, stage in ipairs(tier) do
			stages:add(stage)
		end
	end
	
	for _, stage in ipairs(stages) do
		local list = List.wrap(Stage.wrap(stage).spawn_interactables)
		for i, interactable in ipairs(List.wrap(Stage.wrap(stage).spawn_interactables)) do
			if interactable == card.value then
				list:delete(i - 1)
			end
		end
	end
	
	stages:destroy()
end)