--=============================================================================
-- AutoLFM: Maestro System
--   Minimal event bus and initialization system
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Core = AutoLFM.Core or {}
AutoLFM.Core.Maestro = AutoLFM.Core.Maestro or {}

--=============================================================================
-- PRIVATE STATE
--=============================================================================

local commands = {}
local commandsRegistry = {}  -- Stores {id, key, handler} with incremental IDs
local commandCounter = 0

local initHandlers = {}
local initRegistry = {}  -- Stores {id, key, handler} with incremental IDs
local initCounter = 0

local isInitialized = false

--=============================================================================
-- COMMAND BUS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Command
--   @param key string: Command identifier (e.g., "ui.toggle")
--   @param handler function: Function to execute
--   @param options table: Optional config { silent = true/false }
--   @return number: Assigned command ID
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.RegisterCommand(key, handler, options)
    if commands[key] then
        error("Maestro: Command '" .. key .. "' already registered")
        return
    end
    commandCounter = commandCounter + 1

    local opts = options or {}
    commands[key] = {
        handler = handler,
        silent = opts.silent or false
    }

    table.insert(commandsRegistry, {
        id = commandCounter,
        key = key,
        handler = handler
    })
    return commandCounter
end

-----------------------------------------------------------------------------
-- Dispatch Command
--   @param key string: Command identifier
--   @param ... any: Arguments to pass to handler
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.Dispatch(key, ...)
    local command = commands[key]
    if not command then
        error("Maestro: Unknown command '" .. key .. "'")
        return
    end

    -- Log command execution to debug window (unless command is silent)
    if not command.silent then
        if AutoLFM.Components.DebugWindow and AutoLFM.Components.DebugWindow.LogCommand then
            AutoLFM.Components.DebugWindow.LogCommand(key, unpack(arg))
        end
    end

    local success, err = pcall(command.handler, unpack(arg))
    if not success then
        if AutoLFM.Components.DebugWindow and AutoLFM.Components.DebugWindow.LogError then
            AutoLFM.Components.DebugWindow.LogError("Command '" .. key .. "' failed: " .. tostring(err))
        end
        error("Maestro: Error executing command '" .. key .. "': " .. tostring(err))
    end
end

--=============================================================================
-- INITIALIZATION SYSTEM
--=============================================================================

-----------------------------------------------------------------------------
-- Register Initialization Handler
--   @param id string: Unique identifier
--   @param handler function: Function to execute on init
--   @return number: Assigned init handler ID
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.RegisterInit(id, handler)
    if initHandlers[id] then
        error("Maestro: Init handler '" .. id .. "' already registered")
        return
    end
    initCounter = initCounter + 1
    initHandlers[id] = handler
    table.insert(initRegistry, {
        id = initCounter,
        key = id,
        handler = handler
    })
    return initCounter
end

-----------------------------------------------------------------------------
-- Run All Initialization Handlers
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.RunInit()
    if isInitialized then
        return
    end

    -- Sort handlers by ID for consistent order
    local sorted = {}
    for id, handler in pairs(initHandlers) do
        table.insert(sorted, { id = id, handler = handler })
    end
    table.sort(sorted, function(a, b) return a.id < b.id end)

    -- Execute handlers
    for _, data in ipairs(sorted) do
        -- Log init handler execution
        if AutoLFM.Components.DebugWindow and AutoLFM.Components.DebugWindow.LogEvent then
            AutoLFM.Components.DebugWindow.LogEvent("INIT_" .. data.id)
        end

        local success, err = pcall(data.handler)
        if not success then
            if AutoLFM.Components.DebugWindow and AutoLFM.Components.DebugWindow.LogError then
                AutoLFM.Components.DebugWindow.LogError("Init handler '" .. data.id .. "' failed: " .. tostring(err))
            end
        end
    end

    isInitialized = true
    -- Only success message goes to chat
    AutoLFM.Core.Common.PrintSuccess("Successfully loaded!")
end

-----------------------------------------------------------------------------
-- Print All Registered Commands (Debug Helper)
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.PrintCommands()
    if AutoLFM.Components.DebugWindow and AutoLFM.Components.DebugWindow.LogInfo then
        AutoLFM.Components.DebugWindow.LogInfo("=== Registered Commands ===")

        local sorted = {}
        for key, _ in pairs(commands) do
            table.insert(sorted, key)
        end
        table.sort(sorted)

        for _, key in ipairs(sorted) do
            AutoLFM.Components.DebugWindow.LogInfo("  " .. key)
        end

        AutoLFM.Components.DebugWindow.LogInfo("Total: " .. table.getn(sorted) .. " commands")
    end
end

-----------------------------------------------------------------------------
-- Check if addon is initialized
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.IsInitialized()
    return isInitialized
end

--=============================================================================
-- REGISTRY LISTING FUNCTIONS
--=============================================================================

-----------------------------------------------------------------------------
-- Get All Registered Commands
--   @return table: Array of {id, key, handler}
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetCommands()
    return commandsRegistry
end

-----------------------------------------------------------------------------
-- Get All Registered Init Handlers
--   @return table: Array of {id, key, handler}
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetInitHandlers()
    return initRegistry
end

-----------------------------------------------------------------------------
-- Print All Registered Commands
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.ListCommands()
    AutoLFM.Core.Common.PrintTitle("Registered Commands (" .. commandCounter .. " total):")
    for i = 1, table.getn(commandsRegistry) do
        local entry = commandsRegistry[i]
        AutoLFM.Core.Common.PrintInfo("[" .. entry.id .. "] " .. entry.key)
    end
end

-----------------------------------------------------------------------------
-- Print All Registered Init Handlers
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.ListInitHandlers()
    AutoLFM.Core.Common.PrintTitle("Registered Init Handlers (" .. initCounter .. " total):")
    for i = 1, table.getn(initRegistry) do
        local entry = initRegistry[i]
        AutoLFM.Core.Common.PrintInfo("[" .. entry.id .. "] " .. entry.key)
    end
end

-----------------------------------------------------------------------------
-- Print All Registered Items (Commands + Init Handlers)
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.ListAll()
    AutoLFM.Core.Maestro.ListCommands()
    AutoLFM.Core.Common.Print(" ")
    AutoLFM.Core.Maestro.ListInitHandlers()
end
