--[=[
	@class GuardClass
]=]

-- External Modules
local Promise = require(game.ServerScriptService.Dependencies.promise)
local require = require(script.Parent.loader).load(script)
local stateMachine = require(game.ReplicatedStorage.InfilGame.game.Shared.Packages.GuardStates)

-- Services
local BaseObject = require("BaseObject")
local Maid = require("Maid")
local Signal = require("Signal")
local Players = game:GetService("Players")

-- Class Defenitions
local GuardClass = setmetatable({}, BaseObject)
GuardClass.ClassName = "GuardClass"
GuardClass.__index = GuardClass

function GuardClass.new(Guard, PathfindingService, lineOfSight, Waypoints)
	local self = setmetatable(BaseObject.new(), GuardClass)

	-- Defenitions
	self._animator = Instance.new("Animator")

	-- Static Variables
	self._guard = Guard
	self._humanoid = self._guard.Humanoid
	self._waypoints = self._guard.Waypoints
	self._animator.Parent = self._humanoid
	self._waypoints = Waypoints

	-- Dynamic Variables
	self._currentPlayer = nil

	-- Signals
	self.PatrolCompleted = Signal.new()
	self.PlayerSpotted = Signal.new()
	self.PlayerLost = Signal.new()
	self.InRange = Signal.new()

	-- Services
	self._maid = Maid.new()
	self._pathfindingService = assert(PathfindingService, "[Guard Controller] - No pathfindingservice")
	self._lineOfSight = assert(lineOfSight, "[Guard Controller] - No LOS Service")

	-- Create animations
	local IdleAnimId = "http://www.roblox.com/asset/?id=180435571"
	local WalkAnimId = "http://www.roblox.com/asset/?id=180426354"
	local IdleAnim = Instance.new("Animation")
	local WalkAnim = Instance.new("Animation")

	-- Assign properties
	IdleAnim.AnimationId = IdleAnimId
	IdleAnim.Name = "Idle"
	WalkAnim.AnimationId = WalkAnimId
	WalkAnim.Name = "Walk"

	-- Load animations
	self._walkAnim = self._animator:LoadAnimation(WalkAnim)
	self._idleAnim = self._animator:LoadAnimation(IdleAnim)

	-- States
	self._currentState = nil
	self._states = {
		Idle = stateMachine.Idle(self),
		Patrol = stateMachine.Patrol(self),
		Chase = stateMachine.Chase(self),
	}

	local initalState = self._states.Patrol
	initalState.OnEnter()

	self:SetState(self._states.Patrol)

	self._maid:GiveTask(self.PatrolCompleted:Connect(function()
		if self._currentState.Name == "Patrol" then
			self:SetState(self._states.Idle)
		end
	end))

	self._maid:GiveTask(self.InRange:Connect(function()
		self:SetState(self._states.Idle)
	end))

	self._maid:GiveTask(self.PlayerSpotted:Connect(function(player)
		self:SetState(self._states.Chase, player)
	end))

	self._maid:GiveTask(self.PlayerLost:Connect(function()
		self:SetState(self._states.Patrol)
	end))

	return self
end

function GuardClass:SetState(state, ...)
	if self._currentState == state then
		warn(string.format("[Guard Controller] The current state is already %q!", state.Name))
		return
	end

	if self._currentState then
		self._currentState:OnExit()
	end

	self._currentState = state
	self._currentState:OnEnter(...)
end

function GuardClass:_ExecuteCurrentState()
	if self._currentState and self._currentState.OnExecute then
		self._currentState.OnExecute()
	end
end

function GuardClass:_CheckLineOfSight(player)
	if not player then
		return
	end
	local closestDistance = 20

	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local result = false

		local distance = (self._guard:WaitForChild("HumanoidRootPart").Position - character.HumanoidRootPart.Position).Magnitude
		local direction = (character.HumanoidRootPart.Position - self._guard.HumanoidRootPart.Position)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = { self._guard }
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude

		self._lineOfSight
			.EvalutePoints(direction * closestDistance, self._guard.Head.Position, raycastParams, character)
			:andThen(function(succ)
				result = succ
			end)
			:catch(warn)

		if distance < closestDistance and result then
			return player
		else
			return nil
		end
	end
end

function GuardClass:StartUpdate()
	self._maid:GiveTask(task.spawn(function()
		self:Update()
	end))
end

function GuardClass:Update()
	return Promise.new(function(res, err)
		local timer = 0

		while true do
			task.wait(0.2)
			local closestPlayer

			-- === Phase 1 Info Gathering === --
			-- To-Do: Use work octrees to fix performance bottleneck not need right now.
			for _, player in (Players:GetPlayers()) do
				if player then
					local hasSight = self:_CheckLineOfSight(player)

					if hasSight then
						closestPlayer = hasSight
						self._currentPlayer = player
					end
				end
			end

			-- === Phase 2 Decide === --
			-- To-Do: N/A --
			if closestPlayer then
				timer += 1
				timer = math.clamp(timer, 0, 5)

				if self._currentState.Name ~= "Chase" and timer >= 3 then
					self.PlayerSpotted:Fire(closestPlayer)
				end
			else
				timer -= 1
				timer = math.clamp(timer, 0, 5)

				if self._currentState.Name == "Chase" and timer == 0 then
					self.PlayerLost:Fire()
					self._currentPlayer = nil
				end

				if self._currentState.Name == "Idle" and timer == 0 then
					self:SetState(self._states.Patrol)
					self._currentPlayer = nil
				end
			end

			print(timer)

			-- === Phase 3 Act === --
			-- To-Do: N/A --
			self:_ExecuteCurrentState()
		end
	end)
end

function GuardClass:RequestNewPath(destination: Vector3)
	return Promise.new(function(succ)
		self._pathfindingService
			:FindPath(self._guard.PrimaryPart.Position, destination)
			:andThen(function(val)
				succ(val)
			end)
			:catch(warn)
			:await()
	end)
end

function GuardClass:MoveGuard(Waypoints: table)
	local startingState = self._currentState

	self._walkAnim:Play()
	self._idleAnim:Stop()

	if self._currentState.Name == "Idle" then
		print("[Guard Controller] State changed breaking loop.")
		self._humanoid:MoveTo(self._guard.PrimaryPart.Position)
		return
	else
		for _, waypoint in ipairs(Waypoints) do
			if self._currentState ~= startingState then
				print(
					string.format(
						"[Guard Controller] State changed during MoveGuard loop (to: %q) breaking.",
						self._currentState.Name
					)
				)

				self._humanoid:MoveTo(self._guard.PrimaryPart.Position)
				self._walkAnim:Stop()
				self._idleAnim:Play()
				break -- Exit the for loop
			end

			if self._currentPlayer and self._currentState.Name == "Chase" then
				local distance = (
					self._guard:WaitForChild("HumanoidRootPart").Position
					- self._currentPlayer.Character.HumanoidRootPart.Position
				).Magnitude

				if distance < 5.5 then
					self.InRange:Fire()
					self._walkAnim:Stop()
					self._idleAnim:Play()
					break
				end
			end

			self._humanoid:MoveTo(waypoint.Position)
			self._humanoid.MoveToFinished:Wait()
		end
	end

	self._walkAnim:Stop()
	self._idleAnim:Play()
	return true
end

function GuardClass:Destroy()
	self._maid:DoCleaning()
end

return GuardClass
