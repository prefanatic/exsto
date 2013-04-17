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
	
	end
	function PLUGIN:ExRequestPluginList( reader )
		return reader:ReadSender():IsAllowed( "pluginpage" )
	end

	
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
		
		if line.Info.Data.Status == "disabled" then surface.SetMaterial( PLUGIN.Materials.Red ) else surface.SetMaterial( PLUGIN.Materials.Green ) end
		
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
			
		pnl.List.LineSelected = function( o, disp, data, line )
			-- Disable/Enable.
		end
		
		invalidate( PLUGIN.Page )
	end
	
	local function onShowtime( page )
		exsto.CreateSender( "ExRequestPluginList" ):Send()
	end
	
	local function receivePluginList( reader )
		pnl.List:Clear()
		
		for I = 1, #reader:ReadShort() do
			pnl.List:AddRow( { reader:ReadString() }, { Status = reader:ReadString() } )
		end
		pnl.List:SortByColumn( 1 )
		invalidate( PLUGIN.Page )
	end
	exsto.CreateReader( "ExRecPluginList", receivePluginList )

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