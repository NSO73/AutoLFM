--=============================================================================
-- AutoLFM: Initialization System
--   Lifecycle hooks and addon startup
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Core = AutoLFM.Core or {}
AutoLFM.Core.Maestro = AutoLFM.Core.Maestro or {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local initHandlers = {}
local isInitialized = false

--=============================================================================
-- HELPER FUNCTIONS
--=============================================================================

-----------------------------------------------------------------------------
-- Call Function by Path String
--   Resolves "Logic.Roles.RegisterCommands" to AutoLFM.Logic.Roles.RegisterCommands()
--   @param fullPath string: Dot-separated path to function
--   @return boolean: Success status
-----------------------------------------------------------------------------
local function CallByPath(fullPath)
    if not fullPath or type(fullPath) ~= "string" then
        return false
    end

    -- Split path by dots
    local parts = {}
    local current = 1
    while current <= string.len(fullPath) do
        local dotPos = string.find(fullPath, "%.", current)
        if dotPos then
            local part = string.sub(fullPath, current, dotPos - 1)
            table.insert(parts, part)
            current = dotPos + 1
        else
            local part = string.sub(fullPath, current)
            table.insert(parts, part)
            break
        end
    end

    if table.getn(parts) == 0 then
        return false
    end

    -- Navigate to module (start with AutoLFM)
    local module = AutoLFM
    for i = 1, table.getn(parts) - 1 do
        module = module and module[parts[i]]
        if not module then
            return false
        end
    end

    -- Get function
    local funcName = parts[table.getn(parts)]
    local func = module and module[funcName]
    if not func or type(func) ~= "function" then
        return false
    end

    -- Call function
    func()
    return true
end

--=============================================================================
-- INITIALIZATION REGISTRATION
--=============================================================================

-----------------------------------------------------------------------------
-- Register Initialization Handler
--   @param handlerId string: Unique identifier for this handler
--   @param handler function: Function to execute on init
--   @param metadata table: { name, description } (optional)
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.RegisterInit(handlerId, handler, metadata)
    if initHandlers[handlerId] then
        error("Maestro: Init handler '" .. handlerId .. "' already registered")
        return
    end

    initHandlers[handlerId] = {
        id = handlerId,
        key = (metadata and metadata.key) or handlerId,
        description = (metadata and metadata.description) or "No description",
        handler = handler
    }
end

--=============================================================================
-- INITIALIZATION EXECUTION
--=============================================================================

-----------------------------------------------------------------------------
-- Run All Initialization Handlers
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.RunInit()
    if isInitialized then
        print("AutoLFM: Already initialized")
        return
    end

    print("AutoLFM: Initializing addon...")

    -- Sort handlers by ID for consistent order
    local sortedHandlers = {}
    for id, handlerData in pairs(initHandlers) do
        table.insert(sortedHandlers, handlerData)
    end
    table.sort(sortedHandlers, function(a, b) return a.id < b.id end)

    -- Execute handlers
    for i, handlerData in ipairs(sortedHandlers) do
        if AutoLFM.Core.Maestro.DebugMode then
            AutoLFM.Core.Maestro.Log("INIT", "Running: " .. (handlerData.id or "unknown"), handlerData.key or "")
        end

        local success, err
        local handler = handlerData.handler

        -- Support both function and string path formats
        if type(handler) == "string" then
            success = CallByPath(handler)
            if not success then
                err = "Failed to call " .. handler
            end
        elseif type(handler) == "function" then
            success, err = pcall(handler)
        else
            success = false
            err = "Invalid handler type: " .. type(handler)
        end

        if not success then
            error("Maestro: Error in init handler '" .. handlerData.id .. "': " .. tostring(err))
        end
    end

    isInitialized = true
    print("AutoLFM: Initialization complete")
end

-----------------------------------------------------------------------------
-- Check if addon is initialized
--   @return boolean: true if initialized
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.IsInitialized()
    return isInitialized
end

-----------------------------------------------------------------------------
-- Get All Init Handlers (for debug purposes)
--   @return table: List of registered init handlers
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetInitHandlers()
    local handlers = {}
    for id, handlerData in pairs(initHandlers) do
        table.insert(handlers, {
            id = id,
            key = handlerData.key,
            description = handlerData.description
        })
    end
    table.sort(handlers, function(a, b) return a.id < b.id end)
    return handlers
end

--=============================================================================
-- WOW EVENT HANDLING
--=============================================================================

-----------------------------------------------------------------------------
-- Setup frame for PLAYER_ENTERING_WORLD event
-----------------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
    AutoLFM.Core.Maestro.RunInit()
    initFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)
