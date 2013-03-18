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
		FrameW = 268;
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
fontTbl.weight = 700
for I = 14, 128 do
	fontTbl.size = I;
	surface.CreateFont( "ExGenericText" .. I, fontTbl );
end
fontTbl.weight = 400
for I = 14, 128 do
	fontTbl.size = I;
	surface.CreateFont( "ExGenericTextNoBold" .. I, fontTbl );
end

--[[ -----------------------------------
	Function: exsto.Menu.Initialize
	Description: Initializes Exsto's Menu system.
	----------------------------------- ]]
function exsto.Menu.Initialize()
		
	-- Create the holding frame.  I'm excited!
	exsto.Menu.Frame = exsto.CreateFrame( 0, 0, exsto.Menu.Sizes.FrameW, exsto.Menu.Sizes.FrameH )
		exsto.Menu.Frame:SetSkin( "Exsto" )
		exsto.Menu.Frame:SetDeleteOnClose( false )
		exsto.Menu.Frame:SetDraggable( true )
		exsto.Menu.Frame:Center()
		exsto.Menu.Frame:ShowCloseButton( true )
		exsto.Menu.Frame.btnMinim:SetVisible( false )
		exsto.Menu.Frame.btnMaxim:SetVisible( false )
		exsto.Menu.Frame.btnClose.DoClick = function( btn )
			-- Remove ourself from the open pages.
			--exsto.Menu.OpenPages[ self:GetID() ] = nil;
			--btn:GetParent():Close()
			exsto.Menu.Close()
		end
		
	-- Our amazing logo.
	-- TODO: Lets have this be our close button :0
	exsto.Menu.Logo = vgui.Create( "DImage", exsto.Menu.Frame )
		exsto.Menu.Logo:SetPos( exsto.Menu.Frame:GetWide() - 129, 1 )
		exsto.Menu.Logo:SetSize( 128, 32 )
		exsto.Menu.Logo:SetImage( "exsto/exlogo_qmenu.png" )
		
	-- Create our scroller.
	exsto.Menu.FrameScroller = exsto.CreatePanel( 1, 28, exsto.Menu.Frame:GetWide() - 2, exsto.Menu.Frame:GetTall() - 29, nil, exsto.Menu.Frame )
		exsto.Menu.FrameScroller.Paint = function() end
		
	-- Create our buttons up top
	exsto.Menu.BackButton = exsto.CreateImageButton( 6, 4, 26, 26, "exsto/back_norm.png", exsto.Menu.Frame )
		exsto.Menu.BackButton._Disabled = true
		exsto.Menu.BackButton.DoClick = exsto.Menu.BackButtonClick
		
	-- Create the new panel button
	exsto.Menu.NewPage = exsto.CreateImageButton( 0, 4, 26, 26, "exsto/menu_highlight.png", exsto.Menu.Frame )
		exsto.Menu.NewPage:MoveRightOf( exsto.Menu.BackButton, 6 )
		exsto.Menu.NewPage.DoClick = exsto.Menu.NewPageClick
		exsto.Menu.NewPage.DoRightClick = exsto.Menu.NewPageRightClick
		
	-- Search!
	-- Create search box
	exsto.Menu.Search = exsto.CreateTextEntry( 4, exsto.Menu.Frame:GetTall() + 2, exsto.Menu.Frame:GetWide() - 8, 24, exsto.Menu.Frame )
		exsto.Menu.Search.OnTextChanged = exsto.Menu.SearchOnTextChanged
		exsto.Menu.Search.OnEnter = exsto.Menu.SearchOnEnter
		exsto.Menu.Search.DoClick = exsto.Menu.SearchDoClick
	exsto.Animations.CreateAnimation( exsto.Menu.Search )
		
	-- Create the default quick menu.
	exsto.Menu.QM = exsto.Menu.CreatePage( "quickmenu", exsto.InitQuickMenu )
		exsto.Menu.QM:SetTitle( "Quick Menu" )
		exsto.Menu.QM:SetPanelStyle( "DPanel" )
		exsto.Menu.QM:Build()
		
		-- Override our quick menu skin
		exsto.Menu.QM.Content:SetSkin( "ExstoQuick" )
		
	-- Now create our page icon list.
	exsto.Menu.PageList = exsto.Menu.CreatePage( "pagelist", exsto.InitPageList )
		exsto.Menu.PageList:SetTitle( "Pages" )
		exsto.Menu.PageList:SetUnaccessable()
		exsto.Menu.PageList:OnShowtime( exsto.BuildPageListIcons )
		--exsto.Menu.PageList:SetPanelStyle( "DPanel" )

	if exsto.Menu.LastRank != LocalPlayer():GetRank() then
		-- Finally, lets create these pages that we have, if they're not already created.
		for _, obj in ipairs( exsto.Menu.Pages ) do
			if obj:GetID() != "pagelist" and obj:GetID() != "quickmenu" then
				obj:Build()
			end
		end
		exsto.Menu.LastRank = LocalPlayer():GetRank()
	end
	
	exsto.Menu.PageList:Build() -- We should build after the pages are created so we can throw them into the list of things we need to show.

end

--[[
	** Searching Support **
]]

function exsto.Menu.EnableSearch()
	-- Move him out of hiding!
	exsto.Menu.Search:SetPos( 4, exsto.Menu.Frame:GetTall() - 28 )
	exsto.Menu.Search:SetEditable( true )
	exsto.Menu.Search._Disabled = false
end

function exsto.Menu.DisableSearch()
	exsto.Menu.Search:SetPos( 4, exsto.Menu.Frame:GetTall() + 2 )
	exsto.Menu.Search:SetEditable( false )
	exsto.Menu.Search._Disabled = true
	
	-- Clean it.
	exsto.Menu.Search:SetText( "" )
end

function exsto.Menu.SearchOnTextChanged( entry )
	-- Check stuff first.
	if entry._Disabled then return end
	if !exsto.Menu.ActivePage then return end
	
	local obj = exsto.Menu.ActivePage
	if !obj_SearchOnTextChanged then return end
	
	local succ, err = pcall( obj._SearchOnTextChanged, entry )
	if !succ then
		obj:Error( "Searching errored: " .. err )
		return
	end
end

function exsto.Menu.SearchOnEnter( entry )
	-- Check stuff first.
	if entry._Disabled then return end
	if !exsto.Menu.ActivePage then return end
	
	local obj = exsto.Menu.ActivePage
	if !obj._SearchOnEnter then return end
	
	local succ, err = pcall( obj._SearchOnEnter, entry )
	if !succ then
		obj:Error( "Searching errored: " .. err )
		return
	end
end

function exsto.Menu.SearchDoClick( entry )
	-- Check stuff first.
	if entry._Disabled then return end
	if !exsto.Menu.ActivePage then return end

	local obj = exsto.Menu.ActivePage
	if !obj._SearchDoClick then return end
	
	local succ, err = pcall( obj._SearchDoClick, entry )
	if !succ then
		obj:Error( "Searching errored: " .. err )
		return
	end
end

--[[
	** Back Button Controls **
]]

function exsto.Menu.BackButtonClick( btn )
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
	exsto.Menu.OpenPage( exsto.Menu.PageList )
end

function exsto.Menu.NewPageRightClick( btn )
	local lst = DermaMenu()
	local c = Color( 113, 113, 113, 255 )
	for _, obj in ipairs( exsto.Menu.Pages ) do
		if !obj._Hide then				
			if obj._Child then
				local sub = lst:AddSubMenu( obj:GetTitle() )
				local option = sub:AddOption( obj:GetTitle(), function() exsto.Menu.OpenPage( obj ) end )
					option:SetImage( obj:GetIcon() )
					option.m_Image:SetSize( 16, 16 )
					option.m_Image:SetImageColor( c ) 
					
				for _, child in ipairs( obj._Child ) do
					local option = sub:AddOption( child:GetTitle(), function() exsto.Menu.OpenPage( child ) end )
					option:SetImage( child:GetIcon() )
					option.m_Image:SetSize( 16, 16 )
					option.m_Image:SetImageColor( c ) 
				end
				
			else
				local option = lst:AddOption( obj:GetTitle(), function() exsto.Menu.OpenPage( obj ) end )
				option:SetImage( obj:GetIcon() )
				option.m_Image:SetSize( 16, 16 )
				option.m_Image:SetImageColor( c ) 
			end
		end
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
	if !LocalPlayer():IsAllowed( obj:GetID() ) then obj:Debug( "Denied access." ) return end
	
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
	** Text Entry Focus Handling **
	Thank the gods Garry decided to havea universal implementation I can slightly recreate.
]]

function exsto.Menu.HoldFocus( pnl )
	exsto.Menu.HoldingFocus = pnl
	exsto.Menu.Frame:SetKeyboardInputEnabled( true )
	exsto.Menu.OpenLock = true
end

function exsto.Menu.LoseFocus( pnl )
	if exsto.Menu.HoldingFocus != pnl then return end -- This isn't ours to mess with!
	
	exsto.Menu.Frame:SetKeyboardInputEnabled( false )
	exsto.Menu.OpenLock = false
end

local function keyboardFocusOn( pnl )
	exsto.Menu.HoldFocus( pnl )
end
hook.Add( "OnTextEntryGetFocus", "ExMenuTextFocus", keyboardFocusOn )

local function keyboardFocusOff( pnl )
	exsto.Menu.LoseFocus( pnl )
end
hook.Add( "OnTextEntryLoseFocus", "ExMenuTextFocusOff", keyboardFocusOff )

--[[
	** Menu open/close **
]]

function exsto.Menu.Open()
	-- Handle close if we're open.  We don't want to re-open it I guess.
	if exsto.Menu._Opened then
		exsto.Menu.Close()
		return
	end
	
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
	exsto.Menu.Frame:SetKeyboardInputEnabled( true )
	
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
--hook.Add( "Think", "WHYDOWEHAVETODOTHIS", shit )

function exsto.Menu.Close()
	if exsto.Menu.OpenLock == true then return end -- We're locked open.  Wait until this thing becomes false
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
	
	-- Backstage our open page.  Just for OnBackstage.
	exsto.Menu.ActivePage:Backstage()
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
