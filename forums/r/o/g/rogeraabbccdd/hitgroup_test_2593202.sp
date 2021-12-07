#include <sourcemod>

#pragma newdecls required

public Plugin myinfo =
{
	name = "[CS:GO] Test hitgroup",
	author = "Kento",
	version = "1.0",
	description = "Test hitgroup.",
	url = "http://steamcommunity.com/id/kentomatoryoshika/"
};

public void OnPluginStart() 
{
	HookEvent("player_hurt", Event_PlayerHurt);
}

public Action Event_PlayerHurt (Event event, const char[] name, bool dontBroadcast)
{
	int Hitgroup = event.GetInt("hitgroup");
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if(Hitgroup <= 0)			PrintToChat(attacker, "Hitgroup: %d, NULL HITGROUP", Hitgroup);
	else if(Hitgroup == 1)	PrintToChat(attacker, "Hitgroup: %d, HEAD", Hitgroup);
	else if(Hitgroup == 2)	PrintToChat(attacker, "Hitgroup: %d, CHEST", Hitgroup);
	else if(Hitgroup == 3)	PrintToChat(attacker, "Hitgroup: %d, STOMACH", Hitgroup);
	else if(Hitgroup == 4)	PrintToChat(attacker, "Hitgroup: %d, LEFT_ARM", Hitgroup);
	else if(Hitgroup == 5)	PrintToChat(attacker, "Hitgroup: %d, RIGHT_ARM", Hitgroup);
	else if(Hitgroup == 6)	PrintToChat(attacker, "Hitgroup: %d, LEFT_LEG", Hitgroup);
	else if(Hitgroup == 7)	PrintToChat(attacker, "Hitgroup: %d, RIGHT_LEG", Hitgroup);
	else					PrintToChat(attacker, "Hitgroup: %d, NEW HITGROUP???", Hitgroup);
}