-- therX v0.1.1 by AxzZz
-- Fixed: UI rapi, no emoji (icon shape), ANS working, AutoWalk + Play Route

local ok, err = pcall(function()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui", 10)
local GuiParent = (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or PlayerGui

local Character = Player.Character or Player.CharacterAdded:Wait()
local HRP       = Character:WaitForChild("HumanoidRootPart", 10)
local Humanoid  = Character:WaitForChild("Humanoid", 10)
local Camera    = workspace.CurrentCamera

if not HRP or not Humanoid then return end

Player.CharacterAdded:Connect(function(c)
    Character = c
    HRP       = c:WaitForChild("HumanoidRootPart")
    Humanoid  = c:WaitForChild("Humanoid")
end)

-- =============================================
-- STATE
-- =============================================
local State = {
    fly=false, infiniteJ=false, autoWalk=false, antiLag=false,
    recording=false, noclip=false, godMode=false, antiVoid=false,
    espEnabled=false, chams=false, playingRoute=false,
    flySpeed=50, jumpPower=100, walkSpeed=16,
    mapName="Unknown Map", obsName="Unknown Obstacle",
}
local SavedRoutes = {}
local WaypointLog = {}
local RecordStart = 0
local RecordConn, AutoWalkConn, FlyConn, JumpConn, NoclipConn, AntiVoidConn, GodConn, PlayConn
local EspObjects = {}
local ChamsObjects = {}
local BodyVel, BodyGyro
local lastSafe = HRP.Position

-- =============================================
-- UTILITY
-- =============================================
local function tween(obj, props, t)
    pcall(function()
        TweenService:Create(obj, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quad), props):Play()
    end)
end

local function notify(title, msg, dur)
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "therXN_" .. math.random(1000, 9999)
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 9999
        sg.Parent = GuiParent

        local f = Instance.new("Frame", sg)
        f.Size = UDim2.new(0, 280, 0, 56)
        f.Position = UDim2.new(1, 20, 0, 18)
        f.BackgroundColor3 = Color3.fromRGB(14, 7, 28)
        f.BackgroundTransparency = 0.05
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
        local fs = Instance.new("UIStroke", f)
        fs.Color = Color3.fromRGB(160, 100, 255)
        fs.Transparency = 0.4

        local t1 = Instance.new("TextLabel", f)
        t1.Size = UDim2.new(1, -20, 0, 18)
        t1.Position = UDim2.new(0, 12, 0, 8)
        t1.BackgroundTransparency = 1
        t1.Text = title
        t1.TextColor3 = Color3.fromRGB(220, 200, 255)
        t1.Font = Enum.Font.GothamBold
        t1.TextSize = 12
        t1.TextXAlignment = Enum.TextXAlignment.Left

        local t2 = Instance.new("TextLabel", f)
        t2.Size = UDim2.new(1, -20, 0, 16)
        t2.Position = UDim2.new(0, 12, 0, 28)
        t2.BackgroundTransparency = 1
        t2.Text = msg
        t2.TextColor3 = Color3.fromRGB(140, 110, 180)
        t2.Font = Enum.Font.Gotham
        t2.TextSize = 10
        t2.TextXAlignment = Enum.TextXAlignment.Left

        tween(f, {Position = UDim2.new(1, -300, 0, 18)}, 0.3)
        task.delay(dur or 2.5, function()
            tween(f, {Position = UDim2.new(1, 20, 0, 18)}, 0.2)
            task.delay(0.25, function() pcall(function() sg:Destroy() end) end)
        end)
    end)
end

-- Better fireproximityprompt (handle HoldDuration)
local function firePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end
    local success = pcall(function()
        local oldHold = prompt.HoldDuration
        prompt.HoldDuration = 0
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            -- fallback manual
            prompt:InputHoldBegin()
            task.wait(0.05)
            prompt:InputHoldEnd()
        end
        prompt.HoldDuration = oldHold
    end)
    return success
end

-- =============================================
-- FEATURES
-- =============================================
local function enableFly()
    pcall(function()
        if BodyVel then BodyVel:Destroy() end
        if BodyGyro then BodyGyro:Destroy() end
        BodyVel = Instance.new("BodyVelocity")
        BodyVel.Velocity = Vector3.zero
        BodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        BodyVel.Parent = HRP
        BodyGyro = Instance.new("BodyGyro")
        BodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        BodyGyro.P = 1e4
        BodyGyro.Parent = HRP
        if FlyConn then FlyConn:Disconnect() end
        FlyConn = RunService.Heartbeat:Connect(function()
            if not State.fly or not HRP then return end
            local d = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end
            BodyVel.Velocity = d.Magnitude > 0 and d.Unit * State.flySpeed or Vector3.zero
            BodyGyro.CFrame = Camera.CFrame
        end)
        Humanoid.PlatformStand = true
    end)
    notify("Fly", "Aktif — WASD + Space/Shift", 2)
end

local function disableFly()
    pcall(function()
        if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
        if BodyVel then BodyVel:Destroy(); BodyVel = nil end
        if BodyGyro then BodyGyro:Destroy(); BodyGyro = nil end
        if Humanoid then Humanoid.PlatformStand = false end
    end)
    notify("Fly", "Nonaktif", 1.5)
end

local function enableInfJump()
    if JumpConn then JumpConn:Disconnect() end
    JumpConn = UserInputService.JumpRequest:Connect(function()
        if State.infiniteJ and Humanoid then
            Humanoid.JumpPower = State.jumpPower
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    notify("Infinity Jump", "Aktif", 2)
end

local function disableInfJump()
    if JumpConn then JumpConn:Disconnect(); JumpConn = nil end
    notify("Infinity Jump", "Nonaktif", 1.5)
end

local function enableAutoWalk()
    if AutoWalkConn then AutoWalkConn:Disconnect() end
    pcall(function()
        Humanoid.WalkSpeed = State.walkSpeed
    end)
    AutoWalkConn = RunService.Heartbeat:Connect(function()
        if not State.autoWalk or not Humanoid or not HRP then return end
        -- Move forward relative to character
        local look = HRP.CFrame.LookVector
        Humanoid:Move(Vector3.new(look.X, 0, look.Z).Unit, false)
    end)
    notify("Auto Walk", "Aktif", 2)
end

local function disableAutoWalk()
    if AutoWalkConn then AutoWalkConn:Disconnect(); AutoWalkConn = nil end
    pcall(function()
        if Humanoid then
            Humanoid:Move(Vector3.zero, false)
            Humanoid.WalkSpeed = 16
        end
    end)
    notify("Auto Walk", "Nonaktif", 1.5)
end

local function enableNoclip()
    if NoclipConn then NoclipConn:Disconnect() end
    NoclipConn = RunService.Stepped:Connect(function()
        if not State.noclip or not Character then return end
        for _, p in ipairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function() p.CanCollide = false end)
            end
        end
    end)
    notify("NoClip", "Aktif", 2)
end

local function disableNoclip()
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
    notify("NoClip", "Nonaktif", 1.5)
end

local function enableGodMode()
    pcall(function()
        Humanoid.MaxHealth = math.huge
        Humanoid.Health = math.huge
    end)
    if GodConn then GodConn:Disconnect() end
    GodConn = RunService.Heartbeat:Connect(function()
        if State.godMode and Humanoid then
            pcall(function() Humanoid.Health = Humanoid.MaxHealth end)
        end
    end)
    notify("God Mode", "Aktif — HP Infinity", 2)
end

local function disableGodMode()
    if GodConn then GodConn:Disconnect(); GodConn = nil end
    pcall(function()
        if Humanoid then
            Humanoid.MaxHealth = 100
            Humanoid.Health = 100
        end
    end)
    notify("God Mode", "Nonaktif", 1.5)
end

local function enableAntiVoid()
    if AntiVoidConn then AntiVoidConn:Disconnect() end
    lastSafe = HRP.Position
    AntiVoidConn = RunService.Heartbeat:Connect(function()
        if not State.antiVoid or not HRP then return end
        pcall(function()
            if HRP.Position.Y > -50 then
                lastSafe = HRP.Position
            else
                HRP.CFrame = CFrame.new(lastSafe + Vector3.new(0, 5, 0))
            end
        end)
    end)
    notify("Anti-Void", "Aktif", 2)
end

local function disableAntiVoid()
    if AntiVoidConn then AntiVoidConn:Disconnect(); AntiVoidConn = nil end
    notify("Anti-Void", "Nonaktif", 1.5)
end

local function teleportToPlayer(name)
    local t = Players:FindFirstChild(name)
    if t and t.Character then
        local th = t.Character:FindFirstChild("HumanoidRootPart")
        if th then
            HRP.CFrame = th.CFrame + Vector3.new(2, 0, 2)
            notify("Teleport", "Ke " .. name, 2)
        end
    else
        notify("Teleport", "Tidak ditemukan: " .. name, 2)
    end
end

-- ESP
local EspConn
local function clearEsp()
    for _, o in pairs(EspObjects) do pcall(function() o:Destroy() end) end
    EspObjects = {}
end

local function enableEsp()
    if EspConn then EspConn:Disconnect() end
    EspConn = RunService.Heartbeat:Connect(function()
        if not State.espEnabled then return end
        clearEsp()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player and plr.Character then
                local head = plr.Character:FindFirstChild("Head")
                if head then
                    pcall(function()
                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.new(0, 90, 0, 28)
                        bb.StudsOffset = Vector3.new(0, 2.8, 0)
                        bb.AlwaysOnTop = true
                        bb.Parent = head
                        local nl = Instance.new("TextLabel", bb)
                        nl.Size = UDim2.new(1, 0, 1, 0)
                        nl.BackgroundTransparency = 0.25
                        nl.BackgroundColor3 = Color3.fromRGB(14, 7, 28)
                        nl.Text = plr.Name
                        nl.TextColor3 = Color3.fromRGB(160, 100, 255)
                        nl.Font = Enum.Font.GothamBold
                        nl.TextSize = 11
                        nl.BorderSizePixel = 0
                        Instance.new("UICorner", nl).CornerRadius = UDim.new(0, 6)
                        table.insert(EspObjects, bb)
                    end)
                end
            end
        end
    end)
    notify("ESP", "Aktif", 2)
end

local function disableEsp()
    if EspConn then EspConn:Disconnect(); EspConn = nil end
    clearEsp()
    notify("ESP", "Nonaktif", 1.5)
end

-- Chams
local ChamsConn
local function clearChams()
    for part, orig in pairs(ChamsObjects) do
        pcall(function()
            part.Color = orig.c
            part.Material = orig.m
        end)
    end
    ChamsObjects = {}
end

local function enableChams()
    if ChamsConn then ChamsConn:Disconnect() end
    ChamsConn = RunService.Heartbeat:Connect(function()
        if not State.chams then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player and plr.Character then
                for _, part in ipairs(plr.Character:GetDescendants()) do
                    if part:IsA("BasePart") and not ChamsObjects[part] then
                        pcall(function()
                            ChamsObjects[part] = {c = part.Color, m = part.Material}
                            part.Color = Color3.fromRGB(80, 170, 255)
                            part.Material = Enum.Material.Neon
                        end)
                    end
                end
            end
        end
    end)
    notify("Chams", "Aktif", 2)
end

local function disableChams()
    if ChamsConn then ChamsConn:Disconnect(); ChamsConn = nil end
    clearChams()
    notify("Chams", "Nonaktif", 1.5)
end

-- Potato Mode
local function enablePotato()
    pcall(function()
        workspace.GlobalShadows = false
        Lighting.GlobalShadows = false
        for _, o in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if o:IsA("ParticleEmitter") or o:IsA("Fire") or o:IsA("Smoke")
                    or o:IsA("Sparkles") or o:IsA("Trail") then
                    o.Enabled = false
                end
                if o:IsA("PostEffect") or o:IsA("BlurEffect") or o:IsA("BloomEffect")
                    or o:IsA("SunRaysEffect") then
                    o.Enabled = false
                end
            end)
        end
    end)
    notify("Potato Mode", "Anti Lag aktif", 2)
end

local function disablePotato()
    pcall(function()
        workspace.GlobalShadows = true
        Lighting.GlobalShadows = true
    end)
    notify("Potato Mode", "Nonaktif", 1.5)
end

-- Record
local function startRecord()
    WaypointLog = {}
    RecordStart = tick()
    State.recording = true
    if RecordConn then RecordConn:Disconnect() end
    RecordConn = RunService.Heartbeat:Connect(function()
        if not State.recording or not HRP then return end
        local pos = HRP.Position
        if #WaypointLog == 0 or (WaypointLog[#WaypointLog] - pos).Magnitude > 2.5 then
            table.insert(WaypointLog, pos)
        end
    end)
    notify("Record", "Merekam jalur...", 2)
end

local function stopRecord()
    State.recording = false
    if RecordConn then RecordConn:Disconnect(); RecordConn = nil end
    notify("Record", "Stop — " .. #WaypointLog .. " points", 2)
end

local function saveRecord()
    if #WaypointLog == 0 then
        notify("Save", "Belum ada waypoints!", 2)
        return
    end
    table.insert(SavedRoutes, {
        mapName = State.mapName,
        obsName = State.obsName,
        waypoints = table.clone(WaypointLog),
        duration = math.floor(tick() - RecordStart),
        timestamp = tostring(math.floor(tick()))
    })
    notify("Saved", "[" .. State.mapName .. "] (" .. #WaypointLog .. " pts)", 3)
    WaypointLog = {}
end

-- Play saved route (Auto Walk along waypoints + Auto Jump)
local JUMP_HEIGHT_THRESHOLD = 2.8  -- selisih Y lebih dari ini → auto jump
local lastJumpTime = 0
local JUMP_COOLDOWN = 0.6

local function playRoute(route)
    if State.playingRoute then
        State.playingRoute = false
        if PlayConn then PlayConn:Disconnect(); PlayConn = nil end
        notify("Route", "Playback dihentikan", 1.5)
        return
    end
    if not route or not route.waypoints or #route.waypoints == 0 then
        notify("Route", "Route kosong", 2)
        return
    end
    State.playingRoute = true
    State.autoWalk = false
    if AutoWalkConn then AutoWalkConn:Disconnect(); AutoWalkConn = nil end

    local idx = 1
    local wps = route.waypoints
    notify("Route", "Playing " .. #wps .. " points...", 2)

    if PlayConn then PlayConn:Disconnect() end
    PlayConn = RunService.Heartbeat:Connect(function()
        if not State.playingRoute or not HRP or not Humanoid then
            State.playingRoute = false
            if PlayConn then PlayConn:Disconnect(); PlayConn = nil end
            return
        end
        if idx > #wps then
            State.playingRoute = false
            if PlayConn then PlayConn:Disconnect(); PlayConn = nil end
            notify("Route", "Selesai!", 2)
            return
        end

        local target = wps[idx]
        local dist   = (HRP.Position - target).Magnitude
        local now    = tick()

        -- Auto Jump: kalau waypoint berikutnya jauh lebih tinggi dari posisi sekarang
        local heightDiff = target.Y - HRP.Position.Y
        if heightDiff > JUMP_HEIGHT_THRESHOLD and now - lastJumpTime > JUMP_COOLDOWN then
            pcall(function()
                local hstate = Humanoid:GetState()
                -- lompat hanya kalau sedang di tanah / tidak sudah lagi di udara
                if hstate ~= Enum.HumanoidStateType.Jumping
                    and hstate ~= Enum.HumanoidStateType.Freefall then
                    Humanoid.Jump = true
                    lastJumpTime = now
                end
            end)
        end

        if dist < 3.5 then
            idx = idx + 1
        else
            pcall(function()
                Humanoid.WalkSpeed = State.walkSpeed
                Humanoid:MoveTo(target)
            end)
        end
    end)
end

local function copyMapName()
    local n = workspace.Name
    pcall(function()
        for _, v in ipairs(workspace:GetChildren()) do
            if v:IsA("Model") and v.Name ~= "Camera" and v.Name ~= "Terrain" then
                n = v.Name
                break
            end
        end
    end)
    State.mapName = n
    pcall(function() setclipboard(n) end)
    notify("Map", "Nama: " .. n, 3)
    return n
end

local function rejoin()
    notify("Rejoin", "Rejoining...", 2)
    task.delay(1, function()
        pcall(function() TeleportService:Teleport(game.PlaceId, Player) end)
    end)
end

-- =============================================
-- ANS (Abdi Negara Simulator) - FIXED v3
-- Remotes (Cobalt spy confirmed):
--   ExerciseInput:FireServer("SIAP SIKAP PUSHUP")
--   ExerciseSkillCheck:FireServer(1)
--   ExerciseStop:FireServer("Pushup")
-- =============================================
local ANS = {
    running  = {pushup = false, situp = false, jjs = false, pullup = false},
    count    = {pushup = 0, situp = 0, jjs = 0, pullup = 0},
    antiAfk  = false,
    interval = 0.10,   -- default 0.10 detik (bisa diganti 1.0)
    useNeedle = true,  -- coba deteksi needle hijau dulu, fallback ke interval biasa
}

-- Data per latihan (Input command + Stop name)
-- Confirmed via Cobalt: Pushup + Situp
local EXERCISE_DATA = {
    pushup = {
        input = "SIAP SIKAP PUSHUP",
        stop  = "Pushup",
    },
    situp = {
        input = "SIAP SIKAP SITUP",
        stop  = "Situp",
    },
    jjs = {
        input = "SIAP SIKAP JJS",
        stop  = "JJS",
    },
    pullup = {
        input = "SIAP SIKAP PULLUP",
        stop  = "Pullup",
    },
}

-- Cache remotes
local ExerciseInput, ExerciseSkillCheck, ExerciseStop, AutoExerciseEvent
local function refreshRemotes()
    pcall(function()
        local qs = game:GetService("ReplicatedStorage"):FindFirstChild("QuestSystem")
        if qs then
            ExerciseInput      = qs:FindFirstChild("ExerciseInput")
            ExerciseSkillCheck = qs:FindFirstChild("ExerciseSkillCheck")
            ExerciseStop       = qs:FindFirstChild("ExerciseStop")
            AutoExerciseEvent  = qs:FindFirstChild("AutoExerciseEvent")
        end
    end)
end
refreshRemotes()

-- Cari needle GUI dari PlayerGui/CoreGui
-- Needle = ImageLabel/Frame yang bergerak, area hijau = Frame dengan BackgroundColor hijau
local function findNeedleGui()
    local function scanGui(parent)
        for _, obj in ipairs(parent:GetDescendants()) do
            -- Cari label "REP" atau frame exercise
            if obj:IsA("TextLabel") and obj.Text ~= nil then
                local t = obj.Text:lower()
                if t:find("rep") or t:find("push") or t:find("sit") or t:find("pull") or t:find("jjs") then
                    return obj.Parent  -- kembalikan parent frame exercise
                end
            end
        end
    end
    return scanGui(Player.PlayerGui) or scanGui(GuiParent)
end

-- Deteksi apakah needle sedang di area hijau
-- Strategi: cari Frame dengan warna hijau (area target) dan bandingkan posisi dengan needle
local function isNeedleInGreen()
    local found = false
    pcall(function()
        local exerciseFrame = findNeedleGui()
        if not exerciseFrame then return end

        local greenArea = nil
        local needle    = nil

        for _, obj in ipairs(exerciseFrame:GetDescendants()) do
            if obj:IsA("Frame") or obj:IsA("ImageLabel") then
                local c = obj.BackgroundColor3
                -- Cari frame hijau (area target)
                if c.G > 0.55 and c.R < 0.45 and c.B < 0.45 and obj.BackgroundTransparency < 0.5 then
                    if obj.AbsoluteSize.X > 20 then  -- bukan dot kecil
                        greenArea = obj
                    end
                end
                -- Cari needle: frame putih/terang kecil bergerak
                if c.R > 0.80 and c.G > 0.80 and c.B > 0.80
                    and obj.AbsoluteSize.X < 20 and obj.BackgroundTransparency < 0.5 then
                    needle = obj
                end
            end
        end

        if greenArea and needle then
            local nPos  = needle.AbsolutePosition.X
            local gMin  = greenArea.AbsolutePosition.X
            local gMax  = gMin + greenArea.AbsoluteSize.X
            -- Needle di dalam area hijau dengan sedikit margin
            found = (nPos >= gMin - 5) and (nPos <= gMax + 5)
        end
    end)
    return found
end

local function startExercise(key)
    if ANS.running[key] then return end
    local data = EXERCISE_DATA[key]
    if not data then return end

    ANS.running[key] = true
    notify("ANS", key:upper() .. " dimulai (interval " .. ANS.interval .. "s)", 1.8)

    task.spawn(function()
        refreshRemotes()

        -- 1. Mulai latihan via RemoteEvent
        pcall(function()
            if ExerciseInput then
                ExerciseInput:FireServer(data.input)
            end
        end)

        task.wait(0.3)  -- beri waktu server mulai

        -- 2. Loop skill check dengan needle detection
        local accum = 0
        local frameConn
        frameConn = RunService.Heartbeat:Connect(function(dt)
            if not ANS.running[key] then
                frameConn:Disconnect()
                return
            end

            if ANS.useNeedle then
                -- Mode needle: fire saat jarum di hijau
                if isNeedleInGreen() then
                    pcall(function()
                        if not ExerciseSkillCheck or not ExerciseSkillCheck.Parent then
                            refreshRemotes()
                        end
                        if ExerciseSkillCheck then
                            ExerciseSkillCheck:FireServer(1)
                        end
                    end)
                    ANS.count[key] = ANS.count[key] + 1
                    task.wait(ANS.interval)  -- cooldown setelah berhasil kena
                end
            else
                -- Mode interval: fire setiap N detik
                accum = accum + dt
                if accum >= ANS.interval then
                    accum = 0
                    pcall(function()
                        if not ExerciseSkillCheck or not ExerciseSkillCheck.Parent then
                            refreshRemotes()
                        end
                        if ExerciseSkillCheck then
                            ExerciseSkillCheck:FireServer(1)
                        end
                    end)
                    ANS.count[key] = ANS.count[key] + 1
                end
            end
        end)
    end)
end

local function stopExercise(key)
    if not ANS.running[key] then return end
    ANS.running[key] = false

    local data = EXERCISE_DATA[key]
    pcall(function()
        refreshRemotes()
        -- Stop latihan spesifik
        if ExerciseStop and data then
            ExerciseStop:FireServer(data.stop)
        end
        -- Stop auto mode bawaan game
        if AutoExerciseEvent then
            AutoExerciseEvent:FireServer("STOP")
        end
    end)

    notify("ANS", key:upper() .. " dihentikan", 1.5)
end

local function stopAllExercises()
    for k, running in pairs(ANS.running) do
        if running then
            stopExercise(k)
        end
    end
end

-- =============================================
-- GUI
-- =============================================
local oldG = GuiParent:FindFirstChild("therX_v3")
if oldG then oldG:Destroy() end
task.wait(0.05)

local gui = Instance.new("ScreenGui")
gui.Name = "therX_v3"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = GuiParent

local miniBar

local C = {
    bg      = Color3.fromRGB(14, 7, 28),
    white   = Color3.fromRGB(255, 255, 255),
    purple  = Color3.fromRGB(160, 100, 255),
    blue    = Color3.fromRGB(80, 170, 255),
    green   = Color3.fromRGB(70, 220, 110),
    amber   = Color3.fromRGB(255, 185, 55),
    red     = Color3.fromRGB(255, 80, 80),
    textBr  = Color3.fromRGB(230, 218, 255),
    textDim = Color3.fromRGB(140, 115, 180),
    textMut = Color3.fromRGB(95, 75, 130),
    card    = Color3.fromRGB(22, 12, 40),
}

-- Main frame
local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 640, 0, 420)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = C.bg
main.BackgroundTransparency = 0.06
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 18)
local ms = Instance.new("UIStroke", main)
ms.Color = Color3.fromRGB(255, 255, 255)
ms.Transparency = 0.82
ms.Thickness = 1

-- Responsive scale
local mainScale = Instance.new("UIScale", main)
local function updateScale()
    pcall(function()
        local vp = workspace.CurrentCamera.ViewportSize
        local s = math.clamp(math.min((vp.X - 40) / 640, (vp.Y - 40) / 420), 0.5, 1)
        mainScale.Scale = s
    end)
end
updateScale()
pcall(function()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end)

-- Soft orbs
local function makeOrb(x, y, sz, col, tr)
    local o = Instance.new("Frame", main)
    o.Size = UDim2.new(0, sz, 0, sz)
    o.Position = UDim2.new(0, x, 0, y)
    o.BackgroundColor3 = col
    o.BackgroundTransparency = tr
    o.BorderSizePixel = 0
    o.ZIndex = 0
    Instance.new("UICorner", o).CornerRadius = UDim.new(1, 0)
end
makeOrb(-90, -90, 240, C.purple, 0.90)
makeOrb(520, 310, 190, C.blue, 0.92)
makeOrb(460, -40, 130, Color3.fromRGB(255, 80, 200), 0.94)

-- Title bar
local tBar = Instance.new("Frame", main)
tBar.Size = UDim2.new(1, 0, 0, 48)
tBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
tBar.BackgroundTransparency = 0.94
tBar.BorderSizePixel = 0
tBar.ZIndex = 2
Instance.new("UICorner", tBar).CornerRadius = UDim.new(0, 18)

-- Logo (simple geometric)
local logo = Instance.new("Frame", tBar)
logo.Size = UDim2.new(0, 28, 0, 28)
logo.Position = UDim2.new(0, 14, 0.5, -14)
logo.BackgroundTransparency = 1
logo.ZIndex = 3
local function hex(parent, cx, cy, r, col, a)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0, r * 2, 0, r * 2)
    f.Position = UDim2.new(0, cx - r, 0, cy - r)
    f.BackgroundColor3 = col
    f.BackgroundTransparency = a
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
end
hex(logo, 14, 14, 13, C.purple, 0.55)
hex(logo, 14, 14, 8, C.blue, 0.45)
hex(logo, 14, 14, 3.5, C.white, 0.15)

local titleL = Instance.new("TextLabel", tBar)
titleL.Size = UDim2.new(0, 90, 0, 20)
titleL.Position = UDim2.new(0, 50, 0, 8)
titleL.BackgroundTransparency = 1
titleL.Text = "therX"
titleL.TextColor3 = C.textBr
titleL.Font = Enum.Font.GothamBold
titleL.TextSize = 16
titleL.TextXAlignment = Enum.TextXAlignment.Left
titleL.ZIndex = 3

local verL = Instance.new("TextLabel", tBar)
verL.Size = UDim2.new(0, 160, 0, 13)
verL.Position = UDim2.new(0, 50, 0, 28)
verL.BackgroundTransparency = 1
verL.Text = "v0.1.1  by AxzZz"
verL.TextColor3 = C.purple
verL.Font = Enum.Font.Gotham
verL.TextSize = 10
verL.TextXAlignment = Enum.TextXAlignment.Left
verL.ZIndex = 3

local fpsPingLabel = Instance.new("TextLabel", tBar)
fpsPingLabel.Size = UDim2.new(0, 170, 0, 16)
fpsPingLabel.Position = UDim2.new(0.5, -85, 0.5, -8)
fpsPingLabel.BackgroundTransparency = 1
fpsPingLabel.Text = "FPS: -- | Ping: --ms"
fpsPingLabel.TextColor3 = C.textDim
fpsPingLabel.Font = Enum.Font.Gotham
fpsPingLabel.TextSize = 11
fpsPingLabel.TextXAlignment = Enum.TextXAlignment.Center
fpsPingLabel.ZIndex = 3

local fpsN, fpsT = 0, 0
RunService.Heartbeat:Connect(function(dt)
    fpsN = fpsN + 1
    fpsT = fpsT + dt
    if fpsT >= 0.5 then
        local fps = math.floor(fpsN / fpsT)
        local ping = "--"
        pcall(function()
            ping = tostring(math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()))
        end)
        fpsPingLabel.Text = "FPS: " .. fps .. " | Ping: " .. ping .. "ms"
        fpsPingLabel.TextColor3 = fps >= 55 and C.green or (fps >= 30 and C.amber or C.red)
        fpsN = 0
        fpsT = 0
    end
end)

-- Window buttons
local function winBtn(parent, xOff, col, onClick)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 14, 0, 14)
    btn.Position = UDim2.new(1, xOff, 0.5, -7)
    btn.BackgroundColor3 = col
    btn.BackgroundTransparency = 0.15
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ZIndex = 3
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    btn.MouseButton1Click:Connect(onClick)
    btn.MouseEnter:Connect(function() tween(btn, {BackgroundTransparency = 0}, 0.1) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundTransparency = 0.15}, 0.1) end)
end

local function hideMain()
    tween(main, {Size = UDim2.new(0, 640, 0, 0), BackgroundTransparency = 1}, 0.2)
    task.delay(0.22, function()
        main.Visible = false
        main.Size = UDim2.new(0, 640, 0, 420)
        main.BackgroundTransparency = 0.06
        miniBar.Visible = true
    end)
end

local function killAll()
    State.fly = false; disableFly()
    State.infiniteJ = false; disableInfJump()
    State.autoWalk = false; disableAutoWalk()
    State.noclip = false; disableNoclip()
    State.godMode = false; disableGodMode()
    State.antiVoid = false; disableAntiVoid()
    State.espEnabled = false; disableEsp()
    State.chams = false; disableChams()
    State.antiLag = false; disablePotato()
    State.playingRoute = false
    if PlayConn then PlayConn:Disconnect(); PlayConn = nil end
    stopAllExercises()
    notify("Reset", "Semua fitur dimatikan", 2)
end

winBtn(tBar, -90, C.red, function()
    killAll()
    task.delay(0.3, function() gui:Destroy() end)
end)
winBtn(tBar, -68, C.amber, function()
    main.Visible = not main.Visible
end)
winBtn(tBar, -46, C.green, hideMain)

-- Sidebar
local SIDEW = 58
local CONTENTW = 640 - SIDEW

local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, SIDEW, 1, -48)
sidebar.Position = UDim2.new(0, 0, 0, 48)
sidebar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
sidebar.BackgroundTransparency = 0.5
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 2

local sideDiv = Instance.new("Frame", main)
sideDiv.Size = UDim2.new(0, 1, 1, -48)
sideDiv.Position = UDim2.new(0, SIDEW, 0, 48)
sideDiv.BackgroundColor3 = C.white
sideDiv.BackgroundTransparency = 0.88
sideDiv.BorderSizePixel = 0

-- Clean tab labels (no emoji)
local TABS = {
    {letter = "M", name = "Move"},
    {letter = "V", name = "Visual"},
    {letter = "R", name = "Record"},
    {letter = "S", name = "Saves"},
    {letter = "U", name = "Util"},
    {letter = "P", name = "Perf"},
    {letter = "L", name = "Players"},
    {letter = "A", name = "ANS"},
}

local tabBtns = {}
local tabPanels = {}
local curTab = 1

local function setTab(idx)
    curTab = idx
    for i, b in ipairs(tabBtns) do
        local active = (i == idx)
        tween(b, {BackgroundTransparency = active and 0.45 or 1}, 0.15)
        for _, child in ipairs(b:GetChildren()) do
            if child:IsA("TextLabel") then
                tween(child, {
                    TextColor3 = active and Color3.fromRGB(210, 175, 255) or Color3.fromRGB(95, 70, 130)
                }, 0.15)
            end
        end
    end
    for i, p in ipairs(tabPanels) do
        p.Visible = (i == idx)
    end
end

for i, tab in ipairs(TABS) do
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -6, 0, 42)
    btn.Position = UDim2.new(0, 3, 0, 6 + (i - 1) * 46)
    btn.BackgroundColor3 = C.purple
    btn.BackgroundTransparency = i == 1 and 0.45 or 1
    btn.BorderSizePixel = 0
    btn.ZIndex = 3
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local letterL = Instance.new("TextLabel", btn)
    letterL.Size = UDim2.new(1, 0, 0, 20)
    letterL.Position = UDim2.new(0, 0, 0, 4)
    letterL.BackgroundTransparency = 1
    letterL.Text = tab.letter
    letterL.TextColor3 = i == 1 and Color3.fromRGB(210, 175, 255) or Color3.fromRGB(95, 70, 130)
    letterL.Font = Enum.Font.GothamBold
    letterL.TextSize = 15
    letterL.ZIndex = 4

    local nameL = Instance.new("TextLabel", btn)
    nameL.Size = UDim2.new(1, 0, 0, 12)
    nameL.Position = UDim2.new(0, 0, 0, 24)
    nameL.BackgroundTransparency = 1
    nameL.Text = tab.name
    nameL.TextColor3 = i == 1 and Color3.fromRGB(210, 175, 255) or Color3.fromRGB(95, 70, 130)
    nameL.Font = Enum.Font.Gotham
    nameL.TextSize = 8
    nameL.ZIndex = 4

    btn.MouseButton1Click:Connect(function() setTab(i) end)
    table.insert(tabBtns, btn)
end

-- Panel factories
local function newPanel()
    local sf = Instance.new("ScrollingFrame", main)
    sf.Size = UDim2.new(0, CONTENTW - 14, 1, -58)
    sf.Position = UDim2.new(0, SIDEW + 8, 0, 52)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = C.purple
    sf.Visible = false
    sf.ZIndex = 2
    local ul = Instance.new("UIListLayout", sf)
    ul.Padding = UDim.new(0, 6)
    ul.SortOrder = Enum.SortOrder.LayoutOrder
    local up = Instance.new("UIPadding", sf)
    up.PaddingTop = UDim.new(0, 4)
    up.PaddingLeft = UDim.new(0, 2)
    up.PaddingRight = UDim.new(0, 6)
    ul:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0, 0, 0, ul.AbsoluteContentSize.Y + 12)
    end)
    return sf
end

local function newGridPanel()
    local sf = Instance.new("ScrollingFrame", main)
    sf.Size = UDim2.new(0, CONTENTW - 14, 1, -58)
    sf.Position = UDim2.new(0, SIDEW + 8, 0, 52)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = C.purple
    sf.Visible = false
    sf.ZIndex = 2
    local ug = Instance.new("UIGridLayout", sf)
    ug.CellSize = UDim2.new(0, (CONTENTW - 20) / 2 - 4, 0, 56)
    ug.CellPadding = UDim2.new(0, 8, 0, 8)
    ug.SortOrder = Enum.SortOrder.LayoutOrder
    local up = Instance.new("UIPadding", sf)
    up.PaddingTop = UDim.new(0, 4)
    up.PaddingLeft = UDim.new(0, 2)
    up.PaddingRight = UDim.new(0, 4)
    ug:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0, 0, 0, ug.AbsoluteContentSize.Y + 12)
    end)
    return sf
end

-- UI Helpers
local function sectLbl(parent, txt, order)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = Color3.fromRGB(140, 95, 200)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 3
    l.LayoutOrder = order or 0
    return l
end

local function toggleCard(parent, label, sub, iconColor, warn, order)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 54)
    row.BackgroundColor3 = warn and Color3.fromRGB(48, 28, 10) or C.card
    row.BackgroundTransparency = warn and 0.35 or 0.25
    row.BorderSizePixel = 0
    row.ZIndex = 3
    row.LayoutOrder = order or 1
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)
    local rs = Instance.new("UIStroke", row)
    rs.Color = warn and C.amber or Color3.fromRGB(60, 40, 90)
    rs.Transparency = 0.5
    rs.Thickness = 1

    -- Icon circle
    local ib = Instance.new("Frame", row)
    ib.Size = UDim2.new(0, 30, 0, 30)
    ib.Position = UDim2.new(0, 10, 0.5, -15)
    ib.BackgroundColor3 = iconColor
    ib.BackgroundTransparency = 0.7
    ib.BorderSizePixel = 0
    Instance.new("UICorner", ib).CornerRadius = UDim.new(0, 8)
    local is = Instance.new("UIStroke", ib)
    is.Color = iconColor
    is.Transparency = 0.3
    is.Thickness = 1.2

    local il = Instance.new("TextLabel", ib)
    il.Size = UDim2.new(1, 0, 1, 0)
    il.BackgroundTransparency = 1
    il.Text = "●"
    il.TextColor3 = iconColor
    il.Font = Enum.Font.GothamBold
    il.TextSize = 11
    il.ZIndex = 4

    local nl = Instance.new("TextLabel", row)
    nl.Size = UDim2.new(0.55, 0, 0, 16)
    nl.Position = UDim2.new(0, 48, 0, 10)
    nl.BackgroundTransparency = 1
    nl.Text = label
    nl.TextColor3 = warn and C.amber or C.textBr
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = 12
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.ZIndex = 4
    nl.TextTruncate = Enum.TextTruncate.AtEnd

    local sl = Instance.new("TextLabel", row)
    sl.Size = UDim2.new(0.55, 0, 0, 14)
    sl.Position = UDim2.new(0, 48, 0, 28)
    sl.BackgroundTransparency = 1
    sl.Text = sub
    sl.TextColor3 = C.textMut
    sl.Font = Enum.Font.Gotham
    sl.TextSize = 10
    sl.TextXAlignment = Enum.TextXAlignment.Left
    sl.ZIndex = 4
    sl.TextTruncate = Enum.TextTruncate.AtEnd

    -- Toggle
    local togBg = Instance.new("Frame", row)
    togBg.Size = UDim2.new(0, 38, 0, 22)
    togBg.Position = UDim2.new(1, -50, 0.5, -11)
    togBg.BackgroundColor3 = Color3.fromRGB(40, 22, 70)
    togBg.BorderSizePixel = 0
    Instance.new("UICorner", togBg).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", togBg).Color = Color3.fromRGB(80, 55, 120)

    local knob = Instance.new("Frame", togBg)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(180, 155, 220)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local on = false
    local cz = Instance.new("TextButton", row)
    cz.Size = UDim2.new(1, 0, 1, 0)
    cz.BackgroundTransparency = 1
    cz.Text = ""
    cz.ZIndex = 5

    cz.MouseButton1Click:Connect(function()
        on = not on
        tween(togBg, {
            BackgroundColor3 = on and Color3.fromRGB(110, 55, 220) or Color3.fromRGB(40, 22, 70)
        }, 0.15)
        tween(knob, {
            BackgroundColor3 = on and C.white or Color3.fromRGB(180, 155, 220),
            Position = on and UDim2.new(0, 19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }, 0.15)
        tween(row, {
            BackgroundTransparency = on and (warn and 0.2 or 0.12) or (warn and 0.35 or 0.25)
        }, 0.15)
        rs.Color = (on and not warn) and C.purple or (warn and C.amber or Color3.fromRGB(60, 40, 90))
        rs.Transparency = on and 0.25 or 0.5
    end)

    return row, cz
end

local function glBtn(parent, label, r, g, b, w, cb, order)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(w or 1, 0, 0, 34)
    btn.ZIndex = 3
    btn.BackgroundColor3 = Color3.fromRGB(r, g, b)
    btn.BackgroundTransparency = 0.55
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(math.min(255, r + 80), math.min(255, g + 80), math.min(255, b + 80))
    btn.LayoutOrder = order or 99
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    local bs = Instance.new("UIStroke", btn)
    bs.Color = Color3.fromRGB(math.min(255, r + 40), math.min(255, g + 40), math.min(255, b + 40))
    bs.Transparency = 0.45
    btn.MouseButton1Click:Connect(cb)
    btn.MouseEnter:Connect(function() tween(btn, {BackgroundTransparency = 0.35}, 0.1) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundTransparency = 0.55}, 0.1) end)
    return btn
end

local function makeSlider(parent, label, minV, maxV, defV, onChange, order)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 48)
    row.ZIndex = 3
    row.BackgroundColor3 = C.card
    row.BackgroundTransparency = 0.3
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 10
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", row).Color = Color3.fromRGB(50, 35, 80)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6, 0, 0, 15)
    lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.textDim
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4

    local vLbl = Instance.new("TextLabel", row)
    vLbl.Size = UDim2.new(0.3, 0, 0, 15)
    vLbl.Position = UDim2.new(0.68, 0, 0, 6)
    vLbl.BackgroundTransparency = 1
    vLbl.Text = tostring(defV)
    vLbl.TextColor3 = C.purple
    vLbl.Font = Enum.Font.GothamBold
    vLbl.TextSize = 12
    vLbl.TextXAlignment = Enum.TextXAlignment.Right
    vLbl.ZIndex = 4

    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1, -24, 0, 5)
    track.Position = UDim2.new(0, 12, 0, 30)
    track.BackgroundColor3 = Color3.fromRGB(45, 28, 80)
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local pct = (defV - minV) / (maxV - minV)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = C.purple
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local kn = Instance.new("Frame", track)
    kn.Size = UDim2.new(0, 14, 0, 14)
    kn.Position = UDim2.new(pct, -7, 0.5, -7)
    kn.BackgroundColor3 = Color3.fromRGB(230, 215, 255)
    kn.BorderSizePixel = 0
    Instance.new("UICorner", kn).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local sbtn = Instance.new("TextButton", track)
    sbtn.Size = UDim2.new(1, 0, 0, 24)
    sbtn.Position = UDim2.new(0, 0, 0, -10)
    sbtn.BackgroundTransparency = 1
    sbtn.Text = ""
    sbtn.ZIndex = 5

    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(minV + rel * (maxV - minV))
        vLbl.Text = tostring(val)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        kn.Position = UDim2.new(rel, -7, 0.5, -7)
        onChange(val)
    end

    sbtn.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
    return row
end

local function makeInput(parent, ph, onChange, order)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.ZIndex = 3
    frame.BackgroundColor3 = C.card
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 10
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local fs = Instance.new("UIStroke", frame)
    fs.Color = Color3.fromRGB(55, 40, 90)
    fs.Transparency = 0.5

    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(1, -18, 1, 0)
    box.Position = UDim2.new(0, 10, 0, 0)
    box.BackgroundTransparency = 1
    box.PlaceholderText = ph
    box.PlaceholderColor3 = Color3.fromRGB(90, 65, 120)
    box.Text = ""
    box.TextColor3 = C.textBr
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ZIndex = 4
    if onChange then
        box.FocusLost:Connect(function() onChange(box.Text) end)
    end
    box.Focused:Connect(function()
        fs.Color = C.purple
        fs.Transparency = 0.3
    end)
    box.FocusLost:Connect(function()
        fs.Color = Color3.fromRGB(55, 40, 90)
        fs.Transparency = 0.5
    end)
    return frame, box
end

local function infoBox(parent, h, order)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, h or 64)
    f.ZIndex = 3
    f.BackgroundColor3 = C.card
    f.BackgroundTransparency = 0.3
    f.BorderSizePixel = 0
    f.LayoutOrder = order or 10
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", f).Color = Color3.fromRGB(50, 35, 80)
    return f
end

local function infoRow(parent, lbl, ypos)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(0.48, 0, 0, 14)
    l.Position = UDim2.new(0, 12, 0, ypos)
    l.BackgroundTransparency = 1
    l.Text = lbl
    l.TextColor3 = C.textMut
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 4

    local v = Instance.new("TextLabel", parent)
    v.Size = UDim2.new(0.42, 0, 0, 14)
    v.Position = UDim2.new(0.55, 0, 0, ypos)
    v.BackgroundTransparency = 1
    v.TextColor3 = C.textBr
    v.Font = Enum.Font.GothamBold
    v.TextSize = 11
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.ZIndex = 4
    return v
end

-- =============================================
-- TAB 1 — MOVE
-- =============================================
local p1 = newGridPanel()
table.insert(tabPanels, p1)

local _, flyC = toggleCard(p1, "Fly Mode", "WASD + Space / Shift", C.purple, false, 1)
flyC.MouseButton1Click:Connect(function()
    State.fly = not State.fly
    if State.fly then enableFly() else disableFly() end
end)

local _, jC = toggleCard(p1, "Infinity Jump", "Lompat tanpa batas", C.blue, false, 2)
jC.MouseButton1Click:Connect(function()
    State.infiniteJ = not State.infiniteJ
    if State.infiniteJ then enableInfJump() else disableInfJump() end
end)

local _, wC = toggleCard(p1, "Auto Walk", "Jalan otomatis maju", C.green, false, 3)
wC.MouseButton1Click:Connect(function()
    State.autoWalk = not State.autoWalk
    if State.autoWalk then
        State.playingRoute = false
        if PlayConn then PlayConn:Disconnect(); PlayConn = nil end
        enableAutoWalk()
    else
        disableAutoWalk()
    end
end)

local _, ncC = toggleCard(p1, "NoClip", "Tembus dinding", C.amber, false, 4)
ncC.MouseButton1Click:Connect(function()
    State.noclip = not State.noclip
    if State.noclip then enableNoclip() else disableNoclip() end
end)

-- Sliders container
local sh = Instance.new("Frame", p1)
sh.Size = UDim2.new(1, 0, 0, 220)
sh.BackgroundTransparency = 1
sh.LayoutOrder = 5
local shUl = Instance.new("UIListLayout", sh)
shUl.Padding = UDim.new(0, 6)
makeSlider(sh, "Fly Speed", 10, 200, 50, function(v) State.flySpeed = v end, 1)
makeSlider(sh, "Jump Power", 50, 500, 100, function(v)
    State.jumpPower = v
    pcall(function() Humanoid.JumpPower = v end)
end, 2)
makeSlider(sh, "Walk Speed", 8, 100, 16, function(v)
    State.walkSpeed = v
    if State.autoWalk or State.playingRoute then
        pcall(function() Humanoid.WalkSpeed = v end)
    end
end, 3)
makeSlider(sh, "Speed Hack", 8, 300, 16, function(v)
    pcall(function() Humanoid.WalkSpeed = v end)
end, 4)
shUl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sh.Size = UDim2.new(1, 0, 0, shUl.AbsoluteContentSize.Y + 4)
end)

-- =============================================
-- TAB 2 — VISUAL
-- =============================================
local p2 = newGridPanel()
table.insert(tabPanels, p2)

local _, espC = toggleCard(p2, "Player ESP", "Nametag player lain", C.blue, false, 1)
espC.MouseButton1Click:Connect(function()
    State.espEnabled = not State.espEnabled
    if State.espEnabled then enableEsp() else disableEsp() end
end)

local _, chC = toggleCard(p2, "Chams", "Highlight neon player", Color3.fromRGB(255, 80, 200), false, 2)
chC.MouseButton1Click:Connect(function()
    State.chams = not State.chams
    if State.chams then enableChams() else disableChams() end
end)

local _, gdC = toggleCard(p2, "God Mode", "HP tidak berkurang", C.green, false, 3)
gdC.MouseButton1Click:Connect(function()
    State.godMode = not State.godMode
    if State.godMode then enableGodMode() else disableGodMode() end
end)

local _, avC = toggleCard(p2, "Anti-Void", "Auto teleport saat jatuh", C.amber, false, 4)
avC.MouseButton1Click:Connect(function()
    State.antiVoid = not State.antiVoid
    if State.antiVoid then enableAntiVoid() else disableAntiVoid() end
end)

-- =============================================
-- TAB 3 — RECORD
-- =============================================
local p3 = newPanel()
table.insert(tabPanels, p3)
sectLbl(p3, "MAP INFO", 1)
local _, mapBox = makeInput(p3, "Nama map...", function(v)
    State.mapName = v ~= "" and v or "Unknown Map"
end, 2)
local _, obsBox = makeInput(p3, "Nama rintangan / obstacle...", function(v)
    State.obsName = v ~= "" and v or "Unknown Obstacle"
end, 3)

sectLbl(p3, "REKAMAN", 4)
local rib = infoBox(p3, 72, 5)
local recStat = infoRow(rib, "Status", 8)
local recWp   = infoRow(rib, "Waypoints", 26)
local recDur  = infoRow(rib, "Durasi", 44)
local recMap  = infoRow(rib, "Map", 58)
recStat.Text = "Idle"
recWp.Text = "0"
recDur.Text = "0s"
recMap.Text = "—"

RunService.Heartbeat:Connect(function()
    recWp.Text = tostring(#WaypointLog)
    if State.recording then
        recDur.Text = math.floor(tick() - RecordStart) .. "s"
        recStat.Text = "Recording"
        recStat.TextColor3 = C.green
    else
        recStat.TextColor3 = C.textBr
    end
end)

local rbH = Instance.new("Frame", p3)
rbH.Size = UDim2.new(1, 0, 0, 36)
rbH.BackgroundTransparency = 1
rbH.LayoutOrder = 6
local rbUl = Instance.new("UIListLayout", rbH)
rbUl.FillDirection = Enum.FillDirection.Horizontal
rbUl.Padding = UDim.new(0, 8)

local recBtn = glBtn(rbH, "Record", 180, 40, 40, 0.48, function()
    if not State.recording then
        startRecord()
        recBtn.Text = "Stop"
        recBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        recStat.Text = "Recording"
        recMap.Text = State.mapName
    else
        stopRecord()
        recBtn.Text = "Record"
        recBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        recStat.Text = "Stopped"
    end
end)

glBtn(rbH, "Save Route", 30, 140, 50, 0.48, function()
    saveRecord()
    recStat.Text = "Saved"
    recStat.TextColor3 = C.green
end)

local cpH = Instance.new("Frame", p3)
cpH.Size = UDim2.new(1, 0, 0, 36)
cpH.BackgroundTransparency = 1
cpH.LayoutOrder = 7
Instance.new("UIListLayout", cpH).FillDirection = Enum.FillDirection.Horizontal
glBtn(cpH, "Auto Detect Map Name", 70, 70, 170, 1, function()
    local n = copyMapName()
    mapBox.Text = n
end)

-- =============================================
-- TAB 4 — SAVES
-- =============================================
local p4 = newPanel()
table.insert(tabPanels, p4)

local emptyL = Instance.new("TextLabel", p4)
emptyL.Size = UDim2.new(1, 0, 0, 40)
emptyL.BackgroundTransparency = 1
emptyL.Text = "Belum ada route tersimpan"
emptyL.TextColor3 = Color3.fromRGB(80, 55, 110)
emptyL.Font = Enum.Font.Gotham
emptyL.TextSize = 12
emptyL.ZIndex = 3
emptyL.LayoutOrder = 1

local saveCards = {}
local function refreshSaves()
    for _, c in ipairs(saveCards) do c:Destroy() end
    saveCards = {}
    emptyL.Visible = (#SavedRoutes == 0)

    for i, route in ipairs(SavedRoutes) do
        local card = Instance.new("Frame", p4)
        card.Size = UDim2.new(1, 0, 0, 68)
        card.ZIndex = 3
        card.LayoutOrder = i + 1
        card.BackgroundColor3 = C.card
        card.BackgroundTransparency = 0.25
        card.BorderSizePixel = 0
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
        Instance.new("UIStroke", card).Color = Color3.fromRGB(55, 40, 90)

        local ml = Instance.new("TextLabel", card)
        ml.Size = UDim2.new(0.7, 0, 0, 16)
        ml.Position = UDim2.new(0, 12, 0, 8)
        ml.BackgroundTransparency = 1
        ml.Text = route.mapName
        ml.TextColor3 = C.textBr
        ml.Font = Enum.Font.GothamBold
        ml.TextSize = 12
        ml.TextXAlignment = Enum.TextXAlignment.Left
        ml.ZIndex = 4
        ml.TextTruncate = Enum.TextTruncate.AtEnd

        local ol = Instance.new("TextLabel", card)
        ol.Size = UDim2.new(0.7, 0, 0, 13)
        ol.Position = UDim2.new(0, 12, 0, 26)
        ol.BackgroundTransparency = 1
        ol.Text = route.obsName
        ol.TextColor3 = C.purple
        ol.Font = Enum.Font.Gotham
        ol.TextSize = 10
        ol.TextXAlignment = Enum.TextXAlignment.Left
        ol.ZIndex = 4

        local meta = Instance.new("TextLabel", card)
        meta.Size = UDim2.new(0.7, 0, 0, 12)
        meta.Position = UDim2.new(0, 12, 0, 44)
        meta.BackgroundTransparency = 1
        meta.Text = #route.waypoints .. " pts  ·  " .. route.duration .. "s"
        meta.TextColor3 = C.textMut
        meta.Font = Enum.Font.Gotham
        meta.TextSize = 10
        meta.TextXAlignment = Enum.TextXAlignment.Left
        meta.ZIndex = 4

        -- Play button
        local playB = Instance.new("TextButton", card)
        playB.Size = UDim2.new(0, 52, 0, 26)
        playB.Position = UDim2.new(1, -100, 0.5, -13)
        playB.BackgroundColor3 = C.green
        playB.BackgroundTransparency = 0.55
        playB.Text = "Play"
        playB.TextColor3 = Color3.fromRGB(180, 255, 200)
        playB.Font = Enum.Font.GothamBold
        playB.TextSize = 11
        playB.BorderSizePixel = 0
        playB.ZIndex = 5
        Instance.new("UICorner", playB).CornerRadius = UDim.new(0, 7)
        playB.MouseButton1Click:Connect(function()
            playRoute(route)
        end)

        -- Delete
        local db = Instance.new("TextButton", card)
        db.Size = UDim2.new(0, 28, 0, 26)
        db.Position = UDim2.new(1, -40, 0.5, -13)
        db.BackgroundColor3 = C.red
        db.BackgroundTransparency = 0.55
        db.Text = "X"
        db.TextColor3 = Color3.fromRGB(255, 180, 180)
        db.Font = Enum.Font.GothamBold
        db.TextSize = 12
        db.BorderSizePixel = 0
        db.ZIndex = 5
        Instance.new("UICorner", db).CornerRadius = UDim.new(0, 7)
        db.MouseButton1Click:Connect(function()
            table.remove(SavedRoutes, i)
            refreshSaves()
            notify("Deleted", "Route dihapus", 1.5)
        end)

        table.insert(saveCards, card)
    end
end

tabBtns[4].MouseButton1Click:Connect(function()
    task.defer(refreshSaves)
end)

-- =============================================
-- TAB 5 — UTIL
-- =============================================
local p5 = newPanel()
table.insert(tabPanels, p5)
sectLbl(p5, "TELEPORT", 1)
local _, tpBox = makeInput(p5, "Nama player...", nil, 2)
local tpH = Instance.new("Frame", p5)
tpH.Size = UDim2.new(1, 0, 0, 36)
tpH.BackgroundTransparency = 1
tpH.LayoutOrder = 3
local tpUl = Instance.new("UIListLayout", tpH)
tpUl.FillDirection = Enum.FillDirection.Horizontal
tpUl.Padding = UDim.new(0, 8)
glBtn(tpH, "Teleport ke Player", 90, 55, 220, 1, function()
    teleportToPlayer(tpBox.Text)
end)

sectLbl(p5, "SERVER", 4)
local srvH = Instance.new("Frame", p5)
srvH.Size = UDim2.new(1, 0, 0, 36)
srvH.BackgroundTransparency = 1
srvH.LayoutOrder = 5
local srvUl = Instance.new("UIListLayout", srvH)
srvUl.FillDirection = Enum.FillDirection.Horizontal
srvUl.Padding = UDim.new(0, 8)
glBtn(srvH, "Rejoin", 50, 110, 200, 0.48, function() rejoin() end)
glBtn(srvH, "Copy Map Name", 60, 160, 100, 0.48, function() copyMapName() end)

-- =============================================
-- TAB 6 — PERF
-- =============================================
local p6 = newPanel()
table.insert(tabPanels, p6)
sectLbl(p6, "PERFORMANCE", 1)
local _, lagC = toggleCard(p6, "Potato Mode", "Anti Lag — grafik minimal", C.amber, true, 2)
lagC.MouseButton1Click:Connect(function()
    State.antiLag = not State.antiLag
    if State.antiLag then enablePotato() else disablePotato() end
end)

local pfH = Instance.new("Frame", p6)
pfH.Size = UDim2.new(1, 0, 0, 36)
pfH.BackgroundTransparency = 1
pfH.LayoutOrder = 4
local pfUl = Instance.new("UIListLayout", pfH)
pfUl.FillDirection = Enum.FillDirection.Horizontal
pfUl.Padding = UDim.new(0, 8)
glBtn(pfH, "Kill All Features", 190, 40, 40, 0.48, function() killAll() end)
glBtn(pfH, "Minimize", 160, 160, 180, 0.48, function() hideMain() end)

-- =============================================
-- TAB 7 — PLAYERS
-- =============================================
local p7 = newPanel()
table.insert(tabPanels, p7)
sectLbl(p7, "SERVER PLAYERS", 1)
local plrBox = infoBox(p7, 290, 2)
plrBox.Size = UDim2.new(1, 0, 0, 290)

local plrScroll = Instance.new("ScrollingFrame", plrBox)
plrScroll.Size = UDim2.new(1, -6, 1, -6)
plrScroll.Position = UDim2.new(0, 3, 0, 3)
plrScroll.BackgroundTransparency = 1
plrScroll.BorderSizePixel = 0
plrScroll.ScrollBarThickness = 3
plrScroll.ScrollBarImageColor3 = C.purple
plrScroll.ZIndex = 5
local plrUl = Instance.new("UIListLayout", plrScroll)
plrUl.Padding = UDim.new(0, 4)
plrUl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    plrScroll.CanvasSize = UDim2.new(0, 0, 0, plrUl.AbsoluteContentSize.Y + 8)
end)

glBtn(p7, "Refresh Player List", 80, 90, 200, 1, function()
    for _, c in ipairs(plrScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        local row = Instance.new("Frame", plrScroll)
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = C.card
        row.BackgroundTransparency = 0.3
        row.BorderSizePixel = 0
        row.ZIndex = 6
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local dot = Instance.new("Frame", row)
        dot.Size = UDim2.new(0, 8, 0, 8)
        dot.Position = UDim2.new(0, 10, 0.5, -4)
        dot.BackgroundColor3 = plr == Player and C.green or C.purple
        dot.BorderSizePixel = 0
        dot.ZIndex = 7
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local namL = Instance.new("TextLabel", row)
        namL.Size = UDim2.new(0.65, 0, 1, 0)
        namL.Position = UDim2.new(0, 26, 0, 0)
        namL.BackgroundTransparency = 1
        namL.Text = plr.Name .. (plr == Player and " (you)" or "")
        namL.TextColor3 = plr == Player and C.green or C.textBr
        namL.Font = Enum.Font.GothamBold
        namL.TextSize = 11
        namL.TextXAlignment = Enum.TextXAlignment.Left
        namL.ZIndex = 7

        local pingL = Instance.new("TextLabel", row)
        pingL.Size = UDim2.new(0.25, 0, 1, 0)
        pingL.Position = UDim2.new(0.72, 0, 0, 0)
        pingL.BackgroundTransparency = 1
        local ok, vis = Enum.TextXAlignment.Right
        local ok2, ping = pcall(function() return math.floor(plr:GetNetworkPing() * 1000) end)
        pingL.Text = ok2 and (ping .. "ms") or "—"
        pingL.TextColor3 = C.textMut
        pingL.Font = Enum.Font.Gotham
        pingL.TextSize = 10
        pingL.TextXAlignment = Enum.TextXAlignment.Right
        pingL.ZIndex = 7
    end
end, 3)

-- =============================================
-- TAB 8 — ANS (FIXED)
-- =============================================
local p8 = newPanel()
table.insert(tabPanels, p8)
sectLbl(p8, "ABDI NEGARA SIMULATOR", 1)

local ansIB = infoBox(p8, 78, 2)
local ans1 = infoRow(ansIB, "Push Up", 8)
local ans2 = infoRow(ansIB, "Sit Up", 26)
local ans3 = infoRow(ansIB, "JJS", 44)
local ans4 = infoRow(ansIB, "Pull Up", 62)
ans1.Text = "0 | Idle"
ans2.Text = "0 | Idle"
ans3.Text = "0 | Idle"
ans4.Text = "0 | Idle"

RunService.Heartbeat:Connect(function()
    local function fmt(key, lbl)
        local running = ANS.running[key]
        lbl.Text = ANS.count[key] .. " | " .. (running and "ON" or "Idle")
        lbl.TextColor3 = running and C.green or C.textBr
    end
    fmt("pushup", ans1)
    fmt("situp", ans2)
    fmt("jjs", ans3)
    fmt("pullup", ans4)
end)

sectLbl(p8, "KONTROL LATIHAN", 3)

local _, puC = toggleCard(p8, "Auto Push Up", "Loop push up otomatis", C.purple, false, 4)
puC.MouseButton1Click:Connect(function()
    if ANS.running.pushup then
        stopExercise("pushup")
    else
        startExercise("pushup")
    end
end)

local _, suC = toggleCard(p8, "Auto Sit Up", "Loop sit up otomatis", C.blue, false, 5)
suC.MouseButton1Click:Connect(function()
    if ANS.running.situp then
        stopExercise("situp")
    else
        startExercise("situp")
    end
end)

local _, jjsC = toggleCard(p8, "Auto JJS", "Jumping Jacks otomatis", C.green, false, 6)
jjsC.MouseButton1Click:Connect(function()
    if ANS.running.jjs then
        stopExercise("jjs")
    else
        startExercise("jjs")
    end
end)

local _, puulC = toggleCard(p8, "Auto Pull Up", "Pull up otomatis", Color3.fromRGB(255, 130, 80), false, 7)
puulC.MouseButton1Click:Connect(function()
    if ANS.running.pullup then
        stopExercise("pullup")
    else
        startExercise("pullup")
    end
end)

-- ===== SETTING INTERVAL =====
sectLbl(p8, "SETTING NEEDLE / INTERVAL", 8)

-- Card info needle
local needleInfoBox = infoBox(p8, 50, 9)
local needleStatL = Instance.new("TextLabel", needleInfoBox)
needleStatL.Size = UDim2.new(1,-16,1,-16)
needleStatL.Position = UDim2.new(0,8,0,8)
needleStatL.BackgroundTransparency = 1
needleStatL.Text = "Mode: Needle Auto | Interval: 0.10s | Jeda antar rep"
needleStatL.TextColor3 = Color3.fromRGB(100,220,140)
needleStatL.Font = Enum.Font.Gotham
needleStatL.TextSize = 9
needleStatL.TextWrapped = true
needleStatL.TextXAlignment = Enum.TextXAlignment.Left
needleStatL.ZIndex = 4

local function updateNeedleStat()
    local mode = ANS.useNeedle and "Needle Auto" or "Interval Tetap"
    needleStatL.Text = "Mode: "..mode.." | Jeda: "..string.format("%.2f",ANS.interval).."s"
    needleStatL.TextColor3 = ANS.useNeedle
        and Color3.fromRGB(80,220,120)
        or Color3.fromRGB(255,185,55)
end

-- Toggle mode needle vs interval
local _, needleTogC = toggleCard(p8, "Needle Detection", "Auto deteksi area hijau", C.green, false, 10)
needleTogC.MouseButton1Click:Connect(function()
    ANS.useNeedle = not ANS.useNeedle
    updateNeedleStat()
    notify("ANS", "Mode: "..(ANS.useNeedle and "Needle Auto" or "Interval Tetap"), 2)
end)

-- Tombol pilih interval cepat
local intH = Instance.new("Frame", p8)
intH.Size = UDim2.new(1, 0, 0, 36)
intH.BackgroundTransparency = 1
intH.LayoutOrder = 11
local intUl = Instance.new("UIListLayout", intH)
intUl.FillDirection = Enum.FillDirection.Horizontal
intUl.Padding = UDim.new(0, 4)
intUl.HorizontalAlignment = Enum.HorizontalAlignment.Left

local function makeIntervalBtn(label, val, r, g, b)
    local btn = Instance.new("TextButton", intH)
    btn.Size = UDim2.new(0, 68, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(r,g,b)
    btn.BackgroundTransparency = 0.55
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = Color3.fromRGB(math.min(255,r+100),math.min(255,g+100),math.min(255,b+100))
    btn.ZIndex = 3
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(function()
        ANS.interval = val
        updateNeedleStat()
        notify("ANS", "Interval: "..val.."s", 1.5)
    end)
end
makeIntervalBtn("0.10s", 0.10, 50, 180, 80)
makeIntervalBtn("0.30s", 0.30, 60, 140, 200)
makeIntervalBtn("0.50s", 0.50, 100, 80, 220)
makeIntervalBtn("1.00s", 1.00, 180, 120, 60)

-- Jump threshold (pakai infoBox + 2 tombol, bukan slider supaya tidak crash di list panel)
sectLbl(p8, "AUTO JUMP THRESHOLD (ROUTE)", 12)
local jtH = Instance.new("Frame", p8)
jtH.Size = UDim2.new(1, 0, 0, 36)
jtH.BackgroundTransparency = 1
jtH.LayoutOrder = 13
local jtUl = Instance.new("UIListLayout", jtH)
jtUl.FillDirection = Enum.FillDirection.Horizontal
jtUl.Padding = UDim.new(0, 4)

local jtValLbl = Instance.new("TextLabel", jtH)
jtValLbl.Size = UDim2.new(0, 120, 0, 30)
jtValLbl.BackgroundColor3 = Color3.fromRGB(20,10,40)
jtValLbl.BackgroundTransparency = 0.4
jtValLbl.BorderSizePixel = 0
jtValLbl.Text = "Min Y-diff: "..JUMP_HEIGHT_THRESHOLD
jtValLbl.TextColor3 = Color3.fromRGB(160,100,255)
jtValLbl.Font = Enum.Font.GothamBold
jtValLbl.TextSize = 10
jtValLbl.ZIndex = 3
Instance.new("UICorner", jtValLbl).CornerRadius = UDim.new(0, 8)

local function jtBtn(lbl, r, g, b, cb)
    local b2 = Instance.new("TextButton", jtH)
    b2.Size = UDim2.new(0, 50, 0, 30)
    b2.BackgroundColor3 = Color3.fromRGB(r,g,b)
    b2.BackgroundTransparency = 0.55
    b2.BorderSizePixel = 0
    b2.Text = lbl
    b2.Font = Enum.Font.GothamBold
    b2.TextSize = 11
    b2.TextColor3 = Color3.fromRGB(220,220,220)
    b2.ZIndex = 3
    Instance.new("UICorner", b2).CornerRadius = UDim.new(0, 8)
    b2.MouseButton1Click:Connect(cb)
end
jtBtn("- 0.5", 200, 60, 60, function()
    JUMP_HEIGHT_THRESHOLD = math.max(1, JUMP_HEIGHT_THRESHOLD - 0.5)
    jtValLbl.Text = "Min Y-diff: "..string.format("%.1f", JUMP_HEIGHT_THRESHOLD)
end)
jtBtn("+ 0.5", 60, 180, 80, function()
    JUMP_HEIGHT_THRESHOLD = math.min(15, JUMP_HEIGHT_THRESHOLD + 0.5)
    jtValLbl.Text = "Min Y-diff: "..string.format("%.1f", JUMP_HEIGHT_THRESHOLD)
end)

sectLbl(p8, "SHORTCUT", 14)
local allH = Instance.new("Frame", p8)
allH.Size = UDim2.new(1, 0, 0, 36)
allH.BackgroundTransparency = 1
allH.LayoutOrder = 15
Instance.new("UIListLayout", allH).FillDirection = Enum.FillDirection.Horizontal

local allOn = false
local allBtn = glBtn(allH, "Auto ALL Exercise", 110, 55, 220, 0.62, function()
    allOn = not allOn
    if allOn then
        allBtn.Text = "Stop ALL"
        allBtn.BackgroundColor3 = Color3.fromRGB(190, 40, 40)
        task.wait(0.1); startExercise("pushup")
        task.wait(0.1); startExercise("situp")
        task.wait(0.1); startExercise("jjs")
        task.wait(0.1); startExercise("pullup")
        notify("ANS", "Auto ALL aktif ("
            ..(ANS.useNeedle and "Needle" or "Interval "..ANS.interval.."s")..")", 2.5)
    else
        allBtn.Text = "Auto ALL Exercise"
        allBtn.BackgroundColor3 = Color3.fromRGB(110, 55, 220)
        stopAllExercises()
        notify("ANS", "Semua dihentikan", 2)
    end
end)

local _, afkC = toggleCard(p8, "Anti AFK", "Cegah kick karena idle", C.amber, false, 16)
afkC.MouseButton1Click:Connect(function()
    ANS.antiAfk = not ANS.antiAfk
    if ANS.antiAfk then
        notify("Anti AFK", "Aktif", 2)
        task.spawn(function()
            while ANS.antiAfk do
                pcall(function()
                    if Humanoid then
                        Humanoid:Move(Vector3.new(0.05, 0, 0), false)
                        task.wait(0.15)
                        Humanoid:Move(Vector3.zero, false)
                    end
                end)
                task.wait(50)
                if ANS.antiAfk and Humanoid then
                    pcall(function()
                        Humanoid.Jump = true
                        task.wait(0.25)
                        Humanoid.Jump = false
                    end)
                end
            end
        end)
    else
        notify("Anti AFK", "Nonaktif", 1.5)
    end
end)

local rstH = Instance.new("Frame", p8)
rstH.Size = UDim2.new(1, 0, 0, 36)
rstH.BackgroundTransparency = 1
rstH.LayoutOrder = 17
Instance.new("UIListLayout", rstH).FillDirection = Enum.FillDirection.Horizontal
glBtn(rstH, "Reset Counter", 90, 90, 90, 1, function()
    ANS.count = {pushup = 0, situp = 0, jjs = 0, pullup = 0}
    notify("ANS", "Counter direset", 1.5)
end)

-- =============================================
-- STATUS BAR
-- =============================================
local sBar = Instance.new("Frame", main)
sBar.Size = UDim2.new(1, 0, 0, 24)
sBar.Position = UDim2.new(0, 0, 1, -24)
sBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
sBar.BackgroundTransparency = 0.4
sBar.BorderSizePixel = 0
sBar.ZIndex = 2
Instance.new("UICorner", sBar).CornerRadius = UDim.new(0, 18)

local sDot = Instance.new("Frame", sBar)
sDot.Size = UDim2.new(0, 7, 0, 7)
sDot.Position = UDim2.new(0, 12, 0.5, -3.5)
sDot.BackgroundColor3 = C.green
sDot.BorderSizePixel = 0
Instance.new("UICorner", sDot).CornerRadius = UDim.new(1, 0)
TweenService:Create(sDot, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    BackgroundTransparency = 0.65
}):Play()

local sTxt = Instance.new("TextLabel", sBar)
sTxt.Size = UDim2.new(0.35, 0, 1, 0)
sTxt.Position = UDim2.new(0, 24, 0, 0)
sTxt.BackgroundTransparency = 1
sTxt.Text = "ATTACHED"
sTxt.TextColor3 = Color3.fromRGB(90, 70, 120)
sTxt.Font = Enum.Font.Gotham
sTxt.TextSize = 10
sTxt.TextXAlignment = Enum.TextXAlignment.Left
sTxt.ZIndex = 3

local sInfo = Instance.new("TextLabel", sBar)
sInfo.Size = UDim2.new(0.3, 0, 1, 0)
sInfo.Position = UDim2.new(0.35, 0, 0, 0)
sInfo.BackgroundTransparency = 1
sInfo.Text = "#players: " .. #Players:GetPlayers()
sInfo.TextColor3 = Color3.fromRGB(90, 70, 120)
sInfo.Font = Enum.Font.Gotham
sInfo.TextSize = 10
sInfo.TextXAlignment = Enum.TextXAlignment.Center
sInfo.ZIndex = 3

local sTime = Instance.new("TextLabel", sBar)
sTime.Size = UDim2.new(0.28, -10, 1, 0)
sTime.Position = UDim2.new(0.72, 0, 0, 0)
sTime.BackgroundTransparency = 1
sTime.TextColor3 = Color3.fromRGB(90, 70, 120)
sTime.Font = Enum.Font.Gotham
sTime.TextSize = 10
sTime.TextXAlignment = Enum.TextXAlignment.Right
sTime.ZIndex = 3

RunService.Heartbeat:Connect(function()
    pcall(function()
        local t = os.time()
        local h = math.floor(t / 3600) % 24
        local m = math.floor(t / 60) % 60
        local s = t % 60
        sTime.Text = string.format("%02d:%02d:%02d", h, m, s)
    end)
    sInfo.Text = "#players: " .. #Players:GetPlayers()
end)

-- =============================================
-- MINI BAR
-- =============================================
miniBar = Instance.new("Frame", gui)
miniBar.Name = "therX_MiniBar"
miniBar.Size = UDim2.new(0, 190, 0, 40)
miniBar.AnchorPoint = Vector2.new(0, 1)
miniBar.Position = UDim2.new(0, 20, 1, -20)
miniBar.BackgroundColor3 = C.bg
miniBar.BackgroundTransparency = 0.12
miniBar.BorderSizePixel = 0
miniBar.Active = true
miniBar.Draggable = true
miniBar.Visible = false
miniBar.ZIndex = 10
Instance.new("UICorner", miniBar).CornerRadius = UDim.new(0, 20)
local mbs = Instance.new("UIStroke", miniBar)
mbs.Color = C.purple
mbs.Transparency = 0.35
mbs.Thickness = 1.2

local mLogo = Instance.new("Frame", miniBar)
mLogo.Size = UDim2.new(0, 26, 0, 26)
mLogo.Position = UDim2.new(0, 10, 0.5, -13)
mLogo.BackgroundTransparency = 1
mLogo.ZIndex = 11
hex(mLogo, 13, 13, 12, C.purple, 0.55)
hex(mLogo, 13, 13, 7, C.blue, 0.45)

local mTitle = Instance.new("TextLabel", miniBar)
mTitle.Size = UDim2.new(0, 55, 0, 18)
mTitle.Position = UDim2.new(0, 42, 0.5, -9)
mTitle.BackgroundTransparency = 1
mTitle.Text = "therX"
mTitle.TextColor3 = C.textBr
mTitle.Font = Enum.Font.GothamBold
mTitle.TextSize = 14
mTitle.TextXAlignment = Enum.TextXAlignment.Left
mTitle.ZIndex = 11

local mFps = Instance.new("TextLabel", miniBar)
mFps.Size = UDim2.new(0, 48, 1, 0)
mFps.Position = UDim2.new(0, 100, 0, 0)
mFps.BackgroundTransparency = 1
mFps.Text = "-- fps"
mFps.TextColor3 = C.green
mFps.Font = Enum.Font.Gotham
mFps.TextSize = 10
mFps.TextXAlignment = Enum.TextXAlignment.Center
mFps.ZIndex = 11

RunService.Heartbeat:Connect(function()
    local t = fpsPingLabel.Text
    local fps = t:match("FPS: (%d+)")
    if fps then mFps.Text = fps .. " fps" end
end)

local mBtn = Instance.new("TextButton", miniBar)
mBtn.Size = UDim2.new(0, 30, 0, 30)
mBtn.Position = UDim2.new(1, -36, 0.5, -15)
mBtn.BackgroundColor3 = C.purple
mBtn.BackgroundTransparency = 0.45
mBtn.BorderSizePixel = 0
mBtn.Text = "^"
mBtn.TextColor3 = C.textBr
mBtn.Font = Enum.Font.GothamBold
mBtn.TextSize = 14
mBtn.ZIndex = 12
Instance.new("UICorner", mBtn).CornerRadius = UDim.new(0, 8)
mBtn.MouseButton1Click:Connect(function()
    miniBar.Visible = false
    main.Size = UDim2.new(0, 640, 0, 0)
    main.BackgroundTransparency = 1
    main.Visible = true
    tween(main, {Size = UDim2.new(0, 640, 0, 420), BackgroundTransparency = 0.06}, 0.25)
end)

local mDot = Instance.new("Frame", miniBar)
mDot.Size = UDim2.new(0, 6, 0, 6)
mDot.Position = UDim2.new(0, 95, 0.5, -3)
mDot.BackgroundColor3 = C.green
mDot.BorderSizePixel = 0
mDot.ZIndex = 11
Instance.new("UICorner", mDot).CornerRadius = UDim.new(1, 0)
TweenService:Create(mDot, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    BackgroundTransparency = 0.7
}):Play()

-- =============================================
-- ACTIVATE
-- =============================================
setTab(1)
p1.Visible = true
notify("therX v0.1.1", "by AxzZz — Loaded successfully", 3.5)

end) -- end pcall

if not ok then
    warn("[therX ERROR] " .. tostring(err))
    pcall(function()
        local sg = Instance.new("ScreenGui", game:GetService("CoreGui"))
        sg.Name = "therX_Error"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 99999
        local f = Instance.new("Frame", sg)
        f.Size = UDim2.new(0.9, 0, 0, 140)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.new(0.5, 0, 0.5, 0)
        f.BackgroundColor3 = Color3.fromRGB(25, 5, 5)
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
        local t = Instance.new("TextLabel", f)
        t.Size = UDim2.new(1, -20, 1, -20)
        t.Position = UDim2.new(0, 10, 0, 10)
        t.BackgroundTransparency = 1
        t.Text = "therX ERROR:\n" .. tostring(err)
        t.TextColor3 = Color3.fromRGB(255, 120, 120)
        t.Font = Enum.Font.Gotham
        t.TextSize = 12
        t.TextWrapped = true
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextYAlignment = Enum.TextYAlignment.Top
        task.delay(12, function() sg:Destroy() end)
    end)
end
