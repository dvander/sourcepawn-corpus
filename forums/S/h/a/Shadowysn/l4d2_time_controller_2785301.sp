#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "[L4D2] Time Controller"
#define PLUGIN_AUTHOR "McFlurry, Shadowysn"
#define PLUGIN_DESC "host_timescale functionality for Left 4 Dead 2."
#define PLUGIN_VERSION "1.1"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=139030"
#define PLUGIN_NAME_SHORT "Time Controller"
#define PLUGIN_NAME_TECH "timescale"

#define timeEnt_Name "plugin_time_control_ent"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	description = PLUGIN_DESC,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

public void OnPluginStart()
{
	static char version_str[64];
	Format(version_str, sizeof(version_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	Handle version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, version_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	RegAdminCmd("sm_timescale", TimeScale, ADMFLAG_CHEATS, "Change timescale of game");
}

public void OnPluginEnd()
{
	int timeEnt = FindEntityByTargetname(MaxClients, timeEnt_Name);
	if (RealValidEntity(timeEnt))
	{
		AcceptEntityInput(timeEnt, "Reset");
		AcceptEntityInput(timeEnt, "Kill");
	}
}

public void OnMapEnd()
{
	int timeEnt = FindEntityByTargetname(MaxClients, timeEnt_Name);
	if (RealValidEntity(timeEnt))
	{
		AcceptEntityInput(timeEnt, "Reset");
		AcceptEntityInput(timeEnt, "Kill");
	}
}

Action TimeScale(int client, int args)
{
	static char arg[12];
	if (args == 1)
	{
		GetCmdArg(1, arg, sizeof(arg));
		float scale = StringToFloat(arg);
		if (scale <= 0.0)
		{
			ReplyToCommand(client, "[SM] Invalid number!");
			return Plugin_Handled;
		}
		int timeEnt = FindEntityByTargetname(MaxClients, timeEnt_Name);
		if (!RealValidEntity(timeEnt))
		{
			timeEnt = CreateEntityByName("func_timescale");
			DispatchKeyValue(timeEnt, "targetname", timeEnt_Name);
			DispatchKeyValue(timeEnt, "desiredTimescale", "1.0");
			DispatchKeyValue(timeEnt, "acceleration", "100.0");
			DispatchKeyValue(timeEnt, "minBlendRate", "100.0");
			DispatchKeyValue(timeEnt, "blendDeltaMultiplier", "100.0");
			DispatchSpawn(timeEnt);
		}
		
		if (scale != 1.0)
		{
			DispatchKeyValue(timeEnt, "desiredTimescale", arg);
			AcceptEntityInput(timeEnt, "Reset");
			AcceptEntityInput(timeEnt, "Start");
		}
		else
		{
			AcceptEntityInput(timeEnt, "Stop");
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_timescale <float>");
	}
	return Plugin_Handled;
}

stock int FindEntityByTargetname(int index, const char[] findname, bool onlyNetworked = false)
{
	for (int i = index; i < (onlyNetworked ? GetMaxEntities() : (GetMaxEntities()*2)); i++) {
		if (!RealValidEntity(i)) continue;
		static char name[128];
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		if (strcmp(name, findname, false) != 0) continue;
		return i;
	}
	return -1;
}

stock bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }