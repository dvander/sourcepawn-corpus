/* >>> CHANGELOG <<< //
[ v1.0 ]
	Initial Release
[ v1.1 ]
	Code Cleanup
	Proper L4D1 Support
// >>> CHANGELOG <<< */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "[L4D/L4D2] Last Active Weapon",
    author = "MasterMind420",
    description = "Your active weapon will remain the same going down as well as getting back up instead of auto switching",
    version = "1.1",
    url = ""
}

public void OnPluginStart()
{
	HookEvent("revive_success", eEvents, EventHookMode_Pre);
	HookEvent("player_incapacitated", eEvents, EventHookMode_Pre);
}

public void eEvents(Event event, const char[] name, bool dontBroadcast)
{
	int client;

	if (StrEqual(name, "revive_success"))
		client = GetClientOfUserId(GetEventInt(event, "subject"));
	else if (StrEqual(name, "player_incapacitated"))
		client = GetClientOfUserId(GetEventInt(event, "userid"));

	SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanSwitchTo);
}

public Action OnWeaponCanSwitchTo(int client, int weapon)
{
	SDKUnhook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanSwitchTo);
	return Plugin_Handled;
}