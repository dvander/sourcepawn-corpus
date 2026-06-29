/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* 
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐

- FIX: NONE
- BUG: NONE

└────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>
#include <colors>
#include <left4dhooks>

#define PLUGIN_VERSION "1.2"
#define SPRITE_BEAMS "materials/sprites/laserbeam.vmt"
#define SPRITE_HALOS "materials/sprites/halo01.vmt"
#define HEALTH_SOUND "player/water/pl_wade2.wav"

// Models
#define LUNA_DEFAULT_MODEL "models/pet/vex/default/default.mdl"
#define LUNA_DAWN_MODEL "models/pet/vex/dawn/dawn.mdl"
#define LUNA_SHADOW_MODEL "models/pet/vex/shadow/shadow.mdl"

#define RAVEN_DEFAULT_MODEL "models/pet/poppy/default/default.mdl"
#define RAVEN_NOXUS_MODEL "models/pet/poppy/noxus/noxus.mdl"
#define RAVEN_SNOWY_MODEL "models/pet/poppy/snowy/snowy.mdl"

#define SNOWY_DEFAULT_MODEL "models/pet/anivia/default/default.mdl"
#define SNOWY_EAGLE_MODEL "models/pet/anivia/eagle/eagle.mdl"
#define SNOWY_HEXTECH_MODEL "models/pet/anivia/hextech/hextech.mdl"

#define SPYRO_DEFAULT_MODEL "models/pet/smolder/default/default.mdl"
#define SPYRO_HEAVEN_MODEL "models/pet/smolder/heaven/heaven.mdl"
#define SPYRO_REINDEER_MODEL "models/pet/smolder/reindeer/reindeer.mdl"

#define GHOSTY_DEFAULT_MODEL "models/pet/thresh/default/default.mdl"
#define GHOSTY_JANITOR_MODEL "models/pet/thresh/janitor/janitor.mdl"
#define GHOSTY_MOON_MODEL "models/pet/thresh/moon/moon.mdl"

#define STORM_DEFAULT_MODEL "models/pet/volibear/default/default.mdl"
#define STORM_DEMON_MODEL "models/pet/volibear/demon/demon.mdl"
#define STORM_TIGER_MODEL "models/pet/volibear/tiger/tiger.mdl"

#define EMBER_DEFAULT_MODEL "models/pet/ornn/default/default.mdl"
#define EMBER_CHOOCHOO_MODEL "models/pet/ornn/choochoo/choochoo.mdl"
#define EMBER_THUNDER_MODEL "models/pet/ornn/thunder/thunder.mdl"

#define WARWICK_HUNTER_MODEL "models/pet/warwick/hunter/hunter.mdl"
#define WARWICK_FIREFANG_MODEL "models/pet/warwick/firefang/firefang.mdl"
#define WARWICK_BIGBAD_MODEL "models/pet/warwick/bigbad/bigbad.mdl"

// Configurable parameters
#define STEP_REACH_DISTANCE   20.0   // When the Companion considers a path step reached
#define CLIENT_NEAR_DISTANCE  80.0   // When Companion is close enough to you to reset steps
#define TELEPORT_DISTANCE  800.0   // When Companion is close enough to you to reset steps
#define MAX_STEPS_MEMORY 512 // How many steps the Companion remembers
#define PET_MOVE_INTERVAL 0.1 // Set the interval between every step to remember

enum
{
	L4D2Class_Unknown = 0,
	L4D2Class_Smoker,
	L4D2Class_Boomer,
	L4D2Class_Hunter,
	L4D2Class_Spitter,
	L4D2Class_Jockey,
	L4D2Class_Charger,
	L4D2Class_Witch,
	L4D2Class_Tank,
	L4D2Class_Survivor
};

enum
{
	L4D2Team_Unknown = -1,
	L4D2Team_Unassigned,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected
}

// Cookie Handles
Cookie g_hPetSettings;
Cookie g_hPetAutoAbilities;

// Companion Main Variables
int g_iPet_Entity[MAXPLAYERS+1];
int g_iPet_MoveType [MAXPLAYERS+1];
char g_sPet_Name [MAXPLAYERS+1][16];
char g_sPet_Skin [MAXPLAYERS+1][16];
char g_sPet_Aura [MAXPLAYERS+1][16];
char g_sPet_Size [MAXPLAYERS+1][16];

// Steps Variables
int g_iSavedStep[MAXPLAYERS+1];
int g_iLoadedStep[MAXPLAYERS+1];
int g_iFollowTarget[MAXPLAYERS+1];
bool g_bPetPaused[MAXPLAYERS+1];
float g_fPlayerSteps[MAX_STEPS_MEMORY][MAXPLAYERS+1][3];
float g_fLastStepWriteTime[MAXPLAYERS+1];
float g_fPet_AnimLock[MAXPLAYERS+1];

// Teleport Variables
int g_iLastTeleportTime[MAXPLAYERS+1];
bool g_bIsTeleportPet[MAXPLAYERS+1];

// Create Beam Ring
int g_iBeamSprite;
int g_iHaloSprite;

// Auto Abilities
bool g_bAutoHeal[MAXPLAYERS+1];
bool g_bAutoAntiPuke[MAXPLAYERS+1];
bool g_bAutoRevive[MAXPLAYERS+1];
bool g_bAutoAmmo[MAXPLAYERS+1];
bool g_bAutoAdren[MAXPLAYERS+1];

// Reviving Related Variables
bool g_bTeammate_Reviving[MAXPLAYERS+1];
bool g_bPetReviveActive[MAXPLAYERS+1];
bool g_bReviveInProgress[MAXPLAYERS+1];
float g_fSetupProgressTime[MAXPLAYERS+1];

// Abilities Cooldown
int g_iHealing_Cooldown[MAXPLAYERS+1];
int g_iAntiPuke_Cooldown[MAXPLAYERS+1];
int g_iRevive_Cooldown[MAXPLAYERS+1];
int g_iAmmoRefill_Cooldown[MAXPLAYERS+1];
int g_iAdrenBoost_Cooldown[MAXPLAYERS+1];
int g_iPlayerOnVomit [MAXPLAYERS+1];

// Timers Handles
Handle g_hTimer_MoveIn [MAXPLAYERS+1];
Handle g_hTimer_MoveOut [MAXPLAYERS+1];
Handle g_hTimer_ReviveCheck[MAXPLAYERS+1];
Handle g_hTimer_CheckAutoAbilities[MAXPLAYERS+1];

// Cvars
ConVar g_Cvar_Pet_Plugin_Enable;
ConVar g_Cvar_PetHealCooldown;
ConVar g_Cvar_PetHealAmount;
ConVar g_Cvar_PetAntipukeCooldown;
ConVar g_Cvar_PetReviveCooldown;
ConVar g_Cvar_PetAmmoRefillCooldown;
ConVar g_Cvar_PetAdrenBoostCooldown;
ConVar g_Cvar_Server_MenuSound;
ConVar g_Cvar_Server_Adren_Duration;

// Cvars Changed
bool g_bPluginEnable;
int g_iPet_HealCooldown;
int g_iPet_HealAmount;
int g_iPet_AntiPukeCooldown;
int g_iPet_ReviveCooldown;
int g_iPet_AmmoRefillCooldown;
int g_iPet_AdrenBoostCooldown;

public Plugin myinfo =
{
	name = "L4D2 Companion",
	author = "AlasfourOM",
	description = "Summoning A Companion",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if(test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *												OnPluginStart + OnMapStart										   *
 *================================================================================================================ */

public void OnPluginStart()
{
	CreateConVar ("l4d2_companion_version", PLUGIN_VERSION, "L4D2 Companion", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_Cvar_Pet_Plugin_Enable = CreateConVar("l4d2_pet_plugin_enable", "1", "Enables the companion plugin. 0 = Disable, 1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_PetHealCooldown = CreateConVar("l4d2_pet_heal_cooldown", "120", "Sets the cooldown for the pet's healing ability (in seconds).", FCVAR_NOTIFY);
	g_Cvar_PetHealAmount = CreateConVar("l4d2_pet_heal_amount", "20", "Determines the amount of health the Companion heals.", FCVAR_NOTIFY);
	g_Cvar_PetAntipukeCooldown = CreateConVar("l4d2_pet_antipuke_cooldown", "120", "Sets the cooldown for the pet's antipuke ability (in seconds).", FCVAR_NOTIFY);
	g_Cvar_PetReviveCooldown = CreateConVar("l4d2_pet_revive_cooldown", "360", "Sets the cooldown for the pet's revive ability (in seconds).", FCVAR_NOTIFY);
	g_Cvar_PetAmmoRefillCooldown = CreateConVar("l4d2_pet_ammo_cooldown", "360", "Sets the cooldown for the pet's ammo refill ability (in seconds).", FCVAR_NOTIFY);
	g_Cvar_PetAdrenBoostCooldown = CreateConVar("l4d2_pet_adrenboost_cooldown", "120", "Sets the cooldown for the pet's adrenaline boost ability (in seconds).", FCVAR_NOTIFY);
	g_Cvar_Server_MenuSound = FindConVar("sm_menu_sounds");
	g_Cvar_Server_Adren_Duration = FindConVar("adrenaline_duration");
	
	GetCvars();
	g_Cvar_Pet_Plugin_Enable.AddChangeHook(ConVarChanged);
	g_Cvar_PetHealCooldown.AddChangeHook(ConVarChanged);
	g_Cvar_PetHealAmount.AddChangeHook(ConVarChanged);
	g_Cvar_PetAntipukeCooldown.AddChangeHook(ConVarChanged);
	g_Cvar_PetReviveCooldown.AddChangeHook(ConVarChanged);
	g_Cvar_PetAmmoRefillCooldown.AddChangeHook(ConVarChanged);
	g_Cvar_PetAdrenBoostCooldown.AddChangeHook(ConVarChanged);
	AutoExecConfig(true, "l4d2_companion");
	
	g_hPetSettings = RegClientCookie("l4d2_companion_settings", "Stores pet visual settings", CookieAccess_Protected);
	g_hPetAutoAbilities = RegClientCookie("l4d2_companion_auto_abilities", "Stores pet auto-ability toggles", CookieAccess_Protected);
	
	RegConsoleCmd("sm_pet", Command_SpawnPet, "Create My Pet");
	RegConsoleCmd("sm_companion", Command_SpawnPet, "Create My Pet");
	
	HookEvent("player_spawn", Event_StatusChanged);
	HookEvent("player_team", Event_StatusChanged);
	HookEvent("player_death", Event_StatusChanged);
	HookEvent("player_disconnect", Event_StatusChanged);
	HookEvent("revive_begin", Event_ReviveBegin);
	HookEvent("revive_end", Event_ReviveEnd);
	HookEvent("player_now_it", Event_OnVomit);
	HookEvent("player_no_longer_it", Event_OnUnVomit);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;
		OnClientCookiesCached(i);
	}
}

public void OnMapStart()
{
	// ==================== LUNA ====================
	AddFileToDownloadsTable("models/pet/vex/default/default.mdl");
	AddFileToDownloadsTable("models/pet/vex/default/default.vvd");
	AddFileToDownloadsTable("models/pet/vex/default/default.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/vex/default/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/vex/default/body.vtf");
	
	AddFileToDownloadsTable("models/pet/vex/dawn/dawn.mdl");
	AddFileToDownloadsTable("models/pet/vex/dawn/dawn.vvd");
	AddFileToDownloadsTable("models/pet/vex/dawn/dawn.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/vex/dawn/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/vex/dawn/body.vtf");
	
	AddFileToDownloadsTable("models/pet/vex/shadow/shadow.mdl");
	AddFileToDownloadsTable("models/pet/vex/shadow/shadow.vvd");
	AddFileToDownloadsTable("models/pet/vex/shadow/shadow.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/vex/shadow/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/vex/shadow/body.vtf");
	
	// ==================== RAVEN ====================
	AddFileToDownloadsTable("models/pet/poppy/default/default.mdl");
	AddFileToDownloadsTable("models/pet/poppy/default/default.vvd");
	AddFileToDownloadsTable("models/pet/poppy/default/default.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/poppy/default/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/poppy/default/body.vtf");
	
	AddFileToDownloadsTable("models/pet/poppy/noxus/noxus.mdl");
	AddFileToDownloadsTable("models/pet/poppy/noxus/noxus.vvd");
	AddFileToDownloadsTable("models/pet/poppy/noxus/noxus.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/poppy/noxus/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/poppy/noxus/body.vtf");
	
	AddFileToDownloadsTable("models/pet/poppy/snowy/snowy.mdl");
	AddFileToDownloadsTable("models/pet/poppy/snowy/snowy.vvd");
	AddFileToDownloadsTable("models/pet/poppy/snowy/snowy.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/poppy/snowy/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/poppy/snowy/body.vtf");
	
	
	// ==================== ANIVIA ====================
	AddFileToDownloadsTable("models/pet/anivia/default/default.mdl");
	AddFileToDownloadsTable("models/pet/anivia/default/default.vvd");
	AddFileToDownloadsTable("models/pet/anivia/default/default.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/anivia/default/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/anivia/default/body.vtf");
	
	AddFileToDownloadsTable("models/pet/anivia/eagle/eagle.mdl");
	AddFileToDownloadsTable("models/pet/anivia/eagle/eagle.vvd");
	AddFileToDownloadsTable("models/pet/anivia/eagle/eagle.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/anivia/eagle/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/anivia/eagle/body.vtf");
	
	AddFileToDownloadsTable("models/pet/anivia/hextech/hextech.mdl");
	AddFileToDownloadsTable("models/pet/anivia/hextech/hextech.vvd");
	AddFileToDownloadsTable("models/pet/anivia/hextech/hextech.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/anivia/hextech/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/anivia/hextech/body.vtf");
	
	
	// ==================== SPYRO ====================
	AddFileToDownloadsTable("models/pet/smolder/default/default.mdl");
	AddFileToDownloadsTable("models/pet/smolder/default/default.vvd");
	AddFileToDownloadsTable("models/pet/smolder/default/default.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/smolder/default/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/smolder/default/body.vtf");
	
	AddFileToDownloadsTable("models/pet/smolder/heaven/heaven.mdl");
	AddFileToDownloadsTable("models/pet/smolder/heaven/heaven.vvd");
	AddFileToDownloadsTable("models/pet/smolder/heaven/heaven.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/smolder/heaven/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/smolder/heaven/body.vtf");
	
	AddFileToDownloadsTable("models/pet/smolder/reindeer/reindeer.mdl");
	AddFileToDownloadsTable("models/pet/smolder/reindeer/reindeer.vvd");
	AddFileToDownloadsTable("models/pet/smolder/reindeer/reindeer.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/smolder/reindeer/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/smolder/reindeer/body.vtf");
	
	
	// ==================== GHOSTY ====================
	AddFileToDownloadsTable("models/pet/thresh/default/default.mdl");
	AddFileToDownloadsTable("models/pet/thresh/default/default.vvd");
	AddFileToDownloadsTable("models/pet/thresh/default/default.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/thresh/default/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/thresh/default/body.vtf");
	
	AddFileToDownloadsTable("models/pet/thresh/janitor/janitor.mdl");
	AddFileToDownloadsTable("models/pet/thresh/janitor/janitor.vvd");
	AddFileToDownloadsTable("models/pet/thresh/janitor/janitor.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/thresh/janitor/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/thresh/janitor/body.vtf");
	
	AddFileToDownloadsTable("models/pet/thresh/moon/moon.mdl");
	AddFileToDownloadsTable("models/pet/thresh/moon/moon.vvd");
	AddFileToDownloadsTable("models/pet/thresh/moon/moon.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/thresh/moon/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/thresh/moon/body.vtf");
	
	
	// ==================== STORM ====================
	AddFileToDownloadsTable("models/pet/volibear/default/default.mdl");
	AddFileToDownloadsTable("models/pet/volibear/default/default.vvd");
	AddFileToDownloadsTable("models/pet/volibear/default/default.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/volibear/default/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/volibear/default/body.vtf");
	AddFileToDownloadsTable("materials/models/pet/volibear/default/ice.vmt");
	AddFileToDownloadsTable("materials/models/pet/volibear/default/ice.vtf");
	AddFileToDownloadsTable("materials/models/pet/volibear/default/neck.vmt");
	AddFileToDownloadsTable("materials/models/pet/volibear/default/neck.vtf");
	
	AddFileToDownloadsTable("models/pet/volibear/demon/demon.mdl");
	AddFileToDownloadsTable("models/pet/volibear/demon/demon.vvd");
	AddFileToDownloadsTable("models/pet/volibear/demon/demon.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/volibear/demon/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/volibear/demon/body.vtf");
	
	AddFileToDownloadsTable("models/pet/volibear/tiger/tiger.mdl");
	AddFileToDownloadsTable("models/pet/volibear/tiger/tiger.vvd");
	AddFileToDownloadsTable("models/pet/volibear/tiger/tiger.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/volibear/tiger/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/volibear/tiger/body.vtf");
	
	
	// ==================== EMBER ====================
	AddFileToDownloadsTable("models/pet/ornn/default/default.mdl");
	AddFileToDownloadsTable("models/pet/ornn/default/default.vvd");
	AddFileToDownloadsTable("models/pet/ornn/default/default.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/ornn/default/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/ornn/default/body.vtf");
	
	AddFileToDownloadsTable("models/pet/ornn/choochoo/choochoo.mdl");
	AddFileToDownloadsTable("models/pet/ornn/choochoo/choochoo.vvd");
	AddFileToDownloadsTable("models/pet/ornn/choochoo/choochoo.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/ornn/choochoo/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/ornn/choochoo/body.vtf");
	
	AddFileToDownloadsTable("models/pet/ornn/thunder/thunder.mdl");
	AddFileToDownloadsTable("models/pet/ornn/thunder/thunder.vvd");
	AddFileToDownloadsTable("models/pet/ornn/thunder/thunder.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/ornn/thunder/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/ornn/thunder/body.vtf");
	
	
	// ==================== WARWICK ====================
	AddFileToDownloadsTable("models/pet/warwick/hunter/hunter.mdl");
	AddFileToDownloadsTable("models/pet/warwick/hunter/hunter.vvd");
	AddFileToDownloadsTable("models/pet/warwick/hunter/hunter.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/warwick/hunter/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/warwick/hunter/body.vtf");
	
	AddFileToDownloadsTable("models/pet/warwick/firefang/firefang.mdl");
	AddFileToDownloadsTable("models/pet/warwick/firefang/firefang.vvd");
	AddFileToDownloadsTable("models/pet/warwick/firefang/firefang.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/warwick/firefang/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/warwick/firefang/body.vtf");
	
	AddFileToDownloadsTable("models/pet/warwick/bigbad/bigbad.mdl");
	AddFileToDownloadsTable("models/pet/warwick/bigbad/bigbad.vvd");
	AddFileToDownloadsTable("models/pet/warwick/bigbad/bigbad.dx90.vtx");
	AddFileToDownloadsTable("materials/models/pet/warwick/bigbad/body.vmt");
	AddFileToDownloadsTable("materials/models/pet/warwick/bigbad/body.vtf");
	
	PrecacheSound(HEALTH_SOUND, true);
	PrecacheModel(LUNA_DEFAULT_MODEL, true);
	PrecacheModel(LUNA_DAWN_MODEL, true);
	PrecacheModel(LUNA_SHADOW_MODEL, true);
	PrecacheModel(RAVEN_DEFAULT_MODEL, true);
	PrecacheModel(RAVEN_NOXUS_MODEL, true);
	PrecacheModel(RAVEN_SNOWY_MODEL, true);
	PrecacheModel(SNOWY_DEFAULT_MODEL, true);
	PrecacheModel(SNOWY_EAGLE_MODEL, true);
	PrecacheModel(SNOWY_HEXTECH_MODEL, true);
	PrecacheModel(SPYRO_DEFAULT_MODEL, true);
	PrecacheModel(SPYRO_HEAVEN_MODEL, true);
	PrecacheModel(SPYRO_REINDEER_MODEL, true);
	PrecacheModel(GHOSTY_DEFAULT_MODEL, true);
	PrecacheModel(GHOSTY_JANITOR_MODEL, true);
	PrecacheModel(GHOSTY_MOON_MODEL, true);
	PrecacheModel(STORM_DEFAULT_MODEL, true);
	PrecacheModel(STORM_DEMON_MODEL, true);
	PrecacheModel(STORM_TIGER_MODEL, true);
	PrecacheModel(EMBER_DEFAULT_MODEL, true);
	PrecacheModel(EMBER_CHOOCHOO_MODEL, true);
	PrecacheModel(EMBER_THUNDER_MODEL, true);
	PrecacheModel(WARWICK_HUNTER_MODEL, true);
	PrecacheModel(WARWICK_FIREFANG_MODEL, true);
	PrecacheModel(WARWICK_BIGBAD_MODEL, true);
	
	g_iBeamSprite = PrecacheModel(SPRITE_BEAMS, true);
	g_iHaloSprite = PrecacheModel(SPRITE_HALOS, true);
		
	g_Cvar_Server_MenuSound.SetInt(0);
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *												On Convar Changed		 										   *
 *================================================================================================================ */

public void ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void OnConfigsExecuted()
{
	GetCvars();
}

void GetCvars()
{
	g_bPluginEnable = g_Cvar_Pet_Plugin_Enable.BoolValue;
	g_iPet_HealCooldown = g_Cvar_PetHealCooldown.IntValue;
	g_iPet_HealAmount = g_Cvar_PetHealAmount.IntValue;
	g_iPet_AntiPukeCooldown = g_Cvar_PetAntipukeCooldown.IntValue;
	g_iPet_ReviveCooldown = g_Cvar_PetReviveCooldown.IntValue;
	g_iPet_AmmoRefillCooldown = g_Cvar_PetAmmoRefillCooldown.IntValue;
	g_iPet_AdrenBoostCooldown = g_Cvar_PetAdrenBoostCooldown.IntValue;
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *														Cookies													   *
 *================================================================================================================ */

void LoadPetCookies(int client)
{
	if (!AreClientCookiesCached(client)) return;

	char sSettings[128];
	GetClientCookie(client, g_hPetSettings, sSettings, sizeof(sSettings));
	
	if (sSettings[0] == '\0') 
	{
		strcopy(g_sPet_Name[client], sizeof(g_sPet_Name[]), "Luna");
		strcopy(g_sPet_Skin[client], sizeof(g_sPet_Skin[]), "Type I");
		strcopy(g_sPet_Aura[client], sizeof(g_sPet_Aura[]), "White");
		strcopy(g_sPet_Size[client], sizeof(g_sPet_Size[]), "0.3");
	}
	else 
	{
		char sExploded[4][16]; 
		ExplodeString(sSettings, "|", sExploded, 4, 16);
		
		strcopy(g_sPet_Name[client], sizeof(g_sPet_Name[]), sExploded[0]);
		strcopy(g_sPet_Skin[client], sizeof(g_sPet_Skin[]), sExploded[1]);
		strcopy(g_sPet_Aura[client], sizeof(g_sPet_Aura[]), sExploded[2]);
		strcopy(g_sPet_Size[client], sizeof(g_sPet_Size[]), sExploded[3]);
	}
	
	char sAbilities[32];
	GetClientCookie(client, g_hPetAutoAbilities, sAbilities, sizeof(sAbilities));
	
	if (sAbilities[0] == '\0')
	{
		g_bAutoHeal[client] = false;
		g_bAutoAntiPuke[client] = false;
		g_bAutoRevive[client] = false;
		g_bAutoAmmo[client] = false;
		g_bAutoAdren[client] = false;
	}
	else
	{
		char sExploded[5][4];
		ExplodeString(sAbilities, " ", sExploded, 5, 4);
		
		g_bAutoHeal[client]     = view_as<bool>(StringToInt(sExploded[0]));
		g_bAutoAntiPuke[client] = view_as<bool>(StringToInt(sExploded[1]));
		g_bAutoRevive[client]   = view_as<bool>(StringToInt(sExploded[2]));
		g_bAutoAmmo[client]     = view_as<bool>(StringToInt(sExploded[3]));
		g_bAutoAdren[client]    = view_as<bool>(StringToInt(sExploded[4]));
	}
}

void SavePetCookies_Settings(int client)
{
	if(!AreClientCookiesCached(client)) return;
	
	char sSettings[128];
	FormatEx(sSettings, sizeof(sSettings), "%s|%s|%s|%s", g_sPet_Name[client], g_sPet_Skin[client], g_sPet_Aura[client], g_sPet_Size[client]);
	SetClientCookie(client, g_hPetSettings, sSettings);
}

void SavePetCookies_Abilities(int client)
{
	if(!AreClientCookiesCached(client)) return;
	
	char sAbilities[32];
	FormatEx(sAbilities, sizeof(sAbilities), "%i %i %i %i %i", g_bAutoHeal[client] ? 1 : 0, g_bAutoAntiPuke[client] ? 1 : 0, g_bAutoRevive[client] ? 1 : 0, g_bAutoAmmo[client] ? 1 : 0, g_bAutoAdren[client] ? 1 : 0);
	SetClientCookie(client, g_hPetAutoAbilities, sAbilities);
}

public void OnClientCookiesCached(int client)
{
	LoadPetCookies(client);
}

public void OnClientDisconnect(int client)
{
	SavePetCookies_Settings(client);
	SavePetCookies_Abilities(client);
	RemovePet(client);
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *													ALL Events													   *
 *================================================================================================================ */

void Event_StatusChanged(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || !g_bPluginEnable) return;
	
	RemovePet(client);
	g_iPlayerOnVomit[client] = 0;
}

void Event_ReviveBegin(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnable) return;
	
	int subject = GetClientOfUserId(event.GetInt("subject")); // the survivor being revived
	if (!subject || !IsClientInGame(subject)) return;
	
	// mark that a teammate is reviving this subject
	g_bTeammate_Reviving[subject] = true;
	
	// if our Companion was reviving this subject, cancel our own progress bar cleanly
	for (int owner = 1; owner <= MaxClients; owner++)
	{
		if (!IsClientInGame(owner)) continue;
		if (!g_bReviveInProgress[owner]) continue;
		
		int activeTarget = g_iFollowTarget[owner];
		if (activeTarget != owner && activeTarget == subject) KillProgressBar(owner, subject);
		else if (activeTarget == owner && subject == owner) KillProgressBar(owner, owner);
	}
}

void Event_ReviveEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnable) return;
	
	int subject = GetClientOfUserId(event.GetInt("subject")); // the survivor who was being revived
	if (!subject || !IsClientInGame(subject)) return;
	
	g_bTeammate_Reviving[subject] = false;
	
	// if our Companion was reviving this subject, clear our own progress state
	for (int owner = 1; owner <= MaxClients; owner++)
	{
		if (!IsClientInGame(owner)) continue;
		if (!g_bReviveInProgress[owner]) continue;
		
		int activeTarget = g_iFollowTarget[owner];
		if ((activeTarget == subject) || (activeTarget == owner && subject == owner))
			KillProgressBar(owner, subject);
    }
}

void Event_OnVomit(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnable) return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client)) return;
	g_iPlayerOnVomit[client] = 1;
}

void Event_OnUnVomit(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnable) return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client)) return;
	
	g_iPlayerOnVomit[client] = 0;
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *											Command To Create Companion Menu									   *
 *================================================================================================================ */

Action Command_SpawnPet(int client, int args)
{
	if (!g_bPluginEnable) return Plugin_Handled;
	else if(client == 0) PrintToServer("[Companion] You can not use this function from console.");
	else if(GetClientTeam(client) != L4D2Team_Survivor || !IsPlayerAlive(client)) ReplyToCommand(client, "{Green}[Companion] {default}Only alive survivors can use this command.");
	else OpenPetMainMenu(client);
	return Plugin_Handled;
}

void OpenPetMainMenu(int client)
{
	Panel panel = new Panel();
	char sBuffer[64];
	bool isSpawned = IsPetValid(client);
	
	panel.SetTitle("Companion Panel:");
	panel.DrawItem(isSpawned ? "Dismiss Companion" : "Summon Companion");

	if (!isSpawned)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "Companion: (%s)", g_sPet_Name[client]);
		panel.DrawItem(sBuffer);
	}
	else
	{
		FormatEx(sBuffer, sizeof(sBuffer), "Companion: %s", g_sPet_Name[client]);
		panel.DrawItem(sBuffer);
	}
	
	panel.DrawText(" "); // Spacer
	
	panel.DrawText("Companion Style:");
	FormatEx(sBuffer, sizeof(sBuffer), "Skin: (%s)", g_sPet_Skin[client]);
	panel.DrawItem(sBuffer, isSpawned ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	FormatEx(sBuffer, sizeof(sBuffer), "Glow: (%s)", g_sPet_Aura[client]);
	panel.DrawItem(sBuffer, isSpawned ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	panel.DrawItem("Body Scale", isSpawned ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	panel.DrawText(" "); // Spacer
	
	panel.DrawText("Companion Action:");
	panel.DrawItem("Action Moves", isSpawned ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	panel.DrawItem("Special Power", isSpawned ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	panel.DrawItem("Instant Travel", isSpawned ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	panel.DrawText(" "); // Spacer
	panel.DrawText("0. Exit");
	
	panel.Send(client, Handle_PetPanel, MENU_TIME_FOREVER);
	delete panel;
}

int Handle_PetPanel(Menu menu, MenuAction action, int client, int select)
{
	if (action == MenuAction_Select)
	{
		
		if(GetClientTeam(client) != L4D2Team_Survivor)
		{
			CPrintToChat(client, "{Green}[Companion] {default}Only survivors team can use this.");
			return 0;
		}
		
		if(!IsPlayerAlive(client))
		{
			CPrintToChat(client, "{Green}[Companion] {default}Only alive survivors can use this command.");
			return 0;
		}
		
		bool isSpawned = IsPetValid(client);
		
		if (!isSpawned && (select == 0 || select > 2)) return 0;
		else if (isSpawned && (select == 0 || select > 8)) return 0;
		
		switch(select)
		{
			case 1:
			{
				if (isSpawned) ReturnPet(client);
				else
				{
					if (StrEqual(g_sPet_Name[client], "Luna"))
					{
						if (StrEqual(g_sPet_Skin[client], "Type I")) SpawnPet(client, LUNA_DEFAULT_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type II")) SpawnPet(client, LUNA_DAWN_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type III")) SpawnPet(client, LUNA_SHADOW_MODEL);
						else SpawnPet(client, LUNA_DEFAULT_MODEL);
					}
					else if (StrEqual(g_sPet_Name[client], "Raven"))
					{
						if (StrEqual(g_sPet_Skin[client], "Type I")) SpawnPet(client, RAVEN_DEFAULT_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type II")) SpawnPet(client, RAVEN_NOXUS_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type III")) SpawnPet(client, RAVEN_SNOWY_MODEL);
						else SpawnPet(client, RAVEN_DEFAULT_MODEL);
					}
					else if (StrEqual(g_sPet_Name[client], "Snowy"))
					{
						if (StrEqual(g_sPet_Skin[client], "Type I")) SpawnPet(client, SNOWY_DEFAULT_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type II")) SpawnPet(client, SNOWY_EAGLE_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type III")) SpawnPet(client, SNOWY_HEXTECH_MODEL);
						else SpawnPet(client, SNOWY_DEFAULT_MODEL);
					}
					else if (StrEqual(g_sPet_Name[client], "Spyro"))
					{
						if (StrEqual(g_sPet_Skin[client], "Type I")) SpawnPet(client, SPYRO_DEFAULT_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type II")) SpawnPet(client, SPYRO_HEAVEN_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type III")) SpawnPet(client, SPYRO_REINDEER_MODEL);
						else SpawnPet(client, SPYRO_DEFAULT_MODEL);
					}
					else if (StrEqual(g_sPet_Name[client], "Ghosty"))
					{
						if (StrEqual(g_sPet_Skin[client], "Type I")) SpawnPet(client, GHOSTY_DEFAULT_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type II")) SpawnPet(client, GHOSTY_JANITOR_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type III")) SpawnPet(client, GHOSTY_MOON_MODEL);
						else SpawnPet(client, GHOSTY_DEFAULT_MODEL);
					}
					else if (StrEqual(g_sPet_Name[client], "Storm"))
					{
						if (StrEqual(g_sPet_Skin[client], "Type I")) SpawnPet(client, STORM_DEFAULT_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type II")) SpawnPet(client, STORM_DEMON_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type III")) SpawnPet(client, STORM_TIGER_MODEL);
						else SpawnPet(client, STORM_DEFAULT_MODEL);
					}
					else if (StrEqual(g_sPet_Name[client], "Ember"))
					{
						if (StrEqual(g_sPet_Skin[client], "Type I")) SpawnPet(client, EMBER_DEFAULT_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type II")) SpawnPet(client, EMBER_CHOOCHOO_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type III")) SpawnPet(client, EMBER_THUNDER_MODEL);
						else SpawnPet(client, EMBER_DEFAULT_MODEL);
					}
					else if (StrEqual(g_sPet_Name[client], "Warwick"))
					{
						if (StrEqual(g_sPet_Skin[client], "Type I")) SpawnPet(client, WARWICK_HUNTER_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type II")) SpawnPet(client, WARWICK_FIREFANG_MODEL);
						else if (StrEqual(g_sPet_Skin[client], "Type III"))SpawnPet(client, WARWICK_BIGBAD_MODEL);
						else SpawnPet(client, WARWICK_HUNTER_MODEL);
					}
				}
				OpenPetMainMenu(client);
			}
			case 2:
			{
				if (!isSpawned)
				{
					if(StrEqual(g_sPet_Name[client], "Luna")) FormatEx(g_sPet_Name[client], sizeof(g_sPet_Name), "Raven");
					else if(StrEqual(g_sPet_Name[client], "Raven")) FormatEx(g_sPet_Name[client], sizeof(g_sPet_Name), "Snowy");
					else if(StrEqual(g_sPet_Name[client], "Snowy")) FormatEx(g_sPet_Name[client], sizeof(g_sPet_Name), "Spyro");
					else if(StrEqual(g_sPet_Name[client], "Spyro")) FormatEx(g_sPet_Name[client], sizeof(g_sPet_Name), "Ghosty");
					else if(StrEqual(g_sPet_Name[client], "Ghosty")) FormatEx(g_sPet_Name[client], sizeof(g_sPet_Name), "Storm");
					else if(StrEqual(g_sPet_Name[client], "Storm")) FormatEx(g_sPet_Name[client], sizeof(g_sPet_Name), "Ember");
					else if(StrEqual(g_sPet_Name[client], "Ember")) FormatEx(g_sPet_Name[client], sizeof(g_sPet_Name), "Warwick");
					else if(StrEqual(g_sPet_Name[client], "Warwick")) FormatEx(g_sPet_Name[client], sizeof(g_sPet_Name), "Luna");
				}
				else PetTalk(client);
				OpenPetMainMenu(client);
			}
			case 3: if (isSpawned) CycleModelSkin(client);
			case 4:
			{
				if (isSpawned)
				{
					PetAura_SetOrCycle(client);
					OpenPetMainMenu(client);
				}
			}
			case 5: if (isSpawned) OpenResizePetMenu(client);
			case 6: if (isSpawned) OpenPetEmoteMenu(client);
			case 7: if (isSpawned) OpenAbilitiesPetMenu(client);
			case 8: if (isSpawned) OpenTeleportPetMenu(client);
		}
	}
	return 0;
}

void PetTalk(int client)
{
	char phrases[][] =
	{
		"Hey boss, what's the plan?",
		"I'm right behind you!",
		"Don't worry, I've got your back.",
		"Is it just me, or are there more zombies today?",
		"I'm feeling extra brave right now!",
		"Let's show them what we can do.",
		"Need a hand? Or a paw?",
		"I'm happy to be here with you!",
		"Keep moving, I'm watching the rear.",
		"That was a close one, wasn't it?",
		"I think I smell a Special Infected nearby...",
		"Lead the way, I'll follow.",
		"You're doing great, survivor!",
		"Hope you brought some treats for later!",
		"Stay alert, stay alive.",
		"I'm ready for some action!",
		"Nice shot! You're getting better.",
		"Do you hear that? Something is coming.",
		"Whatever happens, we face it together.",
		"I'm glad you picked me to be your companion!",
		"I've survived worse than this.",
		"Stick close. Things get ugly fast.",
		"If it moves funny, shoot it.",
		"Something’s watching us.",
		"You lead, I protect.",
		"I’ll scream if I see a Tank.",
		"We move fast, we survive.",
		"Stay focused. We’re almost through.",
		"Watch out! I've got a bad feeling about this corner.",
        "You keep shooting, I'll keep scouting!",
        "Don't let them surround us, boss!",
        "I'll bite their ankles if they get too close.",
        "That's one less zombie to worry about. Nice work!",
        "If you see any snacks... you know who to share with.",
        "I’m small, but I’m fierce! Let’s go!",
        "Is that a Tank? Or just a very loud neighbor?",
        "Don't worry, I'm faster than I look.",
        "I'll bark if I see anything ugly. Which is... everything here.",
        "Keep your chin up, we're making it out of here.",
        "I've seen worse. Actually, no I haven't. Let's run!",
        "You're the best teammate I've ever had!",
        "My senses are tingling... stay sharp.",
        "I wonder if there are any other pets left in this city?",
        "Zero regrets being your partner. Let's finish this!",
        "Keep your eyes on the road, I'm watching the shadows.",
        "Wait, did you hear that? Sounded like a Witch...",
        "I'm not scared if you aren't scared!",
        "Let's show these monsters who really owns the streets!"
	};
	
	int random = GetRandomInt(0, sizeof(phrases) - 1);
	CPrintToChat(client, "{green}[%s]{default} %s", g_sPet_Name[client], phrases[random]);
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *													Spawn The Pet												   *
 *================================================================================================================ */

void SpawnPet(int client, char[] model)
{
	if(g_hTimer_MoveOut[client] != null)
	{
		OpenPetMainMenu(client);
		return;
	}
	
	g_iFollowTarget[client] = client;
	g_iPet_Entity[client] = CreatePropDynamic(client, model);
	
	SetPetAnimation(client, "Spawn");
	SetEntProp(g_iPet_Entity[client], Prop_Send, "m_iGlowType", 3);
	PetAura_SetOrCycle(client, g_sPet_Aura[client]);
	AdjustPetSize(client, "DEFAULT");
	
	float fDelay;
	if(StrEqual(g_sPet_Name[client], "Luna")) fDelay = 4.0;
	else if(StrEqual(g_sPet_Name[client], "Raven")) fDelay = 1.3;
	else if(StrEqual(g_sPet_Name[client], "Snowy")) fDelay = 1.2;
	else if(StrEqual(g_sPet_Name[client], "Spyro")) fDelay = 3.5;
	else if(StrEqual(g_sPet_Name[client], "Ghosty")) fDelay = 4.5;
	else if(StrEqual(g_sPet_Name[client], "Storm")) fDelay = 1.0;
	else if(StrEqual(g_sPet_Name[client], "Ember")) fDelay = 1.0;
	else if(StrEqual(g_sPet_Name[client], "Warwick")) fDelay = 2.0;
	
	g_hTimer_MoveIn[client] = CreateTimer(fDelay, Timer_Spawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	g_hTimer_CheckAutoAbilities[client] = CreateTimer(3.0, Timer_ActivateAutoAbilities, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	g_iPet_Entity[client] = EntIndexToEntRef(g_iPet_Entity[client]);
	
	CPrintToChat(client, "{Green}[Companion] {default}Hey, {blue}%s {default}is at your service!", g_sPet_Name[client]);
	
	// Return other pets to their owner if present
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i == client) continue;
		if(!IsClientInGame(i) || !IsPetValid(i)) continue;
		
		if(g_iFollowTarget[i] == client)
		{
			g_iFollowTarget[i] = i;
			TeleportPet(i);
		}
	}
}

Action Timer_Spawn(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client)) return Plugin_Handled;
	
	if (!IsPetValid(client))
	{
		g_hTimer_MoveIn[client] = null;
		return Plugin_Handled;
	}
	
	SetPetAnimation(client, "Idle");
	g_hTimer_MoveIn[client] = null;
	return Plugin_Handled;
}

void CycleModelSkin(int client)
{
	if(!IsPetValid(client)) { OpenPetMainMenu(client); return; }

	int ent = EntRefToEntIndex(g_iPet_Entity[client]);
	if(ent <= 0) { OpenPetMainMenu(client); return; }

	// Save pos/ang (so it looks like only skin changed)
	float pos[3], ang[3];
	GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", pos);
	GetEntPropVector(ent, Prop_Data, "m_angAbsRotation", ang);

	// Cycle: Type I -> Type II -> Type III -> Type I
	if(StrEqual(g_sPet_Skin[client], "Type I")) FormatEx(g_sPet_Skin[client], sizeof(g_sPet_Skin), "Type II");
	else if(StrEqual(g_sPet_Skin[client], "Type II")) FormatEx(g_sPet_Skin[client], sizeof(g_sPet_Skin), "Type III");
	else FormatEx(g_sPet_Skin[client], sizeof(g_sPet_Skin), "Type I");

	// Choose model by pet + skin
	char newModel[PLATFORM_MAX_PATH];

	// Luna
	if (StrEqual(g_sPet_Name[client], "Luna"))
	{
	    if (StrEqual(g_sPet_Skin[client], "Type I")) strcopy(newModel, sizeof(newModel), LUNA_DEFAULT_MODEL);
	    else if (StrEqual(g_sPet_Skin[client], "Type II")) strcopy(newModel, sizeof(newModel), LUNA_DAWN_MODEL);
	    else strcopy(newModel, sizeof(newModel), LUNA_SHADOW_MODEL);
	}
	
	// Raven
	else if (StrEqual(g_sPet_Name[client], "Raven"))
	{
	    if (StrEqual(g_sPet_Skin[client], "Type I")) strcopy(newModel, sizeof(newModel), RAVEN_DEFAULT_MODEL);
	    else if (StrEqual(g_sPet_Skin[client], "Type II")) strcopy(newModel, sizeof(newModel), RAVEN_NOXUS_MODEL);
	    else strcopy(newModel, sizeof(newModel), RAVEN_SNOWY_MODEL);
	}
	
	// Anivia
	else if (StrEqual(g_sPet_Name[client], "Snowy"))
	{
	    if (StrEqual(g_sPet_Skin[client], "Type I")) strcopy(newModel, sizeof(newModel), SNOWY_DEFAULT_MODEL);
	    else if (StrEqual(g_sPet_Skin[client], "Type II")) strcopy(newModel, sizeof(newModel), SNOWY_EAGLE_MODEL);
	    else strcopy(newModel, sizeof(newModel), SNOWY_HEXTECH_MODEL);
	}
	
	// Spyro
	else if (StrEqual(g_sPet_Name[client], "Spyro"))
	{
	    if (StrEqual(g_sPet_Skin[client], "Type I")) strcopy(newModel, sizeof(newModel), SPYRO_DEFAULT_MODEL);
	    else if (StrEqual(g_sPet_Skin[client], "Type II")) strcopy(newModel, sizeof(newModel), SPYRO_HEAVEN_MODEL);
	    else strcopy(newModel, sizeof(newModel), SPYRO_REINDEER_MODEL);
	}
	
	// Ghosty
	else if (StrEqual(g_sPet_Name[client], "Ghosty"))
	{
	    if (StrEqual(g_sPet_Skin[client], "Type I")) strcopy(newModel, sizeof(newModel), GHOSTY_DEFAULT_MODEL);
	    else if (StrEqual(g_sPet_Skin[client], "Type II")) strcopy(newModel, sizeof(newModel), GHOSTY_JANITOR_MODEL);
	    else strcopy(newModel, sizeof(newModel), GHOSTY_MOON_MODEL);
	}
	
	// Storm
	else if (StrEqual(g_sPet_Name[client], "Storm"))
	{
	    if (StrEqual(g_sPet_Skin[client], "Type I")) strcopy(newModel, sizeof(newModel), STORM_DEFAULT_MODEL);
	    else if (StrEqual(g_sPet_Skin[client], "Type II")) strcopy(newModel, sizeof(newModel), STORM_DEMON_MODEL);
	    else strcopy(newModel, sizeof(newModel), STORM_TIGER_MODEL);
	}
	
	// Ember
	else if (StrEqual(g_sPet_Name[client], "Ember"))
	{
	    if (StrEqual(g_sPet_Skin[client], "Type I")) strcopy(newModel, sizeof(newModel), EMBER_DEFAULT_MODEL);
	    else if (StrEqual(g_sPet_Skin[client], "Type II")) strcopy(newModel, sizeof(newModel), EMBER_CHOOCHOO_MODEL);
	    else strcopy(newModel, sizeof(newModel), EMBER_THUNDER_MODEL);
	}
	
	// Warwick
	else if (StrEqual(g_sPet_Name[client], "Warwick"))
	{
	    if (StrEqual(g_sPet_Skin[client], "Type I")) strcopy(newModel, sizeof(newModel), WARWICK_HUNTER_MODEL);
	    else if (StrEqual(g_sPet_Skin[client], "Type II")) strcopy(newModel, sizeof(newModel), WARWICK_FIREFANG_MODEL);
	    else strcopy(newModel, sizeof(newModel), WARWICK_BIGBAD_MODEL);
	}

	// Instant swap (no animation)
	SetEntityModel(ent, newModel);

	// Restore pos/ang (prevents snapping)
	TeleportEntity(ent, pos, ang, NULL_VECTOR);

	// Keep aura
	SetEntProp(ent, Prop_Send, "m_iGlowType", 3);
	PetAura_SetOrCycle(client, g_sPet_Aura[client]);
	SetPetAnimation(client, "Idle");

	// Keep size
	float scale = StringToFloat(g_sPet_Size[client]);
	if(scale > 0.0) SetEntPropFloat(ent, Prop_Send, "m_flModelScale", scale);

	OpenPetMainMenu(client);
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *													Menu Dance													   *
 *================================================================================================================ */

void OpenPetEmoteMenu(int client)
{
	Menu menu = new Menu(Handle_PetDanceMenu);
	
	if(StrEqual(g_sPet_Name[client], "Luna"))
	{
		menu.SetTitle("Select A Move:");
		menu.AddItem("MOVE1", "Shadow Groove");
		menu.AddItem("MOVE2", "Gloom Strut");
		menu.AddItem("MOVE3", "Fade Away");
		menu.AddItem("MOVE4", "Apathy State");
		menu.AddItem("MOVE5", "Dark Return");
		menu.AddItem("MOVE6", "Rise Again");
		menu.AddItem("MOVE7", "Final Silence");
	}
	
	else if(StrEqual(g_sPet_Name[client], "Raven"))
	{
		menu.SetTitle("Select A Move:");
		menu.AddItem("MOVE1", "Hammer Groove");
		menu.AddItem("MOVE2", "Battle Taunt");
		menu.AddItem("MOVE3", "Giggle Break");
		menu.AddItem("MOVE4", "Bouncy Shuffle");
		menu.AddItem("MOVE5", "Scout Stance!");
		menu.AddItem("MOVE6", "Hammer Windup");
		menu.AddItem("MOVE7", "Fallen Hero");
	}
	
	else if(StrEqual(g_sPet_Name[client], "Snowy"))
	{
		menu.SetTitle("Select A Move:");
		menu.AddItem("MOVE1", "Frost Waltz");
		menu.AddItem("MOVE2", "Icebound Taunt");
		menu.AddItem("MOVE3", "Glacial Chuckle");
		menu.AddItem("MOVE4", "Cold Strut");
		menu.AddItem("MOVE5", "Crystal Flip");
		menu.AddItem("MOVE6", "Wing Frost Slash");
		menu.AddItem("MOVE7", "Shatterfall");
	}
	
	else if(StrEqual(g_sPet_Name[client], "Spyro"))
	{
		menu.SetTitle("Select A Move:");
		menu.AddItem("MOVE1", "Flame Groove");
		menu.AddItem("MOVE2", "Dragon Prance");
		menu.AddItem("MOVE3", "Spark Giggle");
		menu.AddItem("MOVE4", "Playful Pounce");
		menu.AddItem("MOVE5", "Tumble Crash");
		menu.AddItem("MOVE6", "Wing Wiggle");
		menu.AddItem("MOVE7", "Dragon Down");
	}
	
	else if(StrEqual(g_sPet_Name[client], "Ghosty"))
	{
		menu.SetTitle("Select A Move:");
		menu.AddItem("MOVE1", "Soul Dance");
		menu.AddItem("MOVE2", "Chain Taunt");
		menu.AddItem("MOVE3", "Grim Laugh");
		menu.AddItem("MOVE4", "Rage Stir");
		menu.AddItem("MOVE5", "Chain Jab");
		menu.AddItem("MOVE6", "Soul Cleaver");
		menu.AddItem("MOVE7", "Soul Released");
	}
	
	else if(StrEqual(g_sPet_Name[client], "Storm"))
	{
		menu.SetTitle("Select A Move:");
		menu.AddItem("MOVE1", "Thunder Stomp");
		menu.AddItem("MOVE2", "Storm Roar");
		menu.AddItem("MOVE3", "War Taunt");
		menu.AddItem("MOVE4", "Bear Laugh");
		menu.AddItem("MOVE5", "Storm Recall");
		menu.AddItem("MOVE6", "Savage Maul");
		menu.AddItem("MOVE7", "Thunder Fall");
	}
	
	else if(StrEqual(g_sPet_Name[client], "Ember"))
	{
		menu.SetTitle("Select A Move:");
		menu.AddItem("MOVE1", "Forge Step");
		menu.AddItem("MOVE2", "Ember Taunt");
		menu.AddItem("MOVE3", "Ash Laugh");
		menu.AddItem("MOVE4", "Iron Mock");
		menu.AddItem("MOVE5", "Master Forge");
		menu.AddItem("MOVE6", "Hammer Strike");
		menu.AddItem("MOVE7", "Ashen Fall");
	}
	
	else if(StrEqual(g_sPet_Name[client], "Warwick"))
	{
		menu.SetTitle("Select A Move:");
		menu.AddItem("MOVE1", "Blood Rage");
		menu.AddItem("MOVE2", "Moon Howl");
		menu.AddItem("MOVE3", "Hunt Scent");
		menu.AddItem("MOVE4", "Curious Pup");
		menu.AddItem("MOVE5", "Maniac Chuckle");
		menu.AddItem("MOVE6", "Savage Strike");
		menu.AddItem("MOVE7", "Final Hunt");
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_PetDanceMenu(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char item[64];
		menu.GetItem(select, item, sizeof(item));
		
		if (!IsPetValid(client)) return 0;
		
		if (StrEqual(item, "MOVE1")) SetPetAnimation(client, "Move 1");
		else if (StrEqual(item, "MOVE2")) SetPetAnimation(client, "Move 2");
		else if (StrEqual(item, "MOVE3")) SetPetAnimation(client, "Move 3");
		else if (StrEqual(item, "MOVE4")) SetPetAnimation(client, "Move 4");
		else if (StrEqual(item, "MOVE5")) SetPetAnimation(client, "Move 5");
		else if (StrEqual(item, "MOVE6")) SetPetAnimation(client, "Move 6");
		else if (StrEqual(item, "MOVE7")) SetPetAnimation(client, "Move 7");
		OpenPetEmoteMenu(client);
	}
	else if(action == MenuAction_Cancel && select == MenuCancel_ExitBack) OpenPetMainMenu(client);
	else if(action == MenuAction_End) delete menu;
	return 0;
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *													Menu Aura													   *
 *================================================================================================================ */

void PetAura_SetOrCycle(int client, const char[] color = "")
{
	if (!IsPetValid(client)) return;
	
	// Both arrays MUST be the same size (22 entries)
	static const char names[22][16] =
	{
		"Disable", "White", "Gray", "Red", "Crimson", 
		"Coral", "Peach", "Orange", "Gold", "Yellow", 
		"Lime", "Green", "Mint", "Cyan", "Sky", 
		"Blue", "Navy", "Purple", "Violet", "Lavender", 
		"Pink", "Rose"
	};
	
	static const int rgb[22] = 
	{
		-1,                                 // 0 - Disable
		255 | (255<<8) | (255<<16),         // 1 - White
		80  | (80<<8)  | (80<<16),          // 2 - Gray
		255 | (0<<8)   | (0<<16),           // 3 - Red
		139 | (0<<8)   | (0<<16),           // 4 - Crimson
		255 | (60<<8)  | (20<<16),          // 5 - Coral (Red-Orange)
		255 | (180<<8) | (140<<16),         // 6 - Peach (Skin tone)
		255 | (120<<8) | (0<<16),           // 7 - Orange (Pure)
		218 | (165<<8) | (32<<16),          // 8 - Gold (Darker/Amber)
		255 | (255<<8) | (0<<16),           // 9 - Yellow (Neon)
		120 | (255<<8) | (0<<16),           // 10 - Lime (Yellow-Green)
		0   | (128<<8) | (0<<16),           // 11 - Green (Forest)
		0   | (255<<8) | (150<<16),         // 12 - Mint (Blue-Green)
		0   | (255<<8) | (255<<16),         // 13 - Cyan
		135 | (206<<8) | (250<<16),         // 14 - Sky
		0   | (0<<8)   | (255<<16),         // 15 - Blue
		0   | (0<<8)   | (100<<16),         // 16 - Navy
		128 | (0<<8)   | (128<<16),         // 17 - Purple
		238 | (130<<8) | (238<<16),         // 18 - Violet (Bright)
		180 | (150<<8) | (255<<16),         // 19 - Lavender (Soft)
		255 | (50<<8)  | (150<<16),         // 20 - Pink (Hot Pink)
		255 | (0<<8)   | (100<<16)          // 21 - Rose (Deep Pinkish-Red)
	};
	
	if (g_sPet_Aura[client][0] == '\0')
		strcopy(g_sPet_Aura[client], 32, "Disable");
	
	int idx = 0;
	
	if (color[0] == '\0')
	{
		for (int i = 0; i < 22; i++)
		{
			if (StrEqual(g_sPet_Aura[client], names[i], false))
			{
				idx = i;
				break;
			}
		}
		
		idx++;
		if (idx >= 22) idx = 0;
	}
	else
	{
		for (int i = 0; i < 22; i++)
		{
			if (StrEqual(color, names[i], false))
			{
				idx = i;
				break;
			}
		}
	}
	
	// Save name
	strcopy(g_sPet_Aura[client], 32, names[idx]);
	
	// Apply
	if (idx == 0 || rgb[idx] == -1) SetEntProp(g_iPet_Entity[client], Prop_Send, "m_iGlowType", 0);
	else
	{
		SetEntProp(g_iPet_Entity[client], Prop_Send, "m_iGlowType", 3);
		SetEntProp(g_iPet_Entity[client], Prop_Send, "m_glowColorOverride", rgb[idx]);
	}
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *													Menu Resize Pets											   *
 *================================================================================================================ */

void OpenResizePetMenu(int client)
{
	Menu menu = new Menu(Handle_ResizePetMenu);
	menu.SetTitle("Scale Your Companion:");
	menu.AddItem("DEFAULT", "Default");
	menu.AddItem("INCREASE", "Increase");
	menu.AddItem("DECREASE", "Decrease");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_ResizePetMenu(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char item[64];
		menu.GetItem(select, item, sizeof(item));
		
		if (!IsPetValid(client)) return 0;
		else if(StrEqual(item, "DEFAULT") || StrEqual(item, "INCREASE") || StrEqual(item, "DECREASE"))
		{
			AdjustPetSize(client, item);
			OpenResizePetMenu(client);
		}
		
	}
	else if(action == MenuAction_Cancel && select == MenuCancel_ExitBack) OpenPetMainMenu(client);
	else if(action == MenuAction_End) delete menu;
	return 0;
}

void AdjustPetSize(int client, const char[] action)
{
	if(!IsPetValid(client)) return;

	float size = StringToFloat(g_sPet_Size[client]);
	float base = 1.00, step = 0.10;

	if(StrEqual(g_sPet_Name[client], "Luna")) { base = 0.30; step = 0.030; }
	else if(StrEqual(g_sPet_Name[client], "Raven")) { base = 0.20; step = 0.020; }
	else if(StrEqual(g_sPet_Name[client], "Snowy")) { base = 0.40; step = 0.035; }
	else if(StrEqual(g_sPet_Name[client], "Spyro")) { base = 0.20; step = 0.025; }
	else if(StrEqual(g_sPet_Name[client], "Ghosty")) { base = 0.30; step = 0.120; }
	else if(StrEqual(g_sPet_Name[client], "Storm")) { base = 0.20; step = 0.020; }
	else if(StrEqual(g_sPet_Name[client], "Ember")) { base = 0.20; step = 0.020; }
	else if(StrEqual(g_sPet_Name[client], "Warwick")) { base = 0.20; step = 0.020; }

	if(size <= 0.0) size = base;

	if(StrEqual(action, "DEFAULT")) size = base;
	else if(StrEqual(action, "INCREASE")) size += step;
	else if(StrEqual(action, "DECREASE")) size -= step;

	float min = base - (step * 4.0);
	float max = base + (step * 4.0);

	if(size < min) size = min;
	if(size > max) size = max;

	FormatEx(g_sPet_Size[client], sizeof(g_sPet_Size[]), "%.3f", size);

	int ent = EntRefToEntIndex(g_iPet_Entity[client]);
	if(ent > 0) SetEntPropFloat(ent, Prop_Send, "m_flModelScale", size);
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *													Menu Ability Pets											   *
 *================================================================================================================ */

void OpenAbilitiesPetMenu(int client)
{
	Menu menu = new Menu(Handle_AbilitiesPetMenu);
	
	menu.SetTitle("Companion Abilities:");
	if (g_iHealing_Cooldown[client] != 0 && (g_iHealing_Cooldown[client] + g_iPet_HealCooldown > GetTime()))
	{
		int timeleft = g_iHealing_Cooldown[client] - GetTime() + g_iPet_HealCooldown;
		char sBuffer[64];
		FormatEx(sBuffer, sizeof(sBuffer), "Healing Spell: %is", timeleft);
		menu.AddItem("HEAL", sBuffer, IsPetValid(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	else menu.AddItem("HEAL", "Healing Spell", IsPetValid(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	if (g_iAntiPuke_Cooldown[client] != 0 && (g_iAntiPuke_Cooldown[client] + g_iPet_AntiPukeCooldown > GetTime()))
	{
		int timeleft = g_iAntiPuke_Cooldown[client] - GetTime() + g_iPet_AntiPukeCooldown;
		char sBuffer[64];
		FormatEx(sBuffer, sizeof(sBuffer), "Anti-Puke Spell: %is", timeleft);
		menu.AddItem("ANTIPUKE", sBuffer, IsPetValid(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	else menu.AddItem("ANTIPUKE", "Anti-Puke Spell", IsPetValid(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	if (g_iRevive_Cooldown[client] != 0 && (g_iRevive_Cooldown[client] + g_iPet_ReviveCooldown > GetTime()))
	{
		int timeleft = g_iRevive_Cooldown[client] - GetTime() + g_iPet_ReviveCooldown;
		char sBuffer[64];
		FormatEx(sBuffer, sizeof(sBuffer), "Reviving Spell: %is", timeleft);
		menu.AddItem("REVIVE", sBuffer, IsPetValid(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	else menu.AddItem("REVIVE", "Reviving Spell", IsPetValid(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	if (g_iAmmoRefill_Cooldown[client] != 0 && (g_iAmmoRefill_Cooldown[client] + g_iPet_AmmoRefillCooldown > GetTime()))
	{
		int timeleft = g_iAmmoRefill_Cooldown[client] - GetTime() + g_iPet_AmmoRefillCooldown;
		char sBuffer[64];
		FormatEx(sBuffer, sizeof(sBuffer), "Max Ammo: %is", timeleft);
		menu.AddItem("AMMO", sBuffer, IsPetValid(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	else menu.AddItem("AMMO", "Max Ammo", IsPetValid(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	if (g_iAdrenBoost_Cooldown[client] != 0 && (g_iAdrenBoost_Cooldown[client] + g_iPet_AdrenBoostCooldown > GetTime()))
	{
		int timeleft = g_iAdrenBoost_Cooldown[client] - GetTime() + g_iPet_AdrenBoostCooldown;
		char sBuffer[64];
		FormatEx(sBuffer, sizeof(sBuffer), "Adrenaline Boost: %is", timeleft);
		menu.AddItem("ADREN", sBuffer, IsPetValid(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	else menu.AddItem("ADREN", "Adrenaline Boost", IsPetValid(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	menu.AddItem("AUTO", "Auto Abilities Setting", IsPetValid(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_AbilitiesPetMenu(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char item[64];
		menu.GetItem(select, item, sizeof(item));
		
		if (!IsPetValid(client)) return 0;
		
		if (StrEqual(item, "HEAL") && !IsAbilityOnCooldown(client, "Health")) ActivateEnergyAbilities(client, "Health", true);
		if (StrEqual(item, "ANTIPUKE") && !IsAbilityOnCooldown(client, "Anti-Puke")) ActivateEnergyAbilities(client, "Anti-Puke", true);
		if (StrEqual(item, "REVIVE") && !IsAbilityOnCooldown(client, "Revive")) RevivePlayer(client, true);
		if (StrEqual(item, "AMMO") && !IsAbilityOnCooldown(client, "Ammo")) TransferAmmoToPlayer(client, true);
		if (StrEqual(item, "ADREN") && !IsAbilityOnCooldown(client, "Adrenaline")) GiveAdrenalineboost(client, true);
		if (StrEqual(item, "AUTO"))
		{
			OpenAutoAbilitiesMenu(client);
			return 0;
		}

		OpenAbilitiesPetMenu(client);
	}
	else if(action == MenuAction_Cancel && select == MenuCancel_ExitBack) OpenPetMainMenu(client);
	else if(action == MenuAction_End) delete menu;
	return 0;
}

void OpenAutoAbilitiesMenu(int client)
{
	Menu menu = new Menu(Handle_AutoAbilitiesMenu);
	menu.SetTitle("Auto Abilities:");
	
	char sBuffer[64];
	FormatEx(sBuffer, sizeof(sBuffer), "Healing Spell: %s", g_bAutoHeal[client] ? "Auto" : "None");
	menu.AddItem("AUTO_HEAL", sBuffer);
	
	FormatEx(sBuffer, sizeof(sBuffer), "Anti-Puke: %s", g_bAutoAntiPuke[client] ? "Auto" : "None");
	menu.AddItem("AUTO_ANTIPUKE", sBuffer);
	
	FormatEx(sBuffer, sizeof(sBuffer), "Revive: %s", g_bAutoRevive[client] ? "Auto" : "None");
	menu.AddItem("AUTO_REVIVE", sBuffer);
	
	FormatEx(sBuffer, sizeof(sBuffer), "Max Ammo: %s", g_bAutoAmmo[client] ? "Auto" : "None");
	menu.AddItem("AUTO_AMMO", sBuffer);
	
	FormatEx(sBuffer, sizeof(sBuffer), "Adrenaline Boost: %s", g_bAutoAdren[client] ? "Auto" : "None");
	menu.AddItem("AUTO_ADREN", sBuffer);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_AutoAbilitiesMenu(Menu menu, MenuAction action, int client, int iItem)
{
	if (action == MenuAction_Select)
	{
		char sId[32];
		menu.GetItem(iItem, sId, sizeof(sId));
		
		if (StrEqual(sId, "AUTO_HEAL"))
		{
			g_bAutoHeal[client] = !g_bAutoHeal[client];
			if(GetClientHealth(client) + L4D_GetTempHealth(client) <= GetEntProp(client, Prop_Send, "m_iMaxHealth") - g_iPet_HealAmount)
				if(!IsAbilityOnCooldown(client, "Health")) ActivateEnergyAbilities(client, "Health", false);
		}
		else if (StrEqual(sId, "AUTO_ANTIPUKE"))
		{
			g_bAutoAntiPuke[client] = !g_bAutoAntiPuke[client];
			if(g_iPlayerOnVomit[client] == 1 && !IsAbilityOnCooldown(client, "Anti-Puke"))
				ActivateEnergyAbilities(client, "Anti-Puke", false);
		}
		else if (StrEqual(sId, "AUTO_REVIVE")) g_bAutoRevive[client] = !g_bAutoRevive[client];
		else if (StrEqual(sId, "AUTO_AMMO"))
		{
			g_bAutoAmmo[client] = !g_bAutoAmmo[client];
			if (!IsAbilityOnCooldown(client, "Adrenaline"))
				GiveAdrenalineboost(client, false);
		}
		else if (StrEqual(sId, "AUTO_ADREN")) g_bAutoAdren[client] = !g_bAutoAdren[client];
		
		OpenAutoAbilitiesMenu(client);
	}
	else if (action == MenuAction_Cancel && iItem == MenuCancel_ExitBack) OpenAbilitiesPetMenu(client);
	else if (action == MenuAction_End) delete menu;
	return 0;
}

void ActivateEnergyAbilities(int client, const char[] sAbility, bool bShowText)
{
	if (!IsPetValid(client)) return;
	
	if (!IsFollowTargetNear(client))
	{
		if (bShowText) CPrintToChat(client, "{green}[Companion]{default} Get closer to your ally before using this ability.");
		return;
	}
	
	float vPetOrigin[3];
	GetEntPropVector(g_iPet_Entity[client], Prop_Data, "m_vecOrigin", vPetOrigin);
	
	int iAbilityHitType = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsPlayerIncapacitated(i) || GetClientTeam(i) != L4D2Team_Survivor) continue;
		
		float vTargetPos[3];
		GetClientAbsOrigin(i, vTargetPos);
		if (GetVectorDistance(vTargetPos, vPetOrigin) > 250.0) continue;
		
		if (StrEqual(sAbility, "Health"))
		{
			HealClient(i);
			ScreenFade(i, 192, 238, 39, 140, 600, 1);
			iAbilityHitType = 1;
		}
		else if (StrEqual(sAbility, "Anti-Puke"))
		{
			L4D_OnITExpired(i);
			ScreenFade(i, 0, 0, 0, 100, 600, 1);
			iAbilityHitType = 2;
		}
	}
	
	if (!iAbilityHitType) return;
	
	float vRingPosition[3];
	vRingPosition[0] = vPetOrigin[0];
	vRingPosition[1] = vPetOrigin[1];
	vRingPosition[2] = vPetOrigin[2] + 20.0;
	
	if (iAbilityHitType == 1) TE_SetupBeamRingPoint(vRingPosition, 10.0, 250.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.3, 10.0, 0.5, {192,238,39,230}, 400, 0);
	else TE_SetupBeamRingPoint(vRingPosition, 10.0, 250.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.3, 10.0, 0.5, {255,255,255,200}, 400, 0);
	
	TE_SendToAll();
	EmitAmbientSound(HEALTH_SOUND, vRingPosition, SOUND_FROM_WORLD, SNDLEVEL_RAIDSIREN);
	
	if (iAbilityHitType == 1) g_iHealing_Cooldown[client] = GetTime();
	else g_iAntiPuke_Cooldown[client] = GetTime();
}

void HealClient(int client)
{
	if(!IsPlayerAlive(client) || GetClientTeam(client) != L4D2Team_Survivor || IsPlayerIncapacitated(client))
		return;
	
	int iHealth = GetClientHealth(client);
	int iMaxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
	float fHealth = L4D_GetTempHealth(client);
	
	iHealth += g_iPet_HealAmount;
	if(iHealth >= iMaxHealth)
	{
		iHealth = iMaxHealth;
		L4D_SetTempHealth(client, 0.0);
	}
	else if(iHealth + fHealth >= iMaxHealth) L4D_SetTempHealth(client, float(iMaxHealth - iHealth));
	if(iHealth <= iMaxHealth) SetEntityHealth(client, iHealth);
}

void RevivePlayer(int client, bool bShowText)
{
	int target = g_iFollowTarget[client];
	if (!CanAutoRevive(client, target, bShowText, false))
	{
		g_bReviveInProgress[client] = false;
		return;
	}
	
	if(!IsFollowTargetNear(client))
	{
		if (bShowText)
		{
			if (target == client) CPrintToChat(client, "{green}[Companion]{default} Wait, I'm coming for you!");
			else CPrintToChat(client, "{green}[Companion]{default} I'm going to revive {blue}%N{default}.", target);
		}
		g_bReviveInProgress[client] = true;
		return;
	}
	
	g_bReviveInProgress[client] = true;
	BeginAutoRevive(client, target);
}

void BeginAutoRevive(int client, int target)
{
	if (g_bPetReviveActive[client]) return;
	
	g_bPetPaused[client]       = false;
	g_bPetReviveActive[client] = true;
	SetupProgressBar(client, target);
}

void SetupProgressBar(int client, int target)
{
	if (g_fSetupProgressTime[client] > 0.0) return;
	
	g_bReviveInProgress[client] = true;
	g_fSetupProgressTime[client] = 5.0;
	
	SetEntPropFloat(target, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(target, Prop_Send, "m_flProgressBarDuration", g_fSetupProgressTime[client]);
	SetEntPropEnt(target, Prop_Send, "m_reviveOwner", client);
	
	SetPetAnimation(client, "Revive");
	
	if (IsValidEntity(target) && IsClientInGame(target))
		SetEntityMoveType(target, MOVETYPE_NONE);
	
	if (g_hTimer_ReviveCheck[client] != null)
	{
		KillTimer(g_hTimer_ReviveCheck[client]);
		g_hTimer_ReviveCheck[client] = null;
	}
	
	DataPack dPack = new DataPack();
	dPack.WriteCell(GetClientUserId(client));
	dPack.WriteCell(GetClientUserId(target));
	g_hTimer_ReviveCheck[client] = CreateTimer(PET_MOVE_INTERVAL, Timer_ReviveCheck, dPack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

Action Timer_ReviveCheck(Handle timer, DataPack dPack)
{
	dPack.Reset();
	int client_userid  = dPack.ReadCell();
	int target_userid = dPack.ReadCell();
	
	int client  = GetClientOfUserId(client_userid);
	int target = GetClientOfUserId(target_userid);
	
	if (!client || !IsClientInGame(client) || !IsPetValid(client))
	{
		delete dPack;
		return Plugin_Stop;
	}
	
	if (!target || !IsClientInGame(target) || GetClientTeam(target) != L4D2Team_Survivor)
	{
		KillProgressBar(client, target);
		delete dPack;
		return Plugin_Stop;
	}
	
	if (!g_bPetReviveActive[client] || !CanAutoRevive(client, target, false, true))
	{
		KillProgressBar(client, target);
		delete dPack;
		return Plugin_Stop;
	}
	
	if (g_fSetupProgressTime[client] > 0.4)
	{
		g_fSetupProgressTime[client] -= 0.1;
		return Plugin_Continue;
	}
	
	g_iRevive_Cooldown[client] = GetTime();
	L4D_ReviveSurvivor(target);
	KillProgressBar(client, target);
	
	delete dPack;
	return Plugin_Stop;
}

void KillProgressBar(int client, int target)
{
	g_bReviveInProgress[client] = false;
	g_bPetReviveActive[client]  = false;
	g_fSetupProgressTime[client] = 0.0;
	
	if (IsClientInGame(target))
	{
		SetEntPropFloat(target, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat(target, Prop_Send, "m_flProgressBarDuration", g_fSetupProgressTime[client]);
		SetEntPropEnt(target,  Prop_Send, "m_reviveOwner", -1);
		
		if (GetClientTeam(target) == L4D2Team_Survivor)
			SetEntityMoveType(target, MOVETYPE_WALK);
	}
	
	SetPetAnimation(client, "Idle");
	
	if (g_hTimer_ReviveCheck[client] != null)
	{
		KillTimer(g_hTimer_ReviveCheck[client]);
		g_hTimer_ReviveCheck[client] = null;
	}
}

bool CanAutoRevive(int client, int target, bool bShowText, bool reviving)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || !IsPetValid(client) || GetClientTeam(client) != L4D2Team_Survivor) return false;
	if (!IsClientInGame(target) || !IsPlayerAlive(target) || GetClientTeam(target) != L4D2Team_Survivor) return false;
	
	if (!IsPlayerIncapacitated(target))
	{
		if (bShowText)
		{
			if (target == client) CPrintToChat(client, "{green}[Companion]{default} You are not incapacitated!");
			else CPrintToChat(client, "{green}[Companion]{default} {blue}%N{default} is not incapacitated!", target);
		}
		return false;
	}
	
	if (IsPlayerGrabbed(target))
	{
		if (bShowText)
		{
			if (target == client) CPrintToChat(client, "{green}[Companion]{default} I can't revive while you're being held!");
			else CPrintToChat(client, "{green}[Companion]{default} I can't revive {blue}%N{default} while they are being held!", target);
		}
		return false;
	}
	
	if (g_bTeammate_Reviving[target])
	{
		if (bShowText)
		{
			if (target == client) CPrintToChat(client, "{green}[Companion]{default} Your teammate is reviving you!");
			else CPrintToChat(client, "{green}[Companion]{default} A teammate is reviving {blue}%N{default}!", target);
		}
		return false;
	}
	
	if (!reviving && g_fSetupProgressTime[client] > 0.0) return false;
	return true;
}

void GiveAdrenalineboost(int client, bool bShowText)
{
	int target = g_iFollowTarget[client];
	if (GetClientTeam(target) != L4D2Team_Survivor || !IsPlayerAlive(target) || IsPlayerIncapacitated(target) || IsPlayerGrabbed(target))
	{
		if(bShowText) CPrintToChat(client, "{green}[Companion]{default} Your companion can't use this ability at this moment!");
		return;
	}
	
	if(!IsFollowTargetNear(client))
	{
		if(bShowText) CPrintToChat(client, "{green}[Companion]{default} Your companion needs to be close!");
		return;
	}
	
	L4D2_UseAdrenaline(target, g_Cvar_Server_Adren_Duration.FloatValue, true);
	ScreenFade(target, 255, 180, 50, 50, RoundToZero(0.6 * 1000.0), 1);
	g_iAdrenBoost_Cooldown[client] = GetTime();
}

void TransferAmmoToPlayer(int client, bool bShowText)
{
	int target = g_iFollowTarget[client];
	if (GetClientTeam(target) != L4D2Team_Survivor || !IsPlayerAlive(target) || IsPlayerIncapacitated(target) || IsPlayerGrabbed(target))
	{
		if(bShowText) CPrintToChat(client, "{green}[Companion]{default} Your companion can't resupply ammo right now!");
		return;
	}
	
	if(!IsFollowTargetNear(client))
	{
		if(bShowText) CPrintToChat(client, "{green}[Companion]{default} Your companion needs to be close!");
		return;
	}
	
	int iPrimary = GetPlayerWeaponSlot(target, 0);
	if (!IsValidEntity(iPrimary) || !IsValidEdict(iPrimary))
	{
		if(bShowText) CPrintToChat(client, "{green}[Companion]{default} No primary weapon found to refill!");
		return;
	}
	
	GiveFullAmmo(target, true, false);
}

void GiveFullAmmo(int client, bool bKeepUpgrade = true, bool bSuppressSound = true)
{
	int iWeapon = GetPlayerWeaponSlot(client, 0);
	if (iWeapon == -1 || !IsValidEntity(iWeapon)) return;
	
	char sClassname[64];
	GetEdictClassname(iWeapon, sClassname, sizeof(sClassname));
	
	bool bIsM60 = StrEqual(sClassname, "weapon_rifle_m60");
	bool bIsGrenadeLauncher = StrEqual(sClassname, "weapon_grenade_launcher");
	
	if (bIsM60 || bIsGrenadeLauncher)
	{
		int iMaxClip = GetMaxClip(iWeapon);
		if (iMaxClip <= 0) iMaxClip = 1;
		
		SetEntProp(iWeapon, Prop_Send, "m_iClip1", iMaxClip);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);
		return;
	}
	
	int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	if (iAmmoType != -1) GivePlayerAmmo(client, 999, iAmmoType, bSuppressSound);
	
	int iMaxClip = GetMaxClip(iWeapon);
	if (iMaxClip <= 0) iMaxClip = 30;
	
	int iUpgradedLoaded = 0;
	if (bKeepUpgrade && HasEntProp(iWeapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded")) iUpgradedLoaded = GetEntProp(iWeapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
	
	if (iUpgradedLoaded > 0)
	{
		if (iUpgradedLoaded > iMaxClip) iUpgradedLoaded = iMaxClip;
		SetEntProp(iWeapon, Prop_Send, "m_iClip1", iUpgradedLoaded);
	}
	else SetEntProp(iWeapon, Prop_Send, "m_iClip1", iMaxClip);
	
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);
	SetEntPropFloat(iWeapon, Prop_Data, "m_flNextPrimaryAttack", GetGameTime());
	
	ScreenFade(client, 100, 255, 255, 50, RoundToZero(0.6 * 1000.0), 1);
	g_iAmmoRefill_Cooldown[client] = GetTime();
}

int GetMaxClip(int iWeapon)
{
	int iAmmo;
	static char sClass[32];
	GetEdictClassname(iWeapon, sClass, sizeof(sClass));

	iAmmo = L4D2_GetIntWeaponAttribute(sClass, L4D2IWA_ClipSize);
	return iAmmo;
}

bool IsAbilityOnCooldown(int client, const char[] sAbility)
{
	int iNow = GetTime();
	if (StrEqual(sAbility, "Health")) return (g_iHealing_Cooldown[client] != 0 && (g_iHealing_Cooldown[client] + g_iPet_HealCooldown > iNow));
	else if (StrEqual(sAbility, "Anti-Puke")) return (g_iAntiPuke_Cooldown[client] != 0 && (g_iAntiPuke_Cooldown[client] + g_iPet_AntiPukeCooldown > iNow));
	else if (StrEqual(sAbility, "Revive")) return (g_iRevive_Cooldown[client] != 0 && (g_iRevive_Cooldown[client] + g_iPet_ReviveCooldown > iNow));
	else if (StrEqual(sAbility, "Ammo")) return (g_iAmmoRefill_Cooldown[client] != 0 && (g_iAmmoRefill_Cooldown[client] + g_iPet_AmmoRefillCooldown > iNow));
	else if (StrEqual(sAbility, "Adrenaline")) return (g_iAdrenBoost_Cooldown[client] != 0 && (g_iAdrenBoost_Cooldown[client] + g_iPet_AdrenBoostCooldown > iNow));
	return false;
}

Action Timer_ActivateAutoAbilities(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsPetValid(client))
	{
		g_hTimer_CheckAutoAbilities[client] = null;
		return Plugin_Stop;
	}
	
	if (g_bAutoHeal[client] && !IsAbilityOnCooldown(client, "Health"))
	{
		if(GetClientHealth(client) + L4D_GetTempHealth(client) <= GetEntProp(client, Prop_Send, "m_iMaxHealth") - g_iPet_HealAmount)
			ActivateEnergyAbilities(client, "Health", false);
	}
	
	if (g_bAutoAntiPuke[client] && g_iPlayerOnVomit[client] == 1 && !IsAbilityOnCooldown(client, "Anti-Puke")) ActivateEnergyAbilities(client, "Anti-Puke", false);
	if (g_bAutoRevive[client] && !IsAbilityOnCooldown(client, "Revive")) RevivePlayer(client, false);
	if (g_bAutoAdren[client] && !IsAbilityOnCooldown(client, "Adrenaline")) GiveAdrenalineboost(client, false);
	if (g_bAutoAmmo[client] && !IsAbilityOnCooldown(client, "Ammo"))
	{
		int target = g_iFollowTarget[client];
		if (!IsClientInGame(target) || !IsPlayerAlive(target)) target = client;
		
		int iWeapon = GetPlayerWeaponSlot(target, 0);
		if (iWeapon == -1 || !IsValidEntity(iWeapon)) return Plugin_Continue;
		
		int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
		
		if (iAmmoType != -1)
		{
			int iReserve = GetEntProp(target, Prop_Send, "m_iAmmo", _, iAmmoType);
			if (iReserve > 0) return Plugin_Continue;
		}
	
		TransferAmmoToPlayer(target, false);
	}
	
	return Plugin_Continue;
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *													Spawn The Pet												   *
 *================================================================================================================ */

void OpenTeleportPetMenu(int client)
{
	Menu menu = new Menu(Handle_TeleportPetMenu);
	menu.SetTitle("Teleport Companion To:");
	
	char sInfo[255];
	char sPosition[32];
	char sUserID[10];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != L4D2Team_Survivor || !IsPetValid(client)) continue;
		
		if(!IsPlayerAlive(i)) FormatEx(sPosition, sizeof(sPosition), "Dead");
		else if (IsPlayerIncapacitated(i) && !IsPlayerGrabbed(i)) FormatEx(sPosition, sizeof(sPosition), "Incapped");
		else if (IsHandingFromLedge(i)) FormatEx(sPosition, sizeof(sPosition), "Hanging");
		else if (IsPlayerGrabbed(i)) FormatEx(sPosition, sizeof(sPosition), "Held By Infected");
		else FormatEx(sPosition, sizeof(sPosition), "Standing");
		
		FormatEx(sInfo, sizeof(sInfo), "%N - %s", i, sPosition);
		IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
		menu.AddItem(sUserID, sInfo);
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Handle_TeleportPetMenu(Menu menu, MenuAction action, int client, int select)
{
	if (action == MenuAction_Select)
	{
		char sUserID[12];
		menu.GetItem(select, sUserID, sizeof(sUserID));
		int target = GetClientOfUserId(StringToInt(sUserID));
		
		if(!IsPetValid(client))
		{
			CPrintToChat(client, "{green}[Companion]{default} You have no pet.");
			OpenPetMainMenu(client);
			return 0;
		}
		
		if (!target || !IsClientInGame(target) || GetClientTeam(target) != L4D2Team_Survivor) return 0;
		
		if (!IsPlayerAlive(target))
		{
			CPrintToChat(client, "{green}[Companion]{default} %N is dead.", target);
			OpenTeleportPetMenu(client);
			return 0;
		}
		
		if (target != client && IsPetValid(target))
		{
			CPrintToChat(client, "{green}[Companion]{blue} %N {default}already has a pet.", target);
			OpenTeleportPetMenu(client);
			return 0;
		}
		
		g_iFollowTarget[client] = target;
		TeleportPet(client);
		OpenTeleportPetMenu(client);
	}
	else if (action == MenuAction_Cancel && select == MenuCancel_ExitBack) OpenPetMainMenu(client);
	else if (action == MenuAction_End) delete menu;
	return 0;
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *											Corner Stone Of Tracking Mechanism									   *
 *================================================================================================================ */

public void OnGameFrame()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != L4D2Team_Survivor) continue;
		if (!IsPetValid(client) || g_hTimer_MoveIn[client] != null || g_bIsTeleportPet[client]) continue;
		
		int target = g_iFollowTarget[client];
		if (!IsClientInGame(target) || !IsPlayerAlive(target) || GetClientTeam(target) != L4D2Team_Survivor) g_iFollowTarget[client] = client;
		
		SetTrackingMethod(client);
    }
}

void SetTrackingMethod(int client)
{
	int target = g_iFollowTarget[client];
	if (!target || !IsClientInGame(target) || GetClientTeam(target) != L4D2Team_Survivor || !IsPlayerAlive(target)) target = client;
	
	float vClientPos[3], vPetPos[3];
	GetClientAbsOrigin(target, vClientPos);
	GetEntPropVector(g_iPet_Entity[client], Prop_Data, "m_vecOrigin", vPetPos);
	
	float fDistance = GetVectorDistance(vClientPos, vPetPos);
	
	// 1) Hanging or active revive: prioritize getting close
	if (IsHandingFromLedge(target) || g_bReviveInProgress[client])
	{
		g_bPetPaused[client] = false;
		
		if (fDistance <= CLIENT_NEAR_DISTANCE)
		{
			if (g_bReviveInProgress[client]) RevivePlayer(client, false);
			else SetPetAnimation(client, "Idle");
			return;
		}
	}
	
	// 2) Hazard / ladder freeze with safe auto-resume via teleport cooldown
	if (g_bPetPaused[client] || ShouldFreezeForFatalOrLadder(client))
	{
		g_bPetPaused[client] = true;
		SetPetAnimation(client, "Idle");
		
		if (IsGrounded(client) && !IsOnLadder(client) && (GetTime() - g_iLastTeleportTime[client] >= 3))
		{
			g_bPetPaused[client] = false;
			TeleportPet(client);
		}
		return;
	}
	
	// 3) Long gap > teleport
	if (fDistance > TELEPORT_DISTANCE)
	{
		TeleportPet(client);
		return;
	}
	
	// 4) Refresh steps while allowing animation
	if (fDistance <= CLIENT_NEAR_DISTANCE)
	{
		if (GetGameTime() < g_fPet_AnimLock[client]) return;
		SetPetAnimation(client, "Idle");
		ResetSteps(client, vClientPos);
		return;
	}
	
	// 5) Normal chase
	MovePetToNextStep(client, vClientPos, vPetPos);
}

void MovePetToNextStep(int client, float vClientPos[3], float vPetPos[3])
{
	float vPetAngle[3];
	GetEntPropVector(g_iPet_Entity[client], Prop_Data, "m_angRotation", vPetAngle);
	
	// Always record the newest step
	SaveNextStep(client, vClientPos);
	
	float nextX = g_fPlayerSteps[g_iLoadedStep[client]][client][0];
	float nextY = g_fPlayerSteps[g_iLoadedStep[client]][client][1];
	float nextZ = g_fPlayerSteps[g_iLoadedStep[client]][client][2];
	
	float deltaX  = nextX - vPetPos[0];
	float deltaY  = nextY - vPetPos[1];
	float deltaZ  = nextZ - vPetPos[2];
	
	float fDist2D = SquareRoot(deltaX *deltaX  + deltaY * deltaY);
	
	// Compute exact yaw & pitch from step A (pet) to step B (next step)
	float fHoriz = (fDist2D < 0.0001) ? 0.0001 : fDist2D;
	float fTargetYaw   =  (ArcTangent2(deltaY , deltaX ) * 180.0) / FLOAT_PI;
	float fTargetPitch = -(ArcTangent2(deltaZ , fHoriz) * 180.0) / FLOAT_PI;
	
	
	// Spin check fix
	float fCurrYaw = vPetAngle[1];
	float fYawDiff = fTargetYaw - fCurrYaw;
	
	while (fYawDiff > 180.0) fYawDiff -= 360.0;
	while (fYawDiff < -180.0) fYawDiff += 360.0;
	if ((fDist2D < 18.0 && FloatAbs(fYawDiff) > 135.0) || (fDist2D < 16.0 && FloatAbs(fTargetPitch) > 45.0))
	{
		SetPetAnimation(client, "Idle");
		ResetSteps(client, vClientPos);
		return;
	}
	
	// Teleport the pet whenever the required pitch angle is too steep, indicating a sharp change in elevation.
	if (FloatAbs(fTargetPitch) > 75.0)
	{
		TeleportPet(client);
		return;
	}
	
	// Set angles directly (no caps / no smoothing)
	vPetAngle[1] = fTargetYaw;
	vPetAngle[0] = fTargetPitch;
	
	// Face and move forward based on the full 3D angle (no vertical cap)
	float vDirection[3];
	float vNewPos[3];
	GetAngleVectors(vPetAngle, vDirection, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vDirection, vDirection);
	
	float fSpeed = SetPetSpeed(client, vClientPos, vPetPos);
	
	// Keep your animation logic tied to fSpeed
	float fAbsPitch = FloatAbs(vPetAngle[0]);
	if (fAbsPitch > 10.0) fSpeed *= 0.9;
	if (fAbsPitch > 18.0) fSpeed *= 0.8;
	
	// Move using the exact forward vector
	vNewPos[0] = vPetPos[0] + vDirection[0] * fSpeed;
	vNewPos[1] = vPetPos[1] + vDirection[1] * fSpeed;
	vNewPos[2] = vPetPos[2] + vDirection[2] * fSpeed;
	
	SetAbsOrigin(g_iPet_Entity[client], vNewPos);
	SetAbsAngles(g_iPet_Entity[client], vPetAngle);
	
	LoadNextStep(client, vNewPos);
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *												Save/Load/Reset Steps											   *
 *================================================================================================================ */

void SaveNextStep(int client, float vPos[3])
{
	float fInterval = PET_MOVE_INTERVAL;
	float fNow = GetGameTime();
	if (fNow - g_fLastStepWriteTime[client] < fInterval) return;
	
	int target = g_iFollowTarget[client];
	if (!target || !IsClientInGame(target) || GetClientTeam(target) != L4D2Team_Survivor || !IsPlayerAlive(target))
	target = client;
	
	g_fPlayerSteps[g_iSavedStep[client]][client][0] = vPos[0];
	g_fPlayerSteps[g_iSavedStep[client]][client][1] = vPos[1];
	g_fPlayerSteps[g_iSavedStep[client]][client][2] = IsGrounded(target) ? vPos[2] : (vPos[2] - GroundDistance(target));
	
	g_iSavedStep[client] = (g_iSavedStep[client] > 0) ? (g_iSavedStep[client] - 1) : (MAX_STEPS_MEMORY - 1);
	g_fLastStepWriteTime[client] = fNow;
}

void LoadNextStep(int client, float pos[3])
{
	float fReached = STEP_REACH_DISTANCE + 6.0;
	if (GetVectorDistance(pos, g_fPlayerSteps[g_iLoadedStep[client]][client]) < fReached)
		g_iLoadedStep[client] = (g_iLoadedStep[client] - 1 + MAX_STEPS_MEMORY) % MAX_STEPS_MEMORY;
}

void ResetSteps(int client, float pos[3])
{
    int target = g_iFollowTarget[client];
    if (!target || !IsClientInGame(target) || GetClientTeam(target) != L4D2Team_Survivor || !IsPlayerAlive(target))
        target = client;

    if (IsGrounded(target)) SnapPetToGround(client);

    if (!g_bReviveInProgress[client]) SetPetAnimation(client, "Idle");

    g_iSavedStep[client]  = MAX_STEPS_MEMORY - 1;
    g_iLoadedStep[client] = MAX_STEPS_MEMORY - 1;

    SaveNextStep(client, pos);
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *									Teleport Companion Mechanism To Prevent Stuck								   *
 *================================================================================================================ */

void TeleportPet(int client)
{
	int iNow = GetTime();
	if (iNow - g_iLastTeleportTime[client] < 3) return;
	g_iLastTeleportTime[client] = iNow;
	
	if (!IsPetValid(client)) return;
	
	g_bIsTeleportPet[client] = true;
	SetPetAnimation(client, "Return");
	CreateTimer(1.0, Timer_TeleportPetIn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_TeleportPetIn(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsPetValid(client))
	{
		g_bIsTeleportPet[client] = false;
		return Plugin_Handled;
	}
	
	int target = g_iFollowTarget[client];
	if (!target || !IsClientInGame(target) || !IsPlayerAlive(target) || GetClientTeam(target) != L4D2Team_Survivor)
        target = client;
	
	float vClientPos[3], vClientAng[3];
	GetClientAbsOrigin(target, vClientPos);
	GetEntPropVector(target, Prop_Data, "m_angRotation", vClientAng);
	
	SetAbsOrigin(g_iPet_Entity[client], vClientPos);
	SetAbsAngles(g_iPet_Entity[client], vClientAng);
	
	SetPetAnimation(client, "Spawn");
	CreateTimer(1.5, Timer_TeleportPetOut, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

Action Timer_TeleportPetOut(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsPetValid(client))
	{
		g_bIsTeleportPet[client] = false;
		return Plugin_Handled;
	}
	
	int target = g_iFollowTarget[client];
	if (!target || !IsClientInGame(target) || !IsPlayerAlive(target) || GetClientTeam(target) != L4D2Team_Survivor)
        target = client;
	
	float vPos[3];
	GetClientAbsOrigin(target, vPos);
	
	ResetSteps(client, vPos);    // <- seed for the OWNER
	
	for (int i = 0; i < MAX_STEPS_MEMORY; i++)
	{
		g_fPlayerSteps[i][client][0] = vPos[0];
		g_fPlayerSteps[i][client][1] = vPos[1];
		g_fPlayerSteps[i][client][2] = vPos[2];
	}
	
	g_bIsTeleportPet[client] = false;
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *													Pets Functions	   											   *
 *================================================================================================================ */

int CreatePropDynamic(int client, char[] model)
{
	int entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "model", model);
	
	float vecView[3], vDirection[3], vecPos[3];
	GetClientEyePosition(client, vecView);
	GetClientAbsOrigin(client, vecPos);
	GetClientEyeAngles(client, vecView);
	GetAngleVectors(vecView, vDirection, NULL_VECTOR, NULL_VECTOR);
	vecPos[0] += vDirection[0] * 50.0;
	vecPos[1] += vDirection[1] * 50.0;
	
	DispatchKeyValueVector(entity, "origin", vecPos);
	DispatchSpawn(entity);
	SetEntPropFloat(entity, Prop_Data, "m_flPoseParameter", 1.0, 4);
	
	g_iSavedStep[client]  = MAX_STEPS_MEMORY - 1;
	g_iLoadedStep[client] = MAX_STEPS_MEMORY - 1;
	
	float vClientPos[3];
	GetClientAbsOrigin(client, vClientPos);
	SaveNextStep(client, vClientPos);
	
	return entity;
}

void ReturnPet(int client)
{
	if(!IsPetValid(client)) return;
	
	CPrintToChat(client, "{green}[Companion] {default}Farewell!");
	SetPetAnimation(client, "Return");
	
	if(StrEqual(g_sPet_Name[client], "Luna") || g_sPet_Name[client][0] == '\0') g_hTimer_MoveOut[client] = CreateTimer(1.87, Timer_ReturnMyPet, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	else if(StrEqual(g_sPet_Name[client], "Raven")) g_hTimer_MoveOut[client] = CreateTimer(1.3, Timer_ReturnMyPet, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	else if(StrEqual(g_sPet_Name[client], "Snowy")) g_hTimer_MoveOut[client] = CreateTimer(1.2, Timer_ReturnMyPet, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	else if(StrEqual(g_sPet_Name[client], "Spyro")) g_hTimer_MoveOut[client] = CreateTimer(2.8, Timer_ReturnMyPet, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	else if(StrEqual(g_sPet_Name[client], "Ghosty")) g_hTimer_MoveOut[client] = CreateTimer(3.0, Timer_ReturnMyPet, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	else if(StrEqual(g_sPet_Name[client], "Storm")) g_hTimer_MoveOut[client] = CreateTimer(0.6, Timer_ReturnMyPet, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	else if(StrEqual(g_sPet_Name[client], "Ember")) g_hTimer_MoveOut[client] = CreateTimer(3.0, Timer_ReturnMyPet, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	else if(StrEqual(g_sPet_Name[client], "Warwick")) g_hTimer_MoveOut[client] = CreateTimer(0.9, Timer_ReturnMyPet, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ReturnMyPet(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client)) return Plugin_Handled;

	g_hTimer_MoveOut[client] = null;
	RemovePet(client);
    
	return Plugin_Handled;
}

void RemovePet(int client)
{
	if (g_iPet_Entity[client] && EntRefToEntIndex(g_iPet_Entity[client]) != INVALID_ENT_REFERENCE)
		AcceptEntityInput(g_iPet_Entity[client], "Kill");
	
	delete g_hTimer_MoveIn[client];
	delete g_hTimer_MoveOut[client];
	delete g_hTimer_ReviveCheck[client];
	delete g_hTimer_CheckAutoAbilities[client];
	
	g_bIsTeleportPet[client]    = false;
	g_bPetPaused[client]        = false;
	g_bReviveInProgress[client] = false;
	g_bPetReviveActive[client]  = false;
	
	g_iPet_Entity[client]       = 0;
	g_iPet_MoveType[client]     = 0;
	
	g_fSetupProgressTime[client] = 0.0;
	g_fPet_AnimLock[client]      = 0.0;
}

bool IsPetValid(int client)
{
	return g_iPet_Entity[client] && EntRefToEntIndex(g_iPet_Entity[client]) != INVALID_ENT_REFERENCE && g_hTimer_MoveOut[client] == null;
}

float SetPetSpeed(int client, float vClientPos[3], float vPetPos[3])
{
	float fDistance = GetVectorDistance(vClientPos, vPetPos);
	float fSpeed = 0.3 + 0.0055 * fDistance;
	if (fSpeed < 0.3) fSpeed = 0.3;
	if (fSpeed > 3.6) fSpeed = 3.6;
	
	float vVel[3];
	GetEntPropVector(g_iPet_Entity[client], Prop_Data, "m_vecVelocity", vVel);
	float fVel2D = SquareRoot(vVel[0]*vVel[0] + vVel[1] * vVel[1]);
	bool bIsMoving = (fDistance > CLIENT_NEAR_DISTANCE) || (fVel2D > 20.0);
	
	if (bIsMoving)
	{
		if (fDistance < 500.0) SetPetAnimation(client, "Walk");
		else SetPetAnimation(client, "Run");
		return fSpeed;
	}
	
	if (g_iPet_MoveType[client] >= 6 && GetGameTime() < g_fPet_AnimLock[client]) return fSpeed;
	
	static float fLastAnimDist[MAXPLAYERS+1];
	float fThreshold = (fLastAnimDist[client] >= 500.0) ? 480.0 : 520.0;
	
	if (fDistance < fThreshold) SetPetAnimation(client, "Walk");
	else SetPetAnimation(client, "Run");
	
	fLastAnimDist[client] = fDistance;
	return fSpeed;
}

void SetPetAnimation(int client, const char[] sAnimName)
{
	if (!IsPetValid(client)) return;
	
	static const char sAnimKeys[][] = { "Idle","Walk","Run","Spawn","Return","Revive","Move 1","Move 2","Move 3","Move 4","Move 5","Move 6","Move 7" };
	static const int iMoveTypes[] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 };
	
	static const char sAnimSeqs_Luna[][] =
	{
		"idle",       // Idle
		"walk",        // Walk
		"run",       // Run
		"respawn",      // Spawn
		"death",     // Return
		"revive",     // Revive
		"dance",   // Move 1
		"jocking",  // Move 2
		"recall",      // Move 3
		"relax",      // Move 4
		"respawn",     // Move 5
		"revive",     // Move 6
		"death"      // Move 7
	};
	
	static const float fLockDurations_Luna[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 4.3, 6.5, 6.4, 3.2, 3.97, 6.37, 1.87 };
	
	static const char sAnimSeqs_Raven[][] =
	{
		"idle",       // Idle
		"walk",        // Walk
		"run",       // Run
		"respawn",      // Spawn
		"respawn",     // Return
		"windup",     // Revive
		"dance",   // Move 1
		"taunt",  // Move 2
		"laughing",      // Move 3
		"jocking",      // Move 4
		"recall",     // Move 5
		"windup",     // Move 6
		"death"      // Move 7
	};
	
	static const float fLockDurations_Raven[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 10.0, 4.0, 1.7, 3.0, 7.0, 5.5, 5.0 };
	
	static const char sAnimSeqs_Snowy[][] =
	{
		"idle",       // Idle
		"run",        // Walk
		"run",       // Run
		"flip",      // Spawn
		"flip",     // Return
		"dance",     // Revive
		"dance",   // Move 1
		"taunt",  // Move 2
		"laughing",      // Move 3
		"jocking",      // Move 4
		"flip",     // Move 5
		"attack2",     // Move 6
		"death"      // Move 7pet
	};
	
	static const float fLockDurations_Snowy[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 10.0, 4.5, 3.0, 3.8, 0.9, 1.0, 5.0 };
	
	static const char sAnimSeqs_Spyro[][] =
	{
		"idle",       // Idle
		"run",        // Walk
		"run",       // Run
		"winddown",      // Spawn
		"death",     // Return
		"dance",     // Revive
		"dance",   // Move 1
		"jocking",  // Move 2
		"laughing",      // Move 3
		"channel_windup",      // Move 4
		"winddown",     // Move 5
		"recall",     // Move 6
		"death"      // Move 7pet
	};
	
	static const float fLockDurations_Spyro[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 10.0, 3.0, 2.0, 1.6, 3.8, 6.0, 5.0 };
	
	static const char sAnimSeqs_Ghosty[][] =
	{
		"idle",       // Idle
		"walk",        // Walk
		"run",       // Run
		"respawn",      // Spawn
		"death",     // Return
		"dance",     // Revive
		"dance",   // Move 1
		"taunt",  // Move 2
		"laughing",      // Move 3
		"spell",      // Move 4
		"attack2",     // Move 5
		"attack1",     // Move 6
		"death"      // Move 7
	};
	
	static const float fLockDurations_Ghosty[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 10.0, 6.5, 4.0, 1.5, 1.2, 1.2, 6.5 };
	
	static const char sAnimSeqs_Storm[][] =
	{
		"idle",       // Idle
		"run",        // Walk
		"crouch_run",       // Run
		"respawn",      // Spawn
		"ground_pound",     // Return
		"dance",     // Revive
		"dance",   // Move 1
		"celebrate",  // Move 2
		"taunt",      // Move 3
		"laughing",      // Move 4
		"recall",     // Move 5
		"attack1",     // Move 6
		"death"      // Move 7
	};
	
	static const float fLockDurations_Storm[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 9.0, 3.6, 4.8, 3.8, 6.2, 1.2, 2.2 };
	
	static const char sAnimSeqs_Ember[][] =
	{
		"idle",       // Idle
		"walk",        // Walk
		"run",       // Run
		"respawn",      // Spawn
		"death",     // Return
		"dance",     // Revive
		"dance",   // Move 1
		"taunt",  // Move 2
		"laughing",      // Move 3
		"jocking",      // Move 4
		"forge",     // Move 5
		"attack1",     // Move 6
		"death"      // Move 7
	};
	
	static const float fLockDurations_Ember[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 10.0, 4.5, 5.6, 10.0, 3.2, 1.6, 3.3 };
	
	static const char sAnimSeqs_Warwick[][] =
	{
		"idle",       // Idle
		"run",        // Walk
		"crouch_walk",       // Run
		"move_in",      // Spawn
		"move_out",     // Return
		"jocking",     // Revive
		"angry",   // Move 1
		"howl",  // Move 2
		"sniffing",      // Move 3
		"jocking",      // Move 4
		"laughing",     // Move 5
		"attack1",     // Move 6
		"death"      // Move 7
	};
	
	static const float fLockDurations_Warwick[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 2.4, 1.0, 1.6, 8.6, 5.1, 1.6, 2.66 };
	
	int iAnimIndex = -1;
	for (int i = 0; i < sizeof(iMoveTypes); i++)
	{
		if (StrEqual(sAnimName, sAnimKeys[i]))
		{
			iAnimIndex = i;
			break;
		}
	}
	
	if (iAnimIndex == -1) return;
	
	int iReqType = iMoveTypes[iAnimIndex];
	float fNow = GetGameTime();
	
	if (iReqType <= 5 && g_iPet_MoveType[client] >= 6 && fNow < g_fPet_AnimLock[client]) g_fPet_AnimLock[client] = 0.0;
	
	if (iReqType <= 5 && g_iPet_MoveType[client] == iReqType) return;
	
	float fLockTime = 0.0;
	char sSeq[32];
	
	if(StrEqual(g_sPet_Name[client], "Luna") || g_sPet_Name[client][0] == '\0')
	{
		if (iAnimIndex < sizeof(sAnimSeqs_Luna))
		{
			fLockTime = fLockDurations_Luna[iAnimIndex];
			strcopy(sSeq, sizeof(sSeq), sAnimSeqs_Luna[iAnimIndex]);
		}
	}
	else if(StrEqual(g_sPet_Name[client], "Raven"))
	{
		if (iAnimIndex < sizeof(sAnimSeqs_Raven))
		{
			fLockTime = fLockDurations_Raven[iAnimIndex];
			strcopy(sSeq, sizeof(sSeq), sAnimSeqs_Raven[iAnimIndex]);
		}
	}
	else if(StrEqual(g_sPet_Name[client], "Snowy"))
	{
		if (iAnimIndex < sizeof(sAnimSeqs_Snowy))
		{
			fLockTime = fLockDurations_Snowy[iAnimIndex];
			strcopy(sSeq, sizeof(sSeq), sAnimSeqs_Snowy[iAnimIndex]);
		}
	}
	else if(StrEqual(g_sPet_Name[client], "Spyro"))
	{
		if (iAnimIndex < sizeof(sAnimSeqs_Spyro))
		{
			fLockTime = fLockDurations_Spyro[iAnimIndex];
			strcopy(sSeq, sizeof(sSeq), sAnimSeqs_Spyro[iAnimIndex]);
		}
	}
	else if(StrEqual(g_sPet_Name[client], "Ghosty"))
	{
		if (iAnimIndex < sizeof(sAnimSeqs_Ghosty))
		{
			fLockTime = fLockDurations_Ghosty[iAnimIndex];
			strcopy(sSeq, sizeof(sSeq), sAnimSeqs_Ghosty[iAnimIndex]);
		}
	}
	else if(StrEqual(g_sPet_Name[client], "Storm"))
	{
		if (iAnimIndex < sizeof(sAnimSeqs_Storm))
		{
			fLockTime = fLockDurations_Storm[iAnimIndex];
			strcopy(sSeq, sizeof(sSeq), sAnimSeqs_Storm[iAnimIndex]);
		}
	}
	else if(StrEqual(g_sPet_Name[client], "Ember"))
	{
		if (iAnimIndex < sizeof(sAnimSeqs_Ember))
		{
			fLockTime = fLockDurations_Ember[iAnimIndex];
			strcopy(sSeq, sizeof(sSeq), sAnimSeqs_Ember[iAnimIndex]);
		}
	}
	else if(StrEqual(g_sPet_Name[client], "Warwick"))
	{
		if (iAnimIndex < sizeof(sAnimSeqs_Warwick))
		{
			fLockTime = fLockDurations_Warwick[iAnimIndex];
			strcopy(sSeq, sizeof(sSeq), sAnimSeqs_Warwick[iAnimIndex]);
		}
	}
	
	if (fLockTime > 0.0) g_fPet_AnimLock[client] = fNow + fLockTime;
	
	SetVariantString(sSeq);
	AcceptEntityInput(g_iPet_Entity[client], "SetAnimation");
	g_iPet_MoveType[client] = iReqType;
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *											Detecting Ground and Fall Distance	   								   *
 *================================================================================================================ */

float GroundDistance(int client)
{
	float fStart[3], fDistance = 0.0;
	if(IsGrounded(client)) return 0.0;
	
	GetClientAbsOrigin(client, fStart);
	fStart[2] += 10.0;
	
	Handle hTrace = TR_TraceRayFilterEx(fStart, view_as<float>({90.0, 0.0, 0.0}), MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client); 
	if (TR_DidHit(hTrace))
	{
		float fEndPos[3];
		TR_GetEndPosition(fEndPos, hTrace);
		fStart[2] -= 10.0;
		fDistance = GetVectorDistance(fStart, fEndPos);
	}
	
	if (hTrace != null) CloseHandle(hTrace);
	return fDistance;
}

void SnapPetToGround(int client)
{
	if (!IsPetValid(client)) return;
	
	float vOrigin[3];
	GetEntPropVector(g_iPet_Entity[client], Prop_Data, "m_vecOrigin", vOrigin);
	
	float vStart[3];
	vStart[0] = vOrigin[0];
	vStart[1] = vOrigin[1];
	vStart[2] = vOrigin[2] + 50.0;

	float vEnd[3];
	vEnd[0] = vStart[0];
	vEnd[1] = vStart[1];
	vEnd[2] = vStart[2] - 2048.0;
	
	Handle hTrace = TR_TraceRayFilterEx(vStart, vEnd, MASK_PLAYERSOLID, RayType_EndPoint, TraceRayDontHitSelf, g_iPet_Entity[client]);
	
	if (hTrace != null && TR_DidHit(hTrace))
	{
		float vHit[3];
		TR_GetEndPosition(vHit, hTrace);
		
		float vFixedPos[3];
		vFixedPos[0] = vOrigin[0];
		vFixedPos[1] = vOrigin[1];
		vFixedPos[2] = vHit[2];
		
		SetAbsOrigin(g_iPet_Entity[client], vFixedPos);
	}
	
	if (hTrace != null) CloseHandle(hTrace);
}

bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	if (entity == data) return false;
	if (entity >= 1 && entity <= MaxClients && IsClientInGame(entity)) return false;
	return true; 
}

bool NextStepIsLadder(int client)
{
	float vNextStep[3];
	vNextStep[0] = g_fPlayerSteps[g_iLoadedStep[client]][client][0];
	vNextStep[1] = g_fPlayerSteps[g_iLoadedStep[client]][client][1];
	vNextStep[2] = g_fPlayerSteps[g_iLoadedStep[client]][client][2] + 16.0;
	
	int iContents  = TR_GetPointContents(vNextStep);
	return (iContents & CONTENTS_LADDER) != 0;
}

bool IsFatalDrop(int client)
{
	if (!IsClientInGame(client)) return false;
	if (IsPlayerIncapacitated(client) || IsGrounded(client) || IsOnLadder(client)) return false;
	
	float fGap = GroundDistance(client);
	
	if (fGap >= 720.0) return true;
	if (fGap >= 520.0)
	{
		float vVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
		if (vVelocity[2] <= -240.0) return true;
	}
	
	return false;
}

bool ShouldFreezeForFatalOrLadder(int client)
{
	int target = g_iFollowTarget[client];
	if (!target || !IsClientInGame(target) || GetClientTeam(target) != L4D2Team_Survivor || !IsPlayerAlive(target)) target = client;
	
	if (IsOnLadder(target) || IsFatalDrop(target) || NextStepIsLadder(client)) return true;
	return false;
}

bool IsFollowTargetNear(int client)
{
    int target = g_iFollowTarget[client];
    if (!target || !IsClientInGame(target) || !IsPlayerAlive(target) || GetClientTeam(target) != L4D2Team_Survivor)
        return false;

    float vTarget[3], vPet[3];
    GetClientAbsOrigin(target, vTarget);
    GetEntPropVector(g_iPet_Entity[client], Prop_Data, "m_vecOrigin", vPet);
    return (GetVectorDistance(vTarget, vPet) <= CLIENT_NEAR_DISTANCE);
}

/* =============================================================================================================== *
 *			                       _____   _         _    _                                                        *
 *			                      |  __ \ | |       | |  (_)                                                       *
 *			                      | |__) || |  __ _ | |_  _  _ __   _   _  _ __ ___                                *
 *			                      |  ___/ | | / _` || __|| || '_ \ | | | || '_ ` _ \                               *
 *			                      | |     | || (_| || |_ | || | | || |_| || | | | | |                              *
 *			                      |_|     |_| \__,_| \__||_||_| |_| \__,_||_| |_| |_|                              *
 *                                                                                                                 *
 * ============================================================================================================== */

/* =============================================================================================================== *
 *												General Functions	   											   *
 *================================================================================================================ */

void ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	
	if (type == 0) BfWriteShort(msg, (0x0002 | 0x0008));
	else BfWriteShort(msg, (0x0001 | 0x0010));
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

bool IsGrounded(int client)
{
	return (GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONGROUND) > 0;
}

bool IsOnLadder(int client)
{
    return GetEntityMoveType(client) == MOVETYPE_LADDER;
}

bool IsPlayerIncapacitated(int client)
{
    return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0;
}

bool IsHandingFromLedge(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0 || GetEntProp(client, Prop_Send, "m_isFallingFromLedge") != 0;
}

bool IsPlayerGrabbed(int client)
{
	if (GetEntProp(client, Prop_Send, "m_pummelAttacker") > 0) return true;
	if (GetEntProp(client, Prop_Send, "m_carryAttacker") > 0) return true;
	if (GetEntProp(client, Prop_Send, "m_pounceAttacker") > 0) return true;
	if (GetEntProp(client, Prop_Send, "m_jockeyAttacker") > 0) return true;
	if (GetEntProp(client, Prop_Send, "m_tongueOwner") > 0) return true;
	return false;
}