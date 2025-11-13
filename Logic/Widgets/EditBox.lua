--=============================================================================
-- AutoLFM: EditBox Widget Logic
--   Link Integration - Allows Shift+Click to insert items/quests/links
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.Logic = AutoLFM.Logic or {}
AutoLFM.Logic.Widgets = AutoLFM.Logic.Widgets or {}
AutoLFM.Logic.Widgets.EditBox = AutoLFM.Logic.Widgets.EditBox or {}

function AutoLFM.Logic.Widgets.EditBox.Init()
  -- Enable link integration hooks (must be done after all modules loaded)
  if AutoLFM.Logic.Widgets.EditBox.EnableLinkIntegration then
    AutoLFM.Logic.Widgets.EditBox.EnableLinkIntegration()
  end
end

-----------------------------------------------------------------------------
-- Private State
-----------------------------------------------------------------------------
local Original_ContainerFrameItemButton_OnClick = nil
local Original_ChatFrame_OnHyperlinkShow = nil
local targetEditBox = nil

-----------------------------------------------------------------------------
-- Set target editbox for link insertion
-----------------------------------------------------------------------------
function AutoLFM.Logic.Widgets.EditBox.SetTargetEditBox(editBox)
  targetEditBox = editBox
end

function AutoLFM.Logic.Widgets.EditBox.GetTargetEditBox()
  return targetEditBox
end

-----------------------------------------------------------------------------
-- Insert link into editbox
-----------------------------------------------------------------------------
local function InsertLink(link)
  if not targetEditBox or not AutoLFM_MainFrame or not AutoLFM_MainFrame:IsVisible() then
    return false
  end

  local currentText = targetEditBox:GetText() or ""
  if currentText == "" then
    targetEditBox:SetText(link)
  else
    targetEditBox:SetText(currentText .. " " .. link)
  end
  targetEditBox:SetFocus()
  targetEditBox:HighlightText(0, 0)
  return true
end

-----------------------------------------------------------------------------
-- Bag Item Clicks (Shift+Click to insert item link)
-----------------------------------------------------------------------------
local function HookBagClicks()
  if not ContainerFrameItemButton_OnClick then return end
  Original_ContainerFrameItemButton_OnClick = ContainerFrameItemButton_OnClick

  ContainerFrameItemButton_OnClick = function(button, ignoreModifiers)
    local success, err = pcall(function()
      if IsShiftKeyDown() and targetEditBox then
        local bag = this:GetParent():GetID()
        local slot = this:GetID()
        local itemLink = GetContainerItemLink(bag, slot)

        if itemLink and InsertLink(itemLink) then
          return
        end
      end

      if Original_ContainerFrameItemButton_OnClick then
        Original_ContainerFrameItemButton_OnClick(button, ignoreModifiers)
      end
    end)

    if not success and Original_ContainerFrameItemButton_OnClick then
      Original_ContainerFrameItemButton_OnClick(button, ignoreModifiers)
    end
  end
end

-----------------------------------------------------------------------------
-- Quest Log Selection (Shift+Click to insert quest link)
-----------------------------------------------------------------------------
local function HookQuestLog()
  local questFrame = CreateFrame("Frame")
  questFrame:RegisterEvent("QUEST_LOG_UPDATE")

  local lastClickedQuest = nil
  local lastClickTime = 0

  questFrame:SetScript("OnEvent", function()
    local success, err = pcall(function()
      if not QuestLogFrame or not QuestLogFrame:IsVisible() then return end

      local currentTime = GetTime()
      if currentTime - lastClickTime < 0.1 then return end

      local selectedQuest = GetQuestLogSelection()
      if selectedQuest and selectedQuest > 0 and selectedQuest ~= lastClickedQuest then
        lastClickedQuest = selectedQuest
        lastClickTime = currentTime

        if IsShiftKeyDown() and targetEditBox then
          local title, level, _, _, _, _, _, questID = GetQuestLogTitle(selectedQuest)
          if title then
            level = level or 0
            questID = questID or 0
            local cleanTitle = string.gsub(title, "^%[.-%]%s*", "")

            -- Create quest link (format: |cFFFFFF00|Hquest:questID:level|h[cleanTitle]|h|r)
            local link = "|cFFFFFF00|Hquest:" .. questID .. ":" .. level .. "|h[" .. cleanTitle .. "]|h|r"
            InsertLink(link)
          end
        end
      end
    end)
    if not success then
      -- Silently fail
    end
  end)
end

-----------------------------------------------------------------------------
-- Chat Hyperlinks (Shift+Click to insert link)
-----------------------------------------------------------------------------
local function HookChatLinks()
  if not ChatFrame_OnHyperlinkShow then return end
  Original_ChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow

  ChatFrame_OnHyperlinkShow = function(link, text, button)
    local success, err = pcall(function()
      -- Right click on player → show menu
      local linkType, playerName = string.match(link or "", "^(%a+):([^:]+)")
      if linkType == "player" and playerName and button == "RightButton" then
        playerName = gsub(playerName, "-.*", "")
        HideDropDownMenu(1)
        ChatFrameDropDown_Show(nil, playerName)
        return
      end

      -- Shift+Click on item/quest → insert into editbox
      if IsShiftKeyDown() and targetEditBox then
        if link and text and (string.find(link, "^item:") or string.find(link, "^quest:")) then
          InsertLink(text)
        end
      end

      -- Call original
      if Original_ChatFrame_OnHyperlinkShow then
        Original_ChatFrame_OnHyperlinkShow(link, text, button)
      end
    end)

    if not success and Original_ChatFrame_OnHyperlinkShow then
      Original_ChatFrame_OnHyperlinkShow(link, text, button)
    end
  end
end

-----------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------
function AutoLFM.Logic.Widgets.EditBox.EnableLinkIntegration()
  local success, err = pcall(function()
    HookBagClicks()
    HookQuestLog()
    HookChatLinks()
  end)

  if not success then
    -- Silently fail
  end
end

-----------------------------------------------------------------------------
-- Auto-register initialization
-----------------------------------------------------------------------------
AutoLFM.Core.Maestro.RegisterInit("EditBox", "Logic.Widgets.EditBox.Init")
