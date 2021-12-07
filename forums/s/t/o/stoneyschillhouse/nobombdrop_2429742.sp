#include <sourcemod>
#include <sdktools_functions>
#include <sdktools_entinput>
public Plugin:myinfo = 
{
	name = "No Bomb Drop", 
	author = "DarklSide edited by stoney", 
	description = "no bomb dropping", 
	version = "1.1", 
	url = ""
};
public OnPluginStart()
{
	AddCommandListener(dropb, "drop");
	AddCommandListener(killb, "kill");
	AddCommandListener(killb, "joinclass");
	AddCommandListener(killb, "jointeam");
	AddCommandListener(killb, "spectate");
}
public Action:dropb(client, const String:command[], args)
{
	if (client && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		if (b_dropbomp(client) > -1)
		{
			PrintToChat(client, "You must try to plant the bomb!");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public b_dropbomp(client)
{
	new String:s_weapon[16];
	new i_weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (i_weapon > -1 && GetEdictClassname(i_weapon, s_weapon, sizeof(s_weapon)))
	{
		if (StrEqual(s_weapon, "weapon_c4", true))
		{
			return i_weapon;
		}
	}
	return -1;
}
public Action:killb(client, const String:command[], args)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		new i_weapon2 = b_dropbomp(client);
		if (i_weapon2 != -1)
		{
			new i_drops = -1;
			for (new x = 1; x <= MaxClients; x++)
			{
				if (IsClientInGame(x) && client != x && IsPlayerAlive(x))
				{
					if (GetClientTeam(x) == 2)
					{
						i_drops = x;
					}
					continue;
				}
			}
			if (i_drops != -1)
			{
				if (RemovePlayerItem(client, i_weapon2))
				{
					if (GivePlayerItem(i_drops, "weapon_c4") > -1)
					{
						AcceptEntityInput(i_weapon2, "kill");
						PrintToChat(i_drops, "Тебе выдан \"дар Богов\" - бомба: в виде c4!");
					}
				}
			}
		}
	}
	return Plugin_Continue;
} 