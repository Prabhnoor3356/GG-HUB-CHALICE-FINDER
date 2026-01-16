-- [[ GG HUB v32: PERFORMANCE & PHYSICS STABLE ]] --
(function()
    local function cleanup(name)
        local existing = game:GetService("CoreGui"):FindFirstChild(name)
        if existing then existing:Destroy() end
    end
    cleanup("GG_HUB_V32")

    local GG = {
        State = { Enabled = false, FastAttack = false, BringMob = false, AutoFarm = false, IsBusy = false },
        Config = {
            Hubs = { [2753915549] = Vector3.new(-5024, 315, -3156), [444224521] = Vector3.new(0, 100, 0) },
            Items = { [2753915549] = "God's Chalice", [444224521] = "Fist of Darkness" },
            MaxTeleportDist = 3500,
            HitboxRange = 65,
            AttackCooldown = 0.12 -- Fix 2: Cooldown constant
        },
        Cache = { Mobs = {} },
        UI = {}
    }

    local Services = setmetatable({}, {__index = function(_, k) return game:GetService(k) end})
    local LP = Services.Players.LocalPlayer
    local TargetItemName = GG.Config.Items[game.PlaceId] or "Common Treasure"
    local ReturnHub = GG.Config.Hubs[game.PlaceId] or Vector3.new(0, 50, 0)
    local LastAttackTick = 0 -- Fix 2: State variable

    local function getRoot()
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then return hrp end
        end
        return nil
    end

    local function updateStatus(txt, color)
        if GG.UI.StatusLabel then
            GG.UI.StatusLabel.Text = "STATUS: " .. tostring(txt):upper()
            GG.UI.StatusLabel.TextColor3 = color or Color3.new(1, 1, 1)
        end
    end

    -- 1. SMART CACHE REFRESH (Fix 1)
    task.spawn(function()
        while task.wait(1) do
            -- Fix 1: Only refresh if combat features are ON
            if GG.State.Enabled and (GG.State.AutoFarm or GG.State.BringMob or GG.State.FastAttack) then
                pcall(function()
                    local root = getRoot()
                    local folder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("NPCs")
                    local temp = {}
                    if folder and root then
                        for _, v in pairs(folder:GetChildren()) do
                            local hum = v:FindFirstChildOfClass("Humanoid")
                            local mRoot = v:FindFirstChild("HumanoidRootPart")
                            if hum and mRoot and hum.Health > 0 then
                                table.insert(temp, v)
                            end
                        end
                        table.sort(temp, function(a, b)
                            return (a.HumanoidRootPart.Position - root.Position).Magnitude < (b.HumanoidRootPart.Position - root.Position).Magnitude
                        end)
                    end
                    GG.Cache.Mobs = temp
                end)
            else
                GG.Cache.Mobs = {} -- Clear cache when idle
            end
        end
    end)

    -- 2. MAIN SCHEDULER
    task.spawn(function()
        while task.wait(0.05) do -- High frequency check
            if GG.State.Enabled and not GG.State.IsBusy then
                local root = getRoot()
                if root then
                    -- MOB BRINGING & COLLISION RESET (Fix 3)
                    if GG.State.BringMob then
                        for i = 1, #GG.Cache.Mobs do
                            local m = GG.Cache.Mobs[i]
                            if m and m:FindFirstChild("HumanoidRootPart") then
                                m.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0, 0, -5)
                                if m.HumanoidRootPart.CanCollide then m.HumanoidRootPart.CanCollide = false end
                            end
                        end
                    else
                        -- Fix 3: Automatic Reset when BringMob is OFF
                        for i = 1, #GG.Cache.Mobs do
                            local m = GG.Cache.Mobs[i]
                            if m and m:FindFirstChild("HumanoidRootPart") and not m.HumanoidRootPart.CanCollide then
                                m.HumanoidRootPart.CanCollide = true
                            end
                        end
                    end

                    -- FAST ATTACK WITH COOLDOWN (Fix 2)
                    if GG.State.FastAttack and (tick() - LastAttackTick) >= GG.Config.AttackCooldown then
                        local targets = {}
                        for i = 1, #GG.Cache.Mobs do
                            local m = GG.Cache.Mobs[i]
                            if m and m:FindFirstChild("HumanoidRootPart") and (m.HumanoidRootPart.Position - root.Position).Magnitude <= GG.Config.HitboxRange then
                                table.insert(targets, m)
                            end
                        end
                        if #targets > 0 then
                            local re = Services.ReplicatedStorage:FindFirstChild("RigControllerEvent")
                            if re then 
                                re:FireServer("hit", targets, 2, "") 
                                LastAttackTick = tick() -- Fix 2: Set last attack
                            end
                        end
                    end

                    -- AUTO FARM
                    if GG.State.AutoFarm and #GG.Cache.Mobs > 0 then
                        root.CFrame = GG.Cache.Mobs[1].HumanoidRootPart.CFrame * CFrame.new(0, 25, 0)
                    end
                end
            end
        end
    end)

    -- 3. ITEM COLLECTION (Same as V31)
    workspace.DescendantAdded:Connect(function(child)
        if GG.State.Enabled and not GG.State.IsBusy and child.Name == TargetItemName then
            pcall(function()
                local handle = child:FindFirstChild("Handle") or (child:IsA("BasePart") and child)
                local root = getRoot()
                if handle and root then
                    if (root.Position - handle.Position).Magnitude <= GG.Config.MaxTeleportDist then
                        GG.State.IsBusy = true
                        updateStatus("COLLECTING " .. child.Name, Color3.new(1, 0.6, 0))
                        root.CFrame = handle.CFrame
                        for i = 1, 5 do
                            firetouchinterest(root, handle, 0); firetouchinterest(root, handle, 1)
                            task.wait(0.2)
                            if child.Parent == LP.Character or child.Parent == LP.Backpack then break end
                        end
                        task.wait(0.5); root.CFrame = CFrame.new(ReturnHub)
                        GG.State.IsBusy = false; updateStatus("READY", Color3.new(0, 1, 0.5))
                    end
                end
            end)
        end
    end)

    -- 4. UI (Responsive)
    local sg = Instance.new("ScreenGui", Services.CoreGui); sg.Name = "GG_HUB_V32"
    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 300, 0, 350); main.Position = UDim2.new(0.5, -150, 0.5, -175)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 20); main.Active = true; main.Draggable = true
    Instance.new("UICorner", main)

    local status = Instance.new("TextLabel", main)
    status.Size = UDim2.new(1, 0, 0, 50); status.Text = "STATUS: READY"
    status.TextColor3 = Color3.new(0, 1, 0.5); status.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    status.Font = Enum.Font.GothamBold; GG.UI.StatusLabel = status

    local function createBtn(name, state, y)
        local b = Instance.new("TextButton", main)
        b.Size = UDim2.new(0.8, 0, 0, 40); b.Position = UDim2.new(0.1, 0, 0, y)
        b.Text = name; b.BackgroundColor3 = Color3.fromRGB(40, 40, 40); b.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", b)
        b.MouseButton1Click:Connect(function()
            if not GG.State.IsBusy then
                GG.State[state] = not GG.State[state]
                b.BackgroundColor3 = GG.State[state] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(40, 40, 40)
            end
        end)
    end

    createBtn("MASTER TOGGLE", "Enabled", 60)
    createBtn("AUTO FARM", "AutoFarm", 110)
    createBtn("FAST ATTACK", "FastAttack", 160)
    createBtn("BRING MOBS", "BringMob", 210)
end)()
