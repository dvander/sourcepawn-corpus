#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

static ConVar g_hPluginOn;
static bool g_bPluginOn;

public Plugin myinfo =
{
	name = "[L4D] Change Team",
	author = "BloodyBlade",
	description = "Cmds for change teams.",
	version = PLUGIN_VERSION,
	url = "https://bloodsiworld.ru/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_Left4Dead || ev == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead game series.");
	return APLRes_SilentFailure;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_change_team_version", PLUGIN_VERSION, "Change Team plugin version.", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_hPluginOn = CreateConVar("l4d_change_team_on", "1", "Enable or Disable plugin.\n1 = Enable plugin.\n0 = Disable plugin.", CVAR_FLAGS, true, 0.0, true, 1.0);
	AutoExecConfig(true, "l4d_change_team");
    g_hPluginOn.AddChangeHook(OnPluginEnableChanged);
    RegConsoleCmd("sm_spec", ChangeToSpec);
    RegConsoleCmd("sm_surv", ChangeToSurv);
    RegConsoleCmd("sm_inf", ChangeToInf);
}

public void OnConfigsExecuted()
{
	OnPluginEnableChanged(null, "", "");
}

void OnPluginEnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_bPluginOn = g_hPluginOn.BoolValue;
}

Action ChangeToSpec(int client, int args)
{
    if(g_bPluginOn && IsValidClient(client, 1))
    {
        ChangeClientTeam(client, 1);
    }
    return Plugin_Handled;
}

Action ChangeToSurv(int client, int args)
{
    if(g_bPluginOn && IsValidClient(client, 2))
    {
        ChangeClientTeam(client, 2);
    }
    return Plugin_Handled;
}

Action ChangeToInf(int client, int args)
{
    if(g_bPluginOn && IsValidClient(client, 3))
    {
        ChangeClientTeam(client, 3);
    }
    return Plugin_Handled;
}

stock bool IsValidClient(int client, int iTeam)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) != iTeam;
}
