 -- Exsto
 -- Reload Plugin Plugin (lol)

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Plugin Controls",
	ID = "plugcontrols",
	Desc = "A plugin that provides reloading support for plugins, and a plugin menu!",
	Owner = "Prefanatic",
} )

if SERVER then

	function PLUGIN:Init()
	
		util.AddNetworkString( "ExRecPluginList" )
		util.AddNetworkString( "ExRequestPluginList" )
		util.AddNetworkString( "ExTogglePlugin" )
	
	end
	function PLUGIN:ExRequestPluginList( reader )
		return reader:ReadSender():IsAllowed( "pluginpage" )
	end
	function PLUGIN:ExTogglePlugin( reader )
		return reader:ReadSender():IsAllowed( "pluginpage" )
	end
	
	function PLUGIN:SendPluginList( reader )
		local ply = reader:ReadSender()
		
		self:Debug( "Sending plugin list to '" .. ply:Nick() .. "'", 1 )
		local sender = exsto.CreateSender( "ExRecPluginList", ply )
			sender:AddShort( #exsto.Plugins )
			for _, plug in ipairs( exsto.Plugins ) do
				sender:AddString( plug:GetName() )
				sender:AddShort( plug:IsEnabled() and 1 or 0 )
				sender:AddString( plug:GetID() )
				sender:AddShort( plug:CanCleanlyUnload() and 1 or 0 )
			end
		sender:Send()
	end
	PLUGIN:CreateReader( "ExRequestPluginList", PLUGIN.SendPluginList )
	
	function PLUGIN:TogglePlugin( reader )
		local ply = reader:ReadSender()
		local id = reader:ReadString()
		local status = reader:ReadBoolean()
		
		local plug = exsto.GetPlugin( id )
		
		if !plug then return end
		self:Debug( "Setting plugin '" .. plug:GetName() .. "' to status '" .. tostring( status ) .. "' triggered by '" .. ply:Nick() .. "'", 1 )
		
		if status == false then
			plug:Disable()
		else
			plug:Enable()
		end
		
		self:SendPluginList( reader )
	end
	PLUGIN:CreateReader( "ExTogglePlugin", PLUGIN.TogglePlugin )

	
elseif CLIENT then

	local function invalidate( cont )
		local pnl = cont.Content
		if !pnl then PLUGIN:Error( "Oh no!  Attempted to access invalid page contents." ) return end
		
		pnl.List:SetDirty( true )
		pnl.List:InvalidateLayout( true )
		
		pnl.List:SizeToContents()
		
		pnl.Cat:InvalidateLayout( true )
	end

	local function lineOver( line )
		surface.SetDrawColor( 255, 255, 255, 255 )
		
		if line.Info.Data.Enabled == 0 then surface.SetMaterial( PLUGIN.Materials.Red ) else surface.SetMaterial( PLUGIN.Materials.Green ) end
		
		surface.DrawTexturedRect( 5, (line:GetTall() / 2 ) - 3, 8, 8 )
	end

	local function pageInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Plugins" )
		
		pnl.List = vgui.Create( "ExListView", pnl.Cat )
			pnl.List:DockMargin( 4, 0, 4, 0 )
			pnl.List:Dock( TOP )
			pnl.List:DisableScrollbar()
			pnl.List:AddColumn( "" )
			pnl.List:SetHideHeaders( true )
			pnl.List:SetQuickList()
			pnl.List:LinePaintOver( lineOver )
			pnl.List:SetTextInset( 25 )
			pnl.List.Populate = function( o, search )
				o:Clear()
				for I = 1, #PLUGIN.PluginList do
					if PLUGIN.PluginList[ I ].name:lower():find( search:lower() ) then
						o:AddRow( { PLUGIN.PluginList[ I ].name }, { Enabled = PLUGIN.PluginList[ I ].status, ID = PLUGIN.PluginList[ I ].id, CleanUnload = PLUGIN.PluginList[ I ].clean } )
					end
				end
				o:SortByColumn( 1 )
				invalidate( PLUGIN.Page )
			end
			
		local function push( data )
			local sender = exsto.CreateSender( "ExTogglePlugin" )
				sender:AddString( data.ID )
				sender:AddBoolean( not tobool( data.Enabled ) )
			sender:Send()
		end
		
		pnl.List.LineSelected = function( o, disp, data, line )
			PrintTable( data )
			if data.CleanUnload == 0 and tobool( data.Enabled ) == true then
				PLUGIN.Page:Alert( "Warning!  This plugin cannot unload cleanly due to developmental error.  A server restart is RECOMMENDED in order to disable.",
					function()
						push( data )
					end
				)
			else
				push( data )
			end
		end
		
		invalidate( PLUGIN.Page )
	end
	
	local function onShowtime( page )
		exsto.CreateSender( "ExRequestPluginList" ):Send()
	end
	
	local function receivePluginList( reader )
		local pnl = PLUGIN.Page.Content
		if !pnl then return end
		
		local tbl = {}
		for I = 1, reader:ReadShort() do
			table.insert( tbl, { name = reader:ReadString(), status = reader:ReadShort(), id = reader:ReadString(), clean = reader:ReadShort() } )
		end
		
		PLUGIN.PluginList = tbl;
		
		pnl.List:Populate( "" )
	end
	exsto.CreateReader( "ExRecPluginList", receivePluginList )
	
	local function onSearch( e )
		PLUGIN.Page.Content.List:Populate( e:GetValue() )
	end

	function PLUGIN:Init()
		self.Page = exsto.Menu.CreatePage( "pluginpage", pageInit )
			self.Page:SetTitle( "Plugins" )
			self.Page:SetSearchable( true )
			self.Page:OnShowtime( onShowtime )
			self.Page:OnSearchTyped( onSearch )
			
		self.Materials = {
			Red = Material( "exsto/red.png" );
			Green = Material( "exsto/green.png" );
		}
	
	end
	
end

PLUGIN:Register()