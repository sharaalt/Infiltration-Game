--[[
	@class InfilGameTranslator
]]

local require = require(script.Parent.loader).load(script)

return require("JSONTranslator").new("InfilGameTranslator", "en", {
	gameName = "InfilGame";
})