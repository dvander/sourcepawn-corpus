//Plugin that removes time limit on your game

#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <updater>


//Don't touch tihs (Plugin information)
#define PLUGIN_NAME "No timelimit for round (not server)"
#define PLUGIN_AUTH "ElPapuh/NetWorld/JLovers"
#define PLUGIN_DESC "A plugin that removes time limit on your game, not the server, if you want to remove time limit on your server, type mp_timelimit 0"
#define PLUGIN_VERS "2.0"
#define PLUGIN_WURL "https://networldftp.000webhostapp.com/" //BEING BUILT
#define PLUGIN_UPDA "https://networldftp.000webhostapp.com/sources/NoTimeLimit.txt"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version = PLUGIN_VERS,
	url = PLUGIN_WURL
};

new Handle:g_DisplayAnnounce;
new Handle:g_PublicTimer;

stock CheckGameType()
{
	new String:sGameType[16];
	GetGameFolderName(sGameType, sizeof(sGameType));
	new bool:IsTeamFortress = StrEqual(sGameType, "tf", true);
	
	if(!IsTeamFortress)
	{
		SetFailState("[ERROR]: No time limit plugin is a Team Fortress 2 plugin only.");
	}
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(PLUGIN_UPDA);
    }
}

public OnPluginStart()
{	
	CreateConVar("ntm_ver", PLUGIN_VERS, _, FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	RegConsoleCmd("ntm_ver", NoTimeLimit_ShowVersion, "Show the version of NoTimeLimit plugin");
	RegAdminCmd("ntm_on", NoTimeLimit_Enable, ADMFLAG_ROOT, "Remove the time limit if the plugin doesn't do by itself | Admin flag: Root");
	RegAdminCmd("ntm_off", NoTimeLimit_Disable, ADMFLAG_ROOT, "Enable the time limit | Admin flag: Root");
	RegAdminCmd("ntm_set", NoTimeLimit_SetTime, ADMFLAG_ROOT, "Set the time limit for round");
	
	g_DisplayAnnounce = CreateConVar("ntm_announce", "1", "Sets if yes or not the plugin will announce the server is using it, to a player who changes team", _, true, 0.0, true, 1.0);
	g_PublicTimer = CreateConVar("ntm_public", "1", "Displays a public message when the plugin disables the timer or re enables it", _, true, 0.0, true, 1.0);
	
	HookEvent("player_team", PlayerChangeTeam);
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("teamplay_point_captured", OnPointCaptured);
	
	if (LibraryExists("updater"))
    {
        Updater_AddPlugin(PLUGIN_UPDA);
    }
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	decl String:mapName[32];
	GetCurrentMap(mapName, sizeof(mapName));

	if (strncmp(mapName, "pl_", 3) == 0)
	{
		CreateTimer(103.0, Timer_Payload);
		PrintToServer("Map game mode payload detected, waiting to setup end to remove time limit");
	} 
	else
	{
		
		new entityTimer = FindEntityByClassname(-1, "team_round_timer");
		if (entityTimer > -1)
		{
			SetVariantInt(StringToInt("0"));
			AcceptEntityInput(entityTimer, "SetTime");
		}
		else
		{
			new Handle:timelimit = FindConVar("mp_timelimit");
			SetConVarFloat(timelimit, StringToFloat("0") / 60);
			CloseHandle(timelimit);
		}
		PrintToServer("[NTM] Round started, timer disabled, if you want to enable it, use /ntm_off");
		
		if(GetConVarFloat(g_PublicTimer) == 1)
		{
			if( GetClientCount() != 0)
			{
				CPrintToChatAll("{cyan}[ {gray}NTM {cyan}] {red}ALERT: {orange}Round timer disabled");
			}
			else
			{
				PrintToServer("Round timer enabled");
			}
		}
	}
}

public Action OnPointCaptured(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(5.0, PointCaptured);
}

public Action PointCaptured(Handle:timer)
{
	new entityTimer = FindEntityByClassname(-1, "team_round_timer");
	if (entityTimer > -1)
	{
		SetVariantInt(StringToInt("0"));
		AcceptEntityInput(entityTimer, "SetTime");
	}
	else
	{
		new Handle:timelimit = FindConVar("mp_timelimit");
		SetConVarFloat(timelimit, StringToFloat("0") / 60);
		CloseHandle(timelimit);
	}
	PrintToServer("[NTM] Point capture detected, disabling timer again");
}

public Action Timer_Payload(Handle:timer)
{
	new entityTimer = FindEntityByClassname(-1, "team_round_timer");
	if (entityTimer > -1)
	{
		SetVariantInt(StringToInt("0"));
		AcceptEntityInput(entityTimer, "SetTime");
	}
	else
	{
		new Handle:timelimit = FindConVar("mp_timelimit");
		SetConVarFloat(timelimit, StringToFloat("0") / 60);
		CloseHandle(timelimit);
	}
	PrintToServer("[NTM] Round started, timer disabled, if you want to enable it, use /ntm_off");
	
	if(GetConVarFloat(g_PublicTimer) == 1)
	{
		if( GetClientCount() != 0)
		{
			CPrintToChatAll("{cyan}[ {gray}NTM {cyan}] {red}ALERT: {orange}Round timer disabled");
		}
		else
		{
			PrintToServer("Round timer enabled");
		}
	}
}

public Action NoTimeLimit_ShowVersion(client, args)
{
	if(args != 0)
	{
		ReplyToCommand(client, "[NTM|Error] Command usage: /ntm_ver");
	} else
	
	PrintToChat(client, "No timelimit plugin version is %s", PLUGIN_VERS);
	
}

public Action NoTimeLimit_Enable(client, args)
{
	if(args != 0 && !IsFakeClient(client) && IsClientInGame(client))
	{
		if(IsClientInGame(client) && client != 0)
		{
			ReplyToCommand(client, "[NTM|Error] Command usage: /ntm_off");
		}
		if(!IsClientInGame(client) && client != 0)
		{
			return Plugin_Changed;
		}
		if(!IsClientInGame(client) && client == 0)
		{
			PrintToServer("[NTM|Error] Command usage: /ntm_off");
		}
	}
	if(args == 0 && !IsFakeClient(client) && IsClientInGame(client))
	{
		new entityTimer = FindEntityByClassname(-1, "team_round_timer");
		if (entityTimer > -1)
		{
			SetVariantInt(StringToInt("0"));
			AcceptEntityInput(entityTimer, "SetTime");
		}
		else
		{
			new Handle:timelimit = FindConVar("mp_timelimit");
			SetConVarFloat(timelimit, StringToFloat("0") / 60);
			CloseHandle(timelimit);
		}
		
		if(client != 0)
		{
			CPrintToChat(client, "{cyan}[ {gray}NTM {cyan}] {orange}Time limit removed, if you want to re enable it, use {red}/ntm_off");
		}
		else
		{
			PrintToServer("[NTM] Time limit removed, if you want to re enable it, use /ntm_off");
		}
	}
	if(GetConVarFloat(g_PublicTimer) == 1)
	{
		if( GetClientCount() != 0)
		{
			CPrintToChatAll("{cyan}[ {gray}NTM {cyan}] {red}ALERT: {orange}Round timer disabled");
		}
		else
		{
			PrintToServer("Round timer enabled");
		}
	}
	return Plugin_Handled;
}

public Action NoTimeLimit_Disable(client, args)
{
	if(args != 0 && !IsFakeClient(client) && IsClientInGame(client))
	{
		if(IsClientInGame(client) && client != 0)
		{
			ReplyToCommand(client, "[NTM|Error] Command usage: /ntm_off");
		}
		if(!IsClientInGame(client) && client != 0)
		{
			return Plugin_Changed;
		}
		if(!IsClientInGame(client) && client == 0)
		{
			PrintToServer("[NTM|Error] Command usage: /ntm_off");
		}
	}
	if(args == 0 && !IsFakeClient(client) && IsClientInGame(client))
	{
		new entityTimer = FindEntityByClassname(-1, "team_round_timer");
		if (entityTimer > -1)
		{
			SetVariantInt(StringToInt("450"));
			AcceptEntityInput(entityTimer, "SetTime");
		}
		else
		{
			new Handle:timelimit = FindConVar("mp_timelimit");
			SetConVarFloat(timelimit, StringToFloat("450") / 60);
			CloseHandle(timelimit);
		}
		
		if(client != 0)
		{
			CPrintToChat(client, "{cyan}[ {gray}NTM {cyan}] {orange}Time limit restored, if you want to disable it, use {red}/ntm_on");
		}
		else
		{
			PrintToServer("[NTM] Time limit restored, if you want to disable it, use /ntm_on");
		}
	}
	if(GetConVarFloat(g_PublicTimer) == 1)
	{
		if( GetClientCount() != 0)
		{
			CPrintToChatAll("{cyan}[ {gray}NTM {cyan}] {red}ALERT: {orange}Round timer enabled");
			PrintToServer("Round timer disabled");
		}
		else
		{
			PrintToServer("Round timer disabled");
		}
	}
	return Plugin_Handled;
}

public Action NoTimeLimit_SetTime(client, args)
{
	decl String:settimeval[32];
	GetCmdArg(1, settimeval, sizeof(settimeval));
	
	if(args == 0 && !IsFakeClient(client) && IsClientInGame(client))
	{
		if(IsClientInGame(client) && client != 0)
		{
			ReplyToCommand(client, "[NTM|Error] Command usage: /ntm_set <value>");
		}
		if(!IsClientInGame(client) && client != 0)
		{
			return Plugin_Changed;
		}
		if(!IsClientInGame(client) && client == 0)
		{
			PrintToServer("[NTM|Error] Command usage: /ntm_set <value>");
		}
	}
	if(args != 0 && !IsFakeClient(client) && IsClientInGame(client))
	{
	
		new entityTimer = FindEntityByClassname(-1, "team_round_timer");
		if (entityTimer > -1)
		{
			SetVariantInt(StringToInt(settimeval));
			AcceptEntityInput(entityTimer, "SetTime");
		}
		else
		{
			new Handle:timelimit = FindConVar("mp_timelimit");
			SetConVarFloat(timelimit, StringToFloat(settimeval) / 60);
			CloseHandle(timelimit);
		}
		
		if(client != 0)
		{
			CPrintToChat(client, "{cyan}[ {gray}NTM {cyan}] {orange}Time limit set to %s", settimeval);
		}
		else
		{
			PrintToServer("[NTM] %s Set the round timer to %s", client, settimeval);
		}
	}
	if(GetConVarFloat(g_PublicTimer) == 1)
	{
		if( GetClientCount() != 0)
		{
			CPrintToChatAll("{cyan}[ {gray}NTM {cyan}] {red}ALERT: {orange}Round timer set to %s", settimeval);
			PrintToServer("Round timer set to %s", settimeval);
		}
		else
		{
			PrintToServer("Round timer set to %s", settimeval);
		}
	}
	return Plugin_Handled;
}

public Action PlayerChangeTeam(Event event, const char[] name, bool dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				if(GetConVarFloat(g_DisplayAnnounce) == 1)
				{
					CPrintToChat(i, "{cyan}[ {gray}NTM {cyan}] {orange}Server using no time limit plugin by {red}ElPapuh");
				}
				if(GetConVarFloat(g_DisplayAnnounce) != 1)
				{
					return Plugin_Continue;
				}
			}
			if(IsClientInGame(i) && IsFakeClient(i))
			{
				return Plugin_Continue;
			}
			if(!IsClientInGame(i))
			{
				return Plugin_Changed;
			}
		}
	return Plugin_Continue;
}