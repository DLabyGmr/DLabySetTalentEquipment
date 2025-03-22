-- Inicializa la tabla de variables guardadas si no existe.
if not TalentEquipDB then
    TalentEquipDB = {}
end

--------------------------------------------------
-- Lógica principal: Equipamiento al actualizar la config.
--------------------------------------------------

-- Crea un frame para registrar eventos.
local frame = CreateFrame("Frame")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")

local function EquipTalentSet()
    local specID = select(1, GetSpecializationInfo(GetSpecialization()))
    if not specID then return end

    local talentConfigID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
    if not talentConfigID then return end

    local mappedSetID = C_EquipmentSet.GetEquipmentSetID(TalentEquipDB[talentConfigID])
    if mappedSetID then
            print("Equipando set mapeado: " .. TalentEquipDB[talentConfigID])
            C_EquipmentSet.UseEquipmentSet(mappedSetID)
    else
        print("No hay mapeo para la configuración de talentos actual.")
    end
end


frame:SetScript("OnEvent", function(self, event, ...)
    if event == "TRAIT_CONFIG_UPDATED" then
        C_Timer.After(0.5, EquipTalentSet)
    end
end)

--------------------------------------------------
-- Función para obtener la lista de configuraciones de talentos
--------------------------------------------------

local function GetTalentLoadouts()
    local loadouts = {}
    local numSpecializations = GetNumSpecializations()
    for i = 1, numSpecializations do
        local specID = select(1, GetSpecializationInfo(i))
        local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)
        if configIDs then
            for _, configID in ipairs(configIDs) do
                local configInfo = C_Traits.GetConfigInfo(configID)
                local loadoutName = configInfo and configInfo.name or "Unknown"
                table.insert(loadouts, { configID = configID, name = loadoutName })
            end
        else
            print("No se encontraron loadouts para specID: " .. tostring(specID))
        end
    end
    return loadouts
end

--------------------------------------------------
-- Función para obtener el nombre del set de equipo actual
--------------------------------------------------

local function GetCurrentEquipmentSetName()
    local numSets = C_EquipmentSet.GetNumEquipmentSets()
    for i = 0, numSets - 1 do
	if select(4,C_EquipmentSet.GetEquipmentSetInfo(i)) then
		return select(1,C_EquipmentSet.GetEquipmentSetInfo(i))
	end
    end
    return nil
end

--------------------------------------------------
-- Panel de Opciones en el menú del juego.
--------------------------------------------------

-- Crea el panel de opciones.
local optionsPanel = CreateFrame("Frame", "TalentEquipOptionsPanel", UIParent)
optionsPanel.name = "TalentEquip Options"

local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("TalentEquip Options")

-- Registra la categoría usando la API actual.
local category, layout = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name, optionsPanel.name)
Settings.RegisterAddOnCategory(category)

optionsPanel:SetScript("OnShow", function(self)
    -- Crea los elementos si no existen
    if not self.loadoutElements then
    self.loadoutElements = {}

    local loadouts = GetTalentLoadouts()
    if loadouts then
        local pos = 10;
        for _, loadout in ipairs(loadouts) do
            -- Crea el label con el nombre de la configuración.
            local label = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            label:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10-pos)
            label:SetText(loadout.name)
            table.insert(self.loadoutElements, label)

            -- Crea el EditBox para que el usuario pueda introducir el mapeo.
            local editBox = CreateFrame("EditBox", nil, optionsPanel, "InputBoxTemplate")
            editBox:SetSize(150, 20)  -- ancho y alto
            editBox:SetPoint("LEFT", label, "RIGHT", 10, 0)
            editBox:SetAutoFocus(false)  -- evita que se enfoque automáticamente

            -- Si hay un valor guardado para este configID, lo carga.
            if TalentEquipDB[loadout.configID] then
                editBox:SetText(TalentEquipDB[loadout.configID])
            end

            -- Al cambiar el texto, se actualiza la base de datos del addon.
            editBox:SetScript("OnTextChanged", function(self)
                local text = self:GetText()
                TalentEquipDB[loadout.configID] = text
            end)
            table.insert(self.loadoutElements, editBox)

	     -- Crea el botón "Fijar actual" al lado del EditBox.
            local setButton = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
            setButton:SetSize(100, 20) -- ancho y alto
            setButton:SetPoint("LEFT", editBox, "RIGHT", 10, 0)
            setButton:SetText("Fijar actual")

	    -- Al hacer clic en el botón, se obtiene el nombre del set actual y se establece en el EditBox.
            setButton:SetScript("OnClick", function()
                local currentSetName = GetCurrentEquipmentSetName()
                if currentSetName then
                    editBox:SetText(currentSetName)
                    TalentEquipDB[loadout.configID] = currentSetName
                else
                    print("No hay un set de equipo actualmente equipado.")
                end
            end)

            pos = pos + 35  -- separa cada línea
        end
    else
        print("No se encontraron configuraciones de talentos.")
    end
end
end)