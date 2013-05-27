local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Timed Ranks",
	ID = "timedranks",
	Desc = "Allows ranking players per their time online.",
	Owner = "Prefanatic",
} )

function PLUGIN:Init()
	exsto.TimedRanksDB = FEL.CreateDatabase( "exsto_plugin_timedranks" )
		exsto.TimedRanksDB:ConstructColumns( {
			Rank = "VARCHAR(255):primary:not_null";
			SetTime = "INTEGER";                                    
		})
end

function PLUGIN:SetRankTime( caller, rankid, time )
	if !exsto.GetPlugin( "time" ) then return { caller, COLOR.NORM, "Missing the ", COLOR.NAME, "time plugin.", COLOR.NORM, "  Unable to set timed ranks." } end
	if !exsto.Ranks[ rankid ] then return { caller, COLOR.NORM, "Unknown rank ", COLOR.NAME, rankid } end

	exsto.TimedRanksDB:AddRow( { Rank = rankid, SetTime = time } );
end
PLUGIN:AddCommand( "setranktime", {
	Call = PLUGIN.SetRankTime,
	Desc = "Allows users to set the time for automatic rank-up.",
	Console = { "ranktime" },
	Chat = { "!ranktime" },
	ReturnOrder = "Rank-Time",
	Args = { Rank = "STRING", Time = "TIME" },
	Category = "Misc",
})

local time, imm
function PLUGIN:Think()
	if !exsto.GetPlugin( "time" ) then return end
	
	for _, ply in ipairs( player.GetAll() ) do
		time = ply:GetTotalTime()
		imm = exsto.Ranks[ ply:GetRank() ].Immunity

		--print( time )

		for _, rank in ipairs( exsto.TimedRanksDB:ReadAll() ) do
			if exsto.Ranks[ rank.Rank ].Immunity < imm and time > rank.SetTime then
				self:Print( "Setting " .. ply:Nick() .. " to rank '" .. rank.Rank .. "'" );
				ply:SetRank( rank.Rank )
				return
			end
		end
	end
end


PLUGIN:Register()