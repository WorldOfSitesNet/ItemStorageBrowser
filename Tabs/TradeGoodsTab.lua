local addonName, ItemStorageBrowser = ...

local function StyleEditBox(editBox)
    editBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 18, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    editBox:SetBackdropColor(0, 0, 0, 0.5)
end

-- Функция для проверки, есть ли выбранные значения в дропдауне
local function HasSelectedValues(dropdown)
    if not dropdown.selectedValues then return false end
    for _, selected in pairs(dropdown.selectedValues) do
        if selected then return true end
    end
    return false
end

-- Функция для обновления текста дропдауна с множественным выбором (с ограничением длины)
local function UpdateMultiSelectDropdownText(dropdown, options)
    local selectedTexts = {}
    for value, selected in pairs(dropdown.selectedValues or {}) do
        if selected then
            for _, option in ipairs(options) do
                if option.value == value then
                    -- Удаляем цветовые коды для качества
                    local cleanText = string.gsub(option.text, "|c%x%x%x%x%x%x%x%x", "")
                    cleanText = string.gsub(cleanText, "|r", "")
                    table.insert(selectedTexts, cleanText)
                    break
                end
            end
        end
    end
    
    if #selectedTexts > 0 then
        local displayText = table.concat(selectedTexts, ", ")
        -- Ограничиваем длину текста, добавляя "..." если слишком длинный
        if #displayText > 25 then
            displayText = string.sub(displayText, 1, 22) .. "..."
        end
        UIDropDownMenu_SetText(dropdown, displayText)
    else
        UIDropDownMenu_SetText(dropdown, "Не выбрано")
    end
end

local function RegisterTradeGoodsTab()
    -- Регистрируем вкладку хозяйственных товаров
    ItemStorageBrowser:RegisterTab({
        name = "Хозяйственные товары",
        icon = "Interface\\Icons\\INV_Fabric_Silk_02",
        
        OnActivate = function(tab, container)
            -- Создаем элементы только если они еще не созданы
            if not tab.initialized then
                -- Создаем элементы фильтрации
                tab.tradeGoodsFiltersFrame = CreateFrame("Frame", nil, container)
                tab.tradeGoodsFiltersFrame:SetSize(500, 90)
                tab.tradeGoodsFiltersFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 10, -10)
                
                -- Выбор типа товара
                tab.typeLabel = tab.tradeGoodsFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.typeLabel:SetWidth(120)
                tab.typeLabel:SetPoint("TOPLEFT", tab.tradeGoodsFiltersFrame, "TOPLEFT", 0, 0)
                tab.typeLabel:SetText("Тип:")
                tab.typeLabel:SetFontObject("ChatFontNormal")
                tab.typeLabel:SetJustifyH("CENTER")
                
                tab.typeDropdown = CreateFrame("Frame", "ISB_TradeGoodsTypeDropdown", tab.tradeGoodsFiltersFrame, "UIDropDownMenuTemplate")
                tab.typeDropdown:SetPoint("TOPLEFT", tab.typeLabel, "BOTTOMLEFT", -20, -5)
                tab.typeDropdown:SetWidth(150)
                tab.typeDropdown.selectedValues = {}
                
                tab.types = {
                    {text = "Ткань/паутины", value = "Cloth"},
                    {text = "Кожа/шкуры", value = "Leather"},
                    {text = "Трава", value = "Herb"},
                    {text = "Металл", value = "Metal"},
                    {text = "Камень", value = "Stone"},
                    {text = "Самоцветы", value = "Gem"},
                    {text = "Стихии", value = "Elemental"},
                    {text = "Жемчужины", value = "Pearl"},
                    {text = "Мясо/Рыба", value = "Meat"},
                    {text = "Наложение чар", value = "Enchanting"},
                    {text = "Устройства", value = "Device"}
                }
                
                UIDropDownMenu_Initialize(tab.typeDropdown, function(self, level, menuList)
                    if level == 1 then
                        for _, type in ipairs(tab.types) do
                            local info = UIDropDownMenu_CreateInfo()
                            info.text = type.text
                            info.value = type.value
                            info.checked = tab.typeDropdown.selectedValues[type.value]
                            info.isNotRadio = true
                            info.keepShownOnClick = true
                            info.func = function(self)
                                tab.typeDropdown.selectedValues[self.value] = not tab.typeDropdown.selectedValues[self.value]
                                UpdateMultiSelectDropdownText(tab.typeDropdown, tab.types)
                                tab:UpdateFilterButtonState()
                            end
                            UIDropDownMenu_AddButton(info)
                        end
                    end
                end)
                
                UIDropDownMenu_SetText(tab.typeDropdown, "Не выбрано")

                -- Выбор качества
                tab.qualityLabel = tab.tradeGoodsFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.qualityLabel:SetWidth(120)
                tab.qualityLabel:SetPoint("TOPLEFT", tab.tradeGoodsFiltersFrame, "TOPLEFT", 180, 0)
                tab.qualityLabel:SetText("Качество:")
                tab.qualityLabel:SetFontObject("ChatFontNormal")
                tab.qualityLabel:SetJustifyH("CENTER")

                tab.qualityDropdown = CreateFrame("Frame", "ISB_TradeGoodsQualityDropdown", tab.tradeGoodsFiltersFrame, "UIDropDownMenuTemplate")
                tab.qualityDropdown:SetPoint("TOPLEFT", tab.qualityLabel, "BOTTOMLEFT", -20, -5)
                tab.qualityDropdown:SetWidth(150)
                tab.qualityDropdown.selectedValues = {}

                tab.qualities = {
                    {text = "|cffffffffОбычное|r", value = 1},
                    {text = "|cff1eff00Необычное|r", value = 2},
                    {text = "|cff0070ddРедкое|r", value = 3},
                    {text = "|cffa335eeЭпическое|r", value = 4},
                }

                UIDropDownMenu_Initialize(tab.qualityDropdown, function(self, level, menuList)
                    for _, quality in ipairs(tab.qualities) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = quality.text
                        info.value = quality.value
                        info.checked = tab.qualityDropdown.selectedValues[quality.value]
                        info.isNotRadio = true
                        info.keepShownOnClick = true
                        info.func = function(self)
                            tab.qualityDropdown.selectedValues[self.value] = not tab.qualityDropdown.selectedValues[self.value]
                            UpdateMultiSelectDropdownText(tab.qualityDropdown, tab.qualities)
                            tab:UpdateFilterButtonState()
                        end
                        UIDropDownMenu_AddButton(info)
                    end
                end)

                UIDropDownMenu_SetText(tab.qualityDropdown, "Не выбрано")
                
                -- Уровень профессии
                tab.skillLabel = tab.tradeGoodsFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.skillLabel:SetWidth(120)
                tab.skillLabel:SetPoint("TOPLEFT", tab.tradeGoodsFiltersFrame, "TOPLEFT", 360, 0)
                tab.skillLabel:SetText("Уровень профессии:")
                tab.skillLabel:SetFontObject("ChatFontNormal")
                tab.skillLabel:SetJustifyH("CENTER")
                
                -- Поля для уровней профессии
                tab.skillInputFrame = CreateFrame("Frame", nil, tab.tradeGoodsFiltersFrame)
                tab.skillInputFrame:SetSize(140, 30)
                tab.skillInputFrame:SetPoint("TOPLEFT", tab.skillLabel, "BOTTOMLEFT", 0, -5)

                tab.minSkill = CreateFrame("EditBox", nil, tab.skillInputFrame)
                tab.minSkill:SetSize(40, 24)
                tab.minSkill:SetPoint("LEFT", tab.skillInputFrame, "LEFT", 15, 0)
                tab.minSkill:SetAutoFocus(false)
                tab.minSkill:SetNumeric(true)
                tab.minSkill:SetMaxLetters(3)
                tab.minSkill:SetText("")
                tab.minSkill:SetCursorPosition(0)
                tab.minSkill:SetFontObject("ChatFontNormal")
                tab.minSkill:SetJustifyH("CENTER")
                StyleEditBox(tab.minSkill)
                
                tab.skillSeparator = tab.skillInputFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                tab.skillSeparator:SetPoint("LEFT", tab.minSkill, "RIGHT", 5, 0)
                tab.skillSeparator:SetText("-")
                tab.skillSeparator:SetTextColor(1, 1, 1, 0.7)
                
                tab.maxSkill = CreateFrame("EditBox", nil, tab.skillInputFrame)
                tab.maxSkill:SetSize(40, 24)
                tab.maxSkill:SetPoint("LEFT", tab.skillSeparator, "RIGHT", 5, 0)
                tab.maxSkill:SetAutoFocus(false)
                tab.maxSkill:SetNumeric(true)
                tab.maxSkill:SetMaxLetters(3)
                tab.maxSkill:SetText("")
                tab.maxSkill:SetCursorPosition(0)
                tab.maxSkill:SetFontObject("ChatFontNormal")
                tab.maxSkill:SetJustifyH("CENTER")
                StyleEditBox(tab.maxSkill)
                
                -- Кнопки (расположены справа под фильтрами)
                tab.buttonsFrame = CreateFrame("Frame", nil, tab.tradeGoodsFiltersFrame)
                tab.buttonsFrame:SetSize(400, 20)
                tab.buttonsFrame:SetPoint("TOP", tab.tradeGoodsFiltersFrame, "RIGHT", 0, -25)
                
                tab.resetButton = CreateFrame("Button", nil, tab.buttonsFrame, "UIPanelButtonTemplate")
                tab.resetButton:SetSize(100, 22)
                tab.resetButton:SetPoint("LEFT", tab.buttonsFrame, "LEFT", 0, 0)
                tab.resetButton:SetText("Сбросить")
                tab.resetButton:SetScript("OnClick", function()
                    tab.typeDropdown.selectedValues = {}
                    UIDropDownMenu_SetText(tab.typeDropdown, "Не выбрано")
                    
                    tab.qualityDropdown.selectedValues = {}
                    UIDropDownMenu_SetText(tab.qualityDropdown, "Не выбрано")
                    
                    tab.minSkill:SetText("")
                    tab.maxSkill:SetText("")
                    tab.minSkill:SetCursorPosition(0)
                    tab.maxSkill:SetCursorPosition(0)
                    
                    if tab.itemListContent then
                        tab.itemListContent:Hide()
                    end
                    
                    tab:UpdateFilterButtonState()
                end)
                
                tab.filterButton = CreateFrame("Button", nil, tab.buttonsFrame, "UIPanelButtonTemplate")
                tab.filterButton:SetSize(100, 22)
                tab.filterButton:SetPoint("LEFT", tab.resetButton, "RIGHT", 10, 0)
                tab.filterButton:SetText("Подобрать")
                tab.filterButton:Disable()
                
                tab.UpdateFilterButtonState = function()
                    local hasType = HasSelectedValues(tab.typeDropdown)
                    local hasQuality = HasSelectedValues(tab.qualityDropdown)
                    local hasSkill = tab.minSkill:GetText() ~= "" or tab.maxSkill:GetText() ~= ""
                    
                    -- Кнопка активна только если есть хотя бы один выбранный фильтр
                    if hasType or hasQuality or hasSkill then
                        tab.filterButton:Enable()
                    else
                        tab.filterButton:Disable()
                    end
                end
                
                tab.filterButton:SetScript("OnClick", function()
                    local minSkillLvl = tab.minSkill:GetText() ~= "" and tonumber(tab.minSkill:GetText()) or nil
                    local maxSkillLvl = tab.maxSkill:GetText() ~= "" and tonumber(tab.maxSkill:GetText()) or nil
                    
                    -- Определяем фильтры
                    local typesToFilter = HasSelectedValues(tab.typeDropdown) and tab.typeDropdown.selectedValues or nil
                    local qualitiesToFilter = HasSelectedValues(tab.qualityDropdown) and tab.qualityDropdown.selectedValues or nil
                    
                    tab:FilterItems(
                        typesToFilter,
                        minSkillLvl,
                        maxSkillLvl,
                        qualitiesToFilter
                    )
                end)
                
                -- Назначим обработчики для полей ввода уровня профессии
                local function UpdateOnTextChanged()
                    tab:UpdateFilterButtonState()
                end
                
                tab.minSkill:SetScript("OnTextChanged", UpdateOnTextChanged)
                tab.maxSkill:SetScript("OnTextChanged", UpdateOnTextChanged)
                
                -- Область для отображения результатов
                tab.itemList = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
                tab.itemList:SetSize(500, 300)
                tab.itemList:SetPoint("TOPLEFT", tab.tradeGoodsFiltersFrame, "BOTTOMLEFT", 0, -20)
                tab.itemList:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -30, 10)
                
                tab.itemListContent = CreateFrame("Frame", nil, tab.itemList)
                tab.itemListContent:SetSize(500, 1)
                tab.itemList:SetScrollChild(tab.itemListContent)
                
                tab.initialized = true
            end
            
            -- Показываем элементы фильтрации
            tab.tradeGoodsFiltersFrame:Show()
            tab.buttonsFrame:Show()
            tab.itemList:Show()
            
            -- Функция для обновления полосы прокрутки
            tab.UpdateScrollBar = function()
                local contentHeight = tab.itemListContent:GetHeight()
                local visibleHeight = tab.itemList:GetHeight()
                if contentHeight > visibleHeight then
                    tab.itemList.ScrollBar:Show()
                else
                    tab.itemList.ScrollBar:Hide()
                end
            end
            
            -- Обновляем полосу прокрутки
            if tab.UpdateScrollBar then
                tab.UpdateScrollBar()
            end
        end,
        
        FilterItems = function(tab, types, minSkill, maxSkill, qualities)
            if not ItemStorageBrowser.database then return end
            if not tab.itemListContent then return end
        
            -- Очищаем предыдущие результаты
            tab.itemListContent:Hide()
            tab.itemListContent:SetParent(nil)
            tab.itemListContent = CreateFrame("Frame", nil, tab.itemList)
            tab.itemListContent:SetSize(500, 1)
            tab.itemList:SetScrollChild(tab.itemListContent)
        
            local yOffset = 0
            local hasResults = false
        
            -- Группируем предметы по персонажам
            local groupedResults = {}
            for _, character in ipairs(ItemStorageBrowser.database) do
                local characterItems = {}
                for _, item in ipairs(character.items) do
                    local itemName, itemLink, itemQuality, _, _, itemType, itemSubType, _, _, _, _, itemClassID, itemSubClassID = GetItemInfo(item.link)
                    
                    -- Проверяем, является ли предмет хозяйственным товаром
                    if itemType == "Хозяйственные товары" or itemType == "Самоцветы" then
                        local matches = true

                        -- 1. Проверка типа товара (если выбраны типы)
                        if types then
                            local typeMatch = false
                            
                            -- Проверяем тип предмета на соответствие выбранным типам
                            for typeValue, selected in pairs(types) do
                                if selected then
                                    if typeValue == "Cloth" then
                                        -- Ткань/паутины
                                        if itemSubType == "Ткань" or itemSubType == "Cloth" then
                                            typeMatch = true
                                            break
                                        end
                                    elseif typeValue == "Leather" then
                                        -- Кожа/шкуры
                                        if itemSubType == "Кожа" or itemSubType == "Leather" or 
                                           itemSubType == "Шкура" or itemSubType == "Hide" or 
                                           itemSubType == "Чешуя" or itemSubType == "Scale" then
                                            typeMatch = true
                                            break
                                        end
                                    elseif typeValue == "Herb" then
                                        -- Трава
                                        if itemSubType == "Трава" or itemSubType == "Herb" then
                                            typeMatch = true
                                            break
                                        end
                                    elseif typeValue == "Metal" then
                                        -- Металл (только руда и слитки)
                                        if (itemSubType == "Металл и камень" or itemSubType == "Metal & Stone") and 
                                           (itemName:find("руда") or itemName:find("ore") or 
                                           itemName:find("слиток") or itemName:find("bar")) then
                                            typeMatch = true
                                            break
                                        end
                                    elseif typeValue == "Stone" then
                                        -- Камень (все что в классе предмета - "металл и камни", но только те, у которых в названии есть слово "камень")
                                        if (itemSubType == "Металл и камень" or itemSubType == "Metal & Stone") and 
                                           (itemName:find("камень") or itemName:find("stone")) then
                                            typeMatch = true
                                            break
                                        end
                                    elseif typeValue == "Gem" then
                                        -- Проверяем, что это самоцвет
                                        local isGem = (itemType == "Самоцветы" or itemType == "Gem")
                                        
                                        if isGem then
                                            -- Исключаем жемчужины по названию
                                            local isPearl = (itemName:find("жемчужина") or itemName:find("Жемчужина") or itemName:find("pearl") or itemName:find("Слеза Сирены"))
                                            
                                            if not isPearl then
                                                -- Проверяем тултип на наличие информации о слотах
                                                local isSocketGem = false
                                                local tooltip = CreateFrame("GameTooltip", "GemCheckTooltip", nil, "GameTooltipTemplate")
                                                tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
                                                tooltip:ClearLines()
                                                tooltip:SetHyperlink(item.link)
                                                
                                                for i = 2, tooltip:NumLines() do -- Начинаем с 2 строки, так как 1 - это название
                                                    local text = _G["GemCheckTooltipTextLeft"..i]:GetText()
                                                    if text and (text:find("гнезд") or text:find("socket") or 
                                                                text:find("голов") or text:find("head") or 
                                                                text:find("оружи") or text:find("weapon")) then
                                                        isSocketGem = true
                                                        break
                                                    end
                                                end
                                                
                                                tooltip:Hide()
                                                
                                                if not isSocketGem then
                                                    typeMatch = true
                                                    break
                                                end
                                            end
                                        end
                                    elseif typeValue == "Elemental" then
                                        -- Стихии
                                        if itemSubType == "Стихии" or itemSubType == "Elemental" then
                                            typeMatch = true
                                            break
                                        end
                                    elseif typeValue == "Pearl" then
                                        -- Жемчужины (простые самоцветы, у которых в названии есть: жемчужина, либо название - "Слеза Сирены")
                                        if (itemType == "Самоцветы" or itemType == "Gem") and 
                                           (itemName:find("жемчужина") or itemName:find("Жемчужина") or itemName:find("pearl") or 
                                            itemName == "Слеза Сирены") then
                                            typeMatch = true
                                            break
                                        end
                                    elseif typeValue == "Meat" then
                                        -- Мясо/Рыба (все что является мясом, кроме расходуемых предметов, восполняющих здоровье, ману и т.п.)
                                        if itemSubType == "Мясо" or itemSubType == "Meat" then
                                            typeMatch = true
                                        end
                                    elseif typeValue == "Enchanting" then
                                        -- Наложение чар
                                        if itemSubType == "Наложение чар" or itemSubType == "Enchanting" then
                                            typeMatch = true
                                            break
                                        end
                                    elseif typeValue == "Device" then
                                        -- Устройства
                                        if itemSubType == "Устройства" or itemSubType == "Devices" then
                                            typeMatch = true
                                            break
                                        end
                                    end
                                end
                            end
                            
                            matches = matches and typeMatch
                        end

                        -- 2. Проверка качества (если выбраны качества)
                        if qualities then
                            local qualityMatch = false
                            for qualityValue, selected in pairs(qualities) do
                                if selected and itemQuality and itemQuality == qualityValue then
                                    qualityMatch = true
                                    break
                                end
                            end
                            matches = matches and qualityMatch
                        end

                        -- 3. Проверка уровня профессии (если указаны границы)
                        if matches and (minSkill or maxSkill) then
                            local requiredSkill = 0
                            local tooltip = CreateFrame("GameTooltip", "TradeGoodsTooltipScanner", UIParent, "GameTooltipTemplate")
                            tooltip:SetOwner(UIParent, "ANCHOR_NONE")
                            tooltip:ClearLines()
                            tooltip:SetHyperlink(item.link)
                            
                            for i = 1, tooltip:NumLines() do
                                local text = _G["TradeGoodsTooltipScannerTextLeft"..i]:GetText()
                                if text then
                                    -- Ищем строку с требованием к профессии (пример: "Требуется Кузнечное дело (125)")
                                    local skillReq = text:match("Требуется.-(%d+)") or text:match("Requires.-(%d+)")
                                    if skillReq then
                                        requiredSkill = tonumber(skillReq) or 0
                                        break
                                    end
                                end
                            end
                            
                            tooltip:Hide()
                            
                            if minSkill and maxSkill then
                                -- Проверка диапазона
                                matches = matches and (requiredSkill >= minSkill and requiredSkill <= maxSkill)
                            elseif minSkill then
                                -- Только минимальный уровень
                                matches = matches and (requiredSkill >= minSkill)
                            elseif maxSkill then
                                -- Только максимальный уровень
                                matches = matches and (requiredSkill <= maxSkill)
                            end
                        end

                        if matches then
                            -- Получаем уровень предмета
                            local _, _, _, itemLevel, _, _, _, _, _, _, _, _ = GetItemInfo(item.link)
                            item.itemLevel = itemLevel or 0 -- Если не удалось получить уровень, используем 0
                            
                            -- Вставляем предмет в таблицу с сохранением уровня
                            table.insert(characterItems, item)
                        end
                    end
                end

                if #characterItems > 0 then
                    table.sort(characterItems, function(a, b)
                        -- Сначала сортируем по уровню (по возрастанию)
                        if a.itemLevel ~= b.itemLevel then
                            return a.itemLevel < b.itemLevel
                        end
                        -- Если уровни равны, сортируем по названию (по алфавиту)
                        return a.name < b.name
                    end)
                    
                    groupedResults[character.name] = characterItems
                    hasResults = true
                end
            end
            
            -- Если нет результатов, показываем сообщение
            if not hasResults then
                local noResultsText = tab.itemListContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                noResultsText:SetPoint("CENTER", tab.itemListContent, "CENTER", 0, 0)
                
                -- Проверяем, применены ли какие-либо фильтры
                local hasFilters = (types and next(types) ~= nil) or 
                                 (qualities and next(qualities) ~= nil) or
                                 tab.minSkill:GetText() ~= "" or tab.maxSkill:GetText() ~= ""
                if hasFilters then
                    noResultsText:SetText("Нет товаров, соответствующих фильтрам")
                else
                    noResultsText:SetText("Нет хозяйственных товаров в хранилище")
                end
                yOffset = yOffset - 30
            else
                -- Отображаем результаты по персонажам
                for characterName, items in pairs(groupedResults) do
                    -- Заголовок с именем персонажа
                    local characterHeader = tab.itemListContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    characterHeader:SetPoint("TOPLEFT", 0, yOffset)
                    characterHeader:SetText("Персонаж: " .. characterName)
                    yOffset = yOffset - 20
                    
                    -- Отображаем предметы для текущего персонажа
                    for _, item in ipairs(items) do
                        local itemFrame = CreateFrame("Frame", nil, tab.itemListContent)
                        itemFrame:SetSize(500, 30)
                        itemFrame:SetPoint("TOPLEFT", 0, yOffset)
                        
                        -- Иконка предмета
                        local itemIcon = CreateFrame("Button", nil, itemFrame)
                        itemIcon:SetSize(24, 24)
                        itemIcon:SetPoint("LEFT", itemFrame, "LEFT", 5, 0)
                        itemIcon:SetNormalTexture(GetItemIcon(item.link))
                        itemIcon:SetScript("OnEnter", function()
                            GameTooltip:SetOwner(itemIcon, "ANCHOR_RIGHT")
                            GameTooltip:SetHyperlink(item.link)
                            GameTooltip:Show()
                        end)
                        itemIcon:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                        end)
                        
                        -- Получаем цвет качества предмета
                        local quality = select(3, GetItemInfo(item.link)) or 1
                        local itemColor = ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or "|cffffffff"
                        
                        -- Кнопка-ссылка на предмет
                        local itemButton = CreateFrame("Button", nil, itemFrame)
                        itemButton:SetPoint("LEFT", itemIcon, "RIGHT", 10, 0)
                        itemButton:SetSize(380, 24)
                        
                        -- Название предмета как гиперссылка с цветом качества
                        itemButton.text = itemButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        itemButton.text:SetPoint("LEFT", itemButton, "LEFT", 0, 0)
                        itemButton.text:SetText(itemColor .. item.name .. "|r")
                        
                        -- Всплывающая подсказка
                        itemButton:SetScript("OnEnter", function()
                            GameTooltip:SetOwner(itemButton, "ANCHOR_RIGHT")
                            GameTooltip:SetHyperlink(item.link)
                            GameTooltip:Show()
                        end)
                        itemButton:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                        end)
                        
                        -- Вставка ссылки в чат при Shift+клике
                        itemIcon:SetScript("OnClick", function(self, button)
                            if IsShiftKeyDown() then
                                ChatEdit_InsertLink(item.link)
                            end
                        end)
                        
                        itemButton:SetScript("OnClick", function(self, button)
                            if IsShiftKeyDown() then
                                ChatEdit_InsertLink(item.link)
                            end
                        end)
                        
                        -- Текст количества предметов
                        local itemCountText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        itemCountText:SetPoint("LEFT", itemButton, "RIGHT", 10, 0)
                        itemCountText:SetText("x" .. item.count)
                        
                        yOffset = yOffset - 30
                    end
                end
            end
            
            -- Обновляем высоту контента
            tab.itemListContent:SetSize(500, math.abs(yOffset))
            -- Обновляем полосу прокрутки
            if tab.UpdateScrollBar then
                tab.UpdateScrollBar()
            end
        end,
        
        OnDeactivate = function(tab, container)
            tab.initialized = false
            -- Очищаем содержимое при деактивации
            if tab.tradeGoodsFiltersFrame then 
                tab.tradeGoodsFiltersFrame:Hide()
            end
            if tab.itemList then 
                tab.itemList:Hide()
            end
            if tab.itemListContent then
                tab.itemListContent:Hide()
            end
        end
    })
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    RegisterTradeGoodsTab()
    self:UnregisterEvent(event)
end)