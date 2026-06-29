#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION "1.1"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar Enable;
bool Allow[MAXPLAYERS + 1] = {false, ...}, g_bCvarAllow = false;

public Plugin myinfo = 
{
	name = "[L4D & L4D2] Survivor Crawl Pounce Fixes",
	author = "McFlurry",
	description = "Disallows crawling of survivor while being pounced and while being revived",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if(test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin supports Left 4 Dead series only.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_crawl_fix_version", PLUGIN_VERSION, "Version of survivor crawl fix", CVAR_FLAGS|FCVAR_DONTRECORD);
	Enable = CreateConVar("l4d_crawl_fix_enable", "1", "Enables Crawl Fixes", CVAR_FLAGS);

	Enable.AddChangeHook(ConVarChanged_Allow);

	AutoExecConfig(true, "l4d2_crawl_fix");
}

public void OnMapStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		Allow[i] = false;
	}
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bCvarAllow = Enable.BoolValue;
	if(!g_bCvarAllow && bCvarAllow)
	{
		g_bCvarAllow = true;
		HookEvent("lunge_pounce", PounceStart);
		HookEvent("pounce_end", PounceEnd);
		HookEvent("revive_begin", ERevive);
		HookEvent("revive_end", ERevive);
		HookEvent("revive_success", ERevive);
	}
	else if(g_bCvarAllow && !bCvarAllow)
	{
		g_bCvarAllow = false;
		UnhookEvent("lunge_pounce", PounceStart);
		UnhookEvent("pounce_end", PounceEnd);
		UnhookEvent("revive_begin", ERevive);
		UnhookEvent("revive_end", ERevive);
		UnhookEvent("revive_success", ERevive);
	}
}

Action PounceStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if(client > 0) Allow[client] = true;
	return Plugin_Continue;
}

Action PounceEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if(client > 0) Allow[client] = false;
	return Plugin_Continue;
}

Action ERevive(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0) Allow[client] = true;
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(g_bCvarAllow && Allow[client] && view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated")) && (buttons & IN_FORWARD)) return Plugin_Handled;
	return Plugin_Continue;
}
