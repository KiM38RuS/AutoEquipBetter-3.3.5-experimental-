local AEB = LibStub("AceAddon-3.0"):NewAddon("AutoEquipBetter", "AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0")

-- Скрытый тултип для сканирования
local scanner = CreateFrame("GameTooltip", "AEBScanner", nil, "GameTooltipTemplate")
scanner:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Обновлённая таблица паттернов под твои скриншоты
local patterns = {
    ["Сила"] = "%+(%d+) к силе",
    ["Ловкость"] = "%+(%d+) к ловкости",
    ["Выносливость"] = "%+(%d+) к выносливости",
    ["Интеллект"] = "%+(%d+) к интеллекту",
    ["Дух"] = "%+(%d+) к духу",
    ["Броня"] = "Броня: (%d+)", 
    ["Ур. предмета"] = "Уровень предмета: (%d+)",
    ["Урон"] = "Урон: (%d+ %- %d+)",
    ["Скорость"] = "Скорость (%d+%.%d+)",
    ["DPS"] = "%((%d+%.%d+) ед%. урона в секунду%)"
}

function AEB:OnInitialize()
    -- Перехватываем клик по сумкам
    self:RawHook("ContainerFrameItemButton_OnModifiedClick", true)
    -- Исправленный перехват клика по окну персонажа
    self:RawHook("PaperDollItemSlotButton_OnModifiedClick", true)
end

-- Функция сканирования тултипа
function AEB:ScanItem(itemLink)
    scanner:ClearLines()
    scanner:SetHyperlink(itemLink)
    
    local foundStats = {}
    for i = 1, scanner:NumLines() do
        local leftLine = _G["AEBScannerTextLeft"..i]
        local text = leftLine:GetText()
        
        if text then
            for statName, pattern in pairs(patterns) do
                local value = text:match(pattern)
                if value then
                    table.insert(foundStats, statName .. ": " .. value)
                end
            end
            
            -- Поиск "Зелёных" эффектов
            if text:find("Если на персонаже:") or text:find("Использование:") then
                table.insert(foundStats, "|cff00ff00Эффект:|r " .. text)
            end
        end
    end
    return foundStats
end

-- Создание окна AceGUI
function AEB:ShowWindow(itemLink)
    local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemLink)
    local stats = self:ScanItem(itemLink)
    
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Анализ предмета")
    frame:SetStatusText("AutoEquipBetter v1.0")
    frame:SetLayout("List")
    frame:SetWidth(300)
    frame:SetHeight(400)

    -- Иконка и название
    local header = AceGUI:Create("Label")
    header:SetText("|T" .. itemTexture .. ":24:24|t  " .. itemLink)
    header:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    header:SetFullWidth(true)
    frame:AddChild(header)

    -- Вывод характеристик
    local statsLabel = AceGUI:Create("Label")
    local statsText = "\nНайденные характеристики:\n\n"
    if #stats > 0 then
        statsText = statsText .. table.concat(stats, "\n")
    else
        statsText = statsText .. "|cffff0000Статы не распознаны|r"
    end
    statsLabel:SetText(statsText)
    statsLabel:SetFullWidth(true)
    frame:AddChild(statsLabel)
end

-- Обновлённая обработка кликов (frame, button)
function AEB:ContainerFrameItemButton_OnModifiedClick(frame, button)
    if IsControlKeyDown() and IsShiftKeyDown() and button == "RightButton" then
        local bag, slot = frame:GetParent():GetID(), frame:GetID()
        local itemLink = GetContainerItemLink(bag, slot)
        if itemLink then
            self:ShowWindow(itemLink)
        end
        return 
    end
    return self.hooks.ContainerFrameItemButton_OnModifiedClick(frame, button)
end

function AEB:PaperDollItemSlotButton_OnModifiedClick(frame, button)
    if IsControlKeyDown() and IsShiftKeyDown() and button == "RightButton" then
        local slot = frame:GetID()
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            self:ShowWindow(itemLink)
        end
        return
    end
    return self.hooks.PaperDollItemSlotButton_OnModifiedClick(frame, button)
end