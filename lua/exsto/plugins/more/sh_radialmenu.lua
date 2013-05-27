-- Exsto

local PLUGIN = exsto.CreatePlugin()
	PLUGIN:SetInfo( {
		Name = "Radial Menu",
		ID = "exsto-radialmenu",
		Desc = "Radial Menu",
		Owner = "Prefanatic",
	} )


if SERVER then

elseif CLIENT then

	-- little function open our list :)
	concommand.Add( "+ExQuick", function()
		if !exsto.Ranks then print( "Ranks non-existant on client.  Please wait..." ) return end
		
		PLUGIN:Show()
	end )
	
	concommand.Add( "-ExQuick", function()
		PLUGIN:Hide()
	end )
	
	PLUGIN.TestingCommands = { "Kick", "Ban", "Rocket", "Rank", "Slap", "..." }
	
	function PLUGIN:LoadFavorites()
		self.Favorites = self.FavDB:GetAll()
	end
	
	function PLUGIN:SetFavorite( id )
		local tbl = { ID = id, NumUsed = 0 }
		table.insert( self.Favorites, tbl )
		return tbl
	end
	
	function PLUGIN:FindFavoriteKey( id )
		for _, data in ipairs( self.Favorites ) do
			if data.ID == id then return _ end
		end
		return
	end
	
	function PLUGIN:GetFavorite( id )
		return self.Favorites[ self:FindFavoriteKey( id ) ]
	end
	
	function PLUGIN:AddUseCount( id )
		local fav = self:GetFavorite( id )
		if !fav then self:SetFavorite( id ) end
		
		fav.NumUsed = fav.NumUsed + 1
	end
	
	function PLUGIN:SetPriority( id, b )
		self:GetFavorite( id ).Priority = true
	end
	
	function PLUGIN:SaveFavorite( fav )
		self.FavDB:AddRow( {
			ID = fav.ID;
			Priority = fav.Priority;
			NumUsed = fav.NumUsed;
		} )
	end
	
	function PLUGIN:SaveFavorites()
		for _, fav in ipairs( self.Favorites ) do
			self:SaveFavorite( fav )
		end
	end
	
	function PLUGIN:ClickCommand( id )
		self.ContentPanel.DisableMouseThinking = true
		self.ComWindow:Populate( exsto.Commands[ id ] or id ) -- Simple way to send ... to create the command list
		
		self.ComWindow:SetPos( ( ScrW() / 2 ) - ( self.ComWindow:GetWide() / 2 ), ( ScrH() / 2 ) - ( self.ComWindow:GetTall() / 2 ) )
		self.ComWindow:SetVisible( true )
		self.ContentPanel:SetVisible( false )
	end
	
	function PLUGIN:Execute()
		local command = exsto.Commands[ self.ContentPanel.SelectedItem ]
		RunConsoleCommand( command.CallerID, unpack( self.ComWindow.ExecuteInfo ) )
		PrintTable( self.ComWindow.ExecuteInfo )
		
		--self:AddUseCount( self.ContentPanel.SelectedItem )
		self:Hide()
	end
	
	function PLUGIN:CreateCommandWindow()
		-- Create the command window.
		
		local centerX = ScrW() / 2
		local centerY = ScrH() / 2
		
		self.ComWindow = exsto.CreatePanel( centerX - 100, centerY + 50, 200, 100, Color( 255, 255, 255, 255 ) )
		self.ComWindow:SetVisible( false )
		
		self.ComWindow.Objects = {}
		self.ComWindow.ExecuteInfo = {}
		
		--self.ComHolder = exsto.CreateComboBox( 0, 0, self.ComWindow:GetWide(), self.ComWindow:GetTall(), self.ComWindow )
		
		self.ComWindow.Cleanup = function( pnl )
			for _, obj in ipairs( pnl.Objects ) do
				if obj and obj:IsValid() then obj:Remove() end
			end
			pnl.ExecuteInfo = {}
			pnl.Objects = {}
			pnl.FromCommandList = false
			
			if self.ComWindow.CommandList then
				self.ComWindow.CommandList:SetPos( 0, 0 )
			end
			
			self.ComWindow:SetVisible( false )
			self.ComWindow:SetPos( ( ScrW() / 2 ) - ( self.ComWindow:GetWide() / 2 ), ( ScrH() / 2 ) + ( self.ComWindow:GetTall() / 2 ) )
			--self.ComWindow.CommandList:SetVisible( false )
		end
		
		local function rowSelectFunc( combobox, lineID, line )
			if line.Type == "COMMAND" then -- If this is a command
				combobox:SetPos( -combobox:GetWide(), 0 )
				self.ComWindow:Populate( line.Data )
				self.ComWindow.Objects[ 1 ]:SetPos( 0, 0 )
				
				self.ContentPanel.SelectedItem = line.Data.ID 
				return
			end
			
			table.insert( self.ComWindow.ExecuteInfo, line.Data )
			
			local nextComboBox = self.ComWindow.Objects[ combobox.Index + 1 ]
			
			if !nextComboBox then -- We've hit the last possible one.  Quit and execute.
				self:Execute()
				return
			end

			if nextComboBox.Optional then
				-- TODO: Create button to execute and just throw the optionals in.
			end
			
			combobox:SetPos( -combobox:GetWide(), 0 )
			nextComboBox:SetPos( 0, 0 )
		end
		
		self.ComWindow.Populate = function( pnl, data )
			if type( data ) == "string" and data == "..." then -- We need to create this list full of commands
				pnl.FromCommandList = true
				
				if !pnl.CommandList then
					pnl.CommandList = exsto.CreateComboBox( 0, 0, pnl:GetWide(), pnl:GetTall(), pnl )
						pnl.CommandList:AddColumn( "Commands" )
						pnl.CommandList.OnRowSelected = rowSelectFunc
						Menu:CreateAnimation( pnl.CommandList )
				else 
					pnl.CommandList:SetVisible( true )
					pnl.CommandList:Clear() 
				end
					
				local comboObj
				for id, comdata in pairs( exsto.Commands ) do
					if comdata.QuickMenu then
						comboObj = pnl.CommandList:AddItem( id )
							comboObj.Type = "COMMAND"
							comboObj.Data = comdata
					end
				end				
				return
			end
			
			local argName, t, comboPnl, fil, comboObj
			for I = 1, #data.ReturnOrder do
				argName = data.ReturnOrder[ I ]
				t = data.Args[ argName ]
				
				comboPnl = exsto.CreateComboBox( 0, 0, pnl:GetWide(), pnl:GetTall(), pnl )
					comboPnl:AddColumn( argName )
					comboPnl.Index = I
				
				fil = ( t == "PLAYER" and player.GetAll() ) or data.ExtraOptionals[ argName ]
				
				for _, fillData in ipairs( fil ) do
					if t == "PLAYER" then -- If we're working with players.
						comboObj = comboPnl:AddItem( fillData:Name() )
							comboObj.Type = "PLAYER"
							comboObj.Data = fillData:Name()
					else -- We're working with another data object.
						comboObj = comboPnl:AddItem( fillData.Display )
							comboObj.Type = t
							comboObj.Data = tostring( fillData.Data or fillData.Display )
					end
				end
				
				comboPnl.OnRowSelected = rowSelectFunc
				table.insert( pnl.Objects, comboPnl )
			
				if data.Optional and data.Optional[ argName ] then comboPnl.Optional = true end
				if I != 1 or pnl.FromCommandList then comboPnl:SetPos( pnl:GetWide() + 1, 0 ) end -- If this isn't the first one, set it to the right.
				
				Menu:CreateAnimation( comboPnl )
			end
			
		end
		
		Menu:CreateAnimation( self.ComWindow )
		self.ComWindow:FadeOnVisible( true )
	end
	
	function PLUGIN:CreateContent()
	-- Create main radial circle content holder.
		-- Its just a DPanel, but we're going to override its paint to draw our own circle.
		-- Using DPanel for easier content placement.
		-- TODO: Create refreshing function to allow for re-centering on resolution change for those who change resolutions.
		local centerX = ScrW() / 2
		local centerY = ScrH() / 2
		self.ContentPanel = exsto.CreatePanel( centerX - 200, centerY - 200, 400, 400, Color( 255, 255, 255, 255 ) )
		self.ContentPanel:SetVisible( false )
		self.ContentPanel.LineModifier = 2
		self.ContentPanel.ItemModifier = 2
		self.ContentPanel.Radius = 50
		self.ContentPanel.CenterX = self.ContentPanel:GetWide() / 2
		self.ContentPanel.CenterY = self.ContentPanel:GetTall() / 2
		self.ContentPanel.Colors = {
			White = Color( 255, 255, 255, 255 )
		}
		
		--[[exsto.Animations.AddObject( self.ContentPanel, {
			Mul = 10;
			Styles = { "fade" };
		} )]]
		
		Menu:CreateAnimation( self.ContentPanel )
		self.ContentPanel:FadeOnVisible( true )
		
		local w, h, x, y
		self.ContentPanel.Paint = function( pnl ) -- 0,0 is top left of center.
			surface.SetFont( "Default" )
			surface.DrawCircle( pnl:GetWide() / 2, pnl:GetTall() / 2, self.ContentPanel.Radius, pnl.m_bgColor )
			surface.SetTextColor( pnl.m_bgColor.r, pnl.m_bgColor.g, pnl.m_bgColor.b, pnl.m_bgColor.a )
			if !pnl.ItemObjects then return end
			for _, obj in ipairs( pnl.ItemObjects ) do
				surface.SetTextPos( self.ContentPanel.CenterX + obj.xMod, self.ContentPanel.CenterY + obj.yMod )
				surface.DrawText( _ )
				surface.DrawLine( self.ContentPanel.CenterX + obj.xMod, self.ContentPanel.CenterY + obj.yMod, self.ContentPanel.CenterX + ( obj.xMod * pnl.LineModifier ), self.ContentPanel.CenterY + ( obj.yMod * pnl.LineModifier ) )
			
				if obj.Item then -- If this is an object.
					w, h = surface.GetTextSize( obj.Item.ID )
					surface.SetTextPos( ( self.ContentPanel.CenterX + ( obj.xModCenter * pnl.ItemModifier ) ) - ( w / 2 ), ( self.ContentPanel.CenterY + ( obj.yModCenter * pnl.ItemModifier ) ) - ( h / 2 ) )
					surface.DrawText( obj.Item.ID )
				end
			end
			
			x, y = pnl:GetPos()
			surface.DrawLine( self.ContentPanel.CenterX, self.ContentPanel.CenterY, gui.MouseX() - x, gui.MouseY() - y )
			
			surface.SetTextPos( pnl.CenterX, pnl.CenterY )
			surface.DrawText( pnl.SelectedItem or "Nothing" )
		end
		
		local x, y
		self.ContentPanel.GetMouseX = function( pnl )
			x, y = pnl:GetPos()
			return gui.MouseX() - x 
		end
		self.ContentPanel.GetMouseY = function( pnl )
			x, y = pnl:GetPos()
			return gui.MouseY() - y 
		end
		
		local curMouseDeg
		local dx, dy
		local prevObj
		local oldthink = self.ContentPanel.Think
		self.ContentPanel.Think = function( pnl )
			if oldthink then oldthink( pnl ) end
			
			if pnl.DisableMouseThinking then return end
			
			-- Mouse code
			dx = pnl:GetMouseX() - pnl.CenterX
			dy = pnl:GetMouseY() - pnl.CenterY
			curMouseDeg = math.deg( math.atan2( dy, dx ) )
			
			-- Normalize it to 0-360
			if curMouseDeg < 0 then curMouseDeg = curMouseDeg + 360 end
			
			for key, obj in ipairs( pnl.ItemObjects ) do
				prevObj = pnl.ItemObjects[ ( key - 1 ) == 0 and ( PLUGIN:GetMaxItems() or #pnl.ItemObjects ) or key - 1 ]
				if ( ( prevObj.ObjDegree < curMouseDeg ) and ( curMouseDeg < obj.ObjDegree ) ) or 
					( ( prevObj.ObjDegree > obj.ObjDegree ) and ( ( curMouseDeg < obj.ObjDegree ) or ( curMouseDeg > prevObj.ObjDegree ) ) ) then
					if !obj.Item then return end
					pnl.SelectedItem = obj.Item.ID 
				end
			end
		end
		
		self.ContentPanel.OnMousePressed = function( pnl, mcode )
			print( "running", mcode )
			if mcode == MOUSE_LEFT and pnl.SelectedItem then self:ClickCommand( pnl.SelectedItem ) end
		end
		
		self.ContentPanel.Populate = function( pnl )
			pnl.ItemObjects = {}
			
			-- Create our maximum items
			pnl.Items = {}
			if #self.Favorites == 0 then -- When we have no favorites, just give him an absolute random list
				print( "no favorites", LocalPlayer():GetRank() )
				local i = 1
				for id, data in pairs( exsto.Commands ) do
					if i == self.ContentMaxItems:GetInt() then break end
					print( "looking at " .. id )
					if LocalPlayer():IsAllowed( id ) and data.QuickMenu then
						print( "allowed for " .. id )
						i = i + 1
						table.insert( pnl.Items, self:SetFavorite( id ) )
					end
				end
				table.insert( pnl.Items, { ID = "...", NumUsed = 0 } )
			else
				for I = 1, #self.Favorites do
					if I == self.ContentMaxItems:GetInt() then break end
					
					table.insert( pnl.Items, self.Favorites[ I ] )
				end
				table.insert( pnl.Items, { ID = "...", NumUsed = 0 } )
			end
			
			print( "fav" )
			PrintTable( self.Favorites )
			print( "items" )
			PrintTable( pnl.Items )
			
			pnl.ItemSpace = 360 / #pnl.Items -- How much degree space each item holds.
			
			-- We're going to draw the extruding lines based off the end of the segment, rather than before.  Meaning we start above 0 and our last line "should" be 0
			local curDegree = pnl.ItemSpace / 2
				--curDegree = 0
			local centerx, centery = pnl:GetWide() / 2, pnl:GetTall() / 2
			for I = 1, #pnl.Items + 1 do
				if ( curDegree + pnl.ItemSpace ) > 360 then
					curDegree = ( curDegree + pnl.ItemSpace ) - 360
				else
					curDegree = curDegree + pnl.ItemSpace
				end
				
				print( curDegree )
				pnl.ItemObjects[ I ] = {
					ObjDegree = curDegree,
					xMod = pnl.Radius * math.cos( math.rad( curDegree ) ),
					yMod = pnl.Radius * math.sin( math.rad( curDegree ) ),
					Item = pnl.Items[ I ] or nil;
					ComData = exsto.Commands[ pnl.Items[ I ] or nil ] or nil;
				}
			end
			
			PrintTable( pnl.ItemObjects )
			
			-- Now, lets set a location for the text, and do any finalization.
			local prevObj, degDiff = nil, pnl.ItemSpace / 2
			for key, obj in ipairs( pnl.ItemObjects ) do
				prevObj = pnl.ItemObjects[ ( key - 1 ) == 0 and ( PLUGIN:GetMaxItems() or #pnl.ItemObjects ) or key - 1 ]
				
				obj.xModCenter = math.cos( math.rad( degDiff + prevObj.ObjDegree ) ) * pnl.Radius 
				obj.yModCenter = math.sin( math.rad( degDiff + prevObj.ObjDegree ) ) * pnl.Radius

			end
			
	
		end
	end
	
	function PLUGIN:GetMaxItems()
		return ( #self.ContentPanel.ItemObjects < self.ContentMaxItems:GetInt() ) and #self.ContentPanel.ItemObjects or self.ContentMaxItems:GetInt()
	end

	function PLUGIN:Init()
	
		-- Create the favorites database
		self.FavDB = FEL.CreateDatabase( "exsto_plugin_favorites" )
		self.FavDB:ConstructColumns( {
			ID = "TEXT:primary";
			Priority = "BOOLEAN";
			NumUsed = "INTEGER";
		} )
		
		self:LoadFavorites()
		self:CreateContent()
		self:CreateCommandWindow()
		
		self.ContentMaxItems = CreateClientConVar( "ExFavorites_MaxItems", 6, true )
		
	end
	
	function PLUGIN:Show() -- TODO: Should we re-set its position every viewing?
		if !exsto.Commands then return end
		if !self.ContentPanel.ItemObjects then self.ContentPanel:Populate() end
		gui.EnableScreenClicker( true )
		self.ContentPanel:SetVisible( true )
		self.ContentPanel.DisableMouseThinking = false
		
		--self.ContentPanel:SetPos( math.random( 0, 1000 ), math.random( 0, 1000 ) )
		
		PrintTable( self.ContentPanel.ItemObjects )
	end
	
	function PLUGIN:Hide()
		gui.EnableScreenClicker( false )
		self.ContentPanel:SetVisible( false )
		self.ContentPanel.DisableMouseThinking = true
		
		self.ComWindow:Cleanup()
	end

end	

PLUGIN:Register()