-- [[ GG HUB v26: GHOST AUTOMATION ]] --
(function()
    local GG = {
        State = {
            Enabled = false,
            FastAttack = false,
            BringMob = false,
            AutoFarmLevel = false,
            IsBusy = false,
            TargetItem = (game.PlaceId == 2753915549) and "God's Chalice" or "Fist of Darkness"
        },
        Config = {
            Hub = Vector3.new(-5024, 315, -3156),
            Speed = 300,
            AttackDelay = 0.12,
            MobRadius = 250,
            MaxItemDist = 3000 -- Fix 2: Safety distance for items
        },
        Cache = { Mobs = {} },
        UI = {}
    }

    local Services = setmetatable({}, {__index = function(_, k) return game:GetService(k) end})
    local LP = Services.Players.LocalPlayer

    -- 1. CHARACTER UTILS
    local function getSafeRoot()
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        return (hum and hum.Health > 0 and char:FindFirstChild("HumanoidRootPart")) or nil
    end

    -- 2. DYNAMIC MOB BRINGING (Fix 3: Implementation & Collision Reset)
    task.spawn(function()
        local lastScan = 0
        while task.wait(0.1) do
            local root = getSafeRoot()
            if not root then continue end

            if GG.State.Enabled and GG.State.BringMob then
                if tick() - lastScan > 1.5 then
                    GG.Cache.Mobs = {}
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v:FindFirstChild("HumanoidRootPart") then table.insert(GG.Cache.Mobs, v) end
                    end
                    lastScan = tick()
                end

                for _, mob in pairs(GG.Cache.Mobs) do
                    local mRoot = mob:FindFirstChild("HumanoidRootPart")
                    if mob.Parent and mRoot then
                        local dist = (mRoot.Position - root.Position).Magnitude
                        if dist < GG.Config.MobRadius then
                            mRoot.CFrame = root.CFrame * CFrame.new(0, -2, -5)
                            mRoot.CanCollide = false
                        end
                    end
                end
            else
                -- Fix 3: Global Cleanup when disabled
                if #GG.Cache.Mobs > 0 then
                    for _, mob in pairs(GG.Cache.Mobs) do
                        if mob.Parent and mob:FindFirstChild("HumanoidRootPart") then
                            mob.HumanoidRootPart.CanCollide = true
                        end
                    end
                    GG.Cache.Mobs = {}
                end
            end
        end
    end)

    -- 3. SMART AUTO-FARM (Fix 1: Dynamic Height)
    task.spawn(function()
        while task.wait(0.1) do
            if GG.State.AutoFarmLevel and not GG.State.IsBusy then
                local root = getSafeRoot()
                if root then
                    local closest = nil
                    local minDist = math.huge
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        local eRoot = v:FindFirstChild("HumanoidRootPart")
                        local hum = v:FindFirstChildOfClass("Humanoid")
                        if eRoot and hum and hum.Health > 0 then
                            local d = (eRoot.Position - root.Position).Magnitude
                            if d < minDist then minDist = d; closest = eRoot end
                        end
                    end
                    
                    if closest then
                        -- Fix 1: Dynamic Height Logic
                        local optimalHeight = math.min(math.max(minDist/10, 15), 30)
                        root.CFrame = closest.CFrame * CFrame.new(0, optimalHeight, 0)
                    end
                end
            end
        end
    end)

    -- 4. ITEM WATCHER (Fix 2: Distance Check)
    workspace.DescendantAdded:Connect(function(child)
        if not GG.State.Enabled or GG.State.IsBusy then return end
        if child.Name == GG.State.TargetItem then
            local root = getSafeRoot()
            local handle = child:WaitForChild("Handle", 5) or (child:IsA("BasePart") and child)
            if root and handle then
                -- Fix 2: Safety Validation
                local dist = (root.Position - handle.Position).Magnitude
                if dist < GG.Config.MaxItemDist then
                    GG.State.IsBusy = true
                    root.CFrame = handle.CFrame
                    task.wait(0.2)
                    firetouchinterest(root, handle, 0)
                    task.wait(0.1)
                    firetouchinterest(root, handle, 1)
                    task.wait(0.5)
                    root.CFrame = CFrame.new(GG.Config.Hub)
                    GG.State.IsBusy = false
                else
                    warn("TARGET BLOCKED: Item beyond safe distance (" .. math.floor(dist) .. " studs)")
                end
            end
        end
    end)

    -- 5. FAST ATTACK ENGINE
    task.spawn(function()
        local lastAttack = 0
        while true do
            Services.RunService.Heartbeat:Wait()
            if GG.State.Enabled and GG.State.FastAttack and (tick() - lastAttack) >= GG.Config.AttackDelay then
                local root = getSafeRoot()
                if not root then continue end
                
                local targets = {}
                for _, enemy in pairs(workspace.Enemies:GetChildren()) do
                    local eRoot = enemy:FindFirstChild("HumanoidRootPart")
                    if eRoot and (eRoot.Position - root.Position).Magnitude < 70 then
                        table.insert(targets, enemy)
                    end
                end

                if #targets > 0 then
                    local rigEvent = Services.ReplicatedStorage:FindFirstChild("RigControllerEvent")
                    if rigEvent then
                        rigEvent:FireServer("hit", targets, 2, "")
                        lastAttack = tick()
                    end
                end
            end
        end
    end)

    -- UI (Standard Build)
    local function buildUI()
        local sg = Instance.new("ScreenGui", Services.CoreGui)
        local main = Instance.new("Frame", sg)
        main.Size = UDim2.new(0, 300, 0, 320)
        main.Position = UDim2.new(0.5, -150, 0.5, -160)
        main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        main.Active = true; main.Draggable = true
        Instance.new("UICorner", main)

        local status = Instance.new("TextLabel", main)
        status.Size = UDim2.new(1, 0, 0, 40)
        status.Text = "GG HUB v26"
        status.TextColor3 = Color3.new(1, 1, 1)
        status.BackgroundTransparency = 1
        GG.UI.StatusLabel = status

        local function createBtn(name, y, stateKey)
            local b = Instance.new("TextButton", main)
            b.Size = UDim2.new(0.8, 0, 0, 35)
            b.Position = UDim2.new(0.1, 0, 0, y)
            b.Text = name
            b.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            b.TextColor3 = Color3.new(1, 1, 1)
            Instance.new("UICorner", b)
            b.MouseButton1Click:Connect(function()
                GG.State[stateKey] = not GG.State[stateKey]
                b.BackgroundColor3 = GG.State[stateKey] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(35, 35, 35)
            end)
        end

        createBtn("MASTER TOGGLE", 60, "Enabled")
        createBtn("AUTO FARM LEVEL", 110, "AutoFarmLevel")
        createBtn("FAST ATTACK", 160, "FastAttack")
        createBtn("BRING MOBS", 210, "BringMob")
    end

    buildUI()
end)()
