
surface.CreateFont( "arial", 18, 700, true, false, "ExCloud_Title" )
surface.CreateFont( "arial", 16, 700, true, false, "ExCloud_Author" )
local textCol = Color( 99, 99, 99, 255 )
local bgCol = Color( 204, 204, 204, 51 )

-- ITLF: We make local functions.
local build = {}

function build.Ping()
	if !exsto.Cloud.ServerData then
		timer.Simple( 0.5, build.Ping )
		return
	end
	
	if exsto.CloudPanel.ClientQueueDownload then -- Easy Check
		exsto.CloudPanel.PluginContent:Populate( 1 )
		exsto.CloudPanel:EndLoad()
		return
	end
	
	build.Build()
	exsto.CloudPanel:EndLoad()
end

function build.Refresh()
	if exsto.CloudPanel then
		exsto.CloudPanel:PushLoad()
	end
	
	-- Clean?
	exsto.Cloud.ServerData = nil
	
	exsto.Cloud.GrabPluginList()
	build.Ping()
end

function build.ShowHelp()
	if !exsto.CloudPanel then return end
	
	file.Write( "exsto_tmp/cloud_help_shown.txt", "yes" )
	Menu:PushNotify( "To get started on this adventure,\n1. Click on the plugin you wish to retrieve.\n2.Click on the \"Install\" button.\nSimple, right?" )
end

function build.Build()
	local panel = exsto.CloudPanel

	panel._hovering = false
	panel._lastHoverTime = 0

	panel.Secondary = panel:RequestSecondary()
	Menu:HideSecondaries()
	
	panel:SetRefresh( build.Refresh )

	exsto.CloudPanel.ClientQueueDownload = {}
	exsto.CloudPanel.ClientQueueDelete = {}
	
	panel.HeaderBar = exsto.CreatePanel( 10, 5, panel:GetWide() - 20, 24, nil, panel )
		panel.HeaderBar.CurrentPage = 1
		panel.HeaderBar.Paint = function( self )
			if !self.col then self.col = Color( 221, 221, 221, 190 ) end
			draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), self.col )
			
			--[[if !self.texid then self.texid = surface.GetTextureID( "exsto/cloudicon" ) end
			surface.SetDrawColor( 221, 221, 221, 255 )
			surface.SetTexture( self.texid )
			surface.DrawTexturedRect( 0, 0, 63, 30 )]]
		end
		
		panel.HeaderBar.SearchBar = exsto.CreateTextEntry( 2, 2, 160, 19, panel.HeaderBar )
			panel.HeaderBar.SearchBar:SetText( "search" )
			panel.HeaderBar.SearchBar.DoMousePressed = function( self ) if self:GetValue() == "search" then self:SetText( "" ) end end
		panel.HeaderBar.SearchGo = exsto.CreateSysButton( 165, 2, 19, 19, "right", panel.HeaderBar )
		
		-- Backwards to center from here on
		panel.HeaderBar.NextPage = exsto.CreateButton( panel.HeaderBar:GetWide() - 35, 2, 33, 19, ">>", panel.HeaderBar )
			panel.HeaderBar.NextPage:SetStyle( "positive" )
			panel.HeaderBar.NextPage.OnClick = function( self )
				if panel.HeaderBar.CurrentPage == #panel.PluginContent.Controls then return end

				for _, obj in ipairs( panel.PluginContent.Controls[ panel.HeaderBar.CurrentPage ] ) do
					local x, y = obj:GetPos()
					obj:SetPos( -400, y )
					//obj:SetVisible( false )
				end
				
				panel.HeaderBar.CurrentPage = panel.HeaderBar.CurrentPage + 1
				--for _, obj in ipairs( panel.PluginContent.Controls[ panel.HeaderBar.CurrentPage ] ) do
					//obj:SetVisible( true )
					--InvalidatePlugs
				--end
				panel.PluginContent:InvalidatePlugs( panel.HeaderBar.CurrentPage )
				
				panel.HeaderBar.PageCount:SetText( "Page " .. panel.HeaderBar.CurrentPage .. " of " .. #panel.PluginContent.Controls )
			end
				
		panel.HeaderBar.PrevPage = exsto.CreateButton( 0, 2, 33, 19, "<<", panel.HeaderBar )
			panel.HeaderBar.PrevPage:SetStyle( "positive" )
			panel.HeaderBar.PrevPage:MoveLeftOf( panel.HeaderBar.NextPage, 4 )
			panel.HeaderBar.PrevPage.OnClick = function( self )
				if panel.HeaderBar.CurrentPage == 1 then return end

				for _, obj in ipairs( panel.PluginContent.Controls[ panel.HeaderBar.CurrentPage ] ) do
					local x, y = obj:GetPos()
					obj:SetPos( 800, y )
					--obj:SetVisible( false )
				end
				
				panel.HeaderBar.CurrentPage = panel.HeaderBar.CurrentPage - 1
				--for _, obj in ipairs( panel.PluginContent.Controls[ panel.HeaderBar.CurrentPage ] ) do
				--	obj:SetVisible( true )
				--end
				panel.PluginContent:InvalidatePlugs( panel.HeaderBar.CurrentPage )
				
				panel.HeaderBar.PageCount:SetText( "Page " .. panel.HeaderBar.CurrentPage .. " of " .. #panel.PluginContent.Controls )
			end
		
		panel.HeaderBar.PageCount = exsto.CreateLabel( 0, 4, "Page 1 of 1", "ExGenericText18", panel.HeaderBar )
			panel.HeaderBar.PageCount:MoveLeftOf( panel.HeaderBar.PrevPage, 10 )
	
	local function nullFunc() end
	local function onPluginClick( objButton )
		panel.InfoScheme:SetVisible( true )
		
		if panel.InfoScheme.ActiveObject and panel.InfoScheme.ActiveObject:IsValid() then
			panel.InfoScheme.ActiveObject:Neutral()
		end
		
		panel.InfoScheme.ActiveObject = objButton:GetParent()
		panel.InfoScheme.ActiveObject:Accept()
		
		panel.InfoScheme.Title:SetText( objButton:GetParent().Data.Name )
		panel.InfoScheme.Author:SetText( objButton:GetParent().Data.Author )
		panel.InfoScheme.Description:SetText( objButton:GetParent().Data.Description )
		panel.InfoScheme.DownloadCount:SetText( objButton:GetParent().Data.Downloads .. " Downloads" )
		panel.InfoScheme.Version:SetText( "Revision " .. objButton:GetParent().Data.Version )
			//panel.InfoScheme.Version:MoveRightOf( panel.InfoScheme.DownloadCount, 50 )
			
		if objButton:GetParent().ServerPlug then
			panel.Secondary.Delete:SetVisible( true )
			panel.Secondary.Download:SetVisible( false )
		else
			panel.Secondary.Delete:SetVisible( false )
			panel.Secondary.Download:SetVisible( true )
		end
			
	end
	
	local gradColHigh = Color( 249, 249, 249, 255 )
	local gradColLow = Color( 236, 236, 236, 255 )
	local outline = Color( 226, 226, 226, 255 )
	local outlineInstalled = Color( 42, 197, 0, 255 )
	local function onPluginObjPaint( obj )
		draw.RoundedBox( 4, 0, 0, obj:GetWide(), obj:GetTall(), obj.Installed and outlineInstalled or outline ) 
		draw.RoundedBox( 4, 1, 1, obj:GetWide() - 2, obj:GetTall() - 2, gradColLow )
		
		surface.SetTexture( exsto.Textures.GradDown )
		draw.TexturedRoundedBox( 4, 1, 1, obj:GetWide() - 2, obj:GetTall() - 2, gradColHigh )
		
		draw.SimpleText( obj.Data.Name, "ExGenericText20", 5, 5, textCol )
		
		surface.SetTexture( exsto.Textures[ obj.IconStyle ] )
		if obj.IconStyle == "CloudDownloading" then
			surface.DrawTexturedRectRotated( obj:GetWide() - 13, 14, 16, 16, math.cos( CurTime() * 5 ) * 45 )
		else
			surface.DrawTexturedRect( obj:GetWide() - 20, 5, 16, 16 )
		end
	end
	
	local function onPluginClick( obj )
		if table.HasValue( exsto.CloudPanel.ClientQueueDownload, obj ) or table.HasValue( exsto.CloudPanel.ClientQueueDelete, obj ) then
			return end
			
		if !obj.Installed then
			RunConsoleCommand( "exsto", "getplug", obj.Data.Identify )
		
			obj.IconStyle = "CloudDownloading"
			exsto.CloudPanel.ClientQueueDownload[ #exsto.CloudPanel.ClientQueueDownload + 1 ] = obj
		else
			RunConsoleCommand( "exsto", "delplug", obj.Data.Identify )
			
			obj.IconStyle = "CloudDeleting"
			exsto.CloudPanel.ClientQueueDelete[ #exsto.CloudPanel.ClientQueueDelete + 1 ] = obj
		end
	end
	
	-- Content for the secondary
	panel.Secondary.Author = exsto.CreateLabel( 5, 3, "Author,", "ExGenericText18", panel.Secondary )
	panel.Secondary.AuthorName = exsto.CreateLabel( 7, 15, "UNKNOWN", "ExGenericText16", panel.Secondary )
	
	panel.Secondary.Desc = exsto.CreateLabel( 5, 35, "UNKNOWN", "ExGenericTextNoBold16", panel.Secondary )
		panel.Secondary.Desc:SetContentAlignment( 7 )
		panel.Secondary.Desc:SetWrap( true )
		
	
	panel.Secondary.Update = function( secondary, obj )
		secondary.AuthorName:SetText( obj.Data.Author )
		secondary.AuthorName:SizeToContents()
		
		secondary.Desc:SetText( obj.Data.Description )
		secondary.Desc:SetSize( panel.Secondary:GetWide() - 10, 300 )
	end

	local function tmrDelay( obj )
		Menu:HideSecondaries()

		panel._lastHoverTime = CurTime()
		panel._hovering = false
	end

	local function onPluginEnter( obj )
		if panel._hovering then 
			panel.Secondary:Update( obj )
			timer.Destroy( "pnlHoverCloud" )
			return 
		end

		panel._hovering = true
		Menu:BringBackSecondaries()
	end

	local function onPluginExit( obj )
		timer.Create( "pnlHoverCloud", 1.5, 1, tmrDelay, obj )
	end
	
	panel.PluginContent = exsto.CreatePanel( 5, 50, panel:GetWide() - 10, panel:GetTall() - 40, Color( 0, 0, 0, 0 ), panel )
		panel.PluginContent.Populate = function( pnl, enum )
			if pnl.Controls then
				for I = 1, #pnl.Controls do
					for _, obj in pairs( pnl.Controls[ I ] ) do
						if obj:IsValid() then obj:Remove() end
					end
				end
				panel.HeaderBar.CurrentPage = 1
			end
			
			pnl.Controls = {}
			
			local curPage = 1
			local curY = 0
			local tbl = table.Copy( exsto.Cloud.ServerData )
				table.SortByMember( tbl, "Name", true ) 
			for _, data in pairs( tbl ) do
				pnl.Controls[ curPage ] = pnl.Controls[ curPage ] or {}
				
				if #pnl.Controls[ curPage ] == 16 then
					curPage = curPage + 1
					pnl.Controls[ curPage ] = {}
					
					curY = 0
				end
				
				if #pnl.Controls[ curPage ] == 8 then curY = 0 end

				local obj = exsto.CreateButton( curPage == 1 and ( #pnl.Controls[ curPage ] < 8 and 5 or 310 ) or ( pnl:GetWide() + 20 ), curY, ( pnl:GetWide() / 2 ) - 20, 27, "", pnl )
					obj.Data = data
					obj.Paint = onPluginObjPaint
					obj.DoClick = onPluginClick
					obj.OnCursorEntered = onPluginEnter
					obj.OnCursorExited = onPluginExit
					
					Menu:CreateAnimation( obj )
					
					-- Get the icon style for him
					if exsto.Cloud.ServerPlugins then
						for _, svData in pairs( exsto.Cloud.ServerPlugins ) do
							if data.Identify == svData.Identify then -- WOAH!
								obj.IconStyle = "CloudActivated"
								obj.Installed = true
							end
						end
					end
					if !obj.IconStyle then -- Hes not on the server, choose from verified or unverified.
						if data.Verified == 1 then obj.IconStyle = "CloudVerified" end
						if !obj.IconStyle then obj.IconStyle = "CloudNotVerified" end
					end
					
				curY = curY + 34
					
				pnl.Controls[ curPage ][ #pnl.Controls[ curPage ] + 1 ] = obj
				if curPage != 1 then obj:SetVisible( false ) end
				
				obj:FadeOnVisible( true )
			end
			
			panel.HeaderBar.PageCount:SetText( "Page 1 of " .. #pnl.Controls )

		end
		panel.PluginContent:Populate()
		
		panel.PluginContent.InvalidatePlugs = function( pnl, pg )
			local curY = 0
			-- Sort through the PLUGINS on that PAGE.
			for _, obj in pairs( pnl.Controls[ pg ] ) do
				if _ == 9 then curY = 0 end
				obj:SetVisible( true )
				
				obj:SetPos( _ < 9 and 5 or 310, curY )
				curY = curY + 34
			end
		end

	panel.InfoScheme = Menu:CreateColorPanel( ( panel:GetWide() / 2 ) + 5, 5, ( panel:GetWide() / 2 ) - 10, panel:GetTall() - 20, panel )
		panel.InfoScheme:SetVisible( false )
		panel.InfoScheme:FadeOnVisible( true )
		
		panel.InfoScheme.Title = exsto.CreateLabel( 5, 10, "Title", "ExGenericText24", panel.InfoScheme )
			panel.InfoScheme.Title:SetWide( panel.InfoScheme:GetWide() - 5 )
		panel.InfoScheme.By = exsto.CreateLabel( 5, 40, "by: ", "ExGenericText14", panel.InfoScheme )
		panel.InfoScheme.Author = exsto.CreateLabel( 25, 40, "Author", "ExGenericText20", panel.InfoScheme )
			panel.InfoScheme.Author:SetWide( panel.InfoScheme:GetWide() - 5 )
			
		panel.InfoScheme.ScrollController = exsto.CreatePanelList( 5, 80, panel.InfoScheme:GetWide() - 5, 100, 5, false, true, panel.InfoScheme )
			panel.InfoScheme.ScrollController.Paint = nullFunc
			
		panel.InfoScheme.Description = exsto.CreateLabel( 5, 90, "Description", "ExGenericText14" )	
			panel.InfoScheme.Description:SetSize( panel.InfoScheme:GetWide(), 100 )
			panel.InfoScheme.Description:SetContentAlignment( 7 )
			panel.InfoScheme.Description:SetWrap( true )
			panel.InfoScheme.ScrollController:AddItem( panel.InfoScheme.Description )
		
		panel.InfoScheme.DownloadCount = exsto.CreateLabel( 5, panel.InfoScheme:GetTall() - 20, "0 Downloads", "ExGenericText18", panel.InfoScheme )
		panel.InfoScheme.Version = exsto.CreateLabel( panel.InfoScheme:GetWide() - 20, panel.InfoScheme:GetTall() - 20, "Revision 1", "ExGenericText18", panel.InfoScheme )
			panel.InfoScheme.Version:Dock( RIGHT )
			panel.InfoScheme.Version:DockMargin( 0, ( panel.InfoScheme:GetTall() / 2 ) + 140, 5, 5 )
end

-- Little hook stuff to display when the plugin downloads, for the menu.
local function UpdatePanel( data )
	if exsto.CloudPanel then
		for _, qData in ipairs( exsto.CloudPanel.ClientQueueDownload ) do
			if qData.Data.Identify == data.Identify then
				qData.Installed = true
				qData.IconStyle = "CloudActivated"
				Menu:PushNotify( qData.Data.Name .. " has downloaded!" )
				
				timer.Simple( 0.1, table.remove, exsto.CloudPanel.ClientQueueDownload, _ )
			end
		end
	end
end
hook.Add( "ExServerPlugReceived", "ExUpdatePanel", UpdatePanel )
hook.Add( "ExPlugDownloaded", "ExUpdatePanel", UpdatePanel )

local function RefreshPanel( data )
	if exsto.CloudPanel then
		for _, qData in ipairs( exsto.CloudPanel.ClientQueueDelete ) do
			if qData.Data.Identify == data.Identify then
				qData.Installed = false
				qData.IconStyle = qData.Data.Verified == 1 and "CloudVerified" or "CloudNotVerified"
				Menu:PushNotify( qData.Data.Name .. " has been deleted!" )
				
				timer.Simple( 0.1, table.remove, exsto.CloudPanel.ClientQueueDelete, _ )
			end
		end
	end
end
hook.Add( "ExClientPlugRemoved", "ExUpdatePanel", RefreshPanel )
--[[
local function PluginFailed( data )
	if exsto.CloudPanel then
		for _, qData in ipairs( exsto.CloudPanel.ClientQueueDownload ) do
			if qData.Data.Identify == data.Identify then
				qData.Installed = true
				qData.IconStyle = "CloudActivated"
				Menu:PushNotify( qData.Data.Name .. " has downloaded!" )
				
				timer.Simple( 0.1, table.remove, exsto.CloudPanel.ClientQueueDownload, _ )
			end
		end
	end
end
hook.Add( "ExPlugExecFail", "ExUpdatePanel", PluginFailed )]]

Menu:CreatePage( {
	Title = "Cloud",
	Short = "cloud",
	},
	function( panel )
		exsto.CloudPanel = panel
		if !exsto.Cloud.ServerData then
			build.Refresh()
		else
			build.Build()
		end
	end
)
function exsto.OpenCloud()
	
end
exsto.CreateReader( "ExOpenCloud", exsto.OpenCloud )

--[[ -----------------------------------
	Category: Server Communication
	----------------------------------- ]]
	
function exsto.Cloud.ClientDownload( reader )
	exsto.Cloud.DownloadPlugin( reader:ReadShort() )
end
exsto.CreateReader( "ExCloudDLWrapper", exsto.Cloud.ClientDownload )

function exsto.Cloud.ClientPluginInit( reader )
	for I = 1, reader:ReadChar() do
		local id, ver, name, author, t, down, desc = reader:ReadChar(), reader:ReadShort(), reader:ReadString(), reader:ReadString(), reader:ReadString(), reader:ReadShort(), reader:ReadString()

		if t != "server" then
			-- Check and see if we have it in our saved table.
			--if !exsto.CloudDB:GetRow( tonumber( id ) ) then
				exsto.CloudDB:AddRow( {
					Name = name;
					Author = author;
					Identify = tonumber( id );
					Version = ver;
					Type = t;
					Downloads = down;
					Description = desc;
				} )
			--end
			
			exsto.Cloud.Execute( id )
			
		end 

		-- We still want to make a note of server plugins.
		exsto.Cloud.ServerPlugins = exsto.Cloud.ServerPlugins or {}
		exsto.Cloud.ServerPlugins[ tonumber( id ) ] = {
			Name = name;
			Author = author;
			Identify = tonumber( id );
			Version = ver;
			Type = t;
			Downloads = down;
			Description = desc;
			Object = t != "server" and exsto.GetLastPluginRegister() or nil;
		}
		
		hook.Call( "ExServerPlugReceived", nil, {
			Name = name;
			Author = author;
			Identify = tonumber( id );
			Version = ver;
			Type = t;
		} )
	end
end
exsto.CreateReader( "ExSendPluginIDS", exsto.Cloud.ClientPluginInit )

function exsto.Cloud.ClientRemovePlug( reader )
	local id = reader:ReadChar()
	hook.Call( "ExClientPlugRemoved", nil, table.Copy( exsto.Cloud.ServerPlugins[ id ] ) )
	
	if exsto.Cloud.ServerPlugins[ tonumber( id ) ].Object then
		exsto.Cloud.ServerPlugins[ tonumber( id ) ].Object:Unload()
	end
	exsto.Cloud.ServerPlugins[ tonumber( id ) ] = nil
end
exsto.CreateReader( "ExDelPlugin", exsto.Cloud.ClientRemovePlug )
	