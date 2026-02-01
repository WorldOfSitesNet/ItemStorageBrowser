local addonName, ItemStorageInfo = ...

-- Аддон ItemStorageInfo
local ItemStorageInfo = CreateFrame("Frame")

-- Переменная для хранения данных из database.lua
local itemStorageDB = {}

-- Функция для загрузки данных из database.lua
local lastUpdateTime = 0

local function LoadDatabase()
    if ItemStorageDB_LastUpdate and ItemStorageDB_LastUpdate > lastUpdateTime then
        lastUpdateTime = ItemStorageDB_LastUpdate
        if ItemStorageDB then
            itemStorageDB = ItemStorageDB
        else
            print("ItemStorageInfo: Database not found or is empty.")
        end
    end
end

-- Функция для поиска информации о предмете в базе данных
local function GetItemStorageInfo(itemLink)
    -- Получаем имя предмета из itemLink
    local itemName = GetItemInfo(itemLink)
    if not itemName then
        -- Если информация о предмете ещё не загружена, возвращаем nil
        return
    end

    LoadDatabase()

    local storageInfo = {}
    for _, characterData in ipairs(itemStorageDB) do
        for _, itemData in ipairs(characterData.items) do
            -- Сравниваем itemLink из базы данных с текущим itemLink
            if itemData.name == itemName then
                table.insert(storageInfo, {
                    character = characterData.name,
                    count = itemData.count
                })
            end
        end
    end

    return storageInfo
end

-- Функция для добавления информации о складах в подсказку
local function AddStorageInfoToTooltip(tooltip, itemLink)
    local storageInfo = GetItemStorageInfo(itemLink)
    if not storageInfo or #storageInfo == 0 then return end

    -- Добавляем разделитель
    tooltip:AddLine(" ")

    -- Добавляем информацию о складах
    for _, info in ipairs(storageInfo) do
        -- Оранжевый цвет для количества предметов (RGB: 1, 0.5, 0)
        tooltip:AddDoubleLine("Склад: " .. info.character, info.count, 1, 1, 1, 1, 0.5, 0)
    end

    tooltip:AddLine(" ")
end

-- Функция для модификации подсказки к предмету
local function ModifyItemTooltip(tooltip)
    -- Перезагружаем базу данных перед каждым обновлением подсказки
    LoadDatabase()

    local itemLink = select(2, tooltip:GetItem())
    if not itemLink then return end

    -- Добавляем информацию о складах в подсказку
    AddStorageInfoToTooltip(tooltip, itemLink)
end

-- Функция для модификации окна предмета
local function ModifyItemRefTooltip(tooltip)
    -- Перезагружаем базу данных перед каждым обновлением подсказки
    LoadDatabase()

    local itemLink = select(2, tooltip:GetItem())
    if not itemLink then return end

    -- Добавляем информацию о складах в окно предмета
    AddStorageInfoToTooltip(tooltip, itemLink)
end

-- Обработчик событий
ItemStorageInfo:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == "ItemStorageInfo" then
        LoadDatabase()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Регистрируем событие загрузки аддона
ItemStorageInfo:RegisterEvent("ADDON_LOADED")

-- Хук на отображение подсказки к предмету
GameTooltip:HookScript("OnTooltipSetItem", ModifyItemTooltip)

-- Хук на отображение окна предмета
ItemRefTooltip:HookScript("OnTooltipSetItem", ModifyItemRefTooltip)