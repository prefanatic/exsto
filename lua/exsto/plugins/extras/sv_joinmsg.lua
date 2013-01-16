local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Player Join Messages",
	ID = "plyjoinmsg",
	Desc = "Nodex shit.",
	Owner = "Prefanatic",
} )

PLUGIN:AddVariable( {
	Pretty = "Display IP on connect",
	Dirty = "ip-on-connect",
	Default = "disabled",
	Description = "This changed what IP will be displayed on connect.",
	Possible = { "disabled", "admins-only", "all" },
} )

PLUGIN:AddVariable( {
	Pretty = "Display Country on connect",
	Dirty = "country-on-connect",
	Default = "disabled",
	Description = "This designates if countries are shown on connect.",
	Possible = { true, false },
} )

PLUGIN:AddVariable( {
	Pretty = "Hatred",
	Dirty = "hatred-connect",
	Default = true,
	Description = "This designates if countries are shown on connect.",
	Possible = { true, false },
} )

function PLUGIN:Init()
	if !GeoIP then require( "geoip" ) end
end

function PLUGIN:PlayerConnect( name, addr )
	local var = exsto.GetVar( "ip-on-connect").Value
	local countryVar = exsto.GetVar( "country-on-connect" ).Value
	local append = "has connected!"
	
	--local rank = exsto.UserDB:GetData( steamid, "Rank" ) -- To see if we've been here.
	--if !rank then append = "has connected for the first time!" end
	
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
	
	if exsto.GetVar( "hatred-connect" ).Value == true and name == "Hatred" then
		exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "Please, don't feed the ", COLOR.NAME, "old man." )
	end

end

PLUGIN:Register()
