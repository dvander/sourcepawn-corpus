#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0"
new bool:g_bEnabled = true;
new Handle:g_hEnabled = INVALID_HANDLE;


public Plugin:myinfo = {
	name        = "DoD:S infinite fastrun",
	author      = "Darkranger",
	description = "DoD:S infinite fastrun",
	version     = PLUGIN_VERSION,
	url         = "http://dark.asmodis.at"
}

public OnPluginStart()
{
	CreateConVar("sm_dods_infinite_fastrun", PLUGIN_VERSION, "DoD:S infinite fastrun", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hEnabled  = CreateConVar("sm_dods_infinite_fastrun_enabled",  "1", "Enable(1)/Disable(0) Infinite Fastrun", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookConVarChange(g_hEnabled, ConVarChange_Enabled);
}


public OnGameFrame()
{
	if (g_bEnabled)
	{
		for(new client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				SetEntPropFloat(client, Prop_Send, "m_flStamina", 100.0);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
			}
		}
	}
}

public ConVarChange_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled  = StrEqual(newValue, "1");
}