#include <sourcemod>

public Plugin myinfo = 
{
	name = "Spawn Armor",
	author = "Mr.Derp",
	description = "",
	version = "",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);
}

public Action Event_Spawn(Event gEventHook, const char[] gEventName, bool iDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(gEventHook, "userid"));
	if (IsClientConnected(client) && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
	}
}