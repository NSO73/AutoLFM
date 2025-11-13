--=============================================================================
-- AutoLFM: Constants
--   Shared constants used across the addon
--=============================================================================

AutoLFM = AutoLFM or {}
AutoLFM.Core = AutoLFM.Core or {}
AutoLFM.Core.Constants = AutoLFM.Core.Constants or {}

--=============================================================================
-- PATHS
--=============================================================================

AutoLFM.Core.Constants.TEXTURE_PATH = "Interface\\AddOns\\AutoLFM3\\UI\\Textures\\"
AutoLFM.Core.Constants.SOUND_PATH = "Interface\\AddOns\\AutoLFM3\\UI\\Sounds\\"

--=============================================================================
-- SOUNDS
--=============================================================================

AutoLFM.Core.Constants.SOUNDS = {
    START = "Start.ogg",
    STOP = "Stop.ogg",
    FULL = "Full.ogg"
}

--=============================================================================
-- COLORS
--=============================================================================

AutoLFM.Core.Constants.COLORS = {
    GOLD = {id = 1, name = "GOLD", priority = 99, r = 1.0, g = 0.82, b = 0.0, hex = "FFD100"},
    WHITE = {id = 2, name = "WHITE", priority = 99, r = 1.0, g = 1.0, b = 1.0, hex = "FFFFFF"},
    GRAY = {id = 3, name = "GRAY", priority = 5, r = 0.5, g = 0.5, b = 0.5, hex = "808080"},
    GREEN = {id = 4, name = "GREEN", priority = 1, r = 0.25, g = 0.75, b = 0.25, hex = "40BF40"},
    YELLOW = {id = 5, name = "YELLOW", priority = 2, r = 1.0, g = 1.0, b = 0.0, hex = "FFFF00"},
    ORANGE = {id = 6, name = "ORANGE", priority = 3, r = 1.0, g = 0.5, b = 0.25, hex = "FF8040"},
    RED = {id = 7, name = "RED", priority = 4, r = 1.0, g = 0.0, b = 0.0, hex = "FF0000"},
    BLUE = {id = 8, name = "BLUE", priority = 99, r = 0.0, g = 0.5, b = 1.0, hex = "0080FF"}
}

AutoLFM.Core.Constants.CHAT_PREFIX = "|cff808080[|r|cffffffffAuto|r|cff0070ddL|r|cffffffffF|r|cffff0000M|r|cff808080]|r "

--=============================================================================
-- DUNGEONS
--=============================================================================

AutoLFM.Core.Constants.DUNGEONS = {
    {name = "Ragefire Chasm", tag = "RFC", levelMin = 13, levelMax = 19},
    {name = "Wailing Caverns", tag = "WC", levelMin = 16, levelMax = 25},
    {name = "The Deadmines", tag = "DM", levelMin = 16, levelMax = 24},
    {name = "Shadowfang Keep", tag = "SFK", levelMin = 20, levelMax = 28},
    {name = "Blackfathom Deeps", tag = "BFD", levelMin = 22, levelMax = 31},
    {name = "The Stockade", tag = "Stockade", levelMin = 23, levelMax = 32},
    {name = "Dragonmaw Retreat", tag = "DR", levelMin = 26, levelMax = 35},
    {name = "Gnomeregan", tag = "Gnomeregan", levelMin = 28, levelMax = 37},
    {name = "Razorfen Kraul", tag = "RFK", levelMin = 29, levelMax = 36},
    {name = "Scarlet Monastery Graveyard", tag = "SM Grav", levelMin = 30, levelMax = 37},
    {name = "Scarlet Monastery Library", tag = "SM Lib", levelMin = 32, levelMax = 40},
    {name = "Stormwrought Castle", tag = "SC", levelMin = 32, levelMax = 40},
    {name = "The Crescent Grove", tag = "Crescent", levelMin = 33, levelMax = 39},
    {name = "Scarlet Monastery Armory", tag = "SM Armo", levelMin = 34, levelMax = 42},
    {name = "Razorfen Downs", tag = "RFD", levelMin = 35, levelMax = 44},
    {name = "Stormwrought Descent", tag = "SD", levelMin = 35, levelMax = 44},
    {name = "Scarlet Monastery Cathedral", tag = "SM Cath", levelMin = 35, levelMax = 45},
    {name = "Uldaman", tag = "Ulda", levelMin = 41, levelMax = 50},
    {name = "Zul'Farrak", tag = "ZF", levelMin = 42, levelMax = 51},
    {name = "Gilneas City", tag = "Gilneas", levelMin = 43, levelMax = 52},
    {name = "Maraudon Orange", tag = "Maraudon Orange", levelMin = 43, levelMax = 51},
    {name = "Maraudon Purple", tag = "Maraudon Purple", levelMin = 45, levelMax = 52},
    {name = "Maraudon Princess", tag = "Maraudon Princess", levelMin = 46, levelMax = 54},
    {name = "The Sunken Temple", tag = "ST", levelMin = 49, levelMax = 58},
    {name = "Blackrock Depths Arena", tag = "BRD Arena", levelMin = 50, levelMax = 60},
    {name = "Halteforge Quarry", tag = "HQ", levelMin = 51, levelMax = 60},
    {name = "Blackrock Depths Emperor", tag = "BRD Emperor", levelMin = 54, levelMax = 60},
    {name = "Blackrock Depths", tag = "BRD", levelMin = 54, levelMax = 60},
    {name = "Lower Blackrock Spire", tag = "LBRS", levelMin = 55, levelMax = 60},
    {name = "Dire Maul East", tag = "DM East", levelMin = 55, levelMax = 60},
    {name = "Dire Maul North", tag = "DM N", levelMin = 57, levelMax = 60},
    {name = "Dire Maul Tribute", tag = "DM Tribute", levelMin = 57, levelMax = 60},
    {name = "Dire Maul West", tag = "DM W", levelMin = 57, levelMax = 60},
    {name = "Stratholme Live 5", tag = "Strat Live 5", levelMin = 58, levelMax = 60},
    {name = "Scholomance 5", tag = "Scholo 5", levelMin = 58, levelMax = 60},
    {name = "Stratholme UD 5", tag = "Strat UD 5", levelMin = 58, levelMax = 60},
    {name = "Stormwind Vault", tag = "SWV", levelMin = 60, levelMax = 60},
    {name = "Karazhan Crypt", tag = "Kara Crypt", levelMin = 60, levelMax = 60},
    {name = "Caverns of Time. Black Morass", tag = "Black Morass", levelMin = 60, levelMax = 60}
}

-- Level-based Priority Thresholds for dungeon colors
AutoLFM.Core.Constants.GREEN_THRESHOLDS = {
    [1] = 4,  -- Level 1-9
    [2] = 5,  -- Level 10-19
    [3] = 6,  -- Level 20-29
    [4] = 7,  -- Level 30-39
    [5] = 8   -- Level 40+
}

--=============================================================================
-- RAIDS
--=============================================================================

AutoLFM.Core.Constants.RAIDS = {
    {name = "Scholomance 10", tag = "Scholo 10", sizeMin = 10, sizeMax = 10},
    {name = "Stratholme Live 10", tag = "Strat Live 10", sizeMin = 10, sizeMax = 10},
    {name = "Stratholme UD 10", tag = "Strat UD 10", sizeMin = 10, sizeMax = 10},
    {name = "Upper Blackrock Spire", tag = "UBRS", sizeMin = 10, sizeMax = 10},
    {name = "Zul'Gurub", tag = "ZG", sizeMin = 12, sizeMax = 20},
    {name = "Ruins of Ahn'Qiraj", tag = "AQ20", sizeMin = 12, sizeMax = 20},
    {name = "Molten Core", tag = "MC", sizeMin = 20, sizeMax = 40},
    {name = "Onyxia's Lair", tag = "Ony", sizeMin = 15, sizeMax = 40},
    {name = "Lower Karazhan Halls", tag = "Kara10", sizeMin = 10, sizeMax = 10},
    {name = "Blackwing Lair", tag = "BWL", sizeMin = 20, sizeMax = 40},
    {name = "Emerald Sanctum", tag = "ES", sizeMin = 30, sizeMax = 40},
    {name = "Temple of Ahn'Qiraj", tag = "AQ40", sizeMin = 20, sizeMax = 40},
    {name = "Naxxramas", tag = "Naxx", sizeMin = 30, sizeMax = 40}
}

--=============================================================================
-- CHANNELS
--=============================================================================

AutoLFM.Core.Constants.CHANNELS = {
    {name = "LookingForGroup", display = "LFG"},
    {name = "World", display = "World"},
    {name = "Hardcore", display = "Hardcore"}
}

--=============================================================================
-- ROLES
--=============================================================================

AutoLFM.Core.Constants.ROLES = {
    {id = "tank", name = "Tank", display = "Tank"},
    {id = "heal", name = "Heal", display = "Heal"},
    {id = "dps", name = "DPS", display = "DPS"}
}

--=============================================================================
-- TABS
--=============================================================================

AutoLFM.Core.Constants.BOTTOM_TAB_MAP = {
    dungeons = 1,
    raids = 2,
    quests = 3,
    broadcasts = 4,
    [1] = "dungeons",
    [2] = "raids",
    [3] = "quests",
    [4] = "broadcasts"
}

AutoLFM.Core.Constants.LINE_TAB_MAP = {
    presets = 1,
    autoinvite = 5,
    options = 4,
    [1] = "presets",
    [5] = "autoinvite",
    [4] = "options"
}

--=============================================================================
-- SELECTION CONSTRAINTS
--=============================================================================

AutoLFM.Core.Constants.MAX_DUNGEONS = 4
AutoLFM.Core.Constants.MAX_RAIDS = 1
AutoLFM.Core.Constants.MAX_CHECKBOX_SEARCH_ITERATIONS = 50

--=============================================================================
-- GROUP SIZES
--=============================================================================

AutoLFM.Core.Constants.GROUP_SIZE_DUNGEON = 5
AutoLFM.Core.Constants.GROUP_SIZE_RAID = 40

--=============================================================================
-- BROADCAST SETTINGS
--=============================================================================

AutoLFM.Core.Constants.INTERVAL_MIN = 30
AutoLFM.Core.Constants.INTERVAL_MAX = 120
AutoLFM.Core.Constants.INTERVAL_STEP = 10
AutoLFM.Core.Constants.INTERVAL_DEFAULT = 60
AutoLFM.Core.Constants.UPDATE_THROTTLE = 0.1

--=============================================================================
-- UI DIMENSIONS
--=============================================================================

AutoLFM.Core.Constants.ROW_HEIGHT = 20
AutoLFM.Core.Constants.CHECKBOX_SIZE = 20
AutoLFM.Core.Constants.CONTENT_DEFAULT_HEIGHT = 230
AutoLFM.Core.Constants.MESSAGE_PREVIEW_WIDTH = 330
AutoLFM.Core.Constants.MESSAGE_PREVIEW_HEIGHT = 30
AutoLFM.Core.Constants.MESSAGE_PREVIEW_TEXT_WIDTH = 290
AutoLFM.Core.Constants.MESSAGE_PREVIEW_ICON_SIZE = 20

--=============================================================================
-- MESSAGE TEMPLATES
--=============================================================================

AutoLFM.Core.Constants.MESSAGE_VARIABLES = {
    ["_CONS_"] = "Dungeon/Raid names",
    ["_MISS_"] = "Number of missing players",
    ["_CUR_"] = "Current group size",
    ["_TAR_"] = "Target group size",
    ["_ROL_"] = "Required roles"
}

AutoLFM.Core.Constants.DEFAULT_MESSAGE_TEMPLATES = {
    dungeon = "LF_MISS_M for _CONS_ _ROL_",
    raid = "_CONS_ LF_MISS_M _ROL_ _CUR_/_TAR_"
}

--=============================================================================
-- LINK FORMATS
--=============================================================================

AutoLFM.Core.Constants.LINK_FORMATS = {
    QUEST = "|c%s|Hquest:%d:%d|h[%s]|h|r"
}

--=============================================================================
-- DEFAULT SETTINGS
--=============================================================================

AutoLFM.Core.Constants.DEFAULTS = {
    BROADCAST_INTERVAL = 60,
    DARK_MODE = nil,
    DEFAULT_PANEL = "dungeons",
    DUNGEON_FILTERS = {
        GRAY = true,
        GREEN = true,
        YELLOW = true,
        ORANGE = true,
        RED = true
    },
    MESSAGE_TEMPLATE_DUNGEON = "LF_MISS_M for _CONS_ _ROL_",
    MESSAGE_TEMPLATE_RAID = "_CONS_ LF_MISS_M _ROL_ _CUR_/_TAR_",
    MINIMAP_HIDDEN = false,
    MINIMAP_POS = nil,
    PRESETS_CONDENSED = false,
    SELECTED_CHANNELS = {},
    WELCOME_SHOWN = false
}
