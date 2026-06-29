#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required
int KillsCounter[MAXPLAYERS + 1] = 0;
int HSCounter[MAXPLAYERS + 1] = 0;
public Plugin myinfo = 
{
	name = "HeadShot percentage on clan tag",
	author = "SheriF",
	description = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn);
}
public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	SetClanTag(client, HSCounter[client], KillsCounter[client]);
}
public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int userid = GetClientOfUserId(event.GetInt("userid"));
	if(attacker!=userid)
	{
		KillsCounter[attacker]++;
		bool headshot = event.GetBool("headshot");
		if(headshot)
		HSCounter[attacker]++;
		SetClanTag(attacker,HSCounter[attacker], KillsCounter[attacker]);
	}
}
public void OnClientPutInServer(int client)
{
	HSCounter[client] = 0;
	KillsCounter[client] = 0;
}
public void SetClanTag(int client,int hs,int kills)
{
	if(kills==0 || hs==0)
	CS_SetClientClanTag(client, "0.0%");
	else
	{
		float hsPercentage = 100.0*(float(hs) / float(kills));
		char shsPercentage[6];
		FloatToString(hsPercentage, shsPercentage, 6);
		StrCat(shsPercentage, 7, "%");
		CS_SetClientClanTag(client, shsPercentage);
	}
}