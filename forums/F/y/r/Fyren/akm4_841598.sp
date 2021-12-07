#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "AKM4",
	author = "",
	description = "",
	version = "",
	url = ""
}

#define NWEAPONS 4
new String:commands[NWEAPONS][] = { "sm_ak", "sm_m4", "sm_au", "sm_sg" };
new String:weapons[NWEAPONS][] = { "weapon_ak47", "weapon_m4a1", "weapon_aug", "weapon_sg552" };

public OnPluginStart()
{
	new i;
	for (i = 0; i < NWEAPONS; i++)
		RegConsoleCmd(commands[i], akm4);
}

public Action:akm4(client, args)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || !GetEntProp(client, Prop_Send, "m_bInBuyZone"))
		return Plugin_Handled;

	decl String:cmd[64];
	GetCmdArg(0, cmd, sizeof(cmd));

	new found;
	new weapon = -1;
	
	while (!found && (weapon++ < NWEAPONS)) 
	{ PrintToServer("Checking weapon: %d", weapon);
		found = StrEqual(cmd, commands[weapon]); }

	if (found) { GivePlayerItem(client, weapons[weapon]); PrintToServer("Found weapon: %d", weapon); }

	return Plugin_Handled;
}
