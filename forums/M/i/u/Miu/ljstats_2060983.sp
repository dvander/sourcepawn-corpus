#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <sdkhooks>
#include <smlib>
#include <morecolors>

//#define DEBUG
//#define LJSERV

#pragma semicolon 1

#define MIN(%0,%1) (%0 > %1 ? %1 : %0)
#define MAX(%0,%1) (%0 < %1 ? %1 : %0)

#define LJSTATS_VERSION "2.0.1"

#define LJTOP_DIR "configs/ljstats/"
#define LJTOP_FILE "ljtop.txt"
#define LJTOP_NUM_ENTRIES 50
#define LJSOUND_NUM 5
#define MAX_STRAFES 50
#define BHOP_TIME 0.3
#define STAMINA_RECHARGE_TIME 0.58579
#define SW_ANGLE_THRESHOLD 20.0
#define LJ_HEIGHT_DELTA_MIN -0.01	// Dropjump limit
#define LJ_HEIGHT_DELTA_MAX 1.5		// Upjump limit
#define CJ_HEIGHT_DELTA_MIN -0.01
#define CJ_HEIGHT_DELTA_MAX 1.5
#define WJ_HEIGHT_DELTA_MIN -0.01
#define WJ_HEIGHT_DELTA_MAX 1.5
#define BJ_HEIGHT_DELTA_MIN -2.0 // dynamic pls
#define BJ_HEIGHT_DELTA_MAX 2.0
#define LAJ_HEIGHT_DELTA_MIN -6.0
#define LAJ_HEIGHT_DELTA_MAX 0.0
#define HUD_HINT_SIZE 256

public Plugin:myinfo = 
{
	name = "ljstats",
	author = "Miu",
	description = "longjump stats",
	version = LJSTATS_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2060983"
}

enum PlayerState
{
	bool:bLJEnabled,
	bool:bHidePanel,
	bool:bHideBhopPanel,
	bool:bShowBhopStats,
	bool:bBeam,
	bool:bSound,
	bool:bBlockMode,
	nVerbosity,
	bool:bShowAllJumps,
	#if defined LJSERV
	bool:bShowPrestrafeHint,
	#endif
	
	Float:fBlockDistance,
	Float:vBlockNormal[2],
	Float:vBlockEndPos[3],
	bool:bFailedBlock,
	
	bool:bDuck,
	bool:bLastDuckState,
	bool:bSecondLastDuckState,
	
	JUMP_DIRECTION:JumpDir,
	ILLEGAL_JUMP_FLAGS:IllegalJumpFlags,
	
	JUMP_TYPE:LastJumpType,
	JUMP_TYPE:JumpType,
	Float:fLandTime,
	Float:fLastJumpHeightDelta,
	nBhops,
	
	bool:bOnGround,
	bool:bOnLadder,
	
	Float:fEdge,
	Float:vJumpOrigin[3],
	Float:fWJDropPre,
	Float:fPrestrafe,
	Float:fJumpDistance,
	Float:fHeightDelta,
	Float:fJumpHeight,
	Float:fSync,
	Float:fMaxSpeed,
	Float:fFinalSpeed,
	Float:fTrajectory,
	Float:fGain,
	Float:fLoss,
	
	STRAFE_DIRECTION:CurStrafeDir,
	nStrafes,
	STRAFE_DIRECTION:StrafeDir[MAX_STRAFES],
	Float:fStrafeGain[MAX_STRAFES],
	Float:fStrafeLoss[MAX_STRAFES],
	Float:fStrafeSync[MAX_STRAFES],
	nStrafeTicks[MAX_STRAFES],
	nStrafeTicksSynced[MAX_STRAFES],
	nTotalTicks,
	Float:fTotalAngle,
	Float:fSyncedAngle,
	
	bool:bStamina,
	nJumpTick,
	nLastAerialTick,
	
	Float:vLastOrigin[3],
	Float:vLastAngles[3],
	Float:vLastVelocity[3],
	
	String:strHUDHint[HUD_HINT_SIZE / 4], // string characters are stored as cells
	
	Float:fPersonalBest,
	
	nSpectators,
	nSpectatorTarget,
	
	GAP_SELECTION_MODE:GapSelectionMode,
	Float:vGapPoint1[3],
	LastButtons,
}

#define LJTOP_MIN_NUM_STATS_0 7
#define LJTOP_MIN_NUM_STATS_1 14
#define LJTOP_MAX_NUM_STATS 14 + 16 * 5
#define LJTOP_MAX_STRAFES 16

enum TopStats
{
	String:m_strName[64 / 4],
	String:m_strSteamID[32 / 4],
	Float:m_fDistance,
	Float:m_fPrestrafe,
	m_nStrafes, //
	Float:m_fSync,
	Float:m_fMaxSpeed,
	m_nTotalTicks,
	Float:m_fSyncedAngle,
	Float:m_fTotalAngle, //
	Float:m_fHeightDelta,
	Float:m_fBlockDistance,
	Float:m_fTrajectory,
	m_nTimestamp,
	
	STRAFE_DIRECTION:m_StrafeDir[LJTOP_MAX_STRAFES],
	Float:m_fStrafeGain[LJTOP_MAX_STRAFES],
	Float:m_fStrafeLoss[LJTOP_MAX_STRAFES],
	m_nStrafeTicks[LJTOP_MAX_STRAFES],
	Float:m_fStrafeSync[LJTOP_MAX_STRAFES],
}

enum ILLEGAL_JUMP_FLAGS
{
	IJF_NONE = 0,
	IJF_WORLD = 1 << 0,
	IJF_BOOSTER = 1 << 1,
	IJF_GRAVITY = 1 << 2,
	IJF_TELEPORT = 1 << 3,
	IJF_LAGGEDMOVEMENTVALUE = 1 << 4,
	IJF_PRESTRAFE = 1 << 5,
	IJF_SCOUT = 1 << 6,
	IJF_NOCLIP = 1 << 7,
}

enum JUMP_TYPE
{
	JT_LONGJUMP,
	JT_COUNTJUMP,
	JT_WEIRDJUMP,
	JT_BHOPJUMP,
	JT_LADDERJUMP,
	JT_BHOP,
	JT_DROP,
	JT_END,
}

enum JUMP_DIRECTION
{
	JD_NONE,		// Indeterminate
	JD_NORMAL,
	JD_FORWARDS = JD_NORMAL,
	JD_SIDEWAYS,
	JD_BACKWARDS,
	JD_END,
}

enum STRAFE_DIRECTION
{
	SD_NONE,
	SD_W,
	SD_D,
	SD_A,
	SD_S,
	SD_WA,
	SD_WD,
	SD_SA,
	SD_SD,
	SD_END,
}

enum GAP_SELECTION_MODE
{
	GSM_NONE,
	GSM_GAP,
	GSM_GAPSECOND,
	GSM_BLOCKGAP,
}

enum LJTOP_TABLE
{
	LT_LJ,
	LT_BLOCKLJ,
	LT_SWLJ,
	LT_BWLJ,
	LT_CJ,
	LT_BJ,
	LT_LAJ,
	LT_STRAFEBHOP,
	LT_END,
}

new String:g_strLJTopTags[LT_END][] =
{
	"lj",
	"blj",
	"swlj",
	"bwlj",
	"cj",
	"bj",
	"laj",
	"strafebhop"
};

new String:g_strLJTopTableName[LT_END][] =
{
	"Longjump",
	"Block longjump",
	"Sideways longjump",
	"Backwards longjump",
	"Countjump",
	"Bhopjump",
	"Ladderjump",
	"_strafe bhop"
};

new String:g_strLJTopOutput[LT_END][] =
{
	"lj",
	"block lj",
	"sideways lj",
	"backwards lj",
	"countjump",
	"bhopjump",
	"ladderjump",
	"_strafe bhop"
};

new String:g_strJumpType[JT_END][] =
{
	"Longjump",
	"Countjump",
	"Weirdjump",
	"Bhopjump",
	"Ladderjump",
	"Bhop",
	"Drop"
};

new String:g_strJumpTypeLwr[JT_END][] =
{
	"longjump",
	"countjump",
	"weirdjump",
	"bhopjump",
	"ladderjump",
	"bhop",
	"drop"
};

new String:g_strJumpTypeShort[JT_END][] =
{
	"LJ",
	"CJ",
	"WJ",
	"BJ",
	"LAJ",
	"Bhop",
	"Drop"
};

new const Float:g_fHeightDeltaMin[JT_END] =
{
	LJ_HEIGHT_DELTA_MIN,
	LJ_HEIGHT_DELTA_MIN,
	WJ_HEIGHT_DELTA_MIN,
	BJ_HEIGHT_DELTA_MIN,
	LAJ_HEIGHT_DELTA_MIN,
	-3.402823466e38,
	-3.402823466e38
};

new const Float:g_fHeightDeltaMax[JT_END] =
{
	LJ_HEIGHT_DELTA_MAX,
	LJ_HEIGHT_DELTA_MAX,
	WJ_HEIGHT_DELTA_MAX,
	BJ_HEIGHT_DELTA_MAX,
	LAJ_HEIGHT_DELTA_MAX,
	3.402823466e38,
	3.402823466e38
};

// SourcePawn is silly
#define HEIGHT_DELTA_MIN(%0) (Float:g_fHeightDeltaMin[Float:%0])
#define HEIGHT_DELTA_MAX(%0) (Float:g_fHeightDeltaMax[Float:%0])

new g_PlayerStates[MAXPLAYERS + 1][PlayerState];

new g_LJTop[LT_END][LJTOP_NUM_ENTRIES][TopStats];

new Handle:g_hLJTopMainMenu = INVALID_HANDLE;
new Handle:g_hLJTopMenus[LT_END] = INVALID_HANDLE;

new g_BeamModel;

new Handle:g_hCvarColorMin = INVALID_HANDLE;
new Handle:g_hCvarColorMax = INVALID_HANDLE;
new Handle:g_hCvarLJMin = INVALID_HANDLE;
new Handle:g_hCvarLJMax = INVALID_HANDLE;
new Handle:g_hCvarLJMaxPrestrafe = INVALID_HANDLE;
new Handle:g_hCvarLJScoutStats = INVALID_HANDLE;
new Handle:g_hCvarLJNoDuckMin = INVALID_HANDLE;
new Handle:g_hCvarLJClientMin = INVALID_HANDLE;
new Handle:g_hCvarWJMin = INVALID_HANDLE;
new Handle:g_hCvarWJDropMax = INVALID_HANDLE;
new Handle:g_hCvarBJMin = INVALID_HANDLE;
new Handle:g_hCvarLAJMin = INVALID_HANDLE;
new Handle:g_hCvarPrintFailedBlockStats = INVALID_HANDLE;
new Handle:g_hCvarShowBhopStats = INVALID_HANDLE;
new Handle:g_hCvarOutput16Style = INVALID_HANDLE;
new Handle:g_hCvarVerbosity = INVALID_HANDLE;
new Handle:g_hCvarLJTopAllowEasyBJ = INVALID_HANDLE;
new Handle:g_hCvarLJSound = INVALID_HANDLE;
new Handle:g_hCvarLJSound1 = INVALID_HANDLE;
new Handle:g_hCvarLJSound2 = INVALID_HANDLE;
new Handle:g_hCvarLJSound3 = INVALID_HANDLE;
new Handle:g_hCvarLJSound4 = INVALID_HANDLE;
new Handle:g_hCvarLJSound5 = INVALID_HANDLE;
new Handle:g_hCvarLJSound1File = INVALID_HANDLE;
new Handle:g_hCvarLJSound2File = INVALID_HANDLE;
new Handle:g_hCvarLJSound3File = INVALID_HANDLE;
new Handle:g_hCvarLJSound4File = INVALID_HANDLE;
new Handle:g_hCvarLJSound5File = INVALID_HANDLE;
new Handle:g_hCvarLJSoundToAll[5] = {INVALID_HANDLE, ...};

new Handle:g_hCvarMaxspeed = INVALID_HANDLE;
new Handle:g_hCvarEnableBunnyHopping = INVALID_HANDLE;

new Handle:g_hCookieDefaultsSet = INVALID_HANDLE;
new Handle:g_hCookieLJEnabled = INVALID_HANDLE;
new Handle:g_hCookieBlockMode = INVALID_HANDLE;
new Handle:g_hCookieBeam = INVALID_HANDLE;
new Handle:g_hCookieSound = INVALID_HANDLE;
new Handle:g_hCookieHidePanel = INVALID_HANDLE;
new Handle:g_hCookieHideBhopPanel = INVALID_HANDLE;
new Handle:g_hCookieShowBhopStats = INVALID_HANDLE;
new Handle:g_hCookieVerbosity = INVALID_HANDLE;
new Handle:g_hCookieShowAllJumps = INVALID_HANDLE;
#if defined LJSERV
new Handle:g_hCookieShowPrestrafeHint = INVALID_HANDLE;
#endif
new Handle:g_hCookiePersonalBest = INVALID_HANDLE;

new g_ColorMin[3] = {0xAD, 0xD8, 0xE6}; // Lightblue!
new g_ColorMax[3] = {0x00, 0x00, 0xFF};
new Float:g_fLJMin = 260.0;
new Float:g_fLJMax = 275.0;
new Float:g_fLJMaxPrestrafe = 280.0;
new bool:g_bLJScoutStats = false;
new Float:g_fLJNoDuckMin = 256.0;
new Float:g_fLJClientMin = 0.0;
new Float:g_fWJMin = 270.0;
new Float:g_fWJDropMax = 30.0;
new Float:g_fBJMin = 270.0;
new Float:g_fLAJMin = 140.0;
new g_nVerbosity = 2;
new bool:g_bPrintFailedBlockStats = true;
new bool:g_bShowBhopStats = true;
new bool:g_bOutput16Style = false;
new bool:g_bLJTopAllowEasyBJ = true;
new bool:g_bLJSound = true;
new Float:g_fLJSound[5] = {260.0, 265.0, 268.0, 270.0, 0.0};
new String:g_strLJSoundFile[5][64] = {"misc/perfect.wav", "misc/mod_wickedsick.wav", "misc/mod_godlike.wav", "misc/holyshit.wav", ""};
new bool:g_bLJSoundToAll[5] = false;

new Float:g_fMaxspeed = 320.0;			// sv_maxspeed
new bool:g_bEnableBunnyHopping = true;	// sv_enablebunnyhopping

Handle:CreateCvar(String:strName[], String:strValue[])
{
	new Handle:hCvar = CreateConVar(strName, strValue);
	HookConVarChange(hCvar, OnCvarChange);
	
	return hCvar;
}

public OnPluginStart()
{
	DB_Connect();
	DB_CreateTables();
	DB_LoadLJTop();
	
	CreateConVar("mljstats_version", LJSTATS_VERSION, "ljstats version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hCvarColorMin = CreateCvar("ljstats_color_min", "ADD8E6");
	g_hCvarColorMax = CreateCvar("ljstats_color_max", "0000FF");
	g_hCvarLJMin = CreateCvar("ljstats_lj_min", "260");
	g_hCvarLJMax = CreateCvar("ljstats_lj_max", "275");
	g_hCvarLJMaxPrestrafe = CreateCvar("ljstats_lj_max_prestrafe", "280");
	g_hCvarLJScoutStats = CreateCvar("ljstats_lj_scout_stats", "0");
	g_hCvarLJNoDuckMin = CreateCvar("ljstats_lj_noduck_min", "256");
	g_hCvarLJClientMin = CreateCvar("ljstats_lj_client_min", "0.0");
	g_hCvarWJMin = CreateCvar("ljstats_wj_min", "270");
	g_hCvarWJDropMax = CreateCvar("ljstats_wj_drop_max", "30.0");
	g_hCvarBJMin = CreateCvar("ljstats_bj_min", "270");
	g_hCvarLAJMin = CreateCvar("ljstats_laj_min", "140");
	g_hCvarVerbosity = CreateCvar("ljstats_verbosity", "2");
	g_hCvarPrintFailedBlockStats = CreateCvar("ljstats_print_failed_block_stats", "1");
	g_hCvarShowBhopStats = CreateCvar("ljstats_show_bhop_stats", "0");
	g_hCvarOutput16Style = CreateCvar("ljstats_output_1.6_style", "0");
	g_hCvarLJTopAllowEasyBJ = CreateCvar("ljstats_ljtop_allow_easybhopjump", "1");
	g_hCvarLJSound = CreateCvar("ljstats_lj_sound", "1");
	g_hCvarLJSound1 = CreateCvar("ljstats_lj_sound1", "260");
	g_hCvarLJSound2 = CreateCvar("ljstats_lj_sound2", "265");
	g_hCvarLJSound3 = CreateCvar("ljstats_lj_sound3", "268");
	g_hCvarLJSound4 = CreateCvar("ljstats_lj_sound4", "270");
	g_hCvarLJSound5 = CreateCvar("ljstats_lj_sound5", "0");
	g_hCvarLJSound1File = CreateCvar("ljstats_lj_sound1_file", g_strLJSoundFile[0]);
	g_hCvarLJSound2File = CreateCvar("ljstats_lj_sound2_file", g_strLJSoundFile[1]);
	g_hCvarLJSound3File = CreateCvar("ljstats_lj_sound3_file", g_strLJSoundFile[2]);
	g_hCvarLJSound4File = CreateCvar("ljstats_lj_sound4_file", g_strLJSoundFile[3]);
	g_hCvarLJSound5File = CreateCvar("ljstats_lj_sound5_file", g_strLJSoundFile[4]);
	g_hCvarLJSoundToAll[0] = CreateCvar("ljstats_lj_sound1_to_all", "0");
	g_hCvarLJSoundToAll[1] = CreateCvar("ljstats_lj_sound2_to_all", "0");
	g_hCvarLJSoundToAll[2] = CreateCvar("ljstats_lj_sound3_to_all", "0");
	g_hCvarLJSoundToAll[3] = CreateCvar("ljstats_lj_sound4_to_all", "0");
	g_hCvarLJSoundToAll[4] = CreateCvar("ljstats_lj_sound5_to_all", "0");
	
	g_hCvarMaxspeed = FindConVar("sv_maxspeed");
	if(g_hCvarMaxspeed)
	{
		g_fMaxspeed = GetConVarFloat(g_hCvarMaxspeed);
	}
	
	HookConVarChange(g_hCvarMaxspeed, OnCvarChange);
	
	g_hCvarEnableBunnyHopping = FindConVar("sv_enablebunnyhopping");
	if(g_hCvarEnableBunnyHopping)
	{
		g_bEnableBunnyHopping = GetConVarBool(g_hCvarEnableBunnyHopping);
	}
	
	HookConVarChange(g_hCvarEnableBunnyHopping, OnCvarChange);
	
	CreateNative("LJStats_CancelJump", Native_CancelJump);
	
	HookEvent("player_jump", Event_PlayerJump);
	
	RegConsoleCmd("sm_ljhelp", Command_LJHelp);
	#if !defined LJSERV
	RegConsoleCmd("sm_lj", Command_LJ);
	#else
	RegConsoleCmd("sm_lj", Command_LJSettings);
	#endif
	RegConsoleCmd("sm_ljsettings", Command_LJSettings);
	RegConsoleCmd("sm_ljs", Command_LJSettings);
	RegConsoleCmd("sm_ljpanel", Command_LJPanel);
	RegConsoleCmd("sm_ljbeam", Command_LJBeam);
	RegConsoleCmd("sm_ljblock", Command_LJBlock);
	RegConsoleCmd("sm_ljb", Command_LJBlock);
	RegConsoleCmd("sm_ljsound", Command_LJSound);
	RegConsoleCmd("sm_ljver", Command_LJVersion);
	RegConsoleCmd("sm_ljversion", Command_LJVersion);
	RegConsoleCmd("sm_ljtop", Command_LJTop);
	#if defined LJSERV
	RegConsoleCmd("sm_wr", Command_LJTop);
	#endif
	RegAdminCmd("sm_ljtopdelete", Command_LJTopDelete, ADMFLAG_RCON);
	RegConsoleCmd("sm_gap", Command_Gap);
	RegConsoleCmd("sm_blockgap", Command_BlockGap);
	RegConsoleCmd("sm_tele", Command_Tele);
	RegAdminCmd("sm_ljtopdeleteall", Command_Delete, ADMFLAG_RCON);
	RegConsoleCmd("sm_ljpb", Command_PersonalBest);
	RegConsoleCmd("sm_pb", Command_PersonalBest);
	RegConsoleCmd("sm_personalbest", Command_PersonalBest);
	RegConsoleCmd("sm_pr", Command_PersonalBest);
	RegConsoleCmd("sm_resetpersonalbest", Command_ResetPersonalBest);
	RegAdminCmd("sm_ljtoploadfromfile", Command_LJTopLoadFromFile, ADMFLAG_RCON);
	
	g_hCookieDefaultsSet = RegClientCookie("ljstats_defaultsset", "ljstats_defaultsset", CookieAccess_Public);
	g_hCookieLJEnabled = RegClientCookie("ljstats_ljenabled", "ljstats_ljenabled", CookieAccess_Public);
	g_hCookieBlockMode = RegClientCookie("ljstats_blockmode", "ljstats_blockmode", CookieAccess_Public);
	g_hCookieBeam = RegClientCookie("ljstats_beam", "ljstats_beam", CookieAccess_Public);
	g_hCookieSound = RegClientCookie("ljstats_sound", "ljstats_sound", CookieAccess_Public);
	g_hCookieHidePanel = RegClientCookie("ljstats_hidepanel", "ljstats_hidepanel", CookieAccess_Public);
	g_hCookieHideBhopPanel = RegClientCookie("ljstats_hidebhoppanel", "ljstats_hidebhoppanel", CookieAccess_Public);
	g_hCookieShowBhopStats = RegClientCookie("ljstats_showbhopstats", "ljstats_showbhopstats", CookieAccess_Public);
	g_hCookieVerbosity = RegClientCookie("ljstats_verbosity", "ljstats_verbosity", CookieAccess_Public);
	g_hCookieShowAllJumps = RegClientCookie("ljstats_showalljumps", "ljstats_showalljumps", CookieAccess_Public);
	#if defined LJSERV
	g_hCookieShowPrestrafeHint = RegClientCookie("ljstats_showprestrafehint", "ljstats_showprestrafehint", CookieAccess_Public);
	#endif
	g_hCookiePersonalBest = RegClientCookie("ljstats_personalbest", "ljstats_personalbest", CookieAccess_Private);
	
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
			OnClientCookiesCached(i);
		}
	}
}

/*
enum TopStats
{
	String:m_strName[64 / 4],
	String:m_strSteamID[32 / 4],
	Float:m_fDistance,
	Float:m_fPrestrafe,
	m_nStrafes, //
	Float:m_fSync,
	Float:m_fMaxSpeed,
	m_nTotalTicks,
	Float:m_fSyncedAngle,
	Float:m_fTotalAngle, //
	Float:m_fHeightDelta,
	Float:m_fBlockDistance,
	Float:m_fTrajectory,
	m_nTimestamp,
	
	STRAFE_DIRECTION:m_StrafeDir[LJTOP_MAX_STRAFES],
	Float:m_fStrafeGain[LJTOP_MAX_STRAFES],
	Float:m_fStrafeLoss[LJTOP_MAX_STRAFES],
	m_nStrafeTicks[LJTOP_MAX_STRAFES],
	Float:m_fStrafeSync[LJTOP_MAX_STRAFES],
}
*/

new const String:SQL_CreateLJTopTable[] = "CREATE TABLE IF NOT EXISTS ljtop (ljtable VARCHAR(16), name VARCHAR(64), steamid VARCHAR(32), distance FLOAT, prestrafe FLOAT, strafes INT, sync FLOAT, maxspeed FLOAT, totalticks FLOAT, syncedangle FLOAT, totalangle FLOAT, heightdelta FLOAT, blockdistance FLOAT, trajectory FLOAT, timestamp INT)";
new const String:SQL_CreateLJTopStrafesTable[] = "CREATE TABLE IF NOT EXISTS ljtopstrafes (ljtable VARCHAR(16), rank INTEGER, strafenum INTEGER, dir VARCHAR(3), gain FLOAT, loss FLOAT, ticks INT, sync FLOAT)";
new const String:SQL_LoadLJTop[] = "SELECT * FROM ljtop ORDER BY distance DESC";
new const String:SQL_LoadLJTopStrafes[] = "SELECT * FROM ljtopstrafes";
new const String:SQL_DeleteLJTop[] = "DELETE FROM ljtop";
new const String:SQL_DeleteLJTopStrafes[] = "DELETE FROM ljtopstrafes";

new Handle:g_DB = INVALID_HANDLE;

DB_Connect()
{
	if (g_DB != INVALID_HANDLE)
	{
		CloseHandle(g_DB);
	}
	
	decl String:error[255];
	g_DB = SQL_Connect("ljstats", true, error, sizeof(error));
	
	if (g_DB == INVALID_HANDLE)
	{
		LogError(error);
		CloseHandle(g_DB);
	}
}

DB_CreateTables()
{
	new Handle:hQ = SQL_Query(g_DB, SQL_CreateLJTopTable);
	
	if(hQ == INVALID_HANDLE)
	{
		decl String:error[255];
		SQL_GetError(g_DB, error, sizeof(error));
		LogError("DB_CreateTables failed: %s", error);
		return;
	}
	
	SQL_Query(g_DB, SQL_CreateLJTopStrafesTable);
	
	if(hQ == INVALID_HANDLE)
	{
		decl String:error[255];
		SQL_GetError(g_DB, error, sizeof(error));
		LogError("DB_CreateTables failed: %s", error);
		return;
	}
}

DB_LoadLJTop()
{
	SQL_TQuery(g_DB, DB_LoadLJTop_Callback, SQL_LoadLJTop);
	SQL_TQuery(g_DB, DB_LoadLJTopStrafes_Callback, SQL_LoadLJTopStrafes);
}

public DB_LoadLJTop_Callback(Handle:owner, Handle:hndl, String:error[], any:pack)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("DB_LoadLJTop failed: %s", error);
		return;
	}
	
	new rows = SQL_GetRowCount(hndl);
	
	new it[LT_END] = {0, ...};
	
	for(new i = 0; i < rows; i++)
	{
		SQL_FetchRow(hndl);
		
		decl String:table[16], String:name[64], String:steamid[32];
		
		SQL_FetchStringByName(hndl, "ljtable", table, sizeof(table));
		
		new iTable = _:GetLJTopTable(table);
		
		if(it[iTable] > LJTOP_NUM_ENTRIES - 1)
		{
			LogError("Too many rows for table %s", table);
			return;
		}
		
		if (iTable == -1)
		{
			LogError("DB_LoadLJTop: Invalid table %s", table);
			return;
		}
		
		SQL_FetchStringByName(hndl, "name", name, sizeof(name));
		SQL_FetchStringByName(hndl, "steamid", steamid, sizeof(steamid));
		
		strcopy(g_LJTop[iTable][it[iTable]][m_strName], 64, name);
		strcopy(g_LJTop[iTable][it[iTable]][m_strSteamID], 32, steamid);
		
		g_LJTop[iTable][it[iTable]][m_fDistance] = SQL_FetchFloatByName(hndl, "distance");
		g_LJTop[iTable][it[iTable]][m_fPrestrafe] = SQL_FetchFloatByName(hndl, "prestrafe");
		g_LJTop[iTable][it[iTable]][m_nStrafes] = SQL_FetchIntByName(hndl, "strafes");
		g_LJTop[iTable][it[iTable]][m_fSync] = SQL_FetchFloatByName(hndl, "sync");
		g_LJTop[iTable][it[iTable]][m_fMaxSpeed] = SQL_FetchFloatByName(hndl, "maxspeed");
		g_LJTop[iTable][it[iTable]][m_nTotalTicks] = SQL_FetchIntByName(hndl, "totalticks");
		g_LJTop[iTable][it[iTable]][m_fSyncedAngle] = SQL_FetchFloatByName(hndl, "syncedangle");
		g_LJTop[iTable][it[iTable]][m_fTotalAngle] = SQL_FetchFloatByName(hndl, "totalangle");
		g_LJTop[iTable][it[iTable]][m_fBlockDistance] = SQL_FetchFloatByName(hndl, "blockdistance");
		g_LJTop[iTable][it[iTable]][m_fTrajectory] = SQL_FetchFloatByName(hndl, "trajectory");
		g_LJTop[iTable][it[iTable]][m_nTimestamp] = SQL_FetchIntByName(hndl, "timestamp");
		
		it[iTable]++;
	}
	
	LJTopCreateMainMenu();
	for(new LJTOP_TABLE:i; i < LT_END; i++)
	{
		LJTopCreateMenu(i);
	}
}

public DB_LoadLJTopStrafes_Callback(Handle:owner, Handle:hndl, String:error[], any:pack)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("DB_LoadLJTopStrafes failed: %s", error);
		return;
	}
	
	new rows = SQL_GetRowCount(hndl);
	
	for(new i = 0; i < rows; i++)
	{
		SQL_FetchRow(hndl);
		
		decl String:table[16];
		
		SQL_FetchStringByName(hndl, "ljtable", table, sizeof(table));
		
		new iTable = -1;
		
		for(new LJTOP_TABLE:j; j < LT_END; j++)
		{
			if(!strcmp(g_strLJTopTags[j], table))
			{
				iTable = _:j;
				break;
			}
		}
		
		if (iTable == -1)
		{
			LogError("DB_LoadLJTop: Invalid table %s", table);
			return;
		}
		
		new iEntry = SQL_FetchIntByName(hndl, "rank");
		new iStrafe = SQL_FetchIntByName(hndl, "strafenum");
		
		decl String:key[3];
		SQL_FetchStringByName(hndl, "dir", key, sizeof(key));
		
		g_LJTop[iTable][iEntry][m_StrafeDir][iStrafe] = GetStrafeDir(key);
		g_LJTop[iTable][iEntry][m_fStrafeGain][iStrafe] = SQL_FetchFloatByName(hndl, "gain");
		g_LJTop[iTable][iEntry][m_fStrafeLoss][iStrafe] = SQL_FetchFloatByName(hndl, "loss");
		g_LJTop[iTable][iEntry][m_nStrafeTicks][iStrafe] = SQL_FetchIntByName(hndl, "ticks");
		g_LJTop[iTable][iEntry][m_fStrafeSync][iStrafe] = SQL_FetchFloatByName(hndl, "sync");
	}
}

DB_SaveLJTop()
{
	SQL_TQuery(g_DB, DB_EmptyCallback, SQL_DeleteLJTop);
	SQL_TQuery(g_DB, DB_EmptyCallback, SQL_DeleteLJTopStrafes);
	
	new Handle:hTxn = SQL_CreateTransaction();
	
	decl String:sQuery[1024];
	
	for(new LJTOP_TABLE:i; i < LT_END; i++)
	{
		for (new j = 0; j < LJTOP_NUM_ENTRIES; j++)
		{
			if (g_LJTop[i][j][m_strSteamID][0] == 0)
				continue;
			
			decl String:EscapedName[512];
			if (!SQL_EscapeString(g_DB, g_LJTop[i][j][m_strName], EscapedName, sizeof(EscapedName)))
			{
				LogError("Failed to escape %s's name when writing ljs to database! Writing name without quotes instead", g_LJTop[i][j][m_strName]);
				strcopy(EscapedName, sizeof(EscapedName), g_LJTop[i][j][m_strName]);
				new index = 0;
				while ((index = StrContains(EscapedName, "'")) != -1)
				{
					strcopy(EscapedName[index], sizeof(EscapedName) - index, EscapedName[index + 1]);
				}
			}
			FormatEx(sQuery, sizeof(sQuery), "INSERT INTO ljtop (ljtable, name, steamid, distance, prestrafe, strafes, sync, maxspeed, totalticks, syncedangle, totalangle, heightdelta, blockdistance, trajectory, timestamp) VALUES ('%s', '%s', '%s', %f, %f, %d, %f, %f, %d, %f, %f, %f, %f, %f, %d)",
			g_strLJTopTags[i],
			EscapedName,
			g_LJTop[i][j][m_strSteamID],
			g_LJTop[i][j][m_fDistance],
			g_LJTop[i][j][m_fPrestrafe],
			g_LJTop[i][j][m_nStrafes],
			g_LJTop[i][j][m_fSync],
			g_LJTop[i][j][m_fMaxSpeed],
			g_LJTop[i][j][m_nTotalTicks],
			g_LJTop[i][j][m_fSyncedAngle],
			g_LJTop[i][j][m_fTotalAngle],
			g_LJTop[i][j][m_fHeightDelta],
			g_LJTop[i][j][m_fBlockDistance],
			g_LJTop[i][j][m_fTrajectory],
			g_LJTop[i][j][m_nTimestamp]);
			
			SQL_AddQuery(hTxn, sQuery);
			
			for (new k = 0; k < g_LJTop[i][j][m_nStrafes]; k++)
			{
				decl String:key[3];
				GetStrafeKey(key, g_LJTop[i][j][m_StrafeDir][k]);
				
				FormatEx(sQuery, sizeof(sQuery), "INSERT INTO ljtopstrafes (ljtable, rank, strafenum, dir, gain, loss, ticks, sync) VALUES ('%s', %d, %d, '%s', %f, %f, %d, %f)",
				g_strLJTopTags[i],
				j,
				k,
				key,
				g_LJTop[i][j][m_fStrafeGain][k],
				g_LJTop[i][j][m_fStrafeLoss][k],
				g_LJTop[i][j][m_nStrafeTicks][k],
				g_LJTop[i][j][m_fStrafeSync][k]);
			
				SQL_AddQuery(hTxn, sQuery);
			}
		}
	}
	
	SQL_ExecuteTransaction(g_DB, hTxn, SQLTxnSuccess:-1, DB_TxnFailure);
}

public DB_EmptyCallback(Handle:owner, Handle:hndl, String:error[], any:pack)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError(error);
	}
}

public DB_TxnFailure(Handle:db, any:data, numQueries, const String:error[], failIndex, any:queryData[])
{
	LogError("DB_SaveLJTop: Transaction failed: %s", error);
}

LJTOP_TABLE:GetLJTopTable(const String:table[])
{
	for(new LJTOP_TABLE:j; j < LT_END; j++)
	{
		if(!strcmp(g_strLJTopTags[j], table))
		{
			return j;
		}
	}
	
	return LJTOP_TABLE:-1;
}

#define ON_CVAR_CHANGE_BOOL(%0,%1) else if(hCvar == %0) { %1 = bool:StringToInt(strNewValue); }
#define ON_CVAR_CHANGE_INT(%0,%1) else if(hCvar == %0) { %1 = StringToInt(strNewValue); }
#define ON_CVAR_CHANGE_FLOAT(%0,%1) else if(hCvar == %0) { %1 = StringToFloat(strNewValue); }

public OnCvarChange(Handle:hCvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hCvar == g_hCvarColorMin)
	{
		new nColor = StringToInt(strNewValue, 16);
		g_ColorMin[0] = (nColor & 0xFF0000) >> 16;
		g_ColorMin[1] = (nColor & 0xFF00) >> 8;
		g_ColorMin[2] = nColor & 0xFF;
	}
	else if(hCvar == g_hCvarColorMax)
	{
		new nColor = StringToInt(strNewValue, 16);
		g_ColorMax[0] = (nColor & 0xFF0000) >> 16;
		g_ColorMax[1] = (nColor & 0xFF00) >> 8;
		g_ColorMax[2] = nColor & 0xFF;
	}
	ON_CVAR_CHANGE_FLOAT(g_hCvarLJMin, g_fLJMin)
	ON_CVAR_CHANGE_FLOAT(g_hCvarLJMax, g_fLJMax)
	ON_CVAR_CHANGE_FLOAT(g_hCvarLJMaxPrestrafe, g_fLJMaxPrestrafe)
	ON_CVAR_CHANGE_BOOL(g_hCvarLJScoutStats, g_bLJScoutStats)
	ON_CVAR_CHANGE_FLOAT(g_hCvarLJNoDuckMin, g_fLJNoDuckMin)
	ON_CVAR_CHANGE_FLOAT(g_hCvarLJClientMin, g_fLJClientMin)
	ON_CVAR_CHANGE_FLOAT(g_hCvarWJMin, g_fWJMin)
	ON_CVAR_CHANGE_FLOAT(g_hCvarWJDropMax, g_fWJDropMax)
	ON_CVAR_CHANGE_FLOAT(g_hCvarBJMin, g_fBJMin)
	ON_CVAR_CHANGE_FLOAT(g_hCvarLAJMin, g_fLAJMin)
	ON_CVAR_CHANGE_INT(g_hCvarVerbosity, g_nVerbosity)
	ON_CVAR_CHANGE_BOOL(g_hCvarPrintFailedBlockStats, g_bPrintFailedBlockStats)
	ON_CVAR_CHANGE_BOOL(g_hCvarShowBhopStats, g_bShowBhopStats)
	ON_CVAR_CHANGE_BOOL(g_hCvarOutput16Style, g_bOutput16Style)
	ON_CVAR_CHANGE_BOOL(g_hCvarLJTopAllowEasyBJ, g_bLJTopAllowEasyBJ)
	ON_CVAR_CHANGE_BOOL(g_hCvarLJSound, g_bLJSound)
	ON_CVAR_CHANGE_FLOAT(g_hCvarLJSound1, g_fLJSound[0])
	ON_CVAR_CHANGE_FLOAT(g_hCvarLJSound2, g_fLJSound[1])
	ON_CVAR_CHANGE_FLOAT(g_hCvarLJSound3, g_fLJSound[2])
	ON_CVAR_CHANGE_FLOAT(g_hCvarLJSound4, g_fLJSound[3])
	ON_CVAR_CHANGE_FLOAT(g_hCvarLJSound5, g_fLJSound[4])
	ON_CVAR_CHANGE_BOOL(g_hCvarLJSoundToAll[0], g_bLJSoundToAll[0])
	ON_CVAR_CHANGE_BOOL(g_hCvarLJSoundToAll[1], g_bLJSoundToAll[1])
	ON_CVAR_CHANGE_BOOL(g_hCvarLJSoundToAll[2], g_bLJSoundToAll[2])
	ON_CVAR_CHANGE_BOOL(g_hCvarLJSoundToAll[3], g_bLJSoundToAll[3])
	ON_CVAR_CHANGE_BOOL(g_hCvarLJSoundToAll[4], g_bLJSoundToAll[4])
	else if(hCvar == g_hCvarLJSound1File)
	{
		strcopy(g_strLJSoundFile[0], sizeof(g_strLJSoundFile[]), strNewValue);
		PrecacheSound(g_strLJSoundFile[0]);
	}
	else if(hCvar == g_hCvarLJSound2File)
	{
		strcopy(g_strLJSoundFile[1], sizeof(g_strLJSoundFile[]), strNewValue);
		PrecacheSound(g_strLJSoundFile[1]);
	}
	else if(hCvar == g_hCvarLJSound3File)
	{
		strcopy(g_strLJSoundFile[2], sizeof(g_strLJSoundFile[]), strNewValue);
		PrecacheSound(g_strLJSoundFile[2]);
	}
	else if(hCvar == g_hCvarLJSound4File)
	{
		strcopy(g_strLJSoundFile[3], sizeof(g_strLJSoundFile[]), strNewValue);
		PrecacheSound(g_strLJSoundFile[3]);
	}
	else if(hCvar == g_hCvarLJSound5File)
	{
		strcopy(g_strLJSoundFile[4], sizeof(g_strLJSoundFile[]), strNewValue);
		PrecacheSound(g_strLJSoundFile[4]);
	}
	
	ON_CVAR_CHANGE_FLOAT(g_hCvarMaxspeed, g_fMaxspeed)
	ON_CVAR_CHANGE_BOOL(g_hCvarEnableBunnyHopping, g_bEnableBunnyHopping)
}

#undef ON_CVAR_CHANGE_BOOL
#undef ON_CVAR_CHANGE_INT
#undef ON_CVAR_CHANGE_FLOAT

public OnMapStart()
{
	g_BeamModel = PrecacheModel("materials/sprites/bluelaser1.vmt");
	
	for(new i; i < LJSOUND_NUM; i++)
	{
		if(g_strLJSoundFile[i][0] != 0)
		{
			PrecacheSound(g_strLJSoundFile[i]);
		}
	}
}

public OnClientPutInServer(client)
{
	/*
	#if defined LJSERV
	g_PlayerStates[client][bLJEnabled] = true;
	#else
	g_PlayerStates[client][bLJEnabled] = false;
	#endif
	g_PlayerStates[client][bHidePanel] = false;
	g_PlayerStates[client][bBeam] = false;
	g_PlayerStates[client][bSound] = true;
	//#if defined LJSERV
	//g_PlayerStates[client][bBlockMode] = true;
	//#else
	g_PlayerStates[client][bBlockMode] = false;
	//#endif
	g_PlayerStates[client][nVerbosity] = g_nVerbosity;
	*/
	g_PlayerStates[client][bOnGround] = true;
	g_PlayerStates[client][fBlockDistance] = -1.0;
	g_PlayerStates[client][IllegalJumpFlags] = IJF_NONE;
	g_PlayerStates[client][nSpectators] = 0;
	g_PlayerStates[client][nSpectatorTarget] = -1;
	/*
	#if defined LJSERV
	g_PlayerStates[client][bShowPrestrafeHint] = true;
	#endif
	*/
	SDKHook(client, SDKHook_Touch, hkTouch);
}

public Action:hkTouch(client, other)
{
	new Float:vOrigin[3];
	GetClientAbsOrigin(client, vOrigin);
	
	if(other == 0 && !(GetEntityFlags(client) & FL_ONGROUND) &&
	!(g_PlayerStates[client][bBlockMode] && g_PlayerStates[client][bFailedBlock] &&
	vOrigin[2] - g_PlayerStates[client][vJumpOrigin][2] < HEIGHT_DELTA_MIN(JT_LONGJUMP)))
	{
		g_PlayerStates[client][IllegalJumpFlags] |= IJF_WORLD;
		
		#if defined DEBUG
		PrintToChat(client, "%d, %d, %f, %d, %d", g_PlayerStates[client][bBlockMode], g_PlayerStates[client][bFailedBlock], vOrigin[2] - g_PlayerStates[client][vJumpOrigin][2],
		vOrigin[2] - g_PlayerStates[client][vJumpOrigin][2] < HEIGHT_DELTA_MIN(JT_LONGJUMP), GetGameTickCount());
		#endif
	}
	else
	{
		decl String:strClassname[64];
		GetEdictClassname(other, strClassname, sizeof(strClassname));
		
		if(!strcmp(strClassname, "trigger_push"))
		{
			g_PlayerStates[client][IllegalJumpFlags] |= IJF_BOOSTER;
			
			#if defined DEBUG
			PrintToChat(client, "booster");
			#endif
		}
	}
}

public Action:Command_Delete(client, args)
{
	SQL_Query(g_DB, "drop table ljtop");
	SQL_Query(g_DB, "drop table ljtopstrafes");
	
	return Plugin_Handled;
}

public Action:Command_LJHelp(client, args)
{
	new Handle:hHelpPanel = CreatePanel();
	
	SetPanelTitle(hHelpPanel, "!lj");
	DrawPanelText(hHelpPanel, "!ljsettings, !ljs");
	DrawPanelText(hHelpPanel, "!ljpanel");
	DrawPanelText(hHelpPanel, "!ljbeam");
	DrawPanelText(hHelpPanel, "!ljblock");
	DrawPanelText(hHelpPanel, "!ljsound");
	DrawPanelText(hHelpPanel, "!gap");
	DrawPanelText(hHelpPanel, "!blockgap");
	DrawPanelText(hHelpPanel, "!ljtop");
	DrawPanelText(hHelpPanel, "!ljtopdelete (requires ADMFLAG_RCON)");
	DrawPanelText(hHelpPanel, "!ljversion, !ljver");
	DrawPanelText(hHelpPanel, " ");
	DrawPanelText(hHelpPanel, "ex. !lj, /lj, or sm_lj");
	
	SendPanelToClient(hHelpPanel, client, EmptyPanelHandler, 10);
	
	CloseHandle(hHelpPanel);
	
	return Plugin_Handled;
}

public Action:Command_LJ(client, args)
{
	g_PlayerStates[client][bLJEnabled] = !g_PlayerStates[client][bLJEnabled];
	SetCookie(client, g_hCookieLJEnabled, g_PlayerStates[client][bLJEnabled]);
	PrintToChat(client, "Longjump stats %s", g_PlayerStates[client][bLJEnabled] ? "ENABLED" : "DISABLED");
	
	return Plugin_Handled;
}

public Action:Command_LJSettings(client, args)
{
	ShowSettingsPanel(client);
	
	return Plugin_Handled;
}

public OnClientCookiesCached(client)
{
	decl String:strCookie[64];
	
	GetClientCookie(client, g_hCookieDefaultsSet, strCookie, sizeof(strCookie));
	
	if(StringToInt(strCookie) == 0)
	{
		#if defined LJSERV
		SetCookie(client, g_hCookieLJEnabled, true);
		SetCookie(client, g_hCookieBlockMode, true);
		#endif
		
		SetCookie(client, g_hCookieSound, g_bLJSound);
		
		SetCookie(client, g_hCookieShowBhopStats, g_bShowBhopStats);
		
		SetCookie(client, g_hCookieVerbosity, g_nVerbosity);
		
		SetCookie(client, g_hCookieShowAllJumps, false);
		
		#if defined LJSERV
		SetCookie(client, g_hCookieShowPrestrafeHint, true);
		#endif
		
		SetCookie(client, g_hCookieDefaultsSet, true);
	}
	
	
	GetClientCookie(client, g_hCookieLJEnabled, strCookie, sizeof(strCookie));
	g_PlayerStates[client][bLJEnabled] = bool:StringToInt(strCookie);
	
	GetClientCookie(client, g_hCookieBlockMode, strCookie, sizeof(strCookie));
	g_PlayerStates[client][bBlockMode] = bool:StringToInt(strCookie);
	
	GetClientCookie(client, g_hCookieBeam, strCookie, sizeof(strCookie));
	g_PlayerStates[client][bBeam] = bool:StringToInt(strCookie);
	
	GetClientCookie(client, g_hCookieSound, strCookie, sizeof(strCookie));
	g_PlayerStates[client][bSound] = bool:StringToInt(strCookie);
	
	GetClientCookie(client, g_hCookieHidePanel, strCookie, sizeof(strCookie));
	g_PlayerStates[client][bHidePanel] = bool:StringToInt(strCookie);
	
	GetClientCookie(client, g_hCookieHideBhopPanel, strCookie, sizeof(strCookie));
	g_PlayerStates[client][bHideBhopPanel] = bool:StringToInt(strCookie);
	
	GetClientCookie(client, g_hCookieShowBhopStats, strCookie, sizeof(strCookie));
	g_PlayerStates[client][bShowBhopStats] = bool:StringToInt(strCookie);
	
	GetClientCookie(client, g_hCookieVerbosity, strCookie, sizeof(strCookie));
	g_PlayerStates[client][nVerbosity] = StringToInt(strCookie);
	
	GetClientCookie(client, g_hCookieShowAllJumps, strCookie, sizeof(strCookie));
	g_PlayerStates[client][bShowAllJumps] = bool:StringToInt(strCookie);
	
	#if defined LJSERV
	GetClientCookie(client, g_hCookieShowPrestrafeHint, strCookie, sizeof(strCookie));
	g_PlayerStates[client][bShowPrestrafeHint] = bool:StringToInt(strCookie);
	#endif
	
	GetClientCookie(client, g_hCookiePersonalBest, strCookie, sizeof(strCookie));
	g_PlayerStates[client][fPersonalBest] = StringToFloat(strCookie);
}

ShowSettingsPanel(client)
{
	new Handle:hMenu = CreateMenu(SettingsMenuHandler);
	
	decl String:buf[64];
	
	Format(buf, sizeof(buf), "LJ stats: %s", g_PlayerStates[client][bLJEnabled] ? "On" : "Off");
	AddMenuItem(hMenu, "ljenabled", buf);
	
	Format(buf, sizeof(buf), "Block mode: %s", g_PlayerStates[client][bBlockMode] ? "On" : "Off");
	AddMenuItem(hMenu, "block", buf);
	
	Format(buf, sizeof(buf), "Beam: %s", g_PlayerStates[client][bBeam] ? "On" : "Off");
	AddMenuItem(hMenu, "beam", buf);
	
	Format(buf, sizeof(buf), "Sounds: %s", g_PlayerStates[client][bSound] ? "On" : "Off");
	AddMenuItem(hMenu, "sound", buf);
	
	Format(buf, sizeof(buf), "Panel: %s", !g_PlayerStates[client][bHidePanel] ? "On" : "Off");
	AddMenuItem(hMenu, "panel", buf);
	
	Format(buf, sizeof(buf), "Bhop panel: %s", !g_PlayerStates[client][bHideBhopPanel] ? "On" : "Off");
	AddMenuItem(hMenu, "bhoppanel", buf);
	
	Format(buf, sizeof(buf), "Bhop stats: %s", g_PlayerStates[client][bShowBhopStats] ? "On" : "Off");
	AddMenuItem(hMenu, "bhopstats", buf);
	
	Format(buf, sizeof(buf), "Verbosity: %d", g_PlayerStates[client][nVerbosity]);
	AddMenuItem(hMenu, "verbosity", buf);
	
	Format(buf, sizeof(buf), "Show all jumps: %s", g_PlayerStates[client][bShowAllJumps] ? "On" : "Off");
	AddMenuItem(hMenu, "showalljumps", buf);
	
	#if defined LJSERV
	Format(buf, sizeof(buf), "Prestrafe hint: %s", g_PlayerStates[client][bShowPrestrafeHint] ? "On" : "Off");
	AddMenuItem(hMenu, "prestrafehint", buf);
	#endif
	
	DisplayMenu(hMenu, client, 0);
}

public SettingsMenuHandler(Handle:hMenu, MenuAction:ma, client, nItem)
{
	switch(ma)
	{
		case MenuAction_Select:
		{
			decl String:strInfo[16];
			
			if(!GetMenuItem(hMenu, nItem, strInfo, sizeof(strInfo)))
			{
				LogError("rip menu...");
				return;
			}
			
			if(!strcmp(strInfo, "ljenabled"))
			{
				g_PlayerStates[client][bLJEnabled] = !g_PlayerStates[client][bLJEnabled];
				SetCookie(client, g_hCookieLJEnabled, g_PlayerStates[client][bLJEnabled]);
				PrintToChat(client, "LJ stats are now %s", g_PlayerStates[client][bLJEnabled] ? "on" : "off");
				ShowSettingsPanel(client);
			}
			else if(!strcmp(strInfo, "block"))
			{
				g_PlayerStates[client][bBlockMode] = !g_PlayerStates[client][bBlockMode];
				SetCookie(client, g_hCookieBlockMode, g_PlayerStates[client][bBlockMode]);
				PrintToChat(client, "Block mode is now %s", g_PlayerStates[client][bBlockMode] ? "on" : "off");
				ShowSettingsPanel(client);
			}
			else if(!strcmp(strInfo, "beam"))
			{
				g_PlayerStates[client][bBeam] = !g_PlayerStates[client][bBeam];
				SetCookie(client, g_hCookieBeam, g_PlayerStates[client][bBeam]);
				PrintToChat(client, "Beam is now %s", g_PlayerStates[client][bBeam] ? "on" : "off");
				ShowSettingsPanel(client);
			}
			else if(!strcmp(strInfo, "sound"))
			{
				g_PlayerStates[client][bSound] = !g_PlayerStates[client][bSound];
				SetCookie(client, g_hCookieSound, g_PlayerStates[client][bSound]);
				PrintToChat(client, "Sound is now %s", g_PlayerStates[client][bSound] ? "on" : "off");
				ShowSettingsPanel(client);
			}
			else if(!strcmp(strInfo, "panel"))
			{
				g_PlayerStates[client][bHidePanel] = !g_PlayerStates[client][bHidePanel];
				SetCookie(client, g_hCookieHidePanel, g_PlayerStates[client][bHidePanel]);
				PrintToChat(client, "Panel is now %s", g_PlayerStates[client][bHidePanel] ? "hidden" : "visible");
				ShowSettingsPanel(client);
			}
			else if(!strcmp(strInfo, "bhoppanel"))
			{
				g_PlayerStates[client][bHideBhopPanel] = !g_PlayerStates[client][bHideBhopPanel];
				SetCookie(client, g_hCookieHideBhopPanel, g_PlayerStates[client][bHideBhopPanel]);
				PrintToChat(client, "Bhop panel is now %s", g_PlayerStates[client][bHideBhopPanel] ? "hidden" : "visible");
				ShowSettingsPanel(client);
			}
			else if(!strcmp(strInfo, "bhopstats"))
			{
				g_PlayerStates[client][bShowBhopStats] = !g_PlayerStates[client][bShowBhopStats];
				SetCookie(client, g_hCookieShowBhopStats, g_PlayerStates[client][bShowBhopStats]);
				PrintToChat(client, "Bhop stats are now %s", g_PlayerStates[client][bShowBhopStats] ? "on" : "off");
				ShowSettingsPanel(client);
			}
			else if(!strcmp(strInfo, "verbosity"))
			{
				hMenu = CreateMenu(VerbosityMenuHandler);
				
				AddMenuItem(hMenu, "0", "0");
				AddMenuItem(hMenu, "1", "1");
				AddMenuItem(hMenu, "2", "2");
				AddMenuItem(hMenu, "3", "3");
				
				DisplayMenu(hMenu, client, 0);
			}
			else if(!strcmp(strInfo, "showalljumps"))
			{
				g_PlayerStates[client][bShowAllJumps] = !g_PlayerStates[client][bShowAllJumps];
				SetCookie(client, g_hCookieShowAllJumps, g_PlayerStates[client][bShowAllJumps]);
				PrintToChat(client, "Showing all jumps is now %s", g_PlayerStates[client][bShowAllJumps] ? "on" : "off");
				ShowSettingsPanel(client);
			}
			#if defined LJSERV
			else if(!strcmp(strInfo, "prestrafehint"))
			{
				g_PlayerStates[client][bShowPrestrafeHint] = !g_PlayerStates[client][bShowPrestrafeHint];
				SetCookie(client, g_hCookieShowPrestrafeHint, g_PlayerStates[client][bShowPrestrafeHint]);
				PrintToChat(client, "Prestrafe hint is now %s", g_PlayerStates[client][bShowPrestrafeHint] ? "on" : "off");
				ShowSettingsPanel(client);
			}
			#endif
		}
		
		case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
	}
}

SetCookie(client, Handle:hCookie, n)
{
	decl String:strCookie[64];
	
	IntToString(n, strCookie, sizeof(strCookie));

	SetClientCookie(client, hCookie, strCookie);
}

SetCookieFloat(client, Handle:hCookie, Float:n)
{
	decl String:strCookie[64];
	
	FloatToString(n, strCookie, sizeof(strCookie));
	
	SetClientCookie(client, hCookie, strCookie);
}

public VerbosityMenuHandler(Handle:hMenu, MenuAction:ma, client, nItem)
{
	switch(ma)
	{
		case MenuAction_Select:
		{
			g_PlayerStates[client][nVerbosity] = nItem;
			SetCookie(client, g_hCookieVerbosity, g_PlayerStates[client][nVerbosity]);
			PrintToChat(client, "Verbosity level is now %d", g_PlayerStates[client][nVerbosity]);
			
			ShowSettingsPanel(client);
		}
		
		case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
	}
}

public Action:Command_LJPanel(client, args)
{
	g_PlayerStates[client][bHidePanel] = !g_PlayerStates[client][bHidePanel];
	SetCookie(client, g_hCookieHidePanel, g_PlayerStates[client][bHidePanel]);
	PrintToChat(client, "Longjump panel %s", g_PlayerStates[client][bHidePanel] ? "ENABLED" : "DISABLED");
	
	return Plugin_Handled;
}

public Action:Command_LJBeam(client, args)
{
	g_PlayerStates[client][bBeam] = !g_PlayerStates[client][bBeam];
	SetCookie(client, g_hCookieBeam, g_PlayerStates[client][bBeam]);
	PrintToChat(client, "Longjump beam %s", g_PlayerStates[client][bBeam] ? "ENABLED" : "DISABLED");
	
	return Plugin_Handled;
}

public Action:Command_LJBlock(client, args)
{
	g_PlayerStates[client][bBlockMode] = !g_PlayerStates[client][bBlockMode];
	SetCookie(client, g_hCookieBlockMode, g_PlayerStates[client][bBlockMode]);
	PrintToChat(client, "Longjump block mode %s", g_PlayerStates[client][bBlockMode] ? "ENABLED" : "DISABLED");
	
	return Plugin_Handled;
}

public Action:Command_LJSound(client, args)
{
	g_PlayerStates[client][bSound] = !g_PlayerStates[client][bSound];
	SetCookie(client, g_hCookieSound, g_PlayerStates[client][bSound]);
	PrintToChat(client, "Longjump sounds %s", g_PlayerStates[client][bSound] ? "enabled" : "disabled");
	
	return Plugin_Handled;
}

public Action:Command_LJVersion(client, args)
{
	CPrintToChat(client, "{green}ljstats %s by Miu -w-", LJSTATS_VERSION);
	
	return Plugin_Handled;
}

public Action:Command_LJTop(client, args)
{
	//SendPanelToClient(g_hLJTopLJPanel, client, EmptyPanelHandler, 10);
	DisplayMenu(g_hLJTopMainMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action:Command_LJTopDelete(client, args)
{
	decl String:buf[32];
	GetCmdArg(1, buf, sizeof(buf));
	
	new LJTOP_TABLE:nLJTopTable = LJTOP_TABLE:-1;
	
	for(new LJTOP_TABLE:i; i < LT_END; i++)
	{
		if(!strcmp(g_strLJTopTags[i], buf))
		{
			nLJTopTable = i;
			break;
		}
	}
	
	if(nLJTopTable == LJTOP_TABLE:-1)
	{
		PrintToChat(client, "Unrecognized table %s", buf);
		
		return Plugin_Handled;
	}
	
	
	decl String:str[4];
	GetCmdArg(2, str, sizeof(str));
	new n = StringToInt(str) - 1;
	
	if(n < 0 || n > LJTOP_NUM_ENTRIES - 1)
	{
		PrintToChat(client, "Invalid entry");
		
		return Plugin_Handled;
	}
	
	PrintToChat(client, "Removing %s's %.2f in table %d (%s)", g_LJTop[nLJTopTable][n][m_strName], g_LJTop[nLJTopTable][n][m_fDistance], nLJTopTable, buf);
	
	LJTopMoveUp(nLJTopTable, n);
	
	LJTopSave();
	LJTopCreateMenu(nLJTopTable);
	
	return Plugin_Handled;
}

public Action:Command_Gap(client, args)
{
	new Handle:hGapPanel = CreatePanel();
	
	SetPanelTitle(hGapPanel, "Select point 1");
	
	SendPanelToClient(hGapPanel, client, EmptyPanelHandler, 10);
	
	CloseHandle(hGapPanel);
	
	g_PlayerStates[client][GapSelectionMode] = GSM_GAP;
	
	return Plugin_Handled;
}

public Action:Command_BlockGap(client, args)
{
	new Handle:hGapPanel = CreatePanel();
	
	SetPanelTitle(hGapPanel, "Select block");
	
	SendPanelToClient(hGapPanel, client, EmptyPanelHandler, 10);
	
	CloseHandle(hGapPanel);
	
	g_PlayerStates[client][GapSelectionMode] = GSM_BLOCKGAP;
	
	return Plugin_Handled;
}

GapSelect(client, buttons)
{
	if(!(buttons & IN_ATTACK || buttons & IN_ATTACK2 || buttons & IN_USE) ||
	g_PlayerStates[client][LastButtons] & IN_ATTACK || g_PlayerStates[client][LastButtons] & IN_ATTACK2 || g_PlayerStates[client][LastButtons] & IN_USE)
	{
		return;
	}
	
	new Float:vPoint[3], Float:vNormal[3];
	GetGapPoint(vPoint, vNormal, client);
	
	switch(g_PlayerStates[client][GapSelectionMode])
	{
		case GSM_GAP:
		{
			Array_Copy(vPoint, g_PlayerStates[client][vGapPoint1], 3);
			
			SendPanelMsg(client, "Select point 2");
			
			g_PlayerStates[client][GapSelectionMode] = GSM_GAPSECOND;
		}
		
		case GSM_GAPSECOND:
		{
			new Float:vPoint1[3];
			Array_Copy(g_PlayerStates[client][vGapPoint1], vPoint1, 3);
			
			new Float:xy = Pow(Pow(vPoint[0] - vPoint1[0], 2.0) + Pow(vPoint[1] - vPoint1[1], 2.0), 0.5);
			
			SendPanelMsg(client, "distance: %.2f, xy: %.2f, z: %.2f", GetVectorDistance(vPoint, vPoint1), xy, vPoint1[2] - vPoint[2]);
			
			CreateBeamClient(client, vPoint, vPoint1, 0, 0, 128, 5.0);
			
			g_PlayerStates[client][GapSelectionMode] = GSM_NONE;
		}
		
		case GSM_BLOCKGAP:
		{
			new Float:vBlockEnd[3], Float:vOrigin[3];
			GetClientAbsOrigin(client, vOrigin);
			GetOppositePoint(vBlockEnd, vPoint, vNormal);
			
			SendPanelMsg(client, "block: %.2f", GetVectorDistance(vPoint, vBlockEnd));
			
			CreateBeamClient(client, vPoint, vBlockEnd, 255, 0, 0, 5.0);
			
			g_PlayerStates[client][GapSelectionMode] = GSM_NONE;
		}
		
	}
}

public Action:Command_Tele(client, args)
{
	g_PlayerStates[client][IllegalJumpFlags] |= IJF_TELEPORT;
	
	return Plugin_Continue;
}

public Action:Command_PersonalBest(client, args)
{
	CPrintToChat(client, "{green}Your longjump record is {default}%.2f{green} units", g_PlayerStates[client][fPersonalBest]);
	
	return Plugin_Handled;
}

UpdatePersonalBest(client)
{
	if(g_PlayerStates[client][JumpType] != JT_LONGJUMP)
	{
		return;
	}
	
	if(g_PlayerStates[client][fJumpDistance] > g_PlayerStates[client][fPersonalBest])
	{
		g_PlayerStates[client][fPersonalBest] = g_PlayerStates[client][fJumpDistance];
		
		CPrintToChat(client, "{green}Congratulations, you have a new longjump record with {default}%.2f{green} units!", g_PlayerStates[client][fPersonalBest]);
		
		SetCookieFloat(client, g_hCookiePersonalBest, g_PlayerStates[client][fPersonalBest]);
	}
}

public Action:Command_ResetPersonalBest(client, args)
{
	SetCookieFloat(client, g_hCookiePersonalBest, 0.0);
	g_PlayerStates[client][fPersonalBest] = 0.0;
	
	return Plugin_Continue;
}

public Action:Command_LJTopLoadFromFile(client, args)
{
	decl String:arg[PLATFORM_MAX_PATH];
	GetCmdArgString(arg, sizeof(arg));
	LJTopLoad(arg);
	
	return Plugin_Handled;
}

LJTopCreateMainMenu()
{
	if(g_hLJTopMainMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hLJTopMainMenu);
	}
	
	g_hLJTopMainMenu = CreateMenu(LJTopMainMenuHandler);
	
	for(new LJTOP_TABLE:i; i < LT_END; i++)
	{
		AddMenuItem(g_hLJTopMainMenu, g_strLJTopTags[i], g_strLJTopTableName[i]);
	}
}

public LJTopMainMenuHandler(Handle:hMenu, MenuAction:ma, client, nItem)
{
	switch(ma)
	{
		case MenuAction_Select:
		{
			decl String:strInfo[16];
			
			if(!GetMenuItem(hMenu, nItem, strInfo, sizeof(strInfo)))
			{
				PrintToChat(client, "rip menu...");
				return;
			}
			
			for(new LJTOP_TABLE:i = LJTOP_TABLE:0; i < LT_END; i++)
			{
				if(!strcmp(g_strLJTopTags[i], strInfo))
				{
					DisplayMenu(g_hLJTopMenus[i], client, 0);
					
					break;
				}
			}
		}
		
		case MenuAction_End:
		{
		}
	}
}

LJTopCreateMenu(LJTOP_TABLE:nTable)
{
	if(g_hLJTopMenus[nTable] != INVALID_HANDLE)
	{
		CloseHandle(g_hLJTopMenus[nTable]);
	}
	
	g_hLJTopMenus[nTable] = CreateMenu(LJTopRecordMenuHandler);
	
	decl String:buf[128], String:info[32];
	
	Format(buf, sizeof(buf), "%s top", g_strLJTopTableName[nTable]);
	
	SetMenuTitle(g_hLJTopMenus[nTable], buf);
	
	for(new i; i < LJTOP_NUM_ENTRIES; i++)
	{
		if(g_LJTop[nTable][i][m_strName][0] == 0)
		{
			break;
		}
		
		if(nTable == LT_BLOCKLJ)
		{
			FormatEx(buf, sizeof(buf), "%s - %.2f (%.2f: %.2f, %d @ %d%%, %.2f)",
			g_LJTop[LT_BLOCKLJ][i][m_strName], g_LJTop[LT_BLOCKLJ][i][m_fBlockDistance], g_LJTop[LT_BLOCKLJ][i][m_fDistance],
			g_LJTop[LT_BLOCKLJ][i][m_fPrestrafe], g_LJTop[LT_BLOCKLJ][i][m_nStrafes], RoundFloat(g_LJTop[LT_BLOCKLJ][i][m_fSync]), g_LJTop[LT_BLOCKLJ][i][m_fMaxSpeed]);
		}
		else
		{
			FormatEx(buf, sizeof(buf), "%s - %.2f (%.2f, %d @ %d%%, %.2f)",
			g_LJTop[nTable][i][m_strName], g_LJTop[nTable][i][m_fDistance],
			g_LJTop[nTable][i][m_fPrestrafe], g_LJTop[nTable][i][m_nStrafes], RoundFloat(g_LJTop[nTable][i][m_fSync]), g_LJTop[nTable][i][m_fMaxSpeed]);
		}
		
		FormatEx(info, sizeof(info), "%s;%d", g_strLJTopTags[nTable], i);
		
		AddMenuItem(g_hLJTopMenus[nTable], info, buf);
	}
	
	//SetMenuExitBackButton(g_hLJTopMenus[nTable], true);
}

public LJTopRecordMenuHandler(Handle:hMenu, MenuAction:ma, client, nItem)
{
	switch(ma)
	{
		case MenuAction_Select:
		{
			decl String:info[16];
			
			if(!GetMenuItem(hMenu, nItem, info, sizeof(info)))
			{
				LogError("rip menu...");
				return;
			}
			
			decl String:split[2][16], String:sTime[128], String:buf[128];
			ExplodeString(info, ";", split, sizeof(split), sizeof(split[]));
			
			new iTable = _:GetLJTopTable(split[0]);
			new iEntry = StringToInt(split[1]);
			
			if(iTable == -1)
			{
				LogError("Unrecognized table %s");
				return;
			}
			
			new Handle:hPanel = CreatePanel();
			
			FormatTime(sTime, sizeof(sTime), NULL_STRING, g_LJTop[iTable][iEntry][m_nTimestamp]); // "%B %d %Y %T"
			
			FormatEx(buf, sizeof(buf), "%s's %.2f -- %s\n ", g_LJTop[iTable][iEntry][m_strName], g_LJTop[iTable][iEntry][m_fDistance], sTime);
			
			SetPanelTitle(hPanel, buf);
			
			for(new i = 0; i < g_LJTop[iTable][iEntry][m_nStrafes] && i < 16; i++)
			{
				decl String:strStrafeKey[3];
				GetStrafeKey(strStrafeKey, g_LJTop[iTable][iEntry][m_StrafeDir][i]);
				
				DrawPanelTextF(hPanel, "%d   %s  %.2f  %.2f  %.2f  %.2f",
				i + 1,
				strStrafeKey,
				g_LJTop[iTable][iEntry][m_fStrafeGain][i], g_LJTop[iTable][iEntry][m_fStrafeLoss][i],
				float(g_LJTop[iTable][iEntry][m_nStrafeTicks][i]) / g_LJTop[iTable][iEntry][m_nTotalTicks] * 100,
				g_LJTop[iTable][iEntry][m_fStrafeSync][i]);
			}
			
			DrawPanelTextF(hPanel, "    %.2f%%", g_LJTop[iTable][iEntry][m_fSync]);
			
			SendPanelToClient(hPanel, client, RecordPanelHandler, 0);
			
			CloseHandle(hPanel);
		}
		
		case MenuAction_Cancel:
		{
			if(nItem == -3)
			{
				DisplayMenu(g_hLJTopMainMenu, client, 0);
			}
		}
	}
}

public RecordPanelHandler(Handle:hMenu, MenuAction:ma, client, nItem)
{
	switch(ma)
	{
		case MenuAction_Select:
		{
			DisplayMenu(g_hLJTopMainMenu, client, 0);
		}
	}
}

LJTopLoad(const String:strPath[])
{
	// Load top stats into memory from file
	
	/*decl String:strPath[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, strPath, PLATFORM_MAX_PATH, LJTOP_DIR);
	
	if(!DirExists(strPath))
	{
		PrintToServer("[LJTop] Dir %s nonexistent", strPath);
		return;
	}
	
	StrCat(strPath, sizeof(strPath), LJTOP_FILE);*/
	
	new Handle:hFile = OpenFile(strPath, "r");
	
	if(hFile == INVALID_HANDLE)
	{
		LogError("[LJTop] Error opening %s", strPath);
		return;
	}
	
	decl String:strLine[1024]; // omg, so big it is???
	decl String:strBuffers[LJTOP_MAX_NUM_STATS][64];
	
	ReadFileLine(hFile, strLine, sizeof(strLine));
	
	new /*nVersion, */MinStats;
	if(!strcmp(strLine, "1\n"))
	{
		//nVersion = 1;
		MinStats = LJTOP_MIN_NUM_STATS_1;
		
		if(IsEndOfFile(hFile))
		{
			PrintToServer("[LJTop] EOF");
			return;
		}
		
		ReadFileLine(hFile, strLine, sizeof(strLine));
	}
	else
	{
		//nVersion = 0;
		MinStats = LJTOP_MIN_NUM_STATS_0;
	}
	
	do
	{
		#if defined DEBUG
		PrintToServer("[LJTop] read %s", strLine);
		#endif
		
		static LJTOP_TABLE:nTable = LJTOP_TABLE:-1;
		static nEntry = 0;
		
		new bool:bTable;
		
		for(new LJTOP_TABLE:j; j < LT_END; j++)
		{
			decl String:strTag[16];
			Format(strTag, sizeof(strTag), "%s:\n", g_strLJTopTags[j]);
			if(!strcmp(strLine, strTag))
			{
				PrintToServer("[LJTop] read tag: %s", g_strLJTopTags[j]);
				nTable = j;
				nEntry = 0;
				bTable = true;
			}
		}
		
		if(bTable)
		{
			continue;
		}
		
		if(nTable == LJTOP_TABLE:-1)
		{
			PrintToServer("[LJTop] no table for line %s", strLine);
			continue;
		}
		
		if(nEntry >= LJTOP_NUM_ENTRIES)
		{
			PrintToServer("[LJTop] Too many entries for table %d; ignoring line", nTable);
			continue;
		}
		
		new nLength = ExplodeString(strLine, ";", strBuffers, LJTOP_MAX_NUM_STATS, sizeof(strBuffers[]), false);
		
		if(nLength < MinStats)
		{
			PrintToServer("[LJTop] Unexpected entry %d length (expected at least %d, got %d); ignoring line", nEntry + 1, MinStats, nLength);
			continue;
		}
		
		new k;
		strcopy(g_LJTop[nTable][nEntry][m_strName], 64, strBuffers[k++]);
		strcopy(g_LJTop[nTable][nEntry][m_strSteamID], 32, strBuffers[k++]);
		g_LJTop[nTable][nEntry][m_fDistance] = StringToFloat(strBuffers[k++]);
		g_LJTop[nTable][nEntry][m_fPrestrafe] = StringToFloat(strBuffers[k++]);
		g_LJTop[nTable][nEntry][m_nStrafes] = StringToInt(strBuffers[k++]);
		g_LJTop[nTable][nEntry][m_fSync] = StringToFloat(strBuffers[k++]);
		g_LJTop[nTable][nEntry][m_fMaxSpeed] = StringToFloat(strBuffers[k++]);
		g_LJTop[nTable][nEntry][m_nTotalTicks] = StringToInt(strBuffers[k++]);
		g_LJTop[nTable][nEntry][m_fHeightDelta] = StringToFloat(strBuffers[k++]);
		g_LJTop[nTable][nEntry][m_fSyncedAngle] = StringToFloat(strBuffers[k++]);
		g_LJTop[nTable][nEntry][m_fTotalAngle] = StringToFloat(strBuffers[k++]);
		g_LJTop[nTable][nEntry][m_fHeightDelta] = StringToFloat(strBuffers[k++]);
		g_LJTop[nTable][nEntry][m_fBlockDistance] = StringToFloat(strBuffers[k++]);
		g_LJTop[nTable][nEntry][m_fTrajectory] = StringToFloat(strBuffers[k++]);
		g_LJTop[nTable][nEntry][m_nTimestamp] = StringToInt(strBuffers[k++]);
		
		for(new l; l < (nLength - MinStats) / 5 && l < LJTOP_MAX_STRAFES && k < 64 - 5; l++)
		{
			g_LJTop[nTable][nEntry][m_StrafeDir][l] = GetStrafeDir(strBuffers[k++]);
			g_LJTop[nTable][nEntry][m_fStrafeGain][l] = StringToFloat(strBuffers[k++]);
			g_LJTop[nTable][nEntry][m_fStrafeLoss][l] = StringToFloat(strBuffers[k++]);
			g_LJTop[nTable][nEntry][m_nStrafeTicks][l] = StringToInt(strBuffers[k++]);
			g_LJTop[nTable][nEntry][m_fStrafeSync][l] = StringToFloat(strBuffers[k++]);
		}
		
		nEntry++;
		
		#if defined DEBUG
		PrintToServer("read %s %.2f in table %d", g_LJTop[nTable][nEntry][m_strName], g_LJTop[nTable][nEntry][m_fDistance], nTable);
		#endif
	}
	while(!IsEndOfFile(hFile) && ReadFileLine(hFile, strLine, sizeof(strLine)));
	
	CloseHandle(hFile);
}

LJTopSave()
{
	DB_SaveLJTop();
}

/*LJTopSave()
{
	// Delete old file and write entirely new one
	
	decl String:strPath[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, strPath, PLATFORM_MAX_PATH, LJTOP_DIR);
	
	if(!DirExists(strPath))
	{
		CreateDirectory(strPath, 0x3FF); // 0777
	}
	
	StrCat(strPath, sizeof(strPath), LJTOP_FILE);
	
	new Handle:hFile = OpenFile(strPath, "w"); // This will overwrite the old file
	
	if(hFile == INVALID_HANDLE)
	{
		PrintToServer("[LJTop] Error opening %s", strPath);
		return;
	}
	
	WriteFileLine(hFile, "1", false);
	
	decl String:buf[512], String:buf2[128];
	
	for(new nIndex; nIndex < _:LT_END; nIndex++)
	{
		Format(buf, sizeof(buf), "%s:", g_strLJTopTags[nIndex]);
		if(!WriteFileLine(hFile, buf, false))
		{
			PrintToServer("[LJTop] Error writing to %s", strPath);
			PrintToChatAll("[LJTop] Error saving ljtop");
		}
		
		for(new i; i < LJTOP_NUM_ENTRIES; i++)
		{
			if(g_LJTop[nIndex][i][m_strSteamID][0] == 0)
			{
				break;
			}
			
			Format(buf, sizeof(buf), "%s;%s;%f;%f;%d;%f;%f;%d;%f;%f;%f;%f;%f;%f;%d;",
			g_LJTop[nIndex][i][m_strName],
			g_LJTop[nIndex][i][m_strSteamID],
			g_LJTop[nIndex][i][m_fDistance],
			g_LJTop[nIndex][i][m_fPrestrafe],
			g_LJTop[nIndex][i][m_nStrafes],
			
			g_LJTop[nIndex][i][m_fSync],
			g_LJTop[nIndex][i][m_fMaxSpeed],
			g_LJTop[nIndex][i][m_nTotalTicks],
			g_LJTop[nIndex][i][m_fHeightDelta],
			g_LJTop[nIndex][i][m_fSyncedAngle],
			
			g_LJTop[nIndex][i][m_fTotalAngle],
			g_LJTop[nIndex][i][m_fHeightDelta],
			g_LJTop[nIndex][i][m_fBlockDistance],
			g_LJTop[nIndex][i][m_fTrajectory],
			g_LJTop[nIndex][i][m_nTimestamp]);
			
			for(new j; j < g_LJTop[nIndex][i][m_nStrafes] && j < LJTOP_MAX_STRAFES; j++)
			{
				decl String:strStrafeKey[4];
				GetStrafeKey(strStrafeKey, g_LJTop[nIndex][i][m_StrafeDir][j]);
				Format(buf2, sizeof(buf2), "%s;%f;%f;%d;%f;",
				strStrafeKey,
				g_LJTop[nIndex][i][m_fStrafeGain][j],
				g_LJTop[nIndex][i][m_fStrafeLoss][j],
				g_LJTop[nIndex][i][m_nStrafeTicks][j],
				g_LJTop[nIndex][i][m_fStrafeSync][j]);
				
				StrCat(buf, sizeof(buf), buf2);
			}
			
			if(!WriteFileLine(hFile, buf))
			{
				PrintToServer("[LJTop] Error writing to %s", strPath);
				PrintToChatAll("[LJTop] Error saving ljtop");
			}
		}
	}
	
	CloseHandle(hFile);
}*/

GetStrafeKey(String:str[], STRAFE_DIRECTION:Dir)
{
	if(Dir == SD_W)
	{
		strcopy(str, 3, "W");
	}
	else if(Dir == SD_A)
	{
		strcopy(str, 3, "A");
	}
	else if(Dir == SD_S)
	{
		strcopy(str, 3, "S");
	}
	else if(Dir == SD_D)
	{
		strcopy(str, 3, "D");
	}
	else if(Dir == SD_WA)
	{
		strcopy(str, 3, "WA");
	}
	else if(Dir == SD_WD)
	{
		strcopy(str, 3, "WD");
	}
	else if(Dir == SD_SA)
	{
		strcopy(str, 3, "SA");
	}
	else if(Dir == SD_SD)
	{
		strcopy(str, 3, "SD");
	}
}

STRAFE_DIRECTION:GetStrafeDir(String:str[])
{
	if(!strcmp(str, "W"))
	{
		return SD_W;
	}
	else if(!strcmp(str, "A"))
	{
		return SD_A;
	}
	else if(!strcmp(str, "S"))
	{
		return SD_S;
	}
	else if(!strcmp(str, "D"))
	{
		return SD_D;
	}
	else if(!strcmp(str, "WA"))
	{
		return SD_WA;
	}
	else if(!strcmp(str, "WD"))
	{
		return SD_WD;
	}
	else if(!strcmp(str, "SA"))
	{
		return SD_SA;
	}
	else if(!strcmp(str, "SD"))
	{
		return SD_SD;
	}
	
	return SD_NONE;
}

LJTopMoveDown(LJTOP_TABLE:nIndex, nOldPos, nPos)
{
	// move entries down for insertion
	for(new i = nOldPos - 1; i >= nPos; i--)
	{
		strcopy(g_LJTop[nIndex][i + 1][m_strName], 64, g_LJTop[nIndex][i][m_strName]);
		strcopy(g_LJTop[nIndex][i + 1][m_strSteamID], 32, g_LJTop[nIndex][i][m_strSteamID]);
		g_LJTop[nIndex][i + 1][m_fDistance] = g_LJTop[nIndex][i][m_fDistance];
		g_LJTop[nIndex][i + 1][m_fPrestrafe] = g_LJTop[nIndex][i][m_fPrestrafe];
		g_LJTop[nIndex][i + 1][m_nStrafes] = g_LJTop[nIndex][i][m_nStrafes];
		g_LJTop[nIndex][i + 1][m_fSync] = g_LJTop[nIndex][i][m_fSync];
		g_LJTop[nIndex][i + 1][m_fMaxSpeed] = g_LJTop[nIndex][i][m_fMaxSpeed];
		g_LJTop[nIndex][i + 1][m_nTotalTicks] = g_LJTop[nIndex][i][m_nTotalTicks];
		g_LJTop[nIndex][i + 1][m_fSyncedAngle] = g_LJTop[nIndex][i][m_fSyncedAngle];
		g_LJTop[nIndex][i + 1][m_fTotalAngle] = g_LJTop[nIndex][i][m_fTotalAngle];
		g_LJTop[nIndex][i + 1][m_fHeightDelta] = g_LJTop[nIndex][i][m_fHeightDelta];
		g_LJTop[nIndex][i + 1][m_fBlockDistance] = g_LJTop[nIndex][i][m_fBlockDistance];
		g_LJTop[nIndex][i + 1][m_fTrajectory] = g_LJTop[nIndex][i][m_fTrajectory];
		g_LJTop[nIndex][i + 1][m_nTimestamp] = g_LJTop[nIndex][i][m_nTimestamp];
		
		for(new j; j < g_LJTop[nIndex][i][m_nStrafes]; j++)
		{
			g_LJTop[nIndex][i + 1][m_StrafeDir][j] = g_LJTop[nIndex][i][m_StrafeDir][j];
			g_LJTop[nIndex][i + 1][m_fStrafeGain][j] = g_LJTop[nIndex][i][m_fStrafeGain][j];
			g_LJTop[nIndex][i + 1][m_fStrafeLoss][j] = g_LJTop[nIndex][i][m_fStrafeLoss][j];
			g_LJTop[nIndex][i + 1][m_nStrafeTicks][j] = g_LJTop[nIndex][i][m_nStrafeTicks][j];
			g_LJTop[nIndex][i + 1][m_fStrafeSync][j] = g_LJTop[nIndex][i][m_fStrafeSync][j];
		}
	}
}

LJTopMoveUp(LJTOP_TABLE:nIndex, nPos)
{
	for(new i = nPos; i < 9; i++)
	{
		strcopy(g_LJTop[nIndex][i][m_strName], 64, g_LJTop[nIndex][i + 1][m_strName]);
		strcopy(g_LJTop[nIndex][i][m_strSteamID], 32, g_LJTop[nIndex][i + 1][m_strSteamID]);
		g_LJTop[nIndex][i][m_fDistance] = g_LJTop[nIndex][i + 1][m_fDistance];
		g_LJTop[nIndex][i][m_fPrestrafe] = g_LJTop[nIndex][i + 1][m_fPrestrafe];
		g_LJTop[nIndex][i][m_nStrafes] = g_LJTop[nIndex][i + 1][m_nStrafes];
		g_LJTop[nIndex][i][m_fSync] = g_LJTop[nIndex][i + 1][m_fSync];
		g_LJTop[nIndex][i][m_fMaxSpeed] = g_LJTop[nIndex][i + 1][m_fMaxSpeed];
		g_LJTop[nIndex][i][m_nTotalTicks] = g_LJTop[nIndex][i + 1][m_nTotalTicks];
		g_LJTop[nIndex][i][m_fSyncedAngle] = g_LJTop[nIndex][i + 1][m_fSyncedAngle];
		g_LJTop[nIndex][i][m_fTotalAngle] = g_LJTop[nIndex][i + 1][m_fTotalAngle];
		g_LJTop[nIndex][i][m_fHeightDelta] = g_LJTop[nIndex][i + 1][m_fHeightDelta];
		g_LJTop[nIndex][i][m_fBlockDistance] = g_LJTop[nIndex][i + 1][m_fBlockDistance];
		g_LJTop[nIndex][i][m_fTrajectory] = g_LJTop[nIndex][i + 1][m_fTrajectory];
		g_LJTop[nIndex][i][m_nTimestamp] = g_LJTop[nIndex][i + 1][m_nTimestamp];
		
		for(new j; j < g_LJTop[nIndex][i + 1][m_nStrafes]; j++)
		{
			g_LJTop[nIndex][i][m_StrafeDir][j] = g_LJTop[nIndex][i + 1][m_StrafeDir][j];
			g_LJTop[nIndex][i][m_fStrafeGain][j] = g_LJTop[nIndex][i + 1][m_fStrafeGain][j];
			g_LJTop[nIndex][i][m_fStrafeLoss][j] = g_LJTop[nIndex][i + 1][m_fStrafeLoss][j];
			g_LJTop[nIndex][i][m_nStrafeTicks][j] = g_LJTop[nIndex][i + 1][m_nStrafeTicks][j];
			g_LJTop[nIndex][i][m_fStrafeSync][j] = g_LJTop[nIndex][i + 1][m_fStrafeSync][j];
		}
	}
	
	// Clear last entry to prevent duplicates
	strcopy(g_LJTop[nIndex][9][m_strName], 64, "");
	strcopy(g_LJTop[nIndex][9][m_strSteamID], 32, "");
	g_LJTop[nIndex][9][m_fDistance] = 0.0;
	g_LJTop[nIndex][9][m_fPrestrafe] = 0.0;
	g_LJTop[nIndex][9][m_nStrafes] = 0;
	g_LJTop[nIndex][9][m_fSync] = 0.0;
	g_LJTop[nIndex][9][m_fMaxSpeed] = 0.0;
	g_LJTop[nIndex][9][m_nTotalTicks] = 0;
	g_LJTop[nIndex][9][m_fSyncedAngle] = 0.0;
	g_LJTop[nIndex][9][m_fTotalAngle] = 0.0;
	g_LJTop[nIndex][9][m_fHeightDelta] = 0.0;
	g_LJTop[nIndex][9][m_fBlockDistance] = 0.0;
	g_LJTop[nIndex][9][m_nTimestamp] = 0;
	
	for(new j; j < g_LJTop[nIndex][9][m_nStrafes]; j++)
	{
		g_LJTop[nIndex][9][m_StrafeDir][j] = SD_NONE;
		g_LJTop[nIndex][9][m_fStrafeGain][j] = 0.0;
		g_LJTop[nIndex][9][m_fStrafeLoss][j] = 0.0;
		g_LJTop[nIndex][9][m_nStrafeTicks][j] = 0;
		g_LJTop[nIndex][9][m_fStrafeSync][j] = 0.0;
	}
}

LJTopUpdate(client)
{
	if(g_PlayerStates[client][JumpType] == JT_LONGJUMP)
	{
		if(g_PlayerStates[client][fJumpDistance] > g_LJTop[LT_LJ][LJTOP_NUM_ENTRIES - 1][m_fDistance])
		{
			LJTopUpdateTable(client, LT_LJ);
		}
		if(g_PlayerStates[client][bBlockMode] && !g_PlayerStates[client][bFailedBlock] && g_PlayerStates[client][fBlockDistance] > g_LJTop[LT_BLOCKLJ][LJTOP_NUM_ENTRIES - 1][m_fBlockDistance])
		{
			LJTopUpdateTable(client, LT_BLOCKLJ);
		}
		if(g_PlayerStates[client][JumpDir] == JD_SIDEWAYS && g_PlayerStates[client][fJumpDistance] > g_LJTop[LT_SWLJ][LJTOP_NUM_ENTRIES - 1][m_fDistance])
		{
			LJTopUpdateTable(client, LT_SWLJ);
		}
		if(g_PlayerStates[client][JumpDir] == JD_BACKWARDS && g_PlayerStates[client][fJumpDistance] > g_LJTop[LT_BWLJ][LJTOP_NUM_ENTRIES - 1][m_fDistance])
		{
			LJTopUpdateTable(client, LT_BWLJ);
		}
	}
	else if(g_PlayerStates[client][JumpType] == JT_COUNTJUMP && g_PlayerStates[client][fJumpDistance] > g_LJTop[LT_CJ][LJTOP_NUM_ENTRIES - 1][m_fDistance])
	{
		LJTopUpdateTable(client, LT_CJ);
	}
	else if(g_PlayerStates[client][JumpType] == JT_BHOPJUMP && g_PlayerStates[client][fJumpDistance] > g_LJTop[LT_BJ][LJTOP_NUM_ENTRIES - 1][m_fDistance] && (!g_PlayerStates[client][bStamina] || g_bLJTopAllowEasyBJ)) // There's no such thing as an easy bj, only sore jaws, pubes down your throat and the taste of acidic ejaculate
	{
		LJTopUpdateTable(client, LT_BJ);
	}
	else if(g_PlayerStates[client][JumpType] == JT_LADDERJUMP && g_PlayerStates[client][fJumpDistance] > g_LJTop[LT_LAJ][LJTOP_NUM_ENTRIES - 1][m_fDistance])
	{
		LJTopUpdateTable(client, LT_LAJ);
	}
	else if(g_PlayerStates[client][JumpType] == JT_BHOP && !g_bEnableBunnyHopping && g_PlayerStates[client][fJumpDistance] > g_LJTop[LT_STRAFEBHOP][LJTOP_NUM_ENTRIES - 1][m_fDistance])
	{
		LJTopUpdateTable(client, LT_STRAFEBHOP);
	}
}	
	
LJTopUpdateTable(client, LJTOP_TABLE:nLJTopTable)
{
	decl String:strName[64], String:strSteamID[32];
	GetClientName(client, strName, sizeof(strName));
	GetClientAuthString(client, strSteamID, sizeof(strSteamID));
	
	decl nIndex;
	while((nIndex = FindCharInString(strName, ';')) != -1)
	{
		strName[nIndex] = '-';
	}
	
	new nPos = 0;
	
	while(nPos < 9 &&
	(nLJTopTable == LT_BLOCKLJ ? g_PlayerStates[client][fBlockDistance] < g_LJTop[nLJTopTable][nPos][m_fBlockDistance] ||
	(g_PlayerStates[client][fBlockDistance] == g_LJTop[nLJTopTable][nPos][m_fBlockDistance] &&
	g_PlayerStates[client][fJumpDistance] < g_LJTop[nLJTopTable][nPos][m_fDistance]) :
	g_PlayerStates[client][fJumpDistance] < g_LJTop[nLJTopTable][nPos][m_fDistance])) // longest statement in history
	{
		if(!strcmp(g_LJTop[nLJTopTable][nPos][m_strSteamID], strSteamID))
		{
			// player already has better record
			g_LJTop[nLJTopTable][nPos][m_strName] = strName; // update name
			return;
		}
		
		nPos++;
	}
	
	new nOldPos = -1;
	
	for(new i = 0; i < 10; i++)
	{
		if(!strcmp(g_LJTop[nLJTopTable][i][m_strSteamID], strSteamID))
		{
			nOldPos = i;
			break;
		}
	}
	
	new bool:bSilent;
	
	if(/*g_LJTop[nLJTopTable][nPos][m_strSteamID][0] == 0 || */g_PlayerStates[client][fJumpDistance] < g_fLJMin ||
	(nLJTopTable == LT_BLOCKLJ && nOldPos == nPos && g_PlayerStates[client][fBlockDistance] == g_LJTop[nLJTopTable][nPos][m_fBlockDistance]))
	{
		bSilent = true;
	}
	
	/*
	enum TopStats
	{
		String:m_strName[64 / 4],
		String:m_strSteamID[32 / 4],
		Float:m_fDistance,
		Float:m_fPrestrafe,
		m_nStrafes,
		Float:m_fSync,
		Float:m_fMaxSpeed,
		m_nTotalTicks,
		Float:m_fSyncedAngle,
		Float:m_fTotalAngle,
		Float:m_fHeightDelta,
		Float:m_fBlockDistance,
		Float:m_fTrajectory,
		m_nTimestamp,
		
		m_StrafeDir[LJTOP_MAX_STRAFES],
		Float:m_fStrafeGain[LJTOP_MAX_STRAFES],
		Float:m_fStrafeLoss[LJTOP_MAX_STRAFES],
		m_nStrafeTicks[LJTOP_MAX_STRAFES],
		Float:m_fStrafeSync[LJTOP_MAX_STRAFES],
	}
	*/
	
	LJTopMoveDown(nLJTopTable, nOldPos == -1 ? 9 : nOldPos, nPos);
	
	// overwrite entry
	strcopy(g_LJTop[nLJTopTable][nPos][m_strName], 64, strName);
	strcopy(g_LJTop[nLJTopTable][nPos][m_strSteamID], 32, strSteamID);
	g_LJTop[nLJTopTable][nPos][m_fDistance] = g_PlayerStates[client][fJumpDistance];
	g_LJTop[nLJTopTable][nPos][m_fPrestrafe] = g_PlayerStates[client][fPrestrafe];
	g_LJTop[nLJTopTable][nPos][m_nStrafes] = g_PlayerStates[client][nStrafes];
	g_LJTop[nLJTopTable][nPos][m_fSync] = g_PlayerStates[client][fSync];
	g_LJTop[nLJTopTable][nPos][m_fMaxSpeed] = g_PlayerStates[client][fMaxSpeed];
	g_LJTop[nLJTopTable][nPos][m_nTotalTicks] = g_PlayerStates[client][nTotalTicks];
	g_LJTop[nLJTopTable][nPos][m_fSyncedAngle] = g_PlayerStates[client][fSyncedAngle];
	g_LJTop[nLJTopTable][nPos][m_fTotalAngle] = g_PlayerStates[client][fTotalAngle];
	g_LJTop[nLJTopTable][nPos][m_fHeightDelta] = g_PlayerStates[client][fHeightDelta];
	g_LJTop[nLJTopTable][nPos][m_fBlockDistance] = g_PlayerStates[client][fBlockDistance];
	g_LJTop[nLJTopTable][nPos][m_fTrajectory] = g_PlayerStates[client][fTrajectory];
	g_LJTop[nLJTopTable][nPos][m_nTimestamp] = GetTime();
	
	for(new j; j < g_PlayerStates[client][nStrafes]; j++)
	{
		g_LJTop[nLJTopTable][nPos][m_StrafeDir][j] = g_PlayerStates[client][StrafeDir][j];
		g_LJTop[nLJTopTable][nPos][m_fStrafeGain][j] = g_PlayerStates[client][fStrafeGain][j];
		g_LJTop[nLJTopTable][nPos][m_fStrafeLoss][j] = g_PlayerStates[client][fStrafeLoss][j];
		g_LJTop[nLJTopTable][nPos][m_nStrafeTicks][j] = g_PlayerStates[client][nStrafeTicks][j];
		g_LJTop[nLJTopTable][nPos][m_fStrafeSync][j] = g_PlayerStates[client][fStrafeSync][j];
	}
	
	LJTopSave();
	LJTopCreateMenu(nLJTopTable);
	
	if(bSilent)
	{
		return;
	}
	
	if(nLJTopTable == LT_BLOCKLJ)
	{
		CPrintToChatAll("%s {green}%s top {default}%d{green} in block lj top with {default}%.2f{green} longjump at {default}%.1f{green} block!",
		strName, nPos == nOldPos ? "has improved their" : "is now", nPos + 1, g_PlayerStates[client][fJumpDistance], g_PlayerStates[client][fBlockDistance]);
	}
	else
	{
		CPrintToChatAll("%s {green}%s top {default}%d{green} in %s top with {default}%.2f{green} %s!",
		strName, nPos == nOldPos ? "has improved their" : "is now", nPos + 1, g_strLJTopOutput[nLJTopTable], g_PlayerStates[client][fJumpDistance], g_strJumpTypeLwr[g_PlayerStates[client][JumpType]]);
	}
}

public Native_CancelJump(Handle:hPlugin, nParams)
{
	CancelJump(GetNativeCell(1));
}

CancelJump(client)
{
	g_PlayerStates[client][bOnGround] = true;
}

public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	PlayerJump(client);
}

// cba with another enum so JT_LONGJUMP = jump, JT_DROP = slide off edge, JT_LADDERJUMP = ladder
PlayerJump(client, JUMP_TYPE:JumpType2 = JT_LONGJUMP)
{
	g_PlayerStates[client][bOnGround] = false;
	
	new Float:fTime = GetGameTime();
	if(fTime - g_PlayerStates[client][fLandTime] < BHOP_TIME)//if((g_PlayerStates[client][nLastAerialTick] - GetGameTickCount()) * GetTickInterval() < BHOP_TIME)
	{
		g_PlayerStates[client][nBhops]++;
	}
	else
	{
		g_PlayerStates[client][nBhops] = 0;
		
		// Only reset flags when jump chain stops so that players can't e.g. boost in the first jump and get a high distance on the next in a bhopjump
		g_PlayerStates[client][IllegalJumpFlags] = IJF_NONE;
	}
	
	g_PlayerStates[client][fLastJumpHeightDelta] = g_PlayerStates[client][fHeightDelta];
	
	for(new i = 0; i < g_PlayerStates[client][nStrafes] && i < MAX_STRAFES; i++)
	{
		g_PlayerStates[client][fStrafeGain][i] = 0.0;
		g_PlayerStates[client][fStrafeLoss][i] = 0.0;
		g_PlayerStates[client][fStrafeSync][i] = 0.0;
		g_PlayerStates[client][nStrafeTicks][i] = 0;
		g_PlayerStates[client][nStrafeTicksSynced][i] = 0;
	}
	
	// Reset stuff
	g_PlayerStates[client][JumpDir] = JD_NONE;
	g_PlayerStates[client][CurStrafeDir] = SD_NONE;
	g_PlayerStates[client][nStrafes] = 0;
	g_PlayerStates[client][fSync] = 0.0;
	g_PlayerStates[client][fMaxSpeed] = 0.0;
	g_PlayerStates[client][fJumpHeight] = 0.0;
	g_PlayerStates[client][nTotalTicks] = 0;
	g_PlayerStates[client][fTotalAngle] = 0.0;
	g_PlayerStates[client][fSyncedAngle] = 0.0;
	g_PlayerStates[client][fEdge] = -1.0;
	g_PlayerStates[client][fBlockDistance] = -1.0;
	g_PlayerStates[client][bStamina] = !GetEntPropFloat(client, Prop_Send, "m_flStamina");
	g_PlayerStates[client][bFailedBlock] = false;
	g_PlayerStates[client][fTrajectory] = 0.0;
	g_PlayerStates[client][fGain] = 0.0;
	g_PlayerStates[client][fLoss] = 0.0;
	g_PlayerStates[client][nJumpTick] = GetGameTickCount();
	
	if(JumpType2 == JT_LONGJUMP && g_PlayerStates[client][bBlockMode])
	{
		g_PlayerStates[client][fBlockDistance] = GetBlockDistance(client);
	}
	
	
	g_PlayerStates[client][LastJumpType] = g_PlayerStates[client][JumpType];
	
	// Determine jump type
	if(JumpType2 == JT_DROP || JumpType2 == JT_LADDERJUMP)
	{
		g_PlayerStates[client][JumpType] = JumpType2;
	}
	else
	{
		if(g_PlayerStates[client][nBhops] > 1)
		{
			g_PlayerStates[client][JumpType] = JT_BHOP;
		}
		else if(g_PlayerStates[client][nBhops] == 1)
		{
			if(g_PlayerStates[client][LastJumpType] == JT_DROP)
			{
				g_PlayerStates[client][fWJDropPre] = g_PlayerStates[client][fPrestrafe];
				g_PlayerStates[client][JumpType] = JT_WEIRDJUMP;
			}
			else if(g_PlayerStates[client][fLastJumpHeightDelta] > HEIGHT_DELTA_MIN(JT_LONGJUMP))
			{
				g_PlayerStates[client][JumpType] = JT_BHOPJUMP;
			}
			else
			{
				g_PlayerStates[client][JumpType] = JT_BHOP;
			}
		}
		else
		{
			if(GetEntProp(client, Prop_Send, "m_bDucking", 1))
			{
				g_PlayerStates[client][JumpType] = JT_COUNTJUMP;
			}
			else
			{
				g_PlayerStates[client][JumpType] = JT_LONGJUMP;
			}
		}
	}
	
	// Jumpoff origin
	new Float:vOrigin[3];
	GetClientAbsOrigin(client, vOrigin);
	Array_Copy(vOrigin, g_PlayerStates[client][vJumpOrigin], 3);
	
	// Prestrafe
	g_PlayerStates[client][fPrestrafe] = GetSpeed(client);
	
	if(g_PlayerStates[client][JumpType] == JT_LONGJUMP)
	{
		if(g_PlayerStates[client][fPrestrafe] > g_fLJMaxPrestrafe)
		{
			g_PlayerStates[client][IllegalJumpFlags] |= IJF_PRESTRAFE;
		}
		
		if(!g_bLJScoutStats && (g_fMaxspeed > 250.0 && GetEntPropFloat(client, Prop_Data, "m_flMaxspeed") > 250.0))
		{
			new String:strPlayerWeapon[32];
			GetClientWeapon(client, strPlayerWeapon, sizeof(strPlayerWeapon));
			
			if(!strcmp(strPlayerWeapon, "weapon_scout") || strPlayerWeapon[0] == 0)
			{
				g_PlayerStates[client][IllegalJumpFlags] |= IJF_SCOUT;
			}
		}
	}
	
	if(JumpType2 == JT_LONGJUMP)
	{
		g_PlayerStates[client][fEdge] = GetEdge(client);
	}
	
	if(g_PlayerStates[client][bLJEnabled] && g_PlayerStates[client][bBeam])
	{
		StopBeam(client);
		
		g_PlayerStates[client][bBeam] = true;
	}
}

StopBeam(client)
{
	g_PlayerStates[client][bBeam] = false;
}

GetJumpDistance(client)
{
	new Float:vCurOrigin[3];
	GetClientAbsOrigin(client, vCurOrigin);
	
	g_PlayerStates[client][fHeightDelta] = vCurOrigin[2] - g_PlayerStates[client][vJumpOrigin][2];
	
	vCurOrigin[2] = 0.0;
	
	new Float:v[3];
	Array_Copy(g_PlayerStates[client][vJumpOrigin], v, 3);
	
	v[2] = 0.0;
	
	if(g_PlayerStates[client][JumpType] == JT_LADDERJUMP)
	{
		g_PlayerStates[client][fJumpDistance] = GetVectorDistance(v, vCurOrigin);
	}
	else
	{
		g_PlayerStates[client][fJumpDistance] = GetVectorDistance(v, vCurOrigin) + 32;
	}
	
	g_PlayerStates[client][bDuck] = bool:GetEntProp(client, Prop_Send, "m_bDucked", 1);
	//g_PlayerStates[client][nTotalTicks] = GetGameTickCount() - g_PlayerStates[client][nJumpTick];
}

GetJumpDistanceLastTick(client)
{
	new Float:vCurOrigin[3];
	Array_Copy(g_PlayerStates[client][vLastOrigin], vCurOrigin, 3);
	
	g_PlayerStates[client][fHeightDelta] = vCurOrigin[2] - g_PlayerStates[client][vJumpOrigin][2];
	
	vCurOrigin[2] = 0.0;
	
	new Float:v[3];
	Array_Copy(g_PlayerStates[client][vJumpOrigin], v, 3);
	
	v[2] = 0.0;
	
	g_PlayerStates[client][fJumpDistance] = GetVectorDistance(v, vCurOrigin) + 32.0;
	
	g_PlayerStates[client][bDuck] = g_PlayerStates[client][bSecondLastDuckState];
	//g_PlayerStates[client][nTotalTicks] = GetGameTickCount() - g_PlayerStates[client][nJumpTick];
	//g_PlayerStates[client][nTotalTicks] -= 1;
}

CheckValidJump(client)
{
	new Float:vOrigin[3];
	GetClientAbsOrigin(client, vOrigin);
	
	// Check gravity
	new Float:fGravity = GetEntPropFloat(client, Prop_Data, "m_flGravity");
	if(fGravity != 1.0 && fGravity != 0.0)
	{
		g_PlayerStates[client][IllegalJumpFlags] |= IJF_GRAVITY;
	}
	
	// Check speed
	if(GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") != 1.0)
	{
		g_PlayerStates[client][IllegalJumpFlags] |= IJF_LAGGEDMOVEMENTVALUE;
	}
	
	if(GetEntityMoveType(client) & MOVETYPE_NOCLIP)
	{
		g_PlayerStates[client][IllegalJumpFlags] |= IJF_NOCLIP;
	}
	
	
	// Teleport check
	new Float:vLastOrig[3], Float:vLastVel[3], Float:vVel[3];
	Array_Copy(g_PlayerStates[client][vLastOrigin], vLastOrig, 3);
	Array_Copy(g_PlayerStates[client][vLastVelocity], vLastVel, 3);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
	
	vLastOrig[2] = 0.0;
	vOrigin[2] = 0.0;
	vLastVel[2] = 0.0;
	vVel[2] = 0.0;
	
	// If the player moved further than their last velocity, they teleported
	// It's slightly off, so adjust velocity
	// pretty suk // less suk
	/*
	teleported 2.461413, 2.461400
	teleported 2.468606, 2.468604
	teleported 2.488778, 2.488739
	teleported 2.517628, 2.517453
	teleported 2.534332, 2.534170
	teleported 2.550610, 2.550508
	teleported 2.567417, 2.567395
	teleported 2.598604, 2.598514
	teleported 2.612708, 2.612616
	teleported 2.633581, 2.633533
	teleported 2.634170, 2.634044
	teleported 2.646703, 2.646473
	teleported 2.657407, 2.657327
	teleported 2.669471, 2.669248
	teleported 2.710047, 2.709968
	teleported 2.723108, 2.722937
	teleported 2.742104, 2.742006
	teleported 2.744069, 2.743859
	teleported 2.751010, 2.750807
	teleported 2.759773, 2.759721
	teleported 2.771660, 2.771600
	teleported 2.822698, 2.822640
	teleported 2.839976, 2.839771
	teleported 2.839976, 2.839771
	teleported 2.850264, 2.850194
	teleported 2.882310, 2.882229
	teleported 2.894205, 2.894115
	teleported 2.905041, 2.905009
	teleported 2.920642, 2.920416
	*/
	if(GetVectorDistance(vLastOrig, vOrigin) > GetVectorLength(vVel) / (1.0 / GetTickInterval()) + 0.001)
	{
		#if defined DEBUG
		PrintToChat(client, "teleported %f, %f (%f)", GetVectorDistance(vLastOrig, vOrigin), GetVectorLength(vVel) / (1.0 / GetTickInterval()) + 0.001, GetVectorLength(vLastVel) / (1.0 / GetTickInterval()));
		#endif
		
		if(g_PlayerStates[client][bBlockMode])
		{
			if(g_PlayerStates[client][bFailedBlock])
			{
				#if defined DEBUG
				PrintToChat(client, "failedblock; returning");
				#endif
				
				return;
			}
			else
			{
				#if defined DEBUG
				PrintToChat(client, "failedblocklongjump 3 tp %s %f %f %d",
				g_PlayerStates[client][vLastOrigin][2] >= g_PlayerStates[client][vJumpOrigin][2] + HEIGHT_DELTA_MIN(JT_LONGJUMP) ? "saved" : "not saved",
				g_PlayerStates[client][vLastOrigin][2], g_PlayerStates[client][vJumpOrigin][2] + HEIGHT_DELTA_MIN(JT_LONGJUMP), GetGameTickCount());
				#endif
				
				if(g_PlayerStates[client][vLastOrigin][2] >= g_PlayerStates[client][vJumpOrigin][2] + HEIGHT_DELTA_MIN(JT_LONGJUMP))
				{
					GetJumpDistanceLastTick(client);
					g_PlayerStates[client][bFailedBlock] = true;
					
					return;
				}
			}
		}
		
		g_PlayerStates[client][IllegalJumpFlags] |= IJF_TELEPORT;
	}
}

TBAnglesToUV(Float:vOut[3], const Float:vAngles[3])
{
	vOut[0] = Cosine(vAngles[1] * FLOAT_PI / 180.0) * Cosine(vAngles[0] * FLOAT_PI / 180.0);
	vOut[1] = Sine(vAngles[1] * FLOAT_PI / 180.0) * Cosine(vAngles[0] * FLOAT_PI / 180.0);
	vOut[2] = -Sine(vAngles[0] * FLOAT_PI / 180.0);
}

_OnPlayerRunCmd(client, buttons, const Float:vOrigin[3], const Float:vAngles[3], const Float:vVelocity[3], bool:bDucked, bool:bGround)
{
	if(g_PlayerStates[client][GapSelectionMode] != GSM_NONE)
	{
		GapSelect(client, buttons);
	}
	
	// Manage spectators
	if(IsClientObserver(client))
	{
		if(g_PlayerStates[client][bLJEnabled])
		{
			new nObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
			
			if(nObserverMode == 4 || nObserverMode == 3)
			{
				new nTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				
				if(g_PlayerStates[client][nSpectatorTarget] != nTarget)
				{
					if(g_PlayerStates[client][nSpectatorTarget] != -1 && g_PlayerStates[client][nSpectatorTarget] > 0 && g_PlayerStates[client][nSpectatorTarget] < MaxClients)
					{
						g_PlayerStates[g_PlayerStates[client][nSpectatorTarget]][nSpectators]--;
					}
					
					g_PlayerStates[nTarget][nSpectators]++;
					g_PlayerStates[client][nSpectatorTarget] = nTarget;
				}
			}
		}
		else
		{
			if(g_PlayerStates[client][nSpectatorTarget] != -1)
			{
				if(g_PlayerStates[client][nSpectatorTarget] > 0 && g_PlayerStates[client][nSpectatorTarget] < MaxClients)
				{
					g_PlayerStates[g_PlayerStates[client][nSpectatorTarget]][nSpectators]--;
				}
				g_PlayerStates[client][nSpectatorTarget] = -1;
			}
		}
		
		return;
	}
	else
	{
		if(g_PlayerStates[client][nSpectatorTarget] != -1)
		{
			g_PlayerStates[g_PlayerStates[client][nSpectatorTarget]][nSpectators]--;
			g_PlayerStates[client][nSpectatorTarget] = -1;
		}
	}
	
	if(!g_PlayerStates[client][bOnGround])
		CheckValidJump(client);
	
	
	// BEAMU
	if(g_PlayerStates[client][bBeam] && !bGround && (g_PlayerStates[client][bShowBhopStats] || g_PlayerStates[client][nBhops] < 2))
	{
		new Float:v1[3], Float:v2[3];
		v1[0] = vOrigin[0];
		v1[1] = vOrigin[1];
		v1[2] = g_PlayerStates[client][vJumpOrigin][2];
		
		v2[0] = g_PlayerStates[client][vLastOrigin][0];
		v2[1] = g_PlayerStates[client][vLastOrigin][1];
		v2[2] = g_PlayerStates[client][vJumpOrigin][2];
		
		new color[4] = {255, 255, 255, 100};
		
		if(g_PlayerStates[client][CurStrafeDir] % STRAFE_DIRECTION:2)
		{
			color[0] = 128;
			color[1] = 128;
		}
		
		TE_SetupBeamPoints(v1, v2, g_BeamModel, 0, 0, 0, 10.0, 3.0, 3.0, 10, 0.0, color, 0);
		TE_SendToClient(client);
	}
	
	
	// Call PlayerJump for ladder jumps or walking off the edge
	if(GetEntityMoveType(client) == MOVETYPE_LADDER)
	{
		g_PlayerStates[client][bOnLadder] = true;
	}
	else
	{
		if(g_PlayerStates[client][bOnLadder])
		{
			PlayerJump(client, JT_LADDERJUMP);
		}
		
		g_PlayerStates[client][bOnLadder] = false;
	}
	
	if(!bGround)
	{
		if(g_PlayerStates[client][bOnGround])
		{
			PlayerJump(client, JT_DROP);
		}
	}
	
	
	if(g_PlayerStates[client][bOnGround] || g_PlayerStates[client][nStrafes] >= MAX_STRAFES || (!g_PlayerStates[client][bLJEnabled] && !g_PlayerStates[client][nSpectators]) || g_PlayerStates[client][bFailedBlock])
	{
		// dumb language
		if((bGround || g_PlayerStates[client][bOnLadder]) && !g_PlayerStates[client][bOnGround])
		{
			PlayerLand(client);
		}
		
		#if defined LJSERV
		if(g_PlayerStates[client][bLJEnabled] && g_PlayerStates[client][bShowPrestrafeHint])
		{
			PrintPrestrafeHint(client);
		}
		#endif
		
		return;
	}
	
	
	if(!bGround)
	{
		g_PlayerStates[client][nLastAerialTick] = GetGameTickCount();
		
		if(GetVSpeed(vVelocity) > g_PlayerStates[client][fMaxSpeed])
			g_PlayerStates[client][fMaxSpeed] = GetVSpeed(vVelocity);
		
		if(vOrigin[2] - g_PlayerStates[client][vJumpOrigin][2] > g_PlayerStates[client][fJumpHeight])
			g_PlayerStates[client][fJumpHeight] = vOrigin[2] - g_PlayerStates[client][vJumpOrigin][2];
		
		// Record the failed distance, but since it will trigger if you duck late, only save it if it's certain that the player will not land
		if(g_PlayerStates[client][bBlockMode] &&
		!g_PlayerStates[client][bFailedBlock] &&
		(bDucked && vOrigin[2] <= g_PlayerStates[client][vJumpOrigin][2] + 1.0 ||
		!bDucked && vOrigin[2] <= g_PlayerStates[client][vJumpOrigin][2] + 1.5) &&
		vOrigin[2] >= g_PlayerStates[client][vJumpOrigin][2] + HEIGHT_DELTA_MIN(JT_LONGJUMP))
		{
			GetJumpDistance(client);
			#if defined DEBUG
			PrintToChat(client, "getting failed dist, %d, %f, %f",
			vOrigin[2] >= g_PlayerStates[client][vJumpOrigin][2] + HEIGHT_DELTA_MIN(JT_LONGJUMP), vOrigin[2], g_PlayerStates[client][vJumpOrigin][2] + HEIGHT_DELTA_MIN(JT_LONGJUMP));
			#endif
		}
		
			
		#if defined DEBUG
		if(vOrigin[2] <= g_PlayerStates[client][vJumpOrigin][2])
		{
			PrintToChat(client, "%d, %d, %d", bDucked, vOrigin[2] <= g_PlayerStates[client][vJumpOrigin][2] + HEIGHT_DELTA_MIN(JT_LONGJUMP), !bDucked && vOrigin[2] <= g_PlayerStates[client][vJumpOrigin][2] - 10.5);
		}
		#endif
		
		// Check if the player is still capable of landing
		if(g_PlayerStates[client][bBlockMode] && !g_PlayerStates[client][bFailedBlock] && 
		(bDucked && vOrigin[2] <= g_PlayerStates[client][vJumpOrigin][2] + HEIGHT_DELTA_MIN(JT_LONGJUMP)/* + 1.0*/ || // You land at 0.79 elevation when ducking
		!bDucked && vOrigin[2] <= g_PlayerStates[client][vJumpOrigin][2] - 10.5))
		// Ducking increases your origin by 8.5; you land at 1.47 units elevation when ducking, so around 10.0; 10.5 for good measure
		{
			StopBeam(client);
			
			g_PlayerStates[client][bDuck] = bDucked;
			g_PlayerStates[client][bFailedBlock] = true;
			
			#if defined DEBUG
			PrintToChat(client, "failedblocklongjump 1 %.2f, %d", vOrigin[2] - g_PlayerStates[client][vJumpOrigin][2], GetGameTickCount());
			#endif
			
			if(bGround && !g_PlayerStates[client][bOnGround])
			{
				PlayerLand(client);
			}
			
			#if defined LJSERV
			if(g_PlayerStates[client][bLJEnabled] && g_PlayerStates[client][bShowPrestrafeHint])
			{
				PrintPrestrafeHint(client);
			}
			#endif
			
			return;
		}
	}
	
	
	if(g_PlayerStates[client][JumpDir] == JD_BACKWARDS)
	{
		new Float:vAnglesUV[3];
		TBAnglesToUV(vAnglesUV, vAngles);
		
		new Float:vVelocityDir[3];
		vVelocityDir = vVelocity;
		vVelocityDir[2] = 0.0;
		NormalizeVector(vVelocityDir, vVelocityDir);
		
		if(ArcCosine(GetVectorDotProduct(vAnglesUV, vVelocityDir)) < FLOAT_PI / 2)
		{
			g_PlayerStates[client][JumpDir] = JD_NORMAL;
		}
	}
	
	// check for multiple keys -- it will spam strafes when multiple are held without this
	new nButtonCount;
	if(buttons & IN_MOVELEFT)
		nButtonCount++;
	if(buttons & IN_MOVERIGHT)
		nButtonCount++;
	if(buttons & IN_FORWARD)
		nButtonCount++;
	if(buttons & IN_BACK)
		nButtonCount++;
	
	if(nButtonCount == 1)
	{
		if(g_PlayerStates[client][CurStrafeDir] != SD_A && buttons & IN_MOVELEFT)
		{
			if(g_PlayerStates[client][JumpDir] == JD_NONE)
			{
				new Float:vAnglesUV[3];
				TBAnglesToUV(vAnglesUV, vAngles);
				
				new Float:vVelocityDir[3];
				vVelocityDir = vVelocity;
				vVelocityDir[2] = 0.0;
				NormalizeVector(vVelocityDir, vVelocityDir);
				
				if(ArcCosine(GetVectorDotProduct(vAnglesUV, vVelocityDir)) > FLOAT_PI / 2)
				{
					g_PlayerStates[client][JumpDir] = JD_BACKWARDS;
				}
				else
				{
					g_PlayerStates[client][JumpDir] = JD_NORMAL;
				}
			}
			
			if(g_PlayerStates[client][JumpDir] == JD_SIDEWAYS)
			{
				g_PlayerStates[client][JumpDir] = JD_NORMAL;
			}
			
			g_PlayerStates[client][StrafeDir][g_PlayerStates[client][nStrafes]] = SD_A;
			g_PlayerStates[client][CurStrafeDir] = SD_A;
			g_PlayerStates[client][nStrafes]++;
		}
		else if(g_PlayerStates[client][CurStrafeDir] != SD_D && buttons & IN_MOVERIGHT)
		{
			if(g_PlayerStates[client][JumpDir] == JD_NONE)
			{
				new Float:vAnglesUV[3];
				TBAnglesToUV(vAnglesUV, vAngles);
				
				new Float:vVelocityDir[3];
				vVelocityDir = vVelocity;
				vVelocityDir[2] = 0.0;
				NormalizeVector(vVelocityDir, vVelocityDir);
				
				if(ArcCosine(GetVectorDotProduct(vAnglesUV, vVelocityDir)) > FLOAT_PI / 2)
				{
					g_PlayerStates[client][JumpDir] = JD_BACKWARDS;
				}
				else
				{
					g_PlayerStates[client][JumpDir] = JD_NORMAL;
				}
			}
			
			else if(g_PlayerStates[client][JumpDir] == JD_SIDEWAYS)
			{
				g_PlayerStates[client][JumpDir] = JD_NORMAL;
			}
			
			g_PlayerStates[client][StrafeDir][g_PlayerStates[client][nStrafes]] = SD_D;
			g_PlayerStates[client][CurStrafeDir] = SD_D;
			g_PlayerStates[client][nStrafes]++;
		}
		else if(g_PlayerStates[client][CurStrafeDir] != SD_W && buttons & IN_FORWARD)
		{
			if(g_PlayerStates[client][JumpDir] == JD_NONE && (vVelocity[0] || vVelocity[1]))
			{
				new Float:vAnglesUV[3];
				TBAnglesToUV(vAnglesUV, vAngles);
				
				new Float:vVelocityDir[3];
				vVelocityDir = vVelocity;
				vVelocityDir[2] = 0.0;
				NormalizeVector(vVelocityDir, vVelocityDir);
				
				if(DegToRad(90.0 - SW_ANGLE_THRESHOLD) < ArcCosine(GetVectorDotProduct(vAnglesUV, vVelocityDir)) < DegToRad(90.0 + SW_ANGLE_THRESHOLD))
				{
					g_PlayerStates[client][JumpDir] = JD_SIDEWAYS;
				}
			}
			
			g_PlayerStates[client][StrafeDir][g_PlayerStates[client][nStrafes]] = SD_W;
			g_PlayerStates[client][CurStrafeDir] = SD_W;
			g_PlayerStates[client][nStrafes]++;
		}
		else if(g_PlayerStates[client][CurStrafeDir] != SD_S && buttons & IN_BACK)
		{
			if(g_PlayerStates[client][JumpDir] == JD_NONE && (vVelocity[0] || vVelocity[1]))
			{
				new Float:vAnglesUV[3];
				TBAnglesToUV(vAnglesUV, vAngles);
				
				new Float:vVelocityDir[3];
				vVelocityDir = vVelocity;
				vVelocityDir[2] = 0.0;
				NormalizeVector(vVelocityDir, vVelocityDir);
				
				if(DegToRad(90.0 - SW_ANGLE_THRESHOLD) < ArcCosine(GetVectorDotProduct(vAnglesUV, vVelocityDir)) < DegToRad(90.0 + SW_ANGLE_THRESHOLD))
				{
					g_PlayerStates[client][JumpDir] = JD_SIDEWAYS;
				}
			}
			
			g_PlayerStates[client][StrafeDir][g_PlayerStates[client][nStrafes]] = SD_S;
			g_PlayerStates[client][CurStrafeDir] = SD_S;
			g_PlayerStates[client][nStrafes]++;
		}
	}
	
	if(g_PlayerStates[client][nStrafes] > 0)
	{
		new Float:v[3], Float:v2[3];
		Array_Copy(g_PlayerStates[client][vLastVelocity], v, 3);
		Array_Copy(g_PlayerStates[client][vLastAngles], v2, 3);
		
		new Float:fVelDelta = GetSpeed(client) - GetVSpeed(v);
		
		new Float:fAngleDelta = fmod((FloatAbs(vAngles[1] - v2[1]) + 180.0), 360.0) - 180.0;
		
		g_PlayerStates[client][nStrafeTicks][g_PlayerStates[client][nStrafes] - 1]++;
		
		g_PlayerStates[client][fTotalAngle] += fAngleDelta;
		
		if(fVelDelta > 0.0)
		{
			g_PlayerStates[client][fStrafeGain][g_PlayerStates[client][nStrafes] - 1] += fVelDelta;
			g_PlayerStates[client][fGain] += fVelDelta;
			
			g_PlayerStates[client][nStrafeTicksSynced][g_PlayerStates[client][nStrafes] - 1]++;
			
			g_PlayerStates[client][fSyncedAngle] += fAngleDelta;
		}
		else
		{
			g_PlayerStates[client][fStrafeLoss][g_PlayerStates[client][nStrafes] - 1] -= fVelDelta;
			g_PlayerStates[client][fLoss] -= fVelDelta;
		}
	}
	
	g_PlayerStates[client][nTotalTicks]++;
	g_PlayerStates[client][fTrajectory] += GetSpeed(client) * GetTickInterval();
	
	if(bGround && !g_PlayerStates[client][bOnGround])
	{
		PlayerLand(client);
	}
	
	#if defined LJSERV
	if(g_PlayerStates[client][bLJEnabled] && g_PlayerStates[client][bShowPrestrafeHint])
	{
		PrintPrestrafeHint(client);
	}
	#endif
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:vAngles[3], &weapon)
{
	new Float:vOrigin[3], Float:vVelocity[3];
	new bool:bDucked = bool:GetEntProp(client, Prop_Send, "m_bDucked", 1), bool:bGround = bool:(GetEntityFlags(client) & FL_ONGROUND);
	GetClientAbsOrigin(client, vOrigin);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
	
	_OnPlayerRunCmd(client, buttons, vOrigin, vAngles, vVelocity, bDucked, bGround);
	
	Array_Copy(vOrigin, g_PlayerStates[client][vLastOrigin], 3);
	Array_Copy(vAngles, g_PlayerStates[client][vLastAngles], 3);
	Array_Copy(vVelocity, g_PlayerStates[client][vLastVelocity], 3);
	g_PlayerStates[client][bSecondLastDuckState] = g_PlayerStates[client][bLastDuckState];
	g_PlayerStates[client][bLastDuckState] = bDucked;
	g_PlayerStates[client][LastButtons] = buttons;
	
	return Plugin_Continue;
}

#if defined LJSERV
PrintPrestrafeHint(client)
{
	new bool:bGround = bool:(GetEntityFlags(client) & FL_ONGROUND);
	decl String:strHint[128];
	
	Format(strHint, sizeof(strHint), "Pre: %.2f", bGround && !GetEntPropFloat(client, Prop_Send, "m_flStamina") ? GetSpeed(client) : g_PlayerStates[client][fPrestrafe]);
	
	if(g_PlayerStates[client][fEdge] != -1.0 && !bGround)
	{
		Append(strHint, sizeof(strHint), " | e: %.2f", g_PlayerStates[client][fEdge]);
	}
	
	if(!bGround)
	{
		Append(strHint, sizeof(strHint), "\nG: %d | L: %d\nMaxspeed: %d", RoundFloat(g_PlayerStates[client][fGain]), RoundFloat(g_PlayerStates[client][fLoss]), RoundFloat(g_PlayerStates[client][fMaxSpeed]));
	}
	
	PrintHintText(client, strHint);
}
#endif

PlayerLand(client)
{
	g_PlayerStates[client][bOnGround] = true;
	
	g_PlayerStates[client][fLandTime] = GetGameTime();
	
	if(!g_PlayerStates[client][bLJEnabled] && !g_PlayerStates[client][nSpectators] || !g_PlayerStates[client][bShowBhopStats] && g_PlayerStates[client][nBhops] > 1)
		return;
	
	
	
	// Final CheckValidJump
	//CheckValidJump(client);
	
	
	new Float:vCurOrigin[3];
	GetClientAbsOrigin(client, vCurOrigin);
	g_PlayerStates[client][fFinalSpeed] = GetSpeed(client);
	
	
	#if defined DEBUG
	if(g_PlayerStates[client][bFailedBlock] && vCurOrigin[2] - g_PlayerStates[client][vJumpOrigin][2] > -2.0)
		PrintToChat(client, "failed block && height delta = %f", vCurOrigin[2] - g_PlayerStates[client][vJumpOrigin][2]);
	
	PrintToChat(client, "%d", g_PlayerStates[client][bFailedBlock]);
	#endif
	
	// Calculate distances
	if(!g_PlayerStates[client][bFailedBlock])// || // if block longjump failed, distances have already been written in mid-air.
	//vCurOrigin[2] - g_PlayerStates[client][vJumpOrigin][2] >= HEIGHT_DELTA_MIN(JT_LONGJUMP)) // bugs sometimes if you land on last tick (I think) idk how else 2 fix
	{
		GetJumpDistance(client);
		
		g_PlayerStates[client][bFailedBlock] = false;
	}
	
	// don't show drop stats
	if(g_PlayerStates[client][JumpType] == JT_DROP)
		return;
	
	if(!g_PlayerStates[client][bShowAllJumps])
	{
		if(g_PlayerStates[client][JumpType] == JT_LONGJUMP)
		{
			if(g_PlayerStates[client][fHeightDelta] > HEIGHT_DELTA_MIN(g_PlayerStates[client][JumpType]) && g_PlayerStates[client][fHeightDelta] < HEIGHT_DELTA_MAX(g_PlayerStates[client][JumpType]))
			{
				if(g_PlayerStates[client][fJumpDistance] < 240.0)
				{
					return;
				}
			}
			else // Dropjump/upjump
			{
				if(g_PlayerStates[client][fJumpDistance] < 240.0 - g_PlayerStates[client][fHeightDelta])
				{
					return;
				}
			}
		}
		else if(g_PlayerStates[client][fJumpDistance] < 240.0)
		{
			return;
		}
	}
	
	// Check whether the player actually moved past the block edge
	if(g_PlayerStates[client][bBlockMode] && !g_PlayerStates[client][bFailedBlock])
	{
		if(!g_PlayerStates[client][vBlockNormal][0] || !g_PlayerStates[client][vBlockNormal][1])
		{
			// bools are not actually handled as 1 bit bools but 32 bit cells so n = normal.y gives out of bounds exception
			// !!normal.y or !normal.x rather
			// pawn good
			new bool:n = !g_PlayerStates[client][vBlockNormal][0];
			
			if(g_PlayerStates[client][vBlockNormal][n] > 0.0)
			{
				if(vCurOrigin[n] + 16.0 * g_PlayerStates[client][vBlockNormal][n] < g_PlayerStates[client][vBlockEndPos][n])
				{
					g_PlayerStates[client][bFailedBlock] = true;
				}
			}
			else
			{
				if(vCurOrigin[n] + 16.0 * g_PlayerStates[client][vBlockNormal][n] > g_PlayerStates[client][vBlockEndPos][n])
				{
					g_PlayerStates[client][bFailedBlock] = true;
				}
			}
		}
		else
		{
			new Float:vAdjCurOrigin[3], Float:vInvNormal[3];
			vAdjCurOrigin = vCurOrigin;
			Array_Copy(g_PlayerStates[client][vBlockNormal], vInvNormal, 2);
			ScaleVector(vInvNormal, -1.0);
			Adjust(vAdjCurOrigin, vInvNormal);
			
			
			// f(endpos.x) + (origin.x - endpos.x) * b = (f(endpos.x) - endpos.x * b) + origin.x * b = f(0) + origin.x * b
			// block normal is perpendicular to the edge direction, so b = 1 / (normal rot 90).x
			// dx and dy should have same sign so ccw rot if facing down, cw rot if up
			new Float:b = 1 / (g_PlayerStates[client][vBlockNormal][0] < 0 ? g_PlayerStates[client][vBlockNormal][1] : -g_PlayerStates[client][vBlockNormal][1]);
			new Float:fPos = g_PlayerStates[client][vBlockEndPos][1] + (vAdjCurOrigin[0] - g_PlayerStates[client][vBlockEndPos][0]) * b;
			
			if(g_PlayerStates[client][vBlockNormal][1] > 0.0 ? vAdjCurOrigin[1] < fPos : vAdjCurOrigin[1] > fPos)
			{
				g_PlayerStates[client][bFailedBlock] = true;
			}
			
			
			#if defined DEBUG
			PrintToChat(client, "block normal: %.2f, %.2f\n%.2f, %.2f, %.2f",
			g_PlayerStates[client][vBlockNormal][0],
			g_PlayerStates[client][vBlockNormal][1],
			vAdjCurOrigin[1],
			fPos,
			g_PlayerStates[client][vBlockEndPos][1]);
			
			new Float:v1[3], Float:v2[3];
			v1[2] = g_PlayerStates[client][vBlockEndPos][2] + 0.1;
			v2[2] = g_PlayerStates[client][vBlockEndPos][2] + 0.1;
			v1[0] = g_PlayerStates[client][vBlockEndPos][0] - 50;
			v1[1] = g_PlayerStates[client][vBlockEndPos][1] + (v1[0] - g_PlayerStates[client][vBlockEndPos][0]) * b;
			v2[0] = g_PlayerStates[client][vBlockEndPos][0] + 50;
			v2[1] = g_PlayerStates[client][vBlockEndPos][1] + (v2[0] - g_PlayerStates[client][vBlockEndPos][0]) * b;
			CreateBeam2(v1, v2, 0, 0, 255);
			
			if(g_PlayerStates[client][bFailedBlock])
			{
				PrintToChat(client, "failedblocklongjump 2");
			}
			#endif
		}
	}
	
	
	// sum sync
	g_PlayerStates[client][fSync] = 0.0;
	
	for(new i = 0; i < g_PlayerStates[client][nStrafes] && i < MAX_STRAFES; i++)
	{
		g_PlayerStates[client][fSync] += g_PlayerStates[client][nStrafeTicksSynced][i];
		g_PlayerStates[client][fStrafeSync][i] = float(g_PlayerStates[client][nStrafeTicksSynced][i]) / g_PlayerStates[client][nStrafeTicks][i] * 100;
	}
	
	g_PlayerStates[client][fSync] /= g_PlayerStates[client][nTotalTicks];
	g_PlayerStates[client][fSync] *= 100;
	
	
	
	
	////
	// Write HUD hint
	////
	
	decl String:buf[1024];
	
	g_PlayerStates[client][strHUDHint][0] = 0;
	
	if(g_PlayerStates[client][bBlockMode])
	{
		if(g_PlayerStates[client][fBlockDistance] != -1.0)
		{
			Format(buf, sizeof(buf), "%.1f block %s\n",
			g_PlayerStates[client][fBlockDistance],
			g_PlayerStates[client][bFailedBlock] ? "(failed)" : "");
			
			StrCat(g_PlayerStates[client][strHUDHint], HUD_HINT_SIZE, buf);
		}
		else
		{
			Format(buf, sizeof(buf), "??? block %s\n",
			g_PlayerStates[client][bFailedBlock] ? "(failed) " : "");
			
			StrCat(g_PlayerStates[client][strHUDHint], HUD_HINT_SIZE, buf);
		}
		
		if(g_PlayerStates[client][fBlockDistance] != -1.0 && g_PlayerStates[client][vBlockNormal][0] != 0.0 && g_PlayerStates[client][vBlockNormal][1] != 0.0 && g_PlayerStates[client][nVerbosity] > 2)
		{
			new Float:f = 32.0 * (FloatAbs(g_PlayerStates[client][vBlockNormal][0]) + FloatAbs(g_PlayerStates[client][vBlockNormal][1]) - 1.0);
			new Float:fAngle = FloatAbs(RadToDeg(ArcSine(g_PlayerStates[client][vBlockNormal][0])));
			fAngle = fAngle <= 45.0 ? fAngle : 90 - fAngle;
			
			Format(buf, sizeof(buf), "(%.1f rotated by %.1fº)\n",
			g_PlayerStates[client][fBlockDistance] + f,
			fAngle);
			
			StrCat(g_PlayerStates[client][strHUDHint], HUD_HINT_SIZE, buf);
		}
		
		if(g_PlayerStates[client][fBlockDistance] != -1.0 && g_PlayerStates[client][nVerbosity] > 1)
		{
			new Float:vJumpAngle[3], Float:vJumpOrig[3], Float:vBlockN[3];
			
			vJumpAngle = vCurOrigin;
			Array_Copy(g_PlayerStates[client][vJumpOrigin], vJumpOrig, 3);
			
			vBlockN[0] = g_PlayerStates[client][vBlockNormal][0];
			vBlockN[1] = g_PlayerStates[client][vBlockNormal][1];
			
			vJumpAngle[2] = 0.0;
			vJumpOrig[2] = 0.0;
			
			SubtractVectors(vJumpAngle, vJumpOrig, vJumpAngle);
			NormalizeVector(vJumpAngle, vJumpAngle);
			
			Format(buf, sizeof(buf), "%.2f degrees off block\n",
			RadToDeg(ArcCosine(GetVectorDotProduct(vJumpAngle, vBlockN))));
			
			StrCat(g_PlayerStates[client][strHUDHint], HUD_HINT_SIZE, buf);
		}
	}
	
	decl String:strJump[32];
	
	if(g_PlayerStates[client][fHeightDelta] > HEIGHT_DELTA_MAX(g_PlayerStates[client][JumpType]))
	{
		if(g_PlayerStates[client][JumpType] == JT_LONGJUMP)
		{
			strJump = "Upjump";
		}
		else
		{
			Format(strJump, sizeof(strJump), "Up%s", g_strJumpTypeLwr[g_PlayerStates[client][JumpType]]);
		}
	}
	else if(g_PlayerStates[client][fHeightDelta] < HEIGHT_DELTA_MIN(g_PlayerStates[client][JumpType]))
	{
		if(g_PlayerStates[client][JumpType] == JT_LONGJUMP)
		{
			strJump = "Dropjump";
		}
		else
		{
			Format(strJump, sizeof(strJump), "Drop%s", g_strJumpTypeLwr[g_PlayerStates[client][JumpType]]);
		}
	}
	else
	{
		strcopy(strJump, sizeof(strJump), g_strJumpType[g_PlayerStates[client][JumpType]]);
	}
	
	decl String:strJumpDir[16];
	strJumpDir = g_PlayerStates[client][JumpDir] == JD_SIDEWAYS ? " sideways" : g_PlayerStates[client][JumpDir] == JD_BACKWARDS ? " backwards" : "";
	
	Format(buf, sizeof(buf), "%s%s%s\npre: %.2f",
	strJump, strJumpDir,
	g_PlayerStates[client][JumpType] == JT_LONGJUMP &&
	g_PlayerStates[client][fHeightDelta] >= HEIGHT_DELTA_MIN(g_PlayerStates[client][JumpType]) &&
	g_PlayerStates[client][IllegalJumpFlags] == IJF_NONE &&
	g_PlayerStates[client][nTotalTicks] > 77 ? " (extended)" : "",
	g_PlayerStates[client][fPrestrafe]);
	
	StrCat(g_PlayerStates[client][strHUDHint], HUD_HINT_SIZE, buf);
	
	if(g_PlayerStates[client][JumpType] == JT_WEIRDJUMP && g_PlayerStates[client][nVerbosity] > 1)
	{
		Format(buf, sizeof(buf), " (%.2f)",
		g_PlayerStates[client][fWJDropPre]);
		
		StrCat(g_PlayerStates[client][strHUDHint], HUD_HINT_SIZE, buf);
	}
	
	Format(buf, sizeof(buf), "; dist: %.2f",
	g_PlayerStates[client][fJumpDistance]);
	
	StrCat(g_PlayerStates[client][strHUDHint], HUD_HINT_SIZE, buf);
	
	if(g_PlayerStates[client][fEdge] != -1.0)
	{
		Format(buf, sizeof(buf), "; edge: %.2f",
		g_PlayerStates[client][fEdge]);
		
		StrCat(g_PlayerStates[client][strHUDHint], HUD_HINT_SIZE, buf);
	}
	
	StrCat(g_PlayerStates[client][strHUDHint], HUD_HINT_SIZE, "\n");
	
	Format(buf, sizeof(buf), "%d; %.2f%; %.2f (%.2f)",
	g_PlayerStates[client][nStrafes],
	g_PlayerStates[client][fSync],
	g_PlayerStates[client][fMaxSpeed],
	g_PlayerStates[client][fMaxSpeed] - g_PlayerStates[client][fPrestrafe]);
	
	StrCat(g_PlayerStates[client][strHUDHint], HUD_HINT_SIZE, buf);
	
	if(g_PlayerStates[client][nVerbosity] > 2)
	{
		Format(buf, sizeof(buf), "\n%s%.2f; %.2f; %.4f%; %d",
		g_PlayerStates[client][fHeightDelta] >= 0.0 ? "+" : "",
		g_PlayerStates[client][fHeightDelta],
		g_PlayerStates[client][fJumpHeight],
		(g_PlayerStates[client][fJumpDistance] - 32.0) / g_PlayerStates[client][fTrajectory],
		g_PlayerStates[client][nTotalTicks]);
		
		StrCat(g_PlayerStates[client][strHUDHint], HUD_HINT_SIZE, buf);
	}
	
	
	if(g_PlayerStates[client][bLJEnabled])
	{
		buf[0] = 0;
		
		Append(buf, sizeof(buf), "\n");
		
		if(g_PlayerStates[client][bBlockMode])
		{
			if(g_PlayerStates[client][fBlockDistance] != -1.0)
			{
				Append(buf, sizeof(buf), "%.01f block%s",
				g_PlayerStates[client][fBlockDistance],
				g_PlayerStates[client][bFailedBlock] ? " (failed)" : "");
			}
			else
			{
				Append(buf, sizeof(buf), "??? block%s",
				g_PlayerStates[client][bFailedBlock] ? " (failed)" : "");
			}
			
			if(g_PlayerStates[client][fBlockDistance] != -1.0 && g_PlayerStates[client][vBlockNormal][0] != 0.0 && g_PlayerStates[client][vBlockNormal][1] != 0.0)
			{
				new Float:f = 32.0 * (FloatAbs(g_PlayerStates[client][vBlockNormal][0]) + FloatAbs(g_PlayerStates[client][vBlockNormal][1]) - 1.0);
				new Float:fAngle = FloatAbs(RadToDeg(ArcSine(g_PlayerStates[client][vBlockNormal][0])));
				fAngle = fAngle <= 45.0 ? fAngle : 90 - fAngle;
				
				Append(buf, sizeof(buf), " (%.1f rotated by %.1f)",
				g_PlayerStates[client][fBlockDistance] + f,
				fAngle);
			}
			
			if(g_PlayerStates[client][fBlockDistance] != -1.0)
			{
				new Float:vJumpAngle[3], Float:vJumpOrig[3], Float:vBlockN[3];
				
				vJumpAngle = vCurOrigin;
				Array_Copy(g_PlayerStates[client][vJumpOrigin], vJumpOrig, 3);
				
				vBlockN[0] = g_PlayerStates[client][vBlockNormal][0];
				vBlockN[1] = g_PlayerStates[client][vBlockNormal][1];
				
				vJumpAngle[2] = 0.0;
				vJumpOrig[2] = 0.0;
				
				SubtractVectors(vJumpAngle, vJumpOrig, vJumpAngle);
				NormalizeVector(vJumpAngle, vJumpAngle);
				
				Append(buf, sizeof(buf), " - %.2f degrees off block",
				RadToDeg(ArcCosine(GetVectorDotProduct(vJumpAngle, vBlockN))));
			}
			
			Append(buf, sizeof(buf), "\n");
		}
		
		Append(buf, sizeof(buf), "%s%s%s\nDistance: %.2f",
		strJump, strJumpDir, 
		g_PlayerStates[client][JumpType] == JT_LONGJUMP &&
		g_PlayerStates[client][fHeightDelta] > HEIGHT_DELTA_MIN(g_PlayerStates[client][JumpType])
		&& g_PlayerStates[client][nTotalTicks] > 77 ? " (extended)" : "",
		g_PlayerStates[client][fJumpDistance]);
		
		Append(buf, sizeof(buf), "; prestrafe: %.2f",
		g_PlayerStates[client][fPrestrafe]);
		
		if(g_PlayerStates[client][JumpType] == JT_WEIRDJUMP)
		{
			Append(buf, sizeof(buf), "; drop prestrafe: %.2f",
			g_PlayerStates[client][fWJDropPre]);
		}
		
		if(g_PlayerStates[client][fEdge] != -1.0)
		{
			Append(buf, sizeof(buf), "; edge: %.2f",
			g_PlayerStates[client][fEdge]);
		}
		
		if(g_PlayerStates[client][nTotalTicks] == 78)
		{
			new Float:vCurOrigin2[3];
			Array_Copy(g_PlayerStates[client][vLastOrigin], vCurOrigin2, 3);
			
			vCurOrigin2[2] = 0.0;
			
			new Float:v[3];
			Array_Copy(g_PlayerStates[client][vJumpOrigin], v, 3);
			
			v[2] = 0.0;
			
			new Float:ProjDist = GetVectorDistance(v, vCurOrigin2) + 32.0;
			
			Append(buf, sizeof(buf), "; projected real distance: %.2f", ProjDist);
		}
		
		Append(buf, sizeof(buf), "\nStrafes: %d; sync: %.2f%%; maxspeed (gain): %.2f (%.2f)",
		g_PlayerStates[client][nStrafes],
		g_PlayerStates[client][fSync],
		g_PlayerStates[client][fMaxSpeed],
		g_PlayerStates[client][fMaxSpeed] - g_PlayerStates[client][fPrestrafe]);
		
		Append(buf, sizeof(buf), "\nHeight diff: %s%.2f; jump height: %.2f; efficiency: %.4f; ticks: %d; degrees synced/degrees turned: %.2f/%.2f",
		g_PlayerStates[client][fHeightDelta] >= 0.0 ? "+" : "",
		g_PlayerStates[client][fHeightDelta],
		g_PlayerStates[client][fJumpHeight],
		(g_PlayerStates[client][fJumpDistance] - 32.0) / g_PlayerStates[client][fTrajectory],
		g_PlayerStates[client][nTotalTicks], 
		g_PlayerStates[client][fSyncedAngle], g_PlayerStates[client][fTotalAngle]);
		
		PrintToConsole(client, buf);
		
		
		new Handle:hBuffer = StartMessageOne("KeyHintText", client);
		BfWriteByte(hBuffer, 1);
		BfWriteString(hBuffer, g_PlayerStates[client][strHUDHint]);
		EndMessage();
	}
	
	
	////
	// Panel
	////
	
	new Handle:hStatsPanel = CreatePanel();
	
	
	Format(buf, 128, "%s %.2f %s%.2f",
	g_strJumpTypeShort[g_PlayerStates[client][JumpType]],
	g_PlayerStates[client][fJumpDistance],
	g_PlayerStates[client][fHeightDelta] > 0.01 ? "+" : "",
	g_PlayerStates[client][fHeightDelta]);
	
	SetPanelTitle(hStatsPanel, buf);
	
	
	if(g_PlayerStates[client][bLJEnabled])
	{
		PrintToConsole(client, "--------------------------------");
	}
	
	// Print first 16 strafes to panel
	for(new i = 0; i < g_PlayerStates[client][nStrafes] && i < 16; i++)
	{
		decl String:strStrafeKey[3];
		GetStrafeKey(strStrafeKey, g_PlayerStates[client][StrafeDir][i]);
		DrawPanelTextF(hStatsPanel, "%d   %s  %.2f  %.2f  %.2f  %.2f",
		i + 1,
		strStrafeKey,
		g_PlayerStates[client][fStrafeGain][i], g_PlayerStates[client][fStrafeLoss][i],
		float(g_PlayerStates[client][nStrafeTicks][i]) / g_PlayerStates[client][nTotalTicks] * 100,
		float(g_PlayerStates[client][nStrafeTicksSynced][i]) / g_PlayerStates[client][nStrafeTicks][i] * 100);
	}
	
	// Print strafes to console
	if(g_PlayerStates[client][bLJEnabled])
	{
		PrintToConsole(client, "#  Key Gain   Loss   Time   Sync");
		
		for(new i = 0; i < g_PlayerStates[client][nStrafes] && i < MAX_STRAFES; i++)
		{
			decl String:strStrafeKey[3];
			GetStrafeKey(strStrafeKey, g_PlayerStates[client][StrafeDir][i]);
			Format(buf, sizeof(buf), "%d  %s %6.2f %6.2f %6.2f %6.2f", i + 1,
			strStrafeKey,
			g_PlayerStates[client][fStrafeGain][i], g_PlayerStates[client][fStrafeLoss][i],
			float(g_PlayerStates[client][nStrafeTicks][i]) / g_PlayerStates[client][nTotalTicks] * 100,
			float(g_PlayerStates[client][nStrafeTicksSynced][i]) / g_PlayerStates[client][nStrafeTicks][i] * 100);
			
			PrintToConsole(client, buf);
		}
	}
	
	DrawPanelTextF(hStatsPanel, "    %.2f%%", g_PlayerStates[client][fSync]);
	
	if(g_PlayerStates[client][nVerbosity] > 2)
	{
		DrawPanelTextF(hStatsPanel, "    %.2f/%.2f", g_PlayerStates[client][fSyncedAngle], g_PlayerStates[client][fTotalAngle]);
	}
	
	DrawPanelTextF(hStatsPanel, "    %s", g_PlayerStates[client][bDuck] ? "Duck" : g_PlayerStates[client][bLastDuckState] ? "Partial Duck" : "No Duck");
	
	if(g_PlayerStates[client][bLJEnabled])
	{
		/*PrintToConsole(client, "    %.2f%%", g_PlayerStates[client][fSync]);
		
		if(g_nVerbosity > 1)
		{
			PrintToConsole(client, "    %.2f/%.2f", g_PlayerStates[client][fSyncedAngle], g_PlayerStates[client][fTotalAngle]);
		}*/
		
		PrintToConsole(client, "    %s", g_PlayerStates[client][bDuck] ? "Duck" : g_PlayerStates[client][bLastDuckState] ? "Partial Duck" : "No Duck");
		
		PrintToConsole(client, ""); // Newline
	}
	
	if(g_PlayerStates[client][bLJEnabled] && g_PlayerStates[client][JumpType] != JT_BHOP && g_PlayerStates[client][IllegalJumpFlags])
	{
		PrintToConsole(client, "Illegal jump: ");
		
		if(g_PlayerStates[client][IllegalJumpFlags] & IJF_WORLD)
		{
			PrintToConsole(client, "Lateral world collision (hit wall/surf)");
		}
		
		if(g_PlayerStates[client][IllegalJumpFlags] & IJF_BOOSTER)
		{
			PrintToConsole(client, "Booster");
		}
		
		if(g_PlayerStates[client][IllegalJumpFlags] & IJF_GRAVITY)
		{
			PrintToConsole(client, "Gravity");
		}
		
		if(g_PlayerStates[client][IllegalJumpFlags] & IJF_TELEPORT)
		{
			PrintToConsole(client, "Teleport");
		}
		
		if(g_PlayerStates[client][IllegalJumpFlags] & IJF_LAGGEDMOVEMENTVALUE)
		{
			PrintToConsole(client, "Lagged movement value");
		}
		
		if(g_PlayerStates[client][IllegalJumpFlags] & IJF_PRESTRAFE)
		{
			PrintToConsole(client, "Prestrafe > %.2f", g_fLJMaxPrestrafe);
		}
		
		if(g_PlayerStates[client][IllegalJumpFlags] & IJF_SCOUT)
		{
			PrintToConsole(client, "Scout");
		}
		
		if(g_PlayerStates[client][IllegalJumpFlags] & IJF_NOCLIP)
		{
			PrintToConsole(client, "noclip");
		}
	
		PrintToConsole(client, ""); // Newline
	}
	
	if(g_PlayerStates[client][bLJEnabled] && !g_PlayerStates[client][bHidePanel] && g_PlayerStates[client][nVerbosity] > 0 && !(g_PlayerStates[client][bHideBhopPanel] && g_PlayerStates[client][nBhops] > 1))
	{
		SendPanelToClient(hStatsPanel, client, EmptyPanelHandler, 5);
	}
	
	
	
	// Send to spectators of this player
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientSourceTV(i) && !IsClientReplay(i) && !IsFakeClient(i))
		{
			if(g_PlayerStates[i][nSpectatorTarget] == client)
			{
				if(g_PlayerStates[i][nVerbosity] > 0 && !g_PlayerStates[i][bHidePanel])
				{
					SendPanelToClient(hStatsPanel, i, EmptyPanelHandler, 5);
				}
				
				new Handle:hBuffer2 = StartMessageOne("KeyHintText", i);
				BfWriteByte(hBuffer2, 1);
				BfWriteString(hBuffer2, g_PlayerStates[client][strHUDHint]);
				EndMessage();
			}
		}
	}
	
	CloseHandle(hStatsPanel);
	
	
	////
	// Print chat message
	////
	
	if(!g_PlayerStates[client][bLJEnabled] ||
	g_PlayerStates[client][IllegalJumpFlags] != IJF_NONE ||
	g_PlayerStates[client][fHeightDelta] < HEIGHT_DELTA_MIN(JUMP_TYPE:(g_PlayerStates[client][JumpType] == JT_BHOP ? JT_BHOPJUMP : g_PlayerStates[client][JumpType])) ||
	g_PlayerStates[client][bFailedBlock] && !g_bPrintFailedBlockStats)
	{
		return;
	}
	
	if(g_PlayerStates[client][JumpType] == JT_BHOPJUMP && g_PlayerStates[client][fLastJumpHeightDelta] < HEIGHT_DELTA_MIN(JT_BHOPJUMP))
	{
		return;
	}
	
	
	switch(g_PlayerStates[client][JumpType])
	{
		case JT_LONGJUMP, JT_COUNTJUMP:
		{
			new Float:fMin = (g_fLJNoDuckMin != 0.0 && !g_PlayerStates[client][bDuck] && !g_PlayerStates[client][bLastDuckState]) ? g_fLJNoDuckMin : g_fLJMin;
			
			if(fMin != 0.0 && g_PlayerStates[client][fJumpDistance] >= fMin)
			{
				OutputJump(client, buf);
			}
			
			if(g_bLJSound && g_PlayerStates[client][bSound])
			{
				for(new i = 0; i < LJSOUND_NUM; i++)
				{
					if(g_PlayerStates[client][fJumpDistance] >= g_fLJSound[i])
					{
						if(i == LJSOUND_NUM || g_PlayerStates[client][fJumpDistance] < g_fLJSound[i + 1] || g_fLJSound[i + 1] == 0.0)
						{
							if(g_bLJSoundToAll[i])
							{
								for(new j = 1; j < MaxClients; j++)
								{
									if(IsClientInGame(client) && !IsFakeClient(client) && g_PlayerStates[j][bSound])
									{
										EmitSoundToClient(j, g_strLJSoundFile[i]);
									}
								}
							}
							else
							{
								EmitSoundToClient(client, g_strLJSoundFile[i]);
							}
							
							break;
						}
					}
					else
					{
						break;
					}
				}
			}
		}
		
		case JT_WEIRDJUMP:
		{
			if(g_fWJMin != 0.0 && g_PlayerStates[client][fJumpDistance] > g_fWJMin && (g_fWJDropMax == 0.0 || g_fWJDropMax >= FloatAbs(g_PlayerStates[client][fLastJumpHeightDelta])))
			{
				OutputJump(client, buf);
			}
		}
		
		case JT_BHOPJUMP:
		{
			if(g_fBJMin != 0.0 && g_PlayerStates[client][fJumpDistance] >= g_fBJMin)
			{
				OutputJump(client, buf);
			}
		}
		
		case JT_LADDERJUMP:
		{
			if(g_fLAJMin != 0.0 && g_PlayerStates[client][fJumpDistance] >= g_fLAJMin)
			{
				OutputJump(client, buf);
			}
		}
	}
	
	UpdatePersonalBest(client);
	
	LJTopUpdate(client);
}

public EmptyPanelHandler(Handle:hPanel, MenuAction:ma, Param1, Param2)
{
}

OutputJump(client, String:buf[1024])
{
	new Float:fMin = (g_fLJNoDuckMin != 0.0 && !g_PlayerStates[client][bDuck] && !g_PlayerStates[client][bLastDuckState]) ? g_fLJNoDuckMin : g_fLJMin;
	new Float:fMinClamp = g_fLJMin ? g_fLJMin : g_fLJNoDuckMin ? g_fLJNoDuckMin : g_fLJClientMin;
	
	new bool:bPrintToAll = true;
	
	if(g_PlayerStates[client][JumpType] == JT_LONGJUMP && g_fLJClientMin != 0 && g_PlayerStates[client][fJumpDistance] < fMin)
	{
		fMin = g_fLJClientMin;
		bPrintToAll = false;
	}
	
	if(!g_bOutput16Style)
	{
		decl String:strOutput[512];
		
		decl String:strName[64];
		GetClientName(client, strName, sizeof(strName));
		
		Format(strOutput, sizeof(strOutput), "%s {green}%s%sed ",
		strName,
		g_PlayerStates[client][JumpType] == JT_BHOPJUMP && g_PlayerStates[client][bStamina] ? "easy" : "",
		g_strJumpTypeLwr[g_PlayerStates[client][JumpType]]);
		
		if(g_PlayerStates[client][JumpType] == JT_LONGJUMP)
		{
			new nColor[3];
			for(new i; i < 3; i++)
				nColor[i] = RoundFloat((MIN(MAX(g_PlayerStates[client][fJumpDistance], fMinClamp), g_fLJMax) - fMinClamp) /
			(g_fLJMax - fMinClamp) * (g_ColorMax[i] - g_ColorMin[i]) + g_ColorMin[i]);
			
			Format(buf, sizeof(buf), "\x07%02X%02X%02X",
			nColor[0], nColor[1], nColor[2]);
			
			StrCat(strOutput, sizeof(strOutput), buf);
		}
		
		Format(buf, sizeof(buf), "%.2f{green} units", g_PlayerStates[client][fJumpDistance]);
		
		StrCat(strOutput, sizeof(strOutput), buf);
		
		if(g_PlayerStates[client][JumpDir] != JD_FORWARDS)
		{
			if(g_PlayerStates[client][JumpDir] == JD_SIDEWAYS)
			{
				StrCat(strOutput, sizeof(strOutput), " sideways");
			}
			else if(g_PlayerStates[client][JumpDir] == JD_BACKWARDS)
			{
				StrCat(strOutput, sizeof(strOutput), " backwards");
			}
		}
		
		if(!g_PlayerStates[client][bDuck] && !g_PlayerStates[client][bLastDuckState])
		{
			StrCat(strOutput, sizeof(strOutput), " no duck");
		}
		
		if(g_PlayerStates[client][bBlockMode])
		{
			if(g_PlayerStates[client][fBlockDistance] != -1.0)
			{
				Format(buf, sizeof(buf), " @ %.1f block%s", g_PlayerStates[client][fBlockDistance], g_PlayerStates[client][bFailedBlock] ? " (failed)" : "");
				
				StrCat(strOutput, sizeof(strOutput), buf);
			}
			else if(g_PlayerStates[client][bFailedBlock])
			{
				StrCat(strOutput, sizeof(strOutput), " @ ? block (failed)");
			}
		}
		
		StrCat(strOutput, sizeof(strOutput), "!");
		
		if(g_nVerbosity > 1)
		{
			Format(buf, sizeof(buf), " ({lightblue}%.2f{green}, {lightblue}%d{green} @ {lightblue}%d%%{green}, {lightblue}%d{green}",
			g_PlayerStates[client][fPrestrafe], g_PlayerStates[client][nStrafes], RoundFloat(g_PlayerStates[client][fSync]), RoundFloat(g_PlayerStates[client][fMaxSpeed]));
			
			StrCat(strOutput, sizeof(strOutput), buf);
		}
		else if(g_nVerbosity > 0)
		{
			Format(buf, sizeof(buf), " ({lightblue}%.2f{green}, {lightblue}%d{green} @ {lightblue}%d%%{green}",
			g_PlayerStates[client][fPrestrafe], g_PlayerStates[client][nStrafes], RoundFloat(g_PlayerStates[client][fSync]));
			
			StrCat(strOutput, sizeof(strOutput), buf);
		}
		
		if(g_PlayerStates[client][bBlockMode] && g_PlayerStates[client][fBlockDistance] != -1.0 && g_PlayerStates[client][fEdge] != -1.0)
		{
			Format(buf, sizeof(buf), ", edge: {lightblue}%.2f{default}", g_PlayerStates[client][fEdge]);
			
			StrCat(strOutput, sizeof(strOutput), buf);
		}
		
		StrCat(strOutput, sizeof(strOutput), ")");
		
		if(bPrintToAll)
		{
			CPrintToChatAll("%s", strOutput);
		}
		else
		{
			CPrintToChat(client, "%s", strOutput);
		}
	}
	else
	{
		decl String:strOutput[512];
		
		if(g_PlayerStates[client][fJumpDistance] < (g_PlayerStates[client][JumpType] == JT_LONGJUMP ? 265.0 : g_PlayerStates[client][JumpType] == JT_LADDERJUMP ? 155.0 : 285.0))
		{
			strcopy(strOutput, sizeof(strOutput), "{white}");
		}
		else if(g_PlayerStates[client][fJumpDistance] < (g_PlayerStates[client][JumpType] == JT_LONGJUMP ? 268.0 : g_PlayerStates[client][JumpType] == JT_LADDERJUMP ? 165.0 : 295.0))
		{
			strcopy(strOutput, sizeof(strOutput), "{green}");
		}
		else
		{
			strcopy(strOutput, sizeof(strOutput), "{red}");
		}
		
		decl String:strName[64];
		GetClientName(client, strName, sizeof(strName));
		
		Format(buf, sizeof(buf), "%s jumped %.2f units",
		strName, g_PlayerStates[client][fJumpDistance]);
		
		StrCat(strOutput, sizeof(strOutput), buf);
		
		if(g_PlayerStates[client][JumpType])
		{
			Format(buf, sizeof(buf), " with %s%s",
			g_PlayerStates[client][JumpType] == JT_BHOPJUMP && g_PlayerStates[client][bStamina] ? "easy" : "",
			g_strJumpTypeLwr[g_PlayerStates[client][JumpType]]);
			
			StrCat(strOutput, sizeof(strOutput), buf);
		}
		
		if(g_PlayerStates[client][JumpDir] != JD_FORWARDS)
		{
			if(g_PlayerStates[client][JumpDir] == JD_SIDEWAYS)
			{
				StrCat(strOutput, sizeof(strOutput), " sideways");
			}
			else if(g_PlayerStates[client][JumpDir] == JD_BACKWARDS)
			{
				StrCat(strOutput, sizeof(strOutput), " backwards");
			}
		}
		
		if(!g_PlayerStates[client][bDuck] && !g_PlayerStates[client][bLastDuckState])
		{
			StrCat(strOutput, sizeof(strOutput), " no duck");
		}
		
		if(g_PlayerStates[client][bBlockMode])
		{
			if(g_PlayerStates[client][fBlockDistance] != -1.0)
			{
				Format(buf, sizeof(buf), " @ %.1f block%s", g_PlayerStates[client][fBlockDistance], g_PlayerStates[client][bFailedBlock] ? " (failed)" : "");
				
				StrCat(strOutput, sizeof(strOutput), buf);
			}
			else if(g_PlayerStates[client][bFailedBlock])
			{
				StrCat(strOutput, sizeof(strOutput), " @ ? block (failed)");
			}
		}
		
		StrCat(strOutput, sizeof(strOutput), "!");
		
		if(g_nVerbosity > 2)
		{
			Format(buf, sizeof(buf), " (%.2f, %d @ %d%%, %d",
			g_PlayerStates[client][fPrestrafe], g_PlayerStates[client][nStrafes], RoundFloat(g_PlayerStates[client][fSync]), RoundFloat(g_PlayerStates[client][fMaxSpeed]));
			
			StrCat(strOutput, sizeof(strOutput), buf);
		}
		else if(g_nVerbosity > 1)
		{
			Format(buf, sizeof(buf), " (%.2f, %d @ %d%%",
			g_PlayerStates[client][fPrestrafe], g_PlayerStates[client][nStrafes], RoundFloat(g_PlayerStates[client][fSync]));
			
			StrCat(strOutput, sizeof(strOutput), buf);
		}
		
		if(g_PlayerStates[client][bBlockMode] && g_PlayerStates[client][fBlockDistance] != -1.0 && g_PlayerStates[client][fEdge] != -1.0)
		{
			Format(buf, sizeof(buf), ", edge: %.2f", g_PlayerStates[client][fEdge]);
			
			StrCat(strOutput, sizeof(strOutput), buf);
		}
		
		StrCat(strOutput, sizeof(strOutput), ")");
		
		if(bPrintToAll)
		{
			CPrintToChatAll("%s", strOutput);
		}
		else
		{
			CPrintToChat(client, "%s", strOutput);
		}
	}
}


///////////////////////////////////
///////////////////////////////////
////////                   ////////
////////  Trace functions  ////////
////////                   ////////
///////////////////////////////////
///////////////////////////////////

#define RAYTRACE_Z_DELTA -0.1
#define GAP_TRACE_LENGTH 10000.0

public bool:WorldFilter(entity, mask)
{
	if (entity >= 1 && entity <= MaxClients)
		return false;
	
	return true;
}

bool:TracePlayer(Float:vEndPos[3], Float:vNormal[3], const Float:vTraceOrigin[3], const Float:vEndPoint[3], bool:bCorrectError = true)
{
	new Float:vMins[3] = {-16.0, -16.0, 0.0}, Float:vMaxs[3] = {16.0, 16.0, 0.0};
	
	TR_TraceHullFilter(vTraceOrigin, vEndPoint, vMins, vMaxs, MASK_PLAYERSOLID, WorldFilter);
	
	if(!TR_DidHit()) // although tracehull does not ever seem to not hit (merely returning a hit at the end of the line), I'm keeping this here just in case, I guess
	{
		return false;
	}
	
	TR_GetEndPosition(vEndPos);
	TR_GetPlaneNormal(INVALID_HANDLE, vNormal);
	
	// correct slopes
	if(vNormal[2])
	{
		vNormal[2] = 0.0;
		NormalizeVector(vNormal, vNormal);
	}
	
	#if defined DEBUG
	new Float:v1[3], Float:v2[3];
	v1 = vEndPos;
	v2 = vEndPos;
	
	v1[0] += 16.0;
	v1[1] += 16.0;
	v2[0] += 16.0;
	v2[1] -= 16.0;
	
	CreateBeam2(v1, v2, 0, 255, 0);
	
	v1[0] -= 32.0;
	v1[1] -= 32.0;
	
	CreateBeam2(v1, v2, 0, 255, 0);
	
	v2[0] -= 32.0;
	v2[1] += 32.0;
	
	CreateBeam2(v1, v2, 0, 255, 0);
	
	v1[0] += 32.0;
	v1[1] += 32.0;
	
	CreateBeam2(v1, v2, 0, 255, 0);
	#endif
	
	Adjust(vEndPos, vNormal);
	
	// dunno where this error comes from
	if(bCorrectError)
	{
		vEndPos[0] -= vNormal[0] * 0.03125;
		vEndPos[1] -= vNormal[1] * 0.03125;
	}
	
	new Float:fDist = GetVectorDistance(vTraceOrigin, vEndPos);
	return fDist != 0.0 && fDist < GetVectorDistance(vTraceOrigin, vEndPoint);
}

// no function overloading... @__@
bool:TracePlayer2(Float:vEndPos[3], const Float:vTraceOrigin[3], const Float:vEndPoint[3], bool:bCorrectError = true)
{
	new Float:vNormal[3];
	
	return TracePlayer(vEndPos, vNormal, vTraceOrigin, vEndPoint, bCorrectError);
}

bool:TraceRay(Float:vEndPos[3], Float:vNormal[3], const Float:vTraceOrigin[3], const Float:vEndPoint[3], bool:bCorrectError = true)
{
	TR_TraceRayFilter(vTraceOrigin, vEndPoint, MASK_PLAYERSOLID, RayType_EndPoint, WorldFilter);
	
	if(!TR_DidHit())
	{
		return false;
	}
	
	TR_GetEndPosition(vEndPos);
	TR_GetPlaneNormal(INVALID_HANDLE, vNormal);
	
	// correct slopes
	if(vNormal[2])
	{
		vNormal[2] = 0.0;
		NormalizeVector(vNormal, vNormal);
	}
	
	if(bCorrectError)
	{
		vEndPos[0] -= vNormal[0] * 0.03125;
		vEndPos[1] -= vNormal[1] * 0.03125;
	}
	
	new Float:fDist = GetVectorDistance(vTraceOrigin, vEndPos);
	return fDist != 0.0 && fDist < GetVectorDistance(vTraceOrigin, vEndPoint);
}

bool:TraceRay2(Float:vEndPos[3], const Float:vTraceOrigin[3], const Float:vEndPoint[3], bool:bCorrectError = true)
{
	new Float:vNormal[3];
	
	return TraceRay(vEndPos, vNormal, vTraceOrigin, vEndPoint, bCorrectError);
}

bool:IsLeft(const Float:vDir[3], const Float:vNormal[3])
{
	if(vNormal[1] > 0)
	{
		if(vDir[0] > vNormal[0])
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{
		if(vDir[0] > vNormal[0])
		{
			return false;
		}
		else
		{
			return true;
		}
	}
}

// align with normal
Align(Float:vOut[3], const Float:v1[3], const Float:v2[3], const Float:vNormal[3])
{
	// cardinal
	if(!vNormal[0] || !vNormal[1])
	{
		if(vNormal[0])
		{
			vOut[0] = v2[0];
			vOut[1] = v1[1];
		}
		else
		{
			vOut[0] = v1[0];
			vOut[1] = v2[1];
		}
		
		return;
	}
	
	// noncardinal
	// rotate to cardinal, perform the same operation, rotate the result back
	
	//		[ cos(t) -sin(t)  0 ]
	// Rz = [ sin(t)  cos(t)  0 ]
	//		[ 0		  0       1 ]
	
	new Float:vTo[3] = {1.0, 0.0}, Float:fAngle = ArcCosine(GetVectorDotProduct(vNormal, vTo)), Float:fRotatedOriginY, Float:vRotatedEndPos[2];
	
	if(IsLeft(vTo, vNormal))
	{
		fAngle = -fAngle;
	}
	
	fRotatedOriginY = v1[0] * Sine(fAngle) + v1[1] * Cosine(fAngle);
	
	vRotatedEndPos[0] = v2[0] * Cosine(fAngle) - v2[1] * Sine(fAngle);
	vRotatedEndPos[1] = fRotatedOriginY;
	
	fAngle = -fAngle;
	
	vOut[0] = vRotatedEndPos[0] * Cosine(fAngle) - vRotatedEndPos[1] * Sine(fAngle);
	vOut[1] = vRotatedEndPos[0] * Sine(fAngle)   + vRotatedEndPos[1] * Cosine(fAngle);
}

// Adjust collision hitbox center to periphery (the furthest point you could be from the edge as inferred by the normal)
Adjust(Float:vOrigin[3], const Float:vNormal[3])
{
	// cardinal
	if(!vNormal[0] || !vNormal[1])
	{
		vOrigin[0] -= vNormal[0] * 16.0;
		vOrigin[1] -= vNormal[1] * 16.0;
		
		return;
	}
	
	// noncardinal
	// since the corner will always be the furthest point, set it to the corner of the normal's quadrant
	if(vNormal[0] > 0.0)
	{
		vOrigin[0] -= 16.0;
	}
	else
	{
		vOrigin[0] += 16.0;
	}
	
	if(vNormal[1] > 0.0)
	{
		vOrigin[1] -= 16.0;
	}
	else
	{
		vOrigin[1] += 16.0;
	}
}

Float:GetEdge(client)
{
	new Float:vOrigin[3], Float:vTraceOrigin[3], Float:vDir[3];
	GetClientAbsOrigin(client, vOrigin);
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vDir);
	
	NormalizeVector(vDir, vDir);
	
	vTraceOrigin = vOrigin;
	vTraceOrigin[0] += vDir[0] * 64.0;
	vTraceOrigin[1] += vDir[1] * 64.0;
	vTraceOrigin[2] += RAYTRACE_Z_DELTA;
	
	new Float:vEndPoint[3];
	vEndPoint = vOrigin;
	vEndPoint[0] -= vDir[0] * 16.0 * 1.414214;
	vEndPoint[1] -= vDir[1] * 16.0 * 1.414214;
	vEndPoint[2] += RAYTRACE_Z_DELTA;
	
	new Float:vEndPos[3], Float:vNormal[3];
	if(!TracePlayer(vEndPos, vNormal, vTraceOrigin, vEndPoint))
	{
		return -1.0;
	}
	
	#if defined DEBUG
	CreateLightglow("0 255 0", vOrigin);
	#endif
	
	Adjust(vOrigin, vNormal);
	
	#if defined DEBUG
	CreateLightglow("255 255 255", vEndPos);
	CreateLightglow("255 0 0", vOrigin);
	#endif
	
	Align(vEndPos, vOrigin, vEndPos, vNormal);
	
	#if defined DEBUG
	CreateLightglow("0 0 255", vEndPos);
	#endif
	
	// Correct Z -- the trace ray is a bit lower
	vEndPos[2] = vOrigin[2];
	
	return GetVectorDistance(vEndPos, vOrigin);
}

Float:GetBlockDistance(client)
{
	decl Float:vOrigin[3], Float:vTraceOrigin[3], Float:vDir[3], Float:vEndPoint[3];
	GetClientAbsOrigin(client, vOrigin);
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vDir);
	
	NormalizeVector(vDir, vDir);
	
	vTraceOrigin = vOrigin;
	vTraceOrigin[0] += vDir[0] * 64.0;
	vTraceOrigin[1] += vDir[1] * 64.0;
	vTraceOrigin[2] += RAYTRACE_Z_DELTA;
	
	vEndPoint = vOrigin;
	vEndPoint[0] -= vDir[0] * 16.0 * 1.414214;
	vEndPoint[1] -= vDir[1] * 16.0 * 1.414214;
	vEndPoint[2] += RAYTRACE_Z_DELTA;
	
	new Float:vBlockStart[3], Float:vNormal[3];
	if(!TracePlayer(vBlockStart, vNormal, vTraceOrigin, vEndPoint))
	{
		return -1.0;
	}
	
	new Float:vBlockEnd[3];
	
	Array_Copy(vNormal, g_PlayerStates[client][vBlockNormal], 2);
	
	vEndPoint = vBlockStart;
	vEndPoint[0] += vNormal[0] * 300.0;
	vEndPoint[1] += vNormal[1] * 300.0;
	
	if(TracePlayer2(vBlockEnd, vBlockStart, vEndPoint))
	{
		Array_Copy(vBlockEnd, g_PlayerStates[client][vBlockEndPos], 3);
		
		Align(vBlockEnd, vBlockStart, vBlockEnd, vNormal);
		
		if(vNormal[0] == 0.0 || vNormal[1] == 0.0)
		{
			return GetVectorDistance(vBlockStart, vBlockEnd);
		}
		else
		{
			return GetVectorDistance(vBlockStart, vBlockEnd) - 32.0 * (FloatAbs(vNormal[0]) + FloatAbs(vNormal[1]) - 1.0);
		}
	}
	else
	{
		// Trace the other direction
		
		// rotate normal da way opposite da direction
		new bool:bLeft = IsLeft(vDir, vNormal);
		
		vDir = vNormal;
		
		new Float:fTempSwap = vDir[0];
		
		vDir[0] = vDir[1];
		vDir[1] = fTempSwap;
		
		if(bLeft)
		{
			vDir[0] = -vDir[0];
		}
		else
		{
			vDir[1] = -vDir[1];
		}
		
		vTraceOrigin = vOrigin;
		vTraceOrigin[0] += vDir[0] * 48.0;
		vTraceOrigin[1] += vDir[1] * 48.0;
		vTraceOrigin[2] += RAYTRACE_Z_DELTA;
		
		vEndPoint = vTraceOrigin;
		vEndPoint[0] += vNormal[0] * 300.0;
		vEndPoint[1] += vNormal[1] * 300.0;
		
		if(!TracePlayer2(vBlockEnd, vTraceOrigin, vEndPoint))
		{
			return -1.0;
		}
		
		Array_Copy(vBlockEnd, g_PlayerStates[client][vBlockEndPos], 3);
		
		// adjust vBlockStart -- the second trace was on a different axis
		Align(vBlockStart, vBlockStart, vBlockEnd, vNormal);
		
		if(vNormal[0] == 0.0 || vNormal[1] == 0.0)
		{
			return GetVectorDistance(vBlockStart, vBlockEnd);
		}
		else
		{
			return GetVectorDistance(vBlockStart, vBlockEnd) - 32.0 * (FloatAbs(vNormal[0]) + FloatAbs(vNormal[1]) - 1.0);
		}
	}
}

bool:GetGapPoint(Float:vOut[3], Float:vNormal[3], client)
{
	decl Float:vAngles[3], Float:vTraceOrigin[3], Float:vDir[3], Float:vEndPoint[3];
	GetClientEyePosition(client, vTraceOrigin);
	GetClientEyeAngles(client, vAngles);
	
	TBAnglesToUV(vDir, vAngles);
	
	vEndPoint = vTraceOrigin;
	vEndPoint[0] += vDir[0] * GAP_TRACE_LENGTH;
	vEndPoint[1] += vDir[1] * GAP_TRACE_LENGTH;
	vEndPoint[2] += vDir[2] * GAP_TRACE_LENGTH;
	
	if(!TraceRay(vOut, vNormal, vTraceOrigin, vEndPoint))
	{
		return false;
	}
	
	#if defined DEBUG
	CreateBeam(vTraceOrigin, vEndPoint);
	#endif
	
	return true;
}

bool:GetOppositePoint(Float:vOut[3], const Float:vTraceOrigin[3], const Float:vNormal[3])
{
	decl Float:vDir[3], Float:vEndPoint[3];
	
	vDir = vNormal;
	
	if(vDir[2])
	{
		vDir[2] = 0.0;
		NormalizeVector(vDir, vDir);
	}
	
	vEndPoint = vTraceOrigin;
	vEndPoint[0] += vDir[0] * 10000.0;
	vEndPoint[1] += vDir[1] * 10000.0;
	
	if(!TraceRay2(vOut, vTraceOrigin, vEndPoint))
	{
		return false;
	}
	
	return true;
}




// generic utility functions

Float:GetSpeed(client)
{
	new Float:vVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
	vVelocity[2] = 0.0;
	
	return GetVectorLength(vVelocity); 
}

Float:GetVSpeed(const Float:v[3])
{
	new Float:vVelocity[3];
	vVelocity = v;
	vVelocity[2] = 0.0;
	
	return GetVectorLength(vVelocity);
}

SendPanelMsg(client, const String:strFormat[], any:...)
{
	new Handle:hPanel = CreatePanel();
	
	decl String:buf[512];
	
	VFormat(buf, sizeof(buf), strFormat, 3);
	
	SetPanelTitle(hPanel, buf);
	
	SendPanelToClient(hPanel, client, EmptyPanelHandler, 10);
	
	CloseHandle(hPanel);
}

DrawPanelTextF(Handle:hPanel, const String:strFormat[], any:...)
{
	decl String:buf[512];
	
	VFormat(buf, sizeof(buf), strFormat, 3);
	
	DrawPanelText(hPanel, buf);
}

Append(String:sOutput[], maxlen, const String:sFormat[], any:...)
{
	decl String:buf[1024];
	
	VFormat(buf, sizeof(buf), sFormat, 4);
	
	StrCat(sOutput, maxlen, buf);
}

// undefined for negative numbers
Float:fmod(Float:a, Float:b)
{
	while(a > b)
		a -= b;
	
	return a;
}

stock Float:round(Float:a, b, Float:Base = 10.0)
{
	new Float:f = Pow(Base, float(b));
	return RoundFloat(a * f) / f;
}

CreateBeamClient(client, const Float:v1[3], const Float:v2[3], r = 255, g = 255, b = 255, Float:fLifetime = 10.0)
{
	new color[4];
	color[0] = r;
	color[1] = g;
	color[2] = b;
	color[3] = 100;
	TE_SetupBeamPoints(v1, v2, g_BeamModel, 0, 0, 0, fLifetime, 10.0, 10.0, 10, 0.0, color, 0);
	TE_SendToClient(client);
}

#if defined DEBUG
CreateLightglow(const String:sColor[], const Float:vOrigin[3])
{
	new Lightglow = CreateEntityByName("env_lightglow");
	SetEntPropVector(Lightglow, Prop_Data, "m_vecOrigin", vOrigin);
	DispatchKeyValue(Lightglow,"rendercolor", sColor);
	DispatchKeyValue(Lightglow,"GlowProxySize", "5");
	DispatchKeyValue(Lightglow,"VerticalGlowSize", "5");
	DispatchKeyValue(Lightglow,"HorizontalGlowSize", "5");
	DispatchSpawn(Lightglow);
	CreateTimer(10.0, KillEntity, Lightglow);
}

CreateBeam(const Float:v1[3], const Float:v2[3])
{
	new color[4] = {255, 255, 255, 100};
	TE_SetupBeamPoints(v1, v2, g_BeamModel, 0, 0, 0, 10.0, 3.0, 3.0, 10, 0.0, color, 0);
	TE_SendToAll();
}

CreateBeam2(const Float:v1[3], const Float:v2[3], r, g, b)
{
	new color[4];
	color[0] = r;
	color[1] = g;
	color[2] = b;
	color[3] = 255;
	TE_SetupBeamPoints(v1, v2, g_BeamModel, 0, 0, 0, 10.0, 10.0, 10.0, 10, 0.0, color, 0);
	TE_SendToAll();
}

public Action:KillEntity(Handle:timer, any:entity)
{
	AcceptEntityInput(entity, "Kill");
}
#endif