#include <sourcemod>

public Plugin:myinfo =
{
	name = "Random Ctf Limit",
	author = "Tylerst",
	description = "Randomize the intel cap limit on map start",
	version = "1.0.0",
};

public OnMapStart()
{
	new random = GetRandomInt(0, 1000000);
	SetConVarInt(FindConVar("tf_flag_caps_per_round"), random); 
}
