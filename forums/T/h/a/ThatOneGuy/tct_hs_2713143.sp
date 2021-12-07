/*

*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <togsclantags>	//https://github.com/ThatOneHomelessGuy/togsclantags
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define LoopValidPlayers(%1)						for(int %1 = 1; %1 <= MaxClients; %1++)		if(IsValidClient(%1))

int g_iKills[MAXPLAYERS + 1] = {0, ...};
int g_iHSs[MAXPLAYERS + 1] = {0, ...};

public Plugin myinfo =
{
	name = "TOGs Clan Tags - Headshot Percent",
	author = "That One Guy",
	description = "Uses TOGS Clan Tags to set score board tags showing headshot percentages. Rolled !resetscore into plugin as well.",
	version = PLUGIN_VERSION,
	url = "https://www.togcoding.com/togcoding/index.php"
}

public void OnPluginStart()
{
	CreateConVar("version_tct_hs", PLUGIN_VERSION, "TOGs Clan Tags - Headshot Percent - Version number.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegConsoleCmd("sm_rs", Cmd_ResetScore, "Resets your frags and death count.");
	RegConsoleCmd("sm_resetscore", Cmd_ResetScore, "Resets your frags and death count.");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public void OnConfigsExecuted()
{
	LoopValidPlayers(i)
	{
		SetTag(i);
	}
}

public Action Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int victim = GetClientOfUserId(hEvent.GetInt("userid"));
	int killer = GetClientOfUserId(hEvent.GetInt("attacker"));
	
	if(victim == killer)
	{
		return Plugin_Continue;
	}
	
	g_iKills[killer]++;
	if(hEvent.GetInt("headshot"))
	{
		g_iHSs[killer]++;
	}
	SetTag(killer);
	
	return Plugin_Continue;
}

void SetTag(int client)
{
	if(!g_iKills[client])
	{
		TOGsClanTags_SetExtTag(client, "-");
	}
	else
	{
		char sTag[10];
		Format(sTag, sizeof(sTag), "%4.1f%%", 100.0*(float(g_iHSs[client]) / float(g_iKills[client])) );
		TOGsClanTags_SetExtTag(client, sTag);
	}
}

public Action Cmd_ResetScore(int client, int iArgs)
{
	if(!IsValidClient(client))
	{
		ReplyToCommand(client, "You must be in game to use this command!");
		return Plugin_Handled;
	}
	
	if(!GetClientFrags(client) && !GetClientDeaths(client))
	{
		ReplyToCommand(client, "Your death and score are both already at zero!");
		return Plugin_Handled;
	}
	
	SetEntProp(client, Prop_Data, "m_iFrags", 0);
	SetEntProp(client, Prop_Data, "m_iDeaths", 0);
	g_iHSs[client] = 0;
	g_iKills[client] = 0;

	PrintToChatAll( " \x04%N was ashamed and reset their score.", client);

	return Plugin_Handled;
}

bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}
	return true;
}

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////// CHANGE LOG //////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/*
	1.0.0
		* Initial creation.
		
*/