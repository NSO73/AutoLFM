---------------------------------------------------------------------------------
--                      Turtle_Minimal.lua - Interface Pure                   --
---------------------------------------------------------------------------------

-- Configuration consolidée
local CONFIG = {
  -- Dimensions principales
  MAIN_FRAME = {384, 512},
  ROLE_SIZE = {54, 54},
  BUTTON_SIZE = {104, 21},
  ENTRY_HEIGHT = 20,
  CHECKBOX_SIZE = {16, 16},
  CHECKBOX_SIZE_LARGE = {18, 18},
  ICON_SIZE = {16, 16},
  PORTRAIT_SIZE = {64, 64},
  
  -- Positions
  FRAME_POSITION = {0, -104},
  SCROLL_POSITION = {25, -158},
  TAB_POSITIONS = {
    {20, 45}, {110, 45}, {250, 45}
  },
  
  -- Tailles de scroll
  SCROLL_SIZES = {
    DUNGEON = {295, 252},
    RAID = {295, 220}
  },
  
  -- Slider de raid
  SLIDER = {
    SIZE = {295, 30},
    EDITBOX_SIZE = {25, 20},
    SLIDER_SIZE = {120, 17},
    MIN_VALUE = 10,
    MAX_VALUE = 40,
    DEFAULT_VALUE = 25
  },
  
  -- More tab
  MORE_TAB = {
    SIZE = {295, 250},
    POSITION = {25, -170},
    INTERVAL_SLIDER_SIZE = {140, 17},
    INTERVAL_MIN = 40,
    INTERVAL_MAX = 120,
    INTERVAL_DEFAULT = 80,
    CHANNEL_SPACING = 20
  }
}

-- Textures
local TEXTURES = {
  PORTRAIT = "Interface\\AddOns\\AutoLFM\\icon\\portrait",
  FRAME = "Interface\\FrameXML\\LFT\\images\\ui-lfg-frame",
  BACKGROUND = "Interface\\FrameXML\\LFT\\images\\ui-lfg-background-dungeonwall",
  TAB_ACTIVE = "Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab",
  TAB_INACTIVE = "Interface\\PaperDollInfoFrame\\UI-Character-InactiveTab",
  TAB_HIGHLIGHT = "Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight",
  SLIDER_THUMB = "Interface\\Buttons\\UI-SliderBar-Button-Horizontal"
}

-- Icônes du More tab
local MORE_ICONS = {
  INTERVAL = "Interface\\GossipFrame\\HealerGossipIcon",
  CHANNELS = "Interface\\GossipFrame\\GossipGossipIcon",
  DURATION = "Interface\\GossipFrame\\VendorGossipIcon",
  SENT = "Interface\\GossipFrame\\TrainerGossipIcon",
  NEXT = "Interface\\GossipFrame\\TaxiGossipIcon"
}

-- Couleurs
local COLORS = {
  TAB_ACTIVE = {0.8, 0.8, 0.8},
  TAB_INACTIVE = {1, 0.82, 0},
  ROLE_BG_ALPHA = 0.6,
  WHITE = {1, 1, 1},
  SELECTION_HIGHLIGHT = {0, 1, 0, 0.3},
  TRANSPARENT = {0, 0, 0, 0},
  EDITBOX_BG = {0, 0, 0, 0.5},
  EDITBOX_BORDER = {0.4, 0.4, 0.4, 1},
  
  LEVEL_COLORS = {
    TRIVIAL = {0.5, 0.5, 0.5},
    EASY = {0.0, 1.0, 0.0},
    NORMAL = {1.0, 1.0, 0.0},
    DIFFICULT = {1.0, 0.5, 0.0},
    VERY_DIFFICULT = {1.0, 0.0, 0.0}
  }
}

-- Backdrops standardisés
local BACKDROPS = {
  DIALOG = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
    tile = true, 
    tileSize = 32, 
    edgeSize = 8, 
    insets = {left = 4, right = 4, top = 4, bottom = 4}
  },
  
  TOOLTIP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = {left = 5, right = 5, top = 5, bottom = 5}
  },
  
  SLIDER = {
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background", 
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border", 
    tile = true, 
    tileSize = 8, 
    edgeSize = 8, 
    insets = {left = 3, right = 3, top = 6, bottom = 6}
  },
  
  ENTRY_SELECTION = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = nil,
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
  },
  
  SIMPLE_TILE = {
    tile = true,
    tileSize = 32,
    edgeSize = 8,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
  }
}

-- Données des rôles
local ROLE_DATA = {
  {
    name = "Tank",
    coord = {0.2968, 0.5937, 0, 0.5937},
    texture = "Interface\\FrameXML\\LFT\\images\\tank2",
    backgroundTexture = "Interface\\FrameXML\\LFT\\images\\ui-lfg-role-background"
  },
  {
    name = "Heal",
    coord = {0, 0.2968, 0, 0.5937},
    texture = "Interface\\FrameXML\\LFT\\images\\healer2",
    backgroundTexture = "Interface\\FrameXML\\LFT\\images\\ui-lfg-role-background"
  },
  {
    name = "Dps",
    coord = {0.5937, 0.8906, 0, 0.5937},
    texture = "Interface\\FrameXML\\LFT\\images\\damage2",
    backgroundTexture = "Interface\\FrameXML\\LFT\\images\\ui-lfg-role-background"
  }
}

-- Canaux de diffusion
local BROADCAST_CHANNELS = {"LookingForGroup", "World", "General"}

---------------------------------------------------------------------------------
--                           Variables d'état                                  --
---------------------------------------------------------------------------------

local showingRaids = false
local currentScrollContent = nil
local selectedRaid = nil
local CurrentTab = 1
local tabs = {}
local roleButtons = {}
local roleChecks = {}
local sliderValue = CONFIG.SLIDER.DEFAULT_VALUE

-- Cache des données d'instance
local instanceDataCache = {
  dungeons = nil,
  raids = nil,
  lastUpdate = 0,
  cacheTimeout = 5
}

-- Références des composants UI
local uiComponents = {
  mainFrame = nil,
  raidSizeControls = nil,
  moreTabContent = nil
}

-- Frames pour gestion des backdrops
local donjonClickableFrames = {}
local raidClickableFrames = {}

---------------------------------------------------------------------------------
--                    Fonctions utilitaires                                    --
---------------------------------------------------------------------------------

local function setSize(obj, w, h)
  if not obj or not w or not h then return end
  obj:SetWidth(w)
  obj:SetHeight(h)
end

local function validateInstanceData()
  local hasDonjons = donjons and type(donjons) == "table" and table.getn(donjons) > 0
  local hasRaids = raids and type(raids) == "table" and table.getn(raids) > 0
  
  if not hasDonjons and not hasRaids then
    DEFAULT_CHAT_FRAME:AddMessage("AutoLFM Warning: No instance data found. Make sure Variables.lua is loaded.")
    return false
  end
  
  return true
end

local function getLevelColor(minLevel, maxLevel)
  local playerLevel = UnitLevel("player")
  if not playerLevel or playerLevel == 0 then
    return COLORS.LEVEL_COLORS.NORMAL
  end
  
  local instanceLevel = math.floor((minLevel + maxLevel) / 2)
  local levelDiff = instanceLevel - playerLevel
  
  if levelDiff <= -10 then
    return COLORS.LEVEL_COLORS.TRIVIAL
  elseif levelDiff <= -4 then
    return COLORS.LEVEL_COLORS.EASY
  elseif levelDiff <= 2 then
    return COLORS.LEVEL_COLORS.NORMAL
  elseif levelDiff <= 5 then
    return COLORS.LEVEL_COLORS.DIFFICULT
  else
    return COLORS.LEVEL_COLORS.VERY_DIFFICULT
  end
end

local function getInstanceData()
  local currentTime = GetTime()
  
  if instanceDataCache.dungeons and instanceDataCache.raids and 
     (currentTime - instanceDataCache.lastUpdate) < instanceDataCache.cacheTimeout then
    return instanceDataCache.dungeons, instanceDataCache.raids
  end
  
  local dungeonData = donjons or {}
  local raidData = raids or {}
  
  instanceDataCache.dungeons = dungeonData
  instanceDataCache.raids = raidData
  instanceDataCache.lastUpdate = currentTime
  
  return dungeonData, raidData
end

function ClearAllBackdrops(frameList)
  for _, frame in ipairs(frameList) do
    if frame and frame.SetBackdropColor then
      frame:SetBackdropColor(unpack(COLORS.TRANSPARENT))
    end
  end
end

---------------------------------------------------------------------------------
--                    Création d'interface - Frame Principal                   --
---------------------------------------------------------------------------------

local function createMainFrame()
  local frame = CreateFrame("Frame", "AutoLFMTurtleFrame", UIParent)
  setSize(frame, CONFIG.MAIN_FRAME[1], CONFIG.MAIN_FRAME[2])
  frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", CONFIG.FRAME_POSITION[1], CONFIG.FRAME_POSITION[2])
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  
  frame:SetScript("OnDragStart", function() 
    if this and this.StartMoving then
      this:StartMoving() 
    end
  end)
  frame:SetScript("OnDragStop", function() 
    if this and this.StopMovingOrSizing then
      this:StopMovingOrSizing() 
    end
  end)
  frame:Hide()
  
  uiComponents.mainFrame = frame
  return frame
end

local function createFrameElements(frame)
  local portrait = frame:CreateTexture(nil, "BACKGROUND")
  portrait:SetTexture(TEXTURES.PORTRAIT)
  setSize(portrait, CONFIG.PORTRAIT_SIZE[1], CONFIG.PORTRAIT_SIZE[2])
  portrait:SetPoint("TOPLEFT", 7, -6)

  local title = frame:CreateFontString("AutoLFMTurtleFrameTitle", "OVERLAY", "GameFontNormal")
  title:SetText("AutoLFM")
  title:SetPoint("TOP", 0, -18)

  local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -27, -8)
  closeBtn:SetScript("OnClick", function() frame:Hide() end)

  local frameTexture = frame:CreateTexture(nil, "ARTWORK")
  frameTexture:SetTexture(TEXTURES.FRAME)
  setSize(frameTexture, 512, 512)
  frameTexture:SetPoint("TOPLEFT", frame, "TOPLEFT")

  local bgWall = frame:CreateTexture(nil, "BACKGROUND")
  bgWall:SetTexture(TEXTURES.BACKGROUND)
  setSize(bgWall, 512, 256)
  bgWall:SetPoint("TOP", 85, -155)
end

local function createEditBox(parent)
  local frame = CreateFrame("Frame", "AutoLFMTurtleFrameEditBox", parent)
  setSize(frame, 330, 30)
  frame:SetPoint("TOP", parent, "TOP", -10, -125)
  
  frame:SetBackdrop(BACKDROPS.TOOLTIP)
  frame:SetBackdropColor(unpack(COLORS.EDITBOX_BG))
  frame:SetBackdropBorderColor(unpack(COLORS.EDITBOX_BORDER))
  
  local placeholder = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  placeholder:SetText("DynamicMessage")
  placeholder:SetPoint("CENTER", frame, "CENTER", 0, 0)
  placeholder:SetTextColor(unpack(COLORS.WHITE))
  
  return frame
end

local function createRaidSizeControls(parent)
  local sliderBg = CreateFrame("Frame", nil, parent)
  setSize(sliderBg, CONFIG.SLIDER.SIZE[1], CONFIG.SLIDER.SIZE[2])
  sliderBg:SetPoint("BOTTOM", parent, "BOTTOM", -20, 105)
  sliderBg:SetBackdrop(BACKDROPS.DIALOG)
  sliderBg:Hide()
  
  local label = sliderBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetText("Group Size:")
  label:SetPoint("LEFT", sliderBg, "LEFT", 10, 0)
  
  local sizeEditBox = CreateFrame("EditBox", "AutoLFMTurtleFrameSizeEditBox", sliderBg, "InputBoxTemplate")
  setSize(sizeEditBox, CONFIG.SLIDER.EDITBOX_SIZE[1], CONFIG.SLIDER.EDITBOX_SIZE[2])
  sizeEditBox:SetPoint("LEFT", label, "RIGHT", 25, 0)
  sizeEditBox:SetAutoFocus(false)
  sizeEditBox:SetMaxLetters(2)
  sizeEditBox:SetText(tostring(CONFIG.SLIDER.DEFAULT_VALUE))
  
  local slider = CreateFrame("Slider", "AutoLFMTurtleFrameRaidSizeSlider", sliderBg)
  setSize(slider, CONFIG.SLIDER.SLIDER_SIZE[1], CONFIG.SLIDER.SLIDER_SIZE[2])
  slider:SetPoint("LEFT", sizeEditBox, "RIGHT", 20, 0)
  slider:SetMinMaxValues(CONFIG.SLIDER.MIN_VALUE, CONFIG.SLIDER.MAX_VALUE)
  slider:SetValue(CONFIG.SLIDER.DEFAULT_VALUE)
  slider:SetValueStep(1)
  slider:SetOrientation("HORIZONTAL")
  slider:SetThumbTexture(TEXTURES.SLIDER_THUMB)
  slider:SetBackdrop(BACKDROPS.SLIDER)
  
  slider:SetScript("OnValueChanged", function()
    local value = slider:GetValue()
    sizeEditBox:SetText(tostring(value))
    sliderValue = value
  end)
  
  sizeEditBox:SetScript("OnTextChanged", function()
    local value = tonumber(sizeEditBox:GetText())
    if value and value >= CONFIG.SLIDER.MIN_VALUE and value <= CONFIG.SLIDER.MAX_VALUE then
      slider:SetValue(value)
    end
  end)
  
  local controls = {
    background = sliderBg,
    label = label,
    editBox = sizeEditBox,
    slider = slider
  }
  
  uiComponents.raidSizeControls = controls
  return controls
end

local function createScrollFrame(parent)
  local scrollFrame = CreateFrame("ScrollFrame", "AutoLFMTurtleFrameInstancesList", parent, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONFIG.SCROLL_POSITION[1], CONFIG.SCROLL_POSITION[2])
  scrollFrame:SetFrameLevel(parent:GetFrameLevel() + 1)
  
  return scrollFrame
end

local function updateScrollFrameSize(scrollFrame)
  if not scrollFrame then return end
  
  local size = showingRaids and CONFIG.SCROLL_SIZES.RAID or CONFIG.SCROLL_SIZES.DUNGEON
  setSize(scrollFrame, size[1], size[2])
end

---------------------------------------------------------------------------------
--                    Gestion des listes d'instances                           --
---------------------------------------------------------------------------------

local function createInstanceEntry(parent, instance, index, isRaid)
  local entry = CreateFrame("Frame", nil, parent)
  setSize(entry, 295, CONFIG.ENTRY_HEIGHT)
  entry:SetPoint("TOPLEFT", 0, -(index-1)*CONFIG.ENTRY_HEIGHT)
  
  entry:SetBackdrop(BACKDROPS.ENTRY_SELECTION)
  entry:SetBackdropColor(unpack(COLORS.TRANSPARENT))
  
  local check = CreateFrame("CheckButton", nil, entry, "OptionsCheckButtonTemplate")
  setSize(check, CONFIG.CHECKBOX_SIZE_LARGE[1], CONFIG.CHECKBOX_SIZE_LARGE[2])
  check:SetPoint("TOPLEFT", entry, "TOPLEFT")
  
  check.instanceData = instance
  check.isRaid = isRaid
  check.entry = entry
  
  check:SetScript("OnClick", function()
    local isChecked = check:GetChecked()
    
    if isRaid then
      ClearAllBackdrops(raidClickableFrames)
      
      if isChecked then
        selectedRaid = instance.abrev
        entry:SetBackdropColor(unpack(COLORS.SELECTION_HIGHLIGHT))
        
        if uiComponents.raidSizeControls then
          local controls = uiComponents.raidSizeControls
          local slider = controls.slider
          local editBox = controls.editBox
          
          if slider and editBox and instance.size_min and instance.size_max then
            slider:SetMinMaxValues(instance.size_min, instance.size_max)
            slider:SetValue(instance.size_min)
            editBox:SetText(tostring(instance.size_min))
            sliderValue = instance.size_min
          end
        end
        
        local children = {parent:GetChildren()}
        for _, child in ipairs(children) do
          local childFrames = {child:GetChildren()}
          for _, childFrame in ipairs(childFrames) do
            if childFrame ~= check and childFrame.GetChecked then
              childFrame:SetChecked(nil)
            end
          end
        end
      else
        selectedRaid = nil
        entry:SetBackdropColor(unpack(COLORS.TRANSPARENT))
      end
    else
      if isChecked then
        entry:SetBackdropColor(unpack(COLORS.SELECTION_HIGHLIGHT))
      else
        entry:SetBackdropColor(unpack(COLORS.TRANSPARENT))
      end
    end
  end)
  
  local name = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  name:SetText(instance.nom or instance.name or "Unknown")
  name:SetPoint("LEFT", entry, "LEFT", 20, 0)
  
  if not isRaid then
    local lvlMin = instance.lvl_min or 0
    local lvlMax = instance.lvl_max or 0
    local color = getLevelColor(lvlMin, lvlMax)
    name:SetTextColor(color[1], color[2], color[3])
  end
  
  local info = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  if isRaid then
    local sizeMin = instance.size_min or 0
    local sizeMax = instance.size_max or 0
    if sizeMin == sizeMax then
      info:SetText(tostring(sizeMin))
    else
      info:SetText(sizeMin .. "-" .. sizeMax)
    end
    info:SetTextColor(unpack(COLORS.WHITE))
  else
    local lvlMin = instance.lvl_min or 0
    local lvlMax = instance.lvl_max or 0
    info:SetText(lvlMin .. "-" .. lvlMax)
    
    local color = getLevelColor(lvlMin, lvlMax)
    info:SetTextColor(color[1], color[2], color[3])
  end
  info:SetPoint("RIGHT", entry, "RIGHT", -10, 0)
  
  if isRaid then
    table.insert(raidClickableFrames, entry)
  else
    table.insert(donjonClickableFrames, entry)
  end
  
  return entry
end

local function clearScrollContent()
  if currentScrollContent then
    currentScrollContent:Hide()
    currentScrollContent = nil
  end
end

local function updateInstanceList()
  local scrollFrame = getglobal("AutoLFMTurtleFrameInstancesList")
  if not scrollFrame then return end
  
  local donjons, raids = getInstanceData()
  local data = showingRaids and raids or donjons
  
  if showingRaids then
    raidClickableFrames = {}
  else
    donjonClickableFrames = {}
  end
  
  if uiComponents.raidSizeControls and uiComponents.raidSizeControls.background then
    if showingRaids then
      uiComponents.raidSizeControls.background:Show()
    else
      uiComponents.raidSizeControls.background:Hide()
    end
  end
  
  clearScrollContent()
  
  if data and table.getn(data) > 0 then
    if not currentScrollContent then
      currentScrollContent = CreateFrame("Frame", nil, scrollFrame)
    end
    
    setSize(currentScrollContent, 298, table.getn(data) * CONFIG.ENTRY_HEIGHT)
    scrollFrame:SetScrollChild(currentScrollContent)
    currentScrollContent:Show()
    
    for i, instance in ipairs(data) do
      createInstanceEntry(currentScrollContent, instance, i, showingRaids)
    end
  end
  
  updateScrollFrameSize(scrollFrame)
end

local function setInstanceMode(isRaid)
  showingRaids = isRaid
  updateInstanceList()
end

---------------------------------------------------------------------------------
--                    Composants More Tab                                       --
---------------------------------------------------------------------------------

local function createMoreTabComponents(parent)
  local moreLabelFrame = CreateFrame("Frame", nil, parent)
  setSize(moreLabelFrame, CONFIG.MORE_TAB.SIZE[1], CONFIG.MORE_TAB.SIZE[2])
  moreLabelFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", CONFIG.MORE_TAB.POSITION[1], CONFIG.MORE_TAB.POSITION[2])
  moreLabelFrame:SetBackdrop(BACKDROPS.SIMPLE_TILE)
  moreLabelFrame:Hide()
  
  local moreLabel = moreLabelFrame:CreateFontString(nil, "OVERLAY", "DialogButtonHighlightText")
  moreLabel:SetText("Broadcast Message")
  moreLabel:SetPoint("TOP", moreLabelFrame, "TOP", 0, 0)
  moreLabel:SetJustifyH("CENTER")
  moreLabel:SetJustifyV("TOP")
  moreLabel:SetWidth(moreLabelFrame:GetWidth() - 20)
  
  local sliderIcon = moreLabelFrame:CreateTexture(nil, "OVERLAY")
  sliderIcon:SetTexture(MORE_ICONS.INTERVAL)
  setSize(sliderIcon, CONFIG.ICON_SIZE[1], CONFIG.ICON_SIZE[2])
  sliderIcon:SetPoint("TOPLEFT", moreLabelFrame, "TOPLEFT", 5, -50)
  
  local sliderLabel = moreLabelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  sliderLabel:SetText("Interval:")
  sliderLabel:SetPoint("LEFT", sliderIcon, "RIGHT", 5, 0)
  
  local intervalSlider = CreateFrame("Slider", nil, moreLabelFrame)
  setSize(intervalSlider, CONFIG.MORE_TAB.INTERVAL_SLIDER_SIZE[1], CONFIG.MORE_TAB.INTERVAL_SLIDER_SIZE[2])
  intervalSlider:SetPoint("TOPLEFT", moreLabelFrame, "TOPLEFT", 85, -52)
  intervalSlider:SetMinMaxValues(CONFIG.MORE_TAB.INTERVAL_MIN, CONFIG.MORE_TAB.INTERVAL_MAX)
  intervalSlider:SetValue(CONFIG.MORE_TAB.INTERVAL_DEFAULT)
  intervalSlider:SetValueStep(10)
  intervalSlider:SetOrientation("HORIZONTAL")
  intervalSlider:SetThumbTexture(TEXTURES.SLIDER_THUMB)
  intervalSlider:SetBackdrop(BACKDROPS.SLIDER)
  
  local sliderValueText = moreLabelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  sliderValueText:SetText(CONFIG.MORE_TAB.INTERVAL_DEFAULT .. " secs")
  sliderValueText:SetPoint("LEFT", intervalSlider, "RIGHT", 10, 0)
  
  intervalSlider:SetScript("OnValueChanged", function()
    local value = intervalSlider:GetValue()
    if value then
      sliderValueText:SetText(tostring(math.floor(value)) .. " secs")
    end
  end)
  
  local channelIcon = moreLabelFrame:CreateTexture(nil, "OVERLAY")
  channelIcon:SetTexture(MORE_ICONS.CHANNELS)
  setSize(channelIcon, CONFIG.ICON_SIZE[1], CONFIG.ICON_SIZE[2])
  channelIcon:SetPoint("TOPLEFT", moreLabelFrame, "TOPLEFT", 5, -90)
  
  local channelsLabel = moreLabelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  channelsLabel:SetText("Channels:")
  channelsLabel:SetPoint("LEFT", channelIcon, "RIGHT", 5, 0)
  
  local hcCheck = CreateFrame("CheckButton", nil, moreLabelFrame, "OptionsCheckButtonTemplate")
  setSize(hcCheck, CONFIG.CHECKBOX_SIZE[1], CONFIG.CHECKBOX_SIZE[2])
  hcCheck:SetPoint("LEFT", channelsLabel, "RIGHT", 10, 0)
  hcCheck:SetChecked(false)
  
  local hcLabel = moreLabelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  hcLabel:SetText("Hardcore")
  hcLabel:SetPoint("LEFT", hcCheck, "RIGHT", 5, 0)
  
  local channelChecks = {Hardcore = hcCheck}
  
  for i, channelName in ipairs(BROADCAST_CHANNELS) do
    local check = CreateFrame("CheckButton", nil, moreLabelFrame, "OptionsCheckButtonTemplate")
    setSize(check, CONFIG.CHECKBOX_SIZE[1], CONFIG.CHECKBOX_SIZE[2])
    check:SetPoint("TOPLEFT", channelsLabel, "BOTTOMLEFT", 0, -5 - (i-1)*CONFIG.MORE_TAB.CHANNEL_SPACING)
    check:SetChecked(i == 1)
    
    local label = moreLabelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetText(channelName)
    label:SetPoint("LEFT", check, "RIGHT", 5, 0)
    
    channelChecks[channelName] = check
  end
  
  local timeIcon = moreLabelFrame:CreateTexture(nil, "OVERLAY")
  timeIcon:SetTexture(MORE_ICONS.DURATION)
  setSize(timeIcon, CONFIG.ICON_SIZE[1], CONFIG.ICON_SIZE[2])
  timeIcon:SetPoint("TOPLEFT", channelIcon, "BOTTOMLEFT", 0, -20)
  
  local timeLabel = moreLabelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  timeLabel:SetText("Duration: 00:00")
  timeLabel:SetPoint("LEFT", timeIcon, "RIGHT", 5, 0)
  
  local sentIcon = moreLabelFrame:CreateTexture(nil, "OVERLAY")
  sentIcon:SetTexture(MORE_ICONS.SENT)
  setSize(sentIcon, CONFIG.ICON_SIZE[1], CONFIG.ICON_SIZE[2])
  sentIcon:SetPoint("TOPLEFT", timeIcon, "BOTTOMLEFT", 0, -20)
  
  local sentLabel = moreLabelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  sentLabel:SetText("Sent: 0")
  sentLabel:SetPoint("LEFT", sentIcon, "RIGHT", 5, 0)
  
  local nextIcon = moreLabelFrame:CreateTexture(nil, "OVERLAY")
  nextIcon:SetTexture(MORE_ICONS.NEXT)
  setSize(nextIcon, CONFIG.ICON_SIZE[1], CONFIG.ICON_SIZE[2])
  nextIcon:SetPoint("TOPLEFT", sentIcon, "BOTTOMLEFT", 0, -20)
  
  local nextLabel = moreLabelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  nextLabel:SetText("Next: 60s")
  nextLabel:SetPoint("LEFT", nextIcon, "RIGHT", 5, 0)
  
  uiComponents.moreTabContent = {
    frame = moreLabelFrame,
    label = moreLabel,
    timeLabel = timeLabel,
    sentLabel = sentLabel,
    nextLabel = nextLabel,
    intervalSlider = intervalSlider,
    sliderValue = sliderValueText,
    channelChecks = channelChecks
  }
  
  return uiComponents.moreTabContent
end

---------------------------------------------------------------------------------
--                           Système de Tabs                                   --
---------------------------------------------------------------------------------

local function CreateTab(name, id, text, parent)
  local tab = CreateFrame("Button", name, parent)
  setSize(tab, 96, 32)
  tab:SetID(id)
  local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  tabText:SetPoint("CENTER", 0, 2)
  tabText:SetText(text)
  tab.text = tabText
  tab.isActive = false
  
  local texture = tab:CreateTexture(nil, "BACKGROUND")
  texture:SetAllPoints()
  tab:SetNormalTexture(texture)
  
  return tab
end

local function setTabInactive(tab)
  tab.isActive = false
  tab:GetNormalTexture():SetTexture(TEXTURES.TAB_INACTIVE)
  tab.text:SetTextColor(unpack(COLORS.TAB_INACTIVE))
  tab:SetScript("OnEnter", function()
    tab:SetHighlightTexture(TEXTURES.TAB_HIGHLIGHT)
  end)
end

local function setTabActive(tab)
  tab.isActive = true
  tab:GetNormalTexture():SetTexture(TEXTURES.TAB_ACTIVE)
  tab.text:SetTextColor(unpack(COLORS.TAB_ACTIVE))
  tab:SetScript("OnEnter", function()
    tab:SetHighlightTexture(nil)
  end)
end

local function updateTabVisibility(tabId)
  local isMoreTab = (tabId == 3)
  
  local scrollFrame = getglobal("AutoLFMTurtleFrameInstancesList")
  if scrollFrame then
    if isMoreTab then
      clearScrollContent()
      scrollFrame:SetScrollChild(nil)
      currentScrollContent = nil
      scrollFrame:Hide()
    else
      scrollFrame:Show()
    end
  end
  
  if uiComponents.raidSizeControls and uiComponents.raidSizeControls.background then
    if isMoreTab then
      uiComponents.raidSizeControls.background:Hide()
    else
      if tabId == 2 then
        uiComponents.raidSizeControls.background:Show()
      else
        uiComponents.raidSizeControls.background:Hide()
      end
    end
  end
  
  if uiComponents.moreTabContent and uiComponents.moreTabContent.frame then
    if isMoreTab then
      uiComponents.moreTabContent.frame:Show()
    else
      uiComponents.moreTabContent.frame:Hide()
    end
  end
end

local function SetTab(frame, id)
  CurrentTab = id
  for i, tab in ipairs(tabs) do
    tab:ClearAllPoints()
    tab:SetPoint("BOTTOMLEFT", uiComponents.mainFrame, "BOTTOMLEFT", CONFIG.TAB_POSITIONS[i][1], CONFIG.TAB_POSITIONS[i][2])
    if i == id then
      setTabActive(tab)
    else
      setTabInactive(tab)
    end
  end
  
  updateTabVisibility(id)
end

---------------------------------------------------------------------------------
--                           Boutons de Rôles                                  --
---------------------------------------------------------------------------------

local function createRoleButton(data, index, parent)
  local btn = CreateFrame("Button", "AutoLFMTurtleFrameRole"..data.name, parent)
  setSize(btn, CONFIG.ROLE_SIZE[1], CONFIG.ROLE_SIZE[2])
  btn:SetPoint("TOPLEFT", 74 + (index-1)*98, -52)
  
  local bg = btn:CreateTexture(nil, "BACKGROUND") 
  bg:SetTexture(data.backgroundTexture)
  bg:SetTexCoord(unpack(data.coord))
  setSize(bg, 84, 84)
  bg:SetPoint("TOPLEFT", -12, 14)
  bg:SetVertexColor(1, 1, 1, COLORS.ROLE_BG_ALPHA)
  
  local icon = btn:CreateTexture(nil, "BORDER")
  icon:SetAllPoints()
  icon:SetTexture(data.texture)
  
  local checkFrame = CreateFrame("Frame", nil, parent)
  setSize(checkFrame, CONFIG.CHECKBOX_SIZE_LARGE[1], CONFIG.CHECKBOX_SIZE_LARGE[2])
  checkFrame:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 3, -3)
  
  local check = CreateFrame("CheckButton", nil, checkFrame, "OptionsCheckButtonTemplate")
  setSize(check, CONFIG.CHECKBOX_SIZE_LARGE[1], CONFIG.CHECKBOX_SIZE_LARGE[2])
  check:SetPoint("CENTER", checkFrame, "CENTER", 0, 0)
  check:SetHitRectInsets(0, 0, 0, 0)
  
  btn:SetScript("OnClick", function()
    check:SetChecked(not check:GetChecked())
  end)
  
  return btn, check
end

---------------------------------------------------------------------------------
--                           Bouton de Recherche                               --
---------------------------------------------------------------------------------

local function createSearchButton(parent)
  local searchBtn = CreateFrame("Button", "AutoLFMTurtleFrameSearchButton", parent, "UIPanelButtonTemplate")
  setSize(searchBtn, CONFIG.BUTTON_SIZE[1], CONFIG.BUTTON_SIZE[2])
  searchBtn:SetPoint("BOTTOM", parent, "BOTTOM", -10, 79)
  searchBtn:SetText("Search")
  
  searchBtn:SetScript("OnClick", function()
    -- Interface pure - pas de logique de recherche
  end)
  
  return searchBtn
end

---------------------------------------------------------------------------------
--                           Initialisation                                    --
---------------------------------------------------------------------------------

local AutoLFMTurtleFrame = createMainFrame()
createFrameElements(AutoLFMTurtleFrame)

local editBox = createEditBox(AutoLFMTurtleFrame)
local raidSizeControls = createRaidSizeControls(AutoLFMTurtleFrame)
local instanceScrollFrame = createScrollFrame(AutoLFMTurtleFrame)
local moreTabContent = createMoreTabComponents(AutoLFMTurtleFrame)

for i, roleData in ipairs(ROLE_DATA) do
  local btn, check = createRoleButton(roleData, i, AutoLFMTurtleFrame)
  roleButtons[roleData.name] = btn
  roleChecks[roleData.name] = check
end

tabs[1] = CreateTab("AutoLFMTurtleFrameTab1", 1, "Dungeons", AutoLFMTurtleFrame)
tabs[2] = CreateTab("AutoLFMTurtleFrameTab2", 2, "Raids", AutoLFMTurtleFrame)
tabs[3] = CreateTab("AutoLFMTurtleFrameTab3", 3, "More", AutoLFMTurtleFrame)

tabs[1]:SetScript("OnClick", function() SetTab(AutoLFMTurtleFrame, 1); setInstanceMode(false) end)
tabs[2]:SetScript("OnClick", function() SetTab(AutoLFMTurtleFrame, 2); setInstanceMode(true) end)
tabs[3]:SetScript("OnClick", function() SetTab(AutoLFMTurtleFrame, 3) end)

local searchButton = createSearchButton(AutoLFMTurtleFrame)

SetTab(AutoLFMTurtleFrame, 1)
updateScrollFrameSize(instanceScrollFrame)
updateInstanceList()

AutoLFMTurtleFrame:Show()

if not validateInstanceData() then
  DEFAULT_CHAT_FRAME:AddMessage("AutoLFM: Please ensure Variables.lua is properly loaded with instance data.")
else
  DEFAULT_CHAT_FRAME:AddMessage("AutoLFM Turtle UI (Interface Pure) loaded successfully!")
end