#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

#pragma newdecls required
#pragma tabsize 0
bool g_bUsed[MAXPLAYERS + 1] = {false, ...};
bool g_bTimePassed = false;

ConVar  g_cTeleport,
        g_cTimer;

public Plugin myinfo =
{
    name        =   "Self Noclip",
    author    = "killjoy + SheriF",
    description =    "personal noclip for Donators",
    version  =    PLUGIN_VERSION,
    url   =    "http://www.epic-nation.com"
};
 
public void OnPluginStart()
{
    RegConsoleCmd("sm_noclipme",NoclipMe,"Toggles noclip on yourself");
    HookEvent("round_start", OnRoundStart);
 	RegAdminCmd("sm_setpos", SetPosCommand, ADMFLAG_ROOT);
    g_cTeleport = CreateConVar("sm_noclipme_teleport", "1", "Teleport player to the place defined in locations.cfg 1 = Enabled | 0 = Disabled (Default 1)");
    g_cTimer    = CreateConVar("sm_noclipme_timer", "5",   "Time in seconds to disable noclip on player (Default 5)");
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        g_bUsed[i] = false;
    }
    g_bTimePassed = false;
	CreateTimer(60.0, Timer_TimePassed);
}
public Action SetPosCommand(int client, int args)
{
	char sPath[PLATFORM_MAX_PATH];
	Format(sPath, sizeof(sPath), "configs/noclipme/locations.cfg");
	BuildPath(Path_SM, sPath, sizeof(sPath), sPath);
	if (!FileExists(sPath))
	{
		PrintToChat(client, "File not found!");
		return Plugin_Handled;	
	}
	KeyValues hKeyValues = CreateKeyValues("Locations");
	FileToKeyValues(hKeyValues, sPath);
	char sMapName[64];
    GetCurrentMap(sMapName, 64);
	KvJumpToKey(hKeyValues, sMapName, true);
	float fClientPos[3];
	GetClientAbsOrigin(client, fClientPos);
	KvSetFloat(hKeyValues, "location_X", fClientPos[0]);
	KvSetFloat(hKeyValues, "location_Y", fClientPos[1]);
	KvSetFloat(hKeyValues, "location_Z", fClientPos[2]);
    PrintToChat(client, "\x04[Noclip]\x01 You set your current positon \x04succesfully!");
    do{
	}while (KvGoBack(hKeyValues));
	KvRewind(hKeyValues);
	KeyValuesToFile(hKeyValues, sPath);
	CloseHandle(hKeyValues);
    return Plugin_Handled;	
}
public Action NoclipMe(int client, int args)
{
    char sAuthID[MAX_NAME_LENGTH];
    GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID));

    if( client < 1 || !IsClientInGame(client) || !IsPlayerAlive(client ))
    {
        PrintToChat(client, "\x04[Noclip]\x01 You have to be alive to use \x04noclip");
        return Plugin_Handled;
    }

    if (GetEntityMoveType(client) != MOVETYPE_NOCLIP && !g_bUsed[client] && g_bTimePassed)
    {
        CreateTimer(g_cTimer.FloatValue, Timer_StopNoclip, client);
        g_bUsed[client] = true;
        LogAction(client, client, "%N (%s) Enabled noclip", client, sAuthID);
        SetEntityMoveType(client, MOVETYPE_NOCLIP);
        PrintToChat(client, "\x04[Noclip]\x01 Noclip \x04enabled.");
    }
    return Plugin_Handled;
}

public Action Timer_StopNoclip(Handle timer, int client)
{
    SetEntityMoveType(client, MOVETYPE_WALK);
    PrintToChat(client, "\x04[Noclip]\x01 Noclip \x07disabled.");
    if(g_cTeleport.IntValue >= 1)
    {
    	char sPath[PLATFORM_MAX_PATH];
		Format(sPath, sizeof(sPath), "configs/noclipme/locations.cfg");
		BuildPath(Path_SM, sPath, sizeof(sPath), sPath);
		if (!FileExists(sPath))
   			 return Plugin_Handled;
		KeyValues hKeyValues = CreateKeyValues("Locations");
		if (!hKeyValues.ImportFromFile(sPath))
   			 return Plugin_Handled;
   		char sMapName[64];
    	GetCurrentMap(sMapName, 64);
		if(hKeyValues.GotoFirstSubKey())
		{
			do
			{
				char sMap[64];
				hKeyValues.GetSectionName(sMap, sizeof(sMap));
				if(StrEqual(sMap,sMapName))
				{
				 	float fClientPos[3];
					fClientPos[0] = hKeyValues.GetFloat("location_X");
					fClientPos[1] = hKeyValues.GetFloat("location_Y");
					fClientPos[2] = hKeyValues.GetFloat("location_Z");
					TeleportEntity(client, fClientPos, NULL_VECTOR, NULL_VECTOR);
				}
			}
			while(hKeyValues.GotoNextKey(false));
		}
		hKeyValues.Close();

    }
  	return Plugin_Handled;
}
public Action Timer_TimePassed(Handle timer)
{
	g_bTimePassed = true;
}