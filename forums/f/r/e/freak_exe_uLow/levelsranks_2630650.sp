/***************************************************************************
****
****		Date of creation :		November 27, 2014
****		Date of official release :	April 12, 2015
****		Last update :			December 9, 2018
****
***************************************************************************/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define EngineGameCSGO 0
#define EngineGameCSS 1

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

#pragma newdecls required
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo"
#define PLUGIN_SITE "http://hlmod.ru/resources/levels-ranks-core.177/"

#define LogLR(%0) LogError("[" ... PLUGIN_NAME ... " Core] " ... %0)
#define CrashLR(%0) SetFailState("[" ... PLUGIN_NAME ... " Core] " ... %0)
#define MenuLR(%0) public int %0(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
#define DBCallbackLR(%0) public void %0(Database db, DBResultSet dbRs, const char[] sError, any iClient)

int			g_iEngineGame,
			g_iClientSessionData[MAXPLAYERS+1][10],
			g_iExp[MAXPLAYERS+1],
			g_iRank[MAXPLAYERS+1],
			g_iKills[MAXPLAYERS+1],
			g_iDeaths[MAXPLAYERS+1],
			g_iShoots[MAXPLAYERS+1],
			g_iHits[MAXPLAYERS+1],
			g_iHeadshots[MAXPLAYERS+1],
			g_iAssists[MAXPLAYERS+1],
			g_iRoundWinStats[MAXPLAYERS+1],
			g_iRoundLoseStats[MAXPLAYERS+1],
			g_iPlayTime[MAXPLAYERS+1],
			g_iKillstreak[MAXPLAYERS+1],
			g_iCountRetryConnect,
			g_iDBCountPlayers,
			g_iDBRankPlayer[MAXPLAYERS+1],
			g_iCountPlayers;
float			g_fCoefficient[MAXPLAYERS+1];
bool			g_bHaveBomb[MAXPLAYERS+1],
			g_bDatabaseSQLite,
			g_bRoundWithoutExp;
Handle		g_hTimerGiver,
			g_hForward_OnSettingsModuleUpdate,
			g_hForward_OnDatabaseLoaded,
			g_hForward_OnMenuCreated,
			g_hForward_OnMenuItemSelected,
			g_hForward_OnLevelChanged;

#include "levels_ranks/settings.sp"
#include "levels_ranks/database.sp"
#include "levels_ranks/custom_functions.sp"
#include "levels_ranks/menus.sp"
#include "levels_ranks/hooks.sp"
#include "levels_ranks/natives.sp"

public Plugin myinfo = {name = "[LR] Core", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION, url = PLUGIN_SITE}
public void OnPluginStart()
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO: g_iEngineGame = EngineGameCSGO;
		case Engine_CSS: g_iEngineGame = EngineGameCSS;
		default: CrashLR("This plugin works only on CS:GO and CS:Source");
	}

	g_hForward_OnSettingsModuleUpdate = CreateGlobalForward("LR_OnSettingsModuleUpdate", ET_Ignore);
	g_hForward_OnDatabaseLoaded = CreateGlobalForward("LR_OnDatabaseLoaded", ET_Ignore);
	g_hForward_OnMenuCreated = CreateGlobalForward("LR_OnMenuCreated", ET_Ignore, Param_Cell, Param_CellByRef);
	g_hForward_OnMenuItemSelected = CreateGlobalForward("LR_OnMenuItemSelected", ET_Ignore, Param_Cell, Param_String);
	g_hForward_OnLevelChanged = CreateGlobalForward("LR_OnLevelChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	LoadTranslations("levels_ranks_core.phrases");
	RegAdminCmd("sm_lvl_reload", ResetSettings, ADMFLAG_ROOT);
	RegAdminCmd("sm_lvl_reset", ResetStatsFull, ADMFLAG_ROOT);
	RegAdminCmd("sm_lvl_del", ResetStatsPlayer, ADMFLAG_ROOT);
	RegConsoleCmd("sm_lvl", CallMainMenu);
	g_hTimerGiver = CreateTimer(1.0, PlayTimeCounter, _, TIMER_REPEAT);

	SetSettings(false);
	MakeHooks();
	ConnectDB();
}

public void OnMapEnd()
{
	if(g_iDaysDeleteFromBase > 0)
	{
		PurgeDatabase();
	}

	if(g_iDaysDeleteFromBaseCalib > 0)
	{
		PurgeDatabaseCalibration();
	}
}

public void OnClientPutInServer(int iClient)
{
	if(IsClientAuthorized(iClient))
	{
		LoadDataPlayer(iClient);
	}
}

public void OnClientAuthorized(int iClient)
{
	if(IsClientInGame(iClient))
	{
		LoadDataPlayer(iClient);
	}
}

public void OnClientDisconnect(int iClient)
{
	for(int i = 0; i < 10; i++)
	{
		g_iClientSessionData[iClient][i] = 0;
	}

	g_iKillstreak[iClient] = 0;
	g_fCoefficient[iClient] = 0.0;
	g_bInitialized[iClient] = false;
}

public void OnPluginEnd()
{
	if(g_hTimerGiver != null)
	{
		KillTimer(g_hTimerGiver);
		g_hTimerGiver = null;
	}

	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			OnClientDisconnect(iClient);	
		}
	}
}