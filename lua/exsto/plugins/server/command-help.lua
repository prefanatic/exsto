-- Prefan Access Controller
-- Command Searcher

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Command Searcher",
	ID = "com-search",
	Desc = "A plugin that allows searching the command list!",
	Owner = "Prefanatic",
} )

function PLUGIN:Init()
	self.Categories = nil
	self.Commands = nil
end

local function sort( a, b )
	if !a.Console or !b.Console then return end
	if !a.Console[1] or !b.Console[1] then return end
	
	return a.Console[1] < b.Console[1]
end

function PLUGIN:Search( ply, command, all )

	if !self.Categories then
		self.Categories = {}
		for short, data in pairs( exsto.Commands ) do
			if !table.HasValue( self.Categories, data.Category ) then
				table.insert( self.Categories, data.Category )
			end
		end
		table.sort( self.Categories )
	end

	if !self.Commands then
		self.Commands = {}
		for short, data in pairs( exsto.Commands ) do
			table.insert( self.Commands, data )
		end
		table.sort( self.Commands, sort )
	end
	
	--[[ What the hell is this doing here?
	
	local data = {}
	-- Grab all the commands that contain the command
	for k,v in pairs( self.Commands ) do
		
		-- Check chat.
		for _, com in pairs( v.Chat ) do
			if string.find( com, command, 1, true ) then data[k] = v end
		end
		
		-- Check console.
		for _, com in pairs( v.Console ) do
			if string.find( com, command, 1, true ) then data[k] = v end
		end
		
	end ]]
	
	-- Loop through the commands and send them to client print.
	exsto.Print( exsto_CLIENT, ply, " ---- Printing Exsto commands to console! ----" )
	if all then exsto.Print( exsto_CLIENT, ply, " ** Forcing the print of all Exsto related commands. **" ) end
	exsto.Print( exsto_CLIENT, ply, " All console commands are proceded by 'exsto', I.E exsto rocket" )

	for _, category in ipairs( self.Categories ) do
		ply:Print( exsto_CLIENT, "\n\n--- Category: " .. category )
		
		
		-- kick, k (!kick, !k): Kicks a player.  Args: aisdfjsdhf
		-- Loop through his stuff.
		for _, data in ipairs( self.Commands ) do
			if data.Category == category and ( ply:IsAllowed( data.ID ) or all ) then
				local console = ""
				for _, com in ipairs( data.Console ) do
					if _ == #data.Console then
						console = console .. com
					else
						console = console .. com .. ", "
					end
				end
				
				local chat = ""
				for _, com in ipairs( data.Chat ) do
					if _ == #data.Chat then
						chat = chat .. com
					else
						chat = chat .. com .. ", "
					end
				end
				
				-- Build the return order
				local retorder = ""
				local insert = ", "
				for _, arg in ipairs( data.ReturnOrder ) do
					if _ == #data.ReturnOrder then insert = "" end
					retorder = retorder .. arg .. insert
				end
				
				local endd = ". "
				if string.Right( data.Desc, 1 ) == "." or string.Right( data.Desc, 1 ) == "!" then endd = " " end
				
				ply:Print( exsto_CLIENT, "\t" .. console .. " ( " .. chat .. " ): " .. data.Desc .. endd .. "Args: " .. retorder  )
			end
		end
	end

	
	exsto.Print( exsto_CLIENT, ply, " \n\n---- End of Exsto help ---- \n" )
	exsto.Print( exsto_CHAT, ply, COLOR.NORM, "All commands have been printed to your ", COLOR.NAME, "console" )

end
PLUGIN:AddCommand( "search", {
	Call = PLUGIN.Search,
	Desc = "Allows users to search for commands.",
	Console = { "commands" },
	Chat = { "!commands" },
	ReturnOrder = "Command-ForceAll",
	Args = {Command = "STRING", ForceAll = "BOOLEAN"},
	Optional = {Command = "", ForceAll = false},
	Category = "Help",
})

PLUGIN:Register()