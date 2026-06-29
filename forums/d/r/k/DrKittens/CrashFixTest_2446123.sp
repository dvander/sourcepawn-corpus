#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "[BH] Hotfix for crashes",
	author = "Kittens",
	description = "We test all our patches at valve hq",
	version = "1.0",
	url = "ban-hammer.net/forums"
}

public Action CS_OnCSWeaponDrop(int client, int weaponIndex)
{
	AcceptEntityInput(weaponIndex, "kill");
	new yunowork = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	EquipPlayerWeapon(client, yunowork);
	return Plugin_Handled;
}

