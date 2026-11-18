-- Lua | Roblox Luau LocalScript | Violence District | HANX HUB FINAL V4 + ULTIMATE PARRY v3
-- Delta Executor Ready | Merged Build

if getgenv().HANX_Unload then pcall(getgenv().HANX_Unload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

_G.Ox = _G.Ox or {}
_G.Ox.Auto = _G.Ox.Auto or {}
_G.Ox.Auto.SkillCheck = false
_G.Ox.Auto.SkillCheckMode = "Legit"
_G.Ox.State = { busy = false, RandomMode_IsNormal = false }
_G.Ox.Connections = { SkillHeartbeat = nil }

KILLER_RANGE = 12
local PLAYER_PALLET_RANGE = 8
local KILLER_PALLET_RANGE = 6
local UsedPallets = setmetatable({}, { __mode = "k" })

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Captures, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

-- ============================================================
-- ESP HANX HUB
-- ============================================================
local ESP = { Master = false, Player = false, Killer = false, Name = false, Distance = false, Outline = false, MaxDistance = 1000, Generator = false, GeneratorName = true }
local ESPColors = { Player = Color3.fromRGB(60, 255, 60), Killer = Color3.fromRGB(255, 60, 60), Generator = Color3.fromRGB(255, 255, 0), GeneratorDone = Color3.fromRGB(0, 255, 0), Name = Color3.fromRGB(255, 255, 255), Distance = Color3.fromRGB(255, 255, 255) }
local MapData = { Generators = {}, Windows = {}, Pallets = {}, Hooks = {}, Gates = {}, SCPs = {} }
local espConn = nil
local scanCooldown = 0

local function getDistance(pos)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    return hrp and (pos - hrp.Position).Magnitude or math.huge
end

local function ScanMap(force)
    if not force and tick() - scanCooldown < 2 then return end
    scanCooldown = tick()
    table.clear(MapData.Generators); table.clear(MapData.Windows); table.clear(MapData.Pallets)
    table.clear(MapData.Hooks); table.clear(MapData.Gates); table.clear(MapData.SCPs)
    local map = workspace:FindFirstChild("Map") or workspace
    for i, desc in ipairs(map:GetDescendants()) do
        if i % 200 == 0 then task.wait() end
        if desc:IsA("Model") then
            local n = string.lower(desc.Name)
            if n == "generator" then
                local body = desc:FindFirstChild("GeneratorBody") or desc:FindFirstChildWhichIsA("BasePart")
                if body then table.insert(MapData.Generators, { model = desc, part = body }) end
            elseif n == "hook" and desc:FindFirstChild("HookPoint") then table.insert(MapData.Hooks, desc)
            elseif n == "gate" and desc:FindFirstChild("ExitLever") then table.insert(MapData.Gates, desc)
            elseif n == "window" then table.insert(MapData.Windows, desc) end
        elseif desc:IsA("BasePart") and desc.Name == "PrimaryPartPallet" then
            if desc.Parent and not table.find(MapData.Pallets, desc.Parent) then table.insert(MapData.Pallets, desc.Parent) end
        end
    end
end

local function CreateESP(parent, typeName, options)
    if not parent then return end
    local name = options.name or ""
    local info = options.infoRich or ""
    local color = options.color or Color3.new(1, 1, 1)
    local nameColor = options.nameColor or color
    local infoColor = options.infoColor or Color3.new(1, 1, 1)
    local offsetY = options.offsetY or 4

    local billboard = parent:FindFirstChild(typeName)
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = typeName
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 220, 0, 34)
        billboard.StudsOffset = Vector3.new(0, offsetY, 0)
        billboard.Parent = parent

        local box = Instance.new("Frame")
        box.Name = "Box"; box.BackgroundTransparency = 1; box.Size = UDim2.new(1, 0, 1, 0); box.Parent = billboard

        local row1 = Instance.new("Frame")
        row1.Name = "Row1"; row1.BackgroundTransparency = 1; row1.Size = UDim2.new(0, 0, 0, 16); row1.AutomaticSize = Enum.AutomaticSize.XY; row1.Parent = box
        local layout1 = Instance.new("UIListLayout", row1)
        layout1.FillDirection = Enum.FillDirection.Horizontal
        layout1.HorizontalAlignment = Enum.HorizontalAlignment.Center

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name = "Name"; nameLbl.BackgroundTransparency = 1; nameLbl.AutomaticSize = Enum.AutomaticSize.XY
        nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 12; nameLbl.TextStrokeTransparency = 0; nameLbl.Parent = row1

        local infoLbl = Instance.new("TextLabel")
        infoLbl.Name = "Info"; infoLbl.BackgroundTransparency = 1; infoLbl.AutomaticSize = Enum.AutomaticSize.XY
        infoLbl.Font = Enum.Font.GothamBold; infoLbl.TextSize = 11; infoLbl.RichText = true; infoLbl.TextStrokeTransparency = 0; infoLbl.Parent = box
    end

    -- Selalu perbarui teks dan warna, supaya perubahan dari picker langsung terlihat
    local box = billboard:FindFirstChild("Box")
    local row1 = box and box:FindFirstChild("Row1")
    local nameLbl = row1 and row1:FindFirstChild("Name")
    local infoLbl = box and box:FindFirstChild("Info")
    if nameLbl then nameLbl.Text = name; nameLbl.TextColor3 = nameColor end
    if infoLbl then infoLbl.Text = info; infoLbl.TextColor3 = infoColor; infoLbl.Visible = info ~= "" end
end

local function updatePlayerESP()
    if not ESP.Master then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local isKiller = plr.Team and plr.Team.Name == "Killer"
            local shouldRender = isKiller and ESP.Killer or not isKiller and ESP.Player
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if not hrp or getDistance(hrp.Position) > ESP.MaxDistance then shouldRender = false end
            local hlName = isKiller and "KEH" or "PEH"
            local textName = isKiller and "KE_Text" or "PE_Text"
            if shouldRender then
                local hl = plr.Character:FindFirstChild(hlName)
                if not hl then hl = Instance.new("Highlight"); hl.Name = hlName; hl.Parent = plr.Character end
                local c = isKiller and ESPColors.Killer or ESPColors.Player
                hl.FillColor = c; hl.OutlineColor = c; hl.FillTransparency = ESP.Outline and 1 or 0.5; hl.OutlineTransparency = 0
                local nText = ESP.Name and plr.Name or ""
                local infoParts = {}
                if ESP.Distance and hrp then table.insert(infoParts, string.format("%dm", math.floor(getDistance(hrp.Position)))) end
                                CreateESP(plr.Character, textName, { name = nText, infoRich = table.concat(infoParts, " · "), color = c, nameColor = ESPColors.Name, infoColor = ESPColors.Distance, offsetY = 4 })
            else
                for _, objName in ipairs({ hlName, textName }) do local obj = plr.Character:FindFirstChild(objName); if obj then obj:Destroy() end end
            end
        end
    end
end

local function updateStaticESP()
    if not ESP.Master then return end
    if ESP.Generator then
        for _, gen in ipairs(MapData.Generators) do
            if gen.model and gen.model.Parent then
                local prog = gen.model:GetAttribute("RepairProgress") or 0
                local pct = math.clamp(math.floor(prog), 0, 100)
                local c = ESPColors.Generator:Lerp(ESPColors.GeneratorDone, pct / 100)
                local hl = gen.model:FindFirstChild("GEH")
                if not hl then hl = Instance.new("Highlight"); hl.Name = "GEH"; hl.Parent = gen.model end
                hl.FillColor = c; hl.OutlineColor = c; hl.FillTransparency = ESP.Outline and 1 or 0.5; hl.OutlineTransparency = 0
                if ESP.GeneratorName and gen.part then
                    local txt = pct >= 100 and "DONE" or string.format("%d%%", pct)
                    CreateESP(gen.part, "GE_Text", { name = "GEN", infoRich = string.format("<font color='#FF8000'>%s</font>", txt), color = ESPColors.Generator, offsetY = gen.part.Size.Y / 2 + 1 })
                end
            end
        end
    end
end

local function ClearAllESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            for _, n in ipairs({ "KEH", "PEH", "KE_Text", "PE_Text" }) do
                local o = plr.Character:FindFirstChild(n)
                if o then o:Destroy() end
            end
        end
    end
    for _, gen in ipairs(MapData.Generators) do
        if gen.model then
            local hl = gen.model:FindFirstChild("GEH")
            if hl then hl:Destroy() end
        end
        if gen.part then
            local tag = gen.part:FindFirstChild("GE_Text")
            if tag then tag:Destroy() end
        end
    end
end

local espRescan = nil
local function startESPLoop()
    if espConn then espConn:Disconnect() end
    espConn = RunService.Heartbeat:Connect(function()
        updatePlayerESP()
        updateStaticESP()
    end)
    if not espRescan then
        espRescan = task.spawn(function()
            while ESP.Master do
                task.wait(8)
                ScanMap(true)
            end
            espRescan = nil
        end)
    end
end

-- ============================================================
-- PISTOL SILENT AIM TOF (TIANHUB CORE)
-- ============================================================
-- TIANHUB SILENT AIM TOF: replacement backend integrated into TianHub.
do
    local W = getgenv()
    local PlayersSvc = game:GetService("Players")
    local RunSvc = game:GetService("RunService")
    local RSvc = game:GetService("ReplicatedStorage")
    local lp = PlayersSvc.LocalPlayer

    local CONFIG = {
        FOV_DEFAULT = 120,
        FOV_MIN = 10,
        FOV_MAX = 360,
        TARGET_PRIORITY = {"UpperTorso", "Torso"},
        BULLET_SPEED = 800,
        PREDICT_ITERATIONS = 3,
    }
    local State = {
        Enabled = false,
        PredictMove = false,
        ShowFOV = true,
        FOV = CONFIG.FOV_DEFAULT,
        Killer = nil,
        KillerChar = nil,
        SkinModel = nil,
        Original = nil,
        Effects = nil,
        Circle = nil,
        CircleStroke = nil,
        CircleGui = nil,
        ShowLaser = false,
        LaserPart0 = nil,
        LaserPart1 = nil,
        LaserBeam = nil,
        LaserLastAim = 0,
        Render = nil,
    }

    local function getTargetPart(character)
        if not character then return nil end
        for _, name in ipairs(CONFIG.TARGET_PRIORITY) do
            local part = character:FindFirstChild(name)
            if part and part:IsA("BasePart") then return part end
        end
        return nil
    end

    local function findKiller()
        for _, player in ipairs(PlayersSvc:GetPlayers()) do
            if player ~= lp and player.Character
                and player.Character:FindFirstChild("Lookscriptkiller", true) then
                return player
            end
        end
        return nil
    end

    local function detectSkin()
        local character = lp.Character
        local tool = character and character:FindFirstChild("Twist of Fate")
        local arm = tool and tool:FindFirstChild("Right Arm")
        if arm then
            for _, child in ipairs(arm:GetChildren()) do
                if child:IsA("Model") then return child end
            end
        end
        return nil
    end

    local function getMuzzlePosition(character)
        local skin = State.SkinModel
        if skin then
            for _, name in ipairs({"SmokePart", "barrel"}) do
                local part = skin:FindFirstChild(name, true)
                if part and part:IsA("BasePart") then return part.Position end
            end
            if skin.PrimaryPart then return skin.PrimaryPart.Position end
        end
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then
            return (root.CFrame * CFrame.new(0.7, 1.373, -2.5)).Position
        end
        return nil
    end

    local function predictPosition(killerCharacter, muzzlePosition)
        local targetPart = getTargetPart(killerCharacter)
        if not targetPart then return nil end
        local root = killerCharacter:FindFirstChild("HumanoidRootPart")
        if not root then return targetPart.Position end
        local velocity = root.AssemblyLinearVelocity
        if velocity.Magnitude < 1 then return targetPart.Position end

        local currentPosition = targetPart.Position
        local timeToHit = (currentPosition - muzzlePosition).Magnitude / CONFIG.BULLET_SPEED
        local predictedPosition = currentPosition
        for _ = 1, CONFIG.PREDICT_ITERATIONS do
            predictedPosition = currentPosition + velocity * timeToHit
            timeToHit = (predictedPosition - muzzlePosition).Magnitude / CONFIG.BULLET_SPEED
        end
        return predictedPosition
    end

    local function getEffectiveTargetPosition(muzzlePosition)
        local part = getTargetPart(State.KillerChar)
        if not part then return nil end
        if State.PredictMove then
            return predictPosition(State.KillerChar, muzzlePosition)
        end
        return part.Position
    end

    local function isInFOV(position)
        local camera = workspace.CurrentCamera
        if not camera then return false end
        local delta = position - camera.CFrame.Position
        if delta.Magnitude < 0.1 then return true end
        local dot = math.clamp(camera.CFrame.LookVector:Dot(delta.Unit), -1, 1)
        local angle = math.deg(math.acos(dot))
        return angle <= State.FOV / 2
    end

    local function isBlocked(origin, targetPosition)
        local direction = targetPosition - origin
        if direction.Magnitude < 0.1 then return false end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        local exclude = {}
        for _, player in ipairs(PlayersSvc:GetPlayers()) do
            if player.Character then table.insert(exclude, player.Character) end
        end
        if State.SkinModel then table.insert(exclude, State.SkinModel) end
        params.FilterDescendantsInstances = exclude
        return workspace:Raycast(origin, direction, params) ~= nil
    end

    local function ensureCircle()
        if State.Circle and State.Circle.Parent then return end
        local parent
        local ok, hui = pcall(function()
            if type(gethui) == "function" then return gethui() end
        end)
        if ok and hui then
            parent = hui
        else
            parent = lp:WaitForChild("PlayerGui")
        end

        local old = parent:FindFirstChild("TianHub_ToF_FOV")
        if old then old:Destroy() end
        local gui = Instance.new("ScreenGui")
        gui.Name = "TianHub_ToF_FOV"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = parent

        local circle = Instance.new("Frame")
        circle.Name = "FOVCircle"
        circle.AnchorPoint = Vector2.new(0.5, 0.5)
        circle.Position = UDim2.fromScale(0.5, 0.5)
        circle.Size = UDim2.fromOffset(State.FOV * 2, State.FOV * 2)
        circle.BackgroundTransparency = 1
        circle.BorderSizePixel = 0
        circle.Visible = false
        circle.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = circle
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(168, 85, 247)
        stroke.Thickness = 2
        stroke.Transparency = 0.15
        stroke.Parent = circle

        State.Circle, State.CircleStroke, State.CircleGui = circle, stroke, gui
    end

    local function ensureAimLaser()
        if State.LaserBeam and State.LaserBeam.Parent then return end
        -- Beam anchors must live in Workspace to render in the 3D world.
        local parent = workspace
        local folder = parent:FindFirstChild("TianHub_ToF_AimLaser")
        if folder then folder:Destroy() end
        folder = Instance.new("Folder")
        folder.Name = "TianHub_ToF_AimLaser"
        folder.Parent = parent

        local function makeAnchor(name)
            local part = Instance.new("Part")
            part.Name = name
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Transparency = 1
            part.Size = Vector3.new(0.05, 0.05, 0.05)
            part.Parent = folder
            local attachment = Instance.new("Attachment")
            attachment.Parent = part
            return part, attachment
        end

        local p0, a0 = makeAnchor("Origin")
        local p1, a1 = makeAnchor("Target")
        local beam = Instance.new("Beam")
        beam.Name = "AimLaserBeam"
        beam.Attachment0 = a0
        beam.Attachment1 = a1
        beam.FaceCamera = true
        beam.LightEmission = 1
        beam.LightInfluence = 0
        beam.Width0 = 0.075
        beam.Width1 = 0.035
        beam.Color = ColorSequence.new(Color3.fromRGB(168, 85, 247))
        beam.Transparency = NumberSequence.new(0.08)
        beam.Enabled = false
        beam.Parent = folder

        State.LaserPart0 = p0
        State.LaserPart1 = p1
        State.LaserBeam = beam
    end

    local function updateAimLaser(origin, targetPosition)
        if not State.ShowLaser or not State.Enabled or not origin or not targetPosition then
            if State.LaserBeam then State.LaserBeam.Enabled = false end
            return
        end
        ensureAimLaser()
        if not State.LaserPart0 or not State.LaserPart1 or not State.LaserBeam then return end
        State.LaserPart0.Position = origin
        State.LaserPart1.Position = targetPosition
        State.LaserLastAim = os.clock()
        State.LaserBeam.Enabled = true
    end

    local function hideAimLaser()
        if State.LaserBeam then State.LaserBeam.Enabled = false end
    end

    local function installHook()
        if State.Original then return true end
        local ok, moduleOrError = pcall(function()
            local module = RSvc:WaitForChild("Modules")
                :WaitForChild("Items")
                :WaitForChild("TwistOfFate")
                :WaitForChild("TwistoffateEffects")
            return require(module)
        end)
        if not ok or type(moduleOrError) ~= "table"
            or type(moduleOrError.aimDirection) ~= "function" then
            return false
        end

        State.Effects = moduleOrError
        State.Original = moduleOrError.aimDirection
        moduleOrError.aimDirection = function(character, cameraCFrame)
            if not State.Enabled then
                return State.Original(character, cameraCFrame)
            end
            local origin = getMuzzlePosition(character)
            if not origin then
                hideAimLaser()
                return State.Original(character, cameraCFrame)
            end
            local targetPosition = getEffectiveTargetPosition(origin)
            if not targetPosition or not isInFOV(targetPosition) then
                hideAimLaser()
                return State.Original(character, cameraCFrame)
            end
            updateAimLaser(origin, targetPosition)
            local direction = targetPosition - origin
            if direction.Magnitude < 0.01 then
                return State.Original(character, cameraCFrame)
            end
            return direction.Unit
        end
        return true
    end

    local function setEnabled(value)
        State.Enabled = value == true
        if State.Enabled then
            if not installHook() then
                State.Enabled = false
                return false
            end
            State.SkinModel = detectSkin()
            ensureCircle()
        else
            if State.Circle then State.Circle.Visible = false end
            hideAimLaser()
        end
        return true
    end

    if not State.Render then
        State.Render = RunSvc.RenderStepped:Connect(function()
            if not State.Enabled then
                if State.Circle then State.Circle.Visible = false end
                hideAimLaser()
                return
            end
            if State.LaserBeam and State.LaserBeam.Enabled
                and os.clock() - (State.LaserLastAim or 0) > 0.14 then
                hideAimLaser()
            end

            State.Killer = findKiller()
            State.KillerChar = State.Killer and State.Killer.Character or nil
            if not State.SkinModel then State.SkinModel = detectSkin() end
            if not State.Circle then ensureCircle() end

            local camera = workspace.CurrentCamera
            if camera and State.Circle then
                State.Circle.Position = UDim2.fromOffset(
                    camera.ViewportSize.X / 2,
                    camera.ViewportSize.Y / 2
                )
                State.Circle.Size = UDim2.fromOffset(State.FOV * 2, State.FOV * 2)
                State.Circle.Visible = State.ShowFOV
            end

            local origin = getMuzzlePosition(lp.Character)
            local targetPosition = origin and getEffectiveTargetPosition(origin)
            if targetPosition and origin and State.CircleStroke then
                State.CircleStroke.Color = Color3.fromRGB(168, 85, 247)
            elseif State.CircleStroke then
                State.CircleStroke.Color = Color3.fromRGB(168, 85, 247)
            end
        end)
    end

    local api = { setEnabled = setEnabled }
    function api.setPredict(value) State.PredictMove = value == true end
    function api.setLead(value) State.PredictMove = value == true end
    function api.setFOV(value)
        State.FOV = math.clamp(tonumber(value) or CONFIG.FOV_DEFAULT, CONFIG.FOV_MIN, CONFIG.FOV_MAX)
    end
    function api.setRadius(value) api.setFOV(value) end
    function api.setShowFOV(value)
        State.ShowFOV = value == true
        if State.Circle then State.Circle.Visible = State.Enabled and State.ShowFOV end
    end
    function api.setShowLaser(value)
        State.ShowLaser = value == true
        if not State.ShowLaser then hideAimLaser() end
    end
    W.TianHub_TOF = api
    W.TianHub_ToFPeekTarget = function()
        local player = State.Killer
        return player and {
            held = true,
            player = player,
            char = player.Character,
            kind = "Killer",
            part = getTargetPart(player.Character),
        } or nil
    end
end

-- ============================================================
-- TIANHUB SILENT VEIL SPEAR AIM (ORIGINAL BACKEND)
-- Backend copied from TianHub_Instant_Fixed_Updated.lua; HanxHub UI adapter below.
-- ============================================================
do
    local W = getgenv()
    -- TianHub Spear backend: embedded spear backend, retained unchanged.
    if type(_G.KinonSilentSpearStandaloneUnload) == "function" then
        pcall(_G.KinonSilentSpearStandaloneUnload)
    end

    do
        local Players          = game:GetService("Players")
        local UserInputService = game:GetService("UserInputService")
        local RunService       = game:GetService("RunService")
        local ReplicatedStorage= game:GetService("ReplicatedStorage")

        local LP = Players.LocalPlayer
        local HUB_NAME = "TianHub"

        local G = (getgenv and getgenv()) or _G
        local V = G.KinonSilentSpearV4 or { Installed = {} }
        G.KinonSilentSpearV4 = V
        V.Installed = V.Installed or {}

        V.Enabled    = false
        V.FOV        = 240
        V.MaxRange   = 500
        V.FovAim     = true
        V.ShowAimFOV = true
        V.SpearSpeed = 180
        V.Drop       = 0.5
        V.Predict    = true
        V.Visuals    = true
        V.Priority   = "Nearest"
        V.Dead       = false

        V.CurPart, V.CurPoint, V.CurOrigin = nil, nil, nil
        V.TargetChar = nil

        local BAL = {
            SpawnOffset    = 3,
            MinChargeTime  = 0.3,
            FullChargeTime = 1,
            YVelClamp      = 14,
            VelMagCap      = 32,
        }

        local wrap = newcclosure or function(f) return f end

        local function getGravity()
            local g = math.max(0, tonumber(workspace.Gravity) or 196.2)
            return Vector3.new(0, -g * math.clamp(tonumber(V.Drop) or 0.5, 0, 1), 0)
        end

        local function getPingHalf()
            local ok, ping = pcall(function() return LP:GetNetworkPing() end)
            if ok and type(ping) == "number" and ping > 0 then
                return math.clamp(ping * 0.5, 0, 0.25)
            end
            return 0.035
        end

        local function clampVelY(v)
            return Vector3.new(v.X, math.clamp(v.Y, -BAL.YVelClamp, BAL.YVelClamp), v.Z)
        end

        local function isKillerTeam(char)
            local plr = Players:GetPlayerFromCharacter(char)
            if plr and plr.Team and plr.Team.Name == "Killer" then return true end
            if char:GetAttribute("Role") == "Killer" then return true end
            if char:GetAttribute("IsKiller") == true then return true end
            return false
        end

        local function isSpearActive(char)
            if not char then return false end
            local morph = char:GetAttribute("MorphedKiller")
            if morph == "Veil" or char:GetAttribute("Veil") == true then return true end
            if char:GetAttribute("spearmode") == true then return true end
            if char:GetAttribute("VeilSpearEquipped") == true then return true end
            local spear = char:FindFirstChild("Spear")
            if spear then
                local inner = spear:FindFirstChild("Spear")
                if inner and inner:IsA("BasePart") then return inner.Transparency < 0.5 end
                return true
            end
            return false
        end

        local function isAuraMode(char)
            if not char then return false end
            if char:GetAttribute("special") == true or char:GetAttribute("Aura") == true then return true end
            return char:FindFirstChild("Aura") ~= nil
        end

        local velCache = setmetatable({}, { __mode = "k" })

        local function getSmoothedVelocity(char, hrp)
            local now = tick()
            local c = velCache[char]
            local raw
            if c and c.lastPos and now - c.time > 0.001 and now - c.time < 0.5 then
                raw = (hrp.Position - c.lastPos) / (now - c.time)
                local live = hrp.AssemblyLinearVelocity or Vector3.zero
                if raw.Magnitude > 60 then raw = live end
                local smoothed = c.velocity:Lerp(raw, 0.5)
                if smoothed.Magnitude > BAL.VelMagCap then
                    smoothed = smoothed.Unit * BAL.VelMagCap
                end
                velCache[char] = { velocity = smoothed, time = now, lastPos = hrp.Position }
                return smoothed
            end
            raw = hrp.AssemblyLinearVelocity or Vector3.zero
            if raw.Magnitude > BAL.VelMagCap then raw = raw.Unit * BAL.VelMagCap end
            velCache[char] = { velocity = raw, time = now, lastPos = hrp.Position }
            return raw
        end

        local tracker = { char = nil, samples = {} }

        local function trackTarget(char, hrp)
            local now = os.clock()
            if tracker.char ~= char then tracker.char, tracker.samples = char, {} end
            local smp = tracker.samples
            smp[#smp + 1] = { t = now, p = hrp.Position }
            while #smp > 2 and now - smp[1].t > 0.32 do table.remove(smp, 1) end
        end

        local function windowVelocity(smp, window)
            local last = smp[#smp]
            local first = smp[1]
            for i = #smp, 1, -1 do
                if last.t - smp[i].t >= window then first = smp[i]; break end
            end
            local dt = last.t - first.t
            if dt < 0.04 then return nil end
            return (last.p - first.p) / dt
        end

        local function estimateVelocity(char, hrp)
            local live = hrp.AssemblyLinearVelocity or Vector3.zero
            local liveFlat = Vector3.new(live.X, 0, live.Z)
            local smp = tracker.samples
            if tracker.char == char and #smp >= 4 then
                local vLong  = windowVelocity(smp, 0.30)
                local vShort = windowVelocity(smp, 0.14)
                local vNow   = windowVelocity(smp, 0.10) or vShort
                if vLong and vShort and vNow then
                    local flatLong  = Vector3.new(vLong.X, 0, vLong.Z)
                    local flatShort = Vector3.new(vShort.X, 0, vShort.Z)
                    local flatNow   = Vector3.new(vNow.X, 0, vNow.Z)

                    local noInput = false
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() noInput = hum.MoveDirection.Magnitude < 0.05 end) end

                    local vel
                    if flatNow.Magnitude < 1.2 and liveFlat.Magnitude < 2 then
                        vel = Vector3.zero
                    elseif noInput and flatShort.Magnitude < 4 and liveFlat.Magnitude < 4 then
                        vel = Vector3.zero
                    elseif flatShort.Magnitude < flatLong.Magnitude * 0.45
                        and liveFlat.Magnitude < flatLong.Magnitude * 0.6 then
                        vel = (vNow + live) * 0.5
                    else
                        local cosA = 1
                        if flatLong.Magnitude > 1 and flatShort.Magnitude > 1 then
                            cosA = flatLong.Unit:Dot(flatShort.Unit)
                        end
                        if cosA < 0.5 and liveFlat.Magnitude > 1
                            and flatShort.Unit:Dot(liveFlat.Unit) > 0.5 then
                            vel = (vNow + live) * 0.5
                        else
                            vel = vLong * 0.3 + vShort * 0.7
                            if liveFlat.Magnitude > 2 then vel = vel * 0.6 + live * 0.4 end
                        end
                    end
                    if vel.Magnitude > BAL.VelMagCap then vel = vel.Unit * BAL.VelMagCap end
                    return vel
                end
            end
            local v = live
            if v.Magnitude > BAL.VelMagCap then v = v.Unit * BAL.VelMagCap end
            return v
        end

        local function solveThrow(targetChar, origin, chargeTime)
            local hrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            if not hrp then return nil end

            local dist = (hrp.Position - origin).Magnitude
            local far = math.clamp((dist - 40) / 40, 0, 1)
            local sliderSpeed = math.clamp(tonumber(V.SpearSpeed) or 180, 60, 180)
            local farSpeed = math.min(isAuraMode(LP.Character) and 170 or 150, sliderSpeed)
            local maxSpeed = sliderSpeed + (farSpeed - sliderSpeed) * far
            local leadMul = 0.85 + (1.5 - 0.85) * far
            local speed = math.clamp((chargeTime or BAL.FullChargeTime) * maxSpeed, 1, maxSpeed)
            local gravity = getGravity()
            local gMag = math.abs(gravity.Y)
            local halfPing = getPingHalf() + 0.03 + 0.13 * far

            local aimTarget = hrp.Position + Vector3.new(0, 0.2, 0)
            if dist > 100 then
                local head = targetChar:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    aimTarget = head.Position
                end
            end
            local vel = clampVelY(estimateVelocity(targetChar, hrp)) * leadMul
            if V.Predict == false then vel = Vector3.zero end

            local delta0 = (aimTarget + vel * halfPing) - origin
            local t = math.max(0.04, delta0.Magnitude / speed)

            local reachable = true
            for _ = 1, 8 do
                local leadPos = aimTarget + vel * (t + halfPing)
                local d = leadPos - origin
                local dxz = Vector3.new(d.X, 0, d.Z).Magnitude
                local dy = d.Y
                local a = 0.25 * gMag * gMag
                local b = dy * gMag - speed * speed
                local c = dxz * dxz + dy * dy
                local disc = b * b - 4 * a * c
                if gMag < 0.001 then
                    t = math.max(0.04, d.Magnitude / speed)
                elseif disc >= 0 then
                    local t2 = (-b - math.sqrt(disc)) / (2 * a)
                    if t2 > 0 then t = math.sqrt(t2)
                    else t = math.max(0.04, d.Magnitude / speed) end
                else
                    reachable = false
                    t = math.max(0.04, d.Magnitude / speed)
                    break
                end
            end

            local finalLead = aimTarget + vel * (t + halfPing)
            local delta = finalLead - origin

            if not reachable and gMag > 0.001 then
                local flat = Vector3.new(delta.X, 0, delta.Z)
                local horiz = flat.Magnitude > 1e-3 and flat.Unit or Vector3.new(0, 0, -1)
                local root = speed * speed - 2 * gMag * delta.Y
                local ang = root > 0 and math.atan(speed / math.sqrt(root)) or math.rad(45)
                local dirv = (horiz * math.cos(ang) + Vector3.new(0, math.sin(ang), 0)).Unit
                return dirv, dirv * speed, speed, finalLead
            end
            local launchVel = (delta - 0.5 * gravity * t * t) / t
            return launchVel.Unit, launchVel, speed, finalLead
        end

        local function candidates()
            local list = {}
            local camera = workspace.CurrentCamera
            if not camera then return list end
            local center = camera.ViewportSize / 2
            local myChar = LP.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return list end

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character and plr.Character ~= myChar then
                    local char = plr.Character
                    if not isKillerTeam(char) then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hum and hum.Health > 0 and hrp
                            and not char:GetAttribute("Immobile")
                            and not char:GetAttribute("IsHooked")
                            and not char:GetAttribute("Knocked") then
                            local dist = (hrp.Position - myHRP.Position).Magnitude
                            if dist <= V.MaxRange then
                                local s, onScreen = camera:WorldToViewportPoint(hrp.Position)
                                if onScreen and s.Z > 0 then
                                    local px = (Vector2.new(s.X, s.Y) - center).Magnitude
                                    if (not V.FovAim) or px <= V.FOV then
                                        table.insert(list, {
                                            char = char, hrp = hrp, hum = hum,
                                            px = px, dist = dist,
                                            health = hum.Health,
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return list
        end

        local function pick(list)
            if #list == 0 then return nil end
            local priority = tostring(V.Priority or "Nearest")
            if priority == "Furthest" then
                table.sort(list, function(a, b) return a.dist > b.dist end)
            elseif priority == "Injured" or priority == "NearestInjured" then
                table.sort(list, function(a, b)
                    if a.health ~= b.health then return a.health < b.health end
                    return a.dist < b.dist
                end)
            elseif priority == "Healed" or priority == "NearestHealed" then
                table.sort(list, function(a, b)
                    if a.health ~= b.health then return a.health > b.health end
                    return a.dist < b.dist
                end)
            elseif priority == "FurthestInjured" then
                table.sort(list, function(a, b)
                    if a.health ~= b.health then return a.health < b.health end
                    return a.dist > b.dist
                end)
            elseif priority == "FurthestHealed" then
                table.sort(list, function(a, b)
                    if a.health ~= b.health then return a.health > b.health end
                    return a.dist > b.dist
                end)
            else -- Nearest (default)
                table.sort(list, function(a, b) return a.dist < b.dist end)
            end
            return list[1]
        end

        local endAttackCache, endAttackAnims, endAttackSearched = nil, nil, false

        local function ensureChargeFn()
            local char = LP.Character
            local anims = char and char:FindFirstChild("Animations")
            if not anims then return end
            if type(getgc) ~= "function" or type(getupvalues) ~= "function" then return end
            if endAttackAnims ~= anims then
                endAttackAnims, endAttackCache, endAttackSearched = anims, nil, false
            end
            if endAttackCache or endAttackSearched then return end
            endAttackSearched = true
            pcall(function()
                for _, fn in ipairs(getgc()) do
                    if type(fn) == "function" and (not islclosure or islclosure(fn)) then
                        if debug.info(fn, "n") == "endAttack" and getfenv(fn).script == anims then
                            endAttackCache = fn
                            break
                        end
                    end
                end
            end)
        end

        local function getChargeTime()
            if not endAttackCache then return BAL.FullChargeTime end
            local ok, ups = pcall(getupvalues, endAttackCache)
            if ok and ups then
                local isThrown = ups[2] == true
                local startTime = tonumber(ups[9]) or 0
                if isThrown and startTime > 0 then
                    return math.max(BAL.MinChargeTime, workspace:GetServerTimeNow() - startTime)
                end
            end
            return BAL.FullChargeTime
        end

        task.spawn(function()
            while not V.Dead do
                if V.Enabled then pcall(ensureChargeFn) end
                task.wait(0.5)
            end
        end)

        local viewDelayFn = nil
        task.spawn(function()
            for _ = 1, 40 do
                if V.Dead or viewDelayFn then return end
                pcall(function()
                    local mods = ReplicatedStorage:FindFirstChild("Modules")
                    local world = mods and mods:FindFirstChild("World")
                    local vis = world and world:FindFirstChild("ProjectileVisualsClient")
                    if vis and vis:IsA("ModuleScript") then
                        local m = require(vis)
                        if m and type(m.viewDelay) == "function" then viewDelayFn = m.viewDelay end
                    end
                end)
                task.wait(0.25)
            end
        end)

        local TRAIL_LIFETIME = 1.5
        local function showTrail(origin, dir, speed)
            if not V.Visuals then return end
            if typeof(origin) ~= "Vector3" or typeof(dir) ~= "Vector3" or dir.Magnitude < 0.01 then return end
            speed = tonumber(speed) or 180
            task.spawn(function()
                local gravity = getGravity()
                local v0 = dir.Unit * speed
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                local ignore = {}
                if LP.Character then table.insert(ignore, LP.Character) end
                params.FilterDescendantsInstances = ignore

                local points = { origin }
                local prev = origin
                local steps, dt = 48, 0.035
                for i = 1, steps do
                    local tt = i * dt
                    local nxt = origin + v0 * tt + 0.5 * gravity * tt * tt
                    local delta = nxt - prev
                    local stop = false
                    if delta.Magnitude > 0.01 then
                        local hit = workspace:Raycast(prev, delta, params)
                        if hit then nxt = hit.Position; stop = true end
                    end
                    table.insert(points, nxt)
                    prev = nxt
                    if stop then break end
                end
                if #points < 2 then return end

                local folder = Instance.new("Folder")
                folder.Name = "KINON_SpearTrail"
                folder.Parent = workspace
                local terrain = workspace.Terrain
                local atts, beams = {}, {}
                for i, pt in ipairs(points) do
                    local a = Instance.new("Attachment")
                    a.Parent = terrain
                    a.WorldPosition = pt
                    atts[i] = a
                end
                local n = #points - 1
                for i = 1, n do
                    local beam = Instance.new("Beam")
                    beam.Attachment0, beam.Attachment1 = atts[i], atts[i + 1]
                    beam.Color = ColorSequence.new(Color3.fromRGB(168, 85, 247))
                    beam.LightEmission = 1
                    beam.LightInfluence = 0
                    beam.FaceCamera = true
                    beam.Segments = 1
                    beam.Width0 = 0.5 * (1 - 0.5 * (i - 1) / n)
                    beam.Width1 = 0.5 * (1 - 0.5 * i / n)
                    beam.Transparency = NumberSequence.new(0.05)
                    beam.Parent = folder
                    beams[i] = beam
                end
                local start = os.clock()
                while folder.Parent and not V.Dead do
                    local alpha = (os.clock() - start) / TRAIL_LIFETIME
                    if alpha >= 1 then break end
                    local seq = NumberSequence.new(0.05 + alpha * 0.95)
                    for _, beam in ipairs(beams) do beam.Transparency = seq end
                    RunService.Heartbeat:Wait()
                end
                if folder.Parent then folder:Destroy() end
                for _, a in ipairs(atts) do a:Destroy() end
            end)
        end

        local function applyPayload(payload, origin, dir, speed)
            payload.Origin = origin
            payload.Direction = dir
            if payload.Velocity ~= nil then payload.Velocity = dir * speed end
            if viewDelayFn then
                pcall(function() payload.ViewDelay = viewDelayFn(origin, dir) end)
            end
        end

        V.NamecallHandler = function(old, self, ...)
            local method = getnamecallmethod()
            if not V.Enabled or (method ~= "FireServer" and method ~= "fireServer") then
                return old(self, ...)
            end
            local isSpear = false
            pcall(function()
                isSpear = typeof(self) == "Instance" and string.lower(self.Name) == "spearthrow"
            end)
            if not isSpear then
                if setnamecallmethod then pcall(setnamecallmethod, method) end
                return old(self, ...)
            end
            if checkcaller and checkcaller() then
                if setnamecallmethod then pcall(setnamecallmethod, method) end
                return old(self, ...)
            end

            local args = table.pack(...)
            local trailOrigin, trailDir, trailSpeed

            pcall(function()
                local char = LP.Character
                if not char or not isSpearActive(char) then return end
                local camera = workspace.CurrentCamera
                if not camera then return end
                local payload = type(args[1]) == "table" and args[1] or nil

                local origin
                if payload and typeof(payload.Origin) == "Vector3" then
                    origin = payload.Origin
                elseif typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
                    origin = args[1]
                else
                    origin = camera.CFrame.Position + camera.CFrame.LookVector * BAL.SpawnOffset
                end

                local charge = getChargeTime()
                local target = V.TargetChar
                local redirected = false

                if target and target.Parent then
                    local dir, _, speed = solveThrow(target, origin, charge)
                    if dir then
                        trailOrigin, trailDir, trailSpeed = origin, dir, speed
                        if payload then
                            local ok = pcall(applyPayload, payload, origin, dir, speed)
                            if ok then redirected = true
                            else
                                local clone = table.clone and table.clone(payload) or nil
                                if clone and pcall(applyPayload, clone, origin, dir, speed) then
                                    args[1] = clone
                                    redirected = true
                                end
                            end
                        elseif typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
                            args[1], args[2] = origin, dir
                            redirected = true
                        elseif typeof(args[1]) == "Vector3" then
                            args[1] = dir
                            redirected = true
                        end
                    end
                end

                if not redirected then
                    trailOrigin, trailDir, trailSpeed = nil, nil, nil
                    if payload and typeof(payload.Direction) == "Vector3" then
                        trailOrigin = origin
                        trailDir = payload.Direction
                        trailSpeed = typeof(payload.Velocity) == "Vector3" and payload.Velocity.Magnitude
                            or math.clamp(charge * (tonumber(V.SpearSpeed) or 180), 1, 180)
                    elseif typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
                        trailOrigin, trailDir = args[1], args[2]
                        trailSpeed = math.clamp(charge * (tonumber(V.SpearSpeed) or 180), 1, 180)
                    end
                end
            end)

            if setnamecallmethod then pcall(setnamecallmethod, method) end
            if setnamecallmethod then pcall(setnamecallmethod, method) end
            local ret = old(self, unpack(args, 1, args.n))
            if trailOrigin then task.defer(showTrail, trailOrigin, trailDir, trailSpeed) end
            return ret
        end

        -- Reactive target visual: intense solid-red body highlight only; no label and no FOV ring.
        local TARGET_COLOR = Color3.fromRGB(255, 0, 0)
        local targetHighlight = Instance.new("Highlight")

        -- Purple FOV visual for Silent Veil (visual only; aim logic/settings stay unchanged).
        local veilFovGui = Instance.new("ScreenGui")
        veilFovGui.Name = "TianHub_SilentVeil_FOV"
        veilFovGui.ResetOnSpawn = false
        veilFovGui.IgnoreGuiInset = true
        veilFovGui.DisplayOrder = 20
        pcall(function() veilFovGui.Parent = game:GetService("CoreGui") end)
        if not veilFovGui.Parent then
            veilFovGui.Parent = LP:WaitForChild("PlayerGui")
        end

        local function makeFovRing(name, thickness, transparency, extra)
            local ring = Instance.new("Frame")
            ring.Name = name
            ring.AnchorPoint = Vector2.new(0.5, 0.5)
            ring.Position = UDim2.fromScale(0.5, 0.5)
            ring.Size = UDim2.fromOffset(480 + extra, 480 + extra)
            ring.BackgroundTransparency = 1
            ring.BorderSizePixel = 0
            ring.Visible = false
            ring.Parent = veilFovGui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = ring

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(168, 85, 247)
            stroke.Thickness = thickness
            stroke.Transparency = transparency
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Parent = ring
            return ring
        end

        local veilFovRing = makeFovRing("FOV_Ring", 2, 0.05, 0)
        local function updateVeilFov()
            local camera = workspace.CurrentCamera
            local show = V.Enabled == true and V.ShowAimFOV == true and camera ~= nil
            veilFovRing.Visible = show
            if show then
                local viewport = camera.ViewportSize
                local diameter = math.clamp(tonumber(V.FOV) or 240, 30, 600) * 2
                veilFovRing.Position = UDim2.fromOffset(viewport.X * 0.5, viewport.Y * 0.5)
                veilFovRing.Size = UDim2.fromOffset(diameter, diameter)
            end
        end
        targetHighlight.Name = "KINON_VeilTargetHighlight"
        targetHighlight.Enabled = false
        targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        targetHighlight.FillColor = TARGET_COLOR
        targetHighlight.OutlineColor = TARGET_COLOR
        targetHighlight.FillTransparency = 0.12
        targetHighlight.OutlineTransparency = 0

        local function hideVisuals()
            pcall(function()
                targetHighlight.Enabled = false
                targetHighlight.Adornee = nil
                targetHighlight.Parent = nil
            end)
        end

        V.DestroyEsp = function()
            V.TargetChar = nil
            V.CurPart, V.CurPoint, V.CurOrigin = nil, nil, nil
            hideVisuals()
            tracker.char, tracker.samples = nil, {}
        end

        V.RenderConn = RunService.RenderStepped:Connect(function()
            updateVeilFov()
            if V.Dead or not V.Enabled then
                if V.TargetChar or targetHighlight.Enabled then V.DestroyEsp() end
                return
            end

            local t = pick(candidates())
            local nowC = os.clock()
            if t then
                V.LastT, V.LastSeen = t, nowC
            elseif V.LastT and nowC - (V.LastSeen or 0) < 0.3 then
                local lt = V.LastT
                local lh = lt.hum
                if lt.hrp and lt.hrp.Parent and lh and lh.Parent and lh.Health > 0 then t = lt end
            end
            V.TargetChar = t and t.char or nil
            V.CurPart = t and t.hrp or nil

            if not (LP.Team and LP.Team.Name == "Killer") then
                hideVisuals()
                return
            end

            if V.TargetChar and V.Visuals and t and t.px <= (tonumber(V.FOV) or 240) then
                local hrp = t.hrp
                trackTarget(V.TargetChar, hrp)

                if targetHighlight.Adornee ~= V.TargetChar or targetHighlight.Parent ~= V.TargetChar then
                    targetHighlight.Parent = V.TargetChar
                    targetHighlight.Adornee = V.TargetChar
                end
                targetHighlight.Enabled = true
            else
                hideVisuals()
                tracker.char, tracker.samples = nil, {}
            end
        end)

        if not V.Installed.namecall and hookmetamethod and getnamecallmethod then
            pcall(function()
                local old
                old = hookmetamethod(game, "__namecall", wrap(function(self, ...)
                    local handler = V.NamecallHandler
                    if handler then return handler(old, self, ...) end
                    return old(self, ...)
                end))
                V._OldNamecall = old
                V.Installed.namecall = true
            end)
        end
        V.HookOk = V.Installed.namecall == true
        if not V.HookOk then
            warn("[" .. HUB_NAME .. "] hookmetamethod/getnamecallmethod unavailable.")
        end

        local toggleConn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == Enum.KeyCode.RightShift then
                V.Enabled = not V.Enabled
                print(string.format("[%s] %s", HUB_NAME, V.Enabled and "ENABLED" or "DISABLED"))
            end
        end)

        local function unload()
            if V.Dead then return end
            V.Dead = true
            V.Enabled = false
            if V.RenderConn then pcall(function() V.RenderConn:Disconnect() end); V.RenderConn = nil end
            if toggleConn then pcall(function() toggleConn:Disconnect() end); toggleConn = nil end
            pcall(function() targetHighlight:Destroy() end)
            pcall(function() veilFovGui:Destroy() end)
            if V._OldNamecall and hookmetamethod then
                pcall(function() hookmetamethod(game, "__namecall", V._OldNamecall) end)
                V._OldNamecall = nil
            end
            V.TargetChar = nil
            V.CurPart, V.CurPoint, V.CurOrigin = nil, nil, nil
            if _G.KinonSilentSpearStandaloneUnload == unload then
                _G.KinonSilentSpearStandaloneUnload = nil
            end
        end
        _G.KinonSilentSpearStandaloneUnload = unload
    end

    -- TianHub UI adapter: keeps the existing Killer tab controls.
    do
        local G = (getgenv and getgenv()) or _G
        local V = G.KinonSilentSpearV4
        if V then
            -- Preserve the original Silent Veil defaults; the TianHub toggles remain runtime controls.
            local Settings = setmetatable({}, {
                __index = function(_, key)
                    local map = {
                        Enabled = V.Enabled,
                        FOVRadius = V.FOV,
                        ShowFOV = V.FovAim,
                        TargetHighlightEnabled = V.Visuals,
                        Priority = V.Priority or "Nearest",
                    }
                    return map[key]
                end,
                __newindex = function(_, key, value)
                    if key == "Enabled" then V.Enabled = value == true
                    elseif key == "FOVRadius" then V.FOV = math.clamp(tonumber(value) or 240, 30, 600)
                    elseif key == "ShowFOV" then V.FovAim = value == true
                    elseif key == "TargetHighlightEnabled" then V.Visuals = value == true
                    elseif key == "Priority" then V.Priority = tostring(value or "Nearest")
                    end
                end,
            })
            W.TianHubSilentVeilSettings = Settings
            W.KinonSilentSpearSettings = V
        end
    end -- end TianHub UI adapter
end

-- ============================================================
-- TIAN HUB AUTO PARRY V2
-- Animation tracking + ParryClient hook + fallback GUI/tool
-- Floating mobile button + CylinderHandleAdornment range circle
-- ============================================================
local AP
do
    local W = getgenv()
    local rawSpawn = task.spawn
    local CollectionService = game:GetService("CollectionService")
    local ProximityPromptService = game:GetService("ProximityPromptService")


    AP = {
        Enabled = false,
        Range = 14,
        FaceSensitivity = 10,
        AggressiveMode = false,
        CircleVisible = false,
        RangeColor = Color3.fromRGB(255, 255, 255),
        Distance = 15,
        FaceBias = 10,
    }
    W.TianHub_AutoParry = AP


    local AttackSkip = {
        ["106871536134254"] = false,
        ["117070354890871"] = false,
        ["73681849513551"]  = false,
        ["100014992013740"] = false,
    }
    AP.AttackSkip = AttackSkip


    local LUNGE_IDS = {}
    for _, id in ipairs({
        "71008020992570","72742711718023","72908958549833","73923929500477","74968262036854",
        "75857500533792","76385865186777","76503974441748","77081789642514","78432063483146",
        "78935059863801","79935565590141","79965656177566","80411309607666","82666958311998",
        "83873880822918","84525330720658","85030641905220","89185525343404","92125118598365",
        "92362656727126","92554564590253","96839438835309","99472251587670","102055678391920",
        "104689417033027","105374834496520","109402730355822","111920872708571","112166042383605",
        "112633191985365","112840768179724","113255068724446","115244153053858","117042998468241",
        "117207742458428","118907603246885","119752564209631","121216847022485","121571390309073",
        "122812055447896","123047897844134","123812278891591","124706657239027","124735239320776",
        "125224839697689","126081405469607","126497551689502","126527634689050","126626340093785",
        "126751859125353","128241974219045","129784271201071","130012819736632","130585295123651",
        "130593238885843","132817836308238","133002120549396","133881825716964","133963973694098",
        "134838390519433","135002183282873","135403091566760","135727476735024","136365031119137",
        "137504605181913","137688077908355","137795837089724","137846825408335","138045669415653",
        "138720291317243","117187218825161","105221485497534","86868198964957","134758728973154",
        "132636403911470","125350153877085","2874840706","110850539331763","72042024",
        "139369275981139","113691709436161","129626174716003","75618342544502","93902163029544",
        "79310600168078","104540716539347","101636125032002","125430111937587","81963230963908",
        "84926129581106","83333467665074","127417297154354",
    }) do LUNGE_IDS[id] = true end


    local SKIP_IDS = {}
    for _, id in ipairs({
        "86266790353635","84093948968516","102746205979822","99210996402874","121108316060822",
        "109928123357793","110466971021611","110355011987939","135181748009911","77210283630654",
        "108211560927158","104192089592095","109257644640676","98163597193511","111223305405046",
        "75258958842388","93136435416899","92098503722633","117886494230451",
    }) do SKIP_IDS[id] = true end


    local SPECIAL_NAMES = {
        ["101443662521580"] = "Veil Spear Throw 1",
        ["127622545856523"] = "Veil Spear Throw 2",
        ["76744850905644"]  = "Myers Grab",
        ["71001061734896"]  = "Take Out Spear",
        ["129669521834246"] = "Put Away Spear",
    }
    local DEFAULT_ATTACKS = {
        ["106871536134254"] = {Name = "Masked Alex Attack", Default = true},
        ["117070354890871"] = {Name = "Masked Alex Lunge",  Default = true},
        ["73681849513551"]  = {Name = "Hidden Dash",        Default = true},
        ["100014992013740"] = {Name = "Abysswalker Slash",  Default = true},
    }


    local state = {
        LastAttempt = 0, LastSuccess = 0,
        SeenAnimators = setmetatable({}, {__mode = "k"}),
        SeenModels = setmetatable({}, {__mode = "k"}),
        ActiveClient = nil, ClientModule = nil, ClientHooked = false,
        WarnedFallback = false, LastGcScan = 0,
    }
    local Connections = {}
    local function addConn(c) table.insert(Connections, c); return c end


    local prompt = { HoldingPrompt = false, HoldSince = 0, UntilTime = 0 }
    addConn(ProximityPromptService.PromptButtonHoldBegan:Connect(function(_, plr)
        if plr == LP then prompt.HoldingPrompt = true; prompt.HoldSince = tick() end
    end))
    addConn(ProximityPromptService.PromptButtonHoldEnded:Connect(function(_, plr)
        if plr == LP then
            prompt.HoldingPrompt = false
            prompt.UntilTime = math.max(prompt.UntilTime, tick() + 0.35)
        end
    end))
    addConn(ProximityPromptService.PromptTriggered:Connect(function(_, plr)
        if plr == LP then
            prompt.HoldingPrompt = false
            prompt.UntilTime = tick() + 1.2
        end
    end))


    local function checkFace(killerHRP, myHRP)
        if AP.AggressiveMode then return true end
        if not killerHRP or not myHRP then return false end
        local delta = myHRP.Position - killerHRP.Position
        if delta.Magnitude <= 0.001 then return true end
        local angle = 15 + math.clamp(tonumber(AP.FaceSensitivity) or 10, 0, 10) / 10 * 75
        return killerHRP.CFrame.LookVector:Dot(delta.Unit) >= math.cos(math.rad(angle))
    end


    local function checkRange(killerHRP, myHRP, tPos, vel)
        if not killerHRP or not myHRP then return false end
        local dist = ((tPos or killerHRP.Position) - myHRP.Position).Magnitude
        local maxRange = math.clamp(tonumber(AP.Range) or 14, 5, 35)
        if dist > maxRange and not tPos then
            local extend = 0
            pcall(function()
                local delta = myHRP.Position - killerHRP.Position
                if delta.Magnitude > 0.01 then
                    local unit = delta.Unit
                    local vel1 = killerHRP.AssemblyLinearVelocity or Vector3.zero
                    if vel and vel.Magnitude > vel1.Magnitude then vel1 = vel end
                    local vel2 = myHRP.AssemblyLinearVelocity or Vector3.zero
                    local closing = math.max(0, vel1:Dot(unit) - vel2:Dot(unit))
                    local ping = 0.05
                    local ok, p = pcall(function() return LP:GetNetworkPing() end)
                    if ok and type(p) == "number" then ping = p end
                    extend = math.clamp(closing * (ping * 2 + 0.16), 0, 26)
                end
            end)
            maxRange = maxRange + extend
        end
        if dist > maxRange then return false end
        return checkFace(killerHRP, myHRP)
    end


    local function hasParryTool()
        local char = LP.Character
        local backpack = LP:FindFirstChildOfClass("Backpack")
        local equipped = tostring(LP:GetAttribute("EquippedItem") or ""):lower()
        if equipped:find("parry") or equipped:find("dagger") then
            if char then
                local t = char:FindFirstChild("Parrying Dagger") or char:FindFirstChild("Parry Dagger")
                if t then return t end
            end
            if backpack then
                local t = backpack:FindFirstChild("Parrying Dagger") or backpack:FindFirstChild("Parry Dagger")
                if t then return t end
            end
            return true
        end
        local containers = {}
        if char then table.insert(containers, char) end
        if backpack then table.insert(containers, backpack) end
        for _, c in ipairs(containers) do
            for _, child in ipairs(c:GetChildren()) do
                local n = child.Name:lower()
                if n:find("parry") or n:find("dagger") then return child end
            end
        end
        return nil
    end


    local function getClient()
        local function isValid(c)
            return type(c) == "table" and type(c.Parry) == "function" and c.tool and c.tool.Parent
        end
        if isValid(state.ActiveClient) then return state.ActiveClient end
        if isValid(_G.TianHub_ActiveParryClient) then state.ActiveClient = _G.TianHub_ActiveParryClient; return state.ActiveClient end
        if not state.ClientModule then
            pcall(function()
                local M = ReplicatedStorage:FindFirstChild("Modules")
                local I = M and M:FindFirstChild("Items")
                local P = I and I:FindFirstChild("ParryingDagger")
                local PC = P and P:FindFirstChild("ParryClient")
                if PC then state.ClientModule = require(PC) end
            end)
        end
        if type(state.ClientModule) == "table" and not state.ClientHooked then
            state.ClientHooked = true
            pcall(function()
                local origNew = state.ClientModule.new
                if type(origNew) == "function" then
                    state.ClientModule.new = function(...)
                        local c = origNew(...)
                        state.ActiveClient = c
                        _G.TianHub_ActiveParryClient = c
                        return c
                    end
                end
            end)
        end
        if typeof(getgc) == "function" and tick() - state.LastGcScan > 3 then
            state.LastGcScan = tick()
            local ok, gc = pcall(getgc, true)
            if ok and type(gc) == "table" then
                for _, c in ipairs(gc) do
                    if type(c) == "table" and type(c.Parry) == "function" and c.tool and c.tool.Parent then
                        if getmetatable(c) == state.ClientModule or rawget(c, "parryEvent") or rawget(c, "daggerFolder") or rawget(c, "tool") then
                            state.ActiveClient = c
                            _G.TianHub_ActiveParryClient = c
                                return c
                        end
                    end
                end
            end
        end
        return nil
    end


    local function doFallback()
        local fired = false
        pcall(function()
            local pg = LP:FindFirstChildOfClass("PlayerGui")
            local mob = pg and (pg:FindFirstChild("Survivor-mob") or pg:FindFirstChild("Survivor"))
            local ctrl = mob and mob:FindFirstChild("Controls")
            local btn = ctrl and (ctrl:FindFirstChild("Gui-mob") or ctrl:FindFirstChild("action"))
            if btn then
                if typeof(firesignal) == "function" then
                    pcall(function() firesignal(btn.MouseButton1Down) end)
                    task.defer(function() pcall(function() firesignal(btn.MouseButton1Up) end) end)
                    fired = true
                end
                if typeof(getconnections) == "function" then
                    local ok, conns = pcall(function() return getconnections(btn.MouseButton1Down) end)
                    if ok and type(conns) == "table" then
                        for _, c in ipairs(conns) do pcall(function() c:Fire(); fired = true end) end
                    end
                    local ok1, conns1 = pcall(function() return getconnections(btn.MouseButton1Up) end)
                    if ok1 and type(conns1) == "table" then
                        task.defer(function() for _, c in ipairs(conns1) do pcall(function() c:Fire() end) end end)
                    end
                end
            end
        end)
        local tool = hasParryTool()
        if typeof(tool) == "Instance" and tool:IsA("Tool") then
            pcall(function() tool:Activate(); fired = true end)
        end
        return fired
    end


    local function autoroateGuard()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return nil end
        local orig = hum.AutoRotate
        pcall(function() hum.AutoRotate = false end)
        local done = false
        return function()
            if done then return end
            done = true
            task.delay(0.04, function()
                if hum and hum.Parent and char == LP.Character then
                    pcall(function() hum.AutoRotate = orig end)
                end
            end)
        end
    end


    local ACTION_KEYWORDS = {"repair","generator","unhook","hooking","rescu","gate","vault","pallet","dropping","interact","opening"}
    local ANIM_KEYWORDS   = {"repair","generator","unhook","rescue","hook","gate","exit","vault","window","pallet","drop"}


    local function hasBlockingAttr(inst)
        local ok, attrs = pcall(function() return inst:GetAttributes() end)
        if not ok or type(attrs) ~= "table" then return false end
        for k, v in pairs(attrs) do
            if v == true then
                local n = string.lower(tostring(k))
                if not (n:find("^can") or n:find("^has") or n:find("^allow")) then
                    for _, kw in ipairs(ACTION_KEYWORDS) do
                        if n:find(kw, 1, true) then return true end
                    end
                end
            end
        end
        return false
    end


    local function isDoingAction()
        local t = tick()
        if t < prompt.UntilTime then return true end
        if prompt.HoldingPrompt and t - prompt.HoldSince < 15 then return true end
        local char = LP.Character
        if not char then return false end
        if hasBlockingAttr(char) or hasBlockingAttr(LP) then return true end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local animator = hum and hum:FindFirstChildOfClass("Animator")
        if animator then
            local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
            if ok and tracks then
                for _, track in ipairs(tracks) do
                    local s = ""
                    pcall(function()
                        local p = track.Priority
                        if p == Enum.AnimationPriority.Action or p == Enum.AnimationPriority.Action2
                            or p == Enum.AnimationPriority.Action3 or p == Enum.AnimationPriority.Action4 then
                            s = string.lower(tostring(track.Name) .. " " .. tostring(track.Animation and track.Animation.Name or ""))
                        end
                    end)
                    if s ~= "" and not s:find("parry", 1, true) and not s:find("dagger", 1, true) then
                        for _, kw in ipairs(ANIM_KEYWORDS) do
                            if s:find(kw, 1, true) then return true end
                        end
                    end
                end
            end
        end
        return false
    end


    local function tryParry(reason)
        if AP.Enabled ~= true then return false end
        if tick() - state.LastAttempt < 0.012 then return false end
        if not hasParryTool() then return false end
        if isDoingAction() then return false end
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then return false end
        if char:GetAttribute("Knocked") or LP:GetAttribute("Knocked")
            or char:GetAttribute("IsHooked") or LP:GetAttribute("IsHooked")
            or char:GetAttribute("IsCarried") or LP:GetAttribute("IsCarried")
            or char:GetAttribute("IsDead") or LP:GetAttribute("IsDead") then return false end
        local client = getClient()
        if client and (client.isParryOnCooldown or client.isParryResolving) then return false end
        if tick() - state.LastSuccess < 0.1 then return false end
        state.LastAttempt = tick()
        local restore = autoroateGuard()
        if client then
            local ok, result = pcall(function()
                if client.character ~= char and type(client._bindCharacter) == "function" then
                    pcall(function() client:_bindCharacter(char) end)
                end
                return client:Parry()
            end)
            if ok and result ~= false then
                state.LastSuccess = tick()
                if restore then restore() end
                return true
            end
            if restore then restore() end
            return false
        end
        local ok2, result2 = pcall(doFallback)
        if ok2 and result2 then
            state.LastSuccess = tick()
            if restore then restore() end
            if not state.WarnedFallback then
                state.WarnedFallback = true
                warn("[TIAN HUB AUTO PARRY V2] GUI/tool fallback activated")
            end
            return true
        end
        if restore then restore() end
        if not state.WarnedFallback then
            state.WarnedFallback = true
            warn("[TIAN HUB AUTO PARRY V2] Attack detected, no ParryClient available")
        end
        return false
    end


    local function handleAnim(track, char)
        if not AP.Enabled or not track or not char or not char.Parent then return end
        local id = ""
        pcall(function() id = tostring(track.Animation.AnimationId):match("%d+") or "" end)
        if id == "" then return end
        if SKIP_IDS[id] then return end
        if SPECIAL_NAMES[id] then return end
        if string.lower(tostring(char.Name or "")):find("veil", 1, true) then
            local n1, n2 = "", ""
            pcall(function() n1 = string.lower(tostring(track.Name or "")) end)
            pcall(function() n2 = string.lower(tostring(track.Animation and track.Animation.Name or "")) end)
            local s = n1 .. " " .. n2
            if s:find("spear", 1, true) or s:find("throw", 1, true) or s:find("charge", 1, true) then return end
        end
        local def = DEFAULT_ATTACKS[id]
        if def and AttackSkip[id] == true then return end
        if LUNGE_IDS[id] ~= true and (def == nil or def.Default ~= true) then return end
        local ok, timePos = pcall(function() return track.TimePosition or 0 end)
        if ok and timePos > 0.45 then return end
        -- raw spawn: per-anim thread, tidak ikut tracker utama (short-lived)
        rawSpawn(function()
            local startT = tick()
            local lastPos, lastT, velEst
            while AP.Enabled and track.IsPlaying do
                local tp = 0
                pcall(function() tp = track.TimePosition or 0 end)
                if tp > 0.45 then break end
                local myChar = LP.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local kHRP = char:FindFirstChild("HumanoidRootPart")
                if kHRP then
                    local now = tick()
                    local pos = kHRP.Position
                    if lastPos and now > lastT then
                        local v = (pos - lastPos) / (now - lastT)
                        velEst = velEst and velEst * 0.5 + v * 0.5 or v
                    end
                    lastPos, lastT = pos, now
                end
                if myHRP and kHRP and checkRange(kHRP, myHRP, nil, velEst) then
                    if tryParry("anim:" .. id) then return end
                end
                RunService.Heartbeat:Wait()
                if tick() - startT >= 0.45 then break end
            end
        end)
    end


    local function hookAnimator(animator, char)
        if not animator or state.SeenAnimators[animator] then return end
        state.SeenAnimators[animator] = true
        local ok, conn = pcall(function()
            return animator.AnimationPlayed:Connect(function(track)
                pcall(handleAnim, track, char)
            end)
        end)
        if ok and conn then addConn(conn) end
        pcall(function()
            for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                rawSpawn(handleAnim, t, char)
            end
        end)
    end


    local function hookCharacter(char)
        if not char or state.SeenModels[char] then return end
        state.SeenModels[char] = true
        local function bind(inst)
            if inst:IsA("Humanoid") then
                local animator = inst:FindFirstChildOfClass("Animator")
                if animator then hookAnimator(animator, char) end
                addConn(inst.ChildAdded:Connect(function(c)
                    if c:IsA("Animator") then hookAnimator(c, char) end
                end))
            end
        end
        for _, c in ipairs(char:GetChildren()) do pcall(bind, c) end
        addConn(char.ChildAdded:Connect(function(c) pcall(bind, c) end))
    end


    local function isKillerChar(char)
        if not char or not char:IsA("Model") or char == LP.Character then return false end
        if not char:FindFirstChildOfClass("Humanoid") or not char:FindFirstChild("HumanoidRootPart") then return false end
        local plr = Players:GetPlayerFromCharacter(char)
        if plr == LP then return false end
        local function chk(inst)
            return inst and (inst:GetAttribute("Role") == "Killer" or inst:GetAttribute("IsKiller") == true)
        end
        if chk(char) or chk(plr) then return true end
        if plr and plr.Team then
            local t = plr.Team.Name:lower()
            if t:find("killer") or t:find("slasher") or t:find("hunter") or t:find("monster") then return true end
            if not t:find("survivor") and not t:find("lobby") and not t:find("spectat") then return true end
        end
        local K = workspace:FindFirstChild("Killers")
        if K and char:IsDescendantOf(K) then return true end
        local n = char.Name:lower()
        for _, kw in ipairs({"zombie","slasher","monster","killer","veil","stalker","masked","abysswalker","hunter"}) do
            if n:find(kw, 1, true) then return true end
        end
        return false
    end


    local function getAllKillers()
        local list, seen = {}, {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                local c = p.Character
                if c and not seen[c] and isKillerChar(c) then
                    seen[c] = true
                    table.insert(list, c)
                end
            end
        end
        local K = workspace:FindFirstChild("Killers")
        if K then
            for _, d in ipairs(K:GetDescendants()) do
                if d:IsA("Model") and not seen[d] and isKillerChar(d) then
                    seen[d] = true
                    table.insert(list, d)
                end
            end
        end
        for _, c in ipairs(workspace:GetChildren()) do
            if c:IsA("Model") and not seen[c] and isKillerChar(c) then
                seen[c] = true
                table.insert(list, c)
            end
        end
        return list
    end


    addConn(task.spawn(function()
        while true do
            if AP.Enabled then
                for _, k in ipairs(getAllKillers()) do pcall(hookCharacter, k) end
                task.wait(0.1)
            else
                task.wait(0.35)
            end
        end
    end))


    addConn(Players.PlayerAdded:Connect(function(player)
        if player == LP then return end
        addConn(player.CharacterAdded:Connect(function(char)
            task.defer(function()
                if char and isKillerChar(char) then hookCharacter(char) end
            end)
        end))
    end))


    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            addConn(p.CharacterAdded:Connect(function(char)
                task.defer(function()
                    if char and isKillerChar(char) then hookCharacter(char) end
                end)
            end))
        end
    end


    -- Range circle: segmented neon ring (visual-only; Auto Parry logic unchanged)
    local ringFolder
    local ringSegments = {}
    local RING_SEGMENTS = 96
    local RING_ALPHA = 0.2
    local RING_THICK = 0.3
    local RING_HEIGHT = 0.1

    local function cleanupRing()
        for _, segment in ipairs(ringSegments) do
            pcall(function() segment:Destroy() end)
        end
        ringSegments = {}
        if ringFolder then
            pcall(function() ringFolder:Destroy() end)
            ringFolder = nil
        end
    end

    local function ensureRing()
        if #ringSegments == RING_SEGMENTS and ringFolder and ringFolder.Parent then return end
        cleanupRing()
        ringFolder = Instance.new("Folder")
        ringFolder.Name = "TIANHUB_ParryCircleVisual"
        ringFolder.Parent = workspace

        for i = 1, RING_SEGMENTS do
            local segment = Instance.new("Part")
            segment.Name = "ParryRingSegment" .. i
            segment.Anchored = true
            segment.CanCollide = false
            segment.CanTouch = false
            segment.CanQuery = false
            segment.CastShadow = false
            segment.Material = Enum.Material.Neon
            segment.Color = Color3.fromRGB(168, 85, 247)
            segment.Transparency = RING_ALPHA
            segment.Size = Vector3.new(RING_THICK, RING_HEIGHT, 1)
            segment.Parent = ringFolder
            ringSegments[i] = segment
        end
    end

    local function updateRing(center, range)
        local segmentLength = (2 * math.pi * range / RING_SEGMENTS) * 1.05
        for i, segment in ipairs(ringSegments) do
            local theta = (i - 1) / RING_SEGMENTS * math.pi * 2
            segment.Size = Vector3.new(RING_THICK, RING_HEIGHT, segmentLength)
            segment.CFrame = CFrame.new(center)
                * CFrame.Angles(0, theta, 0)
                * CFrame.new(range, 0, 0)
        end
    end

    addConn(RunService.Heartbeat:Connect(function()
        local myChar = LP.Character
        local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not AP.Enabled or not AP.CircleVisible or not hrp then
            cleanupRing()
            return
        end

        ensureRing()
        local range = math.clamp(tonumber(AP.Range) or 14, 5, 35)
        local center = hrp.Position + Vector3.new(0, -2.8, 0)
        updateRing(center, range)
    end))

    -- TIAN HUB UI adapter: expose only controls belonging to the new engine.
    function AP.SetEnabled(value)
        AP.Enabled = value == true
    end
    function AP.SetRange(value)
        AP.Range = math.clamp(tonumber(value) or 14, 5, 35)
    end
    function AP.SetRangeESP(value)
        AP.CircleVisible = value == true
    end
    function AP.SetFaceSensitivity(value)
        AP.FaceSensitivity = math.clamp(tonumber(value) or 10, 0, 10)
    end
    function AP.SetAggressiveMode(value)
        AP.AggressiveMode = value == true
    end

    function AP.Destroy()
        AP.Enabled = false
        for _, connection in ipairs(Connections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(Connections)
        cleanupRing()
    end
end

-- ============================================================
-- SKILL CHECK (TIANHUB CORE PORTED; HANX COMPATIBILITY ADAPTATION)
-- ============================================================
local PGui2 = PlayerGui
local VIM2 = VirtualInputManager
local GS2 = GuiService
local Rns = RunService
local isMob2 = UIS.TouchEnabled and not UIS.KeyboardEnabled

local AutoSkill = {
    Mode = "Normal", Active = false, HideUI = false, Speed = 1,
    SpeedCharacter = nil, SpeedOriginal = nil,
    LastGR = nil, HasClicked = false, LastLR = nil, LastTick = nil, WasActive = false,
    PerfLastGR = nil, PerfHasClicked = false, PerfLastLR = nil, PerfLastTick = nil, PerfWasActive = false,
    InstHasClicked = false,
}

local function AS_PressSkill()
    if isMob2 then
        local btn = PGui2:FindFirstChild("check", true)
        if btn and btn:IsA("GuiObject") and btn.Visible then
            local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
            local ins = GS2:GetGuiInset()
            local x = pos.X + size.X/2 + ins.X
            local y = pos.Y + size.Y/2 + ins.Y
            pcall(function()
                VIM2:SendTouchEvent(8822, Enum.UserInputState.Begin.Value, x, y)
                task.wait(0.01)
                VIM2:SendTouchEvent(8822, Enum.UserInputState.End.Value, x, y)
            end)
            if firesignal and btn:IsA("GuiButton") then
                pcall(function() firesignal(btn.MouseButton1Click) end)
            end
            return true
        end
    end
    return pcall(function()
        VIM2:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.01)
        VIM2:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
end

local function AS_GetSC()
    for _, gn in ipairs({"SkillCheckPromptGui", "SkillCheckPromptGui-con"}) do
        local root = PGui2:FindFirstChild(gn, true)
        if root then
            local c = root:FindFirstChild("Check", true)
            if c and c.Visible then
                local tp = c:FindFirstChild("TrapPerfect", true)
                local tg = c:FindFirstChild("TrapGoal", true)
                if (tp and tp.Visible) or (tg and tg.Visible) then return nil end
                local l, g = c:FindFirstChild("Line", true), c:FindFirstChild("Goal", true)
                if l and g then return l, g end
            end
        end
    end
end

local function AS_Delta(a, b)
    local d = b - a
    if d > 180 then d = d - 360 end
    if d < -180 then d = d + 360 end
    return d
end

local function AS_Crossed(prev, now, sp, ep)
    local function inside(r)
        if sp > ep then return r >= sp or r <= ep end
        return r >= sp and r <= ep
    end
    if inside(now) then return true end
    if prev == nil then return false end
    local d = AS_Delta(prev, now)
    local steps = math.abs(math.floor(d))
    if steps < 2 then return false end
    local step = d / steps
    for i = 1, steps do
        if inside((prev + step*i) % 360) then return true end
    end
    return false
end

local function AS_Reset()
    AutoSkill.LastGR, AutoSkill.LastLR, AutoSkill.LastTick = nil, nil, nil
    AutoSkill.HasClicked, AutoSkill.WasActive = false, false
    AutoSkill.PerfLastGR, AutoSkill.PerfLastLR, AutoSkill.PerfLastTick = nil, nil, nil
    AutoSkill.PerfHasClicked, AutoSkill.PerfWasActive = false, false
    AutoSkill.InstHasClicked = false
end

local function AS_Normal()
    local l,g = AS_GetSC()
    if not (l and g) then AutoSkill.WasActive=false return end
    local lr,gr,nw = l.Rotation%360,g.Rotation%360,os.clock()
    if not AutoSkill.WasActive then
        AutoSkill.WasActive=true; AutoSkill.HasClicked=false
        AutoSkill.LastGR=gr; AutoSkill.LastLR=lr; AutoSkill.LastTick=nw
        return
    end
    if AutoSkill.LastGR and math.abs(AS_Delta(AutoSkill.LastGR,gr)) > 5 then
        AutoSkill.HasClicked=false; AutoSkill.LastLR=nil; AutoSkill.LastTick=nil
    end
    AutoSkill.LastGR=gr
    if AutoSkill.HasClicked then AutoSkill.LastLR=lr; AutoSkill.LastTick=nw; return end
    if AutoSkill.LastLR and AutoSkill.LastTick then
        local dt=nw-AutoSkill.LastTick
        if dt>0 then
            local ls=AS_Delta(AutoSkill.LastLR,lr)/dt
            local pr=(lr+ls*dt*0)%360
            if AS_Crossed(AutoSkill.LastLR,pr,(gr+104)%360,(gr+109)%360) then
                AutoSkill.HasClicked=true
                task.spawn(function() task.wait(0.03); AS_PressSkill() end)
            end
        end
    end
    AutoSkill.LastLR,AutoSkill.LastTick=lr,nw
end

local function AS_Perfect()
    local l,g=AS_GetSC()
    if not (l and g) then AutoSkill.PerfWasActive=false return end
    local lr,gr,nw=l.Rotation%360,g.Rotation%360,os.clock()
    if not AutoSkill.PerfWasActive then
        AutoSkill.PerfWasActive=true; AutoSkill.PerfHasClicked=false
        AutoSkill.PerfLastGR=gr; AutoSkill.PerfLastLR=lr; AutoSkill.PerfLastTick=nw
        return
    end
    if AutoSkill.PerfLastGR and math.abs(AS_Delta(AutoSkill.PerfLastGR,gr))>5 then
        AutoSkill.PerfHasClicked=false; AutoSkill.PerfLastLR=nil; AutoSkill.PerfLastTick=nil
    end
    AutoSkill.PerfLastGR=gr
    if AutoSkill.PerfHasClicked then AutoSkill.PerfLastLR=lr; AutoSkill.PerfLastTick=nw; return end
    if AutoSkill.PerfLastLR and AutoSkill.PerfLastTick then
        local dt=nw-AutoSkill.PerfLastTick
        if dt>0 then
            local ls=AS_Delta(AutoSkill.PerfLastLR,lr)/dt
            local pr=(lr+ls*dt*0)%360
            if AS_Crossed(AutoSkill.PerfLastLR,pr,(gr+104)%360,(gr+108)%360) then
                AutoSkill.PerfHasClicked=true
                AS_PressSkill()
            end
        end
    end
    AutoSkill.PerfLastLR,AutoSkill.PerfLastTick=lr,nw
end

local function AS_Instant()
    if AutoSkill.InstHasClicked then return end

    local pr = PGui2:FindFirstChild("SkillCheckPromptGui", true)
        or PGui2:FindFirstChild("SkillCheckPromptGui-con", true)
    if not pr then return end

    local c = pr:FindFirstChild("Check", true)
    if not c or not c.Visible then return end

    local tp = c:FindFirstChild("TrapPerfect", true)
    local tg = c:FindFirstChild("TrapGoal", true)
    if (tp and tp.Visible) or (tg and tg.Visible) then return end

    local l = c:FindFirstChild("Line", true)
    local g = c:FindFirstChild("Goal", true)
    if not (l and g) then return end

    AutoSkill.InstHasClicked = true

    task.spawn(function()
        -- Aim for the middle of the success window, not its outer edge.
        -- Perfect mode detects the success window around Goal +104..108 degrees.
        local targetRotation = (g.Rotation + 106) % 360
        local moved = pcall(function()
            l.Rotation = targetRotation
        end)

        if not moved then
            AutoSkill.InstHasClicked = false
            return
        end

        -- Let the UI update for one rendered frame before sending the key/touch input.
        Rns.RenderStepped:Wait()

        -- Do not press if this skillcheck disappeared or was replaced while waiting.
        if not pr.Parent or not c.Parent or not c.Visible
            or not l.Parent or not g.Parent then
            AutoSkill.InstHasClicked = false
            return
        end

        -- Keep the needle centered in the success zone in case the UI animation updates it.
        pcall(function()
            l.Rotation = targetRotation
        end)

        AS_PressSkill()
        task.wait(0.2)
        AutoSkill.InstHasClicked = false
    end)
end

local function AS_ApplySpeed(enabled)
    local char = LP.Character
    if enabled and char then
        if AutoSkill.SpeedCharacter ~= char then
            -- Restore the previous character before caching a respawned character.
            if AutoSkill.SpeedCharacter and AutoSkill.SpeedOriginal then
                pcall(function()
                    AutoSkill.SpeedCharacter:SetAttribute("skillcheckspeed", AutoSkill.SpeedOriginal.lower)
                    AutoSkill.SpeedCharacter:SetAttribute("SkillCheckSpeed", AutoSkill.SpeedOriginal.upper)
                end)
            end
            AutoSkill.SpeedCharacter = char
            AutoSkill.SpeedOriginal = {
                lower = char:GetAttribute("skillcheckspeed"),
                upper = char:GetAttribute("SkillCheckSpeed"),
            }
        end
        local speed = math.clamp(tonumber(AutoSkill.Speed) or 1, 0.1, 3)
        if char:GetAttribute("skillcheckspeed") ~= speed then
            pcall(function() char:SetAttribute("skillcheckspeed", speed) end)
        end
        if char:GetAttribute("SkillCheckSpeed") ~= speed then
            pcall(function() char:SetAttribute("SkillCheckSpeed", speed) end)
        end
    elseif AutoSkill.SpeedCharacter then
        local oldChar, oldValues = AutoSkill.SpeedCharacter, AutoSkill.SpeedOriginal
        pcall(function()
            oldChar:SetAttribute("skillcheckspeed", oldValues and oldValues.lower)
            oldChar:SetAttribute("SkillCheckSpeed", oldValues and oldValues.upper)
        end)
        AutoSkill.SpeedCharacter, AutoSkill.SpeedOriginal = nil, nil
    end
end

local function AS_HideUI()
    local hidden = AutoSkill.HideUI
    for _, gn in ipairs({"SkillCheckPromptGui","SkillCheckPromptGui-con"}) do
        local root=PGui2:FindFirstChild(gn,true)
        if root then
            if root:IsA("ScreenGui") then
                root.Enabled = not hidden
            else
                for _, o in ipairs(root:GetDescendants()) do
                    if o:IsA("GuiObject") then o.Visible = not hidden end
                end
            end
        end
    end
end

local TianHubSkillConn = Rns.RenderStepped:Connect(function()
    AS_ApplySpeed(AutoSkill.Active)
    if AutoSkill.Active then
        local mode = AutoSkill.Mode
        if mode=="Perfect" then AS_Perfect()
        elseif mode=="Instant" then AS_Instant()
        else AS_Normal() end
    else
        AS_Reset()
    end
    AS_HideUI()
end)


-- ============================================================
-- FAST VAULT
-- ============================================================
local FastVaultEnabled = false
local ControllerModule
local VaultRemote

task.spawn(function()
    if not game:IsLoaded() then pcall(function() game.Loaded:Wait() end) end
    local controller
    for attempt = 1, 15 do
        local ok, result = pcall(function()
            local modules = ReplicatedStorage:WaitForChild("Modules", 5)
            if not modules then return nil end
            local survivors = modules:WaitForChild("Survivors", 5)
            if not survivors then return nil end
            local module = survivors:WaitForChild("SurvivorAnimationsController", 5)
            if not module then return nil end
            return require(module)
        end)
        if ok and result then controller = result break end
        task.wait(1)
    end
    if not controller then return end
    ControllerModule = controller
    pcall(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
        if not remotes then return end
        local window = remotes:WaitForChild("Window", 5)
        if not window then return end
        VaultRemote = window:WaitForChild("fastvault", 5)
    end)
    local OriginalFacing = controller._isFacingStraightEnough
    local OriginalVault = controller._onVaultAnimation
    if type(OriginalFacing) ~= "function" or type(OriginalVault) ~= "function" then return end
    controller._isFacingStraightEnough = function(self, part1, part2, angle)
        if not FastVaultEnabled then return OriginalFacing(self, part1, part2, angle) end
        pcall(function() if self.character then self.character:SetAttribute("speed", 30) end end)
        return true, 0
    end
    controller._onVaultAnimation = function(self, vaultPoint, sprinting, requestId)
        if not FastVaultEnabled then return OriginalVault(self, vaultPoint, sprinting, requestId) end
        if self.isVaulting then return end
        if self.isSlidingPallet ~= nil then self.isSlidingPallet = false end
        if self.character then pcall(function() self.character:SetAttribute("vaultspeed", 2.0) end) end
        local packed = table.pack(pcall(function() return OriginalVault(self, vaultPoint, true, requestId) end))
        if not packed[1] then if self.character then pcall(function() self.character:SetAttribute("vaultspeed", 1) end) end; return end
        task.delay(0.15, function()
            if not self.isVaulting then return end
            if self.activeVaultTrack then pcall(function() self.activeVaultTrack:Stop() end) end
            if self.humanoidRootPart and vaultPoint and typeof(vaultPoint) == "Instance" and vaultPoint:IsA("BasePart") then pcall(function() self.humanoidRootPart.CFrame = vaultPoint.CFrame * CFrame.new(0, 2, -1) end) end
            if self.VaultCompleteEvent then pcall(function() self.VaultCompleteEvent:FireServer(vaultPoint, true, requestId, self.character) end) end
            self.isVaulting = false
            if self.humanoid then pcall(function() self.humanoid.AutoRotate = true end) end
            if type(self._finishVaultOrSlideSpeed) == "function" then pcall(function() self:_finishVaultOrSlideSpeed(true) end) end
            if type(self._checkConditions) == "function" then pcall(function() self:_checkConditions() end) end
        end)
        task.delay(1.0, function() if self.character then pcall(function() self.character:SetAttribute("vaultspeed", 1) end) end end)
        return table.unpack(packed, 2, packed.n)
    end
    task.spawn(function() while task.wait(0.5) do if FastVaultEnabled and VaultRemote then pcall(function() VaultRemote:FireServer(LP) end) end end end)
end)

-- ============================================================
-- UI LIBRARY
-- ============================================================
local Theme = { Bg = Color3.fromRGB(12, 12, 16), Panel = Color3.fromRGB(18, 18, 24), Card = Color3.fromRGB(24, 24, 32), Border = Color3.fromRGB(48, 48, 58), Text = Color3.fromRGB(240, 240, 245), TextMuted = Color3.fromRGB(140, 140, 155), Accent = Color3.fromRGB(160, 80, 255), Font = Enum.Font.Gotham, FontMedium = Enum.Font.GothamMedium, FontBold = Enum.Font.GothamBold }
local function mk(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end
local GUIAnim = { On = true }
local function corner(parent, r) mk("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = parent }) end
local function stroke(parent, color, thickness) return mk("UIStroke", { Color = color or Theme.Border, Thickness = thickness or 1, Parent = parent }) end
local function dragify(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            local conn; conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then conn:Disconnect(); conn = nil end
                end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local sc = frame:FindFirstChildOfClass("UIScale")
            local k = sc and sc.Scale or 1
            local delta = (input.Position - dragStart) / k
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local UI = {}; UI.__index = UI
local SearchRegistry = {}

function UI.new()
    local self = setmetatable({}, UI)
    
    if game:GetService("CoreGui"):FindFirstChild("HanxHubUI") then
        game:GetService("CoreGui"):FindFirstChild("HanxHubUI"):Destroy()
    end
    if PlayerGui:FindFirstChild("HanxHubUI") then
        PlayerGui:FindFirstChild("HanxHubUI"):Destroy()
    end

    local parent
    if gethui then
        local ok, res = pcall(gethui)
        if ok and res then parent = res end
    end
    if not parent then
        local ok, res = pcall(function() return CoreGui end)
        if ok and res then parent = res end
    end
    if not parent then parent = PlayerGui end
    local old = parent:FindFirstChild("HanxHubUI"); if old then old:Destroy() end
    
    self.Gui = mk("ScreenGui", { Name = "HanxHubUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = parent })
    local W, H = 720, 440
    local root = mk("Frame", { Name = "Root", Size = UDim2.fromOffset(W, H), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = self.Gui, ZIndex = 10 })
    self.Root = root
    local uiScale = mk("UIScale", { Parent = root })
    local function fitScale()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        local isTouch = UIS.TouchEnabled and not UIS.MouseEnabled
        local s = math.min(1, (vp.X * 0.94) / W, (vp.Y * 0.9) / H)
        if isTouch then s = math.min(s, 0.78) end
        uiScale.Scale = math.max(0.35, s)
    end
    fitScale()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitScale)
    end
    corner(root, 12)

    local rootStroke = mk("UIStroke", { Color = Color3.fromRGB(160, 80, 255), Thickness = 2, Transparency = 0.1, Parent = root })
    local rootGrad = mk("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(35, 0, 65)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(110, 20, 190)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(210, 130, 255)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(110, 20, 190)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(35, 0, 65))
        }),
        Rotation = 0
    }, rootStroke)

task.spawn(function()
    local t = 0
    while root and root.Parent and rootGrad and rootGrad.Parent do
        if not GUIAnim.On then
            task.wait(0.2)
            continue
        end
        t += task.wait(0.03)
        rootGrad.Rotation = (rootGrad.Rotation + 1.5) % 360
        rootStroke.Transparency = 0.15 + math.abs(math.sin(t * 2.5)) * 0.65
    end
end)


-- Glow luar tebal (lembut)
local sideGlow = mk("UIStroke", {
    Color = Color3.fromRGB(160, 80, 255),
    Thickness = 6,
    Transparency = 0.7,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Parent = root,
})
local sideGlowGrad = mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 225, 255)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(160, 80, 255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(255, 45, 165)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 225, 255)),
    }),
    Parent = sideGlow,
})

-- Garis tajam berwarna yang berputar
local sideLine = mk("UIStroke", {
    Color = Color3.new(1, 1, 1),
    Thickness = 1.5,
    Transparency = 0,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Parent = root,
})
local sideLineGrad = mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 225, 255)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(160, 80, 255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(255, 45, 165)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 225, 255)),
    }),
    Parent = sideLine,
})

-- Kilau putih yang melintas di sekeliling border
local sideShine = mk("UIStroke", {
    Color = Color3.new(1, 1, 1),
    Thickness = 2,
    Transparency = 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Parent = root,
})
local sideShineGrad = mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.10, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.20, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1.00, Color3.new(1, 1, 1)),
    }),
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.00, 1),
        NumberSequenceKeypoint.new(0.08, 0),
        NumberSequenceKeypoint.new(0.16, 1),
        NumberSequenceKeypoint.new(1.00, 1),
    }),
    Parent = sideShine,
})

task.spawn(function()
    local t = 0
    while sideGlowGrad and sideGlowGrad.Parent do if not GUIAnim.On then task.wait(0.2) continue end
        t += task.wait(0.03)
        sideGlowGrad.Rotation = (t * 70) % 360
        sideLineGrad.Rotation = (t * 110) % 360
        sideShineGrad.Rotation = (t * 180) % 360
        sideGlow.Transparency = 0.6 + math.abs(math.sin(t * 2)) * 0.3
    end
end)

    local bgLayer = mk("Frame", { Name = "NeonBackground", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(5, 3, 12), BorderSizePixel = 0, BackgroundTransparency = 0.45, ClipsDescendants = true, Parent = root, ZIndex = 1 })
    corner(bgLayer, 12)
    mk("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 3, 20)), ColorSequenceKeypoint.new(0.45, Color3.fromRGB(25, 5, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 3, 14)) }), Rotation = 125, Parent = bgLayer })

    local function NeonGlow(pos, size, color, transparency)
        local glow = mk("Frame", { Size = UDim2.fromOffset(size, size), Position = pos, BackgroundColor3 = color, BackgroundTransparency = transparency, BorderSizePixel = 0, Parent = bgLayer, ZIndex = 2 })
        corner(glow, size)
        mk("UIGradient", { Rotation = 45, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, color), ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 5, 30)) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.8) }), Parent = glow })
        return glow
    end
    local glow1 = NeonGlow(UDim2.new(-0.12, 0, -0.35, 0), 440, Color3.fromRGB(145, 35, 255), 0.72)
    local glow2 = NeonGlow(UDim2.new(0.72, 0, 0.55, 0), 430, Color3.fromRGB(100, 20, 230), 0.76)
    local glow3 = NeonGlow(UDim2.new(0.35, 0, -0.65, 0), 320, Color3.fromRGB(80, 20, 160), 0.82)

    local neonLines = {}
    for i = 1, 8 do
        local line = mk("Frame", { Name = "NeonLine", Size = UDim2.fromOffset(3, 330), Position = UDim2.new(i * 0.14 - 0.1, 0, -0.5, 0), Rotation = 45, BackgroundColor3 = Color3.fromRGB(155, 55, 255), BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = bgLayer, ZIndex = 2 })
        mk("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.8, 0.0), NumberSequenceKeypoint.new(1, 1) }), Parent = line })
        table.insert(neonLines, { obj = line, speed = math.random(15, 35) / 100, xBase = i * 0.14 - 0.1 })
    end

    local neonDots = {}
    for i = 1, 24 do
        local dot = mk("Frame", { Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4)), Position = UDim2.fromScale(math.random(5, 95) / 100, math.random(-50, 50) / 100), BackgroundColor3 = Color3.fromRGB(190, 110, 255), BackgroundTransparency = 0.15, BorderSizePixel = 0, Parent = bgLayer, ZIndex = 2 })
        corner(dot, 5)
        table.insert(neonDots, { obj = dot, spdY = math.random(5, 15) / 100, xBase = math.random(5, 95) / 100 })
    end

    task.spawn(function()
        local t = 0
        while bgLayer.Parent do if not GUIAnim.On then task.wait(0.2) continue end
            t = t + task.wait(1/60)
            if t % 3 < 1.5 then
                TweenService:Create(glow1, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.84 }):Play()
                TweenService:Create(glow2, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.65 }):Play()
            else
                TweenService:Create(glow1, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.68 }):Play()
                TweenService:Create(glow2, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.82 }):Play()
            end
            for _, data in ipairs(neonLines) do
                local pos = data.obj.Position
                local newY = pos.Y.Scale + data.speed * (1/60)
                if newY > 1.2 then newY = -0.5 end
                data.obj.Position = UDim2.new(data.xBase, 0, newY, 0)
            end
            for _, data in ipairs(neonDots) do
                local pos = data.obj.Position
                local newY = pos.Y.Scale + data.spdY * (1/60)
                if newY > 1.2 then newY = -0.2 end
                data.obj.Position = UDim2.fromScale(data.xBase, newY)
            end
        end
    end)

    local topBar = mk("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = root, ZIndex = 11 })
    dragify(root, topBar)

    local titleHolder = mk("Frame", { Size = UDim2.fromOffset(220, 40), Position = UDim2.fromOffset(16, 8), BackgroundTransparency = 1, Parent = topBar, ZIndex = 12 })

    -- Logo dan tulisan dibuat satu garis tengah agar header lebih rapi.
    local titleBanner = mk("ImageLabel", {
        Name = "HanxHubBanner",
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.fromOffset(0, 3),
        BackgroundTransparency = 1,
        Image = "rbxassetid://98105037209492",
        ScaleType = Enum.ScaleType.Fit,
        Parent = titleHolder,
        ZIndex = 13,
    })
    corner(titleBanner, 17)
    local bannerGlow = mk("UIStroke", { Color = Color3.fromRGB(175, 95, 255), Thickness = 1.5, Transparency = 0.22, Parent = titleBanner })
    local bannerGlowGradient = mk("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(95, 35, 170)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(225, 175, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(95, 35, 170)),
        }),
        Rotation = 0,
    }, bannerGlow)
    task.spawn(function()
        local pulse = 0
        while titleBanner and titleBanner.Parent do
            if GUIAnim.On then
                pulse += task.wait(0.035)
                if bannerGlow and bannerGlow.Parent then bannerGlow.Transparency = 0.18 + math.abs(math.sin(pulse * 2)) * 0.34 end
                if bannerGlowGradient and bannerGlowGradient.Parent then bannerGlowGradient.Rotation = (bannerGlowGradient.Rotation + 1.1) % 360 end
            else
                task.wait(0.2)
            end
        end
    end)
    local title = mk("TextLabel", {
        Size = UDim2.new(1, -44, 0, 22),
        Position = UDim2.fromOffset(42, 9),
        BackgroundTransparency = 1,
        Text = "HANX HUB",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Theme.FontBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleHolder,
        ZIndex = 12
    })

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(35, 0, 65)),
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(100, 20, 180)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(190, 100, 255)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(90, 15, 160)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(35, 0, 65))
    })
    gradient.Parent = title

    local titleStroke = Instance.new("UIStroke")
    titleStroke.Color = Color3.fromRGB(170, 70, 255)
    titleStroke.Thickness = 0.8
    titleStroke.Transparency = 0.25
    titleStroke.Parent = title

    task.spawn(function()
        while title and title.Parent do if not GUIAnim.On then return end
            gradient.Offset = Vector2.new(-1, 0)
            local tween = TweenService:Create(gradient, TweenInfo.new(3, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)})
            tween:Play()
            tween.Completed:Wait()
        end
    end)

    local titleGrad = mk("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 80, 255)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(80, 20, 150)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(80, 20, 150)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 80, 255)),
        }),
        Rotation = 0,
        Offset = Vector2.new(0, 0),
    }, title)

    task.spawn(function()
        local t = 0
        while titleGrad and titleGrad.Parent do if not GUIAnim.On then return end
            t = t + task.wait(0.03)
            titleGrad.Offset = Vector2.new((t * 0.5) % 1, 0)
        end
    end)

    mk("TextLabel", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(58, 24), Size = UDim2.new(1, -58, 0, 14), BackgroundTransparency = 1, Text = "Violence District", TextColor3 = Theme.Accent, Font = Theme.Font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = titleHolder, ZIndex = 12 })


    local sidebar = mk("Frame", { Size = UDim2.new(0, 170, 1, -66), Position = UDim2.new(0, 10, 0, 56), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = root, ZIndex = 11 }); corner(sidebar, 10); stroke(sidebar, Theme.Border, 1)
    local searchBar = mk("Frame", { Name = "SearchBar", Size = UDim2.new(1, -16, 0, 28), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = sidebar, ZIndex = 13 }); corner(searchBar, 8); stroke(searchBar, Theme.Border, 1)
    self.GlobalSearchBox = mk("TextBox", { Name = "FeatureSearch", Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search...", PlaceholderColor3 = Theme.TextMuted, TextColor3 = Theme.Text, Font = Theme.Font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = searchBar, ZIndex = 14 })
    local navList = mk("Frame", { Size = UDim2.new(1, -16, 1, -100), Position = UDim2.fromOffset(8, 44), BackgroundTransparency = 1, Parent = sidebar, ZIndex = 12 }); mk("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = navList })
    self.NavList = navList

    local profile = mk("Frame", { Size = UDim2.new(1, -16, 0, 48), Position = UDim2.new(0, 8, 1, -56), BackgroundColor3 = Theme.Card, BackgroundTransparency = 0.55, Parent = sidebar, ZIndex = 12 }); corner(profile, 8)

    local profileStroke = mk("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1.5, Parent = profile })
    local profileGrad = Instance.new("UIGradient")
    profileGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(35, 0, 65)),
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(100, 20, 180)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(190, 80, 255)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(100, 20, 180)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(35, 0, 65))
    })
    profileGrad.Parent = profileStroke

    task.spawn(function()
        while profile.Parent do if not GUIAnim.On then return end
            profileGrad.Rotation = 0
            local tween = TweenService:Create(profileGrad, TweenInfo.new(3, Enum.EasingStyle.Linear), {Rotation = 360})
            tween:Play()
            tween.Completed:Wait()
        end
    end)
    
    local avatar = mk("ImageLabel", { Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(8, 9), BackgroundColor3 = Theme.Bg, Parent = profile, ZIndex = 13 }); corner(avatar, 15)
    task.spawn(function() local ok, url = pcall(function() return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end); if ok then avatar.Image = url end end)
    mk("TextLabel", { Size = UDim2.new(1, -46, 0, 14), Position = UDim2.fromOffset(46, 10), BackgroundTransparency = 1, Text = LP.DisplayName, TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = profile, ZIndex = 13 })
    mk("TextLabel", { Size = UDim2.new(1, -46, 0, 12), Position = UDim2.fromOffset(46, 24), BackgroundTransparency = 1, Text = "@" .. LP.Name, TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = profile, ZIndex = 13 })

    local content = mk("Frame", { Size = UDim2.new(1, -180, 1, -66), Position = UDim2.new(0, 180, 0, 56), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Parent = root, ZIndex = 11 }); mk("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8), Parent = content })
    self.Tabs = {}; self.ActiveTab = nil; self.Content = content

    local function ApplyFeatureSearch(query)
        query = string.lower(query or ""); local searching = query ~= ""; local cardMatches, pageMatches = {}, {}
        for _, item in ipairs(SearchRegistry) do local match = searching and string.find(string.lower(item.Name), query, 1, true) ~= nil; item.Row.Visible = not searching or match; if match then cardMatches[item.Card] = true; pageMatches[item.Page] = true end end
        for _, item in ipairs(SearchRegistry) do item.Card.Visible = not searching or cardMatches[item.Card] == true end
        local firstMatch = nil; for _, tab in ipairs(self.Tabs) do local matched = not searching or pageMatches[tab.Page] == true; tab.Btn.Visible = matched; if matched and not firstMatch then firstMatch = tab end end
        if searching then self.ActiveTab = firstMatch elseif not self.ActiveTab then self.ActiveTab = self.Tabs[1] end
        for _, tab in ipairs(self.Tabs) do local active = tab == self.ActiveTab; tab.Page.Visible = active; tab.Indicator.Visible = active; tab.Btn.BackgroundTransparency = active and 0.75 or 1; local label = tab.Btn:FindFirstChildOfClass("TextLabel"); if label then label.TextColor3 = active and Theme.Text or Theme.TextMuted end end
    end
    self.ApplyFeatureSearch = ApplyFeatureSearch
    self.GlobalSearchBox:GetPropertyChangedSignal("Text"):Connect(function() ApplyFeatureSearch(self.GlobalSearchBox.Text) end)

    -- ============ HANX HUB CYBER PURPLE CONFIRM POPUP ============
    local confirmPopup = mk("Frame", {
        Name = "ConfirmPopup",
        Size = UDim2.fromOffset(410, 330),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(10, 6, 19),
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        Visible = false,
        Parent = self.Gui,
        ZIndex = 200,
    })
    corner(confirmPopup, 14)

    local confirmStroke = mk("UIStroke", { Color = Color3.fromRGB(170, 80, 255), Thickness = 2, Transparency = 0.1, Parent = confirmPopup })
    local confirmBorderGrad = mk("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(35, 0, 65)),
            ColorSequenceKeypoint.new(0.30, Color3.fromRGB(120, 35, 220)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(210, 140, 255)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(100, 20, 190)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(35, 0, 65)),
        }),
        Rotation = 0,
    }, confirmStroke)

    task.spawn(function()
        local t = 0
        while confirmPopup and confirmPopup.Parent do if not GUIAnim.On then return end
            t += task.wait(0.03)
            if confirmBorderGrad and confirmBorderGrad.Parent then
                confirmBorderGrad.Rotation = (confirmBorderGrad.Rotation + 1.2) % 360
            end
            if confirmStroke and confirmStroke.Parent then
                confirmStroke.Transparency = 0.12 + math.abs(math.sin(t * 2)) * 0.35
            end
        end
    end)

    local topLine = mk("Frame", { Size = UDim2.new(1, -36, 0, 2), Position = UDim2.fromOffset(18, 8), BackgroundColor3 = Color3.fromRGB(160, 70, 255), BorderSizePixel = 0, Parent = confirmPopup, ZIndex = 201 })
    mk("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 0, 80)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(210, 120, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 0, 80)) }) }, topLine)

    local logoBox = mk("Frame", { Size = UDim2.fromOffset(48, 48), Position = UDim2.fromOffset(24, 24), BackgroundColor3 = Color3.fromRGB(38, 15, 65), BorderSizePixel = 0, Parent = confirmPopup, ZIndex = 202 })
    corner(logoBox, 11); stroke(logoBox, Color3.fromRGB(160, 75, 255), 1.4)
    mk("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "H", TextColor3 = Color3.fromRGB(220, 180, 255), Font = Theme.FontBold, TextSize = 30, Parent = logoBox, ZIndex = 203 })

    mk("TextLabel", { Size = UDim2.new(1, -100, 0, 25), Position = UDim2.fromOffset(84, 25), BackgroundTransparency = 1, Text = "HANX HUB", TextColor3 = Color3.fromRGB(225, 195, 255), Font = Theme.FontBold, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, Parent = confirmPopup, ZIndex = 202 })
    mk("TextLabel", { Size = UDim2.new(1, -100, 0, 18), Position = UDim2.fromOffset(85, 49), BackgroundTransparency = 1, Text = "ADVANCED GAMING INTERFACE", TextColor3 = Color3.fromRGB(135, 105, 165), Font = Theme.Font, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, Parent = confirmPopup, ZIndex = 202 })
    mk("Frame", { Size = UDim2.new(1, -36, 0, 1), Position = UDim2.fromOffset(18, 86), BackgroundColor3 = Color3.fromRGB(75, 40, 105), BorderSizePixel = 0, Parent = confirmPopup, ZIndex = 201 })
    mk("TextLabel", { Size = UDim2.new(1, -40, 0, 25), Position = UDim2.fromOffset(20, 101), BackgroundTransparency = 1, Text = "// EXIT CONFIRMATION", TextColor3 = Color3.fromRGB(190, 105, 255), Font = Theme.FontBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = confirmPopup, ZIndex = 202 })

    local confirmTitle = mk("TextLabel", { Size = UDim2.new(1, -40, 0, 35), Position = UDim2.fromOffset(20, 127), BackgroundTransparency = 1, Text = "ARE YOU LEAVING?", TextColor3 = Color3.fromRGB(245, 235, 255), Font = Theme.FontBold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, Parent = confirmPopup, ZIndex = 202 })
    local titleGrad2 = mk("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 115, 255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 55, 220)) }), Rotation = 0 }, confirmTitle)
    task.spawn(function()
        while titleGrad2 and titleGrad2.Parent do if not GUIAnim.On then return end
            titleGrad2.Offset = Vector2.new(-1, 0)
            local tween = TweenService:Create(titleGrad2, TweenInfo.new(3, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)})
            tween:Play(); tween.Completed:Wait()
        end
    end)

    mk("TextLabel", { Size = UDim2.new(1, -40, 0, 35), Position = UDim2.fromOffset(20, 164), BackgroundTransparency = 1, Text = "Are you sure you want to close HANX HUB?", TextColor3 = Color3.fromRGB(165, 150, 185), Font = Theme.Font, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = confirmPopup, ZIndex = 202 })
    
    local warningCard = mk("Frame", { Size = UDim2.new(1, -40, 0, 48), Position = UDim2.fromOffset(20, 207), BackgroundColor3 = Color3.fromRGB(28, 13, 45), BackgroundTransparency = 0.05, BorderSizePixel = 0, Parent = confirmPopup, ZIndex = 202 })
    corner(warningCard, 9); stroke(warningCard, Color3.fromRGB(100, 45, 150), 1)
    mk("TextLabel", { Size = UDim2.fromOffset(35, 48), Position = UDim2.fromOffset(5, 0), BackgroundTransparency = 1, Text = "⚠", TextColor3 = Color3.fromRGB(190, 115, 255), Font = Theme.FontBold, TextSize = 20, Parent = warningCard, ZIndex = 203 })
    mk("TextLabel", { Size = UDim2.new(1, -48, 0, 20), Position = UDim2.fromOffset(40, 5), BackgroundTransparency = 1, Text = "SESSION TERMINATION", TextColor3 = Color3.fromRGB(215, 180, 255), Font = Theme.FontBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = warningCard, ZIndex = 203 })
    mk("TextLabel", { Size = UDim2.new(1, -48, 0, 17), Position = UDim2.fromOffset(40, 24), BackgroundTransparency = 1, Text = "Your current interface will be closed.", TextColor3 = Color3.fromRGB(140, 120, 160), Font = Theme.Font, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, Parent = warningCard, ZIndex = 203 })

    local yesBtn = mk("TextButton", { Size = UDim2.new(0.5, -25, 0, 38), Position = UDim2.new(0, 20, 1, -57), BackgroundColor3 = Color3.fromRGB(105, 35, 175), BorderSizePixel = 0, Text = "✓   YES, CLOSE", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Theme.FontBold, TextSize = 11, AutoButtonColor = false, Parent = confirmPopup, ZIndex = 203 })
    corner(yesBtn, 8); stroke(yesBtn, Color3.fromRGB(190, 110, 255), 1.3)
    local noBtn = mk("TextButton", { Size = UDim2.new(0.5, -25, 0, 38), Position = UDim2.new(0.5, 5, 1, -57), BackgroundColor3 = Color3.fromRGB(30, 20, 43), BorderSizePixel = 0, Text = "✕   CANCEL", TextColor3 = Color3.fromRGB(205, 185, 225), Font = Theme.FontBold, TextSize = 11, AutoButtonColor = false, Parent = confirmPopup, ZIndex = 203 })
    corner(noBtn, 8); stroke(noBtn, Color3.fromRGB(100, 65, 130), 1.2)

    yesBtn.MouseEnter:Connect(function() TweenService:Create(yesBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(145, 55, 225)}):Play() end)
    yesBtn.MouseLeave:Connect(function() TweenService:Create(yesBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(105, 35, 175)}):Play() end)
    noBtn.MouseEnter:Connect(function() TweenService:Create(noBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(55, 32, 75)}):Play() end)
    noBtn.MouseLeave:Connect(function() TweenService:Create(noBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 20, 43)}):Play() end)

    mk("TextLabel", { Size = UDim2.new(1, -40, 0, 12), Position = UDim2.new(0, 20, 1, -15), BackgroundTransparency = 1, Text = "HANX HUB  •  CYBER PURPLE INTERFACE", TextColor3 = Color3.fromRGB(100, 75, 125), Font = Theme.Font, TextSize = 8, Parent = confirmPopup, ZIndex = 202 })

    local confirmDrag = mk("Frame", { Size = UDim2.new(1, 0, 0, 85), BackgroundTransparency = 1, Parent = confirmPopup, ZIndex = 204 })
    dragify(confirmPopup, confirmDrag)
    self.ConfirmPopup = confirmPopup
    -- Glow luar lembut di sekeliling popup
local popupGlow = mk("UIStroke", {
    Color = Color3.fromRGB(170, 80, 255),
    Thickness = 10,
    Transparency = 0.75,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Parent = confirmPopup,
})
task.spawn(function()
    local t = 0
    while popupGlow and popupGlow.Parent do if not GUIAnim.On then task.wait(0.2) continue end
        t += task.wait(0.03)
        popupGlow.Transparency = 0.65 + math.abs(math.sin(t * 1.5)) * 0.3
    end
end)

-- Kilau putih yang melintas di tombol YES
-- Kilau putih di tombol YES (overlay terpisah, teks tidak ikut tersembunyi)
yesBtn.ClipsDescendants = true
local yesShine = mk("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ZIndex = 204,
    Parent = yesBtn,
})
corner(yesShine, 8)
local shineGrad = mk("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.45, 1),
        NumberSequenceKeypoint.new(0.5, 0.75),
        NumberSequenceKeypoint.new(0.55, 1),
        NumberSequenceKeypoint.new(1, 1),
    }),
    Rotation = 20,
    Parent = yesShine,
})
task.spawn(function()
    local x = -1
    while shineGrad and shineGrad.Parent do if not GUIAnim.On then task.wait(0.2) continue end
        x = x + 0.02
        if x > 1.2 then x = -1.2 end
        shineGrad.Offset = Vector2.new(x, 0)
        task.wait(0.03)
    end
end)

    noBtn.MouseButton1Click:Connect(function() confirmPopup.Visible = false end)
    yesBtn.MouseButton1Click:Connect(function() self.Gui:Destroy() end)

-- ============ HANX HUB ROUND MENU BUTTON ============
local tray = mk("TextButton", {
    Name = "HMHubTray",
    Size = UDim2.fromOffset(48, 48),
    Position = UDim2.new(0, 24, 0.5, -24),
    BackgroundColor3 = Color3.fromRGB(18, 10, 30),
    BackgroundTransparency = 0.08,
    Text = "",
    AutoButtonColor = false,
    Visible = true,
    Parent = self.Gui,
    ZIndex = 99,
})
tray.ClipsDescendants = true
corner(tray, 24)

-- Tombol melayang lebih ringkas dengan bingkai neon ungu yang bergerak halus.
local trayStroke = mk("UIStroke", {
    Color = Color3.fromRGB(175, 95, 255),
    Thickness = 2,
    Transparency = 0.12,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Parent = tray,
})
local trayStrokeGradient = mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(75, 20, 130)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(225, 175, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 20, 130)),
    }),
    Rotation = 0,
}, trayStroke)
local trayImage = mk("ImageLabel", {
    Name = "TrayIcon",
    Size = UDim2.fromOffset(48, 48),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundTransparency = 1,
    Image = "rbxassetid://98105037209492",
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 100,
    Parent = tray,
})
corner(trayImage, 24)

task.spawn(function()
    local pulse = 0
    while tray and tray.Parent do
        if GUIAnim.On then
            pulse += task.wait(0.035)
            if trayStroke and trayStroke.Parent then trayStroke.Transparency = 0.12 + math.abs(math.sin(pulse * 2.1)) * 0.3 end
            if trayStrokeGradient and trayStrokeGradient.Parent then trayStrokeGradient.Rotation = (trayStrokeGradient.Rotation + 1.25) % 360 end
        else
            task.wait(0.2)
        end
    end
end)

-- DRAGGABLE ROUND TRAY (mouse + touch)
local trayDragging = false
local trayDragInput, trayDragStart, trayStartPos
local trayMoved = false
tray.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        trayDragging = true
        trayMoved = false
        trayDragInput = input
        trayDragStart = input.Position
        trayStartPos = tray.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then trayDragging = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if trayDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - trayDragStart
        if math.abs(delta.X) + math.abs(delta.Y) > 6 then trayMoved = true end
        tray.Position = UDim2.new(trayStartPos.X.Scale, trayStartPos.X.Offset + delta.X, trayStartPos.Y.Scale, trayStartPos.Y.Offset + delta.Y)
    end
end)

-- MINIMIZE / RESTORE
local minimized = false
local isToggling = false

local function toggleMin()
    if isToggling then return end
    isToggling = true

    minimized = not minimized

    if minimized then
        TweenService:Create(root, TweenInfo.new(
            0.25,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.In
        ), {
            Size = UDim2.fromOffset(0, 0)
        }):Play()

        task.wait(0.25)

        root.Visible = false
        tray.Visible = true
        tray.Size = UDim2.fromOffset(48, 48)

    else
        tray.Visible = true
        root.Visible = true
        root.Size = UDim2.fromOffset(0, 0)

        TweenService:Create(root, TweenInfo.new(
            0.35,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.Out
        ), {
            Size = UDim2.fromOffset(W, H)
        }):Play()
    end

    isToggling = false
end

self.ToggleMin = toggleMin

tray.MouseButton1Click:Connect(function() if not trayMoved then toggleMin() end end)


    return self
end

function UI:AddTab(name)
    local btn = mk("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Card, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = self.NavList, ZIndex = 13 })
    corner(btn, 8); stroke(btn, Theme.Border, 1)
    local indicator = mk("Frame", { Size = UDim2.fromOffset(3, 16), Position = UDim2.new(0, -5, 0.5, -8), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Visible = false, Parent = btn, ZIndex = 14 }); corner(indicator, 2)
    mk("TextLabel", { Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Theme.TextMuted, Font = Theme.FontMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn, ZIndex = 14 })

    local page = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = self.Content, ZIndex = 12 })
    local leftScroll = mk("ScrollingFrame", { Size = UDim2.new(0.5, -4, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Border, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = page, ZIndex = 12 })
    mk("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = leftScroll })
    mk("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = leftScroll })

    local rightScroll = mk("ScrollingFrame", { Size = UDim2.new(0.5, -4, 1, 0), Position = UDim2.new(0.5, 4, 0, 0), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Border, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = page, ZIndex = 12 })
    mk("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = rightScroll })
    mk("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = rightScroll })

    local tab = { Btn = btn, Page = page, Indicator = indicator, Left = leftScroll, Right = rightScroll }
    table.insert(self.Tabs, tab)

    btn.MouseEnter:Connect(function() if self.ActiveTab ~= tab then TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.65 }):Play() end end)
    btn.MouseLeave:Connect(function() if self.ActiveTab ~= tab then TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play() end end)
    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(self.Tabs) do
            t.Page.Visible = false; t.Indicator.Visible = false; t.Btn.BackgroundTransparency = 1
            local lbl = t.Btn:FindFirstChildOfClass("TextLabel"); if lbl then lbl.TextColor3 = Theme.TextMuted end
        end
        page.Visible = true; indicator.Visible = true; btn.BackgroundTransparency = 0.75
        local lbl = btn:FindFirstChildOfClass("TextLabel"); if lbl then lbl.TextColor3 = Theme.Text end
        self.ActiveTab = tab
    end)

    if #self.Tabs == 1 then
        local lbl = btn:FindFirstChildOfClass("TextLabel"); if lbl then lbl.TextColor3 = Theme.Text end
        indicator.Visible = true; btn.BackgroundTransparency = 0.75; page.Visible = true
        self.ActiveTab = tab
    end
    return tab
end

function UI:AddCard(page, icon, title)
    local card = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.fromRGB(19, 13, 30), BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = page, ZIndex = 13 }); corner(card, 10); stroke(card, Color3.fromRGB(145, 55, 255), 1.4).Transparency = 0.12
    mk("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = card })
    mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
    local header = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = card, ZIndex = 14 })
    mk("TextLabel", { Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1, Text = tostring(icon) .. " " .. tostring(title), TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = header, ZIndex = 15 })
    mk("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = card, ZIndex = 14 })
    return card
end

function UI:AddToggle(card, label, default, callback)
    local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = card, ZIndex = 14 }); table.insert(SearchRegistry, { Name = label, Row = row, Card = card, Page = card.Parent })
    mk("TextLabel", { Size = UDim2.new(1, -90, 1, 0), BackgroundTransparency = 1, Text = label, TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = row, ZIndex = 15 })
    local state = default == true
    local statusLabel = mk("TextLabel", { Size = UDim2.fromOffset(36, 16), Position = UDim2.new(1, -80, 0.5, -8), BackgroundTransparency = 1, Text = state and "ON" or "OFF", TextColor3 = state and Theme.Accent or Theme.TextMuted, Font = Theme.FontBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Parent = row, ZIndex = 15 })
    local track = mk("Frame", { Size = UDim2.fromOffset(36, 18), Position = UDim2.new(1, -36, 0.5, -9), BackgroundColor3 = state and Theme.Accent or Theme.Border, BorderSizePixel = 0, Parent = row, ZIndex = 15 }); corner(track, 9)
    local knob = mk("Frame", { Size = UDim2.fromOffset(14, 14), Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = state and Theme.Bg or Theme.Text, BorderSizePixel = 0, Parent = track, ZIndex = 16 }); corner(knob, 7)
    local hit = mk("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = row, ZIndex = 17 })
    hit.MouseButton1Click:Connect(function()
        state = not state
        statusLabel.Text = state and "ON" or "OFF"
        statusLabel.TextColor3 = state and Theme.Accent or Theme.TextMuted
        TweenService:Create(track, TweenInfo.new(0.18), { BackgroundColor3 = state and Theme.Accent or Theme.Border }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18), { Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = state and Theme.Bg or Theme.Text }):Play()
        if callback then callback(state) end
    end)
end

function UI:AddSlider(card, label, min, max, default, callback)
    local wrap = mk("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = card, ZIndex = 14 }); table.insert(SearchRegistry, { Name = label, Row = wrap, Card = card, Page = card.Parent })
    mk("TextLabel", { Size = UDim2.new(1, -50, 0, 16), BackgroundTransparency = 1, Text = label, TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = wrap, ZIndex = 15 })
    local valLabel = mk("TextLabel", { Size = UDim2.fromOffset(44, 16), Position = UDim2.new(1, -44, 0, 0), BackgroundTransparency = 1, Text = tostring(default), TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Parent = wrap, ZIndex = 15 })
    local track = mk("Frame", { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0, 24), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = wrap, ZIndex = 15 }); corner(track, 2)
    local fill = mk("Frame", { Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track, ZIndex = 16 }); corner(fill, 2)
    local dot = mk("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track, ZIndex = 17 }); corner(dot, 6); stroke(dot, Theme.Bg, 2)
    local dragging = false
    local function setFromX(px)
        local rel = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0); dot.Position = UDim2.new(rel, 0, 0.5, 0); valLabel.Text = tostring(val)
        if callback then callback(val) end
    end
    track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; setFromX(i.Position.X) end end)
    UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then setFromX(i.Position.X) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
end

function UI:AddCheckbox(card, label, default, color, callback, colorCallback)
    local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = card, ZIndex = 14 })
    table.insert(SearchRegistry, { Name = label, Row = row, Card = card, Page = card.Parent })

    local box = mk("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = row, ZIndex = 15 })
    corner(box, 4)

    local state = default == true
    local check = mk("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "✓", TextColor3 = color or Theme.Accent, Font = Theme.FontBold, TextSize = 11, Visible = state, Parent = box, ZIndex = 16 })

    mk("TextLabel", { Size = UDim2.new(1, -56, 1, 0), Position = UDim2.fromOffset(24, 0), BackgroundTransparency = 1, Text = label, TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = row, ZIndex = 15 })

    local colorDot = mk("TextButton", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -12, 0.5, -6), BackgroundColor3 = color or Theme.Accent, Text = "", BorderSizePixel = 0, AutoButtonColor = false, Parent = row, ZIndex = 16 })
    corner(colorDot, 6)
    stroke(colorDot, Theme.Bg, 1)

    local hit = mk("TextButton", { Size = UDim2.new(1, -28, 1, 0), BackgroundTransparency = 1, Text = "", Parent = row, ZIndex = 17 })
    hit.MouseButton1Click:Connect(function()
        state = not state
        check.Visible = state
        if callback then callback(state) end
    end)

    colorDot.MouseButton1Click:Connect(function()
        if not colorCallback then return end
        if self.ActivePicker then self.ActivePicker:Destroy() end

        local h, s, v = colorDot.BackgroundColor3:ToHSV()
        local conns = {}
        local dragMode = nil

        local picker = mk("Frame", {
            Size = UDim2.fromOffset(200, 220),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Theme.Card,
            ZIndex = 500,
            Parent = self.Gui,
        })
        corner(picker, 10)
        stroke(picker, Theme.Accent, 2)
        self.ActivePicker = picker

        local area = mk("Frame", { Size = UDim2.fromOffset(160, 120), Position = UDim2.fromOffset(20, 20), BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, ClipsDescendants = true, Active = true, ZIndex = 501, Parent = picker })
        corner(area, 6)

        local white = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 502, Parent = area })
        mk("UIGradient", {
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
            Parent = white,
        })

        local black = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 503, Parent = area })
        mk("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
            Parent = black,
        })

        local areaSel = mk("Frame", { Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 505, Parent = area })
        corner(areaSel, 5)
        stroke(areaSel, Color3.new(1, 1, 1), 2)

        local hueBar = mk("Frame", { Size = UDim2.fromOffset(160, 14), Position = UDim2.fromOffset(20, 152), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Active = true, ZIndex = 501, Parent = picker })
        corner(hueBar, 4)
        mk("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            }),
            Parent = hueBar,
        })
        local hueSel = mk("Frame", { Size = UDim2.fromOffset(6, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 503, Parent = hueBar })
        corner(hueSel, 3)
        stroke(hueSel, Color3.new(0, 0, 0), 1)

        local saveBtn = mk("TextButton", { Size = UDim2.fromOffset(160, 25), Position = UDim2.fromOffset(20, 182), BackgroundColor3 = Theme.Accent, Text = "SAVE COLOR", TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 11, AutoButtonColor = false, ZIndex = 501, Parent = picker })
        corner(saveBtn, 6)

        local function refresh()
            local c = Color3.fromHSV(h, s, v)
            area.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            areaSel.Position = UDim2.fromScale(s, 1 - v)
            hueSel.Position = UDim2.fromScale(h, 0.5)
            colorDot.BackgroundColor3 = c
            check.TextColor3 = c
            colorCallback(c)
        end

        local function applyInput(input)
            local p = input.Position
            if dragMode == "area" then
                s = math.clamp((p.X - area.AbsolutePosition.X) / area.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((p.Y - area.AbsolutePosition.Y) / area.AbsoluteSize.Y, 0, 1)
            elseif dragMode == "hue" then
                h = math.clamp((p.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
            end
            refresh()
        end

        local function isPress(input)
            return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
        end

        area.InputBegan:Connect(function(input)
            if isPress(input) then dragMode = "area"; applyInput(input) end
        end)
        hueBar.InputBegan:Connect(function(input)
            if isPress(input) then dragMode = "hue"; applyInput(input) end
        end)

        table.insert(conns, UIS.InputChanged:Connect(function(input)
            if dragMode and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                applyInput(input)
            end
        end))
        table.insert(conns, UIS.InputEnded:Connect(function(input)
            if isPress(input) then dragMode = nil end
        end))

        local function close()
            for _, c in ipairs(conns) do c:Disconnect() end
            if self.ActivePicker == picker then self.ActivePicker = nil end
            picker:Destroy()
        end
        saveBtn.MouseButton1Click:Connect(close)

        refresh()
    end)
end

function UI:AddDropdown(card, label, options, default, callback)
    local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = card, ZIndex = 14 }); table.insert(SearchRegistry, { Name = label, Row = row, Card = card, Page = card.Parent })
    mk("TextLabel", { Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, Text = label, TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = row, ZIndex = 15 })
    local btn = mk("TextButton", { Size = UDim2.fromOffset(64, 22), Position = UDim2.new(1, -64, 0.5, -11), BackgroundColor3 = Theme.Bg, Text = default, TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 10, Parent = row, ZIndex = 15 }); corner(btn, 6); stroke(btn, Theme.Border, 1)
    local idx = 1; for i, v in ipairs(options) do if v == default then idx = i break end end
    btn.MouseButton1Click:Connect(function() idx = idx % #options + 1; btn.Text = options[idx]; if callback then callback(options[idx]) end end)
end

-- ============================================================
-- BUILD UI
-- ============================================================
local Window = UI.new()
local TabMain = Window:AddTab("Main")
local TabSurvivor = Window:AddTab("Survivor")
local TabKiller = Window:AddTab("Killer")
local TabVisual = Window:AddTab("Visual")
local TabTeleport = Window:AddTab("Teleport")
local TabSettings = Window:AddTab("Settings")

-- ============================================================
-- TELEPORT
-- ============================================================
local TP = { Generators = {}, Hooks = {}, Gates = {}, Pallets = {}, Windows = {}, Idx = { Generator = 1, Hook = 1, Gate = 1, Pallet = 1, Window = 1 }, ScanCooldown = 0 }

local function TP_Scan(force)
    if not force and tick() - TP.ScanCooldown < 2 then return end
    TP.ScanCooldown = tick()
    table.clear(TP.Generators); table.clear(TP.Hooks); table.clear(TP.Gates); table.clear(TP.Pallets); table.clear(TP.Windows)
    local map = workspace:FindFirstChild("Map") or workspace
    for i, desc in ipairs(map:GetDescendants()) do
        if i % 200 == 0 then task.wait() end
        if desc:IsA("Model") then
            local n = string.lower(desc.Name)
            if string.find(n, "generator") or string.find(n, "gen") then
                local body = desc:FindFirstChild("GeneratorBody") or desc:FindFirstChild("Hitbox") or desc:FindFirstChildWhichIsA("BasePart")
                if body then table.insert(TP.Generators, { model = desc, part = body }) end
            elseif string.find(n, "hook") then
                local part = desc:FindFirstChild("HookPoint") or desc:FindFirstChildWhichIsA("BasePart")
                if part then table.insert(TP.Hooks, part) end
            elseif string.find(n, "gate") or string.find(n, "exit") then
                local part = desc:FindFirstChild("ExitLever") or desc:FindFirstChild("Hitbox") or desc:FindFirstChildWhichIsA("BasePart")
                if part then table.insert(TP.Gates, part) end
            elseif string.find(n, "window") then
                local part = desc:FindFirstChildWhichIsA("BasePart")
                if part then table.insert(TP.Windows, part) end
            end
        elseif desc:IsA("BasePart") and string.find(string.lower(desc.Name), "pallet") then
            local parent = desc.Parent; if parent and not table.find(TP.Pallets, parent) then table.insert(TP.Pallets, parent) end
        end
    end
end

local function TP_To(part)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not part or not part:IsA("BasePart") then return false end
    local targetPos = part.Position + Vector3.new(0, 3, 0)
    hrp.Anchored = true
    hrp.CFrame = CFrame.new(targetPos)
    task.wait(0.15)
    hrp.Anchored = false
    hrp.Velocity = Vector3.zero
    if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    return true
end

local function TP_Cycle(category, pickPartFn, label)
    local list = TP[category]
    if not list or #list == 0 then TP_Scan(true); list = TP[category] end
    if not list or #list == 0 then return end
    local idxKey = category:sub(1, -2)
    local idx = TP.Idx[idxKey] or 1
    if idx > #list then idx = 1 end
    local entry = list[idx]
    TP.Idx[idxKey] = (idx % #list) + 1
    local part = pickPartFn(entry)
    if not part then part = entry.part or entry end
    if part and part:IsA("BasePart") then TP_To(part) end
end

local tpMapCard = Window:AddCard(TabTeleport.Left, "◈", "Teleport Map")
local refreshBtn = mk("TextButton", { Size = UDim2.new(1, -12, 0, 30), BackgroundColor3 = Color3.fromRGB(28, 24, 38), BorderSizePixel = 0, Text = "⟳ REFRESH MAP CACHE", TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 10, AutoButtonColor = false, Parent = tpMapCard, ZIndex = 15 }); corner(refreshBtn, 8); stroke(refreshBtn, Color3.fromRGB(160, 80, 255), 1)

refreshBtn.MouseButton1Click:Connect(function()
    TP.Idx.Generator, TP.Idx.Hook, TP.Idx.Gate, TP.Idx.Pallet, TP.Idx.Window = 1, 1, 1, 1, 1
    TP_Scan(true)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Refresh",
            Text = "Map cache refreshed",
            Duration = 2.5
        })
    end)
end)

local function TP_Button(parent, label, category, pickPartFn)
    local btn = mk("TextButton", { Size = UDim2.new(1, -12, 0, 30), BackgroundColor3 = Color3.fromRGB(28, 24, 38), BorderSizePixel = 0, Text = label .. " ›", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Theme.FontBold, TextSize = 10, AutoButtonColor = false, Parent = parent, ZIndex = 15 })
    corner(btn, 8)
    local btnStroke = stroke(btn, Color3.fromRGB(160, 80, 255), 1)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(65, 30, 95) }):Play()
        if btnStroke then TweenService:Create(btnStroke, TweenInfo.new(0.18), { Transparency = 0 }):Play() end
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(28, 24, 38) }):Play()
        if btnStroke then TweenService:Create(btnStroke, TweenInfo.new(0.18), { Transparency = 0.35 }):Play() end
    end)

    btn.MouseButton1Click:Connect(function() TP_Cycle(category, pickPartFn, label) end)
    return btn
end
TP_Button(tpMapCard, "TELEPORT TO GENERATOR", "Generators", function(e) return e.part end)
TP_Button(tpMapCard, "TELEPORT TO HOOK", "Hooks", function(e) return e:FindFirstChild("HookPoint") or e:FindFirstChildWhichIsA("BasePart") end)
TP_Button(tpMapCard, "TELEPORT TO GATE", "Gates", function(e) return e:FindFirstChildWhichIsA("BasePart") end)
TP_Button(tpMapCard, "TELEPORT TO PALLET", "Pallets", function(e) return e:FindFirstChild("PrimaryPartPallet") or e:FindFirstChildWhichIsA("BasePart") end)
TP_Button(tpMapCard, "TELEPORT TO WINDOW", "Windows", function(e) return e:FindFirstChild("Bottom") or e:FindFirstChildWhichIsA("BasePart") end)

local tpPlayerCard = Window:AddCard(TabTeleport.Right, "☻", "Teleport Player")
local tpSelectedPlayer = nil
do
    local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = tpPlayerCard, ZIndex = 14 }); table.insert(SearchRegistry, { Name = "Teleport Player Target", Row = row, Card = tpPlayerCard, Page = tpPlayerCard.Parent })
    mk("TextLabel", { Size = UDim2.new(1, -90, 1, 0), BackgroundTransparency = 1, Text = "Pilih Player", TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = row, ZIndex = 15 })

    local btn = mk("TextButton", {
        Size = UDim2.fromOffset(120, 26),
        Position = UDim2.new(1, -120, 0.5, -13),
        BackgroundColor3 = Color3.fromRGB(27, 17, 40),
        BorderSizePixel = 0,
        Text = "-  ⌄",
        TextColor3 = Color3.fromRGB(195, 145, 255),
        Font = Theme.FontBold,
        TextSize = 10,
        AutoButtonColor = false,
        Parent = row,
        ZIndex = 15
    })
    corner(btn, 7)
    stroke(btn, Color3.fromRGB(150, 65, 230), 1)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(55, 27, 78), TextColor3 = Color3.fromRGB(230, 195, 255) }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(27, 17, 40), TextColor3 = Color3.fromRGB(195, 145, 255) }):Play()
    end)

    local function ListPlayers() local names = {}; for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then table.insert(names, p.Name) end end; table.sort(names); return names end
    local options = ListPlayers(); local idx = 1; if #options > 0 then tpSelectedPlayer = options[1]; btn.Text = options[1] end
    btn.MouseButton1Click:Connect(function()
        options = ListPlayers()
        if #options == 0 then btn.Text = "-"; tpSelectedPlayer = nil; return end
        idx = idx % #options + 1; btn.Text = options[idx]; tpSelectedPlayer = options[idx]
    end)
end
local tpRefresh = mk("TextButton", { Size = UDim2.new(1, -12, 0, 30), BackgroundColor3 = Color3.fromRGB(28, 24, 38), BorderSizePixel = 0, Text = "⟳ REFRESH PLAYER LIST", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Theme.FontBold, TextSize = 10, AutoButtonColor = false, Parent = tpPlayerCard, ZIndex = 15 }); corner(tpRefresh, 8); stroke(tpRefresh, Color3.fromRGB(160, 80, 255), 1)
local tpGo = mk("TextButton", { Size = UDim2.new(1, -12, 0, 32), BackgroundColor3 = Color3.fromRGB(24, 18, 34), BorderSizePixel = 0, Text = "TELEPORT TO PLAYER ›", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Theme.FontBold, TextSize = 10, AutoButtonColor = false, Parent = tpPlayerCard, ZIndex = 15 }); corner(tpGo, 8); stroke(tpGo, Color3.fromRGB(160, 80, 255), 1)

tpRefresh.MouseButton1Click:Connect(function()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then table.insert(names, p.Name) end end
    table.sort(names)
    pcall(function() StarterGui:SetCore("SendNotification", { Title = "Refresh", Text = #names .. " player ditemukan.", Duration = 2 }) end)
end)
tpGo.MouseButton1Click:Connect(function()
    if not tpSelectedPlayer or tpSelectedPlayer == "" then return end
    local target = Players:FindFirstChild(tpSelectedPlayer)
    if not target or not target.Character then return end
    local thrp = target.Character:FindFirstChild("HumanoidRootPart")
    local myhrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not thrp or not myhrp then return end
    myhrp.Anchored = true
    myhrp.CFrame = CFrame.new(thrp.Position + Vector3.new(0, 3, 0))
    task.wait(0.15)
    myhrp.Anchored = false
    myhrp.Velocity = Vector3.zero
end)
task.spawn(function() task.wait(2); TP_Scan(true) end)
workspace.ChildAdded:Connect(function(child) if child.Name == "Map" then task.wait(1); TP_Scan(true) end end)

-- ============================================================
-- KILLER EXTRAS
-- ============================================================
local KillerExtras = { AutoStalk = { Enabled = false, Range = 150, Conn = nil, LastFire = 0 }, CounterParry = { Enabled = false, Distance = 15, Interval = 0.3, AnimId = "rbxassetid://117042998468241", Thread = nil, Track = nil }, NoSlowdown = { Enabled = false } }
local function KE_GetRole() if not LP.Team then return "Unknown" end; local n = LP.Team.Name; if n == "Killer" then return "Killer" end; if n == "Survivors" then return "Survivor" end; return "Spectator" end
local function KE_StalkRemote() local r = ReplicatedStorage:FindFirstChild("Remotes"); local k = r and r:FindFirstChild("Killers"); local s = k and k:FindFirstChild("Stalker"); return s and s:FindFirstChild("StartStalking") end
local function KE_FindStalkTarget()
    local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local best, short = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local phrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and phrp and hum.Health > 30 then
                local d = (phrp.Position - hrp.Position).Magnitude
                if d <= KillerExtras.AutoStalk.Range and d < short then short = d; best = p end
            end
        end
    end
    return best
end
local function KE_StartStalk()
    if KillerExtras.AutoStalk.Conn then return end
    KillerExtras.AutoStalk.Conn = RunService.Heartbeat:Connect(function()
        if not KillerExtras.AutoStalk.Enabled then return end
        if KE_GetRole() ~= "Killer" then return end
        local now = tick()
        if now - KillerExtras.AutoStalk.LastFire < 0.35 then return end
        local target = KE_FindStalkTarget()
        if not target then return end
        local remote = KE_StalkRemote()
        if not remote then return end
        KillerExtras.AutoStalk.LastFire = now
        pcall(function() remote:FireServer(target) end)
    end)
end
local function KE_StopStalk() KillerExtras.AutoStalk.Enabled = false; if KillerExtras.AutoStalk.Conn then KillerExtras.AutoStalk.Conn:Disconnect(); KillerExtras.AutoStalk.Conn = nil end end
local function KE_StopCounterParry() KillerExtras.CounterParry.Enabled = false; if KillerExtras.CounterParry.Thread then task.cancel(KillerExtras.CounterParry.Thread); KillerExtras.CounterParry.Thread = nil end; if KillerExtras.CounterParry.Track then pcall(function() KillerExtras.CounterParry.Track:Stop() end); KillerExtras.CounterParry.Track = nil end end
local function KE_StartCounterParry()
    if KillerExtras.CounterParry.Thread then return end
    KillerExtras.CounterParry.Thread = task.spawn(function()
        while KillerExtras.CounterParry.Enabled do if not GUIAnim.On then return end
            local char = LP.Character
            if char and char.Parent and KE_GetRole() == "Killer" then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local animator = hum and hum:FindFirstChildOfClass("Animator")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if animator and hrp then
                    if not KillerExtras.CounterParry.Track or not KillerExtras.CounterParry.Track.Parent then
                        local ok, track = pcall(function()
                            local a = Instance.new("Animation"); a.AnimationId = KillerExtras.CounterParry.AnimId
                            return animator:LoadAnimation(a)
                        end)
                        if ok then KillerExtras.CounterParry.Track = track end
                    end
                    if KillerExtras.CounterParry.Track then
                        local found = false
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LP and p.Team and p.Team.Name == "Survivors" and p.Character then
                                local phrp = p.Character:FindFirstChild("HumanoidRootPart")
                                if phrp and (phrp.Position - hrp.Position).Magnitude <= KillerExtras.CounterParry.Distance then found = true; break end
                            end
                        end
                        if found then
                            pcall(function() KillerExtras.CounterParry.Track:Play(); KillerExtras.CounterParry.Track:AdjustWeight(0) end)
                            task.wait(0.05)
                            pcall(function() KillerExtras.CounterParry.Track:Stop() end)
                        end
                    end
                end
            end
            task.wait(KillerExtras.CounterParry.Interval)
        end
        KillerExtras.CounterParry.Thread = nil
    end)
end
task.spawn(function()
    while true do
        task.wait(0.2)
        if KillerExtras.NoSlowdown.Enabled and KE_GetRole() == "Killer" then
            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
        end
    end
end)

-- ============================================================
-- MAIN TAB
-- ============================================================
local Purple = Color3.fromRGB(160, 80, 255); local PurpleDark = Color3.fromRGB(65, 25, 120); local Green = Color3.fromRGB(70, 255, 130); local Orange = Color3.fromRGB(255, 190, 100); local Muted = Color3.fromRGB(155, 150, 175)
local DEVELOPER_NAME = "HANX HUB"; local SCRIPT_VERSION = "V3 — Supported by Mimiw Hub"
local function MainLabel(parent, text, height, color, bold, textSize) return mk("TextLabel", { Size = UDim2.new(1, 0, 0, height or 20), BackgroundTransparency = 1, Text = text, TextColor3 = color or Theme.Text, Font = bold and Theme.FontBold or Theme.Font, TextSize = textSize or 11, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true, Parent = parent, ZIndex = 15 }) end
local function MainSection(parent, text) return MainLabel(parent, string.upper(text), 17, Muted, true, 10) end
local function MainButton(parent, title, url, accent)
    local button = mk("TextButton", { Size = UDim2.new(1, -12, 0, 34), BackgroundColor3 = Color3.fromRGB(28, 24, 38), BorderSizePixel = 0, Text = title .. " ›", TextColor3 = Theme.Text, TextSize = 10, Font = Theme.FontBold, AutoButtonColor = false, Parent = parent, ZIndex = 15 }); corner(button, 8); stroke(button, accent or Purple, 1)
    button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(48, 34, 65) }):Play() end)
    button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(28, 24, 38) }):Play() end)
    button.MouseButton1Click:Connect(function()
        local copied = false
        if typeof(setclipboard) == "function" then copied = pcall(setclipboard, url) end
        pcall(function() StarterGui:SetCore("SendNotification", { Title = "HANX HUB", Text = copied and (title .. " link copied!") or "Clipboard unavailable.", Duration = 3 }) end)
    end)
    return button
end

local heroCard = Window:AddCard(TabMain.Left, "✦", "WELCOME")
MainLabel(heroCard, "HANX HUB", 32, Theme.Text, true, 22)
MainLabel(heroCard, "VIOLENCE DISTRICT SCRIPT", 20, Purple, true, 11)
MainLabel(heroCard, "More Power. More Control.", 22, Muted, false, 11)
local statusFrame = mk("Frame", { Size = UDim2.new(1, -12, 0, 38), BackgroundColor3 = Color3.fromRGB(25, 38, 30), BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = heroCard, ZIndex = 15 }); corner(statusFrame, 8)
local statusDot = mk("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.new(0, 11, 0.5, -4), BackgroundColor3 = Green, BorderSizePixel = 0, Parent = statusFrame, ZIndex = 16 }); corner(statusDot, 8)
mk("TextLabel", { Size = UDim2.new(1, -36, 1, 0), Position = UDim2.fromOffset(26, 0), BackgroundTransparency = 1, Text = "HANX HUB | INTERFACE LOADED", TextColor3 = Green, TextSize = 10, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = statusFrame, ZIndex = 16 })
MainSection(heroCard, "Script Version"); MainLabel(heroCard, SCRIPT_VERSION, 22, Purple, true, 14)
MainLabel(heroCard, "Welcome to the official HANX HUB interface.", 30, Muted, false, 10)

local playerCard = Window:AddCard(TabMain.Right, "◎", "SESSION")
MainSection(playerCard, "Player"); MainLabel(playerCard, LP.DisplayName, 25, Theme.Text, true, 16); MainLabel(playerCard, "@" .. LP.Name, 17, Muted, false, 10)
MainSection(playerCard, "Current Game"); MainLabel(playerCard, "Violence District", 22, Theme.Text, true, 13)
MainSection(playerCard, "Session Status"); MainLabel(playerCard, "● Connected", 20, Green, true, 11)
MainSection(playerCard, "Community"); MainLabel(playerCard, "HANX HUB Official Community", 25, Muted, false, 10)

local devCard = Window:AddCard(TabMain.Left, "♙", "DEVELOPER")
MainLabel(devCard, DEVELOPER_NAME, 28, Theme.Text, true, 18)
MainLabel(devCard, "CREATOR & DEVELOPER", 20, Purple, true, 10)
MainLabel(devCard, "Developing scripts and features for Violence District.", 42, Muted, false, 11)
MainSection(devCard, "Our Mission")
MainLabel(devCard, "Building a better experience for the HANX HUB community.", 42, Theme.Text, false, 11)
MainLabel(devCard, "THANK YOU FOR YOUR SUPPORT!", 24, Green, true, 10)

local socialCard = Window:AddCard(TabMain.Right, "◇", "SOCIAL LINKS")
MainLabel(socialCard, "Follow and join our official community.", 30, Muted, false, 11)
MainButton(socialCard, "DISCORD - JOIN COMMUNITY", "https://discord.gg/Gz5pRBTUx", Color3.fromRGB(88, 101, 242))
MainButton(socialCard, "TIKTOK - FOLLOW DEVELOPER", "https://www.tiktok.com/@whoohnbro_", Color3.fromRGB(70, 70, 80))
MainButton(socialCard, "WHATSAPP - JOIN CHANNEL", "https://whatsapp.com/channel/0029Vb94hQl3LdQTdlkiCf0P", Color3.fromRGB(30, 150, 85))
MainLabel(socialCard, "STAY CONNECTED WITH HANX HUB", 22, Purple, true, 10)

local donateCard = Window:AddCard(TabMain.Left, "♡", "SUPPORT & DONATION")
MainLabel(donateCard, "Enjoying HANX HUB?", 26, Theme.Text, true, 15)
MainLabel(donateCard, "Your support helps us continue developing and improving the project.", 48, Muted, false, 11)
MainButton(donateCard, "DONATE VIA SAWERIA", "https://saweria.co/HANXHUB", PurpleDark)
MainLabel(donateCard, "THANK YOU FOR YOUR SUPPORT!", 24, Orange, true, 10)
MainLabel(donateCard, "Every contribution means a lot.", 22, Muted, false, 10)

local infoCard = Window:AddCard(TabMain.Right, "ⓘ", "SCRIPT DETAILS")
MainSection(infoCard, "Project"); MainLabel(infoCard, "HANX HUB", 22, Theme.Text, true, 13)
MainSection(infoCard, "Supported Game"); MainLabel(infoCard, "Violence District", 22, Theme.Text, true, 12)
MainSection(infoCard, "Developer"); MainLabel(infoCard, DEVELOPER_NAME, 22, Theme.Text, true, 12)
MainSection(infoCard, "Version"); MainLabel(infoCard, SCRIPT_VERSION, 22, Purple, true, 13)
MainSection(infoCard, "Community"); MainLabel(infoCard, "HANX HUB OFFICIAL", 22, Muted, true, 10)

-- SURVIVOR
local survCard = Window:AddCard(TabSurvivor.Left, "⚡", "Survivor Features")
local function AddSectionDivider(card, title) mk("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "─── " .. title .. " ───", TextColor3 = Theme.Accent, Font = Theme.FontBold, TextSize = 10, Parent = card, ZIndex = 15 }) end

AddSectionDivider(survCard, "MOVEMENT")
Window:AddToggle(survCard, "Fast Vault", false, function(v) FastVaultEnabled = v end)

AddSectionDivider(survCard, "SKILL CHECK — TIANHUB")
Window:AddToggle(survCard, "Auto Skill Check", false, function(v)
    AutoSkill.Active = v
    if not v then AS_Reset(); AS_ApplySpeed(false) end
end)
Window:AddDropdown(survCard, "Skillcheck Method", { "Normal", "Perfect", "Instant" }, "Normal", function(v)
    AutoSkill.Mode = v
    AS_Reset()
end)
Window:AddSlider(survCard, "Skill Check Speed", 0.1, 3, 1, function(v)
    AutoSkill.Speed = v
end)
Window:AddToggle(survCard, "Hide Skill UI", false, function(v)
    AutoSkill.HideUI = v
    AS_HideUI()
end)

AddSectionDivider(survCard, "PISTOL — SILENT AIM TOF")
Window:AddToggle(survCard, "Enable Silent Aim TOF", false, function(v)
    local api = getgenv().TianHub_TOF
    if api and api.setEnabled then api.setEnabled(v) end
end)
Window:AddToggle(survCard, "Predict Move", false, function(v)
    local api = getgenv().TianHub_TOF
    if api and api.setPredict then api.setPredict(v) end
end)
Window:AddToggle(survCard, "Hide FOV", false, function(v)
    local api = getgenv().TianHub_TOF
    if api and api.setShowFOV then api.setShowFOV(not v) end
end)
Window:AddToggle(survCard, "Show Aim Laser", false, function(v)
    local api = getgenv().TianHub_TOF
    if api and api.setShowLaser then api.setShowLaser(v) end
end)
Window:AddSlider(survCard, "FOV Range", 10, 360, 120, function(v)
    local api = getgenv().TianHub_TOF
    if api and api.setFOV then api.setFOV(v) end
end)

local parryCard = Window:AddCard(TabSurvivor.Right, "🛡", "Auto Parry V2")
Window:AddToggle(parryCard, "Enable Auto Parry", false, function(v) AP.SetEnabled(v) end)
Window:AddSlider(parryCard, "Parry Range", 5, 35, 14, function(v) AP.SetRange(v) end)
Window:AddSlider(parryCard, "Face Sensitivity", 0, 10, 10, function(v) AP.SetFaceSensitivity(v) end)
Window:AddToggle(parryCard, "Aggressive Mode", false, function(v) AP.SetAggressiveMode(v) end)
Window:AddToggle(parryCard, "Range Circle", false, function(v) AP.SetRangeESP(v) end)

-- KILLER
local killerCard = Window:AddCard(TabKiller.Left, "✂", "Killer Features")
-- TianHub Silent Veil controls adapted to HanxHub's Window UI API.
local veilSettings = getgenv().TianHubSilentVeilSettings
local veilAimSettings = getgenv().KinonSilentSpearSettings
Window:AddToggle(killerCard, "Enable Veil", false, function(v)
    if veilSettings then veilSettings.Enabled = v == true end
end)
Window:AddToggle(killerCard, "Show Aim FOV", true, function(v)
    if veilAimSettings then veilAimSettings.ShowAimFOV = v == true end
end)
Window:AddToggle(killerCard, "FOV Check", true, function(v)
    if veilSettings then veilSettings.ShowFOV = v == true end
end)
Window:AddSlider(killerCard, "FOV Size", 30, 600, 240, function(v)
    if veilSettings then veilSettings.FOVRadius = v end
end)
Window:AddSlider(killerCard, "Max Range", 50, 1000, 500, function(v)
    if veilAimSettings then veilAimSettings.MaxRange = v end
end)
Window:AddSlider(killerCard, "Shot Speed", 60, 180, 180, function(v)
    if veilAimSettings then veilAimSettings.SpearSpeed = v end
end)
Window:AddSlider(killerCard, "Shot Drop", 0, 1, 0.5, function(v)
    if veilAimSettings then veilAimSettings.Drop = v end
end)
Window:AddToggle(killerCard, "Aim Prediction", true, function(v)
    if veilAimSettings then veilAimSettings.Predict = v == true end
end)

local killerExtraCard = Window:AddCard(TabKiller.Right, "⚙", "Killer Extras")
Window:AddToggle(killerExtraCard, "Auto Stalk", false, function(v)
    KillerExtras.AutoStalk.Enabled = v
    if v then
        if KE_GetRole() ~= "Killer" then KillerExtras.AutoStalk.Enabled = false; return end
        KE_StartStalk()
    else
        KE_StopStalk()
    end
end)
Window:AddSlider(killerExtraCard, "Stalk Range", 50, 400, 150, function(v) KillerExtras.AutoStalk.Range = v end)
Window:AddToggle(killerExtraCard, "Counter Auto Parry", false, function(v)
    KillerExtras.CounterParry.Enabled = v
    if v then
        if KE_GetRole() ~= "Killer" then KillerExtras.CounterParry.Enabled = false; return end
        KE_StartCounterParry()
    else
        KE_StopCounterParry()
    end
end)
Window:AddSlider(killerExtraCard, "Parry Distance", 5, 30, 15, function(v) KillerExtras.CounterParry.Distance = v end)
Window:AddToggle(killerExtraCard, "No Slowdown Killer", false, function(v) KillerExtras.NoSlowdown.Enabled = v end)

-- VISUAL
local espCard = Window:AddCard(TabVisual.Left, "👁", "ESP Settings")
Window:AddToggle(espCard, "Enable ESP", false, function(v)
    ESP.Master = v
    if v then ScanMap(true); startESPLoop() else ClearAllESP(); if espConn then espConn:Disconnect(); espConn = nil end end
end)
Window:AddSlider(espCard, "ESP Max Distance", 100, 5000, 1000, function(v) ESP.MaxDistance = v end)
Window:AddCheckbox(espCard, "Player ESP", false, Color3.fromRGB(50, 200, 100), function(v) ESP.Player = v end, function(c) ESPColors.Player = c end)
Window:AddCheckbox(espCard, "Killer ESP", false, Color3.fromRGB(255, 50, 50), function(v) ESP.Killer = v end, function(c) ESPColors.Killer = c end)
Window:AddCheckbox(espCard, "ESP Name", false, Color3.fromRGB(255, 255, 255), function(v) ESP.Name = v end, function(c) ESPColors.Name = c end)
Window:AddCheckbox(espCard, "ESP Distance", false, Color3.fromRGB(255, 255, 255), function(v) ESP.Distance = v end, function(c) ESPColors.Distance = c end)
Window:AddCheckbox(espCard, "Generator ESP", false, Color3.fromRGB(255, 255, 0), function(v) ESP.Generator = v end, function(c) ESPColors.Generator = c end)

local DefaultLighting = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, FogColor = Lighting.FogColor,
    GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
}

local function ClearFog(on)
    if on then
        Lighting.FogEnd = 1e9; Lighting.FogStart = 1e9
        Lighting.FogColor = Color3.fromRGB(255, 255, 255)
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then atm.Density = 0; atm.Haze = 0 end
    else
        Lighting.FogEnd = DefaultLighting.FogEnd; Lighting.FogStart = DefaultLighting.FogStart
        Lighting.FogColor = DefaultLighting.FogColor; Lighting.Ambient = DefaultLighting.Ambient
        Lighting.OutdoorAmbient = DefaultLighting.OutdoorAmbient
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then atm.Density = 0.3 end
    end
end

local function FullBright(on)
    if on then
        Lighting.Brightness = 3; Lighting.ClockTime = 12; Lighting.GlobalShadows = false
    else
        Lighting.Brightness = DefaultLighting.Brightness; Lighting.ClockTime = DefaultLighting.ClockTime
        Lighting.GlobalShadows = DefaultLighting.GlobalShadows
    end
end

local worldCard = Window:AddCard(TabVisual.Right, "🏆", "World Effects")
Window:AddToggle(worldCard, "Hapus Kabut & Cerah", false, function(v) ClearFog(v); FullBright(v) end)
Window:AddToggle(worldCard, "No Fog Only", false, function(v) ClearFog(v) end)
Window:AddToggle(worldCard, "Full Bright Only", false, function(v) FullBright(v) end)
Window:AddSlider(worldCard, "Time Of Day", 0, 24, 12, function(v) Lighting.ClockTime = v end)
Window:AddToggle(worldCard, "No Shadow", false, function(v) Lighting.GlobalShadows = not v end)
-- ============================================================
-- ANTI LAG (LOW GRAPHICS)
-- ============================================================
local AntiLag = { On = false, Saved = {} }

local function AntiLagApply(on)
    AntiLag.On = on
    local lighting = game:GetService("Lighting")

    if on then
        for _, obj in ipairs(lighting:GetChildren()) do
            if obj:IsA("PostEffect") or obj:IsA("Atmosphere") then
                if AntiLag.Saved[obj] == nil then
                    AntiLag.Saved[obj] = obj:IsA("Atmosphere") and obj.Density or obj.Enabled
                end
                if obj:IsA("Atmosphere") then obj.Density = 0 else obj.Enabled = false end
            end
        end
        AntiLag.Saved.Shadows = lighting.GlobalShadows
        lighting.GlobalShadows = false
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    else
        for obj, value in pairs(AntiLag.Saved) do
            if typeof(obj) == "Instance" and obj.Parent then
                if obj:IsA("Atmosphere") then obj.Density = value else obj.Enabled = value end
            end
        end
        if AntiLag.Saved.Shadows ~= nil then lighting.GlobalShadows = AntiLag.Saved.Shadows end
        AntiLag.Saved = {}
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    end
end

Window:AddToggle(worldCard, "Anti Lag (Low Graphics)", false, function(v)
    AntiLagApply(v)
end)

local PerfMode = { On = false, Saved = {}, Conn = nil }

local function perfIsCharacter(obj)
    local char = LP.Character
    return char and obj:IsDescendantOf(char)
end

local function perfApply(obj)
    if perfIsCharacter(obj) then return end

    if obj:IsA("BasePart") then
        if PerfMode.Saved[obj] == nil then
            PerfMode.Saved[obj] = {
                Kind = "part", Material = obj.Material, Color = obj.Color,
                Reflectance = obj.Reflectance, CastShadow = obj.CastShadow,
            }
        end
        obj.Material = Enum.Material.SmoothPlastic
        obj.Reflectance = 0
        obj.CastShadow = false
        -- Kurangi saturasi warna (tanpa mengubah kecerahan)
        local h, s, v = obj.Color:ToHSV()
        obj.Color = Color3.fromHSV(h, s * 0.15, v)

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        if PerfMode.Saved[obj] == nil then
            PerfMode.Saved[obj] = { Kind = "decal", Transparency = obj.Transparency }
        end
        obj.Transparency = 1

    elseif obj:IsA("SurfaceAppearance") then
        if PerfMode.Saved[obj] == nil then
            PerfMode.Saved[obj] = { Kind = "sa", Parent = obj.Parent }
        end
        obj.Parent = nil

    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
        if PerfMode.Saved[obj] == nil then
            PerfMode.Saved[obj] = { Kind = "fx", Enabled = obj.Enabled }
        end
        obj.Enabled = false
    end
end

local function perfRestore()
    for obj, d in pairs(PerfMode.Saved) do
        if typeof(obj) == "Instance" and obj.Parent then
            if d.Kind == "part" then
                obj.Material = d.Material
                obj.Color = d.Color
                obj.Reflectance = d.Reflectance
                obj.CastShadow = d.CastShadow
            elseif d.Kind == "decal" then
                obj.Transparency = d.Transparency
            elseif d.Kind == "sa" then
                obj.Parent = d.Parent
            elseif d.Kind == "fx" then
                obj.Enabled = d.Enabled
            end
        end
    end
    PerfMode.Saved = {}
end

local function PerfApply(on)
    PerfMode.On = on
    if on then
        for _, d in ipairs(workspace:GetDescendants()) do pcall(perfApply, d) end
        PerfMode.Conn = workspace.DescendantAdded:Connect(function(d)
            if PerfMode.On then pcall(perfApply, d) end
        end)
    else
        if PerfMode.Conn then PerfMode.Conn:Disconnect(); PerfMode.Conn = nil end
        perfRestore()
    end
end

Window:AddToggle(worldCard, "Performance Mode", false, function(v)
    PerfApply(v)
end)

-- SETTINGS
local settingsMainCard = Window:AddCard(TabSettings.Left, "⚙", "Global Settings & Utilities")
local scrollFrame = mk("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -26), Position = UDim2.fromOffset(0, 26), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = settingsMainCard, ZIndex = 14 })
mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scrollFrame })

local function AddDivider(text)
    mk("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "─── " .. text .. " ───", TextColor3 = Theme.Accent, Font = Theme.FontBold, TextSize = 10, Parent = scrollFrame, ZIndex = 15 })
end

AddDivider("INTERFACE")
Window:AddToggle(scrollFrame, "Hide UI (Right Shift)", false, function(v) Window.Gui.Enabled = not v end)
Window:AddSlider(scrollFrame, "UI Transparency", 0, 100, 35, function(v) local r = Window.Root; if r then r.BackgroundTransparency = v / 100 end end)
Window:AddToggle(scrollFrame, "GUI Animations", true, function(v)
    GUIAnim.On = v
end)
AddDivider("GAMEPLAY UTILITIES")
Window:AddToggle(scrollFrame, "Anti AFK", true, function(v)
    if getgenv().HANX_AntiAFK then getgenv().HANX_AntiAFK:Disconnect(); getgenv().HANX_AntiAFK = nil end
    if v then
        local vu = game:GetService("VirtualUser")
        getgenv().HANX_AntiAFK = LP.Idled:Connect(function() vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)
    end
end)
Window:AddToggle(scrollFrame, "Fast Teleport (No Tween)", false, function(v) _G.HANX_FastTP = v end)

AddDivider("SHORTCUTS INFO")
mk("TextLabel", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = "Right Shift : Hide/Show UI\nF9 : Developer Console", TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = scrollFrame, ZIndex = 15 })

UIS.InputBegan:Connect(function(input, gp) if not gp and input.KeyCode == Enum.KeyCode.RightShift then Window.Gui.Enabled = not Window.Gui.Enabled end end)

local settingsRight = Window:AddCard(TabSettings.Right, "✦", "Quick Actions")
local function SettingsBtn(text, callback)
    local btn = mk("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Text = text, TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 10, AutoButtonColor = false, Parent = settingsRight, ZIndex = 15 })
    corner(btn, 6); stroke(btn, Theme.Accent, 1)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Panel }):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Bg }):Play() end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end
SettingsBtn("HIDE MENU (MINIMIZE)", function() Window.ToggleMin() end)
SettingsBtn("REJOIN SERVER", function() game:GetService("TeleportService"):Teleport(game.PlaceId, LP) end)
SettingsBtn("CLEAR ALL ESP", function() if ClearAllESP then ClearAllESP() end end)

local infoCardS = Window:AddCard(TabSettings.Right, "ⓘ", "Script Info")
MainSection(infoCardS, "VERSION")
MainLabel(infoCardS, "HANX HUB V3 — FINAL", 22, Theme.Accent, true, 13)
MainSection(infoCardS, "STATUS")
MainLabel(infoCardS, "● Loaded & Running", 22, Color3.fromRGB(70, 255, 130), true, 11)
MainSection(infoCardS, "NOTE")
MainLabel(infoCardS, "Jika UI tidak merespon, tekan Right Shift untuk menyembunyikan/menampilkan menu.", 44, Muted, false, 10)

-- ============================================================
-- AUTO PALLET
-- ============================================================
AutoPalletEnabled = false
AutoPalletRadius = 15
AutoPalletCooldown = 1.5
local LastDropTime = 0
local PalletCandidates = {}
local PalletScanAt = 0
local PalletScanInterval = 0.75

local function GetKiller()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Team and player.Team.Name == "Killer" and player.Character then
            local character = player.Character
            local root = character:FindFirstChild("HumanoidRootPart")
            local hum = character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then return player, character, root end
        end
    end
    return nil, nil, nil
end

local function ResolvePallet(candidate)
    if not candidate or not candidate:IsDescendantOf(workspace) then return nil end
    local model = candidate:IsA("Model") and candidate or candidate:FindFirstAncestorOfClass("Model")
    if not model then return nil end
    local hitbox = model:FindFirstChild("hitbox", true) or model:FindFirstChild("Hitbox", true) or model:FindFirstChild("PrimaryPartPallet", true) or model.PrimaryPart
    if hitbox and not hitbox:IsA("BasePart") then hitbox = hitbox:FindFirstChildWhichIsA("BasePart", true) end
    if not hitbox then hitbox = model:FindFirstChildWhichIsA("BasePart", true) end
    if not hitbox then return nil end
    return { model = model, hitbox = hitbox }
end

local function PalletStateAvailable(data)
    if not data or not data.model or not data.hitbox then return false, false end
    local explicitState = false
    local nodes = { data.model, data.hitbox }
    for _, node in ipairs(nodes) do
        for attribute, value in pairs(node:GetAttributes()) do
            local key = string.lower(tostring(attribute))
            if key == "available" or key == "isavailable" or key == "ready" then explicitState = true; if value == false then return false, true end
            elseif key == "dropped" or key == "isdropped" or key == "used" or key == "isused" or key == "palletdown" or key == "isdown" then explicitState = true; if value == true then return false, true end
            elseif key == "palletstate" or key == "state" then
                if type(value) == "string" then
                    local state = string.lower(value)
                    if state:find("drop") or state:find("down") or state:find("used") then return false, true
                    elseif state:find("ready") or state:find("up") or state:find("available") then explicitState = true end
                end
            end
        end
    end
    for _, node in ipairs(data.model:GetDescendants()) do
        if node:IsA("BoolValue") then
            local key = string.lower(node.Name)
            if key == "available" or key == "isavailable" or key == "ready" then explicitState = true; if node.Value == false then return false, true end
            elseif key == "dropped" or key == "isdropped" or key == "used" or key == "isused" or key == "palletdown" or key == "isdown" then explicitState = true; if node.Value == true then return false, true end end
        end
    end
    return true, explicitState
end

local function RefreshPalletCandidates(force)
    local now = os.clock()
    if not force and now - PalletScanAt < PalletScanInterval then return end
    PalletScanAt = now
    local candidates, seen = {}, {}
    local function addCandidate(instance) local data = ResolvePallet(instance); if data and not seen[data.model] then seen[data.model] = true; table.insert(candidates, data.model) end end
    for _, tagged in ipairs(CollectionService:GetTagged("pallet")) do addCandidate(tagged) end
    local map = workspace:FindFirstChild("Map") or workspace
    for _, obj in ipairs(map:GetDescendants()) do local name = string.lower(obj.Name); if name == "pallet" or name == "hitbox" or name == "primarypartpallet" then addCandidate(obj) end end
    PalletCandidates = candidates
end

local function FindClosestPallet(myRoot)
    if not myRoot then return nil, math.huge end
    RefreshPalletCandidates(false)
    local closest, closestDist = nil, math.huge
    for _, model in ipairs(PalletCandidates) do
        if model and model.Parent then
            local data = ResolvePallet(model)
            if data then
                local available, hasState = PalletStateAvailable(data)
                if available and UsedPallets[data.model] and hasState then UsedPallets[data.model] = nil end
                if available and not UsedPallets[data.model] then
                    local distance = (myRoot.Position - data.hitbox.Position).Magnitude
                    if distance < closestDist then closest, closestDist = data, distance end
                end
            end
        end
    end
    return closest, closestDist
end

local function IsKillerChasing(killerRoot, myRoot, distance)
    if not killerRoot or not myRoot then return false end
    local toPlayer = myRoot.Position - killerRoot.Position
    if toPlayer.Magnitude < 0.1 then return false end
    local direction = toPlayer.Unit
    local velocity = killerRoot.AssemblyLinearVelocity
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)
    local closingSpeed = horizontalDirection.Magnitude > 0.1 and horizontalVelocity:Dot(horizontalDirection.Unit) or 0
    local look = killerRoot.CFrame.LookVector
    local horizontalLook = Vector3.new(look.X, 0, look.Z)
    local facingDot = horizontalLook.Magnitude > 0.1 and horizontalDirection.Magnitude > 0.1 and horizontalLook.Unit:Dot(horizontalDirection.Unit) or -1
    local chaseRange = math.max(12, AutoPalletRadius + 5)
    if distance > chaseRange then return false end
    return closingSpeed >= 1.5 or (horizontalVelocity.Magnitude >= 2.5 and facingDot >= 0.65)
end

local function ExecuteDrop(palletData)
    if not palletData or not palletData.model or not palletData.model.Parent or not palletData.hitbox or not palletData.hitbox.Parent then return false end
    local available = PalletStateAvailable(palletData)
    if not available or UsedPallets[palletData.model] then return false end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local palletFolder = remotes and remotes:FindFirstChild("Pallet")
    local dropEvent = palletFolder and palletFolder:FindFirstChild("PalletDropEvent")
    if not dropEvent or not dropEvent:IsA("RemoteEvent") then return false end
    UsedPallets[palletData.model] = true
    local ok = pcall(function() dropEvent:FireServer(palletData.hitbox) end)
    if not ok then UsedPallets[palletData.model] = nil; return false end
    return true
end

task.spawn(function()
    while task.wait(0.1) do
        if not AutoPalletEnabled then continue end
        local _, _, killerRoot = GetKiller()
        local myChar = LP.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not killerRoot or not myRoot or not myHum or myHum.Health <= 0 then continue end
        local killerDistance = (killerRoot.Position - myRoot.Position).Magnitude
        if not IsKillerChasing(killerRoot, myRoot, killerDistance) then continue end
        local palletData, playerPalletDistance = FindClosestPallet(myRoot)
        if not palletData or playerPalletDistance > math.max(5, AutoPalletRadius) then continue end
        local killerPalletDistance = (killerRoot.Position - palletData.hitbox.Position).Magnitude
        local palletThreatRange = math.max(8, AutoPalletRadius * 0.8)
        if killerPalletDistance > palletThreatRange then continue end
        if os.clock() - LastDropTime < AutoPalletCooldown then continue end
        if ExecuteDrop(palletData) then LastDropTime = os.clock() end
    end
end)

-- ============================================================
-- UNLOAD HANDLER
-- ============================================================
getgenv().HANX_Unload = function()
    -- Disconnect the imported TianHub Auto Skillcheck loop on unload/re-execution.
    if TianHubSkillConn then
        pcall(function() TianHubSkillConn:Disconnect() end)
        TianHubSkillConn = nil
    end
    pcall(function() local api = getgenv().TianHub_TOF; if api and api.setEnabled then api.setEnabled(false) end end)
    if AP and AP.Destroy then pcall(AP.Destroy) end
    if type(_G.KinonSilentSpearStandaloneUnload) == "function" then
        pcall(_G.KinonSilentSpearStandaloneUnload)
        _G.KinonSilentSpearStandaloneUnload = nil
    end
    if getgenv().HANX_AntiAFK then getgenv().HANX_AntiAFK:Disconnect(); getgenv().HANX_AntiAFK = nil end
    if Window and Window.Gui then pcall(function() Window.Gui:Destroy() end) end
end

pcall(function()
    StarterGui:SetCore("SendNotification", { Title = "HANX HUB", Text = "Script Loaded Successfully!", Duration = 5 })
end)