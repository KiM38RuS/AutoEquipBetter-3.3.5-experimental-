local AEB = LibStub("AceAddon-3.0"):NewAddon("AutoEquipBetter", "AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0")

-- Скрытый тултип для сканирования
local scanner = CreateFrame("GameTooltip", "AEBScanner", nil, "GameTooltipTemplate")
scanner:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Таблица паттернов (базовый тип брони и оружия убран, так как используем API)
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
    -- Перехват клика по окну персонажа
    self:RawHook("PaperDollItemSlotButton_OnModifiedClick", true)
    -- Перехват клика в окне торговца
    self:RawHook("MerchantItemButton_OnModifiedClick", true)
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
    -- Используем API WoW для получения точной информации о типе и уровне предмета
    local itemName, _, _, _, itemMinLevel, itemType, itemSubType, _, itemEquipLoc, itemTexture = GetItemInfo(itemLink)
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

    -- Собираем базовую информацию о предмете (Слот, Тип, Требуемый уровень)
    local baseInfo = "\n|cffffd100Базовая информация:|r\n"
    if itemEquipLoc and itemEquipLoc ~= "" and _G[itemEquipLoc] then
        baseInfo = baseInfo .. "Слот: " .. _G[itemEquipLoc] .. "\n"
    end
    if itemSubType and itemType ~= "Хозяйственные товары" then
        baseInfo = baseInfo .. "Тип: " .. itemSubType .. "\n"
    end
    if itemMinLevel and itemMinLevel > 1 then
        baseInfo = baseInfo .. "Треб. уровень: " .. itemMinLevel .. "\n"
    end

    -- Вывод характеристик
    local statsLabel = AceGUI:Create("Label")
    local statsText = baseInfo .. "\n|cffffd100Найденные характеристики:|r\n"
    if #stats > 0 then
        statsText = statsText .. table.concat(stats, "\n")
    else
        statsText = statsText .. "|cff888888Статы не распознаны|r"
    end
    statsLabel:SetText(statsText)
    statsLabel:SetFullWidth(true)
    frame:AddChild(statsLabel)
end

-- Обработка клика в сумках
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

-- Обработка клика на персонаже
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

-- Новое: Обработка клика в окне торговца
function AEB:MerchantItemButton_OnModifiedClick(frame, button)
    -- Проверяем Ctrl + Shift + ЛКМ
    if IsControlKeyDown() and IsShiftKeyDown() and button == "LeftButton" then
        local slot = frame:GetID()
        local itemLink = GetMerchantItemLink(slot)
        if itemLink then
            self:ShowWindow(itemLink)
        end
        return -- Прерываем оригинальный вызов, чтобы не купить предмет случайно
    end
    return self.hooks.MerchantItemButton_OnModifiedClick(frame, button)
end