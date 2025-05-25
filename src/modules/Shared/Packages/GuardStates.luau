--[=[
	@class GuardStates
]=]

local GuardStates = {}

function GuardStates.Idle(guard)
	return {
		Name = "Idle",
		OnEnter = function()
			print("Starting Idle")
			guard._idleAnim:Play()
			guard._walkAnim:Stop()
		end,
		OnExecute = function()
			print("Idling")
			task.wait(1)
		end,
		OnExit = function()
			print("Done idling")
		end,
	}
end

function GuardStates.Patrol(guard)
	return {
		Name = "Patrol",
		OnEnter = function()
			print("Starting patrol")
		end,
		OnExecute = function()
			print(guard._waypoints)
			-- for _, waypoint in ipairs(guard._waypoints) do
			-- 	guard._walkAnim:Play()
			-- 	guard._idleAnim:Stop()
			-- 	guard._Humanoid:MoveTo(waypoint.Position)
			-- 	guard._Humanoid.MoveToFinished:Wait()
			-- 	guard._idleAnim:Play()
			-- 	guard._walkAnim:Stop()
			-- end
		end,
		OnExit = function()
			print("Done patrolling.")
		end,
	}
end

function GuardStates.Chase(guard)
	return {
		Name = "Chase",
		OnEnter = function()
			print("Starting patrol")
		end,
		OnExecute = function()
			print(guard._currentPlayer)
			guard
				:RequestNewPath(guard._currentPlayer.Character.HumanoidRootPart.Position)
				:andThen(function(val)
					guard:MoveGuard(val)
				end)
				:catch(warn)
		end,
		OnExit = function()
			print("Done chasing.")
		end,
	}
end

return GuardStates
