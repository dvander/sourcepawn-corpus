/*
	Credits:
		1NutWunder for base JS plugin that i built ideas off and expanded!
		GameChaos for building the base Distance Bug plugin!
		JoinedSenses for helping fix some pesky cvars!
*/
//includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <csgocolors>
#include <cstrike>
#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#undef REQUIRE_PLUGIN
//BEST VERSION
#define VERSION "4.1.0"
//reset stats flag
#define ADMIN_LEVEL				ADMFLAG_BAN
//Colors
#define WHITE							0x01 //{default}
#define DARKRED						0x02 //{darkred}
#define PURPLE						0x03 //{pink}
#define GREEN							0x04 //{green}
#define MOSSGREEN					0x05 //{lightgreen}
#define LIMEGREEN					0x06 //{lime}
#define RED								0x07 //{red}
#define GRAY							0x08 //{grey}
#define YELLOW						0x09 //{olive}
#define ORANGE						0x10 //\x0A
#define DARKGREY					0x0A //{lightblue}
#define BLUE							0x0B //{blue}
#define DARKBLUE					0x0C //\x0C
#define LIGHTBLUE					0x0D //{purple}
#define PINK							0x0E //{darkorange}
#define LIGHTRED					0x0F //{orange}
//extra things
#define PERCENT						0x25
//Stat CVars
#define MAX_STRAFES				99
#define MAX_JUMPSTRAFES		14
//lj
float g_fGreyLJ; // default 240
ConVar g_cvGreyLJ;
float g_fGreenLJ; // default 265
ConVar g_cvGreenLJ;
float g_fBlueLJ; // default 270
ConVar g_cvBlueLJ;
float g_fRedLJ; // default 277
ConVar g_cvRedLJ;
float g_fGoldLJ; // default 283
ConVar g_cvGoldLJ;
float g_fMaxLJ; // default 291
ConVar g_cvMaxLJ;
//wj
float g_fGreyWJ; // default 265
ConVar g_cvGreyWJ;
float g_fGreenWJ; // default 275
ConVar g_cvGreenWJ;
float g_fBlueWJ; // default 280
ConVar g_cvBlueWJ;
float g_fRedWJ; // default 285
ConVar g_cvRedWJ;
float g_fGoldWJ; // default 290
ConVar g_cvGoldWJ;
float g_fMaxWJ; // default 297
ConVar g_cvMaxWJ;
//bhop
float g_fGreyBHOP; // default 265
ConVar g_cvGreyBHOP;
float g_fGreenBHOP; // default 275
ConVar g_cvGreenBHOP;
float g_fBlueBHOP; // default 280
ConVar g_cvBlueBHOP;
float g_fRedBHOP; // default 285
ConVar g_cvRedBHOP;
float g_fGoldBHOP; // default 290
ConVar g_cvGoldBHOP;
float g_fMaxBHOP; // default 297
ConVar g_cvMaxBHOP;
//multibhop
float g_fGreyMBHOP; // default 265
ConVar g_cvGreyMBHOP;
float g_fGreenMBHOP; // default 275
ConVar g_cvGreenMBHOP;
float g_fBlueMBHOP; // default 280
ConVar g_cvBlueMBHOP;
float g_fRedMBHOP; // default 285
ConVar g_cvRedMBHOP;
float g_fGoldMBHOP; // default 290
ConVar g_cvGoldMBHOP;
float g_fMaxMBHOP; // default 297
ConVar g_cvMaxMBHOP;
//dropbhop
float g_fGreyDBHOP; // default 265
ConVar g_cvGreyDBHOP;
float g_fGreenDBHOP; // default 275
ConVar g_cvGreenDBHOP;
float g_fBlueDBHOP; // default 280
ConVar g_cvBlueDBHOP;
float g_fRedDBHOP; // default 285
ConVar g_cvRedDBHOP;
float g_fGoldDBHOP; // default 290
ConVar g_cvGoldDBHOP;
float g_fMaxDBHOP; // default 297
ConVar g_cvMaxDBHOP;
//CT stat CVars
int g_iCTJumpStats;
ConVar g_cvCTJumpStats;
int g_iCTDistbugStats;
ConVar g_cvCTDistbugStats;
//Advert CVars
char g_szAdvert1[1024];
ConVar g_cvAdvert1;
char g_szAdvert2[1024];
ConVar g_cvAdvert2;
//Pre or nopre?
int g_iNoPreServer;
ConVar g_cvNoPreServer;
//distbug things
#define EPSILON						0.000001
#define MAXEDGE						32.0
#define MAXSTRAFES				32
#define PREFIX						"\x01[\x05DistBug\x01]"
Handle g_db_hGravity = INVALID_HANDLE;
float g_db_fTickRate;
float g_db_fTickGravity = 800.0;
float g_db_fMinJumpDistance = 200.0;
float g_db_fMaxJumpDistance = 300.0;
float g_db_fJumpPosition[MAXPLAYERS+1][3];
float g_db_fPosition[MAXPLAYERS+1][3];
float g_db_fVelocity[MAXPLAYERS+1][3];
float g_db_fFailPos[MAXPLAYERS+1][3];
float g_db_fFailVelocity[MAXPLAYERS+1][3];
float g_db_fJEdge[MAXPLAYERS+1];
float g_db_fLastVelInAir[MAXPLAYERS+1][3];
float g_db_fLastVelocity[MAXPLAYERS+1][3];
float g_db_fLastVelocityInAir[MAXPLAYERS+1][3];
float g_db_fLastPosInAir[MAXPLAYERS+1][3];
float g_db_fLastLastPosInAir[MAXPLAYERS+1][3];
float g_db_fStatStrafeGain[MAXPLAYERS+1][MAXSTRAFES];
float g_db_fStatStrafeLoss[MAXPLAYERS+1][MAXSTRAFES];
float g_db_fStatStrafeMax[MAXPLAYERS+1][MAXSTRAFES];
float g_db_fStatStrafeSync[MAXPLAYERS+1][MAXSTRAFES];
float g_db_fStatStrafeAirtime[MAXPLAYERS+1][MAXSTRAFES];
float g_db_fFailStatStrafeGain[MAXPLAYERS+1][MAXSTRAFES];
float g_db_fFailStatStrafeLoss[MAXPLAYERS+1][MAXSTRAFES];
float g_db_fFailStatStrafeMax[MAXPLAYERS+1][MAXSTRAFES];
float g_db_fFailStatStrafeSync[MAXPLAYERS+1][MAXSTRAFES]
float g_db_fFailStatStrafeAirtime[MAXPLAYERS+1][MAXSTRAFES];
float g_db_fMaxHeight[MAXPLAYERS+1];
float g_db_fDistance[MAXPLAYERS+1];
int g_db_iFramesInAir[MAXPLAYERS+1];
int g_db_iFramesOnGround[MAXPLAYERS+1];
int g_db_iFramesOverlapped[MAXPLAYERS+1];
int g_db_iDeadAirtime[MAXPLAYERS+1];
int g_db_iWReleaseFrame[MAXPLAYERS+1];
int g_db_iJumpFrame[MAXPLAYERS+1];
int g_db_iFailAirTime[MAXPLAYERS+1];
int g_db_iFailDeadAirTime[MAXPLAYERS+1];
int g_db_iFailOverlap[MAXPLAYERS+1];
int g_db_iLastButtons[MAXPLAYERS+1];
int g_db_iStatStrafeOverlap[MAXPLAYERS+1][MAXSTRAFES];
int g_db_iStatStrafeDead[MAXPLAYERS+1][MAXSTRAFES];
int g_db_iStatStrafeCount[MAXPLAYERS+1];
int g_db_iStatSync[MAXPLAYERS+1];
int g_db_iFailStatStrafeOverlap[MAXPLAYERS+1][MAXSTRAFES];
int g_db_iFailStatStrafeDead[MAXPLAYERS+1][MAXSTRAFES];
int g_db_iFailStatStrafeCount[MAXPLAYERS+1];
int g_db_iFailStatSync[MAXPLAYERS+1];
bool g_db_bValidJump[MAXPLAYERS+1];
bool g_db_bInAir[MAXPLAYERS+1];
bool g_db_bBlock[MAXPLAYERS+1];
//cookie things
Handle g_hEnableQuakeSounds = INVALID_HANDLE;
Handle g_db_hDistbug = INVALID_HANDLE;
Handle g_hColorChat = INVALID_HANDLE;
Handle g_hInfoPanel = INVALID_HANDLE;
Handle g_hStrafeSync = INVALID_HANDLE;
Handle g_db_hStrafeStats = INVALID_HANDLE;
Handle g_hKeyColorCookie = INVALID_HANDLE;
Handle g_hPerfColorCookie = INVALID_HANDLE;
Handle g_hSpeedColorCookie = INVALID_HANDLE;
Handle g_hMoneyCookie = INVALID_HANDLE;
int g_iEnableQuakeSounds[MAXPLAYERS+1];
int g_db_iDistbug[MAXPLAYERS+1];
int g_iColorChat[MAXPLAYERS+1];
int g_iInfoPanel[MAXPLAYERS+1];
int g_iStrafeSync[MAXPLAYERS+1];
int g_db_iStrafeStats[MAXPLAYERS+1];
int g_iMoneyPB[MAXPLAYERS+1];
int g_iKeyColors[MAXPLAYERS+1];
int g_iPerfColor[MAXPLAYERS+1];
int g_iSpeedColor[MAXPLAYERS+1];
char g_iHEX[] = {
	"#1854F9", //blue
	"#F45050", //red
	"#970FD7", //purple
	"#1CD70F", //green
	"#D7970F", //gold
	"#FFFFFF", //white
	"#00FF00", //green
	"#00FFFF", //light blue
	"#0000FF", //dark blue
	"#7F00FF", //dark purple
	"#FF007F", //pink
	"#FFB6C1"  //dark red
};
//handles
Handle g_hDb = INVALID_HANDLE;
Handle g_hBDb = INVALID_HANDLE;
Handle g_hAdvertTimer = null;
//bools
bool g_js_bPlayerJumped[MAXPLAYERS+1];
bool g_js_bDropJump[MAXPLAYERS+1];
bool g_js_bInvalidGround[MAXPLAYERS+1];
bool g_js_bBhop[MAXPLAYERS+1];
bool g_js_Strafing_AW[MAXPLAYERS+1];
bool g_js_Strafing_SD[MAXPLAYERS+1];
bool g_bLJBlock[MAXPLAYERS+1];
bool g_bLjStarDest[MAXPLAYERS+1];
bool g_bLastInvalidGround[MAXPLAYERS+1];
bool g_bPrestrafeTooHigh[MAXPLAYERS+1];
bool g_bLJBlockValidJumpoff[MAXPLAYERS+1];
bool g_js_bFuncMoveLinear[MAXPLAYERS+1];
bool g_bLastButtonJump[MAXPLAYERS+1];
bool g_bdetailView[MAXPLAYERS+1];
bool g_bFirstTeamJoin[MAXPLAYERS+1];
bool g_bBuggedStat[MAXPLAYERS+1];
bool g_bCheatedJump[MAXPLAYERS+1];
bool g_js_bPerfJump[MAXPLAYERS+1];
bool SpeedPanelUpdate[MAXPLAYERS+1];
//Stat bools
bool g_bLJ[MAXPLAYERS+1];
bool g_bWJ[MAXPLAYERS+1];
bool g_bBhop[MAXPLAYERS+1];
bool g_bMBhop[MAXPLAYERS+1];
bool g_bDBhop[MAXPLAYERS+1];
//ints
int g_Beam[2];
int g_js_Personal_LjBlock_Record[MAXPLAYERS+1]=-1;
int g_js_BuggedPersonal_LjBlock_Record[MAXPLAYERS+1]=-1;
int g_js_BhopRank[MAXPLAYERS+1];
int g_js_MultiBhopRank[MAXPLAYERS+1];
int g_js_LjRank[MAXPLAYERS+1];
int g_js_LjBlockRank[MAXPLAYERS+1];
int g_js_DropBhopRank[MAXPLAYERS+1];
int g_js_WjRank[MAXPLAYERS+1];
int g_js_BBhopRank[MAXPLAYERS+1];
int g_js_BMultiBhopRank[MAXPLAYERS+1];
int g_js_BLjRank[MAXPLAYERS+1];
int g_js_BLjBlockRank[MAXPLAYERS+1];
int g_js_BDropBhopRank[MAXPLAYERS+1];
int g_js_BWjRank[MAXPLAYERS+1];
int g_js_Sync_Final[MAXPLAYERS+1];
int g_js_GroundFrames[MAXPLAYERS+1];
int g_js_StrafeCount[MAXPLAYERS+1];
int g_js_Strafes_Final[MAXPLAYERS+1];
int g_js_LeetJump_Count[MAXPLAYERS+1];
int g_js_GoldJump_Count[MAXPLAYERS+1];
int g_js_MultiBhop_Count[MAXPLAYERS+1];
int g_js_Last_Ground_Frames[MAXPLAYERS+1];
int g_LastButton[MAXPLAYERS+1];
int g_BlockDist[MAXPLAYERS+1];
//floats
float g_fLastSpeed[MAXPLAYERS+1];
float g_flastHeight[MAXPLAYERS+1];
float g_fBlockHeight[MAXPLAYERS+1];
float g_fEdgeVector[MAXPLAYERS+1][3];
float g_fEdgeDist[MAXPLAYERS+1];
float g_fEdgePoint[MAXPLAYERS+1][3];
float g_fOriginBlock[MAXPLAYERS+1][2][3];
float g_fDestBlock[MAXPLAYERS+1][2][3];
float g_fLastPosition[MAXPLAYERS+1][3];
float g_fLastAngles[MAXPLAYERS+1][3];
float g_fSpeed[MAXPLAYERS+1];
float g_fLastPositionOnGround[MAXPLAYERS+1][3];
float g_fAirTime[MAXPLAYERS+1];
float g_js_fJump_JumpOff_Pos[MAXPLAYERS+1][3];
float g_js_fJump_Landing_Pos[MAXPLAYERS+1][3];
float g_js_fJump_JumpOff_PosLastHeight[MAXPLAYERS+1];
float g_js_fJump_DistanceX[MAXPLAYERS+1];
float g_js_fJump_DistanceZ[MAXPLAYERS+1];
float g_js_fJump_Distance[MAXPLAYERS+1];
float g_js_fPreStrafe[MAXPLAYERS+1];
float g_js_fJumpOff_Time[MAXPLAYERS+1];
float g_js_fDropped_Units[MAXPLAYERS+1];
float g_js_fMax_Speed[MAXPLAYERS+1];
float g_js_fMax_Speed_Final[MAXPLAYERS +1];
float g_js_fMax_Height[MAXPLAYERS+1];
float g_js_fLast_Jump_Time[MAXPLAYERS+1];
float g_js_Good_Sync_Frames[MAXPLAYERS+1];
float g_js_Sync_Frames[MAXPLAYERS+1];
float g_js_Strafe_Good_Sync[MAXPLAYERS+1][MAX_STRAFES];
float g_js_Strafe_Frames[MAXPLAYERS+1][MAX_STRAFES];
float g_js_Strafe_Gained[MAXPLAYERS+1][MAX_STRAFES];
float g_js_Strafe_Max_Speed[MAXPLAYERS+1][MAX_STRAFES];
float g_js_Strafe_Lost[MAXPLAYERS+1][MAX_STRAFES];
float g_js_fPersonal_Lj_Record[MAXPLAYERS+1]=-1.0;
float g_js_fBuggedPersonal_Lj_Record[MAXPLAYERS+1]=-1.0;
float g_js_fPersonal_LjBlockRecord_Dist[MAXPLAYERS+1]=-1.0;
float g_js_fBuggedPersonal_LjBlockRecord_Dist[MAXPLAYERS+1]=-1.0;
float g_js_fPersonal_Wj_Record[MAXPLAYERS+1]=-1.0;
float g_js_fBuggedPersonal_Wj_Record[MAXPLAYERS+1]=-1.0;
float g_js_fPersonal_Bhop_Record[MAXPLAYERS+1]=-1.0;
float g_js_fBuggedPersonal_Bhop_Record[MAXPLAYERS+1]=-1.0;
float g_js_fPersonal_MultiBhop_Record[MAXPLAYERS+1]=-1.0;
float g_js_fBuggedPersonal_MultiBhop_Record[MAXPLAYERS+1]=-1.0;
float g_js_fPersonal_DropBhop_Record[MAXPLAYERS+1]=-1.0;
float g_js_fBuggedPersonal_DropBhop_Record[MAXPLAYERS+1]=-1.0;
float g_js_fMoneyDist[MAXPLAYERS+1];
//chars
char g_js_szLastJumpDistance[MAXPLAYERS+1][256];
char g_js_LogPath[PLATFORM_MAX_PATH];
char ResetID[MAXPLAYERS+1][128];
char StatType[MAXPLAYERS+1][128];
//sounds
char NUMBER_ONE_FULL_SOUND_PATH[]					= "sound/quake/holyshitpower.mp3";
char NUMBER_ONE_RELATIVE_SOUND_PATH[]			= "*quake/holyshitpower.mp3";
char NUMBER_TWO_FULL_SOUND_PATH[]					= "sound/quake/wickedsickhades.mp3";
char NUMBER_TWO_RELATIVE_SOUND_PATH[]			= "*quake/wickedsickhades.mp3";
char NUMBER_THREE_FULL_SOUND_PATH[]				= "sound/quake/ownageflow.mp3";
char NUMBER_THREE_RELATIVE_SOUND_PATH[]		= "*quake/ownageflow.mp3";
char OWNAGEJUMP_5_FULL_SOUND_PATH[]				= "sound/quake/combowhore.mp3";
char OWNAGEJUMP_5_RELATIVE_SOUND_PATH[]		= "*quake/combowhore.mp3";
char OWNAGEJUMP_3_FULL_SOUND_PATH[]				= "sound/quake/holyshit.mp3";
char OWNAGEJUMP_3_RELATIVE_SOUND_PATH[]		= "*quake/holyshit.mp3";
char OWNAGEJUMP_FULL_SOUND_PATH[]					= "sound/quake/ownage.mp3";
char OWNAGEJUMP_RELATIVE_SOUND_PATH[]			= "*quake/ownage.mp3";
char LEETJUMP_FULL_SOUND_PATH[]						= "sound/quake/godlike.mp3";
char LEETJUMP_RELATIVE_SOUND_PATH[]				= "*quake/godlike.mp3";
char LEETJUMP_5_FULL_SOUND_PATH[]					= "sound/quake/dominating.mp3";
char LEETJUMP_5_RELATIVE_SOUND_PATH[]			= "*quake/dominating.mp3";
char LEETJUMP_3_FULL_SOUND_PATH[]					= "sound/quake/rampage.mp3";
char LEETJUMP_3_RELATIVE_SOUND_PATH[]			= "*quake/rampage.mp3";
char PROJUMP_FULL_SOUND_PATH[]						= "sound/quake/impressive.mp3";
char PROJUMP_RELATIVE_SOUND_PATH[]				= "*quake/impressive.mp3";
char PERFECTJUMP_FULL_SOUND_PATH[]				= "sound/quake/perfect.mp3";
char PERFECTJUMP_RELATIVE_SOUND_PATH[]		= "*quake/perfect.mp3";
//TABLE JUMMPSTATS
char sql_createPlayerjumpstats[]					= "CREATE TABLE IF NOT EXISTS playerjumpstats (steamid VARCHAR(32), name VARCHAR(32), multibhoprecord FLOAT NOT NULL DEFAULT '-1.0', multibhoppre FLOAT NOT NULL DEFAULT '-1.0', multibhopmax FLOAT NOT NULL DEFAULT '-1.0', multibhopstrafes INT(12),multibhopcount INT(12),multibhopsync INT(12), multibhopheight FLOAT NOT NULL DEFAULT '-1.0', bhoprecord FLOAT NOT NULL DEFAULT '-1.0', bhoppre FLOAT NOT NULL DEFAULT '-1.0', bhopmax FLOAT NOT NULL DEFAULT '-1.0', bhopstrafes INT(12),bhopsync INT(12), bhopheight FLOAT NOT NULL DEFAULT '-1.0', ljrecord FLOAT NOT NULL DEFAULT '-1.0', ljpre FLOAT NOT NULL DEFAULT '-1.0', ljmax FLOAT NOT NULL DEFAULT '-1.0', ljstrafes INT(12),ljsync INT(12), ljheight FLOAT NOT NULL DEFAULT '-1.0', ljblockdist INT(12) NOT NULL DEFAULT '-1',ljblockrecord FLOAT NOT NULL DEFAULT '-1.0', ljblockpre FLOAT NOT NULL DEFAULT '-1.0', ljblockmax FLOAT NOT NULL DEFAULT '-1.0', ljblockstrafes INT(12),ljblocksync INT(12), ljblockheight FLOAT NOT NULL DEFAULT '-1.0', dropbhoprecord FLOAT NOT NULL DEFAULT '-1.0', dropbhoppre FLOAT NOT NULL DEFAULT '-1.0', dropbhopmax FLOAT NOT NULL DEFAULT '-1.0', dropbhopstrafes INT(12),dropbhopsync INT(12), dropbhopheight FLOAT NOT NULL DEFAULT '-1.0', wjrecord FLOAT NOT NULL DEFAULT '-1.0', wjpre FLOAT NOT NULL DEFAULT '-1.0', wjmax FLOAT NOT NULL DEFAULT '-1.0', wjstrafes INT(12),wjsync INT(12), wjheight FLOAT NOT NULL DEFAULT '-1.0', PRIMARY KEY(steamid));";
//bugged
char sql_createBPlayerjumpstats[]					= "CREATE TABLE IF NOT EXISTS buggedplayerjumpstats (steamid VARCHAR(32), name VARCHAR(32), bljrecord FLOAT NOT NULL DEFAULT '-1.0',bljpre FLOAT NOT NULL DEFAULT '-1.0', bljmax FLOAT NOT NULL DEFAULT '-1.0', bljstrafes INT(12),bljsync INT(12),bljheight FLOAT NOT NULL DEFAULT '-1.0', PRIMARY KEY(steamid));";
//Insert player
//nobug
char sql_insertPlayerJumpLj[]							= "INSERT INTO playerjumpstats (steamid, name, ljrecord, ljpre, ljmax, ljstrafes, ljsync, ljheight) VALUES('%s', '%s', '%f', '%f', '%f', '%i', '%i', '%f');";
char sql_insertPlayerJumpLjBlock[]				= "INSERT INTO playerjumpstats (steamid, name, ljblockdist, ljblockrecord, ljblockpre, ljblockmax, ljblockstrafes, ljblocksync, ljblockheight) VALUES('%s', '%s', '%i', '%f', '%f', '%f', '%i', '%i', '%f');";
char sql_insertPlayerJumpWJ[]							= "INSERT INTO playerjumpstats (steamid, name, wjrecord, wjpre, wjmax, wjstrafes, wjsync, wjheight) VALUES('%s', '%s', '%f', '%f', '%f', '%i', '%i', '%f');";
char sql_insertPlayerJumpBhop[] 					= "INSERT INTO playerjumpstats (steamid, name, bhoprecord, bhoppre, bhopmax, bhopstrafes, bhopsync, bhopheight) VALUES('%s', '%s', '%f', '%f', '%f', '%i', '%i', '%f');";
char sql_insertPlayerJumpMultiBhop[]			= "INSERT INTO playerjumpstats (steamid, name, multibhoprecord, multibhoppre, multibhopmax, multibhopstrafes, multibhopcount, multibhopsync, multibhopheight) VALUES('%s', '%s', '%f', '%f', '%f', '%i', '%i', '%i', '%f');";
char sql_insertPlayerJumpDropBhop[]				= "INSERT INTO playerjumpstats (steamid, name, dropbhoprecord, dropbhoppre, dropbhopmax, dropbhopstrafes, dropbhopsync, dropbhopheight) VALUES('%s', '%s', '%f', '%f', '%f', '%i', '%i', '%f');";
//bugged
char sql_BinsertPlayerJumpLj[]						= "INSERT INTO buggedplayerjumpstats (steamid, name, bljrecord, bljpre, bljmax, bljstrafes, bljsync, bljheight) VALUES('%s', '%s', '%f', '%f', '%f', '%i', '%i', '%f');";
//update player
//nobug
char sql_updateLj[]												= "UPDATE playerjumpstats SET name='%s', ljrecord ='%f', ljpre ='%f', ljmax ='%f', ljstrafes='%i', ljsync='%i', ljheight='%f' WHERE steamid = '%s';";
char sql_updateLjBlock[]									= "UPDATE playerjumpstats SET name='%s', ljblockdist ='%i', ljblockrecord ='%f', ljblockpre ='%f', ljblockmax ='%f', ljblockstrafes='%i', ljblocksync='%i', ljblockheight='%f' WHERE steamid = '%s';";
char sql_updateWJ[]												= "UPDATE playerjumpstats SET name='%s', wjrecord ='%f', wjpre ='%f', wjmax ='%f', wjstrafes='%i', wjsync='%i', wjheight='%f' WHERE steamid = '%s';";
char sql_updateBhop[]											= "UPDATE playerjumpstats SET name='%s', bhoprecord ='%f', bhoppre ='%f', bhopmax ='%f', bhopstrafes='%i', bhopsync='%i', bhopheight='%f' WHERE steamid = '%s';";
char sql_updateMultiBhop[]								= "UPDATE playerjumpstats SET name='%s', multibhoprecord ='%f', multibhoppre ='%f', multibhopmax ='%f', multibhopstrafes='%i', multibhopcount='%i', multibhopsync='%i', multibhopheight='%f' WHERE steamid = '%s';";
char sql_updateDropBhop[]									= "UPDATE playerjumpstats SET name='%s', dropbhoprecord ='%f', dropbhoppre ='%f', dropbhopmax ='%f', dropbhopstrafes='%i', dropbhopsync='%i', dropbhopheight='%f' WHERE steamid = '%s';";
//bugged
char sql_BupdateLj[]											= "UPDATE buggedplayerjumpstats SET name='%s', bljrecord ='%f', bljpre ='%f', bljmax ='%f', bljstrafes='%i', bljsync='%i', bljheight='%f' WHERE steamid = '%s';";
//open jumptop user
//nobug
char sql_selectPlayerJumpTopLJ[]					= "SELECT name, ljrecord, ljstrafes, steamid FROM playerjumpstats WHERE ljrecord > -1.0 ORDER BY ljrecord DESC LIMIT 20";
char sql_selectPlayerJumpTopLJBlock[] 		= "SELECT name, ljblockdist, ljblockrecord, ljblockstrafes, steamid FROM playerjumpstats WHERE ljblockdist > -1 ORDER BY ljblockdist DESC, ljblockrecord DESC LIMIT 20";
char sql_selectPlayerJumpTopWJ[]					= "SELECT name, wjrecord, wjstrafes, steamid FROM playerjumpstats WHERE wjrecord > -1.0 ORDER BY wjrecord DESC LIMIT 20";
char sql_selectPlayerJumpTopBhop[]				= "SELECT name, bhoprecord, bhopstrafes, steamid FROM playerjumpstats WHERE bhoprecord > -1.0 ORDER BY bhoprecord DESC LIMIT 20";
char sql_selectPlayerJumpTopMultiBhop[]		= "SELECT name, multibhoprecord, multibhopstrafes, steamid FROM playerjumpstats WHERE multibhoprecord > -1.0 ORDER BY multibhoprecord DESC LIMIT 20";
char sql_selectPlayerJumpTopDropBhop[]		= "SELECT name, dropbhoprecord, dropbhopstrafes, steamid FROM playerjumpstats WHERE dropbhoprecord > -1.0 ORDER BY dropbhoprecord DESC LIMIT 20";
//bugged
char sql_BselectPlayerJumpTopLJ[]					= "SELECT name, bljrecord, bljstrafes, steamid FROM buggedplayerjumpstats WHERE bljrecord > -1.0 ORDER BY bljrecord DESC LIMIT 20";
//check player stat
//nobug
char sql_selectJumpStats[]								= "SELECT steamid, name, bhoprecord,bhoppre,bhopmax,bhopstrafes,bhopsync, ljrecord, ljpre, ljmax, ljstrafes,ljsync, multibhoprecord,multibhoppre, multibhopmax, multibhopstrafes,multibhopcount,multibhopsync, wjrecord, wjpre, wjmax, wjstrafes, wjsync, dropbhoprecord, dropbhoppre, dropbhopmax, dropbhopstrafes, dropbhopsync, ljheight, bhopheight, multibhopheight, dropbhopheight, wjheight,ljblockdist,ljblockrecord, ljblockpre, ljblockmax, ljblockstrafes,ljblocksync, ljblockheight FROM playerjumpstats WHERE (wjrecord > -1.0 OR dropbhoprecord > -1.0 OR ljrecord > -1.0 OR bhoprecord > -1.0 OR multibhoprecord > -1.0) AND steamid = '%s';";
char sql_selectPlayerJumpLJ[]							= "SELECT steamid, name, ljrecord FROM playerjumpstats WHERE steamid = '%s';";
char sql_selectPlayerJumpLJBlock[]				= "SELECT steamid, name, ljblockdist, ljblockrecord FROM playerjumpstats WHERE steamid = '%s';";
char sql_selectPlayerJumpWJ[]							= "SELECT steamid, name, wjrecord FROM playerjumpstats WHERE steamid = '%s';";
char sql_selectPlayerJumpBhop[]						= "SELECT steamid, name, bhoprecord FROM playerjumpstats WHERE steamid = '%s';";
char sql_selectPlayerJumpMultiBhop[]			= "SELECT steamid, name, multibhoprecord FROM playerjumpstats WHERE steamid = '%s';";
char sql_selectPlayerJumpDropBhop[]				= "SELECT steamid, name, dropbhoprecord FROM playerjumpstats WHERE steamid = '%s';";
//bugged
char sql_BselectJumpStats[]								= "SELECT steamid, name, bljrecord, bljpre, bljmax, bljstrafes,bljsync, bljheight FROM buggedplayerjumpstats WHERE (bljrecord > -1.0) AND steamid = '%s';";
char sql_BselectPlayerJumpLJ[]						= "SELECT steamid, name, bljrecord FROM buggedplayerjumpstats WHERE steamid = '%s';";
//opening player stats from jumptop table
//nobug
char sql_selectPlayerRankLj[]							= "SELECT name FROM playerjumpstats WHERE ljrecord >= (SELECT ljrecord FROM playerjumpstats WHERE steamid = '%s' AND ljrecord > -1.0) AND ljrecord > -1.0 ORDER BY ljrecord;";
char sql_selectPlayerRankLjBlock[]				= "SELECT name FROM playerjumpstats WHERE ljblockdist >= (SELECT ljblockdist FROM playerjumpstats WHERE steamid = '%s' AND ljblockdist > -1.0) AND ljblockdist > -1.0 ORDER BY ljblockdist DESC, ljblockrecord DESC;";
char sql_selectPlayerRankWJ[]							= "SELECT name FROM playerjumpstats WHERE wjrecord >= (SELECT wjrecord FROM playerjumpstats WHERE steamid = '%s' AND wjrecord > -1.0) AND wjrecord > -1.0 ORDER BY wjrecord;";
char sql_selectPlayerRankBhop[]						= "SELECT name FROM playerjumpstats WHERE bhoprecord >= (SELECT bhoprecord FROM playerjumpstats WHERE steamid = '%s' AND bhoprecord > -1.0) AND bhoprecord > -1.0 ORDER BY bhoprecord;";
char sql_selectPlayerRankMultiBhop[]			= "SELECT name FROM playerjumpstats WHERE multibhoprecord >= (SELECT multibhoprecord FROM playerjumpstats WHERE steamid = '%s' AND multibhoprecord > -1.0) AND multibhoprecord > -1.0 ORDER BY multibhoprecord;";
char sql_selectPlayerRankDropBhop[]				= "SELECT name FROM playerjumpstats WHERE dropbhoprecord >= (SELECT dropbhoprecord FROM playerjumpstats WHERE steamid = '%s' AND dropbhoprecord > -1.0) AND dropbhoprecord > -1.0 ORDER BY dropbhoprecord;";
//bugged
char sql_BselectPlayerRankLj[]						= "SELECT name FROM buggedplayerjumpstats WHERE bljrecord >= (SELECT bljrecord FROM buggedplayerjumpstats WHERE steamid = '%s' AND bljrecord > -1.0) AND bljrecord > -1.0 ORDER BY bljrecord;";
//reset stats
//nobug
char sql_resetJumpStats[]									= "UPDATE playerjumpstats SET multibhoprecord = '-1.0', ljrecord = '-1.0', wjrecord = '-1.0', dropbhoprecord = '-1.0', bhoprecord = '-1.0', ljblockrecord = '-1' WHERE steamid = '%s';";
char sql_resetLjRecord[]									= "UPDATE playerjumpstats SET ljrecord = '-1.0' WHERE steamid = '%s';";
char sql_resetLjBlockRecord[]							= "UPDATE playerjumpstats SET ljblockrecord = '-1.0' WHERE steamid = '%s';";
char sql_resetWJRecord[]									= "UPDATE playerjumpstats SET wjrecord = '-1.0' WHERE steamid = '%s';";
char sql_resetBhopRecord[]								= "UPDATE playerjumpstats SET bhoprecord = '-1.0' WHERE steamid = '%s';";
char sql_resetMultiBhopRecord[]						= "UPDATE playerjumpstats SET multibhoprecord = '-1.0' WHERE steamid = '%s';";
char sql_resetDropBhopRecord[]						= "UPDATE playerjumpstats SET dropbhoprecord = '-1.0' WHERE steamid = '%s';";
//bugged
char sql_BresetLjRecord[]									= "UPDATE buggedplayerjumpstats SET bljrecord = '-1.0' WHERE steamid = '%s';";
//info
public Plugin myinfo = {
	name = "amuJS",
	author = "hiiamu",
	description = "",
	version = VERSION,
	url = ""
};
public OnPluginStart() {
//lanuage file
	LoadTranslations("kzjumpstats.phrases");
//db setup
	db_setupDatabase();
	db_setupBDatabase();
//config
	AutoExecConfig(true, "KZJumpStats");
//ConVars
	g_cvGreyLJ					= CreateConVar("js_grey_lj", "240.0", "Dist for LJ to be considered GREY", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGreenLJ					= CreateConVar("js_green_lj", "265.0", "Dist for LJ to be considered GREEN", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvBlueLJ					= CreateConVar("js_blue_lj", "270.0", "Dist for LJ to be considered BLUE", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvRedLJ						= CreateConVar("js_red_lj", "277.0", "Dist for LJ to be considered RED", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGoldLJ					= CreateConVar("js_gold_lj", "283.0", "Dist for LJ to be considered GOLD", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvMaxLJ						= CreateConVar("js_max_lj", "291.0", "Dist for LJ to be considered TOO HIGH", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGreyWJ					= CreateConVar("js_grey_wj", "265.0", "Dist for WJ to be considered GREY", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGreenWJ					= CreateConVar("js_green_wj", "275.0", "Dist for WJ to be considered GREEN", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvBlueWJ					= CreateConVar("js_blue_wj", "280.0", "Dist for WJ to be considered BLUE", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvRedWJ						= CreateConVar("js_red_wj", "285.0", "Dist for WJ to be considered RED", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGoldWJ					= CreateConVar("js_gold_wj", "290.0", "Dist for WJ to be considered GOLD", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvMaxWJ						= CreateConVar("js_MaxWJ", "297.0", "Dist for WJ to be considered TOO HIGH", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGreyBHOP				= CreateConVar("js_grey_bhop", "265.0", "Dist for BHOP to be considered GREY", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGreenBHOP				= CreateConVar("js_green_bhop", "275.0", "Dist for BHOP to be considered GREEN", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvBlueBHOP				= CreateConVar("js_blue_bhop", "280.0", "Dist for BHOP to be considered BLUE", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvRedBHOP					= CreateConVar("js_red_bhop", "285.0", "Dist for BHOP to be considered RED", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGoldBHOP				= CreateConVar("js_gold_bhop", "290.0", "Dist for BHOP to be considered GOLD", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvMaxBHOP					= CreateConVar("js_MaxBHOP", "297.0", "Dist for BHOP to be considered TOO HIGH", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGreyMBHOP				= CreateConVar("js_grey_mbhop", "265.0", "Dist for MULTI BHOP to be considered GREY", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGreenMBHOP			= CreateConVar("js_green_mbhop", "275.0", "Dist for MULTI BHOP to be considered GREEN", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvBlueMBHOP				= CreateConVar("js_blue_mbhop", "280.0", "Dist for MULTI BHOP to be considered BLUE", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvRedMBHOP				= CreateConVar("js_red_mbhop", "285.0", "Dist for MULTI BHOP to be considered RED", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGoldMBHOP				= CreateConVar("js_gold_mbhop", "290.0", "Dist for MULTI BHOP to be considered GOLD", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvMaxMBHOP				= CreateConVar("js_MaxMBHOP", "297.0", "Dist for MULTI BHOP to be considered TOO HIGH", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGreyDBHOP				= CreateConVar("js_grey_dbhop", "265.0", "Dist for DROP BHOP to be considered GREY", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGreenDBHOP			= CreateConVar("js_green_dbhop", "275.0", "Dist for DROP BHOP to be considered GREEN", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvBlueDBHOP				= CreateConVar("js_blue_dbhop", "280.0", "Dist for DROP BHOP to be considered BLUE", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvRedDBHOP				= CreateConVar("js_red_dbhop", "285.0", "Dist for DROP BHOP to be considered RED", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvGoldDBHOP				= CreateConVar("js_gold_dbhop", "290.0", "Dist for DROP BHOP to be considered GOLD", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvMaxDBHOP				= CreateConVar("js_max_dbhop", "297.0", "Dist for DROP BHOP to be considered TOO HIGH", FCVAR_NOTIFY, true, 200.0, true, 999.0);
	g_cvCTJumpStats			= CreateConVar("js_ct_jumpstats", "0.0", "Enable/Disable CT JumpStatting. 1 = Enable 0 = Disable", FCVAR_NOTIFY, true, 1.0, true, 0.0);
	g_cvCTDistbugStats	= CreateConVar("js_ct_distbugstats", "0.0", "Enable/Disable CT Distbug Statting. 1 = Enable 0 = Disable", FCVAR_NOTIFY, true, 1.0, true, 0.0);
	g_cvNoPreServer			= CreateConVar("js_nopre_server", "0.0", "Is the server pre or nopre? used for ladder bug detection. 1 = nopre 0 = pre", FCVAR_NOTIFY, true, 1.0, true, 0.0);
	g_cvAdvert1					= CreateConVar("js_advert_1", "", "Text that prints to chat 60 seconds after round start, you can use color tags (see csgocolors.inc) (Leave empty for no advert)", FCVAR_NOTIFY);
	g_cvAdvert2					= CreateConVar("js_advert_2", "", "Text that prints to chat 20 seconds after advert1, you can use color tags (see csgocolors.inc) (Leave empty for no advert)", FCVAR_NOTIFY);

	g_fGreyLJ						= GetConVarFloat(g_cvGreyLJ);
	HookConVarChange(g_cvGreyLJ, OnSettingChanged);
	g_fGreenLJ					= GetConVarFloat(g_cvGreenLJ);
	HookConVarChange(g_cvGreenLJ, OnSettingChanged);
	g_fBlueLJ						= GetConVarFloat(g_cvBlueLJ);
	HookConVarChange(g_cvBlueLJ, OnSettingChanged);
	g_fRedLJ						= GetConVarFloat(g_cvRedLJ);
	HookConVarChange(g_cvRedLJ, OnSettingChanged);
	g_fGoldLJ						= GetConVarFloat(g_cvGoldLJ);
	HookConVarChange(g_cvGoldLJ, OnSettingChanged);
	g_fMaxLJ						= GetConVarFloat(g_cvMaxLJ);
	HookConVarChange(g_cvMaxLJ, OnSettingChanged);
	g_fGreyWJ						= GetConVarFloat(g_cvGreyWJ);
	HookConVarChange(g_cvGreyWJ, OnSettingChanged);
	g_fGreenWJ					= GetConVarFloat(g_cvGreenWJ);
	HookConVarChange(g_cvGreenWJ, OnSettingChanged);
	g_fBlueWJ						= GetConVarFloat(g_cvBlueWJ);
	HookConVarChange(g_cvBlueWJ, OnSettingChanged);
	g_fRedWJ						= GetConVarFloat(g_cvRedWJ);
	HookConVarChange(g_cvRedWJ, OnSettingChanged);
	g_fGoldWJ						= GetConVarFloat(g_cvGoldWJ);
	HookConVarChange(g_cvGoldWJ, OnSettingChanged);
	g_fMaxWJ						= GetConVarFloat(g_cvMaxWJ);
	HookConVarChange(g_cvMaxWJ, OnSettingChanged);
	g_fGreyBHOP					= GetConVarFloat(g_cvGreyBHOP);
	HookConVarChange(g_cvGreyBHOP, OnSettingChanged);
	g_fGreenBHOP				= GetConVarFloat(g_cvGreenBHOP);
	HookConVarChange(g_cvGreenBHOP, OnSettingChanged);
	g_fBlueBHOP					= GetConVarFloat(g_cvBlueBHOP);
	HookConVarChange(g_cvBlueBHOP, OnSettingChanged);
	g_fRedBHOP					= GetConVarFloat(g_cvRedBHOP);
	HookConVarChange(g_cvRedBHOP, OnSettingChanged);
	g_fGoldBHOP					= GetConVarFloat(g_cvGoldBHOP);
	HookConVarChange(g_cvGoldBHOP, OnSettingChanged);
	g_fMaxBHOP					= GetConVarFloat(g_cvMaxBHOP);
	HookConVarChange(g_cvMaxBHOP, OnSettingChanged);
	g_fGreyMBHOP				= GetConVarFloat(g_cvGreyMBHOP);
	HookConVarChange(g_cvGreyMBHOP, OnSettingChanged);
	g_fGreenMBHOP				= GetConVarFloat(g_cvGreenMBHOP);
	HookConVarChange(g_cvGreenMBHOP, OnSettingChanged);
	g_fBlueMBHOP				= GetConVarFloat(g_cvBlueMBHOP);
	HookConVarChange(g_cvBlueMBHOP, OnSettingChanged);
	g_fRedMBHOP					= GetConVarFloat(g_cvRedMBHOP);
	HookConVarChange(g_cvRedMBHOP, OnSettingChanged);
	g_fGoldMBHOP				= GetConVarFloat(g_cvGoldMBHOP);
	HookConVarChange(g_cvGoldMBHOP, OnSettingChanged);
	g_fMaxMBHOP					= GetConVarFloat(g_cvMaxMBHOP);
	HookConVarChange(g_cvMaxMBHOP, OnSettingChanged);
	g_fGreyDBHOP				= GetConVarFloat(g_cvGreyDBHOP);
	HookConVarChange(g_cvGreyDBHOP, OnSettingChanged);
	g_fGreenDBHOP				= GetConVarFloat(g_cvGreenDBHOP);
	HookConVarChange(g_cvGreenDBHOP, OnSettingChanged);
	g_fBlueDBHOP				= GetConVarFloat(g_cvBlueDBHOP);
	HookConVarChange(g_cvBlueDBHOP, OnSettingChanged);
	g_fRedDBHOP					= GetConVarFloat(g_cvRedDBHOP);
	HookConVarChange(g_cvRedDBHOP, OnSettingChanged);
	g_fGoldDBHOP				= GetConVarFloat(g_cvGoldDBHOP);
	HookConVarChange(g_cvGoldDBHOP, OnSettingChanged);
	g_fMaxDBHOP					= GetConVarFloat(g_cvMaxDBHOP);
	HookConVarChange(g_cvMaxDBHOP, OnSettingChanged);
	g_iCTJumpStats			= GetConVarInt(g_cvCTJumpStats);
	HookConVarChange(g_cvCTJumpStats, OnSettingChanged);
	g_iCTDistbugStats		= GetConVarInt(g_cvCTDistbugStats);
	HookConVarChange(g_cvCTDistbugStats, OnSettingChanged);
	g_iNoPreServer			= GetConVarInt(g_cvNoPreServer);
	HookConVarChange(g_cvNoPreServer, OnSettingChanged);
//thanks to JoinedSenses for the help on these 2 cvars
	GetConVarString(g_cvAdvert1, g_szAdvert1, sizeof(g_szAdvert1));
	HookConVarChange(g_cvAdvert1, OnSettingChanged);
	GetConVarString(g_cvAdvert2, g_szAdvert2, sizeof(g_szAdvert2));
	HookConVarChange(g_cvAdvert2, OnSettingChanged);

//commands
	RegConsoleCmd("sm_showkeys",								Client_InfoPanel, "on/off speed/showkeys center panel");
	RegConsoleCmd("sm_speed",										Client_InfoPanel, "on/off speed/showkeys center panel");
	RegConsoleCmd("sm_sync",										Client_StrafeSync,"on/off strafe sync in chat");
	RegConsoleCmd("sm_stats",										Client_Stats,"check client stats");
	RegConsoleCmd("sm_bstats",									Client_BStats,"check client bugged stats");
	RegConsoleCmd("sm_sound",										Client_QuakeSounds,"on/off quake sounds");
	RegConsoleCmd("sm_ljblock",									Client_Ljblock,"registers a lj block");
	RegConsoleCmd("sm_colorchat",								Client_Colorchat, "on/off jumpstats messages of others in chat");
	RegConsoleCmd("sm_jumptop",									Client_Top, "jump top");
	RegConsoleCmd("sm_top",											Client_Top, "jump top");
	RegConsoleCmd("sm_rtop",										Client_RTop, "no bug top");
	RegConsoleCmd("sm_buggedjumptop",						Client_BTop, "bugged top");
	RegConsoleCmd("sm_btop",										Client_BTop, "bugged top");
	RegConsoleCmd("sm_js",											Client_JS, "Settings panel");
	RegConsoleCmd("sm_jssettings",							Client_JS, "Settings panel");
	RegAdminCmd("sm_resetjumpstats",						Admin_DropPlayerJump, ADMIN_LEVEL, "[JS] Resets nobug jump stats - requires ban perm");
	RegAdminCmd("sm_resetallljrecords",					Admin_ResetAllLjRecords, ADMIN_LEVEL, "[JS] Resets nobug lj records - requires ban perm");
	RegAdminCmd("sm_resetallljblockrecords",		Admin_ResetAllLjBlockRecords, ADMIN_LEVEL, "[JS] Resets all lj block records - requires ban perm");
	RegAdminCmd("sm_resetallwjrecords",					Admin_ResetAllWjRecords, ADMIN_LEVEL, "[JS] Resets all wj records - requires ban perm");
	RegAdminCmd("sm_resetallbhoprecords",				Admin_ResetAllBhopRecords, ADMIN_LEVEL, "[JS] Resets all bhop records - requires ban perm");
	RegAdminCmd("sm_resetalldropbhopecords",		Admin_ResetAllDropBhopRecords, ADMIN_LEVEL, "[JS] Resets all drop bjop records - requires ban perm");
	RegAdminCmd("sm_resetallmultibhoprecords",	Admin_ResetAllMultiBhopRecords, ADMIN_LEVEL, "[JS] Resets all multi bhop records - requires ban perm");
	RegAdminCmd("sm_resetljrecord",							Admin_ResetLjRecords, ADMIN_LEVEL, "[JS] Resets lj record for given steamid - requires ban perm");
	RegAdminCmd("sm_resetljblockrecord",				Admin_ResetLjBlockRecords, ADMIN_LEVEL, "[JS] Resets lj block record for given steamid - requires ban perm");
	RegAdminCmd("sm_resetbhoprecord",						Admin_ResetBhopRecords, ADMIN_LEVEL, "[JS] Resets bhop record for given steamid - requires ban perm");
	RegAdminCmd("sm_resetdropbhoprecord",				Admin_ResetDropBhopRecords, ADMIN_LEVEL, "[JS] Resets drop bhop record for given steamid - requires ban perm");
	RegAdminCmd("sm_resetwjrecord",							Admin_ResetWjRecords, ADMIN_LEVEL, "[JS] Resets wj record for given steamid - requires ban perm");
	RegAdminCmd("sm_resetmultibhoprecord",			Admin_ResetMultiBhopRecords, ADMIN_LEVEL, "[JS] Resets multi bhop record for given steamid - requires ban perm");
	RegAdminCmd("sm_resetplayerjumpstats",			Admin_ResetPlayerJumpstats, ADMIN_LEVEL, "[JS] Resets jump stats for given steamid - requires ban perm");
	RegAdminCmd("sm_bresetallljrecords",				Admin_BResetAllLjRecords, ADMIN_LEVEL, "[JS] Resets bugged lj records - requires ban perm");
	RegAdminCmd("sm_bresetljrecord",						Admin_BResetLjRecords, ADMIN_LEVEL, "[JS] Resets lj record for given steamid - requires ban perm");
//Hooks
	HookEvent("player_jump", 										Event_OnJump, EventHookMode_Pre);
	HookEvent("player_spawn", 									Event_OnPlayerSpawn, EventHookMode_Post);
//plugin loaded?
	for(new z=1;z<=MaxClients;z++)
		OnClientPutInServer(z);
	BuildPath(Path_SM, g_js_LogPath, PLATFORM_MAX_PATH, "logs/amuJS.log");
//COOKIES
	g_hEnableQuakeSounds = RegClientCookie("SoundCookie", "Quake Sounds Cookie", CookieAccess_Private);
	g_db_hDistbug = RegClientCookie("DistbugCookie", "Distance Bug Cookie", CookieAccess_Private);
	g_hColorChat = RegClientCookie("ColorChatCookie", "Color chat Cookie", CookieAccess_Private);
	g_hInfoPanel = RegClientCookie("SpeedCookie", "Speed Panel Cookie", CookieAccess_Private);
	g_hStrafeSync = RegClientCookie("StrafeStatsCookie", "Strafe Sync Cookie", CookieAccess_Private);
	g_db_hStrafeStats = RegClientCookie("DistbugStrafeStatsCookie", "DB Strafe stats cookie", CookieAccess_Private);
	g_hKeyColorCookie = RegClientCookie("KeyColorCookie", "Speed Panel Key Color Cookie", CookieAccess_Private);
	g_hPerfColorCookie = RegClientCookie("PerfColorCookie", "Speed Panel Perf Color Cookie", CookieAccess_Private);
	g_hSpeedColorCookie = RegClientCookie("SpeedColorCookie", "Speed Panel Speed Color Cookie", CookieAccess_Private);
	g_hMoneyCookie = RegClientCookie("MoneyCookie", "No Bug LJ PB Money Cookie", CookieAccess_Private);
	for (new i = MaxClients; i > 0; --i) {
		if(!AreClientCookiesCached(i))
			continue;
		OnClientPostAdminCheck(i);
		UpdateThing(i);
	}
//distbug
	g_db_fTickRate = 1 / GetTickInterval();
	RegConsoleCmd("sm_distbug", 								Command_Distbug);
	RegConsoleCmd("sm_strafestats", 						Command_StrafeStats);
	g_db_hGravity = FindConVar("sv_gravity");
	HookConVarChange(g_db_hGravity, OnConvarChanged);
	if(g_db_hGravity != INVALID_HANDLE)
		g_db_fTickGravity = GetConVarFloat(g_db_hGravity) / g_db_fTickRate;
}
public UpdateThing(int client) {
	SpeedPanelUpdate[client] = false;
}
public OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	if(convar == g_cvGreyLJ)
		g_fGreyLJ = StringToFloat(newValue[0]);
	else if(convar == g_cvGreenLJ)
		g_fGreenLJ = StringToFloat(newValue[0]);
	else if(convar == g_cvBlueLJ)
		g_fBlueLJ = StringToFloat(newValue[0]);
	else if(convar == g_cvRedLJ)
		g_fRedLJ = StringToFloat(newValue[0]);
	else if(convar == g_cvGoldLJ)
		g_fGoldLJ = StringToFloat(newValue[0]);
	else if(convar == g_cvMaxLJ)
		g_fMaxLJ = StringToFloat(newValue[0]);
	else if(convar == g_cvGreyWJ)
		g_fGreyWJ = StringToFloat(newValue[0]);
	else if(convar == g_cvGreenWJ)
		g_fGreenWJ = StringToFloat(newValue[0]);
	else if(convar == g_cvBlueWJ)
		g_fBlueWJ = StringToFloat(newValue[0]);
	else if(convar == g_cvRedWJ)
		g_fRedWJ = StringToFloat(newValue[0]);
	else if(convar == g_cvGoldWJ)
		g_fGoldWJ = StringToFloat(newValue[0]);
	else if(convar == g_cvMaxWJ)
		g_fMaxWJ = StringToFloat(newValue[0]);
	else if(convar == g_cvGreyBHOP)
		g_fGreyBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvGreenBHOP)
		g_fGreenBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvBlueBHOP)
		g_fBlueBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvRedBHOP)
		g_fRedBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvGoldBHOP)
		g_fGoldBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvMaxBHOP)
		g_fMaxBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvGreyMBHOP)
		g_fGreyMBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvGreenMBHOP)
		g_fGreenMBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvBlueMBHOP)
		g_fBlueMBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvRedMBHOP)
		g_fRedMBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvGoldMBHOP)
		g_fGoldMBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvMaxMBHOP)
		g_fMaxMBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvGreyDBHOP)
		g_fGreyDBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvGreenDBHOP)
		g_fGreenDBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvBlueDBHOP)
		g_fBlueDBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvRedDBHOP)
		g_fRedDBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvGoldDBHOP)
		g_fGoldDBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvMaxDBHOP)
		g_fMaxDBHOP = StringToFloat(newValue[0]);
	else if(convar == g_cvCTJumpStats)
		g_iCTJumpStats = StringToInt(newValue[0]);
	else if(convar == g_cvCTDistbugStats)
		g_iCTDistbugStats = StringToInt(newValue[0]);
	else if(convar == g_cvNoPreServer)
		g_iNoPreServer = StringToInt(newValue)
	else if(convar == g_cvAdvert1)
		strcopy(g_szAdvert1, sizeof(g_szAdvert1), newValue);
	else if(convar == g_cvAdvert2)
		strcopy(g_szAdvert2, sizeof(g_szAdvert2), newValue);
}
public OnClientPostAdminCheck(int client) {
	char sCookie[128];
	if(SpeedPanelUpdate[client]) {
		GetClientCookie(client, g_hKeyColorCookie, sCookie, sizeof(sCookie));
		g_iKeyColors[client] = StringToInt(sCookie);
		GetClientCookie(client, g_hPerfColorCookie, sCookie, sizeof(sCookie));
		g_iPerfColor[client] = StringToInt(sCookie);
		GetClientCookie(client, g_hSpeedColorCookie, sCookie, sizeof(sCookie));
		g_iSpeedColor[client] = StringToInt(sCookie);
	} else {
		GetClientCookie(client, g_hEnableQuakeSounds, sCookie, sizeof(sCookie));
		g_iEnableQuakeSounds[client] = StringToInt(sCookie);
		GetClientCookie(client, g_db_hDistbug, sCookie, sizeof(sCookie));
		g_db_iDistbug[client] = StringToInt(sCookie);
		GetClientCookie(client, g_hColorChat, sCookie, sizeof(sCookie));
		g_iColorChat[client] = StringToInt(sCookie);
		GetClientCookie(client, g_hInfoPanel, sCookie, sizeof(sCookie));
		g_iInfoPanel[client] = StringToInt(sCookie);
		GetClientCookie(client, g_hStrafeSync, sCookie, sizeof(sCookie));
		g_iStrafeSync[client] = StringToInt(sCookie);
		GetClientCookie(client, g_db_hStrafeStats, sCookie, sizeof(sCookie));
		g_db_iStrafeStats[client] = StringToInt(sCookie);
		GetClientCookie(client, g_hKeyColorCookie, sCookie, sizeof(sCookie));
		g_iKeyColors[client] = StringToInt(sCookie);
		GetClientCookie(client, g_hPerfColorCookie, sCookie, sizeof(sCookie));
		g_iPerfColor[client] = StringToInt(sCookie);
		GetClientCookie(client, g_hSpeedColorCookie, sCookie, sizeof(sCookie));
		g_iSpeedColor[client] = StringToInt(sCookie);
		GetClientCookie(client, g_hMoneyCookie, sCookie, sizeof(sCookie));
		g_iMoneyPB[client] = StringToInt(sCookie);
	}
	GetClientCookie(client, g_db_hDistbug, sCookie, sizeof(sCookie));
	if(sCookie[0] == '\0') {
		strcopy(sCookie, sizeof(sCookie), "1");
		SetClientCookie(client, g_db_hDistbug, sCookie);
	}
	GetClientCookie(client, g_hColorChat, sCookie, sizeof(sCookie));
	if(sCookie[0] == '\0') {
		strcopy(sCookie, sizeof(sCookie), "1");
		SetClientCookie(client, g_hColorChat, sCookie);
	}
	GetClientCookie(client, g_hInfoPanel, sCookie, sizeof(sCookie));
	if(sCookie[0] == '\0') {
		strcopy(sCookie, sizeof(sCookie), "1");
		SetClientCookie(client, g_hInfoPanel, sCookie);
	}
	GetClientCookie(client, g_hStrafeSync, sCookie, sizeof(sCookie));
	if(sCookie[0] == '\0') {
		strcopy(sCookie, sizeof(sCookie), "0");
		SetClientCookie(client, g_hStrafeSync, sCookie);
	}
	GetClientCookie(client, g_hEnableQuakeSounds, sCookie, sizeof(sCookie));
	if(sCookie[0] == '\0') {
		strcopy(sCookie, sizeof(sCookie), "1");
		SetClientCookie(client, g_hEnableQuakeSounds, sCookie);
	}
}
public void OnConvarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	if(convar == g_db_hGravity)
		g_db_fTickGravity = StringToFloat(newValue[0]) / g_db_fTickRate;
}
public OnMapStart() {
	CreateTimer(0.1, Timer1, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	InitPrecache();
	int ent = -1;
	SDKHook(0,SDKHook_Touch,Touch_Wall);
	while((ent = FindEntityByClassname(ent,"func_breakable")) != -1)
		SDKHook(ent,SDKHook_Touch,Touch_Wall);
	ent = -1;
	while((ent = FindEntityByClassname(ent,"func_illusionary")) != -1)
		SDKHook(ent,SDKHook_Touch,Touch_Wall);
	ent = -1;
	while((ent = FindEntityByClassname(ent,"func_wall")) != -1)
		SDKHook(ent,SDKHook_Touch,Touch_Wall);
	ent = -1;
	while((ent = FindEntityByClassname(ent, "trigger_push")) != -1)
		SDKHook(ent,SDKHook_Touch,Push_Touch);
}
public OnMapEnd() {
	int ent = -1;
	SDKUnhook(0,SDKHook_Touch,Touch_Wall);
	while((ent = FindEntityByClassname(ent,"func_breakable")) != -1)
		SDKUnhook(ent,SDKHook_Touch,Touch_Wall);
	ent = -1;
	while((ent = FindEntityByClassname(ent,"func_illusionary")) != -1)
		SDKUnhook(ent,SDKHook_Touch,Touch_Wall);
	ent = -1;
	while((ent = FindEntityByClassname(ent,"func_wall")) != -1)
		SDKUnhook(ent,SDKHook_Touch,Touch_Wall);
	ent = -1;
	while((ent = FindEntityByClassname(ent, "trigger_push")) != -1)
		SDKUnhook(ent,SDKHook_Touch,Push_Touch);
}
public OnClientPutInServer(client) {
	if(!IsValidEntity(client) || IsFakeClient(client) || !IsClientInGame(client))
		return;
	SDKHook(client, SDKHook_StartTouch, Hook_OnTouch);
	g_bdetailView[client] = false;
	g_bFirstTeamJoin[client] = true;
	g_js_bPlayerJumped[client] = false;
	g_bPrestrafeTooHigh[client] = false;
	g_js_bFuncMoveLinear[client] = false;
	g_bBuggedStat[client] = false;
	g_js_Last_Ground_Frames[client] = 11;
	g_js_MultiBhop_Count[client] = 1;
	g_js_GroundFrames[client] = 0;
	g_js_fJump_JumpOff_PosLastHeight[client] = -1.012345;
	g_js_Good_Sync_Frames[client] = 0.0;
	g_js_Sync_Frames[client] = 0.0;
	g_js_LeetJump_Count[client] = 0;
	g_js_GoldJump_Count[client] = 0;
	Format(g_js_szLastJumpDistance[client], 256, "0.0 units");
// set default values
	for(new i = 0; i < MAX_STRAFES; i++) {
		g_js_Strafe_Good_Sync[client][i] = 0.0;
		g_js_Strafe_Frames[client][i] = 0.0;
	}
	char szSteamId[32];
	GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	db_viewPersonalBhopRecord(client, szSteamId);
	db_viewPersonalMultiBhopRecord(client, szSteamId);
	db_viewPersonalWeirdRecord(client, szSteamId);
	db_viewPersonalDropBhopRecord(client, szSteamId);
	db_viewPersonalLJBlockRecord(client, szSteamId);
	db_viewPersonalLJRecord(client, szSteamId);
}
public void OnClientConnected(int client) {
	g_db_fLastVelInAir[client] = NULL_VECTOR;
	g_db_fLastVelocity[client] = NULL_VECTOR;
	g_db_fLastVelocityInAir[client] = NULL_VECTOR;
	g_db_fLastPosInAir[client] = NULL_VECTOR;
	g_db_fLastLastPosInAir[client] = NULL_VECTOR;
	g_db_iFramesInAir[client] = 0;
	g_db_iFramesOnGround[client] = 0;
	g_db_iFramesOverlapped[client] = 0;
	g_db_iDeadAirtime[client] = 0;
	g_db_iWReleaseFrame[client] = 0;
	g_db_iJumpFrame[client] = 0;
	g_db_iLastButtons[client] = 0;
	g_db_bValidJump[client] = false;
	g_db_fDistance[client] = 0.0;
	ResetStatStrafeVars(client);
}
public Action Event_OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0 && g_bFirstTeamJoin[client])
		g_bFirstTeamJoin[client] = false;
	if(IsValidClient(client)) {
		SpeedPanelUpdate[client] = true;
		OnClientPostAdminCheck(client);
		if(g_szAdvert1[0] != '\0'|| g_szAdvert2[0] != '\0') {
			delete g_hAdvertTimer;
			g_hAdvertTimer = CreateTimer(60.0, AdvertTimer, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}
public Action AdvertTimer(Handle timer) {
	if(g_szAdvert1[0] != '\0') {
		g_hAdvertTimer = null;
		CPrintToChatAll("%s", g_szAdvert1);
	}
	if(g_szAdvert2[0] != '\0')
		CreateTimer(20.0, DiscordTimer, TIMER_FLAG_NO_MAPCHANGE);
}
public Action DiscordTimer(Handle timer) {
	CPrintToChatAll("%s", g_szAdvert2);
}
public Hook_OnTouch(client, other) {
	if(IsValidClient(client) && IsPlayerAlive(client)) {
		char classname[32];
		if(IsValidEdict(other))
			GetEntityClassname(other, classname, 32);
		if(StrEqual(classname,"func_movelinear")) {
			g_js_bFuncMoveLinear[client] = true;
			return;
		}
		if(!(GetEntityFlags(client) & FL_ONGROUND) || other != 0)
			ResetJump(client);
	}
}
public db_setupDatabase() {
	char szError[255];
	g_hDb = SQL_Connect("amuJS", false, szError, 255);
	if(g_hDb == INVALID_HANDLE) {
		SetFailState("[amuJS] Unable to connect to database (%s)",szError);
		return;
	}
	char szIdent[8];
	SQL_ReadDriver(g_hDb, szIdent, 8);
	SQL_FastQuery(g_hDb,"SET NAMES 'utf8'");
	db_createTables();
}
public db_setupBDatabase() {
	char szError[255];
	g_hBDb = SQL_Connect("amuJSb", false, szError, 255);
	if(g_hBDb == INVALID_HANDLE) {
		SetFailState("[amuJSb] Unable to connect to database (%s)",szError);
		return;
	}
	char szIdent[8];
	SQL_ReadDriver(g_hBDb, szIdent, 8);
	SQL_FastQuery(g_hBDb,"SET NAMES 'utf8'");
	db_createBTables();
}
public db_createTables() {
	SQL_LockDatabase(g_hDb);
	SQL_FastQuery(g_hDb, sql_createPlayerjumpstats);
	SQL_UnlockDatabase(g_hDb);
}
public db_createBTables() {
	SQL_LockDatabase(g_hBDb);
	SQL_FastQuery(g_hBDb, sql_createBPlayerjumpstats);
	SQL_UnlockDatabase(g_hBDb);
}
public InitPrecache() {
	AddFileToDownloadsTable( NUMBER_ONE_FULL_SOUND_PATH );
	FakePrecacheSound( NUMBER_ONE_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( NUMBER_TWO_FULL_SOUND_PATH );
	FakePrecacheSound( NUMBER_TWO_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( NUMBER_THREE_FULL_SOUND_PATH );
	FakePrecacheSound( NUMBER_THREE_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( OWNAGEJUMP_5_FULL_SOUND_PATH );
	FakePrecacheSound( OWNAGEJUMP_5_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( OWNAGEJUMP_3_FULL_SOUND_PATH );
	FakePrecacheSound( OWNAGEJUMP_3_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( OWNAGEJUMP_FULL_SOUND_PATH );
	FakePrecacheSound( OWNAGEJUMP_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( LEETJUMP_FULL_SOUND_PATH );
	FakePrecacheSound( LEETJUMP_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( LEETJUMP_5_FULL_SOUND_PATH );
	FakePrecacheSound( LEETJUMP_5_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( LEETJUMP_3_FULL_SOUND_PATH );
	FakePrecacheSound( LEETJUMP_3_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( PROJUMP_FULL_SOUND_PATH );
	FakePrecacheSound( PROJUMP_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( PERFECTJUMP_FULL_SOUND_PATH );
	FakePrecacheSound( PERFECTJUMP_RELATIVE_SOUND_PATH );
	g_Beam[0] = PrecacheModel("materials/sprites/laser.vmt");
	g_Beam[1] = PrecacheModel("materials/sprites/halo01.vmt");
}
stock bool IsValidClient(client) {
	if(client >= 1 && client <= MaxClients && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client))
		return true;
	return false;
}
public Action Push_Touch(ent,client) {
	if(IsValidClient(client) && g_js_bPlayerJumped[client])
		ResetJump(client);
	return Plugin_Continue;
}
public Action Touch_Wall(ent,client) {
	if(IsValidClient(client)) {
		if(!(GetEntityFlags(client)&FL_ONGROUND) && g_js_bPlayerJumped[client]) {
			float origin[3];
			float temp[3];
			GetGroundOrigin(client, origin);
			GetClientAbsOrigin(client, temp);
			if(temp[2] - origin[2] <= 0.2)
				ResetJump(client);
		}
	}
	return Plugin_Continue;
}
public Action Event_OnJump(Handle event, const char[] name, bool Broadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_fAirTime[client] = GetEngineTime()
	bool touchwall = WallCheck(client);
	if(!touchwall)
		Prethink(client, view_as<float>({0.0,0.0,0.0}),0.0);
	g_bLJ[client]=false;
	g_bWJ[client]=false;
	g_bBhop[client]=false;
	g_bMBhop[client]=false;
	g_bDBhop[client]=false;

	if(g_js_Last_Ground_Frames[client] == 1)
		g_js_bPerfJump[client] = true;
	else
		g_js_bPerfJump[client] = false;
}
public Action BhopCheck(Handle timer, any client) {
	if(!g_js_bBhop[client]) {
		g_js_LeetJump_Count[client] = 0;
		g_js_GoldJump_Count[client] = 0;
	}
}
float GetSpeed(client) {
	float fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	float speed = SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0));
	return speed;
}
public float GetVelocity(client) {
	float fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	float speed = SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0)+Pow(fVelocity[2],2.0));
	return speed;
}
public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2]) {
	float origin[3];
	float ang[3];
	if(!IsValidClient(client))
		return Plugin_Continue;
//some methods..
	if(IsPlayerAlive(client)) {
		GetClientAbsOrigin(client, origin);
		GetClientEyeAngles(client, ang);
		float flSpeed = GetSpeed(client);
		if(g_js_bPlayerJumped[client] == false && GetEntityFlags(client) & FL_ONGROUND && ((buttons & IN_MOVERIGHT) || (buttons & IN_MOVELEFT) || (buttons & IN_BACK) || (buttons & IN_FORWARD)))
			g_js_GroundFrames[client]++;
	//get player speed
		g_fSpeed[client] = GetSpeed(client);
	//jumpstats/timer
		NoClipCheck(client);
		WaterCheck(client);
		GravityCheck(client);
		BoosterCheck(client);
		WjJumpPreCheck(client,buttons);
		CalcJumpMaxSpeed(client, flSpeed);
		CalcJumpHeight(client);
		CalcJumpSync(client, flSpeed, ang[1], buttons);
		CalcLastJumpHeight(client, buttons, origin);
	//ljblock
		if(g_js_bPlayerJumped[client] == false && GetEntityFlags(client) & FL_ONGROUND && ((buttons & IN_JUMP))) {
			float temp[3];
			float pos[3];
			GetClientAbsOrigin(client,pos);
			g_bLJBlockValidJumpoff[client]=false;
			if(g_bLJBlock[client]) {
				g_bLJBlockValidJumpoff[client]=true;
				g_bLjStarDest[client]=false;
				GetEdgeOrigin(client, origin, temp);
				g_fEdgeDist[client] = GetVectorDistance(temp, origin);
				if(!IsCoordInBlockPoint(pos,g_fOriginBlock[client],false)) {
					if(IsCoordInBlockPoint(pos,g_fDestBlock[client],false))
						g_bLjStarDest[client]=true;
					else
						g_bLJBlockValidJumpoff[client]=false;
				}
			}
		}
		if(g_bLJBlock[client]) {
			TE_SendBlockPoint(client, g_fDestBlock[client][0], g_fDestBlock[client][1], g_Beam[0]);
			TE_SendBlockPoint(client, g_fOriginBlock[client][0], g_fOriginBlock[client][1], g_Beam[0]);
		}
	}
	// postthink jumpstats (landing)
	if(GetEntityFlags(client) & FL_ONGROUND && !g_js_bInvalidGround[client] && !g_bLastInvalidGround[client] && g_js_bPlayerJumped[client] && weapon != -1 && IsValidEntity(weapon) && GetEntProp(client, Prop_Data, "m_nWaterLevel") < 1) {
		GetGroundOrigin(client, g_js_fJump_Landing_Pos[client]);
		g_fAirTime[client] = GetEngineTime() - g_fAirTime[client];
		Postthink(client);
	}
	//reset/save current values
	if(GetEntityFlags(client) & FL_ONGROUND) {
		g_fLastPositionOnGround[client] = origin;
		g_bLastInvalidGround[client] = g_js_bInvalidGround[client];
	}
	if(!(GetEntityFlags(client) & FL_ONGROUND) && g_js_bPlayerJumped[client] == false)
		g_js_GroundFrames[client] = 0;
	g_fLastAngles[client] = ang;
	g_fLastSpeed[client] = g_fSpeed[client];
	g_fLastPosition[client] = origin;
	g_LastButton[client] = buttons;
//distbug things
	g_db_bInAir[client] = GetEntityMoveType(client) != MOVETYPE_NOCLIP && GetEntityMoveType(client) != MOVETYPE_LADDER;
	GetClientAbsOrigin(client, g_db_fPosition[client])
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", g_db_fVelocity[client]);
	if(GetEntityMoveType(client) == MOVETYPE_LADDER)
		g_db_bValidJump[client] = false;
	if(!(buttons & IN_FORWARD) && g_db_iLastButtons[client] & IN_FORWARD)
		g_db_iWReleaseFrame[client] = GetGameTickCount();
	if(GetEntityFlags(client) & FL_ONGROUND) {
		g_db_iFramesOnGround[client]++;
		if(g_db_iFramesOnGround[client] >= 1 && buttons & IN_JUMP && !(g_db_iLastButtons[client] & IN_JUMP)) {
			g_db_bValidJump[client] = true;
			g_db_fMaxHeight[client] = -99999.0;
			g_db_iJumpFrame[client] = GetGameTickCount();
			g_db_fJumpPosition[client] = g_db_fPosition[client];
		}
		if(g_db_bValidJump[client] && g_db_iFramesOnGround[client] == 1) {
			OnJumpLand(client);
			ResetStatStrafeVars(client);
			g_db_fLastVelInAir[client] = NULL_VECTOR;
			g_db_bBlock[client] = false;
		}
		g_db_iFramesInAir[client] = 0;
		g_db_iDeadAirtime[client] = 0;
		g_db_iFramesOverlapped[client] = 0;
	}
	else if(g_db_bInAir[client])
		OnPlayerInAir(client, buttons, vel);
	// LAST
	g_db_fLastVelocity[client] = g_db_fVelocity[client];
	g_db_iLastButtons[client] = buttons;

	if(g_iInfoPanel[client] == 1) {
		char sResult[256];

		Format(sResult, sizeof(sResult), "<font color='#BF2A00'><i>Keys</i></font>");

		bool holdingA = (buttons & IN_MOVELEFT == IN_MOVELEFT);
		bool holdingW = (buttons & IN_FORWARD == IN_FORWARD);
		bool holdingS = (buttons & IN_BACK == IN_BACK);
		bool holdingD = (buttons & IN_MOVERIGHT == IN_MOVERIGHT);
		bool holdingC = (buttons & IN_DUCK == IN_DUCK);
		bool holdingJ = (buttons & IN_JUMP == IN_JUMP);

		char keys[6][64] = { "W", "A", "S", "D", "C", "J" };

		if(!holdingW) keys[0] = "- ";
		if(!holdingA) keys[1] = " - ";
		if(!holdingS) keys[2] = " - ";
		if(!holdingD) keys[3] = " - ";
		if(!holdingC) keys[4] = " - ";
		if(!holdingJ) keys[5] = " - ";

/*		if(holdingW && holdingS) {
			PrintToChat(client, "1");
			keys[0] = "<font color='#FFFFFF'>W - S</font>";
			keys[1] = "";
		} */

		if(IsValidEntity(client) && 1 <= client <= MaxClients) {
			if(g_js_fPreStrafe[client] > 276.0)
				PrintHintText(client, "Last Jump: %s\nSpeed: (%.1f) u/s", g_js_szLastJumpDistance[client], g_fSpeed[client], g_iHEX[g_iPerfColor[client]], g_js_fPreStrafe[client], g_iHEX[g_iKeyColors[client]], keys[0], keys[1], keys[2], keys[3], keys[4], keys[5]);
			else
				PrintHintText(client, "Last Jump: %s\nSpeed: (%.1f) u/s", g_js_szLastJumpDistance[client], g_fSpeed[client], g_js_fPreStrafe[client],g_iHEX[g_iKeyColors[client]], keys[0], keys[1], keys[2], keys[3], keys[4], keys[5]);
		}
	}
	int Cash = GetEntProp(client, Prop_Send, "m_iAccount");
	g_js_fMoneyDist[client] = g_js_fPersonal_Lj_Record[client]*100;
	g_iMoneyPB[client] = RoundToNearest(g_js_fMoneyDist[client]);
	if(Cash != g_iMoneyPB[client])
		SetClientMoney(client, g_iMoneyPB[client]);
	return Plugin_Changed;
}
public CalcJumpMaxSpeed(client, float fspeed) {
	if(g_js_bPlayerJumped[client])
		if(g_fLastSpeed[client] <= fspeed)
			g_js_fMax_Speed[client] = fspeed;
}
public CalcJumpHeight(client) {
	if(g_js_bPlayerJumped[client]) {
		float height[3];
		GetClientAbsOrigin(client, height);
		if(height[2] > g_js_fMax_Height[client])
			g_js_fMax_Height[client] = height[2];
		g_flastHeight[client] = height[2];
	}
}
public CalcLastJumpHeight(client, &buttons, float origin[3]) {
	if(GetEntityFlags(client) & FL_ONGROUND && g_js_bPlayerJumped[client] == false && g_js_GroundFrames[client] > 11) {
		float flPos[3];
		GetClientAbsOrigin(client, flPos);
		g_js_fJump_JumpOff_PosLastHeight[client] = flPos[2];
	}
	float distance = GetVectorDistance(g_fLastPosition[client], origin);
	if(distance > 25.0) {
		if(g_js_bPlayerJumped[client])
			g_js_bPlayerJumped[client] = false;
	}
}
public CalcJumpSync(client, float speed, float ang, &buttons) {
	if(g_js_bPlayerJumped[client]) {
		bool turning_right = false;
		bool turning_left = false;
		if(ang < g_fLastAngles[client][1])
			turning_right = true;
		else if(ang > g_fLastAngles[client][1])
				turning_left = true;
	//strafestats
		if(turning_left || turning_right) {
			if(!g_js_Strafing_AW[client] && ((buttons & IN_FORWARD) || (buttons & IN_MOVELEFT)) && !(buttons & IN_MOVERIGHT) && !(buttons & IN_BACK)) {
				g_js_Strafing_AW[client] = true;
				g_js_Strafing_SD[client] = false;
				g_js_StrafeCount[client]++;
				g_js_Strafe_Good_Sync[client][g_js_StrafeCount[client]-1] = 0.0;
				g_js_Strafe_Frames[client][g_js_StrafeCount[client]-1] = 0.0;
				g_js_Strafe_Max_Speed[client][g_js_StrafeCount[client] - 1] = speed;
			}
			else if(!g_js_Strafing_SD[client] && ((buttons & IN_BACK) || (buttons & IN_MOVERIGHT)) && !(buttons & IN_MOVELEFT) && !(buttons & IN_FORWARD)) {
				g_js_Strafing_AW[client] = false;
				g_js_Strafing_SD[client] = true;
				g_js_StrafeCount[client]++;
				g_js_Strafe_Good_Sync[client][g_js_StrafeCount[client]-1] = 0.0;
				g_js_Strafe_Frames[client][g_js_StrafeCount[client]-1] = 0.0;
				g_js_Strafe_Max_Speed[client][g_js_StrafeCount[client] - 1] = speed;
			}
		}
	//sync
		if(g_fLastSpeed[client] < speed) {
			g_js_Good_Sync_Frames[client]++;
			if(0 < g_js_StrafeCount[client] <= MAX_STRAFES) {
				g_js_Strafe_Good_Sync[client][g_js_StrafeCount[client] - 1]++;
				g_js_Strafe_Gained[client][g_js_StrafeCount[client] - 1] += (speed - g_fLastSpeed[client]);
			}
		}
		else if(g_fLastSpeed[client] > speed) {
			if(0 < g_js_StrafeCount[client] <= MAX_STRAFES)
				g_js_Strafe_Lost[client][g_js_StrafeCount[client] - 1] += (g_fLastSpeed[client] - speed);
		}
	//strafe frames
		if(0 < g_js_StrafeCount[client] <= MAX_STRAFES) {
			g_js_Strafe_Frames[client][g_js_StrafeCount[client] - 1]++;
			if(g_js_Strafe_Max_Speed[client][g_js_StrafeCount[client] - 1] < speed)
				g_js_Strafe_Max_Speed[client][g_js_StrafeCount[client] - 1] = speed;
		}
	//total frames
		g_js_Sync_Frames[client]++;
	}
}
public WjJumpPreCheck(client, &buttons) {
	if(GetEntityFlags(client) & FL_ONGROUND && g_js_bPlayerJumped[client] == false && g_js_GroundFrames[client] > 11) {
		if(buttons & IN_JUMP)
			g_bLastButtonJump[client] = true;
		else
			g_bLastButtonJump[client] = false;
	}
}
public BoosterCheck(client) {
	float flbaseVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", flbaseVelocity);
	if(flbaseVelocity[0] != 0.0 || flbaseVelocity[1] != 0.0 || flbaseVelocity[2] != 0.0 && g_js_bPlayerJumped[client])
		ResetJump(client);
}
public WaterCheck(client) {
	if(GetEntProp(client, Prop_Data, "m_nWaterLevel") > 0 && g_js_bPlayerJumped[client])
		ResetJump(client);
}
public SurfCheck(client) {
	if(g_js_bPlayerJumped[client] && WallCheck(client))
		ResetJump(client);
}
public NoClipCheck(client) {
	MoveType mt = GetEntityMoveType(client);
	if(mt == MOVETYPE_NOCLIP && (g_js_bPlayerJumped[client])) {
		if(g_js_bPlayerJumped[client])
			ResetJump(client);
	}
}
public ResetJump(client) {
	Format(g_js_szLastJumpDistance[client], 256, "invalid", g_js_fJump_Distance[client]);
	g_js_GroundFrames[client] = 0;
	g_js_bPlayerJumped[client] = false;
}
public bool WallCheck(client) {
	float pos[3];
	float endpos[3];
	float angs[3];
	float vecs[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angs);
	GetAngleVectors(angs, vecs, NULL_VECTOR, NULL_VECTOR);
	angs[1] = -180.0;
	while (angs[1] != 180.0) {
		Handle trace = TR_TraceRayFilterEx(pos, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
		if(TR_DidHit(trace)) {
				TR_GetEndPosition(endpos, trace);
				float fdist = GetVectorDistance(endpos, pos, false);
				if(fdist <= 25.0) {
					CloseHandle(trace);
					return true;
				}
		}
		CloseHandle(trace);
		angs[1]+=15.0;
	}
	return false;
}
public bool TraceFilterPlayers(entity,contentsMask) {
	return (entity > MaxClients) ? true : false;
}
stock GetGroundOrigin(client, float pos[3]) {
	float fOrigin[3];
	float result[3];
	GetClientAbsOrigin(client, fOrigin);
	TraceClientGroundOrigin(client, result, 100.0);
	pos = fOrigin;
	pos[2] = result[2];
}
stock TraceClientGroundOrigin(client, float result[3], float offset) {
	float temp[2][3];
	GetClientEyePosition(client, temp[0]);
	temp[1] = temp[0];
	temp[1][2] -= offset;
	float mins[]={-16.0, -16.0, 0.0};
	float maxs[]={16.0, 16.0, 60.0};
	Handle trace = TR_TraceHullFilterEx(temp[0], temp[1], mins, maxs, MASK_SHOT, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) {
		TR_GetEndPosition(result, trace);
		CloseHandle(trace);
		return 1;
	}
	CloseHandle(trace);
	return 0;
}
bool TraceEntityFilterPlayer(entity, contentsMask) {
	return entity > MaxClients;
}
public GravityCheck(client) {
	float flGravity = GetEntityGravity(client);
	if((flGravity != 0.0 && flGravity !=1.0) && g_js_bPlayerJumped[client])
		ResetJump(client);
}
public Action Timer1(Handle timer) {
	for (new client = 1; client <= MaxClients; client++) {
		if(IsValidClient(client) && IsPlayerAlive(client))
			SurfCheck(client);
	}
	return Plugin_Continue;
}
// thx to V952 https://forums.alliedmods.net/showthread.php?t=212886
stock TraceClientViewEntity(client) {
	float m_vecOrigin[3];
	float m_angRotation[3];
	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);
	Handle tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	int pEntity = -1;
	if(TR_DidHit(tr)) {
		pEntity = TR_GetEntityIndex(tr);
		CloseHandle(tr);
		return pEntity;
	}
	CloseHandle(tr);
	return -1;
}
// thx to V952 https://forums.alliedmods.net/showthread.php?t=212886
bool TRDontHitSelf(entity, any data) { //, mask
	if(entity == data)
		return false;
	return true;
}
// Credits: LJStats by justshoot, Zipcore
public Function_BlockJump(client) {
	float pos[3];
	float origin[3];
	GetAimOrigin(client, pos);
	TraceClientGroundOrigin(client, origin, 100.0);
	bool funclinear;
//get aim target
	char classname[32];
	int target = TraceClientViewEntity(client);
	if(IsValidEdict(target))
		GetEntityClassname(target, classname, 32);
	if(StrEqual(classname,"func_movelinear"))
		funclinear=true;
	if((FloatAbs(pos[2] - origin[2]) <= 0.002) || (funclinear && FloatAbs(pos[2] - origin[2]) <= 0.6)) {
		GetBoxFromPoint(origin, g_fOriginBlock[client]);
		GetBoxFromPoint(pos, g_fDestBlock[client]);
		CalculateBlockGap(client, origin, pos);
		g_fBlockHeight[client] = pos[2];
	} else {
		g_bLJBlock[client] = false;
		CPrintToChat(client, "[{lightgreen}JS{default}] {red}Invalid destination (height offset > 0.0)");
	}
}
// Credits: LJStats by justshoot, Zipcore
stock TE_SendBlockPoint(client, const float pos1[3], const float pos2[3], model) {
	float buffer[4][3];
	buffer[2] = pos1;
	buffer[3] = pos2;
	buffer[0] = buffer[2];
	buffer[0][1] = buffer[3][1];
	buffer[1] = buffer[3];
	buffer[1][1] = buffer[2][1];
	int randco[4];
	randco[0] = GetRandomInt(0, 255);
	randco[1] = GetRandomInt(0, 255);
	randco[2] = GetRandomInt(0, 255);
	randco[3] = GetRandomInt(125, 255);
	TE_SetupBeamPoints(buffer[3], buffer[0], model, 0, 0, 0, 0.13, 2.0, 2.0, 10, 0.0, randco, 0);
	TE_SendToClient(client);
	TE_SetupBeamPoints(buffer[0], buffer[2], model, 0, 0, 0, 0.13, 2.0, 2.0, 10, 0.0, randco, 0);
	TE_SendToClient(client);
	TE_SetupBeamPoints(buffer[2], buffer[1], model, 0, 0, 0, 0.13, 2.0, 2.0, 10, 0.0, randco, 0);
	TE_SendToClient(client);
	TE_SetupBeamPoints(buffer[1], buffer[3], model, 0, 0, 0, 0.13, 2.0, 2.0, 10, 0.0, randco, 0);
	TE_SendToClient(client);
}
// Credits: LJStats by justshoot, Zipcore
GetEdgeOrigin(client, float ground[3], float result[3]) {
	result[0] = (g_fEdgeVector[client][0]*ground[0] + g_fEdgeVector[client][1]*g_fEdgePoint[client][0], g_fEdgeVector[client][0]+g_fEdgeVector[client][1]);
	result[1] = (g_fEdgeVector[client][1]*ground[1] - g_fEdgeVector[client][0]*g_fEdgePoint[client][1], g_fEdgeVector[client][1]-g_fEdgeVector[client][0]);
	result[2] = ground[2];
}
// Credits: LJStats by justshoot, Zipcore
stock TraceWallOrigin(float fOrigin[3], float vAngles[3], float result[3]) {
	Handle trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) {
		TR_GetEndPosition(result, trace);
		CloseHandle(trace);
		return 1;
	}
	CloseHandle(trace);
	return 0;
}
// Credits: LJStats by justshoot, Zipcore
stock TraceGroundOrigin(float fOrigin[3], float result[3]) {
	float vAngles[3] = {90.0, 0.0, 0.0};
	Handle trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) {
		TR_GetEndPosition(result, trace);
		CloseHandle(trace);
		return 1;
	}
	CloseHandle(trace);
	return 0;
}
// Credits: LJStats by justshoot, Zipcore
stock GetBeamEndOrigin(float fOrigin[3], float vAngles[3], float distance, float result[3]) {
	float AngleVector[3];
	GetAngleVectors(vAngles, AngleVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(AngleVector, AngleVector);
	ScaleVector(AngleVector, distance);
	AddVectors(fOrigin, AngleVector, result);
}
// Credits: LJStats by justshoot, Zipcore
stock GetBeamHitOrigin(float fOrigin[3], float vAngles[3], float result[3]) {
	Handle trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) {
		TR_GetEndPosition(result, trace);
		CloseHandle(trace);
	}
}
// Credits: LJStats by justshoot, Zipcore
stock GetAimOrigin(client, float hOrigin[3]) {
	float vAngles[3];
	float fOrigin[3];
	GetClientEyePosition(client,fOrigin);
	GetClientEyeAngles(client, vAngles);
	Handle trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) {
		TR_GetEndPosition(hOrigin, trace);
		CloseHandle(trace);
		return 1;
	}
	CloseHandle(trace);
	return 0;
}
// Credits: LJStats by justshoot, Zipcore
stock GetBoxFromPoint(float origin[3], float result[2][3]) {
	float temp[3];
	temp = origin;
	temp[2] += 1.0;
	float ang[4][3];
	ang[1][1] = 90.0;
	ang[2][1] = 180.0;
	ang[3][1] = -90.0;
	bool edgefound[4];
	float dist[4];
	float tempdist[4];
	float position[3];
	float ground[3];
	float Last[4];
	float Edge[4][3];
	for(new i = 0; i < 4; i++) {
		TraceWallOrigin(temp, ang[i], Edge[i]);
		tempdist[i] = GetVectorDistance(temp, Edge[i]);
		Last[i] = origin[2];
		while(dist[i] < tempdist[i]) {
			if(edgefound[i])
				break;
			GetBeamEndOrigin(temp, ang[i], dist[i], position);
			TraceGroundOrigin(position, ground);
			if((Last[i] != ground[2])&&(Last[i] > ground[2])) {
				Edge[i] = ground;
				edgefound[i] = true;
			}
			Last[i] = ground[2];
			dist[i] += 10.0;
		}
		if(!edgefound[i]) {
			TraceGroundOrigin(Edge[i], Edge[i]);
			edgefound[i] = true;
		} else {
			ground = Edge[i];
			ground[2] = origin[2];
			MakeVectorFromPoints(ground, origin, position);
			GetVectorAngles(position, ang[i]);
			ground[2] -= 1.0;
			GetBeamHitOrigin(ground, ang[i], Edge[i]);
		}
		Edge[i][2] = origin[2];
	}
	if(edgefound[0]&&edgefound[1]&&edgefound[2]&&edgefound[3]) {
		result[0][2] = origin[2];
		result[1][2] = origin[2];
		result[0][0] = Edge[0][0];
		result[0][1] = Edge[1][1];
		result[1][0] = Edge[2][0];
		result[1][1] = Edge[3][1];
	}
}
// Credits: LJStats by justshoot, Zipcore
CalculateBlockGap(client, float origin[3], float target[3]) {
	float distance = GetVectorDistance(origin, target);
	float rad = DegToRad(15.0);
	float newdistance = distance/Cosine(rad);
	float eye[3];
	float eyeangle[2][3];
	float temp = 0.0;
	GetClientEyePosition(client, eye);
	GetClientEyeAngles(client, eyeangle[0]);
	eyeangle[0][0] = 0.0;
	eyeangle[1] = eyeangle[0];
	eyeangle[0][1] += 10.0;
	eyeangle[1][1] -= 10.0;
	float position[3];
	float ground[3];
	float Last[2];
	float Edge[2][3];
	bool edgefound[2];
	while(temp < newdistance) {
		temp += 10.0;
		for(new i = 0; i < 2 ; i++) {
			if(edgefound[i])
				continue;
			GetBeamEndOrigin(eye, eyeangle[i], temp, position);
			TraceGroundOrigin(position, ground);
			if(temp == 10.0)
				Last[i] = ground[2];
			else if((Last[i] != ground[2])&&(Last[i] > ground[2])) {
				Edge[i] = ground;
				edgefound[i] = true;
			}
			Last[i] = ground[2];
		}
	}
	float temp2[2][3];
	if(edgefound[0] && edgefound[1]) {
		for(new i = 0; i < 2 ; i++) {
			temp2[i] = Edge[i];
			temp2[i][2] = origin[2] - 1.0;
			if(eyeangle[i][1] > 0)
				eyeangle[i][1] -= 180.0;
			else
				eyeangle[i][1] += 180.0;
			GetBeamHitOrigin(temp2[i], eyeangle[i], Edge[i]);
		}
	} else {
		g_bLJBlock[client] = false;
		CPrintToChat(client, "[{lightgreen}JS{default}] {red}Invalid destination (failed to detect edges)");
		return;
	}
	g_fEdgePoint[client] = Edge[0];
	MakeVectorFromPoints(Edge[0], Edge[1], position);
	g_fEdgeVector[client] = position;
	NormalizeVector(g_fEdgeVector[client], g_fEdgeVector[client]);
	CorrectEdgePoint(client);
	GetVectorAngles(position, position);
	position[1] += 90.0;
	GetBeamHitOrigin(Edge[0], position, Edge[1]);
	distance = GetVectorDistance(Edge[0], Edge[1]);
	g_BlockDist[client] = RoundToNearest(distance);
	float surface = GetVectorDistance(g_fDestBlock[client][0],g_fDestBlock[client][1]);
	surface *= surface;
	if(surface > 1000000) {
		CPrintToChat(client, "[{lightgreen}JS{default}] {red}Invalid destination (selected destination is too large)");
		return;
	}
	if(!IsCoordInBlockPoint(Edge[1],g_fDestBlock[client],true)) {
		g_bLJBlock[client] = false;
		CPrintToChat(client, "[{lightgreen}JS{default}] {lightgreen}Invalid destination");
		return;
	}
	TE_SetupBeamPoints(Edge[0], Edge[1], g_Beam[0], 0, 0, 0, 1.0, 1.0, 1.0, 10, 0.0, {0,255,255,155}, 0);
	TE_SendToClient(client);
	if(g_BlockDist[client] > 195 && g_BlockDist[client] <= 320) {
		CPrintToChat(client, "[{lightgreen}JS{default}] {lime}Longjump Block ({green}%i units{lime}) registered!", g_BlockDist[client]);
		g_bLJBlock[client] = true;
	}
	else if(g_BlockDist[client] < 195)
		CPrintToChat(client, "[{lightgreen}JS{default}] {red}You can only register blocks down to 196 units! (current gap: {darkred}%i units{red})", g_BlockDist[client]);
	else if(g_BlockDist[client] > 320)
		CPrintToChat(client, "[{lightgreen}JS{default}] {red}You can only register blocks up to 320 units! (current gap: {darkred}%i units{red})", g_BlockDist[client]);
}
// Credits: LJStats by justshoot, Zipcore
stock bool IsCoordInBlockPoint(const float origin[3], const float pos[2][3], bool ignorez) {
	bool bX;
	bool bY;
	bool bZ;
	float temp[2][3];
	temp[0] = pos[0];
	temp[1] = pos[1];
	temp[0][0] += 16.0;
	temp[0][1] += 16.0;
	temp[1][0] -= 16.0;
	temp[1][1] -= 16.0;
	if(ignorez)
		bZ=true;
	if(temp[0][0] > temp[1][0]) {
		if(temp[0][0] >= origin[0] >= temp[1][0])
			bX = true;
	}
	else if(temp[1][0] >= origin[0] >= temp[0][0])
		bX = true;
	if(temp[0][1] > temp[1][1]) {
		if(temp[0][1] >= origin[1] >= temp[1][1])
			bY = true;
	}
	else if(temp[1][1] >= origin[1] >= temp[0][1])
		bY = true;
	if(temp[0][2] + 0.002 >= origin[2] >= temp[0][2])
		bZ = true;
	if(bX&&bY&&bZ)
		return true;
	else
		return false;
}
// Credits: LJStats by justshoot, Zipcore
CorrectEdgePoint(client) {
	float vec[3];
	vec[0] = 0.0 - g_fEdgeVector[client][1];
	vec[1] = g_fEdgeVector[client][0];
	vec[2] = 0.0;
	ScaleVector(vec, 16.0);
	AddVectors(g_fEdgePoint[client], vec, g_fEdgePoint[client]);
}
public Prethink (client, float pos[3], float vel) {
//booster or moving plattform?
	float flVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", flVelocity);
	if(flVelocity[0] != 0.0 || flVelocity[1] != 0.0 || flVelocity[2] != 0.0)
		g_js_bInvalidGround[client] = true;
	else
		g_js_bInvalidGround[client] = false;
//reset vars
	g_js_Good_Sync_Frames[client] = 0.0;
	g_js_Sync_Frames[client] = 0.0;
	for(new i = 0; i < MAX_STRAFES; i++) {
		g_js_Strafe_Good_Sync[client][i] = 0.0;
		g_js_Strafe_Frames[client][i] = 0.0;
		g_js_Strafe_Gained[client][i] = 0.0;
		g_js_Strafe_Lost[client][i] = 0.0;
		g_js_Strafe_Max_Speed[client][i] = 0.0;
	}
	g_js_fJumpOff_Time[client] = GetEngineTime();
	g_js_fMax_Speed[client] = 0.0;
	g_js_StrafeCount[client] = 0;
	g_js_bDropJump[client] = false;
	g_js_bPlayerJumped[client] = true;
	g_js_Strafing_AW[client] = false;
	g_js_Strafing_SD[client] = false;
	g_js_bFuncMoveLinear[client] = false;
	g_js_fMax_Height[client] = -99999.0;
	g_js_fLast_Jump_Time[client] = GetEngineTime();
	float fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	g_js_fPreStrafe[client] = SquareRoot(Pow(fVelocity[0], 2.0) + Pow(fVelocity[1], 2.0) + Pow(fVelocity[2], 2.0));
	GetGroundOrigin(client, g_js_fJump_JumpOff_Pos[client]);
	if(g_js_fJump_JumpOff_PosLastHeight[client] != -1.012345) {
		float fGroundDiff = g_js_fJump_JumpOff_Pos[client][2] - g_js_fJump_JumpOff_PosLastHeight[client];
		if(fGroundDiff > -0.1 && fGroundDiff < 0.1)
			fGroundDiff = 0.0;
		if(fGroundDiff <= -1.5) {
			g_js_bDropJump[client] = true;
			g_js_fDropped_Units[client] = FloatAbs(fGroundDiff);
		}
	}
	if(g_js_GroundFrames[client]<11)
		g_js_bBhop[client] = true;
	else
		g_js_bBhop[client] = false;
//last InitialLastHeight
	g_js_fJump_JumpOff_PosLastHeight[client] = g_js_fJump_JumpOff_Pos[client][2];
}
public Postthink(client) {
	if(!IsValidClient(client))
		return;
	int ground_frames = g_js_GroundFrames[client];
	int strafes = g_js_StrafeCount[client];
	g_js_GroundFrames[client] = 0;
	g_js_fMax_Speed_Final[client] = g_js_fMax_Speed[client];
	char szName[128];
	GetClientName(client, szName, 128);
	//get landing position & calc distance
	g_js_fJump_DistanceX[client] = g_js_fJump_Landing_Pos[client][0] - g_js_fJump_JumpOff_Pos[client][0];
	if(g_js_fJump_DistanceX[client] < 0)
		g_js_fJump_DistanceX[client] = -g_js_fJump_DistanceX[client];
	g_js_fJump_DistanceZ[client] = g_js_fJump_Landing_Pos[client][1] - g_js_fJump_JumpOff_Pos[client][1];
	if(g_js_fJump_DistanceZ[client] < 0)
		g_js_fJump_DistanceZ[client] = -g_js_fJump_DistanceZ[client];
	g_js_fJump_Distance[client] = SquareRoot(Pow(g_js_fJump_DistanceX[client], 2.0) + Pow(g_js_fJump_DistanceZ[client], 2.0));
	g_js_fJump_Distance[client] = g_js_fJump_Distance[client] + 32;
	//ground diff
	float fGroundDiff = g_js_fJump_Landing_Pos[client][2] - g_js_fJump_JumpOff_Pos[client][2];
	float fJump_Height;
	if(fGroundDiff > -0.1 && fGroundDiff < 0.1)
		fGroundDiff = 0.0;
	//workaround
	if(g_js_bFuncMoveLinear[client] && fGroundDiff < 0.6 && fGroundDiff > -0.6)
		fGroundDiff = 0.0;
	//ground diff 2
	float groundpos[3];
	GetClientAbsOrigin(client, groundpos);
	float fGroundDiff2 = groundpos[2] - g_fLastPositionOnGround[client][2];
	//GetHeight
	if(FloatAbs(g_js_fJump_JumpOff_Pos[client][2]) > FloatAbs(g_js_fMax_Height[client]))
		fJump_Height = FloatAbs(g_js_fJump_JumpOff_Pos[client][2]) - FloatAbs(g_js_fMax_Height[client]);
	else
		fJump_Height = FloatAbs(g_js_fMax_Height[client]) - FloatAbs(g_js_fJump_JumpOff_Pos[client][2]);
	g_flastHeight[client] = fJump_Height;
	//sync/strafes
	int sync = RoundToNearest(g_js_Good_Sync_Frames[client] / g_js_Sync_Frames[client] * 100.0);
	g_js_Strafes_Final[client] = strafes;
	g_js_Sync_Final[client] = sync;
	//Calc & format strafe sync for chat output
	char szStrafeSync[255];
	char szStrafeSync2[255];
	char szSteamID[128];
	int strafe_sync;
	if(g_iStrafeSync[client] == 1 && strafes > 1) {
		for (new i = 0; i < strafes; i++) {
			if(i==0)
				Format(szStrafeSync, 255, "[%cJS%c] %cSync:",MOSSGREEN,WHITE,GRAY);
			if(g_js_Strafe_Frames[client][i] == 0.0 || g_js_Strafe_Good_Sync[client][i] == 0.0)
				strafe_sync = 0;
			else
				strafe_sync = RoundToNearest(g_js_Strafe_Good_Sync[client][i] / g_js_Strafe_Frames[client][i] * 100.0);
			if(i==0)
				Format(szStrafeSync2, 255, " %c%i.%c %i%c",GRAY, (i+1),LIMEGREEN,strafe_sync,PERCENT);
			else
				Format(szStrafeSync2, 255, "%c - %i.%c %i%c",GRAY, (i+1),LIMEGREEN,strafe_sync,PERCENT);
			StrCat(szStrafeSync, sizeof(szStrafeSync), szStrafeSync2);
			if((i+1) == strafes) {
				Format(szStrafeSync2, 255, " %c[%c%i%c%c]",GRAY,PURPLE, sync,PERCENT,GRAY);
				StrCat(szStrafeSync, sizeof(szStrafeSync), szStrafeSync2);
			}
		}
	}
	else
		Format(szStrafeSync,255, "");
	char szStrafeStats[1024];
	char szGained[16];
	char szLost[16];
	//Format StrafeStats Console
	if(strafes > 1) {
		Format(szStrafeStats,1024, " #. Sync		Gained	  Lost		MaxSpeed\n");
		for(new i = 0; i < strafes; i++) {
			int sync2 = RoundToNearest(g_js_Strafe_Good_Sync[client][i] / g_js_Strafe_Frames[client][i] * 100.0);
			if(sync2 < 0)
				sync2 = 0;
			if(g_js_Strafe_Gained[client][i] < 10.0)
				Format(szGained,16, "%.3f ", g_js_Strafe_Gained[client][i]);
			else
				Format(szGained,16, "%.3f", g_js_Strafe_Gained[client][i]);
			if(g_js_Strafe_Lost[client][i] < 10.0)
				Format(szLost,16, "%.3f ", g_js_Strafe_Lost[client][i]);
			else
				Format(szLost,16, "%.3f", g_js_Strafe_Lost[client][i]);
			Format(szStrafeStats,1024, "%s%2i. %3i%s		%s	  %s	  %3.3f\n",\
			szStrafeStats,\
			i + 1,\
			sync2,\
			PERCENT,\
			szGained,\
			szLost,\
			g_js_Strafe_Max_Speed[client][i]);
		}
	}
	else
		Format(szStrafeStats,1024, "");
	//vertical jump
	if(fGroundDiff2 > 1.82 || fGroundDiff2 < -1.82 || fGroundDiff != 0.0) {
		Format(g_js_szLastJumpDistance[client], 256, "vertical");
		PostThinkPost(client, ground_frames);
		return;
	}
	//invalid jump
	if(g_fAirTime[client] > 0.83) {
		Format(g_js_szLastJumpDistance[client], 256, "invalid");
		PostThinkPost(client, ground_frames);
		return;
	}
	//cheated jump
	if(strafes >= MAX_JUMPSTRAFES) {
		Format(g_js_szLastJumpDistance[client], 256, "Too many strafes");
		PostThinkPost(client, ground_frames);
		LogToFileEx(g_js_LogPath, "%s [JS] %s jumped %0.4f units with a Stat [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szSteamID,szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
		return;
	}
	//funk bug
	for (new i = 0; i < strafes; i++) {
		if(g_js_Strafe_Lost[client][i] >= 20 && !g_js_bBhop[client]) {
			Format(g_js_szLastJumpDistance[client], 256, "Possible Funk Bug");
			PostThinkPost(client, ground_frames);
			return;
		}
	}
	//silent strafe
	for (new i = 0; i < strafes; i++) {
		if(g_js_Strafe_Gained[client][i] >= 26 && !g_js_bBhop[client] && g_js_fJump_Distance[client] >= 262) {
			Format(g_js_szLastJumpDistance[client], 256, "Possible Silent Strafe");
			PostThinkPost(client, ground_frames);
			PrintToConsole(client, "%s", szStrafeStats);
			return;
		}
	}
	//CT
	if(GetClientTeam(client) == CS_TEAM_CT && g_iCTJumpStats == 1) {
		Format(g_js_szLastJumpDistance[client], 256, "T Only Statting Enabled");
		PostThinkPost(client, ground_frames);
		return;
	}
	char sBuggedDist[128];
	char sBuggedC[128];
	//bug check
	g_db_fDistance[client] = CalcJumpDistance(client);
	if(g_db_fDistance[client] <= g_js_fJump_Distance[client]) {
		g_bBuggedStat[client] = true;
		Format(sBuggedDist, 128, "{default}[{purple}Bugged{default}]");
		Format(sBuggedC, 128, "[Bugged]");
	}
	if(g_db_fDistance[client] > g_js_fJump_Distance[client]) {
		g_bBuggedStat[client] = false;
		Format(sBuggedDist, 32, "");
		Format(sBuggedC, 32, "");
	}
	bool touchwall = WallCheck(client);
	bool ValidJump=true;
	g_bCheatedJump[client] = false;
//Ladder Bug fix            This should check if prestrafe is too high or low
	if(g_iNoPreServer == 0 && ground_frames > 11 && fGroundDiff == 0.0 && fJump_Height <= 66.0 && g_js_fJump_Distance[client] < g_fMaxLJ && g_js_fMax_Speed_Final[client] > 250.0 && !touchwall && !(strafes > MAX_JUMPSTRAFES))
		if(g_js_fPreStrafe[client] > 251.0 || g_js_fPreStrafe[client] < 249.0) {
			Format(g_js_szLastJumpDistance[client], 256, "Possible Ladder Jump");
			PostThinkPost(client, ground_frames);
			return;
		}
//CheckIsLJ
	if(g_js_fPreStrafe[client] < 277 && ground_frames > 11 && fGroundDiff == 0.0 && fJump_Height <= 66.0 && g_js_fJump_Distance[client] < g_fMaxLJ && g_js_fMax_Speed_Final[client] > 250.0 && !touchwall && !(strafes > MAX_JUMPSTRAFES)) {
		bool ljblock=false;
		char sBlockDist[32];
		Format(sBlockDist, 32, "");
		char sBlockDistCon[32];
		Format(sBlockDistCon, 32, "");
		if(g_bLJBlock[client] && g_BlockDist[client] > 225 && g_js_fJump_Distance[client] >= float(g_BlockDist[client])) {
			if(g_bLJBlockValidJumpoff[client]) {
				if(g_bLjStarDest[client]) {
					if(IsCoordInBlockPoint(g_js_fJump_Landing_Pos[client],g_fOriginBlock[client],true)) {
						Format(sBlockDist, 32, "%t", "LjBlock", GRAY,YELLOW,g_BlockDist[client],GRAY);
						Format(sBlockDistCon, 32, " [%i block]", g_BlockDist[client]);
						ljblock=true;
					}
				} else if(IsCoordInBlockPoint(g_js_fJump_Landing_Pos[client],g_fDestBlock[client],true)) {
					Format(sBlockDist, 32, "%t", "LjBlock", GRAY,YELLOW,g_BlockDist[client],GRAY);
					Format(sBlockDistCon, 32, " [%i block]", g_BlockDist[client]);
					ljblock=true;
				}
			}
		}
		PrintToConsole(client, "		");
		PrintToConsole(client, "[JS] %s jumped %0.4f units with a %sLongJump [%i Strafes | %.3f %s | %.0f Max | Height %.1f | %i%c Sync]%s",szName, g_js_fJump_Distance[client],sBuggedC,strafes, g_js_fPreStrafe[client], "Pre", g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT,sBlockDistCon);
		PrintToConsole(client, "%s", szStrafeStats);
		g_bLJ[client]=true;
		if(g_fGreyLJ <= g_js_fJump_Distance[client] < g_fGreenLJ) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {grey}LJ{default}: {purple}%s{grey}%.2f units {default}[{grey}%i{default} Strafes | {grey}%.0f{default} Pre | {grey}%.0f{default} Max | {grey}%.0f{default} Height | {grey}%i%s{default} Sync]%s",sBuggedDist,g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT,sBlockDist);
			GreyStat(client);
		}
		else if(g_fGreenLJ <= g_js_fJump_Distance[client] < g_fBlueLJ) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {green}LJ{default}: {purple}%s{green}%.2f units {default}[{green}%i{default} Strafes | {green}%.0f{default} Pre | {green}%.0f{default} Max | {green}%.0f{default} Height | {green}%i%s{default} Sync]%s",sBuggedDist,g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT,sBlockDist);
			GreenStat(client);
		//all chat
			for (new i = 1; i <= MaxClients; i++)
				if(IsValidClient(i) && g_iColorChat[i] == 1 && i != client)
					CPrintToChat(i, "[{lightgreen}JS{default}] {green}%s{lightgreen} jumped {green}%.3f units {lightgreen}with a {green}LJ%s%s",szName,g_js_fJump_Distance[client],sBuggedDist,sBlockDist);
		}
		else if(g_fBlueLJ <= g_js_fJump_Distance[client] < g_fRedLJ) {
			CPrintToChat(client, "[{lightgreen}JS{default}] \x0CLJ{default}: {purple}%s\x0C%.2f units {default}[{blue}%i{default} Strafes | {blue}%.0f{default} Pre | {blue}%.0f{default} Max | {blue}%.0f{default} Height | {blue}%i%s{default} Sync]%s",sBuggedDist,g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT,sBlockDist);
			BlueStat(client);
		//all chat
			for (new i = 1; i <= MaxClients; i++)
				if(IsValidClient(i) && g_iColorChat[i] == 1 && i != client)
					CPrintToChat(i, "[{lightgreen}JS{default}] \x0C%s{blue} jumped \x0C%.3f units {blue}with a \x0CLJ%s%s",szName,g_js_fJump_Distance[client],sBuggedDist,sBlockDist);
					CPrintToChat(i, "[{lightgreen}JS{default}] %s jumped %.3f units with a LJ [%i Strafes] [%i%s Sync]",szName,sBuggedDist,g_js_fJump_Distance[client],strafes,sync);
		}
		else if(g_fRedLJ <= g_js_fJump_Distance[client] < g_fGoldLJ) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {darkred}LJ{default}: {purple}%s{darkred}%.2f units {default}[{red}%i{default} Strafes | {red}%.0f{default} Pre | {red}%.0f{default} Max | {red}%.0f{default} Height | {red}%i%s{default} Sync]%s",sBuggedDist,g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT,sBlockDist);
			RedStat(client);
		//all chat
			for (new i = 1; i <= MaxClients; i++)
				if(IsValidClient(i) && g_iColorChat[i] == 1 && i != client)
					CPrintToChat(i, "[{lightgreen}JS{default}] {darkred}%s{red} jumped {darkred}%.3f units {red}with a {darkred}LJ%s%s",szName,g_js_fJump_Distance[client],sBuggedDist,sBlockDist);
		}
		else if(g_fGoldLJ <= g_js_fJump_Distance[client] < g_fMaxLJ && !(strafes <= 6)) {
			CPrintToChat(client, "[{lightgreen}JS{default}] \x10LJ{default}: {purple}%s\x10%.2f units {default}[{olive}%i{default} Strafes | {olive}%.0f{default} Pre | {olive}%.0f{default} Max | {olive}%.0f{default} Height | {olive}%i%s{default} Sync]%s",sBuggedDist,g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT,sBlockDist);
			GoldStat(client);
		//all chat
			for (new i = 1; i <= MaxClients; i++)
				if(IsValidClient(i) && g_iColorChat[i] == 1 && i != client)
						CPrintToChat(i, "[{lightgreen}JS{default}] \x10%s{olive} jumped \x10%.3f units {olive}with a \x10LJ%s%s",szName,g_js_fJump_Distance[client],sBuggedDist,sBlockDist);
		}
		else if(g_fGoldLJ <= g_js_fJump_Distance[client] < g_fMaxLJ && strafes <= 6) {
			g_bCheatedJump[client] = true;
			CPrintToChat(client, "[{lightgreen}JS{default}] \x10LJ{default}: {purple}%s\x10%.2f units {default}[{olive}%i{default} Strafes | {olive}%.0f{default} Pre | {olive}%.0f{default} Max | {olive}%.0f{default} Height | {olive}%i%s{default} Sync]%s",sBuggedDist,g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT,sBlockDist);
			LogToFileEx(g_js_LogPath, "%s [JS] %s jumped %0.4f units with a LongJump [%i Strafes | %.3f Pre | %.0f Max | Height %.1f | %i%c Sync]%s",szSteamID,szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT,sBlockDistCon);
		}
		else if(g_fMaxLJ <= g_js_fJump_Distance[client]) {
			LogToFileEx(g_js_LogPath, "%s [JS] %s jumped %0.4f units with a LongJump [%i Strafes | %.3f Pre | %.0f Max | Height %.1f | %i%c Sync]%s",szSteamID,szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT,sBlockDistCon);
			g_bCheatedJump[client] = true;
		}
		if(g_js_fPersonal_Lj_Record[client] < g_js_fJump_Distance[client] && g_bBuggedStat[client] == false && g_bCheatedJump[client] == false) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {olive}You beat your personal best LongJump with a %.3f", g_js_fJump_Distance[client]);
			g_js_fPersonal_Lj_Record[client] = g_js_fJump_Distance[client];
			db_updateLjRecord(client);
			CreateTimer(0.2, Top3CheckDelay, client);
			g_js_fMoneyDist[client] = g_js_fPersonal_Lj_Record[client]*100;
			g_iMoneyPB[client] = RoundToNearest(g_js_fMoneyDist[client]);
			SetClientMoney(client, g_iMoneyPB[client]);
			char sCookie[128];
			IntToString(g_iMoneyPB[client], sCookie, sizeof(sCookie));
			SetClientCookie(client, g_hMoneyCookie, sCookie);
		}
		if(g_js_fJump_Distance[client] > g_js_fBuggedPersonal_Lj_Record[client] && g_bBuggedStat[client] && g_bCheatedJump[client] == false) {
			g_js_fBuggedPersonal_Lj_Record[client] = g_js_fJump_Distance[client];
			CPrintToChat(client, "[{lightgreen}JS{default}] {olive}You beat your personal best Bugged LongJump with a %.3f", g_js_fJump_Distance[client]);
			db_BupdateLjRecord(client);
			CreateTimer(0.2, Top3CheckDelay, client);
		}
		if(ljblock && g_js_Personal_LjBlock_Record[client] <= g_BlockDist[client] && g_bCheatedJump[client] == false) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {olive}You beat your personal best Block LongJump with a %.3f", g_js_fJump_Distance[client]);
			g_js_Personal_LjBlock_Record[client] = g_BlockDist[client];
			g_js_fPersonal_LjBlockRecord_Dist[client] = g_js_fJump_Distance[client];
			db_updateLjBlockRecord(client);
			CreateTimer(0.2, Top3CheckDelay, client);
		}
	}
//CheckIsWJ
	else if(g_js_bBhop[client] && ValidJump && ground_frames < 11 && !g_bLastButtonJump[client] && fGroundDiff == 0.0 && fJump_Height <= 68.0 && g_js_bDropJump[client] && g_js_fDropped_Units[client] <= 132.0 && !touchwall) {
		Format(StatType[0], 128, "WJ");
		PrintToConsole(client, "		");
		PrintToConsole(client, "[JS] %s jumped %0.4f units with a Weird Jump [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
		PrintToConsole(client, "%s", szStrafeStats);
		g_bWJ[client]=true;
		if(g_fGreyWJ <= g_js_fJump_Distance[client] < g_fGreenWJ) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {grey}WJ{default}: {grey}%.2f units {default}[{grey}%i{default} Strafes | {grey}%.0f{default} Pre | {grey}%.0f{default} Max | {grey}%.0f{default} Height | {grey}%i%s{default} Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			GreyStat(client);
		}
		else if(g_fGreenWJ <= g_js_fJump_Distance[client] < g_fBlueWJ) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {green}WJ{default}: {green}%.2f units {default}[{green}%i{default} Strafes | {green}%.0f{default} Pre | {green}%.0f{default} Max | {green}%.0f{default} Height | {green}%i%s{default} Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			GreenStat(client);
		}
		else if(g_fBlueWJ <= g_js_fJump_Distance[client] < g_fRedWJ) {
			CPrintToChat(client, "[{lightgreen}JS{default}] \x0CWJ{default}: \x0C%.2f units {default}[{blue}%i{default} Strafes | {blue}%.0f{default} Pre | {blue}%.0f{default} Max | {blue}%.0f{default} Height | {blue}%i%s{default} Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			BlueStat(client);
		}
		else if(g_fRedWJ <= g_js_fJump_Distance[client] < g_fGoldWJ) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {darkred}WJ{default}: {darkred}%.2f units {default}[{red}%i{default} Strafes | {red}%.0f{default} Pre | {red}%.0f{default} Max | {red}%.0f{default} Height | {red}%i%s{default} Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			RedStat(client);
		}
		else if(g_fGoldWJ <= g_js_fJump_Distance[client] < g_fMaxWJ && !(strafes <= 6)) {
			CPrintToChat(client, "[{lightgreen}JS{default}] \x10WJ{default}: \x10%.2f units {default}[{olive}%i{default} Strafes | {olive}%.0f{default} Pre | {olive}%.0f{default} Max | {olive}%.0f{default} Height | {olive}%i%s{default} Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			GoldStat(client);
		}
		else if(g_fGoldWJ <= g_js_fJump_Distance[client] < g_fMaxWJ && strafes <= 6) {
			g_bCheatedJump[client] = true;
			CPrintToChat(client, "[{lightgreen}JS{default}] \x10WJ{default}: \x10%.2f units {default}[{olive}%i{default} Strafes | {olive}%.0f{default} Pre | {olive}%.0f{default} Max | {olive}%.0f{default} Height | {olive}%i%s{default} Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			LogToFileEx(g_js_LogPath, "%s [JS] %s jumped %0.4f units with a WeirdJump [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szSteamID,szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
		}
		if(g_fMaxWJ <= g_js_fJump_Distance[client]) {
			LogToFileEx(g_js_LogPath, "%s [JS] %s jumped %0.4f units with a WeirdJump [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szSteamID,szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			g_bCheatedJump[client] = true;
		}
	}
//CheckIsBhop
	else if(g_js_bBhop[client] && ValidJump && ground_frames < 11 && g_js_Last_Ground_Frames[client] > 10 && fGroundDiff == 0.0 && fJump_Height <= 68.0 && !g_js_bDropJump[client] && g_js_fPreStrafe[client] > 250.1 && !touchwall) {
		Format(StatType[0], 128, "BHOP");
		PrintToConsole(client, "		");
		PrintToConsole(client, "[JS] %s jumped %0.4f units with a Bunny Hop [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
		PrintToConsole(client, "%s", szStrafeStats);
		g_bBhop[client]=true;
		if(g_fGreyBHOP <= g_js_fJump_Distance[client] < g_fGreenBHOP) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {grey}BHOP{default}: {grey}%.2f units {default}[{grey}%i{default} Strafes | {grey}%.0f{default} Pre | {grey}%.0f{default} Max | {grey}%.0f{default} Height | {grey}%i%s{default} Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			GreyStat(client);
		}
		else if(g_fGreenBHOP <= g_js_fJump_Distance[client] < g_fBlueBHOP) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {green}BHOP{default}: {green}%.2f units {default}[{green}%i{default} Strafes | {green}%.0f{default} Pre | {green}%.0f{default} Max | {green}%.0f{default} Height | {green}%i%s{default} Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			GreenStat(client);
		}
		else if(g_fBlueBHOP <= g_js_fJump_Distance[client] < g_fRedBHOP) {
			CPrintToChat(client, "[{lightgreen}JS{default}] \x0CBHOP{default}: \x0C%.2f units {default}[{blue}%i{default} Strafes | {blue}%.0f{default} Pre | {blue}%.0f{default} Max | {blue}%.0f{default} Height | {blue}%i%s{default} Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			BlueStat(client);
		}
		else if(g_fRedBHOP <= g_js_fJump_Distance[client] < g_fGoldBHOP) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {darkred}BHOP{default}: {darkred}%.2f units {default}[{red}%i{default} Strafes | {red}%.0f{default} Pre | {red}%.0f{default} Max | {red}%.0f{default} Height | {red}%i%s{default} Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			RedStat(client);
		}
		else if(g_fGoldBHOP <= g_js_fJump_Distance[client] < g_fMaxBHOP && !(strafes <= 6)) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {olive}BHOP{default}: {olive}%.2f units{grey} [\x10 %i {default}Strafes | \x10%.0f {default}Pre | \x10%.0f {default}Max | \x10%.0f {default}Height | \x10%i%s {default}Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			GoldStat(client);
		}
		else if(g_fGoldBHOP <= g_js_fJump_Distance[client] < g_fMaxBHOP && strafes <= 6) {
			g_bCheatedJump[client] = true;
			CPrintToChat(client, "[{lightgreen}JS{default}] {olive}BHOP{default}: {olive}%.2f units{grey} [\x10%i {default}Strafes | \x10%.0f {default}Pre | \x10%.0f {default}Max | \x10%.0f {default}Height | \x10%i%s {default}Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			LogToFileEx(g_js_LogPath, "%s [JS] %s jumped %0.4f units with a BHOP [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szSteamID,szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
		}
		if(g_fMaxBHOP <= g_js_fJump_Distance[client]) {
			g_bCheatedJump[client] = true;
			LogToFileEx(g_js_LogPath, "%s [JS] %s jumped %0.4f units with a BHOP [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szSteamID,szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
		}
	}
//CheckIsMBhop
	else if(g_js_bBhop[client] && ValidJump && g_js_Last_Ground_Frames[client] < 11 && ground_frames < 11 && fGroundDiff == 0.0 && fJump_Height <= 68.0 && !g_js_bDropJump[client] && !touchwall) {
		Format(StatType[0], 128, "MBHOP");
		g_js_MultiBhop_Count[client]++;
		char szBhopCount[255];
		Format(szBhopCount, sizeof(szBhopCount), "%i", g_js_MultiBhop_Count[client]);
		if(g_js_MultiBhop_Count[client] > 8)
		Format(szBhopCount, sizeof(szBhopCount), "> 8");
		PrintToConsole(client, "		");
		PrintToConsole(client, "[JS] %s jumped %0.4f units with a MultiBhop [%i Strafes | %3.f Pre | %3.f Max | Height %.1f | %s Bhops | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], fJump_Height,szBhopCount,sync,PERCENT);
		PrintToConsole(client, "%s", szStrafeStats);
		g_bMBhop[client]=true;
		if(g_fGreyMBHOP <= g_js_fJump_Distance[client] < g_fGreenMBHOP) {
			PrintToChat(client, "%t", "ClientMultiBhop1",MOSSGREEN,WHITE, GRAY, g_js_fJump_Distance[client],GRAY, strafes, GRAY, GRAY, g_js_fPreStrafe[client], GRAY, GRAY, sync,PERCENT,GRAY);
			GreyStat(client);
		}
		else if(g_fGreenMBHOP <= g_js_fJump_Distance[client] < g_fBlueMBHOP) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {green}MBhop{default}: {green}%.2f units{grey}[{lime}%i {default}Strafes | {lime}%.0f {default}Pre | {lime}%.0f {default}Max | {lime}%.0f {default}Height | {lime}%s {default}Bhops | {lime}%i%s {default}Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,szBhopCount,sync,PERCENT);
			GreenStat(client);
		}
		else if(g_fBlueMBHOP <= g_js_fJump_Distance[client] < g_fRedMBHOP) {
			PrintToChat(client, "%t", "ClientMultiBhop2",MOSSGREEN,WHITE,DARKBLUE,GRAY,DARKBLUE,g_js_fJump_Distance[client],GRAY,BLUE,strafes,GRAY,BLUE,g_js_fPreStrafe[client],GRAY,BLUE,g_js_fMax_Speed_Final[client],GRAY,BLUE, fJump_Height,GRAY, BLUE,szBhopCount,GRAY,BLUE, sync,PERCENT,GRAY);
			BlueStat(client);
		}
		else if(g_fRedMBHOP <= g_js_fJump_Distance[client] < g_fGoldMBHOP) {
			PrintToChat(client, "%t", "ClientMultiBhop2",MOSSGREEN,WHITE,DARKRED,GRAY,DARKRED,g_js_fJump_Distance[client],GRAY,RED,strafes,GRAY,RED,g_js_fPreStrafe[client],GRAY,RED,g_js_fMax_Speed_Final[client],GRAY,RED, fJump_Height,GRAY, RED,szBhopCount,GRAY,RED, sync,PERCENT,GRAY);
			RedStat(client);
		}
		else if(g_fGoldMBHOP <= g_js_fJump_Distance[client] < g_fMaxMBHOP && !(strafes <= 6)) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {olive}MBhop{default}: {olive}%.2f units{grey} [\x10%i {default}Strafes | \x10%.0f {default}Pre | \x10%.0f {default}Max | \x10%.0f {default}Height | \x10%s {default}Bhops | \x10%i%s {default}Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,szBhopCount,sync,PERCENT);
			GoldStat(client);
		}
		else if(g_fGoldMBHOP <= g_js_fJump_Distance[client] < g_fMaxMBHOP && strafes <= 6) {
			g_bCheatedJump[client] = true;
			CPrintToChat(client, "[{lightgreen}JS{default}] {olive}MBhop{default}: {olive}%.2f units{grey} [\x10%i {default}Strafes | \x10%.0f {default}Pre | \x10%.0f {default}Max | \x10%.0f {default}Height | \x10%s {default}Bhops | \x10%i%s {default}Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,szBhopCount,sync,PERCENT);
			LogToFileEx(g_js_LogPath, "%s [JS] %s jumped %0.4f units with a MultiBhop [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szSteamID,szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
		}
		if(g_fMaxMBHOP <= g_js_fJump_Distance[client]) {
			LogToFileEx(g_js_LogPath, "%s [JS] %s jumped %0.4f units with a MultiBhop [%i Strafes | %3.f Pre | %3.f Max | Height %.1f | %s Bhops | %i%c Sync]",szSteamID,szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], fJump_Height,szBhopCount,sync,PERCENT);
			g_bCheatedJump[client] = true;
		}
	}
//CheckIsDBhop
	else if(g_js_bBhop[client] && ValidJump && ground_frames < 11 && g_js_Last_Ground_Frames[client] > 11 && g_bLastButtonJump[client] && fGroundDiff == 0.0 && fJump_Height <= 68.0 && g_js_bDropJump[client] && g_js_fDropped_Units[client] <= 132.0 && !touchwall) {
		Format(StatType[0], 128, "DBHOP");
		PrintToConsole(client, "		");
		PrintToConsole(client, "[JS] %s jumped %0.4f units with a DropBhop [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
		PrintToConsole(client, "%s", szStrafeStats);
		g_bDBhop[client]=true;
		if(g_fGreyDBHOP <= g_js_fJump_Distance[client] < g_fGreenDBHOP) {
			PrintToChat(client, "%t", "ClientDropBhop1",MOSSGREEN,WHITE, GRAY,g_js_fJump_Distance[client],GRAY, strafes, GRAY, GRAY, g_js_fPreStrafe[client], GRAY, GRAY,fJump_Height,GRAY, GRAY,sync,PERCENT,GRAY);
			GreyStat(client);
		}
		else if(g_fGreenDBHOP <= g_js_fJump_Distance[client] < g_fBlueDBHOP) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {green}DBhop{default}: {green}%.2f units{grey} [{lime} %i {default}Strafes | {lime}%.0f {default}Pre | {lime}%.0f {default}Max | {lime}%.0f {default}Height | {lime}%i%s {default}Sync]",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			GreenStat(client);
		}
		else if(g_fBlueDBHOP <= g_js_fJump_Distance[client] < g_fRedDBHOP) {
			PrintToChat(client, "%t", "ClientDropBhop2",MOSSGREEN,WHITE,DARKBLUE,GRAY,DARKBLUE,g_js_fJump_Distance[client],GRAY,BLUE,strafes,GRAY,BLUE,g_js_fPreStrafe[client],GRAY,BLUE, g_js_fMax_Speed_Final[client],GRAY,BLUE, fJump_Height,GRAY, BLUE,sync,PERCENT,GRAY);
			BlueStat(client);
		}
		else if(g_fRedDBHOP <= g_js_fJump_Distance[client] < g_fGoldDBHOP) {
			PrintToChat(client, "%t", "ClientDropBhop2",MOSSGREEN,WHITE,DARKRED,GRAY,DARKRED,g_js_fJump_Distance[client],GRAY,RED,strafes,GRAY,RED,g_js_fPreStrafe[client],GRAY,RED, g_js_fMax_Speed_Final[client],GRAY,RED,fJump_Height,GRAY, RED, sync,PERCENT,GRAY);
			RedStat(client);
		}
		else if(g_fGoldDBHOP <= g_js_fJump_Distance[client] < g_fMaxDBHOP && !(strafes <=6)) {
			CPrintToChat(client, "[{lightgreen}JS{default}] {olive}DBhop{default}: {olive}%.2f units{grey} [\x10 %i {default}Strafes | \x10%.0f {default}Pre | \x10%.0f {default}Max | \x10%.0f {default}Height | \x10%i%s {default}Sync",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			GoldStat(client);
		}
		else if(g_fGoldDBHOP <= g_js_fJump_Distance[client] < g_fMaxDBHOP && strafes <= 6) {
			g_bCheatedJump[client] = true;
			CPrintToChat(client, "[{lightgreen}JS{default}] {olive}DBhop{default}: {olive}%.2f units{grey} [\x10 %i {default}Strafes | \x10%.0f {default}Pre | \x10%.0f {default}Max | \x10%.0f {default}Height | \x10%i%s {default}Sync",g_js_fJump_Distance[client],strafes,g_js_fPreStrafe[client],g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			LogToFileEx(g_js_LogPath, "%s [JS] %s jumped %0.4f units with a DropBhop [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szSteamID,szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
		}
		if(g_fMaxDBHOP <= g_js_fJump_Distance[client]) {
			LogToFileEx(g_js_LogPath, "%s [JS] %s jumped %0.4f units with a DropBhop [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szSteamID,szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
			g_bCheatedJump[client] = true;
		}
	}
	//reset multibhop count
	if(!g_js_bBhop[client] || g_js_Last_Ground_Frames[client] >=11 || fGroundDiff > 0.0 || touchwall)
		g_js_MultiBhop_Count[client] = 1;
	//strafe sync chat
	if(g_iStrafeSync[client] == 1 && g_js_fJump_Distance[client] >= 240)
		PrintToChat(client,"%s", szStrafeSync);
	if(ValidJump) {
	//wjrecord
		if(g_bWJ[client] == true && g_js_fPersonal_Wj_Record[client] < g_js_fJump_Distance[client] && !IsFakeClient(client) && !g_bCheatedJump[client]) {
			if(g_js_fPersonal_Wj_Record[client] > 0.0)
				PrintToChat(client, "%t", "Jumpstats_BeatWjBest",MOSSGREEN,WHITE,YELLOW, g_js_fJump_Distance[client]);
			g_js_fPersonal_Wj_Record[client] = g_js_fJump_Distance[client];
			db_updateWjRecord(client);
			CreateTimer(0.2, Top3CheckDelay, client);
		}
	//bhoprecord
		else if(g_bBhop[client] == true && g_js_fPersonal_Bhop_Record[client] < g_js_fJump_Distance[client] && !IsFakeClient(client) && !g_bCheatedJump[client]) {
			if(g_js_fPersonal_Bhop_Record[client] > 0.0)
				PrintToChat(client, "%t", "Jumpstats_BeatBhopBest",MOSSGREEN,WHITE,YELLOW, g_js_fJump_Distance[client]);
			g_js_fPersonal_Bhop_Record[client] = g_js_fJump_Distance[client];
			db_updateBhopRecord(client);
			CreateTimer(0.2, Top3CheckDelay, client);
		}
	//mbhoprecord
		else if(g_bMBhop[client] == true && g_js_fPersonal_MultiBhop_Record[client] < g_js_fJump_Distance[client] && !IsFakeClient(client) && !g_bCheatedJump[client]) {
			if(g_js_fPersonal_MultiBhop_Record[client] > 0.0)
				PrintToChat(client, "%t", "Jumpstats_BeatMultiBhopBest",MOSSGREEN,WHITE,YELLOW, g_js_fJump_Distance[client]);
			g_js_fPersonal_MultiBhop_Record[client] = g_js_fJump_Distance[client];
			db_updateMultiBhopRecord(client);
			CreateTimer(0.2, Top3CheckDelay, client);
		}
	//dbhoprecord
		else if(g_bDBhop[client] == true && g_js_fPersonal_DropBhop_Record[client] < g_js_fJump_Distance[client] && !IsFakeClient(client) && ValidJump && !g_bCheatedJump[client]) {
			if(g_js_fPersonal_DropBhop_Record[client] > 0.0)
				PrintToChat(client, "%t", "Jumpstats_BeatDropBhopBest",MOSSGREEN,WHITE,YELLOW, g_js_fJump_Distance[client]);
			g_js_fPersonal_DropBhop_Record[client] = g_js_fJump_Distance[client];
			db_updateDropBhopRecord(client);
			CreateTimer(0.2, Top3CheckDelay, client);
		}
	}
	PostThinkPost(client, ground_frames);
}
stock SetClientMoney(int client, int value) {
	int offset = FindSendPropInfo("CCSPlayer", "m_iAccount");
	SetEntData(client, offset, value);
}
/*
* timer seems redundant because it is
* calling Top3Check when the stat gets
* reged on top menu could be more efficient
* as you could call directly to say
* Top3LJ or Top3Bhop
* but i feel that would take more space
* and be less readable
*/
public Action Top3CheckDelay(Handle timer, int client) {
	Top3Check(client);
}
public Top3Check(int client) {
	if(!IsValidClient(client))
		return;
	if(g_bLJ[client] && g_bBuggedStat[client] == false) {
		if(g_js_LjRank[client] == 1)
			NumberOnePost(client);
		else if(g_js_LjRank[client] == 2)
			NumberTwoPost(client);
		else if(g_js_LjRank[client] == 3)
			NumberThreePost(client);
	}
	else if(g_bLJBlock[client] && g_bLJ[client]) {
		if(g_js_LjBlockRank[client] == 1)
			NumberOnePost(client);
		else if(g_js_LjBlockRank[client] == 2)
			NumberTwoPost(client);
		else if(g_js_LjBlockRank[client] == 3)
			NumberThreePost(client);
	}
	else if(g_bWJ[client]) {
		if(g_js_WjRank[client] == 1)
			NumberOnePost(client);
		else if(g_js_WjRank[client] == 2)
			NumberTwoPost(client);
		else if(g_js_WjRank[client] == 3)
			NumberThreePost(client);
	}
	else if(g_bBhop[client]) {
		if(g_js_BhopRank[client] == 1)
			NumberOnePost(client);
		else if(g_js_BhopRank[client] == 2)
			NumberTwoPost(client);
		else if(g_js_BhopRank[client] == 3)
			NumberThreePost(client);
	}
	else if(g_bMBhop[client]) {
		if(g_js_MultiBhopRank[client] == 1)
			NumberOnePost(client);
		else if(g_js_MultiBhopRank[client] == 2)
			NumberTwoPost(client);
		else if(g_js_MultiBhopRank[client] == 3)
			NumberThreePost(client);
	}
	else if(g_bDBhop[client]) {
		if(g_js_DropBhopRank[client] == 1)
			NumberOnePost(client);
		else if(g_js_DropBhopRank[client] == 2)
			NumberTwoPost(client);
		else if(g_js_DropBhopRank[client] == 3)
			NumberThreePost(client);
	}
	else if(g_bLJ[client] && g_bBuggedStat[client]) {
		if(g_js_BLjRank[client] == 1)
			NumberOnePost(client);
		else if(g_js_BLjRank[client] == 2)
			NumberTwoPost(client);
		else if(g_js_BLjRank[client] == 3)
			NumberThreePost(client);
	}
}
public NumberOnePost(int client) {
	char buffer[255];
	Format(buffer, sizeof(buffer), "play %s", NUMBER_ONE_RELATIVE_SOUND_PATH);
	for(new i = 1; i <= MaxClients; i++)
		ClientCommand(i, buffer);
}
public NumberTwoPost(int client) {
	char buffer[255];
	Format(buffer, sizeof(buffer), "play %s", NUMBER_TWO_RELATIVE_SOUND_PATH);
	for(new i = 1; i <= MaxClients; i++)
		ClientCommand(i, buffer);
}
public NumberThreePost(int client) {
	char buffer[255];
	Format(buffer, sizeof(buffer), "play %s", NUMBER_THREE_RELATIVE_SOUND_PATH);
	for(new i = 1; i <= MaxClients; i++)
		ClientCommand(i, buffer);
}
public GreyStat(int client) {
	g_js_GoldJump_Count[client] = 0;
	g_js_LeetJump_Count[client] = 0;
	Format(g_js_szLastJumpDistance[client], 256, "%.2f units", g_js_fJump_Distance[client]);
}
public GreenStat(int client) {
	char szName[128];
	GetClientName(client, szName, 128);
	g_js_GoldJump_Count[client] = 0;
	g_js_LeetJump_Count[client] = 0;
	Format(g_js_szLastJumpDistance[client], 256, "%.2f units", g_js_fJump_Distance[client]);
	//sound
	char buffer[255]
	Format(buffer, sizeof(buffer), "play %s", PROJUMP_RELATIVE_SOUND_PATH);
	if(g_iEnableQuakeSounds[client] == 1)
		ClientCommand(client, buffer);
	if(g_bLJ[client])
		return;
//all chat
	for (new i = 1; i <= MaxClients; i++)
		if(IsValidClient(i) && g_iColorChat[i] == 1 && i != client)
			CPrintToChat(i, "[{lightgreen}JS{default}] {green}%s{lightgreen} jumped {green}%.3f units {lightgreen}with a {green}%s",szName,g_js_fJump_Distance[client],StatType[0]);
}
public BlueStat(int client) {
	char szName[128];
	GetClientName(client, szName, 128);
	g_js_GoldJump_Count[client] = 0;
	g_js_LeetJump_Count[client] = 0;
	Format(g_js_szLastJumpDistance[client], 256, "%.2f units", g_js_fJump_Distance[client]);
	//sound
	char buffer[255]
	Format(buffer, sizeof(buffer), "play %s", PERFECTJUMP_RELATIVE_SOUND_PATH);
	if(g_iEnableQuakeSounds[client] == 1)
		ClientCommand(client, buffer);
	if(g_bLJ[client])
		return;
//all chat
	for (new i = 1; i <= MaxClients; i++)
		if(IsValidClient(i) && g_iColorChat[i] == 1 && i != client)
			CPrintToChat(i, "[{lightgreen}JS{default}] \x0C%s{blue} jumped \x0C%.3f units {blue}with a \x0C%s",szName,g_js_fJump_Distance[client],StatType[0]);
}
public RedStat(int client) {
	char szName[128];
	GetClientName(client, szName, 128);
	g_js_GoldJump_Count[client] = 0;
	Format(g_js_szLastJumpDistance[client], 256, "%.2f units", g_js_fJump_Distance[client]);
	g_js_LeetJump_Count[client]++;
	if(g_js_LeetJump_Count[client] > 5)
		g_js_LeetJump_Count[client] = 0;
//sound
	char buffer[255];
	if(g_js_LeetJump_Count[client]==3) {
		CPrintToChatAll("[{pink}JS{default}]{grey} %s is on a rampage with 3 leet jumps in a row!",szName);
		Format(buffer, sizeof(buffer), "play %s", LEETJUMP_3_RELATIVE_SOUND_PATH);
		if(g_iEnableQuakeSounds[client] == 1)
			ClientCommand(client, buffer);
	}
	else if(g_js_LeetJump_Count[client]==5) {
		CPrintToChat(client, "[{pink}JS{default}]{grey} %s is dominating with 5 leet jumps in a row!",szName);
		Format(buffer, sizeof(buffer), "play %s", LEETJUMP_5_RELATIVE_SOUND_PATH);
		if(g_iEnableQuakeSounds[client] == 1)
			ClientCommand(client, buffer);
	}
	else if(g_js_LeetJump_Count[client] != 5 && g_js_LeetJump_Count[client] != 3) {
		Format(buffer, sizeof(buffer), "play %s", LEETJUMP_RELATIVE_SOUND_PATH);
		if(g_iEnableQuakeSounds[client] == 1)
			ClientCommand(client, buffer);
	}
	if(g_bLJ[client])
		return;
//all chat
	for (new i = 1; i <= MaxClients; i++)
		if(IsValidClient(i) && g_iColorChat[i] == 1 && i != client)
			CPrintToChat(i, "[{lightgreen}JS{default}] {darkred}%s{red} jumped {darkred}%.3f units {red}with a {darkred}%s",szName,g_js_fJump_Distance[client],StatType[0]);
}
public GoldStat(int client) {
	char szName[128];
	GetClientName(client, szName, 128);
	Format(g_js_szLastJumpDistance[client], 256, "%.2f units", g_js_fJump_Distance[client]);
	g_js_LeetJump_Count[client]++;
	g_js_GoldJump_Count[client]++;
	if(g_js_LeetJump_Count[client] > 5)
		g_js_LeetJump_Count[client] = 0;
	if(g_js_GoldJump_Count[client] > 5)
		g_js_GoldJump_Count[client] = 0;
//sound
	char buffer[255];
	if(g_js_GoldJump_Count[client]==3) {
		CPrintToChatAll("[{pink}JS{default}]{grey} HOLY SHIT, %s hit 3 ownages in a row!",szName);
		Format(buffer, sizeof(buffer), "play %s", OWNAGEJUMP_3_RELATIVE_SOUND_PATH);
		if(g_iEnableQuakeSounds[client] == 1)
			ClientCommand(client, buffer);
	}
	else if(g_js_GoldJump_Count[client]==5) {
		CPrintToChatAll("[{pink}JS{default}]{grey} %s is a combowhore with 5 ownages in a row!!",szName);
		Format(buffer, sizeof(buffer), "play %s", OWNAGEJUMP_5_RELATIVE_SOUND_PATH);
		if(g_iEnableQuakeSounds[client] == 1)
			ClientCommand(client, buffer);
	}
	else if(g_js_GoldJump_Count[client] != 5 && g_js_GoldJump_Count[client] != 3) {
		Format(buffer, sizeof(buffer), "play %s", OWNAGEJUMP_RELATIVE_SOUND_PATH);
		if(g_iEnableQuakeSounds[client] == 1)
			ClientCommand(client, buffer);
	}
	if(g_bLJ[client])
		return;
//all chat
	for (new i = 1; i <= MaxClients; i++)
		if(IsValidClient(i) && g_iColorChat[i] == 1 && i != client)
			CPrintToChat(i, "[{lightgreen}JS{default}] \x10%s{olive} jumped \x10%.3f units {olive}with a \x10%s",szName,g_js_fJump_Distance[client],StatType[0]);
}
public PostThinkPost(client, ground_frames) {
	g_js_bPlayerJumped[client] = false;
	g_js_Last_Ground_Frames[client] = ground_frames;
}
public Action Client_Ljblock(client, args) {
	if(IsValidClient(client) && IsPlayerAlive(client))
		LJBlockMenu(client);
	return Plugin_Handled;
}
public LJBlockMenu(client) {
	Handle menu = CreateMenu(LjBlockMenuHandler);
	SetMenuTitle(menu, "LJ Block Jump Menu");
	AddMenuItem(menu, "0", "Select Destination");
	AddMenuItem(menu, "0", "Reset Destination");
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public LjBlockMenuHandler(Handle menu, MenuAction action, client, select) {
	if(action == MenuAction_Select) {
		if(select == 0)
			Function_BlockJump(client);
		else if(select == 1)
			g_bLJBlock[client] = false;
		LJBlockMenu(client);
	}
	if(action == MenuAction_End)
		delete menu;
}
public Action Client_InfoPanel(client, args) {
	g_iInfoPanel[client] = g_iInfoPanel[client] == 1 ? 0 : 1;
	if(g_iInfoPanel[client] == 1)
		PrintToChat(client, "%t", "Info1", MOSSGREEN,WHITE);
	else
		PrintToChat(client, "%t", "Info2", MOSSGREEN,WHITE);
	char sCookie[128];
	IntToString(g_iInfoPanel[client], sCookie, sizeof(sCookie));
	SetClientCookie(client, g_hInfoPanel, sCookie);
	return Plugin_Handled;
}
public Action Client_JS(client, args) {
	JsSettingsMenu(client);
}
public JsSettingsMenu(client) {
	Handle menu = CreateMenu(JsSettingsMenuHandler);
	SetMenuTitle(menu, "Jump Stats Settings");
	AddMenuItem(menu, "0", "Speed Panel Settings");
	AddMenuItem(menu, "1", "JS Settings");
	if(CommandExists("sm_beam"))
		AddMenuItem(menu, "2", "Beam Settings");

	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public JsSettingsMenuHandler(Handle menu, MenuAction action, client, select) {
	if(action == MenuAction_Select) {
		if(select == 0)
			SpeedPanelSettings(client);
		else if(select == 1)
			ToggleSettings(client);
		else if(select == 2)
			ClientCommand(client, "sm_beam");
	}
	if(action == MenuAction_End)
		delete menu;
}
public ToggleSettings(client) {
	Handle menu = CreateMenu(ToggleSettingsHandler);
	SetMenuTitle(menu, "JS Settings");
	if(g_iInfoPanel[client] == 1)
		AddMenuItem(menu, "0", "Speed Panel   [ENABLED]");
	else
		AddMenuItem(menu, "0", "Speed Panel   [DISABLED]");
	if(g_iStrafeSync[client] == 1)
		AddMenuItem(menu, "1", "Sync Chat     [ENABLED]");
	else
		AddMenuItem(menu, "1", "Sync Chat     [DISABLED]");
	if(g_iEnableQuakeSounds[client] == 1)
		AddMenuItem(menu, "2", "Quake Sounds  [ENABLED]");
	else
		AddMenuItem(menu, "2", "Quake Sounds  [DISABLED]");
	if(g_iColorChat[client] == 1)
		AddMenuItem(menu, "3", "Color Chat    [ENABLED]");
	else
		AddMenuItem(menu, "3", "Color Chat    [DISABLED]");
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public ToggleSettingsHandler(Handle menu, MenuAction action, client, select) {
	if(action == MenuAction_Select) {
		if(select == 0)
			FakeClientCommand(client, "sm_speed");
		else if(select == 1)
			FakeClientCommand(client, "sm_sync");
		else if(select == 2)
			FakeClientCommand(client, "sm_sound");
		else if(select == 3)
			FakeClientCommand(client, "sm_colorchat");
		ToggleSettings(client);
	}
	else if(action == MenuAction_Cancel)
		JsSettingsMenu(client);
	if(action == MenuAction_End)
		delete menu;
}
public SpeedPanelSettings(client) {
	Handle menu = CreateMenu(SpeedPanelSettingsHandler);
	SetMenuTitle(menu, "Speed Panel Settings");
	AddMenuItem(menu, "0", "Toggle Speed Panel");
	AddMenuItem(menu, "1", "Key Colors");
	AddMenuItem(menu, "2", "Perf Colors");
	AddMenuItem(menu, "3", "Speed Colors");

	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public SpeedPanelSettingsHandler(Handle menu, MenuAction action, client, select) {
	if(action == MenuAction_Select) {
		if(select == 0) {
		/*
 		* this is like this instead of calling the option
		* because if the option is called it casues a mem leak
		* and crashes the server
		* leave as is unless you know how to fix
		*/
			g_iInfoPanel[client] = g_iInfoPanel[client] == 1 ? 0 : 1;
			if(g_iInfoPanel[client] == 1)
				PrintToChat(client, "%t", "Info1", MOSSGREEN,WHITE);
			else
				PrintToChat(client, "%t", "Info2", MOSSGREEN,WHITE);
			char sCookie[128];
			IntToString(g_iInfoPanel[client], sCookie, sizeof(sCookie));
			SetClientCookie(client, g_hInfoPanel, sCookie);
			SpeedPanelSettings(client);
		}
		else if(select == 1)
			KeyColorSettings(client);
		else if(select == 2)
			PerfColorSettings(client);
		else if(select == 3)
			SpeedColorSettings(client);
	}
	else if(action == MenuAction_Cancel)
		JsSettingsMenu(client);
	if(action == MenuAction_End)
		delete menu;
}
public KeyColorSettings(client) {
	Handle menu = CreateMenu(KeyColorSettingsHandler);
	SetMenuTitle(menu, "Key Color Settings");
	AddMenuItem(menu, "0", "Blue");
	AddMenuItem(menu, "1", "Red");
	AddMenuItem(menu, "2", "Purple");
	AddMenuItem(menu, "3", "Light Green");
	AddMenuItem(menu, "4", "Gold");
	AddMenuItem(menu, "5", "White");
	AddMenuItem(menu, "6", "Green");
	AddMenuItem(menu, "7", "Light Blue");
	AddMenuItem(menu, "8", "Dark Blue");
	AddMenuItem(menu, "9", "Dark Purple");
	AddMenuItem(menu, "10", "Pink");
	AddMenuItem(menu, "11", "Light Pink");

	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public KeyColorSettingsHandler(Handle menu, MenuAction action, client, select) {
	if(action == MenuAction_Select) {
		g_iKeyColors[client] = select * 8;
		KeyColorSettings(client);
		char sCookie[128];
		IntToString(g_iKeyColors[client], sCookie, sizeof(sCookie));
		SetClientCookie(client, g_hKeyColorCookie, sCookie);
	}
	else if(action == MenuAction_Cancel)
		SpeedPanelSettings(client);
	if(action == MenuAction_End)
		delete menu;
}
public PerfColorSettings(client) {
	Handle menu = CreateMenu(PerfColorSettingsHandler);
	SetMenuTitle(menu, "Perf Color Settings");
	AddMenuItem(menu, "0", "Blue");
	AddMenuItem(menu, "1", "Red");
	AddMenuItem(menu, "2", "Purple");
	AddMenuItem(menu, "3", "Light Green");
	AddMenuItem(menu, "4", "Gold");
	AddMenuItem(menu, "5", "White");
	AddMenuItem(menu, "6", "Green");
	AddMenuItem(menu, "7", "Light Blue");
	AddMenuItem(menu, "8", "Dark Blue");
	AddMenuItem(menu, "9", "Dark Purple");
	AddMenuItem(menu, "10", "Pink");
	AddMenuItem(menu, "11", "Light Pink");

	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public PerfColorSettingsHandler(Handle menu, MenuAction action, client, select) {
	if(action == MenuAction_Select) {
		g_iPerfColor[client] = select * 8;
		PerfColorSettings(client);
		char sCookie[128];
		IntToString(g_iPerfColor[client], sCookie, sizeof(sCookie));
		SetClientCookie(client, g_hPerfColorCookie, sCookie);
	}
	else if(action == MenuAction_Cancel)
		SpeedPanelSettings(client);
	if(action == MenuAction_End)
		delete menu;
}
public SpeedColorSettings(client) {
	Handle menu = CreateMenu(SpeedColorSettingsHandler);
	SetMenuTitle(menu, "Speed Color Settings");
	AddMenuItem(menu, "0", "Blue");
	AddMenuItem(menu, "1", "Red");
	AddMenuItem(menu, "2", "Purple");
	AddMenuItem(menu, "3", "Light Green");
	AddMenuItem(menu, "4", "Gold");
	AddMenuItem(menu, "5", "White");
	AddMenuItem(menu, "6", "Green");
	AddMenuItem(menu, "7", "Light Blue");
	AddMenuItem(menu, "8", "Dark Blue");
	AddMenuItem(menu, "9", "Dark Purple");
	AddMenuItem(menu, "10", "Pink");
	AddMenuItem(menu, "11", "Light Pink");

	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public SpeedColorSettingsHandler(Handle menu, MenuAction action, client, select) {
	if(action == MenuAction_Select) {
		g_iSpeedColor[client] = select * 8;
		SpeedColorSettings(client);
		char sCookie[128];
		IntToString(g_iSpeedColor[client], sCookie, sizeof(sCookie));
		SetClientCookie(client, g_hSpeedColorCookie, sCookie);
	}
	else if(action == MenuAction_Cancel)
		SpeedPanelSettings(client);
	if(action == MenuAction_End)
		delete menu;
}
public Action Client_StrafeSync(client, args) {
	g_iStrafeSync[client] = g_iStrafeSync[client] == 1 ? 0 : 1;
	if(g_iStrafeSync[client] == 1)
		PrintToChat(client, "Strafe Chat has been \x04enabled\x01.");
	else
		PrintToChat(client, "Strafe Chat has been \x0Fdisabled\x01.");
	char sCookie[128];
	IntToString(g_iStrafeSync[client], sCookie, sizeof(sCookie));
	SetClientCookie(client, g_hStrafeSync, sCookie);
	return Plugin_Handled;
}
public Action Client_Stats(client, args) {
	g_bdetailView[client]=false;
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	db_viewJumpStats(client, szSteamId)
	return Plugin_Handled;
}
public Action Client_BStats(client, args) {
	g_bdetailView[client]=false;
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	db_viewBJumpStats(client, szSteamId)
	return Plugin_Handled;
}
public Action Client_QuakeSounds(client, args) {
	g_iEnableQuakeSounds[client] = g_iEnableQuakeSounds[client] == 1 ? 0 : 1;
	if(g_iEnableQuakeSounds[client] == 1)
		PrintToChat(client, "Quake has been \x04enabled\x01.");
	else if(g_iEnableQuakeSounds[client] == 0)
		PrintToChat(client, "Quake has been \x0Fdisabled\x01.");
	char sCookie[128];
	IntToString(g_iEnableQuakeSounds[client], sCookie, sizeof(sCookie));
	SetClientCookie(client, g_hEnableQuakeSounds, sCookie);
	return Plugin_Handled;
}
public Action Client_Colorchat(client, args) {
	g_iColorChat[client] = g_iColorChat[client] == 1 ? 0 : 1;
	if(g_iColorChat[client] == 1)
		PrintToChat(client, "Color Chat has been \x04enabled\x01.");
	else if(g_iColorChat[client] == 0)
		PrintToChat(client, "Color Chat has been \x0Fdisabled\x01.");
	char sCookie[128];
	IntToString(g_iColorChat[client], sCookie, sizeof(sCookie));
	SetClientCookie(client, g_hColorChat, sCookie);
	return Plugin_Handled;
}
public Action Client_Top(client, args) {
	TopMenu(client);
	return Plugin_Handled;
}
public Action Client_RTop(client, args) {
	JumpTopMenu(client);
	return Plugin_Handled;
}
public Action Client_BTop(client, args) {
	db_BselectTopLj(client);
	return Plugin_Handled;
}
public TopMenu(client) {
	Handle topmenuselect = CreateMenu(JumpTopSelectionHandler);
	SetMenuTitle(topmenuselect, "Select Jumptop");
	AddMenuItem(topmenuselect, "nobug", "Nobug Leaderboard");
	AddMenuItem(topmenuselect, "bugged", "Bugged Leaderboard");
	SetMenuOptionFlags(topmenuselect, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(topmenuselect, client, MENU_TIME_FOREVER);
}
public JumpTopMenu(client) {
	Handle topmenu2 = CreateMenu(JumpTopMenuHandler);
	SetMenuTitle(topmenu2, "Top Nobug Leaderboard");
	AddMenuItem(topmenu2, "!lj", "Top 20 Longjump");
	AddMenuItem(topmenu2, "!ljblock", "Top 20 Block Longjump");
	AddMenuItem(topmenu2, "!bhop", "Top 20 Bunnyhop");
	AddMenuItem(topmenu2, "!multibhop", "Top 20 Multi-Bunnyhop");
	AddMenuItem(topmenu2, "!dropbhop", "Top 20 Drop-Bunnyhop");
	AddMenuItem(topmenu2, "!wj", "Top 20 Weirdjump");
	SetMenuOptionFlags(topmenu2, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(topmenu2, client, MENU_TIME_FOREVER);
}
public JumpTopSelectionHandler(Handle menu, MenuAction action, param1, param2) {
	if(action == MenuAction_Select) {
		switch (param2) {
			case 0:JumpTopMenu(param1);
			case 1:db_BselectTopLj(param1);
		}
	}
	if(action == MenuAction_End)
		delete menu;
}
public JumpTopMenuHandler(Handle menu, MenuAction action, param1, param2) {
	if(action == MenuAction_Select) {
		switch (param2) {
			case 0:db_selectTopLj(param1);
			case 1:db_selectTopLjBlock(param1);
			case 2:db_selectTopBhop(param1);
			case 3:db_selectTopMultiBhop(param1);
			case 4:db_selectTopDropBhop(param1);
			case 5:db_selectTopWj(param1);
		}
	}
	else if(action == MenuAction_Cancel)
		TopMenu(param1);
	if(action == MenuAction_End)
		delete menu;
}
//SQL
public db_updateLjRecord(client) {
	char szQuery[255];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 255, sql_selectPlayerJumpLJ, szSteamId);
	if(!IsFakeClient(client))
		SQL_TQuery(g_hDb, SQL_UpdateLjRecordCallback, szQuery, client,DBPrio_Low);
}
public db_BupdateLjRecord(client) {
	char szQuery[255];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 255, sql_BselectPlayerJumpLJ, szSteamId);
	if(!IsFakeClient(client))
		SQL_TQuery(g_hBDb, SQL_BUpdateLjRecordCallback, szQuery, client,DBPrio_Low);
}
public db_updateLjBlockRecord(client) {
	char szQuery[255];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 255, sql_selectPlayerJumpLJBlock, szSteamId);
	if(!IsFakeClient(client))
		SQL_TQuery(g_hDb, SQL_UpdateLjBlockRecordCallback, szQuery, client,DBPrio_Low);
}
public db_updateWjRecord(client) {
	char szQuery[255];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 255, sql_selectPlayerJumpWJ, szSteamId);
	if(!IsFakeClient(client))
		SQL_TQuery(g_hDb, SQL_UpdateWjRecordCallback, szQuery, client,DBPrio_Low);
}
public db_updateBhopRecord(client) {
	char szQuery[255];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 255, sql_selectPlayerJumpBhop, szSteamId);
	if(!IsFakeClient(client))
		SQL_TQuery(g_hDb, SQL_UpdateBhopRecordCallback, szQuery, client,DBPrio_Low);
}
public db_updateDropBhopRecord(client) {
	char szQuery[255];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 255, sql_selectPlayerJumpDropBhop, szSteamId);
	if(!IsFakeClient(client))
		SQL_TQuery(g_hDb, SQL_UpdateDropBhopRecordCallback, szQuery, client,DBPrio_Low);
}
public db_updateMultiBhopRecord(client) {
	char szQuery[255];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 255, sql_selectPlayerJumpMultiBhop, szSteamId);
	if(!IsFakeClient(client))
		SQL_TQuery(g_hDb, SQL_UpdateMultiBhopRecordCallback, szQuery, client,DBPrio_Low);
}
public SQL_UpdateLjRecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(IsValidClient(client)) {
		char szQuery[512];
		char szUName[MAX_NAME_LENGTH];
		GetClientName(client, szUName, MAX_NAME_LENGTH);
		char szSteamId[32];
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
		char szName[MAX_NAME_LENGTH*2+1];
		SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH*2+1);
		if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
			Format(szQuery, 512, sql_updateLj, szName, g_js_fPersonal_Lj_Record[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_Sync_Final[client],g_flastHeight[client], szSteamId);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		} else {
			Format(szQuery, 512, sql_insertPlayerJumpLj, szSteamId, szName, g_js_fPersonal_Lj_Record[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_Sync_Final[client],g_flastHeight[client]);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		}
		db_viewLjRecord2(client);
	}
}
public SQL_BUpdateLjRecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(IsValidClient(client)) {
		char szQuery[512];
		char szUName[MAX_NAME_LENGTH];
		GetClientName(client, szUName, MAX_NAME_LENGTH);
		char szSteamId[32];
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
		char szName[MAX_NAME_LENGTH*2+1];
		SQL_EscapeString(g_hBDb, szUName, szName, MAX_NAME_LENGTH*2+1);
		if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
			Format(szQuery, 512, sql_BupdateLj, szName, g_js_fBuggedPersonal_Lj_Record[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_Sync_Final[client],g_flastHeight[client], szSteamId);
			SQL_TQuery(g_hBDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		} else {
			Format(szQuery, 512, sql_BinsertPlayerJumpLj, szSteamId, szName, g_js_fBuggedPersonal_Lj_Record[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_Sync_Final[client],g_flastHeight[client]);
			SQL_TQuery(g_hBDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		}
		db_viewBLjRecord2(client);
	}
}
public SQL_viewBhop2RecordCallback2(Handle owner, Handle hndl, const char[] error, any:data) {
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szName[MAX_NAME_LENGTH];
		int rank = SQL_GetRowCount(hndl);
		Handle pack = data;
		ResetPack(pack);
		int client = ReadPackCell(pack);
		ReadPackString(pack, szName, MAX_NAME_LENGTH);
		CloseHandle(pack);
		if(rank < 21 && rank < g_js_BhopRank[client]) {
			g_js_BhopRank[client] = rank;
			for(new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i) && !IsFakeClient(i)) {
					PrintToChat(i, "%t", "Jumpstats_BhopTop", MOSSGREEN, WHITE, YELLOW, szName, rank, g_js_fPersonal_Bhop_Record[client]);
					PrintToConsole(i, "[JS] %s is now #%i in the nobug Bunnyhop Top 20! [%.3f units]", szName, rank, g_js_fPersonal_Bhop_Record[client]);
				}
			}
		}
	}
}
public SQL_viewDropBhop2RecordCallback2(Handle owner, Handle hndl, const char[] error, any:data) {
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szName[MAX_NAME_LENGTH];
		int rank = SQL_GetRowCount(hndl);
		Handle pack = data;
		ResetPack(pack);
		int client = ReadPackCell(pack);
		ReadPackString(pack, szName, MAX_NAME_LENGTH);
		CloseHandle(pack);
		if(rank < 21 && rank < g_js_DropBhopRank[client]) {
			g_js_DropBhopRank[client] = rank;
			for(new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i) && !IsFakeClient(i)) {
					PrintToChat(i, "%t", "Jumpstats_DropBhopTop", MOSSGREEN, WHITE, YELLOW, szName, rank, g_js_fPersonal_DropBhop_Record[client]);
					PrintToConsole(i, "[JS] %s is now #%i in the nobug Drop-Bunnyhop Top 20! [%.3f units]", szName, rank, g_js_fPersonal_DropBhop_Record[client]);
				}
			}
		}
	}
}
public db_viewMultiBhopRecord2(client) {
	char szQuery[512];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 512, sql_selectPlayerJumpMultiBhop, szSteamId);
	SQL_TQuery(g_hDb, SQL_viewMultiBhop2RecordCallback, szQuery, client,DBPrio_Low);
}
public SQL_viewMultiBhop2RecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szQuery[512];
		char szName[MAX_NAME_LENGTH];
		char szSteamId[32];
		SQL_FetchString(hndl, 0, szSteamId, MAX_NAME_LENGTH);
		SQL_FetchString(hndl, 1, szName, MAX_NAME_LENGTH);
		Handle pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackString(pack, szName);
		Format(szQuery, 512, sql_selectPlayerRankMultiBhop, szSteamId);
		SQL_TQuery(g_hDb, SQL_viewMultiBhop2RecordCallback2, szQuery, pack,DBPrio_Low);
	}
}
public SQL_viewMultiBhop2RecordCallback2(Handle owner, Handle hndl, const char[] error, any:data) {
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szName[MAX_NAME_LENGTH];
		int rank = SQL_GetRowCount(hndl);
		Handle pack = data;
		ResetPack(pack);
		int client = ReadPackCell(pack);
		ReadPackString(pack, szName, MAX_NAME_LENGTH);
		CloseHandle(pack);
		if(rank < 21 && rank < g_js_MultiBhopRank[client]) {
			g_js_MultiBhopRank[client] = rank;
			for(new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i) && !IsFakeClient(i)) {
					PrintToChat(i, "%t", "Jumpstats_MultiBhopTop", MOSSGREEN, WHITE, YELLOW, szName, rank, g_js_fPersonal_MultiBhop_Record[client]);
					PrintToConsole(i, "[JS] %s is now #%i in the nobug Multi-Bunnyhop Top 20! [%.3f units]", szName, rank, g_js_fPersonal_MultiBhop_Record[client]);
				}
			}
		}
	}
}
public db_viewLjRecord2(client) {
	char szQuery[512];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 512, sql_selectPlayerJumpLJ, szSteamId);
	SQL_TQuery(g_hDb, SQL_viewLj2RecordCallback, szQuery, client,DBPrio_Low);
}
public db_viewBLjRecord2(client) {
	char szQuery[512];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 512, sql_BselectPlayerJumpLJ, szSteamId);
	SQL_TQuery(g_hBDb, SQL_viewBLj2RecordCallback, szQuery, client,DBPrio_Low);
}
public db_viewLjBlockRecord2(client) {
	char szQuery[512];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 512, sql_selectPlayerJumpLJBlock, szSteamId);
	SQL_TQuery(g_hDb, SQL_viewLjBlock2RecordCallback, szQuery, client,DBPrio_Low);
}
public SQL_viewLjBlock2RecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szQuery[512];
		char szName[MAX_NAME_LENGTH];
		char szSteamId[32];
		SQL_FetchString(hndl, 0, szSteamId, MAX_NAME_LENGTH);
		SQL_FetchString(hndl, 1, szName, MAX_NAME_LENGTH);
		Handle pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackString(pack, szName);
		Format(szQuery, 512, sql_selectPlayerRankLjBlock, szSteamId);
		SQL_TQuery(g_hDb, SQL_viewLjBlock2RecordCallback2, szQuery, pack,DBPrio_Low);
	}
}
public SQL_viewLj2RecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szQuery[512];
		char szName[MAX_NAME_LENGTH];
		char szSteamId[32];
		SQL_FetchString(hndl, 0, szSteamId, MAX_NAME_LENGTH);
		SQL_FetchString(hndl, 1, szName, MAX_NAME_LENGTH);
		Handle pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackString(pack, szName);
		Format(szQuery, 512, sql_selectPlayerRankLj, szSteamId);
		SQL_TQuery(g_hDb, SQL_viewLj2RecordCallback2, szQuery, pack,DBPrio_Low);
	}
}
public SQL_viewBLj2RecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szQuery[512];
		char szName[MAX_NAME_LENGTH];
		char szSteamId[32];
		SQL_FetchString(hndl, 0, szSteamId, MAX_NAME_LENGTH);
		SQL_FetchString(hndl, 1, szName, MAX_NAME_LENGTH);
		Handle pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackString(pack, szName);
		Format(szQuery, 512, sql_BselectPlayerRankLj, szSteamId);
		SQL_TQuery(g_hDb, SQL_viewBLj2RecordCallback2, szQuery, pack,DBPrio_Low);
	}
}
public SQL_viewLjBlock2RecordCallback2(Handle owner, Handle hndl, const char[] error, any:data) {
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szName[MAX_NAME_LENGTH];
		int rank = SQL_GetRowCount(hndl);
		Handle pack = data;
		ResetPack(pack);
		int client = ReadPackCell(pack);
		ReadPackString(pack, szName, MAX_NAME_LENGTH);
		CloseHandle(pack);
		if(rank < 21 && rank < g_js_LjBlockRank[client]) {
			g_js_LjBlockRank[client] = rank;
			for(new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i) && !IsFakeClient(i)) {
					PrintToChat(i, "%t", "Jumpstats_LjBlockTop", MOSSGREEN, WHITE, YELLOW, szName, rank, g_js_Personal_LjBlock_Record[client],g_js_fPersonal_LjBlockRecord_Dist[client]);
					PrintToConsole(i, "[JS] %s is now #%i in the nobug Longjump 20! [%i units block/%.3f units jump]", szName, rank, g_js_Personal_LjBlock_Record[client],g_js_fPersonal_LjBlockRecord_Dist[client]);
				}
			}
		}
	}
}
public SQL_viewBLjBlock2RecordCallback2(Handle owner, Handle hndl, const char[] error, any:data) {
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szName[MAX_NAME_LENGTH];
		int rank = SQL_GetRowCount(hndl);
		Handle pack = data;
		ResetPack(pack);
		int client = ReadPackCell(pack);
		ReadPackString(pack, szName, MAX_NAME_LENGTH);
		CloseHandle(pack);
		if(rank < 21 && rank < g_js_BLjBlockRank[client]) {
			g_js_BLjBlockRank[client] = rank;
			for(new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i) && !IsFakeClient(i)) {
					CPrintToChat(i, "[{lightgreen}JS{default}] {olive}%s is now #%i in the Bugged Block LongJump Top 20! [%i units block/%.3f units jump]", szName, rank, g_js_BuggedPersonal_LjBlock_Record[client],g_js_fBuggedPersonal_LjBlockRecord_Dist[client]);
					PrintToConsole(i, "[JS] %s is now #%i in the Bugged Block LongJump Top 20! [%i units block/%.3f units jump]", szName, rank, g_js_BuggedPersonal_LjBlock_Record[client],g_js_fBuggedPersonal_LjBlockRecord_Dist[client]);
				}
			}
		}
	}
}
public SQL_viewLj2RecordCallback2(Handle owner, Handle hndl, const char[] error, any:data) {
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szName[MAX_NAME_LENGTH];
		int rank = SQL_GetRowCount(hndl);
		Handle pack = data;
		ResetPack(pack);
		int client = ReadPackCell(pack);
		ReadPackString(pack, szName, MAX_NAME_LENGTH);
		CloseHandle(pack);
		if(rank < 21 && rank < g_js_LjRank[client]) {
			g_js_LjRank[client] = rank;
			for(new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i) && !IsFakeClient(i)) {
					PrintToChat(i, "%t", "Jumpstats_LjTop", MOSSGREEN, WHITE, YELLOW, szName, rank, g_js_fPersonal_Lj_Record[client]);
					PrintToConsole(i, "[JS] %s is now #%i in the Longjump 20! [%.3f units]", szName, rank, g_js_fPersonal_Lj_Record[client]);
				}
			}
		}
	}
}
public SQL_viewBLj2RecordCallback2(Handle owner, Handle hndl, const char[] error, any:data) {
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szName[MAX_NAME_LENGTH];
		int rank = SQL_GetRowCount(hndl);
		Handle pack = data;
		ResetPack(pack);
		int client = ReadPackCell(pack);
		ReadPackString(pack, szName, MAX_NAME_LENGTH);
		CloseHandle(pack);
		if(rank < 21 && rank < g_js_BLjRank[client]) {
			g_js_BLjRank[client] = rank;
			for(new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i) && !IsFakeClient(i)) {
					CPrintToChat(i, "[{lightgreen}JS{default}] {olive}%s is now #%i in the Bugged LongJump Top 20! [%.3f units]", szName, rank, g_js_fBuggedPersonal_Lj_Record[client]);
					PrintToConsole(i, "[JS] %s is now #%i in the Bugged Longjump 20! [%.3f units]", szName, rank, g_js_fBuggedPersonal_Lj_Record[client]);
				}
			}
		}
	}
}
public db_viewWjRecord2(client) {
	char szQuery[512];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 512, sql_selectPlayerJumpWJ, szSteamId);
	SQL_TQuery(g_hDb, SQL_viewWj2RecordCallback, szQuery, client,DBPrio_Low);
}
public SQL_viewWj2RecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szQuery[512];
		char szName[MAX_NAME_LENGTH];
		char szSteamId[32];
		SQL_FetchString(hndl, 0, szSteamId, MAX_NAME_LENGTH);
		SQL_FetchString(hndl, 1, szName, MAX_NAME_LENGTH);
		Handle pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackString(pack, szName);
		Format(szQuery, 512, sql_selectPlayerRankWJ, szSteamId);
		SQL_TQuery(g_hDb, SQL_viewWj2RecordCallback2, szQuery, pack,DBPrio_Low);
	}
}
public SQL_viewWj2RecordCallback2(Handle owner, Handle hndl, const char[] error, any:data) {
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szName[MAX_NAME_LENGTH];
		int rank = SQL_GetRowCount(hndl);
		Handle pack = data;
		ResetPack(pack);
		int client = ReadPackCell(pack);
		ReadPackString(pack, szName, MAX_NAME_LENGTH);
		CloseHandle(pack);
		if(rank < 21 && rank < g_js_WjRank[client]) {
			g_js_WjRank[client] = rank;
			for(new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i) && !IsFakeClient(i)) {
					PrintToChat(i, "%t", "Jumpstats_WjTop", MOSSGREEN, WHITE, YELLOW, szName, rank, g_js_fPersonal_Wj_Record[client]);
					PrintToConsole(i, "[JS] %s is now #%i in the Weirdjump 20! [%.3f units]", szName, rank, g_js_fPersonal_Wj_Record[client]);
				}
			}
		}
	}
}
public SQL_UpdateLjBlockRecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(IsValidClient(client)) {
		char szQuery[512];
		char szUName[MAX_NAME_LENGTH];
		GetClientName(client, szUName, MAX_NAME_LENGTH);
		char szSteamId[32];
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
		char szName[MAX_NAME_LENGTH*2+1];
		SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH*2+1);
		if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
			Format(szQuery, 512, sql_updateLjBlock, szName, g_js_Personal_LjBlock_Record[client], g_js_fPersonal_LjBlockRecord_Dist[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_Sync_Final[client],g_flastHeight[client], szSteamId);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		} else {
			Format(szQuery, 512, sql_insertPlayerJumpLjBlock, szSteamId, szName, g_js_Personal_LjBlock_Record[client], g_js_fPersonal_LjBlockRecord_Dist[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_Sync_Final[client],g_flastHeight[client]);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		}
		db_viewLjBlockRecord2(client);
	}
}
public SQL_UpdateWjRecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(IsValidClient(client)) {
		char szQuery[512];
		char szUName[MAX_NAME_LENGTH];
		GetClientName(client, szUName, MAX_NAME_LENGTH);
		char szSteamId[32];
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
		char szName[MAX_NAME_LENGTH*2+1];
		SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH*2+1);
		if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
			Format(szQuery, 512, sql_updateWJ, szName, g_js_fPersonal_Wj_Record[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_Sync_Final[client],g_flastHeight[client], szSteamId);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		} else {
			Format(szQuery, 512, sql_insertPlayerJumpWJ, szSteamId, szName, g_js_fPersonal_Wj_Record[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_Sync_Final[client],g_flastHeight[client]);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		}
	}
	db_viewWjRecord2(client);
}
public SQL_UpdateDropBhopRecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(IsValidClient(client)) {
		char szQuery[512];
		char szUName[MAX_NAME_LENGTH];
		GetClientName(client, szUName, MAX_NAME_LENGTH);
		char szName[MAX_NAME_LENGTH*2+1];
		char szSteamId[32];
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
		SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH*2+1);
		if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
			Format(szQuery, 512, sql_updateDropBhop, szName, g_js_fPersonal_DropBhop_Record[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_Sync_Final[client],g_flastHeight[client], szSteamId);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		} else {
			Format(szQuery, 512, sql_insertPlayerJumpDropBhop, szSteamId, szName, g_js_fPersonal_DropBhop_Record[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_Sync_Final[client],g_flastHeight[client]);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		}
	}
	db_viewDropBhopRecord2(client);
}
public db_viewDropBhopRecord2(client) {
	char szQuery[512];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 512, sql_selectPlayerJumpDropBhop, szSteamId);
	SQL_TQuery(g_hDb, SQL_viewDropBhop2RecordCallback, szQuery, client,DBPrio_Low);
}
public SQL_viewDropBhop2RecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szQuery[512];
		char szName[MAX_NAME_LENGTH];
		char szSteamId[32];
		SQL_FetchString(hndl, 0, szSteamId, 32);
		SQL_FetchString(hndl, 1, szName, MAX_NAME_LENGTH);
		Handle pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackString(pack, szName);
		Format(szQuery, 512, sql_selectPlayerRankDropBhop, szSteamId);
		SQL_TQuery(g_hDb, SQL_viewDropBhop2RecordCallback2, szQuery, pack,DBPrio_Low);
	}
}
public SQL_viewBhop2RecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szQuery[512];
		char szName[MAX_NAME_LENGTH];
		char szSteamId[32];
		SQL_FetchString(hndl, 0, szSteamId, 32);
		SQL_FetchString(hndl, 1, szName, MAX_NAME_LENGTH);
		Handle pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackString(pack, szName);
		Format(szQuery, 512, sql_selectPlayerRankBhop, szSteamId);
		SQL_TQuery(g_hDb, SQL_viewBhop2RecordCallback2, szQuery, pack,DBPrio_Low);
	}
}
public SQL_UpdateBhopRecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(IsValidClient(client)) {
		char szQuery[512];
		char szUName[MAX_NAME_LENGTH];
		GetClientName(client, szUName, MAX_NAME_LENGTH);
		char szName[MAX_NAME_LENGTH*2+1];
		char szSteamId[32];
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
		SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH*2+1);
		if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
			Format(szQuery, 512, sql_updateBhop, szName, g_js_fPersonal_Bhop_Record[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_Sync_Final[client],g_flastHeight[client], szSteamId);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		} else {
			Format(szQuery, 512, sql_insertPlayerJumpBhop, szSteamId, szName, g_js_fPersonal_Bhop_Record[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_Sync_Final[client],g_flastHeight[client]);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		}
		db_viewBhopRecord2(client);
	}
}
public db_viewBhopRecord2(client) {
	char szQuery[512];
	char szSteamId[32];
	if(IsValidClient(client))
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	else
		return;
	Format(szQuery, 512, sql_selectPlayerJumpBhop, szSteamId);
	SQL_TQuery(g_hDb, SQL_viewBhop2RecordCallback, szQuery, client,DBPrio_Low);
}
public SQL_UpdateMultiBhopRecordCallback(Handle owner, Handle hndl, const char[] error, any:data) {
	int client = data;
	if(IsValidClient(client)) {
		char szQuery[512];
		char szUName[MAX_NAME_LENGTH];
		GetClientName(client, szUName, MAX_NAME_LENGTH);
		char szName[MAX_NAME_LENGTH*2+1];
		char szSteamId[32];
		if(IsValidClient(client))
			GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
		else
			return;
		SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH*2+1);
		if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
			Format(szQuery, 512, sql_updateMultiBhop, szName, g_js_fPersonal_MultiBhop_Record[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_MultiBhop_Count[client],g_js_Sync_Final[client],g_flastHeight[client], szSteamId);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		} else {
			Format(szQuery, 512, sql_insertPlayerJumpMultiBhop, szSteamId, szName, g_js_fPersonal_MultiBhop_Record[client], g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], g_js_Strafes_Final[client],g_js_MultiBhop_Count[client],g_js_Sync_Final[client],g_flastHeight[client]);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery,DBPrio_Low);
		}
		db_viewMultiBhopRecord2(client);
	}
}
public LjBlockJumpMenuHandler1(Handle menu, MenuAction action, param1, param2) {
	if(action == MenuAction_Select)
		JumpTopMenu(param1);
	if(action == MenuAction_End)
		delete menu;
}
public BLjBlockJumpMenuHandler1(Handle menu, MenuAction action, param1, param2) {
	if(action == MenuAction_Select)
		JumpTopMenu(param1);
	if(action == MenuAction_End)
		delete menu;
}
public db_selectTopLj(client) {
	char szQuery[1024];
	Format(szQuery, 1024, sql_selectPlayerJumpTopLJ);
	SQL_TQuery(g_hDb, sql_selectPlayerJumpTopLJCallback, szQuery, client,DBPrio_Low);
}
public db_BselectTopLj(client) {
	char szQuery[1024];
	Format(szQuery, 1024, sql_BselectPlayerJumpTopLJ);
	SQL_TQuery(g_hBDb, sql_BselectPlayerJumpTopLJCallback, szQuery, client,DBPrio_Low);
}
public db_selectTopLjBlock(client) {
	char szQuery[1024];
	Format(szQuery, 1024, sql_selectPlayerJumpTopLJBlock);
	SQL_TQuery(g_hDb, sql_selectPlayerJumpTopLJBlockCallback, szQuery, client,DBPrio_Low);
}
public db_selectTopWj(client) {
	char szQuery[1024];
	Format(szQuery, 1024, sql_selectPlayerJumpTopWJ);
	SQL_TQuery(g_hDb, sql_selectPlayerJumpTopWJCallback, szQuery, client,DBPrio_Low);
}
public db_selectTopBhop(client) {
	char szQuery[1024];
	Format(szQuery, 1024, sql_selectPlayerJumpTopBhop);
	SQL_TQuery(g_hDb, sql_selectPlayerJumpTopBhopCallback, szQuery, client,DBPrio_Low);
}
public db_selectTopDropBhop(client) {
	char szQuery[1024];
	Format(szQuery, 1024, sql_selectPlayerJumpTopDropBhop);
	SQL_TQuery(g_hDb, sql_selectPlayerJumpTopDropBhopCallback, szQuery, client,DBPrio_Low);
}
public db_selectTopMultiBhop(client) {
	char szQuery[1024];
	Format(szQuery, 1024, sql_selectPlayerJumpTopMultiBhop);
	SQL_TQuery(g_hDb, sql_selectPlayerJumpTopMultiBhopCallback, szQuery, client,DBPrio_Low);
}
public sql_selectPlayerJumpTopLJBlockCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	char szValue[128];
	char szName[64];
	char szSteamID[32];
	int ljblock;
	float ljrecord;
	char szStrafes[32];
	int strafes;
	Handle menu = CreateMenu(LjBlockJumpMenuHandler1);
	SetMenuTitle(menu, "Top 20 Block Longjump\n    Rank    Block   Distance           Strafes      Player");
	SetMenuPagination(menu, 5);
	if(SQL_HasResultSet(hndl)) {
		int i = 1;
		while (SQL_FetchRow(hndl)) {
			SQL_FetchString(hndl, 0, szName, 64);
			ljblock = SQL_FetchInt(hndl, 1);
			ljrecord = SQL_FetchFloat(hndl, 2);
			strafes = SQL_FetchInt(hndl, 3);
			SQL_FetchString(hndl, 4, szSteamID, 32);
			if(strafes < 10)
				Format(szStrafes, 32, " %i ", strafes);
			else
				Format(szStrafes, 32, "%i", strafes);
			if(i < 10)
				Format(szValue, 128, "[0%i.]    %i     %.3f units       %s      » %s", i, ljblock, ljrecord, szStrafes, szName);
			else
				Format(szValue, 128, "[%i.]    %i     %.3f units       %s      » %s", i, ljblock, ljrecord, szStrafes, szName);
			AddMenuItem(menu, szSteamID, szValue, ITEMDRAW_DEFAULT);
			i++;
		}
	}
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public sql_selectPlayerJumpTopLJCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	char szValue[128];
	char szName[64];
	char szSteamID[32];
	float ljrecord;
	char szStrafes[32];
	int strafes;
	Handle menu = CreateMenu(LjJumpMenuHandler1);
	SetMenuTitle(menu, "Top 20 Longjump\n    Rank    Distance           Strafes      Player");
	SetMenuPagination(menu, 5);
	if(SQL_HasResultSet(hndl)) {
		int i = 1;
		while (SQL_FetchRow(hndl)) {
			SQL_FetchString(hndl, 0, szName, 64);
			ljrecord = SQL_FetchFloat(hndl, 1);
			strafes = SQL_FetchInt(hndl, 2);
			SQL_FetchString(hndl, 3, szSteamID, 32);
			if(strafes < 10)
				Format(szStrafes, 32, " %i ", strafes);
			else
				Format(szStrafes, 32, "%i", strafes);
			if(i < 10)
				Format(szValue, 128, "[0%i.]    %.3f units      %s      » %s", i, ljrecord, szStrafes, szName);
			else
				Format(szValue, 128, "[%i.]    %.3f units      %s      » %s", i, ljrecord, szStrafes, szName);
			AddMenuItem(menu, szSteamID, szValue, ITEMDRAW_DEFAULT);
			i++;
		}
	}
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public sql_BselectPlayerJumpTopLJCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	char szValue[128];
	char szName[64];
	char szSteamID[32];
	float bljrecord;
	char szStrafes[32];
	int strafes;
	Handle menu = CreateMenu(BLjJumpMenuHandler1);
	SetMenuTitle(menu, "Top 20 Bugged Longjump\n    Rank    Distance           Strafes      Player");
	SetMenuPagination(menu, 5);
	if(SQL_HasResultSet(hndl)) {
		int i = 1;
		while (SQL_FetchRow(hndl)) {
			SQL_FetchString(hndl, 0, szName, 64);
			bljrecord = SQL_FetchFloat(hndl, 1);
			strafes = SQL_FetchInt(hndl, 2);
			SQL_FetchString(hndl, 3, szSteamID, 32);
			if(strafes < 10)
				Format(szStrafes, 32, " %i ", strafes);
			else
				Format(szStrafes, 32, "%i", strafes);
			if(i < 10)
				Format(szValue, 128, "[0%i.]    %.3f units      %s      » %s", i, bljrecord, szStrafes, szName);
			else
				Format(szValue, 128, "[%i.]    %.3f units      %s      » %s", i, bljrecord, szStrafes, szName);
			AddMenuItem(menu, szSteamID, szValue, ITEMDRAW_DEFAULT);
			i++;
		}
	}
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public sql_selectPlayerJumpTopWJCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	char szValue[128];
	char szName[64];
	float ljrecord;
	char szStrafes[32];
	char szSteamID[32];
	int strafes;
	Handle menu = CreateMenu(WjJumpMenuHandler1);
	SetMenuTitle(menu, "Top 20 Weirdjump\n    Rank    Distance           Strafes      Player");
	SetMenuPagination(menu, 5);
	if(SQL_HasResultSet(hndl)) {
		int i = 1;
		while (SQL_FetchRow(hndl)) {
			SQL_FetchString(hndl, 0, szName, 64);
			ljrecord = SQL_FetchFloat(hndl, 1);
			strafes = SQL_FetchInt(hndl, 2);
			SQL_FetchString(hndl, 3, szSteamID, 32);
			if(strafes < 10)
				Format(szStrafes, 32, " %i ", strafes);
			else
				Format(szStrafes, 32, "%i", strafes);
			if(i < 10)
				Format(szValue, 128, "[0%i.]    %.3f units      %s      » %s", i, ljrecord, szStrafes, szName);
			else
				Format(szValue, 128, "[%i.]    %.3f units      %s      » %s", i, ljrecord, szStrafes, szName);
			AddMenuItem(menu, szSteamID, szValue, ITEMDRAW_DEFAULT);
			i++;
		}
	}
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public sql_selectPlayerJumpTopBhopCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	char szValue[128];
	char szName[64];
	float bhoprecord;
	char szSteamID[32];
	char szStrafes[32];
	int strafes;
	Handle menu = CreateMenu(BhopJumpMenuHandler1);
	SetMenuTitle(menu, "Top 20 Bunnyhop\n    Rank    Distance           Strafes      Player");
	SetMenuPagination(menu, 5);
	if(SQL_HasResultSet(hndl)) {
		int i = 1;
		while (SQL_FetchRow(hndl)) {
			SQL_FetchString(hndl, 0, szName, 64);
			bhoprecord = SQL_FetchFloat(hndl, 1);
			strafes = SQL_FetchInt(hndl, 2);
			SQL_FetchString(hndl, 3, szSteamID, 32);
			if(strafes < 10)
				Format(szStrafes, 32, " %i ", strafes);
			else
				Format(szStrafes, 32, "%i", strafes);
			if(i < 10)
				Format(szValue, 128, "[0%i.]    %.3f units      %s      » %s", i, bhoprecord, szStrafes, szName);
			else
				Format(szValue, 128, "[%i.]    %.3f units      %s      » %s", i, bhoprecord, szStrafes, szName);
			AddMenuItem(menu, szSteamID, szValue, ITEMDRAW_DEFAULT);
			i++;
		}
	}
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public sql_selectPlayerJumpTopDropBhopCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	char szValue[128];
	char szName[64];
	float bhoprecord;
	char szSteamID[32];
	char szStrafes[32];
	int strafes;
	Handle menu = CreateMenu(DropBhopJumpMenuHandler1);
	SetMenuTitle(menu, "Top 20 Drop-Bunnyhop\n    Rank    Distance           Strafes      Player");
	SetMenuPagination(menu, 5);
	if(SQL_HasResultSet(hndl)) {
		int i = 1;
		while (SQL_FetchRow(hndl)) {
			SQL_FetchString(hndl, 0, szName, 64);
			bhoprecord = SQL_FetchFloat(hndl, 1);
			strafes = SQL_FetchInt(hndl, 2);
			SQL_FetchString(hndl, 3, szSteamID, 32);
			if(strafes < 10)
				Format(szStrafes, 32, " %i ", strafes);
			else
				Format(szStrafes, 32, "%i", strafes);
			if(i < 10)
				Format(szValue, 128, "[0%i.]    %.3f units      %s      » %s", i, bhoprecord, szStrafes, szName);
			else
				Format(szValue, 128, "[%i.]    %.3f units      %s      » %s", i, bhoprecord, szStrafes, szName);
			AddMenuItem(menu, szSteamID, szValue, ITEMDRAW_DEFAULT);
			i++;
		}
	}
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public sql_selectPlayerJumpTopMultiBhopCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	char szValue[128];
	char szName[64];
	float multibhoprecord;
	char szSteamID[32];
	char szStrafes[32];
	int strafes;
	Handle menu = CreateMenu(MultiBhopJumpMenuHandler1);
	SetMenuTitle(menu, "Top 20 Multi-Bunnyhop\n    Rank    Distance           Strafes      Player");
	SetMenuPagination(menu, 5);
	if(SQL_HasResultSet(hndl)) {
		int i = 1;
		while (SQL_FetchRow(hndl)) {
			SQL_FetchString(hndl, 0, szName, 64);
			multibhoprecord = SQL_FetchFloat(hndl, 1);
			strafes = SQL_FetchInt(hndl, 2);
			SQL_FetchString(hndl, 3, szSteamID, 32);
			if(strafes < 10)
				Format(szStrafes, 32, " %i ", strafes);
			else
				Format(szStrafes, 32, "%i", strafes);
			if(i < 10)
				Format(szValue, 128, "[0%i.]    %.3f units      %s      » %s", i, multibhoprecord, szStrafes, szName);
			else
				Format(szValue, 128, "[%i.]    %.3f units      %s      » %s", i, multibhoprecord, szStrafes, szName);
			AddMenuItem(menu, szSteamID, szValue, ITEMDRAW_DEFAULT);
			i++;
		}
	}
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public LjJumpMenuHandler1(Handle menu, MenuAction action, param1, param2) {
	if(action == MenuAction_Select) {
		g_bdetailView[param1]=true;
		char id[32];
		GetMenuItem(menu, param2, id, sizeof(id));
		db_viewJumpStats(param1, id);
	}
	else if(action == MenuAction_Cancel)
		JumpTopMenu(param1);
	if(action == MenuAction_End)
		delete menu;
}
public BLjJumpMenuHandler1(Handle menu, MenuAction action, param1, param2) {
	if(action == MenuAction_Select) {
		g_bdetailView[param1]=true;
		char id[32];
		GetMenuItem(menu, param2, id, sizeof(id));
		db_viewBJumpStats(param1, id);
	}
	else if(action == MenuAction_Cancel)
		TopMenu(param1);
	if(action == MenuAction_End)
		delete menu;
}
public WjJumpMenuHandler1(Handle menu, MenuAction action, param1, param2) {
	if(action == MenuAction_Select) {
		g_bdetailView[param1]=true;
		char id[32];
		GetMenuItem(menu, param2, id, sizeof(id));
		db_viewJumpStats(param1, id);
	}
	else if(action == MenuAction_Cancel)
		JumpTopMenu(param1);
	if(action == MenuAction_End)
		delete menu;
}
public BhopJumpMenuHandler1(Handle menu, MenuAction action, param1, param2) {
	if(action == MenuAction_Select) {
		g_bdetailView[param1]=true;
		char id[32];
		GetMenuItem(menu, param2, id, sizeof(id));
		db_viewJumpStats(param1, id);
	}
	else if(action == MenuAction_Cancel)
		JumpTopMenu(param1);
	if(action == MenuAction_End)
		delete menu;
}
public DropBhopJumpMenuHandler1(Handle menu, MenuAction action, param1, param2) {
	if(action == MenuAction_Select) {
		g_bdetailView[param1]=true;
		char id[32];
		GetMenuItem(menu, param2, id, sizeof(id));
		db_viewJumpStats(param1, id);
	}
	else if(action == MenuAction_Cancel)
		JumpTopMenu(param1);
	if(action == MenuAction_End)
		delete menu;
}
public MultiBhopJumpMenuHandler1(Handle menu, MenuAction action, param1, param2) {
	if(action == MenuAction_Select) {
		g_bdetailView[param1]=true;
		char id[32];
		GetMenuItem(menu, param2, id, sizeof(id));
		db_viewJumpStats(param1, id);
	}
	else if(action == MenuAction_Cancel)
		JumpTopMenu(param1);
	if(action == MenuAction_End)
		delete menu;
}
public SQL_CheckCallback(Handle owner, Handle hndl, const char[] error, any data) {
}
public db_viewJumpStats(client, char szSteamId[32]) {
	char szQuery[1024];
	Format(szQuery, 1024, sql_selectJumpStats, szSteamId);
	SQL_TQuery(g_hDb, SQL_ViewJumpStatsCallback, szQuery, client,DBPrio_Low);
}
public db_viewBJumpStats(client, char szSteamId[32]) {
	char szQuery[1024];
	Format(szQuery, 1024, sql_BselectJumpStats, szSteamId);
	SQL_TQuery(g_hBDb, SQL_ViewBJumpStatsCallback, szQuery, client,DBPrio_Low);
}
public SQL_ViewJumpStatsCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szSteamId[32];
		char szName[17];
		char szVr[255];
	//get the result
		SQL_FetchString(hndl, 0, szSteamId, MAX_NAME_LENGTH);
		SQL_FetchString(hndl, 1, szName, 17);
	//Bhop
		float bhoprecord = SQL_FetchFloat(hndl, 2);
		float bhoppre = SQL_FetchFloat(hndl, 3);
		float bhopmax = SQL_FetchFloat(hndl, 4);
		int bhopstrafes = SQL_FetchInt(hndl, 5);
		int bhopsync = SQL_FetchInt(hndl, 6);
	//LJ
		float ljrecord = SQL_FetchFloat(hndl, 7);
		float ljpre = SQL_FetchFloat(hndl, 8);
		float ljmax = SQL_FetchFloat(hndl, 9);
		int ljstrafes = SQL_FetchInt(hndl, 10);
		int ljsync = SQL_FetchInt(hndl, 11);
	//MBhop
		float multibhoprecord = SQL_FetchFloat(hndl, 12);
		float multibhoppre = SQL_FetchFloat(hndl, 13);
		float multibhopmax = SQL_FetchFloat(hndl, 14);
		int multibhopstrafes = SQL_FetchInt(hndl, 15);
		int multibhopsync = SQL_FetchInt(hndl, 17);
	//WJ
		float wjrecord = SQL_FetchFloat(hndl, 18);
		float wjpre = SQL_FetchFloat(hndl, 19);
		float wjmax = SQL_FetchFloat(hndl, 20);
		int wjstrafes = SQL_FetchInt(hndl, 21);
		int wjsync = SQL_FetchInt(hndl, 22);
	//DBhop
		float dropbhoprecord = SQL_FetchFloat(hndl, 23);
		float dropbhoppre = SQL_FetchFloat(hndl, 24);
		float dropbhopmax = SQL_FetchFloat(hndl, 25);
		int dropbhopstrafes = SQL_FetchInt(hndl, 26);
		int dropbhopsync = SQL_FetchInt(hndl, 27);
	//Height?
		float ljheight = SQL_FetchFloat(hndl, 28);
		float bhopheight = SQL_FetchFloat(hndl, 29);
		float multibhopheight = SQL_FetchFloat(hndl, 30);
		float dropbhopheight = SQL_FetchFloat(hndl, 31);
		float wjheight = SQL_FetchFloat(hndl, 32);
	//Block LJ
		int ljblockdist = SQL_FetchInt(hndl, 33);
		float ljblockrecord = SQL_FetchFloat(hndl, 34);
		float ljblockpre = SQL_FetchFloat(hndl, 35);
		float ljblockmax = SQL_FetchFloat(hndl, 36);
		int ljblockstrafes = SQL_FetchInt(hndl, 37);
		int ljblocksync = SQL_FetchInt(hndl, 38);
		float ljblockheight = SQL_FetchFloat(hndl, 39);
		if(bhoprecord > 0.0 || ljrecord > 0.0 || multibhoprecord > 0.0 || wjrecord > 0.0 || dropbhoprecord > 0.0) { // || ljblockdist > 0
			Format(szVr, 255, "JS: %s (%s)\nType               Distance  Strafes Pre        Max      Height  Sync", szName, szSteamId);
			Menu menu = new Menu(JumpStatsMenuHandler);
			menu.SetTitle(szVr);
			if(ljrecord > 0.0) {
				if(ljstrafes > 9) {
					Format(szVr, 255, "LJ:              %.3f     %i      %.2f   %.2f  %.1f    %i%c", ljrecord, ljstrafes, ljpre, ljmax, ljheight, ljsync, PERCENT);
					menu.AddItem("1", szVr);
				} else {
					Format(szVr, 255, "LJ:              %.3f       %i      %.2f   %.2f  %.1f    %i%c", ljrecord, ljstrafes, ljpre, ljmax, ljheight, ljsync, PERCENT);
					menu.AddItem("1", szVr);
				}
			}
			if(ljblockdist > 0 && !(CheckCommandAccess(client, "sm_resetplayerjumpstats", ADMFLAG_BAN))) {
				if(ljstrafes > 9) {
					Format(szVr, 255, "BlockLJ:     %i|%.1f %i      %.2f   %.2f  %.1f    %i%c", ljblockdist, ljblockrecord, ljblockstrafes, ljblockpre, ljblockmax, ljblockheight, ljblocksync, PERCENT);
					menu.AddItem("2", szVr);
				} else {
					Format(szVr, 255, "BlockLJ:     %i|%.1f   %i      %.2f   %.2f  %.1f    %i%c", ljblockdist, ljblockrecord, ljblockstrafes, ljblockpre, ljblockmax, ljblockheight, ljblocksync, PERCENT);
					menu.AddItem("2", szVr);
				}
			}
			if(bhoprecord > 0.0) {
				if(bhopstrafes > 9) {
					Format(szVr, 255, "Bhop:         %.3f     %i      %.2f   %.2f  %.1f    %i%c", bhoprecord, bhopstrafes, bhoppre, bhopmax, bhopheight, bhopsync, PERCENT);
					menu.AddItem("3", szVr);
				} else {
					Format(szVr, 255, "Bhop:         %.3f       %i      %.2f   %.2f  %.1f    %i%c", bhoprecord, bhopstrafes, bhoppre, bhopmax, bhopheight, bhopsync, PERCENT);
					menu.AddItem("3", szVr);
				}
			}
			if(dropbhoprecord > 0.0) {
				if(dropbhopstrafes > 9) {
					Format(szVr, 255, "DropBhop: %.3f     %i      %.2f   %.2f  %.1f    %i%c", dropbhoprecord, dropbhopstrafes, dropbhoppre, dropbhopmax, dropbhopheight, dropbhopsync, PERCENT);
					menu.AddItem("4", szVr);
				} else {
					Format(szVr, 255, "DropBhop: %.3f       %i      %.2f   %.2f  %.1f    %i%c", dropbhoprecord, dropbhopstrafes, dropbhoppre, dropbhopmax, dropbhopheight, dropbhopsync, PERCENT);
					menu.AddItem("4", szVr);
				}
			}
			if(multibhoprecord > 0.0) {
				if(multibhopstrafes > 9) {
					Format(szVr, 255, "MultiBhop: %.3f     %i      %.2f   %.2f  %.1f    %i%c", multibhoprecord, multibhopstrafes, multibhoppre, multibhopmax, multibhopheight, multibhopsync, PERCENT);
					menu.AddItem("5", szVr);
				} else {
					Format(szVr, 255, "MultiBhop: %.3f       %i      %.2f   %.2f  %.1f    %i%c", multibhoprecord, multibhopstrafes, multibhoppre, multibhopmax, multibhopheight, multibhopsync, PERCENT);
					menu.AddItem("5", szVr);
				}
			}
			if(wjrecord > 0.0) {
				if(wjstrafes > 9) {
					Format(szVr, 255, "WJ:            %.3f     %i      %.2f   %.2f  %.1f    %i%c", wjrecord, wjstrafes, wjpre, wjmax, wjheight, wjsync, PERCENT);
					menu.AddItem("6", szVr);
				} else {
					Format(szVr, 255, "WJ:            %.3f       %i      %.2f   %.2f  %.1f    %i%c", wjrecord, wjstrafes, wjpre, wjmax, wjheight, wjsync, PERCENT);
					menu.AddItem("6", szVr);
				}
			}
			if(CheckCommandAccess(client, "sm_resetplayerjumpstats", ADMFLAG_BAN)) {
				ResetID[client] = szSteamId;
				menu.AddItem("7", "Reset Player");
				menu.AddItem("8", "Ban Player");
			}
			SetMenuPagination(menu, MENU_NO_PAGINATION);
			SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
		else {
			CPrintToChat(client, "[{lightgreen}JS{default}] No jump records found!");
			JumpTopMenu(client);
		}
	}
	else {
		CPrintToChat(client, "[{lightgreen}JS{default}] No jump records found!");
		JumpTopMenu(client);
	}
}
public SQL_ViewBJumpStatsCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		char szSteamId[32];
		char szName[17];
		char szVr[255];
	//get the result
		SQL_FetchString(hndl, 0, szSteamId, MAX_NAME_LENGTH);
		SQL_FetchString(hndl, 1, szName, 17);
	//LJ
		float bljrecord = SQL_FetchFloat(hndl, 2);
		float bljpre = SQL_FetchFloat(hndl, 3);
		float bljmax = SQL_FetchFloat(hndl, 4);
		int bljstrafes = SQL_FetchInt(hndl, 5);
		int bljsync = SQL_FetchInt(hndl, 6);
	//Height?
		float bljheight = SQL_FetchFloat(hndl, 7);
		if(bljrecord > 0.0) {
			Format(szVr, 255, "JS: %s (%s)\nBugged Stats\nType               Distance  Strafes Pre        Max      Height  Sync", szName, szSteamId);
			Menu menu = new Menu(BJumpStatsMenuHandler);
			menu.SetTitle(szVr);
			if(bljrecord > 0.0) {
				if(bljstrafes > 9) {
					Format(szVr, 255, "LJ:              %.3f     %i      %.2f   %.2f  %.1f    %i%c", bljrecord, bljstrafes, bljpre, bljmax, bljheight, bljsync, PERCENT);
					menu.AddItem("1", szVr);
				} else {
					Format(szVr, 255, "LJ:              %.3f       %i      %.2f   %.2f  %.1f    %i%c", bljrecord, bljstrafes, bljpre, bljmax, bljheight, bljsync, PERCENT);
					menu.AddItem("1", szVr);
				}
			}
			if(CheckCommandAccess(client, "sm_resetplayerjumpstats", ADMFLAG_BAN)) {
				ResetID[client] = szSteamId;
				menu.AddItem("7", "Reset Player");
				menu.AddItem("8", "Ban Player");
			}
			SetMenuPagination(menu, MENU_NO_PAGINATION);
			SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
		else {
			CPrintToChat(client, "[{lightgreen}JS{default}] No jump records found!");
			db_BselectTopLj(client);
		}
	}
	else {
		CPrintToChat(client, "[{lightgreen}JS{default}] No jump records found!");
		db_BselectTopLj(client);
	}
}
public int JumpStatsMenuHandler(Menu menu, MenuAction action, int client, int info) {
	if(action == MenuAction_Select) {
		char choice[32];
		menu.GetItem(info, choice, sizeof(choice));
		if(!(StrEqual(choice, "7")) && !(StrEqual(choice, "8")))
			JumpTopMenu(client);
		else if(StrEqual(choice, "7")) {
			char szQuery[255];
			char szsteamid[128*2+1];
			SQL_EscapeString(g_hDb, ResetID[client], szsteamid, 128*2+1);
			Format(szQuery, 255, sql_resetJumpStats, szsteamid);
			Handle pack = CreateDataPack();
			WritePackCell(pack, client);
			WritePackString(pack, ResetID[client]);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, pack);
			PrintToConsole(client, "jumpstats cleared (%s).", ResetID[client]);
			for (new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i)) {
					char szSteamId2[32];
					GetClientAuthId(i, AuthId_Steam2, szSteamId2, sizeof(szSteamId2));
					if(StrEqual(szSteamId2,szsteamid)) {
						g_js_MultiBhopRank[i] = 99999999;
						g_js_fPersonal_MultiBhop_Record[i] = -1.0;
						g_js_WjRank[i] = 99999999;
						g_js_fPersonal_Wj_Record[i] = -1.0;
						g_js_DropBhopRank[i] = 99999999;
						g_js_fPersonal_DropBhop_Record[i] = -1.0;
						g_js_BhopRank[i] = 99999999;
						g_js_fPersonal_Bhop_Record[i] = -1.0;
						g_js_LjRank[i] = 99999999;
						g_js_fPersonal_Lj_Record[i] = -1.0;
					}
				}
			}
			JumpTopMenu(client);
		}
		else if(StrEqual(choice, "8")) {
			ServerCommand("sm_addban 43200 \"%s\"  \"Cheated Stats\"", ResetID[client]);
			PrintToChat(client, "Banned \"%s\" for 1 month", ResetID[client]);
			char szQuery[255];
			char szsteamid[128*2+1];
			SQL_EscapeString(g_hDb, ResetID[client], szsteamid, 128*2+1);
			Format(szQuery, 255, sql_resetJumpStats, szsteamid);
			Handle pack = CreateDataPack();
			WritePackCell(pack, client);
			WritePackString(pack, ResetID[client]);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, pack);
			PrintToConsole(client, "jumpstats cleared (%s).", ResetID[client]);
			for (new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i)) {
					char szSteamId2[32];
					GetClientAuthId(i, AuthId_Steam2, szSteamId2, sizeof(szSteamId2));
					if(StrEqual(szSteamId2,szsteamid)) {
						g_js_MultiBhopRank[i] = 99999999;
						g_js_fPersonal_MultiBhop_Record[i] = -1.0;
						g_js_WjRank[i] = 99999999;
						g_js_fPersonal_Wj_Record[i] = -1.0;
						g_js_DropBhopRank[i] = 99999999;
						g_js_fPersonal_DropBhop_Record[i] = -1.0;
						g_js_BhopRank[i] = 99999999;
						g_js_fPersonal_Bhop_Record[i] = -1.0;
						g_js_LjRank[i] = 99999999;
						g_js_fPersonal_Lj_Record[i] = -1.0;
					}
				}
			}
			JumpTopMenu(client);
		}
	}
	else if(action == MenuAction_Cancel)
		JumpTopMenu(client);
	if(action == MenuAction_End)
		delete menu;
}
public int BJumpStatsMenuHandler(Menu menu, MenuAction action, int client, int info) {
	if(action == MenuAction_Select) {
		char choice[32];
		menu.GetItem(info, choice, sizeof(choice));
		if(!(StrEqual(choice, "7")) && !(StrEqual(choice, "8")))
			db_BselectTopLj(client);
		else if(StrEqual(choice, "7")) {
			char szQuery[255];
			char szsteamid[128*2+1];
			SQL_EscapeString(g_hBDb, ResetID[client], szsteamid, 128*2+1);
			Format(szQuery, 255, sql_BresetLjRecord, szsteamid);
			Handle pack = CreateDataPack();
			WritePackCell(pack, client);
			WritePackString(pack, ResetID[client]);
			SQL_TQuery(g_hBDb, SQL_CheckCallback, szQuery, pack);
			PrintToConsole(client, "bugged jumpstats cleared (%s).", ResetID[client]);
			for (new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i)) {
					char szSteamId2[32];
					GetClientAuthId(i, AuthId_Steam2, szSteamId2, sizeof(szSteamId2));
					if(StrEqual(szSteamId2,szsteamid)) {
						g_js_BLjRank[i] = 99999999;
						g_js_fBuggedPersonal_Lj_Record[i] = -1.0;
					}
				}
			}
			db_BselectTopLj(client);
		}
		else if(StrEqual(choice, "8")) {
			ServerCommand("sm_addban 43200 \"%s\"  \"Cheated Stats\"", ResetID[client]);
			PrintToChat(client, "Banned \"%s\" for 1 month", ResetID[client]);
			char szQuery[255];
			char szsteamid[128*2+1];
			SQL_EscapeString(g_hBDb, ResetID[client], szsteamid, 128*2+1);
			Format(szQuery, 255, sql_BresetLjRecord, szsteamid);
			Handle pack = CreateDataPack();
			WritePackCell(pack, client);
			WritePackString(pack, ResetID[client]);
			SQL_TQuery(g_hBDb, SQL_CheckCallback, szQuery, pack);
			PrintToConsole(client, "bugged jumpstats cleared (%s).", ResetID[client]);
			for (new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i)) {
					char szSteamId2[32];
					GetClientAuthId(i, AuthId_Steam2, szSteamId2, sizeof(szSteamId2));
					if(StrEqual(szSteamId2,szsteamid)) {
						g_js_BLjRank[i] = 99999999;
						g_js_fBuggedPersonal_Lj_Record[i] = -1.0;
					}
				}
			}
			db_BselectTopLj(client);
		}
	}
	else if(action == MenuAction_Cancel)
		db_BselectTopLj(client);
	if(action == MenuAction_End)
		delete menu;
}
public db_viewPersonalLJRecord(client, char szSteamId[32]) {
	char szQuery[512];
	Format(szQuery, 512, sql_selectPlayerJumpLJ, szSteamId);
	SQL_TQuery(g_hDb, SQL_LJRecordCallback, szQuery, client,DBPrio_Low);
}
public db_viewBPersonalLJRecord(client, char szSteamId[32]) {
	char szQuery[512];
	Format(szQuery, 512, sql_BselectPlayerJumpLJ, szSteamId);
	SQL_TQuery(g_hBDb, SQL_BLJRecordCallback, szQuery, client,DBPrio_Low);
}
public SQL_LJRecordCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		g_js_fPersonal_Lj_Record[client] = SQL_FetchFloat(hndl, 2);
		if(g_js_fPersonal_Lj_Record[client] > -1.0) {
			char szSteamId[32];
			char szQuery[512];
			if(IsValidClient(client)) {
				GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
				Format(szQuery, 255, sql_selectPlayerRankLj, szSteamId);
				SQL_TQuery(g_hDb, SQL_viewLjRecordCallback2, szQuery, client,DBPrio_Low);
			}
		}
		else {
			g_js_LjRank[client] = 99999999;
			g_js_fPersonal_Lj_Record[client] = -1.0;
		}
	}
	else {
		g_js_LjRank[client] = 99999999;
		g_js_fPersonal_Lj_Record[client] = -1.0;
	}
}
public SQL_BLJRecordCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		g_js_fBuggedPersonal_Lj_Record[client] = SQL_FetchFloat(hndl, 2);
		if(g_js_fBuggedPersonal_Lj_Record[client] > -1.0) {
			char szSteamId[32];
			char szQuery[512];
			if(IsValidClient(client)) {
				GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
				Format(szQuery, 255, sql_BselectPlayerRankLj, szSteamId);
				SQL_TQuery(g_hBDb, SQL_viewBLjRecordCallback2, szQuery, client,DBPrio_Low);
			}
		}
		else {
			g_js_BLjRank[client] = 99999999;
			g_js_fBuggedPersonal_Lj_Record[client] = -1.0;
		}
	}
	else {
		g_js_BLjRank[client] = 99999999;
		g_js_fBuggedPersonal_Lj_Record[client] = -1.0;
	}
}
public db_viewPersonalLJBlockRecord(client, char szSteamId[32]) {
	char szQuery[512];
	Format(szQuery, 512, sql_selectPlayerJumpLJBlock, szSteamId);
	SQL_TQuery(g_hDb, SQL_LJBlockRecordCallback, szQuery, client,DBPrio_Low);
}
public db_viewPersonalBhopRecord(client, char szSteamId[32]) {
	char szQuery[512];
	Format(szQuery, 512, sql_selectPlayerJumpBhop, szSteamId);
	SQL_TQuery(g_hDb, SQL_ViewBhopRecordCallback, szQuery, client,DBPrio_Low);
}
public db_viewPersonalDropBhopRecord(client, char szSteamId[32]) {
	char szQuery[512];
	Format(szQuery, 512, sql_selectPlayerJumpDropBhop, szSteamId);
	SQL_TQuery(g_hDb, SQL_ViewDropBhopRecordCallback, szQuery, client,DBPrio_Low);
}
public db_viewPersonalWeirdRecord(client, char szSteamId[32]) {
	char szQuery[512];
	Format(szQuery, 512, sql_selectPlayerJumpWJ, szSteamId);
	SQL_TQuery(g_hDb, SQL_ViewWeirdRecordCallback, szQuery, client,DBPrio_Low);
}
stock FakePrecacheSound(const char[] szPath) {
	AddToStringTable(FindStringTable("soundprecache"), szPath);
}
public db_viewPersonalMultiBhopRecord(client, char szSteamId[32]) {
	char szQuery[512];
	Format(szQuery, 512, sql_selectPlayerJumpMultiBhop, szSteamId);
	SQL_TQuery(g_hDb, SQL_ViewMultiBhopRecordCallback, szQuery, client,DBPrio_Low);
}
public SQL_LJBlockRecordCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		g_js_Personal_LjBlock_Record[client] = SQL_FetchInt(hndl, 2);
		g_js_fPersonal_LjBlockRecord_Dist[client] = SQL_FetchFloat(hndl, 3);
		if(g_js_Personal_LjBlock_Record[client] > -1) {
			char szSteamId[32];
			char szQuery[512];
			if(IsValidClient(client)) {
				GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
				Format(szQuery, 255, sql_selectPlayerRankLjBlock, szSteamId);
				SQL_TQuery(g_hDb, SQL_viewLjBlockRecordCallback2, szQuery, client,DBPrio_Low);
			}
		}
		else {
			g_js_LjBlockRank[client] = 99999999;
			g_js_Personal_LjBlock_Record[client] = -1;
			g_js_fPersonal_LjBlockRecord_Dist[client] = -1.0;
		}
	}
	else {
		g_js_LjBlockRank[client] = 99999999;
		g_js_Personal_LjBlock_Record[client] = -1;
		g_js_fPersonal_LjBlockRecord_Dist[client] = -1.0;
	}
}
public SQL_viewLjRecordCallback2(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_js_LjRank[client]= SQL_GetRowCount(hndl);
}
public SQL_viewBLjRecordCallback2(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_js_BLjRank[client]= SQL_GetRowCount(hndl);
}
public SQL_viewLjBlockRecordCallback2(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_js_LjBlockRank[client]= SQL_GetRowCount(hndl);
}
public SQL_viewBLjBlockRecordCallback2(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_js_BLjBlockRank[client]= SQL_GetRowCount(hndl);
}
public SQL_ViewBhopRecordCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		g_js_fPersonal_Bhop_Record[client] = SQL_FetchFloat(hndl, 2);
		if(g_js_fPersonal_Bhop_Record[client] > -1.0) {
			char szSteamId[32];
			char szQuery[512];
			if(IsValidClient(client)) {
				GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
				Format(szQuery, 255, sql_selectPlayerRankBhop, szSteamId);
				SQL_TQuery(g_hDb, SQL_viewBhopRecordCallback2, szQuery, client,DBPrio_Low);
			}
		}
		else {
			g_js_BhopRank[client] = 99999999;
			g_js_fPersonal_Bhop_Record[client] = -1.0;
		}
	}
	else {
		g_js_BhopRank[client] = 99999999;
		g_js_fPersonal_Bhop_Record[client] = -1.0;
	}
}
public SQL_ViewDropBhopRecordCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		g_js_fPersonal_DropBhop_Record[client] = SQL_FetchFloat(hndl, 2);
		if(g_js_fPersonal_DropBhop_Record[client] > -1.0) {
			char szSteamId[32];
			char szQuery[512];
			if(IsValidClient(client)) {
				GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
				Format(szQuery, 255, sql_selectPlayerRankDropBhop, szSteamId);
				SQL_TQuery(g_hDb, SQL_viewDropBhopRecordCallback2, szQuery, client,DBPrio_Low);
			}
		}
		else {
			g_js_DropBhopRank[client] = 99999999;
			g_js_fPersonal_DropBhop_Record[client] = -1.0;
		}
	}
	else {
		g_js_DropBhopRank[client] = 99999999;
		g_js_fPersonal_DropBhop_Record[client] = -1.0;
	}
}
public SQL_viewDropBhopRecordCallback2(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_js_DropBhopRank[client]= SQL_GetRowCount(hndl);
}
public SQL_viewBDropBhopRecordCallback2(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_js_BDropBhopRank[client]= SQL_GetRowCount(hndl);
}
public SQL_ViewWeirdRecordCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		g_js_fPersonal_Wj_Record[client] = SQL_FetchFloat(hndl, 2);
		if(g_js_fPersonal_Wj_Record[client] > -1.0) {
			char szSteamId[32];
			char szQuery[512];
			if(IsValidClient(client)) {
				GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
				Format(szQuery, 255, sql_selectPlayerRankWJ, szSteamId);
				SQL_TQuery(g_hDb, SQL_viewWeirdRecordCallback2, szQuery, client,DBPrio_Low);
			}
		}
		else {
			g_js_WjRank[client] = 99999999;
			g_js_fPersonal_Wj_Record[client] = -1.0;
		}
	}
	else {
		g_js_WjRank[client] = 99999999;
		g_js_fPersonal_Wj_Record[client] = -1.0;
	}
}
public SQL_viewWeirdRecordCallback2(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_js_WjRank[client]= SQL_GetRowCount(hndl);
}
public SQL_viewBWeirdRecordCallback2(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_js_BWjRank[client]= SQL_GetRowCount(hndl);
}
public SQL_ViewMultiBhopRecordCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		g_js_fPersonal_MultiBhop_Record[client] = SQL_FetchFloat(hndl, 2);
		if(g_js_fPersonal_MultiBhop_Record[client] > -1.0) {
			char szSteamId[32];
			char szQuery[512];
			if(IsValidClient(client)) {
				GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
				Format(szQuery, 255, sql_selectPlayerRankMultiBhop, szSteamId);
				SQL_TQuery(g_hDb, SQL_viewMultiBhopRecordCallback2, szQuery, client,DBPrio_Low);
			}
		}
		else {
			g_js_MultiBhopRank[client] = 99999999;
			g_js_fPersonal_MultiBhop_Record[client] = -1.0;
		}
	}
	else {
		g_js_MultiBhopRank[client] = 99999999;
		g_js_fPersonal_MultiBhop_Record[client] = -1.0;
	}
}
public SQL_viewBhopRecordCallback2(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_js_BhopRank[client]= SQL_GetRowCount(hndl);
}
public SQL_viewBBhopRecordCallback2(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_js_BBhopRank[client]= SQL_GetRowCount(hndl);
}
public SQL_viewMultiBhopRecordCallback2(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_js_MultiBhopRank[client]= SQL_GetRowCount(hndl);
}
public SQL_viewBMultiBhopRecordCallback2(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_js_BMultiBhopRank[client]= SQL_GetRowCount(hndl);
}
//END SQL
//admin stuff
public Action Admin_DropPlayerJump(client, args) {
	db_dropPlayerJump(client);
	return Plugin_Handled;
}
public Action Admin_ResetAllLjRecords(client, args) {
	char szQuery[255];
	Format(szQuery, 255, "UPDATE playerjumpstats SET ljrecord=-1.0");
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "no bug lj records reset.");
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			g_js_LjRank[i] = 99999999;
			g_js_fPersonal_Lj_Record[i] = -1.0;
		}
	}
	return Plugin_Handled;
}
public Action Admin_BResetAllLjRecords(client, args) {
	char szQuery[255];
	Format(szQuery, 255, "UPDATE buggedplayerjumpstats SET ljrecord=-1.0");
	SQL_TQuery(g_hBDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "bugged lj records reset.");
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			g_js_BLjRank[i] = 99999999;
			g_js_fBuggedPersonal_Lj_Record[i] = -1.0;
		}
	}
	return Plugin_Handled;
}
public Action Admin_ResetAllWjRecords(client, args) {
	char szQuery[255];
	Format(szQuery, 255, "UPDATE playerjumpstats SET wjrecord=-1.0");
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "no bug wj records reset.");
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			g_js_WjRank[i] = 99999999;
			g_js_fPersonal_Wj_Record[i] = -1.0;
		}
	}
	return Plugin_Handled;
}
public Action Admin_BResetAllWjRecords(client, args) {
	char szQuery[255];
	Format(szQuery, 255, "UPDATE buggedplayerjumpstats SET wjrecord=-1.0");
	SQL_TQuery(g_hBDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "bugged wj records reset.");
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			g_js_BWjRank[i] = 99999999;
			g_js_fBuggedPersonal_Wj_Record[i] = -1.0;
		}
	}
	return Plugin_Handled;
}
public Action Admin_ResetAllBhopRecords(client, args) {
	char szQuery[255];
	Format(szQuery, 255, "UPDATE playerjumpstats SET bhoprecord=-1.0");
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "no bug bhop records reset.");
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			g_js_BhopRank[i] = 99999999;
			g_js_fPersonal_Bhop_Record[i] = -1.0;
		}
	}
	return Plugin_Handled;
}
public Action Admin_BResetAllBhopRecords(client, args) {
	char szQuery[255];
	Format(szQuery, 255, "UPDATE buggedplayerjumpstats SET bhoprecord=-1.0");
	SQL_TQuery(g_hBDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "bugged bhop records reset.");
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			g_js_BBhopRank[i] = 99999999;
			g_js_fBuggedPersonal_Bhop_Record[i] = -1.0;
		}
	}
	return Plugin_Handled;
}
public Action Admin_ResetAllDropBhopRecords(client, args) {
	char szQuery[255];
	Format(szQuery, 255, "UPDATE playerjumpstats SET dropbhoprecord=-1.0");
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "no bug dropbhop records reset.");
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			g_js_DropBhopRank[i] = 99999999;
			g_js_fPersonal_DropBhop_Record[i] = -1.0;
		}
	}
	return Plugin_Handled;
}
public Action Admin_BResetAllDropBhopRecords(client, args) {
	char szQuery[255];
	Format(szQuery, 255, "UPDATE buggedplayerjumpstats SET dropbhoprecord=-1.0");
	SQL_TQuery(g_hBDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "bugged dropbhop records reset.");
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			g_js_BDropBhopRank[i] = 99999999;
			g_js_fBuggedPersonal_DropBhop_Record[i] = -1.0;
		}
	}
	return Plugin_Handled;
}
public Action Admin_ResetAllMultiBhopRecords(client, args) {
	char szQuery[255];
	Format(szQuery, 255, "UPDATE playerjumpstats SET multibhoprecord=-1.0");
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "no bug multibhop records reset.");
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			g_js_MultiBhopRank[i] = 99999999;
			g_js_fPersonal_MultiBhop_Record[i] = -1.0;
		}
	}
	return Plugin_Handled;
}
public Action Admin_BResetAllMultiBhopRecords(client, args) {
	char szQuery[255];
	Format(szQuery, 255, "UPDATE buggedplayerjumpstats SET multibhoprecord=-1.0");
	SQL_TQuery(g_hBDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "bugged multibhop records reset.");
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			g_js_BMultiBhopRank[i] = 99999999;
			g_js_fBuggedPersonal_MultiBhop_Record[i] = -1.0;
		}
	}
	return Plugin_Handled;
}
public Action Admin_ResetAllLjBlockRecords(client, args) {
	char szQuery[255];
	Format(szQuery, 255, "UPDATE playerjumpstats SET ljblockdist=-1.0");
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "no bug ljblock records reset.");
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			g_js_MultiBhopRank[i] = 99999999;
			g_js_fPersonal_MultiBhop_Record[i] = -1.0;
		}
	}
	return Plugin_Handled;
}
public Action Admin_BResetAllLjBlockRecords(client, args) {
	char szQuery[255];
	Format(szQuery, 255, "UPDATE buggedplayerjumpstats SET ljblockdist=-1.0");
	SQL_TQuery(g_hBDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "bugged ljblock records reset.");
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			g_js_BMultiBhopRank[i] = 99999999;
			g_js_fBuggedPersonal_MultiBhop_Record[i] = -1.0;
		}
	}
	return Plugin_Handled;
}
public Action Admin_ResetLjRecords(client, args) {
	if(args == 0) {
		ReplyToCommand(client, "[JS] Usage: sm_resetljrecord <steamid>");
		return Plugin_Handled;
	}
	if(args > 0) {
		char szSteamID[128];
		char szArg[128];
		Format(szSteamID, 128, "");
		for (new i = 1; i < 6; i++) {
			GetCmdArg(i, szArg, 128);
			if(!StrEqual(szArg, "", false))
				Format(szSteamID, 128, "%s%s", szSteamID, szArg);
		}
		db_resetPlayerLjRecord(client, szSteamID);
	}
	return Plugin_Handled;
}
public Action Admin_BResetLjRecords(client, args) {
	if(args == 0) {
		ReplyToCommand(client, "[JS] Usage: sm_bugresetljrecord <steamid>");
		return Plugin_Handled;
	}
	if(args > 0) {
		char szSteamID[128];
		char szArg[128];
		Format(szSteamID, 128, "");
		for (new i = 1; i < 6; i++) {
			GetCmdArg(i, szArg, 128);
			if(!StrEqual(szArg, "", false))
				Format(szSteamID, 128, "%s%s", szSteamID, szArg);
		}
		db_BresetPlayerLjRecord(client, szSteamID);
	}
	return Plugin_Handled;
}
public Action Admin_ResetLjBlockRecords(client, args) {
	if(args == 0) {
		ReplyToCommand(client, "[JS] Usage: sm_resetljblockrecord <steamid>");
		return Plugin_Handled;
	}
	if(args > 0) {
		char szSteamID[128];
		char szArg[128];
		Format(szSteamID, 128, "");
		for (new i = 1; i < 6; i++) {
			GetCmdArg(i, szArg, 128);
			if(!StrEqual(szArg, "", false))
				Format(szSteamID, 128, "%s%s", szSteamID, szArg);
		}
		db_resetPlayerLjBlockRecord(client, szSteamID);
	}
	return Plugin_Handled;
}
public Action Admin_ResetWjRecords(client, args) {
	if(args == 0) {
		ReplyToCommand(client, "[JS] Usage: sm_resetwjrecord <steamid>");
		return Plugin_Handled;
	}
	if(args > 0) {
		char szSteamID[128];
		char szArg[128];
		Format(szSteamID, 128, "");
		for (new i = 1; i < 6; i++) {
			GetCmdArg(i, szArg, 128);
			if(!StrEqual(szArg, "", false))
				Format(szSteamID, 128, "%s%s", szSteamID, szArg);
		}
		db_resetPlayerWJRecord(client, szSteamID);
	}
	return Plugin_Handled;
}
public Action Admin_ResetPlayerJumpstats(client, args) {
	if(args == 0) {
		ReplyToCommand(client, "[JS] Usage: sm_resetplayerjumpstats <steamid>");
		return Plugin_Handled;
	}
	if(args > 0) {
		char szSteamID[128];
		char szArg[128];
		Format(szSteamID, 128, "");
		for (new i = 1; i < 6; i++) {
			GetCmdArg(i, szArg, 128);
			if(!StrEqual(szArg, "", false))
				Format(szSteamID, 128, "%s%s", szSteamID, szArg);
		}
		db_resetPlayerJumpstats(client, szSteamID);
	}
	return Plugin_Handled;
}
public Action Admin_ResetDropBhopRecords(client, args) {
	if(args == 0) {
		ReplyToCommand(client, "[JS] Usage: sm_resetdropbhoprecord <steamid>");
		return Plugin_Handled;
	}
	if(args > 0) {
		char szSteamID[128];
		char szArg[128];
		Format(szSteamID, 128, "");
		for (new i = 1; i < 6; i++) {
			GetCmdArg(i, szArg, 128);
			if(!StrEqual(szArg, "", false))
				Format(szSteamID, 128, "%s%s", szSteamID, szArg);
		}
		db_resetPlayerDropBhopRecord(client, szSteamID);
	}
	return Plugin_Handled;
}
public Action Admin_ResetBhopRecords(client, args) {
	if(args == 0) {
		ReplyToCommand(client, "[JS] Usage: sm_resetbhoprecord <steamid>");
		return Plugin_Handled;
	}
	if(args > 0) {
		char szSteamID[128];
		char szArg[128];
		Format(szSteamID, 128, "");
		for (new i = 1; i < 6; i++) {
			GetCmdArg(i, szArg, 128);
			if(!StrEqual(szArg, "", false))
				Format(szSteamID, 128, "%s%s", szSteamID, szArg);
		}
		db_resetPlayerBhopRecord(client, szSteamID);
	}
	return Plugin_Handled;
}
public Action Admin_ResetMultiBhopRecords(client, args) {
	if(args == 0) {
		ReplyToCommand(client, "[JS] Usage: sm_resetmultibhoprecord <steamid>");
		return Plugin_Handled;
	}
	if(args > 0) {
		char szSteamID[128];
		char szArg[128];
		Format(szSteamID, 128, "");
		for (new i = 1; i < 6; i++) {
			GetCmdArg(i, szArg, 128);
			if(!StrEqual(szArg, "", false))
				Format(szSteamID, 128, "%s%s", szSteamID, szArg);
		}
		db_resetPlayerMultiBhopRecord(client, szSteamID);
	}
	return Plugin_Handled;
}
public db_resetPlayerBhopRecord(client, char steamid[128]) {
	char szQuery[255];
	char szsteamid[128*2+1];
	SQL_EscapeString(g_hDb, steamid, szsteamid, 128*2+1);
	Format(szQuery, 255, sql_resetBhopRecord, szsteamid);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, steamid);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, pack);
	PrintToConsole(client, "nobug bhop record cleared (%s).", szsteamid);
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			char szSteamId2[32];
			GetClientAuthId(i, AuthId_Steam2, szSteamId2, sizeof(szSteamId2));
			if(StrEqual(szSteamId2,szsteamid)) {
				g_js_BhopRank[i] = 99999999;
				g_js_fPersonal_Bhop_Record[i] = -1.0;
			}
		}
	}
}
public db_resetPlayerDropBhopRecord(client, char steamid[128]) {
	char szQuery[255];
	char szsteamid[128*2+1];
	SQL_EscapeString(g_hDb, steamid, szsteamid, 128*2+1);
	Format(szQuery, 255, sql_resetDropBhopRecord, szsteamid);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, steamid);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, pack);
	PrintToConsole(client, "no bug dropbhop record cleared (%s).", szsteamid);
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			char szSteamId2[32];
			GetClientAuthId(i, AuthId_Steam2, szSteamId2, sizeof(szSteamId2));
			if(StrEqual(szSteamId2,szsteamid)) {
				g_js_DropBhopRank[i] = 99999999;
				g_js_fPersonal_DropBhop_Record[i] = -1.0;
			}
		}
	}
}
public db_resetPlayerWJRecord(client, char steamid[128]) {
	char szQuery[255];
	char szsteamid[128*2+1];
	SQL_EscapeString(g_hDb, steamid, szsteamid, 128*2+1);
	Format(szQuery, 255, sql_resetWJRecord, szsteamid);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, steamid);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, pack);
	PrintToConsole(client, "no bug wj record cleared (%s).", szsteamid);
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			char szSteamId2[32];
			GetClientAuthId(i, AuthId_Steam2, szSteamId2, sizeof(szSteamId2));
			if(StrEqual(szSteamId2,szsteamid)) {
				g_js_WjRank[i] = 99999999;
				g_js_fPersonal_Wj_Record[i] = -1.0;
			}
		}
	}
}
public db_resetPlayerJumpstats(client, char steamid[128]) {
	char szQuery[255];
	char szsteamid[128*2+1];
	SQL_EscapeString(g_hDb, steamid, szsteamid, 128*2+1);
	Format(szQuery, 255, sql_resetJumpStats, szsteamid);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, steamid);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, pack);
	PrintToConsole(client, "no bug jumpstats cleared (%s).", szsteamid);
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			char szSteamId2[32];
			GetClientAuthId(i, AuthId_Steam2, szSteamId2, sizeof(szSteamId2));
			if(StrEqual(szSteamId2,szsteamid)) {
				g_js_MultiBhopRank[i] = 99999999;
				g_js_fPersonal_MultiBhop_Record[i] = -1.0;
				g_js_WjRank[i] = 99999999;
				g_js_fPersonal_Wj_Record[i] = -1.0;
				g_js_DropBhopRank[i] = 99999999;
				g_js_fPersonal_DropBhop_Record[i] = -1.0;
				g_js_BhopRank[i] = 99999999;
				g_js_fPersonal_Bhop_Record[i] = -1.0;
				g_js_LjRank[i] = 99999999;
				g_js_fPersonal_Lj_Record[i] = -1.0;
			}
		}
	}
}
public db_resetPlayerMultiBhopRecord(client, char steamid[128]) {
	char szQuery[255];
	char szsteamid[128*2+1];
	SQL_EscapeString(g_hDb, steamid, szsteamid, 128*2+1);
	Format(szQuery, 255, sql_resetMultiBhopRecord, szsteamid);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, steamid);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, pack);
	PrintToConsole(client, "no bug multibhop record cleared (%s).", szsteamid);
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			char szSteamId2[32];
			GetClientAuthId(i, AuthId_Steam2, szSteamId2, sizeof(szSteamId2));
			if(StrEqual(szSteamId2,szsteamid)) {
				g_js_MultiBhopRank[i] = 99999999;
				g_js_fPersonal_MultiBhop_Record[i] = -1.0;
			}
		}
	}
}
public db_resetPlayerLjRecord(client, char steamid[128]) {
	char szQuery[255];
	char szsteamid[128*2+1];
	SQL_EscapeString(g_hDb, steamid, szsteamid, 128*2+1);
	Format(szQuery, 255, sql_resetLjRecord, szsteamid);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, steamid);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, pack);
	PrintToConsole(client, "no bug lj record cleared (%s).", szsteamid);
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			char szSteamId2[32];
			GetClientAuthId(i, AuthId_Steam2, szSteamId2, sizeof(szSteamId2));
			if(StrEqual(szSteamId2,szsteamid)) {
				g_js_LjRank[i] = 99999999;
				g_js_fPersonal_Lj_Record[i] = -1.0;
			}
		}
	}
}
public db_BresetPlayerLjRecord(client, char steamid[128]) {
	char szQuery[255];
	char szsteamid[128*2+1];
	SQL_EscapeString(g_hBDb, steamid, szsteamid, 128*2+1);
	Format(szQuery, 255, sql_BresetLjRecord, szsteamid);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, steamid);
	SQL_TQuery(g_hBDb, SQL_CheckCallback, szQuery, pack);
	PrintToConsole(client, "bugged lj record cleared (%s).", szsteamid);
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			char szSteamId2[32];
			GetClientAuthId(i, AuthId_Steam2, szSteamId2, sizeof(szSteamId2));
			if(StrEqual(szSteamId2,szsteamid)) {
				g_js_BLjRank[i] = 99999999;
				g_js_fBuggedPersonal_Lj_Record[i] = -1.0;
			}
		}
	}
}
public db_resetPlayerLjBlockRecord(client, char steamid[128]) {
	char szQuery[255];
	char szsteamid[128*2+1];
	SQL_EscapeString(g_hDb, steamid, szsteamid, 128*2+1);
	Format(szQuery, 255, sql_resetLjBlockRecord, szsteamid);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, steamid);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, pack);
	PrintToConsole(client, "no bug ljblock record cleared (%s).", szsteamid);
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			char szSteamId2[32];
			GetClientAuthId(i, AuthId_Steam2, szSteamId2, sizeof(szSteamId2));
			if(StrEqual(szSteamId2,szsteamid)) {
				g_js_LjBlockRank[i] = 99999999;
				g_js_Personal_LjBlock_Record[i] = -1;
			}
		}
	}
}
public db_dropPlayerJump(client) {
	char szQuery[255];
	Format(szQuery, 255, "UPDATE playerjumpstats SET wjrecord=-1.0,bhoprecord=-1.0,ljblockrecord=-1.0,ljrecord=-1.0,dropbhoprecord=-1.0,multibhoprecord=-1.0");
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "no bug jumpstats records reset.");
	for (new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			g_js_LjRank[i] = 99999999;
			g_js_fPersonal_Lj_Record[i] = -1.0;
			g_js_LjBlockRank[i] = 99999999;
			g_js_fPersonal_LjBlockRecord_Dist[i] = -1.0;
			g_js_WjRank[i] = 99999999;
			g_js_fPersonal_Wj_Record[i] = -1.0;
			g_js_BhopRank[i] = 99999999;
			g_js_fPersonal_Bhop_Record[i] = -1.0;
			g_js_DropBhopRank[i] = 99999999;
			g_js_fPersonal_DropBhop_Record[i] = -1.0;
			g_js_MultiBhopRank[i] = 99999999;
			g_js_fPersonal_MultiBhop_Record[i] = -1.0;
		}
	}
}
//Distbug Things
public Action Command_Distbug(int client, int args) {
	g_db_iDistbug[client] = g_db_iDistbug[client] == 1 ? 0 : 1;
	CPrintToChat(client, "%s Distbug has been %s", PREFIX, g_db_iDistbug[client] ? "enabled. Type !strafestats to turn strafestats off." : "disabled.");
	char sCookie[128];
	IntToString(g_db_iDistbug[client], sCookie, sizeof(sCookie));
	SetClientCookie(client, g_db_hDistbug, sCookie);
	return Plugin_Handled;
}
public Action Command_StrafeStats(int client, int args) {
	if(g_db_iDistbug[client] == 1) {
		g_db_iStrafeStats[client] = g_db_iStrafeStats[client] == 1 ? 0 : 1;
		CPrintToChat(client, "%s Strafe stats have been %s.", PREFIX, g_db_iStrafeStats[client] ? "turned on" : "turned off");
		char sCookie[128];
		IntToString(g_db_iStrafeStats[client], sCookie, sizeof(sCookie));
		SetClientCookie(client, g_db_hStrafeStats, sCookie);
	}
	return Plugin_Handled;
}
// var setter
void ResetStatStrafeVars(int client) {
	for (int i = 0; i < MAXSTRAFES; i++) {
		g_db_fStatStrafeGain[client][i] = 0.0;
		g_db_fStatStrafeLoss[client][i] = 0.0;
		g_db_fStatStrafeMax[client][i] = 0.0;
		g_db_fStatStrafeSync[client][i] = 0.0;
		g_db_fStatStrafeAirtime[client][i] = 0.0;
		g_db_iStatStrafeOverlap[client][i] = 0;
		g_db_iStatStrafeDead[client][i] = 0;
	}
	g_db_iStatStrafeCount[client] = 0;
	g_db_iStatSync[client] = 0;
}
// set vars
void SetFailStatVars(int client) {
	if(!IsFailstat(g_db_fPosition[client][2], g_db_fJumpPosition[client][2], -g_db_fVelocity[client][2] / g_db_fTickRate + 1.0))
		return;
	g_db_fFailStatStrafeGain[client] = g_db_fStatStrafeGain[client];
	g_db_fFailStatStrafeLoss[client] = g_db_fStatStrafeLoss[client];
	g_db_fFailStatStrafeMax[client] = g_db_fStatStrafeMax[client];
	g_db_fFailStatStrafeSync[client] = g_db_fStatStrafeSync[client];
	g_db_fFailStatStrafeAirtime[client] = g_db_fStatStrafeAirtime[client];
	g_db_fFailPos[client] = g_db_fPosition[client];
	g_db_fFailVelocity[client] = g_db_fVelocity[client];
	g_db_iFailStatSync[client] = g_db_iStatSync[client];
	g_db_iFailStatStrafeOverlap[client] = g_db_iStatStrafeOverlap[client];
	g_db_iFailStatStrafeDead[client] = g_db_iStatStrafeDead[client];
	g_db_iFailStatStrafeCount[client] = g_db_iStatStrafeCount[client];
	g_db_iFailAirTime[client] = g_db_iFramesInAir[client];
	g_db_iFailDeadAirTime[client] = g_db_iDeadAirtime[client];
	g_db_iFailOverlap[client] = g_db_iFramesOverlapped[client];
}
// important
void OnPlayerInAir(int client, int &buttons, float vel[3]) {
	g_db_iFramesOnGround[client] = 0;
	g_db_iFramesInAir[client]++;
	if(!g_db_bValidJump[client])
		return;
	if(IsFailstat(g_db_fPosition[client][2], g_db_fJumpPosition[client][2], -g_db_fVelocity[client][2] / g_db_fTickRate + 1.0)) {
		float angles[3];
		GetClientAbsAngles(client, angles);
	}
	float speed = GetVectorHorLength(g_db_fVelocity[client]);
	float lastspeed = GetVectorHorLength(g_db_fLastVelocity[client]);
	if(IsOverlapping(buttons))
		g_db_iFramesOverlapped[client]++;
	if(IsDeadAirtime(buttons))
		g_db_iDeadAirtime[client]++;
	if(IsStrafeSynced(speed, lastspeed))
		g_db_iStatSync[client]++;
	CheckMaxHeight(client);
	CheckStrafeStats(client, buttons, vel, speed, lastspeed);
	SetFailStatVars(client);
	g_db_fLastLastPosInAir[client] = g_db_fLastPosInAir[client];
	g_db_fLastVelocityInAir[client] = g_db_fVelocity[client];
	g_db_fLastPosInAir[client] = g_db_fPosition[client];
	g_db_fLastVelInAir[client] = vel;
}

void OnJumpLand(int client) {
	if(GetClientTeam(client) == CS_TEAM_CT && g_iCTDistbugStats == 1)
		return;
	float fOffset = GetOffset(client, false);
	if(fOffset > EPSILON)
		return;
	float fBlockDist = GetBlockDist(client, g_db_fPosition[client], g_db_fJumpPosition[client]);
	// jump start strings
	char szJumpHeight[32];
	FormatHeight(client, szJumpHeight, sizeof(szJumpHeight));
	char szWRelease[32];
	FormatWRelease(client, szWRelease, sizeof(szWRelease));
	char szEdge[32];
	FormatEdge(client, szEdge, sizeof(szEdge));
	if(fOffset < -EPSILON) {
		float failDist = CalcFailDistance(g_db_fJumpPosition[client], g_db_fFailPos[client], g_db_fFailVelocity[client]);
		if(g_db_fMinJumpDistance <= failDist <= g_db_fMaxJumpDistance) {
			char szFailDist[64];
			FormatFailDist(szFailDist, sizeof(szFailDist), failDist);
			char szAirtime[32];
			FormatAirtime(szAirtime, sizeof(szAirtime), g_db_iFailAirTime[client]);
			char szSync[32];
			FormatSync(szSync, sizeof(szSync), g_db_iFailStatSync[client], g_db_iFailAirTime[client]);
			char szBlockdist[32];
			FormatBlockDistance(szBlockdist, sizeof(szBlockdist), fBlockDist);
			char szOverlap[32];
			FormatOverlap(szOverlap, sizeof(szOverlap), g_db_iFramesOverlapped[client]);
			char szDeadAirtime[32];
			FormatDeadAirtime(szDeadAirtime, sizeof(szDeadAirtime), g_db_iDeadAirtime[client]);
			PrintFailStat(client, szFailDist, szEdge, szBlockdist, szJumpHeight, szSync, szAirtime, szWRelease, szOverlap, szDeadAirtime);
		}
	}
	else {
		float distance = CalcJumpDistance(client);
		if(g_db_fMinJumpDistance <= distance <= g_db_fMaxJumpDistance) {
			char szDist[32];
			FormatDist(szDist, sizeof(szDist), distance);
			char szAirtime[32];
			FormatAirtime(szAirtime, sizeof(szAirtime), g_db_iFramesInAir[client]);
			char szSync[32];
			FormatSync(szSync, sizeof(szSync), g_db_iStatSync[client], g_db_iFramesInAir[client]);
			char szBlockdist[32];
			FormatBlockDistance(szBlockdist, sizeof(szBlockdist), fBlockDist);
			char szOverlap[32];
			FormatOverlap(szOverlap, sizeof(szOverlap), g_db_iFramesOverlapped[client]);
			char szDeadAirtime[32];
			FormatDeadAirtime(szDeadAirtime, sizeof(szDeadAirtime), g_db_iDeadAirtime[client]);
			PrintJumpstat(client, szDist, szEdge, szBlockdist, szJumpHeight, szSync, szAirtime, szWRelease, szOverlap, szDeadAirtime);
		}
	}
	g_db_bValidJump[client] = false;
}
//Get z offset of current jump
float GetOffset(int client, bool optimised = true) {
	float jumpground[3];
	float landground[3];
	TraceGround(client, g_db_fJumpPosition[client], jumpground);
	if(optimised)
		TraceGround(client, g_db_fPosition[client], landground);
	else {
		float tempPos[3];
		float tickGravity;
		tempPos = g_db_fPosition[client];
		if(!IsFloatInRange(g_db_fPosition[client][2] - g_db_fJumpPosition[client][2], -EPSILON, EPSILON)) {
			tickGravity = g_db_fTickGravity;
			tempPos = g_db_fLastPosInAir[client];
		}
		TraceLandPos(client, tempPos, g_db_fLastVelocity[client], landground, tickGravity);
	}
	return landground[2] - jumpground[2];
}
float GetBlockDist(int client, float position[3], float jumpPosition[3]) {
	float blockdist;
	float endEdge[3];
	float startEdge[3];
	int blockDir = BlockDirection(jumpPosition, position);
	float pos2[3];
	position[2] = jumpPosition[2];
	pos2 = position;
	pos2[2] = jumpPosition[2] + 1.0;
	pos2[blockDir] += (jumpPosition[blockDir] - position[blockDir]) / 2.0;
	g_db_bBlock[client] = TraceBlock(pos2, jumpPosition, startEdge);
	pos2 = jumpPosition;
	pos2[2] += 1.0;
	pos2[blockDir] += (position[blockDir] - jumpPosition[blockDir]) / 2.0;
	g_db_bBlock[client] = TraceBlock(pos2, position, endEdge);
	blockdist = FloatAbs(endEdge[blockDir] - startEdge[blockDir]) + 32.0625;
	if(startEdge[blockDir] - pos2[blockDir] != 0.0)
		g_db_fJEdge[client] = FloatAbs(jumpPosition[blockDir] - RoundFloat(startEdge[blockDir]));
	else
		g_db_fJEdge[client] = -1.0;
	return blockdist;
}
// calculator
float CalcFailDistance(float jumpPosition[3], float position[3], float velocity[3]) {
	float linePoint[3];
	float lineDirection[3];
	float planePoint[3];
	float planeNormal[3];
	float realLandingPos[3];
	linePoint = position;
	lineDirection = velocity;
	planePoint = jumpPosition;
	planeNormal[2] = 1.0;
	lineIntersection(planePoint, planeNormal, linePoint, lineDirection, realLandingPos);
	return GetVectorHorDistance(jumpPosition, realLandingPos) + 32.0;
}
// calculator
float CalcJumpDistance(int client) {
	float realLandPos[3];
	// is jump bugged?
	if(!IsOffset(g_db_fPosition[client][2], g_db_fJumpPosition[client][2], EPSILON)) {
		if(TraceLandPos(client, g_db_fLastPosInAir[client], g_db_fLastVelocity[client], realLandPos, g_db_fTickGravity))
			return GetVectorHorDistance(g_db_fJumpPosition[client], realLandPos) + 32.0;
	}
	if(TraceLandPos(client, g_db_fPosition[client], g_db_fLastVelocity[client], realLandPos, 0.0))
		return GetVectorHorDistance(g_db_fJumpPosition[client], realLandPos) + 32.0;
	return -1.0;
}
void PrintFailStat(int client, char[] szDist, char[] szEdge, char[] szBlockdist, char[] szJumpHeight, char[] szSync, char[] szAirtime, char[] szWRelease, char[] szOverlap, char[] szDeadAirtime) {
	if(g_db_iDistbug[client] == 1) {
		char chatOutput[256];
		FormatEx(chatOutput, sizeof(chatOutput), "%s{grey} %s %s%s[ %s | %s | %s | %s | %s | %s ]",
				PREFIX, szDist, szEdge, szBlockdist, szJumpHeight, szSync, szAirtime, szWRelease, szOverlap, szDeadAirtime);
		CPrintToChat(client, chatOutput);
		char conOutput[256];
		strcopy(conOutput, sizeof(conOutput), chatOutput);
		CRemoveTags(conOutput, sizeof(conOutput));
		PrintToConsole(client, conOutput);
		EchoToSpectators(client, conOutput, chatOutput);
		if(g_db_iStrafeStats[client] == 1) {
			PrintStrafeStats(client, g_db_fFailStatStrafeGain[client],
				g_db_fFailStatStrafeLoss[client], g_db_fFailStatStrafeMax[client],
				g_db_fFailStatStrafeSync[client], g_db_fFailStatStrafeAirtime[client],
				g_db_iFailAirTime[client], g_db_iFailStatStrafeOverlap[client],
				g_db_iFailStatStrafeDead[client], g_db_iFailStatStrafeCount[client]);
		}
	}
}
void PrintJumpstat(int client, char[] szDist, char[] szEdge, char[] szBlockdist, char[] szJumpHeight, char[] szSync, char[] szAirtime, char[] szWRelease, char[] szOverlap, char[] szDeadAirtime) {
	if(g_db_iDistbug[client] == 1) {
		char chatOutput[256];
		FormatEx(chatOutput, sizeof(chatOutput), "%s{grey} %s %s%s[ %s | %s | %s | %s | %s | %s ]",
				PREFIX, szDist, szEdge, szBlockdist, szJumpHeight, szSync, szAirtime, szWRelease, szOverlap, szDeadAirtime);
		CPrintToChat(client, chatOutput);
		char conOutput[256];
		strcopy(conOutput, sizeof(conOutput), chatOutput);
		CRemoveTags(conOutput, sizeof(conOutput));
		PrintToConsole(client, conOutput);
		EchoToSpectators(client, conOutput, chatOutput);
		if(g_db_iStrafeStats[client] == 1) {
			PrintStrafeStats(client,
				g_db_fStatStrafeGain[client],
				g_db_fStatStrafeLoss[client],
				g_db_fStatStrafeMax[client],
				g_db_fStatStrafeSync[client],
				g_db_fStatStrafeAirtime[client],
				g_db_iFramesInAir[client],
				g_db_iStatStrafeOverlap[client],
				g_db_iStatStrafeDead[client],
				g_db_iStatStrafeCount[client]);
		}
	}
}
void PrintStrafeStats(int client, float gain[MAXSTRAFES], float loss[MAXSTRAFES], float max[MAXSTRAFES], float strafeSync[MAXSTRAFES], float strafeAirtime[MAXSTRAFES], int jumpAirtime, int overlap[MAXSTRAFES], int deadAirtime[MAXSTRAFES], int strafeCount) {
	char strafeStats[2048];
	if(g_db_iDistbug[client] == 1) {
		float sync;
		float airtime;
		FormatEx(strafeStats, sizeof(strafeStats), "#.    Sync    Gain    Loss      Max   Airtime  OL  DA\n");
		for (int i = 1; i <= strafeCount && i < MAXSTRAFES; i++) {
			char szSync[16];
			char szGain[16];
			char szLoss[16];
			char szMax[16];
			char szAirtime[16];
			char szOverlap[16];
			char szDead[16];
			airtime = strafeAirtime[i] / jumpAirtime * 100.0;
			sync = strafeSync[i] / strafeAirtime[i] * 100;
			FormatEx(szSync, sizeof(szSync), "%5.1f", sync);
			FormatEx(szGain, sizeof(szGain), "%6.2f", gain[i]);
			FormatEx(szLoss, sizeof(szLoss), "%6.2f", loss[i]);
			FormatEx(szMax, sizeof(szMax), "%5.1f", max[i]);
			FormatEx(szAirtime, sizeof(szAirtime), "%7.1f", airtime);
			FormatEx(szOverlap, sizeof(szOverlap), "%3i", overlap[i]);
			FormatEx(szDead, sizeof(szDead), "%3i", deadAirtime[i]);
			Format(strafeStats, sizeof(strafeStats), "%s%i.  %s%s  %s  %s    %s  %s%s %s %s\n",
				strafeStats, i, szSync, PERCENT, szGain, szLoss, szMax, szAirtime, PERCENT, szOverlap, szDead);
		}
		PrintToConsole(client, strafeStats);
	}
	EchoToSpectators(client, strafeStats, NULL_STRING);
}
void EchoToSpectators(int client, const char[] conOutput, const char[] chatOutput) {
	if(IsNullString(conOutput) && IsNullString(chatOutput))
		return;
	for (int i = 1; i <= MaxClients; i++) {
		if(i == client || !IsValidClient(i) || !IsClientObserver(i))
			continue;
		// Check if spectating client
		if(GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") != client)
			continue;
		int specMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
		// 4 = 1st person, 5 = 3rd person
		if(specMode != 4 && specMode != 5)
			continue;
		if(!IsNullString(conOutput))
			PrintToConsole(i, conOutput);
		if(!IsNullString(chatOutput))
			CPrintToChat(i, "%s", chatOutput);
	}
}
// formatting
void FormatFailDist(char[] buffer, int maxlen, float distance) {
	FormatEx(buffer, maxlen, "FAILED: {default}%.4f{grey}", distance);
}
void FormatDist(char[] buffer, int maxlen, float distance) {
	FormatEx(buffer, maxlen, "LJ: {default}%.4f{grey}", distance);
}
void FormatAirtime(char[] buffer, int maxlen, int airTime) {
	FormatEx(buffer, maxlen, "Air: {lime}%i{grey}", airTime);
}
void FormatSync(char[] buffer, int maxlen, int iSync, int airTime) {
	float sync = (iSync + 0.0) / (airTime + 0.0) * 100.0;
	FormatEx(buffer, maxlen, "Sync: %.1f%%%", sync);
}
void FormatHeight(int client, char[] buffer, int maxlen) {
	float jumpHeight = g_db_fMaxHeight[client] - g_db_fJumpPosition[client][2];
	FormatEx(buffer, maxlen, "Height: {lime}%.2f{grey}", jumpHeight);
}
void FormatWRelease(int client, char[] buffer, int maxlen) {
	// calculate w release
	int iWRelease = g_db_iWReleaseFrame[client] - g_db_iJumpFrame[client];
	// format w release
	if(iWRelease == 0)
		FormatEx(buffer, maxlen, "-W: {green}✓{grey}");
	else if(abs(iWRelease) > 16)
		FormatEx(buffer, maxlen, "-W: {grey}No{grey}");
	else if(iWRelease > 0)
		FormatEx(buffer, maxlen, "-W: {darkred}+%i{grey}", iWRelease);
	else
		FormatEx(buffer, maxlen, "-W: \x0A%i{grey}", iWRelease);
}
void FormatBlockDistance(char[] buffer, int maxlen, float fBlockDist) {
	if(IsFloatInRange(fBlockDist, g_db_fMinJumpDistance, g_db_fMaxJumpDistance))
		FormatEx(buffer, maxlen, "| Block: {default}%i{grey} ", RoundFloat(fBlockDist));
}
void FormatEdge(int client, char[] buffer, int maxlen) {
	if(g_db_fJEdge[client] >= 0.0 && g_db_fJEdge[client] < MAXEDGE)
		FormatEx(buffer, maxlen, "| Edge: {default}%.3f{grey} ", g_db_fJEdge[client]);
}
void FormatOverlap(char[] buffer, int maxlen, int overlap) {
	FormatEx(buffer, maxlen, "OL: {lime}%i{grey}", overlap);
}
void FormatDeadAirtime(char[] buffer, maxlen, int deadAirtime) {
	FormatEx(buffer, maxlen, "DA: {lime}%i{grey}", deadAirtime);
}
void CheckMaxHeight(int client) {
	float fHeightOrigin[3];
	fHeightOrigin = g_db_fPosition[client];
	if(GetEntityFlags(client) & FL_DUCKING)
		// make height not affected by ducking
		fHeightOrigin[2] -= 9.0
	if(fHeightOrigin[2] > g_db_fMaxHeight[client])
		g_db_fMaxHeight[client] = fHeightOrigin[2];
}
void IncStrafeCount(int client, float vel[3]) {
	if((vel[1] > 0.0 && g_db_fLastVelInAir[client][1] <= 0.0) || (vel[1] < 0.0 && g_db_fLastVelInAir[client][1] >= 0.0))
		g_db_iStatStrafeCount[client]++;
}
void CheckStrafeStats(int client, int &buttons, float vel[3], float speed, float lastspeed) {
	IncStrafeCount(client, vel);
	if(g_db_iStatStrafeCount[client] >= MAXSTRAFES)
		return;
	int strafe = g_db_iStatStrafeCount[client];
	g_db_fStatStrafeAirtime[client][strafe] += 1.0;
	if(CheckMaxSpeed(speed, lastspeed))
		g_db_fStatStrafeMax[client][strafe] = speed;
	if(IsOverlapping(buttons))
		g_db_iStatStrafeOverlap[client][strafe]++;
	else if(IsDeadAirtime(buttons))
		g_db_iStatStrafeDead[client][strafe]++;
	if(IsStrafeSynced(speed, lastspeed)) {
		g_db_fStatStrafeGain[client][strafe] += speed - lastspeed;
		g_db_fStatStrafeSync[client][strafe] += 1.0;
	}
	else
		g_db_fStatStrafeLoss[client][strafe] += lastspeed - speed;
}
stock void lineIntersection(float planePoint[3], float planeNormal[3], float linePoint[3], float lineDirection[3], float result[3]) {
	if(GetVectorDotProduct(planeNormal, lineDirection) == 0)
		return;
	float t = (GetVectorDotProduct(planeNormal, planePoint)
			 - GetVectorDotProduct(planeNormal, linePoint))
			 / GetVectorDotProduct(planeNormal, lineDirection);
	ScaleVector(lineDirection, t);
	AddVectors(linePoint, lineDirection, result);
}
stock bool TraceLandPos(int client, float pos[3], float velocity[3], float result[3], float tickGravity) {
	float mins[3];
	float maxs[3];
	float pos2[3];
	AddVectors(pos, velocity, pos2);
	velocity[2] -= tickGravity;
	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);
	Handle trace = TR_TraceHullFilterEx(pos, pos2, mins, maxs, MASK_PLAYERSOLID, TraceEntityFilterPlayer);
	if(!TR_DidHit(trace)) {
		CloseHandle(trace);
		return false;
	}
	TR_GetEndPosition(result, trace);
	CloseHandle(trace);
	return true;
}
stock int BlockDirection(float jumpoff[3], float position[3]) {
	return FloatAbs(position[1] - jumpoff[1]) > FloatAbs(position[0] - jumpoff[0]);
}
stock void TraceGround(int client, float pos[3], float result[3]) {
	float mins[3];
	float maxs[3];
	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);
	float startpos[3];
	float endpos[3];
	startpos = pos;
	endpos = pos;
	startpos[2]++;
	endpos[2]--;
	Handle trace = TR_TraceHullFilterEx(startpos, endpos, mins, maxs, MASK_PLAYERSOLID, TraceEntityFilterPlayer);
	if(TR_DidHit(trace))
		TR_GetEndPosition(result, trace);
	CloseHandle(trace);
}
stock bool TraceBlock(float pos2[3], float position[3], float result[3]) {
	float mins[3] = { -16.0, -16.0, -1.0 };
	float maxs[3] = { 16.0, 16.0, 0.0 };
	Handle trace = TR_TraceHullFilterEx(pos2, position, mins, maxs, MASK_PLAYERSOLID, TraceEntityFilterPlayer);
	if(!TR_DidHit(trace)) {
		CloseHandle(trace);
		return false;
	}
	TR_GetEndPosition(result, trace);
	CloseHandle(trace);
	return true;
}
stock bool IsOffset(float z1, float z2, float tolerance) {
	return (FloatAbs(z1 - z2) > tolerance);
}
stock float GetVectorHorLength(const float vec[3]) {
	float tempVec[3];
	tempVec = vec;
	tempVec[2] = 0.0;
	return GetVectorLength(tempVec);
}
stock float GetVectorHorDistance(float x[3], float y[3]) {
	float x2[3];
	float y2[3];
	x2 = x;
	y2 = y;
	x2[2] = 0.0;
	y2[2] = 0.0;
	return GetVectorDistance(x2, y2);
}
stock int abs(x) {
	return x >= 0 ? x : -x;
}
stock bool IsOverlapping(int &buttons) {
	return buttons & IN_MOVERIGHT && buttons & IN_MOVELEFT
}
stock bool IsStrafeSynced(float speed, float lastspeed) {
	return speed > lastspeed;
}
stock bool IsDeadAirtime(int &buttons) {
	return !(buttons & IN_MOVERIGHT) && !(buttons & IN_MOVELEFT);
}
stock bool CheckMaxSpeed(float speed, float lastspeed) {
	return speed > lastspeed;
}
stock bool IsFailstat(float z1, float z2, float tolerance) {
	return z1 < z2 && z1 > z2 - tolerance;
}
stock bool IsFloatInRange(float distance, float min, float max) {
	return distance >= min && distance <= max;
}
public float NormaliseAngle(float angle) {
	while (angle <= -180.0)
		angle += 360.0;
	while (angle > 180.0)
		angle -= 360.0;
	return angle;
}
