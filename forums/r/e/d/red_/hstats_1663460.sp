#pragma semicolon 1
/*
	TODO			
			
		later release:
			* make new kpd menu with top-like menu but sorted by kpd
			* count, store & display headshots
			* integrate headshot bonus into kill message
			* point scale down
			* dbg output: benchmark db time, updateRankCache
			* mark admins in dbg output
			* configurable verbosity for client chat messages
			* knife noob penalty weighted by amount of alive players per team
						
*/


#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION "1.9"
#define TRANSLATION_FILE "hstats.phrases"

#define TEAM_T 			2	/**< Terrorists. */
#define TEAM_CT			3	/**< Counter-Terrorists. */

#define MAX_FILE_LEN 80
#define MAX_NAME_LEN 40
#define MAX_LINE_WIDTH 128
#define MAX_WEAPON_NAME_LEN 20

#define MSG_NONE 0
#define MSG_PRIVATE 1
#define MSG_PUBLIC 2

#define BODYPART_HEAD 1

#define POINTS_NEW_PLAYER 1000

#define RP_SIZE_POINTS 2
#define RP_SIZE_ID 20
#define RP_SIZE_ID_BYTES ByteCountToCells(RP_SIZE_ID)

#define NEXT_PANEL_RANGE 7
#define PANEL_SHOW_TIME_MANUAL 9
#define PANEL_SHOW_TIME_AUTO 3
#define TOP_PANEL_SIZE 10

public Plugin:myinfo = 
{
	name = "HANSE-Stats",
	author = "red!",
	description = "Small file-based stats for CS:S",
	version = PLUGIN_VERSION,
	url = "http://www.hanse-clan.de"
};

// console variables
new Handle:s_logScoringEnable = INVALID_HANDLE;
new Handle:s_silentMode = INVALID_HANDLE;
new Handle:s_minPlayersForScoring = INVALID_HANDLE;
new Handle:s_reflectToVictim = INVALID_HANDLE;
new Handle:s_maxInactiveTime = INVALID_HANDLE;
new Handle:s_warmupTime = INVALID_HANDLE;

// CS:S
new Handle:s_csWeapMulDeagle;
new Handle:s_csWeapMulGlock;
new Handle:s_csWeapMulUsp;
new Handle:s_csWeapMulElite;
new Handle:s_csWeapMulP228;
new Handle:s_csWeapMulFiveseven;
new Handle:s_csWeapMulXm1014;
new Handle:s_csWeapMulM3;
new Handle:s_csWeapMulGalil;
new Handle:s_csWeapMulFamas;
new Handle:s_csWeapMulAk47;
new Handle:s_csWeapMulM4a1;
new Handle:s_csWeapMulAug;
new Handle:s_csWeapMulSg552;
new Handle:s_csWeapMulScout;
new Handle:s_csWeapMulSg550;
new Handle:s_csWeapMulG3sg1;
new Handle:s_csWeapMulAwp;
new Handle:s_csWeapMulMac10;
new Handle:s_csWeapMulTmp;
new Handle:s_csWeapMulMp5navy;
new Handle:s_csWeapMulUmp45;
new Handle:s_csWeapMulP90;
new Handle:s_csWeapMulM249;
new Handle:s_csWeapMulHegrenade;
new Handle:s_csWeapMulFlashbang;
new Handle:s_csWeapMulSmokegrenade;
new Handle:s_csWeapMulKnife;
// CS:GO
new Handle:s_csWeapMulNegev;
new Handle:s_csWeapMulBizon;
new Handle:s_csWeapMulDecoy;
new Handle:s_csWeapMulGalilar;
new Handle:s_csWeapMulHkp2000;
new Handle:s_csWeapMulMag7;
new Handle:s_csWeapMulBurnGrenade;
new Handle:s_csWeapMulMp7;
new Handle:s_csWeapMulMp9;
new Handle:s_csWeapMulNova;
new Handle:s_csWeapMulP250;
new Handle:s_csWeapMulSawedoff;
new Handle:s_csWeapMulScar20;
new Handle:s_csWeapMulSg556;
new Handle:s_csWeapMulSsg08;
new Handle:s_csWeapMulTaser;
new Handle:s_csWeapMulTec9;
// Points
new Handle:s_pointsPlrKill;
new Handle:s_pointsPlrTeamKill;
new Handle:s_pointsPlrBombDrop;
new Handle:s_pointsPlrBombPickup;
new Handle:s_pointsPlrBombPlanted;
new Handle:s_pointsPlrBombDefused;
new Handle:s_pointsPlrHstgKill;
new Handle:s_pointsPlrHstgRescue;
new Handle:s_pointsPlrDom;
new Handle:s_pointsPlrRev;	
new Handle:s_pointsPlrHeadshot;
new Handle:s_pointsPlrKnifeNoob;
new Handle:s_pointsPlrKillStreakOffset;
new Handle:s_pointsTeamWin;
new Handle:s_pointsTeamBombDefused;
new Handle:s_pointsTeamBombPlanted;
new Handle:s_pointsTeamBombExploded;
new Handle:s_pointsTeamHstgRescueAll;


// globals
new bool:s_lateLoaded;
new bool:s_isWarmup=false;

// PERSISTENT RANK DB 
new String:s_filenameBufferDB[MAX_FILE_LEN]; 
new String:s_filenameBufferDB2[MAX_FILE_LEN];
new Handle:s_kvStatsDB = INVALID_HANDLE; // stores recent players
new Handle:s_kvStatsDB2 = INVALID_HANDLE;  // stores player which have not been online for more than MAX_INACTIVE_TIME days
new bool:s_kvStatsDB2dirtyFlag=false; // try not to update DB2 too often thus it may get large

// MEMORY RANK CACHE
/*
		s_rankId	: string array of steam ids
		| steam:0:...<0> |
		| steam:0:...<1> |
		...
		| steam:0:...<n> |
		
		s_rankPoints: array of 2 cells (points, foreign key to s_rankIds); sorted by points (first field, descending)
	|	| points<2> | key->s_rankId[a] |
	|	| points<1> | key->s_rankId[b] |
	v	...
		| points<0> | key->s_rankId[z] |

		number of elements in both arrays is given by new s_totalAmountOfPlayers=0;
*/
new s_totalAmountOfPlayers=0;
new Handle:s_rankPoints = INVALID_HANDLE;
#define RANK_ARRAY_IDX_POINTS 0
#define RANK_ARRAY_IDX_ID_KEY 1
new Handle:s_rankIds = INVALID_HANDLE;
new Handle:s_scoreTable = INVALID_HANDLE;
new s_scoreTableSize=0;
new s_teamHasMembersT = false;
new s_teamHasMembersCT = false;

// PLAYER RECORDS
new s_playerKills[MAXPLAYERS+1];
new s_playerKillsAtSesStart[MAXPLAYERS+1];
new s_playerDeaths[MAXPLAYERS+1];
new s_playerDeathsAtSesStart[MAXPLAYERS+1];
new s_playerSuicides[MAXPLAYERS+1];
new s_playerSuicidesAtSesStart[MAXPLAYERS+1];
new s_playerPoints[MAXPLAYERS+1];
new s_playerPointsAtSesStart[MAXPLAYERS+1];
new s_playerRank[MAXPLAYERS+1];
new s_playerRankAtSesStart[MAXPLAYERS+1];
new s_playerConTime[MAXPLAYERS+1];
new s_playerConTimeAtSesStart[MAXPLAYERS+1];
new s_playerFirstConTimestamp[MAXPLAYERS+1];
new s_playerConTimestamp[MAXPLAYERS+1];
new s_playerKillsInARow[MAXPLAYERS+1];
new String:s_playerWeapon[MAXPLAYERS+1][MAX_WEAPON_NAME_LEN];
new s_playerCurrentMenuOffset[MAXPLAYERS+1];

// PLAYER SETTINGS
#define SETT_AUTOSHOW_OFF 0
#define SETT_AUTOSHOW_START 1
#define SETT_AUTOSHOW_END 2
#define SETT_AUTOSHOW_DEFAULT SETT_AUTOSHOW_START
#define SETT_MSG_DEFAULT 1
new Handle:s_autoShowCookie = INVALID_HANDLE;
new Handle:s_textDisplayCookie = INVALID_HANDLE;
new s_settAutoShow[MAXPLAYERS+1];
new s_settMsgDisplay[MAXPLAYERS+1];

new s_teamPoints[4]= {1000, 1000, 1000, 1000};
new s_teamClientCount[4]= {1, 1, 1, 1};
#define MAX_RECORDED_RESULTS 3
new s_lastResults[MAX_RECORDED_RESULTS] = {0,0,0};

new bool:s_hasClientPrefs=false;
new bool:s_hasScoreLoggingEnabled;
new String:s_menutitle[40] = "Stats";

#define GAMEMODE_GENERIC 0
#define GAMEMODE_CSS 1
#define GAMEMODE_CSGO 2
new s_gameMode = GAMEMODE_GENERIC;


/****************************************************
 ****************************************************
 
				Startup

 ****************************************************
*****************************************************/

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	s_lateLoaded = late;
	return APLRes_Success;
}

public OnPluginStart(){

	new String:GameType[10];
	GetGameFolderName(GameType, sizeof(GameType));
	if (StrEqual(GameType, "cstrike", false)) {
		s_gameMode = GAMEMODE_CSS;
		LogMessage("hstats is running in counter strike:source mode");
	} 
	else if (StrEqual(GameType, "csgo", false)) {
		s_gameMode = GAMEMODE_CSGO;
		LogMessage("hstats is running in counter strike:go mode");
	} 
	else {
		s_gameMode = GAMEMODE_GENERIC;
		LogMessage("hstats is running in generic mode");
	}

	LoadTranslations(TRANSLATION_FILE);
	CreateConVar("hstats_version", PLUGIN_VERSION, "Version of HANSE-Stats", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
	
	// init databases and memory cache
	BuildPath(Path_SM, s_filenameBufferDB, MAX_FILE_LEN, "data/hstats_database.txt");
	BuildPath(Path_SM, s_filenameBufferDB2, MAX_FILE_LEN, "data/hstats_database2.txt");
	
	s_kvStatsDB=CreateKeyValues("UserStats");
	if(!FileToKeyValues(s_kvStatsDB, s_filenameBufferDB))
	{
    	KeyValuesToFile(s_kvStatsDB, s_filenameBufferDB);
    }
	
	s_kvStatsDB2=CreateKeyValues("InactiveUserStats");
	FileToKeyValues(s_kvStatsDB2, s_filenameBufferDB2);
	
	s_rankPoints = CreateArray(RP_SIZE_POINTS,300);
	s_rankIds = CreateArray(RP_SIZE_ID_BYTES,300);
	s_scoreTable = CreateArray(RP_SIZE_POINTS,MAXPLAYERS);
	
	for(new i = 1; i <= MAXPLAYERS; i++) {
		purgeClientRecord(i);
	}
	
	// setup console variables 
	
	// all modes
	s_logScoringEnable = CreateConVar("sm_scoringLogEnable", "0", "1 enables logging of all score events. Use for debugging/finetuning only. Produces a lot of data and wastes performance!!!");
	s_silentMode = CreateConVar("sm_statsSilentMode", "0", "1 enables silent mode. No Menus or user interaction is avaible beside the sm_hstats command in console.");
	s_minPlayersForScoring = CreateConVar("sm_minPlayersForScoring", "4", "Number of players needed to be in game for scoring to start");
	s_reflectToVictim = CreateConVar("sm_reflectToVictim", "100", "Percentage of points subtracted from victim. (100% means to subtract all the points the killer got for the kill)");
	s_maxInactiveTime = CreateConVar("sm_maxInactiveTime", "28", "Number of days without connect before a player is not listed in stats. Do not set too high, thus the stats consume higher amounts of resources on large active player counts.");
	s_warmupTime = FindConVar("mp_warmuptime");
	
	s_pointsPlrKillStreakOffset = CreateConVar("sm_pointsPlrKillStreakOffset", "1", "Player Points: Kill Streak Offset (incremented by one for each suceeding kill)");
	s_pointsTeamWin = CreateConVar("sm_pointsTeamWin", "3", "Team Points: Round Win base score (modified by factor build from team score difference)");
	s_pointsPlrDom = CreateConVar("sm_pointsPlrDom", "5", "Player Points: Domination");
	s_pointsPlrRev = CreateConVar("sm_pointsPlrRev", "3", "Player Points: Revenge");
	s_pointsPlrKill = CreateConVar("sm_pointsPlrKill", "4", "Player Points: Kill");
	s_pointsPlrTeamKill = CreateConVar("sm_pointsPlrTeamKill", "-50", "Player Points: Teamkill");
	s_pointsPlrHeadshot = CreateConVar("sm_pointsPlrHeadshot", "1", "Player Points: Headshot");
	
	// CSS/CSGO
	if ((s_gameMode == GAMEMODE_CSS) || (s_gameMode == GAMEMODE_CSGO)) {
		s_pointsPlrKnifeNoob = CreateConVar("sm_pointsPlrKnifeNoob", "-8", "Player Points: Knife Noob Penalty (being shot while using a knife)");
		s_pointsPlrBombPlanted = CreateConVar("sm_pointsPlrBombPlanted", "10", "Player Points: Bomb Planted");
		s_pointsPlrBombDefused = CreateConVar("sm_pointsPlrBombDefused", "10", "Player Points: Bomb Defused");
		s_pointsTeamBombDefused = CreateConVar("sm_pointsTeamBombDefused", "5", "Team Points: Bomb Defused");
		s_pointsTeamBombPlanted = CreateConVar("sm_pointsTeamBombPlanted", "2", "Team Points: Bomb Planted");
		s_pointsTeamBombExploded = CreateConVar("sm_pointsTeamBombExploded", "5", "Team Points: Bomb Exploded");
		s_pointsPlrBombDrop = CreateConVar("sm_pointsPlrBombDrop", "-2", "Player Points: Bomb Drop");
		s_pointsPlrBombPickup = CreateConVar("sm_pointsPlrBombPickup", "2", "Player Points: BombP ickup");
		s_pointsPlrHstgKill = CreateConVar("sm_pointsPlrHstgKill", "-15", "Player Points: Hostage Kill");
		s_pointsPlrHstgRescue = CreateConVar("sm_pointsPlrHstgRescue", "5", "Player Points: Hostage Rescue");
		s_pointsTeamHstgRescueAll = CreateConVar("sm_pointsTeamHstgRescueAll", "8", "Team Points: Rescue All Hostages");
		
		s_csWeapMulDeagle = CreateConVar("sm_csWeapMulDeagle", "1.20", "Weapon multiplier: Deagle (pistol)");
		s_csWeapMulGlock = CreateConVar("sm_csWeapMulGlock", "1.40", "Weapon multiplier: Glock-18 (pistol)");
		s_csWeapMulElite = CreateConVar("sm_csWeapMulElite", "1.40", "Weapon multiplier: Dual Elites (pistol)");
		s_csWeapMulFiveseven = CreateConVar("sm_csWeapMulFiveseven", "1.50", "Weapon multiplier: Fiveseven (pistol)");
		
		s_csWeapMulXm1014 = CreateConVar("sm_csWeapMulXm1014", "1.10", "Weapon multiplier: XM1014 (auto pumpgun)");
		
		s_csWeapMulFamas = CreateConVar("sm_csWeapMulFamas", "1.00", "Weapon multiplier: Famas (assault rifle)");
		s_csWeapMulAk47 = CreateConVar("sm_csWeapMulAk47", "1.00", "Weapon multiplier: Ak47 (assault rifle)");
		s_csWeapMulM4a1 = CreateConVar("sm_csWeapMulM4a1", "1.00", "Weapon multiplier: M4A1 (assault rifle)");
		s_csWeapMulAug = CreateConVar("sm_csWeapMulAug", "1.00", "Weapon multiplier: Aug (scoped assault rifle)");
		
		s_csWeapMulG3sg1 = CreateConVar("sm_csWeapMulG3sg1", "0.40", "Weapon multiplier: G3SG1 (auto sniper)");
		s_csWeapMulAwp = CreateConVar("sm_csWeapMulAwp", "0.60", "Weapon multiplier: AWP (sniper rifle)");
		
		s_csWeapMulMac10 = CreateConVar("sm_csWeapMulMac10", "1.50", "Weapon multiplier: Mac10 (SMG)");
		s_csWeapMulUmp45 = CreateConVar("sm_csWeapMulUmp45", "1.30", "Weapon multiplier: Ump45 (SMG)");
		s_csWeapMulP90 = CreateConVar("sm_csWeapMulP90", "0.80", "Weapon multiplier: P90 (SMG)");
		
		s_csWeapMulM249 = CreateConVar("sm_csWeapMulM249", "1.20", "Weapon multiplier: M249 (heavy machine gun)");
		s_csWeapMulHegrenade = CreateConVar("sm_csWeapMulHegrenade", "1.80", "Weapon multiplier: HE-grenade");
		s_csWeapMulFlashbang = CreateConVar("sm_csWeapMulFlashbang", "10.00", "Weapon multiplier: Flashbang");
		s_csWeapMulSmokegrenade = CreateConVar("sm_csWeapMulSmokegrenade", "10.00", "Weapon multiplier: Smokegrenade");
		s_csWeapMulKnife = CreateConVar("sm_csWeapMulKnife", "2.00", "Weapon multiplier: Knife");
	}
	if (s_gameMode == GAMEMODE_CSS) {
		s_csWeapMulUsp = CreateConVar("sm_csWeapMulUsp", "1.40", "Weapon multiplier: USP (pistol)");
		s_csWeapMulP228 = CreateConVar("sm_csWeapMulP228", "1.50", "Weapon multiplier: P228 (pistol)");
		
		s_csWeapMulM3 = CreateConVar("sm_csWeapMulM3", "1.20", "Weapon multiplier: M3 (pumpgun)");
		
		s_csWeapMulTmp = CreateConVar("sm_csWeapMulTmp", "1.50", "Weapon multiplier: Tmp (SMG)");
		s_csWeapMulMp5navy = CreateConVar("sm_csWeapMulMp5navy", "1.20", "Weapon multiplier: Mp5 navy (SMG)");
		
		s_csWeapMulGalil = CreateConVar("sm_csWeapMulGalil", "1.10", "Weapon multiplier: Galil (assault rifle)");
		s_csWeapMulSg552 = CreateConVar("sm_csWeapMulSg552", "1.00", "Weapon multiplier: SG552 (scoped assault rifle)");
		
		s_csWeapMulSg550 = CreateConVar("sm_csWeapMulSg550", "0.40", "Weapon multiplier: SG550 (auto sniper)");
		s_csWeapMulScout = CreateConVar("sm_csWeapMulScout", "1.10", "Weapon multiplier: Scout (light sniper)");
	}
	if (s_gameMode == GAMEMODE_CSGO) {
		s_csWeapMulP250 = CreateConVar("sm_csWeapMulP250", "1.50", "Weapon multiplier: P250 (pistol)");
		s_csWeapMulHkp2000 = CreateConVar("sm_csWeapMulHkp2000", "1.40", "Weapon multiplier: HK P2000 (pistol)");
		s_csWeapMulTec9 = CreateConVar("sm_csWeapMulTec9", "1.50", "Weapon multiplier: TEC-9 (pistol)");
		
		s_csWeapMulMag7 = CreateConVar("sm_csWeapMulMag7", "1.15", "Weapon multiplier: Mag7 (pumpgun)");
		s_csWeapMulNova = CreateConVar("sm_csWeapMulNova", "1.20", "Weapon multiplier: Nova (pumpgun)");
		s_csWeapMulSawedoff = CreateConVar("sm_csWeapMulSawedoff", "1.40", "Weapon multiplier: Sawedoff (pumpgun)");
		
		s_csWeapMulBizon = CreateConVar("sm_csWeapMulBizon", "1.20", "Weapon multiplier: Bizon (SMG)");
		s_csWeapMulMp7 = CreateConVar("sm_csWeapMulMp7", "1.20", "Weapon multiplier: Mp7 (SMG)");
		s_csWeapMulMp9 = CreateConVar("sm_csWeapMulMp9", "1.50", "Weapon multiplier: Mp9 (SMG)");
		
		s_csWeapMulGalilar = CreateConVar("sm_csWeapMulGalilar", "1.10", "Weapon multiplier: Galil AR (assault rifle)");
		s_csWeapMulSg556 = CreateConVar("sm_csWeapMulSg556", "1.00", "Weapon multiplier: SG-556 (scoped assault rifle)");
		
		s_csWeapMulSsg08 = CreateConVar("sm_csWeapMulSsg08", "1.10", "Weapon multiplier: SSG 08 (light sniper)");
		s_csWeapMulScar20 = CreateConVar("sm_csWeapMulScar20", "0.40", "Weapon multiplier: Scar-20 (auto sniper)");
		
		s_csWeapMulNegev = CreateConVar("sm_csWeapMulNegev", "1.20", "Weapon multiplier: Negev (heavy machine gun)");
		
		s_csWeapMulBurnGrenade = CreateConVar("sm_csWeapMulBurnGrenade", "1.70", "Weapon multiplier: Molotov coctail/Incendiary  grenade");
		s_csWeapMulDecoy = CreateConVar("sm_csWeapMulDecoy", "20.00", "Weapon multiplier: Decoy Grenade");
		s_csWeapMulTaser = CreateConVar("sm_csWeapMulTaser", "2.00", "Weapon multiplier: Taser");	
	}
		
	AutoExecConfig(true, "hstats");
	
	// init ranking
	updateRankCache();
	
	// setup client prefs
	s_hasClientPrefs = GetExtensionFileStatus("clientprefs.ext")==1 && SQL_CheckConfig("clientprefs");
	if(s_hasClientPrefs)
	{
		s_autoShowCookie = RegClientCookie("statsAutoShow", "enabled stats auto show on round start or end", CookieAccess_Private);
		s_textDisplayCookie = RegClientCookie("statsTextMessages", "enabled text messages on stats events", CookieAccess_Private);
		SetCookieMenuItem(showPrefMenu, 0, s_menutitle);
	} else {
		LogError("ClientPrefs extension not found, unable to initialize user setting menu");
	}
	

	// register commands & events
	RegConsoleCmd("sm_hstats", consoleStatsCmd);
	RegAdminCmd("sm_hstats_dbg", consoleDbgCmd, ADMFLAG_GENERIC);
	RegAdminCmd("sm_hstats_adm", consoleAdmCmd, ADMFLAG_CONFIG);
	RegConsoleCmd("sm_rank", showRankPanelCmd);
	RegConsoleCmd("sm_kpd", showRankPanelCmd);
	RegConsoleCmd("sm_top10", showTopPanelCmd);
	RegConsoleCmd("sm_top", showTopPanelCmd);
	RegConsoleCmd("sm_score", showScorePanelCmd);
	RegConsoleCmd("sm_scoreboard", showScorePanelCmd);
	RegConsoleCmd("sm_next", showNextPanelCmd);

   
	HookEvent("round_start", 		EventRoundStart,EventHookMode_PostNoCopy);
	HookEvent("round_end", 			EventRoundEnd,EventHookMode_PostNoCopy);
	HookEvent("player_death", 		EventPlayerDeath);
	HookEvent("player_hurt", 		EventPlayerHurt);
	HookEvent("player_disconnect", 	EventPlayerDisconnect);
	
	if ((s_gameMode == GAMEMODE_CSS) || (s_gameMode == GAMEMODE_CSGO)) {
		HookEvent("bomb_dropped",    	EventPlayerBombDropped);
		HookEvent("bomb_pickup",     	EventPlayerBombPickup);
		HookEvent("bomb_planted",    	EventPlayerBombPlanted);
		HookEvent("bomb_defused",    	EventPlayerBombDefused);
		HookEvent("hostage_killed",  	EventPlayerHostageKill);
		HookEvent("hostage_rescued", 	EventPlayerHostageResc);
		HookEvent("bomb_exploded", 		EventBombExploded);
		HookEvent("hostage_rescued_all",EventPlayerHostageRescAll);
	}
	
	// if loaded late, players may already be present on server without having passed the OnClientPutInServer callback
	if(s_lateLoaded)
	{
		reloadAllPlayers();
	} else {
		CreateTimer(0.2, doDbMaintenanceTimed, 0.0);
	}
}

public OnMapStart() 
{
	new Float:warmupTime = 0.0;
	if (s_warmupTime !=INVALID_HANDLE) {
		warmupTime=GetConVarFloat(s_warmupTime);
	}
	if (warmupTime>0.0) {
		s_isWarmup=true;
		if (s_hasScoreLoggingEnabled) { LogMessage("Starting warmup period of %.1f seconds", warmupTime); }
		if (CreateTimer(warmupTime, Timer_WarmupEnd, 0, TIMER_FLAG_NO_MAPCHANGE)==INVALID_HANDLE) {
			s_isWarmup=false;
		}
	}
}

public Action:Timer_WarmupEnd(Handle:timer, any:param)
{
	if (s_hasScoreLoggingEnabled) { LogMessage("Ending warmup period"); }
	s_isWarmup=false;
}

public OnPluginEnd()
{
	flushAllClientCaches();
	flushDataBaseToFile();
}

public OnClientPutInServer(client)
{
	PrepareClient(client);
}

public OnClientCookiesCached(client)
{
	// Initializations and preferences loading
	if(isValidPlayer(client))
	{
		loadClientCookies(client);	
	}
}


/****************************************************
 ****************************************************
 
				Events
				
 ****************************************************
*****************************************************/


public EventPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new leavingPlayer = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isValidPlayer(leavingPlayer)) {
		flushClientCache(leavingPlayer); 
		purgeClientRecord(leavingPlayer);	
	}
	
	updateScoreBoard();
	
	// server is empty -> cleanup
	if (GetClientCount()==0) {
		updateRankCache();
		flushDataBaseToFile();
		for (new i=0; i<MAX_RECORDED_RESULTS;i++)
		{
			s_lastResults[i]=0;
		}
	}
} 

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// check if both players have human players
	s_teamHasMembersT = false;
	s_teamHasMembersCT = false;
	for ( new i = 1; i <= GetMaxClients(); i++ ) {
        if ( IsClientInGame(i) && !IsFakeClient(i)) {
			new team=GetClientTeam(i);
			if (team==TEAM_T) {
				s_teamHasMembersT=true;
			} else if (team==TEAM_CT) {
				s_teamHasMembersCT=true;
			}
        }
    }

	s_teamPoints[TEAM_T]=0;
	s_teamPoints[TEAM_CT]=0;		
	if (!isScoringEnabled()) 
	{ 
		new String:msgBuf[MAX_LINE_WIDTH];
		Format(msgBuf, MAX_LINE_WIDTH, "%T", "Stats are disabled until there are at least <n> players", LANG_SERVER, GetConVarInt(s_minPlayersForScoring));
		PrintToSubscriberChats(msgBuf); 
	} else {
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(isValidPlayer(i)) {
				if (GetClientTeam(i)==TEAM_CT) {s_teamPoints[TEAM_CT]+=s_playerPoints[i];}
				if (GetClientTeam(i)==TEAM_T) {s_teamPoints[TEAM_T]+=s_playerPoints[i];}
				if (s_settAutoShow[i]==SETT_AUTOSHOW_START)
				{	
					showRankPanel(i,PANEL_SHOW_TIME_AUTO);
				}
			}
			s_playerWeapon[i]="-"; // erase
		}
	}
	if (s_teamPoints[TEAM_CT]<POINTS_NEW_PLAYER) { s_teamPoints[TEAM_CT]=POINTS_NEW_PLAYER;}
	if (s_teamPoints[TEAM_T]<POINTS_NEW_PLAYER) { s_teamPoints[TEAM_T]=POINTS_NEW_PLAYER;}
	
	s_teamClientCount[TEAM_CT] = GetTeamClientCount(TEAM_CT);
	s_teamClientCount[TEAM_T] = GetTeamClientCount(TEAM_T);
	if (s_teamClientCount[TEAM_CT]==0) { s_teamClientCount[TEAM_CT]=1;}
	if (s_teamClientCount[TEAM_T]==0) { s_teamClientCount[TEAM_T]=1;}
	
	s_hasScoreLoggingEnabled = GetConVarBool(s_logScoringEnable);
	 
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isScoringEnabled()) {
	
		new winner = GetEventInt(event, "winner");
		new points = scalePoints (GetConVarInt(s_pointsTeamWin), winner);
			
		grantTeamPoints(winner, points, "WIN_TEAM"); 
		grantTeamPoints(getOpposingTeamOf(winner), 0-points, "LOOSE_TEAM"); 
		
		flushAllClientCaches();
		updateRankCache();
		
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(isValidPlayer(i) && (IsPlayerAlive(i))) 
			{
				// points bonus for survivors
				if (GetClientTeam(i)==winner) { 
					grantClientPoints(i, points, "SURVIVE_BONUS_PLR");
				} else {
					grantClientPoints(i, -1 * points, "COWARD_PENALTY_PLR");
				}
				
				// only for alive players, dead ones got this on death event
				if ( s_settAutoShow[i]==SETT_AUTOSHOW_END ) { showRankPanel(i,PANEL_SHOW_TIME_AUTO); }
			}
		}
		CreateTimer(0.1, PostEventRoundEnd, 0);
		
		// count relative score
		for (new i=1; i<MAX_RECORDED_RESULTS;i++) { s_lastResults[i-1]=s_lastResults[i]; }
		s_lastResults[MAX_RECORDED_RESULTS-1]=winner;
		
	} else {
		for (new i=0; i<MAX_RECORDED_RESULTS;i++) { s_lastResults[i]=0; }
	}
}
public Action:PostEventRoundEnd(Handle:timer, any:value) {
	flushDataBaseToFile();
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:dom	= GetEventBool(event, "dominated");
	new bool:rev	= GetEventBool(event, "revenge");
	new String:weapon[MAX_WEAPON_NAME_LEN] = "";
	GetEventString(event, "weapon",weapon, MAX_WEAPON_NAME_LEN);
	
	new String:vic_nameBuf[MAX_NAME_LEN] = "";	
	GetClientName(victim,vic_nameBuf, MAX_NAME_LEN);
	
	if (isScoringEnabled()) 
	{
		if (isValidPlayer(victim) && isValidPlayer(attacker)) 
		{
			if ( victim == attacker ) // suicide
			{
				s_playerSuicides[victim]+=1;
			} 
			else 
			{
				new String:att_nameBuf[MAX_NAME_LEN] = "";
				GetClientName(attacker,att_nameBuf, MAX_NAME_LEN);
				new String:msgBuf[MAX_LINE_WIDTH];
				new String:logBuf[MAX_LINE_WIDTH];
				
				if (GetClientTeam(victim) == GetClientTeam(attacker)) // team kill
				{
					new points=GetConVarInt(s_pointsPlrTeamKill);
					Format(msgBuf, MAX_LINE_WIDTH, "%T", "<x> got <n> <point|s> for team killing <y>", LANG_SERVER, att_nameBuf, points ,(points==1) ? "point":"points", vic_nameBuf);
					grantClientPoints(attacker, points, "TEAMKILL_PLR", msgBuf, MSG_PUBLIC);
				} 
				else // normal kill
				{				
				
				
					new pointsDelta=0;
					if (s_playerKills[attacker]<50)
					{
						pointsDelta=2;
						Format(logBuf, MAX_LINE_WIDTH, "KILL_PLR while in grace period");
					} else {
						new Float:kpdMultiplier = calcKpd(s_playerKills[victim], s_playerDeaths[victim]) / calcKpd(s_playerKills[attacker], s_playerDeaths[attacker]);
						new Float:weaponMultiplierP1 = getWeaponMultiplier(weapon);
						new Float:weaponMultiplierP2 = getWeaponMultiplier(s_playerWeapon[victim]);
						new Float:weaponMultiplierQ = weaponMultiplierP1 / weaponMultiplierP2;			
						new Float:weaponMultiplier = (weaponMultiplierP1 + weaponMultiplierQ)/2.0; 
						new Float:pointMultiplier = kpdMultiplier * weaponMultiplier;
						pointsDelta = RoundToFloor((float(GetConVarInt(s_pointsPlrKill) * s_playerPoints[victim]) * pointMultiplier)) / s_playerPoints[attacker];
						Format(logBuf, MAX_LINE_WIDTH, "KILL_PLR (%s(%.2f)->%s(%.2f):%.2f+%.2f/2=%.2f)",weapon,weaponMultiplierP1,s_playerWeapon[victim],weaponMultiplierP2,weaponMultiplierP1, weaponMultiplierQ, weaponMultiplier);
					} 
					if (pointsDelta<=0) { pointsDelta=1; }
					new pointsBonus = 0;
					new String:bonusText[30] = "";
					if (dom) { pointsBonus=GetConVarInt(s_pointsPlrDom); Format(bonusText, 30, " (%T)", "plus <n> for domination", LANG_SERVER, pointsBonus);}
					if (rev) { pointsBonus=GetConVarInt(s_pointsPlrRev); Format(bonusText, 30, " (%T)", "plus <n> for revenge", LANG_SERVER, pointsBonus);}
									
					Format(msgBuf, MAX_LINE_WIDTH, "%T", "<x> got <n> <point|s><plus_bonus> for killing <y>", LANG_SERVER, att_nameBuf, pointsDelta, (pointsDelta==1) ? "point":"points", bonusText, vic_nameBuf);
					
					grantClientPoints(attacker, pointsDelta+pointsBonus, logBuf, msgBuf, MSG_PUBLIC);

					new victimsDelta = GetConVarInt(s_reflectToVictim) * pointsDelta / 100;
					grantClientPoints(victim, 0-victimsDelta, "DEATH_PLR");
					
					s_playerKills[attacker]+=1;
					s_playerDeaths[victim]+=1;		

					// kill streak
					s_playerKillsInARow[attacker]++;
					if (s_playerKillsInARow[attacker]>1) {
						grantClientPoints(attacker, GetConVarInt(s_pointsPlrKillStreakOffset)+s_playerKillsInARow[attacker]-1, "KILL_STREAK"); 
					}
					s_playerKillsInARow[victim]=0;
					
					if ((s_gameMode == GAMEMODE_CSS) || (s_gameMode == GAMEMODE_CSGO)) {
						//Knife noob penalty
						if (StrEqual("weapon_knife", s_playerWeapon[victim], false) && !StrEqual("weapon_knife", s_playerWeapon[attacker], false)) 
						{
							new points=GetConVarInt(s_pointsPlrKnifeNoob);
							Format(msgBuf, MAX_LINE_WIDTH, "%T", "<x> got <n> <point|s> for bringing a knife to a gun fight", LANG_SERVER, vic_nameBuf, points,(points==1) ? "point":"points" );
							grantClientPoints(victim, points, "KNIFE_NOOB_PLR", msgBuf, MSG_PUBLIC);
						}
					}
				}
			}
		}
		if ( s_settAutoShow[victim]==SETT_AUTOSHOW_END ) { showRankPanel(victim,PANEL_SHOW_TIME_AUTO); }
	}
}

public EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new part = GetEventInt(event, "hitgroup");	
	new health = GetEventInt(event, "health");	
	
	if (isValidPlayer(victim)) {
		GetClientWeapon(victim, s_playerWeapon[victim], MAX_WEAPON_NAME_LEN); // used for knife noob penalty
	}

	if(isValidPlayer(attacker))
	{	
		GetClientWeapon(attacker, s_playerWeapon[attacker], MAX_WEAPON_NAME_LEN); // used for knife noob penalty
		if (part==BODYPART_HEAD && health<=0) {
			new String:msgBuf[MAX_LINE_WIDTH];
			new points=GetConVarInt(s_pointsPlrHeadshot);
			Format(msgBuf, MAX_LINE_WIDTH, "%T", "You got <n> <point|s> for headshot", LANG_SERVER, points, (points==1) ? "point":"points");
			grantClientPoints(attacker, points, "HEADSHOT_PLR", msgBuf, MSG_PRIVATE);
		}
	}
}

//////////////////////////////////////////
// CSS 
//
public EventPlayerBombDropped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isValidPlayer(player)) {
		new String:nameBuf[MAX_NAME_LEN] = "";
		GetClientName(player,nameBuf, MAX_NAME_LEN);	
		new String:msgBuf[MAX_LINE_WIDTH];
		new points = GetConVarInt(s_pointsPlrBombDrop);
		Format(msgBuf, MAX_LINE_WIDTH, "%T", "You got <n> <point|s> for dropping the bomb", LANG_SERVER, points, (points==1) ? "point":"points");
		grantClientPoints(player, points, "BOMB_DROPPED_PLR", msgBuf, MSG_PRIVATE);
	}
}

public EventPlayerBombPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isValidPlayer(player)) {
		new String:nameBuf[MAX_NAME_LEN] = "";
		GetClientName(player,nameBuf, MAX_NAME_LEN);
		
		new String:msgBuf[MAX_LINE_WIDTH];
		new points=GetConVarInt(s_pointsPlrBombPickup);
		Format(msgBuf, MAX_LINE_WIDTH, "%T", "You got <n> <point|s> for taking the bomb", LANG_SERVER, points, (points==1) ? "point":"points");
		grantClientPoints(player,points, "BOMB_PICKUP", msgBuf, MSG_PRIVATE);
	}
}

public EventPlayerBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isValidPlayer(player)) {
		new String:msgBuf[MAX_LINE_WIDTH];
		new points = scalePoints (GetConVarInt(s_pointsPlrBombPlanted), TEAM_T);
		Format(msgBuf, MAX_LINE_WIDTH, "%T", "You got <n> <point|s> for planting the bomb", LANG_SERVER, points, (points==1) ? "point":"points");
		grantClientPoints(player, points,"BOMB_PLANTED_PLR", msgBuf, MSG_PRIVATE);
		
		points = scalePoints (GetConVarInt(s_pointsTeamBombPlanted), TEAM_T);
		Format(msgBuf, MAX_LINE_WIDTH, "%T", "Terrorists got <n> <point|s> for planting the bomb", LANG_SERVER, points, (points==1) ? "point":"points");
		grantTeamPoints( TEAM_T, points, "BOMB_PLANTED_TEAM", msgBuf, MSG_PUBLIC);
		grantTeamPoints( TEAM_CT, 0-(points/2), "BOMB_PLANTED_PENALTY_TEAM");
	}
}

public EventPlayerBombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:nameBuf[MAX_NAME_LEN] = "";
	new String:msgBuf[MAX_LINE_WIDTH];
	
	new points = scalePoints (GetConVarInt(s_pointsPlrBombDefused), TEAM_CT);
	if(isValidPlayer(player)) {
		GetClientName(player,nameBuf, MAX_NAME_LEN);
		Format(msgBuf, MAX_LINE_WIDTH, "%T", "<x> got <n> <point|s> for defusing the bomb", LANG_SERVER,nameBuf, points, (points==1) ? "point":"points");
		grantClientPoints(player, points, "BOMB_DEFUSED_PLR", msgBuf, MSG_PUBLIC);
	}
	points = scalePoints (GetConVarInt(s_pointsTeamBombDefused), TEAM_CT);
	Format(msgBuf, MAX_LINE_WIDTH, "%T", "Counter-Terrorists got <n> <point|s> for defusing the bomb", LANG_SERVER, points, (points==1) ? "point":"points");
	grantTeamPoints( TEAM_CT, points, "BOMB_DEFUSED_TEAM", msgBuf, MSG_PUBLIC);
	grantTeamPoints( TEAM_T, 0-(points/2), "BOMB_DEFUSED_PENALTY_TEAM");
			
	// estimate alive players
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(isValidPlayer(i) && IsPlayerAlive(i) && GetClientTeam(i)==TEAM_T) 
		{
			grantClientPoints(i, 0-points, "BOMB_NOT_PROTECTED_PLR");
			GetClientName(i,nameBuf, MAX_NAME_LEN);
		}
	}
}

public EventPlayerHostageKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isValidPlayer(player)) {
		new String:nameBuf[MAX_NAME_LEN] = "";
		GetClientName(player,nameBuf, MAX_NAME_LEN);
		new String:msgBuf[MAX_LINE_WIDTH];
		new points=GetConVarInt(s_pointsPlrHstgKill);
		Format(msgBuf, MAX_LINE_WIDTH, "%T", "<x> got <n> <point|s> for killing a hostage", LANG_SERVER, nameBuf, points, (points==1) ? "point":"points");
		grantClientPoints(player,points, "HOSTAGE_KILL_PENALTY_PLR", msgBuf, MSG_PUBLIC);
	}
}
public EventBombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new String:msgBuf[MAX_LINE_WIDTH];
	new points = scalePoints (GetConVarInt(s_pointsTeamBombExploded), TEAM_T);
	Format(msgBuf, MAX_LINE_WIDTH, "%T", "Terrorists got <n> <point|s> for detonating the bomb", LANG_SERVER, points, (points==1) ? "point":"points");
	grantTeamPoints( TEAM_T, points, "BOMB_EXPLODE_TEAM", msgBuf, MSG_PUBLIC );
	grantTeamPoints( TEAM_CT, 0-(points/2),"BOMB_EXPLODE_PENALTY_TEAM");
}

public EventPlayerHostageRescAll(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:msgBuf[MAX_LINE_WIDTH];
	new points = scalePoints (GetConVarInt(s_pointsTeamHstgRescueAll), TEAM_CT);
	Format(msgBuf, MAX_LINE_WIDTH, "%T", "Counter-Terrorists got <n> <point|s> for rescuing all hostages", LANG_SERVER, points, (points==1) ? "point":"points");
	grantTeamPoints( TEAM_CT, points, "ALL_HOSTAGES_RESC_TEAM", msgBuf, MSG_PUBLIC );
	grantTeamPoints( TEAM_T, 0-(points/2), "ALL_HOSTAGES_RESC_PLR");
}

public EventPlayerHostageResc(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isValidPlayer(player)) {
		new String:msgBuf[MAX_LINE_WIDTH];
		new points=GetConVarInt(s_pointsPlrHstgRescue);
		Format(msgBuf, MAX_LINE_WIDTH, "%T", "You got <n> <point|s> for rescuing a hostage", LANG_SERVER, points, (points==1) ? "point":"points");
		grantClientPoints(player, points, "HOSTAGE_RESC_PLR", msgBuf, MSG_PRIVATE);
	}
}


/****************************************************
 ****************************************************
 
				User Interaction

 ****************************************************
*****************************************************/


public PrintToSubscriberChats(const String:message[])
{
	if (GetConVarBool(s_silentMode)) { return; }
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		PrintToSubscribedClientChat(i, message);
	}	
}
public PrintToSubscribedClientChat(client, const String:message[])
{
	if (GetConVarBool(s_silentMode)) { return; }
	if(isValidPlayer(client) && s_settMsgDisplay[client]==1)
	{	
		PrintToChat(client, message);
	}	
}


public Action:showTopPanelCmd(client, args) {
	if (GetConVarBool(s_silentMode)) { return; }
	s_playerCurrentMenuOffset[client]=0;
	CreateTimer(0.6, showTopPanelTimer, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public TopMenuHandler(Handle:menu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		switch (item) {
			case 8:
			{
				// Back
				if (s_playerCurrentMenuOffset[client]>TOP_PANEL_SIZE) { s_playerCurrentMenuOffset[client]-=TOP_PANEL_SIZE; } else { s_playerCurrentMenuOffset[client]=0; }
				showTopPanelTimer(menu, client);
			}
			case 9:
			{
				//Next
				if (s_playerCurrentMenuOffset[client]+TOP_PANEL_SIZE<s_totalAmountOfPlayers) { s_playerCurrentMenuOffset[client]+=TOP_PANEL_SIZE; }
				showTopPanelTimer(menu, client);
			}
			default:
				PrintToConsole(0, "item: %d", item);
		}		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public Action:showTopPanelTimer(Handle:timer, any:client) {	
	// check if other menu is already opened to preserve e.g. votes
	if ((!IsClientInGame(client)) || GetConVarBool(s_silentMode)) {
		return Plugin_Stop;
	}  
	if (GetClientMenu(client)!=MenuSource_None) {
		return Plugin_Continue;
	}
	
	new String:stringBuf[MAX_LINE_WIDTH];
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Player Ranking");
		
	new String:tmpBufId[RP_SIZE_ID];
	new String:tmpBufName[MAX_NAME_LEN];
	new points;
	DrawPanelText(panel, "  ");
	for(new i = s_playerCurrentMenuOffset[client]; i < s_totalAmountOfPlayers && i<s_playerCurrentMenuOffset[client]+TOP_PANEL_SIZE; i++)
	{
		GetArrayString(s_rankIds, GetArrayCell(s_rankPoints, i, RANK_ARRAY_IDX_ID_KEY), tmpBufId, RP_SIZE_ID);
		KvRewind(s_kvStatsDB);
		if(KvJumpToKey(s_kvStatsDB, tmpBufId))
		{
			KvGetString(s_kvStatsDB, "name", tmpBufName, MAX_NAME_LEN, "");
		} else {
			Format(tmpBufName, 30, "err");
		}
		points=GetArrayCell(s_rankPoints, i, RANK_ARRAY_IDX_POINTS);
		Format(stringBuf, MAX_LINE_WIDTH, "%s%d. %s%d  %4.2f  %s", 
			(i<9) ? "    " : (i<99) ? "  " : "" , i+1, 
			(points<1000) ? "    " : (points<10000) ? "  " : ""  , points ,
			calcKpd(KvGetNum(s_kvStatsDB, "kills", 0), KvGetNum(s_kvStatsDB, "death", 0)), tmpBufName);
		DrawPanelText(panel, stringBuf);
	}
	
	DrawPanelText(panel, "  ");
	SetPanelCurrentKey(panel, 8);
	Format(stringBuf, MAX_LINE_WIDTH, "%T", "Back", LANG_SERVER);
	DrawPanelItem(panel, stringBuf);
	SetPanelCurrentKey(panel, 9);
	Format(stringBuf, MAX_LINE_WIDTH, "%T", "Next", LANG_SERVER);
	DrawPanelItem(panel, stringBuf);
	SetPanelCurrentKey(panel, 0);
	Format(stringBuf, MAX_LINE_WIDTH, "%T", "Exit", LANG_SERVER);
	DrawPanelItem(panel, stringBuf);
	
	SendPanelToClient(panel, client, TopMenuHandler, PANEL_SHOW_TIME_MANUAL );
 
	CloseHandle(panel);
	return Plugin_Stop;
}


public Action:showScorePanelCmd(client, args) {
	if (GetConVarBool(s_silentMode)) { return; }
	s_playerCurrentMenuOffset[client]=0;
	CreateTimer(0.6, showScorePanelTimer, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public ScoreMenuHandler(Handle:menu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		switch (item) {
			case 8:
			{
				// Back
				if (s_playerCurrentMenuOffset[client]>TOP_PANEL_SIZE) { s_playerCurrentMenuOffset[client]-=TOP_PANEL_SIZE; } else { s_playerCurrentMenuOffset[client]=0; }
				showScorePanelTimer(menu, client);
			}
			case 9:
			{
				//Next
				if (s_playerCurrentMenuOffset[client]+TOP_PANEL_SIZE<s_scoreTableSize) { s_playerCurrentMenuOffset[client]+=TOP_PANEL_SIZE; }
				showScorePanelTimer(menu, client);
			}
			default:
				PrintToConsole(0, "item: %d", item);
		}		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public Action:showScorePanelTimer(Handle:timer, any:client) {	
	
	// check if other menu is already opened to preserve e.g. votes
	if ((!IsClientInGame(client)) || GetConVarBool(s_silentMode)) {
		return Plugin_Stop;
	}  
	if (GetClientMenu(client)!=MenuSource_None) {
		return Plugin_Continue;
	}
	
	new String:stringBuf[MAX_LINE_WIDTH];
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Scoreboard");
		
	new String:tmpBufName[MAX_NAME_LEN];
	new curPos;
	new curClient;
	new curTableIdx;
	DrawPanelText(panel, "  ");
	for(new i = s_playerCurrentMenuOffset[client]; i < s_scoreTableSize && i<TOP_PANEL_SIZE+s_playerCurrentMenuOffset[client]; i++)
	{
		curTableIdx=s_scoreTableSize-1-i;
		curPos=GetArrayCell(s_scoreTable, curTableIdx, 0);
		curClient=GetArrayCell(s_scoreTable, curTableIdx, 1);
		if (curPos>0 && isValidPlayer(curClient)) {
			GetClientName(curClient, tmpBufName, MAX_NAME_LEN);
			Format(stringBuf, MAX_LINE_WIDTH, "%s%d. %s%d  %4.2f  %s", 
				(curPos<10) ? "    " : (curPos<100) ? "  " : "" , curPos, 
				(s_playerPoints[curClient]<1000) ? "    " : (s_playerPoints[curClient]<10000) ? "  " : ""  , s_playerPoints[curClient] , 
				calcKpd(s_playerKills[curClient], s_playerDeaths[curClient]), tmpBufName);
			DrawPanelText(panel, stringBuf);
		} else {DrawPanelText(panel, "---");}
	}
	
	DrawPanelText(panel, "  ");
	SetPanelCurrentKey(panel, 8);
	Format(stringBuf, MAX_LINE_WIDTH, "%T", "Back", LANG_SERVER);
	DrawPanelItem(panel, stringBuf);
	SetPanelCurrentKey(panel, 9);
	Format(stringBuf, MAX_LINE_WIDTH, "%T", "Next", LANG_SERVER);
	DrawPanelItem(panel, stringBuf);
	SetPanelCurrentKey(panel, 0);
	Format(stringBuf, MAX_LINE_WIDTH, "%T", "Exit", LANG_SERVER);
	DrawPanelItem(panel, stringBuf);

	
	SendPanelToClient(panel, client, ScoreMenuHandler, PANEL_SHOW_TIME_MANUAL );
 
	CloseHandle(panel);
	return Plugin_Stop;
}

	
public Action:showNextPanelCmd(client, args) {	
	if (GetConVarBool(s_silentMode)) { return; }
	s_playerCurrentMenuOffset[client]=s_playerRank[client]-(NEXT_PANEL_RANGE/2)-1;
	CreateTimer(0.1, showNextPanelTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public Action:showNextPanelTimer(Handle:timer, any:client) {	

	// check if other menu is already opened to preserve e.g. votes
	if ((!IsClientInGame(client)) || GetConVarBool(s_silentMode)) {
		return Plugin_Stop;
	}  
	if (GetClientMenu(client)!=MenuSource_None) {
		return Plugin_Continue;
	}
		
	new String:stringBuf[MAX_LINE_WIDTH];
	new String:deltaStringBuf[14];
	new Handle:panel = CreatePanel();

	if (s_playerCurrentMenuOffset[client]+NEXT_PANEL_RANGE>=s_totalAmountOfPlayers) {s_playerCurrentMenuOffset[client]=s_totalAmountOfPlayers-NEXT_PANEL_RANGE;}
	if (s_playerCurrentMenuOffset[client]<0) {s_playerCurrentMenuOffset[client]=0;}
	new endPos = s_playerCurrentMenuOffset[client]+NEXT_PANEL_RANGE;
	if (endPos>s_totalAmountOfPlayers) { endPos=s_totalAmountOfPlayers;}
	
	new String:tmpBufId[RP_SIZE_ID];
	new String:tmpBufName[MAX_NAME_LEN];
	
	new points;
	new deltaPoints;
	for(new i = s_playerCurrentMenuOffset[client]; i<endPos; i++)
	{
		GetArrayString(s_rankIds, GetArrayCell(s_rankPoints, i, RANK_ARRAY_IDX_ID_KEY), tmpBufId, RP_SIZE_ID);
		KvRewind(s_kvStatsDB);
		if(KvJumpToKey(s_kvStatsDB, tmpBufId))
		{
			KvGetString(s_kvStatsDB, "name", tmpBufName, MAX_NAME_LEN, "");
		} else {
			Format(tmpBufName, 30, "err");
		}
		points=GetArrayCell(s_rankPoints, i, RANK_ARRAY_IDX_POINTS);
		deltaPoints=GetArrayCell(s_rankPoints, s_playerRank[client]-1, RANK_ARRAY_IDX_POINTS)-points;
		if (deltaPoints==0) {
			Format(deltaStringBuf, 14, "       -  ");
		} else {
			Format(deltaStringBuf, 14, "%s%d",	(deltaPoints<-1000)	? " " : 
												(deltaPoints<-100)	? "   " :
												(deltaPoints<-10)	? "     " :
												(deltaPoints<0)		? "       " :
												(deltaPoints<10)	? "        " :
												(deltaPoints<100)	? "      " :												
												(deltaPoints<1000) 	? "    " : 
												(deltaPoints<10000) ? "  " : 
																		  "", deltaPoints );
		 }
		Format(stringBuf, MAX_LINE_WIDTH, "%s%d. %s%d  %s    %s", (i<9) ? "    " : (i<99) ? "  " : "" , i+1, (points<1000) ? "    " : (points<10000) ? "  " : ""  , points , deltaStringBuf, tmpBufName);
		DrawPanelText(panel, stringBuf);
	}
	
	DrawPanelText(panel, "  ");
	SetPanelCurrentKey(panel, 8);
	Format(stringBuf, MAX_LINE_WIDTH, "%T", "Back", LANG_SERVER);
	DrawPanelItem(panel, stringBuf);
	SetPanelCurrentKey(panel, 9);
	Format(stringBuf, MAX_LINE_WIDTH, "%T", "Next", LANG_SERVER);
	DrawPanelItem(panel, stringBuf);
	SetPanelCurrentKey(panel, 0);
	Format(stringBuf, MAX_LINE_WIDTH, "%T", "Exit", LANG_SERVER);
	DrawPanelItem(panel, stringBuf);
	
	SendPanelToClient(panel, client, NextPanelHandler, PANEL_SHOW_TIME_MANUAL );
 
	CloseHandle(panel);
	return Plugin_Stop;
}
public NextPanelHandler(Handle:menu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		switch (item) {
			case 8:
			{
				// Back
				if (s_playerCurrentMenuOffset[client]>NEXT_PANEL_RANGE) { s_playerCurrentMenuOffset[client]-=NEXT_PANEL_RANGE; } else { s_playerCurrentMenuOffset[client]=0; }
				showNextPanelTimer(menu, client);
			}
			case 9:
			{
				//Next
				if (s_playerCurrentMenuOffset[client]+NEXT_PANEL_RANGE<s_totalAmountOfPlayers) { s_playerCurrentMenuOffset[client]+=NEXT_PANEL_RANGE; }
				showNextPanelTimer(menu, client);
			}
			default:
				PrintToConsole(0, "item: %d", item);
		}		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


public Action:showRankPanelCmd(client, args) 
{
	if (GetConVarBool(s_silentMode)) { return; }
	showRankPanel(client, PANEL_SHOW_TIME_MANUAL);
}
public showRankPanel(client, time) 
{
	new Handle:pack;
	CreateDataTimer(0.1, showRankPanelTimer, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(pack, client);
	WritePackCell(pack, time);
}
public Action:showRankPanelTimer(Handle:timer, Handle:pack) {	
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new time = ReadPackCell(pack);
	
	// check if other menu is already opened to preserve e.g. votes
	if ((!IsClientInGame(client)) || GetConVarBool(s_silentMode)) {
		return Plugin_Stop;
	}  
	if (GetClientMenu(client)!=MenuSource_None) {
		return Plugin_Continue;
	}

	new String:stringBuf[MAX_LINE_WIDTH];
	new Handle:panel = CreatePanel();

	Format(stringBuf, MAX_LINE_WIDTH, " - %T", "Total", LANG_SERVER);
	DrawPanelItem(panel, stringBuf);
	
	if (s_playerRank[client]>0) {
		Format(stringBuf, MAX_LINE_WIDTH, "   %T", "Position <n> of <m>", LANG_SERVER, s_playerRank[client], s_totalAmountOfPlayers);
		DrawPanelText(panel,stringBuf);
	}

	Format(stringBuf, MAX_LINE_WIDTH, "   %d %T", s_playerPoints[client], "points", LANG_SERVER);
	DrawPanelText(panel,stringBuf);
	
	Format(stringBuf, MAX_LINE_WIDTH, "   %d:%d %T (%4.2f)", s_playerKills[client], s_playerDeaths[client], "frags", LANG_SERVER, calcKpd(s_playerKills[client], s_playerDeaths[client]));
	DrawPanelText(panel,stringBuf);

	// calc conn time
	new String:dateBuf[MAX_LINE_WIDTH];
	formatConTime(s_playerConTime[client], dateBuf, MAX_LINE_WIDTH);
	Format(stringBuf, MAX_LINE_WIDTH, "   %s", dateBuf);
	DrawPanelText(panel,stringBuf);
	
	new String:timeBuf[32];
	FormatTime(timeBuf, 32, NULL_STRING, s_playerFirstConTimestamp[client]);
	Format(stringBuf, MAX_LINE_WIDTH, "   %T: %s", "first", LANG_SERVER, timeBuf);
	DrawPanelText(panel,stringBuf);
	
	DrawPanelText(panel," "); 
	Format(stringBuf, MAX_LINE_WIDTH, " - %T", "Session", LANG_SERVER);
	DrawPanelItem(panel, stringBuf);
	
	if (s_playerRank[client]>0 && s_playerRankAtSesStart[client]>0) {
		new deltaPos = s_playerRankAtSesStart[client] - s_playerRank[client];
		Format(stringBuf, MAX_LINE_WIDTH, "   %s%d %T", (deltaPos>0) ? "+" : "", deltaPos, "positions", LANG_SERVER);
		DrawPanelText(panel,stringBuf);
	}
	
	Format(stringBuf, MAX_LINE_WIDTH, "   %d %T", s_playerPoints[client]-s_playerPointsAtSesStart[client], "points", LANG_SERVER);
	DrawPanelText(panel,stringBuf);
	
	Format(stringBuf, MAX_LINE_WIDTH, "   %d:%d %T (%4.2f)", 
		s_playerKills[client]-s_playerKillsAtSesStart[client], s_playerDeaths[client]-s_playerDeathsAtSesStart[client], 
		"frags", LANG_SERVER,
		calcKpd(s_playerKills[client]-s_playerKillsAtSesStart[client], s_playerDeaths[client]-s_playerDeathsAtSesStart[client]));
	DrawPanelText(panel,stringBuf);

	// calc conn time
	formatConTime(s_playerConTime[client]-s_playerConTimeAtSesStart[client], dateBuf, MAX_LINE_WIDTH);
	Format(stringBuf, MAX_LINE_WIDTH, "   %s", dateBuf);
	DrawPanelText(panel,stringBuf);
	
	SendPanelToClient(panel, client, EmptyPanelHandler, time );
 
	CloseHandle(panel);
	return Plugin_Stop;
}
public EmptyPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}


public showPrefMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption) {
		PrintToConsole(0,"CookieMenuAction_SelectOption: %d, %s", client, buffer);
		createAndShowPrefMenuInternal(client);
	} 
	else if (action == CookieMenuAction_DisplayOption) {
		PrintToConsole(0,"CookieMenuAction_DisplayOption: %d, %s", client, buffer);
	} else {
		PrintToConsole(0,"CookieMenuAction_???: %d, %d, %s", client, action, buffer);
	}
	
}

createAndShowPrefMenuInternal(client)
{
	if(client>0 && client<=MaxClients && IsClientConnected(client))
	{
		new String:MenuItem[40];
		new Handle:prefmenu = CreateMenu(PrefMenuHandler);
		Format(MenuItem, sizeof(MenuItem), "%T", "Configure HStats", LANG_SERVER);
		SetMenuTitle(prefmenu, MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%T: %T", "Automatic Display", LANG_SERVER, s_settAutoShow[client] == SETT_AUTOSHOW_OFF ? "OFF" : s_settAutoShow[client] == SETT_AUTOSHOW_START ? "Round Start" : "Round End", LANG_SERVER);
		AddMenuItem(prefmenu, "auto_show", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%T: %T", "Console Messages", LANG_SERVER, s_settMsgDisplay[client] == 1 ? "ON" : "OFF", LANG_SERVER);
		AddMenuItem(prefmenu, "cons_msg", MenuItem);
		DisplayMenu(prefmenu, client, MENU_TIME_FOREVER);
	}
}


public PrefMenuHandler(Handle:prefmenu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		new String:buffer[3];
		new String:menuItem[10];
		GetMenuItem(prefmenu, item, menuItem, sizeof(menuItem));
		if (StrEqual(menuItem, "auto_show")) // Auto display 
		{
			if (s_settAutoShow[client] == SETT_AUTOSHOW_OFF) { s_settAutoShow[client] = SETT_AUTOSHOW_START; }
			else if (s_settAutoShow[client] == SETT_AUTOSHOW_START) { s_settAutoShow[client] = SETT_AUTOSHOW_END; }
			else {s_settAutoShow[client] = SETT_AUTOSHOW_OFF; }
			
			Format(buffer, sizeof(buffer), "%d", s_settAutoShow[client]);
			SetClientCookie(client, s_autoShowCookie, buffer); 
			createAndShowPrefMenuInternal(client);
		}
		if (StrEqual(menuItem, "cons_msg")) // Console Messages
		{
			if (s_settMsgDisplay[client] == 0) { s_settMsgDisplay[client] = 1; } else { s_settMsgDisplay[client] = 0; }
			
			Format(buffer, sizeof(buffer), "%d", s_settMsgDisplay[client]);
			SetClientCookie(client, s_textDisplayCookie, buffer); 
			createAndShowPrefMenuInternal(client);
		}
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(prefmenu);
	}
}





public Action:consoleDbgCmd(client, args)
{
	
	new String:tmpBufId[RP_SIZE_ID];
	new String:nameBuf[MAX_NAME_LEN] = "";
	new dbPoints=0;
	new currentTime=GetTime();
	new lastConnTime;
	new inactiveTime;
	
	PrintToConsole(client, "Plugin is in %s mode", (s_gameMode==GAMEMODE_CSS) ? "CS:S" : (s_gameMode==GAMEMODE_CSGO) ? "CS:GO" : "GENERIC");
	PrintToConsole(client, "");
	
	PrintToConsole(client,"Rank cache:");
	for(new i = 0; i < s_totalAmountOfPlayers; i++)
	{
		new rankIdIndex=GetArrayCell(s_rankPoints, i, RANK_ARRAY_IDX_ID_KEY);
		if (rankIdIndex>=0 && rankIdIndex<s_totalAmountOfPlayers)
		{
			GetArrayString(s_rankIds, rankIdIndex, tmpBufId, RP_SIZE_ID);
			KvRewind(s_kvStatsDB);
			if(KvJumpToKey(s_kvStatsDB, tmpBufId))
			{
				KvGetString(s_kvStatsDB, "name", nameBuf, MAX_NAME_LEN, "");
				dbPoints = KvGetNum(s_kvStatsDB, "points", 0);
			} else {
				Format(nameBuf, 30, "--ERR--");
			}
			lastConnTime = KvGetNum(s_kvStatsDB, "last_conn", currentTime);
			inactiveTime = (currentTime-lastConnTime)/(60*60*24);
			PrintToConsole(client, "%d: %d [%d]; %s; %s [%d days]", i+1, GetArrayCell(s_rankPoints, i, RANK_ARRAY_IDX_POINTS), dbPoints, tmpBufId, nameBuf, inactiveTime);
		} else {
			PrintToConsole(client, "Corrupted rank id index at position %d (%d, %d)", i+1, rankIdIndex, GetArrayCell(s_rankPoints, i, RANK_ARRAY_IDX_POINTS));
		}
	}
	PrintToConsole(client,"");
	
	PrintToConsole(client,"Scoreboard:");
	new curPos;
	new curId;
	for(new i = 0; i<MAXPLAYERS ; i++)
	{
		curPos=GetArrayCell(s_scoreTable, i, 0);
		curId=GetArrayCell(s_scoreTable, i, 1);
		
		if (curPos>0 && isValidPlayer(curId)) {
			nameBuf="";
			GetClientName(curId, nameBuf, MAX_NAME_LEN);
		} else {
			nameBuf="---";
		}
		PrintToConsole(client,"%s: Pos %d, ID %d", nameBuf, curPos, curId);
	}
	PrintToConsole(client,"Scoretable size: %d", s_scoreTableSize);
	
	PrintToConsole(client,"");
	PrintToConsole(client,"In-game players:");
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i))
		{	
			if (!IsFakeClient(i)) {
				new String:steamId[20];
				GetClientAuthString(i, steamId, 20);
				nameBuf="";
				GetClientName(i, nameBuf, MAX_NAME_LEN);
				GetArrayString(s_rankIds, GetArrayCell(s_rankPoints, s_playerRank[i]-1, RANK_ARRAY_IDX_ID_KEY), tmpBufId, RP_SIZE_ID);
				
				PrintToConsole(client,"%d: %s; Pos: %d, KPD: %4.2f(%4.2f), P:%d(%d)/%d K:%d(%d), D:%d(%d), S:%d(%d) T:%d(%d) [%s/%s]", i, nameBuf,  
					s_playerRank[i], calcKpd(s_playerKills[i], s_playerDeaths[i]), 
					calcKpd(s_playerKills[i]-s_playerKillsAtSesStart[i], s_playerDeaths[i]-s_playerDeathsAtSesStart[i]), 
					s_playerPoints[i], s_playerPoints[i]-s_playerPointsAtSesStart[i], GetArrayCell(s_rankPoints, s_playerRank[i]-1, RANK_ARRAY_IDX_POINTS),
					s_playerKills[i],s_playerKills[i]-s_playerKillsAtSesStart[i], 
					s_playerDeaths[i], s_playerDeaths[i]-s_playerDeathsAtSesStart[i], 
					s_playerSuicides[i],s_playerSuicides[i]-s_playerSuicidesAtSesStart[i], 
					s_playerConTime[i]/60,(s_playerConTime[i]-s_playerConTimeAtSesStart[i])/60, 
					steamId, tmpBufId);
			} else {
				PrintToConsole(client, "%d: Fake client", i);
			}
		}
	}

	KvRewind(s_kvStatsDB);
	new db1AmountOfPlayers=0;
	if (KvGotoFirstSubKey(s_kvStatsDB)) { 
		db1AmountOfPlayers=1;
		while (KvGotoNextKey(s_kvStatsDB)) { db1AmountOfPlayers++; }
	}
	KvRewind(s_kvStatsDB);
	
	KvRewind(s_kvStatsDB2);
	new db2AmountOfPlayers=0;
	if (KvGotoFirstSubKey(s_kvStatsDB2)) { 
		db2AmountOfPlayers=1;
		while (KvGotoNextKey(s_kvStatsDB2)) { db2AmountOfPlayers++; }
	}
	KvRewind(s_kvStatsDB2);
		
	PrintToConsole(client,"");
	PrintToConsole(client,"Max clients: %d", GetMaxClients());
	PrintToConsole(client,"Players in rank cache: %d", s_totalAmountOfPlayers);
	PrintToConsole(client,"Database size: DB1: %d, DB2: %d", db1AmountOfPlayers, db2AmountOfPlayers);
	
	return Plugin_Handled;
}

public Action:consoleAdmCmd(client, args)
{	
	new bool:fail=true;
	new String:argBuf[20]="";
	if (args>0)
	{
		GetCmdArg(1, argBuf, 20);
		fail=false;
	} 
	if (!fail) {
		if (strcmp(argBuf,"reset_scores")==0)
		{
			resetScore(false);
		} 
		else if (strcmp(argBuf,"reset_all")==0)
		{
			resetScore(true);
		} 
		else
		{
			PrintToConsole(client,"valid parameters: ");
			PrintToConsole(client,"	reset_scores: erases points, kills, deaths");
			PrintToConsole(client,"	reset_all   : erases points, kills, deaths and connection time");
		}
	}

	return Plugin_Handled;
}


public Action:consoleStatsCmd(client, args)
{
	new String:nameBuf[MAX_NAME_LEN] = "";
	new curPos;
	new curId;
	for(new i = s_scoreTableSize-1; i>=0 ; --i)
	{
		curPos=GetArrayCell(s_scoreTable, i, 0);
		curId=GetArrayCell(s_scoreTable, i, 1);
		
		if (curPos>0 && isValidPlayer(curId)) {
			nameBuf="";
			GetClientName(curId, nameBuf, MAX_NAME_LEN);
			PrintToConsole(client,"%s: Pos %d/%d, KPD: %4.2f(%4.2f), P:%d(%d) K:%d(%d), D:%d(%d), S:%d(%d), T:%d(%d)", nameBuf, 
				curPos, s_totalAmountOfPlayers,
				calcKpd(s_playerKills[curId], s_playerDeaths[curId]), 
				calcKpd(s_playerKills[client]-s_playerKillsAtSesStart[client], s_playerDeaths[client]-s_playerDeathsAtSesStart[client]), 
				s_playerPoints[curId], s_playerPoints[curId]-s_playerPointsAtSesStart[curId],
				s_playerKills[curId],s_playerKills[client]-s_playerKillsAtSesStart[client], 
				s_playerDeaths[curId], s_playerDeaths[client]-s_playerDeathsAtSesStart[client], 
				s_playerSuicides[curId],s_playerSuicides[curId]-s_playerSuicidesAtSesStart[curId],
				s_playerConTime[curId]/60,(s_playerConTime[curId]-s_playerConTimeAtSesStart[curId])/60);
		}
	}
	PrintToConsole(client,"%T: %d", "Players total", LANG_SERVER, s_totalAmountOfPlayers);
	
	return Plugin_Handled;
}



/****************************************************
 ****************************************************
 
				Helper
				
 ****************************************************
*****************************************************/

public bool:isValidPlayer(playerId)
{
	return (( playerId > 0 ) && ( playerId <= GetMaxClients()) && IsClientInGame(playerId) && !IsFakeClient(playerId));
}

	
public Float:getWeaponMultiplier(String:weapon[]) 
{
	if (s_gameMode == GAMEMODE_GENERIC) { return 1.0; }
		
	if (StrEqual("negev", weapon, false) || StrEqual("weapon_negev", weapon, false)) { return GetConVarFloat(s_csWeapMulNegev); } else
	if (StrEqual("p250", weapon, false) || StrEqual("weapon_p250", weapon, false)) { return GetConVarFloat(s_csWeapMulP250); } else
	if (StrEqual("hkp2000", weapon, false) || StrEqual("weapon_hkp2000", weapon, false)) { return GetConVarFloat(s_csWeapMulHkp2000); } else	
	if (StrEqual("tec9", weapon, false) || StrEqual("weapon_tec9", weapon, false)) { return GetConVarFloat(s_csWeapMulTec9); } else		
	if (StrEqual("mag7", weapon, false) || StrEqual("weapon_mag7", weapon, false)) { return GetConVarFloat(s_csWeapMulMag7); } else
	if (StrEqual("nova", weapon, false) || StrEqual("weapon_nova", weapon, false)) { return GetConVarFloat(s_csWeapMulNova); } else
	if (StrEqual("sawedoff", weapon, false) || StrEqual("weapon_sawedoff", weapon, false)) { return GetConVarFloat(s_csWeapMulSawedoff); } else
	if (StrEqual("bizon", weapon, false) || StrEqual("weapon_bizon", weapon, false)) { return GetConVarFloat(s_csWeapMulBizon); } else
	if (StrEqual("mp7", weapon, false) || StrEqual("weapon_mp7", weapon, false)){ return GetConVarFloat(s_csWeapMulMp7); } else
	if (StrEqual("mp9", weapon, false) || StrEqual("weapon_mp9", weapon, false)) { return GetConVarFloat(s_csWeapMulMp9); } else
	if (StrEqual("galilar", weapon, false) || StrEqual("weapon_galilar", weapon, false)) { return GetConVarFloat(s_csWeapMulGalilar); } else
	if (StrEqual("sg556", weapon, false) || StrEqual("weapon_sg556", weapon, false)) { return GetConVarFloat(s_csWeapMulSg556); } else	
	if (StrEqual("ssg08", weapon, false) || StrEqual("weapon_ssg08", weapon, false)) { return GetConVarFloat(s_csWeapMulSsg08); } else
	if (StrEqual("scar20", weapon, false) || StrEqual("weapon_scar20", weapon, false)) { return GetConVarFloat(s_csWeapMulScar20); } else	
	if (StrEqual("incgrenade", weapon, false) || StrEqual("weapon_incgrenade", weapon, false)) { return GetConVarFloat(s_csWeapMulBurnGrenade); } else
	if (StrEqual("molotov", weapon, false) || StrEqual("weapon_molotov", weapon, false)) { return GetConVarFloat(s_csWeapMulBurnGrenade); } else
	if (StrEqual("inferno", weapon, false)) { return GetConVarFloat(s_csWeapMulBurnGrenade); } else
	if (StrEqual("decoy", weapon, false) || StrEqual("weapon_decoy", weapon, false)) { return GetConVarFloat(s_csWeapMulDecoy); } else
	if (StrEqual("taser", weapon, false) || StrEqual("weapon_taser", weapon, false)) { return GetConVarFloat(s_csWeapMulTaser); } else
	if (StrEqual("glock", weapon, false) || StrEqual("weapon_glock", weapon, false)) { return GetConVarFloat(s_csWeapMulGlock); } else 
	if (StrEqual("usp", weapon, false) || StrEqual("weapon_usp", weapon, false)) { return GetConVarFloat(s_csWeapMulUsp); } else 
	if (StrEqual("p228", weapon, false) || StrEqual("weapon_p228", weapon, false)) { return GetConVarFloat(s_csWeapMulP228); } else 
	if (StrEqual("deagle", weapon, false) || StrEqual("weapon_deagle", weapon, false)) { return GetConVarFloat(s_csWeapMulDeagle); } else 
	if (StrEqual("elite", weapon, false) || StrEqual("weapon_elite", weapon, false)) { return GetConVarFloat(s_csWeapMulElite); } else 
	if (StrEqual("fiveseven", weapon, false) || StrEqual("weapon_fiveseven", weapon, false)) { return GetConVarFloat(s_csWeapMulFiveseven); } else 
	if (StrEqual("m3", weapon, false) || StrEqual("weapon_m3", weapon, false)) { return GetConVarFloat(s_csWeapMulM3); } else 
	if (StrEqual("xm1014", weapon, false) || StrEqual("weapon_xm1014", weapon, false)) { return GetConVarFloat(s_csWeapMulXm1014); } else 
	if (StrEqual("galil", weapon, false) || StrEqual("weapon_galil", weapon, false)) { return GetConVarFloat(s_csWeapMulGalil); } else 
	if (StrEqual("ak47", weapon, false) || StrEqual("weapon_ak47", weapon, false)) { return GetConVarFloat(s_csWeapMulAk47); } else 
	if (StrEqual("scout", weapon, false) || StrEqual("weapon_scout", weapon, false)) { return GetConVarFloat(s_csWeapMulScout); } else 
	if (StrEqual("sg552", weapon, false) || StrEqual("weapon_sg552", weapon, false)) { return GetConVarFloat(s_csWeapMulSg552); } else 
	if (StrEqual("awp", weapon, false) || StrEqual("weapon_awp", weapon, false)) { return GetConVarFloat(s_csWeapMulAwp); } else 
	if (StrEqual("g3sg1", weapon, false) || StrEqual("weapon_g3sg1", weapon, false)) { return GetConVarFloat(s_csWeapMulG3sg1); } else 
	if (StrEqual("famas", weapon, false) || StrEqual("weapon_famas", weapon, false)) { return GetConVarFloat(s_csWeapMulFamas); } else 
	if (StrEqual("m4a1", weapon, false) || StrEqual("weapon_m4a1", weapon, false)) { return GetConVarFloat(s_csWeapMulM4a1); } else 
	if (StrEqual("aug", weapon, false) || StrEqual("weapon_aug", weapon, false)) { return GetConVarFloat(s_csWeapMulAug); } else 
	if (StrEqual("sg550", weapon, false) || StrEqual("weapon_sg550", weapon, false)) { return GetConVarFloat(s_csWeapMulSg550); } else 
	if (StrEqual("mac10", weapon, false) || StrEqual("weapon_mac10", weapon, false)) { return GetConVarFloat(s_csWeapMulMac10); } else 
	if (StrEqual("tmp", weapon, false) || StrEqual("weapon_tmp", weapon, false)) { return GetConVarFloat(s_csWeapMulTmp); } else 
	if (StrEqual("mp5navy", weapon, false) || StrEqual("weapon_mp5navy", weapon, false)) { return GetConVarFloat(s_csWeapMulMp5navy); } else 
	if (StrEqual("ump45", weapon, false) || StrEqual("weapon_ump45", weapon, false)) { return GetConVarFloat(s_csWeapMulUmp45); } else 
	if (StrEqual("p90", weapon, false) || StrEqual("weapon_p90", weapon, false)) { return GetConVarFloat(s_csWeapMulP90); } else 
	if (StrEqual("m249", weapon, false) || StrEqual("weapon_m249", weapon, false)) { return GetConVarFloat(s_csWeapMulM249); } else 
	if (StrEqual("flashbang", weapon, false) || StrEqual("weapon_flashbang", weapon, false)) { return GetConVarFloat(s_csWeapMulFlashbang); } else 
	if (StrEqual("hegrenade", weapon, false) || StrEqual("weapon_hegrenade", weapon, false)) { return GetConVarFloat(s_csWeapMulHegrenade); } else 
	if (StrEqual("smokegrenade", weapon, false) || StrEqual("weapon_smokegrenade", weapon, false)) { return GetConVarFloat(s_csWeapMulSmokegrenade);	} else 
	if (StrEqual("knife", weapon, false) || StrEqual("weapon_knife", weapon, false)) { return GetConVarFloat(s_csWeapMulKnife); } else 
	if (StrEqual("weapon_c4", weapon, false)) { return 0.5; } else 
	{
		LogError("Unknown weapon %s", weapon);
		return 1.0;
	}
}
	
formatConTime(time, String:buffer[], maxSize) {
	new tSec=time%60; 
	new tMin= (time/60)%60; 
	new tHours=((time/60)/60)%24;
	new tDays=((time/60)/60)/24;
	if (tDays>0)
	{
		Format(buffer, maxSize, "%dd %dh %dm", tDays, tHours, tMin);
	} else {
		Format(buffer, maxSize, "%dh %dm %ds", tHours, tMin, tSec);
	}
}

public Float:calcKpd(kills, deaths) 
{
	new calc_kills=kills;
	new calc_deaths=deaths;
	if (deaths==0) { calc_deaths=1; }
	return float(calc_kills*100/calc_deaths)/100.0;
}

public flushAllClientCaches() 
{
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(isValidPlayer(i)) { flushClientCache(i); }
	}
}
public flushClientCache(client)
{
	new String:steamId[20];
	GetClientAuthString(client, steamId, 20);
	KvRewind(s_kvStatsDB);
	if(KvJumpToKey(s_kvStatsDB, steamId))
	{
		new currentTime=GetTime();
		s_playerConTime[client]+=(currentTime-s_playerConTimestamp[client]);
		s_playerConTimestamp[client]=currentTime;
		KvSetNum(s_kvStatsDB, "kills", s_playerKills[client]);
		KvSetNum(s_kvStatsDB, "death", s_playerDeaths[client]);
		KvSetNum(s_kvStatsDB, "suicides", s_playerSuicides[client]);
		KvSetNum(s_kvStatsDB, "points", s_playerPoints[client]);
		KvSetNum(s_kvStatsDB, "conn_time", s_playerConTime[client]);
	} else {
		LogError("Database inconsistency, can not flush player %d to data set %s", client, steamId);
		PrepareClient(client, true); // try to repair client registry
	}
}

purgeClientRecord(index)
{
	if (( index > 0 ) && ( index <= MAXPLAYERS)) {
		s_playerKills[index]=0;
		s_playerKillsAtSesStart[index]=0;
		s_playerDeaths[index]=0;
		s_playerDeathsAtSesStart[index]=0;
		s_playerSuicides[index]=0;
		s_playerSuicidesAtSesStart[index]=0;
		s_playerPoints[index]=0;
		s_playerPointsAtSesStart[index]=0;
		s_playerRank[index]=0;
		s_playerRankAtSesStart[index]=0;
		s_playerConTime[index]=0;
		s_playerConTimeAtSesStart[index]=0;
		s_playerFirstConTimestamp[index]=0;
		s_playerConTimestamp[index]=0;
		s_playerKillsInARow[index]=0;
		Format(s_playerWeapon[index], MAX_WEAPON_NAME_LEN, "");
		s_playerCurrentMenuOffset[index]=0;
	} else {
		LogError("Tried to purge invalid player record %d", index);
	}
}

loadClientCookies(client)
{
	if (s_hasClientPrefs) {
		decl String:buffer[3];

		GetClientCookie(client, s_autoShowCookie, buffer, sizeof(buffer));
		if(!StrEqual(buffer, ""))
		{
			s_settAutoShow[client] = StringToInt(buffer);
		} else {
			s_settAutoShow[client] = SETT_AUTOSHOW_DEFAULT;
		}
		
		GetClientCookie(client, s_textDisplayCookie, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
			s_settMsgDisplay[client] = StringToInt(buffer);
		} else {
			s_settMsgDisplay[client] = SETT_MSG_DEFAULT;
		}
	} else {
		s_settAutoShow[client] = SETT_AUTOSHOW_DEFAULT;
		s_settMsgDisplay[client] = SETT_MSG_DEFAULT;
	}
}

bool:isScoringEnabled()
{
	return ((GetClientCount(true)>=GetConVarInt(s_minPlayersForScoring)) && s_teamHasMembersT && s_teamHasMembersCT && !s_isWarmup);
}





//    ********************************************
//    ********************************************
//
//    *************   Database    ****************
// 
//    ********************************************
//    ********************************************

public Action:retryPrepareClient(Handle:timer, any:client) {
	if(isValidPlayer(client)) {
		new String:name[20];
		GetClientName(client, name, 20);
		LogError("Retrying to prepare client %d [%s]", client, name);
		PrepareClient(client, true); 
	}
}

PrepareClient(client, bool:force=false)
{
	if(isValidPlayer(client))
	{
		if (s_hasClientPrefs && AreClientCookiesCached(client)) { loadClientCookies(client); } // if not, this is done in OnClientCookiesCached-callback
	
		new String:steamId[20];
		if (!GetClientAuthString(client, steamId, 20)) {
			new String:name[20];
			GetClientName(client, name, 20);
			LogError("prepare: client %d [%s] misses SteamId", client, name);
			CreateTimer(0.5, retryPrepareClient, client);
			return;
		}
		
		// check, if client is already in the cache
		if (force==false && s_playerRank[client]>0 && s_playerRank[client]<=s_totalAmountOfPlayers) {
			new idIndex = GetArrayCell(s_rankPoints, s_playerRank[client]-1, 1);
			new String:cSteamId[20];
			GetArrayString(s_rankIds, idIndex, cSteamId, 20);
			
			if (strcmp(steamId, cSteamId)==0) {
				return;
			} 
		}
		
		new bool:cacheDirty=true;
		
		new currentTime=GetTime();
		new String:nameBuf[MAX_NAME_LEN] = "";
		GetClientName(client, nameBuf, MAX_NAME_LEN);
		
		KvRewind(s_kvStatsDB);
		if(!KvJumpToKey(s_kvStatsDB, steamId)) // do nothing if player is in main DB
		{ 
			KvRewind(s_kvStatsDB2);
			if(KvJumpToKey(s_kvStatsDB2, steamId)) // move if player is in DB2
			{
				moveCurrentPlayerKey(s_kvStatsDB2, s_kvStatsDB);
				KvRewind(s_kvStatsDB);
				if(!KvJumpToKey(s_kvStatsDB, steamId)) {
					LogError("PrepareClient failed to move inactive player %s to current DB", steamId);
				}
				s_kvStatsDB2dirtyFlag=true; // will cause DB2 to be written on next map end
			} 
			else // create new player if neither found in any DB 
			{
				if(!KvJumpToKey(s_kvStatsDB, steamId, true)) {
					LogError("PrepareClient failed to create new player %s in current DB", steamId);
				} else {
					KvSetNum(s_kvStatsDB, "first_conn", currentTime);
					KvSetNum(s_kvStatsDB, "conn_time", 0);
					KvSetNum(s_kvStatsDB, "kills", 0);
					KvSetNum(s_kvStatsDB, "death", 0);
					KvSetNum(s_kvStatsDB, "suicides", 0);
					KvSetNum(s_kvStatsDB, "points", POINTS_NEW_PLAYER);
				}
			}
			KvRewind(s_kvStatsDB2);
		} else {
			cacheDirty=false; // players in main db are already cached
		}
		
		KvSetNum(s_kvStatsDB, "last_conn", currentTime);
		KvSetString(s_kvStatsDB, "name", nameBuf);
		
		s_playerKills[client] = KvGetNum(s_kvStatsDB, "kills", 0);
		s_playerDeaths[client] = KvGetNum(s_kvStatsDB, "death", 0);
		s_playerSuicides[client] = KvGetNum(s_kvStatsDB, "suicides", 0);
		s_playerPoints[client] = KvGetNum(s_kvStatsDB, "points", POINTS_NEW_PLAYER);
		s_playerConTime[client] = KvGetNum(s_kvStatsDB, "conn_time", 0);
		s_playerFirstConTimestamp[client]=KvGetNum(s_kvStatsDB, "first_conn", currentTime);

		if (s_playerPoints[client]<1) {
			LogError("Player %s has a record of %d points in DB, resetting to minimum of 1", nameBuf, s_playerPoints[client]);
			s_playerPoints[client]=1;
		}
		
		KvRewind(s_kvStatsDB);
		
		s_playerConTimestamp[client]=currentTime;
		s_playerPointsAtSesStart[client]=s_playerPoints[client];
		s_playerKillsAtSesStart[client] = s_playerKills[client];
		s_playerDeathsAtSesStart[client] = s_playerDeaths[client];
		s_playerSuicidesAtSesStart[client] = s_playerSuicides[client];
		s_playerConTimeAtSesStart[client] = s_playerConTime[client];
		s_playerRank[client] = 0;
		s_playerKillsInARow[client]=0;
		
		s_settAutoShow[client]=SETT_AUTOSHOW_DEFAULT;
		s_settMsgDisplay[client]=SETT_MSG_DEFAULT;

		if (cacheDirty) { 
			updateRankCache(); 
		} else {
			updateClientRankFromCache(client);
		}
		s_playerRankAtSesStart[client] = s_playerRank[client];
		
		updateScoreBoard();
	}
}

flushDataBaseToFile(bool:force=false) {
	KvRewind(s_kvStatsDB);
	KeyValuesToFile(s_kvStatsDB, s_filenameBufferDB);
	if (s_kvStatsDB2dirtyFlag || force) { 
		KvRewind(s_kvStatsDB2);
		KeyValuesToFile(s_kvStatsDB2, s_filenameBufferDB2);
		s_kvStatsDB2dirtyFlag=false;
	} 
}

public Action:doDbMaintenanceTimed(Handle:timer, any:value) {
	doDbMaintenance(); 
}
doDbMaintenance()
{
	LogMessage("Starting Database maintenance");
	new inactivePlayers=0;
	KvRewind(s_kvStatsDB);
	KvRewind(s_kvStatsDB2);
	new bool:currentItemNeedsCheck=KvGotoFirstSubKey(s_kvStatsDB);
	new currentTime=GetTime();
	new lastConnTime;
	new inactiveTime;
	new String:nameBuf[MAX_NAME_LEN] = "";
	new maxInactiveTime = GetConVarInt(s_maxInactiveTime);
	while ( currentItemNeedsCheck )
	{ 
		lastConnTime = KvGetNum(s_kvStatsDB, "last_conn", currentTime);
		inactiveTime = (currentTime-lastConnTime)/(60*60*24);
		if (inactiveTime>maxInactiveTime) {
			KvGetString(s_kvStatsDB, "name", nameBuf, MAX_NAME_LEN, "unnamed");
			LogMessage("inactive player found: %s (%d days)", nameBuf, inactiveTime);
			inactivePlayers++;
			currentItemNeedsCheck = moveCurrentPlayerKey(s_kvStatsDB, s_kvStatsDB2);
		} else {
			currentItemNeedsCheck = KvGotoNextKey(s_kvStatsDB); 
		}
	}
	KvRewind(s_kvStatsDB);
	KvRewind(s_kvStatsDB2);
	LogMessage("moved %d inactive players to secondary storage", inactivePlayers);
	if (inactivePlayers>0) { 
		flushDataBaseToFile(true);
		updateRankCache();
	} 
}

//returns true if source has been sucessfull traversed to a new key
bool:moveCurrentPlayerKey(Handle:source, Handle:dest) 
{
	new String:keyBuf[30] = "";
	new bool:result=false;
	
	KvGetSectionName(source, keyBuf, 30);
	
	KvRewind(dest);
	if (KvJumpToKey(dest, keyBuf, true))
	{
		new String:nameBuf[MAX_NAME_LEN];
		KvGetString(source, "name", nameBuf, MAX_NAME_LEN);
		KvSetString(dest, "name", nameBuf);
		KvSetNum(dest, "kills", KvGetNum(source, "kills"));
		KvSetNum(dest, "death", KvGetNum(source, "death"));
		KvSetNum(dest, "suicides", KvGetNum(source, "suicides"));
		KvSetNum(dest, "first_conn", KvGetNum(source, "first_conn"));
		KvSetNum(dest, "last_conn", KvGetNum(source, "last_conn"));
		KvSetNum(dest, "conn_time", KvGetNum(source, "conn_time"));
		KvSetNum(dest, "points", KvGetNum(source, "points", POINTS_NEW_PLAYER));
		if (KvDeleteThis(source)==1) {result=true;}
	}
	KvRewind(dest);
	return result;
}

reloadAllPlayers() {
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(isValidPlayer(i))
		{
			PrepareClient(i, true);
		}
	}
}

resetScore(bool:complete) {
	for(new i = 1; i <= MAXPLAYERS; i++) {
		s_playerPointsAtSesStart[i]=POINTS_NEW_PLAYER;
		s_playerPoints[i]=POINTS_NEW_PLAYER;
		s_playerKillsAtSesStart[i]=0;
		s_playerKills[i]=0;
		s_playerDeathsAtSesStart[i]=0;
		s_playerDeaths[i]=0;
		s_playerSuicidesAtSesStart[i]=0;
		s_playerSuicides[i]=0;
	}
	
	KvRewind(s_kvStatsDB);
	new bool:hasNextKey = KvGotoFirstSubKey(s_kvStatsDB);
	while (hasNextKey) 
	{
		KvSetNum(s_kvStatsDB, "kills", 0);
		KvSetNum(s_kvStatsDB, "death", 0);
		KvSetNum(s_kvStatsDB, "suicides", 0);
		KvSetNum(s_kvStatsDB, "points", POINTS_NEW_PLAYER);
		if (complete) {
			KvSetNum(s_kvStatsDB, "conn_time", 0);
		}
		hasNextKey = moveCurrentPlayerKey(s_kvStatsDB, s_kvStatsDB2);
	}
	KvRewind(s_kvStatsDB);
	
	KvRewind(s_kvStatsDB2);
	hasNextKey = KvGotoFirstSubKey(s_kvStatsDB2);
	while (hasNextKey) 
	{
		KvSetNum(s_kvStatsDB2, "kills", 0);
		KvSetNum(s_kvStatsDB2, "death", 0);
		KvSetNum(s_kvStatsDB2, "suicides", 0);
		KvSetNum(s_kvStatsDB2, "points", POINTS_NEW_PLAYER);
		if (complete) {
			KvSetNum(s_kvStatsDB2, "conn_time", 0);
		}
		hasNextKey = KvGotoNextKey(s_kvStatsDB2);
	}
	KvRewind(s_kvStatsDB2);
	
	flushDataBaseToFile(true);
	
	updateRankCache();
	reloadAllPlayers();
}




//    ********************************************
//    ********************************************
//
//    **************   Ranking    ****************
// 
//    ********************************************
//    ********************************************






new s_lock=0;
updateRankCache()
{
	if (s_lock++==0) {
		
		new String:tmpBuf[RP_SIZE_ID];
		
		// build unsorted list of points
		KvRewind(s_kvStatsDB);
		new totalAmountOfPlayers=0;
		new plrPoints=0;
		
		new bool:hasNextKey = KvGotoFirstSubKey(s_kvStatsDB);
		while (hasNextKey) 
		{
			if (totalAmountOfPlayers>=GetArraySize(s_rankPoints)) { 
				ResizeArray(s_rankPoints, GetArraySize(s_rankPoints)+50); 
				ResizeArray(s_rankIds, GetArraySize(s_rankPoints)+50); 
			}
			if (!KvGetSectionName(s_kvStatsDB, tmpBuf, RP_SIZE_ID)) {
				Format(tmpBuf, RP_SIZE_ID, "err");
			}
			SetArrayString(s_rankIds, totalAmountOfPlayers, tmpBuf);
			plrPoints=KvGetNum(s_kvStatsDB, "points", POINTS_NEW_PLAYER);
			if (plrPoints<1) { plrPoints=1; }
			SetArrayCell(s_rankPoints, totalAmountOfPlayers, plrPoints, RANK_ARRAY_IDX_POINTS);
			SetArrayCell(s_rankPoints, totalAmountOfPlayers, totalAmountOfPlayers , RANK_ARRAY_IDX_ID_KEY); // foreign key to s_rankIds table
			totalAmountOfPlayers++;
			hasNextKey = KvGotoNextKey(s_kvStatsDB);
		}
		s_totalAmountOfPlayers=totalAmountOfPlayers;
		
		// clear unused array cells
		for(new i = totalAmountOfPlayers; i < GetArraySize(s_rankPoints); i++) {
			SetArrayCell(s_rankPoints, i, -1000, RANK_ARRAY_IDX_POINTS);
			SetArrayCell(s_rankPoints, i, -1 , RANK_ARRAY_IDX_ID_KEY);
			SetArrayString(s_rankIds, i, "");
		}
		KvRewind(s_kvStatsDB);

		// sort the list by points
		SortADTArray(s_rankPoints,Sort_Descending, Sort_Integer);
		
		// find player positions in sorted list
		for(new i = 1; i <= GetMaxClients(); i++) {
			updateClientRankFromCache(i);
		}
		
		updateScoreBoard();
 
		s_lock=0;
	}
}
updateScoreBoard()
{	
	s_scoreTableSize=0;
	for(new i = 1; i<=MAXPLAYERS; i++) {
		// build scoreboard data
		if (isValidPlayer(i)) {
			SetArrayCell(s_scoreTable, i-1, s_playerRank[i], 0);
			SetArrayCell(s_scoreTable, i-1, i, 1); 
			if (s_playerRank[i]>0) { s_scoreTableSize++; }
		} else {
			SetArrayCell(s_scoreTable, i-1, 0, 0);
			SetArrayCell(s_scoreTable, i-1, 0, 1); 
		}
	}
	SortADTArray(s_scoreTable,Sort_Descending, Sort_Integer);
}

updateClientRankFromCache(client)
{
	if(isValidPlayer(client)) {	
		new String:steamId[20];
		if (!GetClientAuthString(client, steamId, 20)) {
			new String:name[20];
			GetClientName(client, name, 20);
			LogError("Can not calculate rank. Client %d (%s) misses auth string.", client, name);
			return;
		}
		
		s_playerRank[client]=0;	// mark position as invalid
		
		new tablePos = FindStringInArray(s_rankIds, steamId);
		if (tablePos>=0 && tablePos<s_totalAmountOfPlayers)
		{
			for (new j=0; j<s_totalAmountOfPlayers && s_playerRank[client]==0;j++) { 
				if (GetArrayCell(s_rankPoints, j, 1)==tablePos)	{
					s_playerRank[client]=j+1;
				}
			}
			if (s_playerRank[client]==0) {
				new String:name[20];
				GetClientName(client, name, 20);
				LogError("Rank can not be calculated for client %d [%s/%s]. Id table position %d not found in points table (size %d)", client, steamId, name, tablePos, s_totalAmountOfPlayers);
			}
		} else {
			new String:name[20];
			GetClientName(client, name, 20);
			LogError("Rank can not be calculated for client %d. Player %s [%s] is missing in DB", client, name, steamId);
		}
	} 
}

scalePoints (inPoints, team) {
	new scaledByPoints = inPoints * s_teamPoints[getOpposingTeamOf(team)] / s_teamPoints[team];
	new scaledBySize = inPoints * s_teamClientCount[getOpposingTeamOf(team)] / s_teamClientCount[team];
	
	new relativeScores[4]= {0,0,0,0};
	for (new i=0; i<MAX_RECORDED_RESULTS;i++)
	{
		relativeScores[s_lastResults[i]]++;
	}
	new scaledByScore = inPoints * (relativeScores[getOpposingTeamOf(team)]+3)/(relativeScores[team]+3); // value 3 is chosen by random, just not to take the first rounds into account too much
	
	new scaledPoints = (scaledByPoints + scaledBySize + scaledByScore) / 3;

	return scaledPoints; 
}

getOpposingTeamOf(team) {
	return (team==TEAM_T) ? TEAM_CT : TEAM_T;
}

grantClientPoints(client, points, String:logMessage[], String:playerMessage[]="", msgType=MSG_NONE) 
{
	if (isScoringEnabled() && points!=0 && isValidPlayer(client)) {
		s_playerPoints[client]+=points; 
		switch (msgType) 
		{
			case MSG_PUBLIC:
				PrintToSubscriberChats(playerMessage);
			case MSG_PRIVATE:
				PrintToSubscribedClientChat(client, playerMessage);
		}
		if (s_hasScoreLoggingEnabled) {
			new String:tmpName[20] = ""; GetClientName(client, tmpName, 20);
			LogMessage("SCORE: player %s got %d points for %s [%s]", tmpName, points, logMessage, playerMessage);
		}
		
		// no negative points allowed
		if (s_playerPoints[client]<1) {
			s_playerPoints[client]=1;
		}
	}
}

grantTeamPoints(team, points, String:logMessage[], String:playerMessage[]="", msgType=MSG_NONE) 
{
	if (isScoringEnabled() && points!=0) {
		if (s_hasScoreLoggingEnabled) {
			LogMessage("SCORE: team %s got %d points for %s [%s]", (team==TEAM_T) ? "TERR" : (team==TEAM_CT) ? "CT" : "ERR", points, logMessage, playerMessage);
		}
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(isValidPlayer(i))
			{	
				if (GetClientTeam(i)==team) { grantClientPoints(i, points, logMessage, playerMessage, MSG_NONE); }
			}
		}
		switch (msgType) 
		{
			case MSG_PUBLIC:
				PrintToSubscriberChats(playerMessage);
		}
	}
}