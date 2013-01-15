-- Exsto
-- Lets notify players that they are protected by Exsto!

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Performance",
	ID = "performance",
	Desc = "A plugin that increases performance of Exsto.",
	Owner = "Prefanatic",
} )

function PLUGIN:Think()
	collectgarbage( "step", 150 )
end

PLUGIN:Register()