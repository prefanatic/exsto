--Exsto Exstinguish Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Extinguish Plugin",
	ID = "extinguish",
	Desc = "A plugin that extinguishes entities.",
	Owner = "Hobo",
})

function PLUGIN:Extinguish( owner )
    for I,K in pairs(ents.GetAll()) do
		if K:IsOnFire() then
			K:Extinguish()
		end
	end
	return {COLOR.NAME,owner:Nick(),COLOR.NORM," extinguished all flames." }
end		
PLUGIN:AddCommand( "extinguish", {
	Call = PLUGIN.Extinguish,
	Desc = "Extinguishes all flames",
	Console = { "extinguish" },
	Chat = { "!extinguish","!ex" },
	Category = "Utilities",
})

PLUGIN:Register()