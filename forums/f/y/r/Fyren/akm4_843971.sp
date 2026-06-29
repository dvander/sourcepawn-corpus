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
	for (new i = 0; i < NWEAPONS; i++)
		RegConsoleCmd(commands[i], akm4);

	HookEvent("round_start", rs);
}

public Action:rs(Handle:event, String:name[], bool:broadcast)
{
	decl String:msg[192];
	msg[0] = '\0';
	strcopy(msg, sizeof(msg), "Say");

	for (new i = 0; i < NWEAPONS - 1; i++)
		Format(msg, sizeof(msg), "%s%s%s%s", msg, " !", commands[i][3], ",");
	Format(msg, sizeof(msg), "%s%s%s%s", msg, " or !", commands[NWEAPONS - 1][3], " for weapons.");

	PrintToChatAll(msg);
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
		found = StrEqual(cmd, commands[weapon]); 

	if (found) 
	{ 
		new old = GetPlayerWeaponSlot(client, 0);
		if (old != -1)
		{
			RemovePlayerItem(client, old);
			RemoveEdict(old);
		}

		GivePlayerItem(client, weapons[weapon]);
	}

	return Plugin_Handled;
}
