-- Prefan Access Controller
-- Goto and Bring

-- FURST PLUGIN TO USE NEW COMMAND SYSTEM

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Bring Commands",
	ID = "goto-bring",
	Desc = "A plugin that allows bringing and goto player commands!",
	Owner = "Prefanatic",
} )

-- I was told to rewrite this by the lovely Megiddo; so I did.  Love: Prefanatic.
-- Hated: hatred says you are now lower life form then a scene whore... hi overv
function PLUGIN:SendPlayer( ply, megiddo, force )

	local isvec = false
	if type( megiddo ) == "Vector" then isvec = true end

	if !isvec and !megiddo:IsInWorld() and !force then return false end
	
	local fuck
	local umegiddo
	if isvec then
		umegiddo = 0
		fuck = megiddo
	else
		umegiddo = megiddo:EyeAngles().yaw
		fuck = megiddo:GetPos()
	end
	
	local ulx_sucks = {
		math.NormalizeAngle( umegiddo - 180 ),
		math.NormalizeAngle( umegiddo + 90 ),
		math.NormalizeAngle( umegiddo - 90 ),
		umegiddo,
	}

	local lol_creative_commons_on_code = {}
	lol_creative_commons_on_code.start = fuck + Vector( 0, 0, 32 )
	lol_creative_commons_on_code.filter = { megiddo, ply }

	local loveyou
	for I = 1, #ulx_sucks do
		lol_creative_commons_on_code.endpos = fuck + Angle( 0, ulx_sucks[ I ], 0 ):Forward() * 47
		loveyou = util.TraceEntity( lol_creative_commons_on_code, ply )
		if !loveyou.Hit then return loveyou.HitPos end
	end
	
	if force then
		return fuck + Angle( 0, ulx_sucks[ 1 ], 0 ):Forward() * 47
	end
	
end


function PLUGIN:Teleport( owner )
	local pos = self:SendPlayer( owner, owner:GetEyeTrace().HitPos )
	if !pos then exsto.Print( exsto_CHAT, owner, COLOR.NORM, "Not enough room to teleport to that ", COLOR.NAME, "position", COLOR.NORM, "!" ) return end
	
	owner:SetPos( pos )
end
PLUGIN:AddCommand( "teleport", {
	Call = PLUGIN.Teleport,
	Desc = "Allows users to teleport to their cursor.",
	Console = { "teleport", "tp" },
	Chat = { "!tp", "!teleport" },
	Args = {},
	Category = "Teleportation",
})

function PLUGIN:Send( owner, victim, to, force )
    victim = victim[1]  -- Victim seems to be returning a table, so just take the player out.
	if owner:GetMoveType() == MOVETYPE_NOCLIP then force = true end
	
	local pos = self:SendPlayer( victim, to, force )
	
	if !pos then exsto.Print( exsto_CHAT, owner, COLOR.NORM, "Not enough room to goto ", COLOR.NAME, to:Nick(), COLOR.NORM, "!" ) return end
	
	victim:SetPos( pos )
	
	return {
		COLOR.NAME, owner:Nick(), COLOR.NORM, " has sent ", COLOR.NAME, victim:Nick(), COLOR.NORM, " to ", COLOR.NAME, to:Nick(), COLOR.NORM, "!"
	}
	
end
PLUGIN:AddCommand( "send", {
	Call = PLUGIN.Send,
	Desc = "Allows users to send other players to places.",
	Console = { "send" },
	Chat = { "!send" },
	ReturnOrder = "Victim-To-Force",
	Args = { Victim = "PLAYER", To = "PLAYER", Force = "BOOLEAN" },
	Optional = { Force = false },
	Category = "Teleportation",
})

function PLUGIN:Goto( owner, ply, force )
	
	if owner:GetMoveType() == MOVETYPE_NOCLIP then force = true end
	
	local pos = self:SendPlayer( owner, ply, force )
	
	if !pos then exsto.Print( exsto_CHAT, owner, COLOR.NORM, "Not enough room to goto ", COLOR.NAME, ply:Nick(), COLOR.NORM, "!" ) return end
	
	owner:SetPos( pos )
	
	return {
		Activator = owner,
		Player = ply,
		Wording = " has gone to "
	}
	
end
PLUGIN:AddCommand( "goto", {
	Call = PLUGIN.Goto,
	Desc = "Allows users to teleport to a player.",
	Console = { "goto" },
	Chat = { "!goto" },
	ReturnOrder = "Victim-Force",
	Args = {Victim = "PLAYER", Force = "BOOLEAN"},
	Optional = { Force = false },
	Category = "Teleportation",
})
PLUGIN:RequestQuickmenuSlot( "goto", "Goto", {
	Force = {
		{ Display = "Force Teleport", Data = true },
	},
} )

function PLUGIN:Bring( owner, ply, force )
		
	if owner:GetMoveType() == MOVETYPE_NOCLIP then force = true end
	
	local pos = self:SendPlayer( ply, owner, force )

	if !pos then return { owner, COLOR.NORM, "Not enough space to bring ", COLOR.NAME, ply:Nick() } end
	
	ply:SetPos( pos )
	return {
		Activator = owner,
		Player = ply,
		Wording = " has brought ",
		Secondary = " to himself"
	}
	
end
PLUGIN:AddCommand( "bring", {
	Call = PLUGIN.Bring,
	Desc = "Allows users to bring other players.",
	Console = { "bring" },
	Chat = { "!bring" },
	ReturnOrder = "Victim-Force",
	Args = {Victim = "PLAYER", Force = "BOOLEAN"},
	Optional = { Force = false },
	Category = "Teleportation",
})
PLUGIN:RequestQuickmenuSlot( "bring", "Bring", {
	Force = {
		{ Display = "Force Teleport", Data = true },
	},
} )

PLUGIN:Register()