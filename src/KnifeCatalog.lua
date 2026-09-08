-- Seeto.Solutionz / Bloxstrike Skinchanger / KnifeCatalog
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SkinsLib = nil
pcall(function()
    SkinsLib = require(ReplicatedStorage.Database.Components.Libraries.Skins)
end)

local KnifeCatalog = {
    Initialized = false,
    CurrentView = "Models", -- "Models" | "Skins"
    ActiveKnife = "Butterfly Knife",
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

local function getRarityColor(knifeModel, skinName)
    if knifeModel == "Default" or skinName == "Default" or skinName == "Stock" or skinName == "Vanilla" then
        return RarityColors.Stock
    end
    if skinName == "Special" or skinName == "Random" then
        return RarityColors.Special
    end
    if SkinsLib and SkinsLib.GetSkinInformation then
        local targetModel = knifeModel
        if targetModel == "Default" then targetModel = "CT Knife" end
        local ok, info = pcall(function()
            return SkinsLib.GetSkinInformation(targetModel, skinName or "Vanilla")
        end)
        if ok and info and info.rarity and RarityColors[info.rarity] then
            return RarityColors[info.rarity]
        end
    end
    return RarityColors.Special
end

local function cleanupViewports()
    for _, fn in ipairs(KnifeCatalog.ViewportCleanups) do
        pcall(fn)
    end
    KnifeCatalog.ViewportCleanups = {}
end

local function setupKnifeViewport(viewportFrame, knifeModelName, skinName)
    viewportFrame:ClearAllChildren()
    if not SkinsLib then return nil end

    local targetModel = knifeModelName
    if targetModel == "Default" then
        targetModel = "CT Knife"
    end

    local model = nil
    local trySkins = { skinName, "Stock", "Vanilla", "Fade", "Ren", "Lebron James" }
    for _, s in ipairs(trySkins) do
        if s and s ~= "Random" and s ~= "Special" then
            local ok, m = pcall(function()
                return SkinsLib.GetCharacterModel(targetModel, s, 0.001)
            end)
            if ok and m then
                model = m
                break
            end
        end
    end

    if not model then
        pcall(function()
            model = SkinsLib.GetCharacterModel(targetModel, "Stock", 0.001)
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
    -- Camera placed 40% closer (0.81 factor vs previous 1.35)
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
    table.insert(KnifeCatalog.ViewportCleanups, function()
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

function KnifeCatalog.init(Tab, Config, API, Library, Database)
    if KnifeCatalog.Initialized then return end
    KnifeCatalog.Initialized = true

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

    -- 1. Model Catalog View
    local ModelView = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Visible = true,
        ZIndex = 2,
        Parent = MainContainer
    })

    -- Model View Header
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
        Text = "Knife Models",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
        Parent = ModelHeader
    })

    local ModelHint = Library:CreateLabel({
        Position = UDim2.new(0.4, 0, 0, 0),
        Size = UDim2.new(0.6, -8, 1, 0),
        Text = "Left-Click: Equip  |  Right-Click: View Skins",
        TextColor3 = Color3.fromRGB(160, 160, 170),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 4,
        Parent = ModelHeader
    })

    -- Model Grid Scroll Frame (10% bigger cards: 136 x 148)
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
        Size = UDim2.new(0, 120, 0, 20),
        Text = "< Back to Models",
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
        Position = UDim2.new(0, 132, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Text = "Butterfly Knife / Skins",
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

    -- Skin Grid Scroll Frame (10% bigger cards: 136 x 148)
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
        KnifeCatalog.CurrentView = "Models"
        SkinView.Visible = false
        ModelView.Visible = true
        renderModelCards()
    end

    local function showSkinView(knifeModelName)
        KnifeCatalog.CurrentView = "Skins"
        KnifeCatalog.ActiveKnife = knifeModelName
        SkinTitle.Text = knifeModelName .. " / Skins"
        ModelView.Visible = false
        SkinView.Visible = true
        renderSkinCards(knifeModelName)
    end

    BackButton.MouseButton1Click:Connect(function()
        showModelView()
    end)

    -- Render Model Cards (136 x 148)
    renderModelCards = function()
        for _, child in ipairs(ModelScroll:GetChildren()) do
            if not child:IsA('UIGridLayout') then
                child:Destroy()
            end
        end
        cleanupViewports()

        local currentEquipped = Config.KNIFE_MODEL or "Default"

        for idx, modelName in ipairs(Database.KnifeModels) do
            local isSelected = (currentEquipped == modelName)

            -- Resolve skin for this model from Config.KNIFE_SKINS first
            local modelSkin = (Config.KNIFE_SKINS and Config.KNIFE_SKINS[modelName])
            if not modelSkin then
                if isSelected and Config.KNIFE_SKIN and Config.KNIFE_SKIN ~= "Stock" and Config.KNIFE_SKIN ~= "Default" then
                    modelSkin = Config.KNIFE_SKIN
                else
                    modelSkin = (modelName == "Default") and "Stock" or "Vanilla"
                end
            end

            local rarityColor = getRarityColor(modelName, modelSkin)

            local Card = Library:Create('TextButton', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = isSelected and Library.AccentColor or Library.OutlineColor,
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

            -- 3D Viewport (Height = 100px)
            local Viewport = Library:Create('ViewportFrame', {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 2, 0, 4),
                Size = UDim2.new(1, -4, 0, 100),
                ZIndex = 5,
                Parent = Card
            })

            local vpController = setupKnifeViewport(Viewport, modelName, modelSkin)

            -- Knife Title Label
            local TitleLabel = Library:CreateLabel({
                Position = UDim2.new(0, 4, 0, 104),
                Size = UDim2.new(1, -8, 0, 20),
                Text = modelName,
                TextSize = 15,
                TextColor3 = isSelected and Library.AccentColor or Library.FontColor,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 6,
                Parent = Card
            })

            -- Knife Subtitle / Badge
            local SubLabel = Library:CreateLabel({
                Position = UDim2.new(0, 4, 0, 126),
                Size = UDim2.new(1, -8, 0, 18),
                Text = isSelected and ("[" .. tostring(modelSkin) .. "]") or tostring(modelSkin),
                TextSize = 13,
                TextColor3 = isSelected and Color3.fromRGB(220, 220, 230) or Color3.fromRGB(140, 140, 150),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 6,
                Parent = Card
            })

            -- Hover effects
            Card.MouseEnter:Connect(function()
                if vpController then vpController.setHover(true) end
                if not (Config.KNIFE_MODEL == modelName) then
                    Card.BorderColor3 = Color3.fromRGB(100, 105, 120)
                end
            end)

            Card.MouseLeave:Connect(function()
                if vpController then vpController.setHover(false) end
                if not (Config.KNIFE_MODEL == modelName) then
                    Card.BorderColor3 = Library.OutlineColor
                end
            end)

            -- Left-Click: Equip Model with its saved skin
            Card.MouseButton1Click:Connect(function()
                API.setKnife(modelName, modelSkin)
                Library:Notify("Equipped " .. modelName, 1.5)
                renderModelCards()
            end)

            -- Right-Click: Open Skins Catalog
            Card.MouseButton2Click:Connect(function()
                showSkinView(modelName)
            end)
        end
    end

    -- Render Skin Cards (136 x 148)
    renderSkinCards = function(knifeModelName)
        for _, child in ipairs(SkinScroll:GetChildren()) do
            if not child:IsA('UIGridLayout') then
                child:Destroy()
            end
        end
        cleanupViewports()

        local currentEquipped = Config.KNIFE_MODEL or "Default"
        local activeModelSkin = (Config.KNIFE_SKINS and Config.KNIFE_SKINS[knifeModelName])
        if not activeModelSkin then
            if currentEquipped == knifeModelName and Config.KNIFE_SKIN and Config.KNIFE_SKIN ~= "Stock" and Config.KNIFE_SKIN ~= "Default" then
                activeModelSkin = Config.KNIFE_SKIN
            else
                activeModelSkin = (knifeModelName == "Default") and "Stock" or "Vanilla"
            end
        end

        local skinList = Database.getKnifeSkinList(knifeModelName)

        for idx, skinName in ipairs(skinList) do
            local isSelected = (currentEquipped == knifeModelName and activeModelSkin == skinName)
            local rarityColor = getRarityColor(knifeModelName, skinName)

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

            local vpController = setupKnifeViewport(Viewport, knifeModelName, skinName)

            -- Skin Title Label
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

            -- Badge Label
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
                API.setKnife(knifeModelName, skinName)
                Library:Notify("Equipped " .. skinName, 1.0)
                renderSkinCards(knifeModelName)
            end)

            -- Right-Click: Choose skin & return to Knife Models Catalog
            Card.MouseButton2Click:Connect(function()
                API.setKnife(knifeModelName, skinName)
                Library:Notify("Equipped " .. knifeModelName .. " - " .. skinName, 1.5)
                showModelView()
            end)
        end
    end

    -- Export refresh and showModelView handlers
    KnifeCatalog.refresh = function()
        if KnifeCatalog.CurrentView == "Skins" and KnifeCatalog.ActiveKnife then
            renderSkinCards(KnifeCatalog.ActiveKnife)
        else
            showModelView()
        end
    end

    KnifeCatalog.showModelView = function()
        showModelView()
    end

    -- Initial Render
    showModelView()
end

function KnifeCatalog.cleanup()
    cleanupViewports()
    for _, conn in ipairs(KnifeCatalog.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    KnifeCatalog.Connections = {}
    KnifeCatalog.Initialized = false
end

return KnifeCatalog
