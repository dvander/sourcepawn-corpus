#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_NAME "[L4D2] InputKill Kick Prevention"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Stops clients from getting kicked via the Kill input"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL ""
#define PLUGIN_NAME_SHORT "InputKill Kick Prevention"
#define PLUGIN_NAME_TECH "inputkill_kick"

#pragma semicolon 1;
#pragma newdecls required;

#define TEAM_SURVIVOR 2
#define TEAM_PASSING 4

ConVar version_cvar;

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
	char version_str[128];
	Format(version_str, sizeof(version_str), "%s version.", PLUGIN_NAME_SHORT);
	char cmd_str[32];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, version_str, FCVAR_NONE|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	// Checks for worldspawn
	if (IsValidEntity(0))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			PreventKill(i, true);
		}
	}
}

public void OnPluginEnd()
{
	if (!IsValidEntity(0)) return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		PreventKill(i, false);
	}
}

// Not sure if OnClientPutInServer is needed
/*public void OnClientPutInServer(int client)
{
	PreventKill(client);
}*/
public void OnEntityCreated(int entity, const char[] class)
{
	if ((class[0] == 's' || class[0] == 'p') && 
	(StrEqual(class, "survivor_bot", false) || StrEqual(class, "player", false)))
	{
		SDKHook(entity, SDKHook_SpawnPost, SpawnPost);
	}
}
void SpawnPost(int client)
{
	if (!RealValidEntity(client)) return;
	PreventKill(client);
	SDKUnhook(client, SDKHook_SpawnPost, SpawnPost);
}

void PreventKill(int client, bool toggle = true)
{
	if (!IsValidClient(client) || (IsPassingSurvivor(client) && IsFakeClient(client))) return;
	int human_spec = GetIdleSurvivor(client);
	if (IsValidClient(human_spec))
	{
		PreventKill(human_spec, toggle);
	}
	
	SetVariantString("self.ValidateScriptScope()");
	AcceptEntityInput(client, "RunScriptCode");
	
	if (toggle)
	{
		SetVariantString("plugin_shouldKill <- false;");
		AcceptEntityInput(client, "RunScriptCode");
		SetVariantString("function InputKill() {return plugin_shouldKill}");
		// unfortunately, killhierarchy cannot be stopped.
		//AcceptEntityInput(client, "RunScriptCode");
		//SetVariantString("function InputKillHierarchy() {return plugin_shouldKill; printl(\"DENIED\")}");
	}
	else
	{
		SetVariantString("plugin_shouldKill <- true;");
	}
	AcceptEntityInput(client, "RunScriptCode");
}

/*bool IsGameSurvivor(int client)
{
	return (GetClientTeam(client) == TEAM_SURVIVOR);
}*/

bool IsPassingSurvivor(int client)
{
	return (GetClientTeam(client) == TEAM_PASSING);
}

/*bool IsSurvivor(int client)
{
	return (IsGameSurvivor(client) || IsPassingSurvivor(client));
}*/

int GetIdleSurvivor(int client)
{
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID")) return -1;
	int target = GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
	return target;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

bool RealValidEntity(int entity)
{
	return (entity > 0 && IsValidEntity(entity));
}