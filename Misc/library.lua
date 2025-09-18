-- outline object
local outline = Object.new(NAMESPACE, "EfOutline")
outline:set_sprite(gm.constants.sLoaderExplode)
outline:set_depth(90)
outline:clear_callbacks()

outline:onCreate(function(self)
	self.parent = -4
	self.image_alpha = 0
	self.pulse_alpha = 1
	self.rate = 0.2
	self.mode = 1 -- 1 is decreasing, 2 is a pulse
	self.pulsed = false
	self.done = false
end)

outline:onStep(function(self)
	if not Instance.exists(self.parent) then self:destroy() end
	if self.done == true then self:destroy() end
	
	self.depth = self.parent.depth + 1
	
	if self.mode == 1 then
		self.pulse_alpha = self.pulse_alpha - self.rate
		if self.pulse_alpha <= 0 then
			self.done = true
		end
	elseif self.mode == 2 then
		if self.pulse_alpha < 1 and self.pulsed == false then
			self.pulse_alpha = math.min(1, self.pulse_alpha + self.rate)
			if self.pulse_alpha >= 1 then
				self.pulsed = true
			end
		else
			self.pulse_alpha = math.max(0, self.pulse_alpha - self.rate)
			if self.pulse_alpha <= 0 then
				self.done = true
			end
		end
	end
end)

outline:onDraw(function(self)
	local actor = self.parent
	
	if actor.visible then
		gm.gpu_set_fog(true, self.image_blend, 0, 0)
		
		gm.draw_sprite_ext(actor.sprite_index, actor.image_index, actor.ghost_x + 2, actor.ghost_y + 2, actor.image_xscale, actor.image_yscale, actor.image_angle, self.image_blend, self.pulse_alpha / 2)
		gm.draw_sprite_ext(actor.sprite_index, actor.image_index, actor.ghost_x + 2, actor.ghost_y, actor.image_xscale, actor.image_yscale, actor.image_angle, self.image_blend, self.pulse_alpha / 2)
		gm.draw_sprite_ext(actor.sprite_index, actor.image_index, actor.ghost_x + 2, actor.ghost_y - 2, actor.image_xscale, actor.image_yscale, actor.image_angle, self.image_blend, self.pulse_alpha / 2)
		gm.draw_sprite_ext(actor.sprite_index, actor.image_index, actor.ghost_x, actor.ghost_y - 2, actor.image_xscale, actor.image_yscale, actor.image_angle, self.image_blend, self.pulse_alpha / 2)
		gm.draw_sprite_ext(actor.sprite_index, actor.image_index, actor.ghost_x - 2, actor.ghost_y - 2, actor.image_xscale, actor.image_yscale, actor.image_angle, self.image_blend, self.pulse_alpha / 2)
		gm.draw_sprite_ext(actor.sprite_index, actor.image_index, actor.ghost_x - 2, actor.ghost_y, actor.image_xscale, actor.image_yscale, actor.image_angle, self.image_blend, self.pulse_alpha / 2)
	
		if actor.state_strafe_half then
			if gm.bool(actor.state_strafe_half) then
				gm.draw_sprite_ext(actor.sprite_index2, actor.image_index2, actor.ghost_x + 2, actor.ghost_y + 2 + actor.ydisp, actor.image_xscale, actor.image_yscale, actor.image_angle, self.image_blend, self.pulse_alpha / 2)
				gm.draw_sprite_ext(actor.sprite_index2, actor.image_index2, actor.ghost_x + 2, actor.ghost_y + actor.ydisp, actor.image_xscale, actor.image_yscale, actor.image_angle, self.image_blend, self.pulse_alpha / 2)
				gm.draw_sprite_ext(actor.sprite_index2, actor.image_index2, actor.ghost_x + 2, actor.ghost_y - 2 + actor.ydisp, actor.image_xscale, actor.image_yscale, actor.image_angle, self.image_blend, self.pulse_alpha / 2)
				gm.draw_sprite_ext(actor.sprite_index2, actor.image_index2, actor.ghost_x, actor.ghost_y - 2 + actor.ydisp, actor.image_xscale, actor.image_yscale, actor.image_angle, self.image_blend, self.pulse_alpha / 2)
				gm.draw_sprite_ext(actor.sprite_index2, actor.image_index2, actor.ghost_x - 2, actor.ghost_y - 2 + actor.ydisp, actor.image_xscale, actor.image_yscale, actor.image_angle, self.image_blend, self.pulse_alpha / 2)
				gm.draw_sprite_ext(actor.sprite_index2, actor.image_index2, actor.ghost_x - 2, actor.ghost_y + actor.ydisp, actor.image_xscale, actor.image_yscale, actor.image_angle, self.image_blend, self.pulse_alpha / 2)
			end
		end
		
		gm.gpu_set_fog(false, self.image_blend, 0, 0)
	end
end)