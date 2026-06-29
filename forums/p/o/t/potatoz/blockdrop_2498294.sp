#include <sourcemod>
#include <cstrike>

public Action:CS_OnCSWeaponDrop(client, weapon)
{
	new String:weapon_name[30];
    GetEntityClassname(weapon, weapon_name, sizeof(weapon_name));
	
	if(StrEqual(weapon_name, "weapon_healthshot", false)) {
	PrintToChat(client, " \x07* You cannot drop your Healthshot");
	return Plugin_Stop;
	}
}  