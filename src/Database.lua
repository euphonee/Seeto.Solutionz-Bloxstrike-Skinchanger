-- Seeto.Solutionz / Bloxstrike Skinchanger / Database
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = {}

Database.KnifeModels = {
    "Default",
    "Butterfly Knife",
    "Karambit",
    "M9 Bayonet",
    "Skeleton Knife",
    "Stiletto Knife",
    "Flip Knife",
    "Gut Knife",
    "LightSaber",
    "CT Knife",
    "T Knife"
}

Database.WeaponTypes = {
    "AK-47", "AUG", "AWP", "Desert Eagle", "Dual Berettas",
    "FAMAS", "Five-SeveN", "Galil AR", "Glock-18", "M4A1-S",
    "M4A4", "MAC-10", "MAG-7", "MP9", "Negev",
    "Nova", "P250", "P90", "R8 Revolver", "SG 553",
    "SSG 08", "Sawed-Off", "Tec-9", "USP-S", "XM1014", "Zeus x27"
}

Database.WearTiers = {
    "Factory New",
    "Minimal Wear",
    "Field-Tested",
    "Well-Worn",
    "Battle-Scarred"
}

Database.TopTierSkins = {
    -- Knives
    ["Butterfly Knife"] = "Fade",
    ["Karambit"]        = "Fade",
    ["M9 Bayonet"]      = "Fade",
    ["Skeleton Knife"]  = "Fade",
    ["Stiletto Knife"]  = "Whiteout",
    ["Flip Knife"]      = "Fade",
    ["Gut Knife"]       = "Fade",
    ["LightSaber"]      = "Ren",
    ["CT Knife"]        = "Lebron James",
    ["T Knife"]         = "Vanilla",

    -- Rifles
    ["AK-47"]           = "Midas",
    ["AWP"]             = "Lore",
    ["M4A4"]            = "The Ambassador",
    ["M4A1-S"]          = "Bloggd",
    ["SSG 08"]          = "Prototype",
    ["Galil AR"]        = "Limewire",
    ["FAMAS"]           = "Wallpaper",
    ["SG 553"]          = "Cryo",
    ["AUG"]             = "Hero of Hell",

    -- Pistols
    ["Desert Eagle"]    = "Lore",
    ["Glock-18"]        = "Fade",
    ["USP-S"]           = "SpecOps",
    ["Tec-9"]           = "Vice",
    ["P250"]            = "Zen",
    ["Five-SeveN"]      = "NoMercy",
    ["Dual Berettas"]   = "Overclock",
    ["R8 Revolver"]     = "Heatseeka",

    -- SMGs and Heavy
    ["MP9"]             = "Hibiki",
    ["MAC-10"]          = "Parcel",
    ["P90"]             = "Visions",
    ["UMP-45"]          = "Primal Saber",
    ["Nova"]            = "Mecha",
    ["XM1014"]          = "BloxoBlasto",
    ["MAG-7"]           = "Ambulance",
    ["Negev"]           = "Rotary Power",
    ["Sawed-Off"]       = "Memento"
}

function Database.getSkinsFolder()
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    if assets then
        return assets:FindFirstChild("Skins")
    end
    return nil
end

function Database.isKnife(weaponName)
    if typeof(weaponName) ~= "string" then return false end
    if weaponName == "Zeus x27" or weaponName:find("Zeus") or weaponName:find("Taser") then
        return false
    end
    if weaponName == "CT Knife" or weaponName == "T Knife" or weaponName == "Butterfly Knife" or weaponName:find("Knife") or weaponName:find("Bayonet") or weaponName:find("Karambit") or weaponName == "LightSaber" then
        return true
    end
    return false
end

function Database.isExemptUtility(weaponName)
    if typeof(weaponName) ~= "string" then return false end
    if weaponName == "Zeus x27" or weaponName:find("Grenade") or weaponName == "Molotov" or weaponName == "Flashbang" or weaponName == "C4" then
        return true
    end
    return false
end

function Database.getKnifeSkinList(knifeModel)
    if not knifeModel or knifeModel == "Default" then
        return { "Default" }
    end

    local list = { "Special", "Random" }
    local skinsFolder = Database.getSkinsFolder()
    local folder = skinsFolder and skinsFolder:FindFirstChild(knifeModel)

    if folder then
        local names = {}
        for _, child in ipairs(folder:GetChildren()) do
            table.insert(names, child.Name)
        end
        table.sort(names, function(a, b)
            if a == "Vanilla" or a == "Stock" then return true end
            if b == "Vanilla" or b == "Stock" then return false end
            return a:lower() < b:lower()
        end)
        for _, name in ipairs(names) do
            table.insert(list, name)
        end
    else
        table.insert(list, "Fade")
    end

    return list
end

function Database.getWeaponSkinList(weaponName)
    if not weaponName then
        return { "Special", "Random", "Stock" }
    end

    local list = { "Special", "Random", "Stock" }
    local skinsFolder = Database.getSkinsFolder()
    local folder = skinsFolder and skinsFolder:FindFirstChild(weaponName)

    if folder then
        local names = {}
        for _, child in ipairs(folder:GetChildren()) do
            if child.Name ~= "Stock" and child.Name ~= "Vanilla" and not child.Name:find("PATTERN") and child.Name ~= "Terrorists" and child.Name ~= "Counter-Terrorists" then
                table.insert(names, child.Name)
            end
        end
        table.sort(names, function(a, b)
            return a:lower() < b:lower()
        end)
        for _, name in ipairs(names) do
            table.insert(list, name)
        end
    end

    return list
end

return Database
