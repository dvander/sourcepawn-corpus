#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

ConVar cvarIsEnabled;
ConVar mapBlockList;

public Plugin myinfo =
{
	name = "L4D2 NO_Invisible_Walls",
	author = "V1sual",
	description = "Removes Invisible walls, letting infecteds walk anywhere",
	version = "1.0.0",
	url = ""
};

public void OnPluginStart()
{
	cvarIsEnabled = CreateConVar("l4d2_no_invisible_walls", "1", "1 Removes walls on round_start, 0 disbles plugin", FCVAR_NOTIFY);
	mapBlockList = CreateConVar("l4d2_no_invisible_walls_mapblacklist", "", "Sets which maps will not have walls removed. Comma (,) separated list");
	
	CreateConVar("l4d2_no_invisible_walls_version", PLUGIN_VERSION, "L4D2 No Invisible Walls Version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT);

	HookEvent("round_start", Event_RoundStart);
	
	AutoExecConfig(true, "l4d2_no_invisible_walls");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!cvarIsEnabled.BoolValue) return;
	if (BlackListMap()) return;
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "func_playerinfected_clip")) != -1)
	{	
		AcceptEntityInput(entity, "kill"); 
	}
}

stock bool BlackListMap()
{
	char map[32], buffer[2048], buffer2[64][32];  // 64 for total ammount of map inputs, 32 for the string length, 
	
	GetCurrentMap(map, sizeof(map));
	mapBlockList.GetString(buffer, sizeof(buffer));
	
	if (strlen(buffer) > 0)
	{	
		ExplodeString(buffer, ",", buffer2, sizeof(buffer2), sizeof(buffer2[]));  
		
		for (int i = 0; i < sizeof(buffer2); i++)
		{
			if (StrEqual(map, buffer2[i], false))
			{
				LogPluginMessage("map %s found, plugin disabled", map);
				return true;
			}
		}
	}
	return false;
}

stock void LogPluginMessage(const char[] format, any:...)
{
	char f_sBuffer[1024], f_sPath[1024];
	VFormat(f_sBuffer, sizeof(f_sBuffer), format, 2);
	BuildPath(Path_SM, f_sPath, sizeof(f_sPath), "logs/l4d2_no_invisible_walls.log");
	LogToFile(f_sPath, "%s", f_sBuffer);
}