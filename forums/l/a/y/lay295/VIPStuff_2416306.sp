#include <sourcemod>
#include <sdktools>

new IsVIP[MAXPLAYERS + 1] = false;

public Plugin myinfo = 
{
	name = "VIP Stuff",
	author = "Mr.Derp",
	description = "VIP Stuff",
	version = "1.0",
	url = "http://steamcommunity.com/id/iLoveAnime69"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
}

public OnClientPostAdminCheck(client)
{
	if (CheckCommandAccess(client ,"is_vip", ADMFLAG_CUSTOM1))
	{
		IsVIP[client] = true;
	}
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsVIP[client])
	{
		SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
		SetEntityHealth(client, 115);
		GivePlayerItem(client, "weapon_hegrenade");
		GivePlayerItem(client, "weapon_smokegrenade");
		GivePlayerItem(client, "weapon_flashbang");
		GivePlayerItem(client, "weapon_flashbang");
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsVIP[client])
	{
		if (IsClientConnected(client) && IsPlayerAlive(client))
		{
			if (event.GetBool("headshot"))
			{
				SetEntityHealth(client, GetClientHealth(client) + 15);
				SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount")+700);
			} else {
				SetEntityHealth(client, GetClientHealth(client) + 10);
				SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount")+500);
			}
		}
	}
}

public Action:Event_PlayerDisconnect(Handle: event, const String:name[], bool:dont_broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	IsVIP[client] = false;
}