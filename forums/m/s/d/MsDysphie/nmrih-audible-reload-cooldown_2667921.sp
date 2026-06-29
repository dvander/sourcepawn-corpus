#include <sourcemod>
#include <sdktools_tempents>

ConVar cvCooldown;
ConVar cvReloads;
int cooldownTime[MAXPLAYERS + 1] = {-1, ...};

public Plugin myinfo =
{
	name = "Audible Reload Cooldown",
	author = "Dysphie",
	description = "Adds a cooldown to audible reloads.",
	version = "0.1"
};

public void OnPluginStart()
{
	cvReloads = CreateConVar("sm_audible_reloads_enable", "1", "Enable reload transmit and receive.");
	cvCooldown = CreateConVar("sm_audible_reloads_cooldown", "10", "Audible reload cooldown in seconds (0 = Disable)");

	AddTempEntHook("TEAudibleReload", OnAudibleReload);
}

public void OnClientPutInServer(int client)
{
    cooldownTime[client] = -1;
}

public Action OnAudibleReload(const char[] te_name, const int[] Players, int numClients, float delay)
{
	if(!cvReloads.BoolValue)
		return Plugin_Handled;

	int currentTime = GetTime();
	int client = TE_ReadNum("_playerIndex");
	
	if (cooldownTime[client] != -1 && cooldownTime[client] > currentTime)
	{
		return Plugin_Handled;
	}

	cooldownTime[client] = currentTime + cvCooldown.IntValue;
	return Plugin_Continue;
}