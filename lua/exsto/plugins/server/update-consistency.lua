local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Consistency",
	ID = "crccheck",
	Desc = "Maintains Exsto consistency by checking pre-built CRC's against runtime CRC's.  Lets you know if your Exsto has been tampered or is out of date.",
	Owner = "Prefanatic",
	CleanUnload = true;
} )

function PLUGIN:Init()

	self.UpdateDelay = exsto.CreateVariable( "ExConsistencyDelay", "Delay", 60, "How often Exsto checks to maintain consistency (updates, modifications, etc).  Set to 0 to disable." )
		self.UpdateDelay:SetUnit( "(minutes)" )
		self.UpdateDelay:SetCategory( "Consistency" )
		self.UpdateDelay:SetMin( 0 )
		self.UpdateDelay:SetMax( 200 )
		
	self.PasteID = "9yYQ9yhS"
	
	self.NextUpdate = CurTime() + self.UpdateDelay:GetValue() * 60
		
	self.StartupEnabled = exsto.CreateVariable( "ExCheckConsistencyOnStartup", "Check on Startup", 1, "Enable to allow Exsto to check consistency on startup and notify of any invalidations." )
		self.StartupEnabled:SetBoolean()
		self.StartupEnabled:SetCategory( "Consistency" )
		
	exsto.CreateFlag( "crcinvalnotify", "Users with this flag will be notified of the invalid CRC checks that occur." )
		
	if self.StartupEnabled:GetValue() == 1 then -- Check and make sure our generated CRC matches what the mothership calls for.
		function self.ExGamemodeFound() self:FetchCRC( true ) end
	end
	
end

function PLUGIN:Think()
	if self.NextUpdate < CurTime() then
		self.NextUpdate = CurTime() + self.UpdateDelay:GetValue() * 60
		
		self:FetchCRC();
	end
end

function PLUGIN:CompareCRC()
	if not self.CRC then self:Print( "We haven't retreived the global CRC yet.  Waiting..." ) return false end
	local crc = self:GenerateCRC();
	local invalid = {}
	
	for f, c in pairs( crc ) do
		if self.CRC[ f ] then
			if ( self.CRC[ f ] != c ) and not f:find( "consistency.lua" ) then -- Invalidation
				table.insert( invalid, { File = f, Global = self.CRC[ f ], Local = c } )
			end
		end
	end
	
	if #invalid > 0 then -- Notify of the invalidations.
		self:Error( "Invalidations found!  CRC errors exist on the following files." )
		
		
		local msg = "Invalid files:\n"
		for I = 1, #invalid do
			msg = msg .. invalid[ I ].File .. "\n"
		end
		self:Print( COLOR.GREY, msg )
		self:Print( "Exsto has either been ", COLOR.NAME, "modified", COLOR.WHITE, " or ", COLOR.NAME, "an update exists", COLOR.WHITE, "." )
		self:Print( "If you've ", COLOR.NAME, "modified", COLOR.WHITE, " Exsto, consider submitting your changes upstream to the github!" )
		
		-- Notify those who have the crcinvalnotify flag
		for _, ply in ipairs( player.GetAll() ) do
			if ply:IsAllowed( "crcinvalnotify" ) then 
				ply:Print( exsto_CHAT, COLOR.NAME, "Warning, ", COLOR.NORM, "CRC checks failed.  An update is availible, or Exsto has been modified.  ", COLOR.NAME, "Suspect files have been printed to your console." )
				local msg = "Invalid files:\n"
				for I = 1, #invalid do
					msg = msg .. invalid[ I ].File .. "\n"
				end
				ply:Print( exsto_CLIENT, ply, msg )
			end
		end
		
		return 1
	else
		self:Print( "No invalidations found!  You're up to date and running an unmodified version :)" )
		return 2
	end
end

function PLUGIN:FetchCRC( checkAfter )
	-- Call the mothership
	http.Fetch( "http://www.pastebin.com/raw.php?i=" .. self.PasteID, function( contents )
		-- Contents is the location of the CRC thing.  Run fetch again to grab it.
		print( contents )
		http.Fetch( "http://www.pastebin.com/raw.php?i=" .. contents, function( contents )
			local data = von.deserialize( contents )
			if not data then
				self:Error( "Unable to deserialize CRC contents.  Dropbox is most likely down, or I goofed." )
				return
			end
			self:Debug( "Global CRC info received.", 1 )
			
			if checkAfter then -- Check our CRC.
				timer.Simple( 0.1, function() self:CompareCRC() end )
			end
			
			self.CRC = data;
		end )
	end )
end

local function recursive( loc )
	local tmp = {}
	local files, directories = file.Find( loc, "LUA" )
	for _, l in ipairs( files ) do table.insert( tmp, loc:Replace( "*", "" ) .. l ) end
	for _, l in ipairs( directories ) do table.Add( tmp, recursive( loc:Replace( "*", "" ) .. l .. "/*" ) ) end
	return tmp
end

function PLUGIN:GenerateCRC()
	-- Generate a list of files to generate CRC for.  This should output us our lua subdirectory, and we can just loop through from here.
	local f = recursive( "exsto/*" )

	-- Loop through each one of these and create a CRC for it.
	local crc = {}
	for _, l in ipairs( f ) do
		crc[ l ] = util.CRC( file.Read( l, "LUA" ) )
	end
	
	return crc
end

function PLUGIN:OutputCRC( caller )
	caller:Print( exsto_CHAT, "Generating CRC contents.  This might hold the server up a little bit." )
	
	local crc = von.serialize( self:GenerateCRC() )
	caller:Print( exsto_CHAT, "CRC generated.  Uploading." )
	
	local date = os.date( "%m-%d-%y" )
	local time = tostring( os.date( "%H:%M:%S" ) )
	
	exsto.CreatePaste( date .. " [" .. time .. "]", crc, function( id )
		if caller:IsPlayer() then
			caller:Print( exsto_CHAT, "Uploaded.  Pastebin ID copied to clipboard." )
			caller:SendLua( "SetClipboardText( \"" .. id .. "\" )" )
		else
			caller:Print( exsto_CHAT, "Uploaded.  Pastebin ID: " .. id )
		end
	end )

end
PLUGIN:AddCommand( "createcrc", {
	Call = PLUGIN.OutputCRC,
	Console = { "createcrc" },
	Category = "Development";
} )

PLUGIN:Register()