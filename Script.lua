-- [[ GG HUB v13: ALL-IN-ONE PRODUCTION BUILD ]] --
(function()
    -- 1. BOOTER INITIALIZATION (Visual Feedback)
    local sg = Instance.new("ScreenGui", game:GetService("CoreGui"))
    local bootFrame = Instance.new("Frame", sg)
    bootFrame.Size = UDim2.new(0, 250, 0, 80)
    bootFrame.Position = UDim2.new(0.5, -125, 0.5, -40)
    bootFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    
    local bootLabel = Instance.new("TextLabel", bootFrame)
    bootLabel.Size = UDim2.new(1, 0, 1, 0)
    bootLabel.Text = "GG HUB: LOADING COMPONENTS..."
    bootLabel.TextColor3 = Color3.new(1, 1, 1)
    bootLabel.BackgroundTransparency = 1

    task.wait(1.5) -- Simulated load for effect/stability
    bootFrame:Destroy()

    -- 2. MAIN CORE CONFIG
    local _R = {
        RS = game:GetService("RunService"),
        LP = game:GetService("Players").LocalPlayer,
        HUB = Vector3.new(-5024, 315, -3156),
        TARGETS = {"God's Chalice", "Fist of Darkness"}
    }

    local _SET = {
        Enabled = false,
        FastAttack = false,
        Gen = 0,
        IsActive = false,
        LastItem = nil
    }

    -- 3. UI CONTROLLER (Draggable & Functional)
    local UI = { Label = nil }
    function UI:Build()
        local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
        local main = Instance.new("Frame", gui)
        main.Size = UDim2.new(0, 200, 0, 210)
        main.Position = UDim2.new(0.05, 0, 0.4, 0)
        main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        main.Active = true
        main.Draggable = true 

        local close = Instance.new("TextButton", main)
        close.Text = "X"
        close.Size = UDim2.new(0, 25, 0, 25)
        close.Position = UDim2.new(1, -30, 0, 5)
        close.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        close.TextColor3 = Color3.new(1, 1, 1)
        close.MouseButton1Click:Connect(function() gui:Destroy() end)

        self.Label = Instance.new("TextLabel", main)
        self.Label.Size = UDim2.new(1, 0, 0, 35)
        self.Label.Text = "STATUS: READY"
        self.Label.TextColor3 = Color3.new(0, 1, 0)
        self.Label.BackgroundTransparency = 1

        local function createBtn(name, pos, callback)
            local b = Instance.new("TextButton", main)
            b.Size = UDim2.new(0.9, 0, 0, 35)
            b.Position = UDim2.new(0.05, 0, 0.22 + (pos * 0.22), 0)
            b.Text = name
            b.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            b.TextColor3 = Color3.new(1, 1, 1)
            b.MouseButton1Click:Connect(function() callback(b) end)
        end

        createBtn("TOGGLE FINDER", 0, function(b)
            _SET.Enabled = not _SET.Enabled
            b.BackgroundColor3 = _SET.Enabled and Color3.new(0, 0.5, 0) or Color3.fromRGB(40, 40, 40)
            UI:Update(_SET.Enabled and "IDLE" or "OFF")
        end)

        createBtn("FAST ATTACK", 1, function(b)
            _SET.FastAttack = not _SET.FastAttack
            b.BackgroundColor3 = _SET.FastAttack and Color3.new(0, 0.5, 0) or Color3.fromRGB(40, 40, 40)
        end)

        createBtn("SERVER HOP", 2, function()
            game:GetService("TeleportService"):Teleport(game.PlaceId)
        end)
    end

    function UI:Update(txt)
        if self.Label then self.Label.Text = "STATUS: " .. txt end
    end

    -- 4. MOVEMENT & COLLECTION
    local function safeMove(targetPos, isReturning)
        _SET.Gen = _SET.Gen + 1
        local myGen = _SET.Gen
        local root = _R.LP.Character and _R.LP.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local startPos = root.Position
        local control = (startPos + targetPos)/2 + Vector3.new(0, 50, 0)
        local duration = (startPos - targetPos).Magnitude / 165
        local elapsed = 0

        local conn; conn = _R.RS.Heartbeat:Connect(function(dt)
            if not isReturning and (_SET.LastItem == nil or _SET.LastItem.Parent ~= workspace) then
                conn:Disconnect()
                _SET.IsActive = false
                UI:Update("TARGET LOST")
                return
            end

            if _SET.Gen ~= myGen or not _SET.Enabled or not root.Parent then
                conn:Disconnect()
                return
            end

            elapsed = elapsed + dt
            local t = math.min(elapsed / duration, 1)
            local p = (1-t)^2 * startPos + 2*(1-t)*t * control + t^2 * targetPos
            
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = CFrame.new(p, targetPos)

            if t >= 1 then
                conn:Disconnect()
                if not isReturning then
                    UI:Update("COLLECTING...")
                    firetouchinterest(root, _SET.LastItem.Handle, 0)
                    task.wait(0.1)
                    firetouchinterest(root, _SET.LastItem.Handle, 1)
                    task.wait(0.5)
                    UI:Update("RETURNING")
                    safeMove(_R.HUB, true)
                else
                    _SET.IsActive = false
                    UI:Update("IDLE (SAFE)")
                end
            end
        end)
    end

    -- 5. STARTUP & LISTENERS
    UI:Build()

    workspace.ChildAdded:Connect(function(child)
        if not _SET.Enabled or _SET.IsActive then return end
        if table.find(_R.TARGETS, child.Name) then
            local h = child:WaitForChild("Handle", 5)
            if h then
                _SET.IsActive = true
                _SET.LastItem = child
                UI:Update("FOUND: " .. child.Name)
                safeMove(h.Position, false)
            end
        end
    end)

    _R.RS.Heartbeat:Connect(function()
        if _SET.FastAttack and _SET.Enabled then
            local tool = _R.LP.Character and _R.LP.Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end
    end)
end)()
