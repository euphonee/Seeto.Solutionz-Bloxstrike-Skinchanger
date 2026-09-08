-- Seeto.Solutionz / Bloxstrike Skinchanger / UIManager
local Database = nil
local KnifeCatalog = nil
local GunCatalog = nil

local function getDatabase()
    if Database then return Database end
    if type(readfile) == "function" then
        local paths = {
            "Seeto.Solutionz-Bloxstrike-Skinchanger/src/Database.lua",
            "Bloxstrike-Skinchanger/src/Database.lua",
            "src/Database.lua",
            "Database.lua"
        }
        for _, p in ipairs(paths) do
            local ok, content = pcall(readfile, p)
            if ok and content then
                local fn = loadstring(content)
                if fn then
                    Database = fn()
                    return Database
                end
            end
        end
    end
    local okHttp, content = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/euphonee/Seeto.Solutionz-Bloxstrike-Skinchanger/main/src/Database.lua?t=" .. tostring(os.time()))
    end)
    if okHttp and content then
        local fn = loadstring(content)
        if fn then
            Database = fn()
            return Database
        end
    end
    return nil
end

local function getKnifeCatalog()
    if KnifeCatalog then return KnifeCatalog end
    if type(readfile) == "function" then
        local paths = {
            "Seeto.Solutionz-Bloxstrike-Skinchanger/src/KnifeCatalog.lua",
            "Bloxstrike-Skinchanger/src/KnifeCatalog.lua",
            "src/KnifeCatalog.lua",
            "KnifeCatalog.lua"
        }
        for _, p in ipairs(paths) do
            local ok, content = pcall(readfile, p)
            if ok and content then
                local fn = loadstring(content)
                if fn then
                    KnifeCatalog = fn()
                    return KnifeCatalog
                end
            end
        end
    end
    local okHttp, content = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/euphonee/Seeto.Solutionz-Bloxstrike-Skinchanger/main/src/KnifeCatalog.lua?t=" .. tostring(os.time()))
    end)
    if okHttp and content then
        local fn = loadstring(content)
        if fn then
            KnifeCatalog = fn()
            return KnifeCatalog
        end
    end
    return nil
end

local function getGunCatalog()
    if GunCatalog then return GunCatalog end
    if type(readfile) == "function" then
        local paths = {
            "Seeto.Solutionz-Bloxstrike-Skinchanger/src/GunCatalog.lua",
            "Bloxstrike-Skinchanger/src/GunCatalog.lua",
            "src/GunCatalog.lua",
            "GunCatalog.lua"
        }
        for _, p in ipairs(paths) do
            local ok, content = pcall(readfile, p)
            if ok and content then
                local fn = loadstring(content)
                if fn then
                    GunCatalog = fn()
                    return GunCatalog
                end
            end
        end
    end
    local okHttp, content = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/euphonee/Seeto.Solutionz-Bloxstrike-Skinchanger/main/src/GunCatalog.lua?t=" .. tostring(os.time()))
    end)
    if okHttp and content then
        local fn = loadstring(content)
        if fn then
            GunCatalog = fn()
            return GunCatalog
        end
    end
    return nil
end

local UIManager = {
    Initialized = false,
    Library = nil,
    Window = nil,
    Tabs = {}
}

function UIManager.bindCatalog(kc, gc)
    KnifeCatalog = kc
    if gc then GunCatalog = gc end
end

function UIManager.bindCatalogs(kc, gc)
    KnifeCatalog = kc
    GunCatalog = gc
end

function UIManager.init(Config, Library, API, Db, unloadCallback)
    if type(API) == "function" and Db == nil then
        unloadCallback = API
        API = nil
        Db = nil
    elseif type(Db) == "function" and unloadCallback == nil then
        unloadCallback = Db
        Db = nil
    end

    Database = Db or Database or getDatabase()
    KnifeCatalog = KnifeCatalog or getKnifeCatalog()
    GunCatalog = GunCatalog or getGunCatalog()

    if UIManager.Initialized then return end
    UIManager.Initialized = true
    UIManager.Library = Library

    -- Apply theme if available
    if Config.UI_THEME then
        for prop, val in pairs(Config.UI_THEME) do
            if Library[prop] ~= nil then
                Library[prop] = val
            end
        end
    end

    -- Create Window (sized for catalog view)
    local defaultW = Config.WINDOW_SIZE_X or 620
    local defaultH = Config.WINDOW_SIZE_Y or 390
    if defaultW < 560 then defaultW = 620 end
    if defaultH < 340 then defaultH = 390 end

    local Window = Library:CreateWindow({
        Title = "Seeto.SolutionZ / Bloxstrike Skinchanger",
        Center = true,
        AutoShow = true,
        TabPadding = 6,
        MenuFadeTime = 0.2,
        Size = UDim2.fromOffset(defaultW, defaultH),
        MinWidth = 520,
        MinHeight = 320,
        ToggleKey = Config.TOGGLE_UI_KEY or Enum.KeyCode.Insert,
        UnloadKey = Config.UNLOAD_KEY or Enum.KeyCode.K,
        CloseCallback = unloadCallback,
        ResizeCallback = function(w, h)
            if Config.WINDOW_SIZE_X ~= w or Config.WINDOW_SIZE_Y ~= h then
                Config.WINDOW_SIZE_X = w
                Config.WINDOW_SIZE_Y = h
                if Config.queueSave then Config.queueSave() else Config.save() end
            end
        end
    })
    UIManager.Window = Window

    -- Add Tabs: Knife, Guns, Settings
    local Tabs = {
        Knife = Window:AddTab("Knife"),
        Guns = Window:AddTab("Guns"),
        Settings = Window:AddTab("Settings")
    }
    UIManager.Tabs = Tabs

    -- 1. Initialize Visual Knife Catalog in Knife Tab
    if KnifeCatalog and KnifeCatalog.init then
        KnifeCatalog.init(Tabs.Knife, Config, API, Library, Database)
    end

    -- 2. Initialize Visual Gun Catalog in Guns Tab
    if GunCatalog and GunCatalog.init then
        GunCatalog.init(Tabs.Guns, Config, API, Library, Database)
    end

    -- 3. Initialize Settings Tab with Reset Buttons
    local ResetGroup = Tabs.Settings:AddLeftGroupbox("Reset Skins")
    local MenuConfigGroup = Tabs.Settings:AddRightGroupbox("Menu & State")

    ResetGroup:AddButton({
        Text = "Reset knife skins to default",
        Func = function()
            if API and API.resetKnifeSkins then
                API.resetKnifeSkins()
            else
                Config.KNIFE_MODEL = "Default"
                Config.KNIFE_SKIN = "Stock"
                Config.KNIFE_SKINS = {}
                if Config.queueSave then Config.queueSave() else Config.save() end
                if API and API.refresh then API.refresh() end
            end
            if KnifeCatalog and KnifeCatalog.refresh then
                pcall(KnifeCatalog.refresh)
            end
            Library:Notify("Reset all knife skins to default", 2)
        end,
        DoubleClick = false,
        Tooltip = "Resets your knife model and all custom knife skins to stock appearance"
    })

    ResetGroup:AddButton({
        Text = "Reset weapon skins to default",
        Func = function()
            if API and API.resetWeaponSkins then
                API.resetWeaponSkins()
            else
                Config.SELECTED_SKINS = {}
                Config.SKIN_MODE = "Stock"
                if Config.queueSave then Config.queueSave() else Config.save() end
                if API and API.refresh then API.refresh() end
            end
            if GunCatalog and GunCatalog.refresh then
                pcall(GunCatalog.refresh)
            end
            Library:Notify("Reset all weapon skins to default", 2)
        end,
        DoubleClick = false,
        Tooltip = "Resets all gun and firearm skins to stock appearance"
    })

    MenuConfigGroup:AddLabel("Toggle UI: Insert / RightShift")
    MenuConfigGroup:AddButton({
        Text = "Unload Skinchanger",
        Func = function()
            if unloadCallback then
                unloadCallback()
            elseif Library and Library.Unload then
                Library:Unload()
            end
        end,
        DoubleClick = true,
        Tooltip = "Double-click to unload the skinchanger"
    })

    -- Focus first tab
    Tabs.Knife:ShowTab()
end

function UIManager.cleanup()
    if KnifeCatalog and KnifeCatalog.cleanup then
        pcall(KnifeCatalog.cleanup)
    end
    if GunCatalog and GunCatalog.cleanup then
        pcall(GunCatalog.cleanup)
    end
    if UIManager.Library and UIManager.Library.Unload then
        pcall(function() UIManager.Library:Unload() end)
    end
    UIManager.Initialized = false
    UIManager.Library = nil
    UIManager.Window = nil
    UIManager.Tabs = {}
end

return UIManager
