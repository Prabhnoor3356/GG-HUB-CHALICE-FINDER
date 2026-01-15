-- [[ GG HUB v21: MOBILE GRAVITY HUB STYLE ]] --
(function()
    -- 1. CENTRALIZED CORE
    local GG = {
        State = {
            Enabled = false,
            FastAttack = false,
            IsBusy = false,
            ThreadID = 0,
            TargetItem = (game.PlaceId == 444224521) and "Fist of Darkness" or "God's Chalice",
            UIVisible = true
        },
        Config = {
            Hub = Vector3.new(-5024, 315, -3156),
            Speed = 175,
            AttackDelay = 0.12
        },
        Connections = {},
        UI = {}
    }

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local CoreGui = game:GetService("CoreGui")
    
    local LP = Players.LocalPlayer

    -- 2. UTILITIES
    local function getRoot()
        return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    end

    local function updateStatus(txt, color)
        if GG.UI.StatusLabel then
            GG.UI.StatusLabel.Text = txt
            GG.UI.StatusLabel.TextColor3 = color or Color3.new(1, 1, 1)
        end
    end

    -- 3. MOVEMENT ENGINE
    local function safeMove(targetPos, callback)
        GG.State.ThreadID = GG.State.ThreadID + 1
        local currentThread = GG.State.ThreadID
        
        local root = getRoot()
        if not root then 
            GG.State.IsBusy = false 
            return 
        end

        local startPos = root.Position
        local distance = (startPos - targetPos).Magnitude
        local duration = distance / GG.Config.Speed
        local elapsed = 0

        if GG.Connections.Move then 
            GG.Connections.Move:Disconnect() 
        end

        GG.Connections.Move = RunService.Heartbeat:Connect(function(dt)
            local currentRoot = getRoot()
            if not currentRoot or GG.State.ThreadID ~= currentThread or not GG.State.Enabled then
                if GG.Connections.Move then 
                    GG.Connections.Move:Disconnect() 
                end
                GG.State.IsBusy = false
                return
            end

            elapsed = elapsed + dt
            local t = math.min(elapsed / duration, 1)
            
            if currentRoot.AssemblyLinearVelocity then
                currentRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            currentRoot.CFrame = CFrame.new(startPos:Lerp(targetPos, t))

            if t >= 1 then
                GG.Connections.Move:Disconnect()
                if callback then callback() end
            end
        end)
    end

    -- 4. SERVER HOP
    local function safeHop()
        updateStatus("🔄 Searching Servers...", Color3.fromRGB(255, 200, 0))
        task.spawn(function()
            local success, result = pcall(function()
                local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=50"
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            
            if success and result and result.data then
                for _, s in pairs(result.data) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                        return
                    end
                end
            end
            updateStatus("❌ No Servers Found", Color3.fromRGB(255, 80, 80))
        end)
    end

    -- 5. UI IMPLEMENTATION (MOBILE OPTIMIZED)
    local function buildUI()
        if CoreGui:FindFirstChild("GGHub") then
            CoreGui:FindFirstChild("GGHub"):Destroy()
        end
        
        local sg = Instance.new("ScreenGui")
        sg.Name = "GGHub"
        sg.Parent = CoreGui
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- FLOATING TOGGLE BUTTON (Always Visible)
        local floatingBtn = Instance.new("TextButton")
        floatingBtn.Name = "FloatingToggle"
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
        main.Name = "MainFrame"
        main.Size = UDim2.new(0, 680, 0, 450)
        main.Position = UDim2.new(0.5, -340, 0.5, -225)
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

        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0, 250, 1, 0)
        title.Position = UDim2.new(0, 20, 0, 0)
        title.Text = "⚡ GRAVITY HUB"
        title.TextColor3 = Color3.fromRGB(120, 200, 255)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 24
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = header

        -- Minimize Button
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

        -- Toggle Functionality
        local function toggleUI()
            GG.State.UIVisible = not GG.State.UIVisible
            main.Visible = GG.State.UIVisible
            floatingBtn.Text = GG.State.UIVisible and "⚡" or "👁️"
        end
        
        minimizeBtn.MouseButton1Click:Connect(toggleUI)
        floatingBtn.MouseButton1Click:Connect(toggleUI)

        -- Left Sidebar (Tabs)
        local sidebar = Instance.new("Frame")
        sidebar.Size = UDim2.new(0, 200, 1, -70)
        sidebar.Position = UDim2.new(0, 10, 0, 65)
        sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        sidebar.BorderSizePixel = 0
        sidebar.Parent = main
        
        local sidebarCorner = Instance.new("UICorner")
        sidebarCorner.CornerRadius = UDim.new(0, 10)
        sidebarCorner.Parent = sidebar

        -- Content Area
        local content = Instance.new("Frame")
        content.Size = UDim2.new(0, 450, 1, -70)
        content.Position = UDim2.new(0, 220, 0, 65)
        content.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        content.BorderSizePixel = 0
        content.Parent = main
        
        local contentCorner = Instance.new("UICorner")
        contentCorner.CornerRadius = UDim.new(0, 10)
        contentCorner.Parent = content

        -- Tab Container
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

        -- Content Pages
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
            pageLayout.Padding = UDim.new(0, 15)
            pageLayout.Parent = page
            
            pages[name] = page
            return page
        end

        -- Create Pages
        local homePage = createPage("Home")
        local farmingPage = createPage("Farming")
        local settingsPage = createPage("Settings")

        -- Show first page
        homePage.Visible = true

        -- Tab Creator (BIGGER FOR MOBILE)
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

        -- Create Tabs
        local homeTab = createTab("Home", "🏠", homePage)
        homeTab.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
        homeTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        createTab("Farming", "⚔️", farmingPage)
        createTab("Settings", "⚙️", settingsPage)

        -- HOME PAGE CONTENT
        local infoSection = Instance.new("Frame")
        infoSection.Size = UDim2.new(1, 0, 0, 140)
        infoSection.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        infoSection.BorderSizePixel = 0
        infoSection.Parent = homePage
        
        local infoCorner = Instance.new("UICorner")
        infoCorner.CornerRadius = UDim.new(0, 10)
        infoCorner.Parent = infoSection

        local infoTitle = Instance.new("TextLabel")
        infoTitle.Size = UDim2.new(1, -20, 0, 35)
        infoTitle.Position = UDim2.new(0, 10, 0, 10)
        infoTitle.Text = "📊 Information"
        infoTitle.TextColor3 = Color3.fromRGB(120, 200, 255)
        infoTitle.BackgroundTransparency = 1
        infoTitle.Font = Enum.Font.GothamBold
        infoTitle.TextSize = 18
        infoTitle.TextXAlignment = Enum.TextXAlignment.Left
        infoTitle.Parent = infoSection

        local playerInfo = Instance.new("TextLabel")
        playerInfo.Size = UDim2.new(1, -20, 0, 25)
        playerInfo.Position = UDim2.new(0, 10, 0, 50)
        playerInfo.Text = "👤 Player: " .. LP.Name
        playerInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
        playerInfo.BackgroundTransparency = 1
        playerInfo.Font = Enum.Font.Gotham
        playerInfo.TextSize = 15
        playerInfo.TextXAlignment = Enum.TextXAlignment.Left
        playerInfo.Parent = infoSection

        local targetInfo = Instance.new("TextLabel")
        targetInfo.Size = UDim2.new(1, -20, 0, 25)
        targetInfo.Position = UDim2.new(0, 10, 0, 80)
        targetInfo.Text = "🎯 Target: " .. GG.State.TargetItem
        targetInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
        targetInfo.BackgroundTransparency = 1
        targetInfo.Font = Enum.Font.Gotham
        targetInfo.TextSize = 15
        targetInfo.TextXAlignment = Enum.TextXAlignment.Left
        targetInfo.Parent = infoSection

        local statusInfo = Instance.new("TextLabel")
        statusInfo.Size = UDim2.new(1, -20, 0, 25)
        statusInfo.Position = UDim2.new(0, 10, 0, 110)
        statusInfo.Text = "✅ Status: Ready"
        statusInfo.TextColor3 = Color3.fromRGB(100, 255, 150)
        statusInfo.BackgroundTransparency = 1
        statusInfo.Font = Enum.Font.GothamBold
        statusInfo.TextSize = 15
        statusInfo.TextXAlignment = Enum.TextXAlignment.Left
        statusInfo.Parent = infoSection
        
        GG.UI.StatusLabel = statusInfo

        -- FARMING PAGE CONTENT (BIGGER BUTTONS FOR MOBILE)
        local function createToggle(name, icon, stateKey, color)
            local toggleFrame = Instance.new("Frame")
            toggleFrame.Size = UDim2.new(1, 0, 0, 65)
            toggleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            toggleFrame.BorderSizePixel = 0
            toggleFrame.Parent = farmingPage
            
            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, 10)
            toggleCorner.Parent = toggleFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 300, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.Text = icon .. "  " .. name
            label.TextColor3 = Color3.fromRGB(220, 220, 220)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBold
            label.TextSize = 17
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = toggleFrame

            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0, 90, 0, 45)
            button.Position = UDim2.new(1, -105, 0.5, -22.5)
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            button.BorderSizePixel = 0
            button.Text = "OFF"
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.Font = Enum.Font.GothamBold
            button.TextSize = 16
            button.Parent = toggleFrame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 10)
            btnCorner.Parent = button

            button.MouseButton1Click:Connect(function()
                GG.State[stateKey] = not GG.State[stateKey]
                button.Text = GG.State[stateKey] and "ON" or "OFF"
                button.BackgroundColor3 = GG.State[stateKey] and color or Color3.fromRGB(60, 60, 60)
                
                if stateKey == "Enabled" then
                    updateStatus(GG.State[stateKey] and "✅ Auto Farming Active" or "⏸️ Auto Farming Paused", 
                               GG.State[stateKey] and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(255, 200, 100))
                end
            end)
        end

        createToggle("Auto Item Finder", "🔍", "Enabled", Color3.fromRGB(120, 200, 255))
        createToggle("Fast Attack", "⚡", "FastAttack", Color3.fromRGB(255, 100, 150))

        -- Server Hop Button (BIGGER FOR MOBILE)
        local hopFrame = Instance.new("Frame")
        hopFrame.Size = UDim2.new(1, 0, 0, 65)
        hopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        hopFrame.BorderSizePixel = 0
        hopFrame.Parent = farmingPage
        
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
        hopButton.TextSize = 18
        hopButton.Parent = hopFrame
        
        local hopBtnCorner = Instance.new("UICorner")
        hopBtnCorner.CornerRadius = UDim.new(0, 10)
        hopBtnCorner.Parent = hopButton
        
        hopButton.MouseButton1Click:Connect(function()
            safeHop()
        end)

        -- SETTINGS PAGE
        local settingsTitle = Instance.new("Frame")
        settingsTitle.Size = UDim2.new(1, 0, 0, 70)
        settingsTitle.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        settingsTitle.BorderSizePixel = 0
        settingsTitle.Parent = settingsPage
        
        local settingsTitleCorner = Instance.new("UICorner")
        settingsTitleCorner.CornerRadius = UDim.new(0, 10)
        settingsTitleCorner.Parent = settingsTitle

        local settingsLabel = Instance.new("TextLabel")
        settingsLabel.Size = UDim2.new(1, -20, 1, 0)
        settingsLabel.Position = UDim2.new(0, 10, 0, 0)
        settingsLabel.Text = "⚙️ Settings"
        settingsLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
        settingsLabel.BackgroundTransparency = 1
        settingsLabel.Font = Enum.Font.GothamBold
        settingsLabel.TextSize = 22
        settingsLabel.TextXAlignment = Enum.TextXAlignment.Left
        settingsLabel.Parent = settingsTitle

        local toggleInfo = Instance.new("Frame")
        toggleInfo.Size = UDim2.new(1, 0, 0, 100)
        toggleInfo.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        toggleInfo.BorderSizePixel = 0
        toggleInfo.Parent = settingsPage
        
        local toggleInfoCorner = Instance.new("UICorner")
        toggleInfoCorner.CornerRadius = UDim.new(0, 10)
        toggleInfoCorner.Parent = toggleInfo

        local toggleText = Instance.new("TextLabel")
        toggleText.Size = UDim2.new(1, -20, 1, -20)
        toggleText.Position = UDim2.new(0, 10, 0, 10)
        toggleText.Text = "👁️ Toggle UI Visibility:\n\nTap the floating button (⚡) on the left side of your screen to hide/show the main menu."
        toggleText.TextColor3 = Color3.fromRGB(200, 200, 200)
        toggleText.BackgroundTransparency = 1
        toggleText.Font = Enum.Font.Gotham
        toggleText.TextSize = 15
        toggleText.TextWrapped = true
        toggleText.TextYAlignment = Enum.TextYAlignment.Top
        toggleText.TextXAlignment = Enum.TextXAlignment.Left
        toggleText.Parent = toggleInfo

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
        versionText.Text = "📱 Version: v21 Mobile Optimized"
        versionText.TextColor3 = Color3.fromRGB(120, 200, 255)
        versionText.BackgroundTransparency = 1
        versionText.Font = Enum.Font.GothamBold
        versionText.TextSize = 15
        versionText.TextXAlignment = Enum.TextXAlignment.Left
        versionText.Parent = versionInfo
    end

    -- 6. ITEM OBSERVER
    game.Workspace.DescendantAdded:Connect(function(child)
        task.wait()
        
        if not GG.State.Enabled or GG.State.IsBusy then return end
        
        if child.Name == GG.State.TargetItem then
            local handle = child:FindFirstChild("Handle") or (child:IsA("BasePart") and child)
            
            if handle then
                GG.State.IsBusy = true
                updateStatus("🎯 Target Spotted!", Color3.fromRGB(255, 200, 0))
                
                task.wait(0.2)
                
                safeMove(handle.Position, function()
                    updateStatus("📦 Collecting...", Color3.fromRGB(255, 255, 100))
                    local root = getRoot()
                    
                    if root and handle.Parent then
                        pcall(function()
                            firetouchinterest(root, handle, 0)
                            task.wait(0.15)
                            firetouchinterest(root, handle, 1)
                        end)
                    end
                    
                    task.wait(0.5)
                    updateStatus("🔄 Returning...", Color3.fromRGB(100, 200, 255))
                    safeMove(GG.Config.Hub, function()
                        GG.State.IsBusy = false
                        updateStatus("✅ Ready", Color3.fromRGB(100, 255, 150))
                    end)
                end)
            end
        end
    end)

    -- 7. FAST ATTACK LOOP
    task.spawn(function()
        while task.wait(GG.Config.AttackDelay) do
            if GG.State.Enabled and GG.State.FastAttack then
                pcall(function()
                    local char = LP.Character
                    if char then
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool and tool:FindFirstChild("Handle") then
                            tool:Activate()
                        end
                    end
                end)
            end
        end
    end)

    buildUI()
    print("✅ Gravity Hub Mobile loaded!")
end)()
