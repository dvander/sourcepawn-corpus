#include <sourcemod>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[L4D2] Infinite Hordes/Tanks Blocker",
	author = "Psyk0tik (Crasher_3637)",
	description = "Blocks infinite hordes/Tanks when rescue vehicle is ready.",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=328088"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "\"Infinite Hordes/Tanks Blocker\" only supports Left 4 Dead 2.");

		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

ConVar g_cvBlockMethod;

int g_iFinaleType;

public void OnPluginStart()
{
	g_cvBlockMethod = CreateConVar("l4d2_ifb_method", "1", "Method for blocking infinite Tanks when rescue vehicle arrives.\n0: Block infinite hordes/Tanks.\n1: Block Tanks from spawning.", _, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d2_infinite_finale_blocker");
}

public void OnMapStart()
{
	g_iFinaleType = 0;
}

public void OnMapEnd()
{
	g_iFinaleType = 0;
}

public Action L4D_OnSpawnTank(const float vecPos[3], const float vecAng[3])
{
	// Rescue Vehicle Ready; block infinite Tank spawns
	return (g_cvBlockMethod.BoolValue && g_iFinaleType == 6) ? Plugin_Handled : Plugin_Continue;
}

public Action L4D2_OnChangeFinaleStage(int &finaleType, const char[] arg)
{
	if (!g_cvBlockMethod.BoolValue && finaleType == 6)
	{
		return Plugin_Handled; // Rescue Vehicle Ready; block change to prevent infinite hordes/Tanks
	}

	g_iFinaleType = finaleType; // Record finale type

	return Plugin_Continue; // Continue as usual
}