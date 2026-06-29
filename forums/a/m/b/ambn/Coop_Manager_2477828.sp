#include <sourcemod>
#define PLUGIN_VERSION "1.5.0"
public Plugin:myinfo = {
	name = "[CSGO] COOP Manager",
	author = "noBrain",
	description = "Manage coop servers operation",
	version = PLUGIN_VERSION,
};
//Handles
new Handle:g_team = INVALID_HANDLE;
new Handle:g_enable = INVALID_HANDLE;
new Handle:g_knifeonly = INVALID_HANDLE;
new Handle:g_maxrounds = INVALID_HANDLE;
new Handle:g_svname = INVALID_HANDLE;
//Booleans
//Defines
//Strings
new String:StrServerName[64];

public void OnPluginStart()
{
	//Hooks
    HookEvent("round_start", Event_NextRound, EventHookMode_PostNoCopy);
	//ConVars
	g_team = CreateConVar("sm_bot_team", "1", "team that bots will be added there. T = 1,CT = 2");
	g_enable = CreateConVar("sm_cm_enable", "1", "Enable/Disable the plugin.");
	g_knifeonly = CreateConVar("sm_bots_knife_only", "0", "Set If The Map Needs Bots To Use Knifes Only.");
	g_maxrounds = CreateConVar("sm_cm_maxrounds", "2", "The Game Max Rounds.");
	g_svname = FindConVar("hostname");
	GetConVarString(g_svname, StrServerName, sizeof(StrServerName));
	//AdminCMD
	//ConsoleCMD
}
public void OnClientPostAdminCheck(client)
{
	if (GetConVarInt(g_enable == 0))
	{
		return Plugin_Handled;
	}
	CreateTimer(15.0 , MovePlayer, client);
}
public Action MovePlayer(Handle timer, any:client)
{
	new String:PlName[MAX_NAME_LENGTH];
	GetClientName(client, PlName, sizeof(PlName));
	if (GetConVarInt(g_team) == 1)
	{
		if (GetClientTeam(client) != 3 && !IsFakeClient(client))
		{
			ChangeClientTeam(client, 3);
			PrintToChatAll(" \x04[Co-oP Manager]\x2 Client %s Has Moved To CT Side!", PlName);
			return Plugin_Handled;
		}
		else
		{
			return Plugin_Handled;
		}
	}
	else if (GetConVarInt(g_team) == 2)
	{
		if (GetClientTeam(client) != 2 && !IsFakeClient(client))
		{
			ChangeClientTeam(client, 2);
			PrintToChatAll(" \x04[Co-oP Manager]\x2 Client %s Has Moved To T Side!", PlName);
			return Plugin_Handled;
		}
		else
		{
			return Plugin_Handled;
		}
	}
	else
	{
		PrintToChatAll(" \x04[Co-oP Manager]\x2 sm_bot_team value is incorrect! Setting It To Default Value ...", PlName);
		SetConVarInt(g_team, 1);
		ChangeClientTeam(client, 3);
		PrintToChatAll(" \x04[Co-oP Manager]\x2 Client %s Has Moved To CT Side!", PlName);
		return Plugin_Handled;
	}
}
public Event_NextRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, GamePostStart);
	CreateTimer(0.1, GameStart);
}  
public Action GamePostStart(Handle timer)
{
	UseDefaultCfg();
}
public Action GameStart(Handle timer, any:client)
{
	if (GetConVarInt(g_team) == 1)
	{
		//3 = CT , 2 = T , 1 = Spect
		ServerCommand("hostname \"%s (Join CT)\" ", StrServerName);
		ServerCommand("mp_mp_respawn_on_death_t 1");
		ServerCommand("mp_mp_respawn_on_death_ct 0");
		ServerCommand("bot_join_team T");
		ServerCommand("bot_kick ct all");
		if(GetConVarInt(g_knifeonly) == 1)
		{
			ServerCommand("bot_knives_only 1");
		}
		else
		{
			ServerCommand("bot_knives_only 0");
		}
	}
	else if (GetConVarInt(g_team) == 2)
	{
		ServerCommand("hostname \"%s (Join T)\" ", StrServerName);
		ServerCommand("mp_mp_respawn_on_death_ct 1");
		ServerCommand("mp_mp_respawn_on_death_t 0");
		ServerCommand("bot_join_team CT");
		ServerCommand("bot_kick t all");
		if(GetConVarInt(g_knifeonly) == 1)
		{
			ServerCommand("bot_knives_only 1");
		}
		else
		{
			ServerCommand("bot_knives_only 0");
		}
	}
	else
	{
		PrintToChatAll(" \x04[Co-oP Manager]\x2 Error! Value Of sm_bot_team Is Wrong! T = 1,CT = 2");
		ServerCommand("mp_mp_respawn_on_death_ct 1");
		ServerCommand("mp_mp_respawn_on_death_t 1");
		ServerCommand("bot_join_team any");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public void UseDefaultCfg()
{
	ServerCommand("mp_freezetime 5");
	ServerCommand("mp_roundtime 60");
	ServerCommand("bot_quota 64");
	ServerCommand("mp_limitteams 0");
	ServerCommand("mp_use_respawn_waves 0");
	ServerCommand("sv_full_alltalk 1");
	ServerCommand("mp_maxrounds %d", GetConVarInt(g_maxrounds));
}