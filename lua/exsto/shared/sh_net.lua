--[[
	Exsto
	Copyright (C) 2010  Prefanatic

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local function split(str,d)
        local t = {}
        local len = str:len()
        local i = 0
        while i*d < len do
                        t[i+1] = str:sub(i*d+1,(i+1)*d)
                        i=i+1
        end
        return t
end

exsto.Net = {
	Running = {},
	NetworkStrings = {
		"ExOpenMenu";
		"ExChatPrint";
		"ExRecCommands";
		"ExRecPlugSettings";
		"ExClearFlags";
		"ExRecFlags";
		"ExRecRank";
		"ExReceivedRanks";
		"ExClientErrNoHalt";
		"ExClearRanks";
		"ExSaveBans";
		"ExRecVars";
		"ExRecVarsFinal";
		"ExSendPlugsDone";
		"ExRecMapData";
		"ExSendPlugs";
		"ExClientErr";
		"ExClientPrint";
		"ExSendVariable";
		"ExRecRankErr";
		"ExCreateFlag";
		"ExClientLoad";
		"ExClientReady";
		"ExMenuUser";
		"ExMenuUserLeft";
	},
	NotifiedNetStrings = {}
}

--[[-----------------------------------
Function: exsto.Net.WatchProcesses()
Description: Error handling to let us know when net pushes send or not.  Also notifies if there was no util.AddNetworkString()
----------------------------------- ]]
function exsto.Net.WatchProcesses()
	if #exsto.Net.Running == 0 then return end
	if exsto.Variables and exsto.GetVar( "exsto_debug" ).Value < 1 then return end
	
	-- Make sure whatever Net process we are using is sending eventually.  For debugging purposes.
	for _, obj in ipairs( exsto.Net.Running ) do
		-- Check and make sure we were actually implemented into a util.AddNetworkString...
		if !table.HasValue( exsto.Net.NetworkStrings, obj.id ) and !table.HasValue( exsto.Net.NotifiedNetStrings, obj.id ) then exsto.ErrorNoHalt( "[NET] --> " .. obj.id .. " --> Not in networked string table.  Will not send to client!" ) table.insert( exsto.Net.NotifiedNetStrings, obj.id ) end;
		if obj.SendConfirmed then table.remove( exsto.Net.Running, _ ) return end
		if ( ( CurTime() - obj.StartTime ) > 5 ) and !obj.Checked then -- We're over our 5 second threshold.  Notify that this net push didn't go through.
			exsto.ErrorNoHalt( "[NET] --> " .. obj.id .. " --> Hasn't finalized a send in 5 seconds.  Check this out!" )
			obj.Checked = true
		end
	end
end
--hook.Add( "Think", "ExNetRunningWatch", exsto.Net.WatchProcesses )

if SERVER then
	-- We need to set ALL of our networked strings for the core HERE.
	for _, id in ipairs( exsto.Net.NetworkStrings ) do
		util.AddNetworkString( id )
	end
	
	function exsto.InitializeClient( reader )
		local ply = reader:ReadSender()
		
		exsto.Debug( "Player '" .. ply:Nick() .. "' ready for clientside load.", 1 )
		hook.Call( "ExClientLoading", nil, ply )
	end
	exsto.CreateReader( "ExClientLoad", exsto.InitializeClient )
	
	function exsto.ClientReady( reader )
		local ply = reader:ReadSender()
		
		exsto.Debug( "Player '" .. ply:Nick() .. "' has finished load.", 1 )
		hook.Call( "ExClientPluginsReady", nil, ply )
	end
	exsto.CreateReader( "ExClientReady", exsto.ClientReady )
	
--[[-----------------------------------
	Function: exsto.SendRankErrors
	Description: Sends the rank errors to the client.
    ----------------------------------- ]]
	function exsto.SendRankErrors( ply )
		for id, data in pairs( exsto.aLoader.Errors ) do
			local sender = exsto.CreateSender( "ExRecRankErr", ply )
				sender:AddString( id )
				sender:AddShort( data )
			sender:Send()
		end
	end

--[[ -----------------------------------
	Function: exsto.SendFlags
	Description: Sends the flags table down to a client.
     ----------------------------------- ]]
	function exsto.SendFlags( ply )
		exsto.CreateSender( "ExClearFlags", ply ):Send()
		
		local sender = exsto.CreateSender( "ExRecFlags", ply )
			sender:AddShort( table.Count( exsto.Flags ) )
			for name, desc in pairs( exsto.Flags ) do
				sender:AddString( name )
				sender:AddString( desc )
			end
			sender:Send()
	end
	concommand.Add( "_ResendFlags", exsto.SendFlags )

--[[ -----------------------------------
	Function: exsto.SendRank
	Description: Sends a single rank down to the client.
     ----------------------------------- ]]
	function exsto.SendRank( ply, short )
		local rank = exsto.Ranks[ short ]

		local sender = exsto.CreateSender( "ExRecRank", ply )
			sender:AddString( short )
			sender:AddString( rank.Name )
			sender:AddString( rank.Parent )
			sender:AddShort( rank.Immunity )
			sender:AddColor( rank.Color )
			
			sender:AddTable( rank.FlagsAllow )
			sender:AddTable( rank.Inherit )
			
		sender:Send()
	end
	
--[[ -----------------------------------
	Function: exsto.SendRanks
	Description: Sends all ranks down to a player.
     ----------------------------------- ]]	
	function exsto.SendRanks( ply )
		exsto.CreateSender( "ExClearRanks", ply ):Send()
		for k,v in pairs( exsto.Ranks ) do
			exsto.SendRank( ply, k )
		end
		exsto.CreateSender( "ExReceivedRanks", ply ):Send()
	end
	
--[[ -----------------------------------
	Function: createFlagFromClient
	Description: Creates a flag from the client.
     ----------------------------------- ]]	
	local function createFlagFromClient( reader )
		local ply = reader:ReadSender()
		local flag = reader:ReadString()
		
		exsto.Debug( "Flags --> Creating '" .. flag .. "' from client '" .. ply:Nick() .. "'", 1 )
		--exsto.CreateFlag( flag, reader:ReadString() )
	end
	exsto.CreateReader( "ExCreateFlag", createFlagFromClient )
	
--[[ -----------------------------------
	Function: meta:Send
	Description: Sends data to a player object.
     ----------------------------------- ]]
	function exsto.Registry.Player:Send( name, ... )
		local sender = exsto.CreateSender( name, self )
			for _, var in ipairs( {...} ) do
				sender:AddVariable( var )
			end
			sender:Send()
	end
	
--[[-----------------------------------
	Function: meta:QuickSend
	Description: Sends a usermessage to a player with no data.
    ----------------------------------- ]]
	function exsto.Registry.Player:QuickSend( name )
		self:Send( name )
	end
	
end

if CLIENT then
	
--[[ -----------------------------------
		Rank Receiving UMSGS
     ----------------------------------- ]]
	local function receive( reader )
		local ID = reader:ReadString()
		exsto._TempRanks[ ID ] = {
			Name = reader:ReadString(),
			ID = ID,
			Parent = reader:ReadString(),
			Immunity = reader:ReadShort(),
			Color = reader:ReadColor(),
			FlagsAllow = reader:ReadTable(),
			Inherit = reader:ReadTable(),
		}
	end
	exsto.CreateReader( "ExRecRank", receive )

	function exsto.ReceiveRankErrors( reader )
		if !exsto.RankErrors then exsto.RankErrors = {} end
		exsto.RankErrors[ reader:ReadString() ] = reader:ReadShort()
	end
	exsto.CreateReader( "ExRecRankErr", exsto.ReceiveRankErrors )
	
	local function receive()
		-- Before we used to just make exsto.Ranks a new table.  Clients loading things during this time would error out.  Prevent it.
		exsto._TempRanks = {}
	end
	exsto.CreateReader( "ExClearRanks", receive )
	
	function exsto.ReceivedRanks()
		-- Finalize our table.
		exsto.Ranks = table.Copy( exsto._TempRanks )
		hook.Call( "ExReceivedRanks" )
	end
	exsto.CreateReader( "ExReceivedRanks", exsto.ReceivedRanks )
	
--[[ -----------------------------------
	Function: receive
	Description: Receives flag data from the server.
     ----------------------------------- ]]
	local function receive( reader )
		for I = 1, reader:ReadShort() do
			exsto.Flags[ reader:ReadString() ] = reader:ReadString()
		end
	end
	exsto.CreateReader( "ExRecFlags", receive )
	
	local function clear()
		exsto.Flags = {}
	end
	exsto.CreateReader( "ExClearFlags", clear )
	
--[[ -----------------------------------
	Function: receive
	Description: Receives the command data from server.
     ----------------------------------- ]]
	local function receive( reader )
		local id = reader:ReadString()
		
		if !exsto.Commands then exsto.Commands = {} end
		
		exsto.Commands[ id ] = {
			ID = id,
			Desc = reader:ReadString(),
			Category = reader:ReadString(),
			QuickMenu = reader:ReadBool(),
			CallerID = reader:ReadString()
		}

		exsto.Commands[ id ].Args = {}
		for I = 1, reader:ReadShort() do
			exsto.Commands[ id ].Args[ reader:ReadString() ] = reader:ReadString()
		end
		
		exsto.Commands[ id ].ReturnOrder = {}
		for I = 1, reader:ReadShort() do
			table.insert( exsto.Commands[ id ].ReturnOrder, reader:ReadString() )
		end
		
		exsto.Commands[ id ].Optional = {}
		for I = 1, reader:ReadShort() do
			exsto.Commands[ id ].Optional[ reader:ReadString() ] = reader:ReadVariable()
		end
		
		exsto.Commands[ id ].Console = {}
		for I = 1, reader:ReadShort() do
			table.insert( exsto.Commands[ id ].Console, reader:ReadString() )
		end
		
		exsto.Commands[ id ].Chat = {}
		for I = 1, reader:ReadShort() do
			table.insert( exsto.Commands[ id ].Chat, reader:ReadString() )
		end
		
		exsto.Commands[ id ].ExtraOptionals = {}
		for I = 1, reader:ReadShort() do
			local name = reader:ReadString()
			exsto.Commands[ id ].ExtraOptionals[ name ] = {}
			for I = 1, reader:ReadShort() do
				table.insert( exsto.Commands[ id ].ExtraOptionals[ name ], { Display = reader:ReadString(), Data = reader:ReadVariable() } )
			end
		end
		
		exsto.Commands[ id ].DisplayName = reader:ReadString()
		
		-- Legacy
		hook.Call( "exsto_ReceivedCommands" ) -- What uses this?
		
		hook.Call( "ExRecCommand", nil, exsto.Commands[ id ] )
		
	end
	exsto.CreateReader( "ExRecCommands", receive )
	
	local function receive( reader )
		local id = reader:ReadString()
		hook.Call( "ExDelCommand", nil, id )
		exsto.Commands[ id ] = nil
	end
	exsto.CreateReader( "ExDelCommand", receive )

end


