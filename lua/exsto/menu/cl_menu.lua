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
	ActivePage = nil;
	Objects = {};
	PageWidth = ScrW();
	PageTall = ScrH() - 280;
	StartTime = 0;
	BottomPadding = 200;
	Sizes = {
		FrameW = 267;
		FrameH = 450;
		PageW = 267;
		PageH = 430;
	};
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
		
	-- Create the holding frame.  I'm excited!
	exsto.Menu.Frame = exsto.CreateFrame( 0, 0, exsto.Menu.Sizes.FrameW, exsto.Menu.Sizes.FrameH )
		exsto.Menu.Frame:SetSkin( "ExstoQuick" )
		exsto.Menu.Frame:SetDeleteOnClose( false )
		exsto.Menu.Frame:SetDraggable( true )
		exsto.Menu.Frame:Center()
		exsto.Menu.Frame:ShowCloseButton( true )
		exsto.Menu.Frame.btnMinim:SetVisible( false )
		exsto.Menu.Frame.btnMaxim:SetVisible( false )
		exsto.Menu.Frame.btnClose.DoClick = function( btn )
			-- Remove ourself from the open pages.
			--exsto.Menu.OpenPages[ self:GetID() ] = nil;
			btn:GetParent():Close()
		end
		
	-- Our amazing logo.
	-- TODO: Lets have this be our close button :0
	exsto.Menu.Logo = vgui.Create( "DImage", exsto.Menu.Frame )
		exsto.Menu.Logo:SetPos( exsto.Menu.Frame:GetWide() - 129, 1 )
		exsto.Menu.Logo:SetSize( 128, 32 )
		exsto.Menu.Logo:SetImage( "exsto/exlogo_qmenu.png" )
		
	-- Create our scroller.
	exsto.Menu.FrameScroller = exsto.CreatePanel( 1, 28, exsto.Menu.Sizes.PageW - 2, exsto.Menu.Sizes.PageH, nil, exsto.Menu.Frame )
		
	-- Create our buttons up top
	exsto.Menu.BackButton = exsto.CreateImageButton( 6, 4, 32, 32, "exsto/back_norm.png", exsto.Menu.Frame )
		exsto.Menu.BackButton._Disabled = true
		exsto.Menu.BackButton.DoClick = exsto.Menu.BackButtonClick
		
	-- Create the new panel button
	exsto.Menu.NewPage = exsto.CreateButton( 0, 0, 26, 20, "+", exsto.Menu.Frame )
		exsto.Menu.NewPage:MoveRightOf( exsto.Menu.BackButton, 6 )
		exsto.Menu.NewPage.DoClick = exsto.Menu.NewPageClick
		exsto.Menu.NewPage.DoRightClick = exsto.Menu.NewPageRightClick
		
	-- Create the default quick menu.
	exsto.Menu.QM = exsto.Menu.CreatePage( "quickmenu", exsto.InitQuickMenu )
		exsto.Menu.QM:SetTitle( "Quick Menu" )
		exsto.Menu.QM:Build()
		
	-- Now create our page icon list.
	exsto.Menu.PageList = exsto.Menu.CreatePage( "pagelist", exsto.InitPageList )
		exsto.Menu.PageList:SetTitle( "Pages" )
		exsto.Menu.PageList:Build()
		
	for I = 1, 3 do
		local pg = exsto.Menu.CreatePage( "Test_" .. I, function( pnl ) exsto.CreateLabel( 10, 40, ":)", "ExGenericText30", pnl ) end )
			pg:SetTitle( "Testing Page " .. I )	
		pg:Build()
	end

end

--[[
	** Back Button Controls **
]]

function exsto.Menu.BackButtonClick( btn )
	-- TODO: Per-page implementation of back button.
	if btn._Disabled then return end -- Don't do anything if we're disabled.
	if !exsto.Menu.ActivePage then return end -- What.
	
	local obj = exsto.Menu.ActivePage
	
	local succ, err = pcall( obj._BackFunction, btn )
	if !succ then
		obj:Error( "Back button errored: " .. err )
		return
	end
end

function exsto.Menu.DisableBackButton()
	exsto.Menu.BackButton._Disabled = true
	exsto.Menu.BackButton:SetImage( "exsto/back_norm.png" )
end

function exsto.Menu.EnableBackButton()
	exsto.Menu.BackButton._Disabled = false
	exsto.Menu.BackButton:SetImage( "exsto/back_highlight.png" )
end

--[[
	** New Page Controls **
]]

function exsto.Menu.NewPageClick( btn )
	-- Always go to the new page list.  No matter what?
end

function exsto.Menu.NewPageRightClick( btn )
	local lst = DermaMenu()
	for _, obj in ipairs( exsto.Menu.Pages ) do
		lst:AddOption( obj:GetTitle(), function() exsto.Menu.OpenPage( obj ) end )
	end
	lst:Open()
end

--[[
	** Utilities **
]]

function exsto.Menu.GetPages()
	return exsto.Menu.Pages
end

function exsto.Menu.OpenPage( obj ) -- I don't know if there is anything that we need to do.
	-- Slide our old page to the right, new comes in the left.
	if exsto.Menu.ActivePage and exsto.Menu.ActivePage:IsValid() then
		exsto.Menu.ActivePage:Backstage()
	end
	
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

--[[
	** Menu open/close **
]]

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
	
	exsto.Menu.Frame:MakePopup()
	exsto.Menu.Frame:SetVisible( true )
	
	exsto.Menu.StartTime = CurTime();
	exsto.Menu.OpenPage( exsto.Menu.GetPageByID( "quickmenu" ) )

	-- Set our window pos.
	local qmpos = posInfo[ "menu" ]
	if qmpos then
		exsto.Menu.Frame:SetPos( qmpos.x, qmpos.y )
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

		qx, qy = exsto.Menu.QM:GetPos()
		qw, qh = exsto.Menu.QM:GetSize()

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
	
	local qmx, qmy = exsto.Menu.Frame:GetPos()
		posInfo[ "menu" ] = {x = qmx, y = qmy}
		
	-- Save the position info
	file.Write( "exsto_windows.txt", von.serialize( posInfo ) )
	
	exsto.Menu.Frame:Close()
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
