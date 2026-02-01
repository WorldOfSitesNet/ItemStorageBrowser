local addonName, ItemStorageBrowser = ...

-- Ждем инициализации основного фрейма
local function InitializeMinimapButton()
    -- Создаем кнопку у мини-карты
    local miniMapButton = CreateFrame("Button", "ItemStorageBrowserMiniMapButton", Minimap)
    miniMapButton:SetSize(32, 32)
    miniMapButton:SetFrameStrata("MEDIUM")

    -- Текстура кнопки
    miniMapButton.icon = miniMapButton:CreateTexture(nil, "BACKGROUND")
    miniMapButton.icon:SetTexture("Interface\\Icons\\HordePandaren_64")
    miniMapButton.icon:SetSize(22, 22)
    miniMapButton.icon:SetPoint("CENTER")

    -- Круглая рамка
    miniMapButton.overlay = miniMapButton:CreateTexture(nil, "OVERLAY")
    miniMapButton.overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    miniMapButton.overlay:SetSize(56, 56)
    miniMapButton.overlay:SetPoint("TOPLEFT", 0, 0)

    -- Функция для обновления позиции кнопки
    local function UpdateMinimapButtonPosition()
        local angle = ItemStorageBrowserDB.minimapAngle or 0
        local radius = 80
        local scale = Minimap:GetWidth() / 150
        
        local x = cos(angle) * radius * scale
        local y = sin(angle) * radius * scale
        
        miniMapButton:ClearAllPoints()
        miniMapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    -- Обработчик перетаскивания
    miniMapButton:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            px, py = px / scale, py / scale
            
            ItemStorageBrowserDB.minimapAngle = atan2(py - my, px - mx)
            UpdateMinimapButtonPosition()
        end)
    end)

    miniMapButton:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnregisterHighlight()
    end)

    miniMapButton:RegisterForDrag("LeftButton")

    -- Обработчики клика
    miniMapButton:SetScript("OnClick", function(self, button)
        if ItemStorageBrowser.frame:IsShown() then
            ItemStorageBrowser.frame:Hide()
        else
            ItemStorageBrowser.frame:Show()
            ItemStorageBrowser.frame:SetFocus(true)
        end
    end)

    -- Глобальный обработчик Esc
    local function OnEscapePressed()
        if ItemStorageBrowser.frame:IsShown() then
            ItemStorageBrowser.frame:Hide()
            return true -- Блокируем дальнейшую обработку Esc
        end
        return false
    end

    -- Регистрируем обработчик Esc
    tinsert(UISpecialFrames, "ItemStorageBrowserFrame") -- Добавляем в стандартные фреймы для закрытия по Esc

    -- Альтернативный вариант обработки Esc через хук
    hooksecurefunc("CloseSpecialWindows", function()
        if ItemStorageBrowser.frame:IsShown() then
            ItemStorageBrowser.frame:Hide()
        end
    end)

    miniMapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Item Storage Browser", 1, 1, 1)
        GameTooltip:AddLine("Кликните, чтобы открыть/закрыть окно аддона.", 0.5, 0.5, 0.5, true)
        GameTooltip:Show()
    end)

    miniMapButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Инициализация позиции кнопки
    UpdateMinimapButtonPosition()

    -- Обновляем позицию при изменении размера мини-карты
    Minimap:HookScript("OnSizeChanged", UpdateMinimapButtonPosition)
end

-- Регистрируем событие для отложенной инициализации
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    InitializeMinimapButton()
    self:UnregisterEvent(event)
end)