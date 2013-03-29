local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Database Settings",
	ID = "felsettings",
	Desc = "Database Settings",
	Owner = "Prefanatic",
} )

if SERVER then

	function PLUGIN:Init()
	
	end	

end

if CLIENT then
	
	function PLUGIN:Init()
		self.MainPage = exsto.Menu.CreatePage( "felsettings", 
	
end

PLUGIN:Register()