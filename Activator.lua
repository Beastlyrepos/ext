--[[
░█▀▀█ ▒█▀▀█ ▀▀█▀▀ ▀█▀ ▒█░▒█ ░█▀▀█ ▀▀█▀▀ ▒█▀▀▀█ ▒█▀▀█ 
▒█▄▄█ ▒█░░░ ░▒█░░ ▒█░ ▒█░▒█ ▒█▄▄█ ░▒█░░ ▒█░░▒█ ▒█▄▄▀
▒█░▒█ ▒█▄▄█  ▒█░░ ▄█▄ ░▀▄▄▀ ▒█░▒█ ░▒█░░ ▒█▄▄▄█ ▒█░▒█ 
]]

local neutral = 300
local friend = myHero.team
local foe = neutral - friend

local mathhuge = math.huge
local mathsqrt = math.sqrt



local HKITEM = {[ITEM_1] = HK_ITEM_1,[ITEM_2] = HK_ITEM_2,[ITEM_3] = HK_ITEM_3,[ITEM_4] = HK_ITEM_4,[ITEM_5] = HK_ITEM_5,[ITEM_6] = HK_ITEM_6,[ITEM_7] = HK_ITEM_7}
local HKSPELL = {[SUMMONER_1] = HK_SUMMONER_1,[SUMMONER_2] = HK_SUMMONER_2,}

local function Ready(slot)
	return myHero:GetSpellData(slot).currentCd == 0
end

local function IsUp(slot)
    return Game.CanUseSpell(slot) == 0
end

local function GetDistanceSqr(Pos1, Pos2)
    local Pos2 = Pos2 or myHero.pos
    local dx = Pos1.x - Pos2.x
    local dz = (Pos1.z or Pos1.y) - (Pos2.z or Pos2.y)
    return dx^2 + dz^2
end

local function GetDistance(Pos1, Pos2)
	return mathsqrt(GetDistanceSqr(Pos1, Pos2))
end

local function GetMode()
    if _G.SDK then
        if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
            return "Combo"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
            return "Harass"	
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR]     then return "Clear"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
            return "LastHit"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
            return "Flee"
        end
    elseif _G.gsoSDK then
    PrintChat (_G.gsoSDK.Orbwalker:UOL_GetMode()) 
        return _G.gsoSDK.Orbwalker:UOL_GetMode()
    else
        return _G.GOS.GetMode()
    end
end

local function GetTarget(range) 
    local target = nil 
    if _G.EOWLoaded then 
        target = EOW:GetTarget(range) 
    elseif _G.SDK and _G.SDK.Orbwalker then 
        target = _G.SDK.TargetSelector:GetTarget(range) 
    else 
        target = GOS:GetTarget(range) 
    end 
    return target 
end


local function ClosestHero(range,team)
    local bestHero = nil
    local closest = math.huge
    for i = 1, Game.HeroCount() do
        local hero = Game.Hero(i)
        if GetDistance(hero.pos) < range and hero.team == team and not hero.dead then
            local Distance = GetDistance(hero.pos, mousePos)
            if Distance < closest then
                bestHero = hero
                closest = Distance
            end
        end
    end
    return bestHero
end

local function ClosestMinion(range,team)
    local bestMinion = nil
    local closest = math.huge
    for i = 1, Game.MinionCount() do
        local minion = Game.Minion(i)
        if GetDistance(minion.pos) < range and minion.team == team and not minion.dead then
            local Distance = GetDistance(minion.pos, mousePos)
            if Distance < closest then
                bestMinion = minion
                closest = Distance
            end
        end
    end
    return bestMinion
end

local function GetClearMinion(range)
    for i = 1, Game.MinionCount() do
        local minion = Game.Minion(i)
        if GetDistance(minion.pos) < range and not minion.dead and (minion.team == neutral or minion.team == foe) then
            return minion
        end
    end
end

local function Hp(source)
    local source = source or myHero
    return source.health/source.maxHealth * 100
end

local function Mp(source)
    local source = source or myHero
    return source.mana/source.maxMana * 100
end

local function ClosestInjuredHero(range,team,life,includeMe)
    local includeMe = includeMe or true
    local life = life or 101
    local bestHero = nil
    local closest = math.huge
    for i = 1, Game.HeroCount() do
        local hero = Game.Hero(i)
        if GetDistance(hero.pos) < range and hero.team == team and not hero.dead and Hp(hero) < life then
            if includeMe == false and hero.isMe then return end
            local Distance = GetDistance(hero.pos, mousePos)
            if Distance < closest then
                bestHero = hero
                closest = Distance
            end
        end
    end
    return bestHero
end

local function HeroesAround(range, pos, team)
    local pos = pos or myHero.pos
    local team = team or foe
    local Count = 0
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero and hero.team == team and not hero.dead and GetDistance(pos, hero.pos) < range then
			Count = Count + 1
		end
	end
	return Count
end

local function BuffByType(wich,time)
	for i = 0, myHero.buffCount do 
	local buff = myHero:GetBuff(i)
		if buff.type == wich and buff.duration > time then 
			return true
		end
	end
	return false
end

local function ExistSpell(spellname)
    if myHero:GetSpellData(SUMMONER_1).name == spellname or myHero:GetSpellData(SUMMONER_2).name == spellname then
        return true
    end
    return false
end

local function SummonerSlot(spellname)
    if myHero:GetSpellData(SUMMONER_1).name == spellname then
        return SUMMONER_1
    elseif myHero:GetSpellData(SUMMONER_2).name == spellname then
        return SUMMONER_2
    end
end

local ActivatorLoaded = false
Callback.Add("Load", function()
    if ActivatorLoaded == false then
        Utility()
        ActivatorLoaded = true
    end
end)


class "Utility"

local ActivatorIcon = "http://www.antrixcorporate.com/images/antrix-A.png"

function Utility:__init()
	self:Menu()
	Callback.Add("Tick", function() self:Tick() end)
end

function Utility:Menu()
    Activator = MenuElement({type = MENU, id = "Activator", name = "BeastlyActivator v 0.01", leftIcon = ActivatorIcon})

    Activator:MenuElement({id = "Enable", name = "Enable Activator", value = true})

    Activator:MenuElement({type = MENU, id = "Potion", name = "Potion"})
    Activator.Potion:MenuElement({id = "CorruptingPotion", name = "Corrupting Potion", value = true})
    Activator.Potion:MenuElement({id = "HP1", name = "Health % to Potion", value = 60, min = 0, max = 100})
    Activator.Potion:MenuElement({id = "MP1", name = "Mana % to Potion", value = 25, min = 0, max = 100})
    Activator.Potion:MenuElement({id = "HealthPotion", name = "Health Potion", value = true})
    Activator.Potion:MenuElement({id = "HP2", name = "Health % to Potion", value = 60, min = 0, max = 100})
    Activator.Potion:MenuElement({id = "HuntersPotion", name = "Hunter's Potion", value = true})
    Activator.Potion:MenuElement({id = "HP3", name = "Health % to Potion", value = 60, min = 0, max = 100})
    Activator.Potion:MenuElement({id = "MP3", name = "Mana % to Potion", value = 25, min = 0, max = 100})
    Activator.Potion:MenuElement({id = "RefillablePotion", name = "Refillable Potion", value = true})
    Activator.Potion:MenuElement({id = "HP4", name = "Health % to Potion", value = 60, min = 0, max = 100})
    Activator.Potion:MenuElement({id = "ManaPotion", name = "Mana Potion", value = true})
    Activator.Potion:MenuElement({id = "MP5", name = "Mana % to Potion", value = 25, min = 0, max = 100})
    Activator.Potion:MenuElement({id = "PilferedHealthPotion", name = "Pilfered Health Potion", value = true})
    Activator.Potion:MenuElement({id = "HP6", name = "Health % to Potion", value = 60, min = 0, max = 100})
    Activator.Potion:MenuElement({id = "TotalBiscuitofEverlastingWill", name = "Total Biscuit of Everlasting Will", value = true})
    Activator.Potion:MenuElement({id = "HP7", name = "Health % to Potion", value = 60, min = 0, max = 100})
    Activator.Potion:MenuElement({id = "MP7", name = "Mana % to Potion", value = 25, min = 0, max = 100})
    
    Activator:MenuElement({type = MENU, id = "Combo", name = "Combo"})
    Activator.Combo:MenuElement({id = "Ignite", name = "Ignite", value = true})
    Activator.Combo:MenuElement({id = "Smite", name = "Smite", value = true})
    Activator.Combo:MenuElement({id = "Exhaust", name = "Exhaust", value = true})
    Activator.Combo:MenuElement({id = " ", name = " ", type = SPACE})
    Activator.Combo:MenuElement({id = "BilgewaterCutlass", name = "Bilgewater Cutlass", value = true})
    Activator.Combo:MenuElement({id = "Tiamat", name = "Tiamat", value = true})
    Activator.Combo:MenuElement({id = "BladeoftheRuinedKing", name = "Blade of the Ruined King", value = true})
    Activator.Combo:MenuElement({id = "HextechGLP800", name = "Hextech GLP-800", value = true})
    Activator.Combo:MenuElement({id = "HextechGunblade", name = "Hextech Gunblade", value = true})
    Activator.Combo:MenuElement({id = "HextechProtobelt01", name = "Hextech Protobelt-01", value = true})
    Activator.Combo:MenuElement({id = "RanduinsOmen", name = "Randuin's Omen", value = true})
    Activator.Combo:MenuElement({id = "RavenousHydra", name = "Ravenous Hydra", value = true})
    Activator.Combo:MenuElement({id = "Spellbinder", name = "Spellbinder", value = true})
    Activator.Combo:MenuElement({id = "TitanicHydra", name = "Titanic Hydra", value = true})

    Activator:MenuElement({type = MENU, id = "Harass", name = "Harass"})
    Activator.Harass:MenuElement({id = "Ignite", name = "Ignite", value = true})
    Activator.Harass:MenuElement({id = "Smite", name = "Smite", value = true})
    Activator.Harass:MenuElement({id = "Exhaust", name = "Exhaust", value = true})
    Activator.Harass:MenuElement({id = " ", name = " ", type = SPACE})
    Activator.Harass:MenuElement({id = "BilgewaterCutlass", name = "Bilgewater Cutlass", value = true})
    Activator.Harass:MenuElement({id = "Tiamat", name = "Tiamat", value = true})
    Activator.Harass:MenuElement({id = "BladeoftheRuinedKing", name = "Blade of the Ruined King", value = true})
    Activator.Harass:MenuElement({id = "HextechGLP800", name = "Hextech GLP-800", value = true})
    Activator.Harass:MenuElement({id = "HextechGunblade", name = "Hextech Gunblade", value = true})
    Activator.Harass:MenuElement({id = "HextechProtobelt01", name = "Hextech Protobelt-01", value = true})
    Activator.Harass:MenuElement({id = "RanduinsOmen", name = "Randuin's Omen", value = true})
    Activator.Harass:MenuElement({id = "RavenousHydra", name = "Ravenous Hydra", value = true})
    Activator.Harass:MenuElement({id = "Spellbinder", name = "Spellbinder", value = true})
    Activator.Harass:MenuElement({id = "TitanicHydra", name = "Titanic Hydra", value = true})

    Activator:MenuElement({type = MENU, id = "Clear", name = "Clear"})
    Activator.Clear:MenuElement({id = "Tiamat", name = "Tiamat", value = true})
    Activator.Clear:MenuElement({id = "HextechGLP800", name = "Hextech GLP-800", value = true})
    Activator.Clear:MenuElement({id = "HextechProtobelt01", name = "Hextech Protobelt-01", value = true})
    Activator.Clear:MenuElement({id = "RavenousHydra", name = "Ravenous Hydra", value = true})
    Activator.Clear:MenuElement({id = "TitanicHydra", name = "Titanic Hydra", value = true})

    Activator:MenuElement({type = MENU, id = "Flee", name = "Flee"})
    Activator.Flee:MenuElement({id = "Exhaust", name = "Exhaust", value = true})
    Activator.Flee:MenuElement({id = " ", name = " ", type = SPACE})
    Activator.Flee:MenuElement({id = "BilgewaterCutlass", name = "Bilgewater Cutlass", value = true})
    Activator.Flee:MenuElement({id = "BladeoftheRuinedKing", name = "Blade of the Ruined King", value = true})
    Activator.Flee:MenuElement({id = "HextechGLP800", name = "Hextech GLP-800", value = true})
    Activator.Flee:MenuElement({id = "HextechGunblade", name = "Hextech Gunblade", value = true})
    Activator.Flee:MenuElement({id = "HextechProtobelt01", name = "Hextech Protobelt-01", value = true})
    Activator.Flee:MenuElement({id = "RanduinsOmen", name = "Randuin's Omen", value = true})
    Activator.Flee:MenuElement({id = "RighteousGlory", name = "Righteous Glory", value = true})
    Activator.Flee:MenuElement({id = "TwinShadows", name = "Twin Shadows", value = true})
    Activator.Flee:MenuElement({id = "YoumuusGhostblade", name = "Youmuu's Ghostblade", value = true})

    Activator:MenuElement({type = MENU, id = "Shield", name = "Shield"})
    Activator.Shield:MenuElement({id = "Barrier", name = "Barrier", value = true})
    Activator.Shield:MenuElement({id = "HPS1", name = "Health % to Shield", value = 15, min = 0, max = 100})
    Activator.Shield:MenuElement({id = " ", name = " ", type = SPACE})
    Activator.Shield:MenuElement({id = "Stopwatch", name = "Stopwatch", value = true})
    Activator.Shield:MenuElement({id = "HP1", name = "Health % to Shield", value = 15, min = 0, max = 100})
    Activator.Shield:MenuElement({id = "GargoyleStoneplate", name = "Gargoyle Stoneplate", value = true})
    Activator.Shield:MenuElement({id = "HP2", name = "Health % to Shield", value = 15, min = 0, max = 100})
    Activator.Shield:MenuElement({id = "LocketoftheIronSolari", name = "Locket of the Iron Solari", value = true})
    Activator.Shield:MenuElement({id = "HP3", name = "Health % to Shield", value = 15, min = 0, max = 100})
    Activator.Shield:MenuElement({id = "SeraphsEmbrace", name = "Seraph's Embrace", value = true})
    Activator.Shield:MenuElement({id = "HP4", name = "Health % to Shield", value = 15, min = 0, max = 100})
    Activator.Shield:MenuElement({id = "WoogletsWitchcap", name = "Wooglet's Witchcap", value = true})
    Activator.Shield:MenuElement({id = "HP5", name = "Health % to Shield", value = 15, min = 0, max = 100})
    Activator.Shield:MenuElement({id = "ZhonyasHourglass", name = "Zhonya's Hourglass", value = true})
    Activator.Shield:MenuElement({id = "HP6", name = "Health % to Shield", value = 15, min = 0, max = 100})

    Activator:MenuElement({type = MENU, id = "Heal", name = "Heal"})
    Activator.Heal:MenuElement({id = "Heal", name = "Heal", value = true})
    Activator.Heal:MenuElement({id = "HPS1", name = "Health % to Heal", value = 15, min = 0, max = 100})
    Activator.Heal:MenuElement({id = " ", name = " ", type = SPACE})
    Activator.Heal:MenuElement({id = "Redemption", name = "Redemption", value = true})
    Activator.Heal:MenuElement({id = "HP1", name = "Health % to Heal", value = 15, min = 0, max = 100})

    Activator:MenuElement({type = MENU, id = "Auto", name = "Auto"})
    Activator.Auto:MenuElement({id = "Ignite", name = "Ignite", value = true})

    Activator:MenuElement({type = MENU, id = "Cleanse", name = "Cleanse"})
    Activator.Cleanse:MenuElement({id = "Cleanse", name = "Cleanse", value = true})
    Activator.Cleanse:MenuElement({id = "DS1", name = "Duration to Cleanse", value = 1, min = .1, max = 5, step = .1})
    Activator.Cleanse:MenuElement({id = " ", name = " ", type = SPACE})
    Activator.Cleanse:MenuElement({id = "QuicksilverSash", name = "Quicksilver Sash", value = true})
    Activator.Cleanse:MenuElement({id = "D1", name = "Duration to Cleanse", value = 1, min = .1, max = 5, step = .1})
    Activator.Cleanse:MenuElement({id = "MercurialScimitar", name = "Mercurial Scimitar", value = true})
    Activator.Cleanse:MenuElement({id = "D2", name = "Duration to Cleanse", value = 1, min = .1, max = 5, step = .1})
    Activator.Cleanse:MenuElement({id = "MikaelsCrucible", name = "Mikael's Crucible", value = true})
    Activator.Cleanse:MenuElement({id = "D3", name = "Duration to Cleanse", value = 1, min = .1, max = 5, step = .1})
    Activator.Cleanse:MenuElement({id = " ", name = " ", type = SPACE})
    Activator.Cleanse:MenuElement({id = "Stun", name = "Stun", value = true})
    Activator.Cleanse:MenuElement({id = "Root", name = "Root", value = true})
    Activator.Cleanse:MenuElement({id = "Taunt", name = "Taunt", value = true})
    Activator.Cleanse:MenuElement({id = "Fear", name = "Fear", value = true})
    Activator.Cleanse:MenuElement({id = "Charm", name = "Charm", value = true})
    Activator.Cleanse:MenuElement({id = "Silence", name = "Silence", value = true})
    Activator.Cleanse:MenuElement({id = "Slow", name = "Slow", value = true})
    Activator.Cleanse:MenuElement({id = "Blind", name = "Blind", value = true})
    Activator.Cleanse:MenuElement({id = "Disarm", name = "Disarm", value = true})
    Activator.Cleanse:MenuElement({id = "Sleep", name = "Sleep", value = true})
    Activator.Cleanse:MenuElement({id = "Nearsight", name = "Nearsight", value = true})
    Activator.Cleanse:MenuElement({id = "Suppression", name = "Suppression", value = true})
end

function Utility:Tick()
    if not Activator.Enable:Value() then return end
    self:Auto()
    self:Cleanse()
    self:Shield()
    self:Heal()
    local mode = GetMode()
    if mode == "Combo" then
        self:Combo()
    end
    if mode == "Harass" then
        self:Harass()
    end
    if mode == "Clear" then
        self:Clear()
    end
    if mode == "Flee" then
        self:Flee()
    end
end

function Utility:Auto()
    local ExistIgnite = ExistSpell("SummonerDot")
    local IgniteSlot = SummonerSlot("SummonerDot")
    local IgniteDamage = 70 + 20 * myHero.levelData.lvl
    local IgniteTarget = ClosestHero(600,foe)
    if ExistIgnite and Ready(IgniteSlot) and IgniteTarget and Activator.Auto.Ignite:Value() then
        if IgniteDamage > IgniteTarget.health then
            Control.CastSpell(HKSPELL[IgniteSlot], IgniteTarget)
        end
    end
end

function Utility:Combo()
    local PostAttack = myHero.attackData.state == STATE_WINDDOWN
    local items = {}
	for slot = ITEM_1,ITEM_6 do
		local id = myHero:GetItemData(slot).itemID 
		if id > 0 then
			items[id] = slot
		end
    end
    local BilgewaterCutlass = items[3144]
    local Tiamat = items[3077]
    local BladeoftheRuinedKing = items[3153]
    local HextechGLP800 = items[3030]
    local HextechGunblade = items[3146]
    local HextechProtobelt01 = items[3152]
    local RanduinsOmen = items[3143]
    local RavenousHydra = items[3074]
    local Spellbinder = items[3907]
    local TitanicHydra = items[3748]
    
    local BilgewaterCutlassTarget = GetTarget(550)
    if BilgewaterCutlass and Ready(BilgewaterCutlass) and BilgewaterCutlassTarget and Activator.Combo.BilgewaterCutlass:Value() then
        Control.CastSpell(HKITEM[BilgewaterCutlass], BilgewaterCutlassTarget)
    end
    local TiamatTarget = GetTarget(400)
    if Tiamat and Ready(Tiamat) and TiamatTarget and Activator.Combo.Tiamat:Value() and PostAttack then
        Control.CastSpell(HKITEM[Tiamat], TiamatTarget)
    end
    local BladeoftheRuinedKingTarget = GetTarget(550)
    if BladeoftheRuinedKing and Ready(BladeoftheRuinedKing) and BladeoftheRuinedKingTarget and Activator.Combo.BladeoftheRuinedKing:Value() then
        Control.CastSpell(HKITEM[BladeoftheRuinedKing], BladeoftheRuinedKingTarget)
    end
    local HextechGLP800Target = GetTarget(700)
    if HextechGLP800 and Ready(HextechGLP800) and HextechGLP800Target and Activator.Combo.HextechGLP800:Value() then
        Control.CastSpell(HKITEM[HextechGLP800], HextechGLP800Target)
    end
    local HextechGunbladeTarget = GetTarget(700)
    if HextechGunblade and Ready(HextechGunblade) and HextechGunbladeTarget and Activator.Combo.HextechGunblade:Value() then
        Control.CastSpell(HKITEM[HextechGunblade], HextechGunbladeTarget)
    end
    local HextechProtobelt01Target = GetTarget(700)
    if HextechProtobelt01 and Ready(HextechProtobelt01) and HextechProtobelt01Target and Activator.Combo.HextechProtobelt01:Value() then
        Control.CastSpell(HKITEM[HextechProtobelt01], HextechProtobelt01Target)
    end
    local RanduinsOmenTarget = GetTarget(500)
    if RanduinsOmen and Ready(RanduinsOmen) and RanduinsOmenTarget and Activator.Combo.RanduinsOmen:Value() then
        Control.CastSpell(HKITEM[RanduinsOmen])
    end
    local RavenousHydraTarget = GetTarget(400)
    if RavenousHydra and Ready(RavenousHydra) and RavenousHydraTarget and Activator.Combo.RavenousHydra:Value() and PostAttack then
        Control.CastSpell(HKITEM[RavenousHydra], RavenousHydraTarget)
    end
    local SpellbinderTarget = GetTarget(900)
    if Spellbinder and Ready(Spellbinder) and SpellbinderTarget and Activator.Combo.Spellbinder:Value() then
        Control.CastSpell(HKITEM[Spellbinder])
    end
    local TitanicHydraTarget = GetTarget(400)
    if TitanicHydra and Ready(TitanicHydra) and TitanicHydraTarget and Activator.Combo.TitanicHydra:Value() and PostAttack then
        Control.CastSpell(HKITEM[TitanicHydra], TitanicHydraTarget)
    end

    local ExistIgnite = ExistSpell("SummonerDot")
    local IgniteSlot = SummonerSlot("SummonerDot")
    local IgniteTarget = GetTarget(600)
    if ExistIgnite and Ready(IgniteSlot) and IgniteTarget and Activator.Combo.Ignite:Value() then
        Control.CastSpell(HKSPELL[IgniteSlot], IgniteTarget)
    end
    local ExistExhaust = ExistSpell("SummonerExhaust")
    local ExhaustSlot = SummonerSlot("SummonerExhaust")
    local ExhaustTarget = GetTarget(650)
    if ExistExhaust and Ready(ExhaustSlot) and ExhaustTarget and Activator.Combo.Exhaust:Value() then
        Control.CastSpell(HKSPELL[ExhaustSlot], ExhaustTarget)
    end
    local ExistSmite = ExistSpell("S5_SummonerSmitePlayerGanker") or ExistSpell("S5_SummonerSmiteDuel")
    local SmiteSlot = SummonerSlot("S5_SummonerSmitePlayerGanker") or SummonerSlot("S5_SummonerSmiteDuel")
    local SmiteTarget = GetTarget(500 + myHero.boundingRadius)
    if ExistSmite and Ready(SmiteSlot) and IsUp(SmiteSlot) and SmiteTarget and Activator.Combo.Smite:Value() then
        Control.CastSpell(HKSPELL[SmiteSlot], SmiteTarget)
    end
end

function Utility:Harass()
    local PostAttack = myHero.attackData.state == STATE_WINDDOWN
    local items = {}
	for slot = ITEM_1,ITEM_6 do
		local id = myHero:GetItemData(slot).itemID 
		if id > 0 then
			items[id] = slot
		end
    end
    local BilgewaterCutlass = items[3144]
    local Tiamat = items[3077]
    local BladeoftheRuinedKing = items[3153]
    local HextechGLP800 = items[3030]
    local HextechGunblade = items[3146]
    local HextechProtobelt01 = items[3152]
    local RanduinsOmen = items[3143]
    local RavenousHydra = items[3074]
    local Spellbinder = items[3907]
    local TitanicHydra = items[3748]
    
    local BilgewaterCutlassTarget = GetTarget(550)
    if BilgewaterCutlass and Ready(BilgewaterCutlass) and BilgewaterCutlassTarget and Activator.Harass.BilgewaterCutlass:Value() then
        Control.CastSpell(HKITEM[BilgewaterCutlass], BilgewaterCutlassTarget)
    end
    local TiamatTarget = GetTarget(400)
    if Tiamat and Ready(Tiamat) and TiamatTarget and Activator.Harass.Tiamat:Value() and PostAttack then
        Control.CastSpell(HKITEM[Tiamat], TiamatTarget)
    end
    local BladeoftheRuinedKingTarget = GetTarget(550)
    if BladeoftheRuinedKing and Ready(BladeoftheRuinedKing) and BladeoftheRuinedKingTarget and Activator.Harass.BladeoftheRuinedKing:Value() then
        Control.CastSpell(HKITEM[BladeoftheRuinedKing], BladeoftheRuinedKingTarget)
    end
    local HextechGLP800Target = GetTarget(700)
    if HextechGLP800 and Ready(HextechGLP800) and HextechGLP800Target and Activator.Harass.HextechGLP800:Value() then
        Control.CastSpell(HKITEM[HextechGLP800], HextechGLP800Target)
    end
    local HextechGunbladeTarget = GetTarget(700)
    if HextechGunblade and Ready(HextechGunblade) and HextechGunbladeTarget and Activator.Harass.HextechGunblade:Value() then
        Control.CastSpell(HKITEM[HextechGunblade], HextechGunbladeTarget)
    end
    local HextechProtobelt01Target = GetTarget(700)
    if HextechProtobelt01 and Ready(HextechProtobelt01) and HextechProtobelt01Target and Activator.Harass.HextechProtobelt01:Value() then
        Control.CastSpell(HKITEM[HextechProtobelt01], HextechProtobelt01Target)
    end
    local RanduinsOmenTarget = GetTarget(500)
    if RanduinsOmen and Ready(RanduinsOmen) and RanduinsOmenTarget and Activator.Harass.RanduinsOmen:Value() then
        Control.CastSpell(HKITEM[RanduinsOmen])
    end
    local RavenousHydraTarget = GetTarget(400)
    if RavenousHydra and Ready(RavenousHydra) and RavenousHydraTarget and Activator.Harass.RavenousHydra:Value() and PostAttack then
        Control.CastSpell(HKITEM[RavenousHydra], RavenousHydraTarget)
    end
    local SpellbinderTarget = GetTarget(900)
    if Spellbinder and Ready(Spellbinder) and SpellbinderTarget and Activator.Harass.Spellbinder:Value() then
        Control.CastSpell(HKITEM[Spellbinder])
    end
    local TitanicHydraTarget = GetTarget(400)
    if TitanicHydra and Ready(TitanicHydra) and TitanicHydraTarget and Activator.Harass.TitanicHydra:Value() and PostAttack then
        Control.CastSpell(HKITEM[TitanicHydra], TitanicHydraTarget)
    end

    local ExistIgnite = ExistSpell("SummonerDot")
    local IgniteSlot = SummonerSlot("SummonerDot")
    local IgniteTarget = GetTarget(600)
    if ExistIgnite and Ready(IgniteSlot) and IgniteTarget and Activator.Harass.Ignite:Value() then
        Control.CastSpell(HKSPELL[IgniteSlot], IgniteTarget)
    end
    local ExistExhaust = ExistSpell("SummonerExhaust")
    local ExhaustSlot = SummonerSlot("SummonerExhaust")
    local ExhaustTarget = GetTarget(650)
    if ExistExhaust and Ready(ExhaustSlot) and ExhaustTarget and Activator.Harass.Exhaust:Value() then
        Control.CastSpell(HKSPELL[ExhaustSlot], ExhaustTarget)
    end
    local ExistSmite = ExistSpell("S5_SummonerSmitePlayerGanker") or ExistSpell("S5_SummonerSmiteDuel")
    local SmiteSlot = SummonerSlot("S5_SummonerSmitePlayerGanker") or SummonerSlot("S5_SummonerSmiteDuel")
    local SmiteTarget = GetTarget(500 + myHero.boundingRadius)
    if ExistSmite and Ready(SmiteSlot) and IsUp(SmiteSlot) and SmiteTarget and Activator.Harass.Smite:Value() then
        Control.CastSpell(HKSPELL[SmiteSlot], SmiteTarget)
    end
end

function Utility:Clear()
    local PostAttack = myHero.attackData.state == STATE_WINDDOWN
    local items = {}
	for slot = ITEM_1,ITEM_6 do
		local id = myHero:GetItemData(slot).itemID 
		if id > 0 then
			items[id] = slot
		end
    end
    local Tiamat = items[3077]
    local HextechGLP800 = items[3030]
    local HextechProtobelt01 = items[3152]
    local RavenousHydra = items[3074]
    local TitanicHydra = items[3748]

    local TiamatTarget = GetClearMinion(400)
    if Tiamat and Ready(Tiamat) and TiamatTarget and Activator.Clear.Tiamat:Value() and PostAttack then
        Control.CastSpell(HKITEM[Tiamat], TiamatTarget)
    end
    local HextechGLP800Target = GetClearMinion(700)
    if HextechGLP800 and Ready(HextechGLP800) and HextechGLP800Target and Activator.Clear.HextechGLP800:Value() then
        Control.CastSpell(HKITEM[HextechGLP800], HextechGLP800Target)
    end
    local HextechProtobelt01Target = GetClearMinion(700)
    if HextechProtobelt01 and Ready(HextechProtobelt01) and HextechProtobelt01Target and Activator.Clear.HextechProtobelt01:Value() then
        Control.CastSpell(HKITEM[HextechProtobelt01], HextechProtobelt01Target)
    end
    local RavenousHydraTarget = GetClearMinion(400)
    if RavenousHydra and Ready(RavenousHydra) and RavenousHydraTarget and Activator.Clear.RavenousHydra:Value() and PostAttack then
        Control.CastSpell(HKITEM[RavenousHydra], RavenousHydraTarget)
    end
    local TitanicHydraTarget = GetClearMinion(400)
    if TitanicHydra and Ready(TitanicHydra) and TitanicHydraTarget and Activator.Clear.TitanicHydra:Value() and PostAttack then
        Control.CastSpell(HKITEM[TitanicHydra], TitanicHydraTarget)
    end
end

function Utility:Flee()
    local items = {}
	for slot = ITEM_1,ITEM_6 do
		local id = myHero:GetItemData(slot).itemID 
		if id > 0 then
			items[id] = slot
		end
    end
    local BilgewaterCutlass = items[3144]
    local BladeoftheRuinedKing = items[3153]
    local HextechGLP800 = items[3030]
    local HextechGunblade = items[3146]
    local HextechProtobelt01 = items[3152]
    local RanduinsOmen = items[3143]
    local RighteousGlory = items[3800]
    local ShurelyasReverie = items[2056]
    local TwinShadows = items[3905]
    local YoumuusGhostblade = items[3142]

    local BilgewaterCutlassTarget = ClosestHero(550,foe)
    if BilgewaterCutlass and Ready(BilgewaterCutlass) and BilgewaterCutlassTarget and Activator.Flee.BilgewaterCutlass:Value() then
        Control.CastSpell(HKITEM[BilgewaterCutlass], BilgewaterCutlassTarget)
    end
    local BladeoftheRuinedKingTarget = ClosestHero(550,foe)
    if BladeoftheRuinedKing and Ready(BladeoftheRuinedKing) and BladeoftheRuinedKingTarget and Activator.Flee.BladeoftheRuinedKing:Value() then
        Control.CastSpell(HKITEM[BladeoftheRuinedKing], BladeoftheRuinedKingTarget)
    end
    local HextechGLP800Target = ClosestHero(700,foe)
    if HextechGLP800 and Ready(HextechGLP800) and HextechGLP800Target and Activator.Flee.HextechGLP800:Value() then
        Control.CastSpell(HKITEM[HextechGLP800], HextechGLP800Target)
    end
    local HextechGunbladeTarget = ClosestHero(700,foe)
    if HextechGunblade and Ready(HextechGunblade) and HextechGunbladeTarget and Activator.Flee.HextechGunblade:Value() then
        Control.CastSpell(HKITEM[HextechGunblade], HextechGunbladeTarget)
    end
    if HextechProtobelt01 and Ready(HextechProtobelt01) and Activator.Flee.HextechProtobelt01:Value() then
        Control.CastSpell(HKITEM[HextechProtobelt01], Game.cursorPos())
    end
    local RanduinsOmenTarget = ClosestHero(500,foe)
    if RanduinsOmen and Ready(RanduinsOmen) and RanduinsOmenTarget and Activator.Flee.RanduinsOmen:Value() then
        Control.CastSpell(HKITEM[RanduinsOmen])
    end
    if RighteousGlory and Ready(RighteousGlory) and Activator.Flee.RighteousGlory:Value() then
        Control.CastSpell(HKITEM[RighteousGlory])
    end
    local TwinShadowsTarget = ClosestHero(1500,foe)
    if TwinShadows and Ready(TwinShadows) and TwinShadowsTarget and Activator.Flee.TwinShadows:Value() then
        Control.CastSpell(HKITEM[TwinShadows])
    end
    if YoumuusGhostblade and Ready(YoumuusGhostblade) and Activator.Flee.YoumuusGhostblade:Value() then
        Control.CastSpell(HKITEM[YoumuusGhostblade])
    end

    local ExistExhaust = ExistSpell("SummonerExhaust")
    local ExhaustSlot = SummonerSlot("SummonerExhaust")
    local ExhaustTarget = GetTarget(650)
    if ExistExhaust and Ready(ExhaustSlot) and ExhaustTarget and Activator.Flee.Exhaust:Value() then
        Control.CastSpell(HKSPELL[ExhaustSlot], ExhaustTarget)
    end
end

function Utility:Shield()
    local items = {}
	for slot = ITEM_1,ITEM_6 do
		local id = myHero:GetItemData(slot).itemID 
		if id > 0 then
			items[id] = slot
		end
    end
    local Stopwatch = items[2420] or items[2423]
    local GargoyleStoneplate = items[3193]
    local LocketoftheIronSolari = items[3190] or items[3383]
    local SeraphsEmbrace = items[3040] or items[3048]
    local WoogletsWitchcap = items[3090] or items[3385]
    local ZhonyasHourglass = items[3157] or items[3386]

    local StopwatchTarget = ClosestHero(700,foe)
    if Stopwatch and Ready(Stopwatch) and StopwatchTarget and Activator.Shield.Stopwatch:Value() and Hp() < Activator.Shield.HP1:Value() then
        Control.CastSpell(HKITEM[Stopwatch])
    end
    local GargoyleStoneplateTarget = ClosestHero(1500,foe)
    if GargoyleStoneplate and Ready(GargoyleStoneplate) and GargoyleStoneplateTarget and Activator.Shield.GargoyleStoneplate:Value() and Hp() < Activator.Shield.HP2:Value() then
        Control.CastSpell(HKITEM[GargoyleStoneplate])
    end
    local LocketoftheIronSolariAlly = ClosestInjuredHero(600,friend,Activator.Shield.HP3:Value(),true)
    if LocketoftheIronSolari and Ready(LocketoftheIronSolari) and LocketoftheIronSolariAlly and HeroesAround(1500,LocketoftheIronSolariAlly.pos) ~= 0 and Activator.Shield.LocketoftheIronSolari:Value() then
        Control.CastSpell(HKITEM[LocketoftheIronSolari])
    end
    local SeraphsEmbraceTarget = ClosestHero(1500,foe)
    if SeraphsEmbrace and Ready(SeraphsEmbrace) and SeraphsEmbraceTarget and Activator.Shield.SeraphsEmbrace:Value() and Hp() < Activator.Shield.HP4:Value() then
        Control.CastSpell(HKITEM[SeraphsEmbrace])
    end
    local WoogletsWitchcapTarget = ClosestHero(700,foe)
    if WoogletsWitchcap and Ready(WoogletsWitchcap) and WoogletsWitchcapTarget and Activator.Shield.WoogletsWitchcap:Value() and Hp() < Activator.Shield.HP5:Value() then
        Control.CastSpell(HKITEM[WoogletsWitchcap])
    end
    local ZhonyasHourglassTarget = ClosestHero(700,foe)
    if ZhonyasHourglass and Ready(ZhonyasHourglass) and ZhonyasHourglassTarget and Activator.Shield.ZhonyasHourglass:Value() and Hp() < Activator.Shield.HP6:Value() then
        Control.CastSpell(HKITEM[ZhonyasHourglass])
    end

    local ExistBarrier = ExistSpell("SummonerBarrier")
    local BarrierSlot = SummonerSlot("SummonerBarrier")
    local BarrierTarget = ClosestHero(1500,foe)
    if ExistBarrier and Ready(BarrierSlot) and BarrierTarget and Activator.Shield.Barrier:Value() and Hp() < Activator.Shield.HPS1:Value() then
        Control.CastSpell(HKSPELL[BarrierSlot])
    end
end

function Utility:Heal()
    local items = {}
	for slot = ITEM_1,ITEM_6 do
		local id = myHero:GetItemData(slot).itemID 
		if id > 0 then
			items[id] = slot
		end
    end
    local CorruptingPotion = items[2033]
    local HealthPotion = items[2003]
    local HuntersPotion = items[2032]
    local RefillablePotion = items[2031]
    local ManaPotion = items[2004]
    local PilferedHealthPotion = items[2061]
    local TotalBiscuitofEverlastingWill = items[2010]
    local Redemption = items[3107] or items[3382]

    local RedemptionAlly = ClosestInjuredHero(5500,friend,Activator.Heal.HP1:Value(),true)
    if Redemption and Ready(Redemption) and RedemptionAlly and HeroesAround(1500,RedemptionAlly.pos) ~= 0 and Activator.Heal.Redemption:Value() then
        Control.CastSpell(HKITEM[Redemption], RedemptionAlly)
    end

    local ExistHeal = ExistSpell("SummonerHeal")
    local HealSlot = SummonerSlot("SummonerHeal")
    local HealTarget = ClosestHero(1500,foe)
    if ExistHeal and Ready(HealSlot) and HealTarget and Activator.Heal.Heal:Value() and Hp() < Activator.Heal.HPS1:Value() then
        Control.CastSpell(HKSPELL[HealSlot])
    end

    if BuffByType(13,0.1) then return end

    local CorruptingPotionTarget = ClosestHero(1500,foe) or ClosestMinion(400,neutral)
    if CorruptingPotion and Ready(CorruptingPotion) and CorruptingPotionTarget and Activator.Potion.CorruptingPotion:Value() and (Hp() < Activator.Potion.HP1:Value() or Mp() < Activator.Potion.MP1:Value()) then
        Control.CastSpell(HKITEM[CorruptingPotion])
    end
    local HealthPotionTarget = ClosestHero(1500,foe) or ClosestMinion(400,neutral)
    if HealthPotion and Ready(HealthPotion) and HealthPotionTarget and Activator.Potion.HealthPotion:Value() and Hp() < Activator.Potion.HP2:Value() then
        Control.CastSpell(HKITEM[HealthPotion])
    end
    local HuntersPotionTarget = ClosestHero(1500,foe) or ClosestMinion(400,neutral)
    if HuntersPotion and Ready(HuntersPotion) and HuntersPotionTarget and Activator.Potion.HuntersPotion:Value() and (Hp() < Activator.Potion.HP3:Value() or Mp() < Activator.Potion.MP3:Value()) then
        Control.CastSpell(HKITEM[HuntersPotion])
    end
    local RefillablePotionTarget = ClosestHero(1500,foe) or ClosestMinion(400,neutral)
    if RefillablePotion and Ready(RefillablePotion) and RefillablePotionTarget and Activator.Potion.RefillablePotion:Value() and Hp() < Activator.Potion.HP4:Value() then
        Control.CastSpell(HKITEM[RefillablePotion])
    end
    local ManaPotionTarget = ClosestHero(1500,foe)
    if ManaPotion and Ready(ManaPotion) and ManaPotionTarget and Activator.Potion.ManaPotion:Value() and Mp() < Activator.Potion.MP5:Value() then
        Control.CastSpell(HKITEM[ManaPotion])
    end
    local PilferedHealthPotionTarget = ClosestHero(1500,foe) or ClosestMinion(400,neutral)
    if PilferedHealthPotion and Ready(PilferedHealthPotion) and PilferedHealthPotionTarget and Activator.Potion.PilferedHealthPotion:Value() and Hp() < Activator.Potion.HP6:Value() then
        Control.CastSpell(HKITEM[PilferedHealthPotion])
    end
    local TotalBiscuitofEverlastingWillTarget = ClosestHero(1500,foe) or ClosestMinion(400,neutral)
    if TotalBiscuitofEverlastingWill and Ready(TotalBiscuitofEverlastingWill) and TotalBiscuitofEverlastingWillTarget and Activator.Potion.TotalBiscuitofEverlastingWill:Value() and (Hp() < Activator.Potion.HP7:Value() or Mp() < Activator.Potion.MP7:Value()) then
        Control.CastSpell(HKITEM[TotalBiscuitofEverlastingWill])
    end
end

function Utility:Cleanse()
    local items = {}
	for slot = ITEM_1,ITEM_6 do
		local id = myHero:GetItemData(slot).itemID 
		if id > 0 then
			items[id] = slot
		end
    end
    local QuicksilverSash = items[3140]
    local MercurialScimitar = items[3139]
    local MikaelsCrucible = items[3222]

    local QuicksilverSashTarget = ClosestHero(1500,foe)
    if QuicksilverSash and Ready(QuicksilverSash) and QuicksilverSashTarget and Activator.Cleanse.QuicksilverSash:Value() then
        if (BuffByType(5,Activator.Cleanse.D1:Value()) and Activator.Cleanse.Stun:Value()) or
            (BuffByType(7,Activator.Cleanse.D1:Value()) and Activator.Cleanse.Silence:Value()) or
            (BuffByType(8,Activator.Cleanse.D1:Value()) and Activator.Cleanse.Taunt:Value()) or
            ((BuffByType(9,Activator.Cleanse.D1:Value()) or BuffByType(31,Activator.Cleanse.D1:Value())) and Activator.Cleanse.Disarm:Value()) or
            (BuffByType(10,Activator.Cleanse.D1:Value()) and Activator.Cleanse.Slow:Value()) or
            (BuffByType(11,Activator.Cleanse.D1:Value()) and Activator.Cleanse.Root:Value()) or
            (BuffByType(18,Activator.Cleanse.D1:Value()) and Activator.Cleanse.Sleep:Value()) or
            (BuffByType(19,Activator.Cleanse.D1:Value()) and Activator.Cleanse.Nearsight:Value()) or
            ((BuffByType(21,Activator.Cleanse.D1:Value()) or BuffByType(28,Activator.Cleanse.D1:Value())) and Activator.Cleanse.Fear:Value()) or
            (BuffByType(22,Activator.Cleanse.D1:Value()) and Activator.Cleanse.Charm:Value()) or
            (BuffByType(24,Activator.Cleanse.D1:Value()) and Activator.Cleanse.Suppression:Value()) or
            (BuffByType(25,Activator.Cleanse.D1:Value()) and Activator.Cleanse.Blind:Value()) then
            Control.CastSpell(HKITEM[QuicksilverSash])
        end
    end
    local MercurialScimitarTarget = ClosestHero(1500,foe)
    if MercurialScimitar and Ready(MercurialScimitar) and MercurialScimitarTarget and Activator.Cleanse.MercurialScimitar:Value() then
        if (BuffByType(5,Activator.Cleanse.D2:Value()) and Activator.Cleanse.Stun:Value()) or
            (BuffByType(7,Activator.Cleanse.D2:Value()) and Activator.Cleanse.Silence:Value()) or
            (BuffByType(8,Activator.Cleanse.D2:Value()) and Activator.Cleanse.Taunt:Value()) or
            ((BuffByType(9,Activator.Cleanse.D2:Value()) or BuffByType(31,Activator.Cleanse.D2:Value())) and Activator.Cleanse.Disarm:Value()) or
            (BuffByType(10,Activator.Cleanse.D2:Value()) and Activator.Cleanse.Slow:Value()) or
            (BuffByType(11,Activator.Cleanse.D2:Value()) and Activator.Cleanse.Root:Value()) or
            (BuffByType(18,Activator.Cleanse.D2:Value()) and Activator.Cleanse.Sleep:Value()) or
            (BuffByType(19,Activator.Cleanse.D2:Value()) and Activator.Cleanse.Nearsight:Value()) or
            ((BuffByType(21,Activator.Cleanse.D2:Value()) or BuffByType(28,Activator.Cleanse.D2:Value())) and Activator.Cleanse.Fear:Value()) or
            (BuffByType(22,Activator.Cleanse.D2:Value()) and Activator.Cleanse.Charm:Value()) or
            (BuffByType(24,Activator.Cleanse.D2:Value()) and Activator.Cleanse.Suppression:Value()) or
            (BuffByType(25,Activator.Cleanse.D2:Value()) and Activator.Cleanse.Blind:Value()) then
            Control.CastSpell(HKITEM[MercurialScimitar])
        end
    end
    local MikaelsCrucibleAlly = ClosestInjuredHero(750,friend,101,false)
    if MikaelsCrucible and Ready(MikaelsCrucible) and MikaelsCrucibleAlly and HeroesAround(1500,MikaelsCrucibleAlly.pos) ~= 0 and Activator.Cleanse.MikaelsCrucible:Value() then
        if (BuffByType(5,Activator.Cleanse.D3:Value()) and Activator.Cleanse.Stun:Value()) or
            (BuffByType(7,Activator.Cleanse.D3:Value()) and Activator.Cleanse.Silence:Value()) or
            (BuffByType(8,Activator.Cleanse.D3:Value()) and Activator.Cleanse.Taunt:Value()) or
            ((BuffByType(9,Activator.Cleanse.D3:Value()) or BuffByType(31,Activator.Cleanse.D3:Value())) and Activator.Cleanse.Disarm:Value()) or
            (BuffByType(10,Activator.Cleanse.D3:Value()) and Activator.Cleanse.Slow:Value()) or
            (BuffByType(11,Activator.Cleanse.D3:Value()) and Activator.Cleanse.Root:Value()) or
            (BuffByType(18,Activator.Cleanse.D3:Value()) and Activator.Cleanse.Sleep:Value()) or
            (BuffByType(19,Activator.Cleanse.D3:Value()) and Activator.Cleanse.Nearsight:Value()) or
            ((BuffByType(21,Activator.Cleanse.D3:Value()) or BuffByType(28,Activator.Cleanse.D3:Value())) and Activator.Cleanse.Fear:Value()) or
            (BuffByType(22,Activator.Cleanse.D3:Value()) and Activator.Cleanse.Charm:Value()) then
            Control.CastSpell(HKITEM[MikaelsCrucible], MikaelsCrucibleAlly)
        end
    end

    local ExistCleanse = ExistSpell("SummonerBoost")
    local CleanseSlot = SummonerSlot("SummonerBoost")
    local CleanseTarget = ClosestHero(1500,foe)
    if ExistCleanse and Ready(CleanseSlot) and CleanseTarget and Activator.Cleanse.Cleanse:Value() then
        if (BuffByType(5,Activator.Cleanse.DS1:Value()) and Activator.Cleanse.Stun:Value()) or
            (BuffByType(7,Activator.Cleanse.DS1:Value()) and Activator.Cleanse.Silence:Value()) or
            (BuffByType(8,Activator.Cleanse.DS1:Value()) and Activator.Cleanse.Taunt:Value()) or
            ((BuffByType(9,Activator.Cleanse.DS1:Value()) or BuffByType(31,Activator.Cleanse.DS1:Value())) and Activator.Cleanse.Disarm:Value()) or
            (BuffByType(10,Activator.Cleanse.DS1:Value()) and Activator.Cleanse.Slow:Value()) or
            (BuffByType(11,Activator.Cleanse.DS1:Value()) and Activator.Cleanse.Root:Value()) or
            (BuffByType(18,Activator.Cleanse.DS1:Value()) and Activator.Cleanse.Sleep:Value()) or
            (BuffByType(19,Activator.Cleanse.DS1:Value()) and Activator.Cleanse.Nearsight:Value()) or
            ((BuffByType(21,Activator.Cleanse.DS1:Value()) or BuffByType(28,Activator.Cleanse.DS1:Value())) and Activator.Cleanse.Fear:Value()) or
            (BuffByType(22,Activator.Cleanse.DS1:Value()) and Activator.Cleanse.Charm:Value()) or
            (BuffByType(25,Activator.Cleanse.DS1:Value()) and Activator.Cleanse.Blind:Value()) then
            Control.CastSpell(HKSPELL[CleanseSlot])
        end      
    end
end
