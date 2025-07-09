--// UI LIBRARY
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = library.CreateLib("Nellix", "DarkTheme")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Add White Stroke Function
local function addStroke(guiObject, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(255, 255, 255)
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = guiObject
end

--// Add stroke to all frames and buttons
task.delay(1, function()
    for _, v in pairs(game.CoreGui:GetDescendants()) do
        if v:IsA("Frame") or v:IsA("TextButton") or v:IsA("TextLabel") then
            pcall(function()
                if not v:FindFirstChildOfClass("UIStroke") then
                    addStroke(v)
                end
            end)
        end
    end
end)

--// 1. Movement Tab
local Movement = Window:NewTab("Movement")
local MoveSec = Movement:NewSection("Speed/Jump/Fly")

MoveSec:NewSlider("Speed", "Adjust walk speed", 200, 16, function(val)
    LocalPlayer.Character.Humanoid.WalkSpeed = val
end)

MoveSec:NewSlider("Jump", "Adjust jump power", 300, 50, function(val)
    LocalPlayer.Character.Humanoid.JumpPower = val
end)

local flying = false
local flySpeed = 2
local flyConn = nil
local bodyGyro = nil
local bodyVelocity = nil

MoveSec:NewSlider("Fly Speed", "Adjust fly speed", 10, 1, function(val)
    flySpeed = val
end)

MoveSec:NewToggle("Fly", "Toggle flight", function(state)
    flying = state
    local humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")

    if state then
        bodyGyro = Instance.new("BodyGyro")
        bodyVelocity = Instance.new("BodyVelocity")

        bodyGyro.P = 9e4
        bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.CFrame = humanoidRootPart.CFrame
        bodyGyro.Parent = humanoidRootPart

        bodyVelocity.velocity = Vector3.zero
        bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVelocity.Parent = humanoidRootPart

        flyConn = RunService.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            local moveDir = Vector3.zero
            pcall(function()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit
                    bodyVelocity.Velocity = moveDir * flySpeed * 10
                else
                    bodyVelocity.Velocity = Vector3.zero
                end
                bodyGyro.CFrame = cam.CFrame
            end)
        end)
    else
        if bodyGyro then bodyGyro:Destroy() end
        if bodyVelocity then bodyVelocity:Destroy() end
        if flyConn then flyConn:Disconnect() end
        bodyGyro = nil
        bodyVelocity = nil
        flyConn = nil
    end
end)

-- Spider Climb
local spiderEnabled = false
local climbSpeed = 50

local function isNearWall()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end

    local hrp = char.HumanoidRootPart
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local dirs = {
        hrp.CFrame.LookVector,
        -hrp.CFrame.LookVector,
        hrp.CFrame.RightVector,
        -hrp.CFrame.RightVector,
    }

    for _, dir in ipairs(dirs) do
        local result = workspace:Raycast(hrp.Position, dir * 2, rayParams)
        if result then return true end
    end

    return false
end

RunService.RenderStepped:Connect(function()
    if not spiderEnabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and isNearWall() then
        hrp.Velocity = Vector3.new(hrp.Velocity.X, climbSpeed, hrp.Velocity.Z)
    end
end)

MoveSec:NewToggle("Spider Climb", "Быстрое лазание по стенам и крышам", function(state)
    spiderEnabled = state
end)

--// 2. Defender Tab
local Defender = Window:NewTab("Defender")
local DefSec = Defender:NewSection("Defensive Tools")

DefSec:NewToggle("No Clip", "Walk through walls", function(state)
    RunService:UnbindFromRenderStep("Noclip")
    if state then
        RunService:BindToRenderStep("Noclip", 1, function()
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
end)

DefSec:NewToggle("ESP", "Highlight players", function(state)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local highlight = player.Character:FindFirstChild("Highlight")
            if state and not highlight then
                local h = Instance.new("Highlight")
                h.FillColor = Color3.fromRGB(255, 50, 50)
                h.FillTransparency = 0.4
                h.OutlineTransparency = 1
                h.Adornee = player.Character
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = player.Character
            elseif not state and highlight then
                highlight:Destroy()
            end
        end
    end
end)

DefSec:NewToggle("God Mode", "High HP mode", function(state)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then
        hum.MaxHealth = state and 1e9 or 100
        hum.Health = hum.MaxHealth
    end
end)

--// 3. Visuals
local Visuals = Window:NewTab("Visuals")
local VisSec = Visuals:NewSection("Lighting and Items")

VisSec:NewToggle("FullBright", "Max brightness", function(state)
    if state then
        game.Lighting.Brightness = 10
        game.Lighting.ClockTime = 14
    else
        game.Lighting.Brightness = 1
    end
end)

VisSec:NewToggle("Item ESP", "Highlight ground items", function(state)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") or obj.Name:lower():find("pickup") then
            if state then
                if not obj:FindFirstChild("Highlight") then
                    local h = Instance.new("Highlight")
                    h.FillColor = Color3.fromRGB(50, 100, 255)
                    h.FillTransparency = 0.5
                    h.OutlineTransparency = 1
                    h.Parent = obj
                end
            else
                local h = obj:FindFirstChild("Highlight")
                if h then h:Destroy() end
            end
        end
    end
end)

--// 4. Render Tab
local Render = Window:NewTab("Render")
local RenderSec = Render:NewSection("Teleport Players")

local selectedPlayer = nil
local playersDropdown

local function updatePlayerList()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(list, player.Name)
        end
    end
    if playersDropdown then
        playersDropdown:Refresh(list, true)
    end
end

playersDropdown = RenderSec:NewDropdown("Choose Player", "Select someone", {}, function(p)
    selectedPlayer = p
end)

updatePlayerList()
task.spawn(function()
    while task.wait(5) do
        updatePlayerList()
    end
end)

RenderSec:NewButton("Teleport to Player", "Go to them", function()
    if selectedPlayer then
        local plr = Players:FindFirstChild(selectedPlayer)
        if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character:MoveTo(plr.Character.HumanoidRootPart.Position + Vector3.new(2, 0, 0))
        end
    end
end)

RenderSec:NewButton("Teleport Player to You", "Bring them", function()
    if selectedPlayer then
        local plr = Players:FindFirstChild(selectedPlayer)
        if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(3, 0, 0)
        end
    end
end)

--// 5. Extras Tab
local Extras = Window:NewTab("Extras")
local ExtrasSection = Extras:NewSection("Extra Tools")

ExtrasSection:NewButton("Auto Join", "Join same game on different server", function()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local PlaceId = game.PlaceId
    local JobId = game.JobId

    local scriptSource = game:HttpGet("https://raw.githubusercontent.com/yourusername/yourrepo/main/yourScript.lua")
    queue_on_teleport(scriptSource)

    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _, server in pairs(servers.data) do
        if server.id ~= JobId then
            TeleportService:TeleportToPlaceInstance(PlaceId, server.id)
            break
        end
    end
end)

local lastPlaceId = nil
ExtrasSection:NewTextBox("Find Player (Username)", "Check status", function(name)
    local HttpService = game:GetService("HttpService")
    local req = (syn and syn.request or http_request or request)
    local success, result = pcall(function()
        return req({
            Url = "https://api.roblox.com/users/get-by-username?username="..name,
            Method = "GET"
        })
    end)

    if success and result and result.Body then
        local userData = HttpService:JSONDecode(result.Body)
        if userData and userData.Id then
            local uid = userData.Id
            local presenceResult = req({
                Url = "https://presence.roblox.com/v1/presence/users",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({ userIds = { uid } })
            })
            local pres = HttpService:JSONDecode(presenceResult.Body)
            local info = pres.userPresences[1]
            local status = ""
            if info.userPresenceType == 2 then
                lastPlaceId = info.rootPlaceId
                status = "В игре: "..info.lastLocation
            elseif info.userPresenceType == 1 then
                status = "Онлайн в меню"
            else
                status = "Оффлайн"
            end
            local label = ExtrasSection:NewLabel("["..name.."] - "..status)
            task.delay(7, function() label:Remove() end)
        else
            local label = ExtrasSection:NewLabel("["..name.."] - Не найден")
            task.delay(7, function() label:Remove() end)
        end
    end
end)

ExtrasSection:NewButton("Join Player Game", "Join their game", function()
    if lastPlaceId then
        game:GetService("TeleportService"):Teleport(lastPlaceId)
    end
end)

ExtrasSection:NewButton("Go Dupe", "Duplicate held tools", function()
    local backpack = game.Players.LocalPlayer:FindFirstChild("Backpack")
    local char = game.Players.LocalPlayer.Character
    if backpack and char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local dupe = tool:Clone()
                dupe.Parent = backpack
            end
        end
    end
end)

ExtrasSection:NewToggle("Infinity Jump", "Бесконечные прыжки", function(state)
    infJumpEnabled = state
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if infJumpEnabled and game.Players.LocalPlayer.Character then
        local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

local function isBrainrotGame()
    return game.PlaceId == 17454934040
end

local function setupBrainrotBypass()
    if not isBrainrotGame() then return end

    local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
    local function disableCollisions()
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    RunService.Stepped:Connect(function()
        if char and char:FindFirstChild("HumanoidRootPart") then
            disableCollisions()
        end
    end)

    local mt = getrawmetatable(game)
    local oldIndex = mt.__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(t, k)
        if tostring(k):lower():find("collide") then
            return true
        end
        return oldIndex(t, k)
    end)
    setreadonly(mt, true)
end

setupBrainrotBypass()

