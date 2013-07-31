--[[
	Exsto
	Copyright (C) 2010  Prefanatic

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

-- Chat Commands

-- Variables

exsto.Commands = {}
exsto.Arguments = {}
exsto.Flags = {}
exsto.FlagIndex = {}

local function AddArg( style, type, func ) table.insert( exsto.Arguments, {Style = style, Type = type, Func = func} ) end
AddArg( "PLAYER", "Player", function( nick, caller ) if nick == "" then return -1 else return exsto.FindPlayers( nick, caller ) end end )
AddArg( "ONEPLAYER", "Player", function( nick, caller ) if nick == "" then return -1 else return exsto.FindPlayers( nick, caller ) end end )
AddArg( "NUMBER", "number", function( num ) return tonumber( num ) end )
AddArg( "STRING", "string", function( string ) return tostring( string ) end )
AddArg( "BOOLEAN", "boolean", function( bool ) return tobool( bool ) end )
AddArg( "NIL", "nil", function( object ) return "" end )
AddArg( "STEAMID", "table", function( str ) if str == "" then return str else return exsto.dbGetPlayerByID(str) end end )

AddArg( "TIME", "string", function( num )
	local split = string.Explode( ":", num )
	if #split == 1 then return tonumber( num ) end
	
	local t = split[1]
		num = tonumber( split[2] )
	
	if t == "s" then
		return tonumber( num / 60 )
	elseif t == "m" then
		return tonumber( num )
	elseif t == "h" then
		return tonumber( num * 60 )
	elseif t == "d" then
		return tonumber( 24 * ( num * 60 ) )
	elseif t == "w" then
		return tonumber( 7 * ( 24 * ( num * 60 ) ) )
	elseif t == "month" then
		return tonumber( 4 * ( 7 * ( 24 * ( num * 60 ) ) ) )
	elseif t == "year" then
		return tonumber( 12 * ( 4 * ( 7 * ( 24 * ( num * 60 ) ) ) ) )
	end
end )

exsto.ChatSpellingSuggest = exsto.CreateVariable( "ExSpellingCorrect",
	"Spelling Suggestions",
	1,
	"If enabled, Exsto will tell you when you type a command incorrectly." )
	exsto.ChatSpellingSuggest:SetBoolean()
	exsto.ChatSpellingSuggest:SetCategory( "Exsto General" )

--[[ -----------------------------------
	Function: exsto.SendCommandList
	Description: Sends the Exsto command list to players on join.
     ----------------------------------- ]]
function exsto.SendCommandList( ply )
	for id in pairs( exsto.Commands ) do
		exsto.SendCommand( id, ply )
	end
end
hook.Add( "ExClientLoading", "exsto_StreamCommandList", exsto.SendCommandList )
concommand.Add( "_ResendCommands", exsto.SendCommandList )

function exsto.SendCommand( id, ply )
	local data = exsto.Commands[ id ]
	local sender = exsto.CreateSender( "ExRecCommands", ply )
		sender:AddString( data.ID )
		sender:AddString( data.Desc )
		sender:AddString( data.Category )
		sender:AddBool( data.QuickMenu )
		sender:AddString( data.CallerID or "" )
		
		sender:AddShort( data.Args and table.Count( data.Args ) or 0 )
		for arg, var in pairs( data.Args ) do
			sender:AddString( arg )
			sender:AddString( var )
		end

		sender:AddShort( data.ReturnOrder and #data.ReturnOrder or 0 )
		for _, arg in ipairs( data.ReturnOrder ) do
			sender:AddString( arg )
		end
		
		sender:AddShort( data.Optional and table.Count( data.Optional ) or 0 )
		for arg, val in pairs( data.Optional ) do
			sender:AddString( arg )
			sender:AddVariable( val )
		end

		sender:AddShort( data.Console and #data.Console or 0 )
		for _, com in ipairs( data.Console ) do
			sender:AddString( com )
		end
		
		sender:AddShort( data.Chat and #data.Chat or 0 )
		for _, com in ipairs( data.Chat ) do
			sender:AddString( com )
		end
		
		sender:AddShort( data.ExtraOptionals and table.Count( data.ExtraOptionals ) or 0 )
		if type( data.ExtraOptionals ) == "table" then
			for name, extra in pairs( data.ExtraOptionals ) do
				sender:AddString( name )
				sender:AddShort( #extra )
				for _, display in ipairs( extra ) do
					sender:AddString( display.Display )
					sender:AddVariable( display.Data )
				end
			end
		end
		
		sender:AddString( data.DisplayName )
		
		sender:Send()
end

--[[ -----------------------------------
	Function: exsto.ResendCommands
	Description: Resends the command list to everyone in the server.
     ----------------------------------- ]]
function exsto.ResendCommands()
	exsto.SendCommandList( player.GetAll() )
end

--[[ -----------------------------------
	Function: exsto.AddChatCommand
	Description: Adds chat commands into the Exsto list.
     ----------------------------------- ]]
function exsto.AddChatCommand( ID, info )

	if !ID or !info then exsto.Error( "No valid ID or Information for a chat command requesting initialization!" ) return end
	
	-- This is probably going to be very bad, with what we're about to do.  But we're going to hack in a new way to make commands into this until I have time to recode everything
	-- It's pretty much a clash of 2013 stuff and 2009 stuff.  This was the FIRST thing I put into exsto, so, its OLD.
	if not info.Args and info.Arguments then -- New style
		exsto.Debug( "Commands --> Downconverting command style.  This will be fixed at one point!", 3 )
	
		info.ReturnOrder = {}
		info.Args = {}
		
		-- Lets construct backwards to the old style from what we've gotten from the developer.
		for _, data in ipairs( info.Arguments ) do -- Loop through the order
			table.insert( info.ReturnOrder, data.Name )
			
			-- Convert data.Type
			if type( data.Type ) == "number" then -- It's an enum, convert it.
				if data.Type == COMMAND_PLAYER then
					data.Type = "PLAYER"
				elseif data.Type == COMMAND_STRING then
					data.Type = "STRING"
				elseif data.Type == COMMAND_NUMBER then
					data.Type = "NUMBER"
				elseif data.Type == COMMAND_BOOLEAN then
					data.Type = "BOOLEAN"
				end
			end
			
			info.Args[ data.Name ] = data.Type
			if data.Optional != nil then
				if not info.Optional then info.Optional = {} end
				info.Optional[ data.Name ] = data.Optional
			end
		end

	end
	
	local returnOrder = {}
	if type( info.ReturnOrder ) == "string" then
		returnOrder = string.Explode( "-", info.ReturnOrder )
	else returnOrder = info.ReturnOrder end

	exsto.Commands[ID] = {
		ID = ID,
		Call = info.Call,
		Desc = info.Desc or "None Provided",
		FlagDesc = info.Desc or "None Provided",
		ReturnOrder = returnOrder or {},
		Args = info.Args or {},
		Optional = info.Optional or {},
		Arguments = info.Arguments;
		Plugin = info.Plugin or nil,
		Category = info.Category or "Unknown",
		DisallowCaller = info.DisallowCaller or false
	}
	
	exsto.Commands[ID].Chat = {}
	if info.Chat then
		for k,v in pairs( info.Chat ) do
			exsto.AddChat( ID, v )
		end
	end
	
	exsto.Commands[ID].Console = {}
	if info.Console then
		for k,v in pairs( info.Console ) do
			exsto.AddConsole( ID, v )
		end
	end
	
end

--[[ -----------------------------------
	Function: exsto.AddChat
	Description: Cleans and categorises chat commands.
     ----------------------------------- ]]
function exsto.AddChat( ID, Look )
	if !ID or !Look then exsto.Error( "No valid ID or Information for a chat command requesting initialization!" ) return end
	
	local tab = exsto.Commands[ID]
	Look = Look:lower():Trim()
	
	table.insert( tab.Chat, Look )	
end

--[[ -----------------------------------
	Function: exsto.AddConsole
	Description: Cleans and categorises console commands.
     ----------------------------------- ]]
function exsto.AddConsole( ID, Look )
	if !ID or !Look then exsto.Error( "No valid ID or Information for a console command requesting initialization!" ) return end
	
	local tab = exsto.Commands[ID]
	
	table.insert( tab.Console, Look )
end

--[[ -----------------------------------
	Function: exsto.RemoveChatCommand
	Description: Removes a command ID from the Exsto list.
     ----------------------------------- ]]
function exsto.RemoveChatCommand( ID )
	exsto.Commands[ID] = nil
end

--[[ -----------------------------------
	Function: exsto.CreateFlag
	Description: Adds a flag to the Exsto flag table.
     ----------------------------------- ]]
function exsto.CreateFlag( ID, Desc )
	if exsto.Flags[ID] then return end
	exsto.Flags[ID] = Desc or "None Provided"
end

--[[ -----------------------------------
	Function: exsto.LoadFlags
	Description: Inserst all flags from commands into the exsto.Flag table.
     ----------------------------------- ]]
function exsto.LoadFlags()
	for k,v in pairs( exsto.Commands ) do
		exsto.CreateFlag( v.ID, v.FlagDesc )
	end
	
	-- To cover lack of flags in commands but in ranks.
	local allow, deny
	for k,v in pairs( exsto.DefaultRanks ) do
		allow = von.deserialize( v.FlagsAllow )
		for I = 1, table.Count( allow ) do
			exsto.CreateFlag( allow[I] )
		end
		
		deny = von.deserialize( v.FlagsDeny )
		for I = 1, table.Count( deny ) do
			exsto.CreateFlag( deny[I] )
		end
	end
end

--[[ -----------------------------------
	Function: exsto.CreateFlagIndex
	Description: Creates a table filled with flags indexed by numbers
     ----------------------------------- ]]
function exsto.CreateFlagIndex()
	local index = {}
	for k,v in pairs( exsto.Flags ) do
		table.insert( exsto.FlagIndex, k )
	end
end

--[[ -----------------------------------
	Function: exsto.GetArgumentKey
	Description: Grabs the index of an argument type.
     ----------------------------------- ]]
function exsto.GetArgumentKey( style )
	for k,v in pairs( exsto.Arguments ) do
		if v.Style == style then return k end
	end
end

--[[ -----------------------------------
	Function: exsto.CommandCompatible
	Description: Checks to see if a command is compatible with Exsto.
     ----------------------------------- ]]
function exsto.CommandCompatible( data )
	if type( data.Call ) != "function"  then return end
	if type( data.Args ) != "table" then return end
	if type( data.Optional ) != "table" then return end
	if type( data.ReturnOrder ) != "table" then return end
	
	return true
end

--[[ -----------------------------------
	Function: exsto.CommandRequiresImmunity
	Description: Checks if a command handles players in any way
     ----------------------------------- ]]
function exsto.CommandRequiresImmunity( data )
	if data.ID == "pm" then return false end  -- Allow pm to be ran on anyone
	for _, argument in ipairs( data.ReturnOrder ) do
		if data.Args[ argument ] == "PLAYER" then return _ end
	end
	return false
end

--[[ -----------------------------------
	Function: exsto.PrintReturns
	Description: Does a format print of the return values given by plugins.
     ----------------------------------- ]]
function exsto.PrintReturns( data, I, multiplePeople, hide )

	local hide = hide or 0

	local style = { exsto_CHAT_ALL }
	
	-- Check if we can do this.
	if type( data ) == "table" then
	
		-- Check if he only wants it printing to the caller.
		if type( data[1] ) == "Player" or type( data[1] ) == "Entity" and data[1]:CanPrint() then
			style = { exsto_CHAT, data[1] }
		end
		
		-- Don't bother if he wants the feedback hidden
		if hide > 0 then return end
		
		-- Continue if he set us up to format his data.
		if data.Activator and (data.Activator:IsValid() or data.Activator:EntIndex() == 0) and data.Wording then
			data.Player = data.Player or data.Object
			local ply = data.Player
			if data.Player and type( data.Player ) == "Player" then ply = data.Player:Nick() end
            
			-- Change to himself if the acting player is the victim
			if ply == data.Activator:Nick() and data.Activator:IsValid() then ply = "themself" end
			
			-- Format any [self] requests.
			data.Wording = data.Wording:gsub( "%[self%]%", data.Activator:Nick() )
			
			local talk = { unpack( style ), COLOR.NAME, data.Activator:EntIndex() == 0 and "Console" or data.Activator:Nick(), COLOR.NORM, data.Wording }
			
			if ply then 
				table.insert( talk, COLOR.NAME )
				table.insert( talk, ply )
			end
			
			if data.Secondary then
				table.insert( talk, COLOR.NORM )
				table.insert( talk, data.Secondary )
			end
			
			table.insert( talk, COLOR.NORM )
			table.insert( talk, "!" )
			
			exsto.Print( unpack( style ), unpack( talk ) )
			
		-- He is returning custom data.
		else exsto.Print( unpack( style ), unpack( data ) ) end
		
	end
	
end

--[[ -----------------------------------
	Function: exsto.ParseStrings
	Description: Parses text, then returns a table with items split by spaces, except stringed items.
     ----------------------------------- ]]
function exsto.ParseStrings( text )
	
	-- Code from raBBish, which is from Lexi, that completely lit up my string finding pattern on fire.
	-- http://www.facepunch.com/showthread.php?t=827179
	
	local quote = string.sub( text, 1, 1 ) ~= '"'
	local data = {}
	
	for chunk in string.gmatch( text, '[^"]+' ) do
		quote = not quote
		
		if quote then
			table.insert( data, chunk )
		else
			for chunk in string.gmatch( chunk, "%S+" ) do
				table.insert( data, chunk )
			end
		end
	end
	
	return data
end

--[[ -----------------------------------
	Function: exsto.PatternArgs
	Description: Parses arguments to replace regex patterns.
     ----------------------------------- ]]
function exsto.PatternArgs( ply, data, args )
	for _, arg in ipairs( args ) do
		if type( arg ) == "string" then
			args[ _ ] = string.gsub( arg, "%[self%]", ply:Nick() )
		end
	end
	return args
end
	 
--[[ -----------------------------------
	Function: exsto.ParseArguments
	Description: Parses text and returns formatted and normal typed variables.
     ----------------------------------- ]]
function exsto.ParseArguments( ply, data, args )

	-- Create return data.
	local cleanedArguments = {} -- Our cleaned argument table
	local activePlayers = { 1 } -- We put a 1 here for those commands who don't use this.
	local playersSlot = 0 -- The slot where the multiple players are
	
	-- Check and see if the arguments need to be cleaned and table'ed
	if type( args ) == "string" then
		args = exsto.ParseStrings( args )
	end
	
	-- See if we can compile the excess text that we have to match the return order.
	if #args > #data.ReturnOrder and #args >= 1 then -- *cough*
		local compile = ""
		for I = #data.ReturnOrder, #args do
			if args[ I ] then
				compile = compile .. args[ I ] .. " "
				args[ I ] = nil
			end
		end
		
		args[ #data.ReturnOrder ] = compile
	end
	
	-- Check and loop through our arguments if he contains any environment variable.
	/*for I = 1, #args do
		for slice in string.gmatch( args[ I ], "\#(%w+)" ) do
			local data = exsto.GetVar( slice )
			if data then
				args[ I ] = string.gsub( args[ I ], "#" .. slice, data.Value )
			end
		end
	end*/ -- FIX THIS
	
	-- Time to loop through our requested return orders and place items
	for I = 1, #data.ReturnOrder do
	
		-- Create local variables so we can call back
		local currentArgument = data.ReturnOrder[ I ]
		local currentType = data.Args[ currentArgument ]
		local currentSplice = args[ I ]
		local currentArgumentData = exsto.Arguments[ exsto.GetArgumentKey( currentType ) ]
		
		-- Check if we contain the splice, then convert that splice into the requested type.
		if currentSplice then
			local converted = currentArgumentData.Func( currentSplice, ply )
			
			if currentArgumentData.Style == "ONEPLAYER" and #converted > 1 then
				ply:Print( exsto_CHAT, COLOR.NAME, currentArgument, COLOR.NORM, " may only match one player, try refining your search!")
				return nil
			
			-- See if we can catch our acting players variable and store it
			elseif currentArgumentData.Type == "Player" and type( converted ) == "table" and #converted >= 1 then
				activePlayers = converted
				playersSlot = #cleanedArguments + 1
				table.insert( cleanedArguments, converted )
			
			-- If we didn't get the correct value back, then something is wrong.  Lets check it out
			elseif currentArgumentData.Type != type( converted ) then
			
				-- See if it is a player that we were looking for.  Maybe we can give a suggestion!
				if type( converted ) == "table" and currentArgumentData.Type == "Player" and #converted == 0 then
					exsto.GetClosestString( currentSplice, exsto.BuildPlayerNicks(), nil, ply, "Unknown player" )
					return nil
				elseif currentArgumentData.Style == "STEAMID" and !converted then
					ply:Print( exsto_CHAT, COLOR.NORM, "Unable to find a player under the SteamID ", COLOR.NAME, currentSplice, COLOR.NORM, "!" )
					return nil
				end
				
				-- Format some issues with Lua
				if type( converted ) == "nil" and currentArgumentData.Type == "number" then converted = "" end
				
				-- Finally notify us.
				ply:Print( exsto_CHAT, COLOR.NORM, "Argument: ", COLOR.NAME, currentArgument .. " (" .. currentArgumentData.Type .. ")", COLOR.NORM, " is needed!  You put ", COLOR.NAME, type( converted ) )
				
				return nil
				
			-- If our data type matches, celebrate!
			elseif currentArgumentData.Type == type( converted ) then
				table.insert( cleanedArguments, converted )
			end
			
		-- We ran out of splices to check; this is where we request optionals.
		else
		
			-- If the optional exists at all; insert his data in place of our own.
			if type( data.Optional[ currentArgument ] ) != "nil" then
				table.insert( cleanedArguments, data.Optional[ currentArgument ] )
			
			-- If the coder never supplied an optional value for the command, try and substitute things in.
			else
			
				-- See if we can substitute ourselves in if he asks for a PLAYER value.
				if currentType == "PLAYER" and I == 1 and ply:IsPlayer() and data.DisallowCaller == false then
					table.insert( cleanedArguments, { ply } )
					activePlayers = { ply }
					playersSlot = #cleanedArguments
					
				-- We can't do anything else.  Tell the caller.
				else
					ply:Print( exsto_CHAT, COLOR.NORM, "Argument ", COLOR.NAME, currentArgument .. " (" .. currentArgumentData.Type .. ")", COLOR.NORM, " is needed!" )
					return nil
				end
			end
		end
	end
	
	-- Lets do a quick string replacement.
	cleanedArguments = exsto.PatternArgs( ply, data, cleanedArguments )
	
	return cleanedArguments, activePlayers, playersSlot
	
end

-- Variable for ImmuneStyles
exsto.ComImmuneStyle = exsto.CreateVariable( "ExComImmuneStyle",
	"Command Immunity Style",
	"remove",
	"Changes how command immunity works, on a selection basis.\n - 'remove' : Removes players who cannot be accessed.\n - 'kill' : Stops the command from running if Exsto fails immune checks.\n - 'ignore' : Ignores immunity and runs anyways."
)
exsto.ComImmuneStyle:SetPossible( "remove", "kill", "ignore" )
exsto.ComImmuneStyle:SetCategory( "Exsto General" )

--[[ -----------------------------------
	Function: ExstoParseCommand
	Description: Main thread that parses commands and runs them.
     ----------------------------------- ]]
local function ExstoParseCommand( ply, command, args, style )
	local hide = string.find(command,"#") or 0
	
	-- Remove the hide-feedback sign
	if style == "chat" then
		command = string.gsub(command,"#","")
	end

	for _, splice in ipairs( args ) do
		args[ _ ] = splice:Trim()
	end
	
	for k, data in pairs( exsto.Commands ) do
		if ( style == "chat" and table.HasValue( data.Chat, command ) ) or ( style == "console" and table.HasValue( data.Console, command ) ) then
		
			-- We found our command, continue.
		
			-- First, parse the text for the arguments.
			if style == "chat" then args = string.Implode( " ", args ) end
			local argTable, activePlayers, playersSlot = exsto.ParseArguments( ply, data, args )
			
			if !argTable then return "" end
			
			-- Check if we are allowed to perform this active command.
			local allowed, reason = ply:IsAllowed( data.ID )
			
			-- If the command requires an immunity check, update our allowance
			local slot, remTriggered = exsto.CommandRequiresImmunity( data ), false
			if slot then
				for I = 1, #activePlayers do
					allowed, reason = ply:IsAllowed( data.ID, type( argTable[ slot ] ) == "Player" and argTable[ slot ] or argTable[ slot ][ I ] )
					if !allowed then
						if exsto.ComImmuneStyle:GetValue() == "remove" then
							table.remove( activePlayers, I )
							I=I-1
							remTriggered = true
						elseif exsto.ComImmuneStyle:GetValue() == "kill" then
							break
						elseif exsto.ComImmuneStyle:GetValue() == "ignore" then
							-- Do nothing!  We should ignore this
							allowed = true
						end
					end
				end
			end
			
			if !allowed then
				-- Check our reason
				if reason == "immunity" then
					ply:Print( exsto_CHAT, COLOR.NORM, "Cannot run ", COLOR.NAME, command, COLOR.NORM, ", due to a player(s) involved having higher immunity!" )
				else
					ply:Print( exsto_CHAT, COLOR.NORM, "You are not allowed to run ", COLOR.NAME, command, COLOR.NORM, "!" )
				end
				return ""
			end
			
			if remTriggered then
				ply:Print( exsto_CHAT, COLOR.NORM, "Some players have been ", COLOR.NAME, "removed from the command", COLOR.NORM, ", due to having a higher immunity!" )
			end
			
			-- Run this command on a loop through all active player participents.
			local newArgs, status, sentback, multiplePeopleToggle, alreadySaid
			
			if #activePlayers >= 3 then multiplePeopleToggle = true end
			for I = 1, #activePlayers do
				
				-- Create a copy of the arg table so we can edit it.
				newArgs = table.Copy( argTable )
				
				-- Now that we passed the immunity and allowance checks, insert what we need into the arg table
				local requiredAdditions = 1
				table.insert( newArgs, 1, ply )
				if data.Plugin then
					requiredAdditions = 2
					table.insert( newArgs, 1, data.Plugin )
				end

				-- Set our multiple player slot to contain only one we currently are on right now.
				if playersSlot != 0 then
					newArgs[ playersSlot + requiredAdditions ] = activePlayers[ I ]
				end
				
				-- Call a hook.  If he returns false, then panic and print his reason.
				local checkcall = { hook.Call( "ExCommandCalled", nil, data.ID, unpack( newArgs or {} ) ) }
				if checkcall[1] == false then
					ply:Print( exsto_CHAT, unpack( checkcall[2] ) )
					return ""
				elseif type( checkcall[1] ) == "table" then
					exsto.PrintReturns( checkcall[1], I, multiplePeopleToggle )
				elseif checkcall[1] != false and checkcall[2] != "no_run" then
			
					-- Finally, call the function
					status, sentback = pcall( data.Call, unpack( newArgs ) )
					
					-- If we didn't make it, oh god.
					if !status then
						ply:Print( exsto_CHAT, COLOR.NORM, "Something went wrong while executing that command!" )
						exsto.ErrorNoHalt( "COMMAND --> " .. command .. " --> " .. sentback )
						return ""
					end
					
					-- Call our hook!
					hook.Call( "ExCommand-" .. data.ID, nil, newArgs )
					
					-- Print the return values.
					exsto.PrintReturns( sentback, I, multiplePeopleToggle, hide )
					
					-- Save this for our ! command
					exsto._LastCommand = { call = data.Call, args = newArgs }
					
				end

			end
		
        -- Console printing
        --[[if type(args) == "string" then 
			Extra = args
		else 
			Extra = table.concat(args," ")
        end]]
			
			return ""
		end
	end
	
	-- I don't think we found anything?
	if string.sub( command, 0, 1 ) == "!" and exsto.ChatSpellingSuggest:GetValue() == true and style != "console" then
		local data = { Max = 100, Com = "" } // Will a command ever be more than 100 chars?
		local dist
		// Apparently we didn't find anything...
		for k,v in pairs( exsto.Commands ) do
			
			for k,v in pairs( v.Chat ) do
				dist = exsto.StringDist( command, v )
			
				if dist < data.Max then data.Max = dist; data.Com = v end
			end
			
		end

		ply:Print( exsto_CHAT, COLOR.NAME, command, COLOR.NORM, " is not a valid command.  Maybe you want ", COLOR.NAME, data.Com, COLOR.NORM, "?" )
	end
	
end

--[[ -----------------------------------
	Function: exsto.ChatMonitor
	Description: Monitors the chat, and checks to see if commands are run.
     ----------------------------------- ]]
function exsto.ChatMonitor( ply, text )
	local args = string.Explode( " ", text )
	local command = ""
	if args[1] then command = args[1]:lower() end
	
	table.remove( args, 1 )
    
    -- Allow PM with @name
	if string.Left(command,1) == "@" and #command > 1 and string.sub(command,2,2) ~= "@" then
		table.insert(args,1,string.sub( command,2 ))
		command = "!pm"
	end

	return ExstoParseCommand( ply, command, args, "chat" )
end
hook.Add( "PlayerSay", "exsto_ChatMonitor", exsto.ChatMonitor )

--[[ -----------------------------------
	Function: exsto.ParseCommands
	Description: Run on console command typing, creates a auto-complete list for console.
     ----------------------------------- ]]
function exsto.ParseCommands( com, args )
	
	-- Split the arguments up.
	args = args:Trim()
	local split = string.Explode( " ", args )
	local command = split[1] -- Convinence.

	if command == "" then return {} end -- Its not a command D:
	if !command then return {} end
	if string.len( command ) <= 0 then return {} end
	
	local niceargs = exsto.ParseStrings( args )

	local possible = {}
	local ID = ""
	local predictedCom = ""
	
	-- Loop through the possible commands!
	for id,v in pairs( exsto.Commands ) do
		-- Loop through all possible console commands.
		for k,v in pairs( v.Console ) do
			-- Find the string
			if string.find( v:lower(), command:lower() ) then
				-- add it
				ID = id
				predictedCom = v
				table.insert( possible, v )
			end
		end
	end
	
	-- Add our command root to the begining
	for k,v in pairs( possible ) do
		possible[k] = com .. " " .. v
	end
	
	if #possible > 1 then return possible end
	
	-- Check to see our arguments availible, and what one we are on right now.
	local comData = exsto.Commands[ID]
	local comArgs = {}
	local comOptional = {}
	local comOrder = {}
	
	if comData then -- We have an ID match.
		comData = table.Copy( comData )
		comArgs = comData.Args
		comOptional = comData.Optional
		comOrder = comData.ReturnOrder
		command = predictedCom
	end
	
	if !comData then return possible end
	
	-- Check to see what arg we are typing in on
	local curArg = args[#args]
	
	-- Grab the associated command argument
	local curComArg = comOrder[#args]
	
	-- Make nice arguments
	for k,v in pairs( comArgs ) do
		table.insert( comArgs, k )
		comArgs[k] = nil
	end
	
	-- Order the args
	local newArgs = ""
	for I = 1, #comOrder do
		local item = comOrder[I]
		
		newArgs = newArgs .. item .. " "
	end		
	
	-- Add his known arguments
	for k,v in pairs( possible ) do
		possible[k] = com .. " " .. command .. " " .. newArgs
	end
	
	return possible
end

--[[ -----------------------------------
	Function: exsto.SetQuickmenuSlot
	Description: Modifies an existing command to work with the quickmenu
     ----------------------------------- ]]
function exsto.SetQuickmenuSlot( id, displayName, data )
	if !exsto.Commands[ id ] then return end
	
	-- We have our data, now add to it.
	-- Create a special caller function for it for the client to call us with.
	local randID = "_ExPlugCaller_" .. id .. "_" .. math.random( -1000, 1000 )
	
	concommand.Add( randID, function( ply, _, args )
		return ExstoParseCommand( ply, exsto.Commands[ id ].Console[ 1 ], args, "console" )
	end )
	
	if type( displayName ) == "table" then
		data = displayName
		displayName = id
	end
	
	if type( displayName ) == "nil" then
		displayName = id
	end
	
	exsto.Commands[ id ].QuickMenu = true
	exsto.Commands[ id ].CallerID = randID
	exsto.Commands[ id ].ExtraOptionals = data
	exsto.Commands[ id ].DisplayName = displayName
end

--[[ -----------------------------------
	Function: exsto.CommandCall
	Description: Run on the 'exsto' command.  It re-directs to a new command.
     ----------------------------------- ]]
function exsto.CommandCall( ply, _, args )
	exsto._TMP = ply
	if #args == 0 then
		local comSearcher = exsto.GetPlugin( "com-search" )
		if not comSearcher then
			ply:Print( exsto_CLIENT, "No command received!  Also, it looks like the command search plugin is either disabled or not here, so enable it for command searching!" ) 
			return 
		end
		
		-- Assume they need help.
		comSearcher:Search( ply )
		return
	end
	
	-- Copy the table so we can edit it clean.
	local command = args[1]
	
	-- Remove the command, we don't need it.  It should leave us with the function arguments.
	table.remove( args, 1 )
	
	-- For some reason the dedicated console rips apart anything with _ or : in it.  Meaning, we can't use STEAMID.  Fix this.
	local id = ""
	for i, arg in ipairs( args ) do
		if arg == "STEAM_0" then -- We've got a steamid.
			for I = 0, 4 do
				id = id .. args[ i + I ]
				args[ i + I ] = nil
			end
			args[ i ] = id
		end
	end

	local finished = exsto.RunCommand( ply, command, args )
	
	if !finished then
		ply:Print( exsto_CLIENT, "Error running command 'exsto " .. command .. "'" )
		return
	end
end
concommand.Add( "exsto", exsto.CommandCall, exsto.ParseCommands )

--[[ -----------------------------------
	Function: exsto.RunCommand
	Description: Adds chat commands into the Exsto list.
     ----------------------------------- ]]
function exsto.RunCommand( ply, command, args )
	return ExstoParseCommand( ply, command, args, "console" )
end

// Stolen from lua-users.org
function exsto.StringDist( s, t )
	local d, sn, tn = {}, #s, #t
		local byte, min = string.byte, math.min
		for i = 0, sn do d[i * tn] = i end
		for j = 0, tn do d[j] = j end
		for i = 1, sn do
			local si = byte(s, i)
			for j = 1, tn do
				d[i*tn+j] = min(d[(i-1)*tn+j]+1, d[i*tn+j-1]+1, d[(i-1)*tn+j-1]+(si == byte(t,j) and 0 or 1))
			end
		end
		return d[#d]
end

function exsto.OpenMenu( ply, _, args )
	ply:QuickSend( "ExOpenMenu" )
end
exsto.AddChatCommand( "menu", {
	Call = exsto.OpenMenu,
	Desc = "Opens the Exsto Menu",
	Console = { "menu" },
	Chat = { "!menu" },
	Args = {},
	Category = "Administration",
})