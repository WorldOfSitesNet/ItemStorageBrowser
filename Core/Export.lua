--[[ local function Log(msg)
    print("|cff00ff00[ItemExport]:|r " .. tostring(msg))
end

local function Debug(msg)
    print("|cffffff00[ItemExport DEBUG]:|r " .. tostring(msg))
end ]] --

local function InsertToChat(msg)

    local editBox = ChatEdit_GetActiveWindow()

    if not editBox then
        ChatFrame_OpenChat(msg)
    else
        editBox:Insert(msg)
    end

end

--------------------------------------------------
-- Сканирование сумок
--------------------------------------------------
local function ScanBags()

    local items = {}

    local itemCount = 0

    local freeBagSlots = 0
    local freeBankSlots = 0

    local inventoryBags = {0, 1, 2, 3, 4}
    local bankBags = {-1, 5, 6, 7, 8, 9, 10, 11}

    local function ScanBagList(bagList, isBank)

        for _, bagID in ipairs(bagList) do

            local slots = GetContainerNumSlots(bagID) or 0

            for slot = 1, slots do

                local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bagID, slot)

                if link then

                    local id = tonumber(link:match("item:(%d+)")) or 0

                    local itemName, itemLink, itemQuality, _, _, itemType, itemSubType = GetItemInfo(link)

                    table.insert(items, {
                        item_id = id,
                        item_count = count or 1,
                        item_name = itemName or "Unknown",
                        item_link = itemLink or link,
                        item_quality = itemQuality or quality or 0,
                        item_type = itemType or "Unknown",
                        item_subtype = itemSubType or "Unknown"
                    })

                    itemCount = itemCount + 1

                else
                    if isBank then
                        freeBankSlots = freeBankSlots + 1
                    else
                        freeBagSlots = freeBagSlots + 1
                    end
                end
            end
        end
    end

    ScanBagList(inventoryBags, false)
    ScanBagList(bankBags, true)

    return items, itemCount, freeBagSlots, freeBankSlots
end

--------------------------------------------------
-- Обновление экспортных данных
--------------------------------------------------

local function UpdateExportData()

    local name = UnitName("player")
    if not name then
        return
    end

    local items, itemCount, freeBagSlots, freeBankSlots = ScanBags()

    -- защита от очистки сумок при logout
    if itemCount == 0 then
        -- Debug("Scan returned 0 items. Previous data preserved.")
        return
    end

    if not ItemStorage_ExportData then
        ItemStorage_ExportData = {}
    end

    ItemStorage_ExportData.character = name
    ItemStorage_ExportData.timestamp = time()
    ItemStorage_ExportData.location = GetRealZoneText() or "Unknown"
    ItemStorage_ExportData.money = GetMoney() or 0
    ItemStorage_ExportData.items = items

    ItemStorage_ExportData.free_bag_slots = freeBagSlots
    ItemStorage_ExportData.free_bank_slots = freeBankSlots
    ItemStorage_ExportData.free_total_slots = freeBagSlots + freeBankSlots

    -- Log("Export updated. Items: " .. itemCount)
end

--------------------------------------------------
-- Event handler
--------------------------------------------------

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("BANKFRAME_OPENED")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event)

    if event == "PLAYER_ENTERING_WORLD" then
        -- Log("Player entered world.")
        UpdateExportData()

    elseif event == "BAG_UPDATE" then
        UpdateExportData()

    elseif event == "BANKFRAME_OPENED" then
        -- Log("Bank opened.")
        UpdateExportData()

    elseif event == "PLAYER_LOGOUT" then
        -- Log("Logout detected. Using last stored snapshot.")
    end

end)

--------------------------------------------------
-- Slash command
--------------------------------------------------

SLASH_EXPORT1 = "/export"

SlashCmdList["EXPORT"] = function()

    -- Log("Manual export triggered.")
    UpdateExportData()

end

SLASH_BAGFREE1 = "/bagfree"
SlashCmdList["BAGFREE"] = function()

    local _, _, bagFree, _ = ScanBags()

    InsertToChat("В сумках " .. bagFree .. " свободных мест")

end

SLASH_BANKFREE1 = "/bankfree"
SlashCmdList["BANKFREE"] = function()

    local _, _, _, bankFree = ScanBags()

    InsertToChat("В банке " .. bankFree .. " свободных мест")

end

SLASH_TOTALFREE1 = "/free"
SlashCmdList["TOTALFREE"] = function()

    local _, _, bagFree, bankFree = ScanBags()

    InsertToChat("Свободных мест всего: " .. (bagFree + bankFree))

end
