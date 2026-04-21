-- Аддон AutoEquipBetter v0.11.4a для World of Warcraft 3.3.5a
--== Важная информация: ==--
-- Для определения возможности надеть предмет на персонажа нельзя использовать функцию IsUsableItem и поиск красного цвета в тексте подсказки, потому что это не даёт нужного результата. Для точного определения типа и подтипа оружия и брони нужно использовать GetItemInfo(id), а для определения возможности надевания - чтение оружейных и доспеховых навыков персонажа.
-- Координаты стрелок относительно иконок и другие подобные визуальные элементы менять не нужно без явного указания. Я настроил их вручную.
local AEB = LibStub("AceAddon-3.0"):NewAddon("AutoEquipBetter", "AceEvent-3.0", "AceHook-3.0")

local scanner = CreateFrame("GameTooltip", "AEBScanner", nil, "GameTooltipTemplate")
scanner:SetOwner(WorldFrame, "ANCHOR_NONE")

AEB_DEBUG_MODE = 1 -- Дебаггер (глобальная переменная)

-- Веса характеристик: [Класс] -> [Ветка талантов (1, 2, 3)]
local classStatWeights = {
    ["HUNTER"] = {
        [1] = { -- Повелитель зверей (BM)
            ["УВС"] = 7.5, ["Ловкость"] = 1.8, ["Сила атаки"] = 2.0, ["Рейтинг меткости"] = 4.0, ["Рейтинг критического удара"] = 1.6, ["Рейтинг скорости"] = 1.2, ["Интеллект"] = 0.5
        },
        [2] = { -- Стрельба (MM)
            ["УВС"] = 8.0, ["Ловкость"] = 2.5, ["Рейтинг пробивания брони"] = 2.4, ["Рейтинг меткости"] = 4.0, ["Рейтинг критического удара"] = 1.9, ["Сила атаки"] = 1.0, ["Интеллект"] = 0.5
        },
        [3] = { -- Выживание (Surv)
            ["УВС"] = 7.5, ["Ловкость"] = 2.8, ["Рейтинг меткости"] = 4.0, ["Рейтинг критического удара"] = 1.8, ["Сила атаки"] = 1.0, ["Рейтинг скорости"] = 1.1, ["Интеллект"] = 0.5
        }
    },
    ["WARRIOR"] = {
        [1] = { -- Оружие (Arms)
            ["УВС"] = 8.0, ["Сила"] = 2.5, ["Рейтинг пробивания брони"] = 2.2, ["Рейтинг мастерства"] = 3.0, ["Рейтинг меткости"] = 3.5, ["Рейтинг критического удара"] = 1.8
        },
        [2] = { -- Неистовство (Fury)
            ["УВС"] = 8.5, ["Сила"] = 2.4, ["Рейтинг пробивания брони"] = 2.3, ["Рейтинг мастерства"] = 3.0, ["Рейтинг меткости"] = 3.5, ["Рейтинг критического удара"] = 1.9, ["Ловкость"] = 1.2
        },
        [3] = { -- Защита (Prot)
            ["Выносливость"] = 3.5, ["Броня"] = 0.15, ["Рейтинг защиты"] = 2.5, ["Рейтинг уклонения"] = 2.0, ["Рейтинг парирования"] = 1.8, ["Блокирование"] = 1.5, ["Сила"] = 1.2
        }
    },
    ["PALADIN"] = {
        [1] = { -- Свет (Holy)
            ["Сила заклинаний"] = 2.0, ["Интеллект"] = 2.2, ["Рейтинг скорости"] = 1.8, ["Рейтинг критического удара"] = 1.2, ["Дух"] = 0.5, ["Восполнение маны"] = 2.5
        },
        [2] = { -- Защита (Prot)
            ["Выносливость"] = 3.5, ["Рейтинг защиты"] = 2.5, ["Броня"] = 0.15, ["Рейтинг уклонения"] = 2.0, ["Рейтинг парирования"] = 1.8, ["Сила"] = 1.5, ["Рейтинг мастерства"] = 2.0
        },
        [3] = { -- Воздаяние (Retri)
            ["Сила"] = 2.5, ["УВС"] = 7.0, ["Рейтинг меткости"] = 3.5, ["Рейтинг мастерства"] = 3.0, ["Рейтинг критического удара"] = 1.8, ["Сила заклинаний"] = 1.0, ["Рейтинг скорости"] = 1.2
        }
    },
    ["DEATHKNIGHT"] = {
        [1] = { -- Кровь (Blood)
            ["Сила"] = 2.5, ["Выносливость"] = 3.0, ["Рейтинг мастерства"] = 2.5, ["Рейтинг меткости"] = 3.5, ["Рейтинг пробивания брони"] = 1.8, ["Рейтинг защиты"] = 2.0
        },
        [2] = { -- Лед (Frost)
            ["Сила"] = 2.5, ["УВС"] = 8.0, ["Рейтинг меткости"] = 3.5, ["Рейтинг мастерства"] = 2.5, ["Рейтинг пробивания брони"] = 2.0, ["Рейтинг критического удара"] = 1.6
        },
        [3] = { -- Нечестивость (Unholy)
            ["Сила"] = 2.5, ["Сила атаки"] = 1.0, ["Рейтинг меткости"] = 3.5, ["Рейтинг критического удара"] = 1.7, ["Рейтинг скорости"] = 1.4, ["Сила заклинаний"] = 0.5
        }
    },
    ["ROGUE"] = {
        [1] = { -- Ликвидация (Assassination)
            ["Ловкость"] = 2.2, ["Сила атаки"] = 1.0, ["Рейтинг меткости"] = 3.5, ["Рейтинг мастерства"] = 2.5, ["Рейтинг скорости"] = 1.8, ["Рейтинг критического удара"] = 1.6
        },
        [2] = { -- Бой (Combat)
            ["УВС"] = 6.0, ["Ловкость"] = 2.0, ["Рейтинг пробивания брони"] = 2.4, ["Рейтинг мастерства"] = 3.0, ["Рейтинг меткости"] = 3.5, ["Сила атаки"] = 1.0
        },
        [3] = { -- Скрытность (Subtlety)
            ["Ловкость"] = 2.4, ["Сила атаки"] = 1.0, ["Рейтинг пробивания брони"] = 1.8, ["Рейтинг критического удара"] = 1.8, ["Рейтинг меткости"] = 3.0
        }
    },
    ["DRUID"] = {
        [1] = { -- Баланс (Balance)
            ["Сила заклинаний"] = 2.0, ["Рейтинг скорости"] = 1.7, ["Рейтинг критического удара"] = 1.5, ["Рейтинг меткости"] = 3.5, ["Интеллект"] = 1.0, ["Дух"] = 0.8
        },
        [2] = { -- Сила зверя (Feral)
            ["Ловкость"] = 2.5, ["Рейтинг пробивания брони"] = 2.2, ["Сила"] = 1.5, ["Рейтинг мастерства"] = 2.5, ["Рейтинг меткости"] = 3.5, ["Выносливость"] = 2.0
        },
        [3] = { -- Исцеление (Restoration)
            ["Сила заклинаний"] = 2.0, ["Дух"] = 1.8, ["Рейтинг скорости"] = 1.6, ["Интеллект"] = 1.4, ["Восполнение маны"] = 2.0
        }
    },
    ["SHAMAN"] = {
        [1] = { -- Стихии (Elemental)
            ["Сила заклинаний"] = 2.0, ["Рейтинг скорости"] = 1.6, ["Рейтинг меткости"] = 3.5, ["Рейтинг критического удара"] = 1.4, ["Интеллект"] = 1.0
        },
        [2] = { -- Совершенствование (Enhancement)
            ["Сила атаки"] = 1.0, ["Ловкость"] = 1.8, ["Сила заклинаний"] = 1.4, ["Рейтинг меткости"] = 3.5, ["Рейтинг мастерства"] = 2.5, ["Рейтинг скорости"] = 1.6
        },
        [3] = { -- Исцеление (Restoration)
            ["Сила заклинаний"] = 2.0, ["Рейтинг скорости"] = 1.7, ["Интеллект"] = 1.2, ["Восполнение маны"] = 2.5, ["Рейтинг критического удара"] = 1.0
        }
    },
    ["MAGE"] = {
        [1] = { -- Тайная магия (Arcane)
            ["Сила заклинаний"] = 2.0, ["Интеллект"] = 1.4, ["Рейтинг скорости"] = 1.6, ["Рейтинг критического удара"] = 1.3, ["Рейтинг меткости"] = 3.5
        },
        [2] = { -- Огонь (Fire)
            ["Сила заклинаний"] = 2.0, ["Рейтинг критического удара"] = 1.8, ["Рейтинг скорости"] = 1.5, ["Рейтинг меткости"] = 3.5, ["Дух"] = 0.8
        },
        [3] = { -- Лед (Frost)
            ["Сила заклинаний"] = 2.0, ["Рейтинг скорости"] = 1.4, ["Рейтинг критического удара"] = 1.4, ["Рейтинг меткости"] = 3.5
        }
    },
    ["WARLOCK"] = {
        [1] = { -- Колдовство (Affliction)
            ["Сила заклинаний"] = 2.1, ["Рейтинг скорости"] = 1.7, ["Дух"] = 1.2, ["Рейтинг меткости"] = 3.5, ["Рейтинг критического удара"] = 1.3
        },
        [2] = { -- Демонология (Demonology)
            ["Сила заклинаний"] = 2.2, ["Рейтинг скорости"] = 1.5, ["Рейтинг критического удара"] = 1.4, ["Рейтинг меткости"] = 3.5, ["Дух"] = 0.7
        },
        [3] = { -- Разрушение (Destruction)
            ["Сила заклинаний"] = 2.0, ["Рейтинг скорости"] = 1.6, ["Рейтинг критического удара"] = 1.6, ["Рейтинг меткости"] = 3.5
        }
    },
    ["PRIEST"] = {
        [1] = { -- Послушание (Discipline)
            ["Сила заклинаний"] = 2.0, ["Интеллект"] = 1.8, ["Рейтинг скорости"] = 1.4, ["Дух"] = 1.0, ["Восполнение маны"] = 2.0
        },
        [2] = { -- Свет (Holy)
            ["Сила заклинаний"] = 2.0, ["Дух"] = 1.8, ["Рейтинг скорости"] = 1.6, ["Интеллект"] = 1.2, ["Восполнение маны"] = 1.5
        },
        [3] = { -- Тьма (Shadow)
            ["Сила заклинаний"] = 2.0, ["Рейтинг скорости"] = 1.8, ["Рейтинг критического удара"] = 1.5, ["Рейтинг меткости"] = 3.5, ["Дух"] = 1.0
        }
    }
}

-- Словарь для перевода подтипов оружия из GetItemInfo в названия навыков из книги
local subTypeToSkill = {
	["Арбалеты"] = "Арбалеты", 
	["Двуручные мечи"] = "Двуручные мечи", 
	["Двуручные топоры"] = "Двуручные топоры", 
	["Древковое"] = "Древковое оружие", 
    ["Кинжалы"] = "Кинжалы", 
	["Луки"] = "Луки", 
	["Метательное"] = "Метательное оружие", 
	["Одноручные мечи"] = "Мечи", 
	["Огнестрельное"] = "Огнестрельное оружие", 
	["Посохи"] = "Посохи", 
	["Одноручные топоры"] = "Топоры", 
	["Одноручное дробящее"] = "Дробящее оружие", 
	["Двуручное дробящее"] = "Двуручное дробящее оружие", 
	["Кистевое"] = "Кистевое", 
	["Жезлы"] = "Жезлы", 
	["Удочки"] = "Рыбная ловля", 
}

AEB.knownSkills = {}

-- Функция сканирует книгу навыков игрока и сохраняет их в таблицу
function AEB:UpdateKnownSkills()
    wipe(self.knownSkills)
    for i = 1, GetNumSkillLines() do
        local skillName, header = GetSkillLineInfo(i)
        if not header and skillName then
            self.knownSkills[skillName] = true
        end
    end
end

-- Проверка способности "Бой двумя оружиями" (Dual Wield)
function AEB:CanDualWield()
    local spellName = GetSpellInfo(674) -- ID способности "Бой двумя оружиями"
    if spellName and GetSpellInfo(spellName) then
        return true
    end
    return false
end

-- Проверка таланта "Хватка титана" (Titan's Grip) для воинов
function AEB:HasTitansGrip()
    local _, class = UnitClass("player")
    if class ~= "WARRIOR" then return false end

    local name, iconTexture, tier, column, currRank = GetTalentInfo(2, 27)
    if currRank and currRank > 0 then
        return true
    end
    return false
end

-- Новая динамическая проверка возможности надеть предмет
function AEB:CanPlayerWear(itemType, subType)
    -- Всегда разрешаем ткань и бижутерию (кольца, шеи, триньки)
    if subType == "Тканевые" or subType == "Разное" then return true end
    if itemType ~= "Оружие" and itemType ~= "Доспехи" then return true end

    -- Проверка оружия: строго ищем совпадение по таблице навыков
    if itemType == "Оружие" then
        local requiredSkill = subTypeToSkill[subType]
        if requiredSkill then
            return self.knownSkills[requiredSkill] or false
        end
        return true -- Если попадётся неизвестный тип, разрешаем
    end

    -- Проверка доспехов: работает по принципу иерархии (Латы -> Кольчуга -> Кожа)
    if itemType == "Доспехи" then
        if subType == "Щиты" then
            return self.knownSkills["Щит"] or false
        end
        if subType == "Латные" then
            return self.knownSkills["Латные доспехи"] or false
        end
        if subType == "Кольчужные" then
            -- Кто умеет носить латы, тот умеет носить и кольчугу
            return self.knownSkills["Кольчужные доспехи"] or self.knownSkills["Латные доспехи"] or false
        end
        if subType == "Кожаные" then
            -- Кто умеет носить кольчугу или латы, тот умеет носить и кожу
            return self.knownSkills["Кожаные доспехи"] or self.knownSkills["Кольчужные доспехи"] or self.knownSkills["Латные доспехи"] or false
        end
        
        -- Разрешаем всё остальное (Манускрипты, Тотемы, Идолы и т.д.)
        return true 
    end

    return true
end

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

-- Настройки по умолчанию
local defaultSettings = {
    autoSuggest = true,
    autoEquip = false,
    delay = 1,
    framePos = { point = "CENTER", x = 0, y = 0 },
    blacklist = {},
    autoEquipAmmo = false,
    ammoBestQuality = true
}

local itemQueue = {}
local mainFrame = nil
local itemScoreCache = {}
local settingsFrame = nil

-- === ОПТИМИЗАЦИЯ СОБЫТИЙ (DEBOUNCE) ===
local isDirty = false
local updateTimer = 0
local bagUpdateTimer = 0
local bagUpdatePending = false
local enterWorldTimer = 0
local enterWorldPending = false

-- Переменные для квестовых стрелок (должны быть доступны глобально)
local questRewardDelayTimer = 0
local questRewardDelayPending = false
local isShowingQuestRewards = false

local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    -- Обработка обновления стрелок
    if isDirty then
        updateTimer = updateTimer + elapsed
        if updateTimer > 0.05 then
            isDirty = false
            updateTimer = 0
            AEB:RefreshArrows()
        end
    end

    -- Обработка задержки при изменении сумок
    if bagUpdatePending then
        bagUpdateTimer = bagUpdateTimer + elapsed
        if bagUpdateTimer >= (AEB.db.delay or 1) then
            bagUpdatePending = false
            bagUpdateTimer = 0
            AEB:CheckAndSuggestUpgrades()
        end
    end

    -- Обработка задержки при входе в мир
    if enterWorldPending then
        enterWorldTimer = enterWorldTimer + elapsed
        if enterWorldTimer >= (AEB.db.delay or 1) then
            enterWorldPending = false
            enterWorldTimer = 0
            if AEB.db.autoSuggest then
                AEB:CheckAndSuggestUpgrades()
            end
        end
    end
end)

-- === ФУНКЦИИ ДЛЯ РАБОТЫ С БОЕПРИПАСАМИ ===
local AMMOSLOT = 0

function AEB:FindBestAmmo()
    local bestAmmo = nil
    local bestQuality = -1

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local _, _, quality, _, _, itemType = GetItemInfo(itemLink)
                if itemType == "Projectile" then
                    -- Если включен приоритет качества, выбираем лучшее
                    if self.db.ammoBestQuality then
                        if quality and quality > bestQuality then
                            bestQuality = quality
                            bestAmmo = {bag = bag, slot = slot, link = itemLink, quality = quality}
                        end
                    else
                        -- Иначе берем первые попавшиеся
                        return {bag = bag, slot = slot, link = itemLink, quality = quality}
                    end
                end
            end
        end
    end

    return bestAmmo
end

function AEB:EquipBestAmmo()
    if not self.db.autoEquipAmmo then
        return
    end

    local ammo = self:FindBestAmmo()
    if ammo then
        -- Проверяем, не экипированы ли уже эти боеприпасы
        local equippedLink = GetInventoryItemLink("player", AMMOSLOT)
        if equippedLink ~= ammo.link then
            PickupContainerItem(ammo.bag, ammo.slot)
            EquipCursorItem(AMMOSLOT)
        end
    end
end

function AEB:OnInitialize()
    -- Инициализация SavedVariables
    if not AutoEquipBetterDB then
        AutoEquipBetterDB = {}
    end

    -- Загрузка настроек персонажа
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local charKey = playerName .. "-" .. realmName

    if not AutoEquipBetterDB[charKey] then
        AutoEquipBetterDB[charKey] = CopyTable(defaultSettings)
    end

    self.db = AutoEquipBetterDB[charKey]

    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("MERCHANT_SHOW")
    self:RegisterEvent("MERCHANT_UPDATE")
    self:RegisterEvent("MERCHANT_CLOSED")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("TRADE_SKILL_SHOW")
    self:RegisterEvent("QUEST_DETAIL")
    self:RegisterEvent("QUEST_COMPLETE")
    self:RegisterEvent("QUEST_FINISHED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    -- Подписываемся на смену талантов (срабатывает и при логине, и при смене спека)
    self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateStatWeights")
    -- Вызываем принудительно при загрузке, чтобы тултипы работали сразу
    self:UpdateStatWeights()
	self:RegisterEvent("SKILL_LINES_CHANGED", "UpdateKnownSkills")
    self:UpdateKnownSkills()
    -- Реагируем на прокрутку окон сумок и торговца
    hooksecurefunc("MerchantFrame_Update", function() isDirty = true end)
    hooksecurefunc("ContainerFrame_Update", function() isDirty = true end)
    -- Хук на QuestInfo_ShowRewards с защитой от рекурсии
    -- Устанавливаем хук после загрузки UI квестов
    local questHookInstalled = false

    local questRewardDelayFrame = CreateFrame("Frame")
    questRewardDelayFrame:SetScript("OnUpdate", function(self, elapsed)
        if questRewardDelayPending then
            questRewardDelayTimer = questRewardDelayTimer + elapsed
            -- Уменьшенная задержка для более быстрого отклика
            if questRewardDelayTimer > 0.1 then
                questRewardDelayPending = false
                questRewardDelayTimer = 0
                AEB:UpdateQuestRewardsArrows()
                isShowingQuestRewards = false
            end
        end
    end)

    -- Функция установки хука
    local function InstallQuestHook()
        if questHookInstalled then return end
        questHookInstalled = true

        hooksecurefunc("QuestInfo_ShowRewards", function()
            if isShowingQuestRewards then return end
            isShowingQuestRewards = true
            questRewardDelayPending = true
            questRewardDelayTimer = 0
        end)

        -- Хук на выбор квеста в журнале
        hooksecurefunc("QuestLog_SetSelection", function(questIndex)
            if QuestLogFrame and QuestLogFrame:IsVisible() and questIndex and questIndex > 0 then
                -- Очищаем старые стрелки перед показом новых
                AEB:ClearQuestRewardMarkers()
                questRewardDelayPending = true
                questRewardDelayTimer = 0
            end
        end)

        -- Хук на обновление деталей квеста (для клика на квест в Quest Watch)
        hooksecurefunc("QuestLog_UpdateQuestDetails", function()
            -- Проверяем оба окна: журнал квестов и окно деталей из трекера
            local isQuestLogVisible = QuestLogFrame and QuestLogFrame:IsVisible()
            local isDetailFrameVisible = QuestLogDetailFrame and QuestLogDetailFrame:IsVisible()

            if isQuestLogVisible or isDetailFrameVisible then
                local selectedQuest = GetQuestLogSelection()
                if selectedQuest and selectedQuest > 0 then
                    questRewardDelayPending = true
                    questRewardDelayTimer = 0
                end
            end
        end)
    end

    -- Устанавливаем хук сразу
    InstallQuestHook()

    -- Отслеживаем закрытие окон квестов через OnHide
    if QuestFrame then
        QuestFrame:HookScript("OnHide", function()
            AEB:ClearQuestRewardMarkers()
        end)
        -- Хук на показ окна "Детали задания"
        QuestFrame:HookScript("OnShow", function()
            questRewardDelayPending = true
            questRewardDelayTimer = 0
        end)
    end
    if QuestLogFrame then
        QuestLogFrame:HookScript("OnHide", function()
            AEB:ClearQuestRewardMarkers()
        end)
    end
    if QuestLogDetailFrame then
        QuestLogDetailFrame:HookScript("OnHide", function()
            AEB:ClearQuestRewardMarkers()
        end)
    end

    -- И также при открытии журнала квестов (на случай если UI грузится по требованию)
    local questLogHooked = false
    local lastQuestLogSelection = nil
    self.QUEST_LOG_UPDATE = function()
        if not questLogHooked and QuestLogFrame then
            questLogHooked = true
            InstallQuestHook()
        end

        -- Дополнительно: обновляем стрелки при изменении выбранного квеста в журнале
        if QuestLogFrame and QuestLogFrame:IsVisible() then
            local selectedQuest = GetQuestLogSelection()
            if selectedQuest ~= lastQuestLogSelection and selectedQuest > 0 then
                lastQuestLogSelection = selectedQuest
                if not AEB_DebugLog then AEB_DebugLog = {} end
                table.insert(AEB_DebugLog, "QUEST_LOG_UPDATE: selectedQuest = " .. selectedQuest)
                -- Задержка для обновления UI
                questRewardDelayPending = true
                questRewardDelayTimer = 0
            end
        end
    end

    self:RegisterEvent("QUEST_LOG_UPDATE")

    -- Реагируем на клик по награде - восстанавливаем стрелки после клика
    local restoreTimer = 0
    local needRestore = false
    if QuestInfoItem_OnClick then
        hooksecurefunc("QuestInfoItem_OnClick", function(self)
            needRestore = true
            restoreTimer = 0
        end)
    end

    -- Добавляем обработчик для восстановления стрелок
    local restoreFrame = CreateFrame("Frame")
    restoreFrame:SetScript("OnUpdate", function(self, elapsed)
        if needRestore then
            restoreTimer = restoreTimer + elapsed
            if restoreTimer > 0.1 then
                needRestore = false
                restoreTimer = 0
                -- Показываем стрелки заново
                for _, arrow in ipairs(upgradeArrows) do
                    if arrow.isQuestReward then
                        -- Проверяем, есть ли у стрелки точки привязки
                        local numPoints = arrow:GetNumPoints()
                        if numPoints == 0 then
                            -- Находим кнопку с лучшим апгрейдом и привязываем заново
                            AEB:UpdateQuestRewardsArrows()
                        else
                            arrow:Show()
                        end
                    end
                end
            end
        end
    end)

    -- Определяем класс игрока и загружаем его веса
    local _, playerClass = UnitClass("player")
    statWeights = classStatWeights[playerClass] or {}

    -- Регистрация команды /aeb
    SLASH_AUTOEQUIPBETTER1 = "/aeb"
    SlashCmdList["AUTOEQUIPBETTER"] = function(msg)
        msg = strtrim(msg:lower())
        if msg == "equip" then
            AEB:CheckAndSuggestUpgrades()
        else
            AEB:ShowSettingsFrame()
        end
    end

    -- Сообщение при запуске
    print("|cff00ff00AutoEquipBetter|r запущен. Введите |cffffcc00/aeb|r для открытия окна настроек")
end

function AEB:BAG_UPDATE()
    isDirty = true

    -- Автопроверка при изменении сумок с задержкой
    if self.db.autoSuggest then
        bagUpdateTimer = 0
        bagUpdatePending = true
    end

    -- Автоэкипировка боеприпасов
    self:EquipBestAmmo()
end
function AEB:MERCHANT_SHOW() isDirty = true end
function AEB:MERCHANT_UPDATE() isDirty = true end
function AEB:MERCHANT_CLOSED() isDirty = true; self:ReleaseAllArrows() end
function AEB:PLAYER_EQUIPMENT_CHANGED()
    isDirty = true
    -- Автоэкипировка боеприпасов при смене оружия
    self:EquipBestAmmo()
end
function AEB:PLAYER_ENTERING_WORLD()
    -- Запуск проверки при входе в мир с задержкой
    enterWorldTimer = 0
    enterWorldPending = true
end

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
        arrow.isQuestReward = nil
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
        coin.isQuestReward = nil
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
        if type(v) == "number" then
            local weight = statWeights[n]
            if not weight then
                if n == "Броня" then weight = 0.001
                elseif n == "УВС" then weight = 0.1
                elseif n == "Выносливость" then weight = 0.05
                else weight = 0
                end
            end
            score = score + (v * weight)
        end
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

local mainHandLocs = { ["INVTYPE_WEAPONMAINHAND"] = true, ["INVTYPE_WEAPON"] = true, ["INVTYPE_2HWEAPON"] = true }
local offHandLocs = { ["INVTYPE_WEAPONOFFHAND"] = true, ["INVTYPE_WEAPON"] = true, ["INVTYPE_SHIELD"] = true, ["INVTYPE_HOLDABLE"] = true, ["INVTYPE_2HWEAPON"] = true }

function AEB:GetBestItemFromBags(allowedLocs)
    local bestScore = 0
    local bestLink = nil
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link and IsEquippableItem(link) then
                local id = link:match("item:(%d+)")
                if id and not self.db.blacklist[id] then
                    local _, _, _, _, minLvl, itemType, subType, _, loc = GetItemInfo(link)
                    if allowedLocs[loc] and (not minLvl or minLvl <= UnitLevel("player")) and self:CanPlayerWear(itemType, subType) then
                        -- Дополнительная проверка: если ищем для offhand и это одноручное оружие
                        if allowedLocs == offHandLocs and loc == "INVTYPE_WEAPON" and not self:CanDualWield() then
                            -- Пропускаем одноручное оружие для offhand без Dual Wield
                        -- Дополнительная проверка: если ищем для offhand и это двуручное оружие
                        elseif allowedLocs == offHandLocs and loc == "INVTYPE_2HWEAPON" and not self:HasTitansGrip() then
                            -- Пропускаем двуручное оружие для offhand без Titan's Grip
                        else
                            local score = self:GetScoreForLink(link)
                            if score > bestScore then
                                bestScore = score
                                bestLink = link
                            end
                        end
                    end
                end
            end
        end
    end
    return bestScore, bestLink
end

function AEB:GetUpgradeInfo(newItemLink, loc, newItemScore)
    if not newItemScore or newItemScore <= 0 then return false end
    
    local isWeaponSlot = (loc == "INVTYPE_WEAPON" or loc == "INVTYPE_2HWEAPON" or loc == "INVTYPE_WEAPONMAINHAND" or loc == "INVTYPE_WEAPONOFFHAND" or loc == "INVTYPE_SHIELD" or loc == "INVTYPE_HOLDABLE")
    
    if isWeaponSlot then
        local eqMHLink = GetInventoryItemLink("player", 16)
        local eqOHLink = GetInventoryItemLink("player", 17)
        local eqMHScore = self:GetScoreForLink(eqMHLink)
        local eqOHScore = self:GetScoreForLink(eqOHLink)

        local isEqMH2H = false
        if eqMHLink then
            local _, _, _, _, _, _, _, _, l = GetItemInfo(eqMHLink)
            if l == "INVTYPE_2HWEAPON" then isEqMH2H = true end
        end

        local hasTitansGrip = self:HasTitansGrip()

        if loc == "INVTYPE_2HWEAPON" then
            if hasTitansGrip then
                -- С талантом "Хватка титана" можно носить два двуручника
                local targetScore = math.min(eqMHScore, eqOHScore)
                local targetLink = (eqMHScore <= eqOHScore) and eqMHLink or eqOHLink
                if newItemScore > targetScore then return true, newItemScore, targetScore, targetLink, nil, nil, false end
            else
                -- Без таланта двуручник заменяет оба слота
                local totalEqScore = eqMHScore + eqOHScore
                if newItemScore > totalEqScore then
                    local names = {}
                    if eqMHLink then table.insert(names, (select(1, GetItemInfo(eqMHLink)))) end
                    if eqOHLink then table.insert(names, (select(1, GetItemInfo(eqOHLink)))) end
                    local oldNameStr = #names > 0 and table.concat(names, " + ") or "Ничего не надето"
                    return true, newItemScore, totalEqScore, nil, oldNameStr, nil, true
                end
            end
            return false
        end

        if isEqMH2H and not hasTitansGrip then
            local comboScore = newItemScore
            local companionLink = nil

            if mainHandLocs[loc] and not offHandLocs[loc] then
                local ohScore, ohLink = self:GetBestItemFromBags(offHandLocs)
                comboScore = comboScore + ohScore
                companionLink = ohLink
            elseif offHandLocs[loc] and not mainHandLocs[loc] then
                local mhScore, mhLink = self:GetBestItemFromBags(mainHandLocs)
                comboScore = comboScore + mhScore
                companionLink = mhLink
            else
                local ohScore, ohLink = self:GetBestItemFromBags(offHandLocs)
                local mhScore, mhLink = self:GetBestItemFromBags(mainHandLocs)
                if ohScore >= mhScore then
                    comboScore = comboScore + ohScore
                    companionLink = ohLink
                else
                    comboScore = comboScore + mhScore
                    companionLink = mhLink
                end
            end

            if comboScore > eqMHScore then
                local oldName = eqMHLink and (select(1, GetItemInfo(eqMHLink))) or "Ничего не надето"
                return true, comboScore, eqMHScore, eqMHLink, oldName, companionLink, false
            end
            return false
        end

        if loc == "INVTYPE_WEAPONMAINHAND" then
            if newItemScore > eqMHScore then return true, newItemScore, eqMHScore, eqMHLink, nil, nil, false end
        elseif loc == "INVTYPE_WEAPONOFFHAND" or loc == "INVTYPE_SHIELD" or loc == "INVTYPE_HOLDABLE" then
            if newItemScore > eqOHScore then return true, newItemScore, eqOHScore, eqOHLink, nil, nil, false end
        elseif loc == "INVTYPE_WEAPON" then
            -- Проверяем способность носить оружие в левой руке
            if not self:CanDualWield() then
                -- Без Dual Wield одноручное оружие может быть только в mainhand
                if newItemScore > eqMHScore then
                    return true, newItemScore, eqMHScore, eqMHLink, nil, nil, false
                end
            else
                -- С Dual Wield сравниваем с худшим из двух слотов
                local targetScore = math.min(eqMHScore, eqOHScore)
                local targetLink = (eqMHScore <= eqOHScore) and eqMHLink or eqOHLink
                if newItemScore > targetScore then
                    return true, newItemScore, targetScore, targetLink, nil, nil, false
                end
            end
        end
        return false
    end

    local oldScore, oldLink = self:GetEquippedScoreAndLink(loc)
    if newItemScore > oldScore then
        return true, newItemScore, oldScore, oldLink, nil, nil, false
    end
    return false
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
-- Функция проверки и предложения улучшений
function AEB:CheckAndSuggestUpgrades()
    if InCombatLockdown() then return end
    if not self.db.autoSuggest and not self.db.autoEquip then return end

    local upgrades = {}

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link and IsEquippableItem(link) then
                local id = link:match("item:(%d+)")
                if id and not self.db.blacklist[id] then
                    local _, _, _, _, minLvl, itemType, subType, _, loc = GetItemInfo(link)
                    if loc and equipSlotMap[loc] then
                        if (not minLvl or minLvl <= UnitLevel("player")) and self:CanPlayerWear(itemType, subType) then
                            local score = self:GetScoreForLink(link)
                            local isUp, newS, oldS, oldL, oldNameOvr, compLink, oldIsPair = self:GetUpgradeInfo(link, loc, score)

                            if isUp then
                                -- Проверка на пустой слот
                                local isEmpty = (oldS == 0 or not oldL)

                                table.insert(upgrades, {
                                    link = link, id = id, score = score, bag = bag, slot = slot, loc = loc,
                                    newS = newS, oldS = oldS, oldL = oldL, oldNameOvr = oldNameOvr,
                                    compLink = compLink, oldIsPair = oldIsPair
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    -- Сортировка по приросту
    table.sort(upgrades, function(a, b)
        return a.newS > b.newS
    end)

    -- Добавление в очередь предложений
    for _, data in ipairs(upgrades) do
        local alreadyInQueue = false
        for _, q in ipairs(itemQueue) do
            if q.id == data.id then
                alreadyInQueue = true
                break
            end
        end

        if not alreadyInQueue then
            if #itemQueue == 0 then
                self.queueCurrent = 1
                self.queueTotal = 0
            end
            table.insert(itemQueue, data)
            self.queueTotal = self.queueTotal + 1
        end
    end

    -- Показ окна или автонадевание
    if #itemQueue > 0 then
        if self.db.autoEquip then
            -- Автонадевание без окна
            for _, data in ipairs(itemQueue) do
                -- Проверка на бой
                if UnitAffectingCombat("player") then
                    local isWeaponSlot = (data.loc == "INVTYPE_WEAPON" or data.loc == "INVTYPE_2HWEAPON" or
                                          data.loc == "INVTYPE_WEAPONMAINHAND" or data.loc == "INVTYPE_WEAPONOFFHAND" or
                                          data.loc == "INVTYPE_SHIELD" or data.loc == "INVTYPE_HOLDABLE" or
                                          data.loc == "INVTYPE_RANGED" or data.loc == "INVTYPE_THROWN" or data.loc == "INVTYPE_RANGEDRIGHT")
                    if isWeaponSlot then
                        EquipItemByName(data.link)
                        if data.compLink then EquipItemByName(data.compLink) end
                    end
                else
                    EquipItemByName(data.link)
                    if data.compLink then EquipItemByName(data.compLink) end
                end
            end
            wipe(itemQueue)
            self.queueCurrent = 1
            self.queueTotal = 0
        else
            -- Показ окна предложения
            self:ShowNextInQueue()
        end
    end
end

function AEB:RefreshArrows()
    self:ReleaseAllArrows()
    self:ReleaseAllCoins()
    if InCombatLockdown() then return end
    
    local bestBags = {}
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link and IsEquippableItem(link) then
                local id = link:match("item:(%d+)")
                if id and not self.db.blacklist[id] then
                    local _, _, _, _, minLvl, itemType, subType, _, loc = GetItemInfo(link)
                    if loc and equipSlotMap[loc] then
                        if (not minLvl or minLvl <= UnitLevel("player")) and self:CanPlayerWear(itemType, subType) then
                            local score = self:GetScoreForLink(link)
                            local isUp, newS, oldS, oldL, oldNameOvr, compLink, oldIsPair = self:GetUpgradeInfo(link, loc, score)

                            if isUp then
                                if not bestBags[loc] or newS > bestBags[loc].newS then
                                    bestBags[loc] = {
                                        link = link, id = id, score = score, bag = bag, slot = slot, loc = loc,
                                        newS = newS, oldS = oldS, oldL = oldL, oldNameOvr = oldNameOvr, compLink = compLink, oldIsPair = oldIsPair
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    local bestMerchant = {}
    if MerchantFrame and MerchantFrame:IsVisible() then
        local numMerchantItems = GetMerchantNumItems()
        for i = 1, numMerchantItems do
            local link = GetMerchantItemLink(i)
            if link and IsEquippableItem(link) then
                local _, _, _, _, minLvl, itemType, subType, _, loc = GetItemInfo(link)
                if loc and equipSlotMap[loc] then
                    if (not minLvl or minLvl <= UnitLevel("player")) and self:CanPlayerWear(itemType, subType) then
                        local score = self:GetScoreForLink(link)
                        local isUp, newS = self:GetUpgradeInfo(link, loc, score)

                        if isUp then
                            local slotId = equipSlotMap[loc]
                            -- Сравниваем между собой предметы для одного слота
                            if not bestMerchant[slotId] or newS > bestMerchant[slotId].newS then
                                bestMerchant[slotId] = { index = i, score = score, loc = loc, newS = newS }
                            end
                        end
                    end
                end
            end
        end
    end

    for loc, data in pairs(bestBags) do
        local btn = self:GetContainerButton(data.bag, data.slot)
        if btn and btn:IsVisible() then
            local arrow = self:GetArrowFrame()
            arrow:SetParent(btn)
            arrow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 5, -3)
            arrow:Show()
        end

        local alreadyInQueue = false
        for _, q in ipairs(itemQueue) do if q.id == data.id then alreadyInQueue = true end end
        if not alreadyInQueue then
            if #itemQueue == 0 then
                self.queueCurrent = 1
                self.queueTotal = 0
            end
            table.insert(itemQueue, data)
            self.queueTotal = self.queueTotal + 1
            self:ShowNextInQueue()
            if mainFrame and mainFrame:IsVisible() and self.queueTotal > 1 then
                mainFrame.count:SetText(self.queueCurrent .. "/" .. self.queueTotal)
            end
        end
    end

    local startIdx = ((MerchantFrame.page or 1) - 1) * MERCHANT_ITEMS_PER_PAGE + 1
    local endIdx = startIdx + MERCHANT_ITEMS_PER_PAGE - 1
    for slotId, data in pairs(bestMerchant) do
        if data.index >= startIdx and data.index <= endIdx then
            local btnIdx = data.index - startIdx + 1
            local btn = _G["MerchantItem"..btnIdx.."ItemButton"]
            if btn and btn:IsVisible() then
                local arrow = self:GetArrowFrame()
                arrow:SetParent(btn)
                arrow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 5, -3)
                arrow:SetFrameLevel(btn:GetFrameLevel() + 5)
                arrow:Show()
            end
        end
    end
end

-- === УПРАВЛЕНИЕ ОЧЕРЕДЬЮ UI ===
function AEB:ShowNextInQueue()
    if mainFrame and mainFrame:IsVisible() then return end
    
    while #itemQueue > 0 do
        local data = itemQueue[1]
        local score = self:GetScoreForLink(data.link)
        local isUp, newS, oldS, oldL, oldNameOvr, compLink, oldIsPair = self:GetUpgradeInfo(data.link, data.loc, score)
        
        if isUp then
            data.newS, data.oldS, data.oldL = newS, oldS, oldL
            data.oldNameOvr, data.compLink, data.oldIsPair = oldNameOvr, compLink, oldIsPair
            self:CreateUI(data)
            return
        else
            table.remove(itemQueue, 1)
        end
    end
end

-- === ОТРИСОВКА ОКНА ===
local function AddStats(t1, t2)
    if not t2 then return end
    for k, v in pairs(t2) do
        if type(v) == "number" then t1[k] = (t1[k] or 0) + v end
    end
end

function AEB:CreateUI(q)
    if not mainFrame then
        mainFrame = CreateFrame("Frame", "AEBMainFrame", UIParent)
        mainFrame:SetSize(450, 300)

        -- Восстановление позиции из настроек
        if self.db and self.db.framePos then
            local pos = self.db.framePos
            mainFrame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
        else
            mainFrame:SetPoint("CENTER")
        end

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
        mainFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Сохранение позиции
            local point, _, _, x, y = self:GetPoint()
            AEB.db.framePos = { point = point, x = x, y = y }
            -- Принудительное сохранение
            if AutoEquipBetterDB then
                local playerName = UnitName("player")
                local realmName = GetRealmName()
                local charKey = playerName .. "-" .. realmName
                AutoEquipBetterDB[charKey] = AEB.db
            end
        end)

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
        mainFrame.statsHeader:SetText("При замене произойдут следующие изменения характеристик:")

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

    local itemName, _, _, _, _, _, _, _, _, tex = GetItemInfo(q.link)

    if q.compLink then
        local compName = (select(1, GetItemInfo(q.compLink)))
        itemName = itemName .. " + " .. compName
    end
    
    mainFrame.icon:SetTexture(tex)
    mainFrame.title:SetText(itemName) 
    mainFrame.title:SetTextColor(1, 1, 1) 
    
    mainFrame.cb.text:SetText("Добавить в чёрный список")
    
    if q.oldNameOvr then
        mainFrame.oldIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
        mainFrame.oldTitle:SetText(q.oldNameOvr)
        mainFrame.oldTitle:SetTextColor(1, 1, 1)
    elseif q.oldL then
        local oldName, _, _, _, _, _, _, _, _, oldTex = GetItemInfo(q.oldL)
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

    local newStats = self:ScanItem(q.link)
    if q.compLink then AddStats(newStats, self:ScanItem(q.compLink)) end
    
    local oldStats = {}
    if q.oldIsPair then
        local eqMHLink = GetInventoryItemLink("player", 16)
        local eqOHLink = GetInventoryItemLink("player", 17)
        if eqMHLink then AddStats(oldStats, self:ScanItem(eqMHLink)) end
        if eqOHLink then AddStats(oldStats, self:ScanItem(eqOHLink)) end
    elseif q.oldL then
        oldStats = self:ScanItem(q.oldL)
    end
    
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
        -- Проверка на бой (кроме оружия)
        if UnitAffectingCombat("player") then
            local isWeaponSlot = (q.loc == "INVTYPE_WEAPON" or q.loc == "INVTYPE_2HWEAPON" or
                                  q.loc == "INVTYPE_WEAPONMAINHAND" or q.loc == "INVTYPE_WEAPONOFFHAND" or
                                  q.loc == "INVTYPE_SHIELD" or q.loc == "INVTYPE_HOLDABLE" or
                                  q.loc == "INVTYPE_RANGED" or q.loc == "INVTYPE_THROWN" or q.loc == "INVTYPE_RANGEDRIGHT")
            if not isWeaponSlot then
                print("|cffff0000Невозможно сменить экипировку в бою (кроме оружия)|r")
                return
            end
        end

        EquipItemByName(q.link)
        if q.compLink then EquipItemByName(q.compLink) end
        table.remove(itemQueue, 1)
        AEB.queueCurrent = AEB.queueCurrent + 1
        mainFrame:Hide()
        AEB:ShowNextInQueue()
    end)

    mainFrame.btnNo:SetScript("OnClick", function()
        if mainFrame.cb:GetChecked() then
            local id = q.link:match("item:(%d+)")
            if id then
                AEB.db.blacklist[id] = true
                print("|cffff8800Предмет добавлен в чёрный список|r")
            end
        end
        table.remove(itemQueue, 1)
        AEB.queueCurrent = AEB.queueCurrent + 1
        mainFrame:Hide()
        AEB:ShowNextInQueue()
    end)

    mainFrame:Show()
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
-- Отдельная функция для обновления стрелок на квестовых наградах
local isUpdatingQuestArrows = false
function AEB:UpdateQuestRewardsArrows()
    -- Защита от рекурсии
    if isUpdatingQuestArrows then return end
    isUpdatingQuestArrows = true

    -- Очищаем только квестовые стрелочки и монетки
    for _, arrow in ipairs(upgradeArrows) do
        if arrow.inUse and arrow.isQuestReward then
            arrow.inUse = false
        end
    end
    for _, coin in ipairs(coinIcons) do
        if coin.inUse and coin.isQuestReward then
            coin.inUse = false
        end
    end

    local numChoices = 0
    local isLog = QuestInfoFrame.questLog
    local isQuestDetail = QuestFrame and QuestFrame:IsVisible() -- Окно принятия задания от NPC
    local isQuestLogDetail = QuestLogDetailFrame and QuestLogDetailFrame:IsVisible() -- Окно из трекера

    -- Если открыт QuestLogDetailFrame, это тоже считается как журнал квестов
    if isQuestLogDetail then
        isLog = true
    end

    if isLog then
        numChoices = GetNumQuestLogChoices()
    else
        numChoices = GetNumQuestChoices()
    end

    if numChoices <= 0 then
        isUpdatingQuestArrows = false
        return
    end

    local bestUpgradeIdx = nil
    local bestUpgradePct = 0
    local bestValueIdx = nil
    local bestValue = -1

    for i = 1, numChoices do
        local link = isLog and GetQuestLogItemLink("choice", i) or GetQuestItemLink("choice", i)
        if link then
            local _, _, _, _, _, itemType, subType, _, loc, _, itemSellPrice = GetItemInfo(link)
            local quantity = 1
            if isLog then
                _, _, quantity = GetQuestLogChoiceInfo(i)
            else
                _, _, quantity = GetQuestItemInfo("choice", i)
            end

            local totalValue = (itemSellPrice or 0) * (quantity or 1)
            if totalValue > bestValue then
                bestValue = totalValue
                bestValueIdx = i
            end

            if IsEquippableItem(link) and loc and equipSlotMap[loc] and self:CanPlayerWear(itemType, subType) then
                local score = self:GetScoreForLink(link)
                local isUp, newS, oldS = self:GetUpgradeInfo(link, loc, score)

                if isUp then
                    local pct = oldS == 0 and 100 or math.floor(((newS - oldS) / newS) * 100)
                    if pct > 100 then pct = 100 end
                    if pct < 1 then pct = 1 end
                    if pct > bestUpgradePct then
                        bestUpgradePct = pct
                        bestUpgradeIdx = i
                    end
                end
            end
        end
    end

    if bestValueIdx then
        local btn = _G["QuestInfoItem" .. bestValueIdx]
        -- Показываем монетку только если это НЕ тот же предмет, что и с апгрейд-маркером
        if btn and btn:IsVisible() and bestUpgradeIdx ~= bestValueIdx then
            local coin = self:GetCoinFrame()
            coin:SetParent(btn)
            coin:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -2, -2)
            coin.isQuestReward = true
            coin:Show()
        end
    end

    if bestUpgradeIdx then
        local btn = _G["QuestInfoItem" .. bestUpgradeIdx]
        if btn and btn:IsVisible() then
            local arrow = self:GetArrowFrame()

            -- Разное позиционирование в зависимости от типа окна
            if isLog or isQuestLogDetail then
                -- В журнале квестов и окне деталей из трекера - привязываем к иконке
                local icon = _G["QuestInfoItem" .. bestUpgradeIdx .. "IconTexture"] or btn.Icon

                if icon then
                    arrow:SetParent(btn)
                    arrow:SetFrameStrata("HIGH")
                    arrow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 5, -3)
                    arrow:SetFrameLevel(btn:GetFrameLevel() + 5)
                else
                    arrow:SetParent(btn)
                    arrow:SetFrameStrata("HIGH")
                    arrow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 5, -3)
                    arrow:SetFrameLevel(btn:GetFrameLevel() + 5)
                end
            elseif isQuestDetail then
                -- В окне принятия задания - привязываем к иконке, но внутри скролла
                local icon = _G["QuestInfoItem" .. bestUpgradeIdx .. "IconTexture"] or btn.Icon

                if icon then
                    arrow:SetParent(btn)
                    arrow:SetFrameStrata("MEDIUM")
                    arrow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 5, -3)
                    arrow:SetFrameLevel(btn:GetFrameLevel() + 5)
                else
                    arrow:SetParent(btn)
                    arrow:SetFrameStrata("MEDIUM")
                    arrow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 5, -3)
                    arrow:SetFrameLevel(btn:GetFrameLevel() + 5)
                end
            else
                -- В окне сдачи квеста (QUEST_COMPLETE) - привязываем к UIParent
                arrow:SetParent(UIParent)
                arrow:SetFrameStrata("TOOLTIP")
                arrow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMLEFT", 42, -2)
                arrow:SetFrameLevel(999)
            end

            arrow.isQuestReward = true
            arrow:Show()
        end
    end

    -- Снимаем флаг защиты от рекурсии
    isUpdatingQuestArrows = false
end

-- === АВТОМАТИЧЕСКИЙ ВЫБОР НАГРАДЫ У NPC ===
function AEB:ClearQuestRewardMarkers()
    -- Очистка квестовых стрелок и монеток
    for _, arrow in ipairs(upgradeArrows) do
        if arrow.isQuestReward then
            arrow:Hide()
            arrow:ClearAllPoints()
            arrow.inUse = false
            arrow.isQuestReward = nil
        end
    end
    for _, coin in ipairs(coinIcons) do
        if coin.isQuestReward then
            coin:Hide()
            coin:ClearAllPoints()
            coin.inUse = false
            coin.isQuestReward = nil
        end
    end
end

function AEB:QUEST_DETAIL()
    -- Событие при открытии окна "Детали задания" (клик на квест в Quest Watch)
    questRewardDelayPending = true
    questRewardDelayTimer = 0
end

function AEB:QUEST_FINISHED()
    -- Событие при закрытии окна квеста
    self:ClearQuestRewardMarkers()
end

function AEB:QUEST_COMPLETE()
    local numChoices = GetNumQuestChoices()
    if numChoices <= 0 then return end

    local bestUpgradeIdx = nil
    local bestUpgradePct = 0
    local bestValueIdx = nil
    local bestValue = -1

    for i = 1, numChoices do
        local link = GetQuestItemLink("choice", i)
        if link then
            local _, _, _, _, _, itemType, subType, _, loc, _, itemSellPrice = GetItemInfo(link)
            local _, _, quantity = GetQuestItemInfo("choice", i)

            local totalValue = (itemSellPrice or 0) * (quantity or 1)
            if totalValue > bestValue then
                bestValue = totalValue
                bestValueIdx = i
            end

            if IsEquippableItem(link) and loc and equipSlotMap[loc] then
                if self:CanPlayerWear(itemType, subType) then
                    local score = self:GetScoreForLink(link)
                    local isUp, newS, oldS = self:GetUpgradeInfo(link, loc, score)

                    if isUp then
                        local pct = oldS == 0 and 100 or math.floor(((newS - oldS) / newS) * 100)
                        if pct > 100 then pct = 100 end
                        if pct < 1 then pct = 1 end
                        if pct > bestUpgradePct then
                            bestUpgradePct = pct
                            bestUpgradeIdx = i
                        end
                    end
                end
            end
        end
    end

    -- Показываем стрелки и монетки ПЕРЕД автоматическим кликом
    -- Монетку показываем только если это НЕ тот же предмет, что и с апгрейд-маркером
    if bestValueIdx and bestUpgradeIdx ~= bestValueIdx then
        local btn = _G["QuestInfoItem" .. bestValueIdx]
        if btn and btn:IsVisible() then
            local coin = self:GetCoinFrame()
            coin:SetParent(btn)
            coin:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -2, -2)
            coin.isQuestReward = true
            coin:Show()
        end
    end

    if bestUpgradeIdx then
        local btn = _G["QuestInfoItem" .. bestUpgradeIdx]
        if btn and btn:IsVisible() then
            local arrow = self:GetArrowFrame()
            -- QUEST_COMPLETE всегда срабатывает в окне NPC (не в журнале)
            arrow:SetParent(UIParent)
            arrow:SetFrameStrata("TOOLTIP")
            arrow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMLEFT", 42, -2)
            arrow:SetFrameLevel(999)
            arrow.isQuestReward = true
            arrow:Show()
        end
    end

    -- Автоматический клик на лучшую награду
    local clickIdx = bestUpgradeIdx or bestValueIdx
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
    local highestPoints = 0
    local activeTab = 1 -- Значение по умолчанию (первая ветка). Сработает, если талантов нет вообще или при ничьей.

    for i = 1, GetNumTalentTabs() do
        local _, _, pointsSpent = GetTalentTabInfo(i, false, false, activeGroup)
        -- Строгое превосходство: если очков поровну (например 1-1-0), останется первая найденная ветка
        if pointsSpent and pointsSpent > highestPoints then
            highestPoints = pointsSpent
            activeTab = i
        end
    end

    if classStatWeights[playerClass] and classStatWeights[playerClass][activeTab] then
        statWeights = classStatWeights[playerClass][activeTab]
    else
        statWeights = {}
    end
end

-- === ОКНО НАСТРОЕК ===
function AEB:ShowSettingsFrame()
    if settingsFrame then
        settingsFrame:Show()
        return
    end

    -- Создание главного окна
    settingsFrame = CreateFrame("Frame", "AEBSettingsFrame", UIParent)
    settingsFrame:SetSize(500, 450)
    settingsFrame:SetPoint("CENTER")
    settingsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 256, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    settingsFrame:SetBackdropColor(0.5, 0.5, 0.5, 1)
    settingsFrame:EnableMouse(true)
    settingsFrame:SetMovable(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
    settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
    settingsFrame:SetFrameStrata("DIALOG")

    -- Закрытие по Esc
    table.insert(UISpecialFrames, "AEBSettingsFrame")

    -- Заголовок
    local title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Настройки AutoEquipBetter")

    -- Кнопка закрытия
    local closeBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)

    -- Вкладки
    local tabs = {}
    local tabButtons = {}

    -- Рамка для области вкладок
    local tabsContainer = CreateFrame("Frame", nil, settingsFrame)
    tabsContainer:SetPoint("TOPLEFT", 15, -50)
    tabsContainer:SetPoint("BOTTOMLEFT", 15, 20)
    tabsContainer:SetWidth(100)
    tabsContainer:SetBackdrop({
        bgFile = nil,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    tabsContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    -- Рамка для области контента
    local contentContainer = CreateFrame("Frame", nil, settingsFrame)
    contentContainer:SetPoint("TOPLEFT", 115, -50)
    contentContainer:SetPoint("BOTTOMRIGHT", -15, 20)
    contentContainer:SetBackdrop({
        bgFile = nil,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    contentContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local function CreateTab(name, index)
        local tab = CreateFrame("Frame", nil, contentContainer)
        tab:SetPoint("TOPLEFT", 10, -10)
        tab:SetPoint("BOTTOMRIGHT", -10, 10)
        tab:Hide()
        tabs[index] = tab

        local btn = CreateFrame("Button", nil, tabsContainer)
        btn:SetSize(94, 22)
        btn:SetPoint("TOPLEFT", 3, -3 - (index - 1) * 22)
        btn:SetNormalFontObject("GameFontNormalSmall")
        btn:SetHighlightFontObject("GameFontHighlightSmall")

        -- Фон кнопки без рамки
        btn:SetBackdrop({
            bgFile = "Interface\\QuestFrame\\UI-QuestLogTitleHighlight",
            edgeFile = nil,
            tile = false, tileSize = 8, edgeSize = 0,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })

        -- Первая вкладка активна по умолчанию
        if index == 1 then
            btn:SetBackdropColor(1, 1, 1, 0.5)
        else
            btn:SetBackdropColor(0.2, 0.2, 0.2, 0)
        end

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btnText:SetPoint("LEFT", 8, 0)
        btnText:SetText(name)
        btnText:SetJustifyH("LEFT")

        btn:SetScript("OnClick", function()
            for i, t in ipairs(tabs) do
                t:Hide()
                tabButtons[i]:SetBackdropColor(0.2, 0.2, 0.2, 0)
            end
            tab:Show()
            btn:SetBackdropColor(1, 1, 1, 0.5)
        end)

        btn:SetScript("OnEnter", function()
            if tabs[index]:IsShown() then return end
            btn:SetBackdropColor(0.4, 0.4, 0.4, 0.3)
        end)

        btn:SetScript("OnLeave", function()
            if tabs[index]:IsShown() then return end
            btn:SetBackdropColor(0.2, 0.2, 0.2, 0)
        end)

        btn:SetScript("OnMouseDown", function()
            btnText:SetPoint("LEFT", 9, -1)
        end)

        btn:SetScript("OnMouseUp", function()
            btnText:SetPoint("LEFT", 8, 0)
        end)

        tabButtons[index] = btn
        return tab
    end

    -- === ВКЛАДКА "ОБЩИЕ" ===
    local generalTab = CreateTab("Общие", 1)

    -- Создаем ScrollFrame для прокручиваемого контента
    local scrollFrame = CreateFrame("ScrollFrame", nil, generalTab, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

    -- Создаем ScrollChild (контент, который будет прокручиваться)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth() - 10, 600) -- Высота больше для прокрутки
    scrollFrame:SetScrollChild(scrollChild)

    local yOffset = -5

    -- Чекбокс "Включить автоматическое сравнение"
    local cbAutoSuggest = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbAutoSuggest:SetSize(20, 20)
    cbAutoSuggest:SetPoint("TOPLEFT", 2, yOffset)
    cbAutoSuggest:SetChecked(self.db.autoSuggest)
    cbAutoSuggest.text = cbAutoSuggest:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cbAutoSuggest.text:SetPoint("LEFT", cbAutoSuggest, "RIGHT", 5, 0)
    cbAutoSuggest.text:SetText("Включить автоматическое сравнение")
    cbAutoSuggest:SetScript("OnClick", function(self)
        AEB.db.autoSuggest = self:GetChecked()
    end)

    yOffset = yOffset - 30

    -- Чекбокс "Надевать автоматически"
    local cbAutoEquip = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbAutoEquip:SetSize(20, 20)
    cbAutoEquip:SetPoint("TOPLEFT", 2, yOffset)
    cbAutoEquip:SetChecked(self.db.autoEquip)
    cbAutoEquip.text = cbAutoEquip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cbAutoEquip.text:SetPoint("LEFT", cbAutoEquip, "RIGHT", 5, 0)
    cbAutoEquip.text:SetText("Надевать автоматически (без окна)")
    cbAutoEquip:SetScript("OnClick", function(self)
        AEB.db.autoEquip = self:GetChecked()
    end)

    yOffset = yOffset - 30

    -- Задержка автоэкипировки
    local delayLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    delayLabel:SetPoint("TOPLEFT", 2, yOffset)
    delayLabel:SetText("Задержка автоэкипировки (сек):")

    local delayInput = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
    delayInput:SetSize(60, 30)
    delayInput:SetPoint("LEFT", delayLabel, "RIGHT", 10, 0)
    delayInput:SetAutoFocus(false)
    delayInput:SetText(tostring(self.db.delay or 1))
    delayInput:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val and val >= 0 and val <= 10 then
            AEB.db.delay = val
        else
            self:SetText(tostring(AEB.db.delay or 1))
        end
        self:ClearFocus()
    end)

    yOffset = yOffset - 30

    -- Расположение окна
    local posLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    posLabel:SetPoint("TOPLEFT", 2, yOffset)
    posLabel:SetText("Расположение окна:")

    local btnChangePos = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    btnChangePos:SetSize(100, 25)
    btnChangePos:SetPoint("LEFT", posLabel, "RIGHT", 10, 0)
    btnChangePos:SetText("Изменить")
    btnChangePos:SetScript("OnClick", function()
        if mainFrame then
            mainFrame:Show()
            print("|cffffcc00Переместите окно сравнения в нужное место. Позиция сохранится автоматически.|r")
        else
            print("|cffff0000Окно сравнения ещё не создано. Дождитесь предложения предмета.|r")
        end
    end)

    local btnResetPos = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    btnResetPos:SetSize(100, 25)
    btnResetPos:SetPoint("LEFT", btnChangePos, "RIGHT", 10, 0)
    btnResetPos:SetText("Сбросить")
    btnResetPos:SetScript("OnClick", function()
        AEB.db.framePos = { point = "CENTER", x = 0, y = 0 }
        if mainFrame then
            mainFrame:ClearAllPoints()
            mainFrame:SetPoint("CENTER")
        end
        print("|cff00ff00Позиция окна сброшена|r")
    end)

    yOffset = yOffset - 40

    -- Чекбокс "Автоэкипировка боеприпасов"
    local cbAutoEquipAmmo = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbAutoEquipAmmo:SetSize(20, 20)
    cbAutoEquipAmmo:SetPoint("TOPLEFT", 2, yOffset)
    cbAutoEquipAmmo:SetChecked(self.db.autoEquipAmmo)
    cbAutoEquipAmmo.text = cbAutoEquipAmmo:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cbAutoEquipAmmo.text:SetPoint("LEFT", cbAutoEquipAmmo, "RIGHT", 5, 0)
    cbAutoEquipAmmo.text:SetText("Автоматически экипировать боеприпасы")
    cbAutoEquipAmmo:SetScript("OnClick", function(self)
        AEB.db.autoEquipAmmo = self:GetChecked()
    end)

    yOffset = yOffset - 30

    -- Чекбокс "Приоритет качества боеприпасов" (дочерний)
    local cbAmmoBestQuality = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbAmmoBestQuality:SetSize(20, 20)
    cbAmmoBestQuality:SetPoint("TOPLEFT", 22, yOffset) -- Отступ 20px для визуальной иерархии
    cbAmmoBestQuality:SetChecked(self.db.ammoBestQuality)
    cbAmmoBestQuality.text = cbAmmoBestQuality:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cbAmmoBestQuality.text:SetPoint("LEFT", cbAmmoBestQuality, "RIGHT", 5, 0)
    cbAmmoBestQuality.text:SetText("Приоритет лучшего качества")
    cbAmmoBestQuality:SetScript("OnClick", function(self)
        AEB.db.ammoBestQuality = self:GetChecked()
    end)

    -- === ВКЛАДКА "ИСКЛЮЧЕНИЯ" ===
    local exceptionsTab = CreateTab("Исключения", 2)

    local listLabel = exceptionsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listLabel:SetPoint("TOPLEFT", 2, -5)
    listLabel:SetText("Список игнорируемых предметов:")

    -- Скролл для списка (упрощённый без шаблона)
    local scrollFrame = CreateFrame("ScrollFrame", "AEBBlacklistScroll", exceptionsTab)
    scrollFrame:SetSize(340, 200)
    scrollFrame:SetPoint("TOPLEFT", 2, -30)

    -- Фон для скролла
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    scrollFrame:SetBackdropColor(0, 0, 0, 0.5)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(400, 200)
    scrollFrame:SetScrollChild(scrollChild)

    -- Слайдер для прокрутки
    local scrollBar = CreateFrame("Slider", "AEBBlacklistScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -2, -18)
    scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -2, 18)
    scrollBar:SetMinMaxValues(0, 100)
    scrollBar:SetValueStep(20)
    scrollBar:SetValue(0)
    scrollBar:SetWidth(16)
    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    local listItems = {}
    local selectedItem = nil

    local function RefreshBlacklist()
        for _, item in ipairs(listItems) do item:Hide() end
        wipe(listItems)
        selectedItem = nil

        local sortedList = {}
        for itemId in pairs(AEB.db.blacklist) do
            local itemName, _, itemQuality = GetItemInfo(itemId)
            if itemName then
                table.insert(sortedList, { id = itemId, name = itemName, quality = itemQuality or 1 })
            end
        end

        table.sort(sortedList, function(a, b) return a.name < b.name end)

        for i, data in ipairs(sortedList) do
            local btn = CreateFrame("Button", nil, scrollChild)
            btn:SetSize(400, 20)
            btn:SetPoint("TOPLEFT", 0, -(i - 1) * 20)

            local r, g, b = GetItemQualityColor(data.quality)
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", 5, 0)
            btn.text:SetText(data.name)
            btn.text:SetTextColor(r, g, b)

            btn:SetScript("OnClick", function()
                selectedItem = data.id
                for _, item in ipairs(listItems) do
                    item:SetBackdrop(nil)
                end
                btn:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = nil,
                    tile = false
                })
                btn:SetBackdropColor(0.3, 0.3, 0.3, 0.5)
            end)

            table.insert(listItems, btn)
        end

        local maxScroll = math.max(0, #sortedList * 20 - 200)
        scrollChild:SetHeight(math.max(200, #sortedList * 20))
        scrollBar:SetMinMaxValues(0, maxScroll)
        scrollBar:SetValue(0)
    end

    RefreshBlacklist()

    -- Кнопки управления
    local btnRemove = CreateFrame("Button", nil, exceptionsTab, "UIPanelButtonTemplate")
    btnRemove:SetSize(100, 25)
    btnRemove:SetPoint("TOPLEFT", 2, -245)
    btnRemove:SetText("Удалить")
    btnRemove:SetScript("OnClick", function()
        if selectedItem then
            AEB.db.blacklist[selectedItem] = nil
            print("|cff00ff00Предмет удалён из чёрного списка|r")
            RefreshBlacklist()
        end
    end)

    local addLabel = exceptionsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addLabel:SetPoint("TOPLEFT", 2, -285)
    addLabel:SetText("Введите название предмета для добавления:")

    local addInput = CreateFrame("EditBox", nil, exceptionsTab)
    addInput:SetSize(230, 32)
    addInput:SetPoint("TOPLEFT", 2, -310)
    addInput:SetAutoFocus(false)
    addInput:SetFontObject("ChatFontNormal")
    addInput:SetMaxLetters(50)
    addInput:SetTextInsets(8, 8, 0, 0)

    -- Фон для поля ввода
    addInput:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    addInput:SetBackdropColor(0, 0, 0, 0.5)
    addInput:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    addInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    addInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    -- Обработчик Alt+ЛКМ для вставки названия предмета
    local originalChatEdit_InsertLink = ChatEdit_InsertLink
    ChatEdit_InsertLink = function(link)
        if addInput:HasFocus() and link then
            local itemName = GetItemInfo(link)
            if itemName then
                addInput:SetText(itemName)
                return true
            end
        end
        return originalChatEdit_InsertLink(link)
    end

    local btnAdd = CreateFrame("Button", nil, exceptionsTab, "UIPanelButtonTemplate")
    btnAdd:SetSize(100, 32)
    btnAdd:SetPoint("TOPRIGHT", scrollFrame, "BOTTOMRIGHT", 0, -80)
    btnAdd:SetText("Добавить")
    btnAdd:SetScript("OnClick", function()
        local itemName = addInput:GetText():trim()
        if itemName ~= "" then
            -- Ищем предмет по названию
            local found = false
            for bag = 0, 4 do
                for slot = 1, GetContainerNumSlots(bag) do
                    local link = GetContainerItemLink(bag, slot)
                    if link then
                        local name = GetItemInfo(link)
                        if name and name:lower() == itemName:lower() then
                            local itemId = link:match("item:(%d+)")
                            if itemId then
                                AEB.db.blacklist[itemId] = true
                                print("|cff00ff00Предмет добавлен в чёрный список: |r" .. name)
                                addInput:SetText("")
                                RefreshBlacklist()
                                found = true
                                return
                            end
                        end
                    end
                end
            end

            -- Проверяем экипированные предметы
            if not found then
                for slot = 1, 19 do
                    local link = GetInventoryItemLink("player", slot)
                    if link then
                        local name = GetItemInfo(link)
                        if name and name:lower() == itemName:lower() then
                            local itemId = link:match("item:(%d+)")
                            if itemId then
                                AEB.db.blacklist[itemId] = true
                                print("|cff00ff00Предмет добавлен в чёрный список: |r" .. name)
                                addInput:SetText("")
                                RefreshBlacklist()
                                found = true
                                return
                            end
                        end
                    end
                end
            end

            if not found then
                print("|cffff0000Предмет не найден в сумках или экипировке. Проверьте название.|r")
            end
        end
    end)

    -- === ВКЛАДКА "ИНФО" ===
    local infoTab = CreateTab("Инфо", 3)

    local authorLabel = infoTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    authorLabel:SetPoint("TOP", 0, -40)
    authorLabel:SetText("Автор аддона - |cff00ff00KiM38RuS|r")

    -- Иконка GitHub (используем текстуру)
    local githubIcon = infoTab:CreateTexture(nil, "ARTWORK")
    githubIcon:SetSize(32, 32)
    githubIcon:SetPoint("TOP", 0, -90)
    githubIcon:SetTexture("Interface\\FriendsFrame\\Battlenet-Portrait")

    local githubLink = infoTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    githubLink:SetPoint("TOP", 0, -130)
    githubLink:SetText("|cff00ccffhttps://github.com/KiM38RuS/AutoEquipBetter-3.3.5|r")

    local githubBtn = CreateFrame("Button", nil, infoTab)
    githubBtn:SetSize(400, 20)
    githubBtn:SetPoint("CENTER", githubLink, "CENTER")
    githubBtn:SetScript("OnClick", function()
        print("|cffffcc00Ссылка на GitHub:|r https://github.com/KiM38RuS/AutoEquipBetter-3.3.5")
    end)

    -- Показываем первую вкладку
    tabs[1]:Show()
    tabButtons[1]:SetBackdropColor(1, 1, 1, 0.5)

    settingsFrame:Show()
end

-- === ИНФОРМАТИВНЫЕ ТУЛТИПЫ ===
local function ProcessTooltip(tooltip)
    local name, link = tooltip:GetItem()
    if not link then return end

    local id = link:match("item:(%d+)")
    if not id or not IsEquippableItem(id) then return end

    local _, _, _, _, _, itemType, subType, _, loc = GetItemInfo(id)

    if not loc or not equipSlotMap[loc] then return end

    local score = AEB:GetScoreForLink(link)
    local isUp, newS, oldS, oldL, oldNameOvr, compLink = AEB:GetUpgradeInfo(link, loc, score)
    
    if isUp then
        local pct = 100
        if newS > 0 and oldS > 0 then
            pct = math.floor(((newS - oldS) / newS) * 100)
            if pct > 100 then pct = 100 end
            if pct < 1 then pct = 1 end
        end

        local targetName = oldNameOvr or (oldL and (select(1, GetItemInfo(oldL)))) or "Ничего не надето"
        tooltip:AddLine(string.format("На |cff00ff00%d%%|r лучше, чем [%s]", pct, targetName), 1, 1, 0)

        if compLink then
            local compName = (select(1, GetItemInfo(compLink)))
            tooltip:AddLine(string.format("  |cff88ff88В комбинации с [%s]|r", compName), 1, 1, 1)
        end

        tooltip:Show()
    end
end

-- Хукаем стандартные игровые тултипы при загрузке
GameTooltip:HookScript("OnTooltipSetItem", ProcessTooltip)
ItemRefTooltip:HookScript("OnTooltipSetItem", ProcessTooltip)