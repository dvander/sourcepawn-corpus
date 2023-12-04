#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>

public Plugin myinfo = 
{
	name = "[TF2] Civilian Mode",
	author = "Drixevel",
	description = "Creates a command which places players into civilian mode.",
	version = "1.0.0",
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_civilian", Command_Civilian, "Toggles civilian mode on or off.");
}

public Action Command_Civilian(int client, int args)
{
	if (client < 1)
	{
		PrintToServer("You must be in-game to use this command.");
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "You must be alive to use this command.");
		return Plugin_Handled;
	}

	if (GetEntProp(client, Prop_Send, "m_nForceTauntCam") > 0)
	{
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");

		int health = GetClientHealth(client);
		TF2_RegeneratePlayer(client);
		SetEntityHealth(client, health);

		PrintToChat(client, "[SM] Civilian: Disabled");

		return Plugin_Handled;
	}

	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");

	TF2_RemoveAllWeapons(client);

	PrintToChat(client, "[SM] Civilian: Enabled");

	return Plugin_Handled;
}