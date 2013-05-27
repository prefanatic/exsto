local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Force DL",
	ID = "forcedl",
	Desc = "Allows server owners to put files to download in a .txt.",
	Owner = "Prefanatic",
} )

PLUGIN.DefaultDownloadsText = [[;This is where you put the files you want to force download to clients.
;Format pretty much emulates that of ULX's implementation of this for easy transfer from ULX --> Exsto.
;The ';' is a comment which makes the plugin ignore the line.
;Put the location of the files you want to download here, separated by a new line, such as the following:
;materials/exsto <-- This will add a folder.
;materials/exsto/gradient.png <-- This will add a specific file.


]]

function PLUGIN:Init()
	self.ForceDL = {}
	
	-- Create the default if it doesn't exist
	if !file.Read( "exsto/force_download.txt", "DATA" ) then
		file.Write( "exsto/force_download.txt", self.DefaultDownloadsText )
	end
	
	-- Read our little file.
	local f = file.Read( "exsto/force_download.txt", "DATA" ):Trim()
	
	-- Clean it
	local tbl = string.Explode( "\n", f )
	
	-- Remove commented files
	for _, str in ipairs( tbl ) do
		if str:Trim():Left( 1 ) != ";" then table.insert( self.ForceDL, str:Trim() ) end
	end
	
	-- Loop through or table and add the resources.
	for _, str in ipairs( self.ForceDL ) do
		self:AddResource( str )
	end
end

function PLUGIN:AddResource( loc )
	if file.IsDir( loc, "GAME" ) then 
		for _, f in ipairs( file.Find( loc ..  "/*", "GAME" ) ) do
			self:AddResource( loc .. "/" .. f ) 
		end
		return
	end
	
	resource.AddFile( loc )
end

PLUGIN:Register()