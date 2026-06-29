#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.1.1 Beta 1"

public Plugin myinfo =
{
	name = "Advanced and silent CVAR change.",
	author = "Axel Juan Nieves",
	description = "Alternate sm_cvar. Allows you to change a cvar value without printing any result to chat. Opcionaly, you can print result to console or server; and/or add a delay.",
	version = PLUGIN_VERSION,
	url = ""
};

ConVar sm_acvar_server_always;
ConVar sm_acvar_override_flags;
int g_iForceOverride = false;

#define FLAG_OVERRIDE_ONMAPSTART		1
#define FLAG_OVERRIDE_ONMAPEND			2
#define FLAG_OVERRIDE_ROUND_START		4
#define FLAG_OVERRIDE_ROUND_END			8
#define FLAG_OVERRIDE_MISSION_LOST		16
#define FLAG_OVERRIDE_MAP_TRANSITION	32

public void OnPluginStart()
{
	CreateConVar("sm_acvar_version", PLUGIN_VERSION, "Silent cvar version", FCVAR_NOTIFY);
	sm_acvar_server_always = CreateConVar("sm_acvar_server_always", "1", "Print always result to server console when using sm_acvar and sm_adcvar?", 0);
	sm_acvar_override_flags = CreateConVar("sm_acvar_override_flags", "0", "0=Dont override, 1=ONMAPSTART, 2=ONMAPEND, 4=ROUND_START, 8=ROUND_END, 16=MISSION_LOST, 32=MAP_TRANSITION", 0);
	RegAdminCmd("sm_acvar", ACvar, ADMFLAG_RCON, "Changes a cvar value without printing result to chat.");
	RegAdminCmd("sm_acvar_console", ACvar, ADMFLAG_RCON, "Changes a cvar value printing result to admin's console.");
	RegAdminCmd("sm_acvar_server", ACvar, ADMFLAG_RCON, "Changes a cvar value printing result to server console.");
	RegAdminCmd("sm_adcvar", ADCvar, ADMFLAG_RCON, "Changes a cvar value without printing result to chat, and adds a delay before performed.");
	RegAdminCmd("sm_adcvar_console", ADCvar, ADMFLAG_RCON, "Changes a cvar value printing result to admin's console, and adds a delay before performed.");
	RegAdminCmd("sm_adcvar_server", ADCvar, ADMFLAG_RCON, "Changes a cvar value printing result to server console, and adds a delay before performed..");
	
	HookEvent("round_start", event_round_start, EventHookMode_Pre);
	HookEvent("round_end", event_round_end, EventHookMode_Pre);
	
	//Left 4 Dead events:
	HookEvent("mission_lost", event_mission_lost, EventHookMode_Pre);
	HookEvent("map_transition", event_map_transition, EventHookMode_Pre);
	
	AutoExecConfig(true, "sm_acvar");
}

public Action ACvar(int client, any args)
{
	char strCallerCmd[32];
	char strCvarName[128];
	char strValue[512];
	Handle hConvar;
	
	GetCmdArg(0, strCallerCmd, sizeof(strCallerCmd));
	GetCmdArg(1, strCvarName, sizeof(strCvarName));
	GetCmdArg(2, strValue, sizeof(strValue));
	
	hConvar = FindConVar(strCvarName);
	if (hConvar == INVALID_HANDLE)
	{
		if ( IsValidClientInGame(client) )
		{
			PrintToConsole(client, "[SM_ACVAR] Error: ConVar '%s' not found. Usage: %s convarName \"Convar value\"", strCvarName, strCallerCmd);
		}
		return Plugin_Continue;
	}	
	
	switch ( changeConvar(hConvar, strCvarName, strValue) )
	{
		case 0:
			return Plugin_Continue;
		case 2:
		{
			GetConVarString(hConvar, strValue, sizeof(strValue));
		}
	}
	
	if ( GetConVarInt(sm_acvar_server_always) || StrEqual(strCallerCmd, "sm_acvar_server", false) )
		PrintToServer("[SM_ACVAR] '%s' changed to: %s", strCvarName, strValue);
	else if ( StrEqual(strCallerCmd, "sm_acvar_console", false) )
	{
		if ( IsValidClientInGame(client) )
			PrintToConsole(client, "[SM_ACVAR] '%s' changed to: %s", strCvarName, strValue);
	}
	
	return Plugin_Continue;
}

public Action ADCvar(int client, any args)
{
	char strCallerCmd[32];
	char strDelay[8];
	char strCvarName[128];
	char strValue[512];
	Handle hConvar;
	
	GetCmdArg(0, strCallerCmd, sizeof(strCallerCmd));
	GetCmdArg(1, strDelay, sizeof(strDelay));
	GetCmdArg(2, strCvarName, sizeof(strCvarName));
	GetCmdArg(3, strValue, sizeof(strValue));
	
	float fDelay = StringToFloat(strDelay);
	
	hConvar = FindConVar(strCvarName);
	if (hConvar == INVALID_HANDLE)
	{
		if ( IsValidClientInGame(client) )
			PrintToConsole(client, "[SM_ACVAR] Error: ConVar '%s' not found. Usage: %s delay convarName \"Convar value\"", strCvarName, strCallerCmd);
		return Plugin_Continue;
	}
	
	//instant exec (delay <= 0.0s)...
	if (fDelay<=0.0)
	{
		switch ( changeConvar(hConvar, strCvarName, strValue) )
		{
			case 0:
				return Plugin_Continue;
			case 2:
			{
				GetConVarString(hConvar, strValue, sizeof(strValue));
			}
		}
		
		if ( GetConVarInt(sm_acvar_server_always) || StrEqual(strCallerCmd, "sm_adcvar_server", false) )
			PrintToServer("[SM_ACVAR] '%s' changed to: %s", strCvarName, strValue);
		else if ( StrEqual(strCallerCmd, "sm_adcvar_console", false) )
		{
			if ( IsValidClientInGame(client) )
				PrintToConsole(client, "[SM_ACVAR] '%s' changed to: %s", strCvarName, strValue);
		}
		
		return Plugin_Continue;
	}
	
	//timed exec
	if ( GetConVarInt(sm_acvar_server_always) || StrEqual(strCallerCmd, "sm_adcvar_server", false) )
		PrintToServer("[SM_ACVAR] '%s' will be changed after %f's", strCvarName, fDelay);
	else if ( StrEqual(strCallerCmd, "sm_adcvar_console", false) )
	{
		if ( IsValidClientInGame(client) )
			PrintToConsole(client, "[SM_ACVAR] '%s' will be changed after %f's", strCvarName, fDelay);
	}
	
	g_iForceOverride = false;
	
	DataPack pack;
	CreateDataTimer(fDelay, ADCvar_post, pack);
	pack.WriteCell(client);
	pack.WriteString(strCallerCmd);
	pack.WriteString(strCvarName);
	pack.WriteString(strValue);
	return Plugin_Continue;
}

public Action ADCvar_post(Handle time, DataPack pack)
{
	Handle hConvar;
	int client;
	char strCallerCmd[32];
	char strCvarName[128];
	char strValue[512];
	
	if ( g_iForceOverride )
	{
		if ( IsValidClientInGame(client) )
			PrintToConsole(client, "[SM_ACVAR] OVERRIDE: ConVar '%s' was not executed due to override flags(%i). Flag: %i", strCvarName, GetConVarInt(sm_acvar_override_flags), g_iForceOverride);
		return Plugin_Continue;
	}
	
	pack.Reset();
	client = pack.ReadCell();
	pack.ReadString(strCallerCmd, sizeof(strCallerCmd));
	pack.ReadString(strCvarName, sizeof(strCvarName));
	pack.ReadString(strValue, sizeof(strValue));
	
	hConvar = FindConVar(strCvarName);
	if (hConvar == INVALID_HANDLE)
	{
		if ( IsValidClientInGame(client) )
			PrintToConsole(client, "[SM_ACVAR] Error: ConVar '%s' was not found after delay.", strCvarName);
		return Plugin_Continue;
	}
	
	switch ( changeConvar(hConvar, strCvarName, strValue) )
	{
		case 0:
			return Plugin_Continue;
		case 2:
		{
			GetConVarString(hConvar, strValue, sizeof(strValue));
		}
	}
	
	if ( GetConVarInt(sm_acvar_server_always) || StrEqual(strCallerCmd, "sm_adcvar_server", false) )
		PrintToServer("[SM_ACVAR] '%s' changed to: %s", strCvarName, strValue);
	else if ( StrEqual(strCallerCmd, "sm_adcvar_console", false) )
	{
		if ( IsValidClientInGame(client) )
			PrintToConsole(client, "[SM_ACVAR] '%s' changed to: %s", strCvarName, strValue);
	}
	
	//PrintToServer("[SM_ACVAR] DEBUG: client(%i), strCallerCmd(%s), strCvarName(%s), strValue(%s)", client, strCallerCmd, strCvarName, strValue);
	
	return Plugin_Continue;
}

stock int changeConvar(Handle hConvar, char[] strCvarName, char[] strValue)
{
	int flags;
	flags = GetCommandFlags(strCvarName);
	SetCommandFlags(strCvarName, 0);
	
	if ( StrContains(strValue, "$$")==0 )
		ReplaceStringEx(strValue, 512, "$$", "$");
	else if ( StrContains(strValue, "$")==0 )
	{
		ReplaceStringEx(strValue, 512, "$", "");
		Handle newCvar = FindConVar(strValue);
		if (newCvar == INVALID_HANDLE)
		{
			PrintToServer("[SM_ACVAR] Error: Pointed ConVar '%s' was not found while trying to setting '%s'.", strValue, strCvarName);
			return 0;
		}
		GetConVarString(newCvar, strValue, 512);
		SetConVarString(hConvar, strValue, true);
		SetCommandFlags(strCvarName, flags);
		return 2;
	}
	
	SetConVarString(hConvar, strValue, true);
	SetCommandFlags(strCvarName, flags);
	return 1;
}

public void OnMapStart()
{
	if ( GetConVarInt(sm_acvar_override_flags) & FLAG_OVERRIDE_ONMAPSTART )
		g_iForceOverride = FLAG_OVERRIDE_ONMAPSTART;
}

public void OnMapEnd()
{
	if ( GetConVarInt(sm_acvar_override_flags) & FLAG_OVERRIDE_ONMAPEND )
		g_iForceOverride = FLAG_OVERRIDE_ONMAPEND;
}

public void event_round_start(Handle event, const char[] name, bool dontBroadcast)
{
	if ( GetConVarInt(sm_acvar_override_flags) & FLAG_OVERRIDE_ROUND_START )
		g_iForceOverride = FLAG_OVERRIDE_ROUND_START;
}

public void event_round_end(Handle event, const char[] name, bool dontBroadcast)
{
	if ( GetConVarInt(sm_acvar_override_flags) & FLAG_OVERRIDE_ROUND_END )
		g_iForceOverride = FLAG_OVERRIDE_ROUND_END;
}

public void event_mission_lost(Handle event, const char[] name, bool dontBroadcast)
{
	if ( GetConVarInt(sm_acvar_override_flags) & FLAG_OVERRIDE_MISSION_LOST )
		g_iForceOverride = FLAG_OVERRIDE_MISSION_LOST;
}

public void event_map_transition(Handle event, const char[] name, bool dontBroadcast)
{
	if ( GetConVarInt(sm_acvar_override_flags) & FLAG_OVERRIDE_MAP_TRANSITION )
		g_iForceOverride = FLAG_OVERRIDE_MAP_TRANSITION;
}

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return 1;
	}
	return 0;
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
}