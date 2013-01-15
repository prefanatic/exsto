local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Advert System",
	ID = "adverts",
	Desc = "Allows for creation of adverts in both chat and banner form.",
	Owner = "Prefanatic",
} )

if SERVER then
	
	function PLUGIN:Init()
		
		self.RunningAds = {}
		
		-- Create database.
		exsto.AdvertDB = FEL.CreateDatabase( "exsto_plugin_adverts", true ) -- Force it SQLite because we don't have support for certain things yet.
			exsto.AdvertDB:ConstructColumns( {
				ID = "VARCHAR(100):primary:not_null";
				Message = "TEXT:not_null";
				Creator = "TEXT:not_null";
				Interval = "INTEGER:not_null";
				Style = "TEXT:not_null";
			} )
		exsto.AdvertDB:SetRefreshRate( 10 * 60 )
		
	end
	
	function PLUGIN:PushAd( id )
		local msg, style = exsto.AdvertDB:GetData( id, "Message, Style" )

		if style == "chat" then
			exsto.Print( exsto_CHAT_ALL, msg )
			return
		end
	end
	
	function PLUGIN:Think()
		-- Loop through the adverts we have stored.
		for k, v in pairs( exsto.AdvertDB:GetAll() ) do
			if !self.RunningAds[ v.ID ] then self.RunningAds[ v.ID ] = CurTime() end -- Key == ID, Value == Last Run Time
			
			if CurTime() > ( self.RunningAds[ v.ID ] + ( v.Interval * 60 ) ) then
				self:PushAd( v.ID )
				self.RunningAds[ v.ID ] = CurTime();
			end
		end
	end
	
	function PLUGIN:RemoveAdvert( caller, id )
		local msg = exsto.AdvertDB:GetData( id, "Message" )
		
		if !msg then
			return { COLOR.NORM, "The advert ", COLOR.NAME, id, COLOR.NORM, " does not exist!" }
		end
		
		exsto.AdvertDB:DropRow( id )
		
		return { COLOR.NORM, "The advert ", COLOR.NAME, id, COLOR.NORM, " has been removed." }
	end
	PLUGIN:AddCommand( "deladvert", { 
		Call = PLUGIN.RemoveAdvert, 
		Desc = "Allows users to remove adverts.", 
		Console = { "deladvert" }, 
		Chat = { "!deladvert" }, 
		ReturnOrder = "ID", 
		Args = {ID = "STRING"}, 
		Category = "Adverts", 
	}) 
	
	function PLUGIN:CreateAdvert( caller, id, msg, interval, style )
		if style != "chat" then
			return { COLOR.NORM, "Invalid style ", COLOR.NAME, style, COLOR.NORM, ".  Must be 'chat' or 'banner'" }
		end
		
		exsto.AdvertDB:AddRow( {
			ID = id;
			Message = msg;
			Creator = caller:SteamID();
			Interval = interval;
			Style = style;
		} )
		
		return { COLOR.NORM, "Added ", COLOR.NAME, id, COLOR.NORM, " to the adverts list!" }
	end
	PLUGIN:AddCommand( "addadvert", { 
		Call = PLUGIN.CreateAdvert, 
		Desc = "Allows users to create adverts.", 
		Console = { "addadvert" }, 
		Chat = { "!addadvert" }, 
		ReturnOrder = "ID-MSG-INTERVAL-STYLE", 
		Args = {ID = "STRING", MSG = "STRING", INTERVAL = "TIME", STYLE = "STRING"}, 
		Optional = {INTERVAL = 5*60, STYLE = "chat"}, 
		Category = "Adverts", 
	}) 
	
end

PLUGIN:Register()