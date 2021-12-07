#include <sourcemod>

public Plugin myinfo = 
{
	name = "Bot kicker",
	author = "Nexd",
	description = "Bot kicker",
	version = SOURCEMOD_VERSION
};

ConVar g_Cvar_bot_quota = null;
int g_bot_quota;
int g_max_players;

public OnConfigsExecuted()
{
    g_Cvar_bot_quota = FindConVar("bot_quota");

    g_bot_quota = GetConVarInt(g_Cvar_bot_quota);
    g_max_players = GetMaxClients();
}

public OnClientPutInServer(client)
{
    if(!IsFakeClient(client))
        return;

    if(g_bot_quota < GetConVarInt(g_Cvar_bot_quota))
        SetConVarInt(g_Cvar_bot_quota, g_bot_quota);

    int i, count;
    for(i = 1; i<=g_max_players; i++)
        if(IsClientInGame(i) && GetClientTeam(i)>1)
            count++;

    if(count<=g_bot_quota)
        return;

    char name[32]
    if(!GetClientName(client, name, 31))
        return;
    ServerCommand("bot_kick %s", name);
}