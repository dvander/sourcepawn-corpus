#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "[L4D2] M60 & Grenade Launcher & Chainsaw Infinite Ammo",
	description = "Gives Infinite Ammo for M60 & GL & Chainsaw to players",
}

//    Special thanks:
//    "[L4D2] Individual Infinite Ammo" by Machine and modified by Psykotik
//    ("http://forums.alliedmods.net/showthread.php?t=123100")

public void OnPluginStart()
{
	HookEvent("weapon_fire", Event_WeaponFire);
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	char weapon[64];
	int client = GetClientOfUserId(event.GetInt("userid"));
	event.GetString("weapon", weapon, sizeof(weapon));
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		int slot = -1, clipsize;
		if (StrEqual(weapon, "rifle_m60"))
		{
			slot = 0;
			clipsize = 200;
		}
		else if (StrEqual(weapon, "grenade_launcher"))
		{
			slot = 0;
			clipsize = 2;
		}
		else if (StrEqual(weapon, "chainsaw"))
		{
			slot = 1;
			clipsize = 60;
		}

		if (slot == 0 || slot == 1)
		{
			SetEntProp(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_iClip1", clipsize + 1);
		}
	}
}
