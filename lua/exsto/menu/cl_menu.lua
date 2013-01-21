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
	Exsto's Main Menu
	-- Designed for https://dl.dropbox.com/u/3913710/Prefan/exsto3.png
	-- Has multiple ways to get in, default page will be "quickmenu"
	-- Entire background is going to be a DPanel.  Center content will span a header down from top of the screen.
	-- Search bar will be on bottom, opens an omnibox with search results.
	-- Page will have a full screen access, from left to right, disregarding space from above.
]]

exsto.Menu = {
	Pages = {};
	OpenPages = {};
	Objects = {};
	PageWidth = ScrW();
	PageTall = ScrH() - 280;
	StartTime = 0;
	BottomPadding = 200;
}

local fontTbl = {
	font = "Arial",
	size = 0,
	weight = 530,
}
for I = 14, 128 do
	fontTbl.size = I;
	surface.CreateFont( "ExGenericTextMidBold" .. I, fontTbl );
end

--[[ -----------------------------------
	Function: exsto.Menu.Initialize
	Description: Initializes Exsto's Menu system.
	----------------------------------- ]]
function exsto.Menu.Initialize()
		
	-- Create the header to hold the Exsto logo and to provide paddding from everyting below.
	exsto.Menu.Objects.Header = exsto.CreatePanel( 0, 0, ScrW(), 80, nil, exsto.Menu.Objects.Content )
		exsto.Menu.Objects.Header.Paint = function() end
		
	-- Create Exsto's logo for the top right.
	--exsto.Menu.Objects.Logo = exsto.CreateImageButton( exsto.Menu.Objects.Header:GetWide() - 105, 20, 86, 37, "exstoLogo", exsto.Menu.Objects.Header )
		
	-- Create the default quick menu.
	exsto.Menu.QM = exsto.Menu.CreatePage( "quickmenu", exsto.InitQuickMenu )
		exsto.Menu.QM:SetTitle( "Quick Menu" )
		exsto.Menu.QM:Build()
		
	for I = 1, 3 do
		local pg = exsto.Menu.CreatePage( "Test_" .. I, function() end )
			pg:SetTitle( "Testing Page " .. I )
			pg:SetFrameSize( math.random( 100, 350 ), math.random( 100, 600 ) )
		pg:Build()
	end

end

function exsto.Menu.GetPages()
	return exsto.Menu.Pages
end

function exsto.Menu.OpenPage( obj ) -- I don't know if there is anything that we need to do.
	exsto.Menu.OpenPages[ obj:GetID() ] = obj
	obj:Showtime()
end

function exsto.Menu.GetPageByID( id )
	for _, obj in ipairs( exsto.Menu.Pages ) do
		if obj.ID == id then return obj end
	end
	return
end

function exsto.Menu.GetPageByKey( key )
	return exsto.Menu.Pages[ key ]
end

function exsto.Menu.Open()
	-- Read our window pos info
	local f = file.Read( "exsto_windows.txt", "DATA" )
	local posInfo = {}
	if f then 
		posInfo = von.deserialize( f )
	end
	
	if !exsto.Menu.QM then
		exsto.Menu.Initialize() 
	end
	
	exsto.Menu.StartTime = CurTime();
	exsto.Menu.QM:Showtime()
	exsto.QuickMenuReset( nil, true )
	
	-- Set the quick menu pos
	local qmpos = posInfo[ "quickmenu" ]
	if qmpos then
		exsto.Menu.QM:SetPos( qmpos.x, qmpos.y )
	end
	
	exsto.Menu.Objects.Header:SetVisible( true )
	
	-- Loop through all our active windows
	local pos
	for id, obj in pairs( exsto.Menu.OpenPages ) do
		obj:Showtime()
		
		pos = posInfo[ id ]
		if pos then
			obj:SetPos( pos.x, pos.y )
		end
	end
	
	-- Set mouse pos
	pos = posInfo[ "__MOUSE" ]
	if pos then
		gui.SetMousePos( pos.x, pos.y )
	end
	
	exsto.Menu._Opened = true
end

local temp, qx, qy, qw, qh = false
local function shit()
	if !exsto.Menu then return end
	-- Handling clicking outside the search box.
	if exsto.Menu.OpenLock == true and input.IsMouseDown( MOUSE_LEFT ) then
		local x, y = gui.MousePos()
		
		print( x, y )
		
		qx, qy = exsto.Menu.QM:GetPos()
		qw, qh = exsto.Menu.QM:GetSize()
		
		print( qx, qy, qw + qx, qh +qy )
		
		if ( x < qx or y < qy ) or ( x > ( qx + qw ) or y > ( qy + qh ) ) and !exsto.Menu._BindPressed then
			exsto.Menu.OpenLock = false
		end
	end
	
	if exsto.Menu.OpenLock == false and temp == true then
		exsto.Menu.Close()
		temp = false
	elseif exsto.Menu.OpenLock == true and temp == false then
		temp = true
	end
end
hook.Add( "Think", "WHYDOWEHAVETODOTHIS", shit )

function exsto.Menu.Close()
	if exsto.Menu.OpenLock then return end -- We're locked open.  Wait until this thing becomes false
	local posInfo = {}
	
	-- Throw in mouse info too.
	local mx, my = gui.MousePos()
	posInfo[ "__MOUSE" ] = {x=mx, y=my}
	
	local qmx, qmy = exsto.Menu.QM:GetPos()
		posInfo[ "quickmenu" ] = {x = qmx, y = qmy}
		
	exsto.Menu.QM:Backstage()
	
	exsto.Menu.Objects.Header:SetVisible( false )
	
	-- Loop through all our open pages.
	local _x, _y
	for id, obj in pairs( exsto.Menu.OpenPages ) do
		_x, _y = obj:GetPos()
		posInfo[ id ] = {x = _x, y = _y}
		
		obj:Backstage()
	end
	
	-- Save the position info
	file.Write( "exsto_windows.txt", von.serialize( posInfo ) )
	
	exsto.Menu._Opened = false
end

function exsto.Menu.Toggle()
	if exsto.Menu._Opened then exsto.Menu.Close() else exsto.Menu.Open() end
end

local function commandMenuHandler( reader )
	--hangdata.key = reader:ReadShort()
	--hangdata.rank = reader:ReadString()
	--hangdata.flagCount = reader:ReadShort()
	
	if exsto.Menu.Objects.Content and exsto.Menu.Objects.Content:IsVisible() then exsto.Menu.Close() return end
	
	exsto.Menu.Open()
end
--exsto.CreateReader( "ExOpenMenu", commandMenuHandler )

concommand.Add( "+ExQuick", function() exsto.Menu.Open() exsto.Menu._BindPressed = true end )
concommand.Add( "-ExQuick", function() exsto.Menu.Close() exsto.Menu._BindPressed = false end )
concommand.Add( "ExQuickToggle", function() exsto.Menu.Toggle() end )
