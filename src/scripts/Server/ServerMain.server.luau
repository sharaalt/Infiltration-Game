--[[
    @class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Promise = require(game.ServerScriptService.Dependencies.promise)
local loader = ServerScriptService.InfilGame:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.InfilGame)

local serviceBag = require("ServiceBag").new()

-- Services
local InfilGameService = serviceBag:GetService(require("InfilGameService"))
local PathfindingService = serviceBag:GetService(require("PathfindingService"))
local LOService = serviceBag:GetService(require("LineOfSightService"))
local TweenService = serviceBag:GetService(require("TweenService"))

-- Clases
local GuardClass = serviceBag:GetService(require("GuardPackage"))
local DoorClass = serviceBag:GetService(require("DoorPackage"))

serviceBag:Init()
serviceBag:Start()

local activeClasses = {}

print("-- [Server Main] Binding script to parts. --")

local function BindScriptsToPartsPromise()
	return Promise.new(function(res, error)
		local startTime = os.clock()

		for _, v in pairs(Workspace:GetDescendants()) do
			if v:HasTag("Enemy") then
				local guardController = GuardClass.new(v, PathfindingService, LOService, v.Waypoints:GetDescendants())
				table.insert(activeClasses, guardController)
				print(
					string.format(
						"-- [Server Main] Created GuardController for %s. Total active: %d",
						v.Name,
						#activeClasses
					)
				)
			end

			if v:HasTag("Door") then
				local newPrompt = Instance.new("ProximityPrompt")
				if v:HasTag("IsLockpickable") then
					newPrompt.Parent = v
					newPrompt.ActionText = "Lockpick Door"
					newPrompt.HoldDuration = 3
				else
					newPrompt.Parent = v
					newPrompt.ActionText = "Open Door"
					newPrompt.HoldDuration = 0.25
				end

				local doorController = DoorClass.new(newPrompt, v, TweenService)
				table.insert(activeClasses, doorController)
			end
		end

		local endTime = os.clock()
		local duration = endTime - startTime
		res(string.format("-- [Server Main] Binded scripts to parts in %.2f seconds --", duration))
	end)
end

BindScriptsToPartsPromise():andThen(print):catch(warn):await()

for _, v in pairs(activeClasses) do
	v:StartUpdate()
end

game:BindToClose(function()
	for _, v in pairs(activeClasses) do
		v:Destroy()
	end
end)
