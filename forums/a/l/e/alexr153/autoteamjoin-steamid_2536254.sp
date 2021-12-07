#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hAlexr"
#define PLUGIN_VERSION "1.0"
#define Default 0x01
#define limeGREEN 0x06

#include <sourcemod>
#include <cstrike>

#pragma newdecls required

EngineVersion g_Game;

ConVar atj_chatMessage;

Handle g_hKV;
char szKvFile[PLATFORM_MAX_PATH];
int g_iWhatTeam[MAXPLAYERS + 1];
char steamidHolder[2][32];

public Plugin myinfo = 
{
	name = "STEAMID Auto team join",
	author = PLUGIN_AUTHOR,
	description = "Sets a given STEAMID to a specified team.",
	version = PLUGIN_VERSION,
	url = "NUN"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	atj_chatMessage = CreateConVar("atj_chatMessage", "1", "Shows chat message on player spawned by ATJ");
}

public void OnClientPutInServer(int client)
{
	get_steamid(client);
	CreateTimer(1.0, steamid_spawner, client, TIMER_FLAG_NO_MAPCHANGE);
}

void get_steamid(int client)
{
	char line[60], steamid[32];
	
	BuildPath(Path_SM, szKvFile, sizeof(szKvFile), "configs/Autoteamjoin-steamids.txt");
	
	GetClientAuthId(client, AuthId_Steam3, steamid, 32);
	
	g_hKV = OpenFile(szKvFile, "r");
	
	if(g_hKV != INVALID_HANDLE)
	{
		while(!IsEndOfFile(g_hKV))
		{
			ReadFileLine(g_hKV, line, 200);
			ExplodeString(line, "--", steamidHolder, sizeof(steamidHolder), sizeof(steamidHolder[]));
			
			if(StrEqual(steamidHolder[0], steamid))
			{
				if(StrEqual(steamidHolder[1], "T", false))
				{
					g_iWhatTeam[client] = 1;
					CloseHandle(g_hKV);
					return; 
				} else if(StrEqual(steamidHolder[1], "CT", false))
				{
					g_iWhatTeam[client] = 2;
					CloseHandle(g_hKV);
					return;
				}
				else if(StrEqual(steamidHolder[1], "SPEC", false))
				{
					g_iWhatTeam[client] = 3;
					CloseHandle(g_hKV);
					return;
				}
			}
		}
		CloseHandle(g_hKV);
	} else {
		//ATJ Auto team join
		SetFailState("[ATJ] (configs/Autoteamjoin-steamids.txt) File was not found!");
	}
}

public Action steamid_spawner(Handle timer, any client)
{
	if(g_iWhatTeam[client] == 1)
	{
		if(IsPlayerAlive(client))
			CS_RespawnPlayer(client);
		CS_SwitchTeam(client, CS_TEAM_T);
	}
	else if(g_iWhatTeam[client] == 2)
	{
		if(IsPlayerAlive(client))
			CS_RespawnPlayer(client);
		CS_SwitchTeam(client, CS_TEAM_CT);
	}
	else if(g_iWhatTeam[client] == 3)
	{
		if(IsPlayerAlive(client))
			CS_RespawnPlayer(client);
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	}
	
	if(GetConVarBool(atj_chatMessage))
	{
		if(g_iWhatTeam[client] == 1)
			PrintToChat(client, "[%cATJ%c] Your team has been set to Terrorist.", limeGREEN, Default);
		else if(g_iWhatTeam[client] == 2)
			PrintToChat(client, "[%cATJ%c] Your team has been set to Counter-Terrorist.", limeGREEN, Default);
			else if(g_iWhatTeam[client] == 2)
			PrintToChat(client, "[%cATJ%c] Your team has been set to Spectator.", limeGREEN, Default);
	}
}
