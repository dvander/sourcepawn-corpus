#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "2.0.3"

new Handle:v_Rate  = INVALID_HANDLE;
new Handle:v_Size  = INVALID_HANDLE;
new Handle:v_AdminOnly  = INVALID_HANDLE;
new Handle:v_MaxMetal  = INVALID_HANDLE;
new Handle:v_Enabled  = INVALID_HANDLE;

new Handle:h_Timer  = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Engineer Metal Regen",
	author = "DarthNinja",
	description = "Regenerates engineers build metal at a configurable rate.",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com",
}

public OnPluginStart()
{
	CreateConVar("sm_rmetal_version", PLUGIN_VERSION, "Metal Regen Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	v_Rate = CreateConVar("sm_rmetal_rate", "5", "How fast in seconds to regen metal");
	v_Size = CreateConVar("sm_rmetal_size", "5", "How much metal to regen per tick");
	v_MaxMetal = CreateConVar("sm_rmetal_max", "200", "The plugin will not add metal if the player's metal is at or above this value", 0, true, 0.0, true, 1023.0);
	v_AdminOnly = CreateConVar("sm_rmetal_adminonly", "0", "Set to 1 to only enable for admins", 0, true, 0.0, true, 1.0);
	v_Enabled = CreateConVar("sm_rmetal_enable", "1", "Set to 0 to disable the plugin", 0, true, 0.0, true, 1.0);

	HookConVarChange(v_Rate, LetsUpdateThisShit);
}

public LetsUpdateThisShit(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (h_Timer != INVALID_HANDLE)
	{
		KillTimer(h_Timer);
		h_Timer = INVALID_HANDLE;
	}
	h_Timer = CreateTimer(GetConVarFloat(v_Rate), Timer_Regen, _, TIMER_REPEAT);
}

public OnConfigsExecuted()
{
	if (h_Timer != INVALID_HANDLE)
	{
		KillTimer(h_Timer);
		h_Timer = INVALID_HANDLE;
	}
	h_Timer = CreateTimer(GetConVarFloat(v_Rate), Timer_Regen, _, TIMER_REPEAT);
}

public Action:Timer_Regen(Handle:timer, any:user)
{
	if (!GetConVarBool(v_Enabled))
		return;

	//PrintToChatAll("Timer called, timestamp: %i", GetTime());
	new iMaxMetal = GetConVarInt(v_MaxMetal);
	new iMetalToAdd = GetConVarInt(v_Size);
	new bool:AdminOnly = GetConVarBool(v_AdminOnly);

	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || TF2_GetPlayerClass(i) != TFClass_Engineer)
			continue;	// Client isnt valid

		if (AdminOnly && !CheckCommandAccess(i, "rmetal_override", ADMFLAG_CUSTOM4))
			continue;	// Admin only mode + not an admin

		new iCurrentMetal = GetEntProp(i, Prop_Data, "m_iAmmo", 4, 3);
		new iNewMetal = iMetalToAdd + iCurrentMetal;
		if (iNewMetal <= iMaxMetal)
			SetEntProp(i, Prop_Data, "m_iAmmo", iNewMetal, 4, 3);
	}
}



