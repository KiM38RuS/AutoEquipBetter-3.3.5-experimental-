local AEB = LibStub("AceAddon-3.0"):NewAddon("AutoEquipBetter", "AceEvent-3.0", "AceHook-3.0")

local scanner = CreateFrame("GameTooltip", "AEBScanner", nil, "GameTooltipTemplate")
scanner:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Конфигурация весов (EP) - потом вынесем в меню
local statWeights = {
    ["Ловкость"] = 2.5, ["Сила атаки"] = 1.0, ["Выносливость"] = 0.5,
    ["Интеллект"] = 0.2, ["Броня"] = 0.05, ["Сила"] = 0.1, ["Дух"] = 0.0
}

local statConfig = {
    ["Сила"] = "%+(%d+) к силе", ["Ловкость"] = "%+(%d+) к ловкости",
    ["Выносливость"] = "%+(%d+) к выносливости", ["Интеллект"] = "%+(%d+) к интеллекту",
    ["Дух"] = "%+(%d+) к духу", ["Броня"] = "Броня: (%d+)", ["Сила атаки"] = "%+(%d+) к силе атаки"
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

local itemQueue = {} -- Очередь найденных вещей
local blacklist = {} -- Список игнорируемых ID
local mainFrame = nil

function AEB:OnInitialize()
    self:RegisterEvent("BAG_UPDATE")
end

function AEB:ScanItem(itemLink)
    scanner:ClearLines()
    scanner:SetHyperlink(itemLink)
    local stats = {}
    for i = 1, scanner:NumLines() do
        local text = _G["AEBScannerTextLeft"..i]:GetText()
        if text then
            for name, pat in pairs(statConfig) do
                local val = text:match(pat)
                if val then stats[name] = tonumber(val) or val end
            end
        end
    end
    return stats
end

function AEB:GetScore(stats)
    local score = 0
    for n, v in pairs(stats) do
        if type(v) == "number" and statWeights[n] then score = score + (v * statWeights[n]) end
    end
    return score
end

function AEB:BAG_UPDATE()
    if InCombatLockdown() then return end
    
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link and IsEquippableItem(link) then
                local id = link:match("item:(%d+)")
                if id and not blacklist[id] then
                    local _, _, _, _, minLvl, _, _, _, loc = GetItemInfo(link)
                    if (not minLvl or minLvl <= UnitLevel("player")) and loc then
                        local newStats = self:ScanItem(link)
                        local newScore = self:GetScore(newStats)
                        
                        local slotId = equipSlotMap[loc]
                        local oldScore = 0
                        local oldLink = nil -- Сохраняем ссылку на старый предмет
                        
                        if slotId then
                            oldLink = GetInventoryItemLink("player", slotId)
                            if oldLink then oldScore = self:GetScore(self:ScanItem(oldLink)) end
                        end
                        
                        if newScore > oldScore then
                            local alreadyInQueue = false
                            for _, q in ipairs(itemQueue) do if q.id == id then alreadyInQueue = true end end
                            
                            if not alreadyInQueue then
                                -- Теперь передаём oldLink в таблицу очереди
                                table.insert(itemQueue, {link = link, id = id, score = newScore, oldScore = oldScore, oldLink = oldLink})
                                self:ShowNextInQueue()
                            end
                        end
                    end
                end
            end
        end
    end
end

function AEB:ShowNextInQueue()
    if #itemQueue == 0 or (mainFrame and mainFrame:IsVisible()) then return end
    local data = itemQueue[1]
    self:CreateUI(data.link, data.oldLink)
end

function AEB:CreateUI(itemLink, oldItemLink)
    if not mainFrame then
        mainFrame = CreateFrame("Frame", "AEBMainFrame", UIParent)
        mainFrame:SetSize(600, 250) -- Делаем окно шире для двух колонок
        mainFrame:SetPoint("CENTER")
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

        -- === ЛЕВАЯ ЧАСТЬ: НОВЫЙ ПРЕДМЕТ ===
        mainFrame.recLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mainFrame.recLabel:SetPoint("TOPLEFT", 25, -25)
        mainFrame.recLabel:SetText("Рекомендуемый предмет")

        mainFrame.icon = mainFrame:CreateTexture(nil, "OVERLAY")
        mainFrame.icon:SetSize(40, 40)
        mainFrame.icon:SetPoint("TOPLEFT", mainFrame.recLabel, "BOTTOMLEFT", 0, -10)
        
        mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        mainFrame.title:SetPoint("LEFT", mainFrame.icon, "RIGHT", 10, 0)
        mainFrame.title:SetWidth(240)
        mainFrame.title:SetJustifyH("LEFT")

        -- === ЛЕВАЯ ЧАСТЬ: СТАРЫЙ ПРЕДМЕТ ===
        mainFrame.eqLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mainFrame.eqLabel:SetPoint("TOPLEFT", mainFrame.icon, "BOTTOMLEFT", 0, -20)
        mainFrame.eqLabel:SetText("Надетый предмет")

        mainFrame.oldIcon = mainFrame:CreateTexture(nil, "OVERLAY")
        mainFrame.oldIcon:SetSize(40, 40)
        mainFrame.oldIcon:SetPoint("TOPLEFT", mainFrame.eqLabel, "BOTTOMLEFT", 0, -10)
        
        mainFrame.oldTitle = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        mainFrame.oldTitle:SetPoint("LEFT", mainFrame.oldIcon, "RIGHT", 10, 0)
        mainFrame.oldTitle:SetWidth(240)
        mainFrame.oldTitle:SetJustifyH("LEFT")

        -- === ПРАВАЯ ЧАСТЬ: СТАТЫ ===
        mainFrame.statsHeader = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mainFrame.statsHeader:SetPoint("TOPLEFT", 300, -25)
        mainFrame.statsHeader:SetWidth(270)
        mainFrame.statsHeader:SetJustifyH("LEFT")
        mainFrame.statsHeader:SetText("При замене этого предмета произойдут следующие изменения характеристик:")

        mainFrame.stats = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        mainFrame.stats:SetPoint("TOPLEFT", mainFrame.statsHeader, "BOTTOMLEFT", 0, -15)
        mainFrame.stats:SetJustifyH("LEFT")

        -- === НИЖНЯЯ ЧАСТЬ: КНОПКИ И ЧЕКБОКС ===
        mainFrame.btnOk = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
        mainFrame.btnOk:SetSize(100, 25)
        mainFrame.btnOk:SetPoint("BOTTOMLEFT", 20, 50)
        mainFrame.btnOk:SetText("Надеть")

        mainFrame.btnNo = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
        mainFrame.btnNo:SetSize(100, 25)
        mainFrame.btnNo:SetPoint("LEFT", mainFrame.btnOk, "RIGHT", 10, 0)
        mainFrame.btnNo:SetText("Отмена")

        mainFrame.cb = CreateFrame("CheckButton", "AEBBlacklistCB", mainFrame, "UICheckButtonTemplate")
        mainFrame.cb:SetPoint("BOTTOMLEFT", 20, 15)
        mainFrame.cb.text = _G[mainFrame.cb:GetName() .. "Text"]
        mainFrame.cb.text:SetText("Добавить в чёрный список")
        mainFrame.cb:SetScale(0.8)

        mainFrame.count = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        mainFrame.count:SetPoint("BOTTOMRIGHT", -25, 20)
    end

    -- Заполняем новую вещь
    local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)
    mainFrame.icon:SetTexture(tex)
    mainFrame.title:SetText(itemLink)
    
    -- Заполняем старую вещь (если слот не пустой)
    if oldItemLink then
        local _, _, _, _, _, _, _, _, _, oldTex = GetItemInfo(oldItemLink)
        mainFrame.oldIcon:SetTexture(oldTex)
        mainFrame.oldTitle:SetText(oldItemLink)
    else
        mainFrame.oldIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        mainFrame.oldTitle:SetText("|cff888888Ничего не надето|r")
    end

    -- Счётчик (показываем только если > 1)
    if #itemQueue > 1 then
        mainFrame.count:SetText("1/" .. #itemQueue)
    else
        mainFrame.count:SetText("")
    end
    mainFrame.cb:SetChecked(false)

    -- Математика статов
    local newStats = self:ScanItem(itemLink)
    local oldStats = oldItemLink and self:ScanItem(oldItemLink) or {}
    local deltas = {}
    
    for statName, newValue in pairs(newStats) do
        if type(newValue) == "number" then
            local oldValue = oldStats[statName] or 0
            local delta = newValue - oldValue
            if delta ~= 0 then deltas[statName] = delta end
        end
    end
    
    for statName, oldValue in pairs(oldStats) do
        if type(oldValue) == "number" and not newStats[statName] then
            deltas[statName] = -oldValue
        end
    end

    -- Формируем финальный текст
    local statsText = ""
    for statName, delta in pairs(deltas) do
        if delta > 0 then
            statsText = statsText .. "|cff00ff00+" .. delta .. "|r " .. statName .. "\n"
        elseif delta < 0 then
            statsText = statsText .. "|cffff0000" .. delta .. "|r " .. statName .. "\n"
        end
    end
    
    if statsText == "" then statsText = "|cff888888Только базовые изменения|r" end
    mainFrame.stats:SetText(statsText)

    -- Кнопки
    mainFrame.btnOk:SetScript("OnClick", function()
        EquipItemByName(itemLink)
        table.remove(itemQueue, 1)
        mainFrame:Hide()
        AEB:ShowNextInQueue()
    end)

    mainFrame.btnNo:SetScript("OnClick", function()
        if mainFrame.cb:GetChecked() then
            local id = itemLink:match("item:(%d+)")
            if id then blacklist[id] = true end
        end
        table.remove(itemQueue, 1)
        mainFrame:Hide()
        AEB:ShowNextInQueue()
    end)

    mainFrame:Show()
end