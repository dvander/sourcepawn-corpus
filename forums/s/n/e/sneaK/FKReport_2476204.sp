#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

char Killer[MAXPLAYERS + 1];
bool usedcmd[MAXPLAYERS + 1];
bool clientiskiller[MAXPLAYERS + 1];
EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "FK Reporter",
	author = "NoyKB",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/bravefox"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	RegAdminCmd("sm_fk", Command_reportfk, 0);
	HookEvent("player_death", player_death);
	HookEvent("round_start", round_start);
}

public Action Command_reportfk(int client, int args)
{
	if(IsClientInGame(client))
	{
		if(usedcmd[client])
		{
			PrintToChat(client, "\x01[\x04BGamer\x01]\x10You already used !fk this round.");
			return Plugin_Handled;
		}
		if(IsPlayerAlive(client))
		{
			PrintToChat(client, "\x01[\x04BGamer\x01]\x10You must to be dead to use this command.");
			return Plugin_Handled;
		}
		if(GetClientTeam(client) == CS_TEAM_CT)
		{
			PrintToChat(client, "\x01[\x04BGamer\x01]\x10You must to be on T team to use !fk.");
			return Plugin_Handled;
		}
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && CheckCommandAccess(i, "", ADMFLAG_GENERIC) && !clientiskiller[client])
			{
				PrintToChat(i, "\x01[\x04BGamer\x01]\x04%N \x10reported \x04%s \x10for freekilling him.", client, Killer[client]);
				usedcmd[client] = true;
			}
		}
	}
	return Plugin_Handled;
}
public Action player_death(Event event, char[] name, bool dontBroadcast)
{
	char KillerName[MAX_NAME_LENGTH];
	int client, attacker;
	client = GetClientOfUserId(event.GetInt("userid"));
	attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(client == attacker)
	{
		clientiskiller[client] = true;
	}
	GetClientName(attacker, KillerName, MAX_NAME_LENGTH);
	Format(Killer[client], MAX_NAME_LENGTH, KillerName);
}	
public Action round_start(Event event, char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		usedcmd[i] = false;
	}
}	