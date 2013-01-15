AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()
	self:SetModel( "" )
	self:DrawShadow( false )
end

function ENT:SetText( text )
	self:SetNWString( "Text", text )
end

function ENT:SetScale( int )
	self:SetNWInt( "scale", int )
end

local function getwide( ent )
	return ent:OBBMaxs().y + ( ent:OBBMins().y * -1 )
end

function ENT:SetPlaceObject( ent )
	self:SetNWInt( "wide", getwide( ent ) )
end