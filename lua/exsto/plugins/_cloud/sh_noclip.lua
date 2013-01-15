 -- Exsto
 -- Noclip Plugin 

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Noclip",
	ID = "noclip",
	Desc = "A plugin that allows noclipping!",
	Owner = "Prefanatic",
} )

if SERVER then

	PLUGIN:AddVariable({
		Pretty = "Admin Only Noclip",
		Dirty = "admin_noclip",
		Default = false,
		Description = "Makes it so only admins can noclip",
		Possible = { true, false }
	})
	
	exsto.CreateFlag( "cannoclip", "Allows users to noclip." )

	function PLUGIN:NoClip( ply, victim )

		local movetype = victim:GetMoveType()
		local changeto = MOVETYPE_NOCLIP
		local style = "noclip"
		
		if movetype == MOVETYPE_NOCLIP then
			changeto = MOVETYPE_WALK	
			style = "walk"
		end
		
		victim:SetMoveType( changeto )
		
		return {
			Activator = ply,
			Player = victim,
			Wording = " has set ",
			Secondary = " to " .. style,
		}	
		
	end
	PLUGIN:AddCommand( "noclip", {
		Call = PLUGIN.NoClip,
		Desc = "Allows users to use noclip on other players.",
		Console = { "noclip" },
		Chat = { "!noclip" },
		ReturnOrder = "Victim",
		Args = { Victim = "PLAYER" },
		Optional = { Victim = nil },
		Category = "Fun",
	})
	PLUGIN:RequestQuickmenuSlot( "noclip" )
	
end

function PLUGIN:PlayerNoClip( ply )

	if ply:IsAllowed( "cannoclip" ) then return true end

	if CLIENT then if !ply:IsAdmin() then return false end end
	
	if SERVER then

		if exsto.GetVar( "admin_noclip" ).Value and !ply:IsAdmin() then
			return false
		end
		
	end

end

PLUGIN:Register()
