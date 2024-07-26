local _wait = task.wait
repeat _wait() until game:IsLoaded()
local _env = getgenv and getgenv() or {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local rs_Monsters = ReplicatedStorage:WaitForChild("MonsterSpawn")
local Modules = ReplicatedStorage:WaitForChild("ModuleScript")
local Monsters = workspace:WaitForChild("Monster")

local QuestSettings = Modules:WaitForChild("Quest_Settings")

local NPCs = workspace:WaitForChild("NPCs")
local Raids = workspace:WaitForChild("Raids")
local Location = workspace:WaitForChild("Location")
local Region = workspace:WaitForChild("Region")
local Island = workspace:WaitForChild("Island")

local Quests_Npc = NPCs:WaitForChild("Quests_Npc")
local EnemyLocation = Location:WaitForChild("Enemy_Location")
local QuestLocation = Location:WaitForChild("QuestLocaion")

local Items = Player:WaitForChild("Items")
local QuestFolder = Player:WaitForChild("QuestFolder")
local Backpack = Player:WaitForChild("Backpack")
local Ability = Player:WaitForChild("Ability")
local PlayerData = Player:WaitForChild("PlayerData")
local PlayerLevel = PlayerData:WaitForChild("Level")

local sethiddenproperty = sethiddenproperty or (function()end)

local CFrame_Angles = CFrame.Angles
local CFrame_new = CFrame.new

local _huge = math.huge

local Loaded, Funcs, Folders = {}, {}, {} do
  Loaded.WeaponsList = { "Fightning Style", "Power", "Weapon" }
  Loaded.EnemeiesList = {}
  Loaded.EnemiesSpawns = {}
  Loaded.EnemiesQuests = {}
  Loaded.Islands = {}
  Loaded.Quests = {}
  
  local function RedeemCode(Code)
    return ReplicatedStorage.OtherEvent.MainEvents.Code:InvokeServer(Code)
  end
  
  Funcs.RAllCodes = function(self)
    if Modules:FindFirstChild("CodeList") then
      local List = require(Modules.CodeList)
      for Code, Info in pairs(type(List) == "table" and List or {}) do
        if type(Code) == "string" and type(Info) == "table" and Info.Status then RedeemCode(Code) end
      end
    end
  end
  
  Funcs.GetPlayerLevel = function(self)
    return PlayerLevel.Value
  end
  
  Funcs.GetCurrentQuest = function(self)
    for _,Quest in pairs(Loaded.Quests) do
      if Quest.Level <= self:GetPlayerLevel() then
        return Quest
      end
    end
  end
  
  Funcs.CheckQuest = function(self)
    for _,v in ipairs(QuestFolder:GetChildren()) do
      if v.Target.Value ~= "None" then
        return v
      end
    end
  end
  
  Funcs.VerifySword = function(self, SName)
    local Swords = Items.Weapon
    return Swords:FindFirstChild(SName) and Swords[SName].Value > 0
  end
  
  Funcs.VerifyAccessory = function(self, AName)
    local Accessories = Items.Accessory
    return Accessories:FindFirstChild(AName) and Accessories[AName].Value > 0
  end
  
  Funcs.GetMaterial = function(self, MName)
    local ItemStorage = Items.ItemStorage
    return ItemStorage:FindFirstChild(MName) and ItemStorage[MName].Value or 0
  end
  
  Funcs.GetAbilityLvl = function(self, Ablt)
    return Ability:FindFirstChild(Ablt) and Ability[Ablt].Value or 0
  end
  
  local _Quests = require(QuestSettings)
  for Npc,Quest in pairs(_Quests) do
    if not Quest.Special_Quest and QuestLocation:FindFirstChild(Npc) then
      table.insert(Loaded.Quests, {
        NpcName = Npc,
        QuestPos = QuestLocation[Npc].CFrame,
        EnemyPos = EnemyLocation[Quest.Target].CFrame,
        Level = Quest.LevelNeed,
        Enemy = Quest.Target
      })
    end
  end
  
  table.sort(Loaded.Quests, function(a, b) return a.Level > b.Level end)
  for _,v in ipairs(Loaded.Quests) do
    table.insert(Loaded.EnemeiesList, v.Enemy)Loaded.EnemiesQuests[v.Enemy] = v.NpcName
  end
end

local Settings = Settings or {} do
  Settings.BringMobs = true
  Settings.FarmDistance = 9
  Settings.ViewHitbox = false
  Settings.AntiAFK = true
  Settings.AutoHaki = true
  Settings.AutoClick = true
  Settings.ToolFarm = "Weapon" -- [[ "Fightning Style", "Power", "Weapon" ]]
  Settings.FarmCFrame = CFrame_new(0, Settings.FarmDistance, 0) * CFrame_Angles(math.rad(-90), 0, 0)
end

local function PlayerClick()
  local Char = Player.Character
  if Char then
    if Settings.AutoClick then
      VirtualUser:CaptureController()
      VirtualUser:Button1Down(Vector2.new(1e4, 1e4))
    end
    if Settings.AutoHaki and Char:FindFirstChild("AuraColor_Folder") and Funcs:GetAbilityLvl("Aura") > 0 then
      if #Char.AuraColor_Folder:GetChildren() < 1 then
        ReplicatedStorage.OtherEvent.MainEvents.Ability:InvokeServer("Aura")
      end
    end
  end
end

local function IsAlive(Char)
  local Hum = Char and Char:FindFirstChild("Humanoid")
  return Hum and Hum.Health > 0
end

local function GetNextEnemie(EnemieName)
  for _,v in ipairs(Monsters:GetChildren()) do
    if (not EnemieName or v.Name == EnemieName) and IsAlive(v) then
      return v
    end
  end
  return false
end

local function GoTo(CFrame)
  local Char = Player.Character
  if IsAlive(Char) then
    Char:SetPrimaryPartCFrame(CFrame)
  end
end

local function EquipWeapon()
  local Char = Player.Character
  if IsAlive(Char) then
    for _,v in ipairs(Backpack:GetChildren()) do
      if v:IsA("Tool") and v.ToolTip == Settings.ToolFarm then
        Char.Humanoid:EquipTool(v)
      end
    end
  end
end

local function BringMobsTo(_Enemie, CFrame, SBring)
  for _,v in ipairs(Monsters:GetChildren()) do
    if (SBring or v.Name == _Enemie) and IsAlive(v) and v.PrimaryPart then
      v.PrimaryPart.CFrame = CFrame
      if v:FindFirstChild("Humanoid") then
        local Hum = v.Humanoid
        Hum.WalkSpeed = 0
        Hum:ChangeState(14)
      end
      local PP = v.PrimaryPart
      PP.CanCollide = false
      PP.Transparency = Settings.ViewHitbox and 0.8 or 1
      PP.Size = Vector3.new(50, 50, 50)
    end
  end
  return pcall(sethiddenproperty, Player, "SimulationRadius", _huge)
end

local function KillMonster(_Enemie, SBring)
  local Enemie = typeof(_Enemie) == "Instance" and _Enemie or GetNextEnemie(_Enemie)
  if IsAlive(Enemie) and Enemie.PrimaryPart then
    GoTo(Enemie.PrimaryPart.CFrame * Settings.FarmCFrame)EquipWeapon()PlayerClick()
    if Settings.BringMobs then BringMobsTo(_Enemie, Enemie.PrimaryPart.CFrame, SBring) end
    return true
  end
end

local function TakeQuest(QuestName, CFrame)
  local QuestGiver = Quests_Npc:FindFirstChild(QuestName)
  if QuestGiver and Player:DistanceFromCharacter(QuestGiver.WorldPivot.p) < 5 then
    return fireproximityprompt(QuestGiver.Block.QuestPrompt), _wait(0.2)
  end
  GoTo(CFrame or QuestLocation[QuestName].CFrame)
end

local function ClearQuests(Ignore)
  for _,v in ipairs(QuestFolder:GetChildren()) do
    if v.QuestGiver.Value ~= Ignore and v.Target.Value ~= "None" then
      ReplicatedStorage.OtherEvent.QuestEvents.Quest:FireServer("Abandon_Quest", { QuestSlot = v.Name })
    end
  end
end

local function GetRaidEnemies()
  for _,v in ipairs(Monsters:GetChildren()) do
    if v:GetAttribute("Raid_Enemy") and IsAlive(v) then
      return v
    end
  end
end

local function GetRaidMap()
  for _,v in ipairs(Raids:GetChildren()) do
    if v.Joiners:FindFirstChild(Player.Name) then
      return v
    end
  end
end

local function VerifyQuest(QName)
  local Quest = Funcs:CheckQuest()
  return Quest and Quest.QuestGiver.Value == QName
end

_env.FarmFuncs = {
  {"_Floppa Sword", (function()
    if not Funcs:VerifySword("Floppa") then
      if VerifyQuest("Cool Floppa Quest") then
        GoTo(CFrame_new(794, -31, -440))
        fireproximityprompt(Island.FloppaIsland["Lava Floppa"].ClickPart.ProximityPrompt)
      else
        ClearQuests("Cool Floppa Quest")
        TakeQuest("Cool Floppa Quest", CFrame_new(758, -31, -424))
      end
      return true
    end
  end)},
  {"Meme Beast", (function()
    local MemeBeast = Monsters:FindFirstChild("Meme Beast") or rs_Monsters:FindFirstChild("Meme Beast")
    if MemeBeast then
      GoTo(MemeBeast.WorldPivot)EquipWeapon()PlayerClick()
      return true
    end
  end)},
  {"Bring Fruits", (function()
    
  end)},
  {"Level Farm", (function()
    local Quest, QuestChecker = Funcs:GetCurrentQuest(), Funcs:CheckQuest()
    if Quest then
      if QuestChecker then
        local _QuestName = QuestChecker.QuestGiver.Value
        if _QuestName == Quest.NpcName then
          if KillMonster(Quest.Enemy) then else GoTo(Quest.EnemyPos) end
        else
          if KillMonster(QuestChecker.Target.Value) then else GoTo(QuestLocation[_QuestName].CFrame) end
        end
      else TakeQuest(Quest.NpcName) end
    end
    return true
  end)},
  {"Raid Farm", (function()
    if Funcs:GetPlayerLevel() >= 1000 then
      local RaidMap = GetRaidMap()
      if RaidMap then
        local Enemie = GetRaidEnemies()
        if Enemie then KillMonster(Enemie, true) else
          local Spawn = RaidMap:FindFirstChild("Spawn_Location")
          if Spawn then GoTo(Spawn.CFrame) end
        end
      else
        local Raid = Region:FindFirstChild("RaidArea")
        if Raid then GoTo(Raid.CFrame) end
      end
      return true
    end
  end)},
  {"FS Enemie", (function()
    local Enemy = _env.SelecetedEnemie
    local Quest = Loaded.EnemiesQuests[Enemy]
    if VerifyQuest(Quest) then
      if KillMonster(Enemy) then else GoTo(EnemyLocation[Enemy].CFrame) end
    else ClearQuests(Quest)TakeQuest(Quest) end
    return true
  end)},
  {"Nearest Farm", (function() return KillMonster(GetNextEnemie()) end) }
}

if not _env.LoadedFarm then
  _env.LoadedFarm = true
  task.spawn(function()
    while _wait() do
      for _,f in _env.FarmFuncs do
        if _env[f[1]] then local s,r=pcall(f[2])if s and r then break end;end
      end
    end
  end)
end

local redzlib = loadstring(game:HttpGet("https://raw.githubusercontent.com/REDzHUB/RedzLibV5/main/Source.Lua"))()
local Window = redzlib:MakeWindow({ Title = "redz Hub : Meme Sea", SubTitle = "by redz9999", SaveFolder = "redzHub-MemeSea.json" })
Window:AddMinimizeButton({
  Button = { Image = "rbxassetid://15298567397", BackgroundTransparency = 0 },
  Corner = { CornerRadius = UDim.new(0, 6) }
})

local Tabs = {
  Discord = Window:MakeTab({"Discord", "Info"}),
  MainFarm = Window:MakeTab({"Farm", "Home"}),
  Items = Window:MakeTab({"Items", "Swords"})
}

Window:SelectTab(Tabs.MainFarm)

local function AddToggle(Tab, Settings, Flag)
  Settings.Description = type(Settings[2]) == "string" and Settings[2]
  Settings.Default = type(Settings[2]) ~= "string" and Settings[2]
  Settings.Flag = Settings.Flag or Flag
  Settings.Callback = function(Value) _env[Settings.Flag] = Value end
  Tab:AddToggle(Settings)
end

local _Discord = Tabs.Discord do
  _Discord:AddDiscordInvite({
    Name = "redz Hub | Community",
    Description = "Join our discord community to receive information about the next update",
    Logo = "rbxassetid://17382040552",
    Invite = "https://discord.gg/7aR7kNVt4g"
  })
end

local _MainFarm = Tabs.MainFarm do
  _MainFarm:AddDropdown({"Farm Tool", Loaded.WeaponsList, { "Fightning Style" }, function(Value)
    Settings.ToolFarm = Value
  end, "Main/FarmTool"})
  _MainFarm:AddSection("Farm")
  AddToggle(_MainFarm, {"Auto Farm Level"}, "Level Farm")
  AddToggle(_MainFarm, {"Auto Farm Nearest"}, "Nearest Farm")
  _MainFarm:AddSection("Enemies")
  _MainFarm:AddDropdown({"Select Enemie", Loaded.EnemeiesList, {Loaded.EnemeiesList[1]}, function(Value)
    _env.SelecetedEnemie = Value
  end, "Main/SEnemy"})
  AddToggle(_MainFarm, {"Auto Farm Selected"}, "FS Enemie")
  _MainFarm:AddSection("Boss Farm")
  AddToggle(_MainFarm, {"Auto Meme Beast"}, "Meme Beast")
  _MainFarm:AddSection("Raid")
  AddToggle(_MainFarm, {"Auto Farm Raid"}, "Raid Farm")
end

local _Items = Tabs.Items do
  _Items:AddSection("Powers")
  _Items:AddToggle({"Auto Store Powers", false, function(Value)
    _env.AutoStorePowers = Value
    while _env.AutoStorePowers do _wait()
      for _,v in ipairs(Backpack:GetChildren()) do
        if v:IsA("Tool") and v.ToolTip == "Power" and v:GetAttribute("Using") == nil then
          v.Parent = Player.Character
          ReplicatedStorage.OtherEvent.MainEvents.Modules:FireServer("Eatable_Power", { Action = "Store", Tool = v })
        end
      end
    end
  end, "AutoStore"})
  _Items:AddSection("Weapons")
  AddToggle(_Items, {"Auto Floppa [ Exclusive Sword ]"}, "_Floppa Sword")
  
  --[[_Items:AddSection("Popcat")
  _Items:AddToggle({"Auto Popcat", false, function(Value)
    _env.AutoPopcat = Value
    while _env.AutoPopcat do _wait()
      fireclickdetector(workspace.Island.FloppaIsland.Popcat_Clickable.Part.ClickDetector)
    end
  end, "AutoPopcat"})]]
end
