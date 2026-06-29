#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_PREFIX "\x04[ConVar Suppression]\x03 "
#define PLUGIN_VERSION "1.0"

new Handle:g_hGlobalTrie = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "ConVar Suppression",	/* https://www.youtube.com/watch?v=ZhjtChtUmBE&hd=1 */
	author = "Kyle Sanderson",
	description = "Atleast we have candy.",
	version = PLUGIN_VERSION,
	url = "http://www.SourceMod.net/"
};

public OnPluginStart()
{
	g_hGlobalTrie = CreateTrie();
	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);
	RegAdminCmd("sm_suppressconvar", OnSupressConVar, ADMFLAG_ROOT, "Supress a ConVar from displaying changes to Clients.");
	
	CreateConVar("sm_convarsuppression_version", PLUGIN_VERSION, "Version string for ConVar Supression.", FCVAR_REPLICATED|FCVAR_DONTRECORD|FCVAR_NOTIFY);
}

public Action:OnSupressConVar(client, argc)
{
	if (client && !IsClientInGame(client)) /* Isn't needed, but makes me feel safe inside. */
	{
		return Plugin_Handled;
	}
	
	decl String:sCommand[256];
	
	if (argc < 2)
	{
		if (!GetCmdArg(0, sCommand, sizeof(sCommand)))
		{
			return Plugin_Handled;
		}

		ReplyToCommand(client, "%s%s <convar> <enabled|disabled>", PLUGIN_PREFIX, sCommand);
		return Plugin_Handled;
	}
	
	if (!GetCmdArg(2, sCommand, sizeof(sCommand)))
	{
		return Plugin_Handled;
	}
	
	TrimString(sCommand);
	new iValue = -1;
	
	if (!IsCharNumeric(sCommand[0]))
	{
		switch (CharToLower(sCommand[0]))
		{
			case 'd':
			{
				iValue = 0;
			}
			
			case 'e':
			{
				iValue = 1;
			}
		}
	}
	else
	{
		iValue = StringToInt(sCommand);
	}
	
	if (!GetCmdArg(1, sCommand, sizeof(sCommand)))
	{
		return Plugin_Handled;
	}
	
	switch (iValue)
	{
		case 0:
		{
			RemoveFromTrie(g_hGlobalTrie, sCommand);
			if (client)
			{
				ReplyToCommand(client, "%sRemoved ConVar: %s", PLUGIN_PREFIX, sCommand);
			}
		}
		
		case 1:
		{
			SetTrieValue(g_hGlobalTrie, sCommand, 1, true);
			if (client)
			{
				ReplyToCommand(client, "%sAdded Hook for ConVar: %s", PLUGIN_PREFIX, sCommand);
			}
		}
		
		default:
		{
			ReplyToCommand(client, "%sIllegal Input for Enabled/Disabled with ConVar: %s", PLUGIN_PREFIX, sCommand);
		}
	}
	
	return Plugin_Handled;
}

public Action:Event_ServerCvar(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:sConVarName[64];
	new iValue;
	
	GetEventString(event, "cvarname", sConVarName, sizeof(sConVarName));
	return (GetTrieValue(g_hGlobalTrie, sConVarName, iValue) && iValue) ? Plugin_Handled : Plugin_Continue;
}