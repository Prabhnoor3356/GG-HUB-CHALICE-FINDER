-- [[ GG HUB v21: FIXED VERSION ]] --
(function()
    -- 1. CENTRALIZED CORE (Unified State & Config)
    local GG = {
        State = {
            Enabled = false,
            FastAttack = false,
            IsBusy = false,
            ThreadID = 0,
            TargetItem = (game.PlaceId == 444224521) and "Fist of Darkness" or "God's Chalice"
        },
        Config = {
            Hub = Vector3.new(-5024, 315, -3156),
            Speed = 175,
            AttackDelay = 0.12
        },
        Connections = {}
    }

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local CoreGui = game:GetService("CoreGui")
    
    local LP = Players.LocalPlayer

    -- 2. ROBUST UTILITIES
    local function getRoot()
        return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    end

    local function updateStatus(txt, color)
        if GG.UI_Status then
            GG.UI_Status.Text = txt:upper()
            GG.UI_Status.TextColor3 = color or Color3.new(1, 1, 1)
        end
    end

    -- 3. THE MOVEMENT ENGINE (Fixed)
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

        -- Disconnect old movement if it exists
        if GG.Connections.Move then 
            GG.Connections.Move:Disconnect() 
        end

        GG.Connections.Move = RunService.Heartbeat:Connect(function(dt)
            local currentRoot = getRoot()
            -- Interrupts: Death, New Command, or Disabled
            if not currentRoot or GG.State.ThreadID ~= currentThread or not GG.State.Enabled then
                if GG.Connections.Move then 
                    GG.Connections.Move:Disconnect() 
                end
                GG.State.IsBusy = false
                return
            end

            elapsed = elapsed + dt
            local t = math.min(elapsed / duration, 1)
            
            -- Fixed: Using AssemblyLinearVelocity properly
            if currentRoot.AssemblyLinearVelocity then
                currentRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            currentRoot.CFrame = CFrame.new(startPos:Lerp(targetPos, t))

            if t >= 1 then
                GG.Connections.Move:Disconnect()
                if callback then 
                    callback() 
                end
            end
        end)
    end

    -- 4. SERVER HOP (Fixed)
    local function safeHop()
        updateStatus("SEARCHING SERVERS...", Color3.new(1, 1, 0))
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
            updateStatus("HOP FAILED - NO SERVERS", Color3.new(1, 0, 0))
        end)
    end

    -- 5. UI IMPLEMENTATION (Fixed)
    local function buildUI()
        -- Remove old UI if exists
        if CoreGui:FindFirstChild("GGHub") then
            CoreGui:FindFirstChild("GGHub"):Destroy()
        end
        
        local sg = Instance.new("ScreenGui")
        sg.Name = "GGHub"
        sg.Parent = CoreGui
        sg.ResetOnSpawn = false
        
        local main = Instance.new("Frame")
        main.Size = UDim2.new(0, 400, 0, 250)
        main.Position = UDim2.new(0.5, -200, 0.5, -125)
        main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        main.BorderSizePixel = 0
        main.Active = true
        main.Draggable = true
        main.Parent = sg
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = main

        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0, 130, 0, 40)
        title.Position = UDim2.new(0, 5, 0, 5)
        title.Text = "GG HUB v21"
        title.TextColor3 = Color3.fromRGB(0, 255, 150)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 18
        title.Parent = main

        -- Status
        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, -140, 0, 40)
        status.Position = UDim2.new(0, 140, 0, 5)
        status.Text = "READY | " .. GG.State.TargetItem
        status.TextColor3 = Color3.new(0, 1, 0.6)
        status.BackgroundTransparency = 1
        status.Font = Enum.Font.GothamBold
        status.TextSize = 14
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Parent = main
        
        GG.UI_Status = status

        -- Button creator
        local function createBtn(name, y, stateKey, color)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 240, 0, 35)
            b.Position = UDim2.new(0, 140, 0, y)
            b.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            b.BorderSizePixel = 0
            b.Text = name
            b.TextColor3 = Color3.new(1, 1, 1)
            b.Font = Enum.Font.Gotham
            b.TextSize = 14
            b.Parent = main
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = b
            
            b.MouseButton1Click:Connect(function()
                if stateKey then
                    GG.State[stateKey] = not GG.State[stateKey]
                    b.BackgroundColor3 = GG.State[stateKey] and color or Color3.fromRGB(35, 35, 35)
                    
                    if stateKey == "Enabled" then
                        updateStatus(GG.State[stateKey] and "AUTO FINDER ON" or "READY", 
                                   GG.State[stateKey] and Color3.new(0, 1, 0) or Color3.new(0, 1, 0.6))
                    end
                else
                    safeHop()
                end
            end)
        end

        createBtn("AUTO FINDER", 60, "Enabled", Color3.fromRGB(0, 100, 255))
        createBtn("FAST ATTACK", 105, "FastAttack", Color3.fromRGB(255, 0, 80))
        createBtn("SERVER SEARCH", 150, nil, nil)
        
        -- Close button
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 30, 0, 30)
        closeBtn.Position = UDim2.new(1, -35, 0, 5)
        closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "X"
        closeBtn.TextColor3 = Color3.new(1, 1, 1)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 16
        closeBtn.Parent = main
        
        local closeBtnCorner = Instance.new("UICorner")
        closeBtnCorner.CornerRadius = UDim.new(0, 8)
        closeBtnCorner.Parent = closeBtn
        
        closeBtn.MouseButton1Click:Connect(function()
            GG.State.Enabled = false
            GG.State.FastAttack = false
            if GG.Connections.Move then
                GG.Connections.Move:Disconnect()
            end
            sg:Destroy()
        end)
    end

    -- 6. ITEM OBSERVER & COLLECTION (Fixed)
    game.Workspace.DescendantAdded:Connect(function(child)
        task.wait() -- Small delay to ensure object is fully loaded
        
        if not GG.State.Enabled or GG.State.IsBusy then return end
        
        if child.Name == GG.State.TargetItem then
            local handle = child:FindFirstChild("Handle") or (child:IsA("BasePart") and child)
            
            if handle then
                GG.State.IsBusy = true
                updateStatus("TARGET SPOTTED!", Color3.new(1, 0.5, 0))
                
                task.wait(0.2) -- Small delay before moving
                
                safeMove(handle.Position, function()
                    -- ARRIVED: Start Collection
                    updateStatus("COLLECTING...", Color3.new(1, 1, 0))
                    local root = getRoot()
                    
                    if root and handle.Parent then
                        -- Try to collect the item
                        pcall(function()
                            firetouchinterest(root, handle, 0)
                            task.wait(0.15)
                            firetouchinterest(root, handle, 1)
                        end)
                    end
                    
                    task.wait(0.5)
                    updateStatus("RETURNING...", Color3.new(0, 1, 1))
                    safeMove(GG.Config.Hub, function()
                        GG.State.IsBusy = false
                        updateStatus("READY", Color3.new(0, 1, 0.6))
                    end)
                end)
            end
        end
    end)

    -- 7. FAST ATTACK LOOP (Fixed)
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

    -- Initialize UI
    buildUI()
    updateStatus("LOADED SUCCESSFULLY", Color3.new(0, 1, 0))
    print("GG Hub v21 loaded successfully!")
end)()
