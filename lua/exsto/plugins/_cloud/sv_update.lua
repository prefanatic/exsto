-- Exsto
-- SVN Update'er

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Update",
	ID = "svn-update",
	Desc = "A plugin that allows updating of Exsto!",
	Owner = "Prefanatic",
} )

if !OOSock then require( "oosocks" ) end
if !glon then require( "glon" ) end
if !rawio then require( "rawio" ) end

rawio = nil

PLUGIN.Latest = 0
PLUGIN.OutOfDate = false
PLUGIN.ToSave = {}

function PLUGIN:Init()
	timer.Simple( 2, self.CreateSocket, self )
end

function PLUGIN:CreateSocket()

	-- Create the object.
	if OOSock then
		local lengthSig = "Content-Length: "
		local HTTPLen = 0
		local RecNum = 0
		local MaxBytes = 128
		local CurRec = 0
		local CompiledData = ""
		
		self.Connection = OOSock( IPPROTO_TCP )
		self.Host = "94.23.154.153"
		
		self.Connection:SetCallback( function( socket, callType, callID, err, data, peer, peerPort )
			
			if callType == SCKCALL_CONNECT and err == SCKERR_OK then
				
				exsto.Print( exsto_CONSOLE, "UPDATE --> Successfully connected to the Exsto update list!" )
				
				socket:SendLine( "GET /Exsto/version.php?simple=true HTTP/1.1" )
				socket:SendLine( "Host: " .. self.Host )
				socket:SendLine( "" )
				socket:ReceiveLine()
			end
			
			self.ReceiveData( callType, err, data:Trim(), socket )
		end )
		
		self.ReceiveData = function( callType, err, data, socket )
			if callType == SCKCALL_REC_LINE and err == SCKERR_OK and data != "" then
			
				if string.find( data, "Not Found</title>", 1, true ) then
					self.Callback( nil, socket )
					return
				end

				if string.Left( data, string.len( lengthSig ) ) == lengthSig  then
					HTTPLen = tonumber( string.Right( data, string.len( data ) - string.len( lengthSig ) ) )
					
					-- Create the number of times to do this.
					RecNum = math.ceil( HTTPLen / MaxBytes )
				end
				
				socket:ReceiveLine()
				
			elseif callType == SCKCALL_REC_LINE and err == SCKERR_OK and data == "" then
				socket:Receive( MaxBytes )
			end
			
			if callType == SCKCALL_REC_SIZE then
			
				if string.find( data, "Not Found</title>", 1, true ) then
					self.Callback( nil, socket )
					return
				end
			
				CurRec = CurRec + 1
				CompiledData = CompiledData .. data
				
				if CurRec >= RecNum then
					CurRec = 0
					RecNum = 0
					HTTPLen = 0
					self.Callback( CompiledData, socket )
					CompiledData = ""
				else
					-- Keep it comming
					socket:Receive( MaxBytes )
				end
			end
		end
	end
	
	if !self.Connection then return end
	
	self.Folder = exsto.GetAddonFolder()

	-- Connect to the plugin updater.
	self.Connection:Connect( self.Host, 80 )
	
	-- Set the socket data receive plugin to set the online version.
	self.Callback = function( data, socket ) 
		if !data then
			self.SocketError = true
			exsto.Print( exsto_CONSOLE, "UPDATE --> Couldn't retrieve latest revision!" )
			self.Latest = exsto.VERSION
			return
		end
		
		self.Latest = tonumber( data )
		exsto.Print( exsto_CONSOLE, "UPDATE --> Received latest revision: " .. self.Latest )
	
		-- Check to see if we are out of date.
		if exsto.VERSION < self.Latest then
			exsto.Print( exsto_CONSOLE, "UPDATE --> Exsto is out of date!" )
			self.OutOfDate = true
			self.RevBehind = self.Latest - exsto.VERSION
			self.RevStyle = " revision"
			
			if self.RevBehind > 1 then self.RevStyle = " revisions" end
			
			-- Lets grab all the changes that Exsto has gone through.
			socket:SendLine( "GET /Exsto/version.php?changes=true&old=" .. exsto.VERSION .. "&new=" .. self.Latest .. " HTTP/1.1" )
			socket:SendLine( "Host: " .. self.Host )
			socket:SendLine( "" )
			socket:ReceiveLine()
			
			self.Callback = function( data, socket )	
				if !data then
					self.SocketError = true
					exsto.Print( exsto_CONSOLE, "UPDATE --> Couldn't retrieve changed update list!" )
					return
				end
				
				local tbl = string.Explode( ";", data )
				
				self.ChangedList = {}
				
				for k,v in ipairs( tbl ) do
					if string.Left( v, 1 ) != "" then
						table.insert( self.ChangedList, { Type = string.Left( v, 1 ):Trim(), File = string.sub( v, 2 ):Trim():gsub( "/", "\\" ) } )
					end
				end
				
				exsto.Print( exsto_CONSOLE, "UPDATE --> Received list of changed files!" )
				
			end
		end
		
	end
	
end

function PLUGIN:exsto_InitSpawn( ply )
	if self.OutOfDate then
		-- Notify the server admins on their join.
		if ply:IsAdmin() then
			ply:Print( exsto_CHAT, COLOR.NORM, "New update available!  ", COLOR.NAME, "Revision " .. self.Latest, COLOR.NORM, "!" )
			ply:Print( exsto_CHAT, COLOR.NORM, "Exsto is out of date by ", COLOR.NAME, self.RevBehind .. self.RevStyle, COLOR.NORM, "!" )
		end
	end
end

function PLUGIN:CheckVersion( owner )
	
	owner:Print( exsto_CHAT, COLOR.NORM, "Currently running revision ", COLOR.NAME, tostring( exsto.VERSION ), COLOR.NORM, "!" )
	
	if self.OutOfDate then
		owner:Print( exsto_CHAT, COLOR.NORM, "New update available!  ", COLOR.NAME, "Revision " .. self.Latest, COLOR.NORM, "!" )
		owner:Print( exsto_CHAT, COLOR.NORM, "Exsto is out of date by ", COLOR.NAME, self.RevBehind .. self.RevStyle, COLOR.NORM, "!" )
	end

end
PLUGIN:AddCommand( "checkversion", {
	Call = PLUGIN.CheckVersion,
	Desc = "Allows users to check and see the version of Exsto.",
	Console = { "version" },
	Chat = { "!version" },
	Args = {},
	Category = "Utilities",
})

function PLUGIN:OnFinishDownloads( ply )

	ply:Print( exsto_CHAT, COLOR.NAME, "Exsto ", COLOR.NAME, "Revision: " .. self.Latest, COLOR.NORM, " has finished downloading!" )
	
	if !rawio then
		ply:Print( exsto_CHAT, COLOR.NORM, "The update has been placed in the ", COLOR.NAME, "data folder.", COLOR.NORM, "  Please move it to the correct folders." )
	else
		ply:Print( exsto_CHAT, COLOR.NORM, "Please ", COLOR.NAME, "restart", COLOR.NORM, " the server to see the update changes!" )
	end
	
end

local relative
function PLUGIN:BuildFolderStructure()

	if rawio then
	
		relative = util.RelativePathToFull( "addons" )
		
		if !file.Exists( relative .. "\\" .. self.Folder ) then
			rawio.mkdir( relative .. "\\" .. self.Folder )
		end
		
		local total = ""
		for _, update in ipairs( self.ChangedList ) do
			for _, folder in ipairs( string.Explode( "\\", update.File ) ) do
				
				if !file.Exists( relative .. "\\" .. self.Folder .. "\\" .. total .. folder ) and !string.find( folder, ".", 1, true ) then
					rawio.mkdir( relative .. "\\" .. self.Folder .. "\\" .. total .. folder )
				end
				total = total .. folder .. "\\"
			end
			total = ""
		end
		
	end
	
end

function PLUGIN:SaveFiles( name, data )

	for _, v in ipairs( self.ToSave ) do
	
		if !rawio then
			file.Write( v.Name:gsub( "%.lua", "%.txt" ), v.Data )
		else
			v.Name = v.Name:gsub( "exsto_rev_" .. self.Latest .. "/", "" )
			relative = util.RelativePathToFull( "addons" )
			
			rawio.writefile( relative .. "\\" .. self.Folder .. "\\" .. v.Name, v.Data )
		end
		
	end
	
	self.ToSave = {}
	
end

function PLUGIN:Update( owner )

	if !self.Connection then
		return { owner, COLOR.NORM, "Please install the ", COLOR.NAME, "gm_oosocks module", COLOR.NORM, " to update Exsto through Garry's Mod!" }
	end
	
	if !self.OutOfDate then
		return { owner, COLOR.NORM, "Exsto is not out of date!" }
	end

	if !self.ChangedList then
		return { owner, COLOR.NORM, "Exsto couldn't retrieve the file changed list.  Please wait a ", COLOR.NAME, "moment", COLOR.NORM, "!" }
	end
	
	if !rawio and !owner.RAWIOAgreed then
		owner:Print( exsto_CHAT, COLOR.NORM, "Exsto couldn't locate the ", COLOR.NAME, "gm_rawio", COLOR.NORM, " module!" )
		owner:Print( exsto_CHAT, COLOR.NORM, "You can still retrieve all the updates to Exsto, but they will be saved in your ", COLOR.NAME, "data", COLOR.NORM, " folder." )
		owner:Print( exsto_CHAT, COLOR.NORM, "You will need to copy and rename the files to your addon directory.  If you wish to continue, run this command ", COLOR.NAME, "again", COLOR.NORM, "!" )
		
		owner.RAWIOAgreed = true
		return
	end
	
	local currentIndex = 1
	local downData = {}
	
	self.Callback = function( data, socket )
		if !data then
			self.SocketError = true
			exsto.Print( exsto_CONSOLE, "UPDATE --> Error retrieving data for " .. self.ChangedList[ currentIndex ].File )
			owner:Print( exsto_CHAT, COLOR.NAME, "ERROR: ", COLOR.NORM, "Issue retreiving update data!" )
			return
		end
		
		data = string.gsub( data, "\1", " " )
		data = string.gsub( data, "\2", "\n" )
		
		exsto.Print( exsto_CONSOLE, "UPDATE --> Grabbing " .. self.ChangedList[ currentIndex ].File )
		owner:Print( exsto_CHAT, COLOR.NORM, "Downloading file ", COLOR.NAME, self.ChangedList[ currentIndex ].File )
		
		table.insert( self.ToSave, { Name = "exsto_rev_" .. self.Latest .. "/" .. self.ChangedList[ currentIndex ].File, Data = data } )
		currentIndex = currentIndex + 1
		
		if currentIndex > #self.ChangedList then
			self:SaveFiles()
			exsto.Print( exsto_CONSOLE, "UPDATE --> Finished downloading updates!" )
			self:OnFinishDownloads( owner )
			return
		end
		
		socket:SendLine( "GET /Exsto/Updates/" .. self.ChangedList[currentIndex].File:gsub( " ", "%%20" ):gsub( "\\", "/" ) .. " HTTP/1.1" )
		socket:SendLine( "Host: " .. self.Host )
		socket:SendLine( "" )
		socket:ReceiveLine()
	end
	
	while true do
		if #string.Explode( ".", self.ChangedList[currentIndex].File ) > 1 then break end
		currentIndex = currentIndex + 1
	end
	
	self:BuildFolderStructure()
	
	self.Connection:SendLine( "GET /Exsto/Updates/" .. self.ChangedList[currentIndex].File:gsub( " ", "%%20" ):gsub( "\\", "/" ) .. " HTTP/1.1" )
	self.Connection:SendLine( "Host: " .. self.Host )
	self.Connection:SendLine( "" )
	self.Connection:ReceiveLine()
	
end
PLUGIN:AddCommand( "update", {
	Call = PLUGIN.Update,
	Desc = "Allows users to update the server via OOSocks.",
	Console = { "update" },
	Chat = { "!update" },
	Args = {},
	Category = "Utilities",
})

PLUGIN:Register()
