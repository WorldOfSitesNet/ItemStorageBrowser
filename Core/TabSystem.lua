local addonName, ItemStorageBrowser = ...

ItemStorageBrowser.tabs = ItemStorageBrowser.tabs or {}

function ItemStorageBrowser:InitializeTabSystem()
    local frame = self.frame
    
    -- Контейнер для вкладок
    local tabContainer = CreateFrame("Frame", nil, frame)
    tabContainer:SetSize(40, 360)
    tabContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -30)
    
    -- Контейнер для содержимого
    local contentContainer = CreateFrame("Frame", nil, frame)
    contentContainer:SetSize(540, 360)
    contentContainer:SetPoint("TOPLEFT", tabContainer, "TOPRIGHT", 5, 0)
    contentContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    
    self.contentContainer = contentContainer
    
    function self:RegisterTab(tabData)
        -- Создаем контейнер для контента вкладки
        tabData.contentFrame = CreateFrame("Frame", nil, contentContainer)
        tabData.contentFrame:SetAllPoints(contentContainer)
        tabData.contentFrame:Hide()
        
        table.insert(self.tabs, tabData)
        self:UpdateTabs()
        return #self.tabs
    end
    
    function self:UpdateTabs()
        for i, tab in ipairs(self.tabs) do
            if not tab.button then
                tab.button = CreateFrame("Button", nil, tabContainer)
                tab.button:SetSize(30, 30)
                tab.button:SetPoint("TOP", tabContainer, "TOP", 0, -(i-1)*35)
                
                tab.button.icon = tab.button:CreateTexture(nil, "BACKGROUND")
                tab.button.icon:SetTexture(tab.icon)
                tab.button.icon:SetAllPoints()
                
                tab.button:SetScript("OnClick", function()
                    self:ActivateTab(tab)
                end)
                
                tab.button:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(tab.button, "ANCHOR_RIGHT")
                    GameTooltip:SetText(tab.name)
                    GameTooltip:Show()
                end)
                
                tab.button:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
                
                tab.button.icon:SetDesaturated(true)
                tab.button.icon:SetAlpha(0.5)
            end
        end
        
        if #self.tabs > 0 and not self.activeTab then
            self:ActivateTab(self.tabs[1])
        end
    end
    
    function self:ActivateTab(tab)
        -- Деактивация текущей вкладки
        if self.activeTab then
            self.activeTab.contentFrame:Hide()
            if self.activeTab.OnDeactivate then
                self.activeTab.OnDeactivate(self.activeTab)
            end
        end
        
        -- Сброс кнопок вкладок
        for _, t in ipairs(self.tabs) do
            if t.button then
                t.button.icon:SetDesaturated(true)
                t.button.icon:SetAlpha(0.5)
            end
        end
        
        -- Активация новой вкладки
        self.activeTab = tab
        if tab.button then
            tab.button.icon:SetDesaturated(false)
            tab.button.icon:SetAlpha(1)
        end
        
        -- Показываем контент вкладки
        tab.contentFrame:Show()
        
        -- Инициализация вкладки при первом открытии
        if not tab.initialized and tab.OnActivate then
            tab.OnActivate(tab, tab.contentFrame)
            tab.initialized = true
        end
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    ItemStorageBrowser:InitializeTabSystem()
    self:UnregisterEvent(event)
end)