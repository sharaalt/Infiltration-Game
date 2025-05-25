local Promise = require(game.ServerScriptService.Dependencies.promise)
local require = require(script.Parent.loader).load(script)

local Maid = require("Maid")
local ServiceBag = require("ServiceBag")

local LineofSight = {}
LineofSight.__index = LineofSight
LineofSight.ServiceName = "LineofSightService"

function LineofSight:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "[LOS Service] - ServiceBag already initalized!")

	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._maid = Maid.new()
end

function LineofSight:Start()
	print("[LOS Service] - Started")
end

--- @param direction Vector3 The direction of the raycast
--- @param origin Vector3 The origin of the raycast in Vector3 form
--- @param Params any The paramaters of the raycast
--- @return RaycastResult Result of the raycast.
function LineofSight.EvalutePoints(direction: Vector3, origin: Vector3, Params, Object): Vector3
	return Promise.new(function(succ, err)
		local raycastResult = workspace:Raycast(origin, direction, Params)

		if raycastResult then
			if raycastResult.Instance then
				if raycastResult.Instance:IsDescendantOf(Object) then
					succ(true)
				else
					succ(false)
				end
			end
		else
			print(raycastResult)
			err("[LOS Service] - No raycast.")
		end
	end)
end

function LineofSight:Destroy()
	print("[LOS Service] - Cleaning up LOS Service.")
	self._maid:DoCleaning()
	self._serviceBag = nil
	self._maid = nil
	print("[LOS Service] - Cleaned up LOS Service.")
end

return LineofSight
