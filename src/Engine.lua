-- Seeto.Solutionz / Bloxstrike Skinchanger / Engine
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local WeaponComponent = require(ReplicatedStorage.Classes.WeaponComponent)
local SkinsLib = require(ReplicatedStorage.Database.Components.Libraries.Skins)

local GetWeaponProperties = nil
pcall(function()
    GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
end)

local CharacterAnimator = nil
pcall(function()
    CharacterAnimator = require(ReplicatedStorage.Classes.WeaponComponent.Classes.CharacterAnimator)
end)

local Sound = nil
pcall(function()
    Sound = require(ReplicatedStorage.Classes.Sound)
end)

local InventoryController = nil
pcall(function()
    InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
end)

local Database = nil
local Config = nil

local Engine = {
    Initialized = false,
    Connections = {},
    RandomCache = {},
    SelectedSkins = {}
}

local function isLocalPlayerAlive()
    local charsFolder = Workspace:FindFirstChild("Characters")
    local myChar = LocalPlayer.Character
    if not myChar or not charsFolder or myChar.Parent ~= charsFolder then
        return false
    end
    if myChar:GetAttribute("Dead") == true then
        return false
    end
    return true
end

local function isViewingLocalPlayer()
    if not isLocalPlayerAlive() then
        return false
    end
    local myChar = LocalPlayer.Character
    local subject = Camera.CameraSubject
    if not subject then
        return true
    end
    if subject == myChar or subject:IsDescendantOf(myChar) then
        return true
    end
    return false
end

function Engine.getKnifeSelection(cfg)
    cfg = cfg or Config
    if not (cfg and cfg.ENABLED ~= false and cfg.KNIFE_SKINS_ENABLED ~= false) then
        return nil, nil
    end

    local targetKnife = cfg.KNIFE_MODEL or "Butterfly Knife"
    if targetKnife == "Default" then
        return nil, nil
    end

    local skinSelection = (cfg.KNIFE_SKINS and cfg.KNIFE_SKINS[targetKnife]) or cfg.KNIFE_SKIN or "Special"
    local skinName = "Fade"
    local skinsFolder = Database.getSkinsFolder()

    if skinSelection == "Random" then
        if not Engine.RandomCache[targetKnife] then
            local folder = skinsFolder and skinsFolder:FindFirstChild(targetKnife)
            if folder then
                local validSkins = {}
                for _, s in ipairs(folder:GetChildren()) do
                    if s.Name ~= "Stock" and s.Name ~= "Vanilla" then
                        table.insert(validSkins, s.Name)
                    end
                end
                if #validSkins > 0 then
                    Engine.RandomCache[targetKnife] = validSkins[math.random(1, #validSkins)]
                else
                    Engine.RandomCache[targetKnife] = "Fade"
                end
            else
                Engine.RandomCache[targetKnife] = "Fade"
            end
        end
        skinName = Engine.RandomCache[targetKnife]
    elseif skinSelection == "Special" then
        skinName = Database.TopTierSkins[targetKnife] or "Fade"
    else
        local folder = skinsFolder and skinsFolder:FindFirstChild(targetKnife)
        if folder and folder:FindFirstChild(skinSelection) then
            skinName = skinSelection
        else
            skinName = Database.TopTierSkins[targetKnife] or "Fade"
        end
    end

    return targetKnife, skinName
end

function Engine.getValidSkin(weaponName, cfg)
    cfg = cfg or Config
    if not (cfg and cfg.ENABLED ~= false and cfg.WEAPON_SKINS_ENABLED ~= false) then
        return nil
    end

    local skinsFolder = Database.getSkinsFolder()
    if not skinsFolder or not weaponName or Database.isExemptUtility(weaponName) then
        return nil
    end

    local folder = skinsFolder:FindFirstChild(weaponName)
    if not folder then return nil end

    local custom = (cfg.SELECTED_SKINS and cfg.SELECTED_SKINS[weaponName]) or Engine.SelectedSkins[weaponName]
    local customSkinName = type(custom) == "table" and custom.Skin or custom

    if customSkinName then
        if customSkinName == "Stock" or customSkinName == "Default" or customSkinName == "Vanilla" then
            return nil
        elseif customSkinName == "Special" then
            local pref = Database.TopTierSkins[weaponName]
            if pref and folder:FindFirstChild(pref) then
                return pref, "Factory New"
            end
        elseif customSkinName == "Random" then
            if not Engine.RandomCache[weaponName] then
                local validSkins = {}
                for _, s in ipairs(folder:GetChildren()) do
                    if s.Name ~= "Stock" and s.Name ~= "Vanilla" and not s.Name:find("PATTERN") and s.Name ~= "Terrorists" and s.Name ~= "Counter-Terrorists" then
                        table.insert(validSkins, s.Name)
                    end
                end
                if #validSkins > 0 then
                    Engine.RandomCache[weaponName] = validSkins[math.random(1, #validSkins)]
                else
                    Engine.RandomCache[weaponName] = "Stock"
                end
            end
            return Engine.RandomCache[weaponName], "Factory New"
        elseif folder:FindFirstChild(customSkinName) then
            local wear = (type(custom) == "table" and custom.Wear) or "Factory New"
            return customSkinName, wear
        end
    end

    local skinMode = cfg.SKIN_MODE or "Stock"

    if skinMode == "Stock" or skinMode == "Default" then
        return nil
    elseif skinMode == "Random" then
        if not Engine.RandomCache[weaponName] then
            local validSkins = {}
            for _, s in ipairs(folder:GetChildren()) do
                if s.Name ~= "Stock" and s.Name ~= "Vanilla" and not s.Name:find("PATTERN") and s.Name ~= "Terrorists" and s.Name ~= "Counter-Terrorists" then
                    table.insert(validSkins, s.Name)
                end
            end
            if #validSkins > 0 then
                Engine.RandomCache[weaponName] = validSkins[math.random(1, #validSkins)]
            else
                Engine.RandomCache[weaponName] = "Stock"
            end
        end
        return Engine.RandomCache[weaponName], "Factory New"
    elseif skinMode == "Special" then
        local pref = Database.TopTierSkins[weaponName]
        if pref and folder:FindFirstChild(pref) then
            return pref, "Factory New"
        end
    end

    return nil
end

function Engine.applySkinToViewModel(viewmodel, weaponName, skinName, wear)
    local skinsFolder = Database.getSkinsFolder()
    if not skinsFolder or not viewmodel or not weaponName or Database.isExemptUtility(weaponName) then
        return false
    end

    local weaponFolder = skinsFolder:FindFirstChild(weaponName)
    if not weaponFolder then return false end

    local targetSkin = skinName or "Stock"
    local skin = weaponFolder:FindFirstChild(targetSkin)
    if not skin and targetSkin == "Stock" then
        skin = weaponFolder:FindFirstChild("Vanilla") or weaponFolder:GetChildren()[1]
    end
    if not skin then return false end

    local camFolder = skin:FindFirstChild("Camera") or skin
    local wearFolder = camFolder:FindFirstChild(wear or "Factory New") 
        or camFolder:FindFirstChild("Factory New")
        or camFolder:FindFirstChild("Minimal Wear")
        or camFolder:FindFirstChild("Field-Tested")
        or camFolder:GetChildren()[1]

    if not wearFolder then return false end

    pcall(function()
        for _, sa in ipairs(wearFolder:GetChildren()) do
            if sa:IsA("SurfaceAppearance") then
                local targetPart = viewmodel:FindFirstChild(sa.Name, true)
                if targetPart and (targetPart:IsA("MeshPart") or targetPart:IsA("BasePart")) then
                    local old = targetPart:FindFirstChildOfClass("SurfaceAppearance")
                    if old then pcall(function() old:Destroy() end) end

                    local clone = sa:Clone()
                    clone.Parent = targetPart
                end
            end
        end
    end)
    return true
end

function Engine.rerollRandomSkins(cfg)
    Engine.RandomCache = {}
    Engine.refreshActiveViewmodels(cfg or Config)
end

function Engine.getActiveLoadout()
    if not InventoryController then
        pcall(function()
            InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
        end)
    end
    if not InventoryController then return nil end

    if type(getupvalues) == "function" then
        for _, fnName in ipairs({"getCurrentEquipped", "removeInventoryItem", "getInventorySlot", "getCurrentInventory"}) do
            local fn = InventoryController[fnName]
            if type(fn) == "function" then
                local ok, uvs = pcall(getupvalues, fn)
                if ok and type(uvs) == "table" then
                    for _, uv in pairs(uvs) do
                        if type(uv) == "table" and rawget(uv, "Inventory") then
                            return uv
                        end
                    end
                end
            end
        end
    end
    return nil
end

function Engine.updateLiveKnife(cfg)
    cfg = cfg or Config
    if not isViewingLocalPlayer() then return false end

    local ld = Engine.getActiveLoadout()
    if not ld or not ld.Inventory then return false end

    local knifeSlot = ld.Inventory[3]
    if not knifeSlot or not knifeSlot._items then return false end

    local knifeItem = knifeSlot._items[1]
    if not knifeItem then return false end

    local knifeEnabled = (cfg and cfg.ENABLED ~= false and cfg.KNIFE_SKINS_ENABLED ~= false)
    local targetKnife, knifeSkin = Engine.getKnifeSelection(cfg)

    if not knifeEnabled or not targetKnife then
        local team = LocalPlayer:GetAttribute("Team")
        targetKnife = (team == "Terrorists") and "T Knife" or "CT Knife"
        knifeSkin = "Stock"
    end

    -- If knife is already this model and skin, keep it
    if knifeItem.Name == targetKnife and knifeItem.Skin == knifeSkin then
        return true
    end

    local wasEquipped = (ld.CurrentEquipped == knifeItem) or (knifeItem.Viewmodel and knifeItem.Viewmodel.IsEquipped == true)

    -- In-place mutation: preserve Identifier and _id so the server never rejects weapon equip packets
    knifeItem.Name = targetKnife
    knifeItem.Skin = knifeSkin

    if GetWeaponProperties then
        pcall(function()
            knifeItem.Properties = GetWeaponProperties(targetKnife) or knifeItem.Properties
        end)
    end

    if knifeItem.CharacterAnimator and CharacterAnimator then
        pcall(function()
            knifeItem.CharacterAnimator:destroy()
            knifeItem.CharacterAnimator = CharacterAnimator.new(LocalPlayer, targetKnife)
        end)
    end

    if knifeItem.Viewmodel then
        local vm = knifeItem.Viewmodel
        vm.Weapon = targetKnife
        vm.CameraModelWeapon = targetKnife
        vm.Skin = knifeSkin

        if Sound and Sound.new then
            pcall(function()
                if vm.Sound then vm.Sound:destroy() end
                vm.Sound = Sound.new(targetKnife)
                if vm.Animation then
                    vm.Animation.Sound = vm.Sound
                end
            end)
        end

        local char = LocalPlayer.Character
        if char then
            pcall(function()
                vm:construct(char, knifeItem)
            end)
        end

        if wasEquipped then
            pcall(function()
                vm:equip(false)
            end)
        end
    end

    -- Fire inventory changed signals to update HUD weapon icons and names
    pcall(function()
        local ic = InventoryController or require(ReplicatedStorage.Controllers.InventoryController)
        if ic then
            if ic.OnInventoryChanged then
                ic.OnInventoryChanged:Fire(ld.Inventory)
            end
            if wasEquipped and ic.OnInventoryItemEquipped then
                ic.OnInventoryItemEquipped:Fire(3, knifeItem)
            end
        end
    end)

    return true
end

function Engine.refreshActiveViewmodels(cfg)
    cfg = cfg or Config
    if not isViewingLocalPlayer() then return end
    if not (cfg and cfg.ENABLED ~= false) then return end

    -- Live update knife model in active loadout immediately
    pcall(function()
        Engine.updateLiveKnife(cfg)
    end)

    local knifeEnabled = (cfg.KNIFE_SKINS_ENABLED ~= false)
    local weaponEnabled = (cfg.WEAPON_SKINS_ENABLED ~= false)

    for _, child in ipairs(Camera:GetChildren()) do
        if child:IsA("Model") and (child:FindFirstChild("Weapon") or child:FindFirstChild("WeaponL") or child:FindFirstChild("WeaponR")) then
            local weaponName = child.Name
            if not Database.isExemptUtility(weaponName) then
                if Database.isKnife(weaponName) then
                    if knifeEnabled then
                        local targetKnife, knifeSkin = Engine.getKnifeSelection(cfg)
                        if targetKnife and knifeSkin and weaponName == targetKnife then
                            Engine.applySkinToViewModel(child, targetKnife, knifeSkin, "Factory New")
                        else
                            Engine.applySkinToViewModel(child, weaponName, "Stock", "Factory New")
                        end
                    else
                        Engine.applySkinToViewModel(child, weaponName, "Stock", "Factory New")
                    end
                else
                    if weaponEnabled then
                        local skinName, wear = Engine.getValidSkin(weaponName, cfg)
                        if skinName then
                            Engine.applySkinToViewModel(child, weaponName, skinName, wear)
                        else
                            Engine.applySkinToViewModel(child, weaponName, "Stock", "Factory New")
                        end
                    else
                        Engine.applySkinToViewModel(child, weaponName, "Stock", "Factory New")
                    end
                end
            end
        end
    end
end

local originalWeaponNew = nil
local originalGetCameraModel = nil
local originalGetCharacterModel = nil

function Engine.init(cfg, db)
    Config = cfg
    Database = db

    if Engine.Initialized then return end
    Engine.Initialized = true

    if not _G.__originalWeaponComponentNew then
        _G.__originalWeaponComponentNew = WeaponComponent.new
    end
    originalWeaponNew = _G.__originalWeaponComponentNew

    if not _G.__originalGetCameraModel then
        _G.__originalGetCameraModel = SkinsLib.GetCameraModel
    end
    originalGetCameraModel = _G.__originalGetCameraModel

    if not _G.__originalGetCharacterModel then
        _G.__originalGetCharacterModel = SkinsLib.GetCharacterModel
    end
    originalGetCharacterModel = _G.__originalGetCharacterModel

    -- Knife component hook
    WeaponComponent.new = function(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, ...)
        local knifeEnabled = (Config.ENABLED ~= false and Config.KNIFE_SKINS_ENABLED ~= false)
        if not knifeEnabled or p1 ~= LocalPlayer or not isLocalPlayerAlive() then
            return originalWeaponNew(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, ...)
        end

        if Database.isKnife(p5, p4) then
            local targetKnife, skinName = Engine.getKnifeSelection(Config)
            if targetKnife then
                return originalWeaponNew(p1, p2, p3, p4, targetKnife, skinName, 0.001, p8, p9, p10, p11, p12, ...)
            end
        end

        return originalWeaponNew(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, ...)
    end

    -- Knife viewmodel model hook
    SkinsLib.GetCameraModel = function(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
        local knifeEnabled = (Config.ENABLED ~= false and Config.KNIFE_SKINS_ENABLED ~= false)
        if not knifeEnabled or not isViewingLocalPlayer() then
            return originalGetCameraModel(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
        end

        if Database.isKnife(weaponName) then
            local targetKnife, knifeSkin = Engine.getKnifeSelection(Config)
            if targetKnife then
                local model = originalGetCameraModel(targetKnife, knifeSkin, 0.001, statTrack, nameTag, charm, stickers, team)
                if model then
                    model.Name = targetKnife
                end
                return model
            end
        end

        return originalGetCameraModel(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
    end

    SkinsLib.GetCharacterModel = function(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
        return originalGetCharacterModel(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
    end

    -- Real-time gun texture hook on camera child added
    local cameraConn = Camera.ChildAdded:Connect(function(child)
        local weaponEnabled = (Config.ENABLED ~= false and Config.WEAPON_SKINS_ENABLED ~= false)
        if not weaponEnabled or not isViewingLocalPlayer() then return end

        if child:IsA("Model") and (child:FindFirstChild("Weapon") or child:FindFirstChild("WeaponL") or child:FindFirstChild("WeaponR")) then
            local weaponName = child.Name
            if not Database.isExemptUtility(weaponName) and not Database.isKnife(weaponName) then
                task.defer(function()
                    task.wait(0.04)
                    local currentEnabled = (Config.ENABLED ~= false and Config.WEAPON_SKINS_ENABLED ~= false)
                    if currentEnabled and isViewingLocalPlayer() then
                        local skinName, wear = Engine.getValidSkin(weaponName, Config)
                        if skinName then
                            Engine.applySkinToViewModel(child, weaponName, skinName, wear)
                        end
                    end
                end)
            end
        end
    end)
    table.insert(Engine.Connections, cameraConn)

    -- Character & Round listener
    local function onRoundChange()
        if Config.ENABLED == false then return end
        Engine.RandomCache = {}
        task.delay(0.25, function()
            if Config.ENABLED ~= false then
                Engine.refreshActiveViewmodels(Config)
            end
        end)
    end

    local charSpawnConn = LocalPlayer.CharacterAdded:Connect(function(char)
        onRoundChange()
    end)
    table.insert(Engine.Connections, charSpawnConn)

    local nr = ReplicatedStorage:FindFirstChild("NetworkRemotes")
    if nr and nr:FindFirstChild("UI") and nr.UI:FindFirstChild("RoundWinner") then
        local roundEndConn = nr.UI.RoundWinner.OnClientEvent:Connect(function()
            onRoundChange()
        end)
        table.insert(Engine.Connections, roundEndConn)
    end

    Engine.refreshActiveViewmodels(Config)
end

function Engine.cleanup()
    for _, c in ipairs(Engine.Connections) do
        pcall(function() c:Disconnect() end)
    end
    Engine.Connections = {}

    if originalWeaponNew then
        WeaponComponent.new = originalWeaponNew
    end
    if originalGetCameraModel then
        SkinsLib.GetCameraModel = originalGetCameraModel
    end
    if originalGetCharacterModel then
        SkinsLib.GetCharacterModel = originalGetCharacterModel
    end

    originalWeaponNew = nil
    originalGetCameraModel = nil
    originalGetCharacterModel = nil
    _G.__originalWeaponComponentNew = nil
    _G.__originalGetCameraModel = nil
    _G.__originalGetCharacterModel = nil
    Engine.RandomCache = {}
    Engine.Initialized = false
end

return Engine
