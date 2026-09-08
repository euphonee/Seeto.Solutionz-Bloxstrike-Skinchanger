-- Seeto.Solutionz / Bloxstrike Skinchanger / Config
local HttpService = game:GetService("HttpService")

local Config = {
    -- Toggles
    ENABLED = true,
    KNIFE_SKINS_ENABLED = true,
    WEAPON_SKINS_ENABLED = true,

    -- Knife Customization
    KNIFE_MODEL = "Default",
    KNIFE_SKIN = "Stock",
    KNIFE_SKINS = {}, -- [knifeModelName] = "SkinName"

    -- Weapon Customization
    SKIN_MODE = "Stock", -- Global fallback: "Stock" | "Special" | "Random"
    SELECTED_WEAPON_TYPE = "AK-47",
    SELECTED_SKINS = {}, -- [weaponName] = "SkinName" or { Skin = "SkinName", Wear = "Factory New" }

    -- Keybinds & UI State
    TOGGLE_UI_KEY = Enum.KeyCode.Insert,
    UNLOAD_KEY = Enum.KeyCode.K,
    WINDOW_SIZE_X = 520,
    WINDOW_SIZE_Y = 420,

    -- Persistence
    SAVE_FILE = "Bloxstrike_Skinchanger.json"
}

local saveDebounce = nil

function Config.reset()
    Config.ENABLED = true
    Config.KNIFE_SKINS_ENABLED = true
    Config.WEAPON_SKINS_ENABLED = true
    Config.KNIFE_MODEL = "Default"
    Config.KNIFE_SKIN = "Stock"
    Config.KNIFE_SKINS = {}
    Config.SKIN_MODE = "Stock"
    Config.SELECTED_WEAPON_TYPE = "AK-47"
    Config.SELECTED_SKINS = {}
    Config.WINDOW_SIZE_X = 520
    Config.WINDOW_SIZE_Y = 420
    Config.save()
end

function Config.queueSave()
    if saveDebounce then
        task.cancel(saveDebounce)
    end
    saveDebounce = task.delay(0.35, function()
        Config.save()
        saveDebounce = nil
    end)
end

function Config.save()
    if type(writefile) ~= "function" then return end
    
    local exportData = {
        ENABLED = Config.ENABLED,
        KNIFE_SKINS_ENABLED = Config.KNIFE_SKINS_ENABLED,
        WEAPON_SKINS_ENABLED = Config.WEAPON_SKINS_ENABLED,
        KNIFE_MODEL = Config.KNIFE_MODEL,
        KNIFE_SKIN = Config.KNIFE_SKIN,
        KNIFE_SKINS = Config.KNIFE_SKINS or {},
        SKIN_MODE = Config.SKIN_MODE,
        SELECTED_WEAPON_TYPE = Config.SELECTED_WEAPON_TYPE,
        SELECTED_SKINS = Config.SELECTED_SKINS,
        WINDOW_SIZE_X = Config.WINDOW_SIZE_X or 440,
        WINDOW_SIZE_Y = Config.WINDOW_SIZE_Y or 210,
        TOGGLE_UI_KEY = Config.TOGGLE_UI_KEY and Config.TOGGLE_UI_KEY.Name or "Insert",
        UNLOAD_KEY = Config.UNLOAD_KEY and Config.UNLOAD_KEY.Name or "K"
    }

    pcall(function()
        local json = HttpService:JSONEncode(exportData)
        writefile(Config.SAVE_FILE, json)
    end)
end

function Config.load()
    if type(readfile) ~= "function" then return end

    local exists = false
    if type(isfile) == "function" then
        exists = isfile(Config.SAVE_FILE)
    else
        local okTest, dataTest = pcall(readfile, Config.SAVE_FILE)
        exists = okTest and (dataTest ~= nil and #dataTest > 0)
    end
    if not exists then return end

    pcall(function()
        local raw = readfile(Config.SAVE_FILE)
        if raw and #raw > 0 then
            local data = HttpService:JSONDecode(raw)
            if type(data) == "table" then
                if data.ENABLED ~= nil then Config.ENABLED = (data.ENABLED == true) end
                if data.KNIFE_SKINS_ENABLED ~= nil then Config.KNIFE_SKINS_ENABLED = (data.KNIFE_SKINS_ENABLED == true) end
                if data.WEAPON_SKINS_ENABLED ~= nil then Config.WEAPON_SKINS_ENABLED = (data.WEAPON_SKINS_ENABLED == true) end
                if data.KNIFE_MODEL ~= nil then Config.KNIFE_MODEL = tostring(data.KNIFE_MODEL) end
                if data.KNIFE_SKIN ~= nil then Config.KNIFE_SKIN = tostring(data.KNIFE_SKIN) end
                if type(data.KNIFE_SKINS) == "table" then
                    Config.KNIFE_SKINS = data.KNIFE_SKINS
                end
                if data.SKIN_MODE ~= nil then Config.SKIN_MODE = tostring(data.SKIN_MODE) end
                if data.SELECTED_WEAPON_TYPE ~= nil then Config.SELECTED_WEAPON_TYPE = tostring(data.SELECTED_WEAPON_TYPE) end
                if type(data.SELECTED_SKINS) == "table" then
                    Config.SELECTED_SKINS = data.SELECTED_SKINS
                end
                if data.WINDOW_SIZE_X and tonumber(data.WINDOW_SIZE_X) then
                    Config.WINDOW_SIZE_X = tonumber(data.WINDOW_SIZE_X)
                end
                if data.WINDOW_SIZE_Y and tonumber(data.WINDOW_SIZE_Y) then
                    Config.WINDOW_SIZE_Y = tonumber(data.WINDOW_SIZE_Y)
                end
                if data.TOGGLE_UI_KEY and Enum.KeyCode[data.TOGGLE_UI_KEY] then
                    Config.TOGGLE_UI_KEY = Enum.KeyCode[data.TOGGLE_UI_KEY]
                end
                if data.UNLOAD_KEY and Enum.KeyCode[data.UNLOAD_KEY] then
                    Config.UNLOAD_KEY = Enum.KeyCode[data.UNLOAD_KEY]
                end
            end
        end
    end)
end

return Config
