local addonName, ItemStorageBrowser = ...

-- Инициализация базы данных
ItemStorageBrowserDB = ItemStorageBrowserDB or {
    minimapAngle = 148.2497927517446,
}

-- Основной фрейм аддона
local frame = CreateFrame("Frame", "ItemStorageBrowserFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(600, 400)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

-- Настраиваем прозрачность фона
frame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

-- Флаг для отслеживания состояния фокуса
frame.hasFocus = false

-- Заголовок
frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
frame.title:SetText("Item Storage Browser")

-- Функция установки фокуса
function frame:SetFocus(hasFocus)
    self.hasFocus = hasFocus
    if hasFocus then
        -- При фокусе - более непрозрачный фон (0.8)
        self:SetBackdropColor(0, 0, 0, .8)
        self:EnableKeyboard(true) -- Включаем обработку клавиш при фокусе
    else
        -- Без фокуса - более прозрачный фон (0.6)
        self:SetBackdropColor(0, 0, 0, .6)
        self:EnableKeyboard(false) -- Отключаем обработку клавиш при потере фокуса
    end
end

-- Инициализируем прозрачность при создании
frame:SetBackdropColor(0, 0, 0, .6) -- Начальное состояние - без фокуса

-- Обработчик клика по фрейму
frame:SetScript("OnMouseDown", function(self)
    self:SetFocus(true)
end)

-- Обработчик потери фокуса
frame:SetScript("OnHide", function(self)
    self:SetFocus(false)
end)

-- Глобальный обработчик Esc - закрывает окно независимо от фокуса
local function OnGlobalKeyDown(_, key)
    if key == "ESCAPE" and frame:IsShown() then
        frame:Hide()
        return false -- Блокируем дальнейшую обработку Esc
    end
    return true
end

-- Регистрируем глобальный обработчик клавиш
frame:RegisterEvent("GLOBAL_KEY_DOWN")
frame:SetScript("OnEvent", function(self, event, key)
    if event == "GLOBAL_KEY_DOWN" then
        OnGlobalKeyDown(key)
    end
end)

-- Обработчик клика вне фрейма
local function OnGlobalMouseUp(_, button)
    if frame:IsShown() and frame.hasFocus then
        local mouseFocus = GetMouseFocus()
        local isChild = false
        
        -- Проверяем, является ли элемент под курсором дочерним для нашего фрейма
        if mouseFocus then
            local parent = mouseFocus:GetParent()
            while parent do
                if parent == frame then
                    isChild = true
                    break
                end
                parent = parent:GetParent()
            end
        end
        
        -- Если клик был вне фрейма и его дочерних элементов
        if not isChild and mouseFocus ~= frame then
            frame:SetFocus(false)
            -- Снимаем фокус со всех дочерних элементов
            for i, child in ipairs({frame:GetChildren()}) do
                if child.HasFocus and child:HasFocus() then
                    child:ClearFocus()
                end
            end
        end
    end
end

-- Регистрируем обработчик клика
frame:RegisterEvent("GLOBAL_MOUSE_UP")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "GLOBAL_MOUSE_UP" then
        OnGlobalMouseUp(...)
    end
end)

-- Функция загрузки базы данных
function ItemStorageBrowser:LoadDatabase()
    if not ItemStorageDB then return end
    self.database = ItemStorageDB
end

-- Экспортируем основной фрейм
ItemStorageBrowser.frame = frame

-- Инициализация при загрузке
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    ItemStorageBrowser:LoadDatabase()
    self:UnregisterEvent(event)
end)

-- Команды чата
SLASH_ITEMSTORAGEBROWSER1 = "/isb"
SlashCmdList["ITEMSTORAGEBROWSER"] = function(msg)
    if msg == "" then
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
            frame:SetFocus(true)
        end
    elseif msg == "show" then
        frame:Show()
        frame:SetFocus(true)
    elseif msg == "hide" then
        frame:Hide()
    else
        print("Используйте: /isb, /isb show, /isb hide")
    end
end