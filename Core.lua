-- Core.lua


------------------------------------------
-- 1. Global Declarations
------------------------------------------

--- Initialize RSI if it doesn't exist
RSI = RSI or {}

-- Global Declarations
local lastTargetChangeTime = 0
local timeSinceLastTargetChange = 0
local initialMark = true

-- Initialize the enabled state from the saved variable or default to true
if RSISkullEnabled == nil then
    RSISkullEnabled = true  -- Default state is enabled
end
RSI.skullMarkingEnabled = RSISkullEnabled

-- Create the RSIFrame here
local RSIFrame = CreateFrame("Frame", "RhodansMarkersFrame", UIParent)


------------------------------------------
-- 2. Utility Functions
------------------------------------------

-- Include utility function to check for 5-man dungeon
local function IsIn5ManDungeon()
    local isInstance, instanceType = IsInInstance()
    return isInstance and instanceType == "party"
end


-- Function to get player's specialization ID (adapted from RM)
local function GetSpecializationID(unit)
    if unit == "player" then
        return GetSpecializationInfo(GetSpecialization())
    else
        return UnitIsPlayer(unit) and tonumber(GetInspectSpecialization(unit)) or nil
    end
end


------------------------------------------
-- 3. Slash Command Registration
------------------------------------------

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


------------------------------------------
-- 4. Target Tracking and Marking Logic
------------------------------------------

local tankTarget
local skullMarker = 8
local markerSet = false
local updateInterval = 5 -- seconds, adjust as needed


-- Define tank specialization IDs
local tankSpecIDs = {250, 104, 581, 66, 268, 73} -- Add all tank spec IDs here


-- Function for handling marking of specific target
local function MarkTankTarget()
    if UnitIsPlayer("target") or not UnitIsEnemy("player", "target") then
        return -- Ensures the target is a hostile NPC
    end

    if GetRaidTargetIndex("target") ~= skullMarker then
        SetRaidTarget("target", skullMarker)
        markerSet = true
    end
end


-- Function to check if player is the leader or a tank in a 5-man dungeon
local function ShouldHandleMarking()
    local isInstance, instanceType = IsInInstance()
    if isInstance and instanceType == "party" then
        -- Inside a dungeon, check if the player is in a tank spec or assigned the tank role
        return UnitGroupRolesAssigned("player") == "TANK" or tContains(tankSpecIDs, GetSpecializationID("player"))
    else
        -- Outside of dungeons, check if the player is the group leader
        return UnitIsGroupLeader("player") and not IsInRaid()
    end
end


-- Updated function to incorporate role-based marking logic
local function UpdateTankMark(self, elapsed)
    lastTargetChangeTime = lastTargetChangeTime + elapsed
    if lastTargetChangeTime < updateInterval then return end

    local shouldMark = RSI.skullMarkingEnabled and ShouldHandleMarking()
    local groupSize = GetNumGroupMembers()
    local inSmallGroup = IsInGroup() and groupSize >= 2 and groupSize <= 5

    -- Reset marker if target changes or under specific conditions
    if UnitGUID("target") ~= tankTarget or (shouldMark and not GetRaidTargetIndex("target") == skullMarker) then
        tankTarget = UnitGUID("target")
        markerSet = false
        timeSinceLastTargetChange = 0 -- Reset this as well to handle delay correctly
    end

    -- Marking logic when conditions are met and marker isn't set
    if shouldMark and not markerSet and tankTarget then
        MarkTankTarget()
    end

    -- Reset initialMark after marking or a significant time has passed without marking
    if markerSet or timeSinceLastTargetChange > 10 then
        initialMark = true
    end

    lastTargetChangeTime = 0 -- Reset lastTargetChangeTime after processing
end


------------------------------------------
-- 5. Frame and Event Handling
------------------------------------------

-- Now you can set the elapsed property and OnUpdate script
RSIFrame.elapsed = 0
RSIFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed >= updateInterval then
        UpdateTankMark(self, self.elapsed)
        self.elapsed = 0
    end
end)


------------------------------------------
-- 6. Event Registration
------------------------------------------

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