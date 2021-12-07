#include <sourcemod>
#include <cstrike>

#define NAME "CSS Late Spawn"
#define VERSION "0.7b3"

new Handle:g_CVarEnable;
new bool:g_bCanLateSpawn[MAXPLAYERS+1];

public Plugin:myinfo = {

	name = NAME,
	author = "meng, St00ne",
	version = VERSION,
	description = "Spawns late joining players in CS:S.",
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{

	CreateConVar("sm_csslatespawn", VERSION, NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_PRINTABLEONLY|FCVAR_DONTRECORD);
	g_CVarEnable = CreateConVar("sm_latespawn_enable", "1", "Enable/disable plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	AddCommandListener(CmdJoinClass, "joinclass");
}

public OnClientConnected(client)
{
	g_bCanLateSpawn[client] = true;
}

public Action:CmdJoinClass(client, const String:command[], argc)
{
	if (GetConVarBool(g_CVarEnable) && g_bCanLateSpawn[client])
	{
		g_bCanLateSpawn[client] = false;
		
		CreateTimer(1.0, LateSpawnClient, GetClientSerial(client));
	}
}

public Action:LateSpawnClient(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client != 0)
	{
		if (IsClientConnected(client) && IsClientInGame(client) && IsValidEntity(client) && !IsPlayerAlive(client) && IsClientObserver(client) && GetClientTeam(client) > 1)
		{
			CS_RespawnPlayer(client);
		}
	}
}

/**END**/