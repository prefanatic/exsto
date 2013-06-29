--Exsto Prop kill message Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Propkill Messages",
	ID = "propkillmsg",
	Desc = "A plugin that prints propkills to admin's console.",
	Owner = "Hobo",
})

function PLUGIN:Init()
	self.Enable = exsto.CreateVariable( "ExPropKillMessage",
		"Kill Message",
		true,
		"If propkill messages are shown in admin's consoles or not (Only with FPP or SPP)."
	)
	self.Enable:SetCategory( "Props" )
	
	timer.Simple(1, function()
						if !FPP then
							self:Debug( "No FPP detected.  Unloading!", 1 )
							self:Unload( "FPP not detected." )
						end
					end )
end

function PLUGIN:AdminPrint(msg)
	for i,ply in pairs (player.GetAll()) do
		if ply:IsAdmin() then ply:PrintMessage(HUD_PRINTCONSOLE,msg) end
	end
end

function PLUGIN:PlayerDeath(victim,inflictor,killer)
	inflictor = inflictor or ""
	if self.Enable:GetValue() then
		if killer:GetClass() != "player" and victim != killer then
			if FPP then
				local KillMsg = "[Propkill] "..victim:Nick().." was killed by "..killer:GetClass().." owned by "
				if killer:CPPIGetOwner() then 
					KillMsg = KillMsg..killer:CPPIGetOwner():Nick()
				end
				self:AdminPrint(KillMsg)
			end
		end
	end
end

PLUGIN:Register()