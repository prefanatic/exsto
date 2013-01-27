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


-- Clientside Menu, with adding functions

Menu = {}
	Menu.List = {}
	Menu.ListIndex = {}
	Menu.CreatePages = {}
	Menu.BaseTitle = "Exsto / "
	Menu.NextPage = {}
	Menu.CurrentPage = {}
	Menu.DefaultPage = nil
	Menu.PreviousPage = {}
	Menu.SecondaryRequests = {}
	Menu.TabRequests = {}
	Menu.CurrentIndex = 1
	Menu.NotifyPanels = {}
	Menu.RefreshCommands = {}
	
surface.CreateFont( "exstoListColumn", { font = "Arial", size = 14, weight = 500 } )
surface.CreateFont( "exstoBottomTitleMenu", { font = "Arial", size = 26, weight = 700 } )
surface.CreateFont( "exstoSecondaryButtons", { font = "Arial", size =  18, weight = 700 } )
surface.CreateFont( "exstoButtons", { font = "Arial", size = 20, weight = 700 } )
surface.CreateFont( "exstoHelpTitle", { font = "Arial", size = 14, weight = 700 } )
surface.CreateFont( "exstoPlyColumn", { font = "Arial", size = 19, weight = 700 } )
surface.CreateFont( "exstoDataLines", { font = "Arial", size = 15, weight = 650 } )
surface.CreateFont( "exstoHeaderTitle", { font = "Arial", size = 21, weight = 500 } )
surface.CreateFont( "exstoArrows", { font = "Arial", size = 26, weight = 400 } )
surface.CreateFont( "exstoTutorialTitle", { font = "Arial", size = 46, weight = 400 } )
surface.CreateFont( "exstoTutorialContent", { font = "Arial", size = 40, weight = 400 } )
surface.CreateFont( "ExLoadingText", { font = "Arial", size = 16, weight = 700 } )
surface.CreateFont( "ExRankText", { font = "Arial", size = 18, weight = 550 } )

local fontTbl = {
	font = "Arial",
	size = 0,
	weight = 700,
}
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
	Function: exsto.Menu
	Description: Opens up the Exsto menu.
	----------------------------------- ]]
local hangdata = {
	key = nil,
	rank = nil,
	flagCount = nil,
	bindOpen = nil,
}

function exsto.Menu2( reader )
	hangdata.key = reader:ReadShort()
	hangdata.rank = reader:ReadString()
	hangdata.flagCount = reader:ReadShort()
	hangdata.bindOpen = reader:ReadBool()
	
	if Menu and Menu:IsValid() then Menu.Initialize( Menu, hangdata.key, hangdata.rank, hangdata.flagCount, hangdata.bindOpen ) return end
	
	print( "Received" )
	
	Menu._HANGING = true
end
exsto.CreateReader( "ExOpenMenu", exsto.Menu2 )

local function Hang()
	if Menu._HANGING then
		if !exsto.Ranks or table.Count( exsto.Ranks ) == 0 then return end
		Menu._HANGING = false
		Menu.Initialize( Menu, hangdata.key, hangdata.rank, hangdata.flagCount, hangdata.bindOpen )
		hook.Remove( "Think", "ExMenuHangThink" )
	end
end
hook.Add( "Think", "ExMenuHangThink", Hang )

local function toggleOpenMenu( ply, _, args )
	-- We need to ping the server for any new data possible.
	RunConsoleCommand( "_ExPingMenuData" )
end
concommand.Add( "+ExMenu", toggleOpenMenu )

local function toggleCloseMenu( ply, _, args )
	if !Menu or !Menu.Frame or !Menu.Frame.btnClose then return end
	
	-- Quick kill when using the quickmenu to prevent mouse from keeping eye movement.
	gui.EnableScreenClicker( false )
	Menu.Frame.btnClose.DoClick( Menu.Frame.btnClose )
end
concommand.Add( "-ExMenu", toggleCloseMenu )

function Menu:Refresh()

	-- Clean our old
	for short, data in pairs( Menu.List ) do
		if data.Panel:IsValid() then
			data.Panel:Remove()
		end
	end
	
	for short, obj in pairs( Menu.SecondaryRequests ) do
		if obj:IsValid() then 
			obj:Remove()
			self.SecondaryRequests[ short ] = nil
		end
	end
	
	for short, obj in pairs( Menu.TabRequests ) do
		if obj:IsValid() then 
			obj:Remove() 
			self.TabRequests[ short ] = nil
		end
	end
	
	Menu.ListIndex = {}
	Menu.DefaultPage = {}
	Menu.PreviousPage = {}
	Menu.CurrentPage = {}
	Menu.NextPage = {}
	Menu.DefaultPage = {}
	self.DefaultPage = nil
	
	Menu:BuildPages( Menu.LastRank, Menu.LastFlagCount )
end
concommand.Add( "ExMenuRefresh", Menu.Refresh )

function Menu:Initialize( key, rank, flagCount, bindOpen )
	Menu.AuthKey = key
	
	--print( bindOpen, "initialize" )
	print( key, rank, flagCount )

	-- If we are valid, just open up.
	if Menu:IsValid() then	
		print( "valid" )
		
		-- Wait, did we change ranks?
		if Menu.LastRank != rank then
			-- Oh god, update us.
			print( "wtf" )
			exsto.Print( exsto_DEBUG, "Menu --> Updating due to a rank change." )
			Menu.LastRank = rank
			Menu.LastFlagCount = flagCount
			self:Refresh()
		end
			
		Menu.Frame:SetVisible( true )
		Menu:BringBackSecondaries()
		Menu:BringBackNotify()
	else
		Menu.LastRank = LocalPlayer():GetRank()
		Menu.LastFlagCount = flagCount
		Menu:Create( rank, flagCount )
	end
	
	if bindOpen then Menu.Frame.btnClose:SetVisible( false ) else Menu.Frame.btnClose:SetVisible( true ) end
	
	if !file.Exists( "exsto_tmp/exsto_menu_opened.txt", "DATA" ) then
		-- Oh lordy, move him to the help page!
		file.CreateDir( "exsto_tmp" )
		file.Write( "exsto_tmp/exsto_menu_opened.txt", "1" )
		Menu:MoveToPage( "helppage" )
		Menu.CurrentPage.Panel:PushGeneric( "Hey!  This seems to be your first time with us.  Moving you to the Help Page." )
	end
end

function Menu:Create( rank, flagCount )

	self.Placement = {
		Main = {
			w = 600,
			h = 380,
		},
		Header = {
			h = 46,
		},
		Side = {
			w = 171,
			h = 345,
		},
		Content = {
			w = 600,
			h = 340,
		},
		Gap = 6,
	}
	
	self.Colors = {
		White = Color( 255, 255, 255, 200 ),
		Black = Color( 0, 0, 0, 0 ),
		HeaderExtendBar = Color( 226, 226, 226, 255 ),
		HeaderTitleText = Color( 103, 103, 103, 255 ),
		ArrowColor = Color( 74, 208, 254, 255 ),
		ColorPanelStandard = Color( 204, 204, 204, 51 ),
	}
	
	self:BuildMainFrame()
	self:BuildMainHeader()
	self:BuildMainContent()
	self:BuildPages( rank, flagCount )
	
	self.Frame:SetSkin( "Exsto" )
end

function Menu:IsValid()
	return self.Frame and self.Frame:IsValid()
end

function Menu:BuildMainFrame()
	
	self.Frame = exsto.CreateFrame( 0, 0, self.Placement.Main.w, self.Placement.Main.h, "", true, self.Colors.White )
	self.Frame:Center()
	self.Frame:SetDeleteOnClose( false )
	self.Frame:SetDraggable( false )
	self.Frame.btnClose.DoClick = function( self )
		self:GetParent():Close()
		
		-- Loop through secondaries and tabs.
		for short, obj in pairs( Menu.SecondaryRequests ) do
			if obj and obj:IsValid() then
				obj:SetVisible( false )
			end
		end
		
		for short, obj in pairs( Menu.TabRequests ) do
			if obj and obj:IsValid() then
				obj:SetVisible( false )
			end
		end
		
		Menu:HideNotify()
	end
	self.Frame.btnMaxim:SetVisible( false )
	self.Frame.btnMinim:SetVisible( false )
	
	-- Move the secondarys and tabs along with us.
	local think = self.Frame.Think
	self.Frame.Think = function( self )
		if think then think( self ) end
		
		if self.Dragging then
			self.OldX = self:GetPos()
			
			Menu:UpdateSecondariesPos()
		end
	end
	
	Menu:CreateAnimation( self.Frame )
	self.Frame:FadeOnVisible( true )
	self.Frame:SetFadeMul( 2 )	
	
end

function Menu:BuildMainHeader()

	self.Header = exsto.CreatePanel( 0, 0, self.Frame:GetWide() - 30, self.Placement.Header.h, self.Colors.Black, self.Frame )

	-- Logo
	self.Header.Logo = vgui.Create( "DImageButton", self.Header )
	self.Header.Logo:SetImage( "exsto/exstoLogo.png" )
	self.Header.Logo:SetSize( 86, 27 )
	self.Header.Logo:SetPos( 9, 9 )
	
	self.Header.Logo.DoClick = function()
		local list = DermaMenu()
		
		for _, data in pairs( Menu.List ) do
			list:AddOption( data.Title, function() Menu:MoveToPage( data.Short ) end )
		end
		list:Open()
	end
	
	self.Header.Title = exsto.CreateLabel( self.Header.Logo:GetWide() + 20, 17, "", "exstoHeaderTitle", self.Header )
		self.Header.Title:SetTextColor( self.Colors.HeaderTitleText )
	
	local function paint( self )
		draw.SimpleText( self.Text, "exstoArrows", self:GetWide() / 2, self:GetTall() / 2, Menu.Colors.ArrowColor, 1, 1 )
	end
	
	self.Header.MoveLeft = exsto.CreateButton( 0, 18, 20, 20, "", self.Header )
		self.Header.MoveLeft.Paint = paint
		self.Header.MoveLeft.DoClick = function( self )
			Menu:MoveToPage( Menu.PreviousPage.Short, false )
		end
	
	self.Header.MoveRight = exsto.CreateButton( 0, 18, 20, 20, "", self.Header )
		self.Header.MoveRight.Paint = paint
		self.Header.MoveRight.DoClick = function( self )
			Menu:MoveToPage( Menu.NextPage.Short, true )
		end
	
	self.Header.MoveLeft.Text = "<"
	self.Header.MoveRight.Text = ">"
	
	self.Header.ExtendBar = exsto.CreatePanel( 0, 20, 0, 1, self.Colors.HeaderExtendBar, self.Header )
	
	self.Header.Refresh = exsto.CreateButton( 0, 20, 14, 14, "", self.Header )
		self.Header.Refresh.Paint = function( self )
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.SetTexture( exsto.Textures.Refresh )
			surface.DrawTexturedRect( 0, 0, self:GetWide(), self:GetTall() )
		end
		self.Header.Refresh.DoClick = function( self )
			if self.Run then self.Run() end
		end
		self.Header.Refresh:SetVisible( false )
	
	self:SetTitle( "Loading" )

end

function Menu:BuildMainContent()
	self.Content = exsto.CreatePanel( 0, 46, self.Placement.Content.w, self.Placement.Content.h, self.Colors.Black, self.Frame )
end

function Menu:BuildTabMenu()
	local tab = exsto.CreatePanel( 0, 0, 174, 348 )
		tab:Gradient( true )
		tab:Center()
		tab:SetVisible( false )
		tab:SetSkin( "Exsto" )
		tab.actAsFrameMat = true
		
		Menu:CreateAnimation( tab )
		tab:FadeOnVisible( true )
		tab:SetPosMul( 2 )
		tab:SetFadeMul( 4 )

		tab.Pages = {}
		tab.Items = {}
		tab.Controls = exsto.CreatePanelList( 8.5, 10, tab:GetWide() - 17, tab:GetTall() - 20, 5, false, true, tab )
		tab.Controls.m_bBackground = false
		
		tab.SetListHeight = function( self, num )
			self.Controls:SetSize( self.Controls:GetWide(), num )
		end
		
		tab.GetListTall = function( self ) return self.Controls:GetTall() end
		tab.GetListWide = function( self ) return self.Controls:GetWide() end
		
		tab.SelectByID = function( self, id )
			for _, item in ipairs( self.Items ) do
				if item.ID and item.ID == id then
					item.Obj.DoClick( item.Obj )
				end
			end
		end
		
		tab.SelectByName = function( self, str )
			for _, item in ipairs( self.Items ) do
				if str == item.Name then
					item.Obj.DoClick( item.Obj )
				end
			end
		end
		
		tab.SelectByObject = function( self, obj )
			self.ActiveButton.isEnabled = false
			self.ActiveButton = obj
			obj.isEnabled = true
		end
		
		tab.CreateButton = function( self, name, _callback, id )
			local button = exsto.CreateButton( 0, 0, self:GetWide() - 40, 27, name )
				button:SetStyle( "secondary" )
				button:SetSkin( "Exsto" )
				
				local function callback( button )
					_callback( button )
					self:SelectByObject( button )
				end
				button.DoClick = callback
				
				self.Controls:AddItem( button )
				table.insert( self.Items, { Obj = button, Name = name, Callback = callback, ID = id } )
				
				if !self.Initialized then
					self.Initialized = true
					self.ActiveButton = button
					button.isEnabled = true
					callback( button )
				end
		end
		
		tab.CreatePage = function( self, page )
			local panel = exsto.CreatePanel( 0, 0, page:GetWide(), page:GetTall(), Menu.Colors.Black, page )
			Menu:CreateAnimation( panel )
			panel:FadeOnVisible( true )
			panel:SetFadeMul( 5 )
			return panel
		end
		
		tab.AddItem = function( self, name, page )
			local button = exsto.CreateButton( 0, 0, self:GetWide() - 40, 27, name )
			button:SetStyle( "secondary" )
			button:SetSkin( "Exsto" )
			button.DoClick = function( button )
			
				self.CurrentPage:SetVisible( false )
				page:SetVisible( true )
				self.ActiveButton.isEnabled = false
				
				self.CurrentPage = page
				self.ActiveButton = button
				button.isEnabled = true 
			end

			table.insert( self.Pages, page )
			self.Controls:AddItem( button )
			
			if !self.DefaultPage then
				self.CurrentPage = page
				self.DefaultPage = page
				self.ActiveButton = button
				button.isEnabled = true
				page:SetVisible( true )
				return
			end
			page:SetVisible( false )
		end
		
		tab.Clear = function( self )
			self.Controls:Clear()
			
			for _, page in ipairs( self.Pages ) do
				page:Remove()
			end
		end
		
		tab.Hide = function( self )
			self.Hidden = true
			self:SetVisible( false )
		end
		
		tab.Show = function( self )
			self.Hidden = false
			Menu:BringBackSecondaries()
		end
	
	return tab
end

function Menu:BuildSecondaryMenu()
	local secondary = exsto.CreatePanel( 0, 0, 174, 348 )
		secondary:Gradient( true )
		secondary:Center()
		secondary:SetVisible( false )
		secondary:SetSkin( "Exsto" )
		secondary.actAsFrameMat = true
		
		Menu:CreateAnimation( secondary )
		secondary:FadeOnVisible( true )
		secondary:SetPosMul( 2 )
		secondary:SetFadeMul( 4 )
		
		secondary.Hide = function( self )
			self.Hidden = true
			self:SetVisible( false )
		end
		
		secondary.Show = function( self )
			self.Hidden = false
			Menu:BringBackSecondaries()
		end

	return secondary
end

function Menu:UpdateSecondariesPos()

	local mainX, mainY = Menu.Frame:GetPos()
	local mainW, mainH = Menu.Frame:GetSize()

	if self.ActiveSecondary and self.ActiveSecondary:IsValid() then
		self.ActiveSecondary:SetPos( mainX + mainW + Menu.Placement.Gap, mainY + mainH - self.ActiveSecondary:GetTall() )
	end
	
	if self.ActiveTab and self.ActiveTab:IsValid() then		
		self.ActiveTab:SetPos( mainX - Menu.Placement.Gap - self.ActiveTab:GetWide(), mainY + mainH - self.ActiveTab:GetTall() )
	end
	
end

function Menu:HideSecondaries()

	local mainX, mainY = Menu.Frame:GetPos()
	local mainW, mainH = Menu.Frame:GetSize()

	if self.ActiveSecondary and self.ActiveSecondary:IsValid() then
		self.ActiveSecondary:SetPos( ( mainX + ( mainW / 2 ) ) - ( self.ActiveSecondary:GetWide() / 2 ), mainY + mainH - self.ActiveSecondary:GetTall() )
	end
	
	if self.ActiveTab and self.ActiveTab:IsValid() then		
		self.ActiveTab:SetPos( ( mainX + ( mainW / 2 ) ) - ( self.ActiveTab:GetWide() / 2 ), mainY + mainH - self.ActiveTab:GetTall() )
	end
	
end

function Menu:BringBackSecondaries()
	if self.ActiveSecondary then
		if !self.ActiveSecondary.Hidden and self.ActiveSecondary:IsValid() then
			self.ActiveSecondary:SetVisible( true )
		end
	end
	
	if self.ActiveTab then
		if !self.ActiveTab.Hidden and self.ActiveTab:IsValid() then
			self.ActiveTab:SetVisible( true )
		end
	end
	
	self:UpdateSecondariesPos()
end

function Menu:BringBackNotify()
	for _, obj in ipairs( self.NotifyPanels ) do
		obj.bar:SetVisible( true )
	end
end

function Menu:HideNotify()
	for _, obj in ipairs( self.NotifyPanels ) do
		obj.bar:SetVisible( false )
	end
end

function Menu:CreateColorPanel( x, y, w, h, page )

	local panel = exsto.CreatePanel( x, y, w, h, Color( 204, 204, 204, 51 ), page )
	
	self:CreateAnimation( panel )
	panel:SetPosMul( 1 )
	
	panel.Styles = {
		accept = Color( 0, 255, 24, 51 );
		deny = Color( 255, 0, 0, 51 );
		neutral = Color( 204, 204, 204, 51 ) ;
		blue = Color( 0, 153, 176, 51 );
	}
	
	panel.AbideStyle = function( self, style )
		if self:GetStyle() == style then return end
		self.Style = style
		self:SetColor( self.Styles[ style ] )
	end
	
	panel.Accept = function( self )
		self:AbideStyle( "accept" )
	end
	
	panel.Deny = function( self )
		self:AbideStyle( "deny" )
	end
	
	panel.Neutral = function( self )
		self:AbideStyle( self.DefaultStyle or "neutral" )
	end
	
	panel.Blue = function( self )
		self:AbideStyle( "blue" )
	end
	
	panel.LockDefault = function( self, default )
		self.DefaultStyle = default
	end
	
	panel.GetStyle = function( self )
		return self.Style
	end
	
	return panel
	
end

local function storeOldFunctions( obj )
	local getPos = obj.GetPos
	local setPos = obj.SetPos
	local setAlpha = obj.SetAlpha
	local setVisible = obj.SetVisible
	
	obj.OldFuncs = {
		GetPos = getPos;
		SetPos = setPos; 
		SetX = function( obj, x ) obj.OldFuncs.SetPos( obj, x, obj.Anims[ 2 ].Last or obj.OldFuncs.GetPos[2] or 0 ) end;
		SetY = function( obj, y ) obj.OldFuncs.SetPos( obj, obj.Anims[ 1 ].Last or obj.OldFuncs.GetPos[1] or 0, y ) end;
		
		SetVisible = setVisible;
		SetAlpha = function( obj, alpha ) 
			setAlpha( obj, alpha ) 
			setVisible( obj, alpha >= 5 ) 
		end;
	
		SetColor = function( obj, color ) obj.m_bgColor = color end;
		SetRed = function( obj, red ) obj.m_bgColor.r = red end;
		SetGreen = function( obj, green ) obj.m_bgColor.g = green end;
		SetBlue = function( obj, blue ) obj.m_bgColor.b = blue end;
		SetAlphaBG = function( obj, alpha ) obj.m_bgColor.a = alpha end;
	}
end

local function buildAnimTable( obj )
	local x, y = obj:GetPos()
	obj.Anims[ 1 ] = {
		Current = x,
		Last = x,
		Mul = 2,
		Call = "SetX",
	}
	
	obj.Anims[ 2 ] = {
		Current = y,
		Last = y,
		Mul = 2,
		Call = "SetY",
	}

	-- Alpha.
	obj.Anims[ 3 ] = {
		Current = 255,
		Last = 255,
		Mul = 4,
		Call = "SetAlpha"
	}
	
	local col = obj.m_bgColor
	if col then
		-- Color Object
		obj.Anims[ 4 ] = {
			Current = col.r,
			Last = col.r,
			Mul = 4,
			Call = "SetRed"
		}
		obj.Anims[ 5 ] = {
			Current = col.g,
			Last = col.g,
			Mul = 4,
			Call = "SetGreen"
		}
		obj.Anims[ 6 ] = {
			Current = col.b,
			Last = col.b,
			Mul = 4,
			Call = "SetBlue"
		}
		obj.Anims[ 7 ] = {
			Current = col.a,
			Last = col.a,
			Mul = 4,
			Call = "SetAlphaBG"
		}
	end
end

local function createOverrides( obj )
	-- General
	obj.SetPosMul = function( obj, mul )
		obj.Anims[1].Mul = mul
		obj.Anims[2].Mul = mul
	end
	
	obj.SetFadeMul = function( obj, mul ) obj.Anims[3].Mul = mul end
	
	obj.SetColorMul = function( obj, mul )
		for I = 4, 7 do
			obj.Anims[ I ].Mul = mul
		end
	end
	
	obj.DisableAnims = function( obj ) self.Anims.Disabled = true end
	obj.EnableAnims = function( obj ) self.Anims.Disabled = false end
	
	-- Positions
	obj.GetPos = function( obj ) return obj.Anims[ 1 ].Last or 0, obj.Anims[ 2 ].Last or 0 end
	obj.SetPos = function( obj, x, y ) 
		obj.Anims[1].Current = x
		obj.Anims[2].Current = y 
	end
	
	-- Fading
	obj.FadeOnVisible = function( obj, bool ) obj.fadeOnVisible = bool end
	obj.SetFadeMul = function( obj, mul ) obj.Anims[3].Mul = mul end
	
	obj.SetAlpha = function( obj, alpha ) obj.Anims[3].Current = alpha end
	
	obj.SetVisible = function( obj, bool )
		if obj.fadeOnVisible then
			if bool == true then
				obj.SetAlpha( obj, 255 )
				obj.Anims[3].Last = 10
				obj.OldFuncs.SetAlpha( obj, 10 )
			else
				obj.SetAlpha( obj, 0 )
			end
		else
			obj.OldFuncs.SetVisible( obj, bool )
		end
	end
	
	-- Color
	obj.SetColor = function( obj, col )
		obj:SetRed( col.r )
		obj:SetGreen( col.g )
		obj:SetBlue( col.b )
		obj:SetAlpha2( col.a )
	end
	
	obj.SetRed = function( obj, r ) obj.Anims[4].Current = r end
	obj.SetGreen = function( obj, g ) obj.Anims[5].Current = g end
	obj.SetBlue = function( obj, b ) obj.Anims[6].Current = b end
	obj.SetAlpha2 = function( obj, a ) obj.Anims[7].Current = a end
	
end

function Menu:CreateAnimation( obj )
	obj.Anims = {}
	
	storeOldFunctions( obj )
	buildAnimTable( obj )
	createOverrides( obj )
	
	local think, dist, speed = obj.Think
	obj.Think = function( self )
		if think then think( self ) end
		
		for _, data in ipairs( self.Anims ) do
			if math.Round( data.Last ) != math.Round( data.Current ) then
				if self.Anims.Disabled then
					data.Last = data.Current
					data.Call( self, self.Anims[ _ ].Last )
				else
					dist = data.Current - data.Last
					speed = RealFrameTime() * ( dist / data.Mul  ) * 40

					self.Anims[ _ ].Last = math.Approach( data.Last, data.Current, speed )
					if self.OldFuncs[ data.Call ] then
						self.OldFuncs[ data.Call ]( self, self.Anims[ _ ].Last )
					else
						Error( "ExDerma --> Unknown animation callback '" .. tostring( data.Call ) .. "'" )
					end
				end
			end
		end
	end
	
end

--[[ -----------------------------------
	Function: Menu.CreateExtras
	Description: Creates the pages
	----------------------------------- ]]
function Menu:BuildPages( rank, flagCount )

	-- Protection against clientside hacks.  Kill if the server's flagcount for the rank is not the same as the clients
	local clientFlags = exsto.Ranks[ rank:lower() ]
	if #clientFlags.FlagsAllow != flagCount then return end

	surface.SetFont( "exstoPlyColumn" )
	
	-- Clean our old
	for short, data in pairs( self.List ) do
		if data.Panel:IsValid() then
			data.Panel:Remove()
		end
	end
	
	self.ListIndex = {}
	self.List = {}
	
	-- Loop through what we need to build.
	for _, data in ipairs( self.CreatePages ) do
		
		print( "on " .. data.Short )
		
		if table.HasValue( clientFlags.FlagsAllow, data.Short ) or rank == "srv_owner" then
			print( "going" )
	
			exsto.Print( exsto_CONSOLE_DEBUG, "MENU --> Creating page for " .. data.Title .. "!" )
			
			-- Call the build function.
			local page = data.Function( self.Content )
			
			-- Insert his data into the list.
			self:AddToList( data, page )
			
			-- Are we the default?  Set us up as visible
			if data.Default then
				self.List[ data.Short ].Panel:SetVisible( true )
			end
		
		end
		
	end
	
	-- If he can't see any pages, why bother?
	if #self.ListIndex == 0 then
		self:SetTitle( "There are no pages for you to view!" )
		return false
	end
	
	-- Set our current page and the ones near us.
	for index, short in ipairs( self.ListIndex ) do
		print( "looping " .. short )
		if self.List[ short ] then
			-- Hes a default, set him up as our first selection.
			if self.List[ short ].Default then
				self:MoveToPage( short )
				self.DefaultPage = self.CurrentPage
				self.DefaultPage.Panel:SetVisible( true )
			else
				self:GetPageData( index ).Panel:SetVisible( false )
			end
		end
	end
	
	-- If there still isn't any default, set the default as the first index.
	if !self.DefaultPage then
		print( "No defualt found" )
		self:MoveToPage( self.ListIndex[ 1 ] )
		self.DefaultPage = self.CurrentPage
		self.DefaultPage.Panel:SetVisible( true )
	end

end

--[[ -----------------------------------
	Function: Menu.AddToList
	Description: Adds a page to the menu list.
	----------------------------------- ]]
function Menu:AddToList( info, panel )
	self.List[info.Short] = {
		Title = info.Title,
		Short = info.Short,
		Default = info.Default,
		Flag = info.Flag,
		Panel = panel,
	}
	
	-- Create an indexed list of the pages.
	table.insert( self.ListIndex, info.Short )
end

--[[ ----------------------------------- 
	Function: Menu:GetPageData
	Description: Grabs page data from the index.
	----------------------------------- ]]
function Menu:GetPageData( index )
	local short = self.ListIndex[ index ]
	if !short then return nil end
	return self.List[ short ]
end

--[[ ----------------------------------- 
	Function: Menu:SetTitle
	Description: Sets the menu title.
	----------------------------------- ]]
function Menu:SetTitle( text )
	self.Header.Title:SetText( text )
	self.Header.Title:SizeToContents()
	
	local start = self.Header.Logo:GetWide() + self.Header.Title:GetWide() + 34
	local refFunc = self:GetPageData( self.CurrentIndex )
		if type( refFunc ) == "table" then refFunc = self.RefreshCommands[ refFunc.Short ] end
	self.Header.ExtendBar:SetPos( start, 27 )
	self.Header.ExtendBar:SetWide( self.Header:GetWide() - start - ( type( refFunc ) != "function" and 60 or 79 ) )

	if type( refFunc ) == "function" then -- Set us!
		self.Header.Refresh:MoveRightOf( self.Header.ExtendBar, 10 )
		self.Header.Refresh.Run = refFunc
		self.Header.MoveLeft:MoveRightOf( self.Header.Refresh, 5 )	
		
		self.Header.Refresh:SetVisible( true )
	else
		self.Header.MoveLeft:MoveRightOf( self.Header.ExtendBar, 10 )
		self.Header.Refresh:SetVisible( false )
	end
	
	self.Header.MoveRight:MoveRightOf( self.Header.MoveLeft, 5 )
	
end

--[[ ----------------------------------- 
	Function: Menu:CreateDialog
	Description: Creates a small notification dialog.
	----------------------------------- ]]
function Menu:CreateDialog()
	self.Dialog = {}
		self.Dialog.Queue = {}
		self.Dialog.Active = false
		self.Dialog.IsLoading = false
	
	self.Dialog.BG = exsto.CreatePanel( 0, 0, self.Frame:GetWide(), self.Frame:GetTall(), Color( 0, 0, 0, 190 ), self.Frame )
		self.Dialog.BG:SetVisible( false )
		local id = surface.GetTextureID( "gui/center_gradient" )
		self.Dialog.BG.Paint = function( self )
			surface.SetDrawColor( 0, 0, 0, 190 )
			surface.SetTexture( id )
			surface.DrawTexturedRect( 0, 0, self:GetWide(), self:GetTall() )
		end
		
	local w, h = surface.GetTextureSize( surface.GetTextureID( "exsto/loading.png" ) )
	self.Dialog.Anim = exsto.CreateImage( 0, 0, w, h, "loading.png", self.Dialog.BG )
		self.Dialog.Anim:SetKeepAspect( true )
		
	self.Dialog.Msg = exsto.CreateLabel( 20, self.Dialog.Anim:GetTall() + 40, "", "exstoBottomTitleMenu", self.Dialog.BG )
		self.Dialog.Msg:DockMargin( ( self.Dialog.BG:GetWide() / 2 ) - 200, self.Dialog.Anim:GetTall() + 40, ( self.Dialog.BG:GetWide() / 2 ) - 200, 0 )
		self.Dialog.Msg:Dock( FILL )
		self.Dialog.Msg:SetContentAlignment( 7 )
		self.Dialog.Msg:SetWrap( true )
		
	self.Dialog.Yes = exsto.CreateButton( ( self.Frame:GetWide() / 2 ) - 140, self.Dialog.BG:GetTall() - 50, 100, 40, "Yes", self.Dialog.BG )
		self.Dialog.Yes:SetStyle( "positive" )
		self.Dialog.Yes.OnClick = function()
			if self.Dialog.YesFunc then
				self.Dialog.YesFunc()
			end
			sef:CleanDialog()
		end
	
	self.Dialog.No = exsto.CreateButton( ( self.Frame:GetWide() / 2 ) + 40, self.Dialog.BG:GetTall() - 50, 100, 40, "No", self.Dialog.BG )
		self.Dialog.No:SetStyle( "negative" )
		self.Dialog.No.OnClick = function()
			if self.Dialog.NoFunc then
				self.Dialog.NoFunc()
			end
			self:CleanDialog()
		end
	
	self.Dialog.OK = exsto.CreateButton( ( self.Frame:GetWide() / 2 ) - 50, self.Dialog.BG:GetTall() - 50, 100, 40, "OK", self.Dialog.BG )
		self.Dialog.OK.OnClick = function()
			self:CleanDialog()
		end
		
	self:CleanDialog()
		
end
	
function Menu:CleanDialog()
	if !self.Dialog then return end
	
	Menu:BringBackSecondaries()
	
	self.Dialog.BG:SetVisible( false )
	self.Dialog.Msg:SetText( "" )
	self.Dialog.OK:SetVisible( false )
	self.Dialog.Yes:SetVisible( false )
	self.Dialog.No:SetVisible( false )
	
	self.Dialog.IsLoading = false
	self.Dialog.Active = false
	
	if self.Dialog.Queue[1] then
		local data = self.Dialog.Queue[1]
		self:PushGeneric( data.Text, data.Texture, data.Color, data.Type )
		table.remove( self.Dialog.Queue, 1 )
	end
end
	
--[[ ----------------------------------- 
	Function: Menu:PushLoad
	Description: Shows a loading screen.
	----------------------------------- ]]
function Menu:PushLoad()
	self:PushGeneric( "Loading...", nil, nil, "loading" )
	timer.Create( "exstoLoadTimeout", 10, 1, function() if Menu.Dialog.IsLoading then Menu:EndLoad() Menu:PushError( "Loading timed out!" ) end end )
end

function Menu:EndLoad()
	if !self.Frame then return end
	if !self.Dialog then return end
	if !self.Dialog.IsLoading then return end
	
	self:CleanDialog()
end

function Menu:PushError( msg )
	self:PushGeneric( msg, "exstoErrorAnim", Color( 176, 0, 0, 255 ), "error" )
end

function Menu:PushNotify( msg )
	self:PushGeneric( msg, nil, nil, "notify" )
end

function Menu:PushQuestion( msg, yesFunc, noFunc )
	self:PushGeneric( msg, nil, nil, "question" )
	self.Dialog.YesFunc = yesFunc
	self.Dialog.NoFunc = noFunc
end

function Menu:PushGeneric( msg, imgTexture, textCol, type )
	if !self.Dialog then
		self:CreateDialog()
	end
	
	if self.Dialog.Active and type != "loading" then
		table.insert( self.Dialog.Queue, {
			Text = msg, Texture = imgTexture, Color = textCol, Type = type }
		)
		return
	elseif self.Dialog.Active and type == "loading" then
		self:EndLoad()
	end
	
	Menu:HideSecondaries()
	
	self.Dialog.Active = true
	
	self.Dialog.Anim:SetImage( imgTexture or "exstoGenericAnim.png" )
	self.Dialog.Msg:SetText( msg )
	self.Dialog.Msg:SetTextColor( textCol or Color( 12, 176, 0, 255 ) )
	
	if type == "notify" or type == "error" then
		self.Dialog.OK:SetVisible( true )
	elseif type == "question" then
		self.Dialog.Yes:SetVisible( true )
		self.Dialog.No:SetVisible( true )
	elseif type == "input" then
		self.Dialog.OK:SetVisible( true )
		--self.Dialog.Input:SetVisible( true )
	elseif type == "loading" then
		self.Dialog.IsLoading = true
	end
	
	self.Dialog.BG:SetVisible( true )
end

--[[ -----------------------------------
	Function: Menu.CallServer
	Description: Calls a server function
	----------------------------------- ]]
function Menu.CallServer( command, ... )
	RunConsoleCommand( command, Menu.AuthKey, unpack( {...} ) )
end
	
--[[ -----------------------------------
	Function: Menu.GetPageIndex
	Description: Gets an index of a page.
	----------------------------------- ]]
function Menu:GetPageIndex( short )
	for k,v in pairs( Menu.ListIndex ) do
		if v == short then return k end
	end
end

function Menu:TuckExtras()
	if self.ActiveSecondary and self.ActiveSecondary:IsValid() then
		-- Tuck him away.
		self.ActiveSecondary:SetVisible( false )
		self.ActiveSecondary = nil
	end
	
	if self.ActiveTab and self.ActiveTab:IsValid() then
		self.ActiveTab:SetVisible( false )
		self.ActiveTab = nil
	end
end

function Menu:CheckRequests( short )
	-- Send our our requests
	local secondary = self.SecondaryRequests[ short ]
	if secondary then
		if !secondary.Hidden then secondary:SetVisible( true ) end
		self.ActiveSecondary = secondary
		self:UpdateSecondariesPos()
	end
	
	local tabs = self.TabRequests[ short ]
	if tabs then
		if !tabs.Hidden then tabs:SetVisible( true ) end
		self.ActiveTab = tabs
		self:UpdateSecondariesPos()
	end
end

--[[ -----------------------------------
	Function: Menu.MoveToPage
	Description: Moves to a page
	----------------------------------- ]]
function Menu:MoveToPage( short, right )

	local page = self.List[ short ]
	local index = self:GetPageIndex( short )
	
	if !short then exsto.ErrorNoHalt( "MENU --> Attempting to move to an unknown page.  The menu is most likely broken." ) return end
	if !index then exsto.ErrorNoHalt( "MENU --> Unable to get page index of '" .. short .. "'" ) return end
	if short == self.CurrentPage.Short then return end -- Why bother.
	
	local oldCurrent = self.CurrentPage.Panel
	local oldIndex = self.CurrentIndex
	
	self.PreviousPage = self.List[self.ListIndex[index - 1]] or self.List[self.ListIndex[#self.ListIndex]]
	self.CurrentPage = page
	self.NextPage = self.List[self.ListIndex[index + 1]] or self.List[self.ListIndex[1]]
	
	self.CurrentIndex = index
	
	self:SetTitle( self.CurrentPage.Title )
	
	self:HideSecondaries()
	self:TuckExtras()
	self:CheckRequests( short )

	if !oldCurrent then return end
	
	local oldW, oldH = oldCurrent:GetSize() 
	
	local startPos = oldW
	if oldIndex > self.CurrentIndex then startPos = -oldW end
	if oldIndex == #self.ListIndex and self.CurrentIndex == 1 then startPos = oldW end
	if self.CurrentIndex == #self.ListIndex and oldIndex == 1 then startPos = -oldW end

	self.CurrentPage.Panel:SetVisible( true ) -- Make him alive.
	
	self.CurrentPage.Panel.OldFuncs.SetPos( self.CurrentPage.Panel, startPos, 0 )
	self.CurrentPage.Panel.Anims[ 1 ].Last = startPos
	self.CurrentPage.Panel.Anims[ 1 ].Current = startPos
	self.CurrentPage.Panel:SetPos( 0, 0 )
	
	oldCurrent:SetPos( -startPos, 0 )

end

--[[ -----------------------------------
	Function: Menu:CalcFontSize
	Description: Calculates the best font to use in an area
	----------------------------------- ]]
function Menu:CalcFontSize( text, maxWidth, maxFont )
	for I = 14, maxFont do
		surface.SetFont( "ExGenericText" .. I )
		local w = surface.GetTextSize( text )
		
		if w > maxWidth then
			maxFont = math.Round( I - 3 )
			break
		end
	end
	return "ExGenericText" .. maxFont
end

--[[ -----------------------------------
	Function: Menu:ConstructBar
	Description: Constructs a notification bar for the menu
	----------------------------------- ]]
local function kill_refresh( bar )
	if bar and bar:IsValid() then bar:Remove() end
	Menu:InvalidateNotify()
end

function Menu:ConstructBar()
	local bar = exsto.CreatePanel( 0, 0, self.Frame:GetWide(), 23 )
		bar:Gradient( true )
		bar:SetSkin( "Exsto" )
		
		local x, y = self.Frame:GetPos()
		bar:SetPos( x, self.Frame:GetTall() + y - 40 )
		
		bar.PaintOver = function( bar )
			if !bar.PrintData then return end
			
			-- Drawing
			for _, line in ipairs( bar.PrintData.Text ) do
				draw.SimpleText( line, "ExGenericText18", 5, _ * 20, bar.PrintData.Color, 0, 4 )
			end
			
			-- Life Controls			
			if bar.PrintData.StartTime + bar.PrintData.LifeTime < CurTime() and !bar.PrintData.Dieing then
				for id, barData in ipairs( Menu.NotifyPanels ) do
					if barData.id == tostring( bar ) then
						table.remove( Menu.NotifyPanels, id )
						break
					end
				end

				bar.PrintData.Dieing = true
				
				bar:SetVisible( false )
				timer.Create( "NPREM_" .. tostring( bar ), 0.3, 1, function() kill_refresh( bar ) end )
			end
		end
	
	Menu:CreateAnimation( bar )
		bar:FadeOnVisible( true )
		bar:SetFadeMul( 2 )
		bar:SetPosMul( 3 )

	return bar
end

--[[ -----------------------------------
	Function: Menu:InvalidateNotify
	Description: Repositions all active notifications
	----------------------------------- ]]
function Menu:InvalidateNotify()
	local lastPos = 5
	local x, y = self.Frame:GetPos()
	
	for I = 1, #Menu.NotifyPanels do
		barData = Menu.NotifyPanels[ ( #Menu.NotifyPanels - I ) + 1 ]
		
		if barData.bar and barData.bar:IsValid() then
			barData.bar:SetPos( x, self.Frame:GetTall() + y + lastPos )
			lastPos = lastPos + barData.bar:GetTall() + 6
		end
	end
end

--[[ -----------------------------------
	Function: Menu:PushNotify
	Description: Pushes a notify into the Exsto notify menu stack
	----------------------------------- ]]
function Menu:PushNotify( text, online )
	local bar = Menu:ConstructBar()

	bar.PrintData = {
		Text = exsto.WordWrap( text, bar:GetWide(), "ExGenericText18" );
		Color = Color( 99, 99, 99, 255 );
		LifeTime = online or 5;
		StartTime = CurTime();
	}
	bar:SetTall( ( #bar.PrintData.Text * 20 ) + 4 )
	
	table.insert( Menu.NotifyPanels, { id = tostring( bar ), bar = bar } )
	bar:SetVisible( true )
	self:InvalidateNotify()
end

--[[ -----------------------------------
	Function: Menu:PushQuestion
	Description: Pushes a question and allows a set of answers to be returned
	----------------------------------- ]]
local function questPaint( self )
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.DrawRect( 0, 0, self:GetWide(), self:GetTall() )
	
	surface.SetDrawColor( 0, 0, 0, 255 )
	surface.DrawOutlinedRect( 0, 0, self:GetWide(), self:GetTall() )
	
	if self.buffer then
		for _, line in pairs( self.buffer ) do
			draw.SimpleText( line, "ExGenericText18", 5, _ * 20, self.textColor, 0, 4 )
		end
	end
end
	
function Menu:PushQuestion( question, qaData )
	-- Get our data that we need to construct
	surface.SetFont( "exstoButtons" )
	local totW = ( #qaData * 70 ) > 120 and ( #qaData * 70 ) or 120

	local tblBuffer = exsto.WordWrap( question, totW - 5, "ExGenericText18" )
	local totH = ( #tblBuffer * 20 ) + 40		
	
	-- Create our derma layout
	local bg = exsto.CreatePanel( 0, 0, self.Frame:GetWide(), self.Frame:GetTall(), Color( 0, 0, 0, 100 ), self.Frame )
	local box = exsto.CreatePanel( ( self.Frame:GetWide() / 2 ) - ( totW / 2 ), ( self.Frame:GetTall() / 2 ) - ( totH / 2 ), totW, totH, nil, bg )
		box.buffer = tblBuffer
		box.textColor = Color( 0, 0, 0, 255 )
		box.Paint = questPaint
		
	-- Create our buttons!
	local answers = {}
	for _, data in pairs( qaData ) do
		local obj = exsto.CreateButton( ( 65 * _ ) - 62, box:GetTall() - 40, 65, 37, data.Text, box )
		table.insert( answers, obj )
	end
end

concommand.Add( "pushlol", function() Menu:PushQuestion( "How many apples do I have?", { { Text = "10 Apples" }, { Text = "10000 Apples" }, { Text = "I have none lol" } } ) end )
--[[ -----------------------------------
	Function: Menu:CreatePage
	Description: Creates a menu page for the Exsto menu
	----------------------------------- ]]
local glow = surface.GetTextureID( "exsto/glow2" )
local loading = Material( "exsto/loading.png" )
function Menu:CreatePage( info, func )

	-- Create a build function
	local function buildPage( bg )
		-- Create the placement background.
		local page = exsto.CreatePanel( 0, 0, Menu.Placement.Content.w, Menu.Placement.Content.h - 6, Menu.Colors.Black, bg )
		page:SetVisible( false )
		Menu:CreateAnimation( page )
		page:SetPosMul( 2 )
		
		function page:SetRefresh( func )
			Menu.RefreshCommands[ info.Short ] = func
		end
		
		function page:Clean()
			for _, panel in ipairs( self.children ) do
				if panel:IsValid() then panel:Remove() end
			end
		end
		
		function page:RequestSecondary( force )
			--print( Menu.SecondaryRequests[ info.Short ] and Menu.SecondaryRequests[ info.Short ]:IsValid() )
			
			--if Menu.SecondaryRequests[ info.Short ] and Menu.SecondaryRequests[ info.Short ]:IsValid() then return Menu.SecondaryRequests[ info.Short ] end
			
			local secondary = Menu:BuildSecondaryMenu()
			Menu.SecondaryRequests[ info.Short ] = secondary
			
			if force then
				Menu.ActiveSecondary = secondary
			end
			return secondary
		end
		
		function page:RequestTabs( force )
			--if Menu.TabRequests[ info.Short ] then return Menu.TabRequests[ info.Short ] end
			
			local tabs = Menu:BuildTabMenu()
			Menu.TabRequests[ info.Short ] = tabs
			
			if force then
				Menu.ActiveTab = tabs
			end
			return tabs
		end
		
		page.ExNotify_Queue = {}
		function page:PushLoad()
			self.ExNotify_Active = true
			self.ExNotify_Loading = true
			self.ExNotify_Rotation = 0
		end
		
		function page:EndLoad()
			self.ExNotify_Active = false
			self.ExNotify_Loading = false
		end
		
		function page:PushQuestion( text, qaData )
			Menu:PushQuestion( text, qaData )
		end
		
		function page:PushGeneric( text, timeOnline, err )
			Menu:PushNotify( text, timeOnline )
		end
		
		function page:PushError( text, timeOnline )
			self:PushGeneric( text, timeOnline, true )
		end
		
		function page:DialogCleanup()
			self.ExNotify_Active = false
			self.ExNotify_Generic = false
			self.ExNotify_Loading = false
			self.ExNotify_Text = ""
			self.ExNotify_EndTime = false
			self.ExNotify_Error = false
			self.ExNotify_Alpha = 0
			
			local x, y = Menu.Frame:GetPos()
			self.ExNotify_Panel:SetPos( x, self:GetTall() - 40 + y )
			
			if self.ExNotify_Queue[1] then
				self:PushGeneric( self.ExNotify_Queue[1].Text, self.ExNotify_Queue[1].TimeOnline, self.ExNotify_Queue[1].Err )
				table.remove( self.ExNotify_Queue, 1 )
			end
		end
		
		page.Text_LoadingColor = Color( 0, 192, 10, 255 )
		page.Text_ErrorColor = Color( 192, 0, 10, 255 )
		page.Text_GenericColor = Color( 30, 30, 30, 255 )
		page.Text_OutlineColor = Color( 255, 255, 255, 255 )
		page.PaintOver = function( self )
			if self.ExNotify_Active then
				if self.ExNotify_Loading then
					surface.SetDrawColor( 255, 255, 255, 255 )
					--surface.SetTexture( glow )
					--surface.DrawTexturedRect( ( self:GetWide() / 2 ) - ( 512 / 2 ), ( self:GetTall() / 2 ) - ( 512 / 2 ), 512, 512 )
					
					self.ExNotify_Rotation = self.ExNotify_Rotation + 1
					surface.SetMaterial( loading )
					surface.DrawTexturedRectRotated( ( self:GetWide() / 2 ), ( self:GetTall() / 2 ), 128, 128, self.ExNotify_Rotation )
					
					draw.SimpleText( "Loading", "ExLoadingText", ( self:GetWide() / 2 ), ( self:GetTall() / 2 ), self.Text_LoadingColor, 1, 1 )
				elseif self.ExNotify_Generic then 
					if self.ExNotify_EndTime <= CurTime() then
						self:DialogCleanup()
						return
					end
				end
			end
		end
		
		local success, err = pcall( func, page )
		if !success then
			exsto.ErrorNoHalt( "MENU --> Error creating page '" .. info.Short .. "':\n" .. err )
		end
		return page
	end

	-- Insert data into a *to create* list.	
	table.insert( Menu.CreatePages, {
		Title = info.Title,
		Flag = info.Flag,
		Short = info.Short,
		Default = info.Default,
		Function = buildPage,
	} )
	
end