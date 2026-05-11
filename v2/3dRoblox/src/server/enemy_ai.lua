-- Enemy AI - Handles enemy behavior and pathfinding
local EnemyAI = {}
EnemyAI.__index = EnemyAI

local STATES = {
	IDLE = 1,
	PATROL = 2,
	CHASE = 3,
	ATTACK = 4,
	DEAD = 5,
}

function EnemyAI.new(enemy_model, enemy_stats, dungeon_data)
	local self = setmetatable({}, EnemyAI)
	
	self.model = enemy_model
	self.humanoid = enemy_model:FindFirstChild("Humanoid")
	self.root_part = enemy_model:FindFirstChild("HumanoidRootPart")
	self.stats = enemy_stats
	self.dungeon_data = dungeon_data
	
	self.state = STATES.IDLE
	self.target = nil
	self.detection_range = 50
	self.attack_range = enemy_stats.attack_range
	self.move_speed = enemy_stats.speed
	
	self.state_timer = 0
	self.attack_cooldown = 0
	self.patrol_timer = 0
	self.patrol_point = nil
	
	self.hp = enemy_stats.max_hp
	self.is_alive = true
	
	return self
end

function EnemyAI:update(delta_time, players)
	if not self.is_alive then return end
	
	self.state_timer = self.state_timer + delta_time
	self.attack_cooldown = math.max(0, self.attack_cooldown - delta_time)
	
	-- Find nearest player
	self.target = self:_find_nearest_player(players)
	
	-- Update state
	if self.state == STATES.IDLE then
		self:_update_idle(delta_time)
	elseif self.state == STATES.PATROL then
		self:_update_patrol(delta_time)
	elseif self.state == STATES.CHASE then
		self:_update_chase(delta_time)
	elseif self.state == STATES.ATTACK then
		self:_update_attack(delta_time)
	end
end

function EnemyAI:_find_nearest_player(players)
	local nearest = nil
	local nearest_distance = self.detection_range
	
	for _, player in ipairs(players) do
		if player.Character then
			local root_part = player.Character:FindFirstChild("HumanoidRootPart")
			if root_part then
				local distance = (root_part.Position - self.root_part.Position).Magnitude
				if distance < nearest_distance then
					nearest = root_part
					nearest_distance = distance
				end
			end
		end
	end
	
	return nearest
end

function EnemyAI:_update_idle(delta_time)
	if self.target then
		self:_set_state(STATES.CHASE)
	elseif self.state_timer > 3 then
		self:_set_state(STATES.PATROL)
	end
end

function EnemyAI:_update_patrol(delta_time)
	if self.target then
		self:_set_state(STATES.CHASE)
		return
	end
	
	if not self.patrol_point or (self.root_part.Position - self.patrol_point).Magnitude < 5 then
		self.patrol_point = self:_get_random_patrol_point()
	end
	
	if self.patrol_point then
		local direction = (self.patrol_point - self.root_part.Position).Unit
		self.humanoid:MoveTo(self.root_part.Position + direction * self.move_speed * delta_time)
	end
end

function EnemyAI:_update_chase(delta_time)
	if not self.target then
		self:_set_state(STATES.PATROL)
		return
	end
	
	local distance = (self.target.Position - self.root_part.Position).Magnitude
	
	if distance <= self.attack_range then
		self:_set_state(STATES.ATTACK)
	else
		local direction = (self.target.Position - self.root_part.Position).Unit
		self.humanoid:MoveTo(self.root_part.Position + direction * self.move_speed * delta_time)
	end
end

function EnemyAI:_update_attack(delta_time)
	if not self.target then
		self:_set_state(STATES.PATROL)
		return
	end
	
	local distance = (self.target.Position - self.root_part.Position).Magnitude
	
	if distance > self.attack_range * 1.5 then
		self:_set_state(STATES.CHASE)
		return
	end
	
	if self.attack_cooldown <= 0 then
		self:_perform_attack()
	end
end

function EnemyAI:_perform_attack()
	if not self.target then return end
	
	self.attack_cooldown = self.stats.attack_cooldown
	
	local damage = self.stats.damage
	local target_humanoid = self.target.Parent:FindFirstChild("Humanoid")
	
	if target_humanoid then
		target_humanoid:TakeDamage(damage)
		
		local knockback_dir = (self.target.Position - self.root_part.Position).Unit
		self.target.AssemblyLinearVelocity = self.target.AssemblyLinearVelocity + knockback_dir * 10
	end
end

function EnemyAI:_set_state(new_state)
	if new_state == self.state then return end
	
	self.state = new_state
	self.state_timer = 0
end

function EnemyAI:_get_random_patrol_point()
	local offset = Vector3.new(
		(math.random() - 0.5) * 30,
		0,
		(math.random() - 0.5) * 30
	)
	return self.root_part.Position + offset
end

function EnemyAI:take_damage(amount)
	self.hp = math.max(0, self.hp - amount)
	
	if self.hp <= 0 then
		self:die()
	end
end

function EnemyAI:die()
	self.is_alive = false
	self:_set_state(STATES.DEAD)
	
	if self.humanoid then
		self.humanoid.Health = 0
	end
end

function EnemyAI:get_state_name()
	local state_names = {
		[STATES.IDLE] = "Idle",
		[STATES.PATROL] = "Patrol",
		[STATES.CHASE] = "Chase",
		[STATES.ATTACK] = "Attack",
		[STATES.DEAD] = "Dead",
	}
	return state_names[self.state] or "Unknown"
end

return EnemyAI
