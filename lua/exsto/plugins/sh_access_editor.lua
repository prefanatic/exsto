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
	
	function PLUGIN:Init()
		exsto.CreateFlag( "rankeditor", "Allows users to edit ranks in the menu." )
	end

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
		local id = reader:ReadString()

		-- Write the data
		PLUGIN:WriteAccess( id, reader:ReadString(), reader:ReadString(), reader:ReadColor(), reader:ReadTable(), reader:ReadTable() )
		
		-- Give him immunity.
		if !exsto.Ranks[ id ] then
			PLUGIN:WriteImmunity( id, 10 )
		end

		-- Reload Exsto's access controllers.  I really hope this doesn't break anything.
		exsto.aLoader.Initialize()
		
		-- We sadly have to resend everything, with flags and stuff being the way they are.
		exsto.SendRanks( player.GetAll() )
		
		-- Reload the rank editor.
		--timer.Create( "reload_" .. ply:EntIndex(), 1, 1, PLUGIN.SendData, PLUGIN, "ExRankEditor_Reload", ply )
		hook.Call( "ExOnRankCreate", nil, id )
	end
	exsto.CreateReader( "ExPushRankToSrv", PLUGIN.CommitChanges )
	
	function PLUGIN.RecieveImmunityData( reader, id, immunity )
	end
	exsto.CreateReader( "ExRecImmuneChange", PLUGIN.RecieveImmunityData )
	
	function PLUGIN:ExClientData( hook, ply, data )
		if hook == "ExRecImmuneChange" or hook == "ExRecRankData" then
			if !ply:IsAllowed( "rankeditor" ) then return false end
		end		
	end
	
	function PLUGIN:WriteImmunity( id, imm )
		exsto.RankDB:AddRow( {
			ID = id;
			Immunity = num;
		} )
	end
	
	function PLUGIN:WriteAccess( short, name, derive, color, flagsallow, flagsdeny )
		exsto.RankDB:AddRow( {
			Name = name;
			ID = short;
			Parent = derive;
			Color = von.serialize( color );
			FlagsAllow = von.serialize( flagsallow );
			FlagsDeny = von.serialize( flagsdeny );
		} )
	end

elseif CLIENT then

	local function errors( rank, pnl ) -- Error checking
		return false
	end

	--[[ UPDATE PUSHING FUNCTIONS ]]
	local function pushUpdate()
		local rank = PLUGIN.WorkingRank
		local pnl = PLUGIN.Page.Content
		if !rank then return end -- We weren't working with anything.
		if errors( rank, pnl ) then return end
		
		PLUGIN:Debug( "Updating rank content for " .. rank.Name )
		local sender = exsto.CreateSender( "ExPushRankToSrv" )
			sender:AddString( rank.ID )
			sender:AddString( pnl.RankName:GetValue() )
			sender:AddString( pnl.Derive:GetValue() )
			sender:AddColor( pnl.RankColor:GetColor() )
			sender:AddTable( rank.FlagsAllow ) -- TODO
			sender:AddTable( rank.FlagsDeny )
		sender:Send()
	end

	local function updateContent( rank )
		local pnl = PLUGIN.Page.Content
		PLUGIN.WorkingRank = rank 
		
		pnl.RankName:SetText( rank.Name )
		pnl.Derive:SetValue( rank.Parent )
		pnl.RankColor:SetColor( rank.Color )
		pnl.RankText:SetTextColor( rank.Color )
		pnl.Flags:Populate( rank )
		
		pnl.OverlayPanel:SetVisible( false )
	end
	
	local function editorRankSelected( box, index, value, data )
		-- Push the rank update to server, if we did so.
		pushUpdate()
		
		-- Update our content.
		updateContent( data )
	end
	
	local function flagIndicator( line )
		if !PLUGIN.WorkingRank then return end
		local data = PLUGIN.Page.Content.Flags:GetLineDataFromObj( line )
		
		draw.SimpleText( data.Status, "ExGenericText14", 0, 2, Color( 0, 0, 0, 255 ) )
	end
	
	local function flagPopulate( lst, rank )
		local allow = rank.FlagsAllow
		local deny = rank.FlagsDeny
		local drv_allow = exsto.Ranks[ rank.Parent ] and exsto.Ranks[ rank.Parent].FlagsAllow or {}
		
		lst:Clear()
		local status = "open"
		for flag, desc in pairs( exsto.Flags ) do
			-- Do some flag status checking first.
			if table.HasValue( allow, flag ) then status = "allowed" end
			if table.HasValue( deny, flag ) then status = "denied" end
			if table.HasValue( drv_allow, flag ) then status = "locked" end
			
			lst:AddRow( { flag }, {Desc = desc, Status = status } )
		end
	end

	local function editorInit( pnl )
		-- Build our layout.
		pnl:CreateCategory( "Rank Editor" )
		pnl:DisableScroller()
		pnl.Holder = exsto.CreatePanel( 0, 0, pnl:GetWide(), pnl:GetTall() - 10, nil, pnl )
			pnl.Holder.Paint = function() end
			pnl:Add( pnl.Holder, "Rank Editor" )
			pnl.Holder:Dock( FILL )
			pnl.Holder:DockPadding( 4, 0, 4, 0 )
			--pnl.Holder:DockMargin( 0, 4, 0, 4 )

		pnl.Header = vgui.Create( "DPanel", pnl.Holder )
			pnl.Header:Dock( TOP )
			pnl.Header:SetTall( 32 )
			pnl.Header.Paint = function() end
			
		pnl.RankSelect = vgui.Create( "DComboBox", pnl.Header )
			pnl.RankSelect:SetValue( "Select a rank" )
			pnl.RankSelect:Dock( FILL )
			pnl.RankSelect.OnSelect = editorRankSelected

		-- TODO: Turn these into ImageButtons
		pnl.CreateRank = vgui.Create( "DButton", pnl.Header )
			pnl.CreateRank:SetText( "+" )
			pnl.CreateRank:SetWide( 32 )
			pnl.CreateRank:Dock( RIGHT )
		
		pnl.DeleteRank = vgui.Create( "DButton", pnl.Header )
			pnl.DeleteRank:SetText( "-" )
			pnl.DeleteRank:SetWide( 32 )
			pnl.DeleteRank:Dock( RIGHT )
			
		pnl.RankName = vgui.Create( "DTextEntry", pnl.Holder )
			pnl.RankName:Dock( TOP )
			pnl.RankName:SetTall( 32 )
			pnl.RankName:DockMargin( 0, 4, 0, 0 )
		
		pnl.Derive = vgui.Create( "DComboBox", pnl.Holder )
			pnl.Derive:AddChoice( "NONE" )
			pnl.Derive:SetTall( 32 )
			pnl.Derive:Dock( TOP )
			pnl.Derive:DockMargin( 0, 4, 0, 0 )
			
		pnl.ColorHolder = vgui.Create( "DPanel", pnl.Holder )
			pnl.ColorHolder:SetTall( 76 )
			pnl.ColorHolder:Dock( TOP )
			pnl.ColorHolder:DockMargin( 6, 4, 6, 0 )
			pnl.ColorHolder.Paint = function() end

		pnl.RankColor = vgui.Create( "DColorMixer", pnl.ColorHolder )
			pnl.RankColor:Dock( FILL )
			pnl.RankColor:DockMargin( 0, 0, 12, 0 )
			pnl.RankColor:SetPalette( false )
			pnl.RankColor:SetAlphaBar( false )
		
		pnl.RankText = vgui.Create( "DLabel", pnl.ColorHolder )
			pnl.RankText:SetText( "ABC\n\nabc\n\n123" )
			pnl.RankText:SetFont( "ExGenericText15" )
			pnl.RankText:SizeToContents()
			pnl.RankText:Dock( RIGHT )
			
		pnl.Flags = vgui.Create( "ExListView", pnl.Holder )
			pnl.Flags:Dock( FILL )
			pnl.Flags:DockMargin( 0, 4, 0, 4 )
			pnl.Flags:SetDataHeight( 22 )
			pnl.Flags:NoHeaders()
			pnl.Flags:LinePaintOver( flagIndicator )
			pnl.Flags.Populate = flagPopulate
			
		local x, y = pnl.RankName:GetPos()
		pnl.OverlayPanel = vgui.Create( "DPanel", pnl.Holder )
			pnl.OverlayPanel:SetSize( pnl:GetWide(), pnl:GetTall() - 10 )
			pnl.OverlayPanel:MoveBelow( pnl.Header, 1 )
			pnl.OverlayPanel.Paint = function( slf )
				surface.SetDrawColor( 255, 255, 255, 100 )
				surface.DrawRect( 0, 0, slf:GetWide(), slf:GetTall() )
			end
			
		-- Populate the RankSelect with our ranks.
		for ID, data in pairs( exsto.Ranks ) do
			if ID != "srv_owner" then 
				pnl.RankSelect:AddChoice( data.Name, data ) 
				pnl.Derive:AddChoice( data.Name )
			end
		end

	end

	function PLUGIN:Init()
		self.Page = exsto.Menu.CreatePage( "rankeditor", editorInit )
			self.Page:SetTitle( "Rank Editor" )
			self.Page:SetSearchable( true )
			self.Page:OnBackstage( pushUpdate )
			
		self.WorkingRank = nil
	end

end

PLUGIN:Register()