
local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Logs",
	ID = "logs",
	Desc = "A plugin that logs all Exsto events.",
	Owner = "Prefanatic",
} )

function PLUGIN:Init()
	self.Types = { "all", "commands", "player", "errors", "chat", "spawns" }
	
	file.CreateDir( "exsto_logs" )
	for _, type in ipairs( self.Types ) do
		file.CreateDir( "exsto_logs/" .. type )
	end
end

function PLUGIN:PlayerSpawnProp( ply, mdl )
	self:SaveEvent( self:Player( ply ) .. " has spawned prop (" .. mdl .. ")", "spawns" )
end

function PLUGIN:PlayerSpawnSENT( ply, class )
	self:SaveEvent( self:Player( ply ) .. " has spawned sent (" .. class .. ")", "spawns" )
end

function PLUGIN:PlayerSpawnSWEP( ply, class )
	self:SaveEvent( self:Player( ply ) .. " has spawned swep (" .. class .. ")", "spawns" )
end

function PLUGIN:PlayerSpawnNPC( ply, npc )
	self:SaveEvent( self:Player( ply ) .. " has spawned npc (" .. npc .. ")", "spawns" )
end

function PLUGIN:PlayerSpawnVehicle( ply, class )
	self:SaveEvent( self:Player( ply ) .. " has spawned vehicle (" .. class .. ")", "spawns" )
end

function PLUGIN:PlayerSpawnRagdoll( ply, mdl )
	self:SaveEvent( self:Player( ply ) .. " has spawned ragdoll (" .. mdl .. ")", "spawns" )
end

function PLUGIN:PlayerSay( ply, text )
	self:SaveEvent( self:Player( ply ) .. ": " .. text, "chat" )
end

function PLUGIN:ExPrintCalled( enum, data )
	if enum == exsto_ERROR or enum == exsto_ERRORNOHALT then
		local trace = debug.getinfo( 5, "Sln" )
		local construct = ""
		--PrintTable( data )
			for _, obj in ipairs( data ) do
				construct = construct .. obj
			end
			--construct .. "[" .. trace.source .. ", N:" .. trace.name .. ", " .. trace.linedefined .. "-" .. trace.currentline .. "-" .. trace.lastlinedefined .. "]"
		self:SaveEvent( construct, "errors" )
	end
end

function PLUGIN:PlayerSpawn( ply )
	self:SaveEvent( self:Player( ply ) .. " has spawned.", "player" )
end

function PLUGIN:PlayerDeath( ply )
	self:SaveEvent( self:Player( ply ) .. " has died.", "player" )
end

function PLUGIN:ExInitSpawn( ply, sid, uid )
	self:SaveEvent( self:Player( ply ) .. " has joined the game.", "player" )
end

function PLUGIN:PlayerDisconnected( ply )
	self:SaveEvent( self:Player( ply ) .. " has disconnected!" )
end

function PLUGIN:ExCommandCalled( id, plug, caller, ... )
	local arg = {...}
	if type( plug ) == "Player" then caller = plug end
	local text = self:Player( caller ) .. " has run command '" .. id .. "'"
	local index = 1
	if arg[1] then
		if type( arg[1] ) == "Player" then
			text = text .. " on player " .. self:Player( arg[1] )
			index = 2
		end
		
		if arg[ index ] then
			text = text .. " with args: "
			for I = index, #arg do
				text = text .. tostring( arg[I] )
			end
		end
	end
	
	self:SaveEvent( text, "commands" )
end

function PLUGIN:Player( ply )
    if ply:EntIndex() == 0 then
        return "CONSOLE"
    else
        return ply:Nick() .. "(" .. ply:SteamID() .. ")"
    end
end

function PLUGIN:SaveEvent( text, type )
	if text == "" then return end

	local date = os.date( "%m-%d-%y" )
	local time = tostring( os.date( "%H:%M:%S" ) )
	
	local obj = { type }
	if type != "all" then obj = { type, "all" } end
	
	for _, type in ipairs( obj ) do
		if !file.Exists( "exsto_logs/" .. type .. "/" .. date .. ".txt", "DATA" ) then
			file.Write( "exsto_logs/" .. type .. "/" .. date .. ".txt", "[" .. time .. "] " .. text:gsub( "\n", "" ) .. "\n" )
		else
			local data = file.Read( "exsto_logs/" .. type .. "/" .. date .. ".txt", "DATA" )
			file.Write( "exsto_logs/" .. type .. "/" .. date .. ".txt", data .. "[" .. time .. "] " .. text:gsub( "\n", "" ) .. "\n" )
		end
	end
	
end

PLUGIN:Register()