-- Exsto
-- Lets notify players that they are protected by Exsto!

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Notifyer",
	ID = "notify",
	Desc = "A plugin that notifies players of Exsto!",
	Owner = "Prefanatic",
} )

function PLUGIN:Init()
	self.Delay = exsto.CreateVariable( "ExCreditDelay", 
		"Exsto's Credit Delay", 
		5,
		"Specifies a delay in which the server is notified of Exsto's existance." )
		self.Delay:SetCategory( "Exsto General" )
		self.Delay:SetUnit( "Time (minutes)" )
		
	self.Next = CurTime() + self.Delay:GetValue() * 60
end

function PLUGIN:Think()
	if self.Next <= CurTime() then
		exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "This server is proudly protected by ", COLOR.EXSTO, "Exsto" )
		self.Next = CurTime() + self.Delay:GetValue() * 60
	end
end

PLUGIN:Register()