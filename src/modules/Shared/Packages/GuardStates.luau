--[=[
	@class GuardStates
]=]

local GuardStates = {}

local require = require(script.Parent.loader).load(script)

local Maid = require("Maid")

function GuardStates.Idle(guard)
	local stateMaid = Maid.new()

	return {
		Name = "Idle",
		OnEnter = function()
			print("Starting Idle")
			guard._idleAnim:Play()
			guard._walkAnim:Stop()
		end,
		OnExecute = function()
			print(string.format("Idling %c", guard._currentPlayer.Character.Humanoid.Health))
			guard._currentPlayer.Character.Humanoid.Health = guard._currentPlayer.Character.Humanoid.Health - 10
		end,
		OnExit = function()
			print("Done idling")
			guard._idleAnim:Stop()
		end,
	}
end

function GuardStates.Patrol(guard)
	local stateMaid = Maid.new()
	local patrolLoopTask = nil

	return {
		Name = "Patrol",
		OnEnter = function()
			patrolLoopTask = task.spawn(function()
				local task = guard:MoveGuard(guard._waypoints)

				if task then
					guard.PatrolCompleted:Fire()
				end
			end)
			print("Starting patrol")
		end,
		OnExecute = function() end,
		OnExit = function()
			stateMaid:DoCleaning()
			patrolLoopTask = nil
			print("Done patrolling.")
		end,
	}
end

function GuardStates.Chase(guard)
	return {
		Name = "Chase",
		OnEnter = function()
			print("Starting chase")
		end,
		OnExecute = function()
			if guard._currentState.Name ~= "Idle" then
				guard
					:RequestNewPath(guard._currentPlayer.Character.HumanoidRootPart.Position)
					:andThen(function(val)
						guard:MoveGuard(val)
					end)
					:catch(warn)
					:await()
			else
				return
			end
		end,
		OnExit = function()
			print("Done chasing.")
		end,
	}
end

return GuardStates
