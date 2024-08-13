local Settings = ...

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local rs_Monsters = ReplicatedStorage:WaitForChild("MonsterSpawn")
local Modules = ReplicatedStorage:WaitForChild("ModuleScript")
local OtherEvent = ReplicatedStorage:WaitForChild("OtherEvent")
local Monsters = workspace:WaitForChild("Monster")

local MQuestSettings = require(Modules:WaitForChild("Quest_Settings"))
local MSetting = require(Modules:WaitForChild("Setting"))

local NPCs = workspace:WaitForChild("NPCs")
local Raids = workspace:WaitForChild("Raids")
local Location = workspace:WaitForChild("Location")
local Region = workspace:WaitForChild("Region")
local Island = workspace:WaitForChild("Island")

local Quests_Npc = NPCs:WaitForChild("Quests_Npc")
local EnemyLocation = Location:WaitForChild("Enemy_Location")
local QuestLocation = Location:WaitForChild("QuestLocaion")

local Cooldown = Player:WaitForChild("Cooldown")
local Items = Player:WaitForChild("Items")
local QuestFolder = Player:WaitForChild("QuestFolder")
local Ability = Player:WaitForChild("Ability")
local PlayerData = Player:WaitForChild("PlayerData")
local PlayerLevel = PlayerData:WaitForChild("Level")

local sethiddenproperty = sethiddenproperty or (function()end)
local _env = getgenv and getgenv() or {}

local _insert = table.insert
local _spawn = task.spawn
local _wait = task.wait
local _huge = math.huge

local Module = {} do
  Module.__index = Module
  
  Module.MaxLevel = MSetting.Setting.MaxLevel
  Module.BL_Spawns = MSetting.Setting.IgnoreSpawnPoints
  
  Module.WeaponList = {"Fight", "Power", "Weapon"}
  Module.Shop = {
    {"Weapons", {
      {"Katana", "$5.000 Money", {"Weapon_Seller", "Doge"}},
      {"Hanger", "$25.000 Money", {"Weapon_Seller", "Hanger"}},
      {"Flame Katana", "1x Cheems Cola and $50.000", {"Weapon_Seller", "Cheems"}},
      {"Banana", "1x Cat Food and $350.000", {"Weapon_Seller", "Smiling Cat"}},
      {"Bonk", "5x Money Bags and $1.000.000", {"Weapon_Seller", "Meme Man"}},
      {"Pumpkin", "1x Nugget Man and $3.500.000", {"Weapon_Seller", "Gravestone"}},
      {"Popcat", "10.000 Pops Clicker", {"Weapon_Seller", "Ohio Popcat"}}
    }},
    {"Ability", {
      {"Flash Step", "$100.000 Money", {"Ability_Teacher", "Giga Chad"}},
      {"Instinct", "$2.500.000 Money", {"Ability_Teacher", "Nugget Man"}},
      {"Aura", "1x Meme Cube and $10.000.000", {"Ability_Teacher", "Aura Master"}}
    }},
    {"Fighting Style", {
      {"Combat", "$0 Money", {"FightingStyle_Teacher", "Maxwell"}},
      {"Baller", "10x Balls and $10.000.000", {"FightingStyle_Teacher", "Baller"}}
    }}
  }
  Module.ItemsPrice = {
    ["Aura"] = { Material = {"Meme Cube", 1}, Money = 10000000 },
    ["Instinct"] = { Money = 2500000 },
    ["FlashStep"] = { Money = 100000 },
    ["Katana"] = { Money = 5000 },
    ["Hanger"] = { Money = 25000 },
    ["Flame Katana"] = { Material = {"Cheems Cola", 1}, Money = 50000 },
    ["Banana"] = { Material = {"Cat Food", 1}, Money = 350000 },
    ["Bonk"] = { Material = {"Money Bag", 5}, Money = 1000000 },
    ["Pumpkin"] = { Material = {"Nugget Man", 1}, Money = 3500000 },
    ["Baller"] = { Material = {"Ball", 10}, Money = 10000000 },
    ["Popcat"] = { Pop = 10000 }
  }
  
  function Module:IsAlive(Char)
    local Hum = Char and Char:FindFirstChild("Humanoid")
    return Hum and Hum.Health > 0
  end
  
  function Module:GetEnemy(EnName)
    if EnName then
      local Enemy = Monsters:FindFirstChild(EnName) or rs_Monsters:FindFirstChild(EnName)
      if self:IsAlive(Enemy) then
        return Enemy
      end
    end
    for _,Enemy in ipairs(Monsters:GetChildren()) do
      if (not EnName or Enemy.Name == EnName) and self:IsAlive(Enemy) then
        return Enemy
      end
    end
    return false
  end
  
  function Module:GoTo(CFrame, Move)
    local Char = Player.Character
    return self:IsAlive(Char) and (Move and Char:MoveTo(CFrame.p) or Char:SetPrimaryPartCFrame(CFrame))
  end
  
  function Module:PlayerClick()
    local Char = Player.Character
    if Char then
      if Settings.AutoClick then
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(1e4, 1e4))
      end
      if Settings.AutoHaki then
        if Char:FindFirstChild("AuraColor_Folder") and self:AbilityUnlocked("Aura") then
          if #Char.AuraColor_Folder:GetChildren() < 1 then
            OtherEvent.MainEvents.Ability:InvokeServer("Aura")
          end
        end
      end
    end
  end
  
  function Module:EquipWeapon()
    local Char, Tool = Player.Character, Settings.ToolFarm
    if Tool and self:IsAlive(Char) then
      local charTool = Char:FindFirstChildOfClass("Tool")
      if not charTool or not charTool.ToolTip:find(Tool) then
        for _,v in ipairs(Player.Backpack:GetChildren()) do
          if v:IsA("Tool") and v.ToolTip:find(Tool) then
            return Char.Humanoid:EquipTool(v)
          end
        end
      end
    end
  end
  
  function Module:BringMobsTo(EnName, CFrame, BAll)
    for _,Enemy in ipairs(Monsters:GetChildren()) do
      if (BAll or Enemy.Name == EnName) and self:IsAlive(Enemy) then
        local PP, Hum = Enemy.PrimaryPart, Enemy.Humanoid
        if PP and (PP.Position - CFrame.p).Magnitude < 500 then
          Hum.WalkSpeed = 0
          Hum:ChangeState(14)
          PP.CFrame = CFrame
          PP.CanCollide = false
          PP.Transparency = Settings.ViewHitbox and 0.8 or 1
          PP.Size = Vector3.new(50, 50, 50)
        end
      end
    end
    return pcall(sethiddenproperty, Player, "SimulationRadius", _huge)
  end
  
  function Module:GetRaidEnemy()
    for _,Enemy in ipairs(Monsters:GetChildren()) do
      if Enemy:GetAttribute("Raid_Enemy") and self:IsAlive(v) then
        return Enemy
      end
    end
  end
  
  function Module:GetRaidMap()
    for _,Map in ipairs(Raids:GetChildren()) do
      if Map.Joiners:FindFirstChild(Player.Name) then
        return Map
      end
    end
  end
  
  function Module:KillEnemy(EnName, ...)
    local Enemy = type(EnName) == "string" and self:GetEnemy(EnName) or EnName
    local PP = Enemy.PrimaryPart
    
    if PP then
      self:GoTo(PP.CFrame * Settings.FarmCFrame)self:EquipWeapon()
      if not Enemy:FindFirstChild("Reverse_Mark") then self:PlayerClick() end
      if Settings.BringMobs then self:BringMobsTo(EnName, PP.CFrame, ...) end
      return true
    end
  end
  
  function Module:AbilityUnlocked(Ablt)
    return Ability:FindFirstChild(Ablt) and Ability[Ablt].Value
  end
  
  function Module:CanUseSkill(key)
    for _,v in ipairs(Cooldown:GetChildren()) do
      if v.Name:find("_" .. key) then
        return false
      end
    end
    return true
  end
  
  function Module:UseSkills()
    for key, Value in pairs(Settings.SkillsSelected) do
      if Value and self:CanUseSkill(key) then
        VIM:SendKeyEvent(true, key, false, game)
        VIM:SendKeyEvent(false, key, false, game)
      end
    end
  end
  
  _spawn(function()
    if _env.Loaded_HUN then return end
    _env.Loaded_HUN = true
    
    local Label = Player.PlayerGui.MainGui.PlayerName
    
    local function Update()
      local Level = PlayerLevel.Value
      local IsMax = Level >= Module.MaxLevel
      Label.Text = ("%s • Lv. %i%s"):format("Anonymous", Level, IsMax and " (Max)" or "")
    end
    
    Label:GetPropertyChangedSignal("Text"):Connect(Update)Update()
  end)
  
  Module.Items = (function()
    local Items = {}
    Items.Inventory = Player:WaitForChild("Items")
    Items.Folders = {}
    
    function Items:GetMaterial(MaName)
      return self.Folders.ItemStorage[MaName].Value
    end
    
    function Items:VerifySword(SwName)
      return self.Folders.Weapon[SwName].Value > 0
    end
    
    function Items:VerifyAccessory(AcName)
      return self.Folders.Accessory[AcName].Value > 0
    end
    
    function Items:VerifyFightStyle(FsName)
      return self.Folders.FightingStyle[FsName].Value = true
    end
    
    for _,Folder in ipairs(Items.Inventory:GetChildren()) do
      Items.Folders[Folder.Name] = Folder
    end
    
    return Items
  end)()
  Module.Quests = (function()
    local Quests = {}
    Quests.QuestsList = {}
    Quests.QuestsNPCs = {}
    Quests.EnemyList = {}
    
    function Quests:UpdateQuestsList()
      table.clear(self.QuestsList)
      for Npc, Quest in pairs(MQuestSettings) do
        if QuestLocation:FindFirstChild(Npc) then
          _insert(self.QuestsList, {
            EnemyPos = EnemyLocation[Quest.Target].CFrame,
            QuestPos = QuestLocation[Npc].CFrame,
            SpecialQuest = Quest.Special_Quest,
            RaidBoss = Quest.Raid_Boss,
            Level = Quest.LevelNeed,
            Enemy = Quest.Target,
            NpcName = Npc
          })
        end
      end
      table.sort(self.QuestsList, function(a,b)return(a.Level>b.Level)end)
      for _,v in ipairs(self.QuestsList) do
        _insert(self.EnemyList, v.Enemy)
        self.QuestsNPCs[v.Enemy] = v.NpcName
      end
    end
    
    return Quests
  end)()
end

return Module
