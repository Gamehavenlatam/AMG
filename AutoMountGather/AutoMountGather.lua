-- AutoMountGather
-- Remonta automaticamente despues de minar o recolectar hierbas (WotLK 3.3.5a)

AutoMountGatherDB = AutoMountGatherDB or { lastMountName = nil, enabled = true, debugCast = false, delay = 1.5 }
AutoMountGatherDB.delay = AutoMountGatherDB.delay or 1.5

local frame = CreateFrame("Frame")
local wasMountedBeforeGather = false
local isGathering = false
local lastMountedTime = 0
local remountAt = nil

-- En 3.3.5 el nombre del hechizo llega localizado (ej: "Minería", "Herboristería" en español,
-- "Mining", "Herb Gathering" en inglés). Agregá acá los nombres exactos que uses.
local gatherSpellNames = {
    ["Mining"] = true,
    ["Herb Gathering"] = true,
    ["Minería"] = true,
    ["Herboristería"] = true,
    ["Woodcutting"] = true,
    ["Skinning"] = true,
    ["Fishing"] = true,
}

-- Detecta y guarda el nombre de la montura actual mientras estás montado.
-- Filtra por el ícono: las monturas siempre usan una textura "Ability_Mount"
local function TrackCurrentMount()
    if not IsMounted() then return end

    for i = 1, 40 do
        local name, _, icon = UnitBuff("player", i)
        if not name then break end
        if icon and icon:find("Ability_Mount") then
            AutoMountGatherDB.lastMountName = name
            return
        end
    end
end

local function TryRemount()
    if not UnitAffectingCombat("player") and not IsMounted() then
        if AutoMountGatherDB.lastMountName then
            CastSpellByName(AutoMountGatherDB.lastMountName)
            if AutoMountGatherDB.debugCast then
                DEFAULT_CHAT_FRAME:AddMessage("|cff888888AMG:|r intentando remontar con "..AutoMountGatherDB.lastMountName)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff9900AutoMountGather:|r no tengo guardada tu montura todavía. Montate una vez manualmente para que la detecte.")
        end
    elseif AutoMountGatherDB.debugCast then
        DEFAULT_CHAT_FRAME:AddMessage("|cff888888AMG:|r no remonto (en combate o ya montado)")
    end
end

frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("LOOT_CLOSED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnUpdate", function(self, elapsed)
    self.timer = (self.timer or 0) + elapsed
    if self.timer < 0.5 then return end
    self.timer = 0

    if IsMounted() then
        lastMountedTime = GetTime()
        if not isGathering then
            TrackCurrentMount()
        end
    end

    if remountAt and GetTime() >= remountAt then
        remountAt = nil
        if wasMountedBeforeGather then
            TryRemount()
        elseif AutoMountGatherDB.debugCast then
            DEFAULT_CHAT_FRAME:AddMessage("|cff888888AMG:|r no remonto, no estabas montado antes de recolectar.")
        end
        isGathering = false
    end
end)

frame:SetScript("OnEvent", function(self, event, ...)
    if not AutoMountGatherDB.enabled then return end

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, spellName, rank, lineID = ...
        if unit == "player" then
            if AutoMountGatherDB.debugCast then
                DEFAULT_CHAT_FRAME:AddMessage("|cff888888AMG cast:|r "..tostring(spellName))
            end
            if gatherSpellNames[spellName] then
                wasMountedBeforeGather = (GetTime() - lastMountedTime) < 8
                isGathering = true
                remountAt = GetTime() + AutoMountGatherDB.delay
                if AutoMountGatherDB.debugCast then
                    DEFAULT_CHAT_FRAME:AddMessage("|cff888888AMG:|r wasMountedBeforeGather="..tostring(wasMountedBeforeGather).." (hace "..string.format("%.1f", GetTime()-lastMountedTime).."s que estabas montado)")
                end
            end
        end

    elseif event == "LOOT_CLOSED" then
        if isGathering and wasMountedBeforeGather then
            remountAt = GetTime() + 0.3
        end
    end
end)

-- Botón en el minimapa
local minimapBtn = CreateFrame("Button", "AutoMountGatherMinimapButton", Minimap)
minimapBtn:SetSize(24, 24)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)
minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetMovable(true)

local btnBg = minimapBtn:CreateTexture(nil, "BACKGROUND")
btnBg:SetSize(20, 20)
btnBg:SetPoint("CENTER")
btnBg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

local btnBorder = minimapBtn:CreateTexture(nil, "OVERLAY")
btnBorder:SetSize(52, 52)
btnBorder:SetPoint("TOPLEFT")
btnBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local btnText = minimapBtn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
btnText:SetPoint("CENTER", 0, 1)
btnText:SetText("AMG")
btnText:SetTextColor(1, 1, 1)

local function UpdateMinimapButtonColor()
    if AutoMountGatherDB.enabled then
        btnText:SetTextColor(0.4, 1, 0.4)
    else
        btnText:SetTextColor(1, 0.3, 0.3)
    end
end

local function GetMinimapButtonPosition()
    return AutoMountGatherDB.minimapAngle or 45
end

local function UpdateMinimapButtonPlacement()
    local angle = math.rad(GetMinimapButtonPosition())
    local radius = 80
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", radius * math.cos(angle), radius * math.sin(angle))
end

minimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function(self)
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        local angle = math.deg(math.atan2(py - my, px - mx))
        AutoMountGatherDB.minimapAngle = angle
        UpdateMinimapButtonPlacement()
    end)
end)

minimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

minimapBtn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        ToggleDropDownMenu(1, nil, AutoMountGatherMenu, self, 0, 0)
    elseif button == "RightButton" then
        AutoMountGatherDB.debugCast = not AutoMountGatherDB.debugCast
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffAutoMountGather:|r debug de casteos: "..(AutoMountGatherDB.debugCast and "ON" or "OFF"))
    end
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("AutoMountGather")
    GameTooltip:AddLine("Clic izq: abrir menú", 1, 1, 1)
    GameTooltip:AddLine("Clic der: modo debug rápido", 1, 1, 1)
    GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

-- Menú desplegable
local delayOptions = {1, 1.5, 2, 3, 5, 8}

AutoMountGatherMenu = CreateFrame("Frame", "AutoMountGatherMenu", UIParent, "UIDropDownMenuTemplate")

local function AutoMountGatherMenu_Init(self, level)
    level = level or 1

    if level == 1 then
        local info = UIDropDownMenu_CreateInfo()
        info.isTitle = true
        info.text = "AutoMountGather"
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = "Activado"
        info.func = function()
            AutoMountGatherDB.enabled = not AutoMountGatherDB.enabled
            UpdateMinimapButtonColor()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffAutoMountGather:|r "..(AutoMountGatherDB.enabled and "|cff00ff00activado" or "|cffff0000desactivado"))
            CloseDropDownMenus()
        end
        info.checked = AutoMountGatherDB.enabled
        info.isNotRadio = true
        info.keepShownOnClick = true
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = "Modo debug"
        info.func = function()
            AutoMountGatherDB.debugCast = not AutoMountGatherDB.debugCast
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffAutoMountGather:|r debug de casteos: "..(AutoMountGatherDB.debugCast and "ON" or "OFF"))
            CloseDropDownMenus()
        end
        info.checked = AutoMountGatherDB.debugCast
        info.isNotRadio = true
        info.keepShownOnClick = true
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = "Tiempo antes de remontar"
        info.hasArrow = true
        info.notCheckable = true
        info.value = "DELAY_SUBMENU"
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = "Cerrar"
        info.notCheckable = true
        info.func = function() CloseDropDownMenus() end
        UIDropDownMenu_AddButton(info, level)

    elseif level == 2 then
        for _, seconds in ipairs(delayOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = seconds.." segundos"
            info.func = function()
                AutoMountGatherDB.delay = seconds
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffAutoMountGather:|r tiempo de remonte: "..seconds.."s")
                CloseDropDownMenus()
            end
            info.checked = (AutoMountGatherDB.delay == seconds)
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

UIDropDownMenu_Initialize(AutoMountGatherMenu, AutoMountGatherMenu_Init, "MENU")

UpdateMinimapButtonPlacement()
UpdateMinimapButtonColor()

-- Slash commands
SLASH_AUTOMOUNTGATHER1 = "/amg"
SlashCmdList["AUTOMOUNTGATHER"] = function(msg)
    msg = msg:lower():trim()
    if msg == "on" then
        AutoMountGatherDB.enabled = true
        UpdateMinimapButtonColor()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00AutoMountGather:|r activado.")
    elseif msg == "off" then
        AutoMountGatherDB.enabled = false
        UpdateMinimapButtonColor()
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000AutoMountGather:|r desactivado.")
    elseif msg == "montura" then
        if AutoMountGatherDB.lastMountName then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffAutoMountGather:|r montura guardada: "..AutoMountGatherDB.lastMountName)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffAutoMountGather:|r todavía no detecté ninguna montura. Montate manualmente una vez.")
        end
    elseif msg == "debugcast" then
        AutoMountGatherDB.debugCast = not AutoMountGatherDB.debugCast
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffAutoMountGather:|r debug de casteos: "..(AutoMountGatherDB.debugCast and "ON" or "OFF"))
    elseif msg:match("^tiempo") then
        local seconds = tonumber(msg:match("tiempo%s+([%d%.]+)"))
        if seconds then
            AutoMountGatherDB.delay = seconds
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffAutoMountGather:|r tiempo de remonte: "..seconds.."s")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffAutoMountGather:|r uso: /amg tiempo 2  (tiempo actual: "..AutoMountGatherDB.delay.."s)")
        end
    elseif msg == "debug" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffAutoMountGather:|r buffs actuales:")
        for i = 1, 40 do
            local name, _, icon = UnitBuff("player", i)
            if not name then break end
            DEFAULT_CHAT_FRAME:AddMessage(i.." - "..name.." - "..tostring(icon))
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffAutoMountGather:|r comandos: /amg on, /amg off, /amg montura, /amg debug, /amg debugcast, /amg tiempo N")
    end
end
