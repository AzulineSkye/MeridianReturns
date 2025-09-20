local sprite_mask		= Resources.sprite_load(NAMESPACE, "basaltCrabMask",		path.combine(PATH, "Sprites/Enemies/BasaltCrab/mask.png"), 1, 48, 25)
local sprite_palette	= Resources.sprite_load(NAMESPACE, "basaltCrabPalette",		path.combine(PATH, "Sprites/Enemies/BasaltCrab/palette.png"))
local sprite_portrait	= Resources.sprite_load(NAMESPACE, "basaltCrabPortrait",	path.combine(PATH, "Sprites/Enemies/BasaltCrab/portrait.png"))
local sprite_spawn		= Resources.sprite_load(NAMESPACE, "basaltCrabSpawn",		path.combine(PATH, "Sprites/Enemies/BasaltCrab/spawn.png"), 6, 48, 25)
local sprite_idle		= Resources.sprite_load(NAMESPACE, "basaltCrabIdle",		path.combine(PATH, "Sprites/Enemies/BasaltCrab/idle.png"), 1, 48, 25)
local sprite_walk		= Resources.sprite_load(NAMESPACE, "basaltCrabWalk",		path.combine(PATH, "Sprites/Enemies/BasaltCrab/walk.png"), 4, 48, 25)
local sprite_death		= Resources.sprite_load(NAMESPACE, "basaltCrabDeath",		path.combine(PATH, "Sprites/Enemies/BasaltCrab/death.png"), 13, 86, 61)
local sprite_shoot1		= Resources.sprite_load(NAMESPACE, "basaltCrabShoot1",		path.combine(PATH, "Sprites/Enemies/BasaltCrab/shoot1.png"), 9, 70, 25)
local sprite_shoot2		= Resources.sprite_load(NAMESPACE, "basaltCrabShoot2",		path.combine(PATH, "Sprites/Enemies/BasaltCrab/shoot2.png"), 18, 48, 25)

gm.elite_generate_palettes(sprite_palette)

local mlog = Monster_Log.new(NAMESPACE, "basaltCrab")
mlog.sprite_id = sprite_walk
mlog.portrait_id = sprite_portrait
mlog.sprite_offset_x = 44
mlog.sprite_offset_y = 28
mlog.stat_hp = 400
mlog.stat_damage = 16
mlog.stat_speed = 1.6

local crab = Object.new(NAMESPACE, "basaltCrab", Object.PARENT.enemyClassic)
crab.obj_sprite = sprite_idle
crab.obj_depth = 11

local slam = Skill.new(NAMESPACE, "basaltCrabZ")
slam.cooldown = 1 * 60
slam.is_primary = true
slam.does_change_activity_state = true

local stateSlam = State.new(NAMESPACE, "basaltCrabPrimary")

local laser = Skill.new(NAMESPACE, "basaltCrabX")
laser.cooldown = 8 * 60
laser.does_change_activity_state = true

laser:clear_callbacks()
local stateLaser = State.new(NAMESPACE, "basaltCrabSecondary")
laser:onActivate(function(actor)
	actor:enter_state(stateLaser)
end)
stateLaser:clear_callbacks()

local eyes = {
	maineye = {x = 4, y = 15},
	eye1 = {x = -24, y = 17},
	eye2 = {x = 24, y = 19},
	eye3 = {x = 4, y = -7}
}

crab:clear_callbacks()
crab:onCreate(function(actor)
	actor.sprite_palette = sprite_palette
	actor.sprite_spawn = sprite_spawn
	actor.sprite_idle = sprite_idle
	actor.sprite_walk = sprite_walk
	actor.sprite_jump = sprite_idle
	actor.sprite_jump_peak = sprite_idle
	actor.sprite_fall = sprite_idle
	actor.sprite_death = sprite_death

	actor.can_jump = false

	actor.mask_index = sprite_mask

	actor.sound_spawn = gm.constants.wCrabSpawn
	actor.sound_hit = gm.constants.wGolemHit
	actor.sound_death = gm.constants.wGolemDeath

	actor:enemy_stats_init(40, 400, 400, 30) -- damage, hp, knockback cap, experience amount
	actor.pHmax_base = 1.6 -- speed, default speed is 2.4

	actor.z_range = 60
	actor.y_range = 100
	actor.x_range = 600
	actor:get_data().is_targeting = false
	actor:get_data().shoot_anim = 0
	
	actor.monster_log_drop_id = mlog.value
	
	actor:set_default_skill(Skill.SLOT.primary, slam)
	actor:set_default_skill(Skill.SLOT.secondary, laser)

	actor:init_actor_late()
end)

crab:onStep(function(actor)
	if actor:get_data().shoot_anim > 0 then
		actor:get_data().shoot_anim = actor:get_data().shoot_anim - 1
	end
end)

crab:onDraw(function(actor)
	if not (actor:get_data().is_targeting or actor:get_data().shoot_anim > 0) then return end
	local data = actor.actor_state_current_data_table
	
	gm.draw_set_colour(Color.RED)
	if actor:get_data().shoot_anim > 0 then
		gm.draw_set_alpha(actor:get_data().shoot_anim / 8)
	else
		gm.draw_set_alpha(0.3 * (data.loop + 1))
	end
	
	for _, eye in pairs(eyes) do
		local xend = gm.lengthdir_x(600, data.target_angle)
		local yend = gm.lengthdir_y(600, data.target_angle)
		actor:collision_line_advanced(actor.x + eye.x * actor.image_xscale, actor.y + eye.y, actor.x + eye.x * actor.image_xscale + xend, actor.y + eye.y + yend, gm.constants.pBlock, true, true)
		local xx = gm.variable_global_get("collision_x")
		local yy = gm.variable_global_get("collision_y")
		if actor:get_data().shoot_anim > 0 then
			gm.draw_line_width(actor.x + eye.x * actor.image_xscale, actor.y + eye.y, xx, yy, actor:get_data().shoot_anim * 2)
			gm.draw_circle(xx, yy, actor:get_data().shoot_anim, false)
		else
			gm.draw_line_width(actor.x + eye.x * actor.image_xscale, actor.y + eye.y, xx, yy, (data.loop + 1) * 2)
			gm.draw_circle(xx, yy, data.loop, false)
		end
	end
	
	gm.draw_set_colour(Color.WHITE)
	gm.draw_set_alpha(1)
end)

slam:clear_callbacks()
slam:onActivate(function(actor)
	actor:enter_state(stateSlam)
end)

stateSlam:clear_callbacks()
stateSlam:onEnter(function(actor, data)
	actor.image_index = 0
	data.fired = 0
end)

stateSlam:onStep(function(actor, data)
	actor:skill_util_fix_hspeed()
	actor:actor_animation_set(sprite_shoot1, 0.2)
	
	if data.fired == 0 and actor.image_index >= 4 then
		data.fired = 1
		actor:fire_explosion_local(actor.x + 12 * actor.image_xscale, actor.y + 35, 75, 75, 1, nil, sBite7)
		actor:sound_play(gm.constants.wGolemAttack1, 1.25, 0.6 + math.random() * 0.2)
		actor:screen_shake(4)
	end
	
	actor:skill_util_exit_state_on_anim_end()
end)

laser:clear_callbacks()
laser:onActivate(function(actor)
	actor:enter_state(stateLaser)
end)

stateLaser:clear_callbacks()
stateLaser:onEnter(function(actor, data)
	actor.image_index = 0
	data.fired = 0
	data.loop = 0
	data.target_angle = 0
	data.is_targeting = false
end)

stateLaser:onStep(function(actor, data)
	actor:skill_util_fix_hspeed()
	actor:actor_animation_set(sprite_shoot2, 0.2)
	
	local target = nil
	if actor.target and Instance.exists(actor.target) then
		if actor.target.parent and Instance.exists(actor.target.parent) then
			target = actor.target.parent
		end
	end
	
	if data.fired == 0 then
		data.fired = 1
		data.target_angle = gm.point_direction(actor.x + eyes.maineye.x * actor.image_xscale, actor.y + eyes.maineye.y, target.x, target.y)
	end
	
	if actor.image_index >= 12 and data.loop == 0 then 
		data.loop = 1 
		actor.image_index = 6
	end
	
	if actor.image_index >= 6 and actor.image_index <= 13 then 
		if target and Instance.exists(target) then
			actor:get_data().is_targeting = true
			data.target_angle = (data.target_angle - angle_dif(data.target_angle, gm.point_direction(actor.x + eyes.maineye.x * actor.image_xscale, actor.y + eyes.maineye.y, target.x, target.y)) * (0.015 * (data.loop + 1)) + 360) % 360
		else
			actor:get_data().is_targeting = false
		end
	end
	
	if actor.image_index >= 13 and data.fired == 1 then
		data.fired = 2
		actor:sound_play(gm.constants.wHANDShoot1_2, 1, 1.6 + math.random() * 0.4)
		actor:screen_shake(6)
		
		if gm._mod_net_isHost() then
			for _, eye in pairs(eyes) do
				actor:fire_bullet(actor.x + eye.x * actor.image_xscale, actor.y + eye.y, 600, data.target_angle, 0.5, nil, gm.constants.sSparks10r, basalt_crab_tracer)
			end
		end
		
		actor:get_data().is_targeting = false
		actor:get_data().shoot_anim = 12
	end
	
	actor:skill_util_exit_state_on_anim_end()
end)

stateLaser:onExit(function(actor, data)
	actor:get_data().is_targeting = false
end)

local mcard = Monster_Card.new(NAMESPACE, "basaltCrab")
mcard.object_id = crab.value
mcard.spawn_cost = 160
mcard.spawn_type = Monster_Card.SPAWN_TYPE.classic
mcard.can_be_blighted = false

local stages = {
	"ror-magmaBarracks",
}

local postLoopStages = {
	"ror-driedLake",
	"ror-sunkenTombs",
	"ssr-whistlingBasin"
}

for _, s in ipairs(stages) do
	local stage = Stage.find(s)
	if stage then
		stage:add_monster(mcard)
	end
end

for _, s in ipairs(postLoopStages) do
	local stage = Stage.find(s)
	if stage then
		stage:add_monster_loop(mcard)
	end
end