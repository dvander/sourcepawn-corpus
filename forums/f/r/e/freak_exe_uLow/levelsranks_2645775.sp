/***************************************************************************
****
****		Date of creation :		November 27, 2014
****		Date of official release :	April 12, 2015
****		Last update :			January 24, 2019
****
***************************************************************************/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define EngineGameCSGO 0
#define EngineGameCSS 1
#define EngineGameCSSv34 2

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

int			g_iEngineGame,
			g_iClientRoundExp[MAXPLAYERS+1],
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
char			g_sWeaponClassname[47][192] = {"weapon_knife", "weapon_taser", "weapon_inferno", "weapon_hegrenade", "weapon_glock", "weapon_hkp2000", "weapon_tec9", "weapon_usp_silencer", "weapon_p250", "weapon_cz75a", "weapon_fiveseven", "weapon_elite", "weapon_revolver", "weapon_deagle", "weapon_negev", "weapon_m249", "weapon_mag7", "weapon_sawedoff", "weapon_nova", "weapon_xm1014", "weapon_bizon", "weapon_mac10", "weapon_ump45", "weapon_mp9", "weapon_mp7", "weapon_p90", "weapon_galilar", "weapon_famas", "weapon_ak47", "weapon_m4a1", "weapon_m4a1_silencer", "weapon_aug", "weapon_sg556", "weapon_ssg08", "weapon_awp", "weapon_scar20", "weapon_g3sg1", "weapon_usp", "weapon_p228", "weapon_m3", "weapon_tmp", "weapon_mp5navy", "weapon_galil", "weapon_scout", "weapon_sg550", "weapon_sg552", "weapon_mp5sd"};
bool			g_bHaveBomb[MAXPLAYERS+1],
			g_bDatabaseSQLite,
			g_bRoundEndGiveExp,
			g_bRoundWithoutExp;
Handle		g_hTimerGiver,
			g_hForward_OnCoreIsReady,
			g_hForward_OnSettingsModuleUpdate,
			g_hForward_OnDatabaseLoaded,
			g_hForward_OnMenuCreated,
			g_hForward_OnMenuItemSelected,
			g_hForward_OnMenuCreatedTop,
			g_hForward_OnMenuItemSelectedTop,
			g_hForward_OnMenuCreatedAdmin,
			g_hForward_OnMenuItemSelectedAdmin,
			g_hForward_OnLevelChanged,
			g_hForward_OnPlayerLoaded,
			g_hForward_OnPlayerSaved;

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
		case Engine_SourceSDK2006: g_iEngineGame = EngineGameCSSv34;
		default: CrashLR("This plugin works only on CS:GO, CSS OB and CSS v34");
	}

	g_hForward_OnCoreIsReady = CreateGlobalForward("LR_OnCoreIsReady", ET_Ignore);
	g_hForward_OnSettingsModuleUpdate = CreateGlobalForward("LR_OnSettingsModuleUpdate", ET_Ignore);
	g_hForward_OnDatabaseLoaded = CreateGlobalForward("LR_OnDatabaseLoaded", ET_Ignore);
	g_hForward_OnMenuCreated = CreateGlobalForward("LR_OnMenuCreated", ET_Ignore, Param_Cell, Param_CellByRef);
	g_hForward_OnMenuItemSelected = CreateGlobalForward("LR_OnMenuItemSelected", ET_Ignore, Param_Cell, Param_String);
	g_hForward_OnMenuCreatedTop = CreateGlobalForward("LR_OnMenuCreatedTop", ET_Ignore, Param_Cell, Param_CellByRef);
	g_hForward_OnMenuItemSelectedTop = CreateGlobalForward("LR_OnMenuItemSelectedTop", ET_Ignore, Param_Cell, Param_String);
	g_hForward_OnMenuCreatedAdmin = CreateGlobalForward("LR_OnMenuCreatedAdmin", ET_Ignore, Param_Cell, Param_CellByRef);
	g_hForward_OnMenuItemSelectedAdmin = CreateGlobalForward("LR_OnMenuItemSelectedAdmin", ET_Ignore, Param_Cell, Param_String);
	g_hForward_OnLevelChanged = CreateGlobalForward("LR_OnLevelChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForward_OnPlayerLoaded = CreateGlobalForward("LR_OnPlayerLoaded", ET_Ignore, Param_Cell);
	g_hForward_OnPlayerSaved = CreateGlobalForward("LR_OnPlayerSaved", ET_Ignore, Param_Cell, Param_CellByRef);

	if(g_iEngineGame == EngineGameCSSv34)
	{
		LoadTranslations("levels_ranks_core_old.phrases");
	}
	else LoadTranslations("levels_ranks_core.phrases");

	RegAdminCmd("sm_lvl_reload", ResetSettings, ADMFLAG_ROOT);
	RegAdminCmd("sm_lvl_reset", ResetStatsFull, ADMFLAG_ROOT);
	RegAdminCmd("sm_lvl_del", ResetStatsPlayer, ADMFLAG_ROOT);
	RegConsoleCmd("sm_lvl", CallMainMenu);
	g_hTimerGiver = CreateTimer(1.0, PlayTimeCounter, _, TIMER_REPEAT);

	SetSettings(false);
	MakeHooks();
	ConnectDB();
	CreateTimer(3.5, TimerCoreIsReady);
}

public Action TimerCoreIsReady(Handle hTimer)
{
	if(!g_hDatabase)
	{
		LogLR("TimerCoreIsReady - database isn't ready");
		return;
	}
	else
	{
		Call_StartForward(g_hForward_OnCoreIsReady);
		Call_Finish();
	}
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
	g_iClientRoundExp[iClient] = 0;
	g_fCoefficient[iClient] = 0.0;

	SaveDataPlayer(iClient);
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