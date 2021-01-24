local DMW = DMW
local Druid = DMW.Rotations.DRUID
local Rotation = DMW.Helpers.Rotation
local Setting = DMW.Helpers.Rotation.Setting
local Player, Buff, Debuff, Spell, Stance, Target, Talent, Item, GCD, CDs, HUD, EnemyMelee, EnemyMeleeCount, pauseTime, HealthPot, HealthStone, Enemy30Y, Enemy30YC, NextEclipse, StarsurgedEclipse, Form, BloodTalonsGenStack, BloodTalonsGenRake, BloodTalonsGenShred, BloodTalonsGenMoonfire, BloodTalonsGenSwipe, BloodTalonsGenThrash, BloodTalonsGenBrutalSlash, noAoE

-----Overrides, hooks etc--------------------------------------------
hooksecurefunc(DMW.Frames.CombatLog, "Reader", function(...)
    local _, event, timeStamp, param, hideCaster, source, sourceName, sourceFlags, sourceRaidFlags, destination, destName, destFlags, destRaidFlags, spell, spellName, _, spellType =
            ...
    if source == DMW.Player.GUID then
        if DMW.Player.SpecID == "Balance" then
            if spell == DMW.Player.Spells.Starsurge.SpellID then
                if (param == "SPELL_CAST_SUCCESS") then
                    StarsurgedEclipse = true
                end
            elseif spell == DMW.Player.Buffs.EclipseLunar.SpellID or spell == DMW.Player.Buffs.EclipseSonar.SpellID then
                if param == "SPELL_AURA_APPLIED"  then
                    StarsurgedEclipse = false
                end
            end
        end
    end
end)
---------------------------------------------------------------------
local noAoeList = {
	[173688] = true,
	[173687] = true,
	[172943] = true,

}

local function aoeCheck()
	for _, Unit in pairs(DMW.Attackable) do
		-- if Unit.Distance <= 10 and noAoeList[Unit.ObjectID] then
		if Unit.Distance <= 11 and not GrindBot.Grinding:CheckLevel(Unit.Level) and not UnitThreatSituation(DMW.Player.Pointer, Unit.Pointer) then
			-- print(Unit.Name)
			return false
		end
	end
	return true
end

local function Locals()
    Player = DMW.Player
    Buff = Player.Buffs
    Debuff = Player.Debuffs
    Spell = Player.Spells
    Talent = Player.Talents
    Item = Player.Items
    Target = Player.Target or false
    Power = Player.Power
    HUD = DMW.Settings.profile.HUD
    EnemyMelee, EnemyMeleeCount = Player:GetEnemies(5)
    -- CDs = Player:CDs() and Target and Target.TTD > 5 and EnemyMeleeCount >= 1

    -- Enemy8Y, Enemy8YC = Player:GetEnemies(8)
    -- Enemy10Y, Enemy10YC = Player:GetEnemies(10)
    Enemy30Y, Enemy30YC = Player:GetEnemies(40)
    GCD = Player:GCDRemain()
    -- if not Form then
        if Buff.FormBear:Exist() then
            Form = "Bear"
        elseif Buff.FormCat:Exist() then
            Form = "Cat"
        elseif Buff.FormMoonkin:Exist() then
            Form = "Moonkin"
        elseif Buff.FormTravel:Exist() or Buff.FormFly:Exist() then
            Form = "Travel"
        else
            Form = "Human"
        end
    -- end
    -- print(Form)
end

local function BaitHelper()
    if IsHackEnabled('fish') then
        local BaitTimer = GetTime()
        local zoneName = GetZoneText()
        if zoneName == "Revendreth" and not Buff.RevendrethBait:Exist() then
            if ((DMW.Time - BaitTimer) < 0.2) then
                if Item.SpinefinPiranhaBait:IsReady() and Item.SpinefinPiranhaBait:Use() then
                    BaitTimer = 0
                    return true
                end
            end
        end
        if zoneName == "Ardenweald" and not Buff.ArdenwealdBait:Exist() then
            if ((DMW.Time - BaitTimer) < 0.2) then
                if Item.IridescentAmberjackBait:IsReady() and Item.IridescentAmberjackBait:Use() then
                    BaitTimer = 0
                    return true
                end
            end
        end
    end
end

---------------------------------------------------------PROTECTION---------------------------------------------------------PROTECTION---------------------------------------------------------PROTECTION-----------------------------------
local function num(val)
    if val then
        return 1
    else
        return 0
    end
end

local function bool(val) return val ~= 0 end


local function isCurrentlyTanking()
    -- is player currently tanking any enemies within 16 yard radius
    local IsTanking = Player:IsTankingAoE(16) or (DMW.Player.Target and (DMW.Player.Target:IsTanking() or DMW.Player.Target.Dummy))
    return IsTanking
end

local function HealthPotUse()
    if Player.Combat and Setting("Health Potion/HealthStone HP%") > 0 and Setting("Health Potion/HealthStone HP%") > Player.HP then
        if Item.HealthStone:IsReady() then
            Item.HealthStone:Use()
        elseif Item.HealthPot:IsReady() then
            Item.HealthPot:Use()
        end
    end
end


local function LocalsBalance()
    if Buff.EclipseLunar:Exist() and NextEclipse ~= "Solar" then NextEclipse = "Solar"
    elseif Buff.EclipseSonar:Exist() and NextEclipse ~= "Lunar"
     then NextEclipse = "Lunar"
    -- else
--
    end
    -- print(NextEclipse)
end

local function LocalsFeral()
	if Talent.BloodTalons then
		BloodTalonsGenStack = 0
		if DMW.Time - Spell.Rake.LastCastTime <= 4 then BloodTalonsGenRake = true; BloodTalonsGenStack = BloodTalonsGenStack + 1 end
		if DMW.Time - Spell.Shred.LastCastTime <= 4 then BloodTalonsGenShred = true; BloodTalonsGenStack = BloodTalonsGenStack + 1 end
		if DMW.Time - Spell.Moonfire.LastCastTime <= 4 then BloodTalonsGenMoonfire = true; BloodTalonsGenStack = BloodTalonsGenStack + 1 end
		if not Talent.BrutalSlash and DMW.Time - Spell.Swipe.LastCastTime <= 4 then BloodTalonsGenSwipe = true; BloodTalonsGenStack = BloodTalonsGenStack + 1 end
		if DMW.Time - Spell.Thrash.LastCastTime <= 4 then BloodTalonsGenThrash = true; BloodTalonsGenStack = BloodTalonsGenStack + 1 end
		if Talent.BrutalSlash and DMW.Time - Spell.BrutalSlash.LastCastTime <= 4 then BloodTalonsGenBrutalSlash = true; BloodTalonsGenStack = BloodTalonsGenStack + 1 end
	end
	noAoE = aoeCheck()
end

local function LocalsGuardian()
	Enemy9Y, Enemy9YC = Player:GetEnemies(9)
end

local function BalanceSunfire()
    if Spell.Sunfire:IsReady()then
        for _, Unit in ipairs(Enemy30Y) do
            if Debuff.Sunfire:Refresh(Unit) and Unit.TTD >= 5 then
                if Spell.Sunfire:Cast(Unit) then return true end
            end
        end
        -- local LowestSunfired = Debuff.Sunfire:Lowest(Enemy30Y)
        -- if Spell.Sunfire:Cast(LowestSunfired) then return true end
    end
end

local function BalanceMoonfire()
    if Spell.Moonfire:IsReady()then
        for _, Unit in ipairs(Enemy30Y) do
            if Debuff.Moonfire:Refresh(Unit) and Unit.TTD >= 5 then
                if Spell.Moonfire:Cast(Unit) then return true end
            end
        end
        -- local LowestMoonfired = Debuff.Moonfire:Lowest(Enemy30Y)
        -- if Spell.Moonfire:Cast(LowestMoonfired) then return true end
    end
end

local function BalanceEclipseStuff()
    if Buff.EclipseSonar:Exist() and Spell.Wrath:IsReady() then
        for _, Unit in ipairs(Enemy30Y) do
            if Spell.Wrath:Cast(Unit) then return true end
        end
    elseif Buff.EclipseLunar:Exist() and Spell.Starfire:IsReady() then
        for _, Unit in ipairs(Enemy30Y) do
            if Spell.Starfire:Cast(Unit) then return true end
        end
    else
        if Spell.Wrath:IsReady() and NextEclipse == "Lunar" then
            for _, Unit in ipairs(Enemy30Y) do
                if Spell.Wrath:Cast(Unit) then return true end
            end
        elseif Spell.Starfire:IsReady() and (NextEclipse == "Solar" or not NextEclipse) then
            for _, Unit in ipairs(Enemy30Y) do
                if Spell.Starfire:Cast(Unit) then return true end
            end
        end
    end
end

local function LocalsRestoration()

end

local function IsSwiftmendUsable(Unit)
    if Unit then
        if Buff.WildGrowth:Exist(Unit) or Buff.Regrowth:Exist(Unit) or Buff.Rejuvenation:Exist(Unit) then return true end
    end
    return false
end

local function RestorationMoonkinCheck()
    if Form == "Human" or Setting("Critical HP") <= DMW.Friends.LowestHP then
        return true
    end
end

local function RestorationLifeBloom()
    if Setting("LifeBloom Tanks") and #DMW.Friends.Tanks > 0 and RestorationMoonkinCheck() then
        if Buff.Lifebloom:Refresh(DMW.Friends.Tanks[1]) then
            if Spell.Lifebloom:Cast(DMW.Friends.Tanks[1]) then return true end
        end
    end
end

local function DruidRebirth()

end

local function RestorationTank(form)
    if not Player.Moving and #DMW.Friends.Tanks > 0 then
        if Spell.Regrowth:IsReady() then
            if Setting("Regrowth HP no Buff") > 0 then
                for _, Unit in ipairs(DMW.Friends.Tanks) do
                    if Unit.HP <= Setting("Regrowth HP no Buff") and Buff.Regrowth:Refresh(Unit) then
                        if Spell.Regrowth:Cast(Unit) then return true end
                    end
                end
            end
            if Setting("Regrowth HP ") > 0 then
                for _, Unit in ipairs(DMW.Friends.Tanks) do
                    if Unit.HP <= Setting("Regrowth HP ") then
                        if Spell.Regrowth:Cast(Unit) then return true end
                    end
                end
            end
        end
        if not form then
            if Spell.Rejuvenation:IsReady() and Setting("Rejuvenation HP ") > 0 and RestorationMoonkinCheck()then
                for _, Unit in ipairs(DMW.Friends.Tanks) do
                    if Unit.HP <= Setting("Rejuvenation HP ") and not Buff.Rejuvenation:Exist(Unit) then
                        if Spell.Rejuvenation:Cast(Unit) then return true end
                    end
                end
                for _, Unit in ipairs(DMW.Friends.Tanks) do
                    if Unit.HP <= Setting("Rejuvenation HP ") and Buff.Rejuvenation:Refresh(Unit) then
                        if Spell.Rejuvenation:Cast(Unit) then return true end
                    end
                end
            end
        end
    end
end

local function RestorationHeal(form)
    if not form and Spell.Rejuvenation:IsReady() and Setting("Rejuvenation HP") > 0 and RestorationMoonkinCheck() then
        for _, Unit in ipairs(DMW.Friends.Units) do
            if Unit.HP <= Setting("Rejuvenation HP") and Buff.Rejuvenation:Refresh(Unit) then
                if Spell.Rejuvenation:Cast(Unit) then return true end
            end
        end
    end
    -- for _, Unit in ipairs(DMW.Friends.Units) do
    --     if Unit.HP <= Setting("Regrowth HP no Buff") and Buff.Regrowth:Refresh(Unit) then
    --         if Spell.Regrowth:Cast(Unit) then return true end
    --     end
    -- end
    if  not Player.Moving and Spell.Regrowth:IsReady() and Setting("Regrowth HP") > 0 then
        for _, Unit in ipairs(DMW.Friends.Units) do
            if Unit.HP <= Setting("Regrowth HP") then
                if Spell.Regrowth:Cast(Unit) then return true end
            end
        end
    end
end

local function RestorationCooldowns(form)
    if Spell.Ironbark:IsReady() then
        if Setting("IronBark HP ") > 0 then
            for _, Unit in ipairs(DMW.Friends.Tanks) do
                if Unit.HP <= Setting("IronBark HP ") then
                    Spell.Ironbark:Cast(Unit)
                    break
                end
            end
        end
        if Setting("IronBark HP") > 0 then
            for _, Unit in ipairs(DMW.Friends.Units) do
                if Unit.HP <= Setting("IronBark HP") then
                Spell.Ironbark:Cast(Unit)
                break
                end
            end
        end
    end
    if Spell.Swiftmend:IsReady() and not form then
        if Setting("Swiftmend HP ") > 0 then
            for _, Unit in ipairs(DMW.Friends.Tanks) do
                if Unit.HP <= Setting("Swiftmend HP ") and IsSwiftmendUsable(Unit) then
                    if Spell.Swiftmend:Cast(Unit) then return true end
                end
            end
        end
        if Setting("Swiftmend HP") > 0 then
            for _, Unit in ipairs(DMW.Friends.Units) do
                if Unit.HP <= Setting("Swiftmend HP") and IsSwiftmendUsable(Unit) then
                if Spell.Swiftmend:Cast(Unit) then return true end
                end
            end
        end
    end
end

function LowFriendsCount(hpLimit)
    local count = 0
    local lowestUnit, lowestHP
    for _, Unit in ipairs(DMW.Friends.Units) do
        if not Unit.Dead and Unit.HP < hpLimit then
            if not lowestUnit or Unit.HP < lowestHP then
                lowestHP = Unit.HP
                lowestUnit = Unit
            end
            count = count + 1
        end
    end
    return count, lowestUnit
end

local function RestorationWildGrowth()
    if not Player.Moving and Spell.WildGrowth:IsReady() and Setting("WildGrowth HP") > 0 and Setting("WildGrowth Count") > 0 and RestorationMoonkinCheck() then
        local Count, Unit = LowFriendsCount(Setting("WildGrowth HP"))
        if Count >= Setting("WildGrowth Count") then
            if Unit and  Spell.WildGrowth:Cast(Unit) then return true end
        end
    end
end

local function RestorationDPS()
    if Setting("Sunfire") then
        if BalanceSunfire() then return true end
    end
    if Setting("Moonfire") then
        if BalanceMoonfire() then return true end
    end
    if Setting("Wrath") then
        if not Player.Moving then
            local WrathCount = GetSpellCount(5176)
            local StarfireCount = GetSpellCount(197628)
            if Spell.Starsurge:IsReady() and WrathCount == 0 and StarfireCount == 0 then
                for _, Unit in ipairs(Enemy30Y) do
                    if Spell.Starsurge:Cast(Unit) then return true end
                end
            end
            if Spell.Wrath:IsReady() and (WrathCount > 0 or Buff.EclipseSonar:Exist()) then
                for _, Unit in ipairs(Enemy30Y) do
                    if Spell.Wrath:Cast(Unit) then return true end
                end
            end
            if Spell.Starfire:IsReady() and (StarfireCount > 0 or Buff.EclipseLunar:Exist()) then
                for _, Unit in ipairs(Enemy30Y) do
                    if Spell.Starfire:Cast(Unit) then return true end
                end
            end
        end
    end
    if Setting("Moonfire") then
        local LowestMoonfired = Debuff.Moonfire:Lowest(Enemy30Y)
        if LowestMoonfired and Spell.Moonfire:Cast(LowestMoonfired) then return true end
    end
    if Setting("Sunfire") then
        local LowestSunfired = Debuff.Sunfire:Lowest(Enemy30Y)
        if LowestSunfired and Spell.Sunfire:Cast(LowestSunfired) then return true end
    end
end

local function Cleanse()
    if Player.SpecID == "Restoration" then
        if Spell.NaturesCure:IsReady() then
            for _, Unit in ipairs(DMW.Friends.Units) do
                if Unit:Dispel(Spell.NaturesCure) then
                    if Spell.NaturesCure:Cast(Unit) then return true end
                end
            end
        end
    else
        if Spell.RemoveCorruption:IsReady() then
            for _, Unit in ipairs(DMW.Friends.Units) do
                if Unit:Dispel(Spell.RemoveCorruption) then
                    if Spell.RemoveCorruption:Cast(Unit) then return true end
                end
            end
        end
    end
end

local function RestorationFeralDPS()
    if not Player.Combat then
        if not Buff.Stealth:Exist() then
            if Spell.Stealth:IsReady() then
                if Spell.Stealth:Cast(Player) then return true end
            end
        end
    end
    if Player.ComboPointsDeficit == 0 then
        if Spell.Rip:IsReady() then
            for _, Unit in ipairs(EnemyMelee) do
                if Unit.TTD >= 15 and Debuff.Rip:Refresh(Unit) then
                    if Spell.Rip:Cast(Unit) then return true end
                end
            end
        end
        if Spell.FerociousBite:IsReady() and Player.Power >= 50 then
            for _, Unit in ipairs(EnemyMelee) do
                -- if Unit.TTD >= 15 and Debuff.Rip:Refresh(Unit) then
                if Spell.FerociousBite:Cast(Unit) then return true end
                -- end
            end
        end
    end
    if Spell.Rake:IsReady() then
        for _, Unit in ipairs(EnemyMelee) do
            if (Unit.TTD >= 15 and Debuff.Rake:Refresh(Unit)) or Buff.Stealth:Exist() then
                if Spell.Rake:Cast(Unit) then return true end
            end
        end
    end
    if EnemyMeleeCount >= 3 then
        if Spell.Swipe:IsReady() and Spell.Swipe:Cast() then return true end
    else
        if Spell.Shred:IsReady() then
            for _, Unit in ipairs(EnemyMelee) do
                if Spell.Shred:Cast(Unit) then return true end
            end
        end
    end
end

local function FeralStealthOpener()
	if Buff.Prowl:Exist() then
		if Spell.Rake:IsReady() then
			for _, Unit in ipairs(EnemyMelee) do
				if Debuff.Rake:Refresh(Unit) then
					if Spell.Rake:Cast(Unit) then return true end
				end
			end
		else
			return true
		end
	end
end

local function FeralFBExecute(Unit)
	local GetSpellDescription = _G["GetSpellDescription"]
	local desc = GetSpellDescription(Spell.FerociousBite.SpellName)
	local damage = 0
	local finishHim = false
	if Player.ComboPoints > 0 then
		local comboStart = desc:find(" "..Player.ComboPoints.." ",1,true)
		if comboStart ~= nil then
			comboStart = comboStart + 2
			local damageList = desc:sub(comboStart,desc:len())
			comboStart = damageList:find(": ",1,true)+2
			damageList = damageList:sub(comboStart,desc:len())
			local comboEnd = damageList:find(" ",1,true)-1
			damageList = damageList:sub(1,comboEnd)
			damage = damageList:gsub(",","")
		end
		finishHim = tonumber(damage) >= Unit.Health
	end
	return finishHim
end

local function TicksRemaining(Unit, Spell)

end

local function FeralBloodTalonsGenerators()
-- actions.bloodtalons=rake,target_if=(!ticking|(refreshable&persistent_multiplier>dot.rake.pmultiplier)|(active_bt_triggers=2&persistent_multiplier>dot.rake.pmultiplier)|(active_bt_triggers=2&refreshable))&buff.bt_rake.down&druid.rake.ticks_gained_on_refresh>=2
	if Spell.Rake:IsReady() and not BloodTalonsGenRake then
		for _, Unit in ipairs(EnemyMelee) do
			if Debuff.Rake:Refresh(Unit) then
				if Spell.Rake:Cast(Unit) then return true end
			end
		end
	end
-- actions.bloodtalons+=/lunar_inspiration,target_if=refreshable&buff.bt_moonfire.down
-- # investigate this line, maybe add ttd logic
-- actions.bloodtalons+=/thrash_cat,target_if=refreshable&buff.bt_thrash.down&druid.thrash_cat.ticks_gained_on_refresh>variable.thrash_ticks
	if Spell.Thrash:IsReady() and not BloodTalonsGenThrash and noAoE and #Player:GetAttackable(5) >= 2 then
		for _, Unit in ipairs(EnemyMelee) do
			if Debuff.Thrash:Refresh(Unit) then
				if Spell.Thrash:Cast(Unit) then return true end
			end
		end
	end
	-- actions.bloodtalons+=/brutal_slash,if=buff.bt_brutal_slash.down
	if Talent.BrutalSlash and Spell.BrutalSlash:IsReady() and noAoE and not BloodTalonsGenBrutalSlash then
		for _, Unit in ipairs(EnemyMelee) do
			-- if Debuff.Thrash:Refresh(Unit) then
				if Spell.BrutalSlash:Cast(Player) then return true end
			-- end
		end
	end
	-- actions.bloodtalons+=/swipe_cat,if=buff.bt_swipe.down&spell_targets.swipe_cat>1
	if not Talent.BrutalSlash and Spell.Swipe:IsReady() and not BloodTalonsGenSwipe and EnemyMeleeCount > 1 and noAoE then
		-- for _, Unit in ipairs(EnemyMelee) do
			-- if Debuff.Thrash:Refresh(Unit) then
				if Spell.Swipe:Cast(Player) then return true end
			-- end
		-- end
	end
	-- actions.bloodtalons+=/shred,if=buff.bt_shred.down
	if Spell.Shred:IsReady() and not BloodTalonsGenShred then
		for _, Unit in ipairs(EnemyMelee) do
			if Spell.Shred:Cast(Unit) then return true end
		end
	end
	-- actions.bloodtalons+=/swipe_cat,if=buff.bt_swipe.down
	if not Talent.BrutalSlash and Spell.Swipe:IsReady() and not BloodTalonsGenSwipe and noAoE then
		-- for _, Unit in ipairs(EnemyMelee) do
			-- if Debuff.Thrash:Refresh(Unit) then
				if Spell.Swipe:Cast(Player) then return true end
			-- end
		-- end
	end
	-- actions.bloodtalons+=/thrash_cat,if=buff.bt_thrash.down
	if Spell.Thrash:IsReady() and not BloodTalonsGenThrash and noAoE and #Player:GetAttackable(5) >= 2 then
		for _, Unit in ipairs(EnemyMelee) do
			if Debuff.Thrash:Refresh(Unit) then
				if Spell.Thrash:Cast(Unit) then return true end
			end
		end
	end
end

local function FeralCooldowns()
	if Spell.TigersFury:IsReady() and Target and Target.TTD > 0 and Player.EnergyDeficit >= 50 and GCD <= 0.1 then
		-- if Target then Spell.Moonfire:Cast(Target) end
		if Spell.TigersFury:Cast(Player) then return true end
	end
	if EnemyMeleeCount >= 2 then
		if Spell.Berserk:IsReady() then
			if Spell.Berserk:Cast(Player) then return true end
		end
		if not Buff.Berserk:Exist() and Spell.Convoke:IsReady() then
			for _, Unit in ipairs(EnemyMelee) do
				if Spell.Convoke:Cast(Unit) then return true end
			end
		end
	end
end

local function FeralFinisher()
	-- actions.finisher=savage_roar,if=buff.savage_roar.down|buff.savage_roar.remains<(combo_points*6+1)*0.3
	-- # Make sure to zero the variable so some old value don't end up lingering
	-- actions.finisher+=/variable,name=best_rip,value=0,if=talent.primal_wrath.enabled
	-- actions.finisher+=/cycling_variable,name=best_rip,op=max,value=druid.rip.ticks_gained_on_refresh,if=talent.primal_wrath.enabled
	-- actions.finisher+=/primal_wrath,if=spell_targets.primal_wrath>2
	-- actions.finisher+=/rip,target_if=refreshable&druid.rip.ticks_gained_on_refresh>variable.rip_ticks&((buff.tigers_fury.up|cooldown.tigers_fury.remains>5)&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&dot.rip.pmultiplier<=persistent_multiplier|!talent.sabertooth.enabled)
	-- actions.finisher+=/ferocious_bite,max_energy=1,target_if=max:time_to_die
	if Spell.Rip:IsReady() then
		for _,Unit in ipairs(EnemyMelee) do
			if Debuff.Rip:Refresh(Unit) and Unit.TTD >= 15 and Unit.Health >= 10000 then
				if Spell.Rip:Cast(Unit) then return true end
			end
		end
	end
	if Spell.FerociousBite:IsReady() and Player.Energy >= 50 then
		for _,Unit in ipairs(EnemyMelee) do
			if Spell.FerociousBite:Cast(Unit) then return true end
		end
	end
end

local function FeralFillers()
	if Spell.Rake:IsReady() then
		for _,Unit in ipairs(EnemyMelee) do
			if Debuff.Rake:Refresh(Unit)  then
				if Spell.Rake:Cast(Unit) then return true end
			end
		end
	end
	for _,Unit in ipairs(EnemyMelee) do
		if Spell.Shred:Cast(Unit) then return true end
	end
end

local function FeralRotation()
	--FB Execute
	if Spell.FerociousBite:IsReady() and Player.ComboPoints > 0 then
		for _,Unit in ipairs(EnemyMelee) do
			if FeralFBExecute(Unit) then
				if Spell.FerociousBite:Cast(Unit) then return true end
			end
		end
	end
	if Buff.Prowl:Exist() then

	else
		if FeralCooldowns() then return true end
		if Player.ComboPoints >= 5 then
			if FeralFinisher() then return true end
		else
			if Talent.BloodTalons then
				if not Buff.BloodTalons:Exist() then
					if BloodTalonsGenStack == 0 and (Player.Energy + 3.5*GetPowerRegen() + 40*num(Buff.Clearcasting:Exist())) < 115 then
						-- print("pool", DMW.Time)
						return true
					end
					if FeralBloodTalonsGenerators() then return true end
				end
			end
			-- actions+=/ferocious_bite,target_if=max:target.time_to_die,if=buff.apex_predators_craving.up
			-- actions+=/pool_resource,for_next=1
			-- actions+=/rake,target_if=(refreshable|persistent_multiplier>dot.rake.pmultiplier)&druid.rake.ticks_gained_on_refresh>spell_targets.swipe_cat*2-2
			if Spell.Rake:IsReady() then
				for _,Unit in ipairs(EnemyMelee) do
					if Debuff.Rake:Refresh(Unit)  then
						if Spell.Rake:Cast(Unit) then return true end
					end
				end
			end
			-- actions+=/moonfire_cat,target_if=refreshable&druid.moonfire.ticks_gained_on_refresh>spell_targets.swipe_cat*2-2
			-- actions+=/pool_resource,for_next=1
			-- actions+=/thrash_cat,target_if=refreshable&druid.thrash_cat.ticks_gained_on_refresh>variable.thrash_ticks&!buff.bs_inc.up
			if Spell.Thrash:IsReady() and noAoE and #Player:GetAttackable(5) >= 2 then
				for _,Unit in ipairs(EnemyMelee) do
					if Debuff.Thrash:Refresh(Unit) then
						if Spell.Thrash:Cast(Unit) then return true end
					end
				end
			end
			-- actions+=/pool_resource,for_next=1
			-- actions+=/brutal_slash,if=(raid_event.adds.in>(1+max_charges-charges_fractional)*recharge_time)&(spell_targets.brutal_slash*action.brutal_slash.damage%action.brutal_slash.cost)>(action.shred.damage%action.shred.cost)
			-- actions+=/swipe_cat,if=spell_targets.swipe_cat>1+buff.bs_inc.up*2
			-- actions+=/shred,if=buff.clearcasting.up
			if Buff.Clearcasting:Exist() and Spell.Shred:IsReady() then
				for _,Unit in ipairs(EnemyMelee) do
					if Spell.Shred:Cast(Unit) then return true end
				end
			end
			if Spell.BrutalSlash:IsReady() and noAoE then
				if Spell.BrutalSlash:Cast(Player) then return true end
			end
			-- actions+=/rake,target_if=buff.bs_inc.up&druid.rake.ticks_gained_on_refresh>2
			-- actions+=/call_action_list,name=filler
			if FeralFillers() then return true end
		end
	end
end

local function GuardianRotation()
	-- if FeralCooldowns() then return true end
	-- actions.bear=bear_form,if=!buff.bear_form.up
	-- actions.bear+=/ravenous_frenzy
	-- actions.bear+=/convoke_the_spirits,if=!druid.catweave_bear&!druid.owlweave_bear
	-- actions.bear+=/berserk_bear,if=(buff.ravenous_frenzy.up|!covenant.venthyr)
	-- actions.bear+=/incarnation,if=(buff.ravenous_frenzy.up|!covenant.venthyr)
	-- actions.bear+=/empower_bond,if=(!druid.catweave_bear&!druid.owlweave_bear)|active_enemies>=2
	-- actions.bear+=/barkskin,if=talent.brambles.enabled
	-- actions.bear+=/adaptive_swarm,if=(!dot.adaptive_swarm_damage.ticking&!action.adaptive_swarm_damage.in_flight&(!dot.adaptive_swarm_heal.ticking|dot.adaptive_swarm_heal.remains>3)|dot.adaptive_swarm_damage.stack<3&dot.adaptive_swarm_damage.remains<5&dot.adaptive_swarm_damage.ticking)
	-- actions.bear+=/thrash_bear,target_if=refreshable|dot.thrash_bear.stack<3|(dot.thrash_bear.stack<4&runeforge.luffainfused_embrace.equipped)|active_enemies>=4
	if Spell.Thrash:IsReady() and noAoE then
		for _, Unit in ipairs(Enemy9Y) do
			if Debuff.Thrash:Refresh(Unit) then
				if Spell.Thrash:Cast(Unit) then return true end
			end
		end
	end
	if Spell.Thrash:IsReady() and Enemy9YC > 1 and noAoE then
		for _, Unit in ipairs(Enemy9Y) do
			if Spell.Thrash:Cast(Unit) then return true end
		end
	end
	-- actions.bear+=/moonfire,if=((buff.galactic_guardian.up)&active_enemies<2)|((buff.galactic_guardian.up)&!dot.moonfire.ticking&active_enemies>1&target.time_to_die>12)
	if Spell.Moonfire:IsReady() then
		if Buff.GalacticGuardian:Exist() then
			for _, Unit in ipairs(Enemy30Y) do
				if Unit.TTD > 8 and not Debuff.Moonfire:Exist(Unit) then
					if Spell.Moonfire:Cast(Unit) then return true end
				end
			end
		end
	end
	-- actions.bear+=/moonfire,if=(dot.moonfire.remains<=3&(buff.galactic_guardian.up)&active_enemies>5&target.time_to_die>12)
	if Spell.Moonfire:IsReady() and EnemyMeleeCount > 5 then
		if Buff.GalacticGuardian:Exist() then
			for _, Unit in ipairs(Enemy30Y) do
				if Unit.TTD > 8 and Debuff.Moonfire:Exist(Unit) and Debuff.Moonfire:Remain(Unit) < 3 then
					if Spell.Moonfire:Cast(Unit) then return true end
				end
			end
		end
	end
	-- actions.bear+=/moonfire,if=(refreshable&active_enemies<2&target.time_to_die>12)|(!dot.moonfire.ticking&active_enemies>1&target.time_to_die>12)
	-- if Spell.Moonfire:IsReady() then
	-- 	if EnemyMeleeCount < 2 then
	-- 		for _, Unit in ipairs(Enemy30Y) do
	-- 			if Unit.TTD > 8 and Debuff.Moonfire:Refresh(Unit)  then
	-- 				if Spell.Moonfire:Cast(Unit) then return true end
	-- 			end
	-- 		end
	-- 	elseif EnemyMeleeCount > 1 then
	-- 		for _, Unit in ipairs(Enemy30Y) do
	-- 			if Unit.TTD > 8 and not Debuff.Moonfire:Exist() then
	-- 				if Spell.Moonfire:Cast(Unit) then return true end
	-- 			end
	-- 		end
	-- 	end
	-- end
	-- actions.bear+=/swipe,if=buff.incarnation_guardian_of_ursoc.down&buff.berserk_bear.down&active_enemies>=4

	if Spell.Swipe:IsReady() and noAoE then
		if not Buff.Berserk:Exist(Player) and Enemy9YC >= 4 then
			if Spell.Swipe:Cast(Player) then return true end
		end
	end
	-- actions.bear+=/maul,if=buff.incarnation.up&active_enemies<2
	-- actions.bear+=/maul,if=(buff.savage_combatant.stack>=1)&(buff.tooth_and_claw.up)&buff.incarnation.up&active_enemies=2
	-- actions.bear+=/mangle,if=buff.incarnation.up&active_enemies<=3
	-- actions.bear+=/maul,if=(((buff.tooth_and_claw.stack>=2)|(buff.tooth_and_claw.up&buff.tooth_and_claw.remains<1.5)|(buff.savage_combatant.stack>=3))&active_enemies<3)
	-- actions.bear+=/thrash_bear,if=active_enemies>1
	if Spell.Thrash:IsReady() and Enemy9YC > 1 and noAoE then
		for _, Unit in ipairs(Enemy9Y) do
			if Spell.Thrash:Cast(Unit) then return true end
		end
	end
	-- actions.bear+=/mangle,if=((rage<90)&active_enemies<3)|((rage<85)&active_enemies<3&talent.soul_of_the_forest.enabled)
	if Spell.Mangle:IsReady() and Player.Rage < 90 and EnemyMeleeCount < 3 and GrindBot.Combat.MultipullForceCombat then
		for _, Unit in ipairs(EnemyMelee) do
			if Spell.Mangle:Cast(Unit) then return true end
		end
	end
	-- actions.bear+=/pulverize,target_if=dot.thrash_bear.stack>2
	-- actions.bear+=/thrash_bear
	if Spell.Thrash:IsReady() and noAoE then
		for _, Unit in ipairs(Enemy9Y) do
			if Spell.Thrash:Cast(Unit) then return true end
		end
	end
	-- actions.bear+=/maul,if=active_enemies<3
	if Spell.Maul:IsReady() and EnemyMeleeCount < 3 and GrindBot.Combat.MultipullForceCombat then
		for _, Unit in ipairs(EnemyMelee) do
			if Spell.Maul:Cast(Unit) then return true end
		end
	end
	-- actions.bear+=/swipe_bear
	if Spell.Swipe:IsReady() and noAoE then
		if Spell.Swipe:Cast(Player) then return true end
	end
	-- actions.bear+=/ironfur,if=rage.deficit<40&buff.ironfur.remains<0.5

end



-- local oldFunction2 = UseToy
-- UseToy = function(...) return EWTUnlock('UseToy', oldFunction2, ...) end
function Druid.Rotation()
    Locals()
    -- if Target then
    --     if Target:HasMovementFlag(DMW.Enums.MovementFlags.Root) then
    --         print("root")
    --     end
    -- end
    if Player.Casting then pauseTime = DMW.Time end
    if pauseTime and DMW.Time - pauseTime <= 0.1 then return true end
    -- if Target and Target.ValidEnemy and Target.Distance <= 5 and Target:Facing() then
    --     if not IsCurrentSpell(Spell.Attack.SpellID) then StartAttack() end
    -- end
    -- HealthPotUse()
    -- if Setting("AutoTarget") and Player.Combat and (not Player.Target or Player.Target.Dead) then if Player:AutoTargetMelee(5, true) then return true end end
    if Player.SpecID == "Balance" then
        LocalsBalance()

        --     for _, Unit in ipairs(DMW.Units) do
        --         if not Unit.Player and not UnitIsTapDenied(Unit.Pointer) and IsSpellInRange(Spell.Sunfire.SpellName, Unit.Pointer) == 1 then
        --             CastSpellByName(Spell.Sunfire.SpellName, Unit.Pointer)
        --             return true
        --         end

        --     end
        -- if Spell.Sunfire:IsReady() then
        --     for _, Unit in ipairs(DMW.Units) do
        --         if not UnitIsTapDenied(Unit.Pointer) and IsSpellInRange(Spell.Sunfire.SpellName, Unit.Pointer) == 1 then
        --             CastSpellByName(Spell.Sunfire.SpellName, Unit.Pointer)
        --             return true
        --         end
        --     end
        -- end


        -- for _, Unit in ipairs(DMW.Attackable) do
        --     if not UnitIsTapDenied(Unit.Pointer) and not Unit.Player and Debuff.Sunfire:Refresh(Unit) and IsSpellInRange(Spell.Sunfire.SpellName, Unit.Pointer) == 1 then
        --         -- CastSpellByName(Spell.Sunfire.SpellName, Unit.Pointer)
        --         if Spell.Sunfire:Cast(Unit) then return true end
        --     end
        -- end

        -- if (not toyTime or DMW.Time > toyTime) and Item.LootToyDraenor:IsReady() then
        --     for _, Unit in pairs(DMW.Units) do
        --         if Unit.Dead and Unit.Distance < 35 and UnitCanBeLooted(Unit.Pointer) then
        --             -- Item.LootToyDraenor:Use()
        --             RunMacroText("/cast Собиратель трофеев Финдля")
        --             C_Timer.After(1, function () SpellStopCasting() end)
        --             toyTime = DMW.Time + 3
        --             return true
        --         end
        --     end
        -- end
        -- if Spell.Sunfire:IsReady() then
        --     -- for _, Unit in ipairs(DMW.Attackable) do
        --     --         if Spell.Sunfire:Cast(Unit) then return true end
        --     -- end
        --     -- for _, Unit in ipairs(DMW.Attackable) do
        --     --     if not Unit.Player and Debuff.Sunfire:Refresh(Unit) then
        --     --         if Spell.Sunfire:Cast(Unit) then return true end
        --     --     end
        --     -- end
        -- end
        -- if PlayerHasToy(60854) then
        --     UseItemByName(select(1,GetItemInfo(60854)))
        -- end
        -- if not Player.Moving and Item.LootToy:IsReady() then
        --     Item.LootToy:Use()
        -- end
        if (Target and Target.ValidEnemy) or (DMW.Player.InstanceID ~= nil and Player.Combat) or not Player.InGroup then
            if BalanceMoonfire() or BalanceSunfire() then return true end
            if Spell.Starsurge:IsReady() and (Buff.EclipseSonar:Exist() or Buff.EclipseLunar:Exist()) and not StarsurgedEclipse then
                for _, Unit in ipairs(Enemy30Y) do
                    if Spell.Starsurge:Cast(Unit) then return true end
                end
            end
            if not Player.Moving then
                if BalanceEclipseStuff() then return true end
            end
            local LowestMoonfired = Debuff.Moonfire:Lowest(Enemy30Y)
            if LowestMoonfired and Spell.Moonfire:Cast(LowestMoonfired) then return true end
            local LowestSunfired = Debuff.Sunfire:Lowest(Enemy30Y)
        	if LowestSunfired and Spell.Sunfire:Cast(LowestSunfired) then return true end
		end
	elseif Player.SpecID == "Feral" then
		LocalsFeral()
		-- if Target and Target.CanAttack and Target.Distance <= 7 and Target.HP == 100 and not Target.LoS and not Target.TriedToPull then
		-- 	if not IsCurrentSpell(Spell.Attack.SpellID) then StartAttack() end
		-- 	if Spell.Thrash:IsReady() then
		-- 		print("trying to pull")
		-- 		if Spell.Thrash:Cast(Player) then Target.TriedToPull = true; return true end
		-- 	end
		-- end
		if not Player.Combat and not Buff.Prowl:Exist() then
			if HUD.Cleanse == 1  then
				if Cleanse() then return true end
			end
			if HUD.Defensive == 1 then
				if Buff.PredatorySwiftness:Exist() and Player.HP <= 90 then
					if Spell.Regrowth:Cast(Player) then return true end
				end
			end
		end
		if (Target and Target.ValidEnemy) or (DMW.Player.InstanceID ~= nil and Player.Combat) or not Player.InGroup then
			if Target and Target.ValidEnemy then
				local flyingT = Target:Flying()
				if flyingT and not Debuff.Moonfire:Exist(Target) then
					if Spell.Moonfire:IsReady() and Spell.Moonfire:Cast(Target) then return true end
					return
				else
					if not Buff.Prowl:Exist() and not Player.Combat and (Target.Distance <= 10 or Spell.WildChargeCat:IsReady()) and Target.Distance <= 25 and Spell.Prowl:IsReady() then
						if Spell.Prowl:Cast(Player) then return true end
					end
					if  Target.Distance >= 10 and Target.Distance <= 25 and not flyingT and Buff.FormCat:Exist() then
						if Spell.WildChargeCat:IsReady() then
							if Spell.WildChargeCat:Cast(Target) then return true end
						end
						-- if Spell.WildChargeTravel:IsReady() and UnitIsFacing("player", Target.Pointer) then
						-- 	if Spell.WildChargeTravel:Cast() then return true end
						-- end
					end
				end
			end

			if Target and Target.ValidEnemy and Target.Distance <= 5 and (not Buff.Prowl:Exist() or Spell.Prowl:CD() > 5) and Target:Facing() then
				if not IsCurrentSpell(Spell.Attack.SpellID) then StartAttack() end
			end

			if HUD.Shifts == 1 then
				if Player.Combat and not Buff.FormCat:Exist() then
					if Spell.FormCat:Cast(Player) then return true end
				end
			end
			if FeralStealthOpener() then return true end
			if HUD.Defensive == 1 then
				if Buff.PredatorySwiftness:Exist() and not Buff.Prowl:Exist() and Player.HP <= 40 then
					if Spell.Regrowth:Cast(Player) then return true end
				end
			end
			if EnemyMeleeCount >= 1 and FeralRotation() then return true end
			if HUD.Cleanse == 1 and not Buff.Prowl:Exist() then
				if Cleanse() then return true end
			end
			if HUD.Defensive == 1 then
				if Buff.PredatorySwiftness:Exist() and not Buff.Prowl:Exist() and Player.HP <= 90 then
					if Spell.Regrowth:Cast(Player) then return true end
				end
			end
		end
	elseif Player.SpecID == "Guardian" then
		LocalsGuardian()
        BaitHelper()
		noAoE = aoeCheck()
		if Player.Combat and not noAoE and GrindBot.Combat.MultipullForceCombat  then
			-- local moveAwayFromUnit
			-- for _, Unit in pairs(DMW.Attackable) do
			-- 	-- if Unit.Distance <= 10 and noAoeList[Unit.ObjectID] then
			-- 	if Unit.Distance <= 11 and not GrindBot.Grinding:CheckLevel(Unit.Level) and not UnitThreatSituation(DMW.Player.Pointer, Unit.Pointer) then
			-- 		-- print(Unit.Name)
			-- 		moveAwayFromUnit = Unit
			-- 		break
			-- 	end
			-- end
			-- print("dodge position")
			GrindBot.Navigation.ForcedMovementCoords = true-- {GetPositionBetweenObjects(moveAwayFromUnit.Pointer, DMW.Player.Pointer, 20)}
		end
		if GrindBot.Navigation.ForcedMovementCoords and (not Player.Combat or noAoE) then
			GrindBot.Navigation.ForcedMovementCoords = nil
		end
		-- if Target and Target.CanAttack and Target.Distance <= 7 and Target.HP == 100 and not Target.LoS and not Target.TriedToPull then
		-- 	if not IsCurrentSpell(Spell.Attack.SpellID) then StartAttack() end
		-- 	if Spell.Thrash:IsReady() then
		-- 		print("trying to pull")
		-- 		if Spell.Thrash:Cast(Player) then Target.TriedToPull = true; return true end
		-- 	end
		-- end

		if not Player.Combat then
			if HUD.Cleanse == 1  then
				if Cleanse() then return true end
			end
			if HUD.Defensive == 1 then
				-- if Buff.PredatorySwiftness:Exist() and Player.HP <= 90 then
				-- 	if Spell.Regrowth:Cast(Player) then return true end
				-- end
				-- if Player.HP <= 80 and not Player.Moving and not Player.Casting then
				-- 	if Spell.Regrowth:Cast(Player) then return true end
				-- end
				if Player.HP <= 80 and not Buff.Rejuvenation:Exist() then
					if Spell.Rejuvenation:Cast(Player) then return true end
				end
			end
			-- if
		end
		if (Target and Target.ValidEnemy) or Player.Combat then
			if Spell.Thrash:IsReady() and Enemy9YC > 2 and noAoE then
				for _, Unit in ipairs(Enemy9Y) do
					if Spell.Thrash:Cast(Unit) then return true end
				end
			end
			if HUD.Defensive == 1 then
				if Talent.Renewal and Player.Combat and Player.HP < 12 then
					if Spell.Renewal:IsReady() and Spell.Renewal:Cast(Player) then
						return true
					end
				end
			end
			-- if Target and Target.ValidEnemy then
			-- 	local flyingT = Target:Flying()
			-- 	if flyingT and not Debuff.Moonfire:Exist(Target) then
			if Target and Target.ValidEnemy and Spell.Moonfire:IsReady() and not Debuff.Moonfire:Exist(Target) and (not Target.Target or Target.Target ~= DMW.Player.Pointer) then
				if Spell.Moonfire:Cast(Target) then
				-- if not Player.Combat then
				-- 	GrindBot.Combat.EvadeCheck = {Target.PosX, Target.PosY}
				-- end
					-- Target.Pulled = DMW.Time
					return true
				end
			end
			if Spell.Moonfire:IsReady() and not GrindBot.Combat.MultipullForceCombat then
				for _, Unit in ipairs(DMW.Enemies) do
					if Unit.LastHitTime and DMW.Time - Unit.LastHitTime >= 13 then
						if Spell.Moonfire:Cast(Unit) then return true end
					end
				end
			end
			if HUD.Shifts == 1 and Player.Combat then
				if not Buff.FormBear:Exist() then
					if Spell.FormBear:Cast(Player) then return true end
				end
			end
			if GrindBot.Settings.profile.GrindingMode.MultipullHP <= Player.HP and Spell.Moonfire:IsReady() then
				for _, Unit in ipairs(DMW.Attackable) do
					if GrindBot.Grinding:UnitIsViableForGrind(Unit) and not Unit:TappedOrPulled() then
						if Spell.Moonfire:Cast(Unit) then return true end
					end
				end
			end
			if Spell.Moonfire:IsReady() and not GrindBot.Combat.MultipullForceCombat then
				if Spell.Moonfire:IsReady() and not GrindBot.Combat.MultipullForceCombat then
					local lastHitTime, lastHitUnit
					for _, Unit in ipairs(DMW.Enemies) do
						if Unit.LastHitTime then
							if not lastHitUnit or lastHitTime > Unit.LastHitTime then
								lastHitUnit = Unit
								lastHitTime = Unit.LastHitTime
							end
						end
					end
					if lastHitUnit then
						if Spell.Moonfire:Cast(lastHitUnit) then return true end
					end
				end
			end
			-- 		return
			-- 	else
			-- 		if not Buff.Prowl:Exist() and not Player.Combat and (Target.Distance <= 10 or Spell.WildChargeCat:IsReady()) and Target.Distance <= 25 and Spell.Prowl:IsReady() then
			-- 			if Spell.Prowl:Cast(Player) then return true end
			-- 		end
			-- 		if  Target.Distance >= 10 and Target.Distance <= 25 and not flyingT and Buff.FormCat:Exist() then
			-- 			if Spell.WildChargeCat:IsReady() then
			-- 				if Spell.WildChargeCat:Cast(Target) then return true end
			-- 			end
			-- 			-- if Spell.WildChargeTravel:IsReady() and UnitIsFacing("player", Target.Pointer) then
			-- 			-- 	if Spell.WildChargeTravel:Cast() then return true end
			-- 			-- end
			-- 		end
			-- 	end
			-- end
			if Target and Target.ValidEnemy and Target.Distance <= 5 and Target:Facing() then
				if not IsCurrentSpell(Spell.Attack.SpellID) then StartAttack() end
			end
			--Cooldowns
			if GrindBot.Combat.MultipullForceCombat then
				if (EnemyMeleeCount >= 5 or Player.HP < 70) and Spell.Barkskin:IsReady()  then
					Spell.Barkskin:Cast(Player)
				end
				if EnemyMeleeCount >= 5 and Player.HP < 45 and Spell.SurvivalInstincts:IsReady() and not Spell.SurvivalInstincts:LastCast() then
					Spell.SurvivalInstincts:Cast(Player)
				end
				if EnemyMeleeCount >= 5 then
					if Spell.Berserk:IsReady() then
						if Spell.Berserk:Cast(Player) then return true end
					end
				end
				if (EnemyMeleeCount >= 5 or Player.HP < 30) and not Spell.Berserk:LastCast() and not Buff.Berserk:Exist() then
					if Spell.Convoke:IsReady() then

						-- if not Buff.FormCat:Exist() then
						-- 	if Spell.FormCat:Cast(Player) then return true end
						-- else
							for _, Unit in ipairs(EnemyMelee) do
								if Unit.Level >= 55 or DMW.Player.Level == 60 then
									if Spell.Convoke:Cast(Unit) then return true end
								end
							end
						-- end
					end
				end
			end


			-- if FeralStealthOpener() then return true end
			if HUD.Defensive == 1 then
				-- if Buff.PredatorySwiftness:Exist() and not Buff.Prowl:Exist() and Player.HP <= 40 then
				-- 	if Spell.Regrowth:Cast(Player) then return true end
				-- end
				-- if EnemyMeleeCount >= 5 then
				-- 	if Spell.Barkskin:IsReady() then
				-- 		Spell.Barkskin:Cast(Player)
				-- 	end
				-- end
				if Spell.Ironfur:IsReady() and (EnemyMeleeCount >= 3 or
					 (Player.RageDeficit < 40 and (Buff.Ironfur:Remain() < 0.5 or Buff.Ironfur:Stacks() < 3))) then
						if Spell.Ironfur:Cast(Player) then end
					-- end
				end
				if Player.HP <= 60 then
					if GrindBot.Combat.MultipullForceCombat then
						if Spell.Mangle:IsReady() then
							for _, Unit in ipairs(EnemyMelee) do
								if Spell.Mangle:Cast(Unit) then return true end
							end
						end
					end
					if Spell.FrenziedRegeneration:IsReady() then
						if Spell.FrenziedRegeneration:Cast(Player) then return true end
					end
				end
			end

			if EnemyMeleeCount >= 1 and GuardianRotation() then return true end
			if HUD.Cleanse == 1 then
				if Cleanse() then return true end
			end
			if HUD.Defensive == 1 then
				-- if Buff.PredatorySwiftness:Exist() and not Buff.Prowl:Exist() and Player.HP <= 90 then
				-- 	if Spell.Regrowth:Cast(Player) then return true end
				-- end
			end
		end

    elseif Player.SpecID =="Restoration" then
        LocalsRestoration()
        -- print(Form)
        if HUD.Cleanse == 1 then
            if Cleanse() then return true end
        end

        if not Player.Combat then
            if Setting("Healing OOC") then
                if Form == "Human" then
                    if RestorationLifeBloom() or RestorationWildGrowth() or RestorationTank() or RestorationHeal() then return true end
                elseif Form == "Moonkin" then
                    if RestorationTank(true) or RestorationHeal(true) then return true end
                end
            end
        end
        if (Target and Target.ValidEnemy) or (DMW.Player.InstanceID ~= nil and Player.Combat) or not Player.InGroup then
            if HUD.Shifts == 1 then
                if DMW.Friends.LowestHP >= Setting("DPS HP") and Form == "Human" then
                    if Talent.BalanceAffinity then
                        if Spell.FormMoonkin:IsReady() and Spell.FormMoonkin:Cast() then return true end
                    elseif Talent.FeralAffinity and EnemyMeleeCount > 0 then
                        if Spell.FormCat:IsReady() and Spell.FormCat:Cast() then return true end
                    end
                end
            end
            if Form == "Moonkin" then
                if DMW.Friends.LowestHP >= Setting("Critical HP") then
                    if RestorationCooldowns(true) then return true end
                    if RestorationTank(true) or RestorationHeal(true) then return true end
                    if RestorationDPS() then return true end
                    return
                else
                    RunMacroText("/cancelform")
                end
            elseif Form == "Cat" then
                if DMW.Friends.LowestHP >= Setting("Critical HP") then
                    if RestorationFeralDPS() or RestorationDPS() then return true end
                    return
                else
                    RunMacroText("/cancelform")
                end
            end
            if RestorationCooldowns() then return true end
            if HUD.Cleanse == 1 then
                if Cleanse() then return true end
            end
            if RestorationLifeBloom() or RestorationWildGrowth() or RestorationTank() or RestorationHeal() then return true end
            if RestorationDPS() then return true end
        end
    end
end
