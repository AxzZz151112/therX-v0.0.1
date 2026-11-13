-- =============================================
--   therX v0.1.0 by AxzZz
--   Fly | Inf Jump | Auto Walk | Speed | NoClip | God Mode
--   Teleport | Anti-Void | ESP | Chams | Record | Anti Lag
--   FPS/Ping | Player List | Rejoin | Copy Map
--   UI: Liquid Glass Horizontal Wide
-- =============================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local StatsService     = game:GetService("Stats")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")

local Player = Players.LocalPlayer
if not Player then
    warn("[therX] LocalPlayer tidak ditemukan. Jalankan script dari client/executor.")
    return
end

-- Tunggu PlayerGui, lalu tampilkan loading UI sebelum inisialisasi fitur.
local PlayerGui = Player:WaitForChild("PlayerGui")

-- LOADING UI: tampilan terpisah, tidak mengubah desain utama therX.
local previousLoader = PlayerGui:FindFirstChild("therX_Loading")
if previousLoader then previousLoader:Destroy() end

local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "therX_Loading"
loadingGui.ResetOnSpawn = false
loadingGui.IgnoreGuiInset = false
loadingGui.DisplayOrder = 10000
loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
loadingGui.Parent = PlayerGui

local loadingCard = Instance.new("Frame")
loadingCard.Name = "LoadingCard"
loadingCard.Size = UDim2.new(0, 310, 0, 126)
loadingCard.AnchorPoint = Vector2.new(0.5, 0.5)
loadingCard.Position = UDim2.new(0.5, 0, 0.5, 0)
loadingCard.BackgroundColor3 = Color3.fromRGB(14, 7, 28)
loadingCard.BackgroundTransparency = 0.06
loadingCard.BorderSizePixel = 0
loadingCard.Parent = loadingGui
Instance.new("UICorner", loadingCard).CornerRadius = UDim.new(0, 16)
local loadingStroke = Instance.new("UIStroke", loadingCard)
loadingStroke.Color = Color3.fromRGB(160, 100, 255)
loadingStroke.Transparency = 0.3
loadingStroke.Thickness = 1

local loadingTitle = Instance.new("TextLabel")
loadingTitle.BackgroundTransparency = 1
loadingTitle.Position = UDim2.new(0, 18, 0, 14)
loadingTitle.Size = UDim2.new(1, -36, 0, 24)
loadingTitle.Font = Enum.Font.GothamBold
loadingTitle.Text = "therX"
loadingTitle.TextColor3 = Color3.fromRGB(230, 218, 255)
loadingTitle.TextSize = 19
loadingTitle.TextXAlignment = Enum.TextXAlignment.Left
loadingTitle.Parent = loadingCard

local loadingStatus = Instance.new("TextLabel")
loadingStatus.BackgroundTransparency = 1
loadingStatus.Position = UDim2.new(0, 18, 0, 43)
loadingStatus.Size = UDim2.new(1, -36, 0, 18)
loadingStatus.Font = Enum.Font.Gotham
loadingStatus.Text = "Menyiapkan script..."
loadingStatus.TextColor3 = Color3.fromRGB(150, 125, 190)
loadingStatus.TextSize = 10
loadingStatus.TextXAlignment = Enum.TextXAlignment.Left
loadingStatus.Parent = loadingCard

local loadingPercent = Instance.new("TextLabel")
loadingPercent.BackgroundTransparency = 1
loadingPercent.Position = UDim2.new(1, -62, 0, 43)
loadingPercent.Size = UDim2.new(0, 44, 0, 18)
loadingPercent.Font = Enum.Font.GothamBold
loadingPercent.Text = "0%"
loadingPercent.TextColor3 = Color3.fromRGB(190, 155, 255)
loadingPercent.TextSize = 10
loadingPercent.TextXAlignment = Enum.TextXAlignment.Right
loadingPercent.Parent = loadingCard

local loadingTrack = Instance.new("Frame")
loadingTrack.Position = UDim2.new(0, 18, 0, 78)
loadingTrack.Size = UDim2.new(1, -36, 0, 7)
loadingTrack.BackgroundColor3 = Color3.fromRGB(42, 28, 62)
loadingTrack.BorderSizePixel = 0
loadingTrack.ClipsDescendants = true
loadingTrack.Parent = loadingCard
Instance.new("UICorner", loadingTrack).CornerRadius = UDim.new(1, 0)

local loadingFill = Instance.new("Frame")
loadingFill.Size = UDim2.new(0, 0, 1, 0)
loadingFill.BackgroundColor3 = Color3.fromRGB(160, 100, 255)
loadingFill.BorderSizePixel = 0
loadingFill.Parent = loadingTrack
Instance.new("UICorner", loadingFill).CornerRadius = UDim.new(1, 0)
local loadingGradient = Instance.new("UIGradient", loadingFill)
loadingGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 170, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 100, 255)),
})

local function setLoadingProgress(percent, status)
    percent = math.clamp(math.floor(percent), 0, 100)
    loadingPercent.Text = tostring(percent) .. "%"
    if status then loadingStatus.Text = status end
    TweenService:Create(loadingFill, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(percent / 100, 0, 1, 0)
    }):Play()
end

setLoadingProgress(0, "Memulai therX...")

local Character = Player.Character or Player.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart", 10)
local Humanoid = Character:WaitForChild("Humanoid", 10)
local Camera = workspace.CurrentCamera

if not HRP or not Humanoid then
    warn("[therX] Karakter belum siap (Humanoid/HRP tidak ditemukan).")
    loadingGui:Destroy()
    return
end
setLoadingProgress(20, "Karakter siap...")

-- Referensi karakter diperbarui ketika respawn agar fitur tidak memakai karakter lama.
Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HRP = newCharacter:WaitForChild("HumanoidRootPart")
    Humanoid = newCharacter:WaitForChild("Humanoid")
    Camera = workspace.CurrentCamera
end)

-- =============================================
-- STATE
-- =============================================
local State = {
    fly         = false,
    infiniteJ   = false,
    autoWalk    = false,
    antiLag     = false,
    recording   = false,
    noclip      = false,
    godMode     = false,
    antiVoid    = false,
    espEnabled  = false,
    chams       = false,
    flySpeed    = 50,
    jumpPower   = 100,
    walkSpeed   = 16,
    speedHack   = 16,
    mapName     = "Unknown Map",
    obsName     = "Unknown Obstacle",
}

local SavedRoutes  = {}
local WaypointLog  = {}
local RecordStart  = 0
local RecordConn, AutoWalkConn, FlyConn, JumpConn
local NoclipConn, AntiVoidConn, GodConn
local EspObjects   = {}
local ChamsObjects = {}
local BodyVel, BodyGyro
local OrigSettings = {}

-- =============================================
-- UTILITY
-- =============================================
local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quad), props):Play()
end

local function notify(title, msg, dur)
    local sg = Instance.new("ScreenGui", PlayerGui)
    sg.Name = "therXN_"..tostring(math.random(1000,9999))
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0,265,0,54)
    f.Position = UDim2.new(1,10,0,18)
    f.BackgroundColor3 = Color3.fromRGB(14,7,28)
    f.BackgroundTransparency = 0.05
    f.BorderSizePixel = 0
    local fc = Instance.new("UICorner", f); fc.CornerRadius = UDim.new(0,12)
    local fs = Instance.new("UIStroke", f); fs.Color = Color3.fromRGB(160,100,255); fs.Transparency = 0.45
    local acc = Instance.new("Frame", f)
    acc.Size = UDim2.new(0,3,0.65,0); acc.Position = UDim2.new(0,0,0.17,0)
    acc.BackgroundColor3 = Color3.fromRGB(160,100,255); acc.BorderSizePixel = 0
    Instance.new("UICorner", acc).CornerRadius = UDim.new(0,3)
    local t1 = Instance.new("TextLabel", f)
    t1.Size = UDim2.new(1,-16,0,18); t1.Position = UDim2.new(0,12,0,8)
    t1.BackgroundTransparency = 1; t1.Text = title
    t1.TextColor3 = Color3.fromRGB(220,200,255); t1.Font = Enum.Font.GothamBold; t1.TextSize = 11
    t1.TextXAlignment = Enum.TextXAlignment.Left
    local t2 = Instance.new("TextLabel", f)
    t2.Size = UDim2.new(1,-16,0,14); t2.Position = UDim2.new(0,12,0,28)
    t2.BackgroundTransparency = 1; t2.Text = msg
    t2.TextColor3 = Color3.fromRGB(130,95,175); t2.Font = Enum.Font.Gotham; t2.TextSize = 9
    t2.TextXAlignment = Enum.TextXAlignment.Left
    tween(f, {Position = UDim2.new(1,-280,0,18)}, 0.3)
    task.delay(dur or 2.5, function()
        tween(f, {Position = UDim2.new(1,10,0,18)}, 0.2)
        task.delay(0.25, function() sg:Destroy() end)
    end)
end

-- =============================================
-- FLY
-- =============================================
local function enableFly()
    if FlyConn then FlyConn:Disconnect() end
    if BodyVel then BodyVel:Destroy() end
    if BodyGyro then BodyGyro:Destroy() end
    BodyVel = Instance.new("BodyVelocity", HRP)
    BodyVel.Velocity = Vector3.zero; BodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
    BodyGyro = Instance.new("BodyGyro", HRP)
    BodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5); BodyGyro.P = 1e4
    FlyConn = RunService.Heartbeat:Connect(function()
        if not State.fly then return end
        local d = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then d += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then d -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then d -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then d += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d -= Vector3.new(0,1,0) end
        BodyVel.Velocity = d.Magnitude > 0 and d.Unit * State.flySpeed or Vector3.zero
        BodyGyro.CFrame = Camera.CFrame
    end)
    Humanoid.PlatformStand = true
    notify("therX | Fly","Aktif — WASD + Space/Shift",2)
end
local function disableFly()
    if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
    if BodyVel then BodyVel:Destroy(); BodyVel = nil end
    if BodyGyro then BodyGyro:Destroy(); BodyGyro = nil end
    Humanoid.PlatformStand = false
    notify("therX | Fly","Nonaktif",1.5)
end

-- =============================================
-- INFINITY JUMP
-- =============================================
local function enableInfiniteJump()
    JumpConn = UserInputService.JumpRequest:Connect(function()
        if State.infiniteJ then
            Humanoid.JumpPower = State.jumpPower
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    notify("therX | Infinity Jump","Aktif",2)
end
local function disableInfiniteJump()
    if JumpConn then JumpConn:Disconnect(); JumpConn = nil end
    notify("therX | Infinity Jump","Nonaktif",1.5)
end

-- =============================================
-- AUTO WALK
-- =============================================
local function enableAutoWalk()
    Humanoid.WalkSpeed = State.walkSpeed
    AutoWalkConn = RunService.Heartbeat:Connect(function()
        if State.autoWalk then Humanoid:Move(Vector3.new(0,0,-1), false) end
    end)
    notify("therX | Auto Walk","Aktif — speed "..State.walkSpeed,2)
end
local function disableAutoWalk()
    if AutoWalkConn then AutoWalkConn:Disconnect(); AutoWalkConn = nil end
    Humanoid.WalkSpeed = 16
    notify("therX | Auto Walk","Nonaktif",1.5)
end

-- =============================================
-- SPEED HACK
-- =============================================
local function applySpeed(v)
    State.speedHack = v
    Humanoid.WalkSpeed = v
end

-- =============================================
-- NOCLIP
-- =============================================
local function enableNoclip()
    NoclipConn = RunService.Stepped:Connect(function()
        if not State.noclip then return end
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    notify("therX | NoClip","Aktif — tembus dinding",2)
end
local function disableNoclip()
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then pcall(function() part.CanCollide = true end) end
    end
    notify("therX | NoClip","Nonaktif",1.5)
end

-- =============================================
-- GOD MODE
-- =============================================
local function enableGodMode()
    Humanoid.MaxHealth = math.huge
    Humanoid.Health = math.huge
    GodConn = RunService.Heartbeat:Connect(function()
        if State.godMode then
            if Humanoid.Health < Humanoid.MaxHealth then
                Humanoid.Health = Humanoid.MaxHealth
            end
        end
    end)
    notify("therX | God Mode","Aktif — HP ∞",2)
end
local function disableGodMode()
    if GodConn then GodConn:Disconnect(); GodConn = nil end
    Humanoid.MaxHealth = 100; Humanoid.Health = 100
    notify("therX | God Mode","Nonaktif",1.5)
end

-- =============================================
-- ANTI-VOID
-- =============================================
local lastSafePos = HRP.Position
local function enableAntiVoid()
    AntiVoidConn = RunService.Heartbeat:Connect(function()
        if not State.antiVoid then return end
        if HRP.Position.Y > -50 then
            lastSafePos = HRP.Position
        else
            HRP.CFrame = CFrame.new(lastSafePos + Vector3.new(0,5,0))
            notify("therX | Anti-Void","Void terdeteksi — teleported",2)
        end
    end)
    notify("therX | Anti-Void","Aktif — anti jatuh void",2)
end
local function disableAntiVoid()
    if AntiVoidConn then AntiVoidConn:Disconnect(); AntiVoidConn = nil end
    notify("therX | Anti-Void","Nonaktif",1.5)
end

-- =============================================
-- TELEPORT TO PLAYER
-- =============================================
local function teleportToPlayer(name)
    local target = Players:FindFirstChild(name)
    if not target or not target.Character then
        notify("therX | Teleport","Player tidak ditemukan: "..name,2); return
    end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if tHRP then
        HRP.CFrame = tHRP.CFrame + Vector3.new(2,0,2)
        notify("therX | Teleport","Teleport ke "..name,2)
    end
end

-- =============================================
-- ESP
-- =============================================
local function clearEsp()
    for _, obj in pairs(EspObjects) do pcall(function() obj:Destroy() end) end
    EspObjects = {}
end
local function updateEsp()
    clearEsp()
    if not State.espEnabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local chr = plr.Character
            local head = chr:FindFirstChild("Head")
            if head then
                local bb = Instance.new("BillboardGui", head)
                bb.Size = UDim2.new(0,80,0,30)
                bb.StudsOffset = Vector3.new(0,2.5,0)
                bb.AlwaysOnTop = true
                local nl = Instance.new("TextLabel", bb)
                nl.Size = UDim2.new(1,0,1,0)
                nl.BackgroundTransparency = 0.3
                nl.BackgroundColor3 = Color3.fromRGB(14,7,28)
                nl.Text = plr.Name
                nl.TextColor3 = Color3.fromRGB(160,100,255)
                nl.Font = Enum.Font.GothamBold
                nl.TextSize = 11
                nl.BorderSizePixel = 0
                Instance.new("UICorner", nl).CornerRadius = UDim.new(0,6)
                table.insert(EspObjects, bb)
            end
        end
    end
end
local EspUpdateConn
local function enableEsp()
    updateEsp()
    EspUpdateConn = RunService.Heartbeat:Connect(function()
        if State.espEnabled then updateEsp() end
    end)
    notify("therX | ESP","Aktif — nama player terlihat",2)
end
local function disableEsp()
    if EspUpdateConn then EspUpdateConn:Disconnect(); EspUpdateConn = nil end
    clearEsp()
    notify("therX | ESP","Nonaktif",1.5)
end

-- =============================================
-- CHAMS
-- =============================================
local function clearChams()
    for part, orig in pairs(ChamsObjects) do
        pcall(function()
            part.Color = orig.color
            part.Material = orig.mat
        end)
    end
    ChamsObjects = {}
end
local function applyChams()
    clearChams()
    if not State.chams then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            for _, part in ipairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    ChamsObjects[part] = {color=part.Color, mat=part.Material}
                    part.Color = Color3.fromRGB(80,170,255)
                    part.Material = Enum.Material.Neon
                end
            end
        end
    end
end
local ChamsConn
local function enableChams()
    applyChams()
    ChamsConn = RunService.Heartbeat:Connect(function()
        if State.chams then applyChams() end
    end)
    notify("therX | Chams","Aktif — highlight player",2)
end
local function disableChams()
    if ChamsConn then ChamsConn:Disconnect(); ChamsConn = nil end
    clearChams()
    notify("therX | Chams","Nonaktif",1.5)
end

-- =============================================
-- ANTI LAG / POTATO MODE
-- =============================================
local function enablePotatoMode()
    OrigSettings.GlobalShadows = workspace.GlobalShadows
    workspace.GlobalShadows = false; Lighting.GlobalShadows = false; Lighting.FogEnd = 100000
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke")
            or obj:IsA("Sparkles") or obj:IsA("Trail") or obj:IsA("Beam") then
            pcall(function() obj.Enabled = false end)
        end
        if obj:IsA("Sky") then pcall(function() obj.Parent = game:GetService("ReplicatedStorage") end) end
        if obj:IsA("Decal") or obj:IsA("Texture") then pcall(function() obj.Transparency = 1 end) end
        if obj:IsA("PostEffect") or obj:IsA("BlurEffect") or obj:IsA("BloomEffect")
            or obj:IsA("ColorCorrectionEffect") or obj:IsA("DepthOfFieldEffect")
            or obj:IsA("SunRaysEffect") then
            pcall(function() obj.Enabled = false end)
        end
    end
    pcall(function() workspace.MeshPartHeadsAndAccessories = Enum.MeshPartHeadsAndAccessories.Disabled end)
    notify("therX | Potato Mode","Anti Lag aktif — grafik minimal",3)
end
local function disablePotatoMode()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    if OrigSettings.GlobalShadows ~= nil then workspace.GlobalShadows = OrigSettings.GlobalShadows end
    pcall(function() workspace.MeshPartHeadsAndAccessories = Enum.MeshPartHeadsAndAccessories.Default end)
    notify("therX | Potato Mode","Nonaktif — grafik normal",2)
end

-- =============================================
-- RECORD
-- =============================================
local function startRecord()
    WaypointLog = {}; RecordStart = tick(); State.recording = true
    RecordConn = RunService.Heartbeat:Connect(function()
        if not State.recording then return end
        local pos = HRP.Position
        if #WaypointLog == 0 or (WaypointLog[#WaypointLog] - pos).Magnitude > 3 then
            table.insert(WaypointLog, pos)
        end
    end)
    notify("therX | Record","Merekam ["..State.mapName.."]",2)
end
local function stopRecord()
    State.recording = false
    if RecordConn then RecordConn:Disconnect(); RecordConn = nil end
    notify("therX | Record","Berhenti — "..#WaypointLog.." waypoints",2)
end
local function saveRecord()
    if #WaypointLog == 0 then notify("therX | Save","Belum ada waypoints!",2); return end
    local dur = math.floor(tick() - RecordStart)
    table.insert(SavedRoutes, {
        mapName = State.mapName, obsName = State.obsName,
        waypoints = table.clone(WaypointLog), duration = dur, timestamp = os.date("%H:%M"),
    })
    notify("therX | Saved","["..State.mapName.."] ("..#WaypointLog.." pts)",3)
    WaypointLog = {}
end

-- =============================================
-- COPY MAP NAME
-- =============================================
local function copyMapName()
    local mapName = workspace.Name
    pcall(function()
        for _, v in ipairs(workspace:GetChildren()) do
            if v:IsA("Model") and v.Name ~= "Camera" then mapName = v.Name; break end
        end
    end)
    State.mapName = mapName
    pcall(function() setclipboard(mapName) end)
    notify("therX | Map","Nama map: "..mapName,3)
    return mapName
end

-- =============================================
-- REJOIN
-- =============================================
local function rejoin()
    notify("therX | Rejoin","Rejoining server...",2)
    task.delay(1, function()
        TeleportService:Teleport(game.PlaceId, Player)
    end)
end

setLoadingProgress(35, "Menyiapkan fitur dan komponen...")

-- =============================================
-- GUI
-- =============================================
-- Bersihkan GUI lama agar eksekusi ulang tidak menumpuk atau tertutup UI duplikat.
local oldGui = PlayerGui:FindFirstChild("therX_v3")
if oldGui then oldGui:Destroy() end

task.wait(0.1) -- beri waktu PlayerGui siap setelah loading screen
local gui = Instance.new("ScreenGui")
gui.Name = "therX_v3"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui
setLoadingProgress(48, "Membangun antarmuka utama...")

local miniBar  -- forward declare

-- Color palette
local C = {
    bg      = Color3.fromRGB(14,7,28),
    white   = Color3.fromRGB(255,255,255),
    purple  = Color3.fromRGB(160,100,255),
    purpleD = Color3.fromRGB(80,45,150),
    blue    = Color3.fromRGB(80,170,255),
    green   = Color3.fromRGB(70,220,110),
    amber   = Color3.fromRGB(255,185,55),
    red     = Color3.fromRGB(255,80,80),
    textBr  = Color3.fromRGB(230,218,255),
    textDim = Color3.fromRGB(130,100,175),
    textMut = Color3.fromRGB(90,65,125),
}

-- ===== MAIN (wide horizontal) =====
-- Width: 620, Height: 400
local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0,620,0,400)
main.AnchorPoint = Vector2.new(0.5,0.5)
main.Position = UDim2.new(0.5,0,0.5,0)
main.BackgroundColor3 = C.bg
main.BackgroundTransparency = 0.08
main.BorderSizePixel = 0
main.Active = true; main.Draggable = true
local mc = Instance.new("UICorner", main); mc.CornerRadius = UDim.new(0,20)
local ms = Instance.new("UIStroke", main); ms.Color = C.white; ms.Transparency = 0.78; ms.Thickness = 1

-- Skala responsif: mempertahankan desain 620x400, tetapi mengecilkan seluruh UI
-- secara proporsional pada layar ponsel agar panel tidak terpotong di luar layar.
local mainScale = Instance.new("UIScale")
mainScale.Parent = main

local function updateMainScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local fitX = (viewport.X - 24) / 620
    local fitY = (viewport.Y - 24) / 400
    mainScale.Scale = math.clamp(math.min(1, fitX, fitY), 0.45, 1)
end

updateMainScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateMainScale)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateMainScale)
        updateMainScale()
    end
end)

-- Top shine
local shine = Instance.new("Frame", main)
shine.Size = UDim2.new(0.5,0,0,1); shine.Position = UDim2.new(0.25,0,0,0)
shine.BackgroundColor3 = C.white; shine.BackgroundTransparency = 0.4; shine.BorderSizePixel = 0
Instance.new("UICorner", shine).CornerRadius = UDim.new(1,0)

-- Orb decorations
local function makeOrb(parent,x,y,sz,col,trans)
    local o = Instance.new("Frame", parent)
    o.Size = UDim2.new(0,sz,0,sz); o.Position = UDim2.new(0,x,0,y)
    o.BackgroundColor3 = col; o.BackgroundTransparency = trans
    o.BorderSizePixel = 0; o.ZIndex = 0
    Instance.new("UICorner", o).CornerRadius = UDim.new(1,0)
end
makeOrb(main,-80,-80,220,C.purple,0.88)
makeOrb(main,500,300,180,C.blue,0.90)
makeOrb(main,440,-30,120,Color3.fromRGB(255,80,200),0.93)

-- ===== TITLE BAR =====
local tBar = Instance.new("Frame", main)
tBar.Size = UDim2.new(1,0,0,46); tBar.Position = UDim2.new(0,0,0,0)
tBar.BackgroundColor3 = C.white; tBar.BackgroundTransparency = 0.94
tBar.BorderSizePixel = 0; tBar.ZIndex = 2
Instance.new("UICorner", tBar).CornerRadius = UDim.new(0,20)

local function hex(parent,x,y,r,col,alpha)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0,r*2,0,r*2); f.Position = UDim2.new(0,x-r,0,y-r)
    f.BackgroundColor3 = col; f.BackgroundTransparency = alpha; f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(1,0)
end

local logoFrame = Instance.new("Frame", tBar)
logoFrame.Size = UDim2.new(0,30,0,30); logoFrame.Position = UDim2.new(0,12,0.5,-15)
logoFrame.BackgroundTransparency = 1
hex(logoFrame,15,15,15,C.purple,0.65)
hex(logoFrame,15,15,10,C.blue,0.70)
hex(logoFrame,15,15,4,C.white,0.1)

local titleL = Instance.new("TextLabel", tBar)
titleL.Size = UDim2.new(0,80,0,20); titleL.Position = UDim2.new(0,50,0,8)
titleL.BackgroundTransparency = 1; titleL.Text = "therX"
titleL.TextColor3 = C.textBr; titleL.Font = Enum.Font.GothamBold; titleL.TextSize = 15
titleL.TextXAlignment = Enum.TextXAlignment.Left; titleL.ZIndex = 3

local verL = Instance.new("TextLabel", tBar)
verL.Size = UDim2.new(0,160,0,12); verL.Position = UDim2.new(0,50,0,28)
verL.BackgroundTransparency = 1; verL.Text = "v0.1.0  by AxzZz"
verL.TextColor3 = C.purple; verL.Font = Enum.Font.Gotham; verL.TextSize = 9
verL.TextXAlignment = Enum.TextXAlignment.Left; verL.ZIndex = 3

-- FPS/Ping di title bar
local fpsPingLabel = Instance.new("TextLabel", tBar)
fpsPingLabel.Size = UDim2.new(0,160,0,14); fpsPingLabel.Position = UDim2.new(0.5,-80,0.5,-7)
fpsPingLabel.BackgroundTransparency = 1; fpsPingLabel.Text = "FPS: -- | Ping: --ms"
fpsPingLabel.TextColor3 = C.textDim; fpsPingLabel.Font = Enum.Font.Gotham; fpsPingLabel.TextSize = 9
fpsPingLabel.TextXAlignment = Enum.TextXAlignment.Center; fpsPingLabel.ZIndex = 3

-- FPS/Ping update
local fpsCount = 0; local fpsTimer = 0
RunService.Heartbeat:Connect(function(dt)
    fpsCount += 1; fpsTimer += dt
    if fpsTimer >= 0.5 then
        local fps = math.floor(fpsCount / fpsTimer)
        local ping = "--"
        pcall(function()
            ping = tostring(math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()))
        end)
        fpsPingLabel.Text = "FPS: "..fps.." | Ping: "..ping.."ms"
        fpsPingLabel.TextColor3 = fps >= 55 and C.green or (fps >= 30 and C.amber or C.red)
        fpsCount = 0; fpsTimer = 0
    end
end)

-- Window buttons
local function winBtn(parent,xOff,col,onClick)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0,14,0,14); btn.Position = UDim2.new(1,xOff,0.5,-7)
    btn.BackgroundColor3 = col; btn.BackgroundTransparency = 0.1; btn.BorderSizePixel = 0
    btn.Text = ""; btn.ZIndex = 3
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)
    btn.MouseButton1Click:Connect(onClick)
    btn.MouseEnter:Connect(function() tween(btn,{BackgroundTransparency=0},0.1) end)
    btn.MouseLeave:Connect(function() tween(btn,{BackgroundTransparency=0.1},0.1) end)
end

local function hideMain()
    tween(main, {Size=UDim2.new(0,620,0,0), BackgroundTransparency=1}, 0.2)
    task.delay(0.25, function()
        main.Visible = false
        main.Size = UDim2.new(0,620,0,400)
        main.BackgroundTransparency = 0.08
        miniBar.Visible = true
    end)
end

-- Delete All (merah)
winBtn(tBar, -88, C.red, function()
    State.fly=false; disableFly()
    State.infiniteJ=false; disableInfiniteJump()
    State.autoWalk=false; disableAutoWalk()
    State.antiLag=false; disablePotatoMode()
    State.noclip=false; disableNoclip()
    State.godMode=false; disableGodMode()
    State.antiVoid=false; disableAntiVoid()
    State.espEnabled=false; disableEsp()
    State.chams=false; disableChams()
    notify("therX | Reset","Semua fitur dimatikan",2)
    task.delay(0.3, function() gui:Destroy() end)
end)
-- Minimize (kuning)
winBtn(tBar, -66, C.amber, function() main.Visible = not main.Visible end)
-- Close (hijau)
winBtn(tBar, -44, C.green, hideMain)

-- ===== LEFT SIDEBAR — tab icons =====
local MAINW = 620
local SIDEW = 54
local CONTENTW = MAINW - SIDEW  -- 566

local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0,SIDEW,1,-46); sidebar.Position = UDim2.new(0,0,0,46)
sidebar.BackgroundColor3 = Color3.fromRGB(0,0,0); sidebar.BackgroundTransparency = 0.55
sidebar.BorderSizePixel = 0; sidebar.ZIndex = 2
local sideDiv = Instance.new("Frame", main)
sideDiv.Size = UDim2.new(0,1,1,-46); sideDiv.Position = UDim2.new(0,SIDEW,0,46)
sideDiv.BackgroundColor3 = C.white; sideDiv.BackgroundTransparency = 0.88; sideDiv.BorderSizePixel = 0

-- ===== TAB DEFINITIONS =====
local TABS = {
    { icon="🚀", name="Move"   },
    { icon="👁",  name="Visual" },
    { icon="⏺",  name="Record" },
    { icon="💾",  name="Saves"  },
    { icon="🛡",  name="Util"   },
    { icon="⚡",  name="Perf"   },
    { icon="👥",  name="Players"},
    { icon="🎖",  name="ANS"    },
}

local tabBtns   = {}
local tabPanels = {}
local curTab    = 1

local function setTab(idx)
    curTab = idx
    for i, b in ipairs(tabBtns) do
        tween(b, {
            BackgroundTransparency = i==idx and 0.5 or 1,
            TextColor3 = i==idx and Color3.fromRGB(205,165,255) or Color3.fromRGB(90,65,120)
        }, 0.15)
    end
    for i, p in ipairs(tabPanels) do p.Visible = (i==idx) end
end

for i, tab in ipairs(TABS) do
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1,-4,0,46)
    btn.Position = UDim2.new(0,2,0,4+(i-1)*50)
    btn.BackgroundColor3 = C.purple
    btn.BackgroundTransparency = i==1 and 0.5 or 1
    btn.BorderSizePixel = 0
    btn.ZIndex = 3
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)

    local iconL = Instance.new("TextLabel", btn)
    iconL.Size = UDim2.new(1,0,0,22); iconL.Position = UDim2.new(0,0,0,4)
    iconL.BackgroundTransparency = 1; iconL.Text = tab.icon
    iconL.TextColor3 = i==1 and Color3.fromRGB(205,165,255) or Color3.fromRGB(90,65,120)
    iconL.Font = Enum.Font.GothamBold; iconL.TextSize = 16; iconL.ZIndex = 4
    iconL.TextXAlignment = Enum.TextXAlignment.Center

    local nameL = Instance.new("TextLabel", btn)
    nameL.Size = UDim2.new(1,0,0,12); nameL.Position = UDim2.new(0,0,0,26)
    nameL.BackgroundTransparency = 1; nameL.Text = tab.name
    nameL.TextColor3 = i==1 and Color3.fromRGB(205,165,255) or Color3.fromRGB(90,65,120)
    nameL.Font = Enum.Font.Gotham; nameL.TextSize = 7; nameL.ZIndex = 4
    nameL.TextXAlignment = Enum.TextXAlignment.Center

    btn.MouseButton1Click:Connect(function()
        for _, b in ipairs(tabBtns) do
            local ic = b:FindFirstChildOfClass("TextLabel")
            local nc = b:FindFirstChildWhichIsA("TextLabel") -- name label
        end
        setTab(i)
        for j, b in ipairs(tabBtns) do
            for _, lbl in ipairs(b:GetChildren()) do
                if lbl:IsA("TextLabel") then
                    tween(lbl, {TextColor3 = j==i and Color3.fromRGB(205,165,255) or Color3.fromRGB(90,65,120)}, 0.15)
                end
            end
        end
    end)
    table.insert(tabBtns, btn)
end

-- ===== CONTENT AREA =====
local function newPanel()
    local sf = Instance.new("ScrollingFrame", main)
    sf.Size = UDim2.new(0,CONTENTW-12,1,-56); sf.Position = UDim2.new(0,SIDEW+6,0,50)
    sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 2; sf.ScrollBarImageColor3 = C.purple
    sf.Visible = false; sf.ZIndex = 2
    local ul = Instance.new("UIListLayout", sf); ul.Padding = UDim.new(0,5)
    local up = Instance.new("UIPadding", sf)
    up.PaddingTop = UDim.new(0,4); up.PaddingLeft = UDim.new(0,2); up.PaddingRight = UDim.new(0,4)
    ul:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0,0,0,ul.AbsoluteContentSize.Y+10)
    end)
    return sf
end

-- Content area uses 2-column grid for wide layout
local function newGridPanel()
    local sf = Instance.new("ScrollingFrame", main)
    sf.Size = UDim2.new(0,CONTENTW-12,1,-56); sf.Position = UDim2.new(0,SIDEW+6,0,50)
    sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 2; sf.ScrollBarImageColor3 = C.purple
    sf.Visible = false; sf.ZIndex = 2
    local ul = Instance.new("UIGridLayout", sf)
    ul.CellSize = UDim2.new(0,(CONTENTW-12)/2-6,0,52)
    ul.CellPadding = UDim2.new(0,6,0,6)
    ul.SortOrder = Enum.SortOrder.LayoutOrder
    local up = Instance.new("UIPadding", sf)
    up.PaddingTop = UDim.new(0,4); up.PaddingLeft = UDim.new(0,2); up.PaddingRight = UDim.new(0,4)
    ul:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0,0,0,ul.AbsoluteContentSize.Y+10)
    end)
    return sf, ul
end

-- Helpers
local function sectLbl(parent, txt)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1,0,0,14); l.BackgroundTransparency = 1
    l.Text = txt; l.TextColor3 = Color3.fromRGB(130,80,200)
    l.Font = Enum.Font.GothamBold; l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 3
    l.LayoutOrder = 0
    return l
end

local function toggleCard(parent, label, subLabel, iconColor, isWarn, layoutOrder)
    local row = Instance.new("Frame", parent)
    row.BackgroundColor3 = isWarn and Color3.fromRGB(50,25,5) or C.white
    row.BackgroundTransparency = isWarn and 0.65 or 0.92
    row.BorderSizePixel = 0; row.ZIndex = 3
    row.LayoutOrder = layoutOrder or 1
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,12)
    local rs = Instance.new("UIStroke", row)
    rs.Color = isWarn and C.amber or C.white; rs.Transparency = isWarn and 0.55 or 0.84; rs.Thickness = 0.8

    local iconBox = Instance.new("Frame", row)
    iconBox.Size = UDim2.new(0,28,0,28); iconBox.Position = UDim2.new(0,7,0.5,-14)
    iconBox.BackgroundColor3 = iconColor; iconBox.BackgroundTransparency = 0.75; iconBox.BorderSizePixel = 0
    Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0,8)
    local ibs = Instance.new("UIStroke", iconBox); ibs.Color = iconColor; ibs.Transparency = 0.5
    local iconLbl = Instance.new("TextLabel", iconBox)
    iconLbl.Size = UDim2.new(1,0,1,0); iconLbl.BackgroundTransparency = 1
    iconLbl.Text = "⬡"; iconLbl.TextColor3 = iconColor
    iconLbl.Font = Enum.Font.GothamBold; iconLbl.TextSize = 12; iconLbl.ZIndex = 4

    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.Size = UDim2.new(0.55,0,0,15); nameLbl.Position = UDim2.new(0,42,0,7)
    nameLbl.BackgroundTransparency = 1; nameLbl.Text = label
    nameLbl.TextColor3 = isWarn and C.amber or C.textBr
    nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 10
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.ZIndex = 4

    local subLbl = Instance.new("TextLabel", row)
    subLbl.Size = UDim2.new(0.55,0,0,11); subLbl.Position = UDim2.new(0,42,0,24)
    subLbl.BackgroundTransparency = 1; subLbl.Text = subLabel
    subLbl.TextColor3 = Color3.fromRGB(120,90,165)
    subLbl.Font = Enum.Font.Gotham; subLbl.TextSize = 8
    subLbl.TextXAlignment = Enum.TextXAlignment.Left; subLbl.ZIndex = 4

    -- Toggle switch
    local togBg = Instance.new("Frame", row)
    togBg.Size = UDim2.new(0,34,0,20); togBg.Position = UDim2.new(1,-42,0.5,-10)
    togBg.BackgroundColor3 = Color3.fromRGB(35,18,65); togBg.BorderSizePixel = 0
    Instance.new("UICorner", togBg).CornerRadius = UDim.new(1,0)
    Instance.new("UIStroke", togBg).Color = C.white

    local knob = Instance.new("Frame", togBg)
    knob.Size = UDim2.new(0,14,0,14); knob.Position = UDim2.new(0,3,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(180,150,220); knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local on = false
    local clickZone = Instance.new("TextButton", row)
    clickZone.Size = UDim2.new(1,0,1,0); clickZone.BackgroundTransparency = 1
    clickZone.Text = ""; clickZone.ZIndex = 5

    local function doToggle()
        on = not on
        tween(togBg, {BackgroundColor3 = on and Color3.fromRGB(100,50,220) or Color3.fromRGB(35,18,65)})
        tween(knob, {
            BackgroundColor3 = on and C.white or Color3.fromRGB(180,150,220),
            Position = on and UDim2.new(0,17,0.5,-7) or UDim2.new(0,3,0.5,-7)
        })
        tween(row, {BackgroundTransparency = on and (isWarn and 0.5 or 0.84) or (isWarn and 0.65 or 0.92)}, 0.2)
        rs.Color = (on and not isWarn) and C.purple or (isWarn and C.amber or C.white)
        rs.Transparency = on and 0.4 or (isWarn and 0.55 or 0.84)
        return on
    end
    clickZone.MouseButton1Click:Connect(doToggle)
    return row, clickZone
end

local function glBtn(parent, label, r, g, b, w, callback, layoutOrder)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(w or 1,0,0,33); btn.ZIndex = 3
    btn.BackgroundColor3 = Color3.fromRGB(r,g,b); btn.BackgroundTransparency = 0.65
    btn.BorderSizePixel = 0; btn.Text = label
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 10
    btn.TextColor3 = Color3.fromRGB(math.min(255,r+90),math.min(255,g+90),math.min(255,b+90))
    btn.LayoutOrder = layoutOrder or 99
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
    local bs = Instance.new("UIStroke", btn)
    bs.Color = Color3.fromRGB(math.min(255,r+50),math.min(255,g+50),math.min(255,b+50)); bs.Transparency = 0.5
    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() tween(btn,{BackgroundTransparency=0.4}) end)
    btn.MouseLeave:Connect(function() tween(btn,{BackgroundTransparency=0.65}) end)
    return btn
end

local function makeSlider(parent, label, minV, maxV, defV, onChange, layoutOrder)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,46); row.ZIndex = 3
    row.BackgroundColor3 = Color3.fromRGB(0,0,0); row.BackgroundTransparency = 0.6
    row.BorderSizePixel = 0; row.LayoutOrder = layoutOrder or 10
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke", row).Color = C.white

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6,0,0,14); lbl.Position = UDim2.new(0,10,0,6)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(140,105,185); lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 9; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4

    local vLbl = Instance.new("TextLabel", row)
    vLbl.Size = UDim2.new(0.3,0,0,14); vLbl.Position = UDim2.new(0.7,-10,0,6)
    vLbl.BackgroundTransparency = 1; vLbl.Text = tostring(defV)
    vLbl.TextColor3 = C.purple; vLbl.Font = Enum.Font.GothamBold
    vLbl.TextSize = 10; vLbl.TextXAlignment = Enum.TextXAlignment.Right; vLbl.ZIndex = 4

    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1,-20,0,4); track.Position = UDim2.new(0,10,0,30)
    track.BackgroundColor3 = Color3.fromRGB(50,28,90); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local pct = (defV-minV)/(maxV-minV)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(pct,0,1,0); fill.BackgroundColor3 = C.purple; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local kn = Instance.new("Frame", track)
    kn.Size = UDim2.new(0,13,0,13); kn.Position = UDim2.new(pct,-6,0.5,-6)
    kn.BackgroundColor3 = Color3.fromRGB(220,205,255); kn.BorderSizePixel = 0
    Instance.new("UICorner", kn).CornerRadius = UDim.new(1,0)

    local dragging = false
    local btn = Instance.new("TextButton", track)
    btn.Size = UDim2.new(1,0,0,22); btn.Position = UDim2.new(0,0,0,-9)
    btn.BackgroundTransparency = 1; btn.Text = ""; btn.ZIndex = 5

    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local val = math.floor(minV + rel*(maxV-minV))
        vLbl.Text = tostring(val)
        fill.Size = UDim2.new(rel,0,1,0); kn.Position = UDim2.new(rel,-6,0.5,-6)
        onChange(val)
    end
    btn.MouseButton1Down:Connect(function() dragging=true end)
    btn.MouseButton1Up:Connect(function() dragging=false end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    return row
end

local function makeInput(parent, placeholder, onChange, layoutOrder)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1,0,0,34); frame.ZIndex = 3
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0); frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0; frame.LayoutOrder = layoutOrder or 10
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)
    local fs = Instance.new("UIStroke", frame); fs.Color = C.white; fs.Transparency = 0.84
    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(1,-16,1,0); box.Position = UDim2.new(0,8,0,0)
    box.BackgroundTransparency = 1; box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(80,55,110); box.Text = ""
    box.TextColor3 = C.textBr; box.Font = Enum.Font.Gotham; box.TextSize = 11
    box.TextXAlignment = Enum.TextXAlignment.Left; box.ZIndex = 4
    box.FocusLost:Connect(function() if onChange then onChange(box.Text) end end)
    box.Focused:Connect(function() fs.Color = C.purple; fs.Transparency = 0.4 end)
    box.FocusLost:Connect(function() fs.Color = C.white; fs.Transparency = 0.84 end)
    return frame, box
end

local function infoBox(parent, h, layoutOrder)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,0,0,h or 60); f.ZIndex = 3
    f.BackgroundColor3 = Color3.fromRGB(0,0,0); f.BackgroundTransparency = 0.55
    f.BorderSizePixel = 0; f.LayoutOrder = layoutOrder or 10
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke", f).Color = C.white
    return f
end

local function infoRow(parent, lbl, ypos)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(0.5,0,0,13); l.Position = UDim2.new(0,10,0,ypos)
    l.BackgroundTransparency = 1; l.Text = lbl
    l.TextColor3 = C.textMut; l.Font = Enum.Font.Gotham; l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 4
    local v = Instance.new("TextLabel", parent)
    v.Size = UDim2.new(0.4,0,0,13); v.Position = UDim2.new(0.6,-10,0,ypos)
    v.BackgroundTransparency = 1; v.TextColor3 = C.textBr
    v.Font = Enum.Font.GothamBold; v.TextSize = 9
    v.TextXAlignment = Enum.TextXAlignment.Right; v.ZIndex = 4
    return v
end

setLoadingProgress(65, "Memuat menu dan kontrol...")

-- =============================================
-- TAB 1 — MOVE
-- =============================================
local p1, p1grid = newGridPanel(); table.insert(tabPanels, p1)

local flyCard, flyClick = toggleCard(p1,"Fly Mode","WASD+Space/Shift",C.purple,false,1)
flyClick.MouseButton1Click:Connect(function()
    State.fly = not State.fly
    if State.fly then enableFly() else disableFly() end
end)

local jCard, jClick = toggleCard(p1,"Infinity Jump","Lompat tanpa batas",C.blue,false,2)
jClick.MouseButton1Click:Connect(function()
    State.infiniteJ = not State.infiniteJ
    if State.infiniteJ then enableInfiniteJump() else disableInfiniteJump() end
end)

local wCard, wClick = toggleCard(p1,"Auto Walk","Jalan otomatis ke depan",C.green,false,3)
wClick.MouseButton1Click:Connect(function()
    State.autoWalk = not State.autoWalk
    if State.autoWalk then enableAutoWalk() else disableAutoWalk() end
end)

local ncCard, ncClick = toggleCard(p1,"NoClip","Tembus dinding/obstacle",C.amber,false,4)
ncClick.MouseButton1Click:Connect(function()
    State.noclip = not State.noclip
    if State.noclip then enableNoclip() else disableNoclip() end
end)

-- Sliders in a list sub-frame
local sliderHolder = Instance.new("Frame", p1)
sliderHolder.Size = UDim2.new(1,0,0,210)
sliderHolder.BackgroundTransparency = 1
sliderHolder.LayoutOrder = 5
local slUl = Instance.new("UIListLayout", sliderHolder); slUl.Padding = UDim.new(0,5)

makeSlider(sliderHolder,"Fly Speed",10,200,50,function(v) State.flySpeed=v end,1)
makeSlider(sliderHolder,"Jump Power",50,500,100,function(v) State.jumpPower=v; Humanoid.JumpPower=v end,2)
makeSlider(sliderHolder,"Walk Speed",8,100,16,function(v) State.walkSpeed=v; if State.autoWalk then Humanoid.WalkSpeed=v end end,3)
makeSlider(sliderHolder,"Speed Hack",8,500,16,function(v) applySpeed(v) end,4)

slUl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sliderHolder.Size = UDim2.new(1,0,0,slUl.AbsoluteContentSize.Y)
end)

-- =============================================
-- TAB 2 — VISUAL (ESP/Chams)
-- =============================================
local p2, p2grid = newGridPanel(); table.insert(tabPanels, p2)

local espCard, espClick = toggleCard(p2,"Player ESP","Nama + jarak player lain",C.blue,false,1)
espClick.MouseButton1Click:Connect(function()
    State.espEnabled = not State.espEnabled
    if State.espEnabled then enableEsp() else disableEsp() end
end)

local chCard, chClick = toggleCard(p2,"Chams","Highlight karakter neon",Color3.fromRGB(255,80,200),false,2)
chClick.MouseButton1Click:Connect(function()
    State.chams = not State.chams
    if State.chams then enableChams() else disableChams() end
end)

local godCard, godClick = toggleCard(p2,"God Mode","HP tidak berkurang",C.green,false,3)
godClick.MouseButton1Click:Connect(function()
    State.godMode = not State.godMode
    if State.godMode then enableGodMode() else disableGodMode() end
end)

local avCard, avClick = toggleCard(p2,"Anti-Void","Auto teleport saat jatuh void",C.amber,false,4)
avClick.MouseButton1Click:Connect(function()
    State.antiVoid = not State.antiVoid
    if State.antiVoid then enableAntiVoid() else disableAntiVoid() end
end)

-- Info card visual
local visInfo = infoBox(p2, 70, 5)
visInfo.Size = UDim2.new(1,0,0,70)
local visL = Instance.new("TextLabel", visInfo)
visL.Size = UDim2.new(1,-16,1,-12); visL.Position = UDim2.new(0,8,0,6)
visL.BackgroundTransparency = 1; visL.ZIndex = 4
visL.Text = "ESP: tampilkan nametag semua player\nChams: warnai karakter player lain neon\nGod Mode: HP infinity, tidak bisa mati\nAnti-Void: auto respawn saat Y < -50"
visL.TextColor3 = Color3.fromRGB(100,160,220); visL.Font = Enum.Font.Gotham
visL.TextSize = 9; visL.TextXAlignment = Enum.TextXAlignment.Left
visL.TextYAlignment = Enum.TextYAlignment.Top

-- =============================================
-- TAB 3 — RECORD
-- =============================================
local p3 = newPanel(); table.insert(tabPanels, p3)

sectLbl(p3,"— map info").LayoutOrder = 1
local mapIn, mapBox = makeInput(p3,"Nama map (cth: Tower of Hell)",function(v) State.mapName=v~="" and v or "Unknown Map" end,2)
local obsIn, obsBox = makeInput(p3,"Nama rintangan (cth: Conveyor Belt)",function(v) State.obsName=v~="" and v or "Unknown Obstacle" end,3)

sectLbl(p3,"— rekaman").LayoutOrder = 4
local recInfoB = infoBox(p3,70,5)
local recStat = infoRow(recInfoB,"Status",6)
local recWpV  = infoRow(recInfoB,"Waypoints",24)
local recDurV = infoRow(recInfoB,"Durasi",42)
local recMapV = infoRow(recInfoB,"Map",58)
recStat.Text="Idle"; recWpV.Text="0"; recDurV.Text="0s"; recMapV.Text="—"

local recSecs = 0
RunService.Heartbeat:Connect(function()
    recWpV.Text = tostring(#WaypointLog)
    if State.recording then
        recSecs = math.floor(tick()-RecordStart)
        recDurV.Text = recSecs.."s"
        recStat.TextColor3 = Color3.fromRGB(80,255,120)
    else
        recStat.TextColor3 = C.textBr
    end
end)

local recBtnHolder = Instance.new("Frame", p3)
recBtnHolder.Size = UDim2.new(1,0,0,33); recBtnHolder.BackgroundTransparency = 1
recBtnHolder.LayoutOrder = 6
local rbUl = Instance.new("UIListLayout", recBtnHolder)
rbUl.FillDirection = Enum.FillDirection.Horizontal; rbUl.Padding = UDim.new(0,6)

local recBtnRef = glBtn(recBtnHolder,"⏺  Record",160,20,20,0.47,function()
    if not State.recording then
        startRecord(); recBtnRef.Text="⏹  Stop"
        recBtnRef.BackgroundColor3=Color3.fromRGB(220,40,40)
        recStat.Text="Recording"; recMapV.Text=State.mapName
    else
        stopRecord(); recBtnRef.Text="⏺  Record"
        recBtnRef.BackgroundColor3=Color3.fromRGB(160,20,20)
        recStat.Text="Stopped"
    end
end)
local saveBtnRef = glBtn(recBtnHolder,"💾  Save",20,100,30,0.47,function()
    saveRecord(); recStat.Text="Saved ✓"
    recStat.TextColor3=Color3.fromRGB(80,255,120)
end)

-- Copy map button
local copyHolder = Instance.new("Frame", p3)
copyHolder.Size = UDim2.new(1,0,0,33); copyHolder.BackgroundTransparency = 1
copyHolder.LayoutOrder = 7
local cpUl = Instance.new("UIListLayout", copyHolder)
cpUl.FillDirection = Enum.FillDirection.Horizontal; cpUl.Padding = UDim.new(0,6)

glBtn(copyHolder,"🗺  Auto-Detect Map",60,60,160,1,function()
    local n = copyMapName()
    mapBox.Text = n
end)

-- =============================================
-- TAB 4 — SAVES
-- =============================================
local p4 = newPanel(); table.insert(tabPanels, p4)
local emptyLabel = Instance.new("TextLabel", p4)
emptyLabel.Size = UDim2.new(1,0,0,36); emptyLabel.BackgroundTransparency=1
emptyLabel.Text = "Belum ada route tersimpan"
emptyLabel.TextColor3 = Color3.fromRGB(70,45,100); emptyLabel.Font = Enum.Font.Gotham
emptyLabel.TextSize = 10; emptyLabel.ZIndex = 3; emptyLabel.LayoutOrder = 1

local saveCardList = {}
local function refreshSaves()
    for _, c in ipairs(saveCardList) do c:Destroy() end
    saveCardList = {}
    emptyLabel.Visible = #SavedRoutes == 0
    for i, route in ipairs(SavedRoutes) do
        local card = Instance.new("Frame", p4)
        card.Size = UDim2.new(1,0,0,58); card.ZIndex = 3; card.LayoutOrder = i+1
        card.BackgroundColor3 = C.white; card.BackgroundTransparency = 0.91
        card.BorderSizePixel = 0
        Instance.new("UICorner", card).CornerRadius = UDim.new(0,12)
        local ccs = Instance.new("UIStroke", card); ccs.Color = C.white; ccs.Transparency = 0.84
        local mapL = Instance.new("TextLabel", card)
        mapL.Size = UDim2.new(0.82,0,0,16); mapL.Position = UDim2.new(0,10,0,6)
        mapL.BackgroundTransparency=1; mapL.Text=route.mapName
        mapL.TextColor3=C.textBr; mapL.Font=Enum.Font.GothamBold; mapL.TextSize=11
        mapL.TextXAlignment=Enum.TextXAlignment.Left; mapL.ZIndex=4
        local obsL = Instance.new("TextLabel", card)
        obsL.Size = UDim2.new(0.82,0,0,12); obsL.Position = UDim2.new(0,10,0,24)
        obsL.BackgroundTransparency=1; obsL.Text="▸ "..route.obsName
        obsL.TextColor3=C.purple; obsL.Font=Enum.Font.Gotham; obsL.TextSize=9
        obsL.TextXAlignment=Enum.TextXAlignment.Left; obsL.ZIndex=4
        local metaL = Instance.new("TextLabel", card)
        metaL.Size = UDim2.new(0.82,0,0,11); metaL.Position = UDim2.new(0,10,0,38)
        metaL.BackgroundTransparency=1
        metaL.Text=#route.waypoints.." pts · "..route.duration.."s · "..route.timestamp
        metaL.TextColor3=C.textMut; metaL.Font=Enum.Font.Gotham; metaL.TextSize=8
        metaL.TextXAlignment=Enum.TextXAlignment.Left; metaL.ZIndex=4
        local delBtn = Instance.new("TextButton", card)
        delBtn.Size=UDim2.new(0,24,0,24); delBtn.Position=UDim2.new(1,-32,0.5,-12)
        delBtn.BackgroundColor3=C.red; delBtn.BackgroundTransparency=0.65
        delBtn.Text="✕"; delBtn.TextColor3=Color3.fromRGB(255,180,180)
        delBtn.Font=Enum.Font.GothamBold; delBtn.TextSize=11; delBtn.BorderSizePixel=0; delBtn.ZIndex=5
        Instance.new("UICorner",delBtn).CornerRadius=UDim.new(0,7)
        delBtn.MouseButton1Click:Connect(function()
            table.remove(SavedRoutes,i); refreshSaves()
            notify("therX | Deleted","Route dihapus",1.5)
        end)
        table.insert(saveCardList, card)
    end
end
tabBtns[4].MouseButton1Click:Connect(function() task.defer(refreshSaves) end)

-- =============================================
-- TAB 5 — UTIL
-- =============================================
local p5 = newPanel(); table.insert(tabPanels, p5)

sectLbl(p5,"— teleport").LayoutOrder = 1
local tpInput, tpBox = makeInput(p5,"Nama player untuk teleport...",nil,2)
local tpBtnH = Instance.new("Frame", p5)
tpBtnH.Size = UDim2.new(1,0,0,33); tpBtnH.BackgroundTransparency=1; tpBtnH.LayoutOrder=3
local tpUl = Instance.new("UIListLayout", tpBtnH)
tpUl.FillDirection=Enum.FillDirection.Horizontal; tpUl.Padding=UDim.new(0,6)
glBtn(tpBtnH,"🎯  Teleport",80,50,220,1,function() teleportToPlayer(tpBox.Text) end)

sectLbl(p5,"— server").LayoutOrder = 4
local serverH = Instance.new("Frame", p5)
serverH.Size = UDim2.new(1,0,0,33); serverH.BackgroundTransparency=1; serverH.LayoutOrder=5
local srvUl = Instance.new("UIListLayout", serverH)
srvUl.FillDirection=Enum.FillDirection.Horizontal; srvUl.Padding=UDim.new(0,6)
glBtn(serverH,"🔄  Rejoin",50,100,200,0.47,function() rejoin() end)
glBtn(serverH,"🗺  Copy Map",60,160,100,0.47,function() copyMapName() end)

sectLbl(p5,"— map info").LayoutOrder = 6
local mapInfoBox = infoBox(p5,42,7)
local mapNameVal = infoRow(mapInfoBox,"Map Name",6)
local placeIdVal = infoRow(mapInfoBox,"Place ID",22)
mapNameVal.Text = workspace.Name
placeIdVal.Text = tostring(game.PlaceId)

-- =============================================
-- TAB 6 — PERF
-- =============================================
local p6 = newPanel(); table.insert(tabPanels, p6)
sectLbl(p6,"— performance").LayoutOrder=1
local lagR, lagClick = toggleCard(p6,"Potato Mode","Anti Lag — grafik minimal",C.amber,true,2)
lagClick.MouseButton1Click:Connect(function()
    State.antiLag = not State.antiLag
    if State.antiLag then enablePotatoMode() else disablePotatoMode() end
end)

local infoC = infoBox(p6,102,3)
local info = Instance.new("TextLabel", infoC)
info.Size = UDim2.new(1,-16,1,-12); info.Position = UDim2.new(0,8,0,6)
info.BackgroundTransparency=1; info.ZIndex=4
info.Text="Potato Mode menerapkan:\n• Graphics Quality → Level 1\n• Global Shadows → Off\n• Particles, Fire, Smoke → Off\n• Sky → Removed\n• Bloom, Blur, DOF, Sun Rays → Off\n• Decal & Texture → Hidden"
info.TextColor3=Color3.fromRGB(180,145,80); info.Font=Enum.Font.Gotham
info.TextSize=9; info.TextXAlignment=Enum.TextXAlignment.Left
info.TextYAlignment=Enum.TextYAlignment.Top

local perfBtnH = Instance.new("Frame", p6)
perfBtnH.Size=UDim2.new(1,0,0,33); perfBtnH.BackgroundTransparency=1; perfBtnH.LayoutOrder=4
local pfUl = Instance.new("UIListLayout", perfBtnH)
pfUl.FillDirection=Enum.FillDirection.Horizontal; pfUl.Padding=UDim.new(0,6)
glBtn(perfBtnH,"🗑  Kill All Features",180,30,30,0.47,function()
    State.fly=false; disableFly()
    State.infiniteJ=false; disableInfiniteJump()
    State.autoWalk=false; disableAutoWalk()
    State.antiLag=false; disablePotatoMode()
    State.noclip=false; disableNoclip()
    State.godMode=false; disableGodMode()
    State.antiVoid=false; disableAntiVoid()
    State.espEnabled=false; disableEsp()
    State.chams=false; disableChams()
    notify("therX | Reset","Semua fitur dimatikan",2)
end)
glBtn(perfBtnH,"✕  Close",160,160,180,0.47,hideMain)

-- =============================================
-- TAB 7 — PLAYERS
-- =============================================
local p7 = newPanel(); table.insert(tabPanels, p7)
sectLbl(p7,"— server players").LayoutOrder=1

local plrListBox = infoBox(p7,280,2)
plrListBox.Size = UDim2.new(1,0,0,280)
local plrScroll = Instance.new("ScrollingFrame", plrListBox)
plrScroll.Size = UDim2.new(1,-4,1,-4); plrScroll.Position = UDim2.new(0,2,0,2)
plrScroll.BackgroundTransparency=1; plrScroll.BorderSizePixel=0
plrScroll.ScrollBarThickness=2; plrScroll.ScrollBarImageColor3=C.purple; plrScroll.ZIndex=5
local plrUl = Instance.new("UIListLayout", plrScroll); plrUl.Padding=UDim.new(0,3)
plrUl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    plrScroll.CanvasSize=UDim2.new(0,0,0,plrUl.AbsoluteContentSize.Y+6)
end)

local plrRefBtn = glBtn(p7,"🔃  Refresh List",80,80,200,1,function()
    for _, c in ipairs(plrScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        local row = Instance.new("Frame", plrScroll)
        row.Size=UDim2.new(1,0,0,28); row.BackgroundColor3=C.white
        row.BackgroundTransparency=0.91; row.BorderSizePixel=0; row.ZIndex=6
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
        local dot = Instance.new("Frame", row)
        dot.Size=UDim2.new(0,7,0,7); dot.Position=UDim2.new(0,8,0.5,-3.5)
        dot.BackgroundColor3=plr==Player and C.green or C.purple
        dot.BorderSizePixel=0; dot.ZIndex=7
        Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
        local namL = Instance.new("TextLabel", row)
        namL.Size=UDim2.new(0.6,0,1,0); namL.Position=UDim2.new(0,22,0,0)
        namL.BackgroundTransparency=1; namL.Text=plr.Name..(plr==Player and " (you)" or "")
        namL.TextColor3=plr==Player and C.green or C.textBr
        namL.Font=Enum.Font.GothamBold; namL.TextSize=10
        namL.TextXAlignment=Enum.TextXAlignment.Left; namL.ZIndex=7
        local pingL = Instance.new("TextLabel", row)
        pingL.Size=UDim2.new(0.35,0,1,0); pingL.Position=UDim2.new(0.65,0,0,0)
        pingL.BackgroundTransparency=1
        local ok, ping = pcall(function()
            return math.floor(plr:GetNetworkPing()*1000)
        end)
        pingL.Text= ok and ping.."ms" or "—"
        pingL.TextColor3=C.textMut; pingL.Font=Enum.Font.Gotham; pingL.TextSize=9
        pingL.TextXAlignment=Enum.TextXAlignment.Right; pingL.ZIndex=7
    end
end,3)

setLoadingProgress(82, "Memuat fitur tambahan...")

-- =============================================
-- TAB 8 — ANS (Abdi Negara Simulator)
-- =============================================
local p8 = newPanel(); table.insert(tabPanels, p8)

-- ANS State
local ANS = {
    autoPushUp   = false,
    autoSitUp    = false,
    autoJJS      = false,
    autoPullUp   = false,
    autoAll      = false,
    antiAfk      = false,
    count        = {pushup=0, situp=0, jjs=0, pullup=0},
    running      = {},
}

-- Utility: cari ProximityPrompt berdasarkan keyword di nama/ActionText
local function findPrompt(keywords)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local n = (obj.ActionText..obj.ObjectText..obj.Parent.Name):lower()
            for _, kw in ipairs(keywords) do
                if n:find(kw:lower()) then
                    return obj
                end
            end
        end
    end
    return nil
end

-- Utility: trigger ProximityPrompt via fireproximityprompt
local function triggerPrompt(prompt)
    if not prompt or not prompt.Parent then return false end
    local ok = pcall(function()
        firetouchinterest(HRP, prompt.Parent, 0)
        fireproximityprompt(prompt)
        firetouchinterest(HRP, prompt.Parent, 1)
    end)
    if not ok then
        -- fallback: coba fire via RemoteEvent
        pcall(function()
            local re = prompt.Parent:FindFirstChildOfClass("RemoteEvent")
                or prompt.Parent.Parent:FindFirstChildOfClass("RemoteEvent")
            if re then re:FireServer(prompt) end
        end)
    end
    return true
end

-- Utility: cari RemoteEvent latihan via nama
local function findRemote(keywords)
    local function search(parent)
        for _, obj in ipairs(parent:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local n = obj.Name:lower()
                for _, kw in ipairs(keywords) do
                    if n:find(kw:lower()) then return obj end
                end
            end
        end
    end
    return search(workspace) or search(game:GetService("ReplicatedStorage"))
end

-- Auto exercise loop generik
local function startExercise(key, keywords, remoteKeywords, label, countRef, statusLbl, countLbl)
    if ANS.running[key] then return end
    ANS.running[key] = true
    ANS.count[key] = 0
    notify("therX | ANS", label.." dimulai", 2)

    task.spawn(function()
        while ANS.running[key] do
            -- Cari prompt dulu
            local prompt = findPrompt(keywords)
            if prompt then
                triggerPrompt(prompt)
                ANS.count[key] += 1
                if countLbl then countLbl.Text = tostring(ANS.count[key]) end
                if statusLbl then statusLbl.Text = "▶ "..label end
                task.wait(0.08)
            else
                -- Fallback: cari RemoteEvent langsung
                local re = findRemote(remoteKeywords)
                if re then
                    pcall(function() re:FireServer() end)
                    ANS.count[key] += 1
                    if countLbl then countLbl.Text = tostring(ANS.count[key]) end
                    if statusLbl then statusLbl.Text = "▶ "..label end
                    task.wait(0.08)
                else
                    -- Belum ketemu, tunggu sebentar
                    if statusLbl then statusLbl.Text = "🔍 Cari "..label.."..." end
                    task.wait(0.5)
                end
            end
        end
        if statusLbl then statusLbl.Text = "⏹ Idle" end
    end)
end

local function stopExercise(key, statusLbl)
    ANS.running[key] = false
    if statusLbl then statusLbl.Text = "⏹ Idle" end
    notify("therX | ANS", "Stop", 1.5)
end

-- ===== ANS UI =====
sectLbl(p8, "— Abdi Negara Simulator").LayoutOrder = 1

-- Status info box
local ansInfoBox = infoBox(p8, 60, 2)
local ansStat1 = infoRow(ansInfoBox, "Push Up", 5)
local ansStat2 = infoRow(ansInfoBox, "Sit Up", 20)
local ansStat3 = infoRow(ansInfoBox, "JJS", 35)
local ansStat4 = infoRow(ansInfoBox, "Pull Up", 50)
ansStat1.Text="0 rep | Idle"
ansStat2.Text="0 rep | Idle"
ansStat3.Text="0 rep | Idle"
ansStat4.Text="0 rep | Idle"

-- Update stats tiap detik
RunService.Heartbeat:Connect(function()
    local function fmt(key, lbl)
        local running = ANS.running[key] and "▶ ON" or "Idle"
        lbl.Text = ANS.count[key].." rep | "..running
        lbl.TextColor3 = ANS.running[key] and Color3.fromRGB(80,255,120) or Color3.fromRGB(180,150,220)
    end
    fmt("pushup", ansStat1)
    fmt("situp",  ansStat2)
    fmt("jjs",    ansStat3)
    fmt("pullup", ansStat4)
end)

sectLbl(p8, "— kontrol latihan").LayoutOrder = 3

-- Push Up card
local puCard, puClick = toggleCard(p8, "Auto Push Up", "Otomatis push up loop", C.purple, false, 4)
puClick.MouseButton1Click:Connect(function()
    ANS.autoPushUp = not ANS.autoPushUp
    if ANS.autoPushUp then
        startExercise("pushup",
            {"push","pushup","push up","angkatbadan","angkat badan"},
            {"pushup","push_up","PushUp","Push","exercise"},
            "Push Up", ANS.count, nil, nil)
    else
        stopExercise("pushup", nil)
    end
end)

-- Sit Up card
local suCard, suClick = toggleCard(p8, "Auto Sit Up", "Otomatis sit up loop", C.blue, false, 5)
suClick.MouseButton1Click:Connect(function()
    ANS.autoSitUp = not ANS.autoSitUp
    if ANS.autoSitUp then
        startExercise("situp",
            {"sit","situp","sit up","crunch","duduk"},
            {"situp","sit_up","SitUp","Sit","exercise"},
            "Sit Up", ANS.count, nil, nil)
    else
        stopExercise("situp", nil)
    end
end)

-- JJS card
local jjsCard, jjsClick = toggleCard(p8, "Auto JJS", "Jumping Jacks otomatis", C.green, false, 6)
jjsClick.MouseButton1Click:Connect(function()
    ANS.autoJJS = not ANS.autoJJS
    if ANS.autoJJS then
        startExercise("jjs",
            {"jump","jumping","jjs","jumping jack","loncat"},
            {"jjs","jumpingjack","JumpingJack","Jump","exercise"},
            "JJS", ANS.count, nil, nil)
    else
        stopExercise("jjs", nil)
    end
end)

-- Pull Up card
local pullCard, pullClick = toggleCard(p8, "Auto Pull Up", "Pull up / chinup otomatis", Color3.fromRGB(255,120,80), false, 7)
pullClick.MouseButton1Click:Connect(function()
    ANS.autoPullUp = not ANS.autoPullUp
    if ANS.autoPullUp then
        startExercise("pullup",
            {"pull","pullup","pull up","chinup","chin up","gantung"},
            {"pullup","pull_up","PullUp","Pull","exercise"},
            "Pull Up", ANS.count, nil, nil)
    else
        stopExercise("pullup", nil)
    end
end)

sectLbl(p8, "— shortcut").LayoutOrder = 8

-- Auto All button
local allBtnH = Instance.new("Frame", p8)
allBtnH.Size=UDim2.new(1,0,0,33); allBtnH.BackgroundTransparency=1; allBtnH.LayoutOrder=9
local allUl = Instance.new("UIListLayout", allBtnH)
allUl.FillDirection=Enum.FillDirection.Horizontal; allUl.Padding=UDim.new(0,6)

local allRunning = false
local allBtn = glBtn(allBtnH, "⚡ Auto ALL Exercise", 100, 50, 220, 0.62, function()
    allRunning = not allRunning
    if allRunning then
        allBtn.Text = "⏹ Stop ALL"
        allBtn.BackgroundColor3 = Color3.fromRGB(180,30,30)
        ANS.autoPushUp=true; ANS.autoSitUp=true; ANS.autoJJS=true; ANS.autoPullUp=true
        startExercise("pushup",{"push","pushup","push up","angkatbadan"},{"pushup","PushUp","Push","exercise"},"Push Up",ANS.count,nil,nil)
        startExercise("situp", {"sit","situp","sit up","crunch"},        {"situp","SitUp","Sit","exercise"},   "Sit Up", ANS.count,nil,nil)
        startExercise("jjs",   {"jump","jumping","jjs","jumping jack"},  {"jjs","JumpingJack","Jump","exercise"},"JJS",  ANS.count,nil,nil)
        startExercise("pullup",{"pull","pullup","pull up","gantung"},    {"pullup","PullUp","Pull","exercise"}, "Pull Up",ANS.count,nil,nil)
        notify("therX | ANS","Auto ALL Exercise aktif 🔥",3)
    else
        allBtn.Text = "⚡ Auto ALL Exercise"
        allBtn.BackgroundColor3 = Color3.fromRGB(100,50,220)
        ANS.autoPushUp=false; ANS.autoSitUp=false; ANS.autoJJS=false; ANS.autoPullUp=false
        ANS.running.pushup=false; ANS.running.situp=false
        ANS.running.jjs=false;    ANS.running.pullup=false
        notify("therX | ANS","Semua exercise dihentikan",2)
    end
end)

-- Anti AFK card
local afkCard, afkClick = toggleCard(p8, "Anti AFK", "Cegah kick karena idle", C.amber, false, 10)
local afkConn
afkClick.MouseButton1Click:Connect(function()
    ANS.antiAfk = not ANS.antiAfk
    if ANS.antiAfk then
        afkConn = task.spawn(function()
            while ANS.antiAfk do
                -- Simulasi gerakan kecil biar ga AFK
                local orig = HRP.CFrame
                Humanoid:Move(Vector3.new(0.1,0,0), false)
                task.wait(0.1)
                Humanoid:Move(Vector3.new(-0.1,0,0), false)
                task.wait(0.1)
                Humanoid:Move(Vector3.zero, false)
                -- Virtual input jump setiap 55 detik
                task.wait(55)
                if ANS.antiAfk then
                    Humanoid.Jump = true
                    task.wait(0.2)
                    Humanoid.Jump = false
                end
            end
        end)
        notify("therX | Anti AFK","Aktif — tidak akan di-kick",2)
    else
        notify("therX | Anti AFK","Nonaktif",1.5)
    end
end)

-- Reset counter button
local resetH = Instance.new("Frame", p8)
resetH.Size=UDim2.new(1,0,0,33); resetH.BackgroundTransparency=1; resetH.LayoutOrder=11
local resetUl = Instance.new("UIListLayout", resetH)
resetUl.FillDirection=Enum.FillDirection.Horizontal; resetUl.Padding=UDim.new(0,6)
glBtn(resetH,"🔄 Reset Counter",80,80,80,1,function()
    ANS.count={pushup=0,situp=0,jjs=0,pullup=0}
    notify("therX | ANS","Counter direset",1.5)
end)

-- =============================================
-- STATUS BAR
-- =============================================
local sBar = Instance.new("Frame", main)
sBar.Size=UDim2.new(1,0,0,22); sBar.Position=UDim2.new(0,0,1,-22)
sBar.BackgroundColor3=Color3.fromRGB(0,0,0); sBar.BackgroundTransparency=0.45
sBar.BorderSizePixel=0; sBar.ZIndex=2
Instance.new("UICorner",sBar).CornerRadius=UDim.new(0,20)

local sDot = Instance.new("Frame", sBar)
sDot.Size=UDim2.new(0,6,0,6); sDot.Position=UDim2.new(0,10,0.5,-3)
sDot.BackgroundColor3=Color3.fromRGB(80,255,120); sDot.BorderSizePixel=0
Instance.new("UICorner",sDot).CornerRadius=UDim.new(1,0)
TweenService:Create(sDot,TweenInfo.new(1.3,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=0.7}):Play()

local sTxt = Instance.new("TextLabel", sBar)
sTxt.Size=UDim2.new(0.4,0,1,0); sTxt.Position=UDim2.new(0,20,0,0)
sTxt.BackgroundTransparency=1; sTxt.Text="ATTACHED"
sTxt.TextColor3=Color3.fromRGB(80,55,110); sTxt.Font=Enum.Font.Gotham; sTxt.TextSize=9
sTxt.TextXAlignment=Enum.TextXAlignment.Left; sTxt.ZIndex=3

local sServerInfo = Instance.new("TextLabel", sBar)
sServerInfo.Size=UDim2.new(0.3,0,1,0); sServerInfo.Position=UDim2.new(0.35,0,0,0)
sServerInfo.BackgroundTransparency=1
sServerInfo.Text="#players: "..#Players:GetPlayers().." | "..tostring(game.PlaceId)
sServerInfo.TextColor3=Color3.fromRGB(80,55,110); sServerInfo.Font=Enum.Font.Gotham; sServerInfo.TextSize=8
sServerInfo.TextXAlignment=Enum.TextXAlignment.Center; sServerInfo.ZIndex=3

local sTime = Instance.new("TextLabel", sBar)
sTime.Size=UDim2.new(0.25,-10,1,0); sTime.Position=UDim2.new(0.75,0,0,0)
sTime.BackgroundTransparency=1; sTime.TextColor3=Color3.fromRGB(80,55,110)
sTime.Font=Enum.Font.Gotham; sTime.TextSize=9
sTime.TextXAlignment=Enum.TextXAlignment.Right; sTime.ZIndex=3

RunService.Heartbeat:Connect(function()
    pcall(function()
        local t = os.time()
        local h = math.floor(t/3600)%24
        local m = math.floor(t/60)%60
        local s = t%60
        sTime.Text=string.format("%02d:%02d:%02d",h,m,s)
    end)
    sServerInfo.Text="#players: "..#Players:GetPlayers()
end)

-- =============================================
-- MINI BAR
-- =============================================
miniBar = Instance.new("Frame", gui)
miniBar.Name = "therX_MiniBar"
miniBar.Size = UDim2.new(0,180,0,38)
miniBar.Position = UDim2.new(0,20,1,-60)
miniBar.BackgroundColor3 = C.bg
miniBar.BackgroundTransparency = 0.15
miniBar.BorderSizePixel = 0
miniBar.Active = true; miniBar.Draggable = true
miniBar.Visible = false; miniBar.ZIndex = 10
Instance.new("UICorner",miniBar).CornerRadius=UDim.new(0,19)
local mbs = Instance.new("UIStroke",miniBar); mbs.Color=C.purple; mbs.Transparency=0.4; mbs.Thickness=1

local mOrb = Instance.new("Frame", miniBar)
mOrb.Size=UDim2.new(0,60,0,60); mOrb.Position=UDim2.new(0,-10,0.5,-30)
mOrb.BackgroundColor3=C.purple; mOrb.BackgroundTransparency=0.88; mOrb.BorderSizePixel=0; mOrb.ZIndex=10
Instance.new("UICorner",mOrb).CornerRadius=UDim.new(1,0)

local mLogo = Instance.new("Frame", miniBar)
mLogo.Size=UDim2.new(0,24,0,24); mLogo.Position=UDim2.new(0,8,0.5,-12)
mLogo.BackgroundTransparency=1; mLogo.ZIndex=11
hex(mLogo,12,12,12,C.purple,0.65); hex(mLogo,12,12,8,C.blue,0.70); hex(mLogo,12,12,3,C.white,0.1)

local mTitle = Instance.new("TextLabel", miniBar)
mTitle.Size=UDim2.new(0,55,0,16); mTitle.Position=UDim2.new(0,38,0.5,-9)
mTitle.BackgroundTransparency=1; mTitle.Text="therX"
mTitle.TextColor3=C.textBr; mTitle.Font=Enum.Font.GothamBold; mTitle.TextSize=13
mTitle.TextXAlignment=Enum.TextXAlignment.Left; mTitle.ZIndex=11

local mVer = Instance.new("TextLabel", miniBar)
mVer.Size=UDim2.new(0,55,0,10); mVer.Position=UDim2.new(0,38,0.5,5)
mVer.BackgroundTransparency=1; mVer.Text="v0.1.0"
mVer.TextColor3=C.purple; mVer.Font=Enum.Font.Gotham; mVer.TextSize=8
mVer.TextXAlignment=Enum.TextXAlignment.Left; mVer.ZIndex=11

-- FPS di miniBar
local mFps = Instance.new("TextLabel", miniBar)
mFps.Size=UDim2.new(0,50,1,0); mFps.Position=UDim2.new(0,96,0,0)
mFps.BackgroundTransparency=1; mFps.Text="-- fps"
mFps.TextColor3=C.green; mFps.Font=Enum.Font.Gotham; mFps.TextSize=8
mFps.TextXAlignment=Enum.TextXAlignment.Center; mFps.ZIndex=11

-- Update FPS di miniBar
RunService.Heartbeat:Connect(function()
    -- reuse fpsPingLabel text
    local t = fpsPingLabel.Text
    local fps = t:match("FPS: (%d+)")
    if fps then mFps.Text=fps.." fps" end
end)

-- Tombol expand
local mBtn = Instance.new("TextButton", miniBar)
mBtn.Size=UDim2.new(0,28,0,28); mBtn.Position=UDim2.new(1,-34,0.5,-14)
mBtn.BackgroundColor3=C.purple; mBtn.BackgroundTransparency=0.5
mBtn.BorderSizePixel=0; mBtn.Text="▲"; mBtn.TextColor3=C.textBr
mBtn.Font=Enum.Font.GothamBold; mBtn.TextSize=11; mBtn.ZIndex=12
Instance.new("UICorner",mBtn).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",mBtn).Color=C.purple

mBtn.MouseEnter:Connect(function() tween(mBtn,{BackgroundTransparency=0.25},0.1) end)
mBtn.MouseLeave:Connect(function() tween(mBtn,{BackgroundTransparency=0.5},0.1) end)
mBtn.MouseButton1Click:Connect(function()
    miniBar.Visible=false
    main.Size=UDim2.new(0,620,0,0)
    main.BackgroundTransparency=1
    main.Visible=true
    tween(main,{Size=UDim2.new(0,620,0,400),BackgroundTransparency=0.08},0.25)
end)

local mDot = Instance.new("Frame", miniBar)
mDot.Size=UDim2.new(0,5,0,5); mDot.Position=UDim2.new(0,91,0.5,-2)
mDot.BackgroundColor3=C.green; mDot.BorderSizePixel=0; mDot.ZIndex=11
Instance.new("UICorner",mDot).CornerRadius=UDim.new(1,0)
TweenService:Create(mDot,TweenInfo.new(1.3,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=0.75}):Play()

setLoadingProgress(95, "Menyelesaikan inisialisasi...")

-- =============================================
-- ACTIVATE
-- =============================================
setTab(1)
p1.Visible = true

notify("therX v0.1.0","by AxzZz — Script loaded ✓",4)

setLoadingProgress(100, "therX berhasil dimuat!")
task.wait(0.45)
local fadeInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
TweenService:Create(loadingCard, fadeInfo, {BackgroundTransparency = 1}):Play()
TweenService:Create(loadingStroke, fadeInfo, {Transparency = 1}):Play()
for _, item in ipairs(loadingCard:GetDescendants()) do
    if item:IsA("TextLabel") then
        TweenService:Create(item, fadeInfo, {TextTransparency = 1}):Play()
    elseif item:IsA("Frame") then
        TweenService:Create(item, fadeInfo, {BackgroundTransparency = 1}):Play()
    end
end
task.wait(0.3)
loadingGui:Destroy()
