-- ==========================================================
-- FERAL_ONE: PANEL DE CONFIGURACIÓN GRÁFICA
-- ==========================================================
DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00F1 Log:|r Archivo de Opciones detectado con éxito.")
local ConfigPanel = CreateFrame("Frame", "F1_ConfigPanel", UIParent)
ConfigPanel:SetWidth(500) -- Mismo tamaño que el panel de ayuda
ConfigPanel:SetHeight(580)
ConfigPanel:SetPoint("CENTER", UIParent, "CENTER", 20, 20) -- Un poco desplazado del centro inicial
ConfigPanel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8", 
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
    tile = true, tileSize = 16, edgeSize = 16, 
    insets = {left = 4, right = 4, top = 4, bottom = 4}
})
ConfigPanel:SetBackdropColor(0, 0, 0, 0.8) -- Un poco más oscuro para diferenciarlo
ConfigPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) -- Borde grisáceo
ConfigPanel:EnableMouse(true)
ConfigPanel:SetMovable(true)
ConfigPanel:RegisterForDrag("LeftButton")
ConfigPanel:SetScript("OnDragStart", function() this:StartMoving() end)
ConfigPanel:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
ConfigPanel:Hide() -- Oculto por defecto

-- Botón de cerrar (X)
local CloseBtn = CreateFrame("Button", nil, ConfigPanel, "UIPanelCloseButton")
CloseBtn:SetPoint("TOPRIGHT", ConfigPanel, "TOPRIGHT", -2, -2)

-- Título del Panel
local Title = ConfigPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
Title:SetPoint("TOP", ConfigPanel, "TOP", 0, -15)
Title:SetText("|cff00ff00CONFIGURACIÓN FERAL_ONE|r")

-- Comando para abrir este panel
SLASH_FOCONFIG1 = "/fo config"
SlashCmdList["FOCONFIG"] = function()
    if ConfigPanel:IsShown() then ConfigPanel:Hide() else ConfigPanel:Show() end
end
-- 1. LA CARCASA (Lo que ya tienes)
local ConfigPanel = CreateFrame("Frame", "F1_ConfigPanel", UIParent)
-- ... resto del código de la ventana ...
local CloseBtn = CreateFrame("Button", nil, ConfigPanel, "UIPanelCloseButton")
CloseBtn:SetPoint("TOPRIGHT", ConfigPanel, "TOPRIGHT", -2, -2)

-- 2. EL NUEVO BLOQUE (Pégalo justo aquí abajo)
local AlphaSlider = CreateFrame("Slider", "F1_AlphaSlider", F1_ConfigPanel, "OptionsSliderTemplate")
AlphaSlider:SetPoint("TOPLEFT", F1_ConfigPanel, "TOPLEFT", 40, -80)
AlphaSlider:SetMinMaxValues(0.1, 1.0)
AlphaSlider:SetValueStep(0.1)
AlphaSlider:SetWidth(200)

getglobal(AlphaSlider:GetName() .. 'Low'):SetText('0.1');
getglobal(AlphaSlider:GetName() .. 'High'):SetText('1.0');
local AlphaTitle = AlphaSlider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
AlphaTitle:SetPoint("BOTTOM", AlphaSlider, "TOP", 0, 5)
AlphaTitle:SetText("Transparencia de la Cruz")

AlphaSlider:SetScript("OnShow", function()
    this:SetValue(F1_Config.alpha or 0.4)
end)

AlphaSlider:SetScript("OnValueChanged", function()
    local val = math.floor(this:GetValue() * 10 + 0.5) / 10
    F1_Config.alpha = val
end)

-- ==========================================================
-- CONTROL: GROSOR DE LA CRUZ
-- ==========================================================

-- 1. Crear el Slider de Grosor
local GrosorSlider = CreateFrame("Slider", "F1_GrosorSlider", F1_ConfigPanel, "OptionsSliderTemplate")
GrosorSlider:SetPoint("TOPLEFT", F1_ConfigPanel, "TOPLEFT", 40, -140) -- 60px debajo del anterior
GrosorSlider:SetMinMaxValues(1, 10) -- Grosor de 1 a 10 píxeles
GrosorSlider:SetValueStep(1)
GrosorSlider:SetWidth(200)

-- 2. Etiquetas
getglobal(GrosorSlider:GetName() .. 'Low'):SetText('1');
getglobal(GrosorSlider:GetName() .. 'High'):SetText('10');
local GrosorTitle = GrosorSlider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
GrosorTitle:SetPoint("BOTTOM", GrosorSlider, "TOP", 0, 5)
GrosorTitle:SetText("Grosor de las Líneas")

-- 3. Lógica
GrosorSlider:SetScript("OnShow", function()
    this:SetValue(F1_Config.grosor or 2)
end)

GrosorSlider:SetScript("OnValueChanged", function()
    local val = math.floor(this:GetValue())
    F1_Config.grosor = val
end)


-- ==========================================================
-- CONTROL: CHECKBOXES (CRUZ Y TUERCA)
-- ==========================================================

-- 1. Checkbox para la Cruz Visual
local CruzCheck = CreateFrame("CheckButton", "F1_CruzCheck", F1_ConfigPanel, "OptionsCheckButtonTemplate")
CruzCheck:SetPoint("TOPLEFT", F1_ConfigPanel, "TOPLEFT", 280, -80) -- A la derecha del primer slider
getglobal(CruzCheck:GetName().."Text"):SetText("Mostrar Cruz")

CruzCheck:SetScript("OnShow", function()
    -- Marcamos o desmarcamos según la configuración actual
    this:SetChecked(F1_Config.showCrosshair)
end)

CruzCheck:SetScript("OnClick", function()
    -- Guardamos el estado (1 o nil) convertido a true/false
    F1_Config.showCrosshair = this:GetChecked() and true or false
end)

-- 2. Checkbox para la Tuerca (Gearbox)
local GearCheck = CreateFrame("CheckButton", "F1_GearCheck", F1_ConfigPanel, "OptionsCheckButtonTemplate")
GearCheck:SetPoint("TOPLEFT", F1_ConfigPanel, "TOPLEFT", 280, -120) -- Debajo del checkbox anterior
getglobal(GearCheck:GetName().."Text"):SetText("Mostrar Tuerca")

GearCheck:SetScript("OnShow", function()
    this:SetChecked(F1_Config.showGearbox)
end)

GearCheck:SetScript("OnClick", function()
    F1_Config.showGearbox = this:GetChecked() and true or false
    -- Llamamos a la función visual del Core para aplicar el cambio
    UpdateGearboxVisual()
end)

-- ==========================================================
-- CONTROL: THRESHOLDS P2 (EDITS)
-- ==========================================================
local P2Title = F1_ConfigPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
-- ESTE ES EL ÚNICO NÚMERO QUE DEBES TOCAR PARA BAJAR TODO EL BLOQUE
P2Title:SetPoint("TOPLEFT", F1_ConfigPanel, "TOPLEFT", 40, -280) 
P2Title:SetText("|cffffff00MARCHA P2: LÍMITES DE ENERGÍA|r")

-- 1. Cuadro para RAKE (Relativo al título)
local P2RakeEdit = CreateFrame("EditBox", "F1_P2RakeEdit", F1_ConfigPanel, "InputBoxTemplate")
P2RakeEdit:SetPoint("TOPLEFT", P2Title, "BOTTOMLEFT", 10, -10)
P2RakeEdit:SetWidth(50); P2RakeEdit:SetHeight(20); P2RakeEdit:SetAutoFocus(false)

local RakeLabel = P2RakeEdit:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
RakeLabel:SetPoint("LEFT", P2RakeEdit, "RIGHT", 10, 0)
RakeLabel:SetText("Rake (Arañazo)")

-- 2. Cuadro para CLAW (Relativo a Rake)
local P2ClawEdit = CreateFrame("EditBox", "F1_P2ClawEdit", F1_ConfigPanel, "InputBoxTemplate")
P2ClawEdit:SetPoint("TOPLEFT", P2RakeEdit, "BOTTOMLEFT", 0, -10)
P2ClawEdit:SetWidth(50); P2ClawEdit:SetHeight(20); P2ClawEdit:SetAutoFocus(false)

local ClawLabel = P2ClawEdit:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ClawLabel:SetPoint("LEFT", P2ClawEdit, "RIGHT", 10, 0)
ClawLabel:SetText("Claw (Zarpa)")

-- Lógica (Igual a la tuerca estable)
P2RakeEdit:SetScript("OnShow", function() this:SetText(F1_Config.p2.rake) end)
P2ClawEdit:SetScript("OnShow", function() this:SetText(F1_Config.p2.claw) end)

P2RakeEdit:SetScript("OnEnterPressed", function() 
    F1_Config.p2.rake = tonumber(this:GetText()) or 0
    this:ClearFocus()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1:|r P2 Rake actualizado a "..F1_Config.p2.rake)
end)

P2ClawEdit:SetScript("OnEnterPressed", function() 
    F1_Config.p2.claw = tonumber(this:GetText()) or 0
    this:ClearFocus()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1:|r P2 Claw actualizado a "..F1_Config.p2.claw)
end)


-- ==========================================================
-- CONTROL: THRESHOLDS TURBO (EDITS)
-- ==========================================================
local TurboTitle = F1_ConfigPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
-- Bajado a -280 para nivelar con el de la izquierda
TurboTitle:SetPoint("TOPLEFT", F1_ConfigPanel, "TOPLEFT", 340, -280)
TurboTitle:SetText("|cffff0000MODO TURBO: LÍMITES|r")

-- 1. Cuadro para RAKE (Turbo)
local TRakeEdit = CreateFrame("EditBox", "F1_TRakeEdit", F1_ConfigPanel, "InputBoxTemplate")
TRakeEdit:SetPoint("TOPLEFT", TurboTitle, "BOTTOMLEFT", 10, -10)
TRakeEdit:SetWidth(40); TRakeEdit:SetHeight(20); TRakeEdit:SetAutoFocus(false)

local TRakeLabel = TRakeEdit:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TRakeLabel:SetPoint("LEFT", TRakeEdit, "RIGHT", 10, 0)
TRakeLabel:SetText("Rake T")

-- 2. Cuadro para CLAW (Turbo)
local TClawEdit = CreateFrame("EditBox", "F1_TClawEdit", F1_ConfigPanel, "InputBoxTemplate")
TClawEdit:SetPoint("TOPLEFT", TRakeEdit, "BOTTOMLEFT", 0, -10)
TClawEdit:SetWidth(40); TClawEdit:SetHeight(20); TClawEdit:SetAutoFocus(false)

local TClawLabel = TClawEdit:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TClawLabel:SetPoint("LEFT", TClawEdit, "RIGHT", 10, 0)
TClawLabel:SetText("Claw T")

-- Lógica
TRakeEdit:SetScript("OnShow", function() this:SetText(F1_Config.turbo.rake) end)
TClawEdit:SetScript("OnShow", function() this:SetText(F1_Config.turbo.claw) end)

TRakeEdit:SetScript("OnEnterPressed", function() 
    F1_Config.turbo.rake = tonumber(this:GetText()) or 0
    this:ClearFocus()
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000F1:|r Turbo Rake actualizado a "..F1_Config.turbo.rake)
end)

TClawEdit:SetScript("OnEnterPressed", function() 
    F1_Config.turbo.claw = tonumber(this:GetText()) or 0
    this:ClearFocus()
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000F1:|r Turbo Claw actualizado a "..F1_Config.turbo.claw)
end)


-- ==========================================================
-- BOTÓN DE CICLO (CORREGIDO: N -> P1 -> P2 -> N)
-- ==========================================================
local CycleBtn = CreateFrame("Button", "F1_CycleBtn", F1_ConfigPanel, "UIPanelButtonTemplate")
CycleBtn:ClearAllPoints()
-- Se ancla 50px debajo del cuadro de Claw de P2 para bajar con todo el grupo
CycleBtn:SetPoint("TOP", F1_P2ClawEdit, "BOTTOM", 120, -50) 
CycleBtn:SetWidth(180); CycleBtn:SetHeight(35)
CycleBtn:SetText("Cambiar Marcha")

CycleBtn:SetScript("OnClick", function()
    -- Corregimos el acceso a la variable para evitar el error de "index field"
    local cur = F1_Config.currentGear
    
    if cur == "n" then 
        F1_Config.currentGear = "p1"
    elseif cur == "p1" then 
        F1_Config.currentGear = "p2"
    else 
        F1_Config.currentGear = "n" -- Vuelve a Neutral después de P2
    end
    
    -- Actualizamos la visual de la tuerca al instante
    if UpdateGearboxVisual then
        UpdateGearboxVisual()
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffF1:|r Ciclo manual a " .. string.upper(F1_Config.currentGear))
end)

-- Etiqueta informativa corregida
local CycleInfo = F1_ConfigPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
CycleInfo:ClearAllPoints()
CycleInfo:SetPoint("TOP", CycleBtn, "BOTTOM", 0, -5)
CycleInfo:SetText("|cff00ccff(N -> P1 -> P2 -> N)|r")


-- ==========================================================
-- CONTROL: MOSTRAR/OCULTAR AYUDA (TEXTOS)
-- ==========================================================

local HelpCheck = CreateFrame("CheckButton", "F1_HelpCheck", F1_ConfigPanel, "OptionsCheckButtonTemplate")
HelpCheck:SetPoint("TOPLEFT", F1_ConfigPanel, "TOPLEFT", 280, -160) -- Debajo de los otros checks
getglobal(HelpCheck:GetName().."Text"):SetText("Mostrar Textos de Ayuda")

HelpCheck:SetScript("OnShow", function()
    -- Cargamos el estado actual (si no existe, por defecto es true)
    if F1_Config.showHelp == nil then F1_Config.showHelp = true end
    this:SetChecked(F1_Config.showHelp)
end)

HelpCheck:SetScript("OnClick", function()
    F1_Config.showHelp = this:GetChecked() and true or false
    
    -- Aplicamos el cambio al frame de ayuda inmediatamente
    if F1_HelpPanel then
        if F1_Config.showHelp then
            F1_HelpPanel:Show()
        else
            F1_HelpPanel:Hide()
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffF1:|r Visibilidad de ayuda actualizada.")
end)


-- ==========================================================
-- CHECKBOX: MODO MOVER (POSICIÓN SIMÉTRICA A -200)
-- ==========================================================
local GMoveCheck = CreateFrame("CheckButton", "F1_GMoveCheck", F1_ConfigPanel, "OptionsCheckButtonTemplate")
-- X en 280 para alinear con los otros, Y en -200 para mantener la distancia de 40px
GMoveCheck:SetPoint("TOPLEFT", F1_ConfigPanel, "TOPLEFT", 280, -200) 
getglobal(GMoveCheck:GetName().."Text"):SetText("Habilitar Movimiento de Tuerca")

GMoveCheck:SetScript("OnShow", function()
    -- Sincroniza visualmente el check con la configuración guardada
    this:SetChecked(F1_Config.editMode)
end)

GMoveCheck:SetScript("OnClick", function()
    local isChecked = this:GetChecked() and true or false
    F1_Config.editMode = isChecked
    
    -- Aplicamos el cambio al frame del Gearbox en tiempo real
    if F1_GearFrame then
        if isChecked then
            F1_GearFrame:RegisterForDrag("LeftButton")
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00F1:|r Modo mover activado.")
        else
            F1_GearFrame:RegisterForDrag(nil)
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000F1:|r Modo mover desactivado.")
        end
    end
end)


-- ==========================================================
-- FUNCIÓN PARA MOSTRAR MACRO COPIABLE
-- ==========================================================
function F1_ShowCopyBox(macroText)
    local f = CreateFrame("Frame", "F1_CopyFrame", UIParent, "DialogBoxFrame")
    f:SetPoint("CENTER")
    f:SetSize(400, 100)
    f:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = {left = 11, right = 12, top = 12, bottom = 11}})
    
    local editBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    editBox:SetSize(360, 30)
    editBox:SetPoint("CENTER", 0, 10)
    editBox:SetText(macroText)
    editBox:HighlightText() -- Selecciona todo el texto automáticamente
    editBox:SetFocus()
    
    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("BOTTOM", editBox, "TOP", 0, 5)
    label:SetText("Presiona CTRL+C para copiar la Macro")
end

-- ==========================================================
-- SECCIÓN: MACROS COPIABLES (COMPATIBLE VERSIÓN ANTIGUA)
-- ==========================================================

-- Función para mostrar la ventana (Sin cambios, ya evita duplicados)
function F1_ShowCopyBox(macroText)
    local f = getglobal("F1_CopyFrame")
    if f then
        f:Show()
        local eb = getglobal("F1_CopyEditBox")
        if eb then
            eb:SetText(macroText)
            eb:HighlightText()
            eb:SetFocus()
        end
        return
    end

    f = CreateFrame("Frame", "F1_CopyFrame", UIParent)
    f:SetWidth(350); f:SetHeight(120)
    f:SetPoint("CENTER", 0, 0)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

    local eb = CreateFrame("EditBox", "F1_CopyEditBox", f, "InputBoxTemplate")
    eb:SetWidth(300); eb:SetHeight(30)
    eb:SetPoint("CENTER", 0, 0)
    eb:SetText(macroText)
    eb:HighlightText()
    
    local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    close:SetWidth(80); close:SetHeight(22)
    close:SetPoint("BOTTOM", 0, 15)
    close:SetText("Cerrar")
    close:SetScript("OnClick", function() f:Hide() end)
    
    local lab = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lab:SetPoint("TOP", 0, -15)
    lab:SetText("Presiona CTRL+C para copiar:")
end

-- ==========================================================
-- BOTONES DE MACRO (BAJADOS A -65)
-- ==========================================================

-- Botón Macro Boss
local MacroResetBtn = CreateFrame("Button", "F1_MacroResetBtn", F1_ConfigPanel, "UIPanelButtonTemplate")
MacroResetBtn:SetPoint("TOPLEFT", F1_CycleBtn, "BOTTOMLEFT", -20, -65) 
MacroResetBtn:SetWidth(110); MacroResetBtn:SetHeight(25)
MacroResetBtn:SetText("Macro boss")
MacroResetBtn:SetScript("OnClick", function() F1_ShowCopyBox("/run DoFeralRotation('boss')") end)

-- Botón Macro Trash
local MacroMoveBtn = CreateFrame("Button", "F1_MacroMoveBtn", F1_ConfigPanel, "UIPanelButtonTemplate")
MacroMoveBtn:SetPoint("TOPRIGHT", F1_CycleBtn, "BOTTOMRIGHT", 20, -65) 
MacroMoveBtn:SetWidth(110); MacroMoveBtn:SetHeight(25)
MacroMoveBtn:SetText("Macro trash")
MacroMoveBtn:SetScript("OnClick", function() F1_ShowCopyBox("/run DoFeralRotation('trash')") end)

-- Texto Informativo en Celeste
local MacroInfoText = F1_ConfigPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
-- Lo centramos debajo de los dos botones
MacroInfoText:SetPoint("TOP", F1_CycleBtn, "BOTTOM", 0, -95) 
MacroInfoText:SetText("|cff00ccffCrea estos dos macros para el uso del addon, mas info en 'Help'|r")

