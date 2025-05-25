local Promise = require(game.ServerScriptService.Dependencies.promise)
local require = require(script.Parent.loader).load(script)

local ts = game:GetService("TweenService")
local Maid = require("Maid")
local ServiceBag = require("ServiceBag")

local tweenService = {}
tweenService.ServiceName = "tweenService"
tweenService.__index = tweenService

function tweenService:Init(ServiceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "ServiceBag already initalized!")

	self._serviceBag = assert(ServiceBag, "No serviceBag")
	self._maid = Maid.new()
end

function tweenService:Start()
	print("[TweenService] - Tween service started.")
end

function tweenService:PlayTween(tween)
	return Promise.new(function(succ, err)
		local connection
		connection = tween.Completed:Connect(function(playBackState)
			if playBackState == Enum.PlaybackState.Completed then
				succ("[TweenService] - Tween successfully played.")
			else
				err("[TweenService] - Tween returned an error: " .. tostring(err))
			end
		end)
		self._maid:Add(connection)

		tween:Play()
	end)
end

function tweenService:Destroy()
	print("[TweenService] - Cleaning up TweenService")
	self._maid:DoCleaning()

	self._maid = nil
	self._serviceBag = nil

	print("[TweenService] - Cleaning complete.")
end

return tweenService
