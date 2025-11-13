--=============================================================================
-- AutoLFM: Maestro
--   Central command bus and event system with numeric IDs and metadata
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Core = AutoLFM.Core or {}
AutoLFM.Core.Maestro = AutoLFM.Core.Maestro or {}

--=============================================================================
-- DEBUG MODE
--=============================================================================

AutoLFM.Core.Maestro.DebugMode = false

-----------------------------------------------------------------------------
-- Logging Function (stub - will be implemented by Debug module)
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.Log(category, message, details)
    -- This will be overridden by Debug/DebugWindow.lua if debug mode is enabled
    -- Default: do nothing
end

--=============================================================================
-- REGISTRY TABLES AND COUNTERS
--=============================================================================

AutoLFM.Core.Maestro.CommandRegistry = {}
AutoLFM.Core.Maestro.EventRegistry = {}
AutoLFM.Core.Maestro.CommandKeyToId = {}
AutoLFM.Core.Maestro.EventKeyToId = {}

local nextCommandId = 1
local nextEventId = 1
local nextListenerId = 1

-- ID formatters
local function FormatCommandId(num)
    return "C" .. num
end

local function FormatEventId(num)
    return "E" .. num
end

local function FormatListenerId(num)
    return "L" .. num
end

--=============================================================================
-- METADATA MANAGEMENT
--=============================================================================

-----------------------------------------------------------------------------
-- Register Command Metadata (Internal)
--   @param metadata table: { key, description, handler }
-----------------------------------------------------------------------------
local function RegisterCommandMetadata(metadata)
    if not metadata or not metadata.key or not metadata.handler then
        error("Maestro: RegisterCommandMetadata requires 'key' and 'handler'")
        return
    end

    local numericId = nextCommandId
    local formattedId = FormatCommandId(numericId)
    nextCommandId = nextCommandId + 1

    AutoLFM.Core.Maestro.CommandRegistry[numericId] = {
        id = formattedId,
        key = metadata.key,
        description = metadata.description or "No description",
        handler = metadata.handler
    }

    AutoLFM.Core.Maestro.CommandKeyToId[metadata.key] = numericId
end

-----------------------------------------------------------------------------
-- Register Event Metadata (Internal)
--   @param metadata table: { key, description }
-----------------------------------------------------------------------------
local function RegisterEventMetadata(metadata)
    if not metadata or not metadata.key then
        error("Maestro: RegisterEventMetadata requires 'key'")
        return
    end

    -- Check if already registered
    if AutoLFM.Core.Maestro.EventKeyToId[metadata.key] then
        return
    end

    local numericId = nextEventId
    local formattedId = FormatEventId(numericId)
    nextEventId = nextEventId + 1

    AutoLFM.Core.Maestro.EventRegistry[numericId] = {
        id = formattedId,
        key = metadata.key,
        description = metadata.description or "No description",
        listeners = {}
    }

    AutoLFM.Core.Maestro.EventKeyToId[metadata.key] = numericId
end

-----------------------------------------------------------------------------
-- Register Event Listener with Metadata (Internal)
--   @param eventKey string: Event key identifier
--   @param listener function: Callback function
--   @param metadata table: { key, description } (optional)
-----------------------------------------------------------------------------
local function RegisterEventListenerMetadata(eventKey, listener, metadata)
    if not eventKey or not listener then return end

    -- Ensure event is registered
    if not AutoLFM.Core.Maestro.EventKeyToId[eventKey] then
        RegisterEventMetadata({ key = eventKey })
    end

    local eventId = AutoLFM.Core.Maestro.EventKeyToId[eventKey]
    local numericId = nextListenerId
    local formattedId = FormatListenerId(numericId)
    nextListenerId = nextListenerId + 1

    local listenerData = {
        id = formattedId,
        callback = listener,
        key = (metadata and metadata.key) or ("Listener." .. formattedId),
        description = (metadata and metadata.description) or "No description"
    }

    table.insert(AutoLFM.Core.Maestro.EventRegistry[eventId].listeners, listenerData)
end

--=============================================================================
-- COMMAND BUS
--=============================================================================

-----------------------------------------------------------------------------
-- Register a Command
--   @param metadata table: { key, description, handler }
--
--   Example:
--   AutoLFM.Core.Maestro.RegisterCommand({
--       key = "roles.toggle",
--       description = "Toggle role selection",
--       handler = function(role) ... end
--   })
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.RegisterCommand(metadata)
    if not metadata then return end

    RegisterCommandMetadata(metadata)

    -- Log registration in debug mode
    if AutoLFM.Core.Maestro.DebugMode then
        local numericId = AutoLFM.Core.Maestro.CommandKeyToId[metadata.key]
        local commandData = AutoLFM.Core.Maestro.CommandRegistry[numericId]
        if commandData then
            AutoLFM.Core.Maestro.Log("COMMAND", "Registered [" .. commandData.id .. "]: " .. metadata.key, metadata.description or "")
        end
    end
end

-----------------------------------------------------------------------------
-- Dispatch a Command
--   @param commandKey string: Command key identifier
--   @param ... any: Arguments to pass to the command handler
--   @return any: Return value from handler
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.Dispatch(commandKey, ...)
    if not commandKey then return end

    local commandId = AutoLFM.Core.Maestro.CommandKeyToId[commandKey]
    if not commandId then
        error("Maestro: Unknown command '" .. commandKey .. "'")
        return
    end

    local commandMeta = AutoLFM.Core.Maestro.CommandRegistry[commandId]

    -- Execute handler (Lua 5.0: arg table is available)
    local success, result = pcall(commandMeta.handler, unpack(arg))

    if not success then
        error("Maestro: Error executing command '" .. commandKey .. "': " .. tostring(result))
        return
    end

    return result
end

-----------------------------------------------------------------------------
-- Check if a command is registered
--   @param commandKey string: Command key identifier
--   @return boolean: true if command exists
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.HasCommand(commandKey)
    if not commandKey then return false end
    return AutoLFM.Core.Maestro.CommandKeyToId[commandKey] ~= nil
end

--=============================================================================
-- EVENT BUS
--=============================================================================

-----------------------------------------------------------------------------
-- Register Event Listener
--   @param eventKey string: Event key identifier
--   @param listener function: Callback function
--   @param metadata table: { key, description } (optional)
--
--   Example:
--   AutoLFM.Core.Maestro.On("Roles.Toggled", function(role, isSelected)
--       -- Handle event
--   end, {
--       key = "update_role_button",
--       description = "Updates role button visual state"
--   })
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.On(eventKey, listener, metadata)
    if not eventKey or not listener then return end

    RegisterEventListenerMetadata(eventKey, listener, metadata)

    -- Log registration in debug mode
    if AutoLFM.Core.Maestro.DebugMode then
        local listenerKey = (metadata and metadata.key) or "anonymous"
        AutoLFM.Core.Maestro.Log("EVENT", "Listener registered: " .. eventKey, listenerKey)
    end
end

-----------------------------------------------------------------------------
-- Emit an Event
--   @param eventKey string: Event key identifier
--   @param ... any: Arguments to pass to listeners
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.Emit(eventKey, ...)
    if not eventKey then return end

    -- Ensure event is registered
    if not AutoLFM.Core.Maestro.EventKeyToId[eventKey] then
        RegisterEventMetadata({ key = eventKey })
    end

    local eventId = AutoLFM.Core.Maestro.EventKeyToId[eventKey]
    local eventMeta = AutoLFM.Core.Maestro.EventRegistry[eventId]

    -- Call all listeners (Lua 5.0: arg table is available)
    if eventMeta and eventMeta.listeners then
        for i, listenerData in ipairs(eventMeta.listeners) do
            if listenerData and listenerData.callback then
                local success, err = pcall(listenerData.callback, unpack(arg))
                if not success then
                    error("Maestro: Error in listener '" .. (listenerData.key or "unknown") .. "' for event '" .. eventKey .. "': " .. tostring(err))
                end
            end
        end
    end
end

-----------------------------------------------------------------------------
-- Check if an event has listeners
--   @param eventKey string: Event key identifier
--   @return boolean: true if event has at least one listener
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.HasListeners(eventKey)
    if not eventKey then return false end

    local eventId = AutoLFM.Core.Maestro.EventKeyToId[eventKey]
    if not eventId then return false end

    local eventMeta = AutoLFM.Core.Maestro.EventRegistry[eventId]
    return eventMeta ~= nil and eventMeta.listeners and table.getn(eventMeta.listeners) > 0
end

-----------------------------------------------------------------------------
-- Get Listener Count for Event
--   @param eventKey string: Event key identifier
--   @return number: Number of listeners
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetListenerCount(eventKey)
    if not eventKey then return 0 end

    local eventId = AutoLFM.Core.Maestro.EventKeyToId[eventKey]
    if not eventId then return 0 end

    local eventMeta = AutoLFM.Core.Maestro.EventRegistry[eventId]
    if not eventMeta or not eventMeta.listeners then return 0 end
    return table.getn(eventMeta.listeners)
end

--=============================================================================
-- INTROSPECTION (For Debug Tools)
--=============================================================================

-----------------------------------------------------------------------------
-- Get Command Metadata by Key
--   @param commandKey string: Command key identifier
--   @return table: Command metadata or nil
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetCommandMetadata(commandKey)
    if not commandKey then return nil end

    local commandId = AutoLFM.Core.Maestro.CommandKeyToId[commandKey]
    if not commandId then return nil end

    return AutoLFM.Core.Maestro.CommandRegistry[commandId]
end

-----------------------------------------------------------------------------
-- Get Command Metadata by ID
--   @param commandId number: Command numeric ID
--   @return table: Command metadata or nil
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetCommandMetadataById(commandId)
    if not commandId then return nil end
    return AutoLFM.Core.Maestro.CommandRegistry[commandId]
end

-----------------------------------------------------------------------------
-- Get Event Metadata by Key
--   @param eventKey string: Event key identifier
--   @return table: Event metadata or nil
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetEventMetadata(eventKey)
    if not eventKey then return nil end

    local eventId = AutoLFM.Core.Maestro.EventKeyToId[eventKey]
    if not eventId then return nil end

    return AutoLFM.Core.Maestro.EventRegistry[eventId]
end

-----------------------------------------------------------------------------
-- Get Event Metadata by ID
--   @param eventId number: Event numeric ID
--   @return table: Event metadata or nil
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetEventMetadataById(eventId)
    if not eventId then return nil end
    return AutoLFM.Core.Maestro.EventRegistry[eventId]
end

-----------------------------------------------------------------------------
-- Get All Commands (sorted by ID)
--   @return table: All registered commands
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetAllCommands()
    local commands = {}
    for id, metadata in pairs(AutoLFM.Core.Maestro.CommandRegistry) do
        if metadata then
            table.insert(commands, {
                id = id,
                key = metadata.key,
                description = metadata.description
            })
        end
    end
    table.sort(commands, function(a, b) return a.id < b.id end)
    return commands
end

-----------------------------------------------------------------------------
-- Get All Events (sorted by ID)
--   @return table: All registered events
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetAllEvents()
    local events = {}
    for id, metadata in pairs(AutoLFM.Core.Maestro.EventRegistry) do
        if metadata then
            table.insert(events, {
                id = id,
                key = metadata.key,
                description = metadata.description,
                listenerCount = (metadata.listeners and table.getn(metadata.listeners)) or 0
            })
        end
    end
    table.sort(events, function(a, b) return a.id < b.id end)
    return events
end

-----------------------------------------------------------------------------
-- Get Event Listeners
--   @param eventKey string: Event key identifier
--   @return table: List of listeners with metadata
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetEventListeners(eventKey)
    if not eventKey then return {} end

    local eventId = AutoLFM.Core.Maestro.EventKeyToId[eventKey]
    if not eventId then return {} end

    local event = AutoLFM.Core.Maestro.EventRegistry[eventId]
    if not event or not event.listeners then return {} end

    local listeners = {}
    for i, listenerData in ipairs(event.listeners) do
        if listenerData then
            table.insert(listeners, {
                id = listenerData.id,
                index = i,
                key = listenerData.key,
                description = listenerData.description
            })
        end
    end
    return listeners
end

-----------------------------------------------------------------------------
-- Get Statistics
--   @return table: Registry statistics
-----------------------------------------------------------------------------
function AutoLFM.Core.Maestro.GetStats()
    local commandCount = 0
    local eventCount = 0
    local listenerCount = 0

    for _ in pairs(AutoLFM.Core.Maestro.CommandRegistry) do
        commandCount = commandCount + 1
    end

    for _, event in pairs(AutoLFM.Core.Maestro.EventRegistry) do
        eventCount = eventCount + 1
        if event.listeners then
            listenerCount = listenerCount + table.getn(event.listeners)
        end
    end

    return {
        commands = commandCount,
        events = eventCount,
        listeners = listenerCount,
        nextCommandId = nextCommandId,
        nextEventId = nextEventId,
        nextListenerId = nextListenerId
    }
end
