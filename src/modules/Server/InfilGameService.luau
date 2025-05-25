--[=[
	@class InfilGameService
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local InfilGameService = {}
InfilGameService.ServiceName = "InfilGameService"

function InfilGameService:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- Internal
	self._serviceBag:GetService(require("InfilGameTranslator"))
end

return InfilGameService
