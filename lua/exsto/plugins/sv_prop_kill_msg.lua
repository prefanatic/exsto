--Exsto Prop kill message Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Propkill Messages",
	ID = "propkillmsg",
	Desc = "A plugin that prints propkills to admin's console.",
	Owner = "Hobo",
})

PLUGIN:AddVariable({
	Pretty = "Prop kill messages",
	Dirty = "propkillmsg",
	Default = true,
	Description = "If propkill messages are shown in admin's consoles or not (Only with FPP or SPP).",
	Possible = {"true","false"},
})

function PLUGIN:AdminPrint(msg)
	for i,ply in pairs (player.GetAll()) do
		if ply:IsAdmin() then ply:PrintMessage(HUD_PRINTCONSOLE,msg) end
	end
end

function PLUGIN:PlayerDeath(victim,inflictor,killer)
	inflictor = inflictor or ""
	if exsto.GetVar("propkillmsg").Value then
		if killer:GetClass() != "player" and victim != killer then
			if FPP or SPP then
				local Msg = "[Propkill] "..victim:Nick().." was killed by "..killer:GetClass().." owned by "
				if FPP and killer.Owner then Msg = Msg..killer.Owner:Nick()
				elseif SPropProtection and killer:GetNWEntity("OwnerObj") then Msg = Msg..killer:GetNWEntity("OwnerObj"):Nick() end				
				self:AdminPrint(Msg)
				--return true
			else
				Msg("Prop kill message not sent, FPP or SPP only.\n")
			end
		end
	end
end

PLUGIN:Register()