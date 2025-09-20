local sprite_berries = Resources.sprite_load(NAMESPACE, "Berries", path.combine(PATH, "Sprites/Items/berries.png"), 1, 15, 15)
local sprite_effect	= Resources.sprite_load(NAMESPACE, "BerriesEffect", path.combine(PATH, "Sprites/Items/Effects/berries.png"), 3, 10, 10)
local sprite_bush = Resources.sprite_load(NAMESPACE, "BerriesBush", path.combine(PATH, "Sprites/Items/Effects/bush.png"), 8, 34, 18)
local sprite_bush_dead = Resources.sprite_load(NAMESPACE, "BerriesBushDead", path.combine(PATH, "Sprites/Items/Effects/dead_bush.png"), 5, 34, 18)

local berries = Item.new(NAMESPACE, "foragedSpoils")
berries:set_sprite(sprite_berries)
berries:set_tier(Item.TIER.uncommon)
berries:set_loot_tags(Item.LOOT_TAG.category_utility)
berries:clear_callbacks()

local berrySplash = Particle.new(NAMESPACE, "bushDebris")
berrySplash:set_sprite(sprite_effect, false, false, true)
berrySplash:set_alpha3(1, 1, 0)
berrySplash:set_scale(1, 1)
berrySplash:set_size(1.1, 0.9, -0.015, 0.01)
berrySplash:set_orientation(0, 360, 1, 0, true)
berrySplash:set_speed(1.6, 3, -0.002, 0)
berrySplash:set_direction(45, 135, 0, 0)
berrySplash:set_gravity(0.1, 270)
berrySplash:set_life(180, 300)

local rewards = {
	-- format is {boss object index, boss item index, boss item type}
	-- boss item type 1 = passive item, 2 = equipment
	
	-- VANILLA --
	{"ror-GolemG", "ror-colossalKnurl", 1},
	{"ror-JellyG", "ror-nematocystNozzle", 2},
	{"ror-Worm", "ror-burningWitness", 1},
	{"ror-WispB", "ror-legendarySpark", 1},
	{"ror-ImpG", "ror-impOverlordsTentacle", 1},
	{"ror-ImpGS", "ror-impOverlordsTentacle", 1},
	{"ror-Ifrit", "ror-ifritsHorn", 1},
	{"ror-Turtle", "ror-scorchingShellPiece", 1},
	{"ror-LizardGS", "ror-minersPickaxe", 1}
}

local bush = Object.new(NAMESPACE, "berriesBush", Object.PARENT.interactable)
bush.obj_sprite = sprite_bush
bush.obj_depth = 12
bush:clear_callbacks()

bush:onCreate(function(self)
	self:move_contact_solid(270, -1)
	self:sound_play(gm.constants.wBrambleShoot2, 2, 0.8 + math.random() * 0.2)
	
	for i = 1, 5 do
		berrySplash:create(self.x + math.random(-16, 16), self.y + math.random(-16, 16), 2, Particle.SYSTEM.above)
	end
	
	self.reward = nil
	self.image_speed = 0.3
end)

bush:onStep(function(self)
	if self.active == 1 then
		if Artifact.find("ror-command").active then
			Item.spawn_crate(self.x, self.y, Item.TIER.boss)
		else
			if self.reward then
				if self.reward_type == 1 then
					Item.find(self.reward):create(self.x, self.y)
				elseif self.reward_type == 2 then
					Equipment.find(self.reward):create(self.x, self.y)
				end
			else
				Item.get_random(Item.TIER.boss):create(self.x, self.y)
			end
		end
		
		for i = 1, 10 do
			berrySplash:create(self.x + math.random(-16, 16), self.y + math.random(-16, 16), 2, Particle.SYSTEM.above)
		end
		
		self:sound_play(gm.constants.wBrambleShoot2, 2, 0.8 + math.random() * 0.2)
		self.sprite_index = sprite_bush_dead
		self.image_speed = 0.3
		self.image_index = 0
		self.active = 2
	end
end)

Callback.add(Callback.TYPE.onDeath, "MNBerriesSummonBush", function(actor, bounds)
	local players = Instance.find_all(gm.constants.oP)
	local chance = 0
	
	for _, player in ipairs(players) do
		if player:item_stack_count(berries) > 0 then
			chance = chance + 0.025 + 0.025 * player:item_stack_count(berries)
		end
	end
	
	if chance == 0 then return end
	
	for _, reward in ipairs(rewards) do	
		if Object.wrap(actor.object_index).value == Object.find(reward[1]).value then
			if Helper.chance(chance) then
				local inst = bush:create(actor.x, actor.bbox_bottom - 32)
				inst.reward = reward[2]
				inst.reward_type = reward[3]
			end
			break
		end
	end
end)