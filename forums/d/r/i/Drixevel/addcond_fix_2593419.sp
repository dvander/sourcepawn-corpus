//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define PLUGIN_VERSION "1.0.0"

//Sourcemod Includes
#include <sourcemod>

//ConVars
ConVar convar_BlockedConditions;

public Plugin myinfo =
{
	name = "[TF2] addcond fix",
	author = "Keith Warren (Shaders Allen)",
	description = "Fixes addcond by removing certain conditions from use due to crashing.",
	version = PLUGIN_VERSION,
	url = "https://github.com/ShadersAllen"
};

public void OnPluginStart()
{
	CreateConVar("sm_addcondfix_version", PLUGIN_VERSION, "Version control.");
	convar_BlockedConditions = CreateConVar("sm_addcondfix_blocked", "88", "Conditions the plugin should block. (separate by spaces)");
	AutoExecConfig();

	AddCommandListener(OnAddCond, "addcond");
}

public Action OnAddCond(int client, const char[] command, int argc)
{
	if (argc == 0)
	{
		return Plugin_Continue;
	}

	char sBuffer[12];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));

	char sBlocked[256];
	convar_BlockedConditions.GetString(sBlocked, sizeof(sBlocked));

	if (StrContains(sBlocked, sBuffer) != -1)
	{
		PrintToChat(client, "This condition is blocked.");
		return Plugin_Stop;
	}

	return Plugin_Continue;
}
