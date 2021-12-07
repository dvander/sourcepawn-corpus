#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
	name = "RespawnTimeFix",
	author = "Asher \"asherkin\" Baker",
	description = "Fixes bots skewing respawn wave timing.",
	version = PLUGIN_VERSION,
	url = "http://limetech.org"
}

// int CTFGameRules::CountActivePlayers(void)
new Handle:hCountActivePlayers;

enum
{
	GAMETYPE_CTF = 1,
	GAMETYPE_CP,
	GAMETYPE_PAYLOAD,
	GAMETYPE_ARENA,
}

public OnPluginStart()
{
	CreateConVar("respawntimefix_version", PLUGIN_VERSION, _, FCVAR_NOTIFY);
	
	new Handle:hGameConfig = LoadGameConfigFile("respawn-time-fix.games");
	if(hGameConfig == INVALID_HANDLE)
	{
		SetFailState("Unable to load respawn-time-fix.games.txt");
	}
	
	new offset = GameConfGetOffset(hGameConfig, "CountActivePlayers");
	if(offset == -1)
	{
		SetFailState("Unable to find offset for CTFGameRules::CountActivePlayers");
	}
	
	hCountActivePlayers = DHookCreate(offset, HookType_GameRules, ReturnType_Int, ThisPointer_Ignore, CountActivePlayers);
	if(hGameConfig == INVALID_HANDLE)
	{
		SetFailState("Unable to create hook for CTFGameRules::CountActivePlayers");
	}
	
	CloseHandle(hGameConfig);
}

public OnMapStart()
{
	new ret = DHookGamerules(hCountActivePlayers, false);
	if(ret == -1)
	{
		SetFailState("Unable to hook CTFGameRules::CountActivePlayers");
	}
}

bool:IsInArenaMode()
{
	return GameRules_GetProp("m_nGameType") == GAMETYPE_ARENA;
}

bool:IsReadyToPlay(client)
{
	if (!IsClientInGame(client))
	{
		return false;
	}
	
	if (GetClientTeam(client) <= 1)
	{
		return false;
	}
	
	if (GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") <= 0)
	{
		return false;
	}
	
	return true;
}

public MRESReturn:CountActivePlayers(Handle:hReturn)
{
	if (IsInArenaMode())
	{
		return MRES_Ignored;
	}
	
	new iCount;
	new iBotCount;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsReadyToPlay(i))
		{
			continue;
		}
		
		if (IsFakeClient(i))
		{
			iBotCount++;
		}
		
		iCount++;
	}
	
	if (iBotCount == iCount)
	{
		iCount = 0;
	}
	
	DHookSetReturn(hReturn, iCount);
	return MRES_Supercede;
}
