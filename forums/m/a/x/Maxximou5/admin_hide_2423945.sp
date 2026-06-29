#include <sourcemod>
// ConVars
ConVar cvar_hideadmin_enabled = null;
ConVar cvar_hideadmin_connect = null;
ConVar cvar_hideadmin_team = null;
// Plugin Start
public void OnPluginStart()
{
	// Console Variables
	cvar_hideadmin_enabled = CreateConVar("sm_hideadmin_on", "1", "Enable or disable hideadmin.", _, true, 0.0, true, 1.0);
	cvar_hideadmin_connect = CreateConVar("sm_hideadmin_connect", "1", "Hides admins on connect.", _, true, 0.0, true, 1.0);
	cvar_hideadmin_team = CreateConVar("sm_hideadmin_team", "1", "Hides admins on player change or join.", _, true, 0.0, true, 1.0);
	// Hook Events
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	// AutoExec
	AutoExecConfig(true, "hideadmin");
}

public Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && (GetUserFlagBits(client) & ADMFLAG_BAN))
	{
		if(cvar_hideadmin_enabled.BoolValue && cvar_hideadmin_connect.BoolValue)
		{
			event.BroadcastDisabled = true;
		}
	}
	return Plugin_Continue;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && (GetUserFlagBits(client) & ADMFLAG_BAN))
	{
		if(cvar_hideadmin_enabled.BoolValue && cvar_hideadmin_team.BoolValue)
		{
			if(!event.GetBool("silent"))
			{
				event.BroadcastDisabled = true;
			}
		}
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if (!(0 < client <= MaxClients)) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	return true;
}