local AEB = LibStub("AceAddon-3.0"):NewAddon("AutoEquipBetter", "AceEvent-3.0", "AceHook-3.0")

local scanner = CreateFrame("GameTooltip", "AEBScanner", nil, "GameTooltipTemplate")
scanner:SetOwner(WorldFrame, "ANCHOR_NONE")

local statConfig = {
    ["Сила"] = "%+(%d+) к силе",
    ["Ловкость"] = "%+(%d+) к ловкости",
    ["Выносливость"] = "%+(%d+) к выносливости",
    ["Интеллект"] = "%+(%d+) к интеллекту",
    ["Дух"] = "%+(%d+) к духу",
    ["Броня"] = "Броня: (%d+)", 
    ["Сила атаки"] = "%+(%d+) к силе атаки", -- Добавил для ханта
}

-- ВЕСА ХАРАКТЕРИСТИК (EP - Equivalence Points)
-- Пока захардкожены для теста (пример для Охотника)
local statWeights = {
    ["Ловкость"] = 2.5,
    ["Сила атаки"] = 1.0,
    ["Выносливость"] = 0.5,
    ["Интеллект"] = 0.2,
    ["Броня"] = 0.05,
    ["Сила"] = 0.1,
    ["Дух"] = 0.0
}

local equipSlotMap = {
    ["INVTYPE_HEAD"] = 1, ["INVTYPE_NECK"] = 2, ["INVTYPE_SHOULDER"] = 3,
    ["INVTYPE_BODY"] = 4, ["INVTYPE_CHEST"] = 5, ["INVTYPE_ROBE"] = 5,
    ["INVTYPE_WAIST"] = 6, ["INVTYPE_LEGS"] = 7, ["INVTYPE_FEET"] = 8,
    ["INVTYPE_WRIST"] = 9, ["INVTYPE_HAND"] = 10, ["INVTYPE_FINGER"] = 11,
    ["INVTYPE_TRINKET"] = 13, ["INVTYPE_CLOAK"] = 15, ["INVTYPE_WEAPON"] = 16,
    ["INVTYPE_SHIELD"] = 17, ["INVTYPE_2HWEAPON"] = 16, ["INVTYPE_WEAPONMAINHAND"] = 16,
    ["INVTYPE_WEAPONOFFHAND"] = 17, ["INVTYPE_HOLDABLE"] = 17,
    ["INVTYPE_RANGED"] = 18, ["INVTYPE_THROWN"] = 18, ["INVTYPE_RANGEDRIGHT"] = 18,
    ["INVTYPE_RELIC"] = 18, ["INVTYPE_TABARD"] = 19
}

-- Таблица для запоминания уже проверенных вещей (чтобы окно не спамило)
local suggestedItems = {}
local mainFrame = nil

function AEB:OnInitialize()
    self:RegisterEvent("BAG_UPDATE")
    
    -- Оставляем ручной клик для тестов
    self:RawHook("ContainerFrameItemButton_OnModifiedClick", true)
end

function AEB:ScanItem(itemLink)
    scanner:ClearLines()
    scanner:SetHyperlink(itemLink)
    local stats = {}
    for i = 1, scanner:NumLines() do
        local leftLine = _G["AEBScannerTextLeft"..i]
        local text = leftLine:GetText()
        if text then
            for statName, pattern in pairs(statConfig) do
                local value = text:match(pattern)
                if value then
                    local numValue = tonumber(value)
                    if numValue then stats[statName] = numValue else stats[statName] = value end
                end
            end
        end
    end
    return stats
end

-- Функция подсчёта полезности вещи
function AEB:CalculateScore(stats)
    local score = 0
    for statName, value in pairs(stats) do
        if type(value) == "number" and statWeights[statName] then
            score = score + (value * statWeights[statName])
        end
    end
    return score
end

-- Обработка изменения сумок
function AEB:BAG_UPDATE(event, bagId)
    -- Не сканируем в бою (защита от ошибок смены экипировки)
    if InCombatLockdown() then return end

    for slot = 1, GetContainerNumSlots(bagId) do
        local itemLink = GetContainerItemLink(bagId, slot)
        if itemLink and IsEquippableItem(itemLink) then
            -- Вытаскиваем уникальный ID предмета
            local itemID = itemLink:match("item:(%d+)")
            
            -- Если мы эту вещь ещё не проверяли
            if itemID and not suggestedItems[itemID] then
                local _, _, _, _, itemMinLevel, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
                local playerLevel = UnitLevel("player")
                
                -- Проверяем, подходит ли по уровню
                if not itemMinLevel or itemMinLevel <= playerLevel then
                    local newStats = self:ScanItem(itemLink)
                    local newScore = self:CalculateScore(newStats)
                    
                    local slotId = equipSlotMap[itemEquipLoc]
                    local oldScore = 0
                    
                    if slotId then
                        local equippedLink = GetInventoryItemLink("player", slotId)
                        if equippedLink then
                            local oldStats = self:ScanItem(equippedLink)
                            oldScore = self:CalculateScore(oldStats)
                        end
                    end
                    
                    -- Если новая вещь ЛУЧШЕ старой (счёт выше)
                    if newScore > oldScore then
                        suggestedItems[itemID] = true -- Запоминаем, чтобы не спамить
                        self:CreateCustomUI(itemLink, bagId, slot)
                        return -- Прерываем цикл, показываем по одной шмотке за раз
                    end
                end
            end
        end
    end
end

-- Отрисовка нашего собственного окна
function AEB:CreateCustomUI(newItemLink, bagId, slot)
    -- Если окно уже есть, просто обновляем его, иначе создаём с нуля
    if not mainFrame then
        mainFrame = CreateFrame("Frame", "AEBMainFrame", UIParent)
        mainFrame:SetSize(400, 250)
        mainFrame:SetPoint("CENTER")
        
        -- Стандартный близзардовский фон с рамкой
        mainFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        mainFrame:EnableMouse(true)
        mainFrame:SetMovable(true)
        mainFrame:RegisterForDrag("LeftButton")
        mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
        mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
        
        -- Текст
        mainFrame.text = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mainFrame.text:SetPoint("TOP", 0, -20)
        
        -- Кнопка "Надеть" (ОК)
        mainFrame.btnEquip = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
        mainFrame.btnEquip:SetSize(100, 30)
        mainFrame.btnEquip:SetPoint("BOTTOMLEFT", 20, 20)
        mainFrame.btnEquip:SetText("Надеть")
        
        -- Кнопка "Отмена"
        mainFrame.btnCancel = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
        mainFrame.btnCancel:SetSize(100, 30)
        mainFrame.btnCancel:SetPoint("BOTTOMRIGHT", -20, 20)
        mainFrame.btnCancel:SetText("Отмена")
        
        mainFrame.btnCancel:SetScript("OnClick", function()
            mainFrame:Hide()
        end)
    end
    
    -- Обновляем данные в окне
    mainFrame.text:SetText("Найдена лучшая экипировка!\n\n" .. newItemLink)
    
    -- Настраиваем кнопку "Надеть" под конкретную шмотку
    mainFrame.btnEquip:SetScript("OnClick", function()
        if not InCombatLockdown() then
            -- Используем вещь из сумки (эквивалент клика ПКМ)
            UseContainerItem(bagId, slot)
            mainFrame:Hide()
        else
            print("|cffff0000AutoEquipBetter:|r Нельзя менять броню в бою!")
        end
    end)
    
    mainFrame:Show()
end

-- Оставляем ручной тест для дебага (считает Score и пишет в чат)
function AEB:ContainerFrameItemButton_OnModifiedClick(frame, button)
    if IsControlKeyDown() and IsShiftKeyDown() and button == "RightButton" then
        local bag, slot = frame:GetParent():GetID(), frame:GetID()
        local itemLink = GetContainerItemLink(bag, slot)
        if itemLink then
            local stats = self:ScanItem(itemLink)
            local score = self:CalculateScore(stats)
            print("Score предмета " .. itemLink .. ": " .. score)
        end
        return 
    end
    return self.hooks.ContainerFrameItemButton_OnModifiedClick(frame, button)
end