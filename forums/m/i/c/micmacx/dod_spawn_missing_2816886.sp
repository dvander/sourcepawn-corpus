#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

bool resetdsm = false;
Handle Cvar_Numb;


public Plugin myinfo = 
{
	name = "Map Spawn Missing", 
	author = "Micmacx", 
	description = "Create log for map missing spawn", 
	version = "1.0", 
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=micmacx&description=&search=1"
};

public void OnPluginStart()
{
	CreateConVar("dod_spawn_missing", PLUGIN_VERSION, "Version of plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_Numb = CreateConVar("dod_num_spawn", "16", "number of spawn for one team, server 32 slots = 16", _, true, 1.0, true, 17.0);
	HookEventEx("dod_round_start", RoundEvent, EventHookMode_Post);
	AutoExecConfig(true, "dod_spawn_missing", "dod_spawn_missing");
}

public void OnMapStart()
{
	resetdsm = false;
}


public void RoundEvent(Handle event, const char []name, bool dontBroadcast)
{
	if(!resetdsm)
	{
		int numallies = 0;
		int numaxis = 0;
		int entid = -1;
		while((entid = FindEntityByClassname(entid, "info_player_allies")) != -1)
		{
			if (IsValidEntity(entid)) numallies++;
		}
		entid = -1;
		while((entid = FindEntityByClassname(entid, "info_player_axis")) != -1)
		{
			if (IsValidEntity(entid)) numaxis++;
		}
		int Numb = GetConVarInt(Cvar_Numb);
		if (numallies < Numb || numaxis < Numb)
		{
			char mapname[256];
			GetCurrentMap(mapname, sizeof(mapname));
			char LogsTo_path[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, LogsTo_path, sizeof(LogsTo_path), "logs/spawn_missing.txt");
			LogToFileEx(LogsTo_path, "   .:[%s]:.   .:[Allies : %i spawns]:.   .:[Axis : %i spawns]:.", mapname, numallies, numaxis);
		}
		resetdsm = true;
	}
}
