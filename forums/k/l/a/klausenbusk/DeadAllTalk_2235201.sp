#include <sourcemod>
#include <dhooks>
#pragma semicolon 1

#define PLUGIN_NAME "[ANY?] DeadAllTalk"
#define PLUGIN_VERSION "1.0.0"

new Handle:g_hCanHearAndReadChatFrom;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "KK",
	description = "Allow alive players to see what dead players type in chat",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/i_like_denmark/"
};

public OnPluginStart() 
{
	CreateConVar("sm_deadalltalk_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	new Handle:temp = LoadGameConfigFile("hearandread-offsets.games");
	if(temp == INVALID_HANDLE)
	{	
		SetFailState("Gamedata missing");
	}

	new offset = GameConfGetOffset(temp, "CanHearAndReadChatFrom");
	g_hCanHearAndReadChatFrom = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, CanHearAndReadChatFrom);

	/* lateload support */
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}

	CloseHandle(temp);
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
	{
		DHookEntity(g_hCanHearAndReadChatFrom, true, client);
	}
}

public MRESReturn:CanHearAndReadChatFrom(this, Handle:hReturn, Handle:hParams)
{
	DHookSetReturn(hReturn, true);
	return MRES_Override;
}
