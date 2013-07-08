local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Player Join Messages",
	ID = "plyjoinmsg",
	Desc = "Nodex shit.",
	Owner = "Prefanatic",
} )

local function loadGeoIP()
	local succ, err = pcall( require, "geoip" )
	if !succ then
		exsto.Error( "Unable to load GeoIP module.  If you want to display countries on connect, you need this." )
	end	
end

local function dispCountryOnChange( old, new )
	if new == true and not GeoIP then
		loadGeoIP()
	end
	return true
end

function PLUGIN:Init()
	-- Variables
	self.IPStyle = exsto.CreateVariable( "ExIPOnConnect", 
		"Display IP on connect", 
		"disabled", 
		"Designates what style of IP on connect shows up.\n - 'disabled' : Does nothing.\n - 'admins-only' : Displays IP for admins only.\n - 'all' : Displays IP for everybody."
	)
		self.IPStyle:SetCategory( "Join Messages" )
		self.IPStyle:SetPossible( "disabled", "admins-only", "all" )
	
	self.Country = exsto.CreateVariable( "ExCountryOnConnect",
		"Display origin country on connect",
		0,
		"Designates if user's countries are shown on connect.  The GeoIP module is needed for this."
	)
		self.Country:SetCallback( dispCountryOnChange )
		self.Country:SetBoolean()
		self.Country:SetCategory( "Join Messages" )
	
	if not GeoIP and self.Country:GetValue() == 1 then 
		loadGeoIP()
	end
end

function PLUGIN:ExPlayerConnect( data )
	local var = self.IPStyle:GetValue()
	local countryVar = self.Country:GetValue()
	local append = "has connected!"
	local name = data.name
	local addr = data.address

	exsto.UserDB:GetRow( data.networkid, function( q, d )
		if !d then append = "has connected for the first time!" end
		
		local countryStyle = ""
		if GeoIP and countryVar == true then
			local data = GeoIP.Get( string.Explode( ":", addr )[1] )
			countryStyle = "[" .. data.country_name .. "] "
		end
		
		if var == "admins-only" then
			for _, ply in ipairs( player.GetAll() ) do
				if ply:IsAdmin() then
					ply:Print( exsto_CHAT, COLOR.NAME, name, " (", addr, ") ", countryStyle, COLOR.NORM, append )
				else
					ply:Print( exsto_CHAT, COLOR.NAME, name, " ", countryStyle, COLOR.NORM, append );
				end
			end
			return
		elseif var == "all" then
			exsto.Print( exsto_CHAT_ALL, COLOR.NAME, name, " (", addr, ") ", countryStyle, COLOR.NORM, append );
			return
		end
		
		exsto.Print( exsto_CHAT_ALL, COLOR.NAME, name, " ", countryStyle, COLOR.NORM, append );
	end )

end

PLUGIN:Register()
