#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.1"

public Plugin myinfo =
{
	name = "Advanced and silent CVAR change.",
	author = "Axel Juan Nieves",
	description = "Alternate sm_cvar. Allows you to change a cvar value without printing any result to chat. Opcionaly, you can print result to console or server; and/or add a delay.",
	version = PLUGIN_VERSION,
	url = ""
};

Handle sm_acvar_server_always;

public void OnPluginStart()
{
	CreateConVar("sm_acvar_version", PLUGIN_VERSION, "Silent cvar version", FCVAR_NOTIFY);
	sm_acvar_server_always = CreateConVar("sm_acvar_server_always", "1", "Print always result to server console when using sm_acvar and sm_adcvar?", 0);
	RegAdminCmd("sm_acvar", ACvar, ADMFLAG_RCON, "Changes a cvar value without printing result to chat.");
	RegAdminCmd("sm_acvar_console", ACvar, ADMFLAG_RCON, "Changes a cvar value printing result to admin's console.");
	RegAdminCmd("sm_acvar_server", ACvar, ADMFLAG_RCON, "Changes a cvar value printing result to server console.");
	RegAdminCmd("sm_adcvar", ADCvar, ADMFLAG_RCON, "Changes a cvar value without printing result to chat, and adds a delay before performed.");
	RegAdminCmd("sm_adcvar_console", ADCvar, ADMFLAG_RCON, "Changes a cvar value printing result to admin's console, and adds a delay before performed.");
	RegAdminCmd("sm_adcvar_server", ADCvar, ADMFLAG_RCON, "Changes a cvar value printing result to server console, and adds a delay before performed..");
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
		PrintToConsole(client, "[SM_ACVAR] Error: ConVar '%s' not found. Usage: %s convarName \"Convar value\"", strCvarName, strCallerCmd);
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
		PrintToConsole(client, "[SM_ACVAR] '%s' changed to: %s", strCvarName, strValue);
	
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
			PrintToConsole(client, "[SM_ACVAR] '%s' changed to: %s", strCvarName, strValue);
		
		return Plugin_Continue;
	}
	
	//timed exec
	if ( GetConVarInt(sm_acvar_server_always) || StrEqual(strCallerCmd, "sm_adcvar_server", false) )
		PrintToServer("[SM_ACVAR] '%s' will be changed after %f's", strCvarName, fDelay);
	else if ( StrEqual(strCallerCmd, "sm_adcvar_console", false) )
		PrintToConsole(client, "[SM_ACVAR] '%s' will be changed after %f's", strCvarName, fDelay);
	
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
	
	pack.Reset();
	client = pack.ReadCell();
	pack.ReadString(strCallerCmd, sizeof(strCallerCmd));
	pack.ReadString(strCvarName, sizeof(strCvarName));
	pack.ReadString(strValue, sizeof(strValue));
	
	hConvar = FindConVar(strCvarName);
	if (hConvar == INVALID_HANDLE)
	{
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
		PrintToConsole(client, "[SM_ACVAR] '%s' changed to: %s", strCvarName, strValue);
	
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