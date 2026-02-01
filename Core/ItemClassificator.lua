local addonName, ItemStorageBrowser = ...

-- Таблица для хранения классифицированных предметов
ItemClassificatorDB = ItemClassificatorDB or {
    lastUpdate = 0,
    items = {},
    categories = {},
}

-- Вспомогательная функция для подсчета общего количества предметов
local function GetTotalItemCount()
    local total = 0
    for _, itemData in pairs(ItemClassificatorDB.items) do
        total = total + (itemData.totalCount or 0)
    end
    return total
end

local function InitializeClassificator()
    -- Проверяем, нужно ли обновлять классификатор
    if not ItemStorageDB or ItemClassificatorDB.lastUpdate >= ItemStorageDB_LastUpdate then
        return
    end

    -- Сбрасываем данные классификатора
    ItemClassificatorDB.items = {}
    ItemClassificatorDB.categories = {
        armor = { subtype = {} },
        weapon = { subtype = {} },
        consumable = { subtype = {} },
        container = { subtype = {} },
        gem = { subtype = {} },
        glyph = { subtype = {} },
        key = { subtype = {} },
        misc = { subtype = {} },
        recipe = { subtype = {} },
        projectile = { subtype = {} },
        quest = { subtype = {} },
        quiver = { subtype = {} },
        reagent = { subtype = {} },
        tradegoods = { subtype = {} },
    }

    local totalItems = 0
    local classifiedItems = 0

    -- Собираем все уникальные ссылки на предметы
    local itemLinks = {}
    for _, character in ipairs(ItemStorageDB) do
        for _, item in ipairs(character.items) do
            if item.link and not itemLinks[item.link] then
                itemLinks[item.link] = true
                totalItems = totalItems + 1
            end
        end
    end

    -- Классифицируем каждый предмет
    for link in pairs(itemLinks) do
        local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, 
              itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(link)

        if itemName then
            local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
            
            -- Создаем запись о предмете
            ItemClassificatorDB.items[itemID] = {
                id = itemID,
                name = itemName,
                link = itemLink,
                rarity = itemRarity,
                level = itemLevel,
                minLevel = itemMinLevel,
                type = itemType,
                subtype = itemSubType,
                stackCount = itemStackCount,
                equipLoc = itemEquipLoc,
                texture = itemTexture,
                sellPrice = itemSellPrice,
                totalCount = 0, -- Будем считать ниже
            }

            -- Добавляем категории и подкатегории
            if itemType and not ItemClassificatorDB.categories[itemType] then
                ItemClassificatorDB.categories[itemType] = { subtype = {} }
            end
            if itemType and itemSubType and not ItemClassificatorDB.categories[itemType].subtype[itemSubType] then
                ItemClassificatorDB.categories[itemType].subtype[itemSubType] = true
            end

            classifiedItems = classifiedItems + 1
        end
    end

    -- Подсчитываем общее количество каждого предмета
    for _, character in ipairs(ItemStorageDB) do
        for _, item in ipairs(character.items) do
            if item.link then
                local itemID = tonumber(string.match(item.link, "item:(%d+)"))
                if itemID and ItemClassificatorDB.items[itemID] then
                    ItemClassificatorDB.items[itemID].totalCount = (ItemClassificatorDB.items[itemID].totalCount or 0) + item.count
                end
            end
        end
    end

    -- Обновляем время последнего обновления
    ItemClassificatorDB.lastUpdate = ItemStorageDB_LastUpdate

    -- Выводим результаты в чат
    print(string.format("|cFF00FF00Item Storage Browser:|r Классификация предметов завершена."))
    print(string.format("Обработано предметов: %d/%d (уникальных)", classifiedItems, totalItems))
    print(string.format("Всего предметов в хранилище: %d", GetTotalItemCount()))
end

-- Регистрируем инициализацию классификатора
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitializeClassificator()
        self:UnregisterEvent(event)
    end
end)

-- Экспортируем функции для использования в других модулях
ItemStorageBrowser.ClassifyItems = InitializeClassificator
ItemStorageBrowser.GetItemClassification = function() return ItemClassificatorDB end