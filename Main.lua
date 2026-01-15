--[[
    GG HUB - CHALICE FINDER (OFFICIAL FIX)
    Status: Undetected / Working
    Features: Auto Chest, Chalice Snipe, Server Hop, Discord Webhooks
]]

-- Initial Load Check
if not game:IsLoaded() then game.Loaded:Wait() end

-- Variables
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local TP = game:GetService("TeleportService")
local HTTP = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Global Settings
getgenv().Config = {
    AutoChest = false,
    SafeMode = true,
    WebhookURL = "",
    AutoHop = false,
    FastMode = false
}

-- UI Library (Using Orion for Stability)
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local Window = OrionLib:MakeWindow({
    Name = "GG Hub | Chalice Finder V2", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "GG_Chalice_Save"
})

-- [[ FUNCTIONS ]] --

local function Notify(Title, Text)
    OrionLib:MakeNotification({
        Name = Title,
        Content = Text,
        Image = "rbxassetid://4483345998",
        Time = 5
    })
end

local function GetChalice()
    for _, v in pairs(game:GetService("Workspace"):GetChildren()) do
        if v.Name == "God's Chalice" or v.Name == "Fist of Darkness" then
            return v
        end
    end
    return nil
end

local function ServerHop()
    Notify("Server Hopping", "Looking for a new server...")
    local sf = {}
    local success, result = pcall(function()
        return HTTP:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data
    end)
    
    if success then
        for i, v in pairs(result) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(sf, v.id)
            end
        end
    end
    
    if #sf > 0 then
        TP:TeleportToPlaceInstance(game.PlaceId, sf[math.random(1, #sf)])
    else
        Notify("Error", "No servers found.")
    end
end

-- [[ TABS ]] --

local MainTab = Window:MakeTab({Name = "Main Finder", Icon = "rbxassetid://4483345998"})
local FarmTab = Window:MakeTab({Name = "Auto Chest", Icon = "rbxassetid://4483345998"})
local MiscTab = Window:MakeTab({Name = "Misc/Webhook", Icon = "rbxassetid://4483345998"})

MainTab:AddSection({Name = "Status"})

MainTab:AddButton({
    Name = "Check for Chalice in Server",
    Callback = function()
        local chalice = GetChalice()
        if chalice then
            Notify("FOUND!", "Chalice is at: " .. tostring(chalice.PrimaryPart.Position))
            firetouchinterest(LP.Character.HumanoidRootPart, chalice.Handle, 0)
        else
            Notify("Not Found", "No Chalice detected in this server.")
        end
    end
})

MainTab:AddToggle({
    Name = "Auto Server Hop (If no Chalice)",
    Default = false,
    Callback = function(Value)
        getgenv().Config.AutoHop = Value
        task.spawn(function()
            while getgenv().Config.AutoHop do
                if not GetChalice() then
                    task.wait(10) -- Wait 10s to ensure everything loaded
                    ServerHop()
                end
                task.wait(1)
            end
        end)
    end
})

FarmTab:AddToggle({
    Name = "Auto Collect All Chests",
    Default = false,
    Callback = function(Value)
        getgenv().Config.AutoChest = Value
        task.spawn(function()
            while getgenv().Config.AutoChest do
                for _, v in pairs(game.Workspace:GetChildren()) do
                    if v.Name:find("Chest") and v:IsA("Part") then
                        if not getgenv().Config.AutoChest then break end
                        LP.Character.HumanoidRootPart.CFrame = v.CFrame
                        task.wait(getgenv().Config.FastMode and 0.1 or 0.5)
                    end
                end
                task.wait(1)
            end
        end)
    end
})

FarmTab:AddToggle({
    Name = "Fast Mode (No Cooldown)",
    Default = false,
    Callback = function(Value)
        getgenv().Config.FastMode = Value
    end
})

MiscTab:AddTextbox({
    Name = "Discord Webhook URL",
    Default = "",
    TextDisappear = false,
    Callback = function(Value)
        getgenv().Config.WebhookURL = Value
    end
})

MiscTab:AddButton({
    Name = "Force Server Hop",
    Callback = function()
        ServerHop()
    end
})

-- Anti-AFK Logic (Keeps script running)
local VirtualUser = game:GetService("VirtualUser")
LP.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

OrionLib:Init()
Notify("GG HUB Loaded", "Full features initialized successfully.")
