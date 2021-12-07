#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

bool patch[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[L4D] Lock From Ledge",
	author = "AlexMy",
	description = "<- Description ->",
	version = "1.0",
	url = "https://forums.alliedmods.net/forumdisplay.php?f=52"
}

public void OnPluginStart()
{
	HookEvent("player_now_it",       eventPlayerNowIt);
	HookEvent("player_no_longer_it", eventPlayerNoLongerIt);
	HookEvent("player_ledge_grab",   eventPlayerLedgeGrab, EventHookMode_Pre);
}

public void eventPlayerNoLongerIt(Event event, const char [] name, bool dontBroadcast)
{
	patch[GetClientOfUserId(event.GetInt("userid"))] = false;
}

public void eventPlayerNowIt(Event event, const char [] name, bool dontBroadcast)
{
	patch[GetClientOfUserId(event.GetInt("userid"))] = true;
}

public Action eventPlayerLedgeGrab(Event event, const char [] name, bool dontBroadcast)
{
	static int client;
	if((client = GetClientOfUserId(event.GetInt("userid"))) && (!patch[client]) && client && GetClientTeam(client) == 2 && !IsFakeClient(client))
	{
		PrintHintText(client, "Печалька %N, но на этом сервере нельзя повиснуть на выступе!", client); 
		SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
		SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
