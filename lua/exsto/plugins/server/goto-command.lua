-- Prefan Access Controller
-- Goto and Bring

-- FURST PLUGIN TO USE NEW COMMAND SYSTEM

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Bring Commands",
	ID = "goto-bring",
	Desc = "A plugin that allows bringing and goto player commands!",
	Owner = "Prefanatic",
	CleanUnload = true;
} )

function PLUGIN:Init()
	-- Construct send positions
	local cos, sin, rad = math.cos, math.sin, math.rad

	self.Pos = {}
	for I = 0, 360, 30 do
		table.insert( self.Pos, Vector( cos( rad( I ) ), sin( rad( I ) ), 0 ) )
	end
	-- Check above and below too.
	table.insert( self.Pos, Vector( 0, 0, 1 ) )
	table.insert( self.Pos, Vector( 0, 0, -1 ) )
	
	self.Sizes = Vector( 40, 40, 77 )
end

-- Sends 'send' to 'to'.  Checks in a circle around 'to' to prevent going into walls.
function PLUGIN:SendPlayer( send, to, force )
	local pos = IsValid( to ) and to:GetPos() or to
	if force and IsValid( to ) and to:IsInWorld() then return pos end
	
	-- Do a trace for each point in the circle.
	local trace = {
		start = pos;
		filter = { send, IsValid( to ) and to or false };
	}
	local traceData = nil; -- Reference
	for I = 1, #self.Pos do
		trace.endpos = pos + ( self.Pos[ I ] * self.Sizes )
		traceData = util.TraceEntity( trace, send )
		if not traceData.Hit then return traceData.HitPos end
	end
	
	if force then return traceData.HitPos end
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
	Arguments = {
		{ Name = "Victim", Type = COMMAND_PLAYER };
		{ Name = "To", Type = COMMAND_PLAYER };
		{ Name = "Force", Type = COMMAND_BOOLEAN, Optional = false };
	};
	Category = "Teleportation",
})

function PLUGIN:Goto( owner, ply, force )
	
	if owner:GetMoveType() == MOVETYPE_NOCLIP then force = true end
	
	local pos = self:SendPlayer( owner, ply, force )
	
	if !pos then exsto.Print( exsto_CHAT, owner, COLOR.NORM, "Not enough room to go to ", COLOR.NAME, ply:Nick(), COLOR.NORM, "!" ) return end
	
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
	Arguments = {
		{ Name = "Victim", Type = COMMAND_PLAYER };
		{ Name = "Force", Type = COMMAND_BOOLEAN, Optional = false };
	};
	Category = "Teleportation",
})
PLUGIN:RequestQuickmenuSlot( "goto", "Go to", {
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
	Arguments = {
		{ Name = "Victim", Type = COMMAND_PLAYER };
		{ Name = "Force", Type = COMMAND_BOOLEAN, Optional = false };
	};
	Category = "Teleportation",
})
PLUGIN:RequestQuickmenuSlot( "bring", "Bring", {
	Force = {
		{ Display = "Force Teleport", Data = true },
	},
} )

PLUGIN:Register()