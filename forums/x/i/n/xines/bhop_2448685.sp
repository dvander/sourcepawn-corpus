#include <sourcemod>
#pragma semicolon 1

ConVar CvarPluginEnabled;
bool PluginEnabled;

public Plugin myinfo =
{
    name = "BunnyHop Enhancement",
    author = "Requi",
    description = "SourceMod plugin that enhances bunnyhopping.",
    version = "1.0.1",
    url = "http://www.requi-dev.de"
}

public void OnPluginStart()
{
	CvarPluginEnabled = CreateConVar("sm_bhop_enabled", "1", "Sets whether BunnyHop is enabled", FCVAR_NOTIFY);
	HookConVarChange(CvarPluginEnabled, OnPluginEnabledChange);
	AutoExecConfig(true, "sm_bhop");
	PluginEnabled = GetConVarBool(CvarPluginEnabled);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(!PluginEnabled && !IsFakeClient(client))
		return Plugin_Continue;
	
	int m_iWater = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	if(m_iWater <= 1 && GetEntityMoveType(client) != MOVETYPE_LADDER)
	{
		if((buttons & IN_JUMP) && !(GetEntityFlags(client) & FL_ONGROUND))
		{
			buttons &= ~IN_JUMP;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public int OnPluginEnabledChange(Handle cvar, const char[] oldVal, const char[] newVal)
{
    PluginEnabled = GetConVarBool(cvar);
}