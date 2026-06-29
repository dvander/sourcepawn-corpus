#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
//#include <sdkhooks>

#pragma newdecls required


public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
		int userid = GetClientOfUserId(event.GetInt("userid"));
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		int hp = GetClientHealth(attacker);
		if(hp==0)
		PrintToChat(userid, "Don't suicide its not healthy");
		else
		PrintToChat(userid, "Your killer had %d HP", hp);
}