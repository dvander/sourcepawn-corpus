#include <sourcemod>
#define PLUGIN_VERSION "0.1"
#define FLAG	ADMFLAG_CHEATS
new Handle:host_timescale;
new Handle:g_hCvarSpeed;
public Plugin:myinfo = 
{
	name = "Server-Side Speedhack",
	author = "Afronanny",
	description = "Look like a speedhacker!",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1136035"
}

public OnPluginStart()
{
	host_timescale = FindConVar("host_timescale");
	
	g_hCvarSpeed = CreateConVar("sm_speedhack_speed", "2.0", "Amount of times faster/slower than normal to make yourself", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 5.0);
	
	RegAdminCmd("sm_makemefast", Command_MakeFast, FLAG);
	RegAdminCmd("sm_normalspeed", Command_NormalSpeed, FLAG);
}

public Action:Command_MakeFast(client, args)
{
	SetConVarFloat(host_timescale, GetConVarFloat(g_hCvarSpeed));
	SendConVarValue(client, FindConVar("sv_cheats"), "1");
	return Plugin_Handled;
}

public Action:Command_NormalSpeed(client, args)
{
	SetConVarFloat(host_timescale, 1.0);
	SendConVarValue(client, FindConVar("sv_cheats"), "0");
	return Plugin_Handled;
}
