--=============================================================================
-- AutoLFM: Tabs Logic
--   Tab state management and content routing
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Widgets = AutoLFM.Logic.Widgets or {}
AutoLFM.Logic.Widgets.Tabs = AutoLFM.Logic.Widgets.Tabs or {}

-----------------------------------------------------------------------------
-- Content mapping (lazy-loaded to avoid module order issues)
-----------------------------------------------------------------------------
local function GetContentMap()
  return {
    lineTab = {
      presets = AutoLFM.Logic.Content.Presets,
      autoinvite = AutoLFM.Logic.Content.AutoInvite,
      options = AutoLFM.Logic.Content.Options
    },
    bottomTab = {
      dungeons = AutoLFM.Logic.Content.Dungeons,
      raids = AutoLFM.Logic.Content.Raids,
      quests = AutoLFM.Logic.Content.Quests,
      broadcasts = AutoLFM.Logic.Content.Broadcasts
    }
  }
end

function AutoLFM.Logic.Widgets.Tabs.ClearContent()
  if AutoLFM.Core.Maestro.currentContent and AutoLFM.Core.Maestro.currentContent.Unload then
    AutoLFM.Core.Maestro.currentContent.Unload()
  end
  AutoLFM.Core.Maestro.currentContent = nil
  AutoLFM.UI.Widgets.Tabs.ClearContentUI()
end

function AutoLFM.Logic.Widgets.Tabs.LoadContent(bottomTab, lineTab)
  AutoLFM.Logic.Widgets.Tabs.ClearContent()

  local contentMap = GetContentMap()
  local content = nil
  if lineTab then
    content = contentMap.lineTab[lineTab]
  elseif bottomTab then
    content = contentMap.bottomTab[bottomTab]
  end

  if content and content.Load then
    content.Load()
    AutoLFM.Core.Maestro.currentContent = content
  end
end

function AutoLFM.Logic.Widgets.Tabs.ReloadCurrentTab()
  AutoLFM.Logic.Widgets.Tabs.LoadContent(
    AutoLFM.Core.Maestro.currentTab.bottomTab,
    AutoLFM.Core.Maestro.currentTab.lineTab
  )
end

-----------------------------------------------------------------------------
-- Tab selection
-----------------------------------------------------------------------------
function AutoLFM.Logic.Widgets.Tabs.SelectBottomTab(tabNameOrIndex)
  if not tabNameOrIndex then return end

  local tabName = tabNameOrIndex
  if type(tabNameOrIndex) == "number" then
    tabName = AutoLFM.Core.Constants.BOTTOM_TAB_MAP[tabNameOrIndex]
  end

  if not tabName then return end

  if AutoLFM.Core.Maestro.currentTab.bottomTab == tabName and AutoLFM.Core.Maestro.currentContent then
    return
  end

  AutoLFM.Core.Maestro.currentTab.bottomTab = tabName
  AutoLFM.Core.Maestro.currentTab.lineTab = nil

  local tabIndex = type(tabNameOrIndex) == "number" and tabNameOrIndex or AutoLFM.Core.Constants.BOTTOM_TAB_MAP[tabName]

  AutoLFM.UI.Widgets.Tabs.UpdateBottomTabs(tabIndex)
  AutoLFM.Logic.Widgets.Tabs.LoadContent(tabName, nil)
end

function AutoLFM.Logic.Widgets.Tabs.SelectLineTab(tabNameOrIndex)
  if not tabNameOrIndex then return end

  local tabName = tabNameOrIndex
  if type(tabNameOrIndex) == "number" then
    tabName = AutoLFM.Core.Constants.LINE_TAB_MAP[tabNameOrIndex]
  end

  if not tabName then return end

  local tabIndex = type(tabNameOrIndex) == "number" and tabNameOrIndex or AutoLFM.Core.Constants.LINE_TAB_MAP[tabName]

  if AutoLFM.Core.Maestro.currentTab.lineTab == tabName and AutoLFM.Core.Maestro.currentContent then
    AutoLFM.UI.Widgets.Tabs.UpdateLineTabs(tabIndex)
    return
  end

  AutoLFM.Core.Maestro.currentTab.bottomTab = nil
  AutoLFM.Core.Maestro.currentTab.lineTab = tabName

  AutoLFM.UI.Widgets.Tabs.UpdateLineTabs(tabIndex)
  AutoLFM.Logic.Widgets.Tabs.LoadContent(nil, tabName)
end
