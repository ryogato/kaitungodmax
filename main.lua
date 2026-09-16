-- =================================================================
-- ⚡ ULTIMATE MELEE KAITUN (HUB CORE ENGINE)
-- =================================================================

-- 1. Kiểm tra bảng Config của người dùng (Nếu chưa có thì dùng mặc định)
if not getgenv().ConfigDMS then
    getgenv().ConfigDMS = {
        ChooseTeam = "Marines",
        LockFPS = 15,
        AutoBuyHaki = true,
        AutoStats = true,
        AutoSeaTravel = true,
    }
end

local Config = getgenv().ConfigVortexZ

repeat task.wait() until game:IsLoaded()

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    HttpService = game:GetService("HttpService"),
    TeleportService = game:GetService("TeleportService")
}

local LocalPlayer = Services.Players.LocalPlayer
local CommF = Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- Áp dụng khóa FPS từ Config
pcall(function()
    if setfpscap and Config.LockFPS then
        setfpscap(Config.LockFPS)
    end
end)

-- Tự động chọn Team (Marines / Pirates) khi vừa vào game
task.spawn(function()
    task.wait(2)
    pcall(function()
        if Config.ChooseTeam then
            CommF:InvokeServer("SetTeam", Config.ChooseTeam)
        end
    end)
end)

local function SafeCommF(...)
    if not CommF then return nil end
    local success, result = pcall(function(...)
        return CommF:InvokeServer(...)
    end, ...)
    if success then return result end
    return nil
end

-- -----------------------------------------------------------------
-- MODULE: BẢO VỆ & RECONNECT
-- -----------------------------------------------------------------
local function ServerHop()
    pcall(function()
        local servers = Services.HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, s in ipairs(servers.data) do
            if s.playing < s.maxPlayers - 1 and s.id ~= game.JobId then
                Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                break
            end
        end
    end)
end

task.spawn(function()
    while task.wait(1) do
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                if (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 100 then
                    ServerHop()
                end
            end
        end
    end
end)

pcall(function()
    game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            Services.TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
end)

-- -----------------------------------------------------------------
-- MODULE: DI CHUYỂN & CHỐNG KẸT (NOCLIP)
-- -----------------------------------------------------------------
local lastPosition = Vector3.zero
local stuckTimer = 0

Services.RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

local function SafeTween(targetCFrame)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if (root.Position - lastPosition).Magnitude < 5 then
        stuckTimer = stuckTimer + 1
        if stuckTimer > 40 then
            root.CFrame = root.CFrame * CFrame.new(0, 1000, 0)
            stuckTimer = 0
            task.wait(1)
        end
    else
        stuckTimer = 0
    end
    lastPosition = root.Position

    local dist = (root.Position - targetCFrame.Position).Magnitude
    if dist > 1 then
        local info = TweenInfo.new(dist / 300, Enum.EasingStyle.Linear)
        local tween = Services.TweenService:Create(root, info, {CFrame = targetCFrame})
        tween:Play()
    end
end

-- -----------------------------------------------------------------
-- MODULE: MUA HAKI CƠ BẢN
-- -----------------------------------------------------------------
if Config.AutoBuyHaki then
    task.spawn(function()
        while task.wait(30) do
            local data = LocalPlayer:FindFirstChild("Data")
            local beli = data and data:FindFirstChild("Beli") and data.Beli.Value or 0
            if beli >= 25000 then SafeCommF("BuyHaki", "Buso") end
            if beli >= 100000 then SafeCommF("BuyHaki", "Soru") end
            if beli >= 10000 then SafeCommF("BuyHaki", "Geppo") end
        end
    end)
end

-- -----------------------------------------------------------------
-- MODULE: DATABASE NHIỆM VỤ (QUEST MAPPING 1-3000)
-- -----------------------------------------------------------------
local QuestDB = {
    { MinLevel = 1,   MaxLevel = 9,   QuestName = "BanditQuest1", QuestLevel = 1, MobName = "Bandit", TargetCFrame = CFrame.new(1050, 16, 1400) },
    { MinLevel = 10,  MaxLevel = 14,  QuestName = "BanditQuest1", QuestLevel = 2, MobName = "Godfather", TargetCFrame = CFrame.new(1160, 16, 1620) },
    { MinLevel = 15,  MaxLevel = 29,  QuestName = "JungleQuest", QuestLevel = 1, MobName = "Monkey", TargetCFrame = CFrame.new(-1145, 4, 3850) },
    { MinLevel = 30,  MaxLevel = 59,  QuestName = "BuggyQuest", QuestLevel = 1, MobName = "Pirate", TargetCFrame = CFrame.new(-1140, 14, 4350) },
    { MinLevel = 60,  MaxLevel = 89,  QuestName = "DesertQuest", QuestLevel = 1, MobName = "Desert Bandit", TargetCFrame = CFrame.new(890, 7, 4390) },
    { MinLevel = 90,  MaxLevel = 119, QuestName = "SnowQuest", QuestLevel = 1, MobName = "Snow Bandit", TargetCFrame = CFrame.new(1385, 87, -1295) },
    { MinLevel = 120, MaxLevel = 149, QuestName = "MarineQuest2", QuestLevel = 1, MobName = "Chief Petty Officer", TargetCFrame = CFrame.new(-5000, 25, 4320) },
    { MinLevel = 150, MaxLevel = 174, QuestName = "SkyQuest", QuestLevel = 1, MobName = "Sky Bandit", TargetCFrame = CFrame.new(-4840, 717, -2620) },
    { MinLevel = 175, MaxLevel = 189, QuestName = "SkyQuest", QuestLevel = 2, MobName = "Dark Master", TargetCFrame = CFrame.new(-5245, 390, -2250) },
    { MinLevel = 190, MaxLevel = 209, QuestName = "PrisonerQuest", QuestLevel = 1, MobName = "Prisoner", TargetCFrame = CFrame.new(5030, 2, 475) },
    { MinLevel = 210, MaxLevel = 249, QuestName = "ColosseumQuest", QuestLevel = 1, MobName = "Toga Warrior", TargetCFrame = CFrame.new(-1580, 7, -2995) },
    { MinLevel = 250, MaxLevel = 299, QuestName = "MagmaQuest", QuestLevel = 1, MobName = "Military Soldier", TargetCFrame = CFrame.new(-5400, 15, 8500) },
    { MinLevel = 300, MaxLevel = 374, QuestName = "UnderWaterQuest", QuestLevel = 1, MobName = "Fishman Warrior", TargetCFrame = CFrame.new(61122, 18, 1568) },
    { MinLevel = 375, MaxLevel = 449, QuestName = "FountainQuest", QuestLevel = 1, MobName = "Galley Pirate", TargetCFrame = CFrame.new(5260, 4, 4050) },
    { MinLevel = 450, MaxLevel = 700, QuestName = "FountainQuest", QuestLevel = 2, MobName = "Galley Captain", TargetCFrame = CFrame.new(5560, 70, 3950) },
    { MinLevel = 700, MaxLevel = 724, QuestName = "Area1Quest", QuestLevel = 1, MobName = "Raider [Lv. 700]", TargetCFrame = CFrame.new(-425, 73, 1835) },
    { MinLevel = 725, MaxLevel = 749, QuestName = "Area1Quest", QuestLevel = 2, MobName = "Mercenary [Lv. 725]", TargetCFrame = CFrame.new(-860, 75, 1340) },
    { MinLevel = 750, MaxLevel = 774, QuestName = "Area2Quest", QuestLevel = 1, MobName = "Swan Pirate [Lv. 750]", TargetCFrame = CFrame.new(635, 74, 915) },
    { MinLevel = 775, MaxLevel = 799, QuestName = "FactoryStaffQuest", QuestLevel = 1, MobName = "Factory Staff [Lv. 800]", TargetCFrame = CFrame.new(300, 75, -260) },
    { MinLevel = 800, MaxLevel = 874, QuestName = "MarineQuest3", QuestLevel = 1, MobName = "Marine Lieutenant [Lv. 825]", TargetCFrame = CFrame.new(-2440, 73, -3215) },
    { MinLevel = 875, MaxLevel = 924, QuestName = "MarineQuest3", QuestLevel = 2, MobName = "Marine Captain [Lv. 850]", TargetCFrame = CFrame.new(-2850, 73, -3050) },
    { MinLevel = 925, MaxLevel = 974, QuestName = "ZombieQuest", QuestLevel = 1, MobName = "Zombie [Lv. 925]", TargetCFrame = CFrame.new(-5650, 50, -780) },
    { MinLevel = 975, MaxLevel = 999, QuestName = "ZombieQuest", QuestLevel = 2, MobName = "Vampire [Lv. 975]", TargetCFrame = CFrame.new(-6015, 20, -1315) },
    { MinLevel = 1000, MaxLevel = 1049, QuestName = "SnowMountainQuest", QuestLevel = 1, MobName = "Snow Trooper [Lv. 1000]", TargetCFrame = CFrame.new(460, 400, -5335) },
    { MinLevel = 1050, MaxLevel = 1099, QuestName = "SnowMountainQuest", QuestLevel = 2, MobName = "Winter Warrior [Lv. 1050]", TargetCFrame = CFrame.new(570, 400, -5815) },
    { MinLevel = 1100, MaxLevel = 1149, QuestName = "IceSideQuest", QuestLevel = 1, MobName = "Lab Subordinate [Lv. 1100]", TargetCFrame = CFrame.new(-6060, 15, -4905) },
    { MinLevel = 1150, MaxLevel = 1199, QuestName = "IceSideQuest", QuestLevel = 2, MobName = "Horned Warrior [Lv. 1150]", TargetCFrame = CFrame.new(-6315, 55, -5745) },
    { MinLevel = 1200, MaxLevel = 1249, QuestName = "FireSideQuest", QuestLevel = 1, MobName = "Magma Ninja [Lv. 1200]", TargetCFrame = CFrame.new(-5425, 15, -5920) },
    { MinLevel = 1250, MaxLevel = 1299, QuestName = "FireSideQuest", QuestLevel = 2, MobName = "Lava Pirate [Lv. 1250]", TargetCFrame = CFrame.new(-5230, 15, -4785) },
    { MinLevel = 1300, MaxLevel = 1349, QuestName = "ShipQuest1", QuestLevel = 1, MobName = "Ship Deckhand [Lv. 1300]", TargetCFrame = CFrame.new(1035, 125, 32915) },
    { MinLevel = 1350, MaxLevel = 1399, QuestName = "ShipQuest1", QuestLevel = 2, MobName = "Ship Engineer [Lv. 1350]", TargetCFrame = CFrame.new(920, 50, 33150) },
    { MinLevel = 1400, MaxLevel = 1449, QuestName = "ShipQuest2", QuestLevel = 1, MobName = "Ship Steward [Lv. 1400]", TargetCFrame = CFrame.new(900, 140, 33500) },
    { MinLevel = 1450, MaxLevel = 1500, QuestName = "ShipQuest2", QuestLevel = 2, MobName = "Ship Officer [Lv. 1450]", TargetCFrame = CFrame.new(925, 140, 33850) },
    { MinLevel = 1500, MaxLevel = 1524, QuestName = "PiratePortQuest", QuestLevel = 1, MobName = "Pirate Millionaire [Lv. 1500]", TargetCFrame = CFrame.new(-418, 73, 5971) },
    { MinLevel = 1525, MaxLevel = 1549, QuestName = "PiratePortQuest", QuestLevel = 2, MobName = "Pistol Billionaire [Lv. 1525]", TargetCFrame = CFrame.new(-470, 73, 6170) },
    { MinLevel = 1550, MaxLevel = 1574, QuestName = "AmazonQuest", QuestLevel = 1, MobName = "Island Boy [Lv. 1550]", TargetCFrame = CFrame.new(5700, 600, 190) },
    { MinLevel = 1575, MaxLevel = 1599, QuestName = "AmazonQuest", QuestLevel = 2, MobName = "Sky Bandit [Lv. 1575]", TargetCFrame = CFrame.new(4650, 600, -700) },
    { MinLevel = 1600, MaxLevel = 1624, QuestName = "AmazonQuest2", QuestLevel = 1, MobName = "Dragon Archer [Lv. 1600]", TargetCFrame = CFrame.new(6430, 300, 175) },
    { MinLevel = 1625, MaxLevel = 1649, QuestName = "AmazonQuest2", QuestLevel = 2, MobName = "Amazon Warrior [Lv. 1625]", TargetCFrame = CFrame.new(6350, 300, 950) },
    { MinLevel = 1650, MaxLevel = 1699, QuestName = "MarineTreeIsland", QuestLevel = 1, MobName = "Marine Commodore [Lv. 1650]", TargetCFrame = CFrame.new(2450, 75, -6750) },
    { MinLevel = 1700, MaxLevel = 1749, QuestName = "MarineTreeIsland", QuestLevel = 2, MobName = "Marine Rear Admiral [Lv. 1700]", TargetCFrame = CFrame.new(2450, 75, -7350) },
    { MinLevel = 1750, MaxLevel = 1799, QuestName = "DeepForestIsland", QuestLevel = 1, MobName = "Fishman Raider [Lv. 1750]", TargetCFrame = CFrame.new(-10585, 330, -8400) },
    { MinLevel = 1800, MaxLevel = 1849, QuestName = "DeepForestIsland", QuestLevel = 2, MobName = "Forest Pirate [Lv. 1800]", TargetCFrame = CFrame.new(-13250, 330, -7625) },
    { MinLevel = 1850, MaxLevel = 1899, QuestName = "DeepForestIsland2", QuestLevel = 1, MobName = "Mythological Pirate [Lv. 1850]", TargetCFrame = CFrame.new(-13550, 330, -6900) },
    { MinLevel = 1900, MaxLevel = 1949, QuestName = "DeepForestIsland2", QuestLevel = 2, MobName = "Jungle Pirate [Lv. 1900]", TargetCFrame = CFrame.new(-12050, 330, -10500) },
    { MinLevel = 1950, MaxLevel = 1999, QuestName = "HauntedQuest1", QuestLevel = 1, MobName = "Reborn Skeleton [Lv. 1950]", TargetCFrame = CFrame.new(-9490, 140, 5565) },
    { MinLevel = 2000, MaxLevel = 2049, QuestName = "HauntedQuest1", QuestLevel = 2, MobName = "Living Zombie [Lv. 2000]", TargetCFrame = CFrame.new(-10150, 140, 5950) },
    { MinLevel = 2050, MaxLevel = 2099, QuestName = "HauntedQuest2", QuestLevel = 1, MobName = "Demonic Soul [Lv. 2050]", TargetCFrame = CFrame.new(-9510, 170, 6080) },
    { MinLevel = 2100, MaxLevel = 2149, QuestName = "HauntedQuest2", QuestLevel = 2, MobName = "Posessed Mummy [Lv. 2100]", TargetCFrame = CFrame.new(-9120, 170, 6150) },
    { MinLevel = 2150, MaxLevel = 2249, QuestName = "NutsIslandQuest", QuestLevel = 1, MobName = "Peanut Scout [Lv. 2150]", TargetCFrame = CFrame.new(-2005, 50, -11985) },
    { MinLevel = 2250, MaxLevel = 2299, QuestName = "NutsIslandQuest", QuestLevel = 2, MobName = "Peanut President [Lv. 2250]", TargetCFrame = CFrame.new(-2200, 50, -10450) },
    { MinLevel = 2300, MaxLevel = 2349, QuestName = "IceCreamIslandQuest", QuestLevel = 1, MobName = "Ice Cream Chef [Lv. 2300]", TargetCFrame = CFrame.new(-805, 70, -11000) },
    { MinLevel = 2350, MaxLevel = 3000, QuestName = "IceCreamIslandQuest", QuestLevel = 2, MobName = "Ice Cream Commander [Lv. 2350]", TargetCFrame = CFrame.new(-1200, 70, -11400) }
}

local function GetCurrentQuest()
    local data = LocalPlayer:FindFirstChild("Data")
    if not data or not data:FindFirstChild("Level") then return nil end
    local level = data.Level.Value
    for _, quest in ipairs(QuestDB) do
        if level >= quest.MinLevel and level <= quest.MaxLevel then
            return quest
        end
    end
    return { QuestName = "IceCreamIslandQuest", QuestLevel = 2, MobName = "Ice Cream Commander [Lv. 2350]", TargetCFrame = CFrame.new(-1200, 70, -11400) }
end

-- -----------------------------------------------------------------
-- MODULE: FARM & FAST ATTACK (MELEE ONLY)
-- -----------------------------------------------------------------
local function EquipMelee()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if tool and tool.ToolTip == "Melee" then return end

    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") and item.ToolTip == "Melee" then
            char.Humanoid:EquipTool(item)
            break
        end
    end
end

local HitDelay = 0.175
local LastHit = tick()

local function SafeFastAttack(mob)
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool and tool.ToolTip == "Melee" then
        if tick() - LastHit >= HitDelay then
            LastHit = tick()
            pcall(function() tool:Activate() end)
            local net = Services.ReplicatedStorage:FindFirstChild("Modules") and Services.ReplicatedStorage.Modules:FindFirstChild("Net")
            if net and net:FindFirstChild("RegisterHit") then
                pcall(function() net.RegisterHit:FireServer({mob.HumanoidRootPart}) end)
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then task.wait(1); continue end

        local pData = LocalPlayer:FindFirstChild("Data")
        if not pData then continue end

        local currentQuest = GetCurrentQuest()
        if not currentQuest then continue end

        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainGui = playerGui and playerGui:FindFirstChild("Main")
        local questGui = mainGui and mainGui:FindFirstChild("Quest")
        
        if not questGui or not questGui.Visible then
            SafeCommF("StartQuest", currentQuest.QuestName, currentQuest.QuestLevel)
            task.wait(0.5)
        end

        SafeTween(currentQuest.TargetCFrame)
        EquipMelee()

        local root = char:FindFirstChild("HumanoidRootPart")
        local enemies = workspace:FindFirstChild("Enemies")

        if root and enemies then
            for _, mob in ipairs(enemies:GetChildren()) do
                if mob.Name == currentQuest.MobName and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                    if (mob.HumanoidRootPart.Position - root.Position).Magnitude <= 30 then
                        mob.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0, 0, -4)
                        mob.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                    end
                    SafeFastAttack(mob)
                end
            end
        end
    end
end)

-- -----------------------------------------------------------------
-- MODULE: AUTO STATS & CHUYỂN BIỂN
-- -----------------------------------------------------------------
if Config.AutoStats then
    task.spawn(function()
        while task.wait(3) do
            local data = LocalPlayer:FindFirstChild("Data")
            local points = data and data:FindFirstChild("Points") and data.Points.Value or 0
            if points > 0 then
                local meleePoints = math.floor(points * 0.6)
                local defensePoints = points - meleePoints
                if meleePoints > 0 then SafeCommF("AddPoint", "Melee", meleePoints) end
                if defensePoints > 0 then SafeCommF("AddPoint", "Defense", defensePoints) end
            end
        end
    end)
end

if Config.AutoSeaTravel then
    task.spawn(function()
        while task.wait(5) do
            local data = LocalPlayer:FindFirstChild("Data")
            local level = data and data:FindFirstChild("Level") and data.Level.Value or 1
            local placeId = game.PlaceId
            
            if placeId == 2753915549 and level >= 700 then
                SafeCommF("MilitaryDetective")
                task.wait(1)
                SafeCommF("TravelDressrosa")
            end
            
            if placeId == 4442272183 and level >= 1500 then
                SafeCommF("KingRedHead")
                task.wait(1)
                SafeCommF("TravelZou")
            end
        end
    end)
end

print("[Ultimate Hub] Khởi chạy thành công!")
