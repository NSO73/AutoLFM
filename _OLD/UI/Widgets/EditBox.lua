--=============================================================================
-- AutoLFM: EditBox Widget
--   Reusable EditBox component with placeholder support
--=============================================================================
AutoLFM = AutoLFM or {}
AutoLFM.UI = AutoLFM.UI or {}
AutoLFM.UI.Widgets = AutoLFM.UI.Widgets or {}
AutoLFM.UI.Widgets.EditBox = AutoLFM.UI.Widgets.EditBox or {}

-----------------------------------------------------------------------------
-- EditBox Creation
-----------------------------------------------------------------------------
function AutoLFM.UI.Widgets.EditBox.Create(config)
  if not config or not config.parent or not config.name then return nil end

  local container = nil
  local editBox = nil

  -- For multiline, create a container frame
  if config.multiline then
    container = CreateFrame("Frame", config.name .. "_Container", config.parent)
    container:SetWidth(config.width or 270)
    container:SetHeight(config.height or 30)

    -- Set position on container
    if config.point then
      container:SetPoint(config.point.point, config.point.relativeTo, config.point.relativePoint, config.point.x, config.point.y)
    end

    -- Create editBox inside container
    editBox = CreateFrame("EditBox", config.name, container)
    editBox:SetWidth(config.width or 270)
    editBox:SetHeight(config.height or 30)
    editBox:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
  else
    -- Simple single-line editBox
    editBox = CreateFrame("EditBox", config.name, config.parent)
    editBox:SetWidth(config.width or 270)
    editBox:SetHeight(config.height or 20)

    -- Set position
    if config.point then
      editBox:SetPoint(config.point.point, config.point.relativeTo, config.point.relativePoint, config.point.x, config.point.y)
    end
  end

  -- Set properties
  editBox:SetAutoFocus(false)
  editBox:SetFontObject("GameFontNormal")
  editBox:SetMaxLetters(config.maxLetters or 255)
  editBox:SetJustifyH(config.justify or "CENTER")
  editBox:SetTextInsets(config.insetX or 10, config.insetX or 10, config.insetY or 5, config.insetY or 5)

  -- Enable multiline if requested
  if config.multiline then
    editBox:SetMultiLine(true)
    editBox:SetJustifyV(config.justifyV or "TOP")
  end

  -- Backdrop (like AutoLFM old style)
  local backdropFrame = config.multiline and container or editBox

  if config.useBackdrop then
    backdropFrame:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 16,
      insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    backdropFrame:SetBackdropColor(0, 0, 0, 0.8)
    backdropFrame:SetBackdropBorderColor(1, 0.82, 0, 1)
  else
    -- Simple background
    local bg = backdropFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, config.bgAlpha or 0.5)

    -- Optional border using backdrop
    if config.border then
      backdropFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
      })
      backdropFrame:SetBackdropBorderColor(1, 0.82, 0, 0.8)
    end
  end

  -- Placeholder text
  local placeholder = nil
  if config.placeholder then
    placeholder = editBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    placeholder:SetText(config.placeholder)
    placeholder:SetPoint("CENTER", editBox, "CENTER", 0, 0)

    local function updatePlaceholder()
      if editBox:GetText() == "" then
        placeholder:Show()
      else
        placeholder:Hide()
      end
    end

    editBox:SetScript("OnEditFocusGained", function()
      placeholder:Hide()
      -- Enable link integration
      if config.enableLinkIntegration and AutoLFM.Logic.Widgets.EditBox.SetTargetEditBox then
        AutoLFM.Logic.Widgets.EditBox.SetTargetEditBox(editBox)
      end
    end)

    editBox:SetScript("OnEditFocusLost", function()
      updatePlaceholder()
      -- Disable link integration
      if config.enableLinkIntegration and AutoLFM.Logic.Widgets.EditBox.SetTargetEditBox then
        AutoLFM.Logic.Widgets.EditBox.SetTargetEditBox(nil)
      end
    end)

    editBox:SetScript("OnTextChanged", function()
      updatePlaceholder()

      -- Auto-resize height for multiline
      if config.multiline and container then
        local text = editBox:GetText() or ""

        -- Count explicit line breaks
        local numLines = 1
        local i = 1
        while i <= string.len(text) do
          if string.sub(text, i, i) == "\n" then
            numLines = numLines + 1
          end
          i = i + 1
        end

        -- Estimate wrapped lines using text width
        if string.len(text) > 0 then
          -- Create temporary FontString to measure text width
          local tempFS = editBox:CreateFontString(nil, "OVERLAY")
          tempFS:SetFontObject("GameFontNormal")
          tempFS:SetText(text)
          local textWidth = tempFS:GetWidth()
          tempFS:Hide()

          -- Available width for text (editbox width - insets)
          local availableWidth = (config.width or 270) - 20

          -- Estimate wrapped lines
          if textWidth > availableWidth then
            local wrappedLines = math.ceil(textWidth / availableWidth)
            numLines = math.max(numLines, wrappedLines)
          end
        end

        -- Calculate height based on number of lines (14 pixels per line + padding)
        local minHeight = config.height or 30
        local lineHeight = 14
        local padding = 12
        local newHeight = math.max(minHeight, numLines * lineHeight + padding)
        local maxHeight = 60  -- Maximum height (2 lines)
        newHeight = math.min(newHeight, maxHeight)

        container:SetHeight(newHeight)
        editBox:SetHeight(newHeight)
      end

      if config.onTextChanged then
        config.onTextChanged()
      end
    end)

    updatePlaceholder()
  else
    -- No placeholder, but we still need link integration handlers
    if config.enableLinkIntegration and AutoLFM.Logic.Widgets.EditBox.SetTargetEditBox then
      editBox:SetScript("OnEditFocusGained", function()
        AutoLFM.Logic.Widgets.EditBox.SetTargetEditBox(editBox)
      end)

      editBox:SetScript("OnEditFocusLost", function()
        AutoLFM.Logic.Widgets.EditBox.SetTargetEditBox(nil)
      end)
    end

    -- Auto-resize for multiline without placeholder
    if config.multiline and container then
      editBox:SetScript("OnTextChanged", function()
        local text = editBox:GetText() or ""

        -- Count explicit line breaks
        local numLines = 1
        local i = 1
        while i <= string.len(text) do
          if string.sub(text, i, i) == "\n" then
            numLines = numLines + 1
          end
          i = i + 1
        end

        -- Estimate wrapped lines using text width
        if string.len(text) > 0 then
          -- Create temporary FontString to measure text width
          local tempFS = editBox:CreateFontString(nil, "OVERLAY")
          tempFS:SetFontObject("GameFontNormal")
          tempFS:SetText(text)
          local textWidth = tempFS:GetWidth()
          tempFS:Hide()

          -- Available width for text (editbox width - insets)
          local availableWidth = (config.width or 270) - 20

          -- Estimate wrapped lines
          if textWidth > availableWidth then
            local wrappedLines = math.ceil(textWidth / availableWidth)
            numLines = math.max(numLines, wrappedLines)
          end
        end

        -- Calculate height based on number of lines (14 pixels per line + padding)
        local minHeight = config.height or 30
        local lineHeight = 14
        local padding = 12
        local newHeight = math.max(minHeight, numLines * lineHeight + padding)
        local maxHeight = 60  -- Maximum height (2 lines)
        newHeight = math.min(newHeight, maxHeight)

        container:SetHeight(newHeight)
        editBox:SetHeight(newHeight)

        if config.onTextChanged then
          config.onTextChanged()
        end
      end)
    elseif config.onTextChanged then
      editBox:SetScript("OnTextChanged", function()
        config.onTextChanged()
      end)
    end
  end

  -- Key handlers
  editBox:SetScript("OnEnterPressed", function()
    if not config.multiline then
      editBox:ClearFocus()
    end
  end)

  editBox:SetScript("OnEscapePressed", function()
    editBox:ClearFocus()
  end)

  -- Return container for multiline (with proxy methods), or editBox for single-line
  if config.multiline and container then
    -- Proxy common EditBox methods to the actual editBox
    container.GetText = function() return editBox:GetText() end
    container.SetText = function(self, text) editBox:SetText(text) end
    container.ClearFocus = function() editBox:ClearFocus() end
    container.SetFocus = function() editBox:SetFocus() end
    container.editBox = editBox  -- Keep reference to actual editBox
    return container
  else
    return editBox
  end
end
