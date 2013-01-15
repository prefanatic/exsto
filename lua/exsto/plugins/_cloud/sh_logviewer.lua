 -- Exsto
 -- Log Viewer

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Log Viewer",
	ID = "logview",
	Desc = "A plugin that creates the log viewer page.",
	Owner = "Prefanatic",
} )

if SERVER then

	function PLUGIN.RequestLogs()
	end

else

end
PLUGIN:Register()
