-- [[ GG HUB v21: FULL FEATURED PREMIUM ]] --
(function()
    -- Combat Framework (Stolen from premium scripts)
    local CombatFramework = require(game:GetService("Players").LocalPlayer.PlayerScripts:WaitForChild("CombatFramework"))
    local CombatFrameworkR = getupvalues(CombatFramework)[2]
    local RigController = require(game:GetService("Players").LocalPlayer.PlayerScripts.CombatFramework.RigController)
    local RigControllerR = getupvalues(RigController)[2]
    local realbhit = require(game.ReplicatedStorage.CombatFramework.RigLib)
    local cooldownfastattack = tick()

    function getAllBladeHits(Sizes)
        local Hits = {}
        local Client = game.Players.LocalPlayer
        local Enemies = game:GetService("Workspace").Enemies:GetChildren()
        for i=1,#Enemies do 
            local v = Enemies[i]
            local Human = v:FindFirstChildOfClass("Humanoid")
            if Human and Human.RootPart and Human.Health > 0 and Client:DistanceFromCharacter(Human.RootPart.Position) < Sizes+5 then
                table.insert(Hits, Human.RootPart)
            end
        end
        return Hits
    end

    function CurrentWeapon()
        local ac = CombatFrameworkR.activeController
        local ret = ac.blades[1]
        if not ret then return game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool").Name end
        pcall(function()
            while ret.Parent ~= game.Players.LocalPlayer.Character do ret = ret.Parent end
        end)
        if not ret then return game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool").Name end
        return ret
    end

    function AttackFunction()
        local ac = CombatFrameworkR.activeController
        if ac and ac.equipped then
            for indexincrement = 1, 1 do
                local bladehit = getAllBladeHits(60)
                if #bladehit > 0 then
                    local AcAttack8 = debug.getupvalue(ac.attack, 5)
                    local AcAttack9 = debug.getupvalue(ac.attack, 6)
                    local AcAttack7 = debug.getupvalue(ac.attack, 4)
                    local AcAttack10 = debug.getupvalue(ac.attack, 7)
                    local NumberAc12 = (AcAttack8 * 798405 + AcAttack7 * 727595) % AcAttack9
                    local NumberAc13 = AcAttack7 * 798405
                    (function()
                        NumberAc12 = (NumberAc12 * AcAttack9 + NumberAc13) % 1099511627776
                        AcAttack8 = math.floor(NumberAc12 / AcAttack9)
                        AcAttack7 = NumberAc12 - AcAttack8 * AcAttack9
                    end)()
                    AcAttack10 = AcAttack10 + 1
                    debug.setupvalue(ac.attack, 5, AcAttack8)
                    debug.setupvalue(ac.attack, 6, AcAttack9)
                    debug.setupvalue(ac.attack, 4, AcAttack7)
                    debug.setupvalue(ac.attack, 7, AcAttack10)
                    for k, v in pairs(ac.animator.anims.basic) do
                        v:Play(0.01, 0.01, 0.01)
                    end                 
                    if game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool") and ac.blades and ac.blades[1] then 
                        game:GetService("ReplicatedStorage").RigControllerEvent:FireServer("weaponChange", tostring(CurrentWeapon()))
                        game.ReplicatedStorage.Remotes.Validator:FireServer(math.floor(NumberAc12 / 1099511627776 * 16777215), AcAttack10)
                        game:GetService("ReplicatedStorage").RigControllerEvent:FireServer("hit", bladehit, 2, "") 
                    end
                end
            end
        end
    end

    function InMyNetWork(object)
        if isnetworkowner then
            return isnetworkowner(object)
        else
            if (object.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 350 then 
                return true
            end
            return false
        end
    end

    -- Core State
    local GG = {
        State = {
            AutoFarmLevel = false,
            FastAttack = false,
            BringMob = false,
            AutoHaki = true,
            AutoGodHuman = false,
            AutoSuperhuman = false,
            AutoElectricClaw = false,
            AutoDeathStep = false,
            AutoSharkmanKarate = false,
            AutoDragonTalon = false,
            AutoAllBoss = false,
            AutoFarmBone = false,
            AutoEliteHunter = false,
            AutoRainbowHaki = false,
            AutoYamaSword = false,
            AutoTushitaSword = false,
            AutoHolyTorch = false,
            AutoBuddySwords = false,
            AutoCakePrince = false,
            AutoDoughV2 = false,
            AutoSerpentBow = false,
            AutoDarkDagger = false,
            AutoNewWorld = false,
            AutoThirdSea = false,
            AutoFactory = false,
            AutoSaber = false,
            AutoPole = false,
            AutoRengoku = false,
            AutoBartiloQuest = false,
            UIVisible = true,
            IsBusy = false,
            TargetItem = (game.PlaceId == 444224521) and "Fist of Darkness" or "God's Chalice"
        },
        Config = {
            Hub = Vector3.new(-5024, 315, -3156),
            Speed = 300,
            FastAttackType = "Fast",
            SelectWeapon = "Melee",
            DistanceAutoFarm = 20,
            BringMobRadius = 350
        },
        Connections = {},
        UI = {}
    }

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local CoreGui = game:GetService("CoreGui")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    local LP = Players.LocalPlayer
    local PosMon = nil

    -- Utilities
    local function getRoot()
        return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    end

    local function updateStatus(txt, color)
        if GG.UI.StatusLabel then
            GG.UI.StatusLabel.Text = txt
            GG.UI.StatusLabel.TextColor3 = color or Color3.new(1, 1, 1)
        end
    end

    function EquipWeapon(Tool)
        pcall(function()
            if LP.Backpack:FindFirstChild(Tool) then 
                local ToolHumanoid = LP.Backpack:FindFirstChild(Tool) 
                LP.Character.Humanoid:EquipTool(ToolHumanoid) 
            end
        end)
    end

    function UnEquipWeapon(Weapon)
        if LP.Character:FindFirstChild(Weapon) then
            wait(.1)
            LP.Character:FindFirstChild(Weapon).Parent = LP.Backpack
        end
    end

    -- Tween System
    local tween = nil
    local function toTarget(targetPos)
        local Distance = (targetPos.Position - getRoot().Position).Magnitude
        local Speed = Distance < 1000 and 315 or 300

        local tween_s = game:service"TweenService"
        local info = TweenInfo.new(Distance/Speed, Enum.EasingStyle.Linear)
        
        if tween then
            tween:Cancel()
        end
        
        pcall(function()
            tween = tween_s:Create(getRoot(), info, {CFrame = targetPos})
            tween:Play()
        end)
        
        return tween
    end

    -- Server Hop
    local function safeHop()
        updateStatus("🔄 Searching Servers...", Color3.fromRGB(255, 200, 0))
        task.spawn(function()
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=50"))
            end)
            
            if success and result and result.data then
                for _, s in pairs(result.data) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                        return
                    end
                end
            end
            updateStatus("❌ No Servers", Color3.fromRGB(255, 80, 80))
        end)
    end

    -- Mob Bringing (OPTIMIZED)
    spawn(function()
        while task.wait(.1) do
            pcall(function()
                if GG.State.AutoFarmLevel and GG.State.BringMob and PosMon then
                    for i,v in pairs(game.Workspace.Enemies:GetChildren()) do
                        if not string.find(v.Name,"Boss") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            if (v.HumanoidRootPart.Position - PosMon.Position).Magnitude <= GG.Config.BringMobRadius then
                                if InMyNetWork(v.HumanoidRootPart) then
                                    v.HumanoidRootPart.CFrame = PosMon
                                    v.Humanoid.JumpPower = 0
                                    v.Humanoid.WalkSpeed = 0
                                    v.HumanoidRootPart.Size = Vector3.new(60,60,60)
                                    v.HumanoidRootPart.Transparency = 1
                                    v.HumanoidRootPart.CanCollide = false
                                    v.Head.CanCollide = false
                                    if v.Humanoid:FindFirstChild("Animator") then
                                        v.Humanoid.Animator:Destroy()
                                    end
                                    v.Humanoid:ChangeState(11)
                                    v.Humanoid:ChangeState(14)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)

    -- No Clip (OPTIMIZED)
    spawn(function()
        while wait(.2) do 
            pcall(function()
                if GG.State.AutoFarmLevel then
                    if not getRoot():FindFirstChild("BodyVelocity1") then
                        local BodyVelocity = Instance.new("BodyVelocity")
                        BodyVelocity.Name = "BodyVelocity1"
                        BodyVelocity.Parent = getRoot()
                        BodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
                        BodyVelocity.Velocity = Vector3.new(0, 0, 0)
                    end
                    for _, v in pairs(LP.Character:GetDescendants()) do
                        if v:IsA("BasePart") then
                            v.CanCollide = false    
                        end
                    end
                else
                    if getRoot():FindFirstChild("BodyVelocity1") then
                        getRoot():FindFirstChild("BodyVelocity1"):Destroy()
                    end
                end
            end)
        end
    end)

    -- UI IMPLEMENTATION
    local function buildUI()
        if CoreGui:FindFirstChild("GGHub") then
            CoreGui:FindFirstChild("GGHub"):Destroy()
        end
        
        local sg = Instance.new("ScreenGui")
        sg.Name = "GGHub"
        sg.Parent = CoreGui
        sg.ResetOnSpawn = false
        
        -- FLOATING BUTTON (OPTIMIZED - ALWAYS LIGHTNING)
        local floatingBtn = Instance.new("TextButton")
        floatingBtn.Size = UDim2.new(0, 60, 0, 60)
        floatingBtn.Position = UDim2.new(0, 10, 0.5, -30)
        floatingBtn.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
        floatingBtn.BorderSizePixel = 0
        floatingBtn.Text = "⚡"
        floatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        floatingBtn.Font = Enum.Font.GothamBold
        floatingBtn.TextSize = 28
        floatingBtn.Active = true
        floatingBtn.Draggable = true
        floatingBtn.ZIndex = 999
        floatingBtn.Parent = sg
        
        local floatingCorner = Instance.new("UICorner")
        floatingCorner.CornerRadius = UDim.new(1, 0)
        floatingCorner.Parent = floatingBtn
        
        local floatingShadow = Instance.new("UIStroke")
        floatingShadow.Color = Color3.fromRGB(0, 0, 0)
        floatingShadow.Thickness = 3
        floatingShadow.Transparency = 0.5
        floatingShadow.Parent = floatingBtn
        
        -- Main Container
        local main = Instance.new("Frame")
        main.Size = UDim2.new(0, 700, 0, 480)
        main.Position = UDim2.new(0.5, -350, 0.5, -240)
        main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        main.BorderSizePixel = 0
        main.Active = true
        main.Draggable = true
        main.Parent = sg
        
        GG.UI.MainFrame = main
        
        local mainCorner = Instance.new("UICorner")
        mainCorner.CornerRadius = UDim.new(0, 12)
        mainCorner.Parent = main

        -- Header
        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 60)
        header.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        header.BorderSizePixel = 0
        header.Parent = main
        
        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = UDim.new(0, 12)
        headerCorner.Parent = header

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0, 250, 1, 0)
        title.Position = UDim2.new(0, 20, 0, 0)
        title.Text = "⚡ GG HUB"
        title.TextColor3 = Color3.fromRGB(120, 200, 255)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 24
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = header

        local minimizeBtn = Instance.new("TextButton")
        minimizeBtn.Size = UDim2.new(0, 45, 0, 45)
        minimizeBtn.Position = UDim2.new(1, -55, 0, 7.5)
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        minimizeBtn.BorderSizePixel = 0
        minimizeBtn.Text = "—"
        minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        minimizeBtn.Font = Enum.Font.GothamBold
        minimizeBtn.TextSize = 22
        minimizeBtn.Parent = header
        
        local minimizeCorner = Instance.new("UICorner")
        minimizeCorner.CornerRadius = UDim.new(0, 10)
        minimizeCorner.Parent = minimizeBtn

        local function toggleUI()
            GG.State.UIVisible = not GG.State.UIVisible
            main.Visible = GG.State.UIVisible
        end
        
        minimizeBtn.MouseButton1Click:Connect(toggleUI)
        floatingBtn.MouseButton1Click:Connect(toggleUI)

        -- Sidebar
        local sidebar = Instance.new("Frame")
        sidebar.Size = UDim2.new(0, 200, 1, -70)
        sidebar.Position = UDim2.new(0, 10, 0, 65)
        sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        sidebar.BorderSizePixel = 0
        sidebar.Parent = main
        
        local sidebarCorner = Instance.new("UICorner")
        sidebarCorner.CornerRadius = UDim.new(0, 10)
        sidebarCorner.Parent = sidebar

        local content = Instance.new("Frame")
        content.Size = UDim2.new(0, 470, 1, -70)
        content.Position = UDim2.new(0, 220, 0, 65)
        content.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        content.BorderSizePixel = 0
        content.Parent = main
        
        local contentCorner = Instance.new("UICorner")
        contentCorner.CornerRadius = UDim.new(0, 10)
        contentCorner.Parent = content

        local tabContainer = Instance.new("ScrollingFrame")
        tabContainer.Size = UDim2.new(1, -10, 1, -10)
        tabContainer.Position = UDim2.new(0, 5, 0, 5)
        tabContainer.BackgroundTransparency = 1
        tabContainer.BorderSizePixel = 0
        tabContainer.ScrollBarThickness = 6
        tabContainer.ScrollBarImageColor3 = Color3.fromRGB(120, 200, 255)
        tabContainer.Parent = sidebar

        local tabList = Instance.new("UIListLayout")
        tabList.Padding = UDim.new(0, 10)
        tabList.Parent = tabContainer

        local pages = {}
        
        local function createPage(name)
            local page = Instance.new("ScrollingFrame")
            page.Name = name
            page.Size = UDim2.new(1, -20, 1, -20)
            page.Position = UDim2.new(0, 10, 0, 10)
            page.BackgroundTransparency = 1
            page.BorderSizePixel = 0
            page.ScrollBarThickness = 6
            page.ScrollBarImageColor3 = Color3.fromRGB(120, 200, 255)
            page.Visible = false
            page.Parent = content
            
            local pageLayout = Instance.new("UIListLayout")
            pageLayout.Padding = UDim.new(0, 12)
            pageLayout.Parent = page
            
            pages[name] = page
            return page
        end

        local mainPage = createPage("Main")
        local fightingPage = createPage("Fighting")
        local itemsPage = createPage("Items")
        local settingsPage = createPage("Settings")

        mainPage.Visible = true

        local function createTab(name, icon, targetPage)
            local tab = Instance.new("TextButton")
            tab.Size = UDim2.new(1, -10, 0, 50)
            tab.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            tab.BorderSizePixel = 0
            tab.Text = "  " .. icon .. "  " .. name
            tab.TextColor3 = Color3.fromRGB(180, 180, 180)
            tab.Font = Enum.Font.GothamBold
            tab.TextSize = 16
            tab.TextXAlignment = Enum.TextXAlignment.Left
            tab.Parent = tabContainer
            
            local tabCorner = Instance.new("UICorner")
            tabCorner.CornerRadius = UDim.new(0, 10)
            tabCorner.Parent = tab
            
            tab.MouseButton1Click:Connect(function()
                for _, page in pairs(pages) do
                    page.Visible = false
                end
                targetPage.Visible = true
                
                for _, child in pairs(tabContainer:GetChildren()) do
                    if child:IsA("TextButton") then
                        child.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                        child.TextColor3 = Color3.fromRGB(180, 180, 180)
                    end
                end
                tab.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
                tab.TextColor3 = Color3.fromRGB(255, 255, 255)
            end)
            
            return tab
        end

        local mainTab = createTab("Main", "🏠", mainPage)
        mainTab.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
        mainTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        createTab("Fighting", "🥊", fightingPage)
        createTab("Items", "🎁", itemsPage)
        createTab("Settings", "⚙️", settingsPage)

        -- Status Section
        local statusSection = Instance.new("Frame")
        statusSection.Size = UDim2.new(1, 0, 0, 80)
        statusSection.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        statusSection.BorderSizePixel = 0
        statusSection.Parent = mainPage
        
        local statusCorner = Instance.new("UICorner")
        statusCorner.CornerRadius = UDim.new(0, 10)
        statusCorner.Parent = statusSection

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Size = UDim2.new(1, -20, 1, -20)
        statusLabel.Position = UDim2.new(0, 10, 0, 10)
        statusLabel.Text = "✅ Status: Ready | " .. GG.State.TargetItem
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Font = Enum.Font.GothamBold
        statusLabel.TextSize = 16
        statusLabel.TextWrapped = true
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.TextYAlignment = Enum.TextYAlignment.Top
        statusLabel.Parent = statusSection
        
        GG.UI.StatusLabel = statusLabel

        local function createToggle(page, name, icon, stateKey, color)
            local toggleFrame = Instance.new("Frame")
            toggleFrame.Size = UDim2.new(1, 0, 0, 55)
            toggleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            toggleFrame.BorderSizePixel = 0
            toggleFrame.Parent = page
            
            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, 10)
            toggleCorner.Parent = toggleFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 320, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.Text = icon .. "  " .. name
            label.TextColor3 = Color3.fromRGB(220, 220, 220)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBold
            label.TextSize = 15
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = toggleFrame

            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0, 80, 0, 38)
            button.Position = UDim2.new(1, -92, 0.5, -19)
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            button.BorderSizePixel = 0
            button.Text = "OFF"
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.Font = Enum.Font.GothamBold
            button.TextSize = 14
            button.Parent = toggleFrame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = button

            button.MouseButton1Click:Connect(function()
                GG.State[stateKey] = not GG.State[stateKey]
                button.Text = GG.State[stateKey] and "ON" or "OFF"
                button.BackgroundColor3 = GG.State[stateKey] and color or Color3.fromRGB(60, 60, 60)
            end)
        end

        -- MAIN PAGE
        createToggle(mainPage, "Auto Farm Level", "⚔️", "AutoFarmLevel", Color3.fromRGB(120, 200, 255))
        createToggle(mainPage, "Fast Attack", "⚡", "FastAttack", Color3.fromRGB(255, 100, 150))
        createToggle(mainPage, "Bring Mobs", "🧲", "BringMob", Color3.fromRGB(100, 255, 100))
        createToggle(mainPage, "Auto Haki", "🛡️", "AutoHaki", Color3.fromRGB(150, 100, 255))
        createToggle(mainPage, "Auto New World", "🌍", "AutoNewWorld", Color3.fromRGB(100, 200, 255))
        createToggle(mainPage, "Auto Third Sea", "🌊", "AutoThirdSea", Color3.fromRGB(0, 150, 255))

        -- FIGHTING PAGE
        createToggle(fightingPage, "Auto God Human", "👊", "AutoGodHuman", Color3.fromRGB(255, 200, 0))
        createToggle(fightingPage, "Auto Superhuman", "💪", "AutoSuperhuman", Color3.fromRGB(255, 150, 0))
        createToggle(fightingPage, "Auto Electric Claw", "⚡", "AutoElectricClaw", Color3.fromRGB(255, 255, 0))
        createToggle(fightingPage, "Auto Death Step", "🦶", "AutoDeathStep", Color3.fromRGB(150, 0, 255))
        createToggle(fightingPage, "Auto Sharkman Karate", "🦈", "AutoSharkmanKarate", Color3.fromRGB(0, 150, 255))
        createToggle(fightingPage, "Auto Dragon Talon", "🐉", "AutoDragonTalon", Color3.fromRGB(255, 0, 0))

        -- ITEMS PAGE
        createToggle(itemsPage, "Auto Farm Bone", "🦴", "AutoFarmBone", Color3.fromRGB(200, 200, 200))
        createToggle(itemsPage, "Auto Elite Hunter", "💀", "AutoEliteHunter", Color3.fromRGB(255, 0, 0))
        createToggle(itemsPage, "Auto Rainbow Haki", "🌈", "AutoRainbowHaki", Color3.fromRGB(255, 100, 255))
        createToggle(itemsPage, "Auto Yama Sword", "⚔️", "AutoYamaSword", Color3.fromRGB(150, 0, 0))
        createToggle(itemsPage, "Auto Tushita Sword", "🗡️", "AutoTushitaSword", Color3.fromRGB(255, 200, 0))
        createToggle(itemsPage, "Auto Holy Torch", "🔥", "AutoHolyTorch", Color3.fromRGB(255, 150, 0))
        createToggle(itemsPage, "Auto Buddy Swords", "⚔️", "AutoBuddySwords", Color3.fromRGB(0, 200, 255))
        createToggle(itemsPage, "Auto Cake Prince", "🍰", "AutoCakePrince", Color3.fromRGB(255, 150, 200))
        createToggle(itemsPage, "Auto Dough V2", "🍩", "AutoDoughV2", Color3.fromRGB(200, 150, 255))

        -- Server Hop
        local hopFrame = Instance.new("Frame")
        hopFrame.Size = UDim2.new(1, 0, 0, 55)
        hopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        hopFrame.BorderSizePixel = 0
        hopFrame.Parent = mainPage
        
        local hopCorner = Instance.new("UICorner")
        hopCorner.CornerRadius = UDim.new(0, 10)
        hopCorner.Parent = hopFrame

        local hopButton = Instance.new("TextButton")
        hopButton.Size = UDim2.new(1, -20, 1, -10)
        hopButton.Position = UDim2.new(0, 10, 0, 5)
        hopButton.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
        hopButton.BorderSizePixel = 0
        hopButton.Text = "🌐  Server Hop"
        hopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        hopButton.Font = Enum.Font.GothamBold
        hopButton.TextSize = 16
        hopButton.Parent = hopFrame
        
        local hopBtnCorner = Instance.new("UICorner")
        hopBtnCorner.CornerRadius = UDim.new(0, 8)
        hopBtnCorner.Parent = hopButton
        
        hopButton.MouseButton1Click:Connect(safeHop)

        -- SETTINGS
        local versionInfo = Instance.new("Frame")
        versionInfo.Size = UDim2.new(1, 0, 0, 70)
        versionInfo.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        versionInfo.BorderSizePixel = 0
        versionInfo.Parent = settingsPage
        
        local versionCorner = Instance.new("UICorner")
        versionCorner.CornerRadius = UDim.new(0, 10)
        versionCorner.Parent = versionInfo

        local versionText = Instance.new("TextLabel")
        versionText.Size = UDim2.new(1, -20, 1, 0)
        versionText.Position = UDim2.new(0, 10, 0, 0)
        versionText.Text = "📱 GG HUB v21 - Premium Full Featured"
        versionText.TextColor3 = Color3.fromRGB(120, 200, 255)
        versionText.BackgroundTransparency = 1
        versionText.Font = Enum.Font.GothamBold
        versionText.TextSize = 15
        versionText.TextXAlignment = Enum.TextXAlignment.Left
        versionText.Parent = versionInfo
    end

    -- Auto Haki (OPTIMIZED)
    spawn(function()
        while wait(1) do
            if GG.State.AutoHaki and GG.State.AutoFarmLevel then
                if not LP.Character:FindFirstChild("HasBuso") then
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                end
            end
        end
    end)

    -- Item Observer (OPTIMIZED)
    game.Workspace.DescendantAdded:Connect(function(child)
        task.wait(0.1)
        
        if not GG.State.AutoFarmLevel or GG.State.IsBusy then return end
        
        if child.Name == GG.State.TargetItem then
            local handle = child:FindFirstChild("Handle") or (child:IsA("BasePart") and child)
            
            if handle then
                GG.State.IsBusy = true
                updateStatus("🎯 Target Spotted!", Color3.fromRGB(255, 200, 0))
                
                task.wait(0.2)
                
                local root = getRoot()
                if root then
                    root.CFrame = CFrame.new(handle.Position)
                    task.wait(0.2)
                    
                    updateStatus("📦 Collecting...", Color3.fromRGB(255, 255, 100))
                    
                    for i = 1, 3 do
                        pcall(function()
                            if handle and handle.Parent then
                                firetouchinterest(root, handle, 0)
                                task.wait(0.05)
                                firetouchinterest(root, handle, 1)
                            end
                        end)
                        task.wait(0.1)
                    end
                    
                    task.wait(0.5)
                    root.CFrame = CFrame.new(GG.Config.Hub)
                    
                    GG.State.IsBusy = false
                    updateStatus("✅ Ready", Color3.fromRGB(100, 255, 150))
                end
            end
        end
    end)

    -- Fast Attack Loop (PREMIUM SYSTEM - OPTIMIZED)
    coroutine.wrap(function()
        while task.wait(.1) do
            pcall(function()
                local ac = CombatFrameworkR.activeController
                if ac and ac.equipped and GG.State.FastAttack then
                    AttackFunction()
                    if GG.Config.FastAttackType == "Fast" then
                        if tick() - cooldownfastattack > 1.5 then 
                            wait(.01) 
                            cooldownfastattack = tick() 
                        end
                    end
                end
            end)
        end
    end)()

    -- Simulation Radius (OPTIMIZED)
    spawn(function()
        while wait(2) do
            pcall(function()
                if GG.State.AutoFarmLevel then
                    if setscriptable then
                        setscriptable(LP, "SimulationRadius", true)
                    end
                    if sethiddenproperty then
                        sethiddenproperty(LP, "SimulationRadius", math.huge)
                    end
                end
            end)
        end
    end)

    buildUI()
    print("✅ GG Hub Premium Full Featured Loaded! 🔥")
end)()
