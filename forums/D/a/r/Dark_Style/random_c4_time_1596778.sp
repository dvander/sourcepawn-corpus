/*
[Cvars]
// 1 by round, 0 by map (Default: 1)
sm_random_c4t_mode <1 or 0>
// Min time for random c4 time (Default: 0)
sm_random_c4t_mintime <value>
// Max time for random c4 time (Default: 35)
sm_random_c4t_maxtime <value>

[Changelog]
0.0.1 	- 	First release playable.
*/

#include <sourcemod>
#pragma semicolon 1

#define Version	"0.0.1"

new Handle:CvarMode;
new Handle:CvarMin;
new Handle:CvarMax;
new Handle:mp_c4timer;
new Random;
new bool:IsHooked;

public Plugin:myinfo = 
{
	name = "Random C4 Time",
	author = "Dark Style",
	description = "This plugin set a random time for c4 explode by map/round",
	version = Version,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CvarMode = CreateConVar("sm_random_c4t_mode", "1", "1 - Per Round / 0 - Per Map", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarMin = CreateConVar("sm_random_c4t_mintime", "5", "Min. time for bomb count", FCVAR_PLUGIN, true, 0.0);
	CvarMax = CreateConVar("sm_random_c4t_maxtime", "45", "Max. time for bomb count", FCVAR_PLUGIN, true, 1.0);
	
	mp_c4timer = FindConVar("mp_c4timer");
	
	if(GetConVarInt(CvarMode) == 0)
	{
		Functions();
		
		PrintToServer("[SM] Random C4 Time [MAP]: %i second%s", Random, (Random > 1) ? "s." : ".");
		
		return;
	}
	
	HookEvent("round_start", Event_RoundStart);
	
	IsHooked = true;
}

public OnPluginEnd()
{
	if(IsHooked == true) UnhookEvent("round_start", Event_RoundStart);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Functions();
	
	PrintToChatAll("[SM] Random C4 Time [ROUND]: %i second%s", Random, (Random > 1) ? "s." : ".");
}

Functions()
{
	Random = GetRandomInt(GetConVarInt(CvarMin), GetConVarInt(CvarMax));
	SetConVarInt(mp_c4timer, Random);
}
