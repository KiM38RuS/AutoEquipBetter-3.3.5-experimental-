local frame = CreateFrame("Frame")

local debounceDelay = 1.0
local timer = 0
local waiting = false

local slots = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot",
    "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot",
    "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot",
    "MainHandSlot", "SecondaryHandSlot"
}

local slotToInvType = {
    HeadSlot = "INVTYPE_HEAD",
    NeckSlot = "INVTYPE_NECK",
    ShoulderSlot = "INVTYPE_SHOULDER",
    BackSlot = "INVTYPE_CLOAK",
    ChestSlot = "INVTYPE_CHEST",
    WristSlot = "INVTYPE_WRIST",
    HandsSlot = "INVTYPE_HAND",
    WaistSlot = "INVTYPE_WAIST",
    LegsSlot = "INVTYPE_LEGS",
    FeetSlot = "INVTYPE_FEET",
    Finger0Slot = "INVTYPE_FINGER",
    Finger1Slot = "INVTYPE_FINGER",
    Trinket0Slot = "INVTYPE_TRINKET",
    Trinket1Slot = "INVTYPE_TRINKET",
    MainHandSlot = "INVTYPE_WEAPONMAINHAND",
    SecondaryHandSlot = "INVTYPE_WEAPONOFFHAND",
}

local statPriority = {
    ["WARRIOR"] = { Strength=10, Agility=5, Stamina=8, Armor=6, Intellect=1, Spirit=1 },
    ["PALADIN"] = { Strength=10, Stamina=9, Intellect=6, Spirit=5, Armor=5, Agility=2 },
    ["HUNTER"] = { Agility=10, Stamina=8, Strength=5, Armor=5, Intellect=2, Spirit=1 },
    ["ROGUE"] = { Agility=10, Strength=7, Stamina=6, Armor=5, Intellect=1, Spirit=1 },
    ["PRIEST"] = { Intellect=10, Spirit=9, Stamina=7, Armor=3, Strength=1, Agility=1 },
    ["DEATHKNIGHT"] = { Strength=10, Stamina=9, Armor=7, Agility=3, Intellect=1, Spirit=1 },
    ["SHAMAN"] = { Intellect=10, Agility=7, Stamina=7, Spirit=6, Armor=5, Strength=2 },
    ["MAGE"] = { Intellect=10, Spirit=8, Stamina=6, Armor=3, Strength=1, Agility=1 },
    ["WARLOCK"] = { Intellect=10, Stamina=8, Spirit=7, Armor=3, Strength=1, Agility=1 },
    ["DRUID"] = { Agility=9, Intellect=8, Stamina=8, Spirit=7, Armor=5, Strength=3 },
}

local allowedWeapons = {
    WARRIOR = { ["One-Handed Axes"]=true, ["Two-Handed Axes"]=true, ["One-Handed Swords"]=true, ["Two-Handed Swords"]=true, ["Polearms"]=true, ["Daggers"]=true, ["Staves"]=true, ["Maces"]=true, ["Two-Handed Maces"]=true, ["Bows"]=true, ["Guns"]=true, ["Crossbows"]=true, ["Thrown"]=true, ["Fist Weapons"]=true, ["Shields"]=true },
    PALADIN = { ["One-Handed Swords"]=true, ["Two-Handed Swords"]=true, ["One-Handed Maces"]=true, ["Two-Handed Maces"]=true, ["Polearms"]=true, ["Shields"]=true },
    HUNTER = { ["Bows"]=true, ["Guns"]=true, ["Crossbows"]=true, ["One-Handed Axes"]=true, ["Two-Handed Axes"]=true, ["Polearms"]=true, ["Staves"]=true, ["Daggers"]=true, ["Fist Weapons"]=true, ["One-Handed Swords"]=true, ["Two-Handed Swords"]=true },
    ROGUE = { ["Daggers"]=true, ["One-Handed Swords"]=true, ["One-Handed Maces"]=true, ["Fist Weapons"]=true, ["Bows"]=true, ["Guns"]=true, ["Crossbows"]=true, ["Thrown"]=true },
    PRIEST = { ["Staves"]=true, ["One-Handed Maces"]=true, ["Daggers"]=true, ["Wands"]=true },
    DEATHKNIGHT = { ["One-Handed Axes"]=true, ["Two-Handed Axes"]=true, ["One-Handed Swords"]=true, ["Two-Handed Swords"]=true, ["Polearms"]=true, ["One-Handed Maces"]=true, ["Two-Handed Maces"]=true },
    SHAMAN = { ["One-Handed Maces"]=true, ["Two-Handed Maces"]=true, ["Staves"]=true, ["Daggers"]=true, ["Fist Weapons"]=true, ["One-Handed Axes"]=true, ["Two-Handed Axes"]=true, ["Shields"]=true },
    MAGE = { ["Staves"]=true, ["Daggers"]=true, ["Wands"]=true, ["One-Handed Swords"]=true },
    WARLOCK = { ["Staves"]=true, ["Daggers"]=true, ["Wands"]=true, ["One-Handed Swords"]=true },
    DRUID = { ["Staves"]=true, ["Daggers"]=true, ["Fist Weapons"]=true, ["One-Handed Maces"]=true, ["Two-Handed Maces"]=true },
}

local playerClass = select(2, UnitClass("player"))
local playerLevel = UnitLevel("player")

-- allowedArmor с учётом уровня и класса
local allowedArmor = {
    WARRIOR = { Cloth=true, Leather=true, Mail=true, Plate=true, Shields=true },
    PALADIN = { Cloth=true, Leather=true, Mail=true, Plate=true, Shields=true },
    HUNTER = nil, -- будет заполнено ниже
    ROGUE = { Cloth=true, Leather=true },
    PRIEST = { Cloth=true },
    DEATHKNIGHT = { Cloth=true, Leather=true, Mail=true, Plate=true },
    SHAMAN = nil, -- будет заполнено ниже
    MAGE = { Cloth=true },
    WARLOCK = { Cloth=true },
    DRUID = { Cloth=true, Leather=true },
}

if playerClass == "HUNTER" then
    if playerLevel < 40 then
        allowedArmor.HUNTER = { Cloth=true, Leather=true }
    else
        allowedArmor.HUNTER = { Cloth=true, Leather=true, Mail=true }
    end
end
if playerClass == "SHAMAN" then
    if playerLevel < 40 then
        allowedArmor.SHAMAN = { Cloth=true, Leather=true, Shields=true }
    else
        allowedArmor.SHAMAN = { Cloth=true, Leather=true, Mail=true, Shields=true }
    end
end

local priorities = statPriority[playerClass] or {}
local armorAllowed = allowedArmor[playerClass] or {}
local weaponsAllowed = allowedWeapons[playerClass] or {}

local compareQueue = {}
local compareWindowShown = false

local debugEnabled = false
local function DebugPrint(...)
    if debugEnabled then
        print("AutoEquipBetter DEBUG:", ...)
    end
end

local function GetItemStats(itemLink)
    if not itemLink then return {}, 0, nil end
    local stats = {}
    local itemName, _, itemRarity, _, _, _, _, _, equipSlot = GetItemInfo(itemLink)
    if not itemName then
        DebugPrint("Инфо о предмете не загружено:", itemLink)
        return {}, 0, nil
    end

    local tooltip = CreateFrame("GameTooltip", "TempTooltip", nil, "GameTooltipTemplate")
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetHyperlink(itemLink)

    for i = 2, tooltip:NumLines() do
        local line = _G["TempTooltipTextLeft"..i]:GetText()
        if line then
            DebugPrint("Tooltip строка:", line)
            local armor = line:match("Броня:%s*(%d+)") or line:match("(%d+) Armor")
            if armor then stats["Armor"] = tonumber(armor) end
            local str = line:match("Сила:%s*(%d+)") or line:match("(%d+) Strength")
            if str then stats["Strength"] = tonumber(str) end
            local agi = line:match("Ловкость:%s*(%d+)") or line:match("(%d+) Agility")
            if agi then stats["Agility"] = tonumber(agi) end
            local sta = line:match("Выносливость:%s*(%d+)") or line:match("(%d+) Stamina")
            if sta then stats["Stamina"] = tonumber(sta) end
            local int = line:match("Интеллект:%s*(%d+)") or line:match("(%d+) Intellect")
            if int then stats["Intellect"] = tonumber(int) end
            local spi = line:match("Дух:%s*(%d+)") or line:match("(%d+) Spirit")
            if spi then stats["Spirit"] = tonumber(spi) end
        end
    end
    tooltip:Hide()
    return stats, itemRarity, equipSlot
end

local function EvaluateItem(stats, rarity)
    if rarity == 0 or rarity == 1 then
        local armor = stats["Armor"] or 0
        DebugPrint("Оценка (серый/белый): броня =", armor)
        return armor
    else
        local score = 0
        for stat, value in pairs(stats) do
            local weight = priorities[stat] or 0
            score = score + value * weight
        end
        DebugPrint("Оценка предмета:", score)
        return score
    end
end

local function CompareItems(oldLink, newLink)
    local oldStats = GetItemStats(oldLink)
    local newStats = GetItemStats(newLink)
    local oldScore = EvaluateItem(oldStats)
    local newScore = EvaluateItem(newStats)
    return newScore > oldScore, oldStats, newStats
end

local function GetItemIcon(itemLink)
    if not itemLink then return nil end
    local texture = select(10, GetItemInfo(itemLink))
    return texture
end

local function GetItemNameAndColor(itemLink)
    if not itemLink then return "—", {1,1,1}, 1 end
    local name, _, quality = GetItemInfo(itemLink)
    local color = ITEM_QUALITY_COLORS[quality or 1]
    return name or "—", {color.r, color.g, color.b}, quality or 1
end

-- Функция для получения типа предмета (используем прямо itemSubType из GetItemInfo)
local function GetItemTypeText(itemLink)
    if not itemLink then return "" end
    local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
    return itemSubType or itemType or ""
end

local function ShowComparisonWindow(oldLink, newLink, oldStats, newStats, slotName, windowIndex, windowTotal)
    DebugPrint("Показ окна сравнения для слота", slotName)
    if compareWindowShown then
        table.insert(compareQueue, {oldLink=oldLink, newLink=newLink, oldStats=oldStats, newStats=newStats, slotName=slotName})
        return
    end
    compareWindowShown = true

    -- Удаляем старое окно, если оно осталось
    if CompareFrame and CompareFrame:IsShown() then
        CompareFrame:Hide()
    end

    local frameWindow = CreateFrame("Frame", "CompareFrame", UIParent, "BasicFrameTemplateWithInset")
    frameWindow:SetSize(350, 230)
    frameWindow:SetPoint("CENTER")
    frameWindow:SetMovable(true)
    frameWindow:EnableMouse(true)
    frameWindow:RegisterForDrag("LeftButton")
    frameWindow:SetClampedToScreen(true)
    frameWindow:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frameWindow:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Заголовок
    frameWindow.title = frameWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frameWindow.title:SetPoint("TOP", 0, -10)
    frameWindow.title:SetText("Сравнение снаряжения: "..slotName)

    -- Иконки
    local oldIcon = GetItemIcon(oldLink)
    local newIcon = GetItemIcon(newLink)

    local oldTexture = CreateFrame("Button", nil, frameWindow)
    oldTexture:SetSize(48,48)
    oldTexture:SetPoint("TOPLEFT", 18, -38)
    oldTexture.icon = oldTexture:CreateTexture(nil, "ARTWORK")
    oldTexture.icon:SetAllPoints()
    if oldIcon then oldTexture.icon:SetTexture(oldIcon) end

    local newTexture = CreateFrame("Button", nil, frameWindow)
    newTexture:SetSize(48,48)
    newTexture:SetPoint("TOPRIGHT", -18, -38)
    newTexture.icon = newTexture:CreateTexture(nil, "ARTWORK")
    newTexture.icon:SetAllPoints()
    if newIcon then newTexture.icon:SetTexture(newIcon) end

    -- Tooltip при наведении на иконку
    oldTexture:SetScript("OnEnter", function(self)
        if oldLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(oldLink)
            GameTooltip:Show()
        end
    end)
    oldTexture:SetScript("OnLeave", function() GameTooltip:Hide() end)

    newTexture:SetScript("OnEnter", function(self)
        if newLink then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetHyperlink(newLink)
            GameTooltip:Show()
        end
    end)
    newTexture:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Названия предметов
    local oldName, oldColor = GetItemNameAndColor(oldLink)
    local newName, newColor = GetItemNameAndColor(newLink)

    local oldNameText = frameWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    oldNameText:SetPoint("TOPLEFT", oldTexture, "BOTTOMLEFT", 0, -4)
    oldNameText:SetWidth(130)
    oldNameText:SetJustifyH("LEFT")
    oldNameText:SetText(oldName)
    oldNameText:SetTextColor(unpack(oldColor))

    local newNameText = frameWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    newNameText:SetPoint("TOPRIGHT", newTexture, "BOTTOMRIGHT", 0, -4)
    newNameText:SetWidth(130)
    newNameText:SetJustifyH("RIGHT")
    newNameText:SetText(newName)
    newNameText:SetTextColor(unpack(newColor))

    -- Тип предмета (используем прямую информацию из игры)
    local oldTypeText = frameWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    oldTypeText:SetPoint("TOPLEFT", oldNameText, "BOTTOMLEFT", 0, -2)
    oldTypeText:SetWidth(130)
    oldTypeText:SetJustifyH("LEFT")
    oldTypeText:SetText(GetItemTypeText(oldLink))

    local newTypeText = frameWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    newTypeText:SetPoint("TOPRIGHT", newNameText, "BOTTOMRIGHT", 0, -2)
    newTypeText:SetWidth(130)
    newTypeText:SetJustifyH("RIGHT")
    newTypeText:SetText(GetItemTypeText(newLink))

    -- Разница характеристик
    local text = frameWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOP", 0, -130)
    text:SetWidth(300)
    text:SetJustifyH("LEFT")

    local diffText = ""
    local allStats = {}
    for stat,_ in pairs(priorities) do allStats[stat] = true end
    allStats["Armor"] = true

    for stat,_ in pairs(allStats) do
        local oldVal = oldStats[stat] or 0
        local newVal = newStats[stat] or 0
        local diff = newVal - oldVal
        if diff ~= 0 then
            local sign = diff > 0 and "+" or ""
            diffText = diffText .. stat .. ": " .. sign .. diff .. "\n"
        end
    end

    if diffText == "" then
        diffText = "Нет изменений в характеристиках."
    end

    text:SetText(diffText)

    -- Индикатор очереди окон (например, 1/3)
    local queueLabel = frameWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    queueLabel:SetPoint("BOTTOM", 0, 18)
    queueLabel:SetText(windowIndex and windowTotal and (windowIndex.."/"..windowTotal) or "")

    -- Кнопки
    local acceptBtn = CreateFrame("Button", nil, frameWindow, "GameMenuButtonTemplate")
    acceptBtn:SetPoint("BOTTOMLEFT", 20, 10)
    acceptBtn:SetSize(100, 25)
    acceptBtn:SetText("Надеть")
    acceptBtn:SetNormalFontObject("GameFontNormal")
    acceptBtn:SetHighlightFontObject("GameFontHighlight")

    local declineBtn = CreateFrame("Button", nil, frameWindow, "GameMenuButtonTemplate")
    declineBtn:SetPoint("BOTTOMRIGHT", -20, 10)
    declineBtn:SetSize(100, 25)
    declineBtn:SetText("Отмена")
    declineBtn:SetNormalFontObject("GameFontNormal")
    declineBtn:SetHighlightFontObject("GameFontHighlight")

    -- Функция закрытия окна и показа следующего
    local function CloseWindow()
        frameWindow:Hide()
        frameWindow:SetScript("OnUpdate", nil)
        compareWindowShown = false
        if #compareQueue > 0 then
            local nextItem = table.remove(compareQueue, 1)
            ShowComparisonWindow(
                nextItem.oldLink, nextItem.newLink, nextItem.oldStats, nextItem.newStats, nextItem.slotName,
                windowTotal - #compareQueue, windowTotal
            )
        end
    end

    acceptBtn:SetScript("OnClick", function()
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                local itemLink = GetContainerItemLink(bag, slot)
                if itemLink == newLink then
                    local slotId = GetInventorySlotInfo(slotName)
                    PickupContainerItem(bag, slot)
                    EquipCursorItem(slotId)
                    CloseWindow()
                    return
                end
            end
        end
        CloseWindow()
    end)

    declineBtn:SetScript("OnClick", CloseWindow)

    frameWindow:SetScript("OnHide", function(self)
        self:Hide()
        compareWindowShown = false
    end)

    frameWindow:Show()
end

local function CheckAndCompare()
    DebugPrint("Запуск CheckAndCompare")
    if InCombatLockdown() then
        DebugPrint("В бою, смена экипировки ограничена")
    end

    -- Сначала соберём все лучшие предметы для каждого слота
    local bestItems = {}
    local bestScores = {}

    for _, slotName in ipairs(slots) do
        bestItems[slotName] = nil
        bestScores[slotName] = -1
    end

    for _, slotName in ipairs(slots) do
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                local itemLink = GetContainerItemLink(bag, slot)
                if itemLink then
                    local _, _, rarity, _, _, itemType, itemSubType, _, equipSlot = GetItemInfo(itemLink)
                    if equipSlot == slotToInvType[slotName] then
                        local allowed = true
                        DebugPrint("itemType:", itemType, "itemSubType:", itemSubType)
                        -- Фильтрация доспехов
                        if itemType == "Armor" then
                            if playerClass == "HUNTER" or playerClass == "SHAMAN" then
                                if playerLevel < 40 and itemSubType == "Mail" then
                                    DebugPrint("Кольчуга запрещена для уровня "..playerLevel)
                                    allowed = false
                                end
                            end
                            if not (armorAllowed and armorAllowed[itemSubType]) then
                                DebugPrint("Тип доспеха не подходит:", itemSubType)
                                allowed = false
                            end
                        end
                        -- Фильтрация оружия
                        if itemType == "Weapon" and not weaponsAllowed[itemSubType] then
                            DebugPrint("Тип оружия не подходит:", itemSubType)
                            allowed = false
                        end
                        if allowed then
                            local stats = GetItemStats(itemLink)
                            local score = EvaluateItem(stats, rarity)
                            if score > bestScores[slotName] then
                                bestScores[slotName] = score
                                bestItems[slotName] = itemLink
                            end
                        end
                    end
                end
            end
        end
    end

    -- Очередь окон сравнения
    compareQueue = {}
    local windowTotal = 0

    for _, slotName in ipairs(slots) do
        local slotId = GetInventorySlotInfo(slotName)
        local oldLink = GetInventoryItemLink("player", slotId)
        local bestItemLink = bestItems[slotName]
        if bestItemLink then
            if not oldLink then
                table.insert(compareQueue, {
                    oldLink = nil,
                    newLink = bestItemLink,
                    oldStats = {},
                    newStats = GetItemStats(bestItemLink),
                    slotName = slotName
                })
                windowTotal = windowTotal + 1
            else
                local better, oldStats, newStats = CompareItems(oldLink, bestItemLink)
                if better then
                    table.insert(compareQueue, {
                        oldLink = oldLink,
                        newLink = bestItemLink,
                        oldStats = oldStats,
                        newStats = newStats,
                        slotName = slotName
                    })
                    windowTotal = windowTotal + 1
                end
            end
        end
    end

    if #compareQueue > 0 then
        local first = table.remove(compareQueue, 1)
        ShowComparisonWindow(
            first.oldLink, first.newLink, first.oldStats, first.newStats, first.slotName,
            1, windowTotal
        )
    end
end

local function StartDebounce()
    timer = 0
    waiting = true
end

frame:SetScript("OnUpdate", function(self, elapsed)
    if waiting then
        timer = timer + elapsed
        if timer >= debounceDelay then
            waiting = false
            if not InCombatLockdown() then
                CheckAndCompare()
            end
        end
    end
end)

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "BAG_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        StartDebounce()
    end
end)

frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGIN")

SLASH_AUTOEQUIPBETTER1 = "/aeb"
SlashCmdList["AUTOEQUIPBETTER"] = function(msg)
    if msg:lower() == "debug" then
        debugEnabled = not debugEnabled
        if debugEnabled then
            print("AutoEquipBetter: отладка включена")
        else
            print("AutoEquipBetter: отладка отключена")
        end
    else
        print("AutoEquipBetter: неизвестная команда. Используйте '/aeb debug' для переключения отладки.")
    end
end

print("AutoEquipBetter загружен.")
