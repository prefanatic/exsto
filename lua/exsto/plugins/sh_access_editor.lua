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
		--timer.Create( "reload_" .. ply:EntIndex(), 1, 1, PLUGIN.SendData, PLUGIN, "ExRankEditor_Reload", ply )
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
			print( numChange )
			for I = 1, numChange do
				local id, immunity = reader:ReadString(), reader:ReadShort()
				exsto.RankDB:AddRow( {
					ID = id,
					Immunity = immunity,
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

	local function editorRankSelected( box, value, data )
		
	end

	local function editorInit( pnl )
		-- Build our layout.
		-- TODO: Skip the page title.  I'm not sure how universal this design goes.
		pnl.RankSelect = exsto.CreateMultiChoice( 4, 26, pnl:GetWide() - 74, 32, pnl )
			pnl.RankSelect.OnSelect = editorRankSelected

		-- TODO: Turn these into ImageButtons
		pnl.CreateRank = exsto.CreateButton( 0, 26, 32, 32, "+", pnl )
			pnl.CreateRank:MoveRightOf( pnl.RankSelect, 1 )
		
		pnl.DeleteRank = exsto.CreateButton( 0, 26, 32, 32, "-", pnl )
			pnl.DeleteRank:MoveRightOf( pnl.CreateRank, 1 )
			
		pnl.RankName = exsto.CreateTextEntry( 4, 0, pnl:GetWide() - 8, 32, pnl )
			pnl.RankName:MoveBelow( pnl.RankSelect, 4 )
		
		pnl.Derive = exsto.CreateMultiChoice( 4, 0, pnl:GetWide() - 8, 32, pnl )
			pnl.Derive:MoveBelow( pnl.RankName, 4 )
			
		pnl.RankColor = exsto.CreateColorMixer( 4, 0, pnl:GetWide() - 65, 100, Color( 100, 100, 100, 255 ), pnl )
			pnl.RankColor:MoveBelow( pnl.Derive, 4 )
			
		pnl.Flags = exsto.CreateListView( 4, 0, pnl:GetWide() - 8, 150, pnl )
			pnl.Flags:MoveBelow( pnl.RankColor, 4 )
			pnl.Flags:AddColumn( "" )
			pnl.Flags:SetHideHeaders( true )
			
		-- Populate the RankSelect with our ranks.
		for ID, data in pairs( exsto.Ranks ) do
			if id != "srv_owner" then pnl.RankSelect:AddChoice( data.Name ) end
		end
	end
	
	local function updateContent( rank )
		local pnl = PLUGIN.Page.Content
		
		PrintTable( rank )
	end

	function PLUGIN:Init()
		self.Page = exsto.Menu.CreatePage( "rankeditor", editorInit )
			self.Page:SetTitle( "Rank Editor" )
			self.Page:SetSearchable( true )
	end

end

PLUGIN:Register()