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
	obj:SetFrameSize( 267, 430 )
	obj:SetPanelStyle( "ExPanelScroller" )
	table.insert( exsto.Menu.Pages, obj )
	
	return obj
end

-- Returns page index in pages table.
function page:GetPageIndex()
	for _, obj in ipairs( exsto.Menu.Pages ) do
		if obj == self then return _ end
	end
	return nil
end

-- Returns page to the left of himself.
function page:GetLeftOf()
	local index = self:GetPageIndex()
	return ( index - 1 != 0 and exsto.Menu.Pages[ index - 1 ] ) or exsto.Menu.Pages[ #exsto.Menu.Pages ]
end

-- Returns page to the right of himself.
function page:GetRightOf()
	local index = self:GetPageIndex()
	return ( index + 1 <= #exsto.Menu.Pages and exsto.Menu.Pages[ index + 1 ] ) or exsto.Menu.Pages[ 1 ]
end

function page:SetBackFunction( func )
	if type( func ) != "function" then self:Error( "Back function supplied non-function!" ) return end
	
	self._BackFunction = func
end

function page:OnShowtime( func )
	if type( func ) != "function" then self:Error( "OnShowtime supplied non-function!" ) return end
	self._OnShowtime = func
end

function page:OnBackstage( func )
	if type( func ) != "function" then self:Error( "OnBackstage supplied non-function!" ) return end
	self._OnBackstage = func
end

function page:OnSearchTyped( func )
	if type( func ) != "function" then self:Error( "OnSearchTyped supplied non-function!" ) return end
	self._SearchOnTextChanged = func
end

function page:OnSearchEntered( func )
	if type( func ) != "function" then self:Error( "OnSearchEntered supplied non-function!" ) return end
	self._SearchOnEnter = func
end

function page:OnSearchClicked( func )
	if type( func ) != "function" then self:Error( "OnSearchClicked supplied non-function!" ) return end
	self._SearchDoClick = func
end

function page:SetSearchable( bool ) self._Searchable = bool end

function page:SetUnaccessable() self._Hide = true end

function page:SetTitle( title )
	self._Title = title
end

function page:SetIcon( icon )
	self._Icon = icon
end

function page:SetFrameSize( w, h )
	self._SizeW = w
	self._SizeH = h
end

function page:Backstage() -- Time to sleep him
	-- Leave to the right.  We should already be at 0, 0?
	self:SetPos( self:GetParent():GetWide() + 2, 0 )
	
	-- Hide the search.
	exsto.Menu.DisableSearch()
	
	-- Call OnBackstage
	if self._OnBackstage then self:_OnBackstage() end
end

function page:Showtime( noAnim ) -- Wake him up!
	-- Come in from the left!
	
	-- Set up our position for animations.
	self.Content.OldFuncs.SetPos( self.Content, -self:GetParent():GetWide() - 2, 0 )
	self.Content.Anims[ 1 ].Current = -self:GetParent():GetWide() - 2
	self.Content.Anims[ 1 ].Last = -self:GetParent():GetWide() - 2
	
	if not noAnim then
		self:SetPos( 0, 0 )
	end
	
	exsto.Menu.ActivePage = self;
	
	-- Call OnShowtime
	if self._OnShowtime then self:_OnShowtime() end
	
	-- Call search if required
	if self._Searchable then exsto.Menu.EnableSearch() end

end

function page:Build()
	self:CreateContentHolder()
	self:CallBuild()
end

function page:CallBuild()
	if !self._buildCallback then self:Error( "No build callback found!" ) return end
	
	local success, err = pcall( self._buildCallback, self.Content )
	if !success then
		self:Error( "Unable to build page: " .. err )
	end
end

function page:ShowClose( bool )
	self.Content:ShowCloseButton( bool )
end

function page:SetPanelStyle( stl )
	self._PanelStyle = stl
end

function page:CreateContentHolder()
	local h = exsto.Menu.FrameScroller:GetTall()
	if self._Searchable then h = h - 32 end
	
	self.Content = vgui.Create( self._PanelStyle, exsto.Menu.FrameScroller )
		self.Content:SetPos( -exsto.Menu.FrameScroller:GetWide() - 2, 0 )
		self.Content:SetSize( exsto.Menu.FrameScroller:GetWide(), h )
		self.Content:SetSkin( "Exsto" )

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
function page:GetSize() return self.Content:GetSize() end
function page:GetParent() return self.Content:GetParent() end
function page:IsValid() return self.Content:IsValid() end
function page:SetVisible( bool ) return self.Content:SetVisible( bool ) end
function page:MoveToFront() return self.Content:MoveToFront() end
function page:GetID() return self.ID end
function page:GetTitle() return self._Title or self:GetID() end

function page:EnableBack() exsto.Menu.EnableBackButton() end
function page:DisableBack() exsto.Menu.DisableBackButton() end