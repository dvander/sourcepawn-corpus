#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

ConVar gCV_BaseFunctionality = null;

int gI_Impulse[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[CS:GO] Native Flashlight",
	author = "shavit",
	description = "Utilizes Source's native flashlight in CS:GO.",
	version = PLUGIN_VERSION,
	url = "https://github.com/shavitush"
}

public void OnPluginStart()
{
	CreateConVar("nativeflashlight_version", PLUGIN_VERSION, "Plugin version.", (FCVAR_NOTIFY | FCVAR_DONTRECORD));
	gCV_BaseFunctionality = CreateConVar("nativeflashlight_base", "0", "Enable the base functionality of +lookatweapon?", 0, true, 0.0, true, 1.0);

	AutoExecConfig();

	AddCommandListener(LookAtWeapon, "+lookatweapon");
}

public void OnConfigsExecuted()
{
	ConVar mp_flashlight = FindConVar("mp_flashlight");
	mp_flashlight.BoolValue = true;
	mp_flashlight.SetBounds(ConVarBound_Lower, true, 1.0);
	delete mp_flashlight;
}

public Action LookAtWeapon(int client, const char[] command, int argc)
{
	gI_Impulse[client] = 100;

	return (gCV_BaseFunctionality.BoolValue)? Plugin_Continue:Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse)
{
	if(!IsPlayerAlive(client) || gI_Impulse[client] == 0)
	{
		return Plugin_Continue;
	}

	impulse = gI_Impulse[client];
	gI_Impulse[client] = 0;

	return Plugin_Changed;
}
