#pragma semicolon 1
// AutoT - AutoTrigger Detection
// CommandProtect - Command Protection
// CvarP - Cvar Protection
// Eye - Eye Angles Test
// Rcon - Rcon Protection
// Speed - Anti Speedhack
#include <sourcemod>
//AutoT
#include <sdktools>
#define TRIGGER_DETECTIONS	20 // Amount of detections needed to perform action.
#define METHOD_BUNNYHOP		0
#define METHOD_AUTOFIRE1	1
#define METHOD_AUTOFIRE2	2
#define METHOD_MAX			3
//AutoT
#include <smac>
#include <colors>
#undef REQUIRE_PLUGIN
#include <updater>

//AutoT
new Handle:g_hCvarBan = INVALID_HANDLE;
new g_iDetections[METHOD_MAX][MAXPLAYERS+1];
new g_iAttackMax = 66;
//AutoT

//CvarP
// Array Index Documentation
// Arrays that come from g_hCVars are index like below.
// 1. CVar Name
// 2. Comparison Type
// 3. CVar Handle - If this is defined then the engine will ignore the Comparison Type and Values as this should be only for FCVAR_REPLICATED CVars.
// 4. Action Type - Determines what action the engine takes.
// 5. Value - The value that the cvar is expected to have.
// 6. Value 2 - Only used as the high bound for COMP_BOUND.
// 7. Important - Defines the importance of the CVar in the ordering of the checks.
// 8. Was Changed - Defines if this CVar was changed recently.
#define CELL_NAME	0
#define CELL_COMPTYPE	1
#define CELL_HANDLE	2
#define CELL_ACTION	3
#define CELL_VALUE	4
#define CELL_VALUE2	5
#define CELL_ALT	6
#define CELL_PRIORITY	7
#define CELL_CHANGED	8
#define ACTION_WARN	0 // Warn Admins
#define ACTION_MOTD	1 // Display MOTD with Alternate URL
#define ACTION_MUTE	2 // Mute the player.
#define ACTION_KICK	3 // Kick the player.
#define ACTION_BAN	4 // Ban the player.
#define COMP_EQUAL	0 // CVar should equal
#define COMP_GREATER	1 // CVar should be equal to or greater than
#define COMP_LESS	2 // CVar should be equal to or less than
#define COMP_BOUND	3 // CVar should be in-between two numbers.
#define COMP_STRING	4 // Cvar should string equal.
#define COMP_NONEXIST	5 // CVar shouldn't exist.
#define PRIORITY_NORMAL	0
#define PRIORITY_MEDIUM	1
#define PRIORITY_HIGH	3
//CvarP

public Plugin:myinfo =
{
	name = "Anti-Flood",
	author = "AlliedModders LLC",
	description = "",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

enum IrcChannel
{
	IrcChannel_Public  = 1,
	IrcChannel_Private = 2,
	IrcChannel_Both    = 3
}

native SBBanPlayer(client, target, time, String:reason[]);
native IRC_MsgFlaggedChannels(const String:flag[], const String:format[], any:...);
native IRC_Broadcast(IrcChannel:type, const String:format[], any:...);

new GameType:g_Game = Game_Unknown;
new Handle:g_hCvarWelcomeMsg = INVALID_HANDLE;
new Handle:g_hCvarBanDuration = INVALID_HANDLE;
new String:g_sLogPath[PLATFORM_MAX_PATH];

/* Plugin Functions */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Detect game.
	decl String:sGame[64];
	GetGameFolderName(sGame, sizeof(sGame));

	if (StrEqual(sGame, "cstrike") || StrEqual(sGame, "cstrike_beta"))
		g_Game = Game_CSS;
	else if (StrEqual(sGame, "tf") || StrEqual(sGame, "tf_beta"))
		g_Game = Game_TF2;
	else if (StrEqual(sGame, "dod"))
		g_Game = Game_DODS;
	else if (StrEqual(sGame, "insurgency"))
		g_Game = Game_INSMOD;
	else if (StrEqual(sGame, "left4dead"))
		g_Game = Game_L4D;
	else if (StrEqual(sGame, "left4dead2"))
		g_Game = Game_L4D2;
	else if (StrEqual(sGame, "hl2mp"))
		g_Game = Game_HL2DM;
	else if (StrEqual(sGame, "fistful_of_frags"))
		g_Game = Game_FOF;
	else if (StrEqual(sGame, "garrysmod"))
		g_Game = Game_GMOD;
	else if (StrEqual(sGame, "hl2ctf"))
		g_Game = Game_HL2CTF;
	else if (StrEqual(sGame, "hidden"))
		g_Game = Game_HIDDEN;
	
	// Path used for logging.
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/SMAC.log");
	
	// Optional dependencies.
	MarkNativeAsOptional("SBBanPlayer");
	MarkNativeAsOptional("IRC_MsgFlaggedChannels");
	MarkNativeAsOptional("IRC_Broadcast");
	
	API_Init();
	RegPluginLibrary("smac");
	
	return APLRes_Success;
}

//Rcon
new Handle:g_hCvarRconPass = INVALID_HANDLE;
new String:g_sRconRealPass[128];
new bool:g_bRconLocked = false;
//Rcon

//Eye
new Float:g_fDetectedTime[MAXPLAYERS+1];
//Eye

// CommandProtect
new Handle:g_hBlockedCmds = INVALID_HANDLE;
new Handle:g_hIgnoredCmds = INVALID_HANDLE;
new g_iCmdSpam = 30;
new g_iCmdCount[MAXPLAYERS+1] = {0, ...};
new Handle:g_hCvarCmdSpam = INVALID_HANDLE;
// CommandProtect

//CvarP
new Handle:g_hCVars = INVALID_HANDLE;
new Handle:g_hCVarIndex = INVALID_HANDLE;
new Handle:g_hCurrentQuery[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:g_hReplyTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:g_hPeriodicTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new String:g_sQueryResult[][] = {"Okay", "Not found", "Not valid", "Protected"};
new g_iCurrentIndex[MAXPLAYERS+1] = {0, ...};
new g_iRetryAttempts[MAXPLAYERS+1] = {0, ...};
new g_iSize = 0;
new bool:g_bMapStarted = false;
//CvarP

//Speed
new Handle:g_hCvarFutureTicks = INVALID_HANDLE;
new g_iTickCount[MAXPLAYERS+1];
new g_iTickRate;
//Speed

public OnPluginStart()
{
	LoadTranslations("smac.phrases");
	
//Speed
	g_hCvarFutureTicks = FindConVar("sv_max_usercmd_future_ticks");
	
	if (g_hCvarFutureTicks != INVALID_HANDLE)
	{
		OnTickCvarChanged(g_hCvarFutureTicks, "", "");
		HookConVarChange(g_hCvarFutureTicks, OnTickCvarChanged);
	}
	
	// The server's tickrate * 1.5 as a buffer zone.
	g_iTickRate = RoundToCeil(1.0 / GetTickInterval() * 1.5);
	CreateTimer(1.0, Timer_ResetTicks, _, TIMER_REPEAT);
//Speed
	
//Rcon
	g_hCvarRconPass = FindConVar("rcon_password");
	HookConVarChange(g_hCvarRconPass, OnRconPassChanged);

	if (GuessSDKVersion() != SOURCE_SDK_EPISODE2VALVE)
	{
		new Handle:hConVar = INVALID_HANDLE;
		
		hConVar = FindConVar("sv_rcon_minfailuretime");
		if (hConVar != INVALID_HANDLE)
		{
			SetConVarBounds(hConVar, ConVarBound_Upper, true, 1.0);
			SetConVarInt(hConVar, 1); // Setting this so we don't track these failures longer than we need to. - Kigen
		}

		hConVar = FindConVar("sv_rcon_minfailures");
		if (hConVar != INVALID_HANDLE)
		{
			SetConVarBounds(hConVar, ConVarBound_Upper, true, 9999999.0);
			SetConVarBounds(hConVar, ConVarBound_Lower, true, 9999999.0);
			SetConVarInt(hConVar, 9999999);
		}

		hConVar = FindConVar("sv_rcon_maxfailures");
		if (hConVar != INVALID_HANDLE)
		{
			SetConVarBounds(hConVar, ConVarBound_Upper, true, 9999999.0);
			SetConVarBounds(hConVar, ConVarBound_Lower, true, 9999999.0);
			SetConVarInt(hConVar, 9999999);
		}
	}
//Rcon

	// AutoT
	g_hCvarBan = SMAC_CreateConVar("smac_autotrigger_ban", "0", "Automatically ban players on auto-trigger detections.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iAttackMax = RoundToNearest(1.0 / GetTickInterval() / 3.0);
	CreateTimer(4.0, Timer_DecreaseCount, _, TIMER_REPEAT);
	//AutoT
	
	//Eye
	g_hCvarBan = SMAC_CreateConVar("smac_eyetest_ban", "0", "Automatically ban players on eye test detections.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	//Eye
	
	g_hCvarWelcomeMsg = CreateConVar("smac_welcomemsg", "0", "Display a message saying that your server is protected.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarBanDuration = CreateConVar("smac_ban_duration", "0", "The duration in minutes used for automatic bans. (0 = Permanent)", FCVAR_PLUGIN, true, 0.0);
	
	//##############
	//CommandProtect
	g_hCvarCmdSpam = SMAC_CreateConVar("smac_antispam_cmds", "0", "Amount of commands allowed in one second before kick. (0 = Disabled)", FCVAR_PLUGIN, true, 0.0);
	OnSettingsChanged(g_hCvarCmdSpam, "", "");
	HookConVarChange(g_hCvarCmdSpam, OnSettingsChanged);
	// (Hooks)
	AddCommandListener(Commands_FilterSay, "say");
	AddCommandListener(Commands_FilterSay, "say_team");
	AddCommandListener(Commands_BlockExploit, "sm_menu");
	
	// (Exploitable needed commands)
	AddCommandListener(Commands_BlockEntExploit, "ent_create");
	AddCommandListener(Commands_BlockEntExploit, "ent_fire");
	
	// (L4D2 uses this for confogl.)
	if ( SMAC_GetGameType() != Game_L4D2 )
		AddCommandListener(Commands_BlockEntExploit, "give");
	
	if ( GuessSDKVersion() != SOURCE_SDK_EPISODE2VALVE )
	{
		HookEvent("player_disconnect", Commands_EventDisconnect, EventHookMode_Pre);
	}
	
	// (Init)
	g_hBlockedCmds = CreateTrie();
	g_hIgnoredCmds = CreateTrie();

	// True sets them to ban, false does not.
	SetTrieValue(g_hBlockedCmds, "ai_test_los", 			false);
	SetTrieValue(g_hBlockedCmds, "changelevel", 			false);
	SetTrieValue(g_hBlockedCmds, "cl_fullupdate",			false);
	SetTrieValue(g_hBlockedCmds, "dbghist_addline", 		false);
	SetTrieValue(g_hBlockedCmds, "dbghist_dump", 			false);
	SetTrieValue(g_hBlockedCmds, "drawcross",			false);
	SetTrieValue(g_hBlockedCmds, "drawline",			false);
	SetTrieValue(g_hBlockedCmds, "dump_entity_sizes", 		false);
	SetTrieValue(g_hBlockedCmds, "dump_globals", 			false);
	SetTrieValue(g_hBlockedCmds, "dump_panels", 			false);
	SetTrieValue(g_hBlockedCmds, "dump_terrain", 			false);
	SetTrieValue(g_hBlockedCmds, "dumpcountedstrings", 		false);
	SetTrieValue(g_hBlockedCmds, "dumpentityfactories", 		false);
	SetTrieValue(g_hBlockedCmds, "dumpeventqueue", 			false);
	SetTrieValue(g_hBlockedCmds, "dumpgamestringtable", 		false);
	SetTrieValue(g_hBlockedCmds, "editdemo", 			false);
	SetTrieValue(g_hBlockedCmds, "endround", 			false);
	SetTrieValue(g_hBlockedCmds, "groundlist", 			false);
	SetTrieValue(g_hBlockedCmds, "listmodels", 			false);
	SetTrieValue(g_hBlockedCmds, "map_showspawnpoints",		false);
	SetTrieValue(g_hBlockedCmds, "mem_dump", 			false);
	SetTrieValue(g_hBlockedCmds, "mp_dump_timers", 			false);
	SetTrieValue(g_hBlockedCmds, "npc_ammo_deplete", 		false);
	SetTrieValue(g_hBlockedCmds, "npc_heal", 			false);
	SetTrieValue(g_hBlockedCmds, "npc_speakall", 			false);
	SetTrieValue(g_hBlockedCmds, "npc_thinknow", 			false);
	SetTrieValue(g_hBlockedCmds, "physics_budget",			false);
	SetTrieValue(g_hBlockedCmds, "physics_debug_entity", 		false);
	SetTrieValue(g_hBlockedCmds, "physics_highlight_active", 	false);
	SetTrieValue(g_hBlockedCmds, "physics_report_active", 		false);
	SetTrieValue(g_hBlockedCmds, "physics_select", 			false);
	SetTrieValue(g_hBlockedCmds, "q_sndrcn", 			false);
	SetTrieValue(g_hBlockedCmds, "report_entities", 		false);
	SetTrieValue(g_hBlockedCmds, "report_touchlinks", 		false);
	SetTrieValue(g_hBlockedCmds, "report_simthinklist", 		false);
	SetTrieValue(g_hBlockedCmds, "respawn_entities",		false);
	SetTrieValue(g_hBlockedCmds, "rr_reloadresponsesystems", 	false);
	SetTrieValue(g_hBlockedCmds, "scene_flush", 			false);
	SetTrieValue(g_hBlockedCmds, "send_me_rcon", 			true);
	SetTrieValue(g_hBlockedCmds, "snd_digital_surround",		false);
	SetTrieValue(g_hBlockedCmds, "snd_restart", 			false);
	SetTrieValue(g_hBlockedCmds, "soundlist", 			false);
	SetTrieValue(g_hBlockedCmds, "soundscape_flush", 		false);
	SetTrieValue(g_hBlockedCmds, "sv_benchmark_force_start", 	false);
	SetTrieValue(g_hBlockedCmds, "sv_findsoundname", 		false);
	SetTrieValue(g_hBlockedCmds, "sv_soundemitter_filecheck", 	false);
	SetTrieValue(g_hBlockedCmds, "sv_soundemitter_flush", 		false);
	SetTrieValue(g_hBlockedCmds, "sv_soundscape_printdebuginfo", 	false);
	SetTrieValue(g_hBlockedCmds, "wc_update_entity", 		false);
	
	if (SMAC_GetGameType() == Game_L4D || SMAC_GetGameType() == Game_L4D2)
	{
		SetTrieValue(g_hIgnoredCmds, "choose_closedoor", 	true);
		SetTrieValue(g_hIgnoredCmds, "choose_opendoor",		true);
	}

	SetTrieValue(g_hIgnoredCmds, "buy",				true);
	SetTrieValue(g_hIgnoredCmds, "buyammo1",			true);
	SetTrieValue(g_hIgnoredCmds, "buyammo2",			true);
	SetTrieValue(g_hIgnoredCmds, "use",				true);
	SetTrieValue(g_hIgnoredCmds, "vmodenable",			true);
	SetTrieValue(g_hIgnoredCmds, "vban",				true);

	CreateTimer(1.0, Timer_CountReset, _, TIMER_REPEAT);
	
	AddCommandListener(Commands_CommandListener);

	RegAdminCmd("smac_addcmd",          Commands_AddCmd,           ADMFLAG_ROOT,  "Adds a command to be blocked by SMAC.");
	RegAdminCmd("smac_addignorecmd",    Commands_AddIgnoreCmd,     ADMFLAG_ROOT,  "Adds a command to ignore on command spam.");
	RegAdminCmd("smac_removecmd",       Commands_RemoveCmd,        ADMFLAG_ROOT,  "Removes a command from the block list.");
	RegAdminCmd("smac_removeignorecmd", Commands_RemoveIgnoreCmd,  ADMFLAG_ROOT,  "Remove a command to ignore.");

	//CommandProtect
	//###########

	
//#############
//CvarP
	decl Handle:f_hConCommand, String:f_sName[64], bool:f_bIsCommand, f_iFlags, Handle:f_hConVar;

	g_hCVars = CreateArray(64);
	g_hCVarIndex = CreateTrie();

	//- High Priority -//  Note: We kick them out before hand because we don't want to have to ban them.
	CVars_AddCVar("0penscript",		COMP_NONEXIST,	ACTION_BAN,	"0.0",	0.0,	PRIORITY_HIGH);
	CVars_AddCVar("aim_bot",		COMP_NONEXIST,	ACTION_BAN,	"0.0",	0.0,	PRIORITY_HIGH);
	CVars_AddCVar("aim_fov",		COMP_NONEXIST,	ACTION_BAN,	"0.0",	0.0,	PRIORITY_HIGH);
	CVars_AddCVar("bat_version", 		COMP_NONEXIST, 	ACTION_KICK, 	"0.0",	0.0, 	PRIORITY_HIGH);
	CVars_AddCVar("beetlesmod_version", 	COMP_NONEXIST,  ACTION_KICK, 	"0.0",  0.0, 	PRIORITY_HIGH);
	CVars_AddCVar("est_version", 		COMP_NONEXIST, 	ACTION_KICK, 	"0.0", 	0.0, 	PRIORITY_HIGH);
	CVars_AddCVar("eventscripts_ver", 	COMP_NONEXIST, 	ACTION_KICK, 	"0.0", 	0.0, 	PRIORITY_HIGH);
	CVars_AddCVar("fm_attackmode",		COMP_NONEXIST,	ACTION_BAN,	"0.0",	0.0,	PRIORITY_HIGH);
	CVars_AddCVar("lua_open",		COMP_NONEXIST,	ACTION_BAN,	"0.0",	0.0,	PRIORITY_HIGH);
	CVars_AddCVar("Lua-Engine",		COMP_NONEXIST, 	ACTION_BAN,	"0.0",	0.0,	PRIORITY_HIGH);
	CVars_AddCVar("mani_admin_plugin_version", COMP_NONEXIST, ACTION_KICK, 	"0.0", 	0.0, 	PRIORITY_HIGH);
	CVars_AddCVar("ManiAdminHacker",	COMP_NONEXIST,	ACTION_BAN,	"0.0",	0.0,	PRIORITY_HIGH);
	CVars_AddCVar("ManiAdminTakeOver",	COMP_NONEXIST,	ACTION_BAN,	"0.0",	0.0,	PRIORITY_HIGH);
	CVars_AddCVar("metamod_version", 	COMP_NONEXIST, 	ACTION_KICK, 	"0.0", 	0.0, 	PRIORITY_HIGH);
	CVars_AddCVar("openscript",		COMP_NONEXIST,	ACTION_BAN,	"0.0",	0.0,	PRIORITY_HIGH);
	CVars_AddCVar("openscript_version",	COMP_NONEXIST,	ACTION_BAN, 	"0.0",	0.0,	PRIORITY_HIGH);
	CVars_AddCVar("runnscript",		COMP_NONEXIST,	ACTION_BAN,	"0.0",	0.0,	PRIORITY_HIGH);
	CVars_AddCVar("SmAdminTakeover", 	COMP_NONEXIST, 	ACTION_BAN,	"0.0", 	0.0,	PRIORITY_HIGH);
	CVars_AddCVar("sourcemod_version", 	COMP_NONEXIST, 	ACTION_KICK, 	"0.0", 	0.0, 	PRIORITY_HIGH);
	CVars_AddCVar("tb_enabled",		COMP_NONEXIST,	ACTION_BAN,	"0.0",	0.0,	PRIORITY_HIGH);
	CVars_AddCVar("zb_version", 		COMP_NONEXIST, 	ACTION_KICK, 	"0.0", 	0.0, 	PRIORITY_HIGH);

	//- Medium Priority -// Note: Now the client should be clean of any third party server side plugins.  Now we can start really checking.
	CVars_AddCVar("sv_cheats", 		COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_MEDIUM);
	CVars_AddCVar("sv_consistency", 	COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_MEDIUM);
	//CVars_AddCVar("sv_gravity", 		COMP_EQUAL, 	ACTION_BAN, 	"800.0", 0.0, 	PRIORITY_MEDIUM);
	CVars_AddCVar("r_drawothermodels", 	COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_MEDIUM);

	//- Normal Priority -//
	CVars_AddCVar("cl_clock_correction", 	COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("cl_leveloverview", 	COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("cl_overdraw_test", 	COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	
	// This doesn't exist on some mods.
	if ( SMAC_GetGameType() == Game_HL2CTF || SMAC_GetGameType() == Game_HIDDEN )
		CVars_AddCVar("cl_particles_show_bbox", COMP_NONEXIST, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_HIGH);
	else
		CVars_AddCVar("cl_particles_show_bbox", COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	
	CVars_AddCVar("cl_phys_timescale", 	COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("cl_showevents", 		COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);

	if ( SMAC_GetGameType() == Game_INSMOD )
		CVars_AddCVar("fog_enable", 		COMP_EQUAL, 	ACTION_KICK, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	else
		CVars_AddCVar("fog_enable", 		COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	
	// This doesn't exist on FoF
	if ( SMAC_GetGameType() == Game_FOF )
		CVars_AddCVar("host_timescale", 	COMP_NONEXIST, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_HIGH);
	else
		CVars_AddCVar("host_timescale", 	COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	
	CVars_AddCVar("mat_dxlevel", 		COMP_GREATER, 	ACTION_KICK, 	"80.0", 0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("mat_fillrate", 		COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("mat_measurefillrate",	COMP_EQUAL,	ACTION_BAN,	"0.0", 	0.0,	PRIORITY_NORMAL);
	CVars_AddCVar("mat_proxy", 		COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("mat_showlowresimage",	COMP_EQUAL, 	ACTION_BAN,	"0.0",	0.0,	PRIORITY_NORMAL);
	CVars_AddCVar("mat_wireframe", 		COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("mem_force_flush", 	COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("snd_show", 		COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("snd_visualize", 		COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_aspectratio", 		COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_colorstaticprops", 	COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_DispWalkable", 	COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_DrawBeams", 		COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_drawbrushmodels", 	COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_drawclipbrushes", 	COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_drawdecals", 		COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_drawentities", 	COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_drawmodelstatsoverlay",COMP_EQUAL,	ACTION_BAN,	"0.0",	0.0,	PRIORITY_NORMAL);
	CVars_AddCVar("r_drawopaqueworld", 	COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_drawparticles", 	COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_drawrenderboxes", 	COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_drawskybox",		COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_drawtranslucentworld", COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_shadowwireframe", 	COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_skybox", 		COMP_EQUAL, 	ACTION_BAN, 	"1.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("r_visocclusion", 	COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);
	CVars_AddCVar("vcollide_wireframe", 	COMP_EQUAL, 	ACTION_BAN, 	"0.0", 	0.0, 	PRIORITY_NORMAL);

	//- Replication Protection -//
	f_hConCommand = FindFirstConCommand(f_sName, sizeof(f_sName), f_bIsCommand, f_iFlags);
	if ( f_hConCommand == INVALID_HANDLE )
		SetFailState("Failed getting first ConVar");

	do
	{
		if ( f_bIsCommand )
			continue;
		
		if ( !(f_iFlags & FCVAR_REPLICATED) )
			continue;
		
		// SMAC will not always be the first to load and many plugins (mistakenly) put
		//  FCVAR_REPLICATED on their version cvar (in addition to FCVAR_PLUGIN)
		if ( f_iFlags & FCVAR_PLUGIN )
			continue;
		
		f_hConVar = FindConVar(f_sName);
		if ( f_hConVar == INVALID_HANDLE )
			continue;
		
		CVars_ReplicateConVar(f_hConVar);
		HookConVarChange(f_hConVar, CVars_Replicate);
	} while ( FindNextConCommand(f_hConCommand, f_sName, sizeof(f_sName), f_bIsCommand, f_iFlags));

	CloseHandle(f_hConCommand);

	//- Register Admin Commands -//
	RegAdminCmd("smac_addcvar",      CVars_CmdAddCVar,  ADMFLAG_ROOT,    "Adds a CVar to the check list.");
	RegAdminCmd("smac_removecvar",   CVars_CmdRemCVar,  ADMFLAG_ROOT,    "Removes a CVar from the check list.");
	RegAdminCmd("smac_cvars_status", CVars_CmdStatus,  ADMFLAG_GENERIC,  "Shows the status of all in-game clients.");
	
	// Start on all clients.
	if (g_bMapStarted)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsClientAuthorized(i))
			{
				OnClientPostAdminCheck(i);
			}
		}
	}
// CvarP
//##################

}

//#######################################################
//CvarP
public OnClientPostAdminCheck(client)
{
	if ( !IsFakeClient(client) )
		g_hPeriodicTimer[client] = CreateTimer(0.1, CVars_PeriodicTimer, client);
}

public OnClientDisconnect(client)
{
	decl Handle:f_hTemp;
	
	g_iCurrentIndex[client] = 0;
	g_iRetryAttempts[client] = 0;

	f_hTemp = g_hPeriodicTimer[client];
	if ( f_hTemp != INVALID_HANDLE )
	{
		g_hPeriodicTimer[client] = INVALID_HANDLE;
		CloseHandle(f_hTemp);
	}
	f_hTemp = g_hReplyTimer[client];
	if ( f_hTemp != INVALID_HANDLE )
	{
		g_hReplyTimer[client] = INVALID_HANDLE;
		CloseHandle(f_hTemp);
	}
}

public OnMapStart()
{
	g_bMapStarted = true;
}

public OnMapEnd()
{
	g_bMapStarted = false;
}

public Action:CVars_CmdStatus(client, args)
{
	if ( client && !IsClientInGame(client) )
		return Plugin_Handled;

	decl String:f_sAuth[64], String:f_sCVarName[64];
	new Handle:f_hTemp;

	for(new i=1;i<=MaxClients;i++)
	{
		if ( IsClientInGame(i) && !IsFakeClient(i) )
		{
			GetClientAuthString(i, f_sAuth, sizeof(f_sAuth));
			f_hTemp = g_hCurrentQuery[i];
			if ( f_hTemp == INVALID_HANDLE )
			{
				if ( g_hPeriodicTimer[i] == INVALID_HANDLE )
				{
					LogError("%N (%s) doesn't have a periodic timer running and no active queries.", i, f_sAuth);
					ReplyToCommand(client, "ERROR: %N (%s) didn't have a periodic timer running nor active queries.", i, f_sAuth);
					g_hPeriodicTimer[i] = CreateTimer(0.1, CVars_PeriodicTimer, i);
					continue;
				}
				ReplyToCommand(client, "%N (%s) is waiting for new query. Current Index: %d.", i, f_sAuth, g_iCurrentIndex[i]);
			}
			else
			{
				GetArrayString(f_hTemp, CELL_NAME, f_sCVarName, sizeof(f_sCVarName));
				ReplyToCommand(client, "%N (%s) has active query on %s. Current Index: %d. Retry Attempts: %d.", i, f_sAuth, f_sCVarName, g_iCurrentIndex[i], g_iRetryAttempts[i]);
			}
		}
	}
	return Plugin_Handled;
}

public Action:CVars_CmdAddCVar(client, args)
{
	if ( args != 4 && args != 5 )
	{
		ReplyToCommand(client, "Usage: smac_addcvar <cvar name> <comparison type> <action> <value> <value2 if bound>");
		return Plugin_Handled;
	}

	decl String:f_sCVarName[64], String:f_sTemp[64], f_iCompType, f_iAction, String:f_sValue[64], Float:f_fValue2;

	GetCmdArg(1, f_sCVarName, sizeof(f_sCVarName));
	
	if ( !CVars_IsValidName(f_sCVarName) )
	{
		ReplyToCommand(client, "The ConVar name \"%s\" is invalid and cannot be used.", f_sCVarName);
		return Plugin_Handled;
	}

	GetCmdArg(2, f_sTemp, sizeof(f_sTemp));

	if ( StrEqual(f_sTemp, "=") || StrEqual(f_sTemp, "equal") )
		f_iCompType = COMP_EQUAL;
	else if ( StrEqual(f_sTemp, "<") || StrEqual(f_sTemp, "greater") )
		f_iCompType = COMP_GREATER;
	else if ( StrEqual(f_sTemp, ">") || StrEqual(f_sTemp, "less") )
		f_iCompType = COMP_LESS;
	else if ( StrEqual(f_sTemp, "bound") || StrEqual(f_sTemp, "between") )
		f_iCompType = COMP_BOUND;
	else if ( StrEqual(f_sTemp, "strequal") )
		f_iCompType = COMP_STRING;
	else if ( StrEqual(f_sTemp, "nonexist") )
		f_iCompType = COMP_NONEXIST;
	else
	{
		ReplyToCommand(client, "Unrecognized comparison type \"%s\", acceptable values: \"equal\", \"greater\", \"less\", \"between\", \"strequal\", or \"nonexist\".", f_sTemp);
		return Plugin_Handled;
	}
	
	if ( f_iCompType == COMP_BOUND && args < 5 )
	{
		ReplyToCommand(client, "Bound comparison type needs two values to compare with.");
		return Plugin_Handled;
	}

	GetCmdArg(3, f_sTemp, sizeof(f_sTemp));

	if ( StrEqual(f_sTemp, "warn") )
		f_iAction = ACTION_WARN;
	else if ( StrEqual(f_sTemp, "motd") )
		f_iAction = ACTION_MOTD;
	else if ( StrEqual(f_sTemp, "mute") )
		f_iAction = ACTION_MUTE;
	else if ( StrEqual(f_sTemp, "kick") )
		f_iAction = ACTION_KICK;
	else if ( StrEqual(f_sTemp, "ban") )
		f_iAction = ACTION_BAN;
	else
	{
		ReplyToCommand(client, "Unrecognized action type \"%s\", acceptable values: \"warn\", \"mute\", \"kick\", or \"ban\".", f_sTemp);
		return Plugin_Handled;
	}

	GetCmdArg(4, f_sValue, sizeof(f_sValue));

	if ( f_iCompType == COMP_BOUND )
	{
		GetCmdArg(5, f_sTemp, sizeof(f_sTemp));
		f_fValue2 = StringToFloat(f_sTemp);
	}

	if ( CVars_AddCVar(f_sCVarName, f_iCompType, f_iAction, f_sValue, f_fValue2, PRIORITY_NORMAL) )
	{
		if ( client )
		{
			SMAC_LogAction(client, "added convar %s to the check list.", f_sCVarName);
		}
		ReplyToCommand(client, "Successfully added ConVar %s to the check list.", f_sCVarName);
	}
	else
		ReplyToCommand(client, "Failed to add ConVar %s to the check list.", f_sCVarName);
	
	return Plugin_Handled;
}

public Action:CVars_CmdRemCVar(client, args)
{
	if ( args != 1 )
	{
		ReplyToCommand(client, "Usage: smac_removecvar <cvar name>");
		return Plugin_Handled;
	}

	decl String:f_sCVarName[64];

	GetCmdArg(1, f_sCVarName, sizeof(f_sCVarName));

	if ( CVars_RemoveCVar(f_sCVarName) )
	{
		if ( client )
		{
			SMAC_LogAction(client, "removed convar %s from the check list.", f_sCVarName);
		}
		else
			SMAC_Log("Console removed convar %s from the check list.", f_sCVarName);
		ReplyToCommand(client, "ConVar %s was successfully removed from the check list.", f_sCVarName);
	}
	else
		ReplyToCommand(client, "Unable to find ConVar %s in the check list.", f_sCVarName);
	
	return Plugin_Handled;
}

//- Timers -//

public Action:CVars_PeriodicTimer(Handle:timer, any:client)
{
	if ( g_hPeriodicTimer[client] == INVALID_HANDLE )
		return Plugin_Stop;

	g_hPeriodicTimer[client] = INVALID_HANDLE;

	if ( !IsClientConnected(client) )
		return Plugin_Stop;

	decl String:f_sName[64], Handle:f_hCVar, f_iIndex;

	if ( g_iSize < 1 )
	{
		PrintToServer("Nothing in convar list");
		CreateTimer(10.0, CVars_PeriodicTimer, client);
		return Plugin_Stop;
	}

	f_iIndex = g_iCurrentIndex[client]++;
	if ( f_iIndex >= g_iSize )
	{
		f_iIndex = 0;
		g_iCurrentIndex[client] = 1;
	}

	f_hCVar = GetArrayCell(g_hCVars, f_iIndex);

	if ( GetArrayCell(f_hCVar, CELL_CHANGED) == INVALID_HANDLE )
	{
		GetArrayString(f_hCVar, 0, f_sName, sizeof(f_sName));
		g_hCurrentQuery[client] = f_hCVar;
		QueryClientConVar(client, f_sName, CVars_QueryCallback, client);
		g_hReplyTimer[client] = CreateTimer(30.0, CVars_ReplyTimer, GetClientUserId(client)); // We'll wait 30 seconds for a reply.
	}
	else
		g_hPeriodicTimer[client] = CreateTimer(0.1, CVars_PeriodicTimer, client);
	return Plugin_Stop;
	
}

public Action:CVars_ReplyTimer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if ( !client || g_hReplyTimer[client] == INVALID_HANDLE )
		return Plugin_Stop;
	g_hReplyTimer[client] = INVALID_HANDLE;
	if ( !IsClientConnected(client) || g_hPeriodicTimer[client] != INVALID_HANDLE )
		return Plugin_Stop;

	if ( g_iRetryAttempts[client]++ > 3 )
		KickClient(client, "%t", "SMAC_FailedToReply");
	else
	{
		decl String:f_sName[64], Handle:f_hCVar;

		if ( g_iSize < 1 )
		{
			PrintToServer("Nothing in convar list");
			CreateTimer(10.0, CVars_PeriodicTimer, client);
			return Plugin_Stop;
		}

		f_hCVar = g_hCurrentQuery[client];

		if ( GetArrayCell(f_hCVar, CELL_CHANGED) == INVALID_HANDLE )
		{
			GetArrayString(f_hCVar, 0, f_sName, sizeof(f_sName));
			QueryClientConVar(client, f_sName, CVars_QueryCallback, client);
			g_hReplyTimer[client] = CreateTimer(15.0, CVars_ReplyTimer, GetClientUserId(client)); // We'll wait 15 seconds for a reply.
		}
		else
			g_hPeriodicTimer[client] = CreateTimer(0.1, CVars_PeriodicTimer, client);
	}

	return Plugin_Stop;
}

public Action:CVars_ReplicateTimer(Handle:timer, any:f_hConVar)
{
	decl String:f_sName[64];
	GetConVarName(f_hConVar, f_sName, sizeof(f_sName));
	if ( StrEqual(f_sName, "sv_cheats") && GetConVarInt(f_hConVar) != 0 )
		SetConVarInt(f_hConVar, 0);
	CVars_ReplicateConVar(f_hConVar);
	return Plugin_Stop;
}

public Action:CVars_ReplicateCheck(Handle:timer, any:f_hIndex)
{
	SetArrayCell(f_hIndex, CELL_CHANGED, INVALID_HANDLE);
	return Plugin_Stop;
}

//- ConVar Query Reply -//

public CVars_QueryCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if ( !IsClientConnected(client) )
		return;

	decl String:f_sCVarName[64], Handle:f_hConVar, Handle:f_hTemp, String:f_sName[MAX_NAME_LENGTH], String:f_sAuthID[64], f_iCompType, f_iAction, String:f_sValue[64], Float:f_fValue2, String:f_sAlternative[128], f_iSize, bool:f_bContinue;

	// Get Client Info
	GetClientName(client, f_sName, sizeof(f_sName));
	GetClientAuthString(client, f_sAuthID, sizeof(f_sAuthID));

	if ( g_hPeriodicTimer[client] != INVALID_HANDLE )
		f_bContinue = false;
	else
		f_bContinue = true;

	f_hConVar = g_hCurrentQuery[client];

	// We weren't expecting a reply or convar we queried is no longer valid and we cannot find it.
	if ( f_hConVar == INVALID_HANDLE && !GetTrieValue(g_hCVarIndex, cvarName, f_hConVar) )
	{
		if ( g_hPeriodicTimer[client] == INVALID_HANDLE ) // Client doesn't have active query or a timer active for them?  Ballocks!
			g_hPeriodicTimer[client] = CreateTimer(GetRandomFloat(0.5, 2.0), CVars_PeriodicTimer, client);
		return;
	}

	GetArrayString(f_hConVar, CELL_NAME, f_sCVarName, sizeof(f_sCVarName));

	// Make sure this query replied correctly.
	if ( !StrEqual(cvarName, f_sCVarName) ) // CVar not expected.
	{
		if ( !GetTrieValue(g_hCVarIndex, cvarName, f_hConVar) ) // CVar doesn't exist in our list.
		{
			SMAC_LogAction(client, "was kicked for a corrupted return with convar name \"%s\" (expecting \"%s\") with value \"%s\".", cvarName, f_sCVarName, cvarValue);
			KickClient(client, "%t", "SMAC_ClientCorrupt");
			return;
		}
		else
			f_bContinue = false;

		GetArrayString(f_hConVar, CELL_NAME, f_sCVarName, sizeof(f_sCVarName));
	}

	f_iCompType = GetArrayCell(f_hConVar, CELL_COMPTYPE);
	f_iAction = GetArrayCell(f_hConVar, CELL_ACTION);

	if ( f_bContinue )
	{
		f_hTemp = g_hReplyTimer[client];
		g_hCurrentQuery[client] = INVALID_HANDLE;

		if ( f_hTemp != INVALID_HANDLE )
		{
			g_hReplyTimer[client] = INVALID_HANDLE;
			CloseHandle(f_hTemp);
			g_iRetryAttempts[client] = 0;
		}
	}

	// Check if it should exist.
	if ( f_iCompType == COMP_NONEXIST )
	{
		if ( result != ConVarQuery_NotFound && SMAC_CheatDetected(client) == Plugin_Continue )
		{
			SMAC_PrintAdminNotice("%t", "SMAC_HasPlugin", f_sName, f_sAuthID, f_sCVarName);
			
			switch(f_iAction)
			{
				case ACTION_MOTD:
				{
					GetArrayString(f_hConVar, CELL_ALT, f_sAlternative, sizeof(f_sAlternative));
					ShowMOTDPanel(client, "", f_sAlternative);
				}
				case ACTION_MUTE:
				{
					PrintToChatAll("%t", "SMAC_Muted", f_sName);
					ServerCommand("sm_mute #%d", GetClientUserId(client));
				}
				case ACTION_KICK:
				{
					SMAC_LogAction(client, "was kicked for returning with plugin convar \"%s\" (value \"%s\", return %s).", cvarName, cvarValue, g_sQueryResult[result]);
					KickClient(client, "%t", "SMAC_RemovePlugins");
					return;
				}
				case ACTION_BAN:
				{
					SMAC_LogAction(client, "has convar \"%s\" (value \"%s\", return %s) when it shouldn't exist.", cvarName, cvarValue, g_sQueryResult[result]);
					SMAC_Ban(client, "ConVar %s violation", cvarName);
					
					return;
				}
			}
		}
		if ( f_bContinue )
			g_hPeriodicTimer[client] = CreateTimer(GetRandomFloat(1.0, 3.0), CVars_PeriodicTimer, client);
		return;
	}

	if ( result != ConVarQuery_Okay ) // ConVar should exist.
	{
		SMAC_LogAction(client, "returned query result \"%s\" (expected Okay) on convar \"%s\" (value \"%s\").", g_sQueryResult[result], cvarName, cvarValue);
		SMAC_Ban(client, "ConVar %s violation (bad query result)", cvarName);
		
		return;
	}

	// Check if the ConVar was recently changed.
	if ( GetArrayCell(f_hConVar, CELL_CHANGED) != INVALID_HANDLE )
	{
		g_hPeriodicTimer[client] = CreateTimer(GetRandomFloat(1.0, 3.0), CVars_PeriodicTimer, client);
		return;
	}

	f_hTemp = GetArrayCell(f_hConVar, CELL_HANDLE);
	if ( f_hTemp == INVALID_HANDLE || f_iCompType != COMP_EQUAL )
		GetArrayString(f_hConVar, CELL_VALUE, f_sValue, sizeof(f_sValue));
	else
		GetConVarString(f_hTemp, f_sValue, sizeof(f_sValue));

	if ( f_iCompType == COMP_BOUND )
		f_fValue2 = GetArrayCell(f_hConVar, CELL_VALUE2);

	if ( f_iCompType != COMP_STRING )
	{
		f_iSize = strlen(cvarValue);
		for(new i=0;i<f_iSize;i++)
		{
			if ( !IsCharNumeric(cvarValue[i]) && cvarValue[i] != '.' )
			{
				SMAC_LogAction(client, "was kicked for returning a corrupted value on %s (%s), value set at \"%s\" (expected \"%s\").", f_sCVarName, cvarName, cvarValue, f_sValue);
				KickClient(client, "%t", "SMAC_ClientCorrupt");
				return;
			}
		}
	}


	switch(f_iCompType)
	{
		case COMP_EQUAL:
			if ( StringToFloat(f_sValue) != StringToFloat(cvarValue) && SMAC_CheatDetected(client) == Plugin_Continue )
			{
				SMAC_PrintAdminNotice("%t", "SMAC_HasNotEqual", f_sName, f_sAuthID, f_sCVarName, cvarValue, f_sValue);
				
				switch(f_iAction)
				{
					case ACTION_MOTD:
					{
						GetArrayString(f_hConVar, CELL_ALT, f_sAlternative, sizeof(f_sAlternative));
						ShowMOTDPanel(client, "", f_sAlternative);
					}
					case ACTION_MUTE:
					{
						PrintToChatAll("%t", "SMAC_Muted", f_sName);
						ServerCommand("sm_mute #%d", GetClientUserId(client));
					}
					case ACTION_KICK:
					{
						SMAC_LogAction(client, "was kicked for returning with convar \"%s\" set to value \"%s\" when it should be \"%s\".", cvarName, cvarValue, f_sValue);
						KickClient(client, "%t", "SMAC_ShouldEqual", cvarName, f_sValue, cvarValue);
						return;
					}
					case ACTION_BAN:
					{
						SMAC_LogAction(client, "has convar \"%s\" set to value \"%s\" (should be \"%s\") when it should equal.", cvarName, cvarValue, f_sValue);
						SMAC_Ban(client, "ConVar %s violation", cvarName);
						return;
					}
				}
			}
		case COMP_GREATER:
			if ( StringToFloat(f_sValue) > StringToFloat(cvarValue) && SMAC_CheatDetected(client) == Plugin_Continue )
			{
				SMAC_PrintAdminNotice("%t", "SMAC_HasNotGreater", f_sName, f_sAuthID, f_sCVarName, cvarValue, f_sValue);
				
				switch(f_iAction)
				{
					case ACTION_MOTD:
					{
						GetArrayString(f_hConVar, CELL_ALT, f_sAlternative, sizeof(f_sAlternative));
						ShowMOTDPanel(client, "", f_sAlternative);
					}
					case ACTION_MUTE:
					{
						PrintToChatAll("%t", "SMAC_Muted", f_sName);
						ServerCommand("sm_mute #%d", GetClientUserId(client));
					}
					case ACTION_KICK:
					{
						SMAC_LogAction(client, "was kicked for returning with convar \"%s\" set to value \"%s\" when it should be greater than or equal to \"%s\".", cvarName, cvarValue, f_sValue);
						KickClient(client, "%t", "SMAC_ShouldBeGreater", cvarName, f_sValue, cvarValue);
						return;
					}
					case ACTION_BAN:
					{
						SMAC_LogAction(client, "has convar \"%s\" set to value \"%s\" (should be \"%s\") when it should greater than or equal to.", cvarName, cvarValue, f_sValue);
						SMAC_Ban(client, "ConVar %s violation", cvarName);
						return;
					}
				}
			}
		case COMP_LESS:
			if ( StringToFloat(f_sValue) < StringToFloat(cvarValue) && SMAC_CheatDetected(client) == Plugin_Continue )
			{
				SMAC_PrintAdminNotice("%t", "SMAC_HasNotLess", f_sName, f_sAuthID, f_sCVarName, cvarValue, f_sValue);
				
				switch(f_iAction)
				{
					case ACTION_MOTD:
					{
						GetArrayString(f_hConVar, CELL_ALT, f_sAlternative, sizeof(f_sAlternative));
						ShowMOTDPanel(client, "", f_sAlternative);
					}
					case ACTION_MUTE:
					{
						PrintToChatAll("%t", "SMAC_Muted", f_sName);
						ServerCommand("sm_mute #%d", GetClientUserId(client));
					}
					case ACTION_KICK:
					{
						SMAC_LogAction(client, "was kicked for returning with convar \"%s\" set to value \"%s\" when it should be less than or equal to \"%s\".", cvarName, cvarValue, f_sValue);
						KickClient(client, "%t", "SMAC_ShouldBeLess", cvarName, f_sValue, cvarValue);
						return;
					}
					case ACTION_BAN:
					{
						SMAC_LogAction(client, "has convar \"%s\" set to value \"%s\" (should be \"%s\") when it should be less than or equal to.", cvarName, cvarValue, f_sValue);
						SMAC_Ban(client, "ConVar %s violation", cvarName);
						return;
					}
				}
			}
		case COMP_BOUND:
			if ( StringToFloat(f_sValue) >= StringToFloat(cvarValue) && f_fValue2 <= StringToFloat(cvarValue) && SMAC_CheatDetected(client) == Plugin_Continue )
			{
				SMAC_PrintAdminNotice("%t", "SMAC_HasNotBound", f_sName, f_sAuthID, f_sCVarName, cvarValue, f_sValue, f_fValue2);
				
				switch(f_iAction)
				{
					case ACTION_MOTD:
					{
						GetArrayString(f_hConVar, CELL_ALT, f_sAlternative, sizeof(f_sAlternative));
						ShowMOTDPanel(client, "", f_sAlternative);
					}
					case ACTION_MUTE:
					{
						PrintToChatAll("%t", "SMAC_Muted", f_sName);
						ServerCommand("sm_mute #%d", GetClientUserId(client));
					}
					case ACTION_KICK:
					{
						SMAC_LogAction(client, "was kicked for returning with convar \"%s\" set to value \"%s\" when it should be between \"%s\" and \"%f\".", cvarName, cvarValue, f_sValue, f_fValue2);
						KickClient(client, "%t", "SMAC_ShouldBound", cvarName, f_sValue, f_fValue2, cvarValue);
						return;
					}
					case ACTION_BAN:
					{
						SMAC_LogAction(client, "has convar \"%s\" set to value \"%s\" when it should be between \"%s\" and \"%f\".", cvarName, cvarValue, f_sValue, f_fValue2);
						SMAC_Ban(client, "ConVar %s violation", cvarName);
						return;
					}
				}
			}
		case COMP_STRING:
			if ( !StrEqual(f_sValue, cvarValue) && SMAC_CheatDetected(client) == Plugin_Continue )
			{
				SMAC_PrintAdminNotice("%t", "SMAC_HasNotEqual", f_sName, f_sAuthID, f_sCVarName, cvarValue, f_sValue);
				
				switch(f_iAction)
				{
					case ACTION_MOTD:
					{
						GetArrayString(f_hConVar, CELL_ALT, f_sAlternative, sizeof(f_sAlternative));
						ShowMOTDPanel(client, "", f_sAlternative);
					}
					case ACTION_MUTE:
					{
						PrintToChatAll("%t", "SMAC_Muted", f_sName);
						ServerCommand("sm_mute #%d", GetClientUserId(client));
					}
					case ACTION_KICK:
					{
						SMAC_LogAction(client, "was kicked for returning with convar \"%s\" set to value \"%s\" when it should be \"%s\".", cvarName, cvarValue, f_sValue);
						KickClient(client, "%t", "SMAC_ShouldEqual", cvarName, f_sValue, cvarValue);
						return;
					}
					case ACTION_BAN:
					{
						SMAC_LogAction(client, "has convar \"%s\" set to value \"%s\" (should be \"%s\") when it should equal.", cvarName, cvarValue, f_sValue);
						SMAC_Ban(client, "ConVar %s violation", cvarName);
						return;
					}
				}
			}
	}
	
	if ( f_bContinue )
		g_hPeriodicTimer[client] = CreateTimer(GetRandomFloat(0.5, 2.0), CVars_PeriodicTimer, client);
	
}

//- Hook -//

public CVars_Replicate(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	decl String:f_sName[64], Handle:f_hCVarIndex, Handle:f_hTimer;
	GetConVarName(convar, f_sName, sizeof(f_sName));
	if ( GetTrieValue(g_hCVarIndex, f_sName, f_hCVarIndex) )
	{
		f_hTimer = GetArrayCell(f_hCVarIndex, CELL_CHANGED);
		if ( f_hTimer != INVALID_HANDLE )
			CloseHandle(f_hTimer);
		f_hTimer = CreateTimer(30.0, CVars_ReplicateCheck, f_hCVarIndex);
		SetArrayCell(f_hCVarIndex, CELL_CHANGED, f_hTimer);
	}
	// The delay is so that nothing interferes with the replication.
	CreateTimer(0.1, CVars_ReplicateTimer, convar);
}

//- Private Functions -//

stock bool:CVars_IsValidName(const String:f_sName[])
{
	if (f_sName[0] == '\0')
		return false;
	
	new len = strlen(f_sName);
	for (new i = 0; i < len; i++)
		if (!IsValidConVarChar(f_sName[i]))
			return false;

	return true;
}

bool:CVars_AddCVar(String:f_sName[], f_iComparisonType, f_iAction, const String:f_sValue[], Float:f_fValue2, f_iImportance, const String:f_sAlternative[] = "")
{
	new Handle:f_hConVar = INVALID_HANDLE, Handle:f_hArray;
	
	new c = 0;
	do
	{
		f_sName[c] = CharToLower(f_sName[c]);
	} while ( f_sName[c++] != '\0' );

	f_hConVar = FindConVar(f_sName);
	if ( f_hConVar != INVALID_HANDLE && (GetConVarFlags(f_hConVar) & FCVAR_REPLICATED) && ( f_iComparisonType == COMP_EQUAL || f_iComparisonType == COMP_STRING ) )
		f_iComparisonType = COMP_EQUAL;
	else
		f_hConVar = INVALID_HANDLE;

	if ( GetTrieValue(g_hCVarIndex, f_sName, f_hArray) ) // Check if CVar check already exists.
	{
		SetArrayString(f_hArray, CELL_NAME, f_sName);			// Name			0
		SetArrayCell(f_hArray, CELL_COMPTYPE, f_iComparisonType);	// Comparison Type	1
		SetArrayCell(f_hArray, CELL_HANDLE, f_hConVar);			// CVar Handle		2
		SetArrayCell(f_hArray, CELL_ACTION, f_iAction);			// Action Type		3
		SetArrayString(f_hArray, CELL_VALUE, f_sValue);			// Value		4
		SetArrayCell(f_hArray, CELL_VALUE2, f_fValue2);			// Value2		5
		SetArrayString(f_hArray, CELL_ALT, f_sAlternative);		// Alternative Info	6
		// We will not change the priority.
		// Nor will we change the "changed" cell either.
	}
	else
	{
		f_hArray = CreateArray(64);
		PushArrayString(f_hArray, f_sName);		// Name			0
		PushArrayCell(f_hArray, f_iComparisonType);	// Comparison Type	1
		PushArrayCell(f_hArray, f_hConVar);		// CVar Handle		2
		PushArrayCell(f_hArray, f_iAction);		// Action Type		3
		PushArrayString(f_hArray, f_sValue);		// Value		4
		PushArrayCell(f_hArray, f_fValue2);		// Value2		5
		PushArrayString(f_hArray, f_sAlternative);	// Alternative Info	6
		PushArrayCell(f_hArray, f_iImportance);		// Importance		7
		PushArrayCell(f_hArray, INVALID_HANDLE);	// Changed		8

		if ( !SetTrieValue(g_hCVarIndex, f_sName, f_hArray) )
		{
			CloseHandle(f_hArray);
			SMAC_Log("Unable to add convar to Trie link list %s.", f_sName);
			return false;
		}

		PushArrayCell(g_hCVars, f_hArray);
		g_iSize = GetArraySize(g_hCVars);

		if ( f_iImportance != PRIORITY_NORMAL && g_bMapStarted )
			CVars_CreateNewOrder();

	}

	return true;
}

stock bool:CVars_RemoveCVar(String:f_sName[])
{
	decl Handle:f_hConVar, f_iIndex;

	if ( !GetTrieValue(g_hCVarIndex, f_sName, f_hConVar) )
		return false;

	f_iIndex = FindValueInArray(g_hCVars, f_hConVar);
	if ( f_iIndex == -1 )
		return false;

	for(new i=0;i<=MaxClients;i++)
		if ( g_hCurrentQuery[i] == f_hConVar )
			g_hCurrentQuery[i] = INVALID_HANDLE;

	RemoveFromArray(g_hCVars, f_iIndex);
	RemoveFromTrie(g_hCVarIndex, f_sName);
	CloseHandle(f_hConVar);
	g_iSize = GetArraySize(g_hCVars);
	return true;
}

CVars_CreateNewOrder()
{
	new Handle:f_hOrder[g_iSize], f_iCurrent;
	new Handle:f_hPHigh, Handle:f_hPMedium, Handle:f_hPNormal, Handle:f_hCurrent;
	new f_iHigh, f_iMedium, f_iNormal, f_iTemp;

	f_hPHigh = CreateArray(64);
	f_hPMedium = CreateArray(64);
	f_hPNormal = CreateArray(64);

	// Get priorities.
	for(new i=0;i<g_iSize;i++)
	{
		f_hCurrent = GetArrayCell(g_hCVars, i);
		f_iTemp = GetArrayCell(f_hCurrent, CELL_PRIORITY);
		if ( f_iTemp == PRIORITY_NORMAL )
			PushArrayCell(f_hPNormal, f_hCurrent);
		else if ( f_iTemp == PRIORITY_MEDIUM )
			PushArrayCell(f_hPMedium, f_hCurrent);
		else if ( f_iTemp == PRIORITY_HIGH )
			PushArrayCell(f_hPHigh, f_hCurrent);
	}

	f_iHigh = GetArraySize(f_hPHigh)-1;
	f_iMedium = GetArraySize(f_hPMedium)-1;
	f_iNormal = GetArraySize(f_hPNormal)-1;

	// Start randomizing!
	while ( f_iHigh > -1 )
	{
		f_iTemp = GetRandomInt(0, f_iHigh);
		f_hOrder[f_iCurrent++] = GetArrayCell(f_hPHigh, f_iTemp);
		RemoveFromArray(f_hPHigh, f_iTemp);
		f_iHigh--;
	}

	while ( f_iMedium > -1 )
	{
		f_iTemp = GetRandomInt(0, f_iMedium);
		f_hOrder[f_iCurrent++] = GetArrayCell(f_hPMedium, f_iTemp);
		RemoveFromArray(f_hPMedium, f_iTemp);
		f_iMedium--;
	}

	while ( f_iNormal > -1 )
	{
		f_iTemp = GetRandomInt(0, f_iNormal);
		f_hOrder[f_iCurrent++] = GetArrayCell(f_hPNormal, f_iTemp);
		RemoveFromArray(f_hPNormal, f_iTemp);
		f_iNormal--;
	}

	ClearArray(g_hCVars);

	for(new i=0;i<g_iSize;i++)
		PushArrayCell(g_hCVars, f_hOrder[i]);

	CloseHandle(f_hPHigh);
	CloseHandle(f_hPMedium);
	CloseHandle(f_hPNormal);
}

CVars_ReplicateConVar(Handle:f_hConVar)
{
	decl String:f_sValue[64];
	GetConVarString(f_hConVar, f_sValue, sizeof(f_sValue));
	
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
			SendConVarValue(i, f_hConVar, f_sValue);
}

//CvarP
//###################################################

// #############################
// Rcon
public OnConfigsExecuted()
{
	if (!g_bRconLocked)
	{
		GetConVarString(g_hCvarRconPass, g_sRconRealPass, sizeof(g_sRconRealPass));
		g_bRconLocked = true;
	}
}

public OnRconPassChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (g_bRconLocked && !StrEqual(newValue, g_sRconRealPass))
	{
		SMAC_Log("Rcon password changed to \"%s\". Reverting back to original config value.", newValue);
		SetConVarString(g_hCvarRconPass, g_sRconRealPass);
	}
}
//Rcon
//############################################



// ############################################
// CommandProtect ################################
public Action:Commands_EventDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:f_sReason[512], String:f_sTemp[512], f_iLength, client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "reason", f_sReason, sizeof(f_sReason));
	GetEventString(event, "name", f_sTemp, sizeof(f_sTemp));
	f_iLength = strlen(f_sReason)+strlen(f_sTemp);
	GetEventString(event, "networkid", f_sTemp, sizeof(f_sTemp));
	
	f_iLength += strlen(f_sTemp);
	if ( f_iLength > 235 )
	{
		if ( IS_CLIENT(client) && IsClientConnected(client) )
		{
			SMAC_LogAction(client, "submitted a bad disconnect reason, length %d, \"%s\"", f_iLength, f_sReason);
		}
		else
		{
			SMAC_Log("Bad disconnect reason, length %d, \"%s\"", f_iLength, f_sReason);
		}
		
		SetEventString(event, "reason", "Bad disconnect message");
		return Plugin_Continue;
	}
	
	f_iLength = strlen(f_sReason);
	for (new i = 0; i < f_iLength; i++)
	{
		if ( f_sReason[i] < 32 && f_sReason[i] != '\n' )
		{
			if ( IS_CLIENT(client) && IsClientConnected(client) )
			{
				SMAC_LogAction(client, "submitted a bad disconnect reason, \"%s\" len = %d. Possible corruption or attack.", f_sReason, f_iLength);
			}
			else
			{
				SMAC_Log("Bad disconnect reason, \"%s\" len = %d. Possible corruption or attack.", f_sReason, f_iLength);
			}
			
			SetEventString(event, "reason", "Bad disconnect message");
			return Plugin_Continue;
		}
	}
	
	return Plugin_Continue;
}

//- Admin Commands -//

public Action:Commands_AddCmd(client, args)
{
	if ( args != 2 )
	{
		ReplyToCommand(client, "Usage: smac_addcmd <command name> <ban (1 or 0)>");
		return Plugin_Handled;
	}

	decl String:f_sCmdName[64], String:f_sTemp[8], bool:f_bBan;
	GetCmdArg(1, f_sCmdName, sizeof(f_sCmdName));

	GetCmdArg(2, f_sTemp, sizeof(f_sTemp));
	if ( StringToInt(f_sTemp) != 0 || StrEqual(f_sTemp, "ban") || StrEqual(f_sTemp, "yes") || StrEqual(f_sTemp, "true") )
		f_bBan = true;
	else
		f_bBan = false;

	if ( SetTrieValue(g_hBlockedCmds, f_sCmdName, f_bBan) )
		ReplyToCommand(client, "You have successfully added %s to the command block list.", f_sCmdName);
	else
		ReplyToCommand(client, "%s already exists in the command block list.", f_sCmdName);
	return Plugin_Handled;
}

public Action:Commands_AddIgnoreCmd(client, args)
{
	if ( args != 1 )
	{
		ReplyToCommand(client, "Usage: smac_addignorecmd <command name>");
		return Plugin_Handled;
	}

	decl String:f_sCmdName[64];

	GetCmdArg(1, f_sCmdName, sizeof(f_sCmdName));

	if ( SetTrieValue(g_hIgnoredCmds, f_sCmdName, true) )
		ReplyToCommand(client, "You have successfully added %s to the command ignore list.", f_sCmdName);
	else
		ReplyToCommand(client, "%s already exists in the command ignore list.", f_sCmdName);
	return Plugin_Handled;
}

public Action:Commands_RemoveCmd(client, args)
{
	if ( args != 1 )
	{
		ReplyToCommand(client, "Usage: smac_removecmd <command name>");
		return Plugin_Handled;
	}

	decl String:f_sCmdName[64];
	GetCmdArg(1, f_sCmdName, sizeof(f_sCmdName));

	if ( RemoveFromTrie(g_hBlockedCmds, f_sCmdName) )
		ReplyToCommand(client, "You have successfully removed %s from the command block list.", f_sCmdName);
	else
		ReplyToCommand(client, "%s is not in the command block list.", f_sCmdName);
	return Plugin_Handled;
}

public Action:Commands_RemoveIgnoreCmd(client, args)
{
	if ( args != 1 )
	{
		ReplyToCommand(client, "Usage: smac_removeignorecmd <command name>");
		return Plugin_Handled;
	}

	decl String:f_sCmdName[64];
	GetCmdArg(1, f_sCmdName, sizeof(f_sCmdName));

	if ( RemoveFromTrie(g_hIgnoredCmds, f_sCmdName) )
		ReplyToCommand(client, "You have successfully removed %s from the command ignore list.", f_sCmdName);
	else
		ReplyToCommand(client, "%s is not in the command ignore list.", f_sCmdName);
	return Plugin_Handled;
}

//- Console Commands -//

public Action:Commands_BlockExploit(client, const String:command[], args)
{
	if ( args > 0 )
	{
		decl String:f_sArg[64];
		GetCmdArg(1, f_sArg, sizeof(f_sArg));
		if ( StrEqual(f_sArg, "rcon_password") )
		{
			decl String:f_sCmdString[256];
			GetCmdArgString(f_sCmdString, sizeof(f_sCmdString));
			SMAC_PrintAdminNotice("%N was banned for command usage violation of command: sm_menu %s", client, f_sCmdString);
			SMAC_LogAction(client, "was banned for command usage violation of command: sm_menu %s", f_sCmdString);
			SMAC_Ban(client, "Exploit violation");
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action:Commands_FilterSay(client, const String:command[], args)
{
	if (!IS_CLIENT(client))
		return Plugin_Continue;

	new iSpaceNum;
	decl String:f_sMsg[256], f_iLen, String:f_cChar;
	GetCmdArgString(f_sMsg, sizeof(f_sMsg));
	f_iLen = strlen(f_sMsg);
	for(new i=0;i<f_iLen;i++)
	{
		f_cChar = f_sMsg[i];
		
		if ( f_cChar == ' ' )
		{
			if ( iSpaceNum++ >= 64 )
			{
				PrintToChat(client, "%t", "SMAC_SayBlock");
				return Plugin_Stop;
			}
		}
			
		if ( f_cChar < 32 && !IsCharMB(f_cChar) )
		{
			PrintToChat(client, "%t", "SMAC_SayBlock");
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action:Commands_BlockEntExploit(client, const String:command[], args)
{
	if ( !g_iCmdSpam || !IS_CLIENT(client) )
		return Plugin_Continue;
	
	if ( !IsClientInGame(client) )
		return Plugin_Stop;
	
	decl String:f_sCmd[512];
	GetCmdArgString(f_sCmd, sizeof(f_sCmd));
	if ( strlen(f_sCmd) > 500 )
		return Plugin_Stop; // Too long to process.
	if ( StrContains(f_sCmd, "point_servercommand") != -1 	|| StrContains(f_sCmd, "point_clientcommand") != -1 
	  || StrContains(f_sCmd, "logic_timer") != -1 	   	|| StrContains(f_sCmd, "quit") != -1
	  || StrContains(f_sCmd, "sm") != -1 		   	|| StrContains(f_sCmd, "quti") != -1 
	  || StrContains(f_sCmd, "restart") != -1 		|| StrContains(f_sCmd, "alias") != -1
	  || StrContains(f_sCmd, "admin") != -1 		|| StrContains(f_sCmd, "ma_") != -1 
	  || StrContains(f_sCmd, "rcon") != -1 			|| StrContains(f_sCmd, "sv_") != -1 
	  || StrContains(f_sCmd, "mp_") != -1 			|| StrContains(f_sCmd, "meta") != -1 
	  || StrContains(f_sCmd, "taketimer") != -1 		|| StrContains(f_sCmd, "logic_relay") != -1 
	  || StrContains(f_sCmd, "logic_auto") != -1 		|| StrContains(f_sCmd, "logic_autosave") != -1 
	  || StrContains(f_sCmd, "logic_branch") != -1 		|| StrContains(f_sCmd, "logic_case") != -1 
	  || StrContains(f_sCmd, "logic_collision_pair") != -1  || StrContains(f_sCmd, "logic_compareto") != -1 
	  || StrContains(f_sCmd, "logic_lineto") != -1 		|| StrContains(f_sCmd, "logic_measure_movement") != -1 
	  || StrContains(f_sCmd, "logic_multicompare") != -1 	|| StrContains(f_sCmd, "logic_navigation") != -1 )
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Commands_CommandListener(client, const String:command[], argc)
{
	if ( !g_iCmdSpam || !IS_CLIENT(client) || (IsClientConnected(client) && IsFakeClient(client)) )
		return Plugin_Continue;
		
	if ( !IsClientInGame(client) )
		return Plugin_Stop;

	decl bool:f_bBan, String:f_sCmd[64];
	
	strcopy(f_sCmd, sizeof(f_sCmd),	command);
	StringToLower(f_sCmd);

	// Check to see if this person is command spamming.
	if ( !GetTrieValue(g_hIgnoredCmds, f_sCmd, f_bBan) && ++g_iCmdCount[client] > g_iCmdSpam )
	{
		if ( !IsClientInKickQueue(client) && SMAC_CheatDetected(client) == Plugin_Continue )
		{
			decl String:f_sCmdString[128];
			GetCmdArgString(f_sCmdString, sizeof(f_sCmdString));
			SMAC_PrintAdminNotice("%N was kicked for command spamming: %s %s", client, command, f_sCmdString);
			SMAC_LogAction(client, "was kicked for command spamming: %s %s", command, f_sCmdString);
			KickClient(client, "%t", "SMAC_CommandSpamKick");
		}
		
		return Plugin_Stop;
	}

	if ( GetTrieValue(g_hBlockedCmds, f_sCmd, f_bBan) )
	{
		if ( f_bBan && SMAC_CheatDetected(client) == Plugin_Continue )
		{
			decl String:f_sCmdString[256];
			GetCmdArgString(f_sCmdString, sizeof(f_sCmdString));
			SMAC_PrintAdminNotice("%N was banned for command usage violation of command: %s %s", client, command, f_sCmdString);
			SMAC_LogAction(client, "was banned for command usage violation of command: %s %s", command, f_sCmdString);
			SMAC_Ban(client, "Command %s violation", command);
		}
		
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

//- Timers -//

public Action:Timer_CountReset(Handle:timer, any:args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		g_iCmdCount[i] = 0;
	}
	
	return Plugin_Continue;
}

public OnSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iCmdSpam = GetConVarInt(convar);
}

//- Private -//

stock StringToLower(String:f_sInput[])
{
	new f_iSize = strlen(f_sInput);
	for(new i=0;i<f_iSize;i++)
		f_sInput[i] = CharToLower(f_sInput[i]);
}
// CommandProtect ################################
// ############################################


// ############################################
// AutoT ######################################
public OnClientDisconnect_Post(client)
{
	for (new i = 0; i < METHOD_MAX; i++)
	{
		g_iDetections[i][client] = 0;
	}
	
	g_fDetectedTime[client] = 0.0;
}

public Action:Timer_DecreaseCount(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		for (new j = 0; j < METHOD_MAX; j++)
		{
			if (g_iDetections[j][i])
			{
				g_iDetections[j][i]--;
			}
		}
	}
	
	return Plugin_Continue;
}

// ##################################
// Speed
public OnTickCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarInt(convar) != 1)
	{
		SetConVarInt(convar, 1);
	}
}

public Action:Timer_ResetTicks(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		g_iTickCount[i] = 0;
	}
	
	return Plugin_Continue;
}
// Speed
//####################################

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static iPrevButtons[MAXPLAYERS+1];
	
	/* BunnyHop */
	static bool:bCheckNextJump[MAXPLAYERS+1];

	// Player didn't jump immediately after the last jump.
	if (bCheckNextJump[client] && !(buttons & IN_JUMP) && (GetEntityFlags(client) & FL_ONGROUND))
	{
		bCheckNextJump[client] = false;
	}
	
	if ((buttons & IN_JUMP) && !(iPrevButtons[client] & IN_JUMP))
	{
		// Player is on the ground and about to trigger a jump.
		if (GetEntityFlags(client) & FL_ONGROUND)
		{
			// Player jumped on the exact frame that allowed it.
			if (bCheckNextJump[client])
			{
				AutoTrigger_Detected(client, METHOD_BUNNYHOP);
			}
			else
			{
				bCheckNextJump[client] = true;
			}
		}
		else
		{
			bCheckNextJump[client] = false;
		}
	}
	
	/* Auto-Fire 1 */
	static bool:bCheckNextShot[MAXPLAYERS+1];
	
	// Player didn't shoot immediately after the last shot.
	if (bCheckNextShot[client] && !(buttons & IN_ATTACK) && CanShootWeapon(client))
	{
		bCheckNextShot[client] = false;
	}
	
	if ((buttons & IN_ATTACK) && !(iPrevButtons[client] & IN_ATTACK))
	{
		// Player is about to shoot.
		if (CanShootWeapon(client))
		{
			// Player shot on the exact frame that allowed it.
			if (bCheckNextShot[client])
			{
				AutoTrigger_Detected(client, METHOD_AUTOFIRE1);
			}
			else
			{
				bCheckNextShot[client] = true;
			}
		}
		else
		{
			bCheckNextShot[client] = false;
		}
	}
	
	/* Auto-Fire 2 */
	static iAttackAmt[MAXPLAYERS+1];
	static bool:bResetNext[MAXPLAYERS+1];
	
	if (((buttons & IN_ATTACK) && !(iPrevButtons[client] & IN_ATTACK)) || 
		(!(buttons & IN_ATTACK) && (iPrevButtons[client] & IN_ATTACK)))
	{
		if (++iAttackAmt[client] >= g_iAttackMax)
		{
			AutoTrigger_Detected(client, METHOD_AUTOFIRE2);
			iAttackAmt[client] = 0;
		}
		
		bResetNext[client] = false;
	}
	else if (bResetNext[client])
	{
		iAttackAmt[client] = 0;
		bResetNext[client] = false;
	}
	else
	{
		bResetNext[client] = true;
	}

	iPrevButtons[client] = buttons;
	
//################################
//Eye in AutoT
	// Check for valid angles. +/- normal limit * 1.5 as a buffer zone.
	if (angles[0] > -135.0 && angles[0] < 135.0 && angles[1] > -270.0 && angles[1] < 270.0)
	{
		return Plugin_Continue;
	}
	
	// Ignore bots and dead clients.
	if (IsFakeClient(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	// Game specific checks.
	switch (SMAC_GetGameType())
	{
		case Game_DODS:
		{
			// Ignore prone players.
			if (DODS_IsPlayerProne(client))
			{
				return Plugin_Continue;
			}
		}
		
		case Game_L4D, Game_L4D2:
		{
			// Only check survivors in first-person view.
			static Float:fLastBusy = 0.0;
			new iTeam = GetClientTeam(client);

			if (iTeam == 2 && L4D_IsSurvivorBusy(client))
			{
				fLastBusy = GetTickedTime() + 10.0;
				return Plugin_Continue;
			}
			else if (iTeam != 2 || fLastBusy > GetTickedTime())
			{
				return Plugin_Continue;
			}
		}
	}
	
	// Ignore clients that are interacting with the map.
	new flags = GetEntityFlags(client);
	if (flags & FL_FROZEN || flags & FL_ATCONTROLS)
	{
		return Plugin_Continue;
	}
	
	// The client failed all checks.
	Eyetest_Detected(client, angles);
// Eye in AutoT
//#############################

	if (++g_iTickCount[client] > g_iTickRate)
	{
		return Plugin_Handled; 
	}

	return Plugin_Continue;
}

bool:CanShootWeapon(client)
{
	/* Check if this client's weapon can be fired. */
	new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	if (weapon != -1 && IsValidEntity(weapon))
	{
		decl String:sNetClass[64];
		
		if (GetEntityNetClass(weapon, sNetClass, sizeof(sNetClass)))
		{
			new offset = FindSendPropOffs(sNetClass, "m_flNextPrimaryAttack");
			
			if (offset != -1 && GetGameTime() >= GetEntDataFloat(weapon, offset))
			{
				return true;
			}
		}
	}
	
	return false;
}

AutoTrigger_Detected(client, method)
{
	if (!IsFakeClient(client) && IsPlayerAlive(client) && ++g_iDetections[method][client] >= TRIGGER_DETECTIONS)
	{
		if (SMAC_CheatDetected(client) == Plugin_Continue)
		{
			decl String:sMethod[32], String:sName[MAX_NAME_LENGTH];

			switch (method)
			{
				case METHOD_BUNNYHOP:
				{
					strcopy(sMethod, sizeof(sMethod), "BunnyHop");
				}
				case METHOD_AUTOFIRE1:
				{
					strcopy(sMethod, sizeof(sMethod), "Auto-Fire (1)");
				}
				case METHOD_AUTOFIRE2:
				{
					strcopy(sMethod, sizeof(sMethod), "Auto-Fire (2)");
				}
			}
			
			GetClientName(client, sName, sizeof(sName));
			SMAC_PrintAdminNotice("%t", "SMAC_AutoTriggerDetected", sName, sMethod);
			
			if (GetConVarBool(g_hCvarBan))
			{
				SMAC_LogAction(client, "was banned for using auto-trigger cheat: %s", sMethod);
				SMAC_Ban(client, "AutoTrigger Detection: %s", sMethod);
			}
			else
			{
				SMAC_LogAction(client, "is suspected of using auto-trigger cheat: %s", sMethod);
			}
		}
		
		g_iDetections[method][client] = 0;
	}
}
// AutoT ######################################
// ############################################


//#############
//Eye
Eyetest_Detected(client, const Float:angles[3])
{
	// Allow the same player to be processed once every 30 seconds.
	if (!IsFakeClient(client) && GetGameTime() > g_fDetectedTime[client])
	{
		g_fDetectedTime[client] = GetGameTime() + 30.0;
		
		if (SMAC_CheatDetected(client) == Plugin_Continue)
		{
			decl String:sName[MAX_NAME_LENGTH];
			GetClientName(client, sName, sizeof(sName));
			
			SMAC_PrintAdminNotice("%t", "SMAC_EyetestDetected", sName);
			
			if (GetConVarBool(g_hCvarBan))
			{
				SMAC_LogAction(client, "was banned for cheating with their eye angles. Eye Angles: %.0f %.0f %.0f", angles[0], angles[1], angles[2]);
				SMAC_Ban(client, "Eye Angles Violation");
			}
			else
			{
				SMAC_LogAction(client, "is suspected of cheating with their eye angles. Eye Angles: %.0f %.0f %.0f", angles[0], angles[1], angles[2]);
			}
		}
	}
}
//Eye
//##################


public OnAllPluginsLoaded()
{
	// Wait for other modules to create their convars.
	AutoExecConfig(true, "smac");
	
	PrintToServer("SourceMod Anti-Cheat %s has been successfully loaded.", SMAC_VERSION);
}

public OnClientPutInServer(client)
{
	if (GetConVarBool(g_hCvarWelcomeMsg))
	{
		CreateTimer(10.0, Timer_WelcomeMsg, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_WelcomeMsg(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (client && IsClientInGame(client))
	{
		CPrintToChat(client, "%t%t", "SMAC_Tag", "SMAC_WelcomeMsg");
	}
		
	return Plugin_Stop;
}

/* API - Natives & Forwards */

new Handle:g_OnCheatDetected = INVALID_HANDLE;

API_Init()
{
	CreateNative("SMAC_GetGameType", Native_GetGameType);
	CreateNative("SMAC_Log", Native_Log);
	CreateNative("SMAC_LogAction", Native_LogAction);
	CreateNative("SMAC_Ban", Native_Ban);
	CreateNative("SMAC_PrintAdminNotice", Native_PrintAdminNotice);
	CreateNative("SMAC_CreateConVar", Native_CreateConVar);
	CreateNative("SMAC_CheatDetected", Native_CheatDetected);
	
	g_OnCheatDetected = CreateGlobalForward("SMAC_OnCheatDetected", ET_Event, Param_Cell, Param_String);
}

// native GameType:SMAC_GetGameType();
public Native_GetGameType(Handle:plugin, numParams)
{
	return _:g_Game;
}

// native SMAC_Log(const String:format[], any:...);
public Native_Log(Handle:plugin, numParams)
{
	decl String:sFilename[64], String:sBuffer[256];
	GetPluginBasename(plugin, sFilename, sizeof(sFilename));
	FormatNativeString(0, 1, 2, sizeof(sBuffer), _, sBuffer);
	LogToFileEx(g_sLogPath, "[%s] %s", sFilename, sBuffer);
}

// native SMAC_LogAction(client, const String:format[], any:...);
public Native_LogAction(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (!IS_CLIENT(client) || !IsClientConnected(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	decl String:sName[MAX_NAME_LENGTH], String:sAuthID[32], String:sIP[17];
	if (!GetClientName(client, sName, sizeof(sName)))
	{
		strcopy(sName, sizeof(sName), "Unknown");
	}
	if (!GetClientAuthString(client, sAuthID, sizeof(sAuthID)))
	{
		strcopy(sAuthID, sizeof(sAuthID), "Unknown");
	}
	if (!GetClientIP(client, sIP, sizeof(sIP)))
	{
		strcopy(sIP, sizeof(sIP), "Unknown");
	}
	
	decl String:sFilename[64], String:sBuffer[256];
	GetPluginBasename(plugin, sFilename, sizeof(sFilename));
	FormatNativeString(0, 2, 3, sizeof(sBuffer), _, sBuffer);
	LogToFileEx(g_sLogPath, "[%s] %s (ID: %s | IP: %s) %s", sFilename, sName, sAuthID, sIP, sBuffer);
}

// native SMAC_Ban(client, const String:reason[], any:...);
public Native_Ban(Handle:plugin, numParams)
{
	decl String:sReason[256];
	new client = GetNativeCell(1);
	new duration = GetConVarInt(g_hCvarBanDuration);
	
	FormatNativeString(0, 2, 3, sizeof(sReason), _, sReason);
	Format(sReason, sizeof(sReason), "SMAC: %s", sReason);
	
	if (GetFeatureStatus(FeatureType_Native, "SBBanPlayer") == FeatureStatus_Available)
	{
		SBBanPlayer(0, client, duration, sReason);
	}
	else
	{
		decl String:sKickMsg[256];
		FormatEx(sKickMsg, sizeof(sKickMsg), "%T", "SMAC_Banned", client);
		BanClient(client, duration, BANFLAG_AUTO, sReason, sKickMsg, "SMAC");
	}
}

// native SMAC_PrintAdminNotice(const String:format[], any:...);
public Native_PrintAdminNotice(Handle:plugin, numParams)
{
	decl String:sBuffer[192];

	for (new i = 1; i <= MaxClients; i++)
	{
		if (CheckCommandAccess(i, "smac_admin_notices", ADMFLAG_GENERIC, true))
		{
			SetGlobalTransTarget(i);
			FormatNativeString(0, 1, 2, sizeof(sBuffer), _, sBuffer);
			CPrintToChat(i, "%t%s", "SMAC_Tag", sBuffer);
		}
	}
	
	// SourceIRC
	if (GetFeatureStatus(FeatureType_Native, "IRC_MsgFlaggedChannels") == FeatureStatus_Available)
	{
		SetGlobalTransTarget(LANG_SERVER);
		FormatNativeString(0, 1, 2, sizeof(sBuffer), _, sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%t%s", "SMAC_Tag", sBuffer);
		CRemoveTags(sBuffer, sizeof(sBuffer));
		IRC_MsgFlaggedChannels("ticket", sBuffer);
	}
	
	// IRC Relay
	if (GetFeatureStatus(FeatureType_Native, "IRC_Broadcast") == FeatureStatus_Available)
	{
		SetGlobalTransTarget(LANG_SERVER);
		FormatNativeString(0, 1, 2, sizeof(sBuffer), _, sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%t%s", "SMAC_Tag", sBuffer);
		CRemoveTags(sBuffer, sizeof(sBuffer));
		IRC_Broadcast(IrcChannel_Private, sBuffer);
	}
}

// native Handle:SMAC_CreateConVar(const String:name[], const String:defaultValue[], const String:description[]="", flags=0, bool:hasMin=false, Float:min=0.0, bool:hasMax=false, Float:max=0.0);
public Native_CreateConVar(Handle:plugin, numParams)
{
	decl String:name[64], String:defaultValue[16], String:description[192];
	GetNativeString(1, name, sizeof(name));
	GetNativeString(2, defaultValue, sizeof(defaultValue));
	GetNativeString(3, description, sizeof(description));
	
	new flags = GetNativeCell(4);
	new bool:hasMin = bool:GetNativeCell(5);
	new Float:min = Float:GetNativeCell(6);
	new bool:hasMax = bool:GetNativeCell(7);
	new Float:max = Float:GetNativeCell(8);
	
	decl String:sFilename[64];
	GetPluginBasename(plugin, sFilename, sizeof(sFilename));
	Format(description, sizeof(description), "[%s] %s", sFilename, description);
	
	return _:CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
}

// native Action:SMAC_CheatDetected(client);
public Native_CheatDetected(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (!IS_CLIENT(client) || !IsClientConnected(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	}
	
	decl String:sFilename[64];
	GetPluginBasename(plugin, sFilename, sizeof(sFilename));
	
	// forward Action:SMAC_OnCheatDetected(client, const String:module[]);
	new Action:result = Plugin_Continue;
	Call_StartForward(g_OnCheatDetected);
	Call_PushCell(client);
	Call_PushString(sFilename);
	Call_Finish(result);
	
	return _:result;
}
