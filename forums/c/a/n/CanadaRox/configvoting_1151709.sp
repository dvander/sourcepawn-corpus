#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "L4D2 Config Voter",
	author = "CanadaRox",
	description = "Allows players to vote for which config to use for a versus game.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=123180"
}

new Handle:g_hEnabled;

new Handle:g_hVoteMenu = INVALID_HANDLE;

new bool:g_bEnabled = true;

new bool:g_bIsFirstPlayer = true;

public OnPluginStart()
{
	decl String: sGame[64];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		SetFailState("Use this in Left 4 Dead 2 only.");
	}
	
	g_hEnabled = CreateConVar("l4d2_cfgvote_enable", "1", "Enables the L4D2 Config Voter plugin");
	HookConVarChange(g_hEnabled, ConVarChange_Enable);
	
	HookEvent("player_disconnect", PlayerDisconnect_Event);
}

public ConVarChange_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled = GetConVarBool(g_hEnabled);
}

public OnClientPostAdminCheck(client)
{
	if (!g_bEnabled) return;
	if (!g_bIsFirstPlayer) return;
	if (!IsVersus()) return;
	g_bIsFirstPlayer = false;
	
	CreateTimer(30.0, VoteDelay);
}

public Action:PlayerDisconnect_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsHumanOnServer()) return;
	g_bIsFirstPlayer = true;
}

public Action:VoteDelay(Handle:timer)
{
	if (IsVoteInProgress()) return Plugin_Stop;
	
	g_hVoteMenu = CreateMenu(Handle_VoteMenu);
	
	SetMenuTitle(g_hVoteMenu, "Change server config to:");
	AddMenuItem(g_hVoteMenu, "vanilla", "Vanilla L4D2");
	AddMenuItem(g_hVoteMenu, "cevo", "CEVO");
	AddMenuItem(g_hVoteMenu, "confogl", "Confogl");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 30);
	
	return Plugin_Stop;
}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_VoteEnd)
	{
		switch (param1)
		{
			case 0:
			{
				ExecConfig("cevo_off.cfg");
				ServerCommand("sm_restartmap");
			}
			case 1:
			{
				ExecConfig("cevo_versus.cfg");
			}
			case 2:
			{
				ServerCommand("sm_forcematch");
			}
		}
	}
}

public ExecConfig (const String:sFileName[])
{
	decl String:sFilePath[1024];
	BuildPath(Path_SM, sFilePath, 1024, "../../cfg/%s", sFileName);
	
	if(FileExists(sFilePath)) ServerCommand("exec %s", sFileName);
	else PrintToChatAll("[Voter] Error: sFileName could not be found.");
}

bool:IsVersus()
{
	decl String:GameMode[32];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	if(StrContains(GameMode, "versus", false) != -1)
	{
		return true;
	}
	return false;
}

bool:IsHumanOnServer()
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientConnected(i) && !IsFakeClient(i))
		{
			return true;
		}
	}
	return false;
}