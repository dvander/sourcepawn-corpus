#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdktools_voice>
#include <sdkhooks>
#include <sendproxy>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <readyup>
#include <left4dhooks>
#include "l4d2_ttt_karma.inc"

#define PLUGIN_VERSION "0.5-alpha"

// ============================================================================
// Role constants
// ============================================================================
#define ROLE_NONE       0
#define ROLE_INNOCENT   1
#define ROLE_TRAITOR    2
#define ROLE_DETECTIVE  3

// ============================================================================
// Glow constants
//   m_iGlowType: 0 = off, 3 = steady (visible through walls)
//   m_glowColorOverride encoding: R + (G * 256) + (B * 65536)
// ============================================================================
#define GLOW_TYPE_OFF       0
#define GLOW_TYPE_STEADY    3

#define GLOW_COLOR_RED      255       // R=255, G=0,   B=0
#define GLOW_COLOR_BLUE     16711680  // R=0,   G=0,   B=255
#define GLOW_COLOR_GREEN    65280     // R=0,   G=255, B=0

// ============================================================================
// Plugin info
// ============================================================================
public Plugin myinfo =
{
	name        = "[L4D2] Trouble in Terrorist Town",
	author      = "Not HaTs",
	description = "TTT Gamemode",
	version     = PLUGIN_VERSION,
	url         = ""
};

#define MAX_ROUND_ACTIONS 32

char g_sActionLog[MAXPLAYERS + 1][MAX_ROUND_ACTIONS][128];
int  g_iActionCredits[MAXPLAYERS + 1][MAX_ROUND_ACTIONS];
int  g_iActionCount[MAXPLAYERS + 1];

// ============================================================================
// Game state globals
// ============================================================================
bool  g_bRoundLive                      = false;
int   g_iPlayerRole[MAXPLAYERS + 1];
bool  g_bWantsDetective[MAXPLAYERS + 1];
bool  g_bNextRoundTraitor[MAXPLAYERS + 1];
Handle g_hCookieCredits;
int   g_iCredits[MAXPLAYERS + 1];
int   g_iSpriteEntity[MAXPLAYERS + 1];

float g_fWallhackEndTime[MAXPLAYERS + 1];
int   g_iWallhackSprite[MAXPLAYERS + 1][MAXPLAYERS + 1];
int   g_iWallhackSpriteOwner[2048];

// Ragdoll tracking
int   g_RagdollRole[2048];
bool  g_RagdollScanned[2048];
char  g_RagdollName[2048][MAX_NAME_LENGTH];
char  g_RagdollWeapon[2048][64];
float g_RagdollTimeOfDeath[2048];
bool  g_bRagdollIdentified[2048];
char  g_RagdollKiller[2048][MAX_NAME_LENGTH];
int   g_iCorpseIdentifiers[MAXPLAYERS + 1];
int   g_iLastButtons[MAXPLAYERS + 1];
float g_fLastChatHint[MAXPLAYERS + 1];
bool  g_bHasSeenHint[MAXPLAYERS + 1];
int   g_iPillsHealAmount[MAXPLAYERS + 1];
Handle g_hPillsTimer[MAXPLAYERS + 1];
bool  g_bHasKevlar[MAXPLAYERS + 1];
bool  g_bHasHelmet[MAXPLAYERS + 1];
int   g_iTaserTarget[MAXPLAYERS + 1];
float g_fTaserEndTime[MAXPLAYERS + 1];
int   g_iTaserSprite[MAXPLAYERS + 1];
float g_fLastAimHint[MAXPLAYERS + 1];
int   g_iLastAimTarget[MAXPLAYERS + 1];
float g_fLastValidAimTime[MAXPLAYERS + 1];
int   g_iLastValidAimTarget[MAXPLAYERS + 1];
bool  g_bLastValidAimIsPlayer[MAXPLAYERS + 1];

// Missile state
bool  g_bBoughtMissile[MAXPLAYERS + 1];
int   g_iActiveMissile[MAXPLAYERS + 1];
float g_fMissileEndTime[MAXPLAYERS + 1];
float g_fLastPipeThrowTime[MAXPLAYERS + 1];

// C4 state
bool  g_bBoughtC4[MAXPLAYERS + 1];
int   g_iC4Entity[MAXPLAYERS + 1];
int   g_iC4PackEnt[MAXPLAYERS + 1];
int   g_iC4CorrectWire[MAXPLAYERS + 1];
int   g_iC4WrongAttempts[MAXPLAYERS + 1];
float g_fC4ExplodeTime[MAXPLAYERS + 1];
Handle g_hC4DefuseTimer[MAXPLAYERS + 1];
int   g_iMenuC4Owner[MAXPLAYERS + 1];
bool  g_bHasDefuser[MAXPLAYERS + 1];
bool  g_bC4WireCut[MAXPLAYERS + 1][6];
bool  g_bC4DefuserUsed[MAXPLAYERS + 1][MAXPLAYERS + 1];
int   g_iC4DefuserFakeWire[MAXPLAYERS + 1][MAXPLAYERS + 1];

float g_fImmortalityEndTime[MAXPLAYERS + 1];

float g_fHordeCooldownEndTime = 0.0;

float g_fSpecialCooldownEndTime = 0.0;

// ============================================================================
// Survivor character ID constants (m_survivorCharacter)
// ============================================================================
#define CHAR_NICK       0   // L4D2 — Gambler    — survivor_gambler.mdl
#define CHAR_ROCHELLE   1   // L4D2 — Producer   — survivor_producer.mdl
#define CHAR_COACH      2   // L4D2 — Coach      — survivor_coach.mdl
#define CHAR_ELLIS      3   // L4D2 — Mechanic   — survivor_mechanic.mdl
#define CHAR_BILL       4   // L4D1 — Namvet     — survivor_namvet.mdl
#define CHAR_ZOEY       5   // L4D1 — Teenangst  — survivor_teenangst.mdl
#define CHAR_FRANCIS    6   // L4D1 — Biker      — survivor_biker.mdl
#define CHAR_LOUIS      7   // L4D1 — Manager    — survivor_manager.mdl

// Original Character Storage
int   g_iOriginalChar[MAXPLAYERS + 1] = {-1, ...};
char  g_sOriginalModel[MAXPLAYERS + 1][128];
bool  g_bIsL4D1Map = false;

char g_sModelPaths[8][64] = {
	"models/survivors/survivor_gambler.mdl",   // 0 Nick
	"models/survivors/survivor_producer.mdl",  // 1 Rochelle
	"models/survivors/survivor_coach.mdl",     // 2 Coach
	"models/survivors/survivor_mechanic.mdl",  // 3 Ellis
	"models/survivors/survivor_namvet.mdl",    // 4 Bill
	"models/survivors/survivor_teenangst.mdl", // 5 Zoey
	"models/survivors/survivor_biker.mdl",     // 6 Francis
	"models/survivors/survivor_manager.mdl"    // 7 Louis
};

// Traitor traps
bool  g_bTraitorSpawning             = false;
bool  g_bTraitorSpawned[MAXPLAYERS + 1];
bool  g_bHordeActive                 = false;
bool  g_bWitchSpawning               = false;
int   g_iZombieOwner[MAXPLAYERS + 1];
float g_fTankCooldownEndTime[MAXPLAYERS + 1];
int   g_iCurrentPrimaryWeapon[MAXPLAYERS + 1];
bool  g_bHasLootbox[MAXPLAYERS + 1];
int   g_iLootboxCrateRef[MAXPLAYERS + 1];
bool  g_bIsCustomBot[MAXPLAYERS + 1];
bool  g_bPendingCustomBot         = false;
int   g_iPendingBotTeleportClient = 0;

// Round manager
int   g_iCurrentRound                = 1;
bool  g_bTruceActive                 = false;
bool  g_bRoundEnded                  = false;
bool  g_bRandomizerActive             = false;
int   g_iTruceTimeLeft               = 0;
float g_fRoundStartTime              = 0.0;
int   g_iRoundTimeLeft               = 300;
int   g_iLastTimeLeftDrawn[MAXPLAYERS + 1];
Handle g_hRoundTimer                 = null;

// Weapon
ArrayList g_aConfigPos;
ArrayList g_aConfigAng;
ArrayList g_aConfigMod;
ArrayList g_aAmmoPos;
ArrayList g_aAmmoAng;
ArrayList g_aPlayerSpawns;

// ============================================================================
// RTV System
// ============================================================================
int g_iMaxRounds = 12;
bool g_bVoteActive = false;
int g_iVotes[32];
int g_iPlayerVote[MAXPLAYERS+1];
Handle g_hVoteTimer = null;
Handle g_hVoteUpdateTimer = null;
int g_iWinningVote = -1;
int g_iRTVTimeLeft = 0;
bool g_bHasRTVMenuOpen[MAXPLAYERS+1];

ArrayList g_aRTVMapNames;
ArrayList g_aRTVMapDisplays;

ConVar cv_ttt_rtv_enabled;
ConVar cv_ttt_rtv_extend_rounds;
ConVar cv_ttt_rtv_vote_duration;
ConVar cv_ttt_max_rounds;

// ============================================================================
// Shop CVars
// ============================================================================
ConVar cv_ttt_shop_enabled;
ConVar cv_ttt_shop_price_kevlar;
ConVar cv_ttt_shop_price_kevlar_helmet;
ConVar cv_ttt_shop_price_ammo;
ConVar cv_ttt_shop_price_pills;
ConVar cv_ttt_shop_price_deagle;
ConVar cv_ttt_shop_price_bat;
ConVar cv_ttt_shop_price_taser;
ConVar cv_ttt_shop_price_defuser;
ConVar cv_ttt_shop_price_identifier;
ConVar cv_ttt_shop_price_lootbox;
ConVar cv_ttt_shop_price_wallhack;
ConVar cv_ttt_shop_price_horde;
ConVar cv_ttt_shop_price_special;
ConVar cv_ttt_shop_price_gl;
ConVar cv_ttt_shop_price_c4;
ConVar cv_ttt_shop_price_missile;
ConVar cv_ttt_shop_price_tank;
ConVar cv_ttt_shop_price_traitor_next;
ConVar cv_ttt_shop_price_detective_now;
ConVar cv_ttt_shop_price_traitor_now;
ConVar cv_ttt_shop_price_immortality;

ConVar cv_ttt_shop_immortality_duration;
ConVar cv_ttt_shop_horde_cooldown;
ConVar cv_ttt_shop_infected_cooldown;
ConVar cv_ttt_shop_tank_cooldown;

// ============================================================================
// Economy CVars
// ============================================================================
ConVar cv_ttt_credits_kill_traitor;
ConVar cv_ttt_credits_kill_detective;
ConVar cv_ttt_credits_kill_innocent;
ConVar cv_ttt_credits_survive;
ConVar cv_ttt_credits_defuse_c4;
ConVar cv_ttt_credits_kill_tank;
ConVar cv_ttt_credits_kill_witch;
ConVar cv_ttt_credits_kill_special;

// ============================================================================
// Role & Round CVars
// ============================================================================
ConVar cv_ttt_role_traitor_ratio;
ConVar cv_ttt_role_detective_ratio;
ConVar cv_ttt_round_duration;
ConVar cv_ttt_truce_duration;

// ============================================================================
// Glow state
// ============================================================================
bool g_bGlowHooked[MAXPLAYERS + 1];

// ============================================================================
// HUD / GameMode Spoofing Globals
// ============================================================================
int g_iManagerEnt = -1;

stock void SetScreenOverlay(int client, const char[] overlay)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client)) return;
	
	int flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", flags);
}

// ============================================================================
// OnPluginStart
// ============================================================================
public void OnPluginStart()
{
	LoadTranslations("l4d2_ttt_phrases");
	g_aConfigPos = new ArrayList(3);
	g_aConfigAng = new ArrayList(3);
	g_aConfigMod = new ArrayList(1);
	g_aAmmoPos   = new ArrayList(3);
	g_aAmmoAng   = new ArrayList(3);
	g_aPlayerSpawns = new ArrayList(3);
	g_aRTVMapNames = new ArrayList(ByteCountToCells(64));
	g_aRTVMapDisplays = new ArrayList(ByteCountToCells(128));

	cv_ttt_rtv_enabled = CreateConVar("ttt_rtv_enabled", "1", "Enable or disable the RTV system at the end of the round.", FCVAR_NOTIFY);
	cv_ttt_rtv_extend_rounds = CreateConVar("ttt_rtv_extend_rounds", "6", "Number of rounds added when 'Extend Map' wins.", FCVAR_NOTIFY);
	cv_ttt_rtv_vote_duration = CreateConVar("ttt_rtv_vote_duration", "30", "Duration of the RTV vote in seconds.", FCVAR_NOTIFY);
	cv_ttt_max_rounds = CreateConVar("ttt_max_rounds", "12", "Default number of rounds per map before RTV or map restart.", FCVAR_NOTIFY);

	cv_ttt_shop_enabled = CreateConVar("ttt_shop_enabled", "1", "Enable or disable the Shop system.", FCVAR_NOTIFY);
	cv_ttt_shop_price_kevlar = CreateConVar("ttt_shop_price_kevlar", "1", "Price for Kevlar (set -1 to disable).", FCVAR_NOTIFY);
	cv_ttt_shop_price_kevlar_helmet = CreateConVar("ttt_shop_price_kevlar_helmet", "2", "Price for Kevlar + Helmet.", FCVAR_NOTIFY);
	cv_ttt_shop_price_ammo = CreateConVar("ttt_shop_price_ammo", "1", "Price for Ammo refill.", FCVAR_NOTIFY);
	cv_ttt_shop_price_pills = CreateConVar("ttt_shop_price_pills", "4", "Price for Pain Pills.", FCVAR_NOTIFY);
	cv_ttt_shop_price_deagle = CreateConVar("ttt_shop_price_deagle", "3", "Price for Desert Eagle.", FCVAR_NOTIFY);
	cv_ttt_shop_price_bat = CreateConVar("ttt_shop_price_bat", "2", "Price for Baseball Bat.", FCVAR_NOTIFY);
	cv_ttt_shop_price_taser = CreateConVar("ttt_shop_price_taser", "5", "Price for Taser.", FCVAR_NOTIFY);
	cv_ttt_shop_price_defuser = CreateConVar("ttt_shop_price_defuser", "2", "Price for C4 Defuser.", FCVAR_NOTIFY);
	cv_ttt_shop_price_identifier = CreateConVar("ttt_shop_price_identifier", "3", "Price for Corpse Identifier.", FCVAR_NOTIFY);
	cv_ttt_shop_price_lootbox = CreateConVar("ttt_shop_price_lootbox", "8", "Price for Lootbox.", FCVAR_NOTIFY);
	cv_ttt_shop_price_wallhack = CreateConVar("ttt_shop_price_wallhack", "5", "Price for Wallhack.", FCVAR_NOTIFY);
	cv_ttt_shop_price_horde = CreateConVar("ttt_shop_price_horde", "2", "Price for Horde.", FCVAR_NOTIFY);
	cv_ttt_shop_price_special = CreateConVar("ttt_shop_price_special", "8", "Price for Special Infected.", FCVAR_NOTIFY);
	cv_ttt_shop_price_gl = CreateConVar("ttt_shop_price_gl", "6", "Price for Grenade Launcher.", FCVAR_NOTIFY);
	cv_ttt_shop_price_c4 = CreateConVar("ttt_shop_price_c4", "7", "Price for C4.", FCVAR_NOTIFY);
	cv_ttt_shop_price_missile = CreateConVar("ttt_shop_price_missile", "8", "Price for Missile.", FCVAR_NOTIFY);
	cv_ttt_shop_price_tank = CreateConVar("ttt_shop_price_tank", "14", "Price for Tank.", FCVAR_NOTIFY);
	cv_ttt_shop_price_traitor_next = CreateConVar("ttt_shop_price_traitor_next", "5", "Price for Traitor Next Round.", FCVAR_NOTIFY);
	cv_ttt_shop_price_detective_now = CreateConVar("ttt_shop_price_detective_now", "8", "Price for Detective Now.", FCVAR_NOTIFY);
	cv_ttt_shop_price_traitor_now = CreateConVar("ttt_shop_price_traitor_now", "10", "Price for Traitor Now.", FCVAR_NOTIFY);
	cv_ttt_shop_price_immortality = CreateConVar("ttt_shop_price_immortality", "15", "Price for Immortality.", FCVAR_NOTIFY);

	cv_ttt_shop_immortality_duration = CreateConVar("ttt_shop_immortality_duration", "3.0", "Immortality duration in seconds.", FCVAR_NOTIFY);
	cv_ttt_shop_horde_cooldown = CreateConVar("ttt_shop_horde_cooldown", "60.0", "Cooldown between Horde purchases in seconds.", FCVAR_NOTIFY);
	cv_ttt_shop_infected_cooldown = CreateConVar("ttt_shop_infected_cooldown", "15.0", "Cooldown between Special Infected purchases in seconds.", FCVAR_NOTIFY);
	cv_ttt_shop_tank_cooldown = CreateConVar("ttt_shop_tank_cooldown", "30.0", "Cooldown per player for Tank purchases in seconds.", FCVAR_NOTIFY);

	cv_ttt_credits_kill_traitor = CreateConVar("ttt_credits_kill_traitor", "2", "Credits awarded for killing a Traitor.", FCVAR_NOTIFY);
	cv_ttt_credits_kill_detective = CreateConVar("ttt_credits_kill_detective", "2", "Credits awarded for killing a Detective.", FCVAR_NOTIFY);
	cv_ttt_credits_kill_innocent = CreateConVar("ttt_credits_kill_innocent", "1", "Credits awarded for killing an Innocent.", FCVAR_NOTIFY);
	cv_ttt_credits_survive = CreateConVar("ttt_credits_survive", "1", "Credits awarded for surviving the round.", FCVAR_NOTIFY);
	cv_ttt_credits_defuse_c4 = CreateConVar("ttt_credits_defuse_c4", "3", "Credits awarded for defusing C4.", FCVAR_NOTIFY);
	cv_ttt_credits_kill_tank = CreateConVar("ttt_credits_kill_tank", "2", "Credits awarded for killing a Tank.", FCVAR_NOTIFY);
	cv_ttt_credits_kill_witch = CreateConVar("ttt_credits_kill_witch", "2", "Credits awarded for killing a Witch.", FCVAR_NOTIFY);
	cv_ttt_credits_kill_special = CreateConVar("ttt_credits_kill_special", "1", "Credits awarded for killing a Special Infected.", FCVAR_NOTIFY);

	cv_ttt_role_traitor_ratio = CreateConVar("ttt_role_traitor_ratio", "25", "Percentage of alive players that will be Traitors (0-100).", FCVAR_NOTIFY);
	cv_ttt_role_detective_ratio = CreateConVar("ttt_role_detective_ratio", "12", "Percentage of alive players that will be Detectives (0-100).", FCVAR_NOTIFY);
	cv_ttt_round_duration = CreateConVar("ttt_round_duration", "300", "Round duration in seconds.", FCVAR_NOTIFY);
	cv_ttt_truce_duration = CreateConVar("ttt_truce_duration", "10", "Truce duration at the start of the round in seconds.", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d2_ttt");

	g_hCookieCredits = RegClientCookie("ttt_credits", "TTT Shop Credits", CookieAccess_Private);
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && AreClientCookiesCached(i)) {
			OnClientCookiesCached(i);
		}
	}

	HookEvent("round_start",  Event_RoundStart,  EventHookMode_PostNoCopy);
	HookEvent("pills_used",   Event_PillsUsed,   EventHookMode_Post);
	HookEvent("round_end",    Event_RoundEnd,    EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_bot_replace", Event_PlayerBotReplace, EventHookMode_Post);
	HookEvent("bot_player_replace", Event_BotPlayerReplace, EventHookMode_Post);
	HookEvent("weapon_fire",  Event_WeaponFire,  EventHookMode_Post);
	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab, EventHookMode_Post);
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Post);
	
	RegConsoleCmd("sm_detective", Cmd_Detective, "Opt-in to be a Detective");
	RegConsoleCmd("sm_t", Cmd_TraitorChat, "Exclusive chat for Traitors");
	RegConsoleCmd("sm_d", Cmd_DetectiveChat, "Exclusive chat for Detectives");
	RegAdminCmd("sm_setrole", Cmd_SetRole, ADMFLAG_ROOT, "Set a player's TTT role");
	RegConsoleCmd("sm_shop", Cmd_Shop, "Open TTT Shop");
	RegConsoleCmd("sm_tienda", Cmd_Shop, "Open TTT Shop (alias)");
	RegAdminCmd("sm_shop_wall", Cmd_AdminWall, ADMFLAG_ROOT, "Force Wallhack");
	RegAdminCmd("sm_shop_piano", Cmd_AdminPiano, ADMFLAG_ROOT, "Force Piano");
	RegAdminCmd("sm_shop_randomizer", Cmd_AdminRandomizer, ADMFLAG_ROOT, "Force Randomizer");
	RegAdminCmd("sm_givecredits", Cmd_GiveCredits, ADMFLAG_ROOT, "Give credits to a player");
	RegAdminCmd("sm_darcreditos", Cmd_GiveCredits, ADMFLAG_ROOT, "Give credits to a player (alias)");
	RegConsoleCmd("sm_credits", Cmd_SeeCredits, "View your current credits");
	RegConsoleCmd("sm_vercreditos", Cmd_SeeCredits, "View your current credits (alias)");
	RegAdminCmd("sm_giveimmortality", Cmd_GiveImmortality, ADMFLAG_ROOT, "Give 3s immortality to a player");
	RegAdminCmd("sm_add_ttt_spawn", Cmd_AddTTTSpawn, ADMFLAG_ROOT, "Adds a player spawn point for TTT");
	RegAdminCmd("sm_del_ttt_spawn", Cmd_DelTTTSpawn, ADMFLAG_ROOT, "Deletes the last added player spawn point for TTT");
	RegAdminCmd("sm_clear_ttt_spawns", Cmd_ClearTTTSpawns, ADMFLAG_ROOT, "Clears all player spawn points for TTT on this map");
	RegAdminCmd("sm_addbot", Command_AddBot, ADMFLAG_ROOT, "Add a bot bypassing the director limit");

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_SayTeam, "say_team");

	CreateConVar("ttt_version", PLUGIN_VERSION, "TTT Gamemode Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	SetConVarInt(FindConVar("director_no_mobs"),       1);
	SetConVarInt(FindConVar("director_no_specials"),   1);
	SetConVarInt(FindConVar("director_no_bosses"),     1);

	SetConVarInt(FindConVar("z_common_limit"),         0);
	SetConVarInt(FindConVar("z_max_player_zombies"),   0);
	SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 0);
	SetConVarInt(FindConVar("survivor_limp_health"),   0);
	SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.7);
	SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"),   0.7);
	SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.7);

	ConVar cvNoDeath = FindConVar("director_no_death_check");
	if (cvNoDeath != null) cvNoDeath.SetInt(1);

	ConVar cvSurvivorLimit = FindConVar("survivor_limit");
	if (cvSurvivorLimit != null)
	{
		SetConVarBounds(cvSurvivorLimit, ConVarBound_Upper, true, 32.0);
		cvSurvivorLimit.SetInt(0);
	}

	Karma_OnPluginStart();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			Karma_OnClientPutInServer(i);
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_TraceAttack,  OnTraceAttack);
			Glow_HookClient(i);
			
			if (AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
		}
	}
}

// ============================================================================
// OnPluginEnd — clean up all SendProxy hooks before unload
// ============================================================================
public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			Glow_UnhookClient(i);
	}

	for (int v = 1; v <= MaxClients; v++)
	{
		for (int t = 1; t <= MaxClients; t++)
		{
			int spr = g_iWallhackSprite[v][t];
			if (spr > 0 && IsValidEntity(spr)) AcceptEntityInput(spr, "Kill");
			if (spr > 0 && spr < 2048) g_iWallhackSpriteOwner[spr] = 0;
			g_iWallhackSprite[v][t] = 0;
		}
		g_fWallhackEndTime[v] = 0.0;
	}
}

// ============================================================================
// Client callbacks
// ============================================================================
public void OnClientPutInServer(int client)
{
	g_bIsCustomBot[client] = false;
	g_bWantsDetective[client] = false;
	g_bGlowHooked[client]     = false;
	g_iPlayerRole[client]     = ROLE_NONE;
	g_iOriginalChar[client]   = -1;
	g_bBoughtMissile[client] = false;
	g_bBoughtC4[client] = false;
	if (g_iC4Entity[client] != 0)
	{
		int c4 = EntRefToEntIndex(g_iC4Entity[client]);
		if (c4 > 0 && IsValidEntity(c4)) AcceptEntityInput(c4, "Kill");
		g_iC4Entity[client] = 0;
	}
	g_iC4PackEnt[client] = 0;
	g_iC4WrongAttempts[client] = 0;
	if (g_hC4DefuseTimer[client] != null) { KillTimer(g_hC4DefuseTimer[client]); g_hC4DefuseTimer[client] = null; }
	g_iMenuC4Owner[client] = 0;
	g_fMissileEndTime[client] = 0.0;
	g_bHasDefuser[client] = false;
	g_fLastPipeThrowTime[client] = 0.0;
	g_fImmortalityEndTime[client] = 0.0;
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, 255, 255, 255, 255);

	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_TraceAttack,  OnTraceAttack);
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
	g_iCurrentPrimaryWeapon[client] = -1;

	Glow_HookClient(client);
	
	if (g_iManagerEnt == -1 || !IsValidEntity(g_iManagerEnt))
		g_iManagerEnt = FindEntityByClassname(-1, "terror_player_manager");
	
	if (g_iManagerEnt != -1 && IsValidEntity(g_iManagerEnt))
	{
		SendProxy_HookArrayProp(g_iManagerEnt, "m_iTeam", client, Prop_Int, Proxy_ManagerTeam);
	}

	Handle cv = FindConVar("mp_gamemode");
	if (cv != null && !IsFakeClient(client)) SendConVarValue(client, cv, "realism");

	Karma_OnClientPutInServer(client);
}

public void OnClientDisconnect(int client)
{
	if (g_hPillsTimer[client] != null) { KillTimer(g_hPillsTimer[client]); g_hPillsTimer[client] = null; }
	if (g_iTaserSprite[client] > 0 && IsValidEntity(g_iTaserSprite[client]))
	{
		AcceptEntityInput(g_iTaserSprite[client], "Kill");
	}
	g_iTaserSprite[client] = 0;
	g_iTaserTarget[client] = 0;
	g_bHasKevlar[client] = false;
	g_bHasHelmet[client] = false;
	g_iPlayerRole[client] = ROLE_NONE;
	if (g_iSpriteEntity[client] > 0 && IsValidEntity(g_iSpriteEntity[client]))
	{
		AcceptEntityInput(g_iSpriteEntity[client], "Kill");
	}
	g_iSpriteEntity[client] = 0;
	
	if (g_iActiveMissile[client] > 0)
	{
		g_iActiveMissile[client] = 0;
	}
	g_bBoughtMissile[client] = false;
	g_fMissileEndTime[client] = 0.0;
	g_fLastPipeThrowTime[client] = 0.0;

	for (int t = 1; t <= MaxClients; t++)
	{
		int wspr = g_iWallhackSprite[client][t];
		if (wspr > 0 && IsValidEntity(wspr))
		{
			AcceptEntityInput(wspr, "Kill");
		}
		if (wspr > 0 && wspr < 2048) g_iWallhackSpriteOwner[wspr] = 0;
		g_iWallhackSprite[client][t] = 0;
	}
	g_fWallhackEndTime[client] = 0.0;

	for (int v = 1; v <= MaxClients; v++)
	{
		if (v == client) continue;
		int wspr2 = g_iWallhackSprite[v][client];
		if (wspr2 > 0 && IsValidEntity(wspr2))
		{
			AcceptEntityInput(wspr2, "Kill");
		}
		if (wspr2 > 0 && wspr2 < 2048) g_iWallhackSpriteOwner[wspr2] = 0;
		g_iWallhackSprite[v][client] = 0;
	}

	Karma_SaveCookies(client);
	if (g_iManagerEnt != -1 && IsValidEntity(g_iManagerEnt))
	{
		SendProxy_UnhookArrayProp(g_iManagerEnt, "m_iTeam", client, Prop_Int, Proxy_ManagerTeam);
	}
	Glow_UnhookClient(client);
	g_bWantsDetective[client] = false;
	if (!IsFakeClient(client))
	{
		CreateTimer(0.1, Timer_CheckLastHuman, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_CheckLastHuman(Handle timer)
{
	int humans = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			humans++;
	}

	if (humans == 0)
	{
		// PrintToServer("[TTT BotMgr] Last human left. Kicking all survivor bots.");
		ConVar cv = FindConVar("survivor_limit");
		if (cv != null) cv.SetInt(0);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
			{
				KickClient(i, "Server empty");
			}
		}
		g_bRoundLive = false;
	}
	else
	{
		// A human still exists; just update the limit
		UpdateSurvivorLimit();
	}
	return Plugin_Stop;
}

// ============================================================================
// MAP & CONFIG
// ============================================================================
public void OnMapStart()
{
	g_bIsL4D1Map = false;
	CreateTimer(3.0, Timer_DetectMapType);

	AddFileToDownloadsTable("materials/sprites/Tside/Tside.vmt");
	AddFileToDownloadsTable("materials/sprites/Tside/Tside.vtf");
	AddFileToDownloadsTable("materials/sprites/Dside/Dside.vmt");
	AddFileToDownloadsTable("materials/sprites/Dside/Dside.vtf");
	AddFileToDownloadsTable("materials/sprites/Iside/Iside.vmt");
	AddFileToDownloadsTable("materials/sprites/Iside/Iside.vtf");

	AddFileToDownloadsTable("materials/sprites/Hud/Ihud.vmt");
	AddFileToDownloadsTable("materials/sprites/Hud/Ihud.vtf");
	AddFileToDownloadsTable("materials/sprites/Hud/Thud.vmt");
	AddFileToDownloadsTable("materials/sprites/Hud/Thud.vtf");
	AddFileToDownloadsTable("materials/sprites/Hud/Dhud.vmt");
	AddFileToDownloadsTable("materials/sprites/Hud/Dhud.vtf");

	AddFileToDownloadsTable("materials/sprites/ResultIV/Twin.vmt");
	AddFileToDownloadsTable("materials/sprites/ResultIV/Twin.vtf");
	AddFileToDownloadsTable("materials/sprites/ResultIV/Iwin.vmt");
	AddFileToDownloadsTable("materials/sprites/ResultIV/Iwin.vtf");

	PrecacheGeneric("materials/sprites/Hud/Ihud.vmt", true);
	PrecacheGeneric("materials/sprites/Hud/Thud.vmt", true);
	PrecacheGeneric("materials/sprites/Hud/Dhud.vmt", true);
	PrecacheModel("sprites/Tside/Tside.vmt", true);
	PrecacheModel("sprites/Dside/Dside.vmt", true);
	PrecacheModel("sprites/Iside/Iside.vmt", true);

	PrecacheGeneric("materials/sprites/ResultIV/Twin.vmt", true);
	PrecacheGeneric("materials/sprites/ResultIV/Iwin.vmt", true);

	PrecacheModel("models/props_junk/wood_crate001a.mdl", true);
	PrecacheModel("models/props_furniture/piano.mdl", true);

	PrecacheSound("music/safe/themonsterswithout.wav", true);

	PrecacheModel("models/survivors/survivor_gambler.mdl",  true);  // Nick
	PrecacheModel("models/survivors/survivor_producer.mdl", true);  // Rochelle
	PrecacheModel("models/survivors/survivor_coach.mdl",   true);   // Coach
	PrecacheModel("models/survivors/survivor_mechanic.mdl",true);   // Ellis
	PrecacheModel("models/survivors/survivor_namvet.mdl",  true);   // Bill
	PrecacheModel("models/survivors/survivor_teenangst.mdl",true);  // Zoey
	PrecacheModel("models/survivors/survivor_biker.mdl",   true);   // Francis
	PrecacheModel("models/survivors/survivor_manager.mdl", true);   // Louis

	PrecacheModel("models/props_equipment/oxygentank01.mdl", true);
	PrecacheModel("models/w_models/weapons/w_eq_incendiary_ammo.mdl", true);
	PrecacheSound("buttons/blip1.wav", true);

	LoadWeaponsFromConfig();
	LoadPlayerSpawnsFromConfig();
	SetConVarInt(FindConVar("pain_pills_health_value"), 0);

	g_iMaxRounds = cv_ttt_max_rounds.IntValue;

	ServerCommand("sm plugins unload l4d_weapon_spawn");
	ServerCommand("sm plugins unload optional/l4d_weapon_spawn");
	ServerCommand("sm plugins unload l4d_ammo_spawn");
	ServerCommand("sm plugins unload optional/l4d_ammo_spawn");

	for (int i = 1; i <= MaxClients; i++) g_bHasSeenHint[i] = false;

	g_iManagerEnt = FindEntityByClassname(-1, "terror_player_manager");
	
	CreateTimer(1.0, Timer_RemoveSafeRoomDoors, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, Timer_EnforceHUD, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, Timer_DeadMute, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	if (!LibraryExists("readyup"))
	{
		PrintToServer("[TTT Lobby] ReadyUp not detected, activating provisional lobby.");
		CreateTimer(2.0, Timer_AutoStartCheck, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		PrintToServer("[TTT Lobby] ReadyUp detected, using !ready to start.");
	}
}

public Action Timer_RemoveSafeRoomDoors(Handle timer)
{
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "prop_door_rotating_checkpoint")) != -1)
	{
		if (IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "Kill");
		}
	}
	return Plugin_Stop;
}

public Action Timer_DeadMute(Handle timer)
{
	if (!g_bRoundLive || g_bTruceActive) 
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			for (int j = 1; j <= MaxClients; j++)
			{
				if (i == j || !IsClientInGame(j)) continue;
				SetListenOverride(i, j, Listen_Default);
			}
		}
		return Plugin_Continue;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		bool iDead = (!IsPlayerAlive(i) || GetClientTeam(i) != 2);
		
		for (int j = 1; j <= MaxClients; j++)
		{
			if (i == j || !IsClientInGame(j)) continue;
			bool jDead = (!IsPlayerAlive(j) || GetClientTeam(j) != 2);
			
			if (!iDead && jDead)
			{
				SetListenOverride(i, j, Listen_No);
			}
			else
			{
				SetListenOverride(i, j, Listen_Default);
			}
		}
	}
	return Plugin_Continue;
}

// ============================================================================
// Timer_DetectMapType
// ============================================================================
public Action Timer_DetectMapType(Handle timer)
{
	DetectAndSetMapType();
	return Plugin_Stop;
}

void DetectAndSetMapType()
{
	char map[64];
	GetCurrentMap(map, sizeof(map));
	
	g_bIsL4D1Map = false;
	
	if (StrContains(map, "c7m") == 0 ||
	    StrContains(map, "c8m") == 0 ||
	    StrContains(map, "c9m") == 0 ||
	    StrContains(map, "c10m") == 0 ||
	    StrContains(map, "c11m") == 0 ||
	    StrContains(map, "c12m") == 0 ||
	    StrContains(map, "c14m") == 0 ||
	    StrContains(map, "l4d_") == 0 ||
	    StrContains(map, "l4d1_") == 0)
	{
		g_bIsL4D1Map = true;
	}
}

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iOriginalChar[i] = -1;
		g_iPlayerRole[i]   = ROLE_NONE;
		g_bGlowHooked[i]   = false;
		g_bBoughtMissile[i] = false;
		g_iActiveMissile[i] = 0;
		g_fMissileEndTime[i] = 0.0;
		g_fLastPipeThrowTime[i] = 0.0;
	}

	// Reset traitor-spawn tracking
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bTraitorSpawned[i] = false;
		g_iZombieOwner[i] = 0;
	}
	g_bRoundLive  = false;
	g_bTruceActive = false;
	g_bRoundEnded  = false;
	if (g_hRoundTimer != null) { KillTimer(g_hRoundTimer); g_hRoundTimer = null; }
}

public Action Timer_EnforceHUD(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			SetEntProp(i, Prop_Send, "m_bSurvivorGlowEnabled", 0);
		}
	}
	return Plugin_Continue;
}

void LoadWeaponsFromConfig()
{
	g_aConfigPos.Clear();
	g_aConfigAng.Clear();
	g_aConfigMod.Clear();

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/l4d_spawn_weapon.cfg");

	KeyValues kv = new KeyValues("spawns");
	if (!kv.ImportFromFile(path)) { delete kv; return; }

	char currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if (!kv.JumpToKey(currentMap)) { delete kv; return; }

	if (kv.GotoFirstSubKey())
	{
		do
		{
			float pos[3], ang[3];
			kv.GetVector("pos", pos);
			kv.GetVector("ang", ang);
			int mod = kv.GetNum("MOD");
			g_aConfigPos.PushArray(pos, 3);
			g_aConfigAng.PushArray(ang, 3);
			g_aConfigMod.Push(mod);
		} while (kv.GotoNextKey());
	}
	delete kv;

	g_aAmmoPos.Clear();
	g_aAmmoAng.Clear();

	char ammoPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ammoPath, sizeof(ammoPath), "data/l4d_ammo_spawn.cfg");

	KeyValues kvAmmo = new KeyValues("spawns");
	if (kvAmmo.ImportFromFile(ammoPath))
	{
		if (kvAmmo.JumpToKey(currentMap) && kvAmmo.GotoFirstSubKey())
		{
			do
			{
				float pos[3], ang[3];
				kvAmmo.GetVector("pos", pos);
				kvAmmo.GetVector("ang", ang);
				g_aAmmoPos.PushArray(pos, 3);
				g_aAmmoAng.PushArray(ang, 3);
			} while (kvAmmo.GotoNextKey());
		}
	}
	delete kvAmmo;
}

void LoadPlayerSpawnsFromConfig()
{
	g_aPlayerSpawns.Clear();

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/l4d_ttt_spawns.cfg");

	KeyValues kv = new KeyValues("ttt_spawns");
	if (!kv.ImportFromFile(path)) { delete kv; return; }

	char currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if (!kv.JumpToKey(currentMap)) { delete kv; return; }

	if (kv.GotoFirstSubKey())
	{
		do
		{
			float pos[3];
			kv.GetVector("pos", pos);
			g_aPlayerSpawns.PushArray(pos, 3);
		} while (kv.GotoNextKey());
	}
	delete kv;
}

void SavePlayerSpawnsToConfig()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/l4d_ttt_spawns.cfg");

	KeyValues kv = new KeyValues("ttt_spawns");
	kv.ImportFromFile(path);

	char currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if (kv.JumpToKey(currentMap))
	{
		kv.DeleteThis();
		kv.Rewind();
	}

	if (g_aPlayerSpawns.Length > 0)
	{
		kv.JumpToKey(currentMap, true);
		for (int i = 0; i < g_aPlayerSpawns.Length; i++)
		{
			char key[16];
			IntToString(i + 1, key, sizeof(key));
			kv.JumpToKey(key, true);
			
			float pos[3];
			g_aPlayerSpawns.GetArray(i, pos, 3);
			kv.SetVector("pos", pos);
			
			kv.GoBack();
		}
	}
	
	kv.Rewind();
	kv.ExportToFile(path);
	delete kv;
}

public Action Cmd_AddTTTSpawn(int client, int args)
{
	if (client < 1 || !IsClientInGame(client)) return Plugin_Handled;

	float pos[3];
	GetClientAbsOrigin(client, pos);

	g_aPlayerSpawns.PushArray(pos, 3);
	SavePlayerSpawnsToConfig();
	
	TTT_PrintToChat(client, "%t", "Spawn_Added", g_aPlayerSpawns.Length, pos[0], pos[1], pos[2]);
	return Plugin_Handled;
}

public Action Cmd_DelTTTSpawn(int client, int args)
{
	if (client < 1 || !IsClientInGame(client)) return Plugin_Handled;

	int len = g_aPlayerSpawns.Length;
	if (len == 0)
	{
		TTT_PrintToChat(client, "%t", "Spawn_None");
		return Plugin_Handled;
	}

	g_aPlayerSpawns.Erase(len - 1);
	SavePlayerSpawnsToConfig();

	TTT_PrintToChat(client, "%t", "Spawn_Deleted", g_aPlayerSpawns.Length);
	return Plugin_Handled;
}

public Action Cmd_ClearTTTSpawns(int client, int args)
{
	if (client < 1 || !IsClientInGame(client)) return Plugin_Handled;

	g_aPlayerSpawns.Clear();
	SavePlayerSpawnsToConfig();
	TTT_PrintToChat(client, "%t", "Spawn_Cleared");
	return Plugin_Handled;
}

// ============================================================================
// Entity hooks
// ============================================================================
public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "weapon_ammo_spawn"))
	{
		SDKHook(entity, SDKHook_Use, OnAmmoUse);
	}
	else if (StrContains(classname, "weapon_") == 0 && StrContains(classname, "_spawn") == -1)
	{
		RequestFrame(Frame_SetWeaponAmmo, EntIndexToEntRef(entity));
	}
	else if (StrEqual(classname, "survivor_death_model"))
	{
		AcceptEntityInput(entity, "KillHierarchy");
	}
	else if (StrEqual(classname, "survivor_bot"))
	{
		// PrintToServer("[TTT BOTDBG] OnEntityCreated: classname='survivor_bot' ent=%d g_bPendingCustomBot=%d", entity, g_bPendingCustomBot);
		if (g_bPendingCustomBot)
		{
			g_bPendingCustomBot = false;
			// PrintToServer("[TTT BOTDBG]   -> CLAIMED as our custom bot, hooking SpawnPost on ent=%d", entity);
			SDKHook(entity, SDKHook_SpawnPost, OnCustomBotSpawnPost);
		}
		else
		{
			// PrintToServer("[TTT BOTDBG]   -> NOT claimed (no pending request). This bot will likely get kicked as 'director bot' later. ent=%d", entity);
		}
	}
	else if (StrEqual(classname, "infected"))
	{
		if (g_bRoundEnded || !g_bHordeActive)
			AcceptEntityInput(entity, "KillHierarchy");
	}
	else if (StrEqual(classname, "witch"))
	{
		if (g_bWitchSpawning) return;
		if (g_bRoundEnded || !g_bHordeActive)
			AcceptEntityInput(entity, "KillHierarchy");
	}

	else if (StrEqual(classname, "grenade_launcher_projectile"))
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if (owner <= 0) owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if (owner <= 0) owner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
		if (owner <= 0) owner = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		if (owner > 0 && owner <= MaxClients && IsClientInGame(owner))
		{
			CreateTimer(0.05, Timer_RemoveGrenadeLauncher, GetClientUserId(owner), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if (StrEqual(classname, "pipe_bomb_projectile"))
	{
		CreateTimer(0.1, Timer_MatchMissile, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrEqual(classname, "upgrade_ammo_incendiary"))
	{
		SDKHook(entity, SDKHook_Use, OnC4Use);
	}
}

public void OnCustomBotSpawnPost(int entity)
{
	if (!IsClientInGame(entity)) return;

	g_bIsCustomBot[entity] = true;

	if (g_iPendingBotTeleportClient > 0 && IsClientInGame(g_iPendingBotTeleportClient))
	{
		float origin[3];
		GetClientAbsOrigin(g_iPendingBotTeleportClient, origin);
		TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
	}
	g_iPendingBotTeleportClient = 0;
	
	CreateTimer(0.3, Timer_InitCustomBot, GetClientUserId(entity));
}

public Action Timer_InitCustomBot(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		if (!IsPlayerAlive(client))
		{
			L4D_RespawnPlayer(client);
		}
		
		if (g_bRoundLive || g_bTruceActive)
		{
			ScheduleModelChange(client, g_sModelPaths[6], 6);
		}
	}
	return Plugin_Stop;
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if (client <= 0 || client > MaxClients || !IsClientInGame(client)) return;

	char wep[64];
	event.GetString("weapon", wep, sizeof(wep));
	if (StrContains(wep, "grenade_launcher") != -1)
	{
		CreateTimer(0.05, Timer_RemoveGrenadeLauncher, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrEqual(wep, "pipe_bomb") && g_bBoughtMissile[client])
	{
		g_bBoughtMissile[client] = false;
		g_fLastPipeThrowTime[client] = GetEngineTime();
	}
}

public void Event_PlayerLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		ForcePlayerSuicide(client);
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) return;

	g_fImmortalityEndTime[client] = 0.0;
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	
	if (!IsFakeClient(client) && cv_ttt_karma_enabled.BoolValue && g_iActiveKarma[client] == 0)
	{
		CreateTimer(1.0, Timer_EnforceKarmaZero, GetClientUserId(client));
	}

	if (IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		if (g_bRoundEnded || (!g_bTraitorSpawned[client] && !g_bTraitorSpawning))
			KickClient(client, "Natural Special Infected blocked");
	}

	if (GetClientTeam(client) == 2)
	{
		if (g_iOriginalChar[client] == -1 && !g_bRoundLive && !g_bTruceActive)
		{
			RequestFrame(Frame_CaptureOriginalModel, GetClientUserId(client));
		}
		
		SetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled", 0);

		Glow_UnhookClient(client);
		Glow_HookClient(client);
	}
}

public Action Timer_EnforceKarmaZero(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client) && g_iActiveKarma[client] == 0)
	{
		if (cv_ttt_karma_zero_autospectator.BoolValue)
		{
			ChangeClientTeam(client, 1);
			TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Karma_Spectator");
		}
		else if (cv_ttt_karma_zero_autosuicide.BoolValue && IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
			TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Karma_Suicide");
		}
	}
	return Plugin_Continue;
}

public void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));
	int bot    = GetClientOfUserId(event.GetInt("bot"));

	if (player > 0 && bot > 0 && IsClientInGame(player) && IsClientInGame(bot))
	{
		if (!g_bRoundLive)
		{
			if (bot > 0 && bot <= MaxClients && g_bIsCustomBot[bot]) return;
			
			KickClient(bot, "Orphan bot (player left in lobby)");
			UpdateSurvivorLimit();
			return;
		}

		if (g_bRoundLive && IsPlayerAlive(bot) && GetClientTeam(bot) == 2)
		{
			if (bot > 0 && bot <= MaxClients && g_bIsCustomBot[bot]) return;

			g_iPlayerRole[bot] = g_iPlayerRole[player];
			
			if (g_iPlayerRole[bot] == ROLE_DETECTIVE)
				SetEntityModel(bot, g_sModelPaths[4]); // Bill
			else
				SetEntityModel(bot, g_sModelPaths[6]); // Francis
			
			ForcePlayerSuicide(bot);
			
			TTT_PrintToChatAll("\x05[TTT]\x01 %t", "Player_Disconnected");
		}
	}
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int bot    = GetClientOfUserId(event.GetInt("bot"));
	int player = GetClientOfUserId(event.GetInt("player"));

	if (player > 0 && bot > 0 && IsClientInGame(player) && IsClientInGame(bot))
	{
		g_iPlayerRole[player] = g_iPlayerRole[bot];
		g_iPlayerRole[bot] = ROLE_NONE;

		if (g_bRoundLive && !g_bTruceActive && IsPlayerAlive(player) && GetClientTeam(player) == 2)
		{
			if (g_iPlayerRole[player] == ROLE_NONE)
			{
				ChangeClientTeam(player, 1);
				TTT_PrintToChat(player, "\x05[TTT]\x01 You joined mid-round. You've been moved to Spectator until next time.");
				return;
			}

			if (g_iPlayerRole[player] == ROLE_DETECTIVE)
				ScheduleModelChange(player, g_sModelPaths[4], 4);
			else
				ScheduleModelChange(player, g_sModelPaths[6], 6);

			ClientCommand(player, "stop");
		}
	}
}

public void Frame_CaptureOriginalModel(any data)
{
	int userid = data;
	int client = GetClientOfUserId(userid);
	if (client < 1 || !IsClientInGame(client) || GetClientTeam(client) != 2) return;
	if (g_bRoundLive || g_bTruceActive) return;

	if (g_iOriginalChar[client] == -1)
	{
		int nativeChar = (client % 4); 
		if (g_bIsL4D1Map) nativeChar += 4; // 4=Bill, 5=Zoey, 6=Francis, 7=Louis
		
		SetEntProp(client, Prop_Send, "m_survivorCharacter", nativeChar);
		SetEntityModel(client, g_sModelPaths[nativeChar]);
		
		g_iOriginalChar[client] = nativeChar;
		strcopy(g_sOriginalModel[client], 128, g_sModelPaths[nativeChar]);
	}
}

public void Frame_SetWeaponAmmo(int ref)
{
	int entity = EntRefToEntIndex(ref);
	if (entity > 0 && IsValidEntity(entity))
	{
		if (HasEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo"))
			SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", 0);
	}
}

public Action OnAmmoUse(int entity, int activator, int caller, UseType type, float value)
{
	if (activator > 0 && activator <= MaxClients && IsClientInGame(activator) && GetClientTeam(activator) == 2)
	{
		int weapon = GetPlayerWeaponSlot(activator, 0);
		if (weapon > 0 && IsValidEntity(weapon))
		{
			int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			if (ammotype != -1)
			{
				char cls[64];
				GetEntityClassname(weapon, cls, sizeof(cls));
				if (StrContains(cls, "grenade_launcher") != -1) return Plugin_Handled;

				int addAmmo = 60;
				if (StrContains(cls, "shotgun") != -1) addAmmo = 16;
				else if (StrContains(cls, "smg")  != -1) addAmmo = 100;
				else if (StrContains(cls, "rifle") != -1 || StrContains(cls, "sniper") != -1) addAmmo = 30;

				int currentAmmo = GetEntProp(activator, Prop_Send, "m_iAmmo", _, ammotype);
				SetEntProp(activator, Prop_Send, "m_iAmmo", currentAmmo + addAmmo, _, ammotype);
				AcceptEntityInput(entity, "Kill");
				TTT_PrintToChat(activator, "\x05[TTT]\x01 %t", "Item_Ammo");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

// ============================================================================
// Damage system
// ============================================================================
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype,
    int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if ((!g_bRoundLive && !g_bRoundEnded) || g_bTruceActive)
	{
		if (attacker == 0 && (damage >= 500.0 || (damagetype & 16384)))
		{
			return Plugin_Continue;
		}
		
		damage = 0.0;
		return Plugin_Handled;
	}
	
	if (victim > 0 && victim <= MaxClients && g_fImmortalityEndTime[victim] > GetEngineTime())
	{
		damage = 0.0;
		return Plugin_Handled;
	}

	if (attacker > 0 && attacker <= MaxClients && victim > 0 && victim <= MaxClients)
	{
		if (cv_ttt_karma_enabled.BoolValue && g_bRoundLive && attacker != victim)
		{
			g_fLastDamageTime[victim][attacker] = GetEngineTime();
			damage *= Karma_GetOutgoingDamageMult(g_iActiveKarma[attacker]);
			damage *= Karma_GetIncomingDamageMult(g_iActiveKarma[victim]);
		}

		if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 2)
		{
			if (inflictor > MaxClients && IsValidEntity(inflictor))
			{
				char inflCls[64];
				GetEntityClassname(inflictor, inflCls, sizeof(inflCls));
				if (StrEqual(inflCls, "grenade_launcher_projectile"))
				{
					damage = 1000.0;
					return Plugin_Changed;
				}
			}

			if (weapon > 0 && IsValidEntity(weapon))
			{
				char cls[64];
				GetEntityClassname(weapon, cls, sizeof(cls));
				
				if (StrEqual(cls, "weapon_melee"))
				{
					char itemName[64];
					GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", itemName, sizeof(itemName));
					if (StrEqual(itemName, "baseball_bat"))
					{
						damage = 0.0;
						
						RemovePlayerItem(attacker, weapon);
						AcceptEntityInput(weapon, "Kill");

						int pistol = CreateEntityByName("weapon_pistol");
						if (pistol != -1)
						{
							DispatchSpawn(pistol);
							EquipPlayerWeapon(attacker, pistol);
						}
						
						float vSource[3];
						GetClientAbsOrigin(attacker, vSource);
						L4D_StaggerPlayer(victim, attacker, vSource);
						
						TTT_PrintToChat(attacker, "\x05[TTT]\x01 %t", "Stun_Attacker", victim);
						TTT_PrintToChat(victim, "\x05[TTT]\x01 %t", "Stun_Victim", attacker);
						
						return Plugin_Handled;
					}
					else if (StrEqual(itemName, "tonfa") || itemName[0] == '\0')
					{
						damage = 0.0;
						
						g_iTaserTarget[attacker] = victim;
						g_fTaserEndTime[attacker] = GetEngineTime() + 3.0;
						
						RemovePlayerItem(attacker, weapon);
						AcceptEntityInput(weapon, "Kill");

						int pistol = CreateEntityByName("weapon_pistol");
						if (pistol != -1)
						{
							DispatchSpawn(pistol);
							EquipPlayerWeapon(attacker, pistol);
						}
						
						int sprite = CreateEntityByName("env_sprite");
						if (sprite != -1)
						{
							char sprModel[PLATFORM_MAX_PATH];
							if (g_iPlayerRole[victim] == ROLE_TRAITOR) strcopy(sprModel, sizeof(sprModel), "sprites/Tside/Tside.vmt");
							else if (g_iPlayerRole[victim] == ROLE_DETECTIVE) strcopy(sprModel, sizeof(sprModel), "sprites/Dside/Dside.vmt");
							else strcopy(sprModel, sizeof(sprModel), "sprites/Iside/Iside.vmt");

							DispatchKeyValue(sprite, "model", sprModel);
							DispatchKeyValue(sprite, "scale", "0.05");
							DispatchKeyValue(sprite, "rendermode", "9");
							DispatchKeyValue(sprite, "rendercolor", "255 255 255");
							DispatchKeyValue(sprite, "renderamt", "255");
							DispatchKeyValue(sprite, "spawnflags", "1");
							DispatchKeyValue(sprite, "framerate", "0");

							float pos[3];
							GetClientAbsOrigin(victim, pos);
							pos[2] += 90.0;
							DispatchKeyValueVector(sprite, "origin", pos);

							DispatchSpawn(sprite);
							ActivateEntity(sprite);
							
							SetVariantString("!activator");
							AcceptEntityInput(sprite, "SetParent", victim, sprite, 0);

							SDKHook(sprite, SDKHook_SetTransmit, Proxy_TaserSpriteTransmit);
							
							g_iTaserSprite[attacker] = sprite;
							CreateTimer(3.0, Timer_KillTaserSprite, GetClientUserId(attacker));
						}

						if (g_bRoundLive)
						{
							int attackerRole = g_iPlayerRole[attacker];
							int victimRole   = g_iPlayerRole[victim];
							if (attackerRole == ROLE_DETECTIVE || attackerRole == ROLE_INNOCENT)
							{
								if (victimRole == ROLE_TRAITOR)
									LogActionCredits(attacker, "Taser_Label", 2);
								else if (victimRole == ROLE_INNOCENT)
									LogActionCredits(attacker, "Taser_Innocent", 1);
								else if (victimRole == ROLE_DETECTIVE)
									LogActionCredits(attacker, "Taser_Detective", 1);
							}
						}

						return Plugin_Handled;
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action Proxy_TaserSpriteTransmit(int entity, int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_iTaserSprite[i] == entity)
		{
			if (client == i) return Plugin_Continue;
			else return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action Timer_KillTaserSprite(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && client <= MaxClients)
	{
		if (g_iTaserSprite[client] > 0 && IsValidEntity(g_iTaserSprite[client]))
		{
			AcceptEntityInput(g_iTaserSprite[client], "Kill");
		}
		g_iTaserSprite[client] = 0;
	}
	return Plugin_Stop;
}

public Action Timer_KillWallhackSprites(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && client <= MaxClients)
	{
		for (int t = 1; t <= MaxClients; t++)
		{
			int spr = g_iWallhackSprite[client][t];
			if (spr > 0 && IsValidEntity(spr))
			{
				AcceptEntityInput(spr, "Kill");
			}
			if (spr > 0 && spr < 2048) g_iWallhackSpriteOwner[spr] = 0;
			g_iWallhackSprite[client][t] = 0;
		}
		g_fWallhackEndTime[client] = 0.0;
	}
	return Plugin_Stop;
}

public Action Timer_RemoveGrenadeLauncher(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || client > MaxClients || !IsClientInGame(client)) return Plugin_Stop;

	int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (active > 0 && IsValidEntity(active))
	{
		char cls[64];
		GetEntityClassname(active, cls, sizeof(cls));
		if (StrContains(cls, "grenade_launcher") != -1)
		{
			RemovePlayerItem(client, active);
			AcceptEntityInput(active, "Kill");
			return Plugin_Stop;
		}
	}

	for (int slot = 0; slot < 5; slot++)
	{
		int wep = GetPlayerWeaponSlot(client, slot);
		if (wep > 0 && IsValidEntity(wep))
		{
			char cls2[64];
			GetEntityClassname(wep, cls2, sizeof(cls2));
			if (StrContains(cls2, "grenade_launcher") != -1)
			{
				RemovePlayerItem(client, wep);
				AcceptEntityInput(wep, "Kill");
				break;
			}
		}
	}

	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "weapon_grenade_launcher")) != -1)
	{
		if (!IsValidEntity(ent)) continue;
		int owner = -1;
		if (HasEntProp(ent, Prop_Send, "m_hOwnerEntity")) owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (owner <= 0 && HasEntProp(ent, Prop_Data, "m_hOwnerEntity")) owner = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
		if (owner == client)
		{
			AcceptEntityInput(ent, "Kill");
		}
	}

	return Plugin_Stop;
}

public Action Proxy_WallhackSpriteTransmit(int entity, int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) return Plugin_Handled;

	if (entity > 0 && entity < 2048)
	{
		int owner = g_iWallhackSpriteOwner[entity];
		if (owner == client) return Plugin_Continue;
	}
	return Plugin_Handled;
}

void GiveWallhackToClient(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) return;
	if (g_fWallhackEndTime[client] > GetEngineTime())
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Give_Wallhack_Active");
		return;
	}

	g_fWallhackEndTime[client] = GetEngineTime() + 3.0;

	for (int t = 1; t <= MaxClients; t++)
	{
		if (t == client) continue;
		if (!IsClientInGame(t) || !IsPlayerAlive(t) || GetClientTeam(t) != 2) continue;
		
		int roleTarget = g_iPlayerRole[t];
		int roleViewer = g_iPlayerRole[client];

		if (roleTarget == ROLE_DETECTIVE) continue;
		
		if (roleTarget == ROLE_TRAITOR && roleViewer == ROLE_TRAITOR) continue;

		int sprite = CreateEntityByName("env_sprite");
		if (sprite == -1) continue;

		char sprModel[PLATFORM_MAX_PATH];
		strcopy(sprModel, sizeof(sprModel), "sprites/Iside/Iside.vmt");

		DispatchKeyValue(sprite, "model", sprModel);
		DispatchKeyValue(sprite, "scale", "0.05");
		DispatchKeyValue(sprite, "rendermode", "9");
		DispatchKeyValue(sprite, "rendercolor", "255 255 255");
		DispatchKeyValue(sprite, "renderamt", "255");
		DispatchKeyValue(sprite, "spawnflags", "1");
		DispatchKeyValue(sprite, "framerate", "0");

		float pos[3];
		GetClientAbsOrigin(t, pos);
		pos[2] += 90.0;
		DispatchKeyValueVector(sprite, "origin", pos);

		DispatchSpawn(sprite);
		ActivateEntity(sprite);

		SetVariantString("!activator");
		AcceptEntityInput(sprite, "SetParent", t, sprite, 0);

		SDKHook(sprite, SDKHook_SetTransmit, Proxy_WallhackSpriteTransmit);

		g_iWallhackSprite[client][t] = sprite;
		if (sprite > 0 && sprite < 2048) g_iWallhackSpriteOwner[sprite] = client;
	}

	CreateTimer(3.0, Timer_KillWallhackSprites, GetClientUserId(client));
}

public Action Cmd_AdminWall(int client, int args)
{
	if (client == 0 || !IsClientInGame(client)) return Plugin_Handled;
	GiveWallhackToClient(client);
	TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Admin_Wallhack");
	return Plugin_Handled;
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype,
    int &ammotype, int hitbox, int hitgroup)
{
	if ((!g_bRoundLive && !g_bRoundEnded) || g_bTruceActive) return Plugin_Handled;

	if (victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients)
	{
		if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 2)
		{
			if (hitgroup == 1) 
			{
				damage *= 5.0;
				if (g_bHasHelmet[victim]) damage *= 0.6;
			}
			else
			{
				damage *= 1.4;
				if (g_bHasKevlar[victim]) damage *= 0.65;
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

// ============================================================================
// Corpse scanning
// ============================================================================
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if ((!g_bRoundLive && !g_bRoundEnded) || !IsPlayerAlive(client)) return Plugin_Continue;
	if (GetClientTeam(client) != 2) return Plugin_Continue;

	if (g_iActiveMissile[client] != 0)
	{
		int missile = EntRefToEntIndex(g_iActiveMissile[client]);
		if (missile > 0 && IsValidEntity(missile))
		{
			buttons &= ~IN_ATTACK;
			buttons &= ~IN_ATTACK2;
			buttons &= ~IN_FORWARD;
			buttons &= ~IN_BACK;
			buttons &= ~IN_MOVELEFT;
			buttons &= ~IN_MOVERIGHT;
			buttons &= ~IN_JUMP;
			buttons &= ~IN_DUCK;
			return Plugin_Changed;
		}
		else
		{
			g_iActiveMissile[client] = 0;
			SetClientViewEntity(client, client);
		}
	}

	int currentTarget = 0;
	bool isPlayerAim = false;

	if (g_bRoundLive && !g_bTruceActive && (GetEngineTime() - g_fRoundStartTime) > 2.0)
	{
		int target = GetClientAimTarget(client, true);
		if (target > 0 && target <= MaxClients && IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			currentTarget = target;
			isPlayerAim = true;
		}
	}

	float eyeOrigin[3], eyeAngles[3];
	GetClientEyePosition(client, eyeOrigin);
	GetClientEyeAngles(client, eyeAngles);

	Handle trace = TR_TraceRayFilterEx(eyeOrigin, eyeAngles, MASK_SOLID, RayType_Infinite, TraceFilter_IgnorePlayers);
	if (TR_DidHit(trace))
	{
		int ent = TR_GetEntityIndex(trace);
		if (ent > MaxClients && IsValidEntity(ent))
		{
			char cls[64];
			GetEntityClassname(ent, cls, sizeof(cls));
			if (StrEqual(cls, "prop_ragdoll"))
			{
				float ePos[3];
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", ePos);
				if (GetVectorDistance(eyeOrigin, ePos) < 150.0)
				{
					if (!isPlayerAim) currentTarget = ent;

					if (!g_RagdollScanned[ent])
					{
						if (!g_bHasSeenHint[client] && GetEngineTime() - g_fLastChatHint[client] > 3.0)
						{
							TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Corpse_Inspect_Hint");
							g_fLastChatHint[client] = GetEngineTime();
							g_bHasSeenHint[client]  = true;
						}

						if ((buttons & IN_USE) && !(g_iLastButtons[client] & IN_USE))
						{
							g_RagdollScanned[ent] = true;
							ScanCorpse(client, ent);
							g_fLastAimHint[client] = 0.0;
						}
					}
					else
					{
						if ((buttons & IN_USE) && !(g_iLastButtons[client] & IN_USE))
						{
							ShowCorpseMenu(client, ent);
						}
					}
				}
			}
		}
	}
	CloseHandle(trace);

	if (g_bRoundLive && !g_bTruceActive && (GetEngineTime() - g_fRoundStartTime) > 2.0)
	{
		if (currentTarget != 0)
		{
			g_fLastValidAimTime[client] = GetEngineTime();
			g_iLastValidAimTarget[client] = currentTarget;
			g_bLastValidAimIsPlayer[client] = isPlayerAim;
		}
		else
		{
			if (GetEngineTime() - g_fLastValidAimTime[client] <= 1.0)
			{
				currentTarget = g_iLastValidAimTarget[client];
				isPlayerAim = g_bLastValidAimIsPlayer[client];
				
				if (isPlayerAim)
				{
					if (currentTarget <= 0 || currentTarget > MaxClients || !IsClientInGame(currentTarget) || !IsPlayerAlive(currentTarget))
						currentTarget = 0;
				}
				else
				{
					if (currentTarget <= MaxClients || !IsValidEntity(currentTarget))
						currentTarget = 0;
				}
			}
		}

		bool forceDraw = false;
		if (currentTarget != g_iLastAimTarget[client]) forceDraw = true;
		if (g_iRoundTimeLeft != g_iLastTimeLeftDrawn[client]) forceDraw = true;

		if (forceDraw || (currentTarget != 0 && GetEngineTime() - g_fLastAimHint[client] > 0.5))
		{
			g_iLastAimTarget[client] = currentTarget;
			g_iLastTimeLeftDrawn[client] = g_iRoundTimeLeft;
			g_fLastAimHint[client] = GetEngineTime();

			char timeStr[64];
			Format(timeStr, sizeof(timeStr), "%T", "HUD_RoundTime", client, g_iRoundTimeLeft / 60, g_iRoundTimeLeft % 60);

			if (currentTarget == 0)
			{
				PrintHintText(client, "%s", timeStr);
			}
			else if (isPlayerAim)
			{
				int hp = GetClientHealth(currentTarget);
				char status[32];
				if (hp >= 80)      Format(status, sizeof(status), "%T", "HUD_Healthy", client);
				else if (hp >= 60) Format(status, sizeof(status), "%T", "HUD_Damaged", client);
				else if (hp >= 40) Format(status, sizeof(status), "%T", "HUD_Hurt", client);
				else if (hp >= 20) Format(status, sizeof(status), "%T", "HUD_Severe", client);
				else               Format(status, sizeof(status), "%T", "HUD_Critical", client);
				
				char rank[32];
				Karma_GetRankName(client, g_iActiveKarma[currentTarget], rank, sizeof(rank));
				PrintHintText(client, "%t", "Hint_AimingAt", currentTarget, status, rank);
			}
			else
			{
				if (g_RagdollScanned[currentTarget])
				{
					char roleName[32];
					if (g_RagdollRole[currentTarget] == ROLE_TRAITOR) Format(roleName, sizeof(roleName), "%T", "Role_Name_Traitor", client);
					else if (g_RagdollRole[currentTarget] == ROLE_DETECTIVE) Format(roleName, sizeof(roleName), "%T", "Role_Name_Detective", client);
					else Format(roleName, sizeof(roleName), "%T", "Role_Name_Innocent", client);
					
					PrintHintText(client, "%s (%s)", g_RagdollName[currentTarget], roleName);
				}
				else
				{
					PrintHintText(client, "%t", "Hint_Unscanned", g_RagdollName[currentTarget]);
				}
			}
		}
	}

	g_iLastButtons[client] = buttons;
	return Plugin_Continue;
}

public bool TraceFilter_IgnorePlayers(int entity, int contentsMask)
{
	if (entity == 0)                            return true;
	if (entity > 0 && entity <= MaxClients)     return false;
	return true;
}

void ScanCorpse(int client, int ent)
{
	int corpseRole = g_RagdollRole[ent];
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	if (corpseRole == ROLE_TRAITOR)
	{
		SetEntityRenderColor(ent, 255, 0, 0, 255);
		TTT_PrintToChatAll("\x05[TTT]\x01 %t", "Body_Found_Traitor", client, g_RagdollName[ent]);
	}
	else if (corpseRole == ROLE_DETECTIVE)
	{
		SetEntityRenderColor(ent, 0, 0, 255, 255);
		TTT_PrintToChatAll("\x05[TTT]\x01 %t", "Body_Found_Detective", client, g_RagdollName[ent]);
	}
	else
	{
		SetEntityRenderColor(ent, 0, 255, 0, 255);
		TTT_PrintToChatAll("\x05[TTT]\x01 %t", "Body_Found_Innocent", client, g_RagdollName[ent]);
	}
}

void ShowCorpseMenu(int client, int ent)
{
	Menu menu = new Menu(MenuHandler_Corpse);
	char title[512];
	
	char roleName[32];
	if (g_RagdollRole[ent] == ROLE_TRAITOR) Format(roleName, sizeof(roleName), "%T", "Role_Name_Traitor", client);
	else if (g_RagdollRole[ent] == ROLE_DETECTIVE) Format(roleName, sizeof(roleName), "%T", "Role_Name_Detective", client);
	else Format(roleName, sizeof(roleName), "%T", "Role_Name_Innocent", client);

	int timeSinceDeath = RoundToNearest(GetEngineTime() - g_RagdollTimeOfDeath[ent]);
	char timeStr[32];
	if (timeSinceDeath < 60) Format(timeStr, sizeof(timeStr), "%T", "Body_Time_Seconds", LANG_SERVER, timeSinceDeath);
	else Format(timeStr, sizeof(timeStr), "%T", "Body_Time_Minutes", LANG_SERVER, timeSinceDeath / 60);

	if (g_iPlayerRole[client] == ROLE_DETECTIVE && g_iCorpseIdentifiers[client] > 0 && !g_bRagdollIdentified[ent])
	{
		g_iCorpseIdentifiers[client]--;
		g_bRagdollIdentified[ent] = true;
	}

	char killerStr[MAX_NAME_LENGTH];
	if (g_bRagdollIdentified[ent])
	{
		strcopy(killerStr, sizeof(killerStr), g_RagdollKiller[ent]);
	}
	else
	{
		char clientName[MAX_NAME_LENGTH];
		GetClientName(client, clientName, sizeof(clientName));
		if (StrEqual(g_RagdollKiller[ent], clientName)) Format(killerStr, sizeof(killerStr), "%T", "Corpse_Reason_You", client);
		else Format(killerStr, sizeof(killerStr), "%T", "Role_Unknown", client);
	}

	Format(title, sizeof(title), "%T", "Corpse_Title", client, g_RagdollName[ent], roleName, g_RagdollWeapon[ent], timeStr, killerStr);

	menu.SetTitle(title);
	char exitLabel[32];
	Format(exitLabel, sizeof(exitLabel), "%T", "Corpse_Menu_Exit", client);
	menu.AddItem("0", exitLabel);
	menu.ExitButton = false;
	menu.Display(client, 15);
}

public int MenuHandler_Corpse(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End) delete menu;
	return 0;
}

// ============================================================================
// Commands
// ============================================================================
public Action Command_Say(int client, const char[] command, int argc)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client)) return Plugin_Continue;
	
	char text[256];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	
	if (StrEqual(text, "!rtv", false) || StrEqual(text, "/rtv", false))
	{
		if (g_bVoteActive)
		{
			CancelClientMenu(client);
			ShowRTVMenu(client);
			return Plugin_Handled; // Blocks chat and other plugins like basevotes
		}
	}

	if (!g_bRoundLive || g_bTruceActive) return Plugin_Continue;

	if (!IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{
		if (text[0] == '\0') return Plugin_Handled;
		
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (!IsPlayerAlive(i) || GetClientTeam(i) != 2))
			{
				TTT_PrintToChat(i, "%t", "Chat_Dead_Prefix", name, text);
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_SayTeam(int client, const char[] command, int argc)
{
	return Command_Say(client, command, argc);
}

public Action Cmd_TraitorChat(int client, int args)
{
	if (client == 0 || !IsClientInGame(client)) return Plugin_Handled;
	if (!g_bRoundLive || g_bTruceActive) return Plugin_Handled;
	
	if (!IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Chat_Role_Dead");
		return Plugin_Handled;
	}
	
	if (g_iPlayerRole[client] != ROLE_TRAITOR)
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Chat_Traitor_Only");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Chat_Traitor_Usage");
		return Plugin_Handled;
	}
	
	char text[256];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && g_iPlayerRole[i] == ROLE_TRAITOR)
		{
			TTT_PrintToChat(i, "%t", "Chat_Traitor_Format", name, text);
		}
	}
	
	return Plugin_Handled;
}

public Action Cmd_DetectiveChat(int client, int args)
{
	if (client == 0 || !IsClientInGame(client)) return Plugin_Handled;
	if (!g_bRoundLive || g_bTruceActive) return Plugin_Handled;
	
	if (!IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Chat_Role_Dead");
		return Plugin_Handled;
	}
	
	if (g_iPlayerRole[client] != ROLE_DETECTIVE)
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Chat_Detective_Only");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Chat_Detective_Usage");
		return Plugin_Handled;
	}
	
	char text[256];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && g_iPlayerRole[i] == ROLE_DETECTIVE)
		{
			TTT_PrintToChat(i, "%t", "Chat_Detective_Format", name, text);
		}
	}
	
	return Plugin_Handled;
}

public Action Cmd_Detective(int client, int args)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		if (cv_ttt_karma_enabled.BoolValue && g_iActiveKarma[client] < 550)
		{
			TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Role_Requirements");
			return Plugin_Handled;
		}

		if (g_bNextRoundTraitor[client])
		{
			Menu menu = new Menu(MenuHandler_Detective_Confirm);
			char titleMsg[256]; Format(titleMsg, sizeof(titleMsg), "%T", "Menu_Detective_Active", client);
			menu.SetTitle(titleMsg);
			
			char itemYes[128]; Format(itemYes, sizeof(itemYes), "%T", "Menu_Detective_Cancel", client);
			menu.AddItem("yes", itemYes);
			
			char itemNo[128]; Format(itemNo, sizeof(itemNo), "%T", "Menu_Detective_Keep", client);
			menu.AddItem("no", itemNo);
			menu.Display(client, MENU_TIME_FOREVER);
			return Plugin_Handled;
		}

		Menu menu = new Menu(MenuHandler_Detective);
		char titleD[256]; Format(titleD, sizeof(titleD), "%T", "Menu_Detective_Confirm", client);
		menu.SetTitle(titleD);
		
		char itemYesD[128]; Format(itemYesD, sizeof(itemYesD), "%T", "Menu_Detective_Yes", client);
		menu.AddItem("yes", itemYesD);
		
		char itemNoD[128]; Format(itemNoD, sizeof(itemNoD), "%T", "Menu_Detective_No", client);
		menu.AddItem("no",  itemNoD);
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int MenuHandler_Detective_Confirm(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "yes"))
		{
			g_bNextRoundTraitor[param1] = false;
			g_bWantsDetective[param1] = true;
			TTT_PrintToChat(param1, "\x05[TTT]\x01 %t", "Menu_Detective_Cancelled");
		}
	}
	else if (action == MenuAction_End) delete menu;
	return 0;
}

public int MenuHandler_Detective(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "yes"))
		{
			g_bWantsDetective[param1] = true;
			TTT_PrintToChat(param1, "\x05[TTT]\x01 %t", "Menu_Detective_Applied");
		}
		else
		{
			g_bWantsDetective[param1] = false;
			TTT_PrintToChat(param1, "\x05[TTT]\x01 %t", "Menu_Detective_Revoked");
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public Action Cmd_SetRole(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_setrole <target> <1|2|3> (1=Innocent, 2=Traitor, 3=Detective)");
		return Plugin_Handled;
	}

	if (g_bTruceActive)
	{
		ReplyToCommand(client, "\x05[TTT]\x01 %t", "Admin_Role_Truce");
		return Plugin_Handled;
	}

	char arg1[32], arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	int role = StringToInt(arg2);
	if (role < 1 || role > 3) role = 1;

	char target_name[MAX_TARGET_LENGTH];
	int  target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS,
	    COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		if (GetClientTeam(target) != 2) continue;

		if (g_iSpriteEntity[target] > 0 && IsValidEntity(g_iSpriteEntity[target]))
		{
			AcceptEntityInput(g_iSpriteEntity[target], "Kill");
			g_iSpriteEntity[target] = 0;
		}

		g_iPlayerRole[target] = role;
		CreateRoleSprite(target, role);

		if (role == ROLE_DETECTIVE)
		{
			ScheduleModelChange(target, g_sModelPaths[4], 4);
			SetScreenOverlay(target, "sprites/Hud/Dhud");
		}
		else if (role == ROLE_TRAITOR)
		{
			ScheduleModelChange(target, g_sModelPaths[6], 6);
			SetScreenOverlay(target, "sprites/Hud/Thud");
		}
		else
		{
			ScheduleModelChange(target, g_sModelPaths[6], 6);
			SetScreenOverlay(target, "sprites/Hud/Ihud");
		}

		if (!IsFakeClient(target))
		{
			if      (role == ROLE_TRAITOR)   TTT_PrintToChat(target, "\x05[TTT]\x01 %t", "Admin_Role_Traitor");
			else if (role == ROLE_DETECTIVE)
			{
				TTT_PrintToChat(target, "\x05[TTT]\x01 %t", "Admin_Role_Detective");
				g_iCorpseIdentifiers[target] = 1;
				g_bHasKevlar[target] = true;
				g_bHasHelmet[target] = true;
				TTT_PrintToChat(target, "\x05[TTT]\x01 %t", "Role_Detective_Equip");
				
				int currentSecondary = GetPlayerWeaponSlot(target, 1);
				if (currentSecondary > 0 && IsValidEntity(currentSecondary))
				{
					RemovePlayerItem(target, currentSecondary);
					AcceptEntityInput(currentSecondary, "Kill");
				}

				int wep = CreateEntityByName("weapon_melee");
				if (wep != -1)
				{
					DispatchKeyValue(wep, "melee_script_name", "tonfa");
					DispatchSpawn(wep);
					EquipPlayerWeapon(target, wep);
				}

				if (GetPlayerWeaponSlot(target, 4) == -1)
				{
					int entity = CreateEntityByName("weapon_pain_pills");
					if (entity != -1)
					{
						DispatchSpawn(entity);
						EquipPlayerWeapon(target, entity);
					}
				}
			}
			else                             TTT_PrintToChat(target, "\x05[TTT]\x01 %t", "Admin_Role_Innocent");
		}
	}

	ReplyToCommand(client, "\x05[TTT]\x01 %t", "Admin_Role_Updated");
	CheckWinConditions();
	return Plugin_Handled;
}

// ============================================================================
// Round management
// ============================================================================
int g_iCleanCount = 0;

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{

	g_bRoundLive = false;
	g_bRoundEnded = false;
	if (g_hRoundTimer != null) { KillTimer(g_hRoundTimer); g_hRoundTimer = null; }

	int maxEnts = GetMaxEntities();
	char classname[64];
	char model[128];
	for (int e = MaxClients + 1; e <= maxEnts; e++)
	{
		if (IsValidEntity(e))
		{
			GetEntityClassname(e, classname, sizeof(classname));
			if (strncmp(classname, "prop_physics", 12, false) == 0)
			{
				GetEntPropString(e, Prop_Data, "m_ModelName", model, sizeof(model));
				if (StrContains(model, "wood_crate001a", false) != -1)
				{
					if (GetEntProp(e, Prop_Send, "m_iGlowType") == 3)
					{
						AcceptEntityInput(e, "Kill");
					}
				}
				else if (StrContains(model, "piano", false) != -1)
				{
					AcceptEntityInput(e, "Kill");
				}
			}
		}
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		CancelClientMenu(i);
		SetScreenOverlay(i, "");
		g_iPlayerRole[i] = ROLE_NONE;
		g_bHasKevlar[i] = false;
		g_bHasHelmet[i] = false;
		if (g_iSpriteEntity[i] > 0 && IsValidEntity(g_iSpriteEntity[i]))
		{
			AcceptEntityInput(g_iSpriteEntity[i], "Kill");
			g_iSpriteEntity[i] = 0;
		}
		g_bBoughtMissile[i] = false;
		g_iActiveMissile[i] = 0;
		g_fMissileEndTime[i] = 0.0;
		g_fLastPipeThrowTime[i] = 0.0;
		
		g_bBoughtC4[i] = false;
		g_iC4Entity[i] = 0;
		g_iC4PackEnt[i] = 0;
		g_iC4WrongAttempts[i] = 0;
		if (g_hC4DefuseTimer[i] != null) { KillTimer(g_hC4DefuseTimer[i]); g_hC4DefuseTimer[i] = null; }
		g_iMenuC4Owner[i] = 0;
		
		g_bHasDefuser[i] = false;
		g_fImmortalityEndTime[i] = 0.0;
		
		g_iActionCount[i] = 0;
	}
	g_fHordeCooldownEndTime = 0.0;
	g_fSpecialCooldownEndTime = 0.0;

	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "prop_dynamic_override")) != -1)
	{
		char targetName[64];
		GetEntPropString(ent, Prop_Data, "m_iName", targetName, sizeof(targetName));
		if (StrEqual(targetName, "ttt_missile"))
		{
			AcceptEntityInput(ent, "Kill");
		}
	}
	
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "upgrade_ammo_incendiary")) != -1)
	{
		char targetName[64];
		GetEntPropString(ent, Prop_Data, "m_iName", targetName, sizeof(targetName));
		if (StrEqual(targetName, "ttt_c4"))
		{
			AcceptEntityInput(ent, "Kill");
		}
	}

	for (int i = 0; i < 2048; i++)
	{
		g_RagdollRole[i]    = ROLE_NONE;
		g_RagdollScanned[i] = false;
	}

	g_iCleanCount = 0;
	CreateTimer(2.0, Timer_CleanLobby, _, TIMER_REPEAT);
}

void Karma_ProcessRoundEnd()
{
	if (!cv_ttt_karma_enabled.BoolValue || !g_bRoundLive) return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (g_iKarma[i] == 0)
			{
				g_iKarmaZeroRounds[i]++;
				if (g_iKarmaZeroRounds[i] >= 5)
				{
					g_iKarmaZeroRounds[i] = 0;
					Karma_Modify(i, 50, false);
					Karma_LogEvent(i, "Karma_Log_PenaltyServed", 50);
					TTT_PrintToChat(i, "\x05[TTT]\x01 %t", "Karma_Penalty_Done");
					ChangeClientTeam(i, 2);
				}
				else
				{
					if (!IsFakeClient(i))
						TTT_PrintToChat(i, "\x05[TTT]\x01 %t", "Karma_Penalty_Remaining", 5 - g_iKarmaZeroRounds[i]);
				}
			}
			else if (g_iPlayerRole[i] != ROLE_NONE)
			{
				if (!g_bHadPenaltyThisRound[i] && g_iKarma[i] > 0)
				{
					Karma_Modify(i, 20, false);
					Karma_LogEvent(i, "Karma_Log_CleanRound", 20);
					
					if (IsPlayerAlive(i))
					{
						Karma_Modify(i, 5, false);
						Karma_LogEvent(i, "Karma_Log_Survived", 5);
					}
					
					g_iCleanRounds[i]++;
					if (g_iCleanRounds[i] == 10)
					{
						Karma_Modify(i, 100, false);
						Karma_LogEvent(i, "Karma_Log_CleanStreak", 100);
					}
				}
			}
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Karma_ProcessRoundEnd();

	g_bRoundLive  = false;
	g_bRoundEnded = true;
	if (g_hRoundTimer != null) { KillTimer(g_hRoundTimer); g_hRoundTimer = null; }
	for (int i = 1; i <= MaxClients; i++)
	{
		SetScreenOverlay(i, "");
		if (g_iSpriteEntity[i] > 0 && IsValidEntity(g_iSpriteEntity[i]))
		{
			AcceptEntityInput(g_iSpriteEntity[i], "Kill");
			g_iSpriteEntity[i] = 0;
		}
		g_bBoughtMissile[i] = false;
		g_iActiveMissile[i] = 0;
		g_fMissileEndTime[i] = 0.0;
		g_fLastPipeThrowTime[i] = 0.0;
		
		g_bBoughtC4[i] = false;
		if (g_iC4Entity[i] != 0)
		{
			int c4 = EntRefToEntIndex(g_iC4Entity[i]);
			if (c4 > 0 && IsValidEntity(c4)) AcceptEntityInput(c4, "Kill");
			g_iC4Entity[i] = 0;
		}
		g_iC4PackEnt[i] = 0;
		g_iC4WrongAttempts[i] = 0;
		if (g_hC4DefuseTimer[i] != null) { KillTimer(g_hC4DefuseTimer[i]); g_hC4DefuseTimer[i] = null; }
		g_iMenuC4Owner[i] = 0;
		g_bHasDefuser[i] = false;
		g_fImmortalityEndTime[i] = 0.0;
		if (IsClientInGame(i))
		{
			SetEntityRenderMode(i, RENDER_NORMAL);
			SetEntityRenderColor(i, 255, 255, 255, 255);
		}
		for (int j = 1; j <= 5; j++) g_bC4WireCut[i][j] = false;
		for (int j = 1; j <= MaxClients; j++) 
		{
			g_bC4DefuserUsed[i][j] = false;
			g_iC4DefuserFakeWire[i][j] = 0;
		}
		g_fTankCooldownEndTime[i] = 0.0;
		g_bHasLootbox[i] = false;
		g_iLootboxCrateRef[i] = 0;
	}
	g_fHordeCooldownEndTime = 0.0;
	g_fSpecialCooldownEndTime = 0.0;
}

public Action Timer_CleanLobby(Handle timer)
{
	ServerCommand("sm_weapon_spawn_clear");
	ServerCommand("sm_ammo_spawn_clear");
	CleanWorldWeapons();
	g_iCleanCount++;
	if (g_iCleanCount >= 5) return Plugin_Stop;
	return Plugin_Continue;
}

void CleanWorldWeapons()
{
	int toKill[2048];
	int killCount = 0;
	int ent = -1;

	while ((ent = FindEntityByClassname(ent, "weapon_*")) != -1)
	{
		if (!IsValidEntity(ent)) continue;
		char cls[64];
		GetEntityClassname(ent, cls, sizeof(cls));

		if (StrContains(cls, "_spawn") != -1)
		{
			if (killCount < 2048) toKill[killCount++] = ent;
			continue;
		}
		if (HasEntProp(ent, Prop_Send, "m_hOwnerEntity"))
		{
			if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == -1)
				if (killCount < 2048) toKill[killCount++] = ent;
		}
		else
		{
			if (killCount < 2048) toKill[killCount++] = ent;
		}
	}

	ent = -1;
	while ((ent = FindEntityByClassname(ent, "prop_ragdoll")) != -1)
	{
		if (IsValidEntity(ent))
			if (killCount < 2048) toKill[killCount++] = ent;
	}

	for (int i = 0; i < killCount; i++)
		if (IsValidEntity(toKill[i])) AcceptEntityInput(toKill[i], "Kill");
}

// Called by ReadyUp plugin
public void OnRoundIsLive()
{
	if (g_bRoundLive) return;

	ConVar hRescue = FindConVar("rescue_min_dead_time");
	if (hRescue != null) hRescue.SetInt(99999);
	ConVar hClosets = FindConVar("director_no_rescue_closets");
	if (hClosets != null) hClosets.SetInt(1);

	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "prop_door_rotating_checkpoint")) != -1)
		if (IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "trigger_changelevel")) != -1)
		if (IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "info_changelevel")) != -1)
		if (IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "trigger_finale")) != -1)
		if (IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
	
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "weapon_gascan")) != -1)
		if (IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "prop_minigun")) != -1)
		if (IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "prop_minigun_l4d1")) != -1)
		if (IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "prop_mounted_machine_gun")) != -1)
		if (IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			for (int slot = 0; slot < 5; slot++)
			{
				int weapon = GetPlayerWeaponSlot(i, slot);
				if (weapon > 0 && IsValidEntity(weapon))
				{
					RemovePlayerItem(i, weapon);
					AcceptEntityInput(weapon, "Kill");
				}
			}
			for (int j = 0; j < 32; j++)
			{
				SetEntProp(i, Prop_Send, "m_iAmmo", 0, _, j);
			}
			int wep = CreateEntityByName("weapon_pistol");
			DispatchSpawn(wep);
			EquipPlayerWeapon(i, wep);
		}
	}

	CleanWorldWeapons();
	SpawnConfigWeapons();
	SpawnConfigAmmo();

	g_iCurrentRound = 1;
	g_bRoundEnded   = false;
	StartTruce();
}

// ============================================================================
// Weapon spawning
// ============================================================================
void SpawnConfigWeapons()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) CancelClientMenu(i);
	}

	char modWeapons[29][64] = {
		"weapon_pistol",
		"weapon_pistol_magnum",
		"weapon_rifle",
		"weapon_rifle_ak47",
		"weapon_rifle_sg552",
		"weapon_rifle_desert",
		"weapon_autoshotgun",
		"weapon_shotgun_spas",
		"weapon_pumpshotgun",
		"weapon_shotgun_chrome",
		"weapon_smg",
		"weapon_smg_silenced",
		"weapon_smg_mp5",
		"weapon_hunting_rifle",
		"weapon_sniper_awp",
		"weapon_sniper_military",
		"weapon_sniper_scout",
		"weapon_rifle_m60",
		"weapon_grenade_launcher",
		"weapon_chainsaw",
		"weapon_molotov",
		"weapon_pipe_bomb",
		"weapon_vomitjar",
		"weapon_pain_pills",
		"weapon_adrenaline",
		"weapon_first_aid_kit",
		"weapon_defibrillator",
		"weapon_upgradepack_explosive",
		"weapon_upgradepack_incendiary"
	};

	int len = g_aConfigPos.Length;
	for (int i = 0; i < len; i++)
	{
		int mod = g_aConfigMod.Get(i);
		if (mod < 0 || mod >= 29) continue;
		if (modWeapons[mod][0] == '\0') continue;

		float pos[3], ang[3];
		g_aConfigPos.GetArray(i, pos, 3);
		g_aConfigAng.GetArray(i, ang, 3);

		int wep = CreateEntityByName(modWeapons[mod]);
		if (wep > 0 && IsValidEntity(wep))
		{
			DispatchKeyValue(wep, "count", "1");
			DispatchKeyValueVector(wep, "origin", pos);
			DispatchKeyValueVector(wep, "angles", ang);
			DispatchSpawn(wep);
			SetEntityMoveType(wep, MOVETYPE_NONE);
		}
	}
}

void SpawnConfigAmmo()
{
	int len = g_aAmmoPos.Length;
	for (int i = 0; i < len; i++)
	{
		float pos[3], ang[3];
		g_aAmmoPos.GetArray(i, pos, 3);
		g_aAmmoAng.GetArray(i, ang, 3);

		int wep = CreateEntityByName("weapon_ammo_spawn");
		if (wep > 0 && IsValidEntity(wep))
		{
			DispatchKeyValue(wep, "count", "1");
			DispatchKeyValueVector(wep, "origin", pos);
			DispatchKeyValueVector(wep, "angles", ang);
			DispatchSpawn(wep);
		}
	}
}

// ============================================================================
// Truce & Roles
// ============================================================================
void ForceClientModel(int client, const char[] modelPath, int charId)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return;
	if (GetClientTeam(client) != 2) return;

	SetEntityModel(client, modelPath);
	SetEntProp(client, Prop_Send, "m_survivorCharacter", charId);
	SetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled", 0);
}

ArrayList g_aPendingModelChanges = null;

void ScheduleModelChange(int client, const char[] modelPath, int charId)
{
	if (g_aPendingModelChanges == null)
		g_aPendingModelChanges = new ArrayList(3);

	int idx = g_aPendingModelChanges.Length;
	g_aPendingModelChanges.Resize(idx + 1);
	g_aPendingModelChanges.Set(idx, GetClientUserId(client), 0);
	g_aPendingModelChanges.Set(idx, charId, 1);

	int modelIdx = 0;
	if (StrContains(modelPath, "gambler")  != -1) modelIdx = 0;
	else if (StrContains(modelPath, "producer") != -1) modelIdx = 1;
	else if (StrContains(modelPath, "coach")    != -1) modelIdx = 2;
	else if (StrContains(modelPath, "mechanic") != -1) modelIdx = 3;
	else if (StrContains(modelPath, "namvet")   != -1) modelIdx = 4;
	else if (StrContains(modelPath, "teenangst")!= -1) modelIdx = 5;
	else if (StrContains(modelPath, "biker")    != -1) modelIdx = 6;
	else if (StrContains(modelPath, "manager")  != -1) modelIdx = 7;
	g_aPendingModelChanges.Set(idx, modelIdx, 2);

	RequestFrame(Frame_ApplyModelChange, idx);
}

public void Frame_ApplyModelChange(any data)
{
	int idx = data;
	if (g_aPendingModelChanges == null || idx >= g_aPendingModelChanges.Length) return;

	int userid   = g_aPendingModelChanges.Get(idx, 0);
	int charId   = g_aPendingModelChanges.Get(idx, 1);
	int modelIdx = g_aPendingModelChanges.Get(idx, 2);

	int client = GetClientOfUserId(userid);
	if (client < 1 || !IsClientInGame(client) || !IsPlayerAlive(client)) return;
	if (GetClientTeam(client) != 2) return;
	if (modelIdx < 0 || modelIdx > 7) return;

	ForceClientModel(client, g_sModelPaths[modelIdx], charId);
}

void RestoreOriginalModel(int client)
{
	if (!IsClientInGame(client)) return;
	if (g_iOriginalChar[client] == -1) return;
	if (GetClientTeam(client) != 2) return;

	SetEntityModel(client, g_sOriginalModel[client]);
	SetEntProp(client, Prop_Send, "m_survivorCharacter", g_iOriginalChar[client]);
}

void StartTruce()
{
	g_bRoundLive   = true;
	g_bTruceActive = true;
	g_bRoundEnded  = false;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			if (IsPlayerAlive(i))
				ScheduleModelChange(i, g_sModelPaths[6], 6);
		}
	}

	TeleportPlayersToSpawns();

	g_iTruceTimeLeft = cv_ttt_truce_duration.IntValue;
	PrintHintTextToAll("%t", "Hint_RoundStartIn", g_iCurrentRound, g_iMaxRounds, g_iTruceTimeLeft);
	CreateTimer(1.0, Timer_TruceCountdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void TeleportPlayersToSpawns()
{
	bool usePlayerSpawns = (g_aPlayerSpawns != null && g_aPlayerSpawns.Length > 0);
	
	if (!usePlayerSpawns && g_aConfigPos.Length == 0) return;

	ArrayList availableSpawns;
	if (usePlayerSpawns) {
		availableSpawns = g_aPlayerSpawns.Clone();
	} else {
		availableSpawns = g_aConfigPos.Clone();
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			if (availableSpawns.Length == 0)
			{
				delete availableSpawns;
				if (usePlayerSpawns) {
					availableSpawns = g_aPlayerSpawns.Clone();
				} else {
					availableSpawns = g_aConfigPos.Clone();
				}
			}

			int rand = GetRandomInt(0, availableSpawns.Length - 1);
			float pos[3];
			availableSpawns.GetArray(rand, pos, 3);
			availableSpawns.Erase(rand);

			if (!usePlayerSpawns) {
				pos[2] += 20.0;
			} else {
				pos[2] += 5.0;
			}
			
			TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
	delete availableSpawns;
}

public Action Timer_TruceCountdown(Handle timer)
{
	g_iTruceTimeLeft--;
	if (g_iTruceTimeLeft > 0)
	{
		PrintHintTextToAll("%t", "Hint_RoundStartIn", g_iCurrentRound, g_iMaxRounds, g_iTruceTimeLeft);
		return Plugin_Continue;
	}

	PrintHintTextToAll("%t", "Hint_RoundStarted", g_iCurrentRound);
	g_bTruceActive = false;
	g_fRoundStartTime = GetEngineTime();
	
	g_iRoundTimeLeft = cv_ttt_round_duration.IntValue;
	if (g_hRoundTimer != null) { KillTimer(g_hRoundTimer); g_hRoundTimer = null; }
	g_hRoundTimer = CreateTimer(1.0, Timer_RoundCountdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "survivor_death_model")) != -1)
		if (IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "prop_ragdoll")) != -1)
		if (IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");

	bool usePlayerSpawns = (g_aPlayerSpawns != null && g_aPlayerSpawns.Length > 0);
	ArrayList availableSpawns = null;
	if (usePlayerSpawns || g_aConfigPos.Length > 0)
	{
		availableSpawns = usePlayerSpawns ? g_aPlayerSpawns.Clone() : g_aConfigPos.Clone();
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i))
		{
			L4D_RespawnPlayer(i);
			
			if (availableSpawns != null && availableSpawns.Length > 0)
			{
				int rand = GetRandomInt(0, availableSpawns.Length - 1);
				float pos[3];
				availableSpawns.GetArray(rand, pos, 3);
				availableSpawns.Erase(rand);
				
				if (!usePlayerSpawns) pos[2] += 20.0;
				else pos[2] += 5.0;
				
				TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
				
				if (availableSpawns.Length == 0)
				{
					delete availableSpawns;
					availableSpawns = usePlayerSpawns ? g_aPlayerSpawns.Clone() : g_aConfigPos.Clone();
				}
			}
		}
	}
	
	if (availableSpawns != null) delete availableSpawns;
	
	AssignRoles();
	return Plugin_Stop;
}

public Action Timer_RoundCountdown(Handle timer)
{
	if (!g_bRoundLive || g_bTruceActive || g_bRoundEnded)
	{
		g_hRoundTimer = null;
		return Plugin_Stop;
	}

	g_iRoundTimeLeft--;

	if (g_iRoundTimeLeft <= 0)
	{
		g_bRoundLive  = false;
		g_bRoundEnded = true;
		
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				PrintHintText(i, "%t", "Hint_RoundOver");
				SetScreenOverlay(i, "sprites/ResultIV/Iwin");
			}
		}

		CreateTimer(5.0, Timer_RestartRound);
		
		g_hRoundTimer = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void AssignRoles()
{
	int players[MAXPLAYERS + 1];
	int count = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			players[count] = i;
			count++;
			g_iPlayerRole[i] = ROLE_INNOCENT;
		}
	}

	if (count == 0) return;

	// --- Assign Detectives ---
	float detRatio = cv_ttt_role_detective_ratio.FloatValue / 100.0;
	int numDetectives = RoundToNearest(count * detRatio);

	int optInPool[MAXPLAYERS + 1];
	int optInCount = 0;
	for (int i = 0; i < count; i++)
		if (g_bWantsDetective[players[i]]) optInPool[optInCount++] = players[i];

	int assignedDetectives = 0;
	while (assignedDetectives < numDetectives && optInCount > 0)
	{
		int randIdx = GetRandomInt(0, optInCount - 1);
		int cl      = optInPool[randIdx];
		if (g_iPlayerRole[cl] == ROLE_INNOCENT)
		{
			g_iPlayerRole[cl] = ROLE_DETECTIVE;
			assignedDetectives++;
			optInPool[randIdx] = optInPool[optInCount - 1];
			optInCount--;
		}
	}

	// --- Assign Traitors ---
	float traitorRatio = cv_ttt_role_traitor_ratio.FloatValue / 100.0;
	int numTraitors = RoundToNearest(count * traitorRatio);
	if (numTraitors < 1) numTraitors = 1;

	int assignedTraitors = 0;
	
	int optInPoolT[MAXPLAYERS + 1];
	int optInCountT = 0;
	for (int i = 0; i < count; i++)
		if (g_bNextRoundTraitor[players[i]] && g_iPlayerRole[players[i]] == ROLE_INNOCENT)
			optInPoolT[optInCountT++] = players[i];
			
	while (assignedTraitors < numTraitors && optInCountT > 0)
	{
		int randIdx = GetRandomInt(0, optInCountT - 1);
		int cl      = optInPoolT[randIdx];
		g_iPlayerRole[cl] = ROLE_TRAITOR;
		assignedTraitors++;
		optInPoolT[randIdx] = optInPoolT[optInCountT - 1];
		optInCountT--;
	}

	while (assignedTraitors < numTraitors)
	{
		int randIdx = GetRandomInt(0, count - 1);
		int cl      = players[randIdx];
		if (g_iPlayerRole[cl] == ROLE_INNOCENT)
		{
			g_iPlayerRole[cl] = ROLE_TRAITOR;
			assignedTraitors++;
		}
	}
	
	for (int i = 1; i <= MaxClients; i++) g_bNextRoundTraitor[i] = false;

	// --- Announce ---
	char traitorStr[64];
	if (numTraitors == 1) Format(traitorStr, sizeof(traitorStr), "%T", "Role_Assign_Traitors1", LANG_SERVER);
	else                  Format(traitorStr, sizeof(traitorStr), "%T", "Role_Assign_TraitorsN", LANG_SERVER, numTraitors);

	char detectiveStr[64] = "";
	if      (assignedDetectives == 1) Format(detectiveStr, sizeof(detectiveStr), "%T", "Role_Assign_Detectives1", LANG_SERVER);
	else if (assignedDetectives  > 1) Format(detectiveStr, sizeof(detectiveStr), "%T", "Role_Assign_DetectivesN", LANG_SERVER, assignedDetectives);

	char verbStr[64];
	if (numTraitors + assignedDetectives == 1) Format(verbStr, sizeof(verbStr), "%T", "Role_Assign_Verb1", LANG_SERVER);
	else                                       Format(verbStr, sizeof(verbStr), "%T", "Role_Assign_VerbN", LANG_SERVER);

	TTT_PrintToChatAll("\x05[TTT]\x01 %t", "Role_Assign_Final", traitorStr, detectiveStr, verbStr);

	// --- Notify players individually ---
	for (int i = 0; i < count; i++)
	{
		int cl = players[i];

		if (g_iPlayerRole[cl] == ROLE_TRAITOR)
		{
			if (!IsFakeClient(cl)) TTT_PrintToChat(cl, "\x05[TTT]\x01 %t", "Role_YouAre_Traitor");

			if (!IsFakeClient(cl))
			{
				int teamCount = 0;
				for (int j = 0; j < count; j++)
					if (players[j] != cl && g_iPlayerRole[players[j]] == ROLE_TRAITOR) teamCount++;

				if (teamCount > 0)
				{
					TTT_PrintToChat(cl, "\x05[TTT]\x01 %t", "Role_Traitor_Mates");
					for (int j = 0; j < count; j++)
						if (players[j] != cl && g_iPlayerRole[players[j]] == ROLE_TRAITOR)
							TTT_PrintToChat(cl, "\x05[TTT]\x01 {green}%N{default}", players[j]);
				}
			}
			CreateRoleSprite(cl, ROLE_TRAITOR);
			SetScreenOverlay(cl, "sprites/Hud/Thud");
		}
		else if (g_iPlayerRole[cl] == ROLE_DETECTIVE)
		{
			ScheduleModelChange(cl, g_sModelPaths[4], 4);

			if (!IsFakeClient(cl)) 
			{
				TTT_PrintToChat(cl, "\x05[TTT]\x01 %t", "Role_YouAre_Detective");
				g_iCorpseIdentifiers[cl] = 1;
				g_bHasKevlar[cl] = true;
				g_bHasHelmet[cl] = true;
				TTT_PrintToChat(cl, "\x05[TTT]\x01 %t", "Role_Detective_Equip");
				
				int currentSecondary = GetPlayerWeaponSlot(cl, 1);
				if (currentSecondary > 0 && IsValidEntity(currentSecondary))
				{
					RemovePlayerItem(cl, currentSecondary);
					AcceptEntityInput(currentSecondary, "Kill");
				}

				int wep = CreateEntityByName("weapon_melee");
				if (wep != -1)
				{
					DispatchKeyValue(wep, "melee_script_name", "tonfa");
					DispatchSpawn(wep);
					EquipPlayerWeapon(cl, wep);
				}

				if (GetPlayerWeaponSlot(cl, 4) == -1)
				{
					int entity = CreateEntityByName("weapon_pain_pills");
					if (entity != -1)
					{
						DispatchSpawn(entity);
						EquipPlayerWeapon(cl, entity);
					}
				}
			}

			if (!IsFakeClient(cl))
			{
				int teamCountD = 0;
				for (int j = 0; j < count; j++)
					if (players[j] != cl && g_iPlayerRole[players[j]] == ROLE_DETECTIVE) teamCountD++;

				if (teamCountD > 0)
				{
					TTT_PrintToChat(cl, "\x05[TTT]\x01 %t", "Role_Detective_Mates");
					for (int j = 0; j < count; j++)
						if (players[j] != cl && g_iPlayerRole[players[j]] == ROLE_DETECTIVE)
							TTT_PrintToChat(cl, "\x05[TTT]\x01 {lightgreen}%N{default}", players[j]);
				}
			}
			CreateRoleSprite(cl, ROLE_DETECTIVE);
			SetScreenOverlay(cl, "sprites/Hud/Dhud");
		}
		else
		{
			if (!IsFakeClient(cl)) TTT_PrintToChat(cl, "\x05[TTT]\x01 %t", "Role_YouAre_Innocent");
			SetScreenOverlay(cl, "sprites/Hud/Ihud");
		}
	}
}

public void Event_PillsUsed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		g_iPillsHealAmount[client] = 50;
		if (g_hPillsTimer[client] == null)
		{
			g_hPillsTimer[client] = CreateTimer(0.1, Timer_ProgressiveHeal, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_ProgressiveHeal(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		if (client > 0 && client <= MaxClients) g_hPillsTimer[client] = null;
		return Plugin_Stop;
	}

	int hp = GetClientHealth(client);
	if (hp >= 100 || g_iPillsHealAmount[client] <= 0)
	{
		g_hPillsTimer[client] = null;
		return Plugin_Stop;
	}

	SetEntityHealth(client, hp + 1);
	g_iPillsHealAmount[client]--;
	return Plugin_Continue;
}

// ============================================================================
// Death & Win conditions
// ============================================================================
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bRoundLive && !g_bRoundEnded) return;

	event.BroadcastDisabled = true;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int client   = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0 && client <= MaxClients)
	{
		if (g_bBoughtMissile[client])
		{
			int wep = GetPlayerWeaponSlot(client, 2);
			if (wep > 0 && IsValidEntity(wep))
			{
				char cls[64];
				GetEntityClassname(wep, cls, sizeof(cls));
				if (StrEqual(cls, "weapon_pipe_bomb"))
				{
					RemovePlayerItem(client, wep);
					AcceptEntityInput(wep, "Kill");
				}
			}
			g_bBoughtMissile[client] = false;
		}

		if (g_iActiveMissile[client] != 0)
		{
			g_iActiveMissile[client] = 0;
			if (IsClientInGame(client)) SetClientViewEntity(client, client);
		}
	}

	if (client > 0 && client <= MaxClients && g_hPillsTimer[client] != null)
	{
		KillTimer(g_hPillsTimer[client]);
		g_hPillsTimer[client] = null;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_iTaserTarget[i] == client)
		{
			if (g_iTaserSprite[i] > 0 && IsValidEntity(g_iTaserSprite[i]))
			{
				AcceptEntityInput(g_iTaserSprite[i], "Kill");
			}
			g_iTaserSprite[i] = 0;
			g_iTaserTarget[i] = 0;
		}
	}

	int realAttacker = attacker;
	if (attacker > 0 && attacker <= MaxClients && IsFakeClient(attacker) && GetClientTeam(attacker) == 3 && g_iZombieOwner[attacker] > 0)
	if (realAttacker > 0 && realAttacker <= MaxClients && IsFakeClient(attacker) && GetClientTeam(attacker) == 3 && g_iZombieOwner[attacker] > 0)
	{
		realAttacker = g_iZombieOwner[attacker];
	}

	if (client > 0 && client <= MaxClients && IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		int killer = realAttacker;
		if (g_bRoundLive && killer > 0 && killer <= MaxClients && IsClientInGame(killer)
			&& (g_iPlayerRole[killer] == ROLE_INNOCENT || g_iPlayerRole[killer] == ROLE_DETECTIVE))
		{
			if (g_iZombieOwner[client] > 0)
			{
				int ZClass = GetEntProp(client, Prop_Send, "m_zombieClass");
				if (ZClass == 8)
					LogActionCredits(killer, "Karma_Log_Tank", cv_ttt_credits_kill_tank.IntValue);
				else
					LogActionCredits(killer, "Karma_Log_Special", cv_ttt_credits_kill_special.IntValue);
			}
		}

		g_iZombieOwner[client] = 0;
		if (client >= 1 && client <= MaxClients) g_bTraitorSpawned[client] = false;

		return;
	}

	if (realAttacker > 0 && realAttacker <= MaxClients && realAttacker != client
	    && GetClientTeam(realAttacker) == 2 && GetClientTeam(client) == 2)
	{
		if (g_bRoundLive && cv_ttt_karma_enabled.BoolValue)
		{
			bool isTeamkill = false;
			int atkRole = g_iPlayerRole[realAttacker];
			int vicRole = g_iPlayerRole[client];
			
			if (atkRole == ROLE_TRAITOR && vicRole == ROLE_TRAITOR) isTeamkill = true;
			else if ((atkRole == ROLE_INNOCENT || atkRole == ROLE_DETECTIVE) &&
			         (vicRole == ROLE_INNOCENT || vicRole == ROLE_DETECTIVE)) isTeamkill = true;
			
			if (isTeamkill)
			{
				g_bHasValidKillThisRound[realAttacker] = true;
				float lastDmgTime = g_fLastDamageTime[realAttacker][client];
				if (GetEngineTime() - lastDmgTime <= cv_ttt_karma_defend_window.FloatValue)
				{
					TTT_PrintToChat(realAttacker, "\x05[TTT]\x01 %t", "Death_Legit_Defense");
				}
				else
				{
					int penalty = cv_ttt_karma_penalty_teamkill.IntValue;
					Karma_Modify(realAttacker, -penalty, true);
					Karma_LogEvent(realAttacker, "Karma_Log_Teamkill", -penalty);
				}
			}
			else
			{
				if (!g_bHasValidKillThisRound[realAttacker])
				{
					g_bHasValidKillThisRound[realAttacker] = true;
					Karma_Modify(realAttacker, 10, false);
					Karma_LogEvent(realAttacker, "Karma_Log_ValidKill", 10);
				}
			}
		}

		if (!IsFakeClient(realAttacker) && g_iPlayerRole[realAttacker] == ROLE_TRAITOR)
		{
			if      (g_iPlayerRole[client] == ROLE_INNOCENT)  TTT_PrintToChat(realAttacker, "\x05[TTT]\x01 %t", "Death_Killed_Innocent");
			else if (g_iPlayerRole[client] == ROLE_DETECTIVE) TTT_PrintToChat(realAttacker, "\x05[TTT]\x01 %t", "Death_Killed_Detective");
			else if (g_iPlayerRole[client] == ROLE_TRAITOR)   TTT_PrintToChat(realAttacker, "\x05[TTT]\x01 %t", "Death_Killed_Traitor");
		}

		if (!IsFakeClient(client))
		{
			if      (g_iPlayerRole[realAttacker] == ROLE_INNOCENT)  TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Death_Killer_Innocent");
			else if (g_iPlayerRole[realAttacker] == ROLE_DETECTIVE) TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Death_Killer_Detective");
			else if (g_iPlayerRole[realAttacker] == ROLE_TRAITOR)   TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Death_Killer_Traitor");
		}
	}

	if (client > 0 && client <= MaxClients && GetClientTeam(client) == 2)
	{
		float pos[3], ang[3];
		GetClientAbsOrigin(client, pos);
		GetClientAbsAngles(client, ang);

		char modelName[PLATFORM_MAX_PATH];
		GetEntPropString(client, Prop_Data, "m_ModelName", modelName, sizeof(modelName));

		int ragdoll = CreateEntityByName("prop_ragdoll");
		if (ragdoll != -1)
		{
			DispatchKeyValue(ragdoll, "model", modelName);
			DispatchKeyValueVector(ragdoll, "origin", pos);
			DispatchKeyValueVector(ragdoll, "angles", ang);
			DispatchSpawn(ragdoll);

			SetEntProp(ragdoll, Prop_Data, "m_CollisionGroup", 2);

			float vel[3];
			vel[0] = GetRandomFloat(-150.0, 150.0);
			vel[1] = GetRandomFloat(-150.0, 150.0);
			vel[2] = GetRandomFloat(100.0, 250.0);
			TeleportEntity(ragdoll, NULL_VECTOR, NULL_VECTOR, vel);

			g_RagdollRole[ragdoll]    = g_iPlayerRole[client];
			GetClientName(client, g_RagdollName[ragdoll], MAX_NAME_LENGTH);
			g_RagdollScanned[ragdoll] = false;
			g_RagdollTimeOfDeath[ragdoll] = GetEngineTime();
			
			char weapon[64];
			GetEventString(event, "weapon", weapon, sizeof(weapon));
			if (weapon[0] == '\0') Format(weapon, sizeof(weapon), "%T", "Corpse_Weapon_Unknown", LANG_SERVER);
			strcopy(g_RagdollWeapon[ragdoll], sizeof(g_RagdollWeapon[]), weapon);
			
			if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
			{
				if (IsFakeClient(attacker) && GetClientTeam(attacker) == 3 && g_iZombieOwner[attacker] > 0)
				{
					int owner = g_iZombieOwner[attacker];
					if (IsClientInGame(owner))
						GetClientName(owner, g_RagdollKiller[ragdoll], MAX_NAME_LENGTH);
					else
						Format(g_RagdollKiller[ragdoll], MAX_NAME_LENGTH, "%T", "Role_Name_Disconnected", LANG_SERVER);
				}
				else
				{
					GetClientName(attacker, g_RagdollKiller[ragdoll], MAX_NAME_LENGTH);
				}
			}
			else
				Format(g_RagdollKiller[ragdoll], MAX_NAME_LENGTH, "%T", "Role_Name_Unknown", LANG_SERVER);
		}

		if (g_bRoundLive && realAttacker > 0 && realAttacker <= MaxClients && IsClientInGame(realAttacker) && realAttacker != client)
		{
			int aRole = g_iPlayerRole[realAttacker];
			int vRole = g_iPlayerRole[client];

			if (aRole == ROLE_TRAITOR)
			{
				if (vRole == ROLE_INNOCENT)       LogActionCredits(realAttacker, "Karma_Log_KillInnocent", cv_ttt_credits_kill_innocent.IntValue);
				else if (vRole == ROLE_DETECTIVE) LogActionCredits(realAttacker, "Karma_Log_KillDetective", cv_ttt_credits_kill_detective.IntValue);
				else if (vRole == ROLE_TRAITOR)   LogActionCredits(realAttacker, "Karma_Log_KillTraitor", cv_ttt_credits_kill_traitor.IntValue);
			}
			else if (aRole == ROLE_INNOCENT || aRole == ROLE_DETECTIVE)
			{
				if (vRole == ROLE_DETECTIVE)
				{
					LogActionCredits(realAttacker, "Karma_Log_KillDetective", (aRole == ROLE_INNOCENT) ? -cv_ttt_credits_kill_detective.IntValue : -1);
				}
				else if (vRole == ROLE_TRAITOR)
				{
					LogActionCredits(realAttacker, "Karma_Log_KillTraitor", cv_ttt_credits_kill_traitor.IntValue);
				}
				else if (GetClientTeam(client) == 3 && g_iZombieOwner[client] > 0)
				{
					int zClass = GetEntProp(client, Prop_Send, "m_zombieClass");
					if (zClass == 8) // Tank
						LogActionCredits(realAttacker, "Karma_Log_Tank", cv_ttt_credits_kill_tank.IntValue);
					else if (GetEntProp(client, Prop_Send, "m_zombieClass") != 8)
						LogActionCredits(realAttacker, "Karma_Log_Special", cv_ttt_credits_kill_special.IntValue);
				}
			}
		}

		g_iPlayerRole[client] = ROLE_NONE;

		if (g_iSpriteEntity[client] > 0 && IsValidEntity(g_iSpriteEntity[client]))
		{
			AcceptEntityInput(g_iSpriteEntity[client], "Kill");
			g_iSpriteEntity[client] = 0;
		}
		CheckWinConditions();
	}
}

public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bRoundLive) return;
	
	int userid = event.GetInt("userid");
	if (userid == 0) return;
	
	int killer = GetClientOfUserId(userid);
	if (killer > 0 && killer <= MaxClients && IsClientInGame(killer))
	{
		int kRole = g_iPlayerRole[killer];
		if (kRole == ROLE_INNOCENT || kRole == ROLE_DETECTIVE)
		{
			LogActionCredits(killer, "Karma_Log_Witch", cv_ttt_credits_kill_witch.IntValue);
		}
	}
}

void CheckWinConditions()
{
	if (!g_bRoundLive || g_bTruceActive) return;

	int innocentsAlive = 0;
	int traitorsAlive  = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			if      (g_iPlayerRole[i] == ROLE_TRAITOR)  traitorsAlive++;
			else if (g_iPlayerRole[i] == ROLE_INNOCENT || g_iPlayerRole[i] == ROLE_DETECTIVE) innocentsAlive++;
		}
	}

	if (traitorsAlive == 0)
	{
		Karma_ProcessRoundEnd();
		g_bRoundLive  = false;
		g_bRoundEnded = true;
		CleanupZombiesAndBots();
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				PrintHintText(i, "%t", "Hint_RoundOver");
				SetScreenOverlay(i, "sprites/ResultIV/Iwin");
				
				if (IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					if (g_iActiveKarma[i] < 550)
						LogActionCredits(i, "Win_Survivor_Karma", 0);
					else
						LogActionCredits(i, "Win_Survivor", cv_ttt_credits_survive.IntValue);
				}
				
				PrintRoundSummary(i);
			}
		}

		CreateTimer(5.0, Timer_RestartRound);
	}
	else if (innocentsAlive == 0)
	{
		Karma_ProcessRoundEnd();
		g_bRoundLive  = false;
		g_bRoundEnded = true;
		CleanupZombiesAndBots();
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				PrintHintText(i, "%t", "Hint_RoundOver");
				SetScreenOverlay(i, "sprites/ResultIV/Twin");
				
				if (IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					if (g_iActiveKarma[i] < 550)
						LogActionCredits(i, "Win_Survivor_Karma", 0);
					else
						LogActionCredits(i, "Win_Survivor", cv_ttt_credits_survive.IntValue);
				}
				
				PrintRoundSummary(i);
			}
		}

		CreateTimer(5.0, Timer_RestartRound);
	}
}

public Action Timer_RestartRound(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++) {
		SetScreenOverlay(i, "");
		g_iCorpseIdentifiers[i] = 0;
		if (g_hPillsTimer[i] != null) { KillTimer(g_hPillsTimer[i]); g_hPillsTimer[i] = null; }
		
		g_iActionCount[i] = 0;
		
		if (IsClientInGame(i))
		{
			g_iActiveKarma[i] = g_iKarma[i];
			g_bKarmaChangedThisRound[i] = false;
			g_bHadPenaltyThisRound[i] = false;
			g_bHasValidKillThisRound[i] = false;
			
			g_iKarmaLogCount_Prev[i] = g_iKarmaLogCount[i];
			for (int j = 0; j < g_iKarmaLogCount[i]; j++)
			{
				strcopy(g_sKarmaLog_Prev[i][j], 64, g_sKarmaLog[i][j]);
				g_iKarmaLogPoints_Prev[i][j] = g_iKarmaLogPoints[i][j];
			}
			g_iKarmaLogCount[i] = 0;
			
			if (!IsFakeClient(i) && g_iActiveKarma[i] == 0)
			{
				if (cv_ttt_karma_zero_autospectator.BoolValue)
				{
					ChangeClientTeam(i, 1);
					TTT_PrintToChat(i, "\x05[TTT]\x01 %t", "Karma_Spectator_Kick");
				}
				else if (cv_ttt_karma_zero_autosuicide.BoolValue && IsPlayerAlive(i))
				{
					ForcePlayerSuicide(i);
					TTT_PrintToChat(i, "\x05[TTT]\x01 %t", "Karma_Zero_Death");
				}
			}
		}
	}

	for (int i = 0; i < 2048; i++) {
		g_bRagdollIdentified[i] = false;
	}

	g_bRoundEnded = false;
	g_iCurrentRound++;

	if (g_iCurrentRound == g_iMaxRounds - 1)
	{
		StartRTVVote();
	}

	if (g_iCurrentRound > g_iMaxRounds)
	{
		int len = g_aRTVMapNames.Length;
		
		if (g_iWinningVote == len)
		{
			int extendRounds = cv_ttt_rtv_extend_rounds.IntValue;
			g_iMaxRounds += extendRounds;
			TTT_PrintToChatAll("\x05[TTT]\x01 %t", "RTV_Extend_Map", extendRounds, g_iMaxRounds);
			
			g_bVoteActive = false;
			g_iWinningVote = -1;
			for (int j = 0; j < 32; j++) g_iVotes[j] = 0;
			for (int j = 1; j <= MaxClients; j++) g_iPlayerVote[j] = -1;
		}
		else if (g_iWinningVote >= 0 && g_iWinningVote < len)
		{
			char mapName[64];
			char mapDisplay[128];
			g_aRTVMapNames.GetString(g_iWinningVote, mapName, sizeof(mapName));
			g_aRTVMapDisplays.GetString(g_iWinningVote, mapDisplay, sizeof(mapDisplay));
			
			TTT_PrintToChatAll("\x05[TTT]\x01 %t", "RTV_End_Change", mapDisplay);
			ServerCommand("changelevel %s", mapName);
			return Plugin_Stop;
		}
		else
		{
			TTT_PrintToChatAll("\x05[TTT]\x01 %t", "RTV_End_Restart", g_iMaxRounds);
			char currentMap[64];
			GetCurrentMap(currentMap, sizeof(currentMap));
			ServerCommand("changelevel %s", currentMap);
			return Plugin_Stop;
		}
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			if (!IsPlayerAlive(i)) L4D_RespawnPlayer(i);
			SetEntityHealth(i, 100);

			for (int slot = 0; slot < 5; slot++)
			{
				int weapon = GetPlayerWeaponSlot(i, slot);
				if (weapon > 0 && IsValidEntity(weapon))
				{
					RemovePlayerItem(i, weapon);
					AcceptEntityInput(weapon, "Kill");
				}
			}

			for (int j = 0; j < 32; j++)
			{
				SetEntProp(i, Prop_Send, "m_iAmmo", 0, _, j);
			}

			int wep = CreateEntityByName("weapon_pistol");
			DispatchSpawn(wep);
			EquipPlayerWeapon(i, wep);

			if (g_iSpriteEntity[i] > 0 && IsValidEntity(g_iSpriteEntity[i]))
			{
				AcceptEntityInput(g_iSpriteEntity[i], "Kill");
				g_iSpriteEntity[i] = 0;
			}
			g_iPlayerRole[i] = ROLE_NONE;
			
			g_bHasKevlar[i] = false;
			g_bHasHelmet[i] = false;
			g_bBoughtMissile[i] = false;
			g_iActiveMissile[i] = 0;
			g_fMissileEndTime[i] = 0.0;
			g_fLastPipeThrowTime[i] = 0.0;
			g_bBoughtC4[i] = false;
			g_iC4Entity[i] = 0;
			g_iC4PackEnt[i] = 0;
			g_iC4WrongAttempts[i] = 0;
			if (g_hC4DefuseTimer[i] != null) { KillTimer(g_hC4DefuseTimer[i]); g_hC4DefuseTimer[i] = null; }
			g_iMenuC4Owner[i] = 0;
			g_bHasDefuser[i] = false;
			g_fImmortalityEndTime[i] = 0.0;
			for (int j = 1; j <= 5; j++) g_bC4WireCut[i][j] = false;
			for (int j = 1; j <= MaxClients; j++)
			{
				g_bC4DefuserUsed[i][j] = false;
				g_iC4DefuserFakeWire[i][j] = 0;
			}
			g_fTankCooldownEndTime[i] = 0.0;
			
			SetEntityRenderMode(i, RENDER_NORMAL);
			SetEntityRenderColor(i, 255, 255, 255, 255);
		}
	}
	g_fHordeCooldownEndTime = 0.0;
	g_fSpecialCooldownEndTime = 0.0;

	for (int i = 0; i < 2048; i++)
	{
		g_RagdollRole[i]    = ROLE_NONE;
		g_RagdollScanned[i] = false;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		g_iZombieOwner[i] = 0;
		g_bTraitorSpawned[i] = false;
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
		{
			KickClient(i, "Round cleanup");
		}
	}

	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "infected")) != -1)
	{
		AcceptEntityInput(ent, "KillHierarchy");
	}
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "witch")) != -1)
	{
		AcceptEntityInput(ent, "KillHierarchy");
	}

	CleanWorldWeapons();
	SpawnConfigWeapons();
	SpawnConfigAmmo();
	StartTruce();

	return Plugin_Stop;
}

// ============================================================================
// Sprite system (unchanged)
// ============================================================================
void CreateRoleSprite(int client, int role)
{
	if (g_iSpriteEntity[client] > 0 && IsValidEntity(g_iSpriteEntity[client]))
	{
		AcceptEntityInput(g_iSpriteEntity[client], "Kill");
		g_iSpriteEntity[client] = 0;
	}

	if (role == ROLE_INNOCENT || role == ROLE_NONE) return;

	int sprite = CreateEntityByName("env_sprite");
	if (sprite == -1) return;

	if      (role == ROLE_TRAITOR)   DispatchKeyValue(sprite, "model", "sprites/Tside/Tside.vmt");
	else if (role == ROLE_DETECTIVE) DispatchKeyValue(sprite, "model", "sprites/Dside/Dside.vmt");

	DispatchKeyValue(sprite, "rendercolor",  "255 255 255");
	DispatchKeyValue(sprite, "renderamt",    "255");
	DispatchKeyValue(sprite, "rendermode",   "9");
	DispatchKeyValue(sprite, "scale",        "0.05");
	DispatchKeyValue(sprite, "spawnflags",   "1");
	DispatchKeyValue(sprite, "framerate",    "0");

	float pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] += 90.0;
	DispatchKeyValueVector(sprite, "origin", pos);

	DispatchSpawn(sprite);
	ActivateEntity(sprite);

	SetVariantString("!activator");
	AcceptEntityInput(sprite, "SetParent", client, sprite, 0);

	SDKHook(sprite, SDKHook_SetTransmit, OnSpriteTransmit);
	SDKHook(sprite, SDKHook_Use,         OnSpriteUse);
	g_iSpriteEntity[client] = sprite;
}

public Action OnSpriteUse(int entity, int activator, int caller, UseType type, float value)
{
	return Plugin_Handled;
}

public Action OnSpriteTransmit(int entity, int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) return Plugin_Continue;

	int owner = -1;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_iSpriteEntity[i] == entity) { owner = i; break; }
	}

	if (owner == -1)                                                              return Plugin_Continue;
	if (client == owner)                                                          return Plugin_Handled;

	if (g_iPlayerRole[owner] == ROLE_DETECTIVE)                                  return Plugin_Continue;

	if (g_iPlayerRole[owner] == ROLE_TRAITOR  && g_iPlayerRole[client] == ROLE_TRAITOR)  return Plugin_Continue;

	return Plugin_Handled;
}

// ============================================================================
// ──────────────────────────────────────────────────────────────────────────
//  GLOW SYSTEM — SendProxy per-client filtering
//
//  How it works:
//    Each player entity has m_iGlowType and m_glowColorOverride hooked.
//    When the engine sends an update for player A to client B, our proxy
//    intercepts and decides what B sees for A's glow, based on roles.
//
//  Rules:
//    T  (viewer) → T  (target) : RED  glow   — never self
//    D  (viewer) → D  (target) : BLUE glow   — never self
//    I  (viewer) → anyone      : no glow
//    Bot viewer                : skip (Plugin_Continue = no overhead)
//    Bot target                : normal target — humans see their glow
//
//  Green glow (GLOW_COLOR_GREEN) is reserved for future detective-tase
//  mechanic. The constant is defined but never assigned yet.
// ──────────────────────────────────────────────────────────────────────────
// ============================================================================

/**
 * Glow_HookClient — registers SendProxy hooks for one player entity.
 * Safe to call multiple times; tracks state in g_bGlowHooked[].
 */
void Glow_HookClient(int client)
{
	if (g_bGlowHooked[client])   return;
	if (!IsClientInGame(client)) return;

	bool ok1 = SendProxy_Hook(client, "m_iGlowType",        Prop_Int, Proxy_GlowType);
	bool ok2 = SendProxy_Hook(client, "m_glowColorOverride", Prop_Int, Proxy_GlowColor);

	if (ok1 && ok2)
	{
		g_bGlowHooked[client] = true;
	}
	else
	{
		// Partial failure — roll back to avoid inconsistent state
		if (ok1) SendProxy_Unhook(client, "m_iGlowType",        Proxy_GlowType);
		if (ok2) SendProxy_Unhook(client, "m_glowColorOverride", Proxy_GlowColor);
		LogError("[TTT Glow] SendProxy_Hook failed for slot %d (ok1=%d ok2=%d)", client, ok1, ok2);
	}
}

/**
 * Glow_UnhookClient — removes SendProxy hooks for one player entity.
 * Safe to call even if not hooked.
 */
void Glow_UnhookClient(int client)
{
	if (!g_bGlowHooked[client]) return;

	SendProxy_Unhook(client, "m_iGlowType",        Proxy_GlowType);
	SendProxy_Unhook(client, "m_glowColorOverride", Proxy_GlowColor);
	g_bGlowHooked[client] = false;
}

// ─── Proxy: m_iGlowType ────────────────────────────────────────────────────
//  iEntity = the player whose property is being sent  (TARGET)
//  iClient = the client receiving the network update  (VIEWER)
public Action Proxy_GlowType(const int iEntity, const char[] cPropName,
    int &iValue, const int iElement, const int iClient)
{
	// Guard: viewer must be a valid, connected human
	if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
		return Plugin_Continue;

	// Bot viewers get the unmodified value — no CPU spent on them
	if (IsFakeClient(iClient))
		return Plugin_Continue;

	// Guard: target must be a valid, alive survivor
	if (iEntity < 1 || iEntity > MaxClients
	    || !IsClientInGame(iEntity) || !IsPlayerAlive(iEntity)
	    || GetClientTeam(iEntity) != 2)
	{
		iValue = GLOW_TYPE_OFF;
		return Plugin_Changed;
	}

	// No self-glow
	if (iClient == iEntity)
	{
		iValue = GLOW_TYPE_OFF;
		return Plugin_Changed;
	}

	int viewerRole = g_iPlayerRole[iClient];
	int targetRole = g_iPlayerRole[iEntity];

	if (g_iTaserTarget[iClient] == iEntity && GetEngineTime() < g_fTaserEndTime[iClient])
	{
		iValue = GLOW_TYPE_STEADY;
		return Plugin_Changed;
	}

	if (g_fWallhackEndTime[iClient] > GetEngineTime())
	{
		iValue = GLOW_TYPE_STEADY;
		return Plugin_Changed;
	}

	if ((viewerRole == ROLE_TRAITOR  && targetRole == ROLE_TRAITOR) ||
	    (viewerRole == ROLE_DETECTIVE && targetRole == ROLE_DETECTIVE))
	{
		iValue = GLOW_TYPE_STEADY;
		return Plugin_Changed;
	}

	iValue = GLOW_TYPE_OFF;
	return Plugin_Changed;
}

// ─── Proxy: m_glowColorOverride ────────────────────────────────────────────
public Action Proxy_GlowColor(const int iEntity, const char[] cPropName,
    int &iValue, const int iElement, const int iClient)
{
	// Guard: viewer must be a valid, connected human
	if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
		return Plugin_Continue;

	// Bot viewers: skip
	if (IsFakeClient(iClient))
		return Plugin_Continue;

	// Guard: target must be a valid, alive survivor
	if (iEntity < 1 || iEntity > MaxClients
	    || !IsClientInGame(iEntity) || !IsPlayerAlive(iEntity)
	    || GetClientTeam(iEntity) != 2)
	{
		iValue = 0;
		return Plugin_Changed;
	}

	// No self-glow
	if (iClient == iEntity)
	{
		iValue = 0;
		return Plugin_Changed;
	}

	int viewerRole = g_iPlayerRole[iClient];
	int targetRole = g_iPlayerRole[iEntity];

	if (g_iTaserTarget[iClient] == iEntity && GetEngineTime() < g_fTaserEndTime[iClient])
	{
		if (targetRole == ROLE_TRAITOR) iValue = GLOW_COLOR_RED;
		else if (targetRole == ROLE_DETECTIVE) iValue = GLOW_COLOR_BLUE;
		else iValue = GLOW_COLOR_GREEN;
		return Plugin_Changed;
	}

	if (g_fWallhackEndTime[iClient] > GetEngineTime())
	{
		if (targetRole == ROLE_DETECTIVE) iValue = GLOW_COLOR_BLUE;
		else if (viewerRole == ROLE_TRAITOR && targetRole == ROLE_TRAITOR) iValue = GLOW_COLOR_RED;
		else iValue = GLOW_COLOR_GREEN;
		return Plugin_Changed;
	}

	if (viewerRole == ROLE_TRAITOR && targetRole == ROLE_TRAITOR)
	{
		iValue = GLOW_COLOR_RED;
		return Plugin_Changed;
	}

	if (viewerRole == ROLE_DETECTIVE && targetRole == ROLE_DETECTIVE)
	{
		iValue = GLOW_COLOR_BLUE;
		return Plugin_Changed;
	}

	iValue = 0;
	return Plugin_Changed;
}

// ============================================================================
// SendProxy Callbacks for HUD and GameMode (Names)
// ============================================================================
public Action Proxy_ManagerTeam(const int iEntity, const char[] propname, int &iValue, const int iElement, const int iClient)
{
	if (iClient < 1 || iClient > MaxClients || iElement < 1 || iElement > MaxClients)
		return Plugin_Continue;

	if (!IsClientInGame(iClient) || !IsClientInGame(iElement))
		return Plugin_Continue;

	if (GetClientTeam(iClient) != 2 || GetClientTeam(iElement) != 2)
		return Plugin_Continue;

	if (iClient == iElement)
		return Plugin_Continue;

	// No TAB detection. Always hide teammates from HUD and Scoreboard.
	iValue = 4;
	return Plugin_Changed;
}

public void OnClientCookiesCached(int client)
{
	char buffer[16];
	GetClientCookie(client, g_hCookieCredits, buffer, sizeof(buffer));
	if (buffer[0] != '\0') g_iCredits[client] = StringToInt(buffer);
	else g_iCredits[client] = 0;

	Karma_OnClientCookiesCached(client);
}

void SaveCredits(int client)
{
	if (AreClientCookiesCached(client))
	{
		char buffer[16];
		IntToString(g_iCredits[client], buffer, sizeof(buffer));
		SetClientCookie(client, g_hCookieCredits, buffer);
	}
}

public Action Cmd_SeeCredits(int client, int args)
{
	if (client > 0) TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Cmd_Credits_Balance", g_iCredits[client]);
	return Plugin_Handled;
}

public Action Cmd_GiveCredits(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "%t", "Cmd_GiveCredits_Usage");
		return Plugin_Handled;
	}
	char arg1[32], arg2[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int amount = StringToInt(arg2);

	int target = FindTarget(client, arg1, false, false);
	if (target > 0)
	{
		g_iCredits[target] += amount;
		SaveCredits(target);
		ReplyToCommand(client, "%t", "Cmd_GiveCredits_Done", amount, target);
	}
	return Plugin_Handled;
}

// ============================================================================
// Missile System Logic
// ============================================================================
public Action Timer_MatchMissile(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	int owner = -1;
	if (entity > 0 && IsValidEntity(entity))
	{
		if (HasEntProp(entity, Prop_Send, "m_hOwnerEntity")) owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if (owner <= 0 && HasEntProp(entity, Prop_Send, "m_hThrower")) owner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	}
	
	int bestClient = -1;
	if (owner > 0 && owner <= MaxClients && IsClientInGame(owner))
	{
		bestClient = owner;
	}
	else
	{
		float bestTimeDiff = 999.0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && g_fLastPipeThrowTime[i] > 0.0)
			{
				float diff = GetEngineTime() - g_fLastPipeThrowTime[i];
				if (diff >= 0.0 && diff < 0.5 && diff < bestTimeDiff)
				{
					if (entity > 0)
					{
						float pPos[3], ePos[3];
						GetClientAbsOrigin(i, pPos);
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", ePos);
						if (GetVectorDistance(pPos, ePos) < 200.0)
						{
							bestClient = i;
							bestTimeDiff = diff;
						}
					}
					else
					{
						bestClient = i;
						bestTimeDiff = diff;
					}
				}
			}
		}
	}
	
	if (bestClient > 0)
	{
		if (g_fLastPipeThrowTime[bestClient] > 0.0)
		{
			g_fLastPipeThrowTime[bestClient] = 0.0;
			SpawnMissile(bestClient, entity);
		}
	}
	return Plugin_Stop;
}

void SpawnMissile(int client, int projectile)
{
	float pos[3], ang[3];
	if (projectile > 0 && IsValidEntity(projectile))
	{
		GetEntPropVector(projectile, Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(projectile, Prop_Send, "m_angRotation", ang);
		AcceptEntityInput(projectile, "Kill");
	}
	else
	{
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, ang);
		float fwd[3];
		GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
		pos[0] += fwd[0] * 50.0;
		pos[1] += fwd[1] * 50.0;
		pos[2] += fwd[2] * 50.0;
	}
	
	int missile = CreateEntityByName("prop_dynamic_override");
	if (missile != -1)
	{
		DispatchKeyValue(missile, "targetname", "ttt_missile");
		DispatchKeyValue(missile, "model", "models/props_equipment/oxygentank01.mdl");
		DispatchKeyValue(missile, "solid", "0");
		DispatchKeyValueVector(missile, "origin", pos);
		DispatchKeyValueVector(missile, "angles", ang);
		DispatchSpawn(missile);
		SetEntityMoveType(missile, MOVETYPE_NOCLIP);
		
		SDKHook(missile, SDKHook_SetTransmit, Proxy_MissileTransmit);
		
		int viewctrl = CreateEntityByName("point_viewcontrol");
		if (viewctrl != -1)
		{
			DispatchKeyValueVector(viewctrl, "origin", pos);
			DispatchKeyValueVector(viewctrl, "angles", ang);
			DispatchSpawn(viewctrl);
			
			AcceptEntityInput(viewctrl, "Enable", client, client);
			SetClientViewEntity(client, viewctrl);
		}
		
		g_iActiveMissile[client] = EntIndexToEntRef(missile);
		
		DataPack pack;
		CreateDataTimer(0.05, Timer_MissileThink, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(EntIndexToEntRef(missile));
		pack.WriteCell(EntIndexToEntRef(viewctrl));
	}
}

public Action Proxy_MissileTransmit(int entity, int client)
{
	if (client > 0 && client <= MaxClients && g_iActiveMissile[client] != 0)
	{
		if (EntRefToEntIndex(g_iActiveMissile[client]) == entity)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Timer_MissileThink(Handle timer, DataPack pack)
{
	pack.Reset();
	int userid = pack.ReadCell();
	int refMissile = pack.ReadCell();
	int refCam = pack.ReadCell();
	
	int client = GetClientOfUserId(userid);
	int missile = EntRefToEntIndex(refMissile);
	int cam = EntRefToEntIndex(refCam);
	
	if (missile <= 0 || !IsValidEntity(missile)) return Plugin_Stop;
	
	float ePos[3], eAng[3];
	GetEntPropVector(missile, Prop_Send, "m_vecOrigin", ePos);
	
	if (cam > 0 && IsValidEntity(cam))
	{
		GetEntPropVector(cam, Prop_Send, "m_angRotation", eAng);
	}
	else
	{
		GetEntPropVector(missile, Prop_Send, "m_angRotation", eAng);
		eAng[0] -= 90.0;
	}
	
	if (client > 0 && g_iActiveMissile[client] == refMissile && IsClientInGame(client) && IsPlayerAlive(client))
	{
		GetClientEyeAngles(client, eAng);
	}
	else
	{
		if (client > 0 && IsClientInGame(client))
		{
			if (cam > 0 && IsValidEntity(cam)) AcceptEntityInput(cam, "Disable", client, client);
			SetClientViewEntity(client, client);
		}
		if (cam > 0 && IsValidEntity(cam)) AcceptEntityInput(cam, "Kill");
		cam = -1;
		
		if (client > 0 && g_iActiveMissile[client] == refMissile) g_iActiveMissile[client] = 0;
	}
	
	float fwd[3], nextPos[3];
	GetAngleVectors(eAng, fwd, NULL_VECTOR, NULL_VECTOR);
	
	float speed = 600.0;
	float tickRate = 0.05;
	nextPos[0] = ePos[0] + fwd[0] * speed * tickRate;
	nextPos[1] = ePos[1] + fwd[1] * speed * tickRate;
	nextPos[2] = ePos[2] + fwd[2] * speed * tickRate;
	
	Handle trace = TR_TraceHullFilterEx(ePos, nextPos, view_as<float>({-8.0, -8.0, -8.0}), view_as<float>({8.0, 8.0, 8.0}), MASK_SOLID, TraceFilter_IgnoreMissile, missile);
	if (TR_DidHit(trace))
	{
		CloseHandle(trace);
		ExplodeMissile(client, refMissile, refCam);
		return Plugin_Stop;
	}
	CloseHandle(trace);
	
	if (cam > 0 && IsValidEntity(cam))
	{
		TeleportEntity(cam, nextPos, eAng, NULL_VECTOR);
	}
	
	float mAng[3];
	mAng[0] = eAng[0] + 90.0;
	mAng[1] = eAng[1];
	mAng[2] = eAng[2];
	TeleportEntity(missile, nextPos, mAng, NULL_VECTOR);
	
	return Plugin_Continue;
}

void ExplodeMissile(int client, int refMissile, int refCam)
{
	int missile = EntRefToEntIndex(refMissile);
	float pos[3];
	bool gotPos = false;
	
	if (missile > 0 && IsValidEntity(missile))
	{
		GetEntPropVector(missile, Prop_Send, "m_vecOrigin", pos);
		AcceptEntityInput(missile, "Kill");
		gotPos = true;
	}
	
	int cam = EntRefToEntIndex(refCam);
	if (cam > 0 && IsValidEntity(cam))
	{
		if (client > 0 && IsClientInGame(client)) AcceptEntityInput(cam, "Disable", client, client);
		AcceptEntityInput(cam, "Kill");
	}
	
	if (client > 0 && g_iActiveMissile[client] == refMissile)
	{
		g_iActiveMissile[client] = 0;
		if (IsClientInGame(client)) SetClientViewEntity(client, client);
	}
	
	if (gotPos)
	{
		int env_exp = CreateEntityByName("env_explosion");
		if (env_exp != -1)
		{
			DispatchKeyValue(env_exp, "iMagnitude", "1000");
			DispatchKeyValue(env_exp, "iRadiusOverride", "200");
			DispatchKeyValue(env_exp, "rendermode", "5");
			DispatchKeyValueVector(env_exp, "origin", pos);
			
			if (client > 0 && IsClientInGame(client))
			{
				SetEntPropEnt(env_exp, Prop_Data, "m_hOwnerEntity", client);
			}
			
			DispatchSpawn(env_exp);
			AcceptEntityInput(env_exp, "Explode");
		}
	}
}

public bool TraceFilter_IgnoreMissile(int entity, int contentsMask, any data)
{
	if (entity == data) return false;
	return true;
}

public void OnEntityDestroyed(int entity)
{
	if (entity > 0 && entity <= 2048)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (g_bBoughtC4[i] && g_iC4PackEnt[i] != 0 && EntRefToEntIndex(g_iC4PackEnt[i]) == entity)
			{
				g_iC4PackEnt[i] = 0;
				CreateTimer(0.1, Timer_CleanIncendiary, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
				break;
			}
		}
	}
}

public Action Timer_CleanIncendiary(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client)) return Plugin_Stop;
	
	float cPos[3];
	GetClientAbsOrigin(client, cPos);
	
	int ent = -1;
	float closestDist = 9999.0;
	int targetIncendiary = -1;
	
	while ((ent = FindEntityByClassname(ent, "upgrade_ammo_incendiary")) != -1)
	{
		float ePos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", ePos);
		float dist = GetVectorDistance(cPos, ePos);
		if (dist < 100.0 && dist < closestDist)
		{
			closestDist = dist;
			targetIncendiary = ent;
		}
	}
	
	if (targetIncendiary != -1)
	{
		// Block pickup via E key (fixes incendiary ammo exploit)
		SDKHook(targetIncendiary, SDKHook_Use, OnC4Use);
		
		// Rename it so round cleanup can find it
		DispatchKeyValue(targetIncendiary, "targetname", "ttt_c4");
		
		g_iC4Entity[client] = EntIndexToEntRef(targetIncendiary);
		g_iC4CorrectWire[client] = GetRandomInt(1, 5);
		g_iC4WrongAttempts[client] = 0;
		g_fC4ExplodeTime[client] = GetEngineTime() + 40.0;
		
		for (int j = 1; j <= 5; j++) g_bC4WireCut[client][j] = false;
		for (int j = 1; j <= MaxClients; j++) 
		{
			g_bC4DefuserUsed[client][j] = false;
			g_iC4DefuserFakeWire[client][j] = 0;
		}
		
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "C4_Planted");
		C4_ScheduleNextThink(userid, EntIndexToEntRef(targetIncendiary), 0.0);
	}
	
	return Plugin_Stop;
}

public Action OnC4Use(int entity, int activator, int caller, UseType type, float value)
{
	char targetName[64];
	GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
	if (StrEqual(targetName, "ttt_c4"))
	{
		if (activator > 0 && activator <= MaxClients && IsClientInGame(activator) && IsPlayerAlive(activator))
		{
			if (g_iPlayerRole[activator] == ROLE_INNOCENT || g_iPlayerRole[activator] == ROLE_DETECTIVE)
			{
				int owner = 0;
				for (int i = 1; i <= MaxClients; i++)
				{
					if (g_iC4Entity[i] != 0 && EntRefToEntIndex(g_iC4Entity[i]) == entity)
					{
						owner = i;
						break;
					}
				}
				
				if (owner > 0 && g_fC4ExplodeTime[owner] > GetEngineTime())
				{
					g_iMenuC4Owner[activator] = owner;
					ShowC4DefuseMenu(activator);
					if (g_hC4DefuseTimer[activator] != null) KillTimer(g_hC4DefuseTimer[activator]);
					g_hC4DefuseTimer[activator] = CreateTimer(1.0, Timer_UpdateDefuseMenu, GetClientUserId(activator), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		return Plugin_Handled;
	}
	
	// Block pickup during the 0.1s conversion window
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bBoughtC4[i] && g_iC4Entity[i] == 0 && IsClientInGame(i) && IsPlayerAlive(i))
		{
			float ePos[3], cPos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", ePos);
			GetClientAbsOrigin(i, cPos);
			if (GetVectorDistance(ePos, cPos) < 150.0)
			{
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

void C4_ScheduleNextThink(int userid, int refC4, float lastBeep)
{
	DataPack dp;
	CreateDataTimer(0.1, Timer_C4Think, dp, TIMER_FLAG_NO_MAPCHANGE);
	dp.WriteCell(userid);
	dp.WriteCell(refC4);
	dp.WriteFloat(lastBeep);
}

public Action Timer_C4Think(Handle timer, DataPack pack)
{
	pack.Reset();
	int userid = pack.ReadCell();
	int refC4 = pack.ReadCell();
	float lastBeep = pack.ReadFloat();
	
	int client = GetClientOfUserId(userid);
	int c4 = EntRefToEntIndex(refC4);
	
	// Stop if entity was destroyed (round cleanup) or round ended
	if (c4 <= 0 || !IsValidEntity(c4) || !g_bRoundLive)
	{
		if (c4 > 0 && IsValidEntity(c4)) AcceptEntityInput(c4, "Kill");
		if (client > 0 && g_iC4Entity[client] == refC4)
		{
			g_bBoughtC4[client] = false;
			g_iC4Entity[client] = 0;
		}
		return Plugin_Stop;
	}
	
	float now = GetEngineTime();
	float timeLeft = g_fC4ExplodeTime[client] - now;
	
	if (timeLeft <= 0.0)
	{
		float pos[3];
		GetEntPropVector(c4, Prop_Send, "m_vecOrigin", pos);
		AcceptEntityInput(c4, "Kill");
		
		if (client > 0 && g_iC4Entity[client] == refC4)
		{
			g_bBoughtC4[client] = false;
			g_iC4Entity[client] = 0;
		}
		
		int env_exp = CreateEntityByName("env_explosion");
		if (env_exp != -1)
		{
			DispatchKeyValue(env_exp, "iMagnitude", "1000");
			DispatchKeyValue(env_exp, "iRadiusOverride", "800");
			DispatchKeyValue(env_exp, "rendermode", "5");
			DispatchKeyValueVector(env_exp, "origin", pos);
			
			if (client > 0 && IsClientInGame(client))
			{
				SetEntPropEnt(env_exp, Prop_Data, "m_hOwnerEntity", client);
			}
			
			DispatchSpawn(env_exp);
			AcceptEntityInput(env_exp, "Explode");
		}
		
		return Plugin_Stop;
	}
	
	float beepInterval = (timeLeft > 10.0) ? 2.0 : 0.3;
	if (now - lastBeep >= beepInterval)
	{
		EmitSoundToAll("buttons/blip1.wav", c4, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		lastBeep = now;
	}
	
	C4_ScheduleNextThink(userid, refC4, lastBeep);
	return Plugin_Stop;
}

public Action Timer_UpdateDefuseMenu(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || g_iMenuC4Owner[client] == 0)
	{
		if (client > 0 && g_hC4DefuseTimer[client] != null) g_hC4DefuseTimer[client] = null;
		return Plugin_Stop;
	}
	
	int owner = g_iMenuC4Owner[client];
	int c4 = EntRefToEntIndex(g_iC4Entity[owner]);
	if (c4 <= 0 || !IsValidEntity(c4) || g_fC4ExplodeTime[owner] <= GetEngineTime())
	{
		CancelClientMenu(client);
		g_iMenuC4Owner[client] = 0;
		g_hC4DefuseTimer[client] = null;
		return Plugin_Stop;
	}
	
	ShowC4DefuseMenu(client);
	return Plugin_Continue;
}

void ShowC4DefuseMenu(int client)
{
	int owner = g_iMenuC4Owner[client];
	if (owner <= 0) return;
	
	float timeLeft = g_fC4ExplodeTime[owner] - GetEngineTime();
	if (timeLeft < 0.0) timeLeft = 0.0;
	
	Menu menu = new Menu(MenuHandler_C4Defuse);
	char title[128];
	Format(title, sizeof(title), "%T", "C4_Defuse_Title", client, timeLeft);
	menu.SetTitle(title);
	
	bool useDefuser = (g_bHasDefuser[client] && !g_bC4DefuserUsed[owner][client]);
	int correctWire = g_iC4CorrectWire[owner];
	
	if (useDefuser && g_iC4DefuserFakeWire[owner][client] == 0)
	{
		int uncutWrongs[5];
		int numUncut = 0;
		for (int i = 1; i <= 5; i++)
		{
			if (i != correctWire && !g_bC4WireCut[owner][i])
			{
				uncutWrongs[numUncut++] = i;
			}
		}
		if (numUncut > 0) g_iC4DefuserFakeWire[owner][client] = uncutWrongs[GetRandomInt(0, numUncut - 1)];
		else g_iC4DefuserFakeWire[owner][client] = -1;
	}
	
	int fakeWire = g_iC4DefuserFakeWire[owner][client];
	char wireKeys[6][] = {"", "C4_Wire_Red", "C4_Wire_Green", "C4_Wire_Blue", "C4_Wire_Yellow", "C4_Wire_White"};
	
	for (int i = 1; i <= 5; i++)
	{
		if (g_bC4WireCut[owner][i]) continue;
		if (useDefuser && i != correctWire && i != fakeWire) continue;
		
		char num[8], name[32], wireColor[32];
		IntToString(i, num, sizeof(num));
		Format(wireColor, sizeof(wireColor), "%T", wireKeys[i], client);
		Format(name, sizeof(name), "%T", "C4_Wire_Format", client, wireColor);
		menu.AddItem(num, name);
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_C4Defuse(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client = param1;
		int owner = g_iMenuC4Owner[client];
		
		if (owner <= 0 || g_iC4Entity[owner] == 0) return 0;
		
		int c4 = EntRefToEntIndex(g_iC4Entity[owner]);
		if (c4 <= 0 || !IsValidEntity(c4)) return 0;
		
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		int selectedWire = StringToInt(info);
		
		g_bC4WireCut[owner][selectedWire] = true;
		
		CancelClientMenu(client);
		g_iMenuC4Owner[client] = 0;
		if (g_hC4DefuseTimer[client] != null) { KillTimer(g_hC4DefuseTimer[client]); g_hC4DefuseTimer[client] = null; }
		
		if (selectedWire == g_iC4CorrectWire[owner])
		{
			AcceptEntityInput(c4, "Kill");
			g_iC4Entity[owner] = 0;
			g_bBoughtC4[owner] = false;
			TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "C4_Defuse_Success");
			LogActionCredits(client, "Karma_Log_C4Defused", cv_ttt_credits_defuse_c4.IntValue);
			if (IsClientInGame(owner))
			{
				TTT_PrintToChat(owner, "\x05[TTT]\x01 %t", "C4_Defuse_Owner");
			}
		}
		else
		{
			bool usedDefuser = (g_bHasDefuser[client] && !g_bC4DefuserUsed[owner][client]);
			
			if (usedDefuser)
			{
				g_bC4DefuserUsed[owner][client] = true;
				g_fC4ExplodeTime[owner] = GetEngineTime() + 3.0;
				TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "C4_Defuse_Fail_Defuser");
			}
			else
			{
				g_iC4WrongAttempts[owner]++;
				if (g_iC4WrongAttempts[owner] == 1)
				{
					float timeLeft = g_fC4ExplodeTime[owner] - GetEngineTime();
					g_fC4ExplodeTime[owner] = GetEngineTime() + (timeLeft / 2.0);
					TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "C4_Defuse_Fail_Time");
				}
				else
				{
					g_fC4ExplodeTime[owner] = GetEngineTime();
					TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "C4_Defuse_Fail_Explode");
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		int client = param1;
		if (param2 == MenuCancel_Exit || param2 == MenuCancel_Disconnected || param2 == MenuCancel_Timeout)
		{
			g_iMenuC4Owner[client] = 0;
			if (g_hC4DefuseTimer[client] != null) { KillTimer(g_hC4DefuseTimer[client]); g_hC4DefuseTimer[client] = null; }
		}
	}
	return 0;
}

// ============================================================================
// Immortality Logic
// ============================================================================
public Action Cmd_GiveImmortality(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "%t", "Cmd_GiveImmortality_Usage");
		return Plugin_Handled;
	}

	char targetName[32];
	GetCmdArg(1, targetName, sizeof(targetName));

	int target = FindTarget(client, targetName, false, true);
	if (target <= 0) return Plugin_Handled;

	GiveImmortality(target);
	ReplyToCommand(client, "%t", "Give_Immortality_Done", target);

	return Plugin_Handled;
}

void GiveImmortality(int client)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		float duration = cv_ttt_shop_immortality_duration.FloatValue;
		g_fImmortalityEndTime[client] = GetEngineTime() + duration;
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 0, 255);
		CreateTimer(duration, Timer_RemoveImmortality, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_RemoveImmortality(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client))
	{
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		if (IsPlayerAlive(client))
		{
			TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Immortality_Expired");
		}
	}
	return Plugin_Stop;
}

void InvokeHorde()
{
	g_bHordeActive = true;
	SetConVarInt(FindConVar("z_common_limit"), 30);
	
	L4D2Direct_SetPendingMobCount(30);
	
	CreateTimer(45.0, Timer_EndHorde, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_EndHorde(Handle timer)
{
	g_bHordeActive = false;
	SetConVarInt(FindConVar("z_common_limit"), 0);
	
	// Kill remaining zombies
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "infected")) != -1)
	{
		AcceptEntityInput(ent, "KillHierarchy");
	}
	return Plugin_Stop;
}

bool TraceFilter_NoPlayers(int entity, int contentsMask, any data)
{
	return entity > MaxClients || entity == 0;
}

void SpawnSpecialAtCrosshair(int client)
{
	int classes[] = {1, 3, 5, 6};
	char classNames[][] = {"Smoker", "Hunter", "Jockey", "Charger"};
	int idx = GetRandomInt(0, 3);
	int zombieClass = classes[idx];
	
	float eyePos[3], eyeAng[3], endPos[3];
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);
	
	Handle trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SOLID, RayType_Infinite, TraceFilter_NoPlayers, client);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(endPos, trace);
		endPos[2] += 20.0;
	}
	else
	{
		GetClientAbsOrigin(client, endPos);
		endPos[2] += 50.0;
	}
	delete trace;
	
	g_bTraitorSpawning = true;
	int spawned = L4D2_SpawnSpecial(zombieClass, endPos, eyeAng);
	g_bTraitorSpawning = false;
	
	if (spawned > 0 && spawned <= MaxClients)
	{
		g_iZombieOwner[spawned] = client;
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Spawn_Special", classNames[idx]);
	}
	else
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Spawn_Special_Fail");
		g_fSpecialCooldownEndTime = 0.0;
	}
}

public void OnWeaponEquipPost(int client, int weapon)
{
	if (!IsValidEntity(weapon)) return;
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) return;
	RequestFrame(CheckPrimaryWeaponChange, GetClientUserId(client));
	
	char targetname[32];
	if (HasEntProp(weapon, Prop_Data, "m_iName"))
	{
		GetEntPropString(weapon, Prop_Data, "m_iName", targetname, sizeof(targetname));
		if (StrEqual(targetname, "ttt_lootbox_c4"))
		{
			g_bBoughtC4[client] = true;
			g_iC4PackEnt[client] = EntIndexToEntRef(weapon);
			TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Lootbox_Pickup_C4");
		}
		else if (StrEqual(targetname, "ttt_lootbox_missile"))
		{
			g_bBoughtMissile[client] = true;
			TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Lootbox_Pickup_Missile");
		}
	}
}

void CheckPrimaryWeaponChange(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client)) return;
	
	int weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon == -1 || !IsValidEntity(weapon)) return;
	
	if (weapon != g_iCurrentPrimaryWeapon[client])
	{
		int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
		if (ammotype != -1)
		{
			SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, ammotype);
		}
		g_iCurrentPrimaryWeapon[client] = weapon;
	}
}

bool GiveFullAmmo(int client)
{
	int weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon == -1 || !IsValidEntity(weapon))
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Ammo_Need_Primary");
		return false;
	}
	
	char cls[64];
	GetEntityClassname(weapon, cls, sizeof(cls));
	if (StrContains(cls, "grenade_launcher") != -1)
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Ammo_No_GL");
		return false;
	}
	
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype == -1) 
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Ammo_No_Reserve");
		return false;
	}
	
	int currentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
	int maxAmmo = GetWeaponMaxAmmo(cls);
	
	if (currentAmmo >= maxAmmo)
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Ammo_Full");
		return false;
	}
	
	SetEntProp(client, Prop_Send, "m_iAmmo", maxAmmo, _, ammotype);
	
	TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Ammo_Restocked");
	return true;
}

int GetWeaponMaxAmmo(const char[] cls)
{
	if (StrContains(cls, "rifle_m60") != -1) return 150;
	if (StrContains(cls, "smg") != -1) return 650;
	if (StrContains(cls, "rifle") != -1) return 360;
	if (StrContains(cls, "autoshotgun") != -1 || StrContains(cls, "shotgun_spas") != -1) return 90;
	if (StrContains(cls, "shotgun") != -1) return 56;
	if (StrContains(cls, "hunting_rifle") != -1) return 150;
	if (StrContains(cls, "sniper") != -1) return 180;
	return 360;
}

bool SpawnTankAtCrosshair(int client)
{
	float eyePos[3], eyeAng[3], endPos[3];
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);
	
	Handle trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SOLID, RayType_Infinite, TraceFilter_NoPlayers, client);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(endPos, trace);
	}
	delete trace;
	
	g_bTraitorSpawning = true;
	int spawned = L4D2_SpawnTank(endPos, eyeAng);
	g_bTraitorSpawning = false;
	
	if (spawned > 0 && spawned <= MaxClients)
	{
		g_iZombieOwner[spawned] = client;
		SetEntProp(spawned, Prop_Send, "m_iHealth", 2500, 1);
		SetEntProp(spawned, Prop_Send, "m_iMaxHealth", 2500, 1);
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Spawn_Tank");
		return true;
	}
	else
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Spawn_Tank_Fail");
		return false;
	}
}

// ============================================================================
// Lootbox System
// ============================================================================
void SpawnLootboxAtPosition(float pos[3])
{
	int box = CreateEntityByName("prop_physics_override");
	if (box != -1)
	{
		DispatchKeyValue(box, "model", "models/props_junk/wood_crate001a.mdl");
		DispatchKeyValue(box, "targetname", "ttt_lootbox");
		DispatchSpawn(box);
		TeleportEntity(box, pos, NULL_VECTOR, NULL_VECTOR);
		
		SetEntProp(box, Prop_Send, "m_nGlowRange", 1500);
		SetEntProp(box, Prop_Send, "m_iGlowType", 3);
		SetEntProp(box, Prop_Send, "m_glowColorOverride", 255 + (215 * 256) + (0 * 65536));
		
		SDKHook(box, SDKHook_StartTouch, OnLootboxTouch);
	}
}

public Action OnLootboxTouch(int entity, int other)
{
	if (other < 1 || other > MaxClients || !IsClientInGame(other)) return Plugin_Continue;
	if (!IsPlayerAlive(other) || GetClientTeam(other) != 2) return Plugin_Continue;
	if (g_bRoundEnded || g_bTruceActive) return Plugin_Continue;
	if (!IsValidEntity(entity)) return Plugin_Continue;
	
	float boxPos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", boxPos);
	
	AcceptEntityInput(entity, "Kill");
	
	int item = GetRandomInt(0, 22);
	GiveLootboxItem(other, item, boxPos);
	return Plugin_Handled;
}

void GiveLootboxItem(int client, int item, float boxPos[3])
{
	char itemKeys[][] = {
		"Lootbox_Item_Kevlar", "Lootbox_Item_Ammo", "Lootbox_Item_Bat", "Lootbox_Item_KevlarHelmet",
		"Lootbox_Item_Defuser", "Lootbox_Item_Horde", "Lootbox_Item_Deagle", "Lootbox_Item_Identifier",
		"Lootbox_Item_Pills", "Lootbox_Item_Wallhack", "Lootbox_Item_Taser", "Lootbox_Item_TraitorNext",
		"Lootbox_Item_GL", "Lootbox_Item_C4", "Lootbox_Item_DetNow", "Lootbox_Item_Missile",
		"Lootbox_Item_Special", "Lootbox_Item_TraitorNow", "Lootbox_Item_Tank", "Lootbox_Item_Immortality",
		"Lootbox_Item_Piano", "Lootbox_Item_Randomizer", "Lootbox_Item_Witch"
	};
	char itemNames[32];
	Format(itemNames, sizeof(itemNames), "%T", itemKeys[item], client);
	int itemCosts[] = { 1, 1, 2, 2, 2, 2, 3, 3, 4, 5, 5, 5, 6, 7, 8, 8, 8, 10, 14, 15, 0, 0, 0 };
	
	TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Lootbox_Given", itemNames);
	
	switch (item)
	{
		case 0:
		{
			if (g_bHasKevlar[client])
			{
				g_iCredits[client] += itemCosts[item]; SaveCredits(client);
				TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Item_Duplicate_Refund", itemCosts[item]);
			}
			else { g_bHasKevlar[client] = true; }
		}
		case 1:
		{
			if (!GiveFullAmmo(client))
			{
				g_iCredits[client] += itemCosts[item]; SaveCredits(client);
				TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Item_Duplicate_Refund", itemCosts[item]);
			}
		}
		case 2:
		{
			int wep = CreateEntityByName("weapon_melee");
			if (wep != -1) { DispatchKeyValue(wep, "melee_script_name", "baseball_bat"); DispatchSpawn(wep); TeleportEntity(wep, boxPos, NULL_VECTOR, NULL_VECTOR); }
		}
		case 3:
		{
			if (g_bHasKevlar[client] && g_bHasHelmet[client])
			{
				g_iCredits[client] += itemCosts[item]; SaveCredits(client);
				TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Item_Duplicate_Refund", itemCosts[item]);
			}
			else { g_bHasKevlar[client] = true; g_bHasHelmet[client] = true; }
		}
		case 4:
		{
			if (g_bHasDefuser[client])
			{
				g_iCredits[client] += itemCosts[item]; SaveCredits(client);
				TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Item_Duplicate_Refund", itemCosts[item]);
			}
			else { g_bHasDefuser[client] = true; }
		}
		case 5:
		{
			InvokeHorde();
		}
		case 6:
		{
			int wep = CreateEntityByName("weapon_pistol_magnum");
			if (wep != -1) { DispatchSpawn(wep); TeleportEntity(wep, boxPos, NULL_VECTOR, NULL_VECTOR); }
		}
		case 7:
		{
			if (g_iCorpseIdentifiers[client] > 0)
			{
				g_iCredits[client] += itemCosts[item]; SaveCredits(client);
				TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Item_Duplicate_Refund", itemCosts[item]);
			}
			else { g_iCorpseIdentifiers[client] = 1; }
		}
		case 8:
		{
			int wep = CreateEntityByName("weapon_pain_pills");
			if (wep != -1) { DispatchSpawn(wep); TeleportEntity(wep, boxPos, NULL_VECTOR, NULL_VECTOR); }
		}
		case 9:
		{
			if (g_fWallhackEndTime[client] > GetEngineTime())
			{
				g_iCredits[client] += itemCosts[item]; SaveCredits(client);
				TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Item_Duplicate_Refund", itemCosts[item]);
			}
			else { GiveWallhackToClient(client); }
		}
		case 10:
		{
			int wep = CreateEntityByName("weapon_melee");
			if (wep != -1) { DispatchKeyValue(wep, "melee_script_name", "tonfa"); DispatchSpawn(wep); TeleportEntity(wep, boxPos, NULL_VECTOR, NULL_VECTOR); }
		}
		case 11:
		{
			if (g_bNextRoundTraitor[client])
			{
				g_iCredits[client] += itemCosts[item]; SaveCredits(client);
				TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Item_Duplicate_Refund", itemCosts[item]);
			}
			else { g_bNextRoundTraitor[client] = true; }
		}
		case 12:
		{
			int wep = CreateEntityByName("weapon_grenade_launcher");
			if (wep != -1)
			{
				DispatchSpawn(wep);
				SetEntProp(wep, Prop_Send, "m_iClip1", 1);
				TeleportEntity(wep, boxPos, NULL_VECTOR, NULL_VECTOR);
			}
		}
		case 13:
		{
			int wep = CreateEntityByName("weapon_upgradepack_incendiary");
			if (wep != -1)
			{
				DispatchSpawn(wep);
				DispatchKeyValue(wep, "targetname", "ttt_lootbox_c4");
				TeleportEntity(wep, boxPos, NULL_VECTOR, NULL_VECTOR);
			}
		}
		case 14:
		{
			if (g_iPlayerRole[client] == ROLE_DETECTIVE)
			{
				g_iCredits[client] += itemCosts[item]; SaveCredits(client);
				TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Item_Duplicate_Refund", itemCosts[item]);
			}
			else
			{
				if (g_iSpriteEntity[client] > 0 && IsValidEntity(g_iSpriteEntity[client])) { AcceptEntityInput(g_iSpriteEntity[client], "Kill"); g_iSpriteEntity[client] = 0; }
				g_iPlayerRole[client] = ROLE_DETECTIVE;
				CreateRoleSprite(client, ROLE_DETECTIVE);
				ScheduleModelChange(client, g_sModelPaths[4], 4);
				SetScreenOverlay(client, "sprites/Hud/Dhud");
			}
		}
		case 15:
		{
			int wep = CreateEntityByName("weapon_pipe_bomb");
			if (wep != -1)
			{
				DispatchSpawn(wep);
				DispatchKeyValue(wep, "targetname", "ttt_lootbox_missile");
				TeleportEntity(wep, boxPos, NULL_VECTOR, NULL_VECTOR);
			}
		}
		case 16:
		{
			int classes[] = {1, 3, 5, 6};
			int idx = GetRandomInt(0, 3);
			g_bTraitorSpawning = true;
			L4D2_SpawnSpecial(classes[idx], boxPos, view_as<float>({0.0, 0.0, 0.0}));
			g_bTraitorSpawning = false;
		}
		case 17:
		{
			if (g_iPlayerRole[client] == ROLE_TRAITOR)
			{
				g_iCredits[client] += itemCosts[item]; SaveCredits(client);
				TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Item_Duplicate_Refund", itemCosts[item]);
			}
			else
			{
				if (g_iSpriteEntity[client] > 0 && IsValidEntity(g_iSpriteEntity[client])) { AcceptEntityInput(g_iSpriteEntity[client], "Kill"); g_iSpriteEntity[client] = 0; }
				g_iPlayerRole[client] = ROLE_TRAITOR;
				CreateRoleSprite(client, ROLE_TRAITOR);
				ScheduleModelChange(client, g_sModelPaths[6], 6);
				SetScreenOverlay(client, "sprites/Hud/Thud");
			}
		}
		case 18:
		{
			g_bTraitorSpawning = true;
			int spawned = L4D2_SpawnTank(boxPos, view_as<float>({0.0, 0.0, 0.0}));
			g_bTraitorSpawning = false;
			if (spawned > 0 && spawned <= MaxClients)
			{
				SetEntProp(spawned, Prop_Send, "m_iHealth", 2500, 1);
				SetEntProp(spawned, Prop_Send, "m_iMaxHealth", 2500, 1);
			}
		}
		case 19:
		{
			if (g_fImmortalityEndTime[client] > GetEngineTime())
			{
				g_iCredits[client] += itemCosts[item]; SaveCredits(client);
				TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Item_Duplicate_Refund", itemCosts[item]);
			}
			else { GiveImmortality(client); }
		}
		case 20:
		{
			CreateTimer(1.0, Timer_SpawnPiano, GetClientUserId(client));
		}
		case 21:
		{
			StartRandomizer();
		}
		case 22:
		{
			float ang[3] = {0.0, 0.0, 0.0};
			g_bWitchSpawning = true;
			L4D2_SpawnWitch(boxPos, ang);
			g_bWitchSpawning = false;
		}
	}
}

void CleanupZombiesAndBots()
{
	g_bHordeActive = false;
	SetConVarInt(FindConVar("z_common_limit"), 0);
	L4D2Direct_SetPendingMobCount(0);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
		{
			KickClient(i, "Round cleanup");
		}
	}
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "infected")) != -1) AcceptEntityInput(ent, "KillHierarchy");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "witch")) != -1) AcceptEntityInput(ent, "KillHierarchy");
	
	int maxEnts = GetMaxEntities();
	char classname[64];
	char model[128];
	for (int e = MaxClients + 1; e <= maxEnts; e++)
	{
		if (IsValidEntity(e))
		{
			GetEntityClassname(e, classname, sizeof(classname));
			if (strncmp(classname, "prop_physics", 12, false) == 0)
			{
				GetEntPropString(e, Prop_Data, "m_ModelName", model, sizeof(model));
				if (StrContains(model, "wood_crate001a", false) != -1)
				{
					if (GetEntProp(e, Prop_Send, "m_iGlowType") == 3)
					{
						AcceptEntityInput(e, "Kill");
					}
				}
				else if (StrContains(model, "piano", false) != -1)
				{
					AcceptEntityInput(e, "Kill");
				}
			}
		}
}
}

public Action Timer_SpawnPiano(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		float pos[3];
		GetClientAbsOrigin(client, pos);
		pos[2] += 400.0;
		
		int piano = CreateEntityByName("prop_physics_override");
		if (piano != -1)
		{
			DispatchKeyValue(piano, "model", "models/props_furniture/piano.mdl"); 
			DispatchKeyValue(piano, "targetname", "ttt_piano");
			DispatchSpawn(piano);
			
			TeleportEntity(piano, pos, NULL_VECTOR, NULL_VECTOR);
			
			int ref = EntIndexToEntRef(piano);
			
			DataPack pack;
			CreateDataTimer(0.1, Timer_PianoProximity, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(ref);
			pack.WriteFloat(GetEngineTime() + 2.0);
			
			CreateTimer(7.0, Timer_KillPiano, ref);
		}
	}
	return Plugin_Handled;
}

public Action Timer_PianoProximity(Handle timer, DataPack pack)
{
	pack.Reset();
	int ref = pack.ReadCell();
	float endTime = pack.ReadFloat();
	
	int piano = EntRefToEntIndex(ref);
	if (piano == INVALID_ENT_REFERENCE || !IsValidEntity(piano))
		return Plugin_Stop;
	
	if (GetEngineTime() > endTime)
		return Plugin_Stop;
	
	float pianoPos[3];
	GetEntPropVector(piano, Prop_Send, "m_vecOrigin", pianoPos);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2) continue;
		
		float playerPos[3];
		GetClientAbsOrigin(i, playerPos);
		
		float dist = GetVectorDistance(pianoPos, playerPos);
		if (dist < 100.0)
		{
			ForcePlayerSuicide(i);
			TTT_PrintToChat(i, "\x05[TTT]\x01 %t", "Piano_Death");
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_KillPiano(Handle timer, any ref)
{
	int piano = EntRefToEntIndex(ref);
	if (piano != INVALID_ENT_REFERENCE && IsValidEntity(piano))
	{
		AcceptEntityInput(piano, "Kill");
	}
	return Plugin_Handled;
}

public Action Cmd_AdminPiano(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Handled;
	CreateTimer(0.1, Timer_SpawnPiano, GetClientUserId(client));
	TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Admin_Piano");
	return Plugin_Handled;
}

public Action Cmd_AdminRandomizer(int client, int args)
{
	if (client == 0 || !IsClientInGame(client)) return Plugin_Handled;
	StartRandomizer();
	TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Admin_Randomizer");
	return Plugin_Handled;
}

// ============================================================================
// Randomizer System
// ============================================================================
void StartRandomizer()
{
	if (g_bRandomizerActive) return;
	g_bRandomizerActive = true;
	
	TTT_PrintToChatAll("\x05[TTT]\x01 %t", "Randomizer_Start");
	
	CreateTimer(1.0, Timer_RandomizerCountdown, 2);
}

public Action Timer_RandomizerCountdown(Handle timer, any secondsLeft)
{
	if (g_bRoundEnded)
	{
		g_bRandomizerActive = false;
		TTT_PrintToChatAll("\x05[TTT]\x01 %t", "Randomizer_Cancel");
		return Plugin_Stop;
	}
	
	if (secondsLeft > 0)
	{
		TTT_PrintToChatAll("\x05[TTT]\x01 %t", "Randomizer_Countdown", secondsLeft, secondsLeft > 1 ? "s" : "");
		CreateTimer(1.0, Timer_RandomizerCountdown, secondsLeft - 1);
	}
	else
	{
		ExecuteRandomizer();
	}
	return Plugin_Stop;
}

void ExecuteRandomizer()
{
	int alivePlayers[MAXPLAYERS + 1];
	int aliveCount = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			alivePlayers[aliveCount] = i;
			aliveCount++;
		}
	}
	
	if (aliveCount < 2)
	{
		g_bRandomizerActive = false;
		return;
	}
	
	int oldRole[MAXPLAYERS + 1];
	for (int i = 1; i <= MaxClients; i++)
	{
		oldRole[i] = g_iPlayerRole[i];
	}
	
	int numDetectives = 0;
	int numTraitors = 0;
	int numInnocents = 0;
	
	for (int i = 0; i < aliveCount; i++)
	{
		int cl = alivePlayers[i];
		int oldR = oldRole[cl];
		
		int possibleRoles[2];
		if (oldR == ROLE_INNOCENT) {
			possibleRoles[0] = ROLE_TRAITOR;
			possibleRoles[1] = ROLE_DETECTIVE;
		} else if (oldR == ROLE_TRAITOR) {
			possibleRoles[0] = ROLE_INNOCENT;
			possibleRoles[1] = ROLE_DETECTIVE;
		} else {
			possibleRoles[0] = ROLE_INNOCENT;
			possibleRoles[1] = ROLE_TRAITOR;
		}
		
		int newR = possibleRoles[GetRandomInt(0, 1)];
		g_iPlayerRole[cl] = newR;
		
		if (newR == ROLE_TRAITOR) numTraitors++;
		else if (newR == ROLE_DETECTIVE) numDetectives++;
		else numInnocents++;
	}
	
	if (numInnocents == 0 && aliveCount >= 2) {
		int cl = -1;
		for (int i = 0; i < aliveCount; i++) {
			int candidate = alivePlayers[i];
			if (oldRole[candidate] != ROLE_INNOCENT) {
				cl = candidate;
				break;
			}
		}
		if (cl != -1) {
			if (g_iPlayerRole[cl] == ROLE_TRAITOR) numTraitors--;
			else numDetectives--;
			g_iPlayerRole[cl] = ROLE_INNOCENT;
			numInnocents++;
		}
	}
	if (numTraitors == 0 && aliveCount >= 2) {
		int cl = -1;
		for (int i = 0; i < aliveCount; i++) {
			int candidate = alivePlayers[i];
			if (oldRole[candidate] != ROLE_TRAITOR) {
				if (g_iPlayerRole[candidate] == ROLE_INNOCENT && numInnocents == 1) continue;
				cl = candidate;
				break;
			}
		}
		if (cl != -1) {
			if (g_iPlayerRole[cl] == ROLE_DETECTIVE) numDetectives--;
			else numInnocents--;
			g_iPlayerRole[cl] = ROLE_TRAITOR;
			numTraitors++;
		}
	}
	
	char traitorStr[64];
	if (numTraitors == 1) Format(traitorStr, sizeof(traitorStr), "%T", "Role_Assign_Traitors1", LANG_SERVER);
	else                  Format(traitorStr, sizeof(traitorStr), "%T", "Role_Assign_TraitorsN", LANG_SERVER, numTraitors);
	
	char detectiveStr[64] = "";
	if      (numDetectives == 1) Format(detectiveStr, sizeof(detectiveStr), "%T", "Role_Assign_Detectives1", LANG_SERVER);
	else if (numDetectives  > 1) Format(detectiveStr, sizeof(detectiveStr), "%T", "Role_Assign_DetectivesN", LANG_SERVER, numDetectives);
	
	char verbStr[64];
	if (numTraitors + numDetectives == 1) Format(verbStr, sizeof(verbStr), "%T", "Role_Assign_Verb1", LANG_SERVER);
	else                                  Format(verbStr, sizeof(verbStr), "%T", "Role_Assign_VerbN", LANG_SERVER);
	
	TTT_PrintToChatAll("\x05[TTT]\x01 %t", "Role_Assign_Final", traitorStr, detectiveStr, verbStr);
	
	for (int i = 0; i < aliveCount; i++)
	{
		int cl = alivePlayers[i];
		
		if (g_iSpriteEntity[cl] > 0 && IsValidEntity(g_iSpriteEntity[cl]))
		{
			AcceptEntityInput(g_iSpriteEntity[cl], "Kill");
			g_iSpriteEntity[cl] = 0;
		}
		
		if (g_iPlayerRole[cl] == ROLE_TRAITOR)
		{
			if (!IsFakeClient(cl)) TTT_PrintToChat(cl, "\x05[TTT]\x01 %t", "Role_YouAre_Traitor");
			
			if (!IsFakeClient(cl))
			{
				int teamCount = 0;
				for (int j = 0; j < aliveCount; j++)
					if (alivePlayers[j] != cl && g_iPlayerRole[alivePlayers[j]] == ROLE_TRAITOR) teamCount++;
				
				if (teamCount > 0)
				{
					TTT_PrintToChat(cl, "\x05[TTT]\x01 %t", "Role_Traitor_Mates");
					for (int j = 0; j < aliveCount; j++)
						if (alivePlayers[j] != cl && g_iPlayerRole[alivePlayers[j]] == ROLE_TRAITOR)
							TTT_PrintToChat(cl, "\x05[TTT]\x01 {green}%N{default}", alivePlayers[j]);
				}
			}
			CreateRoleSprite(cl, ROLE_TRAITOR);
			ScheduleModelChange(cl, g_sModelPaths[6], 6);
			SetScreenOverlay(cl, "sprites/Hud/Thud");
		}
		else if (g_iPlayerRole[cl] == ROLE_DETECTIVE)
		{
			ScheduleModelChange(cl, g_sModelPaths[4], 4);
			
			if (!IsFakeClient(cl))
			{
				TTT_PrintToChat(cl, "\x05[TTT]\x01 %t", "Role_YouAre_Detective");
				
				int teamCountD = 0;
				for (int j = 0; j < aliveCount; j++)
					if (alivePlayers[j] != cl && g_iPlayerRole[alivePlayers[j]] == ROLE_DETECTIVE) teamCountD++;
				
				if (teamCountD > 0)
				{
					TTT_PrintToChat(cl, "\x05[TTT]\x01 %t", "Role_Detective_Mates");
					for (int j = 0; j < aliveCount; j++)
						if (alivePlayers[j] != cl && g_iPlayerRole[alivePlayers[j]] == ROLE_DETECTIVE)
							TTT_PrintToChat(cl, "\x05[TTT]\x01 {lightgreen}%N{default}", alivePlayers[j]);
				}
			}
			CreateRoleSprite(cl, ROLE_DETECTIVE);
			SetScreenOverlay(cl, "sprites/Hud/Dhud");
		}
		else
		{
			ScheduleModelChange(cl, g_sModelPaths[6], 6);
			if (!IsFakeClient(cl)) TTT_PrintToChat(cl, "\x05[TTT]\x01 %t", "Role_YouAre_Innocent");
			SetScreenOverlay(cl, "sprites/Hud/Ihud");
		}
	}
	
	g_bRandomizerActive = false;
}

void LogActionCredits(int client, const char[] description, int points)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client)) return;
	if (points == 0) return;
	int idx = g_iActionCount[client];
	if (idx >= MAX_ROUND_ACTIONS) return;
	
	strcopy(g_sActionLog[client][idx], sizeof(g_sActionLog[][]), description);
	g_iActionCredits[client][idx] = points;
	g_iActionCount[client]++;
	g_iCredits[client] += points;
}

void PrintRoundSummary(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client)) return;
	if (g_iActionCount[client] <= 0) return;

	int total = 0;
	for (int j = 0; j < g_iActionCount[client]; j++)
		total += g_iActionCredits[client][j];

	TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Summary_Log_Title");
	
	for (int j = 0; j < g_iActionCount[client]; j++)
	{
		int pts = g_iActionCredits[client][j];
		
		char translatedAction[64];
		Format(translatedAction, sizeof(translatedAction), "%T", g_sActionLog[client][j], client);
		
		if (pts > 0)
			TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Summary_Log_Positive", translatedAction, pts);
		else
			TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Summary_Log_Negative", translatedAction, pts);
	}
	
	TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Summary_Total", total);
	TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Summary_Divider");
	if (g_bKarmaChangedThisRound[client])
	{
		TTT_PrintToChat(client, "\x05[TTT]\x01 %t", "Summary_Karma_Updated");
	}
}

#include "l4d2_ttt_shop.inc"

// ============================================================================
// RTV Logic
// ============================================================================
void LoadRTVMapsFromConfig()
{
	g_aRTVMapNames.Clear();
	g_aRTVMapDisplays.Clear();
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/l4d_ttt_rtv.cfg");
	
	KeyValues kv = new KeyValues("rtv_maps");
	if (!FileExists(path))
	{
		kv.SetString("c8m5_rooftop", "No Mercy (Azotea)");
		kv.SetString("c5m1_waterfront", "The Parish (Muelle)");
		kv.SetString("c1m4_atrium", "Dead Center (Atrio)");
		kv.SetString("c14m2_lighthouse", "The Last Stand (Faro)");
		kv.SetString("c6m3_port", "The Passing (Puerto)");
		kv.Rewind();
		kv.ExportToFile(path);
	}
	else
	{
		kv.ImportFromFile(path);
	}

	char currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			char mapName[64];
			char mapDisplay[128];
			kv.GetSectionName(mapName, sizeof(mapName));
			kv.GetString(NULL_STRING, mapDisplay, sizeof(mapDisplay), mapName);

			if (!StrEqual(mapName, currentMap, false))
			{
				g_aRTVMapNames.PushString(mapName);
				g_aRTVMapDisplays.PushString(mapDisplay);
			}

		} while (kv.GotoNextKey(false));
	}
	delete kv;
}

void StartRTVVote()
{
	if (!cv_ttt_rtv_enabled.BoolValue)
	{
		char currentMap[64];
		GetCurrentMap(currentMap, sizeof(currentMap));
		TTT_PrintToChatAll("\x05[TTT]\x01 %t", "RTV_End_Restart", g_iMaxRounds);
		ServerCommand("changelevel %s", currentMap);
		return;
	}

	LoadRTVMapsFromConfig();

	g_bVoteActive = true;
	g_iRTVTimeLeft = cv_ttt_rtv_vote_duration.IntValue;
	for (int i = 0; i < 32; i++) g_iVotes[i] = 0;
	for (int i = 1; i <= MaxClients; i++) g_iPlayerVote[i] = -1;

	TTT_PrintToChatAll("\x05[TTT]\x01 %t", "RTV_Vote_Start");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			CancelClientMenu(i);
			ShowRTVMenu(i);
		}
	}

	if (g_hVoteTimer != null) { KillTimer(g_hVoteTimer); g_hVoteTimer = null; }
	if (g_hVoteUpdateTimer != null) { KillTimer(g_hVoteUpdateTimer); g_hVoteUpdateTimer = null; }
	
	g_hVoteTimer = CreateTimer(float(g_iRTVTimeLeft), Timer_EndRTVVote);
	g_hVoteUpdateTimer = CreateTimer(1.0, Timer_UpdateRTVMenu, _, TIMER_REPEAT);
}

public Action Timer_UpdateRTVMenu(Handle timer)
{
	if (!g_bVoteActive)
	{
		g_hVoteUpdateTimer = null;
		return Plugin_Stop;
	}

	g_iRTVTimeLeft--;
	if (g_iRTVTimeLeft <= 0)
	{
		g_hVoteUpdateTimer = null;
		return Plugin_Stop;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && g_bHasRTVMenuOpen[i])
		{
			ShowRTVMenu(i);
		}
	}
	
	return Plugin_Continue;
}

void ShowRTVMenu(int client)
{
	Menu menu = new Menu(MenuHandler_RTV);
	
	char title[64];
	Format(title, sizeof(title), "%T", "RTV_Menu_Title", client, g_iRTVTimeLeft);
	menu.SetTitle(title);

	int len = g_aRTVMapNames.Length;
	for (int i = 0; i < len; i++)
	{
		char info[8];
		IntToString(i, info, sizeof(info));
		
		char mapDisplay[128];
		g_aRTVMapDisplays.GetString(i, mapDisplay, sizeof(mapDisplay));
		
		char display[128];
		if (g_iPlayerVote[client] == i)
		{
			Format(display, sizeof(display), "[X] %s", mapDisplay);
		}
		else
		{
			Format(display, sizeof(display), "%s", mapDisplay);
		}
		
		menu.AddItem(info, display);
	}
	
	char infoEx[8];
	IntToString(len, infoEx, sizeof(infoEx));
	char displayEx[128];
	if (g_iPlayerVote[client] == len)
		Format(displayEx, sizeof(displayEx), "%T", "RTV_Extend_Option_Voted", client, cv_ttt_rtv_extend_rounds.IntValue);
	else
		Format(displayEx, sizeof(displayEx), "%T", "RTV_Extend_Option_Plain", client, cv_ttt_rtv_extend_rounds.IntValue);
		
	menu.AddItem(infoEx, displayEx);
	
	menu.ExitButton = true;
	menu.Display(client, g_iRTVTimeLeft);
	g_bHasRTVMenuOpen[client] = true;
}

public int MenuHandler_RTV(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client = param1;
		if (!g_bVoteActive) return 0;
		
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		int choice = StringToInt(info);
		
		// Remove old vote
		int oldVote = g_iPlayerVote[client];
		if (oldVote != -1 && oldVote >= 0 && oldVote < 32)
		{
			g_iVotes[oldVote]--;
		}
		
		// Set new vote
		g_iPlayerVote[client] = choice;
		g_iVotes[choice]++;
		
		ShowRTVMenu(client);
	}
	else if (action == MenuAction_Cancel)
	{
		int client = param1;
		if (param2 == MenuCancel_Exit || param2 == MenuCancel_ExitBack || param2 == MenuCancel_Timeout)
		{
			g_bHasRTVMenuOpen[client] = false;
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public Action Timer_EndRTVVote(Handle timer)
{
	g_hVoteTimer = null;
	if (g_hVoteUpdateTimer != null) { KillTimer(g_hVoteUpdateTimer); g_hVoteUpdateTimer = null; }
	g_bVoteActive = false;
	
	int len = g_aRTVMapNames.Length;
	int totalOptions = len + 1;
	
	int highestVotes = -1;
	int winner = -1;
	
	for (int i = 0; i < totalOptions; i++)
	{
		if (g_iVotes[i] > highestVotes)
		{
			highestVotes = g_iVotes[i];
			winner = i;
		}
		else if (g_iVotes[i] == highestVotes)
		{
			// Tiebreaker
			if (GetRandomInt(0, 1) == 1)
			{
				winner = i;
			}
		}
	}
	
	g_iWinningVote = winner;
	
	if (winner >= 0 && winner < totalOptions)
	{
		int totalVotes = 0;
		for (int i = 0; i < totalOptions; i++) totalVotes += g_iVotes[i];
		
		int winnerVotes = g_iVotes[winner];
		float percent = totalVotes > 0 ? (float(winnerVotes) / float(totalVotes)) * 100.0 : 0.0;
		
		char winnerDisplay[128];
		if (winner == len)
		{
			Format(winnerDisplay, sizeof(winnerDisplay), "%T", "RTV_Extend_Display", LANG_SERVER, cv_ttt_rtv_extend_rounds.IntValue);
		}
		else
		{
			g_aRTVMapDisplays.GetString(winner, winnerDisplay, sizeof(winnerDisplay));
		}
		
		TTT_PrintToChatAll("\x05[TTT]\x01 %t", "RTV_Vote_End", winnerDisplay, winnerVotes, percent);
	}
	else
	{
		TTT_PrintToChatAll("\x05[TTT]\x01 %t", "RTV_Vote_End_Tie");
		g_iWinningVote = -1; // -1 fallback
	}
	
	return Plugin_Stop;
}

// --- Color wrappers ---
void TTT_PrintToChat(int client, const char[] format, any ...)
{
	SetGlobalTransTarget(client);
	char buffer[254];
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
	ReplaceString(buffer, sizeof(buffer), "{red}", "\x02");
	ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "\x03");
	ReplaceString(buffer, sizeof(buffer), "{green}", "\x04");
	ReplaceString(buffer, sizeof(buffer), "{olive}", "\x05");
	PrintToChat(client, "%s", buffer);
}

void TTT_PrintToChatAll(const char[] format, any ...)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			char buffer[254];
			VFormat(buffer, sizeof(buffer), format, 2);
			ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
			ReplaceString(buffer, sizeof(buffer), "{red}", "\x02");
			ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "\x03");
			ReplaceString(buffer, sizeof(buffer), "{green}", "\x04");
			ReplaceString(buffer, sizeof(buffer), "{olive}", "\x05");
			PrintToChat(i, "%s", buffer);
		}
	}
}
int g_iCountdownTimer = 0;
Handle g_hStartTimer = null;

// ============================================================================
// Dynamic survivor_limit — adjusts to match the number of connected humans
// ============================================================================
void UpdateSurvivorLimit()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			if (!IsFakeClient(i))
				count++;
		}
	}

	ConVar cv = FindConVar("survivor_limit");
	if (cv != null)
	{
		cv.SetInt(count);
	}
}

public Action Timer_AutoStartCheck(Handle timer)
{
	if (g_bRoundLive || g_bTruceActive)
	{
		PrintToServer("[TTT Lobby] Timer_AutoStartCheck: game already active, stopping.");
		return Plugin_Stop;
	}

	UpdateSurvivorLimit();

	// Count humans AND custom bots
	int humanCount = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != 2) continue;
		if (IsFakeClient(i) && !g_bIsCustomBot[i]) continue;
		humanCount++;
	}

	if (humanCount >= 3)
	{
		g_iCountdownTimer = 5;
		for (int j = 1; j <= MaxClients; j++) {
			if (IsClientInGame(j) && !IsFakeClient(j)) {
				PrintHintText(j, "Starting in 5 seconds...");
			}
		}
		PrintToServer("[TTT Lobby] Enough players. Starting countdown.");
		CreateTimer(1.0, Timer_StartCountdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
	else
	{
		int needed = 3 - humanCount;
		for (int j = 1; j <= MaxClients; j++) {
			if (IsClientInGame(j) && !IsFakeClient(j)) {
				PrintHintText(j, "Waiting for players... Need at least %d to start.", needed);
			}
		}
		CreateTimer(2.0, Timer_AutoStartCheck, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
}

public Action Timer_StartCountdown(Handle timer)
{
	if (g_bRoundLive)
	{
		PrintToServer("[TTT Lobby] Timer_StartCountdown: game active, stopping.");
		g_hStartTimer = null;
		return Plugin_Stop;
	}

	UpdateSurvivorLimit();

	// Count humans AND custom bots
	int humanCount = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != 2) continue;
		if (IsFakeClient(i) && !g_bIsCustomBot[i]) continue;
		humanCount++;
	}

	if (humanCount < 3)
	{
		PrintToServer("[TTT Lobby] Countdown canceled: only %d human(s).", humanCount);
		g_hStartTimer = null;
		int needed = 3 - humanCount;
		for (int j = 1; j <= MaxClients; j++) {
			if (IsClientInGame(j) && !IsFakeClient(j)) {
				PrintHintText(j, "Waiting for players... Need at least %d to start.", needed);
			}
		}
		CreateTimer(2.0, Timer_AutoStartCheck, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}

	if (g_iCountdownTimer <= 0)
	{
		PrintToServer("[TTT Lobby] Countdown finished. Starting TTT.");
		g_hStartTimer = null;
		OnRoundIsLive();
		return Plugin_Stop;
	}

	PrintToServer("[TTT Lobby] Starting in %d...", g_iCountdownTimer);
	for (int j = 1; j <= MaxClients; j++) {
		if (IsClientInGame(j) && !IsFakeClient(j)) {
			PrintHintText(j, "Starting in %d seconds...", g_iCountdownTimer);
		}
	}

	g_iCountdownTimer--;
	return Plugin_Continue;
}

public Action Command_AddBot(int client, int args)
{
	CreateCustomBot(client);
	return Plugin_Handled;
}

void CreateCustomBot(int ownerClient)
{
	char ownerName[MAX_NAME_LENGTH];
	if (ownerClient > 0 && IsClientInGame(ownerClient)) GetClientName(ownerClient, ownerName, sizeof(ownerName));
	else strcopy(ownerName, sizeof(ownerName), "none");

	int trigger = CreateFakeClient("TTT_Bot");

	if (trigger != 0)
	{
		g_bPendingCustomBot = true;
		g_iPendingBotTeleportClient = (ownerClient > 0 && IsClientInGame(ownerClient)) ? ownerClient : 0;

		DispatchKeyValue(trigger, "classname", "SurvivorBot");
		ChangeClientTeam(trigger, 2);
		DispatchSpawn(trigger);
		KickClient(trigger);
	}
}

