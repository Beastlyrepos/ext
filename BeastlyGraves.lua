if myHero.charName ~= "Graves" then return end

require "DamageLib"
require "MapPositionGOS"

local GravesIcon = "https://raw.githubusercontent.com/Beastlyrepos/ext/master/Icons/GravesOriginal.png"
local QIcon = "https://raw.githubusercontent.com/Beastlyrepos/ext/master/Icons/EndoftheLine.png"
local WIcon = "https://raw.githubusercontent.com/Beastlyrepos/ext/master/Icons/SmokeScreen.png"
local EIcon = "https://raw.githubusercontent.com/Beastlyrepos/ext/master/Icons/Quickdraw.png"
local RIcon = "https://raw.githubusercontent.com/Beastlyrepos/ext/master/Icons/CollateralDamage.png"

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0
end

local function PercentHP(target)
    return 100 * target.health / target.maxHealth
end

local function PercentMP(target)
    return 100 * target.mana / target.maxMana
end

local function IsImmune(unit)
    for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
        if (buff.name == "KindredRNoDeathBuff" or buff.name == "UndyingRage") and PercentHP(unit) <= 10 then
            return true
        end
        if buff.name == "VladimirSanguinePool" or buff.name == "JudicatorIntervention" then 
            return true
        end
    end
    return false
end

local sqrt = math.sqrt

local function GetDistanceSqr(p1, p2)
    local dx = p1.x - p2.x
    local dz = p1.z - p2.z
    return (dx * dx + dz * dz)
end

local function GetDistance(p1, p2)
    return p1:DistanceTo(p2)
end

local function GetDistance2D(p1,p2)
    return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
end

local function IsImmobileTarget(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
			return true
		end
	end
	return false	
end

local function IsValidTarget(target, range)
	range = range and range or math.huge
	return target ~= nil and target.valid and target.visible and not target.dead and target.distance <= range and IsImmune(target) == false
end

local Q = {range = 925, speed = 2000, delay = 0.25, width = myHero:GetSpellData(_Q).width}
local W = {range = 950, speed = 1450, delay = 0.25, width = myHero:GetSpellData(_W).width}
local E = {range = 425}
local R = {range = 1000, speed = myHero:GetSpellData(_R).speed, delay = 0.25, width = myHero:GetSpellData(_R).width}

local HKITEM = {
	[ITEM_1] = HK_ITEM_1,
	[ITEM_2] = HK_ITEM_2,
	[ITEM_3] = HK_ITEM_3,
	[ITEM_4] = HK_ITEM_4,
	[ITEM_5] = HK_ITEM_5,
	[ITEM_6] = HK_ITEM_6,
	[ITEM_7] = HK_ITEM_7,
}

local function Qdmg(target)
    return 0
end

local function Wdmg(target)
    return 0
end

local function Edmg(target)
    return 0
end

local function Rdmg(target)
    if Ready(_R) then
        return CalcPhysicalDamage(myHero,target,(100 + 150 * myHero:GetSpellData(_R).level + 1.5 * myHero.bonusDamage))
    end
    return 0
end

local function HeroesAround(pos, range, team)
	local Count = 0
	for i = 1, Game.HeroCount() do
		local minion = Game.Hero(i)
		if minion and minion.team == team and not minion.dead and pos:DistanceTo(minion.pos) <= range then
			Count = Count + 1
		end
	end
	return Count
end

local function MinionsAround(pos, range, team)
	local Count = 0
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion and minion.team == team and not minion.dead and pos:DistanceTo(minion.pos) <= range then
			Count = Count + 1
		end
	end
	return Count
end

local function GetTarget(range)
	if _G.SDK then
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL);
	elseif _G.gsoSDK then
		return _G.gsoSDK.TS:GetTarget()
	else
		return _G.GOS:GetTarget(range,"AD")
	end
end

local function GotBuff()
	for i = 0, myHero.buffCount do 
	local buff = myHero:GetBuff(i)
		if buff.type == 13 and Game.Timer() < buff.expireTime then 
			return false
		end
	end
	return true
end

local function GetMode()
      if _G.SDK then
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			return "Combo"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
			return "Harass"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] then
			return "Clear"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
			return "Flee"
		end
	elseif _G.gsoSDK then
		return _G.gsoSDK.Orbwalker:GetMode()
	else
		return GOS.GetMode()
	end
end

local function EnableOrb(bool)
	if Orb == 1 then
		EOW:SetMovements(bool)
		EOW:SetAttacks(bool)
	elseif Orb == 2 then
		_G.SDK.Orbwalker:SetMovement(bool)
		_G.SDK.Orbwalker:SetAttack(bool)
	else
		GOS.BlockMovement = not bool
		GOS.BlockAttack = not bool
	end
end

local abs = math.abs 
local deg = math.deg 
local acos = math.acos
function IsFacing(target)
    local V = Vector((target.pos - myHero.pos))
    local D = Vector(target.dir)
    local Angle = 180 - deg(acos(V*D/(V:Len()*D:Len())))
    if abs(Angle) < 80 then 
        return true  
    end
    return false
end
       

local Graves = MenuElement({type = MENU, id = "Graves", name = "BeastlyGraves", leftIcon = GravesIcon})

      Graves:MenuElement({id = "Combo", name = "Combo", type = MENU})
	  Graves.Combo:MenuElement({id = "Q", name = "Q -> End of the Line", value = true, leftIcon = QIcon})
      Graves.Combo:MenuElement({id = "W", name = "W -> Smoke Screen", value = true, leftIcon = WIcon})
      Graves.Combo:MenuElement({id = "E", name = "E -> Quickdraw", value = true, leftIcon = EIcon})

      Graves:MenuElement({id = "Harass", name = "Harass", type = MENU})
      Graves.Harass:MenuElement({id = "Q", name = "Q -> End of the Line", value = true, leftIcon = QIcon})
	  Graves.Harass:MenuElement({id = "W", name = "W -> Smoke Screen", value = true, leftIcon = WIcon})
      Graves.Harass:MenuElement({id = "E", name = "E -> Quickdraw", value = false, leftIcon = EIcon})

      Graves:MenuElement({id = "Clear", name = "Clear", type = MENU})
      Graves.Clear:MenuElement({id = "Q", name = "Q -> End of the Line", value = true, leftIcon = QIcon})
      Graves.Clear:MenuElement({id = "W", name = "W -> Smoke Screen", value = true, leftIcon = WIcon})
      Graves.Clear:MenuElement({id = "X", name = "Minions", value = 5, min = 1, max = 7})
      Graves.Clear:MenuElement({id = "E", name = "E -> Quickdraw", value = true, leftIcon = EIcon})
	  Graves.Clear:MenuElement({id = "MP", name = "Min mana", value = 35, min = 0, max = 100})
      Graves.Clear:MenuElement({id = "Key", name = "Enable/Disable", key = string.byte("A"), toggle = true})

      Graves:MenuElement({id = "Flee", name = "Flee", type = MENU})
      Graves.Flee:MenuElement({id = "W", name = "W -> Smoke Screen", value = true, leftIcon = WIcon})
      Graves.Flee:MenuElement({id = "E", name = "E -> Quickdraw", value = true, leftIcon = EIcon})

      Graves:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})  
      Graves.Killsteal:MenuElement({id = "R", name = "R -> Collateral Damage", value = true, leftIcon = RIcon})


    Graves:MenuElement({id = "Draw", name = "Drawings", type = MENU})
    Graves.Draw:MenuElement({id = "Q", name = "Q -> End of the Line", value = true, leftIcon = QIcon})
    Graves.Draw:MenuElement({id = "W", name = "W -> Smoke Screen", value = true, leftIcon = WIcon})
    Graves.Draw:MenuElement({id = "R", name = "R -> Collateral Damage", value = true, leftIcon = RIcon})
    Graves.Draw:MenuElement({id = "C", name = "Enable Text", value = true})

Callback.Add("Tick", function() Tick() end)
Callback.Add("Draw", function() Drawings() end)


function Tick()
	local Mode = GetMode()
	if Mode == "Combo" then
		Combo()
	elseif Mode == "Harass" then
		Harass()
	elseif Mode == "Clear" then
		Lane()
	elseif Mode == "Flee" then
		Flee()
    end
	Killsteal()
end

local _EnemyHeroes
local function GetEnemyHeroes()
	if _EnemyHeroes then return _EnemyHeroes end
	_EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.isEnemy then
			table.insert(_EnemyHeroes, unit)
		end
	end
	return _EnemyHeroes
end

local _OnVision = {}
function OnVision(unit)
	if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {state = unit.visible , tick = GetTickCount(), pos = unit.pos} end
	if _OnVision[unit.networkID].state == true and not unit.visible then _OnVision[unit.networkID].state = false _OnVision[unit.networkID].tick = GetTickCount() end
	if _OnVision[unit.networkID].state == false and unit.visible then _OnVision[unit.networkID].state = true _OnVision[unit.networkID].tick = GetTickCount() end
	return _OnVision[unit.networkID]
end
Callback.Add("Tick", function() OnVisionF() end)
local visionTick = GetTickCount()
function OnVisionF()
	if GetTickCount() - visionTick > 100 then
		for i,v in pairs(GetEnemyHeroes()) do
			OnVision(v)
		end
	end
end

local _OnWaypoint = {}
function OnWaypoint(unit)
	if _OnWaypoint[unit.networkID] == nil then _OnWaypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = Game.Timer()} end
	if _OnWaypoint[unit.networkID].pos ~= unit.posTo then 
		-- print("OnWayPoint:"..unit.charName.." | "..math.floor(Game.Timer()))
		_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
			DelayAction(function()
				local time = (Game.Timer() - _OnWaypoint[unit.networkID].time)
				local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
				if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and GetDistance(unit.pos,_OnWaypoint[unit.networkID].pos) > 200 then
					_OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
					-- print("OnDash: "..unit.charName)
				end
			end,0.05)
	end
	return _OnWaypoint[unit.networkID]
end

local function GetPred(unit,speed,delay,sourcePos)
	local speed = speed or math.huge
	local delay = delay or 0.25
	local sourcePos = sourcePos or myHero.pos
	local unitSpeed = unit.ms
	if OnWaypoint(unit).speed > unitSpeed then unitSpeed = OnWaypoint(unit).speed end
	if OnVision(unit).state == false then
		local unitPos = unit.pos + Vector(unit.pos,unit.posTo):Normalized() * ((GetTickCount() - OnVision(unit).tick)/1000 * unitSpeed)
		local predPos = unitPos + Vector(unit.pos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(sourcePos,unitPos)/speed)))
		if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
		return predPos
	else
		if unitSpeed > unit.ms then
			local predPos = unit.pos + Vector(OnWaypoint(unit).startPos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(sourcePos,unit.pos)/speed)))
			if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
			return predPos
		elseif IsImmobileTarget(unit) then
			return unit.pos
		else
			return unit:GetPrediction(speed,delay)
		end
	end
end

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local function CastSpell(spell,pos,range,delay)
local range = range or math.huge
local delay = delay or 250
local ticker = GetTickCount()

	if castSpell.state == 0 and GetDistance(myHero.pos,pos) < range and ticker - castSpell.casting > delay + Game.Latency() and pos:ToScreen().onScreen then
		castSpell.state = 1
		castSpell.mouse = mousePos
		castSpell.tick = ticker
	end
	if castSpell.state == 1 then
		if ticker - castSpell.tick < Game.Latency() then
			Control.SetCursorPos(pos)
			Control.KeyDown(spell)
			Control.KeyUp(spell)
			castSpell.casting = ticker + delay
			DelayAction(function()
				if castSpell.state == 1 then
					Control.SetCursorPos(castSpell.mouse)
					castSpell.state = 0
				end
			end,Game.Latency()/1000)
		end
		if ticker - castSpell.casting > Game.Latency() then
			Control.SetCursorPos(castSpell.mouse)
			castSpell.state = 0
		end
	end
end

function CastQ(target)
	if target.ms ~= 0 and (Q.range - GetDistance(target.pos,myHero.pos))/target.ms <= GetDistance(myHero.pos,target.pos)/(Q.speed + Q.delay) and not IsFacing(target) then return end
    if Ready(_Q) and castSpell.state == 0 then
        if (Game.Timer() - OnWaypoint(target).time < 0.15 or Game.Timer() - OnWaypoint(target).time > 1.0) then
            local qPred = GetPred(target,Q.speed,Q.delay + Game.Latency()/1000)
		if not MapPosition:intersectsWall(LineSegment(myHero,qPred)) then
            CastSpell(HK_Q,qPred,Q.range + 200,250)
				end
        end
	end
end

function CastW(target)
	if target.ms ~= 0 and (W.range - GetDistance(target.pos,myHero.pos))/target.ms <= GetDistance(myHero.pos,target.pos)/(W.speed + W.delay) and not IsFacing(target) then return end
	if Ready(_W) and castSpell.state == 0 then
        if (Game.Timer() - OnWaypoint(target).time < 0.15 or Game.Timer() - OnWaypoint(target).time > 1.0) then
            local wPred = GetPred(target,W.speed,W.delay + Game.Latency()/1000)
            CastSpell(HK_W,wPred,W.range + 200,250)
        end
	end
end

function CastR(target)
	if target.ms ~= 0 and (R.range - GetDistance(target.pos,myHero.pos))/target.ms <= GetDistance(myHero.pos,target.pos)/(R.speed + R.delay) and not IsFacing(target) then return end
	if Ready(_R) and castSpell.state == 0 then
        if (Game.Timer() - OnWaypoint(target).time < 0.15 or Game.Timer() - OnWaypoint(target).time > 1.0) then
            local rPred = GetPred(target,R.speed,R.delay + Game.Latency()/1000)
            CastSpell(HK_R,rPred,R.range + 200,250)
        end
	end
end

function Combo()
    local target = GetTarget(Q.range)
    if target == nil then return end

    if IsValidTarget(target,myHero.range + E.range) and Graves.Combo.E:Value() and Ready(_E) and myHero.attackData.state ~= STATE_ATTACK then
		local vec = Vector(myHero.pos):Extended(Vector(mousePos), E.range)
        if GetDistance(vec,target.pos) < myHero.range then
            if myHero.range > target.range then
                if GetDistance(vec,target.pos) > target.range then
                    Control.CastSpell(HK_E,vec)
                end
            else
                Control.CastSpell(HK_E,vec)
            end
        end
    end
	if IsValidTarget(target,Q.range) and Graves.Combo.Q:Value() and Ready(_Q) then
		CastQ(target)
    end
    if IsValidTarget(target,W.range) and Graves.Combo.W:Value() and Ready(_W) then
		CastW(target)
    end
end

function Harass()
	local target = GetTarget(Q.range)
	if target == nil then return end
    
	if IsValidTarget(target,myHero.range + E.range) and Graves.Harass.E:Value() and Ready(_E) and myHero.attackData.state ~= STATE_ATTACK then
		local vec = Vector(myHero.pos):Extended(Vector(mousePos), E.range)
        if GetDistance(vec,target.pos) < myHero.range then
            if myHero.range > target.range then
                if GetDistance(vec,target.pos) > target.range then
                    Control.CastSpell(HK_E,vec)
                end
            else
                Control.CastSpell(HK_E,vec)
            end
        end
    end
	if IsValidTarget(target,Q.range) and Graves.Harass.Q:Value() and Ready(_Q) then
		CastQ(target)
    end
    if IsValidTarget(target,W.range) and Graves.Harass.W:Value() and Ready(_W) then
		CastW(target)
    end
end

function Lane()
	if Graves.Clear.Key:Value() == false then return end
	if PercentMP(myHero) < Graves.Clear.MP:Value() then return end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
        if minion then
			if minion.team == 300 - myHero.team then
                if IsValidTarget(minion,Q.range) and minion:GetCollision(Q.width, Q.speed, Q.delay) - 1 >= Graves.Clear.X:Value() and Graves.Clear.Q:Value() and Ready(_Q) then
                    Control.CastSpell(HK_Q, minion.pos)
				end
				if IsValidTarget(minion,W.range) and Graves.Clear.W:Value() and Ready(_W) and MinionsAround(minion.pos, 250, 300 - myHero.team) >= Graves.Clear.X:Value() then
                    Control.CastSpell(HK_W, minion.pos)
                end
			end
			if minion.team == 300 then
				if IsValidTarget(minion,E.range) and Graves.Clear.E:Value() and Ready(_E) and myHero.attackData.state == STATE_WINDDOWN then
                    Control.CastSpell(HK_E, minion)
                end
                if IsValidTarget(minion,Q.range) and Graves.Clear.Q:Value() and Ready(_Q) then
                    Control.CastSpell(HK_Q, minion)
				end
				if IsValidTarget(minion,W.range) and Graves.Clear.W:Value() and Ready(_W) then
                    Control.CastSpell(HK_W, minion)
                end
			end
		end
	end
end

function Flee()
	local target = GetTarget(W.range)
    
    if Graves.Flee.E:Value() and Ready(_E) then
        Control.CastSpell(HK_E, Game.cursorPos())
    end
    if target and IsValidTarget(target,W.range) and Graves.Flee.W:Value() and Ready(_W) then
		CastW(target)
    end
end

function Killsteal()
	local target = GetTarget(R.range)
    if target == nil then return end
    
    if IsValidTarget(target,R.range) and Graves.Killsteal.R:Value() and Ready(_R) and Rdmg(target) > target.health then
		CastR(target)
    end
end

function Drawings()
    if myHero.dead then return end
    if Graves.Draw.Q:Value() and Ready(_Q) then Draw.Circle(myHero.pos, Q.range, 0.5,  Draw.Color(255, 255, 62, 150)) end
    if Graves.Draw.W:Value() and Ready(_W) then Draw.Circle(myHero.pos, W.range, 0.5,  Draw.Color(255, 139, 34, 82)) end
    if Graves.Draw.R:Value() and Ready(_R) then Draw.Circle(myHero.pos, R.range, 0.5,  Draw.Color(255, 000, 043, 255)) end
	if Graves.Draw.C:Value() then
		local textPos = myHero.pos:To2D()
		if Graves.Clear.Key:Value() then
			Draw.Text("CLEAR ENABLED", 20, textPos.x - 57, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 
		else
			Draw.Text("CLEAR DISABLED", 20, textPos.x - 57, textPos.y + 40, Draw.Color(255, 225, 000, 000)) 
		end
    end
end
