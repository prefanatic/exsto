--Exsto Grammar Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Grammar Nazi Plugin",
	ID = "grammar",
	Desc = "A plugin that allows for almost perfect grammar.",
	Owner = "Hobo",
})

Fixes = {	
		"b",		
		"becoz-because",
		"c-see",
		"dat-that",
		"dis-this",
		"doin-doing",
		"doesnt-doesn't",
		"dont-don't",
		"gonna-going to",
		"hasnt-hasn't",
		"i-I", 
		"its-it's", 
		"im-I'm",
		"lets-let's",
		"o-oh",
		"r-are",
		"thats-that's",
		"theres-there's",
		"thier-their",
		"u-you",
		"ur-you're",
		"wat-what",
		"wont-won't",
		"y-why",
		
		"hobo-Hobo",
	}

function Grammar(Message)
	local Last = ""
	local foundChar = false
	local Length = string.len(Message)
	while (string.byte(Message,Length) or 0) > 32 and (string.byte(Message,Length) or 0) < 64 do
		Last = string.sub(Message,Length,Length)..Last
		Message = string.sub(Message,1,Length-1)
		foundChar = true
		Length = string.len(Message)
	end
     local FirstChar = string.sub(Message,1,1)
	if string.sub(Message,Length,Length) == "D" then -- Face lol.
		Last = ""
	elseif !foundChar then
		Last = "."
	end
	local MsgArray = string.Explode(" ",Message)
     for i,k in pairs (MsgArray) do
     	for j,l in pairs(Fixes) do
			local Fixing = string.Explode("-",l)[1]
     		if string.lower(k) == Fixing then
			Msg(tostring(j).." -"..l.."\n")
				MsgArray[i] = string.Explode("-",Fixes[j])[2]
			end
     	end
     end
     Message = table.concat(MsgArray," ")
	 FirstChar = string.upper(FirstChar)
     local Rest = string.sub(Message,2)
     Message = FirstChar..Rest..Last
     Message = string.Replace(Message,"/.",".")
     
	return Message
end

function PLUGIN:Init()
	self.Correct = exsto.CreateVariable( "ExGrammarCorrect",
		"Correct",
		false,
		"Enables grammar correction."
	)
	self.Correct:SetCategory( "Grammar" )
end

function PLUGIN:PlayerSay(ply,text,team,dead)
	local Active = self.Correct:GetValue() or ply.Grammar == true
	local match = 0
	if Active and text and type(text) == "string" && text != "" then --Nothing seems to work, so I'll try EVERYTHING. =3
        for i,com in pairs(exsto.Commands) do
            for k,comm in pairs(com.Chat) do
                if string.match( text, comm, 1, true ) then match = 1 end
            end
        end
		if !tobool(match) then
			if (string.byte(text,1) or 0) < 32 or (string.byte(text or "",1) or 0) > 64 then
				return Grammar(text)
			end
		end
	end
end
function PLUGIN:Grammar( owner, ply )
    if ply.Grammar and ply.Grammar == true then
		ply.Grammar = false
	else
		ply.Grammar = true
	end
	return { COLOR.CHAT,"Grammar plugin turned ",COLOR.NAME,ply.Grammar }
end		
PLUGIN:AddCommand( "grammar", {
	Call = PLUGIN.Grammar,
	Desc = "A Grammar Nazi plugin, for the lols",
	Console = { "grammar" },
	Chat = { "!grammar" },
    ReturnOrder = "Player",
    Args = { Player = "PLAYER" },
	Category = "Utilities",
})

PLUGIN:Register()