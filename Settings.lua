local DMW = DMW
DMW.Rotations.DRUID = {}
local Druid = DMW.Rotations.DRUID
local UI = DMW.UI

function Druid.Settings()
    DMW.Helpers.Rotation.CastingCheck = false

    UI.HUD.Options = {
		[1] = {
            Defensive = {
                [1] = {Text = "|cFF00FF00Defensives On", Tooltip = ""},
                [2] = {Text = "|cFFFFFF00No Defensives", Tooltip = ""}
            }
        },
        [2] = {
            Info = {
                [1] = {Text = "", Tooltip = ""},
                [2] = {Text = "|cffFF4500Explosives", Tooltip = ""},
                [3] = {Text = "|cffFF4500Holding AoE", Tooltip = ""}
            }
        },
        [3] = {
            Cleanse = {
                [1] = {Text = "|cFF00FF00Cleanse", Tooltip = ""},
                [2] = {Text = "|cffFF4500Cleanse", Tooltip = ""},
            }
        },
        [4] = {
            Shifts = {
                [1] = {Text = "|cFF00FF00Shifts", Tooltip = ""},
                [2] = {Text = "|cffFF4500Shifts", Tooltip = ""},
            }
        },
        [5] = {
            Prowl = {
                [1] = {Text = "|cFF00FF00Prowl", Tooltip = ""},
                [2] = {Text = "|cffFF4500Prowl", Tooltip = ""},
            }
        }
    }
    UI.AddToggle("Healing OOC", nil, false)
    if DMW.Player.SpecID == "Restoration" then
        UI.AddRange("DPS HP", nil, 0, 100, 1, 0)
        UI.AddRange("Critical HP", nil, 0, 100, 1, 0)
        UI.AddHeader("Tank Healing")
        UI.AddRange("Regrowth HP ", nil, 0, 100, 1, 0)
        UI.AddRange("Regrowth HP no Buff", nil, 0, 100, 1, 0)
        UI.AddRange("Rejuvenation HP ", nil, 0, 100, 1, 0)
        UI.AddRange("Swiftmend HP ", nil, 0, 100, 1, 0)
        UI.AddToggle("LifeBloom Tanks", nil, false)
        UI.AddRange("IronBark HP ", nil, 0, 100, 1, 0)
        UI.AddHeader("Party Healing")
        UI.AddRange("Regrowth HP", nil, 0, 100, 1, 0)
        UI.AddRange("Rejuvenation HP", nil, 0, 100, 1, 0)
        UI.AddRange("Swiftmend HP", nil, 0, 100, 1, 0)
        UI.AddRange("IronBark HP", nil, 0, 100, 1, 0)
        UI.AddHeader("Wild Growth")
        UI.AddRange("WildGrowth HP", nil, 0, 100, 1, 0)
        UI.AddRange("WildGrowth Count", nil, 0, 5, 1, 0)
    end
        UI.AddTab("Damage")
    UI.AddToggle("Moonfire", "", true)
    UI.AddToggle("Sunfire", "", true)
    UI.AddToggle("Wrath", "", true)
    UI.AddToggle("AOE Moonfire", "", false)
    -- UI.AddToggle("Moonfire", "", true)

    -- UI.AddHeader("This Is A Header")
    -- UI.AddDropdown("This Is A Dropdown", nil, {"Yay", "Nay"}, 1)
    -- UI.AddRange("This Is A Range", "One more tooltip", 0, 100, 1, 70)
    -- UI.AddHeader("Usual Options")
    --     -- UI.AddToggle("AutoExecute360", nil, false)
    --     -- UI.AddRange("Rotation", "4 = furyprot, 3 leveling, 2 - dps , 1 - tanking  ", 1, 4, 1, 1)
    --     UI.AddToggle("Debug", nil, false)
    --     UI.AddDropdown("Rotation", nil, {"Tanking","Fury","Fury/Slam","Fury/Prot","Testing", "PVP", "Arms PVP", "TESTTESTTEST"}, "Tanking")
    --     -- UI.AddRange("Stance", "any, combat, def, bers", 1, 4, 1, 1)
    --     UI.AddDropdown("First check Stance", "", {"Battle","Defensive","Berserker"}, "Battle")
    --     UI.AddDropdown("Second check Stance", "", {"Battle","Defensive","Berserker"}, "Berserker")
    --     UI.AddDropdown("Third check Stance", "", {"Battle","Defensive","Berserker"}, "Defensive")
    --     UI.AddToggle("Charge", nil, false)
    -- UI.AddHeader("Auto stuff")
    --     UI.AddToggle("AutoFaceMelee", nil, false)
    --General

end
