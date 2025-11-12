function gadget:GetInfo()
    return {
        name = "Scenario Loader",
        desc = "Loads custom tournament scenarios from luarules/gadgets/scenarios/",
        author = "AI Competition Mod",
        date = "2025",
        license = "GPL v2",
        layer = -1,  -- Run before other gadgets like game_initial_spawn
        enabled = true,
    }
end

-- ============================================================================
-- Configuration
-- ============================================================================

local SCENARIOS_DIR = "luarules/gadgets/scenarios"

-- ============================================================================
-- Utilities
-- ============================================================================

local function Echo(msg)
    Spring.Echo("[ScenarioLoader] " .. msg)
end

local function GetScenarioName()
    -- Get scenario name from modOptions (set via tweakdefs in lobby)
    local modOptions = Spring.GetModOptions()
    if modOptions and modOptions.scenario then
        return modOptions.scenario
    end
    
    -- Default to center_start
    return "center_start"
end

local function LoadScenarioFile(scenarioName)
    local path = SCENARIOS_DIR .. "/" .. scenarioName .. ".lua"
    
    if not VFS.FileExists(path) then
        Echo("ERROR: Scenario file not found: " .. path)
        return nil
    end
    
    local ok, scenario = pcall(VFS.Include, path)
    if not ok then
        Echo("ERROR: Failed to load scenario " .. scenarioName .. ": " .. tostring(scenario))
        return nil
    end
    
    return scenario
end

local function ValidateScenario(scenario)
    -- Check required fields
    if not scenario.name then
        Echo("WARNING: Scenario missing 'name' field")
    end
    
    if not scenario.teams or #scenario.teams == 0 then
        Echo("ERROR: Scenario must have at least one team")
        return false
    end
    
    -- Validate each team
    for teamIdx, team in ipairs(scenario.teams) do
        if not team.units or #team.units == 0 then
            Echo("WARNING: Team " .. teamIdx .. " has no units")
        end
        
        -- Validate each unit
        for unitIdx, unit in ipairs(team.units or {}) do
            if not unit.defName then
                Echo("ERROR: Team " .. teamIdx .. " unit " .. unitIdx .. " missing 'defName'")
                return false
            end
            
            if not unit.x or not unit.z then
                Echo("ERROR: Team " .. teamIdx .. " unit " .. unitIdx .. " missing position (x, z)")
                return false
            end
            
            -- Check if unit def exists
            local unitDef = UnitDefNames[unit.defName]
            if not unitDef then
                Echo("ERROR: Team " .. teamIdx .. " unit " .. unitIdx .. ": unknown unit '" .. unit.defName .. "'")
                return false
            end
            
            -- For buildings, validate placement
            if unitDef.isBuilding then
                local y = unit.y or Spring.GetGroundHeight(unit.x, unit.z)
                local facing = unit.facing or 0
                local testResult = Spring.TestBuildOrder(unitDef.id, unit.x, y, unit.z, facing)
                
                if testResult ~= 2 then  -- 2 = buildable
                    Echo("WARNING: Team " .. teamIdx .. " unit " .. unitIdx .. " (" .. unit.defName .. ") at (" .. unit.x .. ", " .. unit.z .. ") may not be buildable (test result: " .. testResult .. ")")
                end
            end
        end
    end
    
    Echo("Scenario '" .. (scenario.name or "unknown") .. "' validated successfully")
    return true
end

local function SpawnUnit(unitDefName, x, y, z, facing, teamID)
    -- Try the unit name as-is first
    local unitDef = UnitDefNames[unitDefName]
    
    -- If not found and not already prefixed, try common prefixes
    if not unitDef and not string.match(unitDefName, "^(arm|leg|cor)") then
        for _, prefix in ipairs({"arm", "leg", "cor"}) do
            local prefixedName = prefix .. unitDefName
            unitDef = UnitDefNames[prefixedName]
            if unitDef then
                unitDefName = prefixedName
                break
            end
        end
    end
    
    if not unitDef then
        Echo("ERROR: Cannot spawn unknown unit: " .. unitDefName)
        return nil
    end
    
    if not y then
        y = Spring.GetGroundHeight(x, z)
    end
    
    facing = facing or 0
    
    local unitID = Spring.CreateUnit(unitDefName, x, y, z, facing, teamID)
    if not unitID then
        Echo("ERROR: Failed to spawn unit " .. unitDefName .. " at (" .. x .. ", " .. z .. ")")
        return nil
    end
    
    return unitID
end

local function SetupScenario(scenario)
    Echo("Setting up scenario: " .. (scenario.name or "unknown"))
    
    local teamList = Spring.GetTeamList()
    
    -- Validate we have enough teams
    if #teamList < #scenario.teams then
        Echo("WARNING: Scenario has " .. #scenario.teams .. " teams but only " .. #teamList .. " teams in game")
    end
    
    -- Set team start positions in GG.teamStartPoints (used by game_initial_spawn)
    -- Initialize GG.teamStartPoints if it doesn't exist yet
    if not GG.teamStartPoints then
        GG.teamStartPoints = {}
    end
    
    -- Also store scenario start positions for AIs to query
    if not GG.scenarioStartPositions then
        GG.scenarioStartPositions = {}
    end
    
    for teamIdx, teamSetup in ipairs(scenario.teams) do
        if teamIdx > #teamList then
            Echo("WARNING: Skipping team " .. teamIdx .. " (no team slot available)")
            break
        end
        
        local teamID = teamList[teamIdx]
        
        -- Set team start position if specified
        if teamSetup.startX and teamSetup.startZ then
            local y = Spring.GetGroundHeight(teamSetup.startX, teamSetup.startZ)
            GG.teamStartPoints[teamID] = {teamSetup.startX, y, teamSetup.startZ}
            GG.scenarioStartPositions[teamID] = {x = teamSetup.startX, y = y, z = teamSetup.startZ}
            Echo("Set team " .. teamID .. " start position to (" .. teamSetup.startX .. ", " .. teamSetup.startZ .. ")")
            Echo("DEBUG: GG.scenarioStartPositions[" .. teamID .. "] = {x=" .. teamSetup.startX .. ", z=" .. teamSetup.startZ .. "}")
        end
    end
    
    Echo("DEBUG: Full GG.scenarioStartPositions table:")
    for teamID, pos in pairs(GG.scenarioStartPositions) do
        Echo("  Team " .. teamID .. ": (" .. pos.x .. ", " .. pos.z .. ")")
    end
    
    Echo("Scenario setup complete")
end

local scenarioData = nil
local scenarioEvents = {}  -- Track which events have been triggered

local function ProcessScenarioEvents(scenario, frame)
    if not scenario.events then return end
    
    for eventIdx, event in ipairs(scenario.events) do
        -- Skip if already triggered
        if not scenarioEvents[eventIdx] then
            local shouldTrigger = false
            
            -- Check timed event (frame-based)
            if event.frame and frame == event.frame then
                shouldTrigger = true
            end
            
            -- Check conditional event
            if event.condition and type(event.condition) == "function" then
                if event.condition(frame) then
                    shouldTrigger = true
                end
            end
            
            -- Trigger the event
            if shouldTrigger then
                if event.action and type(event.action) == "function" then
                    local ok, err = pcall(event.action, frame)
                    if not ok then
                        Echo("ERROR: Event " .. eventIdx .. " failed: " .. tostring(err))
                    else
                        Echo("Event " .. eventIdx .. " triggered at frame " .. frame)
                        scenarioEvents[eventIdx] = true
                    end
                end
            end
        end
    end
end

local function SpawnScenarioUnits(scenario)
    Echo("Spawning scenario units...")
    
    local teamList = Spring.GetTeamList()
    
    -- Spawn units for each team (runs after default commanders are already spawned)
    for teamIdx, teamSetup in ipairs(scenario.teams) do
        if teamIdx > #teamList then
            break
        end
        
        local teamID = teamList[teamIdx]
        
        -- Get team start position for relative coordinates
        local startX = teamSetup.startX or 0
        local startZ = teamSetup.startZ or 0
        
        -- Spawn units
        for unitIdx, unit in ipairs(teamSetup.units or {}) do
            -- Unit coordinates are relative to team start position
            local x = startX + (unit.x or 0)
            local z = startZ + (unit.z or 0)
            local y = unit.y
            local facing = unit.facing or 0
            
            local unitID = SpawnUnit(unit.defName, x, y, z, facing, teamID)
            if unitID then
                Echo("Spawned " .. unit.defName .. " for team " .. teamID .. " at (" .. x .. ", " .. z .. ") (unitID: " .. unitID .. ")")
            end
        end
    end
    
    Echo("Scenario units spawned")
end

function gadget:GameFrame(frame)
    -- On frame 1, move default commanders to scenario start positions
    if frame == 1 and scenarioData then
        Echo("Moving default commanders to scenario positions...")
        local teamList = Spring.GetTeamList()
        
        for teamIdx, teamSetup in ipairs(scenarioData.teams) do
            if teamIdx > #teamList then
                break
            end
            
            local teamID = teamList[teamIdx]
            if teamSetup.startX and teamSetup.startZ then
                -- Find the commander
                local units = Spring.GetTeamUnits(teamID) or {}
                for _, unitID in ipairs(units) do
                    local unitDefID = Spring.GetUnitDefID(unitID)
                    local unitDef = unitDefID and UnitDefs[unitDefID]
                    if unitDef and unitDef.customParams and unitDef.customParams.iscommander then
                        Spring.SetUnitPosition(unitID, teamSetup.startX, teamSetup.startZ)
                        Echo("Moved commander (unitID: " .. unitID .. ") to (" .. teamSetup.startX .. ", " .. teamSetup.startZ .. ")")
                        break
                    end
                end
            end
        end
    end
    
    -- Process scenario events every frame
    if scenarioData then
        ProcessScenarioEvents(scenarioData, frame)
    end
end

-- ============================================================================
-- Gadget Callins
-- ============================================================================

function gadget:GameStart()
    Echo("Game started, loading scenario...")
    
    local scenarioName = GetScenarioName()
    Echo("Scenario name: " .. scenarioName)
    
    local scenario = LoadScenarioFile(scenarioName)
    if not scenario then
        Echo("ERROR: Could not load scenario, using default setup")
        return
    end
    
    if not ValidateScenario(scenario) then
        Echo("ERROR: Scenario validation failed, using default setup")
        return
    end
    
    SetupScenario(scenario)
    SpawnScenarioUnits(scenario)
    
    -- Reset event tracking for this scenario
    scenarioEvents = {}
    
    -- Store scenario data for GameFrame to use
    scenarioData = scenario
end

-- ============================================================================
-- Unsynced (for debugging)
-- ============================================================================

if not gadgetHandler:IsSyncedCode() then
    function gadget:Initialize()
        -- Unsynced code can list available scenarios
    end
end
