#include <sourcemod>
#include <tf2_stocks>

public OnPluginStart()
{
	HookEvent("arena_round_start", RoundStart);
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			SetClip(i, 0, 0, i);
			SetClip(i, 1, 0, i);
			SetAmmo(i, 0, 0, i);
			SetAmmo(i, 1, 0, i);
		}
	}
}

stock SetClip(client, wepslot, newAmmo, admin)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (!IsValidEntity(weapon))
	{
		ReplyToCommand(admin, "\x04[\x03SetAmmo\x04]:\x01 Invalid weapon slot");
	}
	if (IsValidEntity(weapon))
	{
		new iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		SetEntData(weapon, iAmmoTable, newAmmo, 4, true);
	}
}


stock SetAmmo(client, wepslot, newAmmo, admin)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (!IsValidEntity(weapon))
	{
		ReplyToCommand(admin, "\x04[\x03SetAmmo\x04]:\x01 Invalid weapon slot");
	}
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
	}
}