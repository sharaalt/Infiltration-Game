local Promise = require(game.ServerScriptService.Dependencies.promise)
local require = require(script.Parent.loader).load(script)

local PathfindingService = game:GetService("PathfindingService")
local Maid = require("Maid")
local ServiceBag = require("ServiceBag")

local Pathfinding = {}
Pathfinding.__index = Pathfinding
Pathfinding.ServiceName = "PathfindingService"

local partPostionUpdateConnection

function Pathfinding:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "ServiceBag already initalized!")

	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._maid = Maid.new()
end

function Pathfinding:Start()
	print("[PathfindingService] - Pathfinding service started.")
end

function Pathfinding:ReturnObject()
	return self._maid
end

function Pathfinding:FindPath(PointA: Vector3, PointB: Vector3)
	return Promise.new(function(succ, err)
		-- Potential Problem Area 1: If RobloxPathfindingService was nil (very unlikely)
		local Path = PathfindingService:CreatePath({
			AgentRadius = 3,
			AgentHeight = 6,
			AgentCanJump = true,
		})

		-- Potential Problem Area 2: If PointA or PointB are nil (pcall should catch this, but worth confirming)
		local success, errorMessage = pcall(function()
			Path:ComputeAsync(PointA, PointB)
		end)

		if success and Path.Status == Enum.PathStatus.Success then
			-- Potential Problem Area 3: If Path:GetWaypoints() returns nil or is not iterable (unlikely if Status is Success)
			for index, waypoint in (Path:GetWaypoints()) do
				local part = Instance.new("Part")
				part.Position = waypoint.Position
				part.Size = Vector3.new(0.5, 0.5, 0.5)
				part.Color = Color3.new(1, 0, 1)
				part.Anchored = true
				part.CanCollide = false
				part.Parent = game.Workspace
			end

			succ(Path:GetWaypoints())
		else
			-- This block is where errors are handled.
			-- If you get "nil" *here* as the error message, it means 'errorMessage' was nil.
			local errorMsg = errorMessage or "Pathfinding failed with status: " .. tostring(Path.Status)
			err("[PathfindingService] - Pathfinding to points returned an error: " .. errorMsg)
		end
	end)
end

function Pathfinding:Destroy()
	print("[PathfindingService] - Cleaning up.")
	self._maid:DoCleaning()
end

return Pathfinding
