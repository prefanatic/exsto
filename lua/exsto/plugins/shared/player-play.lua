local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	ID = "sound-player",
	Name = "Sound Player",
	Desc = "Plays a sound on a client",
	Owner = "Shank",
})

if SERVER then

	function PLUGIN:PlaySound( owner, ply, path, clientOnly )
		if clientOnly then
			ply:Send( "ExPlaySound", path )
		else
			ply:EmitSound( path )
		end

		return {
			Activator = owner,
			Player = ply,
			Wording = " has played a sound on ",
		}
	end
	PLUGIN:AddCommand( "playsound", {
		Call = PLUGIN.PlaySound,
		Desc = "Allows a player to play a sound on the selected player.",
		Console = { "play", },
		Chat = { "!play" },
		ReturnOrder = "Victim-Path-ClientOnly",
		Optional = { ClientOnly = false },
		Args = { Victim = "PLAYER", Path = "STRING", ClientOnly = "BOOLEAN" },
		Category = "Fun",
	})
	
else
	
	local function play( reader )
		LocalPlayer():EmitSound( reader:ReadString() )
	end
	exsto.CreateReader( "ExPlaySound", play )

end

PLUGIN:Register()