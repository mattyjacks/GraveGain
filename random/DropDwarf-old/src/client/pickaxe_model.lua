-- DropDwarf: pickaxe_model.lua
-- Client-side pickaxe orchestrator.
-- Loads viewmodel geometry, triggers camera animations, and binds hits to the collision detector.

local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local Networking = require(game.ReplicatedStorage.Shared.networking)

-- Sub-modules
local ViewModel   = require(script.Parent.pickaxe.viewmodel)
local Animations  = require(script.Parent.pickaxe.animations)
local HitDetector = require(script.Parent.pickaxe.hit_detector)

local PickaxeModel = {}
PickaxeModel.__index = PickaxeModel

local HEAVY_CHARGE_MAX  = 5.0
local HEAVY_CHARGE_TIME = 0.6
local TP_GRIP_CF        = CFrame.new(0, -0.5, -0.8)
    * CFrame.Angles(math.rad(-90), math.rad(180), math.rad(0))

function PickaxeModel.new(camera)
    local self = setmetatable({}, PickaxeModel)
    self.camera         = camera
    self.model          = nil
    self.parts          = {}
    self.connection     = nil
    self.tpConnection   = nil
    self.bobTime        = 0
    self.breathTime     = 0
    self.isSwinging     = false
    self.swingTime      = 0
    self.isHeavySwing   = false
    self.chargeTime     = 0
    self.isCharging     = false
    self.chargePower    = 0
    self.isThirdPerson  = false
    self.hubMode        = true
    self.tpWeld         = nil
    self.chargeBarGui   = nil
    self.baseOffset     = CFrame.new(0.52, -0.72, -1.4)
    self.currentOffset  = self.baseOffset
    self.movementRef    = nil
    self.player         = Players.LocalPlayer
    return self
end

function PickaxeModel:SetMovement(movement)
    self.movementRef = movement
    self.hubMode     = false
end

function PickaxeModel:SetThirdPerson(isTps)
    self.isThirdPerson = isTps
    if isTps then
        self:_AttachToHand()
        if self.root then self.root.CFrame = CFrame.new(0, -9999, 0) end
    else
        self:_DetachFromHand()
    end
end

function PickaxeModel:_AttachToHand()
    local char = self.player and self.player.Character
    if not char then return end
    local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
    if not rightHand or not self.root then return end
    self:_DetachFromHand()
    
    local motor = Instance.new("Motor6D")
    motor.Name   = "PickaxeGrip"
    motor.Part0  = rightHand
    motor.Part1  = self.root
    motor.C0     = TP_GRIP_CF
    motor.C1     = CFrame.new()
    motor.Parent = rightHand
    self.tpWeld  = motor
    if self.root then self.root.Transparency = 1 end
end

function PickaxeModel:_DetachFromHand()
    if self.tpWeld and self.tpWeld.Parent then
        self.tpWeld:Destroy()
    end
    self.tpWeld = nil
    if self.root then self.root.Transparency = 1 end
end

function PickaxeModel:_BuildChargeBar()
    if self.chargeBarGui then return end
    local sg = Instance.new("ScreenGui")
    sg.Name            = "PickaxeChargeBar"
    sg.ResetOnSpawn    = false
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.Parent          = self.player:WaitForChild("PlayerGui")

    local track = Instance.new("Frame")
    track.Name              = "Track"
    track.Size              = UDim2.new(0, 220, 0, 18)
    track.Position          = UDim2.new(0.5, -110, 0.82, 0)
    track.BackgroundColor3  = Color3.fromRGB(20, 20, 25)
    track.BackgroundTransparency = 0.35
    track.BorderSizePixel   = 0
    track.Visible           = false
    track.Parent            = sg
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 6)

    local fill = Instance.new("Frame")
    fill.Name             = "Fill"
    fill.Size             = UDim2.new(0, 0, 1, 0)
    fill.Position         = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = Color3.fromRGB(60, 210, 180)
    fill.BorderSizePixel  = 0
    fill.Parent           = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size                    = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency  = 1
    lbl.Text                    = "CHARGING..."
    lbl.TextColor3              = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeColor3        = Color3.fromRGB(0, 0, 0)
    lbl.TextStrokeTransparency  = 0.4
    lbl.Font                    = Enum.Font.GothamBold
    lbl.TextScaled              = true
    lbl.Parent                  = track

    self.chargeBarGui  = sg
    self.chargeTrack   = track
    self.chargeBarFill = fill
    self.chargeLbl     = lbl
end

function PickaxeModel:_UpdateChargeBar(power)
    if not self.chargeTrack then return end
    self.chargeTrack.Visible = (power > 0)
    if self.chargeBarFill then
        self.chargeBarFill.Size = UDim2.new(power, 0, 1, 0)
        local r = math.floor(power * 220)
        local g = math.floor((1 - power) * 180 + 30)
        self.chargeBarFill.BackgroundColor3 = Color3.fromRGB(r, g, 50)
    end
    if self.chargeLbl then
        if power >= 1 then
            self.chargeLbl.Text = "MAX CHARGE!"
            self.chargeLbl.TextColor3 = Color3.fromRGB(255, 80, 0)
        else
            local pct = math.floor(power * 100)
            self.chargeLbl.Text = "CHARGING " .. pct .. "%"
            self.chargeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

function PickaxeModel:Build()
    local model, root = ViewModel.Build()
    self.model = model
    self.root  = root
end

function PickaxeModel:Destroy()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    if self.tpConnection then
        self.tpConnection:Disconnect()
        self.tpConnection = nil
    end
    self:_DetachFromHand()
    if self.chargeBarGui and self.chargeBarGui.Parent then
        self.chargeBarGui:Destroy()
        self.chargeBarGui = nil
    end
    if self.model then
        self.model:Destroy()
        self.model = nil
    end
end

-- ==================== LOCAL ORE BREAK VFX ====================
local function spawnOreDepletion(pos, oreType, goldEarned)
    for i = 1, 14 do
        local angle = (i / 14) * math.pi * 2
        local spark = Instance.new("Part")
        spark.Name       = "OreSpark"
        spark.Size       = Vector3.new(0.18, 0.18, 0.18)
        spark.Position   = pos
        spark.Color      = Color3.fromRGB(255, 210, 50)
        spark.Material   = Enum.Material.Neon
        spark.Anchored   = false
        spark.CanCollide = false
        spark.CastShadow = false
        spark.Parent     = workspace
        spark.AssemblyLinearVelocity = Vector3.new(
            math.cos(angle) * math.random(8, 18),
            math.random(6, 16),
            math.sin(angle) * math.random(8, 18)
        )
        TweenService:Create(spark, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Transparency = 1, Size = Vector3.new(0.02, 0.02, 0.02) }):Play()
        task.delay(0.75, function() if spark.Parent then spark:Destroy() end end)
    end

    if goldEarned and goldEarned > 0 then
        local billboard = Instance.new("Part")
        billboard.Size        = Vector3.new(0.1, 0.1, 0.1)
        billboard.Position    = pos + Vector3.new(0, 2, 0)
        billboard.Anchored    = true
        billboard.CanCollide  = false
        billboard.Transparency = 1
        billboard.CastShadow  = false
        billboard.Parent      = workspace
        
        local bg = Instance.new("BillboardGui")
        bg.Size           = UDim2.new(0, 80, 0, 32)
        bg.StudsOffset    = Vector3.new(0, 1, 0)
        bg.Parent         = billboard
        
        local lbl = Instance.new("TextLabel")
        lbl.Size          = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text          = "+" .. goldEarned .. " GOLD"
        lbl.TextColor3    = Color3.fromRGB(255, 215, 50)
        lbl.TextStrokeColor3 = Color3.fromRGB(80, 50, 0)
        lbl.TextStrokeTransparency = 0.4
        lbl.Font          = Enum.Font.GothamBold
        lbl.TextScaled    = true
        lbl.Parent        = bg

        TweenService:Create(billboard, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = pos + Vector3.new(0, 6, 0) }):Play()
        TweenService:Create(lbl, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
        task.delay(1.5, function() if billboard.Parent then billboard:Destroy() end end)
    end
end

local function spawnOreCrack(pos, hpLeft, hpMax)
    local crackColor = Color3.fromRGB(
        math.floor(255 * (1 - hpLeft / hpMax)),
        math.floor(200 * (hpLeft / hpMax)),
        50
    )
    local flash = Instance.new("Part")
    flash.Size        = Vector3.new(1.2, 1.2, 0.05)
    flash.CFrame      = CFrame.new(pos)
    flash.Anchored    = true
    flash.CanCollide  = false
    flash.CastShadow  = false
    flash.Color       = crackColor
    flash.Material    = Enum.Material.Neon
    flash.Transparency = 0.3
    flash.Parent      = workspace

    TweenService:Create(flash, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Transparency = 1, Size = Vector3.new(2, 2, 0.02) }):Play()
    task.delay(0.4, function() if flash.Parent then flash:Destroy() end end)
end

function PickaxeModel:Start(isMovingFn, isFallingFn)
    local alreadyRunning = (self.model ~= nil)

    if not alreadyRunning then
        self:Build()
        self:_BuildChargeBar()
    end

    self.isMovingFn  = isMovingFn  or function() return false end
    self.isFallingFn = isFallingFn or function() return false end

    if alreadyRunning then return end
    self.hubMode = true

    -- Left click to mine
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or self.hubMode then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not self.isSwinging then
                self.isCharging  = true
                self.chargeTime  = 0
                self.chargePower = 0
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.isCharging and not self.hubMode then
                self.isCharging   = false
                self.isHeavySwing = self.chargeTime >= HEAVY_CHARGE_TIME
                self.chargePower  = math.min(self.chargeTime / HEAVY_CHARGE_MAX, 1)
                self:_UpdateChargeBar(0)
                self:Swing(self.isHeavySwing)

                local char = self.player and self.player.Character
                if char then
                    local hit = HitDetector.Raycast(self.camera, char)
                    if hit then
                        HitDetector.Process(self, hit, self.isHeavySwing, self.chargePower)
                    end
                end

                if self.isThirdPerson then
                    Animations.PlayTPSSwing(self.player, self.isHeavySwing)
                end
            end
        end
    end)

    Networking.OnClient(Networking.Events.WallMined, function(pos, oreType, goldEarned, hpLeft, hpMax)
        if goldEarned and goldEarned > 0 then
            spawnOreDepletion(pos, oreType, goldEarned)
        else
            spawnOreCrack(pos, hpLeft or 1, hpMax or 2)
        end
    end)

    Networking.OnClient(Networking.Events.SpawnMiningNugget, function(pos, oreType)
        -- Spawn a beautiful flying physical gold/gem nugget!
        local nug = Instance.new("Part")
        nug.Name = "MiningNugget"
        nug.Size = Vector3.new(0.6, 0.5, 0.6)
        nug.Position = pos + Vector3.new(0, 0.5, 0)
        nug.Material = Enum.Material.Neon
        
        -- Colored based on oreType (Gold, Ruby, Emerald, Sapphire, Amethyst, Diamond)
        if oreType == "Ruby" then
            nug.Color = Color3.fromRGB(255, 30, 30)
        elseif oreType == "Emerald" then
            nug.Color = Color3.fromRGB(30, 255, 30)
        elseif oreType == "Sapphire" then
            nug.Color = Color3.fromRGB(30, 100, 255)
        elseif oreType == "Amethyst" then
            nug.Color = Color3.fromRGB(200, 50, 255)
        elseif oreType == "Diamond" then
            nug.Color = Color3.fromRGB(150, 240, 255)
        else -- Gold/Default
            nug.Color = Color3.fromRGB(255, 210, 30)
        end
        
        nug.Anchored = false
        nug.CanCollide = true
        nug.CastShadow = true
        nug.Parent = workspace
        
        -- Dynamic lighting on the nugget
        local pl = Instance.new("PointLight")
        pl.Color = nug.Color
        pl.Range = 10
        pl.Brightness = 2.5
        pl.Parent = nug
        
        -- Fly out with physical velocity
        nug.AssemblyLinearVelocity = Vector3.new(
            math.random(-12, 12),
            math.random(15, 25),
            math.random(-12, 12)
        )
        
        -- Fade out after 3 seconds
        task.delay(3, function()
            if nug and nug.Parent then
                TweenService:Create(nug, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Transparency = 1
                }):Play()
                TweenService:Create(pl, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Range = 0,
                    Brightness = 0
                }):Play()
                task.delay(1.05, function()
                    if nug and nug.Parent then nug:Destroy() end
                end)
            end
        end)
    end)

    self.connection = RunService.RenderStepped:Connect(function(dt)
        self:Update(dt)
    end)
end

function PickaxeModel:Update(dt)
    if not self.root or not self.camera then return end

    local isMoving  = self.isMovingFn()
    local isFalling = self.isFallingFn()

    -- Charge state
    if self.isCharging then
        self.chargeTime  = math.min(self.chargeTime + dt, HEAVY_CHARGE_MAX)
        self.chargePower = self.chargeTime / HEAVY_CHARGE_MAX
        self:_UpdateChargeBar(self.chargePower)
        
        local runeStrip = self.model and self.model:FindFirstChild("RuneStrip")
        if runeStrip then
            local pulse = 0.1 + 0.6 * self.chargePower
            runeStrip.Transparency = pulse * math.abs(math.sin(tick() * 8))
        end
    end

    -- Animations
    local bobX, bobY, bobRoll, breathX, breathY = Animations.GetBobSway(self, isMoving, isFalling, dt)
    local chargeOffset = Animations.GetChargePullback(self, self.isCharging, self.chargePower)
    local swingOffset  = Animations.GetSwingOffset(self, dt)

    local fallSway = CFrame.new()
    if isFalling then
        fallSway = CFrame.new(0, -0.10, 0.06) * CFrame.Angles(math.rad(18), 0, math.rad(-2))
    end

    local camCF    = self.camera.CFrame
    local targetCF = camCF
        * self.baseOffset
        * CFrame.new(bobX + breathX, -bobY + breathY, 0)
        * CFrame.Angles(0, 0, bobRoll)
        * chargeOffset
        * swingOffset
        * fallSway

    local lerpAlpha = self.isSwinging and 0.38 or 0.22
    self.root.CFrame = self.root.CFrame:Lerp(targetCF, lerpAlpha)
end

function PickaxeModel:Swing(isHeavy)
    if not self.isSwinging then
        self.isSwinging   = true
        self.isHeavySwing = isHeavy or false
        self.swingTime    = 0
    end
end

return PickaxeModel
