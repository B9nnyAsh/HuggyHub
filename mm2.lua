-- Also works in MMV and other mm2 clones. Doesnt do a game compability check.
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/B9nnyAsh/Starry/refs/heads/main/Scripts/Library.lua"))()
local GameName = game:GetService("MarketplaceService"):GetProductInfoAsync(game.PlaceId).Name

-- Role Check
local Murderer = nil
local Sheriff = nil

local function check(item)
    if item.Name == "Knife" then
        Murderer = game.Players:GetPlayerFromCharacter(item.Parent) or Murderer
    elseif item.Name == "Gun" then
        Sheriff = game.Players:GetPlayerFromCharacter(item.Parent) or Sheriff
    end
end
-----------------------------------------------

for _, player in pairs(game.Players:GetPlayers()) do
    player.CharacterAppearanceLoaded:Connect(function(char)
        char.ChildAdded:Connect(check)
    end)
    if player.Character then
        player.Character.ChildAdded:Connect(check)
    end
end

game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(check)
    end)
end)

local Window = Library:Window({
    Title = "Seratin Hub",
    SubTitle = GameName
})

local MainPage = Window:NewPage({Title = "Main", Desc = "MM2 Features", Icon = 127194456372995})
local UniversalPage = Window:NewPage({Title = "Universal", Desc = "Movement & Fly", Icon = 127194456372995})

local wsEnabled, wsValue = false, 16
local jpEnabled, jpValue = false, 50
local cfEnabled, cfValue = false, 0
local flyEnabled, flySpeed = false, 50
local flyKey, grabKey = nil, nil

local ESP_Config = {
    AIO = false,
    Murderer = false,
    Sheriff = false,
    Innocent = false
}

local AutoGrab = false
local ESPObjects = {}
local COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 0, 255),
    Innocent = Color3.fromRGB(0, 255, 0)
}

local flying = false
local bv, bav
local buttons = {W = false, S = false, A = false, D = false}

local function getPlayerRole(player)
    local character = player.Character
    if not character then return "Innocent" end
    local backpack = player.Backpack
    if character:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife")) then
        return "Murderer"
    elseif character:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")) then
        return "Sheriff"
    end
    return "Innocent"
end

local function createESP(player)
    if player == game.Players.LocalPlayer then return end
    local esp = {Player = player}
    local billboard = Instance.new("BillboardGui", game.CoreGui)
    billboard.Name = "ESP_" .. player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    local textLabel = Instance.new("TextLabel", billboard)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    esp.BillboardGui = billboard
    esp.TextLabel = textLabel
    return esp
end

local function updateESP(esp)
    local player = esp.Player
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        esp.BillboardGui.Enabled = false
        if esp.Highlight then esp.Highlight.Enabled = false end
        return
    end
    
    local role = getPlayerRole(player)
    local isVisible = ESP_Config.AIO or ESP_Config[role]
    
    esp.BillboardGui.Adornee = character.HumanoidRootPart
    esp.BillboardGui.Enabled = isVisible
    
    local lp = game.Players.LocalPlayer
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local dist = math.floor((lp.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude)
        esp.TextLabel.Text = player.Name .. "\n[" .. role .. "]\n" .. dist .. "m"
    else
        esp.TextLabel.Text = player.Name .. "\n[" .. role .. "]"
    end
    esp.TextLabel.TextColor3 = COLORS[role]
    
    if not esp.Highlight or esp.Highlight.Adornee ~= character then
        if esp.Highlight then esp.Highlight:Destroy() end
        local highlight = Instance.new("Highlight", character)
        highlight.Adornee = character
        highlight.FillTransparency = 0.5
        esp.Highlight = highlight
    end
    esp.Highlight.Enabled = isVisible
    esp.Highlight.FillColor = COLORS[role]
    esp.Highlight.OutlineColor = COLORS[role]
end

local grabbing = false
local function grabLogic()
    if grabbing then return end
    local gundrop = workspace:FindFirstChild("GunDrop")
    local char = game.Players.LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if gundrop and root then
        grabbing = true
        local oldCF = root.CFrame
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            if gundrop:IsDescendantOf(workspace) and root then
                root.CFrame = gundrop.CFrame
            else
                connection:Disconnect()
                root.CFrame = oldCF
                grabbing = false
            end
        end)
    end
end

local function startFly()
    local char = game.Players.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    char.Humanoid.PlatformStand = true
    bv = Instance.new("BodyVelocity", char.HumanoidRootPart)
    bav = Instance.new("BodyAngularVelocity", char.HumanoidRootPart)
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bav.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flying = true
end

local function stopFly()
    flying = false
    if bv then bv:Destroy() end
    if bav then bav:Destroy() end
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.PlatformStand = false
    end
end

-- Fling Section
local function flingMurderer()
    local lp = game.Players.LocalPlayer
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local targetChar = Murderer and Murderer.Character
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

    if root and targetRoot then
        local oldCF = root.CFrame
        local vel = root.Velocity
        root.CanCollide = false
        
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            if Murderer and Murderer.Character and targetRoot then
                root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0)
                root.Velocity = Vector3.new(999999, 999999, 999999)
            else
                connection:Disconnect()
                root.CFrame = oldCF
                root.Velocity = vel
            end
        end)
        task.wait(0.5)
        if connection then connection:Disconnect() end
        root.CFrame = oldCF
        root.Velocity = vel
    end
end

local function flingSheriff()
    local lp = game.Players.LocalPlayer
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local targetChar = Sheriff and Sheriff.Character
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

    if root and targetRoot then
        local oldCF = root.CFrame
        local vel = root.Velocity
        root.CanCollide = false
        
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            if Sheriff and Sheriff.Character and targetRoot then
                root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0)
                root.Velocity = Vector3.new(999999, 999999, 999999)
            else
                connection:Disconnect()
                root.CFrame = oldCF
                root.Velocity = vel
            end
        end)
        task.wait(0.5)
        if connection then connection:Disconnect() end
        root.CFrame = oldCF
        root.Velocity = vel
    end
end

local function flingTarget(targetPlayer)
    local lp = game.Players.LocalPlayer
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local targetChar = targetPlayer and targetPlayer.Character
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

    if root and targetRoot then
        local oldCF = root.CFrame
        local vel = root.Velocity
        local oldCollide = root.CanCollide
        root.CanCollide = false
        
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            if targetPlayer and targetPlayer.Character and targetRoot then
                root.CFrame = targetRoot.CFrame
                root.Velocity = Vector3.new(999999, 999999, 999999)
            else
                connection:Disconnect()
                root.CFrame = oldCF
                root.Velocity = vel
                root.CanCollide = oldCollide
            end
        end)
        
        task.wait(0.5)
        if connection then connection:Disconnect() end
        root.CFrame = oldCF
        root.Velocity = vel
        root.CanCollide = oldCollide
    end
end

local function getPlayer(name)
    name = name:lower()
    for _, p in pairs(game.Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name) == name or p.DisplayName:lower():sub(1, #name) == name then
            return p
        end
    end
end

local selectedPlayerName = ""
------------------------------

MainPage:Section("Visuals")
MainPage:Toggle({Title = "All-in-one ESP", Desc = "Shows every player on the map", Value = false, Callback = function(v) ESP_Config.AIO = v end})
MainPage:Toggle({Title = "Murderer ESP", Desc = "Highlights only the murderer", Value = false, Callback = function(v) ESP_Config.Murderer = v end})
MainPage:Toggle({Title = "Sheriff ESP", Desc = "Highlights only the sheriff", Value = false, Callback = function(v) ESP_Config.Sheriff = v end})
MainPage:Toggle({Title = "Innocent ESP", Desc = "Highlights innocent players", Value = false, Callback = function(v) ESP_Config.Innocent = v end})

MainPage:Section("Automation")
MainPage:Toggle({Title = "Auto Grab Gun", Desc = "Automatically picks up dropped gun", Value = false, Callback = function(v) AutoGrab = v end})
MainPage:Button({Title = "Manual Grab Gun", Desc = "Teleports you to the gun instantly", Text = "Grab", Callback = function() grabLogic() end})
MainPage:Input({Title = "Grab Gun Key", Desc = "Set a shortcut key to grab gun", Value = "None", Callback = function(t) local s, k = pcall(function() return Enum.KeyCode[t:upper()] end) grabKey = s and k or nil end})

MainPage:Section("Fling")
MainPage:Button({Title = "Fling Murderer", Desc = "Flings murderer (sometimes fails, press again)", Text = "Fling", Callback = function() flingMurderer() end})
MainPage:Button({Title = "Fling Sheriff", Desc = "Flings sheriff (sometimes fails, press again)", Text = "Fling", Callback = function() flingSheriff() end})
MainPage:Input({
    Title = "Target Name",
    Desc = "Enter player name or display name",
    Value = "",
    Callback = function(t)
        selectedPlayerName = t
    end
})
MainPage:Button({
    Title = "Fling Player",
    Desc = "Flings the specified target",
    Text = "Fling",
    Callback = function()
        local target = getPlayer(selectedPlayerName)
        if target then
            flingTarget(target)
        end
    end
})

UniversalPage:Section("Movement")
UniversalPage:Toggle({Title = "Enable WalkSpeed", Desc = "Toggle custom movement speed", Value = false, Callback = function(v) wsEnabled = v end})
UniversalPage:Slider({Title = "WalkSpeed Value", Desc = "Adjust character speed", Min = 16, Max = 250, Value = 16, Callback = function(v) wsValue = v end})
UniversalPage:Toggle({Title = "Enable JumpPower", Desc = "Toggle custom jump strength", Value = false, Callback = function(v) jpEnabled = v end})
UniversalPage:Slider({Title = "JumpPower Value", Desc = "Adjust jump height", Min = 50, Max = 500, Value = 50, Callback = function(v) jpValue = v end})

UniversalPage:Section("CFrame Movement")
UniversalPage:Toggle({Title = "Enable CFrame Walk", Desc = "Glides through objects", Value = false, Callback = function(v) cfEnabled = v end})
UniversalPage:Slider({Title = "CFrame Value", Desc = "CFrame movement speed", Min = 0, Max = 100, Value = 0, Callback = function(v) cfValue = v end})

UniversalPage:Section("Fly Settings")
UniversalPage:Toggle({Title = "Fly", Desc = "Enables flight mode", Value = false, Callback = function(v) flyEnabled = v; if v then startFly() else stopFly() end end})
UniversalPage:Slider({Title = "Fly Speed", Desc = "Adjust flight speed", Min = 20, Max = 300, Value = 50, Callback = function(v) flySpeed = v end})
UniversalPage:Input({Title = "Fly Keybind", Desc = "Key to toggle fly mode", Value = "None", Callback = function(t) local s, k = pcall(function() return Enum.KeyCode[t:upper()] end) flyKey = s and k or nil end})

UniversalPage:Section("Misc")
UniversalPage:Button({
    Title = "Infinite Yield",
    Desc = "Load Infinite Yield",
    Text = "Load",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end
})
UniversalPage:Button({
    Title = "Advanced Fling GUI",
    Desc = "Load Advanced Fling GUI",
    Text = "Load",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/nvkob1/rbxscripts/refs/heads/main/FlingGUI/FlingGUI.lua"))()
    end
})

game:GetService("UserInputService").InputBegan:Connect(function(i, g)
    if g then return end
    if flyKey and i.KeyCode == flyKey then flyEnabled = not flyEnabled; if flyEnabled then startFly() else stopFly() end end
    if grabKey and i.KeyCode == grabKey then grabLogic() end
    if i.KeyCode == Enum.KeyCode.W then buttons.W = true end
    if i.KeyCode == Enum.KeyCode.S then buttons.S = true end
    if i.KeyCode == Enum.KeyCode.A then buttons.A = true end
    if i.KeyCode == Enum.KeyCode.D then buttons.D = true end
end)

game:GetService("UserInputService").InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.W then buttons.W = false end
    if i.KeyCode == Enum.KeyCode.S then buttons.S = false end
    if i.KeyCode == Enum.KeyCode.A then buttons.A = false end
    if i.KeyCode == Enum.KeyCode.D then buttons.D = false end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    local lp = game.Players.LocalPlayer
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if hum then
        if wsEnabled then hum.WalkSpeed = wsValue end
        if jpEnabled then hum.UseJumpPower = true; hum.JumpPower = jpValue end
    end
    
    if cfEnabled and root and hum and hum.MoveDirection.Magnitude > 0 then
        root.CFrame = root.CFrame + (hum.MoveDirection * cfValue / 50)
    end
    
    if flying and root and hum then
        local camCF = workspace.CurrentCamera.CFrame
        local dir = Vector3.new()
        if buttons.W then dir = dir + camCF.LookVector end
        if buttons.S then dir = dir - camCF.LookVector end
        if buttons.A then dir = dir - camCF.RightVector end
        if buttons.D then dir = dir + camCF.RightVector end
        bv.Velocity = dir * flySpeed
        root.CFrame = CFrame.new(root.Position, root.Position + camCF.LookVector)
    end
    
    if AutoGrab and workspace:FindFirstChild("GunDrop") and not grabbing then grabLogic() end

    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= lp then
            if not ESPObjects[p] then ESPObjects[p] = createESP(p) end
            updateESP(ESPObjects[p])
        end
    end
end)

task.spawn(function() while task.wait(1) do Library:SetTimeValue(os.date("%H:%M:%S")) end end)
