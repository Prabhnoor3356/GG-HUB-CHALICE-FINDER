-- [[ GG HUB v13: THE POLISHED SPECTRE ]] --
(function()
    -- 1. POINTERS & CONFIG
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

    -- 2. DYNAMIC UI CONTROLLER
    local UI = { Label = nil }
    function UI:Build()
        local sg = Instance.new("ScreenGui", game:GetService("CoreGui"))
        local main = Instance.new("Frame", sg)
        main.Size = UDim2.new(0, 200, 0, 210)
        main.Position = UDim2.new(0.05, 0, 0.4, 0)
        main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        main.BorderSizePixel = 0

        -- [OPTIMIZATION 2: Draggable & Close Button]
        main.Active = true
        main.Draggable = true 
        
        local close = Instance.new("TextButton", main)
        close.Text = "X"
        close.Size = UDim2.new(0, 25, 0, 25)
        close.Position = UDim2.new(1, -30, 0, 5)
        close.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        close.TextColor3 = Color3.new(1, 1, 1)
        close.MouseButton1Click:Connect(function() sg:Destroy() end)

        self.Label = Instance.new("TextLabel", main)
        self.Label.Size = UDim2.new(1, 0, 0, 35)
        self.Label.Text = "STATUS: OFF"
        self.Label.TextColor3 = Color3.new(0, 1, 0)
        self.Label.BackgroundTransparency = 1

        local function createBtn(name, pos, callback)
            local b = Instance.new("TextButton", main)
            b.Size = UDim2.new(0.9, 0, 0, 35)
            b.Position = UDim2.new(0.05, 0, 0.22 + (pos * 0.22), 0)
            b.Text = name
            b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            b.TextColor3 = Color3.new(1, 1, 1)
            b.BorderSizePixel = 0
            b.MouseButton1Click:Connect(function() callback(b) end)
        end

        createBtn("TOGGLE FINDER", 0, function(b)
            _SET.Enabled = not _SET.Enabled
            b.BackgroundColor3 = _SET.Enabled and Color3.new(0, 0.5, 0) or Color3.fromRGB(45, 45, 45)
            UI:Update(_SET.Enabled and "IDLE" or "OFF")
        end)

        createBtn("FAST ATTACK", 1, function(b)
            _SET.FastAttack = not _SET.FastAttack
            b.BackgroundColor3 = _SET.FastAttack and Color3.new(0, 0.5, 0) or Color3.fromRGB(45, 45, 45)
        end)

        createBtn("SERVER HOP", 2, function()
            UI:Update("HOPPING...")
            game:GetService("TeleportService"):Teleport(game.PlaceId)
        end)
    end

    function UI:Update(txt)
        if self.Label then self.Label.Text = "STATUS: " .. txt end
    end

    -- 3. BÉZIER MOVEMENT ENGINE (Optimization 1: Item Parent Guard)
    local function safeMove(targetPos, isReturning)
        _SET.Gen = _SET.Gen + 1
        local myGen = _SET.Gen
        local char = _R.LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local startPos = root.Position
        local control = (startPos + targetPos)/2 + Vector3.new(0, 45, 0)
        local duration = (startPos - targetPos).Magnitude / 165
        local elapsed = 0

        local conn; conn = _R.RS.Heartbeat:Connect(function(dt)
            -- [OPTIMIZATION 1: Target Lost Logic]
            if not isReturning and (_SET.LastItem == nil or _SET.LastItem.Parent ~= workspace) then
                conn:Disconnect()
                _SET.IsActive = false
                UI:Update("TARGET LOST")
                return
            end

            -- Interruption Guard
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

    -- 4. OBSERVER
    workspace.ChildAdded:Connect(function(child)
        if not _SET.Enabled or _SET.IsActive then return end
        if child:IsA("Tool") and table.find(_R.TARGETS, child.Name) then
            local handle = child:WaitForChild("Handle", 5)
            if handle then
                _SET.IsActive = true
                _SET.LastItem = child
                UI:Update("TARGET: " .. child.Name:upper())
                safeMove(handle.Position, false)
            end
        end
    end)

    -- 5. STARTUP
    pcall(function() UI:Build() end)

    _R.RS.Heartbeat:Connect(function()
        if _SET.FastAttack and _SET.Enabled then
            local tool = _R.LP.Character and _R.LP.Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end
    end)
end)()
