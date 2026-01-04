-- ==========================================================
-- GESTIÓN DE VARIABLES Y PERFILES (Persistencia)
-- ==========================================================
local function InitializeSettings()
    if not F1_Config then F1_Config = {} end
    if F1_Config.currentGear == nil then F1_Config.currentGear = "p2" end
    if F1_Config.showCrosshair == nil then F1_Config.showCrosshair = true end
    if F1_Config.alpha == nil then F1_Config.alpha = 1.0 end
    if F1_Config.latency == nil then F1_Config.latency = 0.5 end 
    
    if not F1_Config.p1 then F1_Config.p1 = {rake=10, claw=15} end 
    if not F1_Config.p2 then F1_Config.p2 = {rake=35, claw=40} end 
    if not F1_Config.turbo then F1_Config.turbo = {rake=32, claw=37} end 
    
    if F1_Config.offsetX == nil then F1_Config.offsetX = 0 end
    if F1_Config.offsetY == nil then F1_Config.offsetY = -7 end
    if F1_Config.grosor == nil then F1_Config.grosor = 2 end
end

local lastEnergyError = false
local isImmuneToBleed = false
local rakePending = false
local rakeTimer = 0
local isTurboActive = false
local lastReshiftTime = 0 

-- ==========================================================
-- SISTEMA DE ANUNCIOS
-- ==========================================================
local F1_MsgFrame = CreateFrame("MessageFrame", "F1_AnnounceFrame", UIParent)
F1_MsgFrame:SetPoint("CENTER", 0, 150)
F1_MsgFrame:SetWidth(600) F1_MsgFrame:SetHeight(100)
F1_MsgFrame:SetInsertMode("TOP") F1_MsgFrame:SetFrameStrata("HIGH")
F1_MsgFrame:SetTimeVisible(2.5) F1_MsgFrame:SetFont("Fonts\\FRIZQT__.TTF", 26, "OUTLINE") 

local function F1_Announce(text, r, g, b)
    F1_MsgFrame:AddMessage(text, r, g, b)
end

-- ==========================================================
-- SECCIÓN: CRUZ DE OBJETIVO
-- ==========================================================
local NPL_Frame = CreateFrame("Frame", nil, UIParent)
NPL_Frame:SetFrameStrata("BACKGROUND")
local HBar = NPL_Frame:CreateTexture(nil, "BACKGROUND")
HBar:SetTexture(1, 1, 1, 1)
local VBar = NPL_Frame:CreateTexture(nil, "BACKGROUND")
VBar:SetTexture(1, 1, 1, 1)

local function GetTargetPlate()
    if not UnitExists("target") then return nil end
    local children = {WorldFrame:GetChildren()}
    for _, child in ipairs(children) do
        if child:IsShown() and child:GetAlpha() == 1 then
            if child:GetObjectType() == "Button" or (pfUI and child.hp) then return child end
        end
    end
    return nil
end

NPL_Frame:SetScript("OnUpdate", function()
    if not F1_Config or not F1_Config.showCrosshair then 
        HBar:Hide() VBar:Hide() return 
    end
    local plate = GetTargetPlate()
    if plate then
        local a = F1_Config.alpha or 1.0
        local g = F1_Config.grosor or 2
        HBar:SetHeight(g) HBar:SetWidth(5000)
        VBar:SetWidth(g) VBar:SetHeight(5000)
        
        if UnitIsFriend("player", "target") then HBar:SetVertexColor(1,1,1, a) VBar:SetVertexColor(1,1,1, a)
        elseif UnitIsEnemy("player", "target") then HBar:SetVertexColor(1,0,0, a) VBar:SetVertexColor(1,0,0, a)
        else HBar:SetVertexColor(1,1,0, a) VBar:SetVertexColor(1,1,0, a) end
        
        HBar:ClearAllPoints() HBar:SetPoint("CENTER", plate, "CENTER", F1_Config.offsetX, F1_Config.offsetY)
        VBar:ClearAllPoints() VBar:SetPoint("CENTER", plate, "CENTER", F1_Config.offsetX, F1_Config.offsetY)
        HBar:Show() VBar:Show()
    else HBar:Hide() VBar:Hide() end
end)

-- ==========================================================
-- LÓGICA DE EVENTOS (v11.6 Blindado)
-- ==========================================================
local FeralEvents = CreateFrame("Frame")
FeralEvents:RegisterEvent("ADDON_LOADED")
FeralEvents:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
FeralEvents:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
FeralEvents:RegisterEvent("PLAYER_TARGET_CHANGED")
FeralEvents:RegisterEvent("UI_ERROR_MESSAGE")
FeralEvents:RegisterEvent("PLAYER_AURAS_CHANGED")

FeralEvents:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "Feral_One" then
        InitializeSettings()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Feral_One v11.6 Blindado. (/fo help)|r")
    elseif event == "PLAYER_TARGET_CHANGED" then
        isImmuneToBleed = false; rakePending = false; lastEnergyError = false
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        if (string.find(arg1, "Rake") or string.find(arg1, "Arañazo")) then
            if string.find(arg1, "hits") or string.find(arg1, "crits") or string.find(arg1, "golpea") then
                rakePending = true; rakeTimer = GetTime()
            elseif string.find(arg1, "immune") or string.find(arg1, "inmune") then
                isImmuneToBleed = true; rakePending = false
                F1_Announce("TARGET INMUNE", 1, 0, 0)
            elseif string.find(arg1, "miss") or string.find(arg1, "dodge") or string.find(arg1, "parry") or string.find(arg1, "esquiva") or string.find(arg1, "para") then
                rakePending = false
            end
        end
    elseif event == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" then
        if string.find(arg1, "Rake") or string.find(arg1, "Arañazo") then
            isImmuneToBleed = false; rakePending = false
        end
    elseif event == "UI_ERROR_MESSAGE" then
        if (arg1 == "Not enough energy" or arg1 == "Falta energía") then lastEnergyError = true end
    elseif event == "PLAYER_AURAS_CHANGED" then
        local found = false; local i = 1
        while true do
            local b = GetPlayerBuffTexture(GetPlayerBuff(i, "HELPFUL"))
            if not b then break end
            if string.find(b, "Ability_Druid_Berserk") then found = true break end
            i = i + 1
        end
        if found and not isTurboActive then
            isTurboActive = true; F1_Announce(">>> MODO TURBO: ACTIVADO <<<", 1, 0, 0)
        elseif not found and isTurboActive then
            isTurboActive = false; F1_Announce("Turbo finalizado", 1, 1, 1)
        end
    end
end)

-- ==========================================================
-- SISTEMA DE COMANDOS /fo
-- ==========================================================
SLASH_FERALONE1 = "/fo"
SlashCmdList["FERALONE"] = function(msg)
    local args = {}
    for word in string.gfind(msg, "%S+") do table.insert(args, word) end
    
    if args[1] == "latency" and args[2] then
        local lat = tonumber(args[2])
        if lat < 100 then F1_Config.latency = 0.5
        elseif lat < 200 then F1_Config.latency = 1.0
        else F1_Config.latency = 1.5 end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1 Log:|r Latencia ajustada a |cffffffff"..lat.."ms|r (Espera: "..F1_Config.latency.."s)")

    elseif args[1] == "alpha" and args[2] then 
        F1_Config.alpha = tonumber(args[2])
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1 Log:|r Transparencia de cruz fijada en |cffffffff"..args[2].."|r")
    elseif args[1] == "grosor" and args[2] then 
        F1_Config.grosor = tonumber(args[2])
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1 Log:|r Grosor de cruz fijado en |cffffffff"..args[2].."|r")
    elseif args[1] == "cruz" then 
        F1_Config.showCrosshair = not F1_Config.showCrosshair
        local st = F1_Config.showCrosshair and "ACTIVADA" or "DESACTIVADA"
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1 Log:|r Cruz visual "..st)

    elseif args[1] == "p1" or args[1] == "p2" or args[1] == "n" then
        F1_Config.currentGear = args[1]
        local name = (args[1] == "p1") and "PRIMERA" or (args[1] == "p2" and "SEGUNDA" or "NEUTRAL")
        F1_Announce("MARCHA: "..name, 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1 Log:|r Cambio a marcha |cffffffff"..name.."|r")

    elseif args[1] == "edit" and args[2] and args[3] and args[4] then
        local p = args[2]
        if F1_Config[p] then 
            F1_Config[p].rake = tonumber(args[3]); F1_Config[p].claw = tonumber(args[4])
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00F1 Log:|r Perfil |cffffffff"..p.."|r actualizado: Rake |cffffffff"..args[3].."|r / Claw |cffffffff"..args[4].."|r")
        end

    elseif args[1] == "status" then
        local gear = F1_Config.currentGear
        local gearName = (gear == "p1") and "PRIMERA" or (gear == "p2" and "SEGUNDA" or "NEUTRAL")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00=== FERAL_ONE STATUS ===|r")
        DEFAULT_CHAT_FRAME:AddMessage(" - Marcha Actual: |cffffffff"..gearName.."|r")
        DEFAULT_CHAT_FRAME:AddMessage(" - [P1] Rake: |cffffffff"..F1_Config.p1.rake.."|r / Claw: |cffffffff"..F1_Config.p1.claw.."|r")
        DEFAULT_CHAT_FRAME:AddMessage(" - [P2] Rake: |cffffffff"..F1_Config.p2.rake.."|r / Claw: |cffffffff"..F1_Config.p2.claw.."|r")
        DEFAULT_CHAT_FRAME:AddMessage(" - [TURBO] Rake: |cffffffff"..F1_Config.turbo.rake.."|r / Claw: |cffffffff"..F1_Config.turbo.claw.."|r")
        DEFAULT_CHAT_FRAME:AddMessage(" - Cruz: |cffffffffVisible: "..(F1_Config.showCrosshair and "SI" or "NO").." / Alpha: "..F1_Config.alpha.." / Grosor: "..F1_Config.grosor.."|r")
        DEFAULT_CHAT_FRAME:AddMessage(" - Turbo Activo: "..(isTurboActive and "|cff00ff00SI|r" or "|cffff0000NO|r"))

    elseif args[1] == "help" or args[1] == nil then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00=== GUÍA RÁPIDA FERAL_ONE ===|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff001. MODOS DE COMBATE:|r")
        DEFAULT_CHAT_FRAME:AddMessage(" - |cffffffffModo Boss:|r Hecho para Jefes y maximizar daño.")
        DEFAULT_CHAT_FRAME:AddMessage(" - |cffffffffModo Trash:|r Hecho para limpieza rápida de pulls.")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000IMPORTANTE: ES NECESARIO CREAR ESTOS 2 MACROS:|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff/run DoFeralRotation('boss')|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff/run DoFeralRotation('trash')|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff002. DETECCIÓN DE INMUNIDAD:|r")
        DEFAULT_CHAT_FRAME:AddMessage(" - |cffffffff/fo latency [tus ms]:|r Ajusta la espera según tu conexión.")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff003. CONFIGURACIÓN Y MARCHAS:|r")
        DEFAULT_CHAT_FRAME:AddMessage(" - |cffffffff/fo p1 / p2 / n:|r Selecciona Primera, Segunda o Neutral.")
        DEFAULT_CHAT_FRAME:AddMessage(" - |cffffffff/fo edit [p1/p2/turbo] [rake] [claw]:|r Ajusta energía de reshift.")
        DEFAULT_CHAT_FRAME:AddMessage(" - |cffffffff/fo status:|r Muestra tu configuración actual.")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff004. CRUZ VISUAL:|r")
        DEFAULT_CHAT_FRAME:AddMessage(" - |cffffffff/fo cruz:|r Enciende o apaga la mira visual.")
        DEFAULT_CHAT_FRAME:AddMessage(" - |cffffffff/fo alpha [0.1-1.0]:|r Cambia transparencia (0.1-1.0).")
        DEFAULT_CHAT_FRAME:AddMessage(" - |cffffffff/fo grosor [n]:|r Cambia ancho de líneas (ej: 1, 2, 4).")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000AVISO: EN MODO TURBO (BERSERK) NO SE REALIZA RESHIFT PARA TIGER FURY.|r")
    end
end

-- ==========================================================
-- MOTOR DE ROTACIÓN F1 (Sin Rip)
-- ==========================================================
function DoFeralRotation(mode)
    if not F1_Config then return end
    
    local hasTF, hasCC, isProwl, tfTime = false, false, false, 0
    local i = 1
    while true do
        local bIdx = GetPlayerBuff(i, "HELPFUL")
        if bIdx == -1 then break end
        local tex = GetPlayerBuffTexture(bIdx)
        if string.find(tex, "TigerFury") or string.find(tex, "JungleTiger") then 
            hasTF = true; tfTime = GetPlayerBuffTimeLeft(bIdx)
        end
        if string.find(tex, "ManaBurn") or string.find(tex, "Clearcasting") then hasCC = true end
        if string.find(tex, "Ambush") or string.find(tex, "Prowl") then isProwl = true end
        i = i + 1
    end
    
    if isProwl then 
        rakePending = false; isImmuneToBleed = false
        CastSpellByName("Ravage") 
        return 
    end

    local energy = UnitMana("player")
    local now = GetTime()
    local limit = F1_Config.latency or 0.5

    -- 1. TIGER FURY AUTO
    if not hasTF and not isTurboActive then
        if energy < 30 then
            if (now - lastReshiftTime > 1.2) then CastSpellByName("Reshift"); lastReshiftTime = now end
        else CastSpellByName("Tiger's Fury") end
        return
    end

    -- 2. PROCESO DE INMUNIDAD
    if rakePending and (now - rakeTimer > limit) then
        isImmuneToBleed = true; rakePending = false
        F1_Announce("TARGET POSIBLE INMUNE", 1, 0.5, 0)
    end

    -- 3. REMATES (SIEMPRE BITE)
    if GetComboPoints() >= 5 then
        CastSpellByName("Ferocious Bite") return 
    end
    
    -- 4. ATAQUE (RAKE/CLAW)
    local spell = "Rake"
    if isImmuneToBleed or IsShiftKeyDown() then
        spell = "Claw"
    else
        local hasB = false; local j = 1
        while true do
            local d = UnitDebuff("target", j)
            if not d then break end
            if string.find(string.lower(d), "rake") or string.find(string.lower(d), "arañazo") or string.find(string.lower(d), "embowel") then hasB = true break end
            j = j + 1
        end
        if hasB then spell = "Claw" 
        elseif (now - rakeTimer < limit) then spell = "Claw" 
        else spell = "Rake" end
    end

    -- 5. CLEARCASTING
    if hasCC then
        if mode == "boss" then CastSpellByName("Shred") else CastSpellByName(spell) end
        return
    end

    -- 6. RESHIFT DINÁMICO
    local prf = isTurboActive and "turbo" or F1_Config.currentGear
    if prf ~= "n" and lastEnergyError then
        local p = F1_Config[prf]
        local th = (spell == "Claw") and (p.claw - 1) or (p.rake - 1)
        if energy < 11 or energy <= th then
            if (now - lastReshiftTime > 1.2) then
                if not isTurboActive then
                    if (not hasTF) or (tfTime <= 4) then CastSpellByName("Reshift"); lastReshiftTime = now end
                else CastSpellByName("Reshift"); lastReshiftTime = now end
            end
        end
        lastEnergyError = false
    end
    
    CastSpellByName(spell)
end