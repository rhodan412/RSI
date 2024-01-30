-- Core.lua

--- Initialize RSI if it doesn't exist
RSI = RSI or {}

-- Initialize the enabled state from the saved variable or default to true
if RSISkullEnabled == nil then
    RSISkullEnabled = true  -- Default state is enabled
end
RSI.skullMarkingEnabled = RSISkullEnabled

-- Create the RSIFrame here
local RSIFrame = CreateFrame("Frame", "RhodansMarkersFrame", UIParent)

-- Function to toggle the skull marking feature
local function ToggleSkullMarking(state)
    if state == "on" then
        RSI.skullMarkingEnabled = true
        RSISkullEnabled = true  -- Make sure to update the saved variable
        print("Skull marking is now enabled.")
    elseif state == "off" then
        RSI.skullMarkingEnabled = false
        RSISkullEnabled = false  -- Make sure to update the saved variable
        print("Skull marking is now disabled.")
    else
        print("Usage: /RSI on | off")
    end
end

-- Register the slash command
SLASH_RSISKULL1 = "/RSI"
SlashCmdList["RSISKULL"] = function(msg)
    ToggleSkullMarking(msg:lower())
end

local tankTarget
local lastTargetChangeTime = 0
local skullMarker = 8
local markerSet = false
local updateInterval = 1 -- seconds, adjust as needed


local function MarkTankTarget()
    if UnitIsPlayer("target") or not UnitIsEnemy("player", "target") then
        --print("RSI: Target is a player or not an enemy.")
        return -- Ensures the target is a hostile NPC
    end

    if GetRaidTargetIndex("target") ~= skullMarker then
        --print("RSI: Marking target with a skull.")
        SetRaidTarget("target", skullMarker)
        markerSet = true
    else
        --print("RSI: Target is already marked with a skull.")
    end
end

-- In the UpdateTankMark function
local function UpdateTankMark(self, elapsed)
    print("UpdateTankMark called")
    lastTargetChangeTime = lastTargetChangeTime + elapsed
    if lastTargetChangeTime < updateInterval then return end
    lastTargetChangeTime = 0

    local inInstance, instanceType = IsInInstance()
    local inSmallGroup = IsInGroup() and GetNumGroupMembers() <= 5

    print("In instance: " .. tostring(inInstance))
    print("In small group: " .. tostring(inSmallGroup))
    print("Skull marking enabled: " .. tostring(RSI.skullMarkingEnabled))

    if not inInstance and inSmallGroup and RSI.skullMarkingEnabled then
        if UnitGUID("target") ~= tankTarget then
            tankTarget = UnitGUID("target")
            markerSet = false
            print("New target acquired. Marking needed.")
        elseif not markerSet and tankTarget then
            MarkTankTarget()
            print("Marking target with a skull.")
        end
    end
end


-- Now you can set the elapsed property and OnUpdate script
RSIFrame.elapsed = 0
RSIFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed >= updateInterval then
        UpdateTankMark(self, self.elapsed)
        self.elapsed = 0
    end
end)

-- Event handling function
RSIFrame:SetScript("OnEvent", function(self, event, ...)
    -- You need to ensure that the RSI.isEnabled line is correctly placed within an event where it's used
    -- For example, if you have a specific event that checks for RSI.isEnabled, it should be inside that event's handling block.
    
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "RhodansSkullIt" then  -- Make sure this matches your actual addon's folder name
            -- Initialize the skull marking state from the saved variable or default to true
            RSI.skullMarkingEnabled = RSISkullEnabled
        end
    end
end)

-- Register events
RSIFrame:RegisterEvent("ADDON_LOADED")