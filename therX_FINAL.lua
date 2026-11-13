-- therX v0.1.0 by AxzZz
-- Delta-compatible fix: CoreGui + full pcall wrap

local ok, err = pcall(function()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui", 10)
-- Delta: pakai CoreGui sebagai fallback agar GUI pasti muncul
local GuiParent = pcall(function() return game:GetService("CoreGui") end) 
    and game:GetService("CoreGui") or PlayerGui

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
    espEnabled=false, chams=false,
    flySpeed=50, jumpPower=100, walkSpeed=16,
    mapName="Unknown Map", obsName="Unknown Obstacle",
}
local SavedRoutes={} local WaypointLog={} local RecordStart=0
local RecordConn,AutoWalkConn,FlyConn,JumpConn,NoclipConn,AntiVoidConn,GodConn
local EspObjects={} local ChamsObjects={} local BodyVel,BodyGyro
local OrigSettings={}

-- =============================================
-- UTILITY
-- =============================================
local function tween(obj,props,t)
    pcall(function()
        TweenService:Create(obj,TweenInfo.new(t or 0.2,Enum.EasingStyle.Quad),props):Play()
    end)
end

local function notify(title,msg,dur)
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "therXN_"..math.random(1000,9999)
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 9999
        sg.Parent = GuiParent
        local f = Instance.new("Frame",sg)
        f.Size=UDim2.new(0,265,0,54)
        f.Position=UDim2.new(1,10,0,18)
        f.BackgroundColor3=Color3.fromRGB(14,7,28)
        f.BackgroundTransparency=0.05
        f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,12)
        local fs=Instance.new("UIStroke",f)
        fs.Color=Color3.fromRGB(160,100,255);fs.Transparency=0.45
        local t1=Instance.new("TextLabel",f)
        t1.Size=UDim2.new(1,-16,0,18);t1.Position=UDim2.new(0,12,0,8)
        t1.BackgroundTransparency=1;t1.Text=title
        t1.TextColor3=Color3.fromRGB(220,200,255);t1.Font=Enum.Font.GothamBold;t1.TextSize=11
        t1.TextXAlignment=Enum.TextXAlignment.Left
        local t2=Instance.new("TextLabel",f)
        t2.Size=UDim2.new(1,-16,0,14);t2.Position=UDim2.new(0,12,0,28)
        t2.BackgroundTransparency=1;t2.Text=msg
        t2.TextColor3=Color3.fromRGB(130,95,175);t2.Font=Enum.Font.Gotham;t2.TextSize=9
        t2.TextXAlignment=Enum.TextXAlignment.Left
        tween(f,{Position=UDim2.new(1,-280,0,18)},0.3)
        task.delay(dur or 2.5,function()
            tween(f,{Position=UDim2.new(1,10,0,18)},0.2)
            task.delay(0.25,function() pcall(function() sg:Destroy() end) end)
        end)
    end)
end

-- =============================================
-- FEATURES
-- =============================================
local function enableFly()
    pcall(function()
        if BodyVel then BodyVel:Destroy() end
        if BodyGyro then BodyGyro:Destroy() end
        BodyVel=Instance.new("BodyVelocity",HRP)
        BodyVel.Velocity=Vector3.zero;BodyVel.MaxForce=Vector3.new(1e5,1e5,1e5)
        BodyGyro=Instance.new("BodyGyro",HRP)
        BodyGyro.MaxTorque=Vector3.new(1e5,1e5,1e5);BodyGyro.P=1e4
        if FlyConn then FlyConn:Disconnect() end
        FlyConn=RunService.Heartbeat:Connect(function()
            if not State.fly then return end
            local d=Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then d+=Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then d-=Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then d-=Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then d+=Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d+=Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d-=Vector3.new(0,1,0) end
            BodyVel.Velocity=d.Magnitude>0 and d.Unit*State.flySpeed or Vector3.zero
            BodyGyro.CFrame=Camera.CFrame
        end)
        Humanoid.PlatformStand=true
    end)
    notify("Fly","Aktif — WASD+Space",2)
end
local function disableFly()
    pcall(function()
        if FlyConn then FlyConn:Disconnect();FlyConn=nil end
        if BodyVel then BodyVel:Destroy();BodyVel=nil end
        if BodyGyro then BodyGyro:Destroy();BodyGyro=nil end
        Humanoid.PlatformStand=false
    end)
    notify("Fly","Nonaktif",1.5)
end

local function enableInfJump()
    JumpConn=UserInputService.JumpRequest:Connect(function()
        if State.infiniteJ then
            Humanoid.JumpPower=State.jumpPower
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    notify("Infinity Jump","Aktif",2)
end
local function disableInfJump()
    if JumpConn then JumpConn:Disconnect();JumpConn=nil end
    notify("Infinity Jump","Nonaktif",1.5)
end

local function enableAutoWalk()
    AutoWalkConn=RunService.Heartbeat:Connect(function()
        if State.autoWalk then Humanoid:Move(Vector3.new(0,0,-1),false) end
    end)
    notify("Auto Walk","Aktif",2)
end
local function disableAutoWalk()
    if AutoWalkConn then AutoWalkConn:Disconnect();AutoWalkConn=nil end
    Humanoid.WalkSpeed=16
    notify("Auto Walk","Nonaktif",1.5)
end

local function enableNoclip()
    NoclipConn=RunService.Stepped:Connect(function()
        if not State.noclip then return end
        for _,p in ipairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide=false end) end
        end
    end)
    notify("NoClip","Aktif",2)
end
local function disableNoclip()
    if NoclipConn then NoclipConn:Disconnect();NoclipConn=nil end
    notify("NoClip","Nonaktif",1.5)
end

local function enableGodMode()
    pcall(function() Humanoid.MaxHealth=math.huge;Humanoid.Health=math.huge end)
    GodConn=RunService.Heartbeat:Connect(function()
        if State.godMode then pcall(function() Humanoid.Health=Humanoid.MaxHealth end) end
    end)
    notify("God Mode","Aktif — HP ∞",2)
end
local function disableGodMode()
    if GodConn then GodConn:Disconnect();GodConn=nil end
    pcall(function() Humanoid.MaxHealth=100;Humanoid.Health=100 end)
    notify("God Mode","Nonaktif",1.5)
end

local lastSafe=HRP.Position
local function enableAntiVoid()
    AntiVoidConn=RunService.Heartbeat:Connect(function()
        if not State.antiVoid then return end
        pcall(function()
            if HRP.Position.Y>-50 then lastSafe=HRP.Position
            else HRP.CFrame=CFrame.new(lastSafe+Vector3.new(0,5,0)) end
        end)
    end)
    notify("Anti-Void","Aktif",2)
end
local function disableAntiVoid()
    if AntiVoidConn then AntiVoidConn:Disconnect();AntiVoidConn=nil end
    notify("Anti-Void","Nonaktif",1.5)
end

local function teleportToPlayer(name)
    local t=Players:FindFirstChild(name)
    if t and t.Character then
        local th=t.Character:FindFirstChild("HumanoidRootPart")
        if th then HRP.CFrame=th.CFrame+Vector3.new(2,0,2);notify("Teleport","→ "..name,2) end
    else notify("Teleport","Tidak ditemukan: "..name,2) end
end

-- ESP
local EspConn
local function clearEsp()
    for _,o in pairs(EspObjects) do pcall(function() o:Destroy() end) end
    EspObjects={}
end
local function enableEsp()
    if EspConn then EspConn:Disconnect() end
    EspConn=RunService.Heartbeat:Connect(function()
        if not State.espEnabled then return end
        clearEsp()
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=Player and plr.Character then
                local head=plr.Character:FindFirstChild("Head")
                if head then
                    pcall(function()
                        local bb=Instance.new("BillboardGui",head)
                        bb.Size=UDim2.new(0,80,0,26);bb.StudsOffset=Vector3.new(0,2.5,0);bb.AlwaysOnTop=true
                        local nl=Instance.new("TextLabel",bb)
                        nl.Size=UDim2.new(1,0,1,0);nl.BackgroundTransparency=0.3
                        nl.BackgroundColor3=Color3.fromRGB(14,7,28);nl.Text=plr.Name
                        nl.TextColor3=Color3.fromRGB(160,100,255);nl.Font=Enum.Font.GothamBold
                        nl.TextSize=11;nl.BorderSizePixel=0
                        Instance.new("UICorner",nl).CornerRadius=UDim.new(0,6)
                        table.insert(EspObjects,bb)
                    end)
                end
            end
        end
    end)
    notify("ESP","Aktif",2)
end
local function disableEsp()
    if EspConn then EspConn:Disconnect();EspConn=nil end
    clearEsp();notify("ESP","Nonaktif",1.5)
end

-- Chams
local ChamsConn
local function clearChams()
    for part,orig in pairs(ChamsObjects) do
        pcall(function() part.Color=orig.c;part.Material=orig.m end)
    end
    ChamsObjects={}
end
local function enableChams()
    if ChamsConn then ChamsConn:Disconnect() end
    ChamsConn=RunService.Heartbeat:Connect(function()
        if not State.chams then return end
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=Player and plr.Character then
                for _,part in ipairs(plr.Character:GetDescendants()) do
                    if part:IsA("BasePart") and not ChamsObjects[part] then
                        pcall(function()
                            ChamsObjects[part]={c=part.Color,m=part.Material}
                            part.Color=Color3.fromRGB(80,170,255)
                            part.Material=Enum.Material.Neon
                        end)
                    end
                end
            end
        end
    end)
    notify("Chams","Aktif",2)
end
local function disableChams()
    if ChamsConn then ChamsConn:Disconnect();ChamsConn=nil end
    clearChams();notify("Chams","Nonaktif",1.5)
end

-- Potato Mode
local function enablePotato()
    pcall(function()
        workspace.GlobalShadows=false;Lighting.GlobalShadows=false
        for _,o in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if o:IsA("ParticleEmitter") or o:IsA("Fire") or o:IsA("Smoke")
                    or o:IsA("Sparkles") or o:IsA("Trail") then o.Enabled=false end
                if o:IsA("PostEffect") or o:IsA("BlurEffect") or o:IsA("BloomEffect")
                    or o:IsA("SunRaysEffect") then o.Enabled=false end
            end)
        end
    end)
    notify("Potato Mode","Anti Lag aktif",2)
end
local function disablePotato()
    pcall(function() workspace.GlobalShadows=true;Lighting.GlobalShadows=true end)
    notify("Potato Mode","Nonaktif",1.5)
end

-- Record
local function startRecord()
    WaypointLog={};RecordStart=tick();State.recording=true
    if RecordConn then RecordConn:Disconnect() end
    RecordConn=RunService.Heartbeat:Connect(function()
        if not State.recording then return end
        local pos=HRP.Position
        if #WaypointLog==0 or (WaypointLog[#WaypointLog]-pos).Magnitude>3 then
            table.insert(WaypointLog,pos)
        end
    end)
    notify("Record","Merekam...",2)
end
local function stopRecord()
    State.recording=false
    if RecordConn then RecordConn:Disconnect();RecordConn=nil end
    notify("Record","Stop — "..#WaypointLog.." pts",2)
end
local function saveRecord()
    if #WaypointLog==0 then notify("Save","Belum ada waypoints!",2);return end
    table.insert(SavedRoutes,{
        mapName=State.mapName,obsName=State.obsName,
        waypoints=table.clone(WaypointLog),
        duration=math.floor(tick()-RecordStart),
        timestamp=tostring(math.floor(tick()))
    })
    notify("Saved","["..State.mapName.."] ("..#WaypointLog.." pts)",3)
    WaypointLog={}
end

local function copyMapName()
    local n=workspace.Name
    pcall(function()
        for _,v in ipairs(workspace:GetChildren()) do
            if v:IsA("Model") and v.Name~="Camera" then n=v.Name;break end
        end
    end)
    State.mapName=n
    pcall(function() setclipboard(n) end)
    notify("Map","Nama: "..n,3)
    return n
end

local function rejoin()
    notify("Rejoin","Rejoining...",2)
    task.delay(1,function()
        pcall(function() TeleportService:Teleport(game.PlaceId,Player) end)
    end)
end

-- ANS
local ANS={
    running={pushup=false,situp=false,jjs=false,pullup=false},
    count={pushup=0,situp=0,jjs=0,pullup=0},
    antiAfk=false,
}
local function findPrompt(kws)
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("ProximityPrompt") then
            local n=(o.ActionText..o.ObjectText..o.Parent.Name):lower()
            for _,k in ipairs(kws) do if n:find(k) then return o end end
        end
    end
end
local function findRemote(kws)
    local function s(p)
        for _,o in ipairs(p:GetDescendants()) do
            if o:IsA("RemoteEvent") then
                local n=o.Name:lower()
                for _,k in ipairs(kws) do if n:find(k) then return o end end
            end
        end
    end
    return s(workspace) or s(game:GetService("ReplicatedStorage"))
end
local function startExercise(key,pkws,rkws,label)
    if ANS.running[key] then return end
    ANS.running[key]=true
    notify("ANS",label.." dimulai",2)
    task.spawn(function()
        while ANS.running[key] do
            pcall(function()
                local p=findPrompt(pkws)
                if p then
                    fireproximityprompt(p)
                else
                    local r=findRemote(rkws)
                    if r then r:FireServer() end
                end
                ANS.count[key]+=1
            end)
            task.wait(0.08)
        end
    end)
end
local function stopExercise(key,label)
    ANS.running[key]=false
    notify("ANS",label.." dihentikan",1.5)
end

-- =============================================
-- GUI
-- =============================================
local oldG=GuiParent:FindFirstChild("therX_v3")
if oldG then oldG:Destroy() end
task.wait(0.05)

local gui=Instance.new("ScreenGui")
gui.Name="therX_v3";gui.ResetOnSpawn=false
gui.DisplayOrder=999;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=GuiParent

local miniBar -- forward declare

local C={
    bg=Color3.fromRGB(14,7,28),white=Color3.fromRGB(255,255,255),
    purple=Color3.fromRGB(160,100,255),blue=Color3.fromRGB(80,170,255),
    green=Color3.fromRGB(70,220,110),amber=Color3.fromRGB(255,185,55),
    red=Color3.fromRGB(255,80,80),textBr=Color3.fromRGB(230,218,255),
    textDim=Color3.fromRGB(130,100,175),textMut=Color3.fromRGB(90,65,125),
}

-- Main frame
local main=Instance.new("Frame",gui)
main.Size=UDim2.new(0,620,0,400)
main.AnchorPoint=Vector2.new(0.5,0.5)
main.Position=UDim2.new(0.5,0,0.5,0)
main.BackgroundColor3=C.bg;main.BackgroundTransparency=0.08
main.BorderSizePixel=0;main.Active=true;main.Draggable=true
Instance.new("UICorner",main).CornerRadius=UDim.new(0,20)
local ms=Instance.new("UIStroke",main);ms.Color=C.white;ms.Transparency=0.78;ms.Thickness=1

-- Scale responsif
local mainScale=Instance.new("UIScale",main)
local function updateScale()
    pcall(function()
        local vp=workspace.CurrentCamera.ViewportSize
        local s=math.clamp(math.min((vp.X-24)/620,(vp.Y-24)/400),0.45,1)
        mainScale.Scale=s
    end)
end
updateScale()
pcall(function()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end)

-- Orbs deko
local function makeOrb(x,y,sz,col,tr)
    local o=Instance.new("Frame",main)
    o.Size=UDim2.new(0,sz,0,sz);o.Position=UDim2.new(0,x,0,y)
    o.BackgroundColor3=col;o.BackgroundTransparency=tr
    o.BorderSizePixel=0;o.ZIndex=0
    Instance.new("UICorner",o).CornerRadius=UDim.new(1,0)
end
makeOrb(-80,-80,220,C.purple,0.88)
makeOrb(500,300,180,C.blue,0.90)
makeOrb(440,-30,120,Color3.fromRGB(255,80,200),0.93)

-- Title bar
local tBar=Instance.new("Frame",main)
tBar.Size=UDim2.new(1,0,0,46);tBar.Position=UDim2.new(0,0,0,0)
tBar.BackgroundColor3=C.white;tBar.BackgroundTransparency=0.94
tBar.BorderSizePixel=0;tBar.ZIndex=2
Instance.new("UICorner",tBar).CornerRadius=UDim.new(0,20)

local function hex(parent,x,y,r,col,alpha)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(0,r*2,0,r*2);f.Position=UDim2.new(0,x-r,0,y-r)
    f.BackgroundColor3=col;f.BackgroundTransparency=alpha;f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(1,0)
end

local lf=Instance.new("Frame",tBar)
lf.Size=UDim2.new(0,30,0,30);lf.Position=UDim2.new(0,12,0.5,-15)
lf.BackgroundTransparency=1
hex(lf,15,15,15,C.purple,0.65);hex(lf,15,15,10,C.blue,0.70);hex(lf,15,15,4,C.white,0.1)

local titleL=Instance.new("TextLabel",tBar)
titleL.Size=UDim2.new(0,80,0,20);titleL.Position=UDim2.new(0,50,0,8)
titleL.BackgroundTransparency=1;titleL.Text="therX"
titleL.TextColor3=C.textBr;titleL.Font=Enum.Font.GothamBold;titleL.TextSize=15
titleL.TextXAlignment=Enum.TextXAlignment.Left;titleL.ZIndex=3

local verL=Instance.new("TextLabel",tBar)
verL.Size=UDim2.new(0,160,0,12);verL.Position=UDim2.new(0,50,0,28)
verL.BackgroundTransparency=1;verL.Text="v0.1.0  by AxzZz"
verL.TextColor3=C.purple;verL.Font=Enum.Font.Gotham;verL.TextSize=9
verL.TextXAlignment=Enum.TextXAlignment.Left;verL.ZIndex=3

local fpsPingLabel=Instance.new("TextLabel",tBar)
fpsPingLabel.Size=UDim2.new(0,160,0,14);fpsPingLabel.Position=UDim2.new(0.5,-80,0.5,-7)
fpsPingLabel.BackgroundTransparency=1;fpsPingLabel.Text="FPS: -- | Ping: --ms"
fpsPingLabel.TextColor3=C.textDim;fpsPingLabel.Font=Enum.Font.Gotham;fpsPingLabel.TextSize=9
fpsPingLabel.TextXAlignment=Enum.TextXAlignment.Center;fpsPingLabel.ZIndex=3

local fpsN=0;local fpsT=0
RunService.Heartbeat:Connect(function(dt)
    fpsN+=1;fpsT+=dt
    if fpsT>=0.5 then
        local fps=math.floor(fpsN/fpsT)
        local ping="--"
        pcall(function()
            ping=tostring(math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()))
        end)
        fpsPingLabel.Text="FPS: "..fps.." | Ping: "..ping.."ms"
        fpsPingLabel.TextColor3=fps>=55 and C.green or (fps>=30 and C.amber or C.red)
        fpsN=0;fpsT=0
    end
end)

-- Window buttons
local function winBtn(parent,xOff,col,onClick)
    local btn=Instance.new("TextButton",parent)
    btn.Size=UDim2.new(0,14,0,14);btn.Position=UDim2.new(1,xOff,0.5,-7)
    btn.BackgroundColor3=col;btn.BackgroundTransparency=0.1
    btn.BorderSizePixel=0;btn.Text="";btn.ZIndex=3
    Instance.new("UICorner",btn).CornerRadius=UDim.new(1,0)
    btn.MouseButton1Click:Connect(onClick)
    btn.MouseEnter:Connect(function() tween(btn,{BackgroundTransparency=0},0.1) end)
    btn.MouseLeave:Connect(function() tween(btn,{BackgroundTransparency=0.1},0.1) end)
end

local function hideMain()
    tween(main,{Size=UDim2.new(0,620,0,0),BackgroundTransparency=1},0.2)
    task.delay(0.25,function()
        main.Visible=false
        main.Size=UDim2.new(0,620,0,400)
        main.BackgroundTransparency=0.08
        miniBar.Visible=true
    end)
end

local function killAll()
    State.fly=false;disableFly()
    State.infiniteJ=false;disableInfJump()
    State.autoWalk=false;disableAutoWalk()
    State.noclip=false;disableNoclip()
    State.godMode=false;disableGodMode()
    State.antiVoid=false;disableAntiVoid()
    State.espEnabled=false;disableEsp()
    State.chams=false;disableChams()
    State.antiLag=false;disablePotato()
    notify("Reset","Semua fitur dimatikan",2)
end

winBtn(tBar,-88,C.red,function() killAll();task.delay(0.3,function() gui:Destroy() end) end)
winBtn(tBar,-66,C.amber,function() main.Visible=not main.Visible end)
winBtn(tBar,-44,C.green,hideMain)

-- Sidebar
local SIDEW=54
local CONTENTW=620-SIDEW

local sidebar=Instance.new("Frame",main)
sidebar.Size=UDim2.new(0,SIDEW,1,-46);sidebar.Position=UDim2.new(0,0,0,46)
sidebar.BackgroundColor3=Color3.fromRGB(0,0,0);sidebar.BackgroundTransparency=0.55
sidebar.BorderSizePixel=0;sidebar.ZIndex=2

local sideDiv=Instance.new("Frame",main)
sideDiv.Size=UDim2.new(0,1,1,-46);sideDiv.Position=UDim2.new(0,SIDEW,0,46)
sideDiv.BackgroundColor3=C.white;sideDiv.BackgroundTransparency=0.88;sideDiv.BorderSizePixel=0

local TABS={
    {icon="🚀",name="Move"},
    {icon="👁",name="Visual"},
    {icon="⏺",name="Record"},
    {icon="💾",name="Saves"},
    {icon="🛡",name="Util"},
    {icon="⚡",name="Perf"},
    {icon="👥",name="Players"},
    {icon="🎖",name="ANS"},
}

local tabBtns={}
local tabPanels={}
local curTab=1

local function setTab(idx)
    curTab=idx
    for i,b in ipairs(tabBtns) do
        tween(b,{BackgroundTransparency=i==idx and 0.5 or 1},0.15)
        for _,lbl in ipairs(b:GetChildren()) do
            if lbl:IsA("TextLabel") then
                tween(lbl,{TextColor3=i==idx and Color3.fromRGB(205,165,255) or Color3.fromRGB(90,65,120)},0.15)
            end
        end
    end
    for i,p in ipairs(tabPanels) do p.Visible=(i==idx) end
end

for i,tab in ipairs(TABS) do
    local btn=Instance.new("TextButton",sidebar)
    btn.Size=UDim2.new(1,-4,0,42)
    btn.Position=UDim2.new(0,2,0,4+(i-1)*46)
    btn.BackgroundColor3=C.purple
    btn.BackgroundTransparency=i==1 and 0.5 or 1
    btn.BorderSizePixel=0;btn.ZIndex=3;btn.Text=""
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)
    local iconL=Instance.new("TextLabel",btn)
    iconL.Size=UDim2.new(1,0,0,20);iconL.Position=UDim2.new(0,0,0,4)
    iconL.BackgroundTransparency=1;iconL.Text=tab.icon
    iconL.TextColor3=i==1 and Color3.fromRGB(205,165,255) or Color3.fromRGB(90,65,120)
    iconL.Font=Enum.Font.GothamBold;iconL.TextSize=15;iconL.ZIndex=4
    iconL.TextXAlignment=Enum.TextXAlignment.Center
    local nameL=Instance.new("TextLabel",btn)
    nameL.Size=UDim2.new(1,0,0,11);nameL.Position=UDim2.new(0,0,0,24)
    nameL.BackgroundTransparency=1;nameL.Text=tab.name
    nameL.TextColor3=i==1 and Color3.fromRGB(205,165,255) or Color3.fromRGB(90,65,120)
    nameL.Font=Enum.Font.Gotham;nameL.TextSize=7;nameL.ZIndex=4
    nameL.TextXAlignment=Enum.TextXAlignment.Center
    btn.MouseButton1Click:Connect(function() setTab(i) end)
    table.insert(tabBtns,btn)
end

-- Content panel factory
local function newPanel()
    local sf=Instance.new("ScrollingFrame",main)
    sf.Size=UDim2.new(0,CONTENTW-12,1,-56);sf.Position=UDim2.new(0,SIDEW+6,0,50)
    sf.BackgroundTransparency=1;sf.BorderSizePixel=0
    sf.ScrollBarThickness=2;sf.ScrollBarImageColor3=C.purple
    sf.Visible=false;sf.ZIndex=2
    local ul=Instance.new("UIListLayout",sf);ul.Padding=UDim.new(0,5)
    local up=Instance.new("UIPadding",sf)
    up.PaddingTop=UDim.new(0,4);up.PaddingLeft=UDim.new(0,2);up.PaddingRight=UDim.new(0,4)
    ul:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize=UDim2.new(0,0,0,ul.AbsoluteContentSize.Y+10)
    end)
    return sf
end

local function newGridPanel()
    local sf=Instance.new("ScrollingFrame",main)
    sf.Size=UDim2.new(0,CONTENTW-12,1,-56);sf.Position=UDim2.new(0,SIDEW+6,0,50)
    sf.BackgroundTransparency=1;sf.BorderSizePixel=0
    sf.ScrollBarThickness=2;sf.ScrollBarImageColor3=C.purple
    sf.Visible=false;sf.ZIndex=2
    local ul=Instance.new("UIGridLayout",sf)
    ul.CellSize=UDim2.new(0,(CONTENTW-12)/2-6,0,52)
    ul.CellPadding=UDim2.new(0,6,0,6)
    ul.SortOrder=Enum.SortOrder.LayoutOrder
    local up=Instance.new("UIPadding",sf)
    up.PaddingTop=UDim.new(0,4);up.PaddingLeft=UDim.new(0,2);up.PaddingRight=UDim.new(0,4)
    ul:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize=UDim2.new(0,0,0,ul.AbsoluteContentSize.Y+10)
    end)
    return sf
end

-- UI helpers
local function sectLbl(parent,txt,order)
    local l=Instance.new("TextLabel",parent)
    l.Size=UDim2.new(1,0,0,14);l.BackgroundTransparency=1
    l.Text=txt;l.TextColor3=Color3.fromRGB(130,80,200)
    l.Font=Enum.Font.GothamBold;l.TextSize=9
    l.TextXAlignment=Enum.TextXAlignment.Left;l.ZIndex=3
    l.LayoutOrder=order or 0
    return l
end

local function toggleCard(parent,label,sub,iconColor,warn,order)
    local row=Instance.new("Frame",parent)
    row.BackgroundColor3=warn and Color3.fromRGB(50,25,5) or C.white
    row.BackgroundTransparency=warn and 0.65 or 0.92
    row.BorderSizePixel=0;row.ZIndex=3;row.LayoutOrder=order or 1
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,12)
    local rs=Instance.new("UIStroke",row)
    rs.Color=warn and C.amber or C.white;rs.Transparency=warn and 0.55 or 0.84;rs.Thickness=0.8

    local ib=Instance.new("Frame",row)
    ib.Size=UDim2.new(0,28,0,28);ib.Position=UDim2.new(0,7,0.5,-14)
    ib.BackgroundColor3=iconColor;ib.BackgroundTransparency=0.75;ib.BorderSizePixel=0
    Instance.new("UICorner",ib).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",ib).Color=iconColor
    local il=Instance.new("TextLabel",ib)
    il.Size=UDim2.new(1,0,1,0);il.BackgroundTransparency=1
    il.Text="⬡";il.TextColor3=iconColor
    il.Font=Enum.Font.GothamBold;il.TextSize=12;il.ZIndex=4

    local nl=Instance.new("TextLabel",row)
    nl.Size=UDim2.new(0.55,0,0,15);nl.Position=UDim2.new(0,42,0,7)
    nl.BackgroundTransparency=1;nl.Text=label
    nl.TextColor3=warn and C.amber or C.textBr
    nl.Font=Enum.Font.GothamBold;nl.TextSize=10
    nl.TextXAlignment=Enum.TextXAlignment.Left;nl.ZIndex=4

    local sl=Instance.new("TextLabel",row)
    sl.Size=UDim2.new(0.55,0,0,11);sl.Position=UDim2.new(0,42,0,24)
    sl.BackgroundTransparency=1;sl.Text=sub
    sl.TextColor3=Color3.fromRGB(120,90,165)
    sl.Font=Enum.Font.Gotham;sl.TextSize=8
    sl.TextXAlignment=Enum.TextXAlignment.Left;sl.ZIndex=4

    local togBg=Instance.new("Frame",row)
    togBg.Size=UDim2.new(0,34,0,20);togBg.Position=UDim2.new(1,-42,0.5,-10)
    togBg.BackgroundColor3=Color3.fromRGB(35,18,65);togBg.BorderSizePixel=0
    Instance.new("UICorner",togBg).CornerRadius=UDim.new(1,0)
    Instance.new("UIStroke",togBg).Color=C.white

    local knob=Instance.new("Frame",togBg)
    knob.Size=UDim2.new(0,14,0,14);knob.Position=UDim2.new(0,3,0.5,-7)
    knob.BackgroundColor3=Color3.fromRGB(180,150,220);knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local on=false
    local cz=Instance.new("TextButton",row)
    cz.Size=UDim2.new(1,0,1,0);cz.BackgroundTransparency=1;cz.Text="";cz.ZIndex=5

    cz.MouseButton1Click:Connect(function()
        on=not on
        tween(togBg,{BackgroundColor3=on and Color3.fromRGB(100,50,220) or Color3.fromRGB(35,18,65)})
        tween(knob,{
            BackgroundColor3=on and C.white or Color3.fromRGB(180,150,220),
            Position=on and UDim2.new(0,17,0.5,-7) or UDim2.new(0,3,0.5,-7)
        })
        tween(row,{BackgroundTransparency=on and (warn and 0.5 or 0.84) or (warn and 0.65 or 0.92)},0.2)
        rs.Color=(on and not warn) and C.purple or (warn and C.amber or C.white)
        rs.Transparency=on and 0.4 or (warn and 0.55 or 0.84)
    end)
    return row,cz
end

local function glBtn(parent,label,r,g,b,w,cb,order)
    local btn=Instance.new("TextButton",parent)
    btn.Size=UDim2.new(w or 1,0,0,33);btn.ZIndex=3
    btn.BackgroundColor3=Color3.fromRGB(r,g,b);btn.BackgroundTransparency=0.65
    btn.BorderSizePixel=0;btn.Text=label
    btn.Font=Enum.Font.GothamBold;btn.TextSize=10
    btn.TextColor3=Color3.fromRGB(math.min(255,r+90),math.min(255,g+90),math.min(255,b+90))
    btn.LayoutOrder=order or 99
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)
    local bs=Instance.new("UIStroke",btn)
    bs.Color=Color3.fromRGB(math.min(255,r+50),math.min(255,g+50),math.min(255,b+50));bs.Transparency=0.5
    btn.MouseButton1Click:Connect(cb)
    btn.MouseEnter:Connect(function() tween(btn,{BackgroundTransparency=0.4}) end)
    btn.MouseLeave:Connect(function() tween(btn,{BackgroundTransparency=0.65}) end)
    return btn
end

local function makeSlider(parent,label,minV,maxV,defV,onChange,order)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,46);row.ZIndex=3
    row.BackgroundColor3=Color3.fromRGB(0,0,0);row.BackgroundTransparency=0.6
    row.BorderSizePixel=0;row.LayoutOrder=order or 10
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,10)
    Instance.new("UIStroke",row).Color=C.white
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.6,0,0,14);lbl.Position=UDim2.new(0,10,0,6)
    lbl.BackgroundTransparency=1;lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(140,105,185);lbl.Font=Enum.Font.Gotham
    lbl.TextSize=9;lbl.TextXAlignment=Enum.TextXAlignment.Left;lbl.ZIndex=4
    local vLbl=Instance.new("TextLabel",row)
    vLbl.Size=UDim2.new(0.3,0,0,14);vLbl.Position=UDim2.new(0.7,-10,0,6)
    vLbl.BackgroundTransparency=1;vLbl.Text=tostring(defV)
    vLbl.TextColor3=C.purple;vLbl.Font=Enum.Font.GothamBold
    vLbl.TextSize=10;vLbl.TextXAlignment=Enum.TextXAlignment.Right;vLbl.ZIndex=4
    local track=Instance.new("Frame",row)
    track.Size=UDim2.new(1,-20,0,4);track.Position=UDim2.new(0,10,0,30)
    track.BackgroundColor3=Color3.fromRGB(50,28,90);track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local pct=(defV-minV)/(maxV-minV)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new(pct,0,1,0);fill.BackgroundColor3=C.purple;fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local kn=Instance.new("Frame",track)
    kn.Size=UDim2.new(0,13,0,13);kn.Position=UDim2.new(pct,-6,0.5,-6)
    kn.BackgroundColor3=Color3.fromRGB(220,205,255);kn.BorderSizePixel=0
    Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    local dragging=false
    local sbtn=Instance.new("TextButton",track)
    sbtn.Size=UDim2.new(1,0,0,22);sbtn.Position=UDim2.new(0,0,0,-9)
    sbtn.BackgroundTransparency=1;sbtn.Text="";sbtn.ZIndex=5
    local function update(x)
        local rel=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local val=math.floor(minV+rel*(maxV-minV))
        vLbl.Text=tostring(val)
        fill.Size=UDim2.new(rel,0,1,0);kn.Position=UDim2.new(rel,-6,0.5,-6)
        onChange(val)
    end
    sbtn.MouseButton1Down:Connect(function() dragging=true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    return row
end

local function makeInput(parent,ph,onChange,order)
    local frame=Instance.new("Frame",parent)
    frame.Size=UDim2.new(1,0,0,34);frame.ZIndex=3
    frame.BackgroundColor3=Color3.fromRGB(0,0,0);frame.BackgroundTransparency=0.5
    frame.BorderSizePixel=0;frame.LayoutOrder=order or 10
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
    local fs=Instance.new("UIStroke",frame);fs.Color=C.white;fs.Transparency=0.84
    local box=Instance.new("TextBox",frame)
    box.Size=UDim2.new(1,-16,1,0);box.Position=UDim2.new(0,8,0,0)
    box.BackgroundTransparency=1;box.PlaceholderText=ph
    box.PlaceholderColor3=Color3.fromRGB(80,55,110);box.Text=""
    box.TextColor3=C.textBr;box.Font=Enum.Font.Gotham;box.TextSize=11
    box.TextXAlignment=Enum.TextXAlignment.Left;box.ZIndex=4
    if onChange then box.FocusLost:Connect(function() onChange(box.Text) end) end
    box.Focused:Connect(function() fs.Color=C.purple;fs.Transparency=0.4 end)
    box.FocusLost:Connect(function() fs.Color=C.white;fs.Transparency=0.84 end)
    return frame,box
end

local function infoBox(parent,h,order)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,0,0,h or 60);f.ZIndex=3
    f.BackgroundColor3=Color3.fromRGB(0,0,0);f.BackgroundTransparency=0.55
    f.BorderSizePixel=0;f.LayoutOrder=order or 10
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,10)
    Instance.new("UIStroke",f).Color=C.white
    return f
end

local function infoRow(parent,lbl,ypos)
    local l=Instance.new("TextLabel",parent)
    l.Size=UDim2.new(0.5,0,0,13);l.Position=UDim2.new(0,10,0,ypos)
    l.BackgroundTransparency=1;l.Text=lbl
    l.TextColor3=C.textMut;l.Font=Enum.Font.Gotham;l.TextSize=9
    l.TextXAlignment=Enum.TextXAlignment.Left;l.ZIndex=4
    local v=Instance.new("TextLabel",parent)
    v.Size=UDim2.new(0.4,0,0,13);v.Position=UDim2.new(0.6,-10,0,ypos)
    v.BackgroundTransparency=1;v.TextColor3=C.textBr
    v.Font=Enum.Font.GothamBold;v.TextSize=9
    v.TextXAlignment=Enum.TextXAlignment.Right;v.ZIndex=4
    return v
end

-- =============================================
-- TAB 1 — MOVE
-- =============================================
local p1=newGridPanel();table.insert(tabPanels,p1)

local _,flyC=toggleCard(p1,"Fly Mode","WASD+Space/Shift",C.purple,false,1)
flyC.MouseButton1Click:Connect(function()
    State.fly=not State.fly
    if State.fly then enableFly() else disableFly() end
end)

local _,jC=toggleCard(p1,"Infinity Jump","Lompat tanpa batas",C.blue,false,2)
jC.MouseButton1Click:Connect(function()
    State.infiniteJ=not State.infiniteJ
    if State.infiniteJ then enableInfJump() else disableInfJump() end
end)

local _,wC=toggleCard(p1,"Auto Walk","Jalan otomatis",C.green,false,3)
wC.MouseButton1Click:Connect(function()
    State.autoWalk=not State.autoWalk
    if State.autoWalk then enableAutoWalk() else disableAutoWalk() end
end)

local _,ncC=toggleCard(p1,"NoClip","Tembus dinding",C.amber,false,4)
ncC.MouseButton1Click:Connect(function()
    State.noclip=not State.noclip
    if State.noclip then enableNoclip() else disableNoclip() end
end)

local sh=Instance.new("Frame",p1)
sh.Size=UDim2.new(1,0,0,210);sh.BackgroundTransparency=1;sh.LayoutOrder=5
local shUl=Instance.new("UIListLayout",sh);shUl.Padding=UDim.new(0,5)
makeSlider(sh,"Fly Speed",10,200,50,function(v) State.flySpeed=v end,1)
makeSlider(sh,"Jump Power",50,500,100,function(v) State.jumpPower=v;pcall(function() Humanoid.JumpPower=v end) end,2)
makeSlider(sh,"Walk Speed",8,100,16,function(v) State.walkSpeed=v;if State.autoWalk then pcall(function() Humanoid.WalkSpeed=v end) end end,3)
makeSlider(sh,"Speed Hack",8,300,16,function(v) pcall(function() Humanoid.WalkSpeed=v end) end,4)
shUl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sh.Size=UDim2.new(1,0,0,shUl.AbsoluteContentSize.Y)
end)

-- =============================================
-- TAB 2 — VISUAL
-- =============================================
local p2=newGridPanel();table.insert(tabPanels,p2)

local _,espC=toggleCard(p2,"Player ESP","Nametag player lain",C.blue,false,1)
espC.MouseButton1Click:Connect(function()
    State.espEnabled=not State.espEnabled
    if State.espEnabled then enableEsp() else disableEsp() end
end)

local _,chC=toggleCard(p2,"Chams","Highlight neon player",Color3.fromRGB(255,80,200),false,2)
chC.MouseButton1Click:Connect(function()
    State.chams=not State.chams
    if State.chams then enableChams() else disableChams() end
end)

local _,gdC=toggleCard(p2,"God Mode","HP tidak berkurang",C.green,false,3)
gdC.MouseButton1Click:Connect(function()
    State.godMode=not State.godMode
    if State.godMode then enableGodMode() else disableGodMode() end
end)

local _,avC=toggleCard(p2,"Anti-Void","Auto teleport saat void",C.amber,false,4)
avC.MouseButton1Click:Connect(function()
    State.antiVoid=not State.antiVoid
    if State.antiVoid then enableAntiVoid() else disableAntiVoid() end
end)

-- =============================================
-- TAB 3 — RECORD
-- =============================================
local p3=newPanel();table.insert(tabPanels,p3)
sectLbl(p3,"— map info",1)
local _,mapBox=makeInput(p3,"Nama map...",function(v) State.mapName=v~="" and v or "Unknown Map" end,2)
local _,obsBox=makeInput(p3,"Nama rintangan...",function(v) State.obsName=v~="" and v or "Unknown Obstacle" end,3)
sectLbl(p3,"— rekaman",4)
local rib=infoBox(p3,70,5)
local recStat=infoRow(rib,"Status",6)
local recWp=infoRow(rib,"Waypoints",22)
local recDur=infoRow(rib,"Durasi",38)
local recMap=infoRow(rib,"Map",54)
recStat.Text="Idle";recWp.Text="0";recDur.Text="0s";recMap.Text="—"

RunService.Heartbeat:Connect(function()
    recWp.Text=tostring(#WaypointLog)
    if State.recording then
        recDur.Text=math.floor(tick()-RecordStart).."s"
        recStat.TextColor3=C.green
    else recStat.TextColor3=C.textBr end
end)

local rbH=Instance.new("Frame",p3)
rbH.Size=UDim2.new(1,0,0,33);rbH.BackgroundTransparency=1;rbH.LayoutOrder=6
local rbUl=Instance.new("UIListLayout",rbH)
rbUl.FillDirection=Enum.FillDirection.Horizontal;rbUl.Padding=UDim.new(0,6)
local recBtn=glBtn(rbH,"⏺ Record",160,20,20,0.47,function()
    if not State.recording then
        startRecord();recBtn.Text="⏹ Stop"
        recBtn.BackgroundColor3=Color3.fromRGB(220,40,40)
        recStat.Text="Recording";recMap.Text=State.mapName
    else
        stopRecord();recBtn.Text="⏺ Record"
        recBtn.BackgroundColor3=Color3.fromRGB(160,20,20)
        recStat.Text="Stopped"
    end
end)
glBtn(rbH,"💾 Save",20,100,30,0.47,function()
    saveRecord();recStat.Text="Saved ✓";recStat.TextColor3=C.green
end)

local cpH=Instance.new("Frame",p3)
cpH.Size=UDim2.new(1,0,0,33);cpH.BackgroundTransparency=1;cpH.LayoutOrder=7
Instance.new("UIListLayout",cpH).FillDirection=Enum.FillDirection.Horizontal
glBtn(cpH,"🗺 Auto-Detect Map",60,60,160,1,function()
    local n=copyMapName();mapBox.Text=n
end)

-- =============================================
-- TAB 4 — SAVES
-- =============================================
local p4=newPanel();table.insert(tabPanels,p4)
local emptyL=Instance.new("TextLabel",p4)
emptyL.Size=UDim2.new(1,0,0,36);emptyL.BackgroundTransparency=1
emptyL.Text="Belum ada route tersimpan"
emptyL.TextColor3=Color3.fromRGB(70,45,100);emptyL.Font=Enum.Font.Gotham
emptyL.TextSize=10;emptyL.ZIndex=3;emptyL.LayoutOrder=1
local saveCards={}
local function refreshSaves()
    for _,c in ipairs(saveCards) do c:Destroy() end;saveCards={}
    emptyL.Visible=#SavedRoutes==0
    for i,route in ipairs(SavedRoutes) do
        local card=Instance.new("Frame",p4)
        card.Size=UDim2.new(1,0,0,58);card.ZIndex=3;card.LayoutOrder=i+1
        card.BackgroundColor3=C.white;card.BackgroundTransparency=0.91;card.BorderSizePixel=0
        Instance.new("UICorner",card).CornerRadius=UDim.new(0,12)
        Instance.new("UIStroke",card).Color=C.white
        local ml=Instance.new("TextLabel",card)
        ml.Size=UDim2.new(0.82,0,0,16);ml.Position=UDim2.new(0,10,0,6)
        ml.BackgroundTransparency=1;ml.Text=route.mapName
        ml.TextColor3=C.textBr;ml.Font=Enum.Font.GothamBold;ml.TextSize=11
        ml.TextXAlignment=Enum.TextXAlignment.Left;ml.ZIndex=4
        local ol=Instance.new("TextLabel",card)
        ol.Size=UDim2.new(0.82,0,0,12);ol.Position=UDim2.new(0,10,0,24)
        ol.BackgroundTransparency=1;ol.Text="▸ "..route.obsName
        ol.TextColor3=C.purple;ol.Font=Enum.Font.Gotham;ol.TextSize=9
        ol.TextXAlignment=Enum.TextXAlignment.Left;ol.ZIndex=4
        local meta=Instance.new("TextLabel",card)
        meta.Size=UDim2.new(0.82,0,0,11);meta.Position=UDim2.new(0,10,0,38)
        meta.BackgroundTransparency=1
        meta.Text=#route.waypoints.." pts · "..route.duration.."s"
        meta.TextColor3=C.textMut;meta.Font=Enum.Font.Gotham;meta.TextSize=8
        meta.TextXAlignment=Enum.TextXAlignment.Left;meta.ZIndex=4
        local db=Instance.new("TextButton",card)
        db.Size=UDim2.new(0,24,0,24);db.Position=UDim2.new(1,-32,0.5,-12)
        db.BackgroundColor3=C.red;db.BackgroundTransparency=0.65
        db.Text="✕";db.TextColor3=Color3.fromRGB(255,180,180)
        db.Font=Enum.Font.GothamBold;db.TextSize=11;db.BorderSizePixel=0;db.ZIndex=5
        Instance.new("UICorner",db).CornerRadius=UDim.new(0,7)
        db.MouseButton1Click:Connect(function()
            table.remove(SavedRoutes,i);refreshSaves()
            notify("Deleted","Route dihapus",1.5)
        end)
        table.insert(saveCards,card)
    end
end
tabBtns[4].MouseButton1Click:Connect(function() task.defer(refreshSaves) end)

-- =============================================
-- TAB 5 — UTIL
-- =============================================
local p5=newPanel();table.insert(tabPanels,p5)
sectLbl(p5,"— teleport",1)
local _,tpBox=makeInput(p5,"Nama player...",nil,2)
local tpH=Instance.new("Frame",p5)
tpH.Size=UDim2.new(1,0,0,33);tpH.BackgroundTransparency=1;tpH.LayoutOrder=3
local tpUl=Instance.new("UIListLayout",tpH)
tpUl.FillDirection=Enum.FillDirection.Horizontal;tpUl.Padding=UDim.new(0,6)
glBtn(tpH,"🎯 Teleport",80,50,220,1,function() teleportToPlayer(tpBox.Text) end)

sectLbl(p5,"— server",4)
local srvH=Instance.new("Frame",p5)
srvH.Size=UDim2.new(1,0,0,33);srvH.BackgroundTransparency=1;srvH.LayoutOrder=5
local srvUl=Instance.new("UIListLayout",srvH)
srvUl.FillDirection=Enum.FillDirection.Horizontal;srvUl.Padding=UDim.new(0,6)
glBtn(srvH,"🔄 Rejoin",50,100,200,0.47,function() rejoin() end)
glBtn(srvH,"🗺 Copy Map",60,160,100,0.47,function() copyMapName() end)

-- =============================================
-- TAB 6 — PERF
-- =============================================
local p6=newPanel();table.insert(tabPanels,p6)
sectLbl(p6,"— performance",1)
local _,lagC=toggleCard(p6,"Potato Mode","Anti Lag — grafik minimal",C.amber,true,2)
lagC.MouseButton1Click:Connect(function()
    State.antiLag=not State.antiLag
    if State.antiLag then enablePotato() else disablePotato() end
end)

local pfH=Instance.new("Frame",p6)
pfH.Size=UDim2.new(1,0,0,33);pfH.BackgroundTransparency=1;pfH.LayoutOrder=4
local pfUl=Instance.new("UIListLayout",pfH)
pfUl.FillDirection=Enum.FillDirection.Horizontal;pfUl.Padding=UDim.new(0,6)
glBtn(pfH,"🗑 Kill All",180,30,30,0.47,function() killAll() end)
glBtn(pfH,"✕ Close",160,160,180,0.47,function() hideMain() end)

-- =============================================
-- TAB 7 — PLAYERS
-- =============================================
local p7=newPanel();table.insert(tabPanels,p7)
sectLbl(p7,"— server players",1)
local plrBox=infoBox(p7,280,2)
plrBox.Size=UDim2.new(1,0,0,280)
local plrScroll=Instance.new("ScrollingFrame",plrBox)
plrScroll.Size=UDim2.new(1,-4,1,-4);plrScroll.Position=UDim2.new(0,2,0,2)
plrScroll.BackgroundTransparency=1;plrScroll.BorderSizePixel=0
plrScroll.ScrollBarThickness=2;plrScroll.ScrollBarImageColor3=C.purple;plrScroll.ZIndex=5
local plrUl=Instance.new("UIListLayout",plrScroll);plrUl.Padding=UDim.new(0,3)
plrUl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    plrScroll.CanvasSize=UDim2.new(0,0,0,plrUl.AbsoluteContentSize.Y+6)
end)
glBtn(p7,"🔃 Refresh List",80,80,200,1,function()
    for _,c in ipairs(plrScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for _,plr in ipairs(Players:GetPlayers()) do
        local row=Instance.new("Frame",plrScroll)
        row.Size=UDim2.new(1,0,0,28);row.BackgroundColor3=C.white
        row.BackgroundTransparency=0.91;row.BorderSizePixel=0;row.ZIndex=6
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
        local dot=Instance.new("Frame",row)
        dot.Size=UDim2.new(0,7,0,7);dot.Position=UDim2.new(0,8,0.5,-3.5)
        dot.BackgroundColor3=plr==Player and C.green or C.purple
        dot.BorderSizePixel=0;dot.ZIndex=7
        Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
        local namL=Instance.new("TextLabel",row)
        namL.Size=UDim2.new(0.7,0,1,0);namL.Position=UDim2.new(0,22,0,0)
        namL.BackgroundTransparency=1
        namL.Text=plr.Name..(plr==Player and " (you)" or "")
        namL.TextColor3=plr==Player and C.green or C.textBr
        namL.Font=Enum.Font.GothamBold;namL.TextSize=10
        namL.TextXAlignment=Enum.TextXAlignment.Left;namL.ZIndex=7
        local pingL=Instance.new("TextLabel",row)
        pingL.Size=UDim2.new(0.25,0,1,0);pingL.Position=UDim2.new(0.73,0,0,0)
        pingL.BackgroundTransparency=1
        local ok2,ping=pcall(function() return math.floor(plr:GetNetworkPing()*1000) end)
        pingL.Text=ok2 and ping.."ms" or "—"
        pingL.TextColor3=C.textMut;pingL.Font=Enum.Font.Gotham;pingL.TextSize=9
        pingL.TextXAlignment=Enum.TextXAlignment.Right;pingL.ZIndex=7
    end
end,3)

-- =============================================
-- TAB 8 — ANS
-- =============================================
local p8=newPanel();table.insert(tabPanels,p8)
sectLbl(p8,"— Abdi Negara Simulator",1)

local ansIB=infoBox(p8,68,2)
local ans1=infoRow(ansIB,"Push Up",5)
local ans2=infoRow(ansIB,"Sit Up",20)
local ans3=infoRow(ansIB,"JJS",35)
local ans4=infoRow(ansIB,"Pull Up",50)
ans1.Text="0 | Idle";ans2.Text="0 | Idle";ans3.Text="0 | Idle";ans4.Text="0 | Idle"

RunService.Heartbeat:Connect(function()
    local function fmt(key,lbl)
        lbl.Text=ANS.count[key].." | "..(ANS.running[key] and "▶ ON" or "Idle")
        lbl.TextColor3=ANS.running[key] and C.green or C.textBr
    end
    fmt("pushup",ans1);fmt("situp",ans2);fmt("jjs",ans3);fmt("pullup",ans4)
end)

sectLbl(p8,"— kontrol latihan",3)

local _,puC=toggleCard(p8,"Auto Push Up","Loop push up otomatis",C.purple,false,4)
puC.MouseButton1Click:Connect(function()
    ANS.running.pushup=not ANS.running.pushup
    if ANS.running.pushup then
        startExercise("pushup",{"push","pushup","push up","angkat"},{"pushup","PushUp","Push"},"Push Up")
    else stopExercise("pushup","Push Up") end
end)

local _,suC=toggleCard(p8,"Auto Sit Up","Loop sit up otomatis",C.blue,false,5)
suC.MouseButton1Click:Connect(function()
    ANS.running.situp=not ANS.running.situp
    if ANS.running.situp then
        startExercise("situp",{"sit","situp","sit up","crunch"},{"situp","SitUp","Sit"},"Sit Up")
    else stopExercise("situp","Sit Up") end
end)

local _,jjsC=toggleCard(p8,"Auto JJS","Jumping Jacks otomatis",C.green,false,6)
jjsC.MouseButton1Click:Connect(function()
    ANS.running.jjs=not ANS.running.jjs
    if ANS.running.jjs then
        startExercise("jjs",{"jump","jumping","jjs","jumping jack"},{"jjs","JumpingJack","Jump"},"JJS")
    else stopExercise("jjs","JJS") end
end)

local _,puulC=toggleCard(p8,"Auto Pull Up","Pull up otomatis",Color3.fromRGB(255,120,80),false,7)
puulC.MouseButton1Click:Connect(function()
    ANS.running.pullup=not ANS.running.pullup
    if ANS.running.pullup then
        startExercise("pullup",{"pull","pullup","pull up","gantung"},{"pullup","PullUp","Pull"},"Pull Up")
    else stopExercise("pullup","Pull Up") end
end)

sectLbl(p8,"— shortcut",8)
local allH=Instance.new("Frame",p8)
allH.Size=UDim2.new(1,0,0,33);allH.BackgroundTransparency=1;allH.LayoutOrder=9
Instance.new("UIListLayout",allH).FillDirection=Enum.FillDirection.Horizontal

local allOn=false
local allBtn=glBtn(allH,"⚡ Auto ALL Exercise",100,50,220,0.62,function()
    allOn=not allOn
    if allOn then
        allBtn.Text="⏹ Stop ALL";allBtn.BackgroundColor3=Color3.fromRGB(180,30,30)
        startExercise("pushup",{"push","pushup","push up"},{"pushup","PushUp"},"Push Up")
        startExercise("situp",{"sit","situp","sit up"},{"situp","SitUp"},"Sit Up")
        startExercise("jjs",{"jump","jumping","jjs"},{"jjs","JumpingJack"},"JJS")
        startExercise("pullup",{"pull","pullup","pull up"},{"pullup","PullUp"},"Pull Up")
        notify("ANS","Auto ALL aktif 🔥",3)
    else
        allBtn.Text="⚡ Auto ALL Exercise";allBtn.BackgroundColor3=Color3.fromRGB(100,50,220)
        for k in pairs(ANS.running) do ANS.running[k]=false end
        notify("ANS","Semua dihentikan",2)
    end
end)

local _,afkC=toggleCard(p8,"Anti AFK","Cegah kick karena idle",C.amber,false,10)
afkC.MouseButton1Click:Connect(function()
    ANS.antiAfk=not ANS.antiAfk
    if ANS.antiAfk then
        notify("Anti AFK","Aktif",2)
        task.spawn(function()
            while ANS.antiAfk do
                pcall(function() Humanoid:Move(Vector3.new(0.1,0,0),false) end)
                task.wait(0.1)
                pcall(function() Humanoid:Move(Vector3.zero,false) end)
                task.wait(55)
                if ANS.antiAfk then
                    pcall(function() Humanoid.Jump=true end)
                    task.wait(0.2)
                    pcall(function() Humanoid.Jump=false end)
                end
            end
        end)
    else notify("Anti AFK","Nonaktif",1.5) end
end)

local rstH=Instance.new("Frame",p8)
rstH.Size=UDim2.new(1,0,0,33);rstH.BackgroundTransparency=1;rstH.LayoutOrder=11
Instance.new("UIListLayout",rstH).FillDirection=Enum.FillDirection.Horizontal
glBtn(rstH,"🔄 Reset Counter",80,80,80,1,function()
    ANS.count={pushup=0,situp=0,jjs=0,pullup=0}
    notify("ANS","Counter direset",1.5)
end)

-- =============================================
-- STATUS BAR
-- =============================================
local sBar=Instance.new("Frame",main)
sBar.Size=UDim2.new(1,0,0,22);sBar.Position=UDim2.new(0,0,1,-22)
sBar.BackgroundColor3=Color3.fromRGB(0,0,0);sBar.BackgroundTransparency=0.45
sBar.BorderSizePixel=0;sBar.ZIndex=2
Instance.new("UICorner",sBar).CornerRadius=UDim.new(0,20)

local sDot=Instance.new("Frame",sBar)
sDot.Size=UDim2.new(0,6,0,6);sDot.Position=UDim2.new(0,10,0.5,-3)
sDot.BackgroundColor3=C.green;sDot.BorderSizePixel=0
Instance.new("UICorner",sDot).CornerRadius=UDim.new(1,0)
TweenService:Create(sDot,TweenInfo.new(1.3,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=0.7}):Play()

local sTxt=Instance.new("TextLabel",sBar)
sTxt.Size=UDim2.new(0.4,0,1,0);sTxt.Position=UDim2.new(0,20,0,0)
sTxt.BackgroundTransparency=1;sTxt.Text="ATTACHED"
sTxt.TextColor3=Color3.fromRGB(80,55,110);sTxt.Font=Enum.Font.Gotham;sTxt.TextSize=9
sTxt.TextXAlignment=Enum.TextXAlignment.Left;sTxt.ZIndex=3

local sInfo=Instance.new("TextLabel",sBar)
sInfo.Size=UDim2.new(0.3,0,1,0);sInfo.Position=UDim2.new(0.35,0,0,0)
sInfo.BackgroundTransparency=1;sInfo.Text="#players: "..#Players:GetPlayers()
sInfo.TextColor3=Color3.fromRGB(80,55,110);sInfo.Font=Enum.Font.Gotham;sInfo.TextSize=8
sInfo.TextXAlignment=Enum.TextXAlignment.Center;sInfo.ZIndex=3

local sTime=Instance.new("TextLabel",sBar)
sTime.Size=UDim2.new(0.25,-10,1,0);sTime.Position=UDim2.new(0.75,0,0,0)
sTime.BackgroundTransparency=1;sTime.TextColor3=Color3.fromRGB(80,55,110)
sTime.Font=Enum.Font.Gotham;sTime.TextSize=9;sTime.TextXAlignment=Enum.TextXAlignment.Right;sTime.ZIndex=3

RunService.Heartbeat:Connect(function()
    pcall(function()
        local t=os.time();local h=math.floor(t/3600)%24
        local m=math.floor(t/60)%60;local s=t%60
        sTime.Text=string.format("%02d:%02d:%02d",h,m,s)
    end)
    sInfo.Text="#players: "..#Players:GetPlayers()
end)

-- =============================================
-- MINI BAR
-- =============================================
miniBar=Instance.new("Frame",gui)
miniBar.Name="therX_MiniBar"
miniBar.Size=UDim2.new(0,180,0,38)
miniBar.AnchorPoint=Vector2.new(0,1)
miniBar.Position=UDim2.new(0,20,1,-20)
miniBar.BackgroundColor3=C.bg;miniBar.BackgroundTransparency=0.15
miniBar.BorderSizePixel=0;miniBar.Active=true;miniBar.Draggable=true
miniBar.Visible=false;miniBar.ZIndex=10
Instance.new("UICorner",miniBar).CornerRadius=UDim.new(0,19)
local mbs=Instance.new("UIStroke",miniBar);mbs.Color=C.purple;mbs.Transparency=0.4;mbs.Thickness=1

local mLogo=Instance.new("Frame",miniBar)
mLogo.Size=UDim2.new(0,24,0,24);mLogo.Position=UDim2.new(0,8,0.5,-12)
mLogo.BackgroundTransparency=1;mLogo.ZIndex=11
hex(mLogo,12,12,12,C.purple,0.65);hex(mLogo,12,12,8,C.blue,0.70)

local mTitle=Instance.new("TextLabel",miniBar)
mTitle.Size=UDim2.new(0,55,0,16);mTitle.Position=UDim2.new(0,38,0.5,-9)
mTitle.BackgroundTransparency=1;mTitle.Text="therX"
mTitle.TextColor3=C.textBr;mTitle.Font=Enum.Font.GothamBold;mTitle.TextSize=13
mTitle.TextXAlignment=Enum.TextXAlignment.Left;mTitle.ZIndex=11

local mFps=Instance.new("TextLabel",miniBar)
mFps.Size=UDim2.new(0,45,1,0);mFps.Position=UDim2.new(0,96,0,0)
mFps.BackgroundTransparency=1;mFps.Text="-- fps"
mFps.TextColor3=C.green;mFps.Font=Enum.Font.Gotham;mFps.TextSize=8
mFps.TextXAlignment=Enum.TextXAlignment.Center;mFps.ZIndex=11

RunService.Heartbeat:Connect(function()
    local t=fpsPingLabel.Text
    local fps=t:match("FPS: (%d+)")
    if fps then mFps.Text=fps.." fps" end
end)

local mBtn=Instance.new("TextButton",miniBar)
mBtn.Size=UDim2.new(0,28,0,28);mBtn.Position=UDim2.new(1,-34,0.5,-14)
mBtn.BackgroundColor3=C.purple;mBtn.BackgroundTransparency=0.5
mBtn.BorderSizePixel=0;mBtn.Text="▲";mBtn.TextColor3=C.textBr
mBtn.Font=Enum.Font.GothamBold;mBtn.TextSize=11;mBtn.ZIndex=12
Instance.new("UICorner",mBtn).CornerRadius=UDim.new(0,8)
mBtn.MouseButton1Click:Connect(function()
    miniBar.Visible=false
    main.Size=UDim2.new(0,620,0,0);main.BackgroundTransparency=1;main.Visible=true
    tween(main,{Size=UDim2.new(0,620,0,400),BackgroundTransparency=0.08},0.25)
end)

local mDot=Instance.new("Frame",miniBar)
mDot.Size=UDim2.new(0,5,0,5);mDot.Position=UDim2.new(0,91,0.5,-2)
mDot.BackgroundColor3=C.green;mDot.BorderSizePixel=0;mDot.ZIndex=11
Instance.new("UICorner",mDot).CornerRadius=UDim.new(1,0)
TweenService:Create(mDot,TweenInfo.new(1.3,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=0.75}):Play()

-- =============================================
-- ACTIVATE
-- =============================================
setTab(1)
p1.Visible=true
notify("therX v0.1.0","by AxzZz — Script loaded ✓",4)

end) -- end pcall

if not ok then
    warn("[therX ERROR] "..tostring(err))
    -- Tampilkan error di layar
    pcall(function()
        local sg=Instance.new("ScreenGui",game:GetService("CoreGui"))
        sg.Name="therX_Error";sg.ResetOnSpawn=false;sg.DisplayOrder=99999
        local f=Instance.new("Frame",sg)
        f.Size=UDim2.new(0.9,0,0,130)
        f.AnchorPoint=Vector2.new(0.5,0.5)
        f.Position=UDim2.new(0.5,0,0.5,0)
        f.BackgroundColor3=Color3.fromRGB(20,0,0);f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,12)
        local t=Instance.new("TextLabel",f)
        t.Size=UDim2.new(1,-16,1,-16);t.Position=UDim2.new(0,8,0,8)
        t.BackgroundTransparency=1
        t.Text="therX ERROR:\n"..tostring(err)
        t.TextColor3=Color3.fromRGB(255,100,100);t.Font=Enum.Font.Gotham;t.TextSize=11
        t.TextWrapped=true;t.TextXAlignment=Enum.TextXAlignment.Left
        t.TextYAlignment=Enum.TextYAlignment.Top
        task.delay(10,function() sg:Destroy() end)
    end)
end
