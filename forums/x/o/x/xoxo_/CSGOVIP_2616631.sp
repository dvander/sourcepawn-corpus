#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "fafafa"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

native bool CSGOVIP_IsClientVIP(int client);
native Store_GetClientCredits(int client);
native Store_SetClientCredits(int client, int credits);

public Plugin myinfo = 
{
	name = "fafafa Vip Addons", 
	author = PLUGIN_AUTHOR, 
	description = "Custom features for vips", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_Player_SpawnPost, EventHookMode_Post);
    CreateTimer(350.0, Timer_GiveCredits, _,TIMER_REPEAT);
}

public Action Event_Player_SpawnPost(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!CSGOVIP_IsClientVIP(client))
		return;
	SetEntityHealth(client, 110);
	GivePlayerItem(client, "weapon_hegrenade");
	GivePlayerItem(client, "weapon_flashbang");
	GivePlayerItem(client, "weapon_smokegrenade");
}

public Action Timer_GiveCredits(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !CSGOVIP_IsClientVIP(i))continue;
		PrintToChat(i, " \x04[WePlay]\x01 You have earned \x0410\x01 credits for being a \x07Vip\x01.");
		Store_SetClientCredits(i, Store_GetClientCredits(i) + 10);
		
	}
} 