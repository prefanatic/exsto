local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Rank Editor",
	ID = "rank-editor",
	Desc = "A plugin that allows management over rank creation.",
	Owner = "Prefanatic",
} )

if SERVER then
	
	util.AddNetworkString( "ExPushRankToSrv" )
	util.AddNetworkString( "ExRecImmuneChange" )
	util.AddNetworkString( "ExDelRankFromClient" )

	function PLUGIN.DeleteRank( reader )
		-- Add Flag.
		
		-- Remove exsto rank error data if we are removing the rank
		//exsto.RankErrors[ args[ 1 ] ] = nil

		-- Remove the data.
		exsto.RankDB:DropRow( reader:ReadString() )
		
		-- Reload Exsto's access controllers.  I really hope this doesn't break anything.
		exsto.aLoader.Initialize()
		
		-- Reload the rank editor.
		exsto.SendRanks( player.GetAll() )
		--exsto.CreateSender( "ExRankEditor_Reload", "all" ):Send()
		
	end
	exsto.CreateReader( "ExDelRankFromClient", PLUGIN.DeleteRank )
	
	function PLUGIN.CommitChanges( reader )
		local immunity = nil
		local id = reader:ReadString()
		if !exsto.Ranks[ id ] then immunity = 10 end

		-- Write the data
		PLUGIN:WriteAccess( id, reader:ReadString(), reader:ReadString(), reader:ReadString(), reader:ReadColor(), reader:ReadTable(), reader:ReadTable() )
		if immunity then
			PLUGIN.RecieveImmunityData( nil, id, immunity )
		end
		
		-- Reload Exsto's access controllers.  I really hope this doesn't break anything.
		exsto.aLoader.Initialize()
		
		-- We sadly have to resend everything, with flags and stuff being the way they are.
		exsto.SendRanks( player.GetAll() )
		
		-- Reload the rank editor.
		//timer.Create( "reload_" .. ply:EntIndex(), 1, 1, PLUGIN.SendData, PLUGIN, "ExRankEditor_Reload", ply )
		hook.Call( "ExOnRankCreate", nil, id )
	end
	exsto.CreateReader( "ExPushRankToSrv", PLUGIN.CommitChanges )
	
	function PLUGIN.RecieveImmunityData( reader, id, immunity )
		if !reader then
			exsto.RankDB:AddRow( {
			ID = id;
			Immunity = immunity;
		} )
		else
			local numChange = reader:ReadShort()
			for I = 1, numChange do
				exsto.RankDB:AddRow( {
					ID = reader:ReadString(),
					Immunity = reader:ReadShort(),
				} )
			end
		end
	end
	exsto.CreateReader( "ExRecImmuneChange", PLUGIN.RecieveImmunityData )
	
	function PLUGIN:ExClientData( hook, ply, data )
		if hook == "ExRecImmuneChange" or hook == "ExRecRankData" then
			if !ply:IsAllowed( "rankeditor" ) then return false end
		end		
	end
	
	function PLUGIN:WriteAccess( short, name, derive, desc, color, flagsallow, flagsdeny )
		exsto.RankDB:AddRow( {
			Name = name;
			ID = short;
			Description = desc;
			Parent = derive;
			Color = von.serialize( color );
			FlagsAllow = von.serialize( flagsallow );
			FlagsDeny = von.serialize( flagsdeny );
		} )
	end

elseif CLIENT then

	PLUGIN.Panel = nil
	PLUGIN.Recieved = false
	
	local function reload()
		print( "HELLO" )
		PLUGIN:Main( PLUGIN.Panel )
	end
	exsto.CreateReader( "ExRankEditor_Reload", reload )

	Menu:CreatePage( {
		Title = "Rank Editor",
		Short = "rankeditor", },
		function( panel )
			-- Request ranks.
			PLUGIN.Panel = panel
			PLUGIN.Panel:FadeOnVisible( true )
			PLUGIN.Panel:SetFadeMul( 3 )
			if !PLUGIN.Recieved or #exsto.Ranks == 0 then
				panel:PushLoad()
				RunConsoleCommand( "_ResendRanks" )
			else
				PLUGIN:Main( panel )
			end
		end
	)
	
	local function received( reader )
		print( "reloading panel" )
		PLUGIN.Recieved = true
		if PLUGIN.Panel then
			print( "moving on." )
			PLUGIN:Main( PLUGIN.Panel )
		end
	end
	exsto.CreateReader( "ExRecievedRanks", received )
	
	function PLUGIN:Main( panel )
	
		if !self.Flags then
			self.Flags = {}
			for name, desc in pairs( exsto.Flags ) do
				table.insert( self.Flags, {Name = name, Desc = desc} )
			end
			table.SortByMember( self.Flags, "Name", true )
		end
		
		panel:EndLoad()
		self:BuildMenu( panel )
	end
	
	function PLUGIN:ReloadMenu( panel )
		exsto.Ranks = {}
		//panel:PushLoad()
		self.Recieved = false
		RunConsoleCommand( "_ResendRanks" )
	end
	
	function PLUGIN:FormulateUpdate( name, short, desc, derive, col, flagsallow, flagsdeny )

		-- Upload new rank data
		self.Panel:PushLoad()
		local sender = exsto.CreateSender( "ExPushRankToSrv" )
			sender:AddString( short )
			sender:AddString( name )
			sender:AddString( derive )
			sender:AddString( desc )
			sender:AddColor( col )
			
			sender:AddTable( flagsallow )
			sender:AddTable( flagsdeny )
			
			sender:Send()
		
		-- Send changes to immunity
		if table.Count( self.ImmunityBox.Changed ) >= 1 then
			local sender = exsto.CreateSender( "ExRecImmuneChange" )
				sender:AddShort( #self.ImmunityBox.Changed )
			for short, immunity in pairs( self.ImmunityBox.Changed ) do
				sender:AddString( short )
				sender:AddShort( immunity )
			end
			sender:Send()
			self.ImmunityBox.Changed = {}
		end
		
		self._LastPage = short
		--self:ReloadMenu( self.Panel )
		
	end
	
	function PLUGIN:BuildMenu( panel )
	
		-- Clear pre-existing content.
		local reloading = false
		if self.Tabs then
			self.Tabs:Clear()
			self.Tabs:Remove()
			reloading = true
		end
		
		if self.Secondary then
			self.Secondary:Remove()
			reloading = true
		end
		
		self.Tabs = panel:RequestTabs( reloading )
		self.Secondary = panel:RequestSecondary( reloading )
		if reloading then 
			Menu:BringBackSecondaries() 
		end

		self.Tabs:SetListHeight( self.Tabs:GetListTall() - 20 )
		
		self.Tabs.AddNew = exsto.CreateImageButton( self.Tabs:GetWide() - 20, self.Tabs:GetTall() - 20, 16, 16, "icon16/add.png", self.Tabs )
			self.Tabs.AddNew.DoClick = function( img )
				local function build()
					self:UpdateForms( {
						Name = "",
						ID = "",
						Description = "",
						Parent = "NONE",
						Color = Color( 255, 255, 255, 200 ),
						FlagsAllow = {},
						FlagsDeny = {},
					} ) 
				end
				self.Tabs:CreateButton( "New Rank", build )
				self.Tabs:SelectByName( "New Rank" )
			end
			
		-- Rank building.  
		local immunityData = {}
		self.Ranks = table.Copy( exsto.Ranks )
		for _, data in SortedPairsByMemberValue( self.Ranks, "Immunity" ) do
			if data.ID != "srv_owner" then				
				self.Tabs:CreateButton( data.Name, function() self:UpdateForms( data ) end, data.ID )
				
				table.insert( immunityData, { Name = data.Name, Immunity = data.Immunity, ID = data.ID } )
			end
		end
		
		if self._LastPage then self.Tabs:SelectByID( self._LastPage ) end

		-- Immunity Box
		local immunityLabel = exsto.CreateLabel( "center", 5, "Immunity", "exstoSecondaryButtons", self.Secondary )
		self.ImmunityBox = exsto.CreateComboBox( 10, 25, self.Secondary:GetWide() - 20, self.Secondary:GetTall() - 60, self.Secondary )
			self.ImmunityBox:AddColumn( "Immunity" )
			self.ImmunityBox.Changed = {}
			
			self.ImmunityBox.BuildData = function( self, data )
				self:Clear()
				table.sort( data, function( a, b )
					if !tonumber( a.Immunity ) or !tonumber( b.Immunity ) then return false end
					return tonumber( a.Immunity ) < tonumber( b.Immunity )
				end)
				for _, info in ipairs( data ) do
					local item = PLUGIN.ImmunityBox:AddItem( info.Name )
						item.Name = info.Name
						item.Immunity = info.Immunity
						item.ID = info.ID
						item.Key = _
						
						item.PaintOver = function( self )
							draw.SimpleText( "Level: " .. self.Immunity, "default", self:GetWide() - 50, self:GetTall() / 2, Color( 0, 0, 0, 255 ), 0, 1 )
						end
				end
			end

		local immunityRaise = exsto.CreateButton( 10, self.Secondary:GetTall() - 33, 60, 27, "Raise", self.Secondary )
			immunityRaise:SetStyle( "positive" )
			immunityRaise.OnClick = function( self )
				local selected = PLUGIN.ImmunityBox.m_pSelected
				if selected then
					if selected.Immunity == 0 then return end
					
					PLUGIN.ImmunityBox.Changed[ selected.ID ] = selected.Immunity - 1
					immunityData[ selected.Key ].Immunity = tonumber( selected.Immunity - 1 )
					PLUGIN.ImmunityBox:BuildData( immunityData )
					PLUGIN.ImmunityBox:SelectByName( selected.Name )
				end
			end	
			
		local immunityLower = exsto.CreateButton( self.Secondary:GetWide() - 70, self.Secondary:GetTall() - 33, 60, 27, "Lower", self.Secondary )
			immunityLower:SetStyle( "negative" )
			immunityLower.OnClick = function( self )
				local selected = PLUGIN.ImmunityBox.m_pSelected
				if selected then				
					PLUGIN.ImmunityBox.Changed[ selected.ID ] = selected.Immunity + 1
					immunityData[ selected.Key ].Immunity = tonumber( selected.Immunity + 1 )
					PLUGIN.ImmunityBox:BuildData( immunityData )
					PLUGIN.ImmunityBox:SelectByName( selected.Name )
				end
			end	
			
		local immunitySlider = exsto.CreateNumberWang( ( self.Secondary:GetWide() / 2 ) - 15, self.Secondary:GetTall() - 30, 30, 20, 0, 100, 0, self.Secondary )
			immunitySlider.OnValueChanged = function( self )
				if !self.MotherObject then return false end
				if self.DontUpdateValue then return false end
				PLUGIN.ImmunityBox.Changed[ self.MotherObject.ID ] = self:GetValue()
				immunityData[ self.MotherObject.Key ].Immunity = self:GetValue()
				PLUGIN.ImmunityBox:BuildData( immunityData )
				PLUGIN.ImmunityBox:SelectByName( self.MotherObject.Name )
			end
			--immunitySlider.Wanger.Paint = function() end
			immunitySlider:SetDecimals( 0 )
			
		local oldSelect = self.ImmunityBox.SelectItem
			self.ImmunityBox.SelectItem = function( self, item, onlyme )
				oldSelect( self, item, onlyme )
				immunitySlider.MotherObject = item
				immunitySlider.DontUpdateValue = true
				immunitySlider:SetValue( item.Immunity )
				immunitySlider.DontUpdateValue = false
			end
			
		self:UpdateForms( self.Ranks[ immunityData[ 1 ].ID ] )
			
		self.ImmunityBox:BuildData( immunityData )
	end
	
	function PLUGIN:UpdateForms( data )
		self.Panel:SetVisible( false )
		--timer.Simple( 0.1, function()
			if !self.nameEntry or !self.nameEntry:IsValid() then self:FormPage( self.Panel, data ) end
			
			self.nameEntry:SetText( data.Name )
			self.descEntry:SetText( data.Description )
			self.uidEntry:SetText( data.ID )
			
			if data.ID == "" then self.uidEntry:SetEditable( true ) else self.uidEntry:SetEditable( false ) end
			
			self.deriveEntry:Clear()
			self.deriveEntry:SetText( data.Parent )
			for short, info in SortedPairsByMemberValue( exsto.Ranks, "Immunity" ) do
				if short != data.ID and data.ID != "srv_owner" then
					self.deriveEntry:AddChoice( short )
				end
			end
			--self.deriveEntry:SelectByName( data.Parent )
			
			self.colorMixer:SetColor( data.Color )
			self.colorExample:SetTextColor( data.Color )
			--self.redSlider:SetValue( data.Color.r )
			--self.greenSlider:SetValue( data.Color.g )
			--self.blueSlider:SetValue( data.Color.b )
			--self.alphaSlider:SetValue( data.Color.a )
			
			self.FlagsAllow = data.FlagsAllow
			self.FlagsDeny = data.FlagsDeny
			self.flagList:Clear()
			self.flagList:UpdateFlagList( 1, data )
			
			--self.delete:SetVisible( data.CanRemove )
			if Menu.CurrentPage.Short == "rankeditor" then self.Panel:SetVisible( true ) end
		--end )
	end
	
	function PLUGIN:FormPage( panel, data )

		-- Main data color panel.
		local mainColorPanel = Menu:CreateColorPanel( 10, 10, panel:GetWide() - 20, 110, panel )
		
		local invalidator = nil
		local function ContentCheck( self )
			if string.find( self:GetValue(), "['\"]" ) then
				self.Invalid = true
				invalidator = self
				mainColorPanel:Deny()
				self:SetToolTip( "You cannot have ', \", or ! in the name!" )
				return
			end
			
			if self:GetValue() == "" then
				self.Invalid = true
				invalidator = self
				mainColorPanel:Deny()
				self:SetToolTip( "You cannot leave this empty!" )
				return
			end
			
			if self.IsUID then
				for short, info in pairs( exsto.Ranks ) do
					if self:GetValue() == short then
						self.Invalid = true
						invalidator = self
						mainColorPanel:Deny()
						self:SetToolTip( "You cannot have more than one rank with the same unique id!" )
						return
					end
				end
			end
			
			if self.Invalid then
				self:SetToolTip( "" )
				self.Invalid = false
			end
				
			if mainColorPanel:GetStyle() != "accept" and !self.Invalid and invalidator == self then
				mainColorPanel:Accept()
			end
		end
			
		-- Display Name
		local nameLabel = exsto.CreateLabel( 20, 5, "Display Name", "exstoSecondaryButtons", mainColorPanel )
		self.nameEntry = exsto.CreateTextEntry( 20, 0, 200, 20, mainColorPanel )
			self.nameEntry:MoveBelow( nameLabel )
			self.nameEntry:SetText( data.Name )
			self.nameEntry.OnTextChanged = ContentCheck
			
		-- Description
		local descLabel = exsto.CreateLabel( ( mainColorPanel:GetWide() / 2 ) + 20, 5, "Description", "exstoSecondaryButtons", mainColorPanel )
		self.descEntry = exsto.CreateTextEntry( ( mainColorPanel:GetWide() / 2 ) + 20, 0, 200, 20, mainColorPanel )
			self.descEntry:MoveBelow( descLabel )
			self.descEntry:SetText( data.Description )
			self.descEntry.OnTextChanged = ContentCheck
			
		-- UniqueID
		local x, y = self.nameEntry:GetPos()
		local uidLabel = exsto.CreateLabel( 20, y + 40, "Unique ID", "exstoSecondaryButtons", mainColorPanel )
		self.uidEntry = exsto.CreateTextEntry( 20, 0, 200, 20, mainColorPanel )
			self.uidEntry:MoveBelow( uidLabel )
			self.uidEntry:SetText( data.ID )
			self.uidEntry.IsUID = true
			self.uidEntry.OnTextChanged = ContentCheck
			
			if data.ID != "" then
				self.uidEntry:SetEditable( false )
			end
			
		-- Derive
		local x, y = self.descEntry:GetPos()
		local deriveLabel = exsto.CreateLabel( ( mainColorPanel:GetWide() / 2 ) + 20, y + 40, "Derive From", "exstoSecondaryButtons", mainColorPanel )
		self.deriveEntry = exsto.CreateMultiChoice( ( mainColorPanel:GetWide() / 2 ) + 20, 0, 200, 20, mainColorPanel )
			self.deriveEntry:MoveBelow( deriveLabel )
			self.deriveEntry:SetText( data.Parent )
			--self.deriveEntry:SetEditable( false )
			
			for short, info in SortedPairsByMemberValue( table.Copy( exsto.Ranks ), "Immunity" ) do
				if short != data.ID and data.ID != "srv_owner" then
					self.deriveEntry:AddChoice( short )
				end
			end
			self.deriveEntry:AddChoice( "NONE" )
			
		-- Color Panel
		local colorColorPanel = Menu:CreateColorPanel( ( mainColorPanel:GetWide() / 2 ) + 70, 10, ( mainColorPanel:GetWide() / 2 ) - 60, 160, panel )
			colorColorPanel:MoveBelow( mainColorPanel, 10 )
			
		self.colorMixer = exsto.CreateColorMixer( 0, 0, 160, 100, data.Color, colorColorPanel )
			self.colorMixer:Center()
			--self.colorMixer:SetLabel( "abc ABC 123" )
			
		self.colorExample = exsto.CreateLabel( "center", 5, "abc ABC 123", "exstoSecondaryButtons", colorColorPanel )
			self.colorExample:SetTextColor( data.Color )
			
		self.colorExample.ValueChanged = function( cl, col )
			print( "why isn't this working" )
			self.colorExample:SetTextColor( col )
		end

		local emptyFunc = function() end
		
		-- Flag Panel
		local flagColorPanel = Menu:CreateColorPanel( 10, 0, ( mainColorPanel:GetWide() / 2 ) + 50, 195, panel )
			flagColorPanel:MoveBelow( mainColorPanel, 10 )
			
		self.flagList = exsto.CreateComboBox( 0, 0, flagColorPanel:GetWide(), flagColorPanel:GetTall(), flagColorPanel )
			self.flagList.dontDrawBackground = true
			self.flagList:AddColumn( "Flags" )
			self.flagList.OnRowSelected = function( lst, lineID, line )
				PLUGIN:HandleFlagModification( line, self.Ranks[ self.uidEntry:GetValue() ] )
			end
			self.flagList.DoDoubleClick = function( lst, lineID, line )
				PLUGIN:HandleFlagModification( line, self.Ranks[ self.uidEntry:GetValue() ], true )
			end

			self.flagList.UpdateFlagList = function( lst, index, rank )
				local info = PLUGIN.Flags[ index ]
				if !info then return end

				local obj = lst:AddItem( info.Name )
					obj:SetToolTip( info.Description )
					obj.FlagName = info.Name
					obj.disableSelect = true
					
					obj.OnCursorMoved = emptyFunc
					
					obj.Status = "removed"
					obj.Icon = nil
					obj.PaintOver = function( obj )
						if !obj.Icon then return end
						
						surface.SetTextColor( 50, 50, 50, 255 )
						surface.SetTextPos( self.flagList:GetWide() - 80, 2 )
						if obj.Icon == "gui/silkicons/check_on" then
							surface.DrawText( "Allowed" )
						elseif obj.Icon == "gui/silkicons/check_off" then
							surface.DrawText( "Denied" )
						elseif obj.Icon == "exsto/icon_locked" then
							surface.DrawText( "Locked" )
						end
						
						--[[
						if obj.OldIcon != obj.Icon then
							obj.IconID = surface.GetTextureID( obj.Icon )
							obj.OldIcon = obj.Icon
						end

						surface.SetTexture( obj.IconID )
						surface.SetDrawColor( 255, 255, 255, 255 )
						surface.DrawTexturedRect( self.flagList:GetWide() - 40, ( obj:GetTall() / 2 ) - 8, 16, 16 )]]
					end
					
					local parentFlagsAllow, parentFlagsDeny = {}, {}
					if self.Ranks[ rank.Parent ] then
						parentFlagsAllow = self.Ranks[ rank.Parent ].FlagsAllow
						parentFlagsDeny = self.Ranks[ rank.Parent ].FlagsDeny
					end
					if table.HasValue( parentFlagsAllow, obj.FlagName ) then obj.ParentLocked = true end
					if table.HasValue( parentFlagsDeny, obj.FlagName ) then obj.ParentLocked = true end
					
					if table.HasValue( rank.FlagsAllow, obj.FlagName ) then
						obj.Icon = "gui/silkicons/check_on"
						obj.Status = "allowed"
						obj.overrideColor = Color( 180, 241, 170 )
					elseif table.HasValue( rank.FlagsDeny, obj.FlagName ) then
						obj.Icon = "gui/silkicons/check_off"
						obj.Status = "denied"
						obj.overrideColor = Color( 249, 37, 101 ) 
					end
					
					if obj.ParentLocked then
						obj.Icon = "exsto/icon_locked"
						obj.overrideColor = nil
					end
					
				lst:UpdateFlagList( index + 1, rank )
			end
		
		-- Commit Buttons
		self.save = exsto.CreateButton( panel:GetWide() - 80, panel:GetTall() - 40, 70, 27, "Save", panel )
			self.save:SetStyle( "positive" )
			self.save.OnClick = function( button )
				if self.nameEntry:GetValue() == "" then PLUGIN.Panel:PushError( "Please enter a name for the rank!" ) return end
				if self.uidEntry:GetValue() == "" then PLUGIN.Panel:PushError( "Please enter a UID for the rank!" ) return end
				if self.descEntry:GetValue() == "" then self.descEntry:SetText( "None Provided" ) end
				if self.deriveEntry:GetValue() == "" then PLUGIN.Panel:PushError( "Please enter a valid derive!" ) return end
				
				PLUGIN:FormulateUpdate( self.nameEntry:GetValue(), self.uidEntry:GetValue(), self.descEntry:GetValue(), self.deriveEntry:GetValue(), self.colorMixer:GetColor(), self.FlagsAllow, self.FlagsDeny )
			end
			
		self.delete = exsto.CreateButton( 0, panel:GetTall() - 40, 70, 27, "Delete", panel )
			self.delete:SetStyle( "negative" )
			self.delete:MoveLeftOf( self.save, 5 )
			--self.delete:SetVisible( data.CanRemove )
			self.delete.OnClick = function( button )
				local id, loop = self.uidEntry:GetValue(), false
				for id, rank in pairs( self.Ranks ) do
					if rank.Parent == id then loop = true break end
				end
				if id == "superadmin" or id == "guest" or id == "admin" or loop then
					PLUGIN.Panel:PushError( "Unable to delete rank.  Either default or something derives from it!" )
					return
				end
				
				PLUGIN.Panel:PushLoad()
				local sender = exsto.CreateSender( "ExDelRankFromClient" )
					sender:AddString( self.uidEntry:GetValue() )
		
					sender:Send()
			end
			
		self.refresh = exsto.CreateButton( 0, panel:GetTall() - 40, 75, 27, "Refresh", panel )
			self.refresh:SetStyle( "neutral" )
			self.refresh:MoveLeftOf( self.delete, 5 )
			self.refresh.OnClick = function( button )
				PLUGIN:ReloadMenu( PLUGIN.Panel )
			end
	end
	
	local function handler( obj, tbl, flag )
		if table.HasValue( tbl, flag ) then
			for _, f in ipairs( tbl ) do
				if f == flag then table.remove( tbl, _ ) return true end
			end
		end
	end
	
	function PLUGIN:HandleFlagModification( obj, data, doubled )
		if obj.FlagName == "issuperadmin" or obj.FlagName == "isadmin" then return end
		
		-- Make sure this flag isn't apart of the derive.
		local parentFlagsAllow, parentFlagsDeny = {}, {}
		if self.Ranks[ data.Parent ] then
			parentFlagsAllow = self.Ranks[ data.Parent ].FlagsAllow
			parentFlagsDeny = self.Ranks[ data.Parent ].FlagsDeny
		end
		if table.HasValue( parentFlagsAllow, obj.FlagName ) then return end
		if table.HasValue( parentFlagsDeny, obj.FlagName ) then return end
		
		-- Double click for deny
		if doubled then
			handler( obj, data.FlagsAllow, obj.FlagName )
			table.insert( data.FlagsDeny, obj.FlagName )
			
			obj.Status = "denied"
			obj.Icon = "gui/silkicons/check_off"
			obj.overrideColor = Color( 249, 37, 101 )
			return
		end
		
		-- If the object is enabled, next click will disable, and third will remove it.
		if obj.Status == "denied" or obj.Status == "allowed" then
			handler( obj, data.FlagsDeny, obj.FlagName )
			
			obj.Status = "removed"
			obj.Icon = nil
			obj.overrideColor = nil
		elseif obj.Status == "removed" then
			table.insert( data.FlagsAllow, obj.FlagName )
			
			obj.Status = "allowed"
			obj.Icon = "gui/silkicons/check_on"
			obj.overrideColor = Color( 180, 241, 170 )
		end
		
	end

end

PLUGIN:Register()
		