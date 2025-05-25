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

function GuardClass.new(Guard, PathfindingService, lineOfSight)
	local self = setmetatable(BaseObject.new(), GuardClass)

	-- Defenitions
	self._animator = Instance.new("Animator")

	-- Static Variables
	self._guard = Guard
	self._humanoid = self._guard.Humanoid
	self._waypoints = self._guard.Waypoints
	self._animator.Parent = self._humanoid

	-- Signals
	self.PathCompleted = Signal.new()
	self.PlayerSpotted = Signal.new()
	self.PlayerLost = Signal.new()

	-- Services
	self._maid = Maid.new()
	self._pathfindingService = assert(PathfindingService, "No pathfindingservice")
	self._lineOfSight = assert(lineOfSight, "[Guard Controller] - No LOS Service")

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

	self._maid:GiveTask(self.PathCompleted:Connect(function()
		if self._currentState then
			self._currentState.OnExit()
			self._currentState = "Idle"
			self._currentState.OnEnter()
		end
	end))

	self._maid:GiveTask(self.PlayerSpotted:Connect(function()
		if self._currentState then
			self._currentState.OnExit()
			self._currentState = "Chase"
			self._currentState.OnEnter()
		end
	end))

	self._maid:GiveTask(self.PlayerLost:Connect(function()
		if self._currentState then
			self._currentState.OnExit()
			self._currentState = "Idle"
			self._currentState.OnEnter()
		end
	end))

	return self
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

	local character = player.Character or player.CharacterAdded:Wait()
	if character and character:FindFirstChild("HumanoidRootPart") then
		local result = false

		local distance = (self._guard.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
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
			:await()

		if distance < closestDistance and result then
			return player
		else
			return nil
		end
	end
end

function GuardClass:Start()
	-- This creates a dedicated thread for THIS guard's AI loop
	task.spawn(function()
		self:Update() -- Clean up if guard is removed
	end)
end

function GuardClass:Update()
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
					self.PlayerSpotted:Fire()
				end
			end

			print(closestPlayer)
		end

		-- === Phase 2 Decide === --
		-- To-Do: N/A --
		if closestPlayer then
			if self._currentState ~= "Chase" then
				self.PlayerSpotted:Fire()
			end
		end

		-- === Phase 3 Act === --
		-- To-Do: N/A --
		self:_ExecuteCurrentState()
	end
end

function GuardClass:_RequestNewPath(destination: Vector3)
	return Promise.new(function(succ)
		self
			._pathfindingService
			:FindPath(self._guard.PrimaryPart.Position, destination) -- Access a service "Pathfinding Service"
			:andThen(function(val)
				succ(val)
			end)
			:catch(warn)
			:await()
	end)
end

function GuardClass:MoveGuard(Waypoints: table)
	for _, waypoint in Waypoints do
		self._walkAnim:Play()
		self._idleAnim:Stop()

		self._humanoid:MoveTo(waypoint.Position)
		self._humanoid.MoveToFinished:Wait()

		self._walkAnim:Stop()
		self._idleAnim:Play()
	end

	return true
end

function GuardClass:Destroy()
	self._maid:DoCleaning()
end

return GuardClass
