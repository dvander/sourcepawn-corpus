#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "[L4D2] Unlimited Chainsaw",
	author = "bullet28",
	description = "Chainsaw fuel always at 100%",
	version = "1",
	url = ""
}

public void OnPluginStart()
{
	HookEvent("weapon_fire", eventWeaponFire);
}

Action eventWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("weaponid") == 20)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			static char classname[16];
			event.GetString("weapon", classname, sizeof(classname));
			if (StrEqual(classname, "weapon_chainsaw"))
			{
				SetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_iClip1", 30);
			}
		}
	}
	return Plugin_Continue;
}