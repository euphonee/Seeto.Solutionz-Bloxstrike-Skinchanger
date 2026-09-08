-- Seeto.Solutionz / Bloxstrike Skinchanger / GunCatalog
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SkinsLib = nil
pcall(function()
    SkinsLib = require(ReplicatedStorage.Database.Components.Libraries.Skins)
end)

local GunCatalog = {
    Initialized = false,
    CurrentView = "Models", -- "Models" | "Skins"
    ActiveGun = "AK-47",
    Connections = {},
    ViewportCleanups = {}
}

local RarityColors = {
    Special   = Color3.fromRGB(255, 215, 0),   -- Gold / Yellow
    Forbidden = Color3.fromRGB(255, 140, 0),   -- Contraband / Gold-Orange
    Red       = Color3.fromRGB(235, 75, 75),    -- Covert
    Pink      = Color3.fromRGB(211, 44, 230),   -- Classified
    Purple    = Color3.fromRGB(136, 71, 255),   -- Restricted
    Blue      = Color3.fromRGB(75, 106, 255),   -- Mil-Spec
    Stock     = Color3.fromRGB(150, 155, 165),  -- Stock / Default
}

local function getRarityColor(weaponName, skinName)
    if skinName == "Stock" or skinName == "Default" or skinName == "Vanilla" then
        return RarityColors.Stock
    end
    if skinName == "Special" or skinName == "Random" then
        return RarityColors.Special
    end
    if SkinsLib and SkinsLib.GetSkinInformation then
        local ok, info = pcall(function()
            return SkinsLib.GetSkinInformation(weaponName, skinName)
        end)
        if ok and info and info.rarity and RarityColors[info.rarity] then
            return RarityColors[info.rarity]
        end
    end
    return RarityColors.Blue
end

local function cleanupViewports()
    for _, fn in ipairs(GunCatalog.ViewportCleanups) do
        pcall(fn)
    end
    GunCatalog.ViewportCleanups = {}
end

local function setupGunViewport(viewportFrame, weaponName, skinName)
    viewportFrame:ClearAllChildren()
    if not SkinsLib then return nil end

    local model = nil
    local trySkins = { skinName, "Stock", "Vanilla", "Fade", "Midas", "Lore" }
    for _, s in ipairs(trySkins) do
        if s and s ~= "Random" and s ~= "Special" then
            local ok, m = pcall(function()
                return SkinsLib.GetCharacterModel(weaponName, s, 0.001)
            end)
            if ok and m then
                model = m
                break
            end
        end
    end

    if not model then
        pcall(function()
            model = SkinsLib.GetCharacterModel(weaponName, "Stock", 0.001)
        end)
    end

    if not model then return nil end

    local clone = nil
    local cloneOk, cloneRes = pcall(function()
        return model:Clone()
    end)
    if cloneOk and cloneRes then
        clone = cloneRes
    else
        clone = model
    end

    if not clone then return nil end
    clone.Parent = viewportFrame

    local cf, sz = clone:GetBoundingBox()
    local maxDim = math.max(sz.X, sz.Y, sz.Z, 0.5)
    -- Camera placed 40% closer (0.81 factor)
    local dist = maxDim * 0.81

    local camera = Instance.new("Camera")
    camera.FieldOfView = 50
    local camPos = cf.Position + Vector3.new(dist * 0.75, dist * 0.35, dist * 0.8)
    camera.CFrame = CFrame.new(camPos, cf.Position)
    camera.Parent = viewportFrame

    viewportFrame.CurrentCamera = camera
    viewportFrame.LightColor = Color3.fromRGB(245, 245, 255)
    viewportFrame.Ambient = Color3.fromRGB(150, 150, 160)
    viewportFrame.LightDirection = Vector3.new(-1, -1.2, -1).Unit

    -- Hover turntable rotation
    local rotConn = nil
    local isHovered = false
    local currentAngle = 0

    local function onStep(dt)
        if isHovered and clone and clone.Parent and camera and camera.Parent then
            currentAngle = currentAngle + dt * 1.8
            local rotatedOffset = CFrame.Angles(0, currentAngle, 0) * Vector3.new(dist * 0.75, dist * 0.35, dist * 0.8)
            camera.CFrame = CFrame.new(cf.Position + rotatedOffset, cf.Position)
        end
    end

    rotConn = RunService.RenderStepped:Connect(onStep)
    table.insert(GunCatalog.ViewportCleanups, function()
        if rotConn then pcall(function() rotConn:Disconnect() end) end
    end)

    return {
        setHover = function(hovered)
            isHovered = hovered
            if not hovered and camera and camera.Parent then
                camera.CFrame = CFrame.new(camPos, cf.Position)
                currentAngle = 0
            end
        end
    }
end

function GunCatalog.init(Tab, Config, API, Library, Database)
    if GunCatalog.Initialized then return end
    GunCatalog.Initialized = true

    -- Hide default Linoria dual scrolling frames
    if Tab.LeftSide then Tab.LeftSide.Visible = false end
    if Tab.RightSide then Tab.RightSide.Visible = false end

    local TabFrame = Tab.TabFrame
    if not TabFrame then return end

    -- Master Container
    local MainContainer = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 6, 0, 6),
        Size = UDim2.new(1, -12, 1, -12),
        ZIndex = 2,
        Parent = TabFrame
    })

    -- 1. Gun Model Catalog View
    local ModelView = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Visible = true,
        ZIndex = 2,
        Parent = MainContainer
    })

    -- Gun View Header
    local ModelHeader = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 26),
        ZIndex = 3,
        Parent = ModelView
    })
    Library:AddToRegistry(ModelHeader, {
        BackgroundColor3 = 'BackgroundColor',
        BorderColor3 = 'OutlineColor'
    })

    local ModelTitle = Library:CreateLabel({
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Text = "Gun Models",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
        Parent = ModelHeader
    })

    local ModelHint = Library:CreateLabel({
        Position = UDim2.new(0.4, 0, 0, 0),
        Size = UDim2.new(0.6, -8, 1, 0),
        Text = "Click any gun to view and select skins",
        TextColor3 = Color3.fromRGB(160, 160, 170),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 4,
        Parent = ModelHeader
    })

    -- Gun Grid Scroll Frame (136 x 148)
    local ModelScroll = Library:Create('ScrollingFrame', {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 1, -32),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
        TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.AccentColor,
        ZIndex = 3,
        Parent = ModelView
    })
    Library:AddToRegistry(ModelScroll, { ScrollBarImageColor3 = 'AccentColor' })

    local ModelGrid = Library:Create('UIGridLayout', {
        CellSize = UDim2.fromOffset(136, 148),
        CellPadding = UDim2.fromOffset(8, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ModelScroll
    })

    ModelGrid:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
        ModelScroll.CanvasSize = UDim2.fromOffset(0, ModelGrid.AbsoluteContentSize.Y + 12)
    end)

    -- 2. Skin Catalog View
    local SkinView = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = 2,
        Parent = MainContainer
    })

    -- Skin View Header
    local SkinHeader = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 26),
        ZIndex = 3,
        Parent = SkinView
    })
    Library:AddToRegistry(SkinHeader, {
        BackgroundColor3 = 'BackgroundColor',
        BorderColor3 = 'OutlineColor'
    })

    local BackButton = Library:Create('TextButton', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 4, 0, 3),
        Size = UDim2.new(0, 110, 0, 20),
        Text = "< Back to Guns",
        TextColor3 = Library.FontColor,
        TextSize = 12,
        Font = Library.Font,
        ZIndex = 4,
        Parent = SkinHeader
    })
    Library:AddToRegistry(BackButton, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
        TextColor3 = 'FontColor'
    })

    local SkinTitle = Library:CreateLabel({
        Position = UDim2.new(0, 122, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Text = "AK-47 / Skins",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
        Parent = SkinHeader
    })

    local SkinHint = Library:CreateLabel({
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0.5, -8, 1, 0),
        Text = "Left-Click: Test / Equip  |  Right-Click: Equip & Return",
        TextColor3 = Color3.fromRGB(160, 160, 170),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 4,
        Parent = SkinHeader
    })

    -- Skin Grid Scroll Frame (136 x 148)
    local SkinScroll = Library:Create('ScrollingFrame', {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 1, -32),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
        TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.AccentColor,
        ZIndex = 3,
        Parent = SkinView
    })
    Library:AddToRegistry(SkinScroll, { ScrollBarImageColor3 = 'AccentColor' })

    local SkinGrid = Library:Create('UIGridLayout', {
        CellSize = UDim2.fromOffset(136, 148),
        CellPadding = UDim2.fromOffset(8, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = SkinScroll
    })

    SkinGrid:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
        SkinScroll.CanvasSize = UDim2.fromOffset(0, SkinGrid.AbsoluteContentSize.Y + 12)
    end)

    -- Forward declarations
    local renderModelCards = nil
    local renderSkinCards = nil

    local function showModelView()
        GunCatalog.CurrentView = "Models"
        SkinView.Visible = false
        ModelView.Visible = true
        renderModelCards()
    end

    local function showSkinView(weaponName)
        GunCatalog.CurrentView = "Skins"
        GunCatalog.ActiveGun = weaponName
        SkinTitle.Text = weaponName .. " / Skins"
        ModelView.Visible = false
        SkinView.Visible = true
        renderSkinCards(weaponName)
    end

    BackButton.MouseButton1Click:Connect(function()
        showModelView()
    end)

    -- Render Gun Model Cards (136 x 148)
    renderModelCards = function()
        for _, child in ipairs(ModelScroll:GetChildren()) do
            if not child:IsA('UIGridLayout') then
                child:Destroy()
            end
        end
        cleanupViewports()

        for idx, weaponName in ipairs(Database.WeaponTypes) do
            local saved = Config.SELECTED_SKINS and Config.SELECTED_SKINS[weaponName]
            local currentSkin = (type(saved) == "table" and saved.Skin) or saved
            if not currentSkin or currentSkin == "Default" then
                if Config.SKIN_MODE == "Special" then
                    currentSkin = Database.TopTierSkins[weaponName] or "Stock"
                elseif Config.SKIN_MODE == "Random" then
                    currentSkin = "Random"
                else
                    currentSkin = "Stock"
                end
            end

            local rarityColor = getRarityColor(weaponName, currentSkin)
            local isCustomEquipped = (currentSkin ~= "Stock" and currentSkin ~= "Default" and currentSkin ~= "Vanilla")

            local Card = Library:Create('TextButton', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = isCustomEquipped and Library.AccentColor or Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.fromOffset(136, 148),
                LayoutOrder = idx,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 4,
                Parent = ModelScroll
            })

            -- Accent indicator line at top of card
            local CardTopAccent = Library:Create('Frame', {
                BackgroundColor3 = isCustomEquipped and Library.AccentColor or Color3.fromRGB(40, 40, 45),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 5,
                Parent = Card
            })

            -- Rarity Gradient (smooth gradient rising from bottom third)
            local RarityGradientFrame = Library:Create('Frame', {
                BackgroundColor3 = rarityColor,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 4,
                Parent = Card
            })

            local Grad = Instance.new('UIGradient')
            Grad.Rotation = 90
            Grad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.67, 1),
                NumberSequenceKeypoint.new(1, 0.3)
            })
            Grad.Parent = RarityGradientFrame

            -- 3D Viewport (Height = 100px)
            local Viewport = Library:Create('ViewportFrame', {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 2, 0, 4),
                Size = UDim2.new(1, -4, 0, 100),
                ZIndex = 5,
                Parent = Card
            })

            local vpController = setupGunViewport(Viewport, weaponName, currentSkin)

            -- Gun Title Label (25% bigger: size 15)
            local TitleLabel = Library:CreateLabel({
                Position = UDim2.new(0, 4, 0, 104),
                Size = UDim2.new(1, -8, 0, 20),
                Text = weaponName,
                TextSize = 15,
                TextColor3 = Library.FontColor,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 6,
                Parent = Card
            })

            -- Gun Subtitle / Badge (25% bigger: size 13)
            local SubLabel = Library:CreateLabel({
                Position = UDim2.new(0, 4, 0, 126),
                Size = UDim2.new(1, -8, 0, 18),
                Text = "[" .. tostring(currentSkin) .. "]",
                TextSize = 13,
                TextColor3 = (currentSkin ~= "Stock") and Color3.fromRGB(220, 220, 230) or Color3.fromRGB(140, 140, 150),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 6,
                Parent = Card
            })

            -- Hover effects
            Card.MouseEnter:Connect(function()
                if vpController then vpController.setHover(true) end
                Card.BorderColor3 = Color3.fromRGB(100, 105, 120)
            end)

            Card.MouseLeave:Connect(function()
                if vpController then vpController.setHover(false) end
                Card.BorderColor3 = Library.OutlineColor
            end)

            -- Click: Open Skins Catalog for this weapon
            Card.MouseButton1Click:Connect(function()
                showSkinView(weaponName)
            end)

            Card.MouseButton2Click:Connect(function()
                showSkinView(weaponName)
            end)
        end
    end

    -- Render Gun Skin Cards (136 x 148)
    renderSkinCards = function(weaponName)
        for _, child in ipairs(SkinScroll:GetChildren()) do
            if not child:IsA('UIGridLayout') then
                child:Destroy()
            end
        end
        cleanupViewports()

        local saved = Config.SELECTED_SKINS and Config.SELECTED_SKINS[weaponName]
        local activeSkin = (type(saved) == "table" and saved.Skin) or saved
        if not activeSkin or activeSkin == "Default" then
            if Config.SKIN_MODE == "Special" then
                activeSkin = Database.TopTierSkins[weaponName] or "Stock"
            elseif Config.SKIN_MODE == "Random" then
                activeSkin = "Random"
            else
                activeSkin = "Stock"
            end
        end

        local skinList = Database.getWeaponSkinList(weaponName)

        for idx, skinName in ipairs(skinList) do
            local isSelected = (activeSkin == skinName)
            local rarityColor = getRarityColor(weaponName, skinName)

            local Card = Library:Create('TextButton', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = isSelected and Library.AccentColor or Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.fromOffset(136, 148),
                LayoutOrder = idx,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 4,
                Parent = SkinScroll
            })

            -- Accent indicator line at top of card
            local CardTopAccent = Library:Create('Frame', {
                BackgroundColor3 = isSelected and Library.AccentColor or Color3.fromRGB(40, 40, 45),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 5,
                Parent = Card
            })

            -- Rarity Gradient (smooth gradient rising from bottom third)
            local RarityGradientFrame = Library:Create('Frame', {
                BackgroundColor3 = rarityColor,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 4,
                Parent = Card
            })

            local Grad = Instance.new('UIGradient')
            Grad.Rotation = 90
            Grad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.67, 1),
                NumberSequenceKeypoint.new(1, 0.3)
            })
            Grad.Parent = RarityGradientFrame

            -- 3D Viewport (Height = 104px)
            local Viewport = Library:Create('ViewportFrame', {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 2, 0, 4),
                Size = UDim2.new(1, -4, 0, 104),
                ZIndex = 5,
                Parent = Card
            })

            local displaySkin = skinName
            if skinName == "Special" then
                displaySkin = Database.TopTierSkins[weaponName] or "Stock"
            elseif skinName == "Random" then
                displaySkin = "Stock"
            end

            local vpController = setupGunViewport(Viewport, weaponName, displaySkin)

            -- Skin Title Label (25% bigger: size 15)
            local TitleLabel = Library:CreateLabel({
                Position = UDim2.new(0, 4, 0, 108),
                Size = UDim2.new(1, -8, 0, 20),
                Text = skinName,
                TextSize = 15,
                TextColor3 = isSelected and Library.AccentColor or Library.FontColor,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 6,
                Parent = Card
            })

            -- Badge Label (25% bigger: size 13)
            local SubLabel = Library:CreateLabel({
                Position = UDim2.new(0, 4, 0, 128),
                Size = UDim2.new(1, -8, 0, 18),
                Text = isSelected and "[Equipped]" or "Click to Select",
                TextSize = 13,
                TextColor3 = isSelected and Library.AccentColor or Color3.fromRGB(130, 130, 140),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 6,
                Parent = Card
            })

            -- Hover effects
            Card.MouseEnter:Connect(function()
                if vpController then vpController.setHover(true) end
                if not isSelected then
                    Card.BorderColor3 = Color3.fromRGB(100, 105, 120)
                end
            end)

            Card.MouseLeave:Connect(function()
                if vpController then vpController.setHover(false) end
                if not isSelected then
                    Card.BorderColor3 = Library.OutlineColor
                end
            end)

            -- Left-Click: Test / Equip skin in place (remain in skin catalog)
            Card.MouseButton1Click:Connect(function()
                API.setWeaponSkin(weaponName, skinName)
                Library:Notify("Equipped " .. skinName, 1.0)
                renderSkinCards(weaponName)
            end)

            -- Right-Click: Choose skin & return to Gun Models Catalog
            Card.MouseButton2Click:Connect(function()
                API.setWeaponSkin(weaponName, skinName)
                Library:Notify("Equipped " .. weaponName .. " - " .. skinName, 1.5)
                showModelView()
            end)
        end
    end

    -- Export refresh and showModelView handlers
    GunCatalog.refresh = function()
        if GunCatalog.CurrentView == "Skins" and GunCatalog.ActiveGun then
            renderSkinCards(GunCatalog.ActiveGun)
        else
            showModelView()
        end
    end

    GunCatalog.showModelView = function()
        showModelView()
    end

    -- Initial Render
    showModelView()
end

function GunCatalog.cleanup()
    cleanupViewports()
    for _, conn in ipairs(GunCatalog.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    GunCatalog.Connections = {}
    GunCatalog.Initialized = false
end

return GunCatalog
