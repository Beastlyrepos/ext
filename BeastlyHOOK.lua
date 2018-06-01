class "Blitzcrank"


if FileExist(COMMON_PATH .. "HPred.lua") then
	require 'HPred'
else
	PrintChat("HPred.lua missing!")
end
if FileExist(COMMON_PATH .. "TPred.lua") then
	require 'TPred'
else
	PrintChat("TPred.lua missing!")
end

function GetTarget(range)
	if _G.SDK then
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_MAGICAL);
	elseif _G.gsoSDK then
		return _G.gsoSDK.TS:GetTarget()
	else
		return _G.GOS:GetTarget(range,"AP")
	end
end

function IsRecalling()
	for K, Buff in pairs(GetBuffs(myHero)) do
		if Buff.name == "recall" and Buff.duration > 0 then
			return true
		end
	end
	return false
end

function IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Ready(spellSlot)
	return IsReady(spellSlot)
end

function GetEnemyHeroes()
	EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(EnemyHeroes, Hero)
		end
	end
	return EnemyHeroes
end

function EnemyInRange(range)
	local count = 0
	for i, target in ipairs(GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end


function Blitzcrank:LoadSpells()

	Q = {Range = 925, Width = 70, Delay = 0.25, Speed = 1800, Collision = true, aoe = false}
    E = {Range = myHero.range+50}
    R = {Range = 600, Width = 0, Delay = 0.01, Speed = 347, Collision = false, aoe = false, Type = "linear"}
end


function Blitzcrank:LoadMenu()
	Blitzcrank = MenuElement({type = MENU, id = "Blitzcrank", name = "BeastlyHOOK"})
	Blitzcrank:MenuElement({id = "Combo", name = "Combo", type = MENU})
	Blitzcrank.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	Blitzcrank.Combo:MenuElement({id = "MinQ", name = "Min Distance to Q", value = 900,min = 200,max = 925})	
    Blitzcrank.Combo:MenuElement({id = "UseE", name = "E", value = true})
    Blitzcrank.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})

    Blitzcrank:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	
	Blitzcrank.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    Blitzcrank.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    Blitzcrank.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    Blitzcrank.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	Blitzcrank.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    Blitzcrank.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})
    Blitzcrank.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    Blitzcrank.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
end

function Blitzcrank:__init()
	
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Blitzcrank:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() then return end
    if Blitzcrank.Combo.comboActive:Value() then
		self:Combo()
		self:ComboE()
end
end

function Blitzcrank:Draw()
    if Ready(_Q) and Blitzcrank.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Blitzcrank.Combo.MinQ:Value(), Blitzcrank.Drawings.Q.Width:Value(), Blitzcrank.Drawings.Q.Color:Value()) end
    if Ready(_R) and Blitzcrank.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, 600, Blitzcrank.Drawings.R.Width:Value(), Blitzcrank.Drawings.R.Color:Value()) end
        
        if Ready(_Q) then
                if Ready(_Q) then
                local target = GetTarget(Blitzcrank.Combo.MinQ:Value())
                if target == nil then return end
                if (TPred) then
                    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Blitzcrank.Combo.MinQ:Value(), Q.Speed, myHero.pos, Q.Type )
                    Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
                end
            end
       end
end

function Blitzcrank:Combo()
    local target = GetTarget(Q.Range)
    if target == nil then return end
        if Blitzcrank.Combo.UseQ:Value() and target and Ready(_Q) then
                local level = myHero:GetSpellData(_Q).level	
                local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Blitzcrank.Combo.MinQ:Value(), Q.Speed, myHero.pos, Q.Type )
                if (HitChance > 0 ) and target.distance <= Blitzcrank.Combo.MinQ:Value() and myHero.pos:DistanceTo(target.pos) > 200 then
                Control.CastSpell(HK_Q,castpos)
            end
       end
end

 function Blitzcrank:ComboE()
        local target = GetTarget()
        if target == nil then return end
        if Blitzcrank.Combo.UseE:Value() and target and Ready(_E) then
        if EnemyInRange(E.Range) then 
        Control.CastSpell(HK_E)
        end
     end
 end

function OnLoad()
	Blitzcrank()
end
