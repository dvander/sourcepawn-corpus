#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION   "1.1"

new Handle:g_lastFragKnifeEna = INVALID_HANDLE;
new Handle:g_fragLimit;

public Plugin:myinfo = {
    name = "Last frag knife",
    author = "iDragon",
    description = "When a player is one kill off the mp_fraglimit it strips all weapons except knife, which will force them to knife last kill.",
    version = PLUGIN_VERSION,
    url = "http://pro-css.co.il/"
};

public OnPluginStart() {

	g_lastFragKnifeEna = CreateConVar("sm_lastfrag_knife_enabled", "1", "Enable last frag knife plugin? DO not change this cvar, Unless you know what you are doing.");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("item_pickup", Event_OnItemPickup);
	
	g_fragLimit = FindConVar("mp_fraglimit");
	HookConVarChange(g_fragLimit, fragLimitConVar);
	
	PrintToChatAll("\x04Last frag knife\x03 Loaded.");
	
	if (GetConVarInt(g_fragLimit) <= 0)
	{
		ServerCommand("sm_lastfrag_knife_enabled 0");
		PrintToChatAll("\x04Last frag knife:\x03 Disabled. \x04Please set mp_fraglimit num. \x03(num > 0)");
	}
}

public OnPluginEnd()
{
	PrintToChatAll("\x04Last frag knife\x03 Un-Loaded.");
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_lastFragKnifeEna))
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (GetClientFrags(attacker) == (GetConVarInt(g_fragLimit) - 2))
		{
			CreateTimer(0.01, StripWeapons, attacker);
			PrintToChat(attacker, "\x04You are one kill off the mp_fraglimit. Go and knife the last player.");
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_lastFragKnifeEna))
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (GetClientFrags(client) == (GetConVarInt(g_fragLimit) - 1))
		{
			CreateTimer(0.01, StripWeapons, client);
			PrintToChat(client, "\x04You are one kill off the mp_fraglimit. Go and knife the last player.");
		}
	}
}

public Action:Event_OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_lastFragKnifeEna))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetClientFrags(client) == (GetConVarInt(g_fragLimit) - 1))
		{
			CreateTimer(0.01, StripWeapons, client);
			PrintToChat(client, "\x04You are one kill off the mp_fraglimit. Go and knife the last player.");
		}
	}
}

public fragLimitConVar(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal) > 0)
	{
		ServerCommand("sm_lastfrag_knife_enabled 1");
		PrintToChatAll("\x04Last frag knife\x03 Enabled.");
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (GetClientFrags(i) == (GetConVarInt(g_fragLimit) - 1))
			{
				CreateTimer(0.01, StripWeapons, i);
				PrintToChat(i, "\x04You are one kill off the mp_fraglimit. Go and knife the last player.");
			}
		}
	}
	else
	{
		ServerCommand("sm_lastfrag_knife_enabled 0");
		PrintToChatAll("\x04Last frag knife\x03 Disabled.\x03 Please use a number. \x04(number > 0)");
	}
}

public Action:StripWeapons(Handle:timer, any:client)
{
	new weapon_slot;
	for(new i = 0; i < 5; i++)
	{
		if(i == 2) continue;
		while((weapon_slot = GetPlayerWeaponSlot(client, i)) != -1)
			RemovePlayerItem(client, weapon_slot);
	}
	ClientCommand(client, "slot3");
}