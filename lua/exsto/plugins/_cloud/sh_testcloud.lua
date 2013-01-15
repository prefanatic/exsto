-- Exsto
local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Test Cloud",
	ID = "test_cloud",
	Desc = "A plugin that tests the CLOUD system.",
	Owner = "Prefanatic",
} )

if SERVER then
	function PLUGIN:Init()
		exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "This test plugin has ", COLOR.NAME, "LOADED!" )
	end
else
	function PLUGIN:Init()
		chat.AddText( COLOR.NORM, "Greetings from a ", COLOR.NAME, "CLIENTSIDE LOAD!" )
	end
end

PLUGIN:Register()