--[[
	Exsto
	Copyright (C) 2013  Prefanatic

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

--[[
	Object-Oriented Menu Page Functions
	-- Designed for https://dl.dropbox.com/u/3913710/Prefan/exsto3.png
]]

local page = {}
	page.__index = page
	
--[[ -----------------------------------
	Function: exsto.Menu.CreatePage
	Description: Creates a page object for Exsto's Menu
	Inputs: ID --> Identifier string for exsto.Menu.Pages
			Func --> Function callback which creates the page's contents
	----------------------------------- ]]
function exsto.Menu.CreatePage( id, func )
	local obj = {}
	
	setmetatable( obj, page )
	
	obj.ID = id
	obj:SetBuildCallback( func )
	obj:SetFrameSize( 267, 450 )
	table.insert( exsto.Menu.Pages, obj )
	
	return obj
end

function page:SetTitle( title )
	self._Title = title
end

function page:SetFrameSize( w, h )
	self._SizeW = w
	self._SizeH = h
end

function page:Backstage() -- Time to sleep him
	self.Content:Close()
end

function page:Showtime() -- Wake him up!
	self.Content:MakePopup()
	self.Content:SetVisible( true )
	
	if !exsto.Menu.OpenPages[ self:GetID() ] then
		exsto.Menu.OpenPages[ self:GetID() ] = self
	end
end

function page:Build()
	self:CreateContentHolder()
	self:CallBuild()
end

function page:CallBuild()
	local success, err = pcall( self._buildCallback, self.Content )
	if !success then
		self:Error( "Unable to build page: " .. err )
	end
end

function page:ShowClose( bool )
	self.Content:ShowCloseButton( bool )
end

function page:CreateContentHolder()
	self.Content = exsto.CreateFrame( 0, 0, self._SizeW, self._SizeH )
		self.Content:SetSkin( "Exsto" ) -- Ahoy!
		self.Content:SetDeleteOnClose( false )
		self.Content:SetDraggable( true )
		self.Content:Center()
		self.Content:ShowCloseButton( true )
		
		self.Content.btnMinim:SetVisible( false )
		self.Content.btnMaxim:SetVisible( false )
		self.Content.btnClose.DoClick = function( btn )
			-- Remove ourself from the open pages.
			exsto.Menu.OpenPages[ self:GetID() ] = nil;
			btn:GetParent():Close()
		end
		
		-- But we don't want it open.
		self.Content:Close()
		
	exsto.Animations.CreateAnimation( self.Content )
end

function page:SetBuildCallback( func )
	if type( func ) != "function" then self:Print( "Invalid page builder function!") return end
	self._buildCallback = func
end

function page:Print( str )
	exsto.Print( exsto_CONSOLE, self.ID .. " --> " .. str )
end

function page:Error( str )
	exsto.ErrorNoHalt( self.ID .. " --> " .. str )
end

function page:SetPos( x, y ) return self.Content:SetPos( x, y ) end
function page:GetPos() return self.Content:GetPos() end
function page:SetSize( w, h ) return self.Content:SetSize( w, h ) end
function page:IsValid() return self.Content:IsValid() end
function page:SetVisible( bool ) return self.Content:SetVisible( bool ) end
function page:MoveToFront() return self.Content:MoveToFront() end
function page:GetID() return self.ID end
function page:GetTitle() return self._Title or self:GetID() end