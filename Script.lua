-- [[ GG HUB v18: PERSISTENCE & SAFETY UPDATE ]] --
local GGHUB = {
    _VERSION = "18.0.0",
    _ACTIVE = true,
    
    State = {
        Running = false,
        Combat = false,
        Busy = false,
        ThreadID = 0,
        LastTarget = nil
    },
    
    Settings = {
        Speed = 170,
        Targets = {"God's Chalice", "Fist of Darkness"},
        Hub = Vector3.new(-5024, 315, -3156),
        SafeHealth = 20
    }
}

-- 1. SERVICE PROVIDER & UTILS
local Services = setmetatable({}, {__index = function(t, k) return game:GetService(k) end})

function GGHUB:Log(level, message)
    local colors = {INFO = Color3.new(1,1,1), WARN = Color3.new(1,1,0), ERROR = Color3.new(1,0,0)}
    print(string.format("[%s] GG HUB: %s", level, message))
    if self.StatusLabel then
        self.StatusLabel.Text = message:upper()
        self.StatusLabel.TextColor3 = colors[level] or colors.INFO
    end
end

-- 2. CONFIGURATION PERSISTENCE (Fix 4: Saving/Loading)
function GGHUB:SaveSettings()
    local success, err = pcall(function()
        local data = Services.HttpService:JSONEncode({
            Speed = self.Settings.Speed,
            Combat = self.State.Combat,
            Running = self.State.Running
        })
        writefile("GGHUB_Config.json", data)
    end)
    if not success then self:Log("WARN", "Save Failed: " .. tostring(err)) end
end

function GGHUB:LoadSettings()
    if isfile("GGHUB_Config.json") then
        local success, data = pcall(function()
            return Services.HttpService:JSONDecode(readfile("GGHUB_Config.json"))
        end)
        if success then
            self.Settings.Speed = data.Speed or self.Settings.Speed
            self:Log("INFO", "Settings Loaded")
        end
    end
end

-- 3. EMERGENCY STOP (Fix 2: Safety Kill-switch)
function GGHUB:EmergencyStop()
    self._ACTIVE = false
    self.State.Running = false
    self.State.Combat = false
    if self.MovementConn then self.MovementConn:Disconnect() end
    if self.MainGui then self.MainGui:Destroy() end
    self:Log("ERROR", "EMERGENCY SHUTDOWN EXECUTED")
end

Services.UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.P then
        GGHUB:EmergencyStop()
    end
end)

-- 4. UI IMPLEMENTATION (Fix 1: Full Implementation)
local UI = {}
function UI:Build()
    local sg = Instance.new("ScreenGui", Services.CoreGui)
    GGHUB.MainGui = sg
    
    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 220, 0, 240)
    main.Position = UDim2.new(0.05, 0, 0.4, 0)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    main.Active = true
    main.Draggable = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    
    local label = Instance.new("TextLabel", main)
    label.Size = UDim2.new(1, 0, 0, 40)
    label.BackgroundTransparency = 1
    label.Text = "GG HUB " .. GGHUB._VERSION
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    GGHUB.StatusLabel = label

    local function createBtn(text, yPos, toggleState, color)
        local btn = Instance.new("TextButton", main)
        btn.Size = UDim2.new(0.9, 0, 0, 40)
        btn.Position = UDim2.new(0.05, 0, 0, yPos)
        btn.Text = text
        btn.BackgroundColor3 = GGHUB.State[toggleState] and color or Color3.fromRGB(40,40,40)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.Gotham
        Instance.new("UICorner", btn)

        btn.MouseButton1Click:Connect(function()
            GGHUB.State[toggleState] = not GGHUB.State[toggleState]
            btn.BackgroundColor3 = GGHUB.State[toggleState] and color or Color3.fromRGB(40,40,40)
            GGHUB:SaveSettings()
            GGHUB:Log("INFO", text .. " " .. (GGHUB.State[toggleState] and "ON" or "OFF"))
        end)
    end

    createBtn("TOGGLE FINDER", 50, "Running", Color3.fromRGB(0, 150, 80))
    createBtn("FAST ATTACK", 100, "Combat", Color3.fromRGB(150, 0, 50))
    createBtn("FORCE SERVER HOP", 150, "Busy", Color3.fromRGB(80, 80, 80)) -- Dummy state for hop
end

-- 5. REFACTORED MOVEMENT ENGINE
local Movement = {}
function Movement:Fly(targetPos, callback)
    GGHUB.State.ThreadID = GGHUB.State.ThreadID + 1
    local currentID = GGHUB.State.ThreadID
    local root = Services.Players.LocalPlayer.Character and Services.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local start = root.Position
    local duration = (start - targetPos).Magnitude / GGHUB.Settings.Speed
    local elapsed = 0

    if GGHUB.MovementConn then GGHUB.MovementConn:Disconnect() end

    GGHUB.MovementConn = Services.RunService.Heartbeat:Connect(function(dt)
        if GGHUB.State.ThreadID ~= currentID or not GGHUB._ACTIVE then 
            if GGHUB.MovementConn then GGHUB.MovementConn:Disconnect() end
            return 
        end
        
        elapsed = elapsed + dt
        local t = math.min(elapsed / duration, 1)
        root.CFrame = CFrame.new(start:Lerp(targetPos, t), targetPos)
        root.AssemblyLinearVelocity = Vector3.zero

        if t >= 1 then
            GGHUB.MovementConn:Disconnect()
            if callback then callback() end
        end
    end)
end

-- 6. INITIALIZATION
GGHUB:LoadSettings()
UI:Build()
GGHUB:Log("INFO", "System Ready. Press 'P' to Kill.")

-- Fast Attack Loop
task.spawn(function()
    while GGHUB._ACTIVE do
        if GGHUB.State.Running and GGHUB.State.Combat then
            pcall(function()
                local tool = Services.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end)
        end
        task.wait(0.12)
    end
end)

-- Item Observer
Services.Workspace.DescendantAdded:Connect(function(child)
    if GGHUB.State.Running and not GGHUB.State.Busy and table.find(GGHUB.Settings.Targets, child.Name) then
        local h = child:WaitForChild("Handle", 5) or child:IsA("BasePart") and child
        if h then
            GGHUB.State.Busy = true
            GGHUB:Log("WARN", "Target Found: " .. child.Name)
            Movement:Fly(h.Position, function()
                -- Collect and Return Logic...
                task.wait(1)
                Movement:Fly(GGHUB.Settings.Hub, function() GGHUB.State.Busy = false end)
            end)
        end
    end
end)
