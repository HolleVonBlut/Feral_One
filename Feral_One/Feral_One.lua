-- ==========================================================
-- Feral_One v11.6 - Edición Blindada + HELP PANEL PRO
-- Colaboración: Holle & Gemini
-- ==========================================================

local F1 = {} 
F1.Version = "11.6"
F1.Author = "Holle"

local lastEnergyError = false
local isImmuneToBleed = false
local rakePending = false
local rakeTimer = 0
local isTurboActive = false
local lastReshiftTime = 0 
local isGearMoving = false 

-- ==========================================================
-- GESTIÓN DE CONFIGURACIÓN (Persistencia)
-- ==========================================================
local function InitializeSettings()
    if not F1_Config then F1_Config = {} end
    if F1_Config.currentGear == nil then F1_Config.currentGear = "p2" end
    if F1_Config.showCrosshair == nil then F1_Config.showCrosshair = true end
    if F1_Config.showGearbox == nil then F1_Config.showGearbox = true end
    if F1_Config.alpha == nil then F1_Config.alpha = 0.4 end
    if F1_Config.latency == nil then F1_Config.latency = 0.5 end 
    
    if not F1_Config.p1 then F1_Config.p1 = {rake=0, claw=0} end 
    if not F1_Config.p2 then F1_Config.p2 = {rake=25, claw=30} end 
    if not F1_Config.turbo then F1_Config.turbo = {rake=32, claw=37} end 
    
    if F1_Config.offsetX == nil then F1_Config.offsetX = 0 end
    if F1_Config.offsetY == nil then F1_Config.offsetY = -7 end
    if F1_Config.grosor == nil then F1_Config.grosor = 2 end

    if not F1_Config.pos then F1_Config.pos = {} end
    if not F1_Config.pos.sysX then F1_Config.pos.sysX = 0; F1_Config.pos.sysY = 150 end
    if not F1_Config.pos.gearX then F1_Config.pos.gearX = -150; F1_Config.pos.gearY = 0 end
    if not F1_Config.pos.helpX then F1_Config.pos.helpX = 0; F1_Config.pos.helpY = 0 end
end

-- ==========================================================
-- SISTEMA DE ANUNCIOS (Cuadro Central)
-- ==========================================================
local function CreateMovableFrame(name, title, configX, configY, fontSize)
    local f = CreateFrame("Frame", name.."Anchor", UIParent)
    f:SetWidth(200); f:SetHeight(40)
    f:SetPoint("CENTER", UIParent, "CENTER", configX, configY)
    f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = {left = 2, right = 2, top = 2, bottom = 2}})
    f:SetBackdropColor(0, 1, 0, 0.5)
    f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() 
        this:StopMovingOrSizing() 
        local _, _, _, sx, sy = this:GetPoint()
        F1_Config.pos.sysX, F1_Config.pos.sysY = sx, sy
    end)
    f:Hide()
    local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t:SetPoint("CENTER", f, "CENTER"); t:SetText(title)
    local msg = CreateFrame("MessageFrame", name, UIParent)
    msg:SetPoint("CENTER", f, "CENTER", 0, 0); msg:SetWidth(600); msg:SetHeight(100)
    msg:SetInsertMode("TOP"); msg:SetFrameStrata("HIGH"); msg:SetTimeVisible(2.5)
    msg:SetFont("Interface\\AddOns\\Feral_One\\Fonts\\Formula1-Bold-4.ttf", fontSize, "OUTLINE")
    return f, msg
end

local SysAnchor, F1_MsgFrame = CreateMovableFrame("F1_AnnounceFrame", "SISTEMA", 0, 150, 20)
local function F1_Announce(text, r, g, b) F1_MsgFrame:AddMessage(text, r, g, b) end

-- ==========================================================
-- PANEL DE AYUDA (Translúcido 0.7, Centrado y Grande)
-- ==========================================================
local HelpPanel = CreateFrame("Frame", "F1_HelpPanel", UIParent)
HelpPanel:SetWidth(500); HelpPanel:SetHeight(580)
HelpPanel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8", 
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
    tile = true, tileSize = 16, edgeSize = 16, 
    insets = {left = 4, right = 4, top = 4, bottom = 4}
})
HelpPanel:SetBackdropColor(0, 0, 0, 0.7)
HelpPanel:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
HelpPanel:EnableMouse(true); HelpPanel:SetMovable(true)
HelpPanel:RegisterForDrag("LeftButton")
HelpPanel:SetScript("OnDragStart", function() this:StartMoving() end)
HelpPanel:SetScript("OnDragStop", function() 
    this:StopMovingOrSizing()
    local _, _, _, hx, hy = this:GetPoint()
    F1_Config.pos.helpX, F1_Config.pos.helpY = hx, hy
end)
HelpPanel:Hide()

local CloseBtn = CreateFrame("Button", nil, HelpPanel, "UIPanelCloseButton")
CloseBtn:SetPoint("TOPRIGHT", HelpPanel, "TOPRIGHT", -2, -2)

local HelpText = HelpPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HelpText:SetPoint("CENTER", HelpPanel, "CENTER", 0, 0)
HelpText:SetJustifyH("CENTER")
HelpText:SetText(
"|cff00ff00=== GUÍA DETALLADA FERAL_ONE v11.6 ===|r\n\n"..
    "|cffffff001. MODOS DE COMBATE Y MACROS|r\n"..
    "|cffff0000Es necesario crear estos dos macros para que el addon funcione!!\nubica los dos macros en lugares comodos.|r\n\n"..
    "|cffffffff- BOSS: Prioriza shred bajo proc de CLEARCASTING.\n|r"..
    "|cff00ffff/run DoFeralRotation('boss')|r\n"..
    "|cffffffff- TRASH: Máximo daño sin buscar la espalda.\n|r"..
    "|cff00ffff/run DoFeralRotation('trash')|r\n\n"..
    "|cffffff002. MARCHAS (GEARBOX)|r\n"..
    "|cffffffffN y P1: El addon renueva Tiger Fury e incluso hace reshift\n"..
    "para mantener el buff activo lo mas rapido posible.\n"..
    "P2 y Turbo: No se renueva Tiger Fury para priorizar el daño.|r\n"..
    "|cff00ff00P1 (Verde)|r | |cffffff00P2 (Amarillo)|r | |cff00ffffN (Celeste)|r\n"..
    "|cff00ffff/fo p1 -- /fo p2 -- /fo n|r o Clic en la Tuerca\n\n"..
    "|cffffff003. CONFIGURACIÓN TÉCNICA (EJEMPLOS)|r\n"..
    "|cffffffffAjusta los límites de energía para el Reshift automático:\n"..
    "|cff00ffff/fo edit [marcha] [rake] [claw]|r\n"..
    "|cffffcc00Ej: /fo edit p2 25 30|r |cffffffff(Reshift si E <= 25 en Rake o 30 en Claw).\n"..
    "Ajusta la respuesta según tus MS (Latencia):\n"..
    "|cff00ffff/fo latency [ms]|r |cffffcc00Ej: /fo latency 150|r\n\n"..
    "|cffffff004. CONTROL VISUAL Y CRUZ|r\n"..
    "|cffffffffMover elementos o personalizar la mira visual:\n"..
    "|cff00ffff/fo gearbox|r (On/Off) | |cff00ffff/fo gmove|r (Mover Tuerca)\n"..
    "|cff00ffff/fo cruz|r (Mira On/Off) | |cff00ffff/fo alpha 0.5|r (Semitransparente)\n"..
    "|cff00ffff/fo grosor 4|r (Líneas más gruesas) | |cff00ffff/fo move|r (Mover Anuncios)\n\n"..
    "|cffff0000/fo reset: Resetea todas las posiciones y valores.|r\n\n"..
    "|cffffffffUsa |cffffff00/fo status|r para ver tu configuración actual.|r"
)

-- ==========================================================
-- SISTEMA GEARBOX (La Tuerca) - Versión Estable
-- ==========================================================
F1_GearFrame = CreateFrame("Button", "F1_Gearbox", UIParent) -- Ahora es global y visible
F1_GearFrame:SetWidth(64); F1_GearFrame:SetHeight(64)
F1_GearFrame:SetMovable(true); F1_GearFrame:EnableMouse(true)
F1_GearFrame:RegisterForClicks("LeftButtonUp")
F1_GearFrame:RegisterForDrag("LeftButton") -- Habilita el arrastre

local F1_GearTex = F1_GearFrame:CreateTexture("F1_GearTex", "OVERLAY")
F1_GearTex:SetAllPoints(F1_GearFrame)

local F1_GearText = F1_GearFrame:CreateFontString("F1_GearText", "OVERLAY")
F1_GearText:SetFont("Interface\\AddOns\\Feral_One\\Fonts\\Formula1-Bold-4.ttf", 14, "OUTLINE")
F1_GearText:SetPoint("CENTER", F1_GearFrame, "CENTER", 0, 0)

-- Función de Actualización (Corregida para evitar desapariciones)
function UpdateGearboxVisual()
    -- Seguridad: inicializar coordenadas si no existen
    if not F1_Config.pos.gearX then F1_Config.pos.gearX = 0 end
    if not F1_Config.pos.gearY then F1_Config.pos.gearY = 0 end

    if not F1_Config.showGearbox then F1_GearFrame:Hide(); return end
    F1_GearFrame:Show()

    local path = "Interface\\AddOns\\Feral_One\\Media\\"
    local tex, gearName, r, g, b = "tuerca_N", "NEUTRAL", 0, 1, 1
    
    if isTurboActive then
        tex, gearName, r, g, b = "tuerca_T", "TURBO", 1, 0, 0
        F1_GearText:SetText("|cffff0000T|r")
    elseif F1_Config.currentGear == "p1" then
        tex, gearName, r, g, b = "tuerca_P1", "PRIMERA", 0, 1, 0
        F1_GearText:SetText("|cff00ff00P1|r")
    elseif F1_Config.currentGear == "p2" then
        tex, gearName, r, g, b = "tuerca_P2", "SEGUNDA", 1, 1, 0
        F1_GearText:SetText("|cffffff00P2|r")
    else
        F1_GearText:SetText("|cff00ffffN|r")
    end
    
    F1_GearTex:SetTexture(path..tex)
    PlaySoundFile(path.."t2.wav")
    F1_Announce("MARCHA: "..gearName, r, g, b)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1 Log:|r Marcha cambiada a "..gearName)

    -- Aplicamos la posición guardada de forma segura
    if F1_GearFrame then
        F1_GearFrame:ClearAllPoints()
        F1_GearFrame:SetPoint("CENTER", UIParent, "CENTER", F1_Config.pos.gearX, F1_Config.pos.gearY)
    end
end

-- Scripts de Interacción
F1_GearFrame:SetScript("OnClick", function()
    if not isTurboActive then
        local cur = F1_Config.currentGear
        if cur == "n" then F1_Config.currentGear = "p1"
        elseif cur == "p1" then F1_Config.currentGear = "p2"
        else F1_Config.currentGear = "n" end
        UpdateGearboxVisual()
    end
end)

F1_GearFrame:SetScript("OnDragStart", function() 
    this:StartMoving() 
end)

F1_GearFrame:SetScript("OnDragStop", function() 
    this:StopMovingOrSizing() 
    -- Cálculo de coordenadas relativas al centro (Crucial para que no desaparezca)
    local x, y = this:GetCenter()
    local cx, cy = UIParent:GetCenter()
    
    -- Guardamos en la tabla de configuración persistente
    F1_Config.pos.gearX = x - cx
    F1_Config.pos.gearY = y - cy
    
    -- Forzamos el re-anclaje inmediato
    this:ClearAllPoints()
    this:SetPoint("CENTER", UIParent, "CENTER", F1_Config.pos.gearX, F1_Config.pos.gearY)
end)


-- ==========================================================
-- LOGO DE CRÉDITOS
-- ==========================================================
local F1_LogoFrame = CreateFrame("Frame", nil, UIParent)
F1_LogoFrame:SetWidth(754); F1_LogoFrame:SetHeight(252) 
F1_LogoFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200); F1_LogoFrame:Hide()
local F1_LogoTex = F1_LogoFrame:CreateTexture(nil, "OVERLAY")
F1_LogoTex:SetAllPoints(F1_LogoFrame)
F1_LogoTex:SetTexture("Interface\\AddOns\\Feral_One\\Media\\Creditos")

local function ShowF1Logo()
    F1_LogoFrame:SetAlpha(1.0); F1_LogoFrame:Show()
    local startTime = GetTime()
    F1_LogoFrame:SetScript("OnUpdate", function()
        local elapsed = GetTime() - startTime
        if elapsed > 5 then 
            local alpha = 1.0 - (elapsed - 5) 
            if alpha <= 0 then F1_LogoFrame:Hide(); F1_LogoFrame:SetScript("OnUpdate", nil)
            else F1_LogoFrame:SetAlpha(alpha) end
        end
    end)
end

-- ==========================================================
-- CRUZ DE OBJETIVO
-- ==========================================================
local NPL_Frame = CreateFrame("Frame", nil, UIParent)
NPL_Frame:SetFrameStrata("BACKGROUND")
local HBar = NPL_Frame:CreateTexture(nil, "BACKGROUND"); HBar:SetTexture(1, 1, 1, 1)
local VBar = NPL_Frame:CreateTexture(nil, "BACKGROUND"); VBar:SetTexture(1, 1, 1, 1)

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
    if not F1_Config or not F1_Config.showCrosshair then HBar:Hide(); VBar:Hide(); return end
    local plate = GetTargetPlate()
    if plate then
        local a, g = F1_Config.alpha or 1.0, F1_Config.grosor or 2
        HBar:SetHeight(g); HBar:SetWidth(5000); VBar:SetWidth(g); VBar:SetHeight(5000)
        if UnitIsFriend("player", "target") then HBar:SetVertexColor(1,1,1, a); VBar:SetVertexColor(1,1,1, a)
        elseif UnitIsEnemy("player", "target") then HBar:SetVertexColor(1,0,0, a); VBar:SetVertexColor(1,0,0, a)
        else HBar:SetVertexColor(1,1,0, a); VBar:SetVertexColor(1,1,0, a) end
        HBar:ClearAllPoints(); HBar:SetPoint("CENTER", plate, "CENTER", F1_Config.offsetX, F1_Config.offsetY)
        VBar:ClearAllPoints(); VBar:SetPoint("CENTER", plate, "CENTER", F1_Config.offsetX, F1_Config.offsetY)
        HBar:Show(); VBar:Show()
    else HBar:Hide(); VBar:Hide() end
end)

-- ==========================================================
-- LÓGICA DE CICLO DE MARCHAS (PARA EL PANEL)
-- ==========================================================
function F1_CycleGears()
    -- Obtenemos la marcha actual y la pasamos a minúsculas para evitar errores
    local gear = string.lower(F1_Config.currentGear or "n")
    
    if gear == "n" then 
        F1_Config.currentGear = "p1"
    elseif gear == "p1" then 
        F1_Config.currentGear = "p2"
    elseif gear == "p2" then 
        F1_Config.currentGear = "T"
    else 
        F1_Config.currentGear = "n" 
    end
    
    -- Llamamos a tu función para que cambie el color y el texto de la tuerca
    UpdateGearboxVisual()
end


-- ==========================================================
-- COMANDOS /fo
-- ==========================================================
SLASH_FERALONE1 = "/fo"
SlashCmdList["FERALONE"] = function(msg)
    local args = {}
    for word in string.gfind(msg, "%S+") do table.insert(args, word) end
    
    if args[1] == "help" or args[1] == nil then
        if HelpPanel:IsShown() then HelpPanel:Hide() else HelpPanel:Show() end
elseif args[1] == "config" then
        if F1_ConfigPanel:IsShown() then F1_ConfigPanel:Hide() else F1_ConfigPanel:Show() end
    elseif args[1] == "reset" then
        F1_Config.pos = { sysX=0, sysY=150, gearX=-150, gearY=0, helpX=0, helpY=0 }
        SysAnchor:ClearAllPoints(); SysAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        F1_GearFrame:ClearAllPoints(); F1_GearFrame:SetPoint("CENTER", UIParent, "CENTER", -150, 0)
        HelpPanel:ClearAllPoints(); HelpPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        F1_Config.latency = 0.5; F1_Config.alpha = 0.4; F1_Config.grosor = 2
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000F1 Log:|r Todas las posiciones y valores reseteados.")
    elseif args[1] == "move" then
        if SysAnchor:IsShown() then SysAnchor:Hide(); DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1 Log:|r Posición anuncios guardada.")
        else SysAnchor:Show(); DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1 Log:|r Modo edición activado.") end
    elseif args[1] == "gmove" then
        if isGearMoving then 
            F1_GearFrame:RegisterForDrag(); isGearMoving = false
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1 Log:|r Tuerca fijada.")
        else 
            F1_GearFrame:RegisterForDrag("LeftButton"); isGearMoving = true
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1 Log:|r Modo edición: Arrastra la tuerca.") 
        end
    elseif args[1] == "gearbox" then
        F1_Config.showGearbox = not F1_Config.showGearbox; UpdateGearboxVisual()
    elseif args[1] == "p1" or args[1] == "p2" or args[1] == "n" then
        F1_Config.currentGear = args[1]; UpdateGearboxVisual()
    elseif args[1] == "status" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00=== FERAL_ONE STATUS ===|r")
        DEFAULT_CHAT_FRAME:AddMessage("Marcha: "..F1_Config.currentGear.." | Latencia: "..F1_Config.latency)
    elseif args[1] == "edit" and args[2] and args[3] and args[4] then
        local p = args[2]
        if F1_Config[p] then 
            F1_Config[p].rake = tonumber(args[3]); F1_Config[p].claw = tonumber(args[4]) 
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1 Log:|r "..p.." -> Rake:"..args[3].." Claw:"..args[4])
        end
    elseif args[1] == "latency" and args[2] then
        F1_Config.latency = tonumber(args[2]) < 100 and 0.5 or 1.0
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1 Log:|r Latencia a "..args[2].."ms")
    elseif args[1] == "cruz" then 
        F1_Config.showCrosshair = not F1_Config.showCrosshair
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1 Log:|r Cruz Visual: "..(F1_Config.showCrosshair and "ON" or "OFF"))
    elseif args[1] == "alpha" and args[2] then F1_Config.alpha = tonumber(args[2])
    elseif args[1] == "grosor" and args[2] then F1_Config.grosor = tonumber(args[2])
    end
end

-- ==========================================================
-- MOTOR DE ROTACIÓN Y EVENTOS
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
        SysAnchor:SetPoint("CENTER", UIParent, "CENTER", F1_Config.pos.sysX, F1_Config.pos.sysY)
        F1_GearFrame:SetPoint("CENTER", UIParent, "CENTER", F1_Config.pos.gearX, F1_Config.pos.gearY)
        HelpPanel:SetPoint("CENTER", UIParent, "CENTER", F1_Config.pos.helpX, F1_Config.pos.helpY)
        UpdateGearboxVisual(); ShowF1Logo()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Feral_One v"..F1.Version.." Cargado.|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00- /fo config:|r configuracion del addon.")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00- /fo help:|r Guía detallada.")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00- /fo status:|r para ver la marcha actual y demas configuraciones.")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00- /fo reset:|r Resetea la interfaz si se pierde.")
    elseif event == "PLAYER_TARGET_CHANGED" then
        isImmuneToBleed, rakePending, lastEnergyError = false, false, false
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        if (string.find(arg1, "Rake") or string.find(arg1, "Arañazo")) then
            if string.find(arg1, "hits") or string.find(arg1, "crits") or string.find(arg1, "golpea") then
                rakePending = true; rakeTimer = GetTime()
            elseif string.find(arg1, "immune") or string.find(arg1, "inmune") then
                isImmuneToBleed = true; rakePending = false
            end
        end
    elseif event == "UI_ERROR_MESSAGE" then
        if (arg1 == "Not enough energy" or arg1 == "Falta energía") then lastEnergyError = true end
    elseif event == "PLAYER_AURAS_CHANGED" then
        local found, i = false, 1
        while true do
            local b = GetPlayerBuffTexture(GetPlayerBuff(i, "HELPFUL")); if not b then break end
            if string.find(b, "Ability_Druid_Berserk") then found = true break end
            i = i + 1
        end
        if found and not isTurboActive then isTurboActive = true; UpdateGearboxVisual()
        elseif not found and isTurboActive then isTurboActive = false; UpdateGearboxVisual() end
    end
end)

function DoFeralRotation(mode)
    if not F1_Config then return end
    local hasTF, hasCC, isProwl, tfTime, i = false, false, false, 0, 1
    while true do
        local bIdx = GetPlayerBuff(i, "HELPFUL"); if bIdx == -1 then break end
        local tex = GetPlayerBuffTexture(bIdx)
        if string.find(tex, "TigerFury") then hasTF = true; tfTime = GetPlayerBuffTimeLeft(bIdx) end
        if string.find(tex, "Clearcasting") then hasCC = true end
        if string.find(tex, "Prowl") then isProwl = true end
        i = i + 1
    end
    if isProwl then CastSpellByName("Ravage"); return end
    local energy, now = UnitMana("player"), GetTime()
    if (F1_Config.currentGear == "p1") and not hasTF and not isTurboActive then
        if energy < 30 then if (now - lastReshiftTime > 1.2) then CastSpellByName("Reshift"); lastReshiftTime = now end
        else CastSpellByName("Tiger's Fury") end return
    end
    if GetComboPoints() >= 5 then CastSpellByName("Ferocious Bite"); return end
    local spell = "Rake"
    local hasB, j = false, 1
    while true do
        local d = UnitDebuff("target", j); if not d then break end
        if string.find(string.lower(d), "rake") then hasB = true break end
        j = j + 1
    end
    if hasB or isImmuneToBleed then spell = "Claw" end
    if hasCC then if mode == "boss" then CastSpellByName("Shred") else CastSpellByName(spell) end return end
    local prf = isTurboActive and "turbo" or F1_Config.currentGear
    if prf ~= "n" and lastEnergyError then
        local p = F1_Config[prf]; local th = (spell == "Claw") and p.claw or p.rake
        local shouldReshift = false
    if prf == "turbo" then
        if energy < th then shouldReshift = true end
    else
        if energy <= th then shouldReshift = true end
    end

    if shouldReshift then
        if (now - lastReshiftTime > 1.2) then 
            CastSpellByName("Reshift"); 
            lastReshiftTime = now 
        end 
    end
    lastEnergyError = false
end
end


-- ==========================================================
-- INICIALIZACIÓN DE ESTADO (Pegar al final del archivo)
-- ==========================================================

-- Verificamos el estado del modo edición al cargar
if F1_Config and F1_Config.editMode then
    F1_GearFrame:RegisterForDrag("LeftButton")
else
    F1_GearFrame:RegisterForDrag(nil)
end

-- También ejecutamos la visualización inicial para que la tuerca 
-- aparezca en su posición guardada nada más entrar
UpdateGearboxVisual()