local ReplicatedStorage = game:GetService("ReplicatedStorage")
--[=[
	@class InfilGameServiceClient
]=]

local ServiceBag = require(ReplicatedStorage.InfilGame.node_modules["@quenty"].servicebag.Shared.ServiceBag)
local require = require(script.Parent.loader).load(script)

local InfilGameServiceClient = {}
InfilGameServiceClient.ServiceName = "InfilGameServiceClient"

function InfilGameServiceClient:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- Internal
	self._serviceBag:GetService(require("InfilGameTranslator"))
end

return InfilGameServiceClient
