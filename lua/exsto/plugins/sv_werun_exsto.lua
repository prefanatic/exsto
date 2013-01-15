-- Exsto
-- Lets notify players that they are protected by Exsto!

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Notifyer",
	ID = "notify",
	Desc = "A plugin that notifies players of Exsto!",
	Owner = "Prefanatic",
} )

PLUGIN:AddVariable({
	Pretty = "Exsto Credit Delay",
	Dirty = "notify_delay",
	Default = 5,
	Description = "How long in minutes till players are notified of Exsto.",
})

PLUGIN.Next = 0
function PLUGIN:Think()
	if self.Next <= CurTime() then
		exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "This server is proudly protected by ", COLOR.EXSTO, "Exsto" )
		self.Next = CurTime() + exsto.GetVar( "notify_delay" ).Value * 60
	end
end

PLUGIN:Register()