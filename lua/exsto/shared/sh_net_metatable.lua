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

-- Data sender stuff.
local sender = {}
	sender.__index = sender

--[[ -----------------------------------
Function: exsto.CreateSender
Description: Creates a sender object to work and send data to a client.
 ----------------------------------- ]]	
function exsto.CreateSender( id, filter )
	local obj = {}
	setmetatable( obj, sender )
	
	obj.id = id or ""
	
	obj:SetFilter( filter )
	
	obj.StartTime = CurTime()
	table.insert( exsto.Net.Running, obj )
	
	return obj
end

function sender:SetID( id )
	self.id = id
end

function sender:SetFilter( filter )
	local t = type( filter )
	if t == "CRecipientFilter" then
		exsto.Error( "NET --> Attempted to send net data '" .. self.id or "UNKNOWN" .. "' to a CRecipientFilter!  No longer supported!" )
		return false
	else
		if t == "Player" and filter:IsValid() or t == "table" then
			self.filter = filter
		elseif t == "string" and filter == "all" then
			self.filter = player.GetAll()
		end
	end
	
	if !self.filter and !CLIENT then
		exsto.Error( "NET --> Attempted to send net data '" .. self.id or "UNKNOWN" .. "' to an invalid filter!" )
		return false
	end

	local succ, err = pcall( net.Start, self.id )
	if !succ then -- Assume we aren't in the util.AddNetworkString
		exsto.ErrorNoHalt( "NET --> " .. self.id .. " --> Network name not called in util.AddNetworkString().  Unable to send." )
	end

end

function sender:AddBit( b ) net.WriteBit( b ) end
function sender:AddChar( char ) net.WriteFloat( char ) end
function sender:AddString( str ) net.WriteString( tostring( str ) ) end
function sender:AddLong( num ) net.WriteDouble( num ) end
function sender:AddShort( num ) net.WriteFloat( num ) end
function sender:AddBoolean( bool ) net.WriteBit( tobool( bool ) ) end
sender.AddBool = sender.AddBoolean
function sender:AddEntity( ent ) net.WriteEntity( ent ) end
function sender:AddColor( col ) net.WriteTable( col ) end
function sender:AddTable( tbl ) net.WriteTable( tbl ) end
function sender:AddAngle( ang ) net.WriteAngle( ang ) end
function sender:AddVector( vec ) net.WriteVector( vec ) end

function sender:AddVariable( var )
	local t = type( var )
	if t == "number" then
		self:AddChar( 1 )
		self:AddShort( var )
	elseif t == "string" then
		self:AddChar( 2 )
		self:AddString( var )
	elseif t == "boolean" then
		self:AddChar( 3 )
		self:AddBool( var )
	elseif t == "table" and var.r and var.g and var.b then
		self:AddChar( 4 )
		self:AddColor( var )
	elseif t == "Entity" or t == "Player" then
		self:AddChar( 5 )
		self:AddEntity( var )
	elseif t == "table" then
		self:AddChar( 6 )
		self:AddTable( var )
	elseif t == "nil" then
		self:AddChar( 0 )
	end
end

function sender:Send()
	if !self.filter and !CLIENT then exsto.ErrorNoHalt( "NET --> Attempting to send without a filter!" ) return end
	if !self.id then exsto.ErrorNoHalt( "NET --> Attempting to send without ID!" ) return end

	if SERVER then
		net.Send( self.filter )
	elseif CLIENT then net.SendToServer() end
	self.SendConfirmed = true
	hook.Call( "ExDataSend", nil, self.id, self.filter )
end

local reader = {}
	reader.__index = reader
function exsto.CreateReader( id, func )
	local obj = {}
	
	setmetatable( obj, reader )
	obj.id = id
	
	if type( func ) != "function" then return end
	obj.callback = function( l, p )
		obj._Sender = p
		obj._Len = l
		
		-- Do NOT run if our hook that we call returns false.
		if hook.Call( id, nil, obj ) != false then
			local success, err = pcall( func, obj, l, p )
			if !success then
				exsto.ErrorNoHalt( "NET --> Error with net parse: " .. err )
			end
		end
	end
	
	net.Receive( id, obj.callback )
	
	return obj
end

function reader:ReadBit() return net.ReadBit() end
function reader:ReadSender() return self._Sender end
function reader:ReadLength() return self._Len end
function reader:ReadChar() return net.ReadFloat() end
function reader:ReadBoolean() return tobool( net.ReadBit() ) end
reader.ReadBool = reader.ReadBoolean
function reader:ReadLong() return net.ReadDouble() end
function reader:ReadShort() return net.ReadFloat() end
function reader:ReadString() return net.ReadString() end
function reader:ReadColor() return net.ReadTable() end -- Might have to format as a color.
function reader:ReadTable() return net.ReadTable() end
function reader:ReadEntity() return net.ReadEntity() end
function reader:ReadVector() return net.ReadVector() end
function reader:ReadAngle() return net.ReadAngle() end

function reader:ReadVariable()
	local t = self:ReadChar()
	if t == 1 then -- short
		return self:ReadShort()
	elseif t == 2 then -- string
		return self:ReadString()
	elseif t == 3 then -- bool
		return self:ReadBool()
	elseif t == 4 then -- color
		return self:ReadColor()
	elseif t == 5 then -- ent
		return self:ReadEntity()
	elseif t == 6 then -- table
		return self:ReadTable()
	elseif t == 0 then -- nil
		return nil
	end
end

hook.Call( "ExNetworkingReady" )