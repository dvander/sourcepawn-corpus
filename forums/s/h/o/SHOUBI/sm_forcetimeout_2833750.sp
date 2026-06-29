
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new bool:g_bDisabled[MAXPLAYERS + 1];
new Handle:g_hTimer_Notify[MAXPLAYERS + 1];
new Handle:g_hTimer_Query[MAXPLAYERS + 1];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hRate = INVALID_HANDLE;

new Float:g_fRate;
new bool:g_bLateLoad, bool:g_bEnabled;

public Plugin:myinfo = 
{
	name = "Force Custom Timeout", 
	author = "Warlock", 
	description = "Prevents players from joining a server as long as timeout cvars are default", 
	version = PLUGIN_VERSION, 
	url = "https://mygamingedge.online/"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	
	CreateConVar("sm_force_custom_files_version", PLUGIN_VERSION, "Force Custom Files Version: Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_force_custom_files_enable", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hRate = CreateConVar("sm_force_custom_files_rate", "1.0", "How often the query runs to check client cvar values.", FCVAR_NONE, true, 1.0);
	HookConVarChange(g_hRate, OnSettingsChange);
	AutoExecConfig(true, "sm_force_custom_files");
	
	AddCommandListener(Command_Join, "jointeam");
	AddCommandListener(Command_Join, "joinclass");
	
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_fRate = GetConVarFloat(g_hRate);
}

public OnConfigsExecuted()
{
	if (g_bEnabled)
	{	
		if (g_bLateLoad)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_hTimer_Query[i] = CreateTimer(g_fRate, Timer_QueryClient, i);
				}
			}
			
			g_bLateLoad = false;
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if (g_bEnabled)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
			g_hTimer_Query[client] = CreateTimer(g_fRate, Timer_QueryClient, client);
	}
}

public OnClientDisconnect(client)
{
	if (g_bEnabled)
	{
		g_iTeam[client] = 0;
		g_bLoaded[client] = false;
		g_bDisabled[client] = false;
		
		if (g_hTimer_Notify[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Notify[client]))
			g_hTimer_Notify[client] = INVALID_HANDLE;
		if (g_hTimer_Query[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Query[client]))
			g_hTimer_Query[client] = INVALID_HANDLE;
	}
}

public Action:Command_Join(client, const String:command[], argc)
{
	if (client > 0 && IsClientInGame(client))
	{
		if (g_bDisabled[client])
			return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:Timer_QueryClient(Handle:timer, any:client)
{
	g_hTimer_Query[client] = INVALID_HANDLE;
	if (IsClientInGame(client))
    {
		QueryClientConVar(client, "cl_resend_timeout", ConVar_QueryClient);
        QueryClientConVar(client, "cl_timeout", ConVar_QueryClient);
	}
	return Plugin_Continue;
}

public ConVar_QueryClient(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (g_bEnabled && IsClientInGame(client))
	{
		if (result == ConVarQuery_Okay)
		{
			bool varDisabled = true;
			if (StrEqual(cvarValue, "420", false))
			{
				varDisabled = false;
			}
			
			g_bDisabled[client] = varDisabled;
			if (varDisabled != false)
			{
				KickClient(client, "CONSOLE: exec xlife_setup.cfg and retry");
			}
		}
		
		g_hTimer_Query[client] = CreateTimer(g_fRate, Timer_QueryClient, client);
	}
}


public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if (cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if (cvar == g_hRate)
		g_fRate = StringToFloat(newvalue);
} 
