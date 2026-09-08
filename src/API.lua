-- Seeto.Solutionz / Bloxstrike Skinchanger / Public API
local API = {}

local Config = nil
local Database = nil
local Engine = nil
local KnifeCatalog = nil
local GunCatalog = nil

function API.bind(cfg, db, eng, kc, gc)
    Config = cfg
    Database = db
    Engine = eng
    if kc then KnifeCatalog = kc end
    if gc then GunCatalog = gc end
end

function API.bindCatalogs(kc, gc)
    KnifeCatalog = kc
    GunCatalog = gc
end

-- Core lifecycle
function API.init(customConfig)
    if customConfig and type(customConfig) == "table" then
        for k, v in pairs(customConfig) do
            Config[k] = v
        end
    else
        Config.load()
    end
    Engine.init(Config, Database)
end

function API.cleanup()
    Engine.cleanup()
end

-- Toggles
function API.setEnabled(enabled)
    Config.ENABLED = (enabled ~= false)
    Config.save()
    Engine.refreshActiveViewmodels(Config)
end

function API.setKnifeEnabled(enabled)
    Config.KNIFE_SKINS_ENABLED = (enabled ~= false)
    Config.save()
    Engine.refreshActiveViewmodels(Config)
end

function API.setWeaponEnabled(enabled)
    Config.WEAPON_SKINS_ENABLED = (enabled ~= false)
    Config.save()
    Engine.refreshActiveViewmodels(Config)
end

-- Knife configuration
function API.setKnife(model, skin)
    if model then
        Config.KNIFE_MODEL = model
        if skin then
            if not Config.KNIFE_SKINS then Config.KNIFE_SKINS = {} end
            Config.KNIFE_SKINS[model] = skin
            Config.KNIFE_SKIN = skin
        else
            if Config.KNIFE_SKINS and Config.KNIFE_SKINS[model] then
                Config.KNIFE_SKIN = Config.KNIFE_SKINS[model]
            end
        end
    elseif skin then
        Config.KNIFE_SKIN = skin
        local currentModel = Config.KNIFE_MODEL or "Butterfly Knife"
        if not Config.KNIFE_SKINS then Config.KNIFE_SKINS = {} end
        Config.KNIFE_SKINS[currentModel] = skin
    end
    Config.save()
    Engine.refreshActiveViewmodels(Config)
end

function API.setKnifeModel(model)
    API.setKnife(model, nil)
end

function API.setKnifeSkin(skin)
    API.setKnife(nil, skin)
end

-- Weapon configuration
function API.setWeaponSkin(weaponName, skinName, wear)
    if not weaponName then return end
    if not Config.SELECTED_SKINS then Config.SELECTED_SKINS = {} end

    if wear then
        Config.SELECTED_SKINS[weaponName] = {
            Skin = skinName or "Special",
            Wear = wear or "Factory New"
        }
    else
        Config.SELECTED_SKINS[weaponName] = skinName or "Special"
    end

    Config.save()
    Engine.refreshActiveViewmodels(Config)
end

function API.getWeaponSkin(weaponName)
    if not weaponName or not Config.SELECTED_SKINS then return nil end
    return Config.SELECTED_SKINS[weaponName]
end

-- Batch configuration methods
function API.setAllSpecial()
    if not Config.SELECTED_SKINS then Config.SELECTED_SKINS = {} end
    for _, wp in ipairs(Database.WeaponTypes) do
        Config.SELECTED_SKINS[wp] = "Special"
    end
    Config.SKIN_MODE = "Special"
    Config.save()
    Engine.refreshActiveViewmodels(Config)
end

function API.setAllRandom()
    if not Config.SELECTED_SKINS then Config.SELECTED_SKINS = {} end
    for _, wp in ipairs(Database.WeaponTypes) do
        Config.SELECTED_SKINS[wp] = "Random"
    end
    Config.SKIN_MODE = "Random"
    Config.save()
    Engine.rerollRandomSkins(Config)
end

function API.setAllDefault()
    if not Config.SELECTED_SKINS then Config.SELECTED_SKINS = {} end
    for _, wp in ipairs(Database.WeaponTypes) do
        Config.SELECTED_SKINS[wp] = "Stock"
    end
    Config.save()
    Engine.refreshActiveViewmodels(Config)
end

function API.rerollRandom()
    Engine.rerollRandomSkins(Config)
end

function API.refresh()
    Engine.refreshActiveViewmodels(Config)
end

-- Query helpers
function API.getConfig()
    return Config
end

function API.getKnifeList()
    return Database.KnifeModels
end

function API.getWeaponList()
    return Database.WeaponTypes
end

function API.getKnifeSkins(knifeModel)
    return Database.getKnifeSkinList(knifeModel or Config.KNIFE_MODEL)
end

function API.getWeaponSkins(weaponName)
    return Database.getWeaponSkinList(weaponName or Config.SELECTED_WEAPON_TYPE)
end

function API.save()
    Config.save()
end

function API.load()
    Config.load()
end

function API.resetKnifeSkins()
    Config.KNIFE_MODEL = "Default"
    Config.KNIFE_SKIN = "Stock"
    Config.KNIFE_SKINS = {}
    Config.save()
    Engine.refreshActiveViewmodels(Config)
    if KnifeCatalog and KnifeCatalog.refresh then
        pcall(KnifeCatalog.refresh)
    end
end

function API.resetWeaponSkins()
    Config.SELECTED_SKINS = {}
    Config.SKIN_MODE = "Stock"
    Config.save()
    Engine.refreshActiveViewmodels(Config)
    if GunCatalog and GunCatalog.refresh then
        pcall(GunCatalog.refresh)
    end
end

function API.reset()
    Config.reset()
    Config.save()
    Engine.refreshActiveViewmodels(Config)
    if KnifeCatalog and KnifeCatalog.refresh then
        pcall(KnifeCatalog.refresh)
    end
    if GunCatalog and GunCatalog.refresh then
        pcall(GunCatalog.refresh)
    end
end

return API
