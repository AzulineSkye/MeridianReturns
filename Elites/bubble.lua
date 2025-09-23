local sprite_icon = Resources.sprite_load(NAMESPACE, "EliteIconBubble", path.combine(PATH, "Sprites/Elites/Bubble/icon.png"), 1, 16, 8)
local sprite_palette = Resources.sprite_load(NAMESPACE, "ElitePaletteBubble", path.combine(PATH, "Sprites/Elites/Bubble/palette.png"))
local sprite_bubble = Resources.sprite_load(NAMESPACE, "EliteBubbleBubble", path.combine(PATH, "Sprites/Elites/Bubble/bubble.png"), 4, 14, 14)
local sprite_pop = Resources.sprite_load(NAMESPACE, "EliteBubbleBubblePop", path.combine(PATH, "Sprites/Elites/Bubble/bubble_pop.png"), 4, 34, 42)

local sound_spawn = gm.constants.wUse
local sound_pop = gm.constants.wJellyHit

local rippling = Elite.new(NAMESPACE, "rippling")
rippling.healthbar_icon = sprite_icon
rippling.palette = sprite_palette
rippling.blend_col = Color.from_rgb(77, 82, 184)
rippling:clear_callbacks()

GM.elite_generate_palettes()

local orb = Item.new(NAMESPACE, "ripplingOrb", true)
orb.is_hidden = true
orb:clear_callbacks()

local bubble = Object.new(NAMESPACE, "ripplingBubble")
bubble.obj_sprite = sprite_bubble
bubble:clear_callbacks()

orb:onPostStep(function(actor, stack)
	if actor:get_data().bubble_cooldown then
		if actor:get_data().bubble_cooldown > 0 then
			actor:get_data().bubble_cooldown = actor:get_data().bubble_cooldown - 1
		end
	else
		actor:get_data().bubble_cooldown = 0
	end
end)

orb:onDamagedProc(function(actor, attacker, stack, hit_info)
	if actor:get_data().bubble_cooldown > 0 then return end
	
	local amount = math.max(1, gm.round(math.random(1, 3) * (gm.sprite_get_height(actor.sprite_idle) / 16)))
	actor:get_data().bubble_cooldown = amount * 40
	actor:sound_play(sound_spawn, 1, 0.8 + math.random() * 0.4)
	for i = 1, math.min(20, amount) do
		local inst = bubble:create(actor.x, actor.y)
		inst.parent = actor
		inst.target_x = actor.x + math.random(-100, 100)
		inst.target_y = actor.y + math.random(-75, 75)
	end
end)

rippling:onApply(function(actor)
	actor:item_give(orb)
end)

bubble:onCreate(function(self)
	self.team = 2
	self.damage = 1
	self.target_x = self.x
	self.target_y = self.y
	self.parent = nil
	self.image_speed = 0.12 + (0.01 * math.random(-1, 1))
	self.life = 0
	self.life_max = math.random(180, 250)
end)

bubble:onStep(function(self)
	if Instance.exists(Instance.wrap(self.parent.value)) and self.life == 0 then
		self.team = self.parent.team
		self.damage = self.parent.damage * 0.6
	end
	
	self.life = self.life + 1
	
	local actor = self.parent
	local life = self.life
	local life_max = self.life_max
	
	if life >= life_max then
		if Instance.exists(Instance.wrap(actor.value)) then
			actor:fire_explosion_local(self.x, self.y, 65, 65, 0.6, sprite_pop)
		elseif gm._mod_net_isHost() then
			actor:fire_explosion_noparent(self.x, self.y, self.team, self.damage, false, nil, sprite_pop, 65 / 95, 65 / 20)
		end
		
		self:sound_play(sound_pop, 1, 0.8 + math.random() * 0.4)
		self:destroy()
	elseif life == gm.round(life_max * 0.9) or life == gm.round(life_max * 0.8) then
		local flash = Object.find("ror-EfFlash"):create(self.x, self.y)
		flash.parent = self
		flash.rate = 0.1
	end
	
	if not (gm.round(math.abs(self.x - self.target_x)) == 0 and gm.round(math.abs(self.y - self.target_y)) == 0) then
		self.x = approach(self.x, self.target_x, math.abs(gm.round((self.x - self.target_x) * 0.1)))
		self.y = approach(self.y, self.target_y, math.abs(gm.round((self.y - self.target_y) * 0.1)))
	end
end)

local all_monster_cards = Monster_Card.find_all()
for i, card in ipairs(all_monster_cards) do
	local elite_list = List.wrap(card.elite_list)
	if not elite_list:contains(rippling) then
		elite_list:add(rippling)
	end
end

