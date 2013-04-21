local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Vote Map",
	ID = "votemap",
	Desc = "Allows clients to vote on maps.",
	Owner = "Prefanatic",
} )

concommand.Add( "_VOTEMAP", function() PLUGIN:Votemap() end )

function PLUGIN:Votemap()
	self:Print( "Starting votemap..." )
	
	local dt = exsto.VotemapDB:GetAll()
	-- Quick thing to make the sorting easier later on
	local tmp = {}
	for _, data in ipairs( dt ) do
		tmp[ data.Map ] = data.Played
	end	
	dt = tmp
	
	-- Lets get our map list from sh_restart, because Exsto is awwweeesome <3
	local rstart = exsto.GetPlugin( "restart-changelvl" )
	if !rstart then	self:Print( "Andddd we can't find our restart plugin.  Uh oh!  But this should never happen." ) return end
	
	local maplist = table.Copy( rstart.MapList )
	local lst = {}
	
	-- Clean the map list and only let ttt maps go through.
	for map, data in pairs( maplist ) do
		if data.Category:find( "Trouble" ) then 
			table.insert( lst, map ) 
			if !dt[ map ] then dt[ map ] = 0 end
		end
	end
	
	-- Now, we need to put the highest played maps on top.  Sort this thing by the count in exsto.VotemapDB.
	table.sort( lst, function( a, b ) return dt[ a ] > dt[ b ] end )
	
	-- We should have a proper sorted table, with the most played maps closer to 0 on the index.  Push the vote!
	local vote = exsto.GetPlugin( "votefuncs" )
	if !vote then self:Print( "Couldn't find the vote API.  This shouldn't ever happen." ) return end
	
	vote:Vote( "votemap", "Next map!", lst, self.Timeout:GetValue(), "large" )
	self.MapList = lst
end

function PLUGIN:ExVoteFinished( data )
	if data.ID == "votemap" then -- Make sure this is ours to use.
		-- Check and make sure people voted...
		if data.Won == -1 then -- Fuck
			-- Just set up some random map to go to.
			data.Won = math.random( 1, #self.MapList )
		end
		
		local map = self.MapList[ data.Won ]
		
		local count = exsto.VotemapDB:GetData( map, "Played" )
		if !count then count = 0 end
		
		-- Throw this into the statisitcs table
		exsto.VotemapDB:AddRow( {
			Map = map;
			Played = count + 1;
		} )
		
		-- Now restart.
		local rstart = exsto.GetPlugin( "restart-changelvl" )
		if !rstart then	self:Print( "Andddd we can't find our restart plugin.  Uh oh!  But this should never happen." ) return end
		
		rstart:ChangeLevel( "Console", map, 3, "current" )
		self:Print( exsto_CHAT_ALL, 
			COLOR.NORM, "Changing level to ",
			COLOR.NAME, map:gsub( "%.bsp", "" ),
			COLOR.NORM, " in ",
			COLOR.NAME, tostring( 3 ),
			COLOR.NORM, " seconds!"
		)
	end
end


function PLUGIN:Init()
	-- Purely for statistical purposes.  Votemap also puts the most played above everything else in the list.
	self.Timeout = exsto.CreateVariable( "ExVotemapTimeout", "Votemap timeout", 30, "How long the votemap has until it is done polling for votes." )
	self.Timeout:SetMinimum( 0 )
	self.Timeout:SetCategory( "Votes" )
	self.Timeout:SetUnit( "Time (seconds" )
	exsto.VotemapDB = FEL.CreateDatabase( "exsto_plugin_votemap" )
		exsto.VotemapDB:SetDisplayName( "Votemap Statistics" )
		exsto.VotemapDB:ConstructColumns( {
			Map = "VARCHAR(255):primary:not_null";
			Played = "INTEGER";
		} )
end

PLUGIN:Register()



