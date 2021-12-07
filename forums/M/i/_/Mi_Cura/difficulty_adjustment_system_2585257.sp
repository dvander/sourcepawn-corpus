/***The Difficulty Adjustment System***/
#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "10.0"

bool bAdvanced;
bool bEasy;
bool bExpert;
bool bNormal;
bool bTimerOn;

char sGameModes[64];
char sGameName[32];
char sModeName[32];

ConVar cvAdvanced;
ConVar cvAnnounceDifficulty;
ConVar cvDifficulty;
ConVar cvEasy;
ConVar cvEnablePlugin;
ConVar cvExpert;
ConVar cvNormal;

Handle hDisabledGameModes;
Handle hEnabledGameModes;

public Plugin myinfo =
{
	name = "Difficulty Adjustment System",
	author = "Psykotik (Crasher_3637)",
	description = "Adjusts difficulty based on the number of clients on the server.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=303117"
};

public void OnPluginStart()
{
	GetGameFolderName(sGameName, sizeof(sGameName));
	if (!StrEqual(sGameName, "left4dead2", false) && !StrEqual(sGameName, "left4dead", false))
	{
		SetFailState("The Difficulty Adjustment System supports Left 4 Dead and Left 4 Dead 2 only.");
	}

	cvDifficulty = FindConVar("z_difficulty");
	cvAnnounceDifficulty = CreateConVar("das_announcedifficulty", "1", "Announce the difficulty when it is changed?\n(0: OFF)\n(1: ON)");
	hDisabledGameModes = CreateConVar("das_disabledgamemodes", "versus,realismversus,survival,scavenge", "Disable the plugin in these game modes.\n(Empty: None)\n(Not empty: Disabled in these game modes, separated by commas with no spaces.)");
	hEnabledGameModes = CreateConVar("das_enabledgamemodes", "coop,realism,mutation1,mutation12", "Enable the plugin in these game modes.\n(Empty: All)\n(Not empty: Enabled in these game modes, separated by commas with no spaces.)");
	cvEnablePlugin = CreateConVar("das_enableplugin", "1", "Enable the Difficulty Adjustment System?\n(0: OFF)\n(1: ON)");
	cvEasy = CreateConVar("das_easydifficulty", "1", "Minimum players required for Easy.");
	cvNormal = CreateConVar("das_normaldifficulty", "2", "Minimum players required for Normal.");
	cvAdvanced = CreateConVar("das_advanceddifficulty", "3", "Minimum players required for Advanced.");
	cvExpert = CreateConVar("das_expertdifficulty", "4", "Minimum players required for Expert.");
	CreateConVar("das_pluginversion", PLUGIN_VERSION, "[L4D & L4D2] Difficulty Adjustment System version", FCVAR_NOTIFY);
	HookEvent("round_start", vStartTimer);
	HookEvent("round_end", vStopTimer);
	HookEvent("finale_win", vStopTimer);
	HookEvent("mission_lost", vStopTimer);
	HookEvent("map_transition", vStopTimer);
	AutoExecConfig(true, "difficulty_adjustment_system");
}

public void OnMapStart()
{
	bEasy = false;
	bNormal = false;
	bAdvanced = false;
	bExpert = false;
}

public void OnMapEnd()
{
	bEasy = false;
	bNormal = false;
	bAdvanced = false;
	bExpert = false;
}

public void vStartTimer(Event event, const char[] name, bool dontBroadcast)
{
	if (cvEnablePlugin.BoolValue && bIsSystemValid())
	{
		bTimerOn = true;
		CreateTimer(1.0, tUpdatePlayerCount, _, TIMER_REPEAT);
	}
}

public void vStopTimer(Event event, const char[] name, bool dontBroadcast)
{
	if (bTimerOn)
	{
		bTimerOn = false;
	}
}

public Action tUpdatePlayerCount(Handle timer)
{
	if (!bTimerOn || !cvEnablePlugin.BoolValue || !bIsSystemValid())
	{
		return Plugin_Stop;
	}

	int iEasy = cvEasy.IntValue;
	int iNormal = cvNormal.IntValue;
	int iAdvanced = cvAdvanced.IntValue;
	int iExpert = cvExpert.IntValue;
	int iPlayerCount = iGetPlayerCount();
	if (!bEasy && ((iPlayerCount == iEasy && iPlayerCount < iNormal && iPlayerCount < iAdvanced && iPlayerCount < iExpert) || (iPlayerCount == iEasy && iEasy > iNormal && iEasy > iAdvanced && iEasy > iExpert)))
	{
		cvDifficulty.SetString("easy");
		bEasy = true;
		bNormal = false;
		bAdvanced = false;
		bExpert = false;
		if (bEasy && cvAnnounceDifficulty.BoolValue)
		{
			PrintToChatAll("\x04[DAS]\x01 Difficulty changed to\x03 Easy\x01.");
		}
	}

	else if (!bNormal && ((iPlayerCount == iNormal && iPlayerCount > iEasy && iPlayerCount < iAdvanced && iPlayerCount < iExpert) || (iPlayerCount == iNormal && iNormal > iEasy && iNormal > iAdvanced && iNormal > iExpert)))
	{
		cvDifficulty.SetString("normal");
		bEasy = false;
		bNormal = true;
		bAdvanced = false;
		bExpert = false;
		if (bNormal && cvAnnounceDifficulty.BoolValue)
		{
			PrintToChatAll("\x04[DAS]\x01 Difficulty changed to\x03 Normal\x01.");
		}
	}

	else if (!bAdvanced && ((iPlayerCount == iAdvanced && iPlayerCount > iEasy && iPlayerCount > iNormal && iPlayerCount < iExpert) || (iPlayerCount == iAdvanced && iAdvanced > iEasy && iAdvanced > iNormal && iAdvanced > iExpert)))
	{
		cvDifficulty.SetString("hard");
		bEasy = false;
		bNormal = false;
		bAdvanced = true;
		bExpert = false;
		if (bAdvanced && cvAnnounceDifficulty.BoolValue)
		{
			PrintToChatAll("\x04[DAS]\x01 Difficulty changed to\x03 Advanced\x01.");
		}
	}

	else if (!bExpert && ((iPlayerCount == iExpert && iPlayerCount > iEasy && iPlayerCount > iNormal && iPlayerCount > iAdvanced) || (iPlayerCount == iExpert && iExpert > iEasy && iExpert > iNormal && iExpert > iAdvanced)))
	{
		cvDifficulty.SetString("impossible");
		bEasy = false;
		bNormal = false;
		bAdvanced = false;
		bExpert = true;
		if (bExpert && cvAnnounceDifficulty.BoolValue)
		{
			PrintToChatAll("\x04[DAS]\x01 Difficulty changed to\x03 Expert\x01.");
		}
	}

	return Plugin_Continue;
}

int iGetPlayerCount()
{
	int iPlayerCount = 0;
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (bIsHumanSurvivor(iPlayer))
		{
			iPlayerCount += 1;
		}
	}

	return iPlayerCount;
}

bool bHasIdlePlayer(int client)
{
	int iIdler = GetClientOfUserId(GetEntData(client, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID")));
	if (iIdler)
	{
		if (IsClientInGame(iIdler) && !IsFakeClient(iIdler) && (GetClientTeam(iIdler) != 2))
		{
			return true;
		}
	}

	return false;
}

bool bIsHumanSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !IsClientInKickQueue(client) && !IsFakeClient(client) && !bHasIdlePlayer(client) && !bIsPlayerIdle(client));
}

bool bIsPlayerIdle(int client)
{
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (!IsClientConnected(iPlayer) || !IsClientInGame(iPlayer) || GetClientTeam(iPlayer) != 2 || !IsFakeClient(iPlayer) || !bHasIdlePlayer(iPlayer))
		{
			continue;
		}

		int iIdler = GetClientOfUserId(GetEntData(iPlayer, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID")));
		if (iIdler == client)
		{
			return true;
		}
	}

	return false;
}

bool bIsSystemValid()
{
	GetConVarString(FindConVar("mp_gamemode"), sModeName, sizeof(sModeName));
	Format(sModeName, sizeof(sModeName), ",%s,", sModeName);
	GetConVarString(hEnabledGameModes, sGameModes, sizeof(sGameModes));
	if (strcmp(sGameModes, ""))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sModeName, false) == -1)
		{
			return false;
		}
	}

	GetConVarString(hDisabledGameModes, sGameModes, sizeof(sGameModes));
	if (strcmp(sGameModes, ""))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sModeName, false) != -1)
		{
			return false;
		}
	}

	return true;
}