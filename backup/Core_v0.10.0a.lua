-- Аддон AutoEquipBetter v0.10a для World of Warcraft 3.3.5a

local AEB = LibStub("AceAddon-3.0"):NewAddon("AutoEquipBetter", "AceEvent-3.0", "AceHook-3.0")

local scanner = CreateFrame("GameTooltip", "AEBScanner", nil, "GameTooltipTemplate")
scanner:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Веса характеристик: [Класс] -> [Ветка талантов (1, 2, 3)]
local classStatWeights = {
    ["HUNTER"] = {
        [1] = { ["УВС"] = 7.5, ["Ловкость"] = 1.8, ["Сила атаки"] = 2.0, ["Рейтинг меткости"] = 4.0, ["Рейтинг критического удара"] = 1.6, ["Рейтинг скорости"] = 1.2, ["Интеллект"] = 0.5 }, -- БМ
        [2] = { ["УВС"] = 8.0, ["Ловкость"] = 2.5, ["Рейтинг пробивания брони"] = 2.4, ["Рейтинг меткости"] = 4.0, ["Рейтинг критического удара"] = 1.9, ["Сила атаки"] = 1.0, ["Интеллект"] = 0.5 }, -- ММ
        [3] = { ["УВС"] = 7.5, ["Ловкость"] = 2.8, ["Рейтинг меткости"] = 4.0, ["Рейтинг критического удара"] = 1.8, ["Сила атаки"] = 1.0, ["Рейтинг скорости"] = 1.1, ["Интеллект"] = 0.5 }  -- Сурв
    },
    ["WARRIOR"] = {
        [1] = { ["УВС"] = 8.0, ["Сила"] = 2.5, ["Рейтинг пробивания брони"] = 2.2, ["Рейтинг мастерства"] = 3.0, ["Рейтинг меткости"] = 3.5, ["Рейтинг критического удара"] = 1.8 }, -- Армс
        [2] = { ["УВС"] = 8.5, ["Сила"] = 2.4, ["Рейтинг пробивания брони"] = 2.3, ["Рейтинг мастерства"] = 3.0, ["Рейтинг меткости"] = 3.5, ["Рейтинг критического удара"] = 1.9, ["Ловкость"] = 1.2 }, -- Фури
        [3] = { ["Выносливость"] = 3.5, ["Броня"] = 0.15, ["Рейтинг защиты"] = 2.5, ["Рейтинг уклонения"] = 2.0, ["Рейтинг парирования"] = 1.8, ["Блокирование"] = 1.5, ["Сила"] = 1.2 } -- Прот
    },
    ["PALADIN"] = {
        [1] = { ["Сила заклинаний"] = 2.0, ["Интеллект"] = 2.2, ["Рейтинг скорости"] = 1.8, ["Рейтинг критического удара"] = 1.2, ["Дух"] = 0.5, ["Восполнение маны"] = 2.5 }, -- Холи
        [2] = { ["Выносливость"] = 3.5, ["Рейтинг защиты"] = 2.5, ["Броня"] = 0.15, ["Рейтинг уклонения"] = 2.0, ["Рейтинг парирования"] = 1.8, ["Сила"] = 1.5, ["Рейтинг мастерства"] = 2.0 }, -- Прот
        [3] = { ["Сила"] = 2.5, ["УВС"] = 7.0, ["Рейтинг меткости"] = 3.5, ["Рейтинг мастерства"] = 3.0, ["Рейтинг критического удара"] = 1.8, ["Сила заклинаний"] = 1.0, ["Рейтинг скорости"] = 1.2 } -- Ретри
    },
    ["DEATHKNIGHT"] = {
        [1] = { ["Сила"] = 2.5, ["Выносливость"] = 3.0, ["Рейтинг мастерства"] = 2.5, ["Рейтинг меткости"] = 3.5, ["Рейтинг пробивания брони"] = 1.8, ["Рейтинг защиты"] = 2.0 }, -- Блад (Танк/ДД)
        [2] = { ["Сила"] = 2.5, ["УВС"] = 8.0, ["Рейтинг меткости"] = 3.5, ["Рейтинг мастерства"] = 2.5, ["Рейтинг пробивания брони"] = 2.0, ["Рейтинг критического удара"] = 1.6 }, -- Фрост
        [3] = { ["Сила"] = 2.5, ["Сила атаки"] = 1.0, ["Рейтинг меткости"] = 3.5, ["Рейтинг критического удара"] = 1.7, ["Рейтинг скорости"] = 1.4, ["Сила заклинаний"] = 0.5 } -- Анхоли
    },
    ["ROGUE"] = {
        [1] = { ["Ловкость"] = 2.2, ["Сила атаки"] = 1.0, ["Рейтинг меткости"] = 3.5, ["Рейтинг мастерства"] = 2.5, ["Рейтинг скорости"] = 1.8, ["Рейтинг критического удара"] = 1.6 }, -- Мути
        [2] = { ["УВС"] = 6.0, ["Ловкость"] = 2.0, ["Рейтинг пробивания брони"] = 2.4, ["Рейтинг мастерства"] = 3.0, ["Рейтинг меткости"] = 3.5, ["Сила атаки"] = 1.0 }, -- Комбат
        [3] = { ["Ловкость"] = 2.4, ["Сила атаки"] = 1.0, ["Рейтинг пробивания брони"] = 1.8, ["Рейтинг критического удара"] = 1.8, ["Рейтинг меткости"] = 3.0 } -- ШД
    },
    ["DRUID"] = {
        [1] = { ["Сила заклинаний"] = 2.0, ["Рейтинг скорости"] = 1.7, ["Рейтинг критического удара"] = 1.5, ["Рейтинг меткости"] = 3.5, ["Интеллект"] = 1.0, ["Дух"] = 0.8 }, -- Сова
        [2] = { ["Ловкость"] = 2.5, ["Рейтинг пробивания брони"] = 2.2, ["Сила"] = 1.5, ["Рейтинг мастерства"] = 2.5, ["Рейтинг меткости"] = 3.5, ["Выносливость"] = 2.0 }, -- Ферал
        [3] = { ["Сила заклинаний"] = 2.0, ["Дух"] = 1.8, ["Рейтинг скорости"] = 1.6, ["Интеллект"] = 1.4, ["Восполнение маны"] = 2.0 } -- Рдрю
    },
    ["SHAMAN"] = {
        [1] = { ["Сила заклинаний"] = 2.0, ["Рейтинг скорости"] = 1.6, ["Рейтинг меткости"] = 3.5, ["Рейтинг критического удара"] = 1.4, ["Интеллект"] = 1.0 }, -- Элем
        [2] = { ["Сила атаки"] = 1.0, ["Ловкость"] = 1.8, ["Сила заклинаний"] = 1.4, ["Рейтинг меткости"] = 3.5, ["Рейтинг мастерства"] = 2.5, ["Рейтинг скорости"] = 1.6 }, -- Энх
        [3] = { ["Сила заклинаний"] = 2.0, ["Рейтинг скорости"] = 1.7, ["Интеллект"] = 1.2, ["Восполнение маны"] = 2.5, ["Рейтинг критического удара"] = 1.0 } -- Рестор
    },
    ["MAGE"] = {
        [1] = { ["Сила заклинаний"] = 2.0, ["Интеллект"] = 1.4, ["Рейтинг скорости"] = 1.6, ["Рейтинг критического удара"] = 1.3, ["Рейтинг меткости"] = 3.5 }, -- Аркан
        [2] = { ["Сила заклинаний"] = 2.0, ["Рейтинг критического удара"] = 1.8, ["Рейтинг скорости"] = 1.5, ["Рейтинг меткости"] = 3.5, ["Дух"] = 0.8 }, -- Файер
        [3] = { ["Сила заклинаний"] = 2.0, ["Рейтинг скорости"] = 1.4, ["Рейтинг критического удара"] = 1.4, ["Рейтинг меткости"] = 3.5 }  -- Фрост
    },
    ["WARLOCK"] = {
        [1] = { ["Сила заклинаний"] = 2.1, ["Рейтинг скорости"] = 1.7, ["Дух"] = 1.2, ["Рейтинг меткости"] = 3.5, ["Рейтинг критического удара"] = 1.3 }, -- Афли
        [2] = { ["Сила заклинаний"] = 2.2, ["Рейтинг скорости"] = 1.5, ["Рейтинг критического удара"] = 1.4, ["Рейтинг меткости"] = 3.5, ["Дух"] = 0.7 }, -- Демо
        [3] = { ["Сила заклинаний"] = 2.0, ["Рейтинг скорости"] = 1.6, ["Рейтинг критического удара"] = 1.6, ["Рейтинг меткости"] = 3.5 }  -- Дестро
    },
    ["PRIEST"] = {
        [1] = { ["Сила заклинаний"] = 2.0, ["Интеллект"] = 1.8, ["Рейтинг скорости"] = 1.4, ["Дух"] = 1.0, ["Восполнение маны"] = 2.0 }, -- ДЦ
        [2] = { ["Сила заклинаний"] = 2.0, ["Дух"] = 1.8, ["Рейтинг скорости"] = 1.6, ["Интеллект"] = 1.2, ["Восполнение маны"] = 1.5 }, -- Холи
        [3] = { ["Сила заклинаний"] = 2.0, ["Рейтинг скорости"] = 1.8, ["Рейтинг критического удара"] = 1.5, ["Рейтинг меткости"] = 3.5, ["Дух"] = 1.0 }  -- ШП
    }
}

local statWeights = {} -- Текущие веса (определяются динамически)

-- Расширенный парсер, учитывающий и белые, и зелёные тексты
local statConfig = {
    -- Основные характеристики (белые)
    { name = "Сила", pattern = "%+(%d+) к силе" },
    { name = "Ловкость", pattern = "%+(%d+) к ловкости" },
    { name = "Выносливость", pattern = "%+(%d+) к выносливости" },
    { name = "Интеллект", pattern = "%+(%d+) к интеллекту" },
    { name = "Дух", pattern = "%+(%d+) к духу" },
    { name = "Броня", pattern = "Броня: (%d+)" },
    { name = "УВС", pattern = "%(([%d%.]+) ед%. урона в секунду%)" },
    
    -- Вторичные характеристики (зелёные)
    { name = "Сила атаки", pattern = "Сила атаки %+(%d+)" },
    { name = "Сила атаки", pattern = "%+(%d+) к силе атаки" }, -- Для чарок/камней
    { name = "Рейтинг критического удара", pattern = "критического удара %+(%d+)" },
    { name = "Рейтинг меткости", pattern = "Рейтинг меткости %+(%d+)" },
    { name = "Рейтинг скорости", pattern = "Рейтинг скорости %+(%d+)" },
    { name = "Рейтинг пробивания брони", pattern = "пробивания брони %+(%d+)" },
    { name = "Рейтинг мастерства", pattern = "Рейтинг мастерства %+(%d+)" }, -- Это Expertise
    
    -- Заклинатели
    { name = "Сила заклинаний", pattern = "силу заклинаний на (%d+)" },
    { name = "Восполнение маны", pattern = "восполняет (%d+) ед%. маны раз в 5 сек" },
    
    -- Танковские и ПвП статы
    { name = "Рейтинг защиты", pattern = "Рейтинг защиты %+(%d+)" },
    { name = "Рейтинг уклонения", pattern = "Рейтинг уклонения %+(%d+)" },
    { name = "Рейтинг парирования", pattern = "Рейтинг парирования %+(%d+)" },
    { name = "Рейтинг устойчивости", pattern = "Рейтинг устойчивости %+(%d+)" }
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

local itemQueue = {} 
local blacklist = {} 
local mainFrame = nil
local itemScoreCache = {}

-- === ОПТИМИЗАЦИЯ СОБЫТИЙ (DEBOUNCE) ===
local isDirty = false
local updateTimer = 0
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    if not isDirty then return end
    updateTimer = updateTimer + elapsed
    if updateTimer > 0.3 then -- Защита от спама событий
        isDirty = false
        updateTimer = 0
        AEB:RefreshArrows()
    end
end)

function AEB:OnInitialize()
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("MERCHANT_SHOW")
    self:RegisterEvent("MERCHANT_UPDATE")
    self:RegisterEvent("MERCHANT_CLOSED")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("TRADE_SKILL_SHOW")
    self:RegisterEvent("QUEST_COMPLETE")
    self:RegisterEvent("SKILL_LINES_CHANGED", "UpdateKnownSkills")
    self:UpdateKnownSkills()
    -- Подписываемся на смену талантов (срабатывает и при логине, и при смене спека)
    self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateStatWeights")
    -- Вызываем принудительно при загрузке, чтобы тултипы работали сразу
    self:UpdateStatWeights()
    
    -- Реагируем на прокрутку окон сумок и торговца
    hooksecurefunc("MerchantFrame_Update", function() isDirty = true end)
    hooksecurefunc("ContainerFrame_Update", function() isDirty = true end)
    
    -- Определяем класс игрока и загружаем его веса
    local _, playerClass = UnitClass("player")
    statWeights = classStatWeights[playerClass] or {}
end

function AEB:BAG_UPDATE() isDirty = true end
function AEB:MERCHANT_SHOW() isDirty = true end
function AEB:MERCHANT_UPDATE() isDirty = true end
function AEB:MERCHANT_CLOSED() isDirty = true; self:ReleaseAllArrows() end
function AEB:PLAYER_EQUIPMENT_CHANGED() isDirty = true end

-- === ПУЛ СТРЕЛОЧЕК ===
local upgradeArrows = {}
function AEB:GetArrowFrame()
    for _, arrow in ipairs(upgradeArrows) do
        if not arrow.inUse then 
            arrow.inUse = true
            return arrow 
        end
    end
    
    local arrow = CreateFrame("Frame", nil, UIParent)
    -- Размер фрейма со стрелочкой. 18x18 обычно хорошо смотрится, 
    -- но ты можешь изменить эти цифры, если стрелочка покажется мелкой или крупной.
    arrow:SetSize(18, 18) 
    arrow:SetFrameLevel(10) -- Поверх кнопки
    
    -- Создаем текстуру вместо текста
    arrow.texture = arrow:CreateTexture(nil, "OVERLAY")
    arrow.texture:SetAllPoints(arrow) -- Текстура заполняет весь фрейм
    
    -- Указываем путь к картинке. 
    -- ВНИМАНИЕ: Если папка твоего аддона называется иначе, замени "AutoEquipBetter" на свое название!
    arrow.texture:SetTexture("Interface\\AddOns\\AutoEquipBetter\\Pictures\\GreenUpArrow.tga")
    
    arrow.inUse = true
    table.insert(upgradeArrows, arrow)
    return arrow
end

function AEB:ReleaseAllArrows()
    for _, arrow in ipairs(upgradeArrows) do
        arrow:Hide()
        arrow:ClearAllPoints()
        arrow.inUse = false
    end
end

-- === ПУЛ МОНЕТОК (ДЛЯ КВЕСТОВ) ===
local coinIcons = {}
function AEB:GetCoinFrame()
    for _, coin in ipairs(coinIcons) do
        if not coin.inUse then 
            coin.inUse = true
            return coin 
        end
    end
    
    local coin = CreateFrame("Frame", nil, UIParent)
    coin:SetSize(16, 16)
    coin:SetFrameLevel(10)
    coin.texture = coin:CreateTexture(nil, "OVERLAY")
    coin.texture:SetAllPoints(coin)
    coin.texture:SetTexture("Interface\\AddOns\\AutoEquipBetter\\Pictures\\Coin.tga")
    
    coin.inUse = true
    table.insert(coinIcons, coin)
    return coin
end

function AEB:ReleaseAllCoins()
    for _, coin in ipairs(coinIcons) do
        coin:Hide()
        coin:ClearAllPoints()
        coin.inUse = false
    end
end

-- === МАТЕМАТИКА И КЭШИРОВАНИЕ ===
function AEB:ScanItem(itemLink)
    scanner:ClearLines()
    scanner:SetHyperlink(itemLink)
    local stats = {}
    for i = 1, scanner:NumLines() do
        local text = _G["AEBScannerTextLeft"..i]:GetText()
        if text then
            for _, config in ipairs(statConfig) do
                local val = text:match(config.pattern)
                if val then 
                    -- Суммируем, если характеристика встречается дважды (например, белый + зеленый стат)
                    stats[config.name] = (stats[config.name] or 0) + (tonumber(val) or val)
                end
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

function AEB:GetScoreForLink(link)
    if not link then return 0 end
    if itemScoreCache[link] then return itemScoreCache[link] end
    
    local stats = self:ScanItem(link)
    local score = self:GetScore(stats)
    itemScoreCache[link] = score
    return score
end

-- === ПОЛУЧЕНИЕ СЧЕТА НАДЕТОГО (С УЧЕТОМ КОЛЕЦ/ТРИНЕК) ===
function AEB:GetEquippedScoreAndLink(loc)
    local slot1 = equipSlotMap[loc]
    if not slot1 then return 0, nil end
    
    local score1 = 0
    local link1 = GetInventoryItemLink("player", slot1)
    if link1 then score1 = self:GetScoreForLink(link1) end
    
    -- Проверка вторых слотов
    local slot2 = nil
    if loc == "INVTYPE_FINGER" then slot2 = 12
    elseif loc == "INVTYPE_TRINKET" then slot2 = 14
    elseif loc == "INVTYPE_WEAPON" then slot2 = 17 end
    
    if slot2 then
        local score2 = 0
        local link2 = GetInventoryItemLink("player", slot2)
        if link2 then score2 = self:GetScoreForLink(link2) end
        
        -- Возвращаем худший надетый предмет, чтобы перекрыть его улучшением
        if score2 < score1 then return score2, link2 end
    end
    
    return score1, link1
end

-- === ПОИСК КНОПОК ИНТЕРФЕЙСА ===
function AEB:GetContainerButton(bag, slot)
    for i = 1, NUM_CONTAINER_FRAMES do
        local frame = _G["ContainerFrame"..i]
        if frame and frame:IsVisible() and frame:GetID() == bag then
            local btnName = frame:GetName().."Item"..(frame.size - slot + 1)
            return _G[btnName]
        end
    end
    return nil
end

function AEB:GetMerchantButton(index)
    local page = MerchantFrame.page or 1
    local perPage = MERCHANT_ITEMS_PER_PAGE or 10
    local startIdx = (page - 1) * perPage + 1
    local endIdx = startIdx + perPage - 1
    if index >= startIdx and index <= endIdx then
        local btnIdx = index - startIdx + 1
        return _G["MerchantItem"..btnIdx.."ItemButton"]
    end
    return nil
end

-- === ГЛАВНАЯ ЛОГИКА АНАЛИЗА И ОТРИСОВКИ ===
function AEB:RefreshArrows()
    self:ReleaseAllArrows()
    if InCombatLockdown() then return end
    
    -- 1. Предварительный отбор лучшего в сумках (Внутренняя конкуренция)
    local bestBags = {} 
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link and IsEquippableItem(link) then
                local id = link:match("item:(%d+)")
                if id and not blacklist[id] then
                    local _, _, _, _, minLvl, itemType, subType, _, loc = GetItemInfo(link)
                    if loc and equipSlotMap[loc] then
                        local hasSkill = true
                        if itemType == "Доспехи" or itemType == "Оружие" then
                            hasSkill = self.knownSkills[subType]
                        end
                        if hasSkill and (not minLvl or minLvl <= UnitLevel("player")) then
                            local score = self:GetScoreForLink(link)
                            if not bestBags[loc] or score > bestBags[loc].score then
                                bestBags[loc] = { link = link, id = id, score = score, bag = bag, slot = slot, loc = loc }
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- 2. Предварительный отбор у торговца
    local bestMerchant = {}
    if MerchantFrame and MerchantFrame:IsVisible() then
        for i = 1, GetMerchantNumItems() do
            local link = GetMerchantItemLink(i)
            if link and IsEquippableItem(link) then
                local id = link:match("item:(%d+)")
                if id and not blacklist[id] then
                    local _, _, _, _, minLvl, itemType, subType, _, loc = GetItemInfo(link)
                    if loc and equipSlotMap[loc] then
                        local hasSkill = true
                        if itemType == "Доспехи" or itemType == "Оружие" then
                            hasSkill = self.knownSkills[subType]
                        end
                        if hasSkill and (not minLvl or minLvl <= UnitLevel("player")) then
                            local score = self:GetScoreForLink(link)
                            if not bestMerchant[loc] or score > bestMerchant[loc].score then
                                bestMerchant[loc] = { link = link, id = id, score = score, index = i, loc = loc }
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- 3. Финальное сравнение с надетым и отрисовка
    -- Обработка сумок (создание очередей UI и стрелочек)
    for loc, data in pairs(bestBags) do
        local oldScore, oldLink = self:GetEquippedScoreAndLink(loc)
        if data.score > oldScore then
            local btn = self:GetContainerButton(data.bag, data.slot)
            if btn and btn:IsVisible() then
                local arrow = self:GetArrowFrame()
                arrow:SetParent(btn)
                arrow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 5, -3)
                arrow:Show()
            end
            
            -- Добавляем в очередь окон
            local alreadyInQueue = false
            for _, q in ipairs(itemQueue) do if q.id == data.id then alreadyInQueue = true end end
            if not alreadyInQueue then
                -- Инициализируем глобальные счетчики при новой пачке предметов
                if #itemQueue == 0 then
                    self.queueCurrent = 1
                    self.queueTotal = 0
                end
                table.insert(itemQueue, {link = data.link, id = data.id, score = data.score, oldScore = oldScore, oldLink = oldLink, loc = data.loc})
                self.queueTotal = self.queueTotal + 1
                
                self:ShowNextInQueue()
                
                -- Если окно уже открыто, динамически обновляем счетчик при поступлении новых вещей
                if mainFrame and mainFrame:IsVisible() and self.queueTotal > 1 then
                    mainFrame.count:SetText(self.queueCurrent .. "/" .. self.queueTotal)
                end
            end
        end
    end
    
    -- Обработка торговца (только стрелочки)
    for loc, data in pairs(bestMerchant) do
        local oldScore, oldLink = self:GetEquippedScoreAndLink(loc)
        if data.score > oldScore then
            local btn = self:GetMerchantButton(data.index)
            if btn and btn:IsVisible() then
                local arrow = self:GetArrowFrame()
                arrow:SetParent(btn)
                arrow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 5, -3)
                arrow:Show()
            end
        end
    end
end

-- === УПРАВЛЕНИЕ ОЧЕРЕДЬЮ UI ===
function AEB:ShowNextInQueue()
    if mainFrame and mainFrame:IsVisible() then return end
    
    -- Прогоняем очередь, удаляя устаревшие улучшения
    while #itemQueue > 0 do
        local data = itemQueue[1]
        local currentOldScore, currentOldLink = self:GetEquippedScoreAndLink(data.loc)
        local currentNewScore = self:GetScoreForLink(data.link)
        
        -- Если вещь всё ещё лучше надетой — показываем окно
        if currentNewScore > currentOldScore then
            self:CreateUI(data.link, currentOldLink)
            return
        else
            -- Если мы уже надели что-то получше, выкидываем этот пункт и идём дальше
            table.remove(itemQueue, 1)
        end
    end
end

-- === ОТРИСОВКА ОКНА ===
function AEB:CreateUI(itemLink, oldItemLink)
    if not mainFrame then
        mainFrame = CreateFrame("Frame", "AEBMainFrame", UIParent)
        mainFrame:SetSize(450, 300)
        mainFrame:SetPoint("CENTER")
        
        mainFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 256, edgeSize = 24,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })

        mainFrame:SetBackdropColor(0, 0, 0, .5)
		mainFrame:EnableMouse(true)
        mainFrame:SetMovable(true)
        mainFrame:RegisterForDrag("LeftButton")
        mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
        mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)

        local fontTitle = "GameFontNormal"
        
        mainFrame.recLabel = mainFrame:CreateFontString(nil, "OVERLAY", fontTitle)
        mainFrame.recLabel:SetPoint("TOPLEFT", 20, -20)
        mainFrame.recLabel:SetJustifyH("LEFT")
        mainFrame.recLabel:SetText("Рекомендуемый предмет:")

        mainFrame.icon = mainFrame:CreateTexture(nil, "OVERLAY")
        mainFrame.icon:SetSize(42, 42)
        mainFrame.icon:SetPoint("TOPLEFT", mainFrame.recLabel, "BOTTOMLEFT", 0, -10)
        
        mainFrame.iconBorder = mainFrame:CreateTexture(nil, "BORDER")
        mainFrame.iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        mainFrame.iconBorder:SetSize(70, 70)
        mainFrame.iconBorder:SetPoint("CENTER", mainFrame.icon, "CENTER", 0, 0)

		mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mainFrame.title:SetPoint("LEFT", mainFrame.icon, "RIGHT", 1, 0)
        mainFrame.title:SetSize(160, 44)
        mainFrame.title:SetJustifyH("LEFT")
		
		mainFrame.titleBG = CreateFrame("Frame", nil, mainFrame)
		mainFrame.titleBG:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		})
		mainFrame.titleBG:SetBackdropColor(0, 0, 0, 0.6)
		mainFrame.titleBG:SetBackdropBorderColor(0.5, 0.5, 0.5)
		mainFrame.titleBG:SetHeight(44)
		mainFrame.titleBG:SetPoint("LEFT", mainFrame.title, "LEFT", -3, 0)
		mainFrame.titleBG:SetPoint("RIGHT", mainFrame.title, "RIGHT", 5, 0)
		mainFrame.title:SetParent(mainFrame.titleBG) 

        mainFrame.eqLabel = mainFrame:CreateFontString(nil, "OVERLAY", fontTitle)
        mainFrame.eqLabel:SetPoint("TOPLEFT", mainFrame.icon, "BOTTOMLEFT", 0, -15)
        mainFrame.eqLabel:SetText("Надетый предмет:")

        mainFrame.oldIcon = mainFrame:CreateTexture(nil, "OVERLAY")
        mainFrame.oldIcon:SetSize(42, 42)
        mainFrame.oldIcon:SetPoint("TOPLEFT", mainFrame.eqLabel, "BOTTOMLEFT", 0, -10)
        
        mainFrame.oldIconBorder = mainFrame:CreateTexture(nil, "BORDER")
        mainFrame.oldIconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        mainFrame.oldIconBorder:SetSize(70, 70)
        mainFrame.oldIconBorder:SetPoint("CENTER", mainFrame.oldIcon, "CENTER", 0, 0)
        
		mainFrame.oldTitle = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mainFrame.oldTitle:SetPoint("LEFT", mainFrame.oldIcon, "RIGHT", 1, 0)
        mainFrame.oldTitle:SetSize(160, 44)
        mainFrame.oldTitle:SetJustifyH("LEFT")
		
		mainFrame.oldTitleBG = CreateFrame("Frame", nil, mainFrame)
		mainFrame.oldTitleBG:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		})
		mainFrame.oldTitleBG:SetBackdropColor(0, 0, 0, 0.6)
		mainFrame.oldTitleBG:SetBackdropBorderColor(0.5, 0.5, 0.5)
		mainFrame.oldTitleBG:SetHeight(44)
		mainFrame.oldTitleBG:SetPoint("LEFT", mainFrame.oldTitle, "LEFT", -3, 0)
		mainFrame.oldTitleBG:SetPoint("RIGHT", mainFrame.oldTitle, "RIGHT", 5, 0)
		mainFrame.oldTitle:SetParent(mainFrame.oldTitleBG)

        mainFrame.statsHeader = mainFrame:CreateFontString(nil, "OVERLAY", fontTitle)
        mainFrame.statsHeader:SetPoint("TOPLEFT", 240, -20)
        mainFrame.statsHeader:SetWidth(200)
        mainFrame.statsHeader:SetJustifyH("LEFT")
        mainFrame.statsHeader:SetText("При замене этого предмета произойдут следующие изменения характеристик:")

        mainFrame.stats = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        mainFrame.stats:SetPoint("TOPLEFT", mainFrame.statsHeader, "BOTTOMLEFT", 0, 0)
        mainFrame.stats:SetWidth(200)
        mainFrame.stats:SetJustifyH("LEFT")

        mainFrame.cb = CreateFrame("CheckButton", "AEBBlacklistCB", mainFrame, "UICheckButtonTemplate")
        mainFrame.cb:SetPoint("BOTTOMLEFT", 15, 45)
        mainFrame.cb.text = _G[mainFrame.cb:GetName() .. "Text"]
        mainFrame.cb.text:SetFontObject("GameFontNormal")

        mainFrame.btnOk = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
        mainFrame.btnOk:SetSize(80, 25)
        mainFrame.btnOk:SetPoint("BOTTOMLEFT", 18, 15)
        mainFrame.btnOk:SetText("ОК")

        mainFrame.btnNo = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
        mainFrame.btnNo:SetSize(80, 25)
        mainFrame.btnNo:SetPoint("LEFT", mainFrame.btnOk, "RIGHT", 10, 0)
        mainFrame.btnNo:SetText("Отмена")

        mainFrame.count = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        mainFrame.count:SetPoint("BOTTOMRIGHT", -25, 20)
    end

    local itemName, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)
    
    mainFrame.icon:SetTexture(tex)
    mainFrame.title:SetText(itemName) 
    mainFrame.title:SetTextColor(1, 1, 1) 
    
    mainFrame.cb.text:SetText("Добавить " .. itemLink .. " в чёрный список")
    
    if oldItemLink then
        local oldName, _, _, _, _, _, _, _, _, oldTex = GetItemInfo(oldItemLink)
        mainFrame.oldIcon:SetTexture(oldTex)
        mainFrame.oldTitle:SetText(oldName)
        mainFrame.oldTitle:SetTextColor(1, 1, 1)
    else
        mainFrame.oldIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        mainFrame.oldTitle:SetText("Ничего не надето")
        mainFrame.oldTitle:SetTextColor(0.5, 0.5, 0.5)
    end

    if (self.queueTotal or 0) > 1 then
        mainFrame.count:SetText((self.queueCurrent or 1) .. "/" .. self.queueTotal)
    else
        mainFrame.count:SetText("")
    end
    mainFrame.cb:SetChecked(false)

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

    local statsText = ""
    for statName, delta in pairs(deltas) do
        if delta > 0 then
            statsText = statsText .. "|cff00ff00" .. delta .. "|r " .. statName .. "\n"
        elseif delta < 0 then
            statsText = statsText .. "|cffff0000" .. delta .. "|r " .. statName .. "\n"
        end
    end
    
    if statsText == "" then statsText = "|cff888888Только базовые изменения|r" end
    mainFrame.stats:SetText(statsText)

    mainFrame.btnOk:SetScript("OnClick", function()
        EquipItemByName(itemLink)
        table.remove(itemQueue, 1)
        AEB.queueCurrent = AEB.queueCurrent + 1
        mainFrame:Hide()
        AEB:ShowNextInQueue()
    end)

    mainFrame.btnNo:SetScript("OnClick", function()
        if mainFrame.cb:GetChecked() then
            local id = itemLink:match("item:(%d+)")
            if id then blacklist[id] = true end
        end
        table.remove(itemQueue, 1)
        AEB.queueCurrent = AEB.queueCurrent + 1
        mainFrame:Hide()
        AEB:ShowNextInQueue()
    end)

    mainFrame:Show()
end

function AEB:UpdateKnownSkills()
    self.knownSkills = {}
    local currentHeader = nil
    
    for i = 1, GetNumSkillLines() do
        local name, isHeader = GetSkillLineInfo(i)
        
        if isHeader then
            currentHeader = name
        else
            if currentHeader == "Доспехи" or currentHeader == "Оружейные навыки" then
                local cleanName = name:gsub(" доспехи", "")
                self.knownSkills[cleanName] = true
            end
        end
    end
end

-- === ИНТЕГРАЦИЯ В ПРОФЕССИИ (TRADESKILL) ===
function AEB:TRADE_SKILL_SHOW()
    -- Окно профессий загружается по требованию (LoD), поэтому хукаем безопасно
    if not self.tsHooked and IsAddOnLoaded("Blizzard_TradeSkillUI") then
        hooksecurefunc("TradeSkillFrame_SetSelection", function(id)
            AEB:UpdateTradeSkillArrow(id)
        end)
        self.tsHooked = true
    end
    if self.tsHooked then
        self:UpdateTradeSkillArrow(TradeSkillFrame.selectedSkill)
    end
end

function AEB:UpdateTradeSkillArrow(id)
    if not id or not TradeSkillSkillIcon then return end
    
    -- Выделяем персональную стрелочку для окна крафта, чтобы не зависеть от пула сумок
    if not self.tsArrow then
        self.tsArrow = self:GetArrowFrame()
    end
    self.tsArrow:Hide()
    self.tsArrow:ClearAllPoints()

    local link = GetTradeSkillItemLink(id)
    if link and IsEquippableItem(link) then
        local _, _, _, _, _, _, _, _, loc = GetItemInfo(link)
        if loc and equipSlotMap[loc] then
            local score = self:GetScoreForLink(link)
            local oldScore = self:GetEquippedScoreAndLink(loc)
            if score > oldScore then
                self.tsArrow:SetParent(TradeSkillSkillIcon)
                self.tsArrow:SetPoint("BOTTOMRIGHT", TradeSkillSkillIcon, "BOTTOMRIGHT", 5, -3)
                self.tsArrow:Show()
            end
        end
    end
end

-- === АНАЛИЗ НАГРАД ЗА ЗАДАНИЯ ===
function AEB:QUEST_COMPLETE()
    self:ReleaseAllCoins()
    -- Очищаем стрелочки, которые могли остаться на квестах (используем общий пул)
    
    local numChoices = GetNumQuestChoices()
    if numChoices <= 0 then return end

    local bestUpgradeIdx = nil
    local bestUpgradePct = 0
    local bestValueIdx = nil
    local bestValue = -1

    -- Сканируем награды
    for i = 1, numChoices do
        local link = GetQuestItemLink("choice", i)
        if link then
            -- В 3.3.5 11-й аргумент GetItemInfo — это цена продажи
            local _, _, _, _, _, _, _, _, loc, _, itemSellPrice = GetItemInfo(link)
            local _, _, quantity = GetQuestItemInfo("choice", i)
            
            -- Считаем профит
            local totalValue = (itemSellPrice or 0) * (quantity or 1)
            if totalValue > bestValue then
                bestValue = totalValue
                bestValueIdx = i
            end

            -- Считаем полезность
            if IsEquippableItem(link) and loc and equipSlotMap[loc] then
                local score = self:GetScoreForLink(link)
                local oldScore = self:GetEquippedScoreAndLink(loc)
                
                if score > oldScore then
                    local pct = oldScore == 0 and 100 or ((score - oldScore) / oldScore * 100)
                    if pct > bestUpgradePct then
                        bestUpgradePct = pct
                        bestUpgradeIdx = i
                    end
                end
            end
        end
    end

    -- Визуализация и автовыбор
    local clickIdx = bestUpgradeIdx or bestValueIdx -- Улучшение в приоритете над ценой

    if bestValueIdx then
        local btn = _G["QuestInfoItem" .. bestValueIdx]
        if btn then
            local coin = self:GetCoinFrame()
            coin:SetParent(btn)
            coin:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -2, -2)
            coin:Show()
        end
    end

    if bestUpgradeIdx then
        local btn = _G["QuestInfoItem" .. bestUpgradeIdx]
        if btn then
            local arrow = self:GetArrowFrame()
            arrow:SetParent(btn)
            arrow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 5, -3)
            arrow:Show()
        end
    end

    -- Имитация клика для выбора лучшей награды
    if clickIdx then
        local btn = _G["QuestInfoItem" .. clickIdx]
        if btn then
            QuestInfoItem_OnClick(btn)
        end
    end
end

-- Функция определения активной специализации и обновления весов
function AEB:UpdateStatWeights()
    local _, playerClass = UnitClass("player")
    local activeGroup = GetActiveTalentGroup()
    local highestPoints = -1
    local activeTab = 1

    -- Ищем ветку с максимальным количеством вложенных талантов
    for i = 1, GetNumTalentTabs() do
        local _, _, pointsSpent = GetTalentTabInfo(i, false, false, activeGroup)
        if pointsSpent and pointsSpent > highestPoints then
            highestPoints = pointsSpent
            activeTab = i
        end
    end

    -- Назначаем веса, если таблица для класса и ветки существует
    if classStatWeights[playerClass] and classStatWeights[playerClass][activeTab] then
        statWeights = classStatWeights[playerClass][activeTab]
    else
        statWeights = {} -- Сбрасываем, если данных нет
    end
end

-- === ИНФОРМАТИВНЫЕ ТУЛТИПЫ ===
local function ProcessTooltip(tooltip)
    -- Получаем текущий предмет из тултипа
    local name, link = tooltip:GetItem()
    if not link or not IsEquippableItem(link) then return end

    local _, _, _, _, _, _, _, _, loc = GetItemInfo(link)
    if not loc or not equipSlotMap[loc] then return end

    local score = AEB:GetScoreForLink(link)
    if score <= 0 then return end

    local oldScore, oldLink = AEB:GetEquippedScoreAndLink(loc)
    
    if score > oldScore then
        local pct = 0
        if oldScore == 0 then
            pct = 100 -- Если слот пустой
        else
            pct = math.floor(((score - oldScore) / score) * 100)
        end
        
        -- Получаем имя старого предмета для отображения
        local oldName = oldLink and GetItemInfo(oldLink) or "Ничего не надето"
        
        -- Добавляем строку. 1, 1, 0 — это базовый цвет строки (жёлтый), но проценты зеленые благодаря тегу |cff00ff00
        tooltip:AddLine(string.format("На |cff00ff00%d%%|r лучше, чем [%s]", pct, oldName), 1, 1, 0)
        -- Обязательно вызываем Show, чтобы фрейм пересчитал свою высоту в 3.3.5
        tooltip:Show()
    end
end

-- Хукаем стандартные игровые тултипы при загрузке
GameTooltip:HookScript("OnTooltipSetItem", ProcessTooltip)
ItemRefTooltip:HookScript("OnTooltipSetItem", ProcessTooltip)