/**
* hide & Seek for Sourcemod, by 1695.
*
* Description:
*   Terrorists take the appearence of models and hide in the map, Cts must find and kill them before round end.
*
* CVars:
*   sm_hns_enable - Enables\Disables Hide & Seek plugin
*     - 0 = off
*     - 1 = on (default)
*   sm_hns_announce - Enables\Disables announcing of the plugin at the beginning of the round.
*     - 0 = off
*     - 1 = on (default)
*   sm_hns_life_add - Amount of life to give to CTs when they hurt a Terro.
*     - Ranges from 0 to 100. (default = 10)
*   sm_hns_life_take - Amount of life to take to CTs when they shoot nothing.
*     - Ranges from 0 to 100. (default = 2)
*   sm_hns_blind_time - duration while CTs can't move and see at the beginning of the round.
*     - Ranges from 10 to 100. (default = 35)
*
* Version 1.0
* Changelog @ NOWHERE
*/

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
 
public Plugin:myinfo = 
{
	name = "Hide & Seek",
	author = "1695",
	description = "HnS for SM",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:cvarEnable;
new Handle:cvarLifeAdd;
new Handle:cvarLifeTake;
new Handle:cvarBlindTime;
new HealthOffset;
new bool:Announce;
new bool:isHooked;

new Handle:g_hModelsMenu = INVALID_HANDLE;		// Models menu HANDLE

public OnPluginStart()
{

	LoadTranslations("hns.phrases");

	CreateConVar("sm_hns_version", PLUGIN_VERSION, "Hide&Seek version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_hns_enable", "1", "Enables/Disables the Hide & Seek plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAnnounce = CreateConVar("sm_hns_announce", "1", "Enables/Disables the Hide & Seek announcement at the beginning of the round.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarLifeAdd = CreateConVar("sm_hns_life_add", "10", "Sets the amount of health to give to a CT for hurting a terro.", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	cvarLifeTake = CreateConVar("sm_hns_life_take", "2", "Sets the amount of health to take to a CT for shooting nothing.", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	cvarBlindTime = CreateConVar("sm_hns_blind_time", "35", "Sets time in seconds, before CTs can see and move.", FCVAR_PLUGIN, true, 0.0, true, 100.0);

	CreateTimer(2.0, OnPluginStart_Delayed);

}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (GetConVarInt(cvarEnable) == 1)
	{
		isHooked = true;
		HookEvent("round_start", event_RoundStart);

		HookConVarChange(cvarEnable, CvarChange_Enable);

		LogMessage("[Hide&Seek] - Loaded");
	}

	if (GetConVarInt(cvarAnnounce) == 1)
	{
		Announce = true;
		HookEvent("round_start", event_RoundStart);

		HookConVarChange(cvarAnnounce, CvarChange_Announce);
	}
}

public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new playerId = GetEventInt(event, "userid");
	new player = GetClientOfUserId(playerId);
	
	if (player != 0)
	{
		new playerTeam = GetClientTeam(player);

		if (playerTeam = 0)
			{
			1 // action to take according to player team
			2
			3
			4
			}
		else if (playerTeam = 1)
			{
			1 // action to take according to player team
			2
			3
			4
			}
	}
	PrintToChatAll("[Hide & Seek] %T", "Announce", LANG_SERVER);
}




public CvarChange_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarInt(cvarEnable) <= 0)
	{
		if (isHooked)
		{
			isHooked = false;
			UnhookEvent("round_start", event_RoundStart);
		}
	}
	else if (!isHooked)
	{
		isHooked = true;
		HookEvent("round_start", event_RoundStart);
	}
}

public CvarChange_Announce(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarInt(cvarAnnounce) <= 0)
	{
		if (Announce)
		{
			Announce = false;
			UnhookEvent("round_start", event_RoundStart);
		}
	}
	else if (!Announce)
	{
		Announce = true;
		HookEvent("round_start", event_RoundStart);
	}
}
