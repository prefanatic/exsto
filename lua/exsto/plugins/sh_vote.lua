local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Vote Functions",
	ID = "votefuncs",
	Desc = "Allows clients to vote on things.",
	Owner = "Prefanatic",
} )

if SERVER then

	--[[ optiontbl = {
		1 = "This is an answer"
	]]
	util.AddNetworkString( "ExClientVoted" )
	util.AddNetworkString( "ExVoteInit" )
	util.AddNetworkString( "ExVoteUpdate" )
	util.AddNetworkString( "ExVoteTLeft" )
	util.AddNetworkString( "ExVoteClear" )
	
	PLUGIN:AddVariable( {
		Pretty = "Vote Timeout Time",
		Dirty = "vote-timeout",
		Default = 30,
		Description = "This sets the default time for a vote, if no delay is passed.",
	} )

	-- We should send him the vote stuff so he can vote, because he just joined.
	function PLUGIN:ExInitSpawn( ply )
		if !self.VoteID then return end -- We aren't voting on anything

	end
	
	function PLUGIN:SendVoteInfo( ply )
		local sender = exsto.CreateSender( "ExVoteInit", ply );
			sender:AddString( self.VoteQuestion );
			sender:AddShort( self.VoteDelay );
			sender:AddShort( #self.VoteQuestions );

			for I = 1, #self.VoteQuestions do
				sender:AddString( self.VoteQuestions[ I ] )
				self.VoteData[ I ] = 0
			end
		sender:Send()
	end

	function PLUGIN:Vote( id, question, optiontbl, delay )
		-- Check and make sure we aren't voting on something already...
		if self.VoteID then
			self:Print( "Already in a vote!  Additional voting unimplemented." )
			return
		end
		
		self.VoteData = {}
		self.Voted = {}
		self.VoteID = id
		self.VoteQuestion = question
		self.VoteDelay = delay or exsto.GetVar( "vote-timeout" ).Value
		self.VoteQuestions = optiontbl

		self:SendVoteInfo( player.GetAll() )

		self:Print( "Pushed question '" .. question .. "' to players." )
		
		-- Create the handler for us to end with
		timer.Create( "ExVote_" .. id, delay or exsto.GetVar( "vote-timeout" ).Value, 1, function()
			PLUGIN:EndVote()
		end )
		
		-- Every second, send down a time update for players.
		--[[local count = 0
		timer.Create( "ExVoteTime_" .. id, 1, delay or exsto.GetVar( "vote-timeout" ).Value, function()
			count = count + 1
			local sender = exsto.CreateSender( "ExVoteTLeft", player.GetAll() )
				sender:AddShort( ( delay or exsto.GetVar( "vote-timeout" ).Value ) - count )
			sender:Send()
		end )]]
		
	end
	
	concommand.Add( "_TESTVOTE", function( p, _, args ) 
	    local tbl = {}
	    for I = 1, 60 do
	    	table.insert( tbl, "TEST VOTE " .. I )
	    end
		PLUGIN:Vote( "test_vote", "This is a test vote!", tbl ) 
	end )
	
	function PLUGIN:EndVote()
		local sender = exsto.CreateSender( "ExVoteClear", player.GetAll() )
		sender:Send()
		
		-- Calculate results.
		local numVotes = 0
		for name, _ in pairs( self.Voted ) do
			numVotes = numVotes + 1
		end
		
		local percent, lrgPercent, indxWinning, tiedVotes = 0, -1, -1, {}
		for I = 1, #self.VoteData do
			percent = math.Round( ( ( self.VoteData[ I ] or 0 ) / numVotes ) * 100 )
			
			if percent > lrgPercent then 
				lrgPercent = percent
				indxWinning = I
			elseif percent == lrgPercent then
				tiedVotes[ I ] = percent
			end
		end
		
		if indxWinning != -1 then
			self:Print( "Vote finished.  " .. self.VoteQuestions[ indxWinning ] .. " won with " .. lrgPercent )
			if #tiedVotes != 0 then
				self:Print( "Tie exists!  Handling unimplemented!" )
				PrintTable( tiedVotes ) -- TODO: Do something about tied voting.
			end
		else -- We suck and nobody voted :(
			
		end
		
		hook.Call( "ExVoteFinished", nil, { ID = self.VoteID, Won = indxWinning, Percent = lrgPercent } )
		
		-- Cleanup.
		self.VoteID = nil
	end			
	
	local function recClient( reader, len, ply )
		local indx = reader:ReadShort()
		if PLUGIN.Voted[ ply:Nick() ] then
			PLUGIN.VoteData[ PLUGIN.Voted[ ply:Nick() ] ] = PLUGIN.VoteData[ PLUGIN.Voted[ ply:Nick() ] ] - 1
			
			-- Resend this new info.
			PLUGIN:Print( exsto_DEBUG, "Updating " .. PLUGIN.Voted[ ply:Nick() ] .. " for " .. PLUGIN.VoteData[ PLUGIN.Voted[ ply:Nick() ] ] .. " votes" )

			local sender = exsto.CreateSender( "ExVoteUpdate", player.GetAll() )
				sender:AddShort( PLUGIN.Voted[ ply:Nick() ] )
				sender:AddShort( PLUGIN.VoteData[ PLUGIN.Voted[ ply:Nick() ] ] )
			sender:Send()
		end
		
		PLUGIN:Print( exsto_DEBUG, ply:Nick() .. " voting on " .. indx )
		
		PLUGIN.Voted[ ply:Nick() ] = indx;
		PLUGIN.VoteData[ indx ] = PLUGIN.VoteData[ indx ] + 1;
		
		PLUGIN:Print( exsto_DEBUG, "Updating " .. indx .. " for " .. PLUGIN.VoteData[ indx ] .. " votes" )
		local sender = exsto.CreateSender( "ExVoteUpdate", player.GetAll() )
			sender:AddShort( indx )
			sender:AddShort( PLUGIN.VoteData[ indx ] )
		sender:Send()
	end
	exsto.CreateReader( "ExClientVoted", recClient )

elseif CLIENT then

	local function recTLeft( reader )
		PLUGIN.TimeLeft = reader:ReadShort()
	end
	exsto.CreateReader( "ExVoteTLeft", recTLeft )

	local function recVote( reader )
		PLUGIN.ActiveVote = {}
		PLUGIN.VoteData = {}
		
		PLUGIN.Question = reader:ReadString()
		PLUGIN.VoteTime = reader:ReadShort()
		
		PLUGIN.VoteEnd = PLUGIN.VoteTime + CurTime()
		
		for I = 1, reader:ReadShort() do
			table.insert( PLUGIN.ActiveVote, reader:ReadString() )
		end
		
		PLUGIN:StartVote()
	end
	exsto.CreateReader( "ExVoteInit", recVote )

	local function clrVote( reader )
		PLUGIN:EndVote()
		
		PLUGIN.ActiveVote = {}
		PLUGIN.Question = "#VOTEMSG"
		PLUGIN.VoteData = {}
	end
	exsto.CreateReader( "ExVoteClear", clrVote )
	
	local function updateVote( reader )
		PLUGIN.VoteData[ reader:ReadShort() ] = reader:ReadShort()
	end
	exsto.CreateReader( "ExVoteUpdate", updateVote )
	
	function PLUGIN:VoteOn( indx )
		local sender = exsto.CreateSender( "ExClientVoted" )
			sender:AddShort( indx )
		sender:Send()
	end
	
	function PLUGIN:EndVote()
		self.VoteLarge:SetPos( ( ScrW() / 2 ) - ( 200 ), ( ScrH() / 2 ) )
		self.VoteLarge:SetVisible( false )
		
		gui.EnableScreenClicker( false )
	end
	
	function PLUGIN:StartVote()
		self.VoteLarge.Question:SetText( self.Question )
		self.VoteLarge.Question:SizeToContents()
		
		self.VoteLarge.List:Populate( self.ActiveVote )
		
		self.TimeDelta = ( self.VoteLarge:GetWide() - 20 ) / self.VoteTime
		
		-- Move the panel
		self.VoteLarge._TIMEW = 0
		self.VoteLarge:SetVisible( true )
		self.VoteLarge:SetPos( ( ScrW() / 2 ) - ( 200 ), ( ScrH() / 2 ) - 300 )
		
		gui.EnableScreenClicker( true )
	end
	
	function PLUGIN:Init()
		
		-- Material resources
		self.VoteCheck = Material( "exsto/greentick.png" )
		
		-- Create our vote panel(s).  Fuck you schuyler :(
		self.VoteLarge = exsto.CreatePanel( ( ScrW() / 2 ) - ( 200 ), ( ScrH() / 2 ), 400, 600 )
			self.VoteLarge:SetVisible( false )
			self.VoteLarge:SetSkin( "Exsto" )
		self.VoteLarge.Question = exsto.CreateLabel( 10, 10, "#VOTEMSG", "ExGenericText26", self.VoteLarge )
		self.VoteLarge.Scroller = vgui.Create( "DScrollPanel", self.VoteLarge )
			self.VoteLarge.Scroller:SetPos( 10, 40 )
			self.VoteLarge.Scroller:SetSize( self.VoteLarge:GetWide() - 20, self.VoteLarge:GetTall() - 70 )
		self.VoteLarge.List = vgui.Create( "DIconLayout", self.VoteLarge.Scroller )
			self.VoteLarge.List:SetPos( 0, 0 )
			self.VoteLarge.List:SetSize( self.VoteLarge.Scroller:GetWide(), self.VoteLarge.Scroller:GetTall() )
			self.VoteLarge.List:SetSpaceX( 12 )
			self.VoteLarge.List:SetSpaceY( 10 )
			self.VoteLarge.List:SetLayoutDir( TOP )
			
		local function countdownPaint( pnl )	
			pnl._TIMEW = math.Approach( pnl._TIMEW, pnl:GetWide() - 20, FrameTime() * PLUGIN.TimeDelta )
			--pnl._TIMEW = pnl._TIMEW + ( FrameTime() * PLUGIN.TimeDelta )
			
			surface.SetDrawColor( 0, 153, 176, 255 )
			surface.DrawRect( 10, pnl:GetTall() - 22, pnl._TIMEW, 20 )
			
			surface.SetDrawColor( 100, 100, 100, 255 )
			surface.DrawOutlinedRect( 10, pnl:GetTall() - 22, pnl._TIMEW, 20 )
			
		end
		self.VoteLarge.PaintOver = countdownPaint
			
		local function btnPaint( btn )
			-- Votes under text
			if !PLUGIN.VoteData[ btn._VoteIndex ] or PLUGIN.VoteData[ btn._VoteIndex ] == 0 then return end
			surface.SetMaterial( PLUGIN.VoteCheck )
			for I = 1, PLUGIN.VoteData[ btn._VoteIndex ] do
				if I > 10 then return end
				surface.DrawTexturedRect( 2 + ( I * 16 ), btn:GetTall() - 17, 16, 16 )
			end
		end
		local function btnClick( btn )
			PLUGIN:VoteOn( btn._VoteIndex )
		end
		self.VoteLarge.List.Populate = function( lst, tbl )
			lst:Clear()
			
			-- We first need to set this up so it looks nice.  Get max length of the largest text
			--[[surface.SetFont( "ExGenericText16" )
			local w, h, lrgW = 0, 0, 0
			for _, data in ipairs( tbl ) do
				w, h = surface.GetTextSize( data )
				if w > lrgW then lrgW = w end
			end]]
			
			for _, data in ipairs( tbl ) do
				local btn = vgui.Create( "ExButton", lst )
					btn:SetSize( 175, 36 )
					btn:MaxFontSize( 20 )
					btn:Text( data )
					btn:SetAlignX( TEXT_ALIGN_CENTER )
					btn:SetAlignY( TEXT_ALIGN_TOP )
					btn._VoteIndex = _
					btn.OnPaint = btnPaint
					btn.OnClick = btnClick
				lst:Add( btn )
			end
		end
		
		exsto.Animations.CreateAnimation( self.VoteLarge )
		
		-- And the smaller one.
		-- TODO
	end

end

PLUGIN:Register()