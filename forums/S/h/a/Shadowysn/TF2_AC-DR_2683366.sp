#define PLUGIN_NAME "[TF2] All-Class Dead Ringer"
#define PLUGIN_AUTHOR "Shadowysn, Mentlegen (original inspiration)"
#define PLUGIN_DESC "Use sm_fd to activate the AC-DR."
#define PLUGIN_VERSION "1.2.8d"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?p=2683366"
#define PLUGIN_NAME_SHORT "All-Class Dead Ringer"
#define PLUGIN_NAME_TECH "ac_dr"

#define USE_SENDPROXY false
#define DEBUG false

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#if USE_SENDPROXY
	#include <sendproxy>
#endif
#include <tf2_stocks>

//#define GAMEDATA "tf2.allclass-deadringer"

enum
{
	TYPE_GLOVES = 0,
	TYPE_POWERJACK,
	TYPE_BEARCLAWS,
	TYPE_ZATOICHI,
	TYPE_CANDYCANE,
	TYPE_CLASSIC,
	TYPE_NEONLATOR,
	TYPE_SPYCICLE,
	TYPE_MANMELTER,
	TYPE_THIRDDEGREE,
	TYPE_PHLOG,
	TYPE_EREWARD,
	TYPE_WPRICK,
	TYPE_BEARNER,
	TYPE_GOLDWRENCH,
	TYPE_GOLDPAN,
	TYPE_SAXXY
}

enum
{
	AP_NORMAL = 0,
	AP_HALLOWEEN,
	AP_CHRISTMAS
}

#define ACTIVE_STR "A-C DR ACTIVE"
#define INACTIVE_STR "A-C DR INACTIVE"
#define UNCLOAK_SND "Player.Spy_UnCloakFeignDeath"
#define STOPWEP_SND "BaseCombatCharacter.StopWeaponSounds"
#define FALLGIB_SND "Player.FallDamage"

#define CHANGE_DAMAGE_HOOK SDKHook_OnTakeDamage
#define THINK_POST_HOOK SDKHook_ThinkPost
#define POST_THINK_HOOK SDKHook_PostThink

#pragma semicolon 1
#pragma newdecls required

bool can[MAXPLAYERS+1] = {true};
bool trigger[MAXPLAYERS+1] = {false};
bool isCloaked[MAXPLAYERS+1] = {false};
//int g_Ragdoll[MAXPLAYERS+1];

static ConVar ACDR_RechargeTime, ACDR_CloakTime, ACDR_AfterburnImmune, ACDR_SpeedBoost, ACDR_WeaponTime, 
ACDR_FriendlyDisguise, ACDR_ClassRestrictSpy, ACDR_ExtraEffects, 
ACDR_DamageRes_Min, ACDR_DamageRes_Max, 
ACDR_BotSpawn,
ACDR_AllowTeam;
ConVar playergib_cvar/*, friendlyfire_cvar*/;

float g_fRechargeTime, g_fCloakTime, g_fAfterburnImmune, g_fSpeedBoost, g_fWeaponTime, g_fDamageRes_Min, g_fDamageRes_Max;
bool g_bFriendlyDisguise, g_bClassRestrictSpy;
int g_iExtraEffects, g_iBots, g_iAllowTeam, g_iPlayerGib;

#define BITFLAG_EXTRAEFFECT	(1 << 0)
#define BITFLAG_AMMOPACK		(1 << 1)
#define BITFLAG_BUILDINGDEATH	(1 << 2)

#define BITFLAG_SPAWNTOGGLE	(1 << 0)
#define BITFLAG_TOGGLEONREADY	(1 << 1)

#define BITFLAG_TEAMRED		(1 << 0)
#define BITFLAG_TEAMBLUE		(1 << 1)
#define BITFLAG_AFFECTMVM		(1 << 2)
#define BITFLAG_AFFECTPVP		(1 << 3)

//char g_wep_netclass_attacker[MAXPLAYERS+1];

//Handle g_fUncloakTimer[MAXPLAYERS+1] = {null};
float g_fUncloakTimer[MAXPLAYERS+1], g_fReadyTimer[MAXPLAYERS+1], g_fResistTimer[MAXPLAYERS+1];
bool g_bUsingM2[MAXPLAYERS+1];
//Handle g_BoostTimer[MAXPLAYERS+1] = {null};
//float g_BoostTimer[MAXPLAYERS+1] = {0.0};
//Handle g_fReadyTimer[MAXPLAYERS+1] = {null};

float g_fClientWait[MAXPLAYERS+1];
#define THINK_WAITTIME 0.5

bool isMVM = false;

bool g_bLateLoad = false;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_TF2)
	{
		g_bLateLoad = late;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Team Fortress 2.");
	return APLRes_SilentFailure;
}

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		version_cvar.SetString(PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_recharge_timelimit", PLUGIN_NAME_TECH);
	ACDR_RechargeTime = CreateConVar(cmd_str, "8.0", "Set the time limit until the AC-DR fully recharges.", FCVAR_NONE, true, 0.0);
	ACDR_RechargeTime.AddChangeHook(CC_DR_RechargeTime);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_cloak_timelimit", PLUGIN_NAME_TECH);
	ACDR_CloakTime = CreateConVar(cmd_str, "6.5", "Set the time limit the AC-DR cloaks the user for.", FCVAR_NONE, true, 0.0);
	ACDR_CloakTime.AddChangeHook(CC_DR_CloakTime);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_speedboost", PLUGIN_NAME_TECH);
	ACDR_SpeedBoost = CreateConVar(cmd_str, "3.0", "Time of speed-boost upon AC-DR usage.\n0.0 = disable.", FCVAR_NONE, true, 0.0);
	ACDR_SpeedBoost.AddChangeHook(CC_DR_SpeedBoost);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_weapon_time", PLUGIN_NAME_TECH);
	ACDR_WeaponTime = CreateConVar(cmd_str, "3.0", "Time until weapons can be used again upon AC-DR uncloaking.\n0.0 = disable.", FCVAR_NONE, true, 0.0);
	ACDR_WeaponTime.AddChangeHook(CC_DR_WeaponTime);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_afterburn_immune", PLUGIN_NAME_TECH);
	ACDR_AfterburnImmune = CreateConVar(cmd_str, "3.0", "Time of afterburn-immunity upon AC-DR usage.\n0.0 = disable.", FCVAR_NONE, true, 0.0);
	ACDR_AfterburnImmune.AddChangeHook(CC_DR_AfterburnImmune);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_friendlydis", PLUGIN_NAME_TECH);
	ACDR_FriendlyDisguise = CreateConVar(cmd_str, "0.0", "Makes Spies drop the corpse of the friendly disguise instead of themselves.", FCVAR_NONE, true, 0.0, true, 1.0);
	ACDR_FriendlyDisguise.AddChangeHook(CC_DR_FriendlyDisguise);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_classrestrict_spy", PLUGIN_NAME_TECH);
	ACDR_ClassRestrictSpy = CreateConVar(cmd_str, "0.0", "Restrict Spies from using the AC-DR.", FCVAR_NONE, true, 0.0, true, 1.0);
	ACDR_ClassRestrictSpy.AddChangeHook(CC_DR_ClassRestrictSpy);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_extra_effects", PLUGIN_NAME_TECH);
	ACDR_ExtraEffects = CreateConVar(cmd_str, "0.0", "Recreate other effects that the normal DR couldn't. (THESE ARE BITFLAGS, COMBINE THEM)\n1 = Attacker benefits.\n2 = Ammopack gives ammo.\n4 = Carried buildings fake explode and killfeed.", FCVAR_NONE, true, 0.0, true, 7.0);
	ACDR_ExtraEffects.AddChangeHook(CC_DR_ExtraEffects);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_damage_res_min", PLUGIN_NAME_TECH);
	ACDR_DamageRes_Min = CreateConVar(cmd_str, "0.2", "Damage is multiplied by this value for cloaked AC-DR users with LOW charge.\nDo <0.9 for lesser damage.", FCVAR_NONE, true, 0.0);
	ACDR_DamageRes_Min.AddChangeHook(CC_DR_DamageRes_Min);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_damage_res_max", PLUGIN_NAME_TECH);
	ACDR_DamageRes_Max = CreateConVar(cmd_str, "0.65", "Damage is multiplied by this value for cloaked AC-DR users with HIGH charge.\nDo <0.9 for lesser damage.", FCVAR_NONE, true, 0.0);
	ACDR_DamageRes_Max.AddChangeHook(CC_DR_DamageRes_Max);

	Format(cmd_str, sizeof(cmd_str), "sm_%s_bots", PLUGIN_NAME_TECH);
	ACDR_BotSpawn = CreateConVar(cmd_str, "0.0", "Toggle bot behavior with AC-DR. (THESE ARE BITFLAGS, COMBINE THEM)\n1 = Enable on spawn.\n2 = Enable when available after recharging.", FCVAR_NONE, true, 0.0, true, 3.0);
	ACDR_BotSpawn.AddChangeHook(CC_DR_BotSpawn);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_teams", PLUGIN_NAME_TECH);
	ACDR_AllowTeam = CreateConVar(cmd_str, "5.0", "Choose AC-DR availability for teams. Mainly for MVM. (THESE ARE BITFLAGS, COMBINE THEM)\n1 = Team RED can use.\n2 = Team BLUE can use.\n4 = Set team restrict for MVM.\n8 = Set team restrict for all other gamemodes.", FCVAR_NONE, true, 0.0, true, 15.0);
	ACDR_AllowTeam.AddChangeHook(CC_DR_AllowTeam);
	
	playergib_cvar = FindConVar("tf_playergib");
	playergib_cvar.AddChangeHook(CC_playergib_cvar);
	//friendlyfire_cvar = FindConVar("mp_friendlyfire");
	
	AutoExecConfig(true, "TF2_AC_DR");
	SetCvarValues();
	
	HookEvent("player_hurt", player_hurt, EventHookMode_Pre);
	HookEvent("player_death", player_death, EventHookMode_Post);
	HookEvent("player_spawn", player_spawn, EventHookMode_Post);
	HookEvent("player_changeclass", player_changeclass, EventHookMode_Pre);
	RegConsoleCmd("sm_fd", ACDR_Command, "Toggle the All-Class Dead Ringer.");
	#if DEBUG
	RegConsoleCmd("sm_testfd", ACDR_Test, "testfd.");
	#endif
	RegAdminCmd("sm_fd_ply", ACDR_Force_Command, ADMFLAG_GENERIC, "Toggle the All-Class Dead Ringer on a specified player.");
	
	if (g_bLateLoad)
	{
		for (int client = 1; client <= MAXPLAYERS; client++)
		{
			can[client] = true;
			trigger[client] = false;
		}
		CheckMap();
	}
	
	LoadTranslations("common.phrases");
}

public void OnPluginEnd()
{
	int ply_manager = GetPlayerResourceEntity();
	if (ply_manager != -1)
	{ SDKUnhook(ply_manager, THINK_POST_HOOK, Hook_OnThinkPost); }
	
	UnhookEvent("player_hurt", player_hurt, EventHookMode_Pre);
	UnhookEvent("player_death", player_death, EventHookMode_Post);
	UnhookEvent("player_spawn", player_spawn, EventHookMode_Post);
	UnhookEvent("player_changeclass", player_changeclass, EventHookMode_Pre);
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client, true, true)) continue;
		
		HookThink(client, false);
		//RemoveACDRRagdoll(client);
		//Hook_Manager_AliveProp(client, false);
		#if USE_SENDPROXY
		if (SendProxy_IsHooked(client, "m_lifeState"))
			SendProxy_Unhook(client, "m_lifeState", ProxyCallback_lifestate); // SendProxy 1.3
		//if (SendProxy_IsHooked(client, "m_vecOrigin"))
		//	SendProxy_Unhook(client, "m_vecOrigin", ProxyCallback_vecOrigin); // SendProxy 1.3
		#endif
	}
}

// ConVar Values
void CC_DR_RechargeTime(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fRechargeTime =		convar.FloatValue;	}
void CC_DR_CloakTime(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_fCloakTime =			convar.FloatValue;	}
void CC_DR_SpeedBoost(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_fSpeedBoost =			convar.FloatValue;	}
void CC_DR_WeaponTime(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_fWeaponTime =			convar.FloatValue;	}
void CC_DR_AfterburnImmune(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fAfterburnImmune =	convar.FloatValue;	}
void CC_DR_FriendlyDisguise(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_bFriendlyDisguise =	convar.BoolValue;		}
void CC_DR_ClassRestrictSpy(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_bClassRestrictSpy =	convar.BoolValue;		}
void CC_DR_ExtraEffects(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iExtraEffects =		convar.IntValue;		}
void CC_DR_DamageRes_Min(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fDamageRes_Min =		convar.FloatValue;	}
void CC_DR_DamageRes_Max(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fDamageRes_Max =		convar.FloatValue;	}
void CC_DR_BotSpawn(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_iBots =				convar.IntValue;		}
void CC_DR_AllowTeam(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_iAllowTeam =			convar.IntValue;		}
void SetCvarValues()
{
	CC_DR_RechargeTime(ACDR_RechargeTime, "", "");
	CC_DR_CloakTime(ACDR_CloakTime, "", "");
	CC_DR_SpeedBoost(ACDR_SpeedBoost, "", "");
	CC_DR_WeaponTime(ACDR_WeaponTime, "", "");
	CC_DR_AfterburnImmune(ACDR_AfterburnImmune, "", "");
	CC_DR_FriendlyDisguise(ACDR_FriendlyDisguise, "", "");
	CC_DR_ClassRestrictSpy(ACDR_ClassRestrictSpy, "", "");
	CC_DR_ExtraEffects(ACDR_ExtraEffects, "", "");
	CC_DR_DamageRes_Min(ACDR_DamageRes_Min, "", "");
	CC_DR_DamageRes_Max(ACDR_DamageRes_Max, "", "");
	CC_DR_BotSpawn(ACDR_BotSpawn, "", "");
	CC_DR_AllowTeam(ACDR_AllowTeam, "", "");
	CC_playergib_cvar(playergib_cvar, "", "");
}
void CC_playergib_cvar(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iPlayerGib =	convar.IntValue;	}

// Scene Entity Start v
void PlayScene(int client, const char[] str)
{
	int scene = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(scene, "SceneFile", str);
	SetEntPropEnt(scene, Prop_Data, "m_hOwner", client);
	DispatchKeyValue(scene, "busyactor", "0");
	DispatchSpawn(scene);
	ActivateEntity(scene);
	AcceptEntityInput(scene, "Start");
}

void StopScene(int client)
{
	int scene = CreateEntityByName("instanced_scripted_scene");
	
	TFClassType class = TF2_GetPlayerClass(client);
	if (IsDisguisedAsFriendly(client))
	{ class = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass")); }
	
	switch (class)
	{
		case TFClass_Scout:		DispatchKeyValue(scene, "SceneFile", "scenes/player/scout/low/idleloop01.vcd");
		case TFClass_Soldier:	DispatchKeyValue(scene, "SceneFile", "scenes/player/soldier/low/idleloop01.vcd");
		case TFClass_Pyro:		DispatchKeyValue(scene, "SceneFile", "scenes/player/pyro/low/idleloop01.vcd");
		case TFClass_DemoMan:	DispatchKeyValue(scene, "SceneFile", "scenes/player/demoman/low/idleloop01.vcd");
		case TFClass_Heavy:		DispatchKeyValue(scene, "SceneFile", "scenes/player/heavy/low/idleloop01.vcd");
		case TFClass_Engineer:	DispatchKeyValue(scene, "SceneFile", "scenes/player/engineer/low/idleloop01.vcd");
		case TFClass_Medic:		DispatchKeyValue(scene, "SceneFile", "scenes/player/medic/low/idleloop01.vcd");
		case TFClass_Sniper:	DispatchKeyValue(scene, "SceneFile", "scenes/player/sniper/low/idleloop01.vcd");
		case TFClass_Spy:		DispatchKeyValue(scene, "SceneFile", "scenes/player/spy/low/idleloop01.vcd");
	}
	//DispatchKeyValue(scene, "SceneFile", "scenes/Player/Scout/low/456.vcd");
	SetEntPropEnt(scene, Prop_Data, "m_hOwner", client);
	DispatchKeyValue(scene, "busyactor", "0");
	DispatchSpawn(scene);
	ActivateEntity(scene);
	AcceptEntityInput(scene, "Start");
}

#define DEATHSCR_EXPLODE 0
#define DEATHSCR_NORMAL 1
#define DEATHSCR_CRIT 2
#define DEATHSCR_FALL 3
void DoClientScream(int client, int type = DEATHSCR_NORMAL)
{
	EmitGameSoundToAll(STOPWEP_SND, client);
	
	if (type == DEATHSCR_FALL)
	{
		EmitGameSoundToAll(FALLGIB_SND, client);
		StopScene(client);
		return;
	}
	
	int num_low = -1; int num_high = -1;
	static char target_ClassName[12]; target_ClassName[0] = '\0';
	TFClassType class = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
	//TFTeam team = view_as<TFTeam>(GetClientTeam(client));
	//TFTeam disguise_team = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_nDisguiseTeam"));
	if (!IsDisguisedAsFriendly(client))
	{ class = TF2_GetPlayerClass(client); }
	
	EmitGameSoundToAll("Spy.ExplosionDeath", client, SND_STOP);
	EmitGameSoundToAll("Spy.Death", client, SND_STOP);
	EmitGameSoundToAll("Spy.CritDeath", client, SND_STOP);
	
	switch (class)
	{
		case TFClass_Scout: // Scout
		{
			
			switch (type)
			{
				case DEATHSCR_EXPLODE:
				{ num_low = 464; num_high = 466; EmitGameSoundToAll("Scout.ExplosionDeath", client); }
				case DEATHSCR_NORMAL:
				{ num_low = 461; num_high = 463; EmitGameSoundToAll("Scout.Death", client); }
				case DEATHSCR_CRIT:
				{ num_low = 458; num_high = 460; EmitGameSoundToAll("Scout.CritDeath", client); }
			}
			strcopy(target_ClassName, sizeof(target_ClassName), "scout");
		}
		case TFClass_Soldier: // Soldier
		{
			switch (type)
			{
				case DEATHSCR_EXPLODE:
				{ num_low = 1168; num_high = 1170; EmitGameSoundToAll("Soldier.ExplosionDeath", client); }
				case DEATHSCR_NORMAL:
				{ num_low = 1165; num_high = 1167; EmitGameSoundToAll("Soldier.Death", client); }
				case DEATHSCR_CRIT:
				{ num_low = 1162; num_high = 1164; EmitGameSoundToAll("Soldier.CritDeath", client); }
			}
			strcopy(target_ClassName, sizeof(target_ClassName), "soldier");
		}
		case TFClass_Pyro: // Pyro
		{
			switch (type)
			{
				case DEATHSCR_EXPLODE:
				{ num_low = 1584; num_high = 1593; EmitGameSoundToAll("Pyro.ExplosionDeath", client); }
				case DEATHSCR_NORMAL:
				{ num_low = 1581; num_high = 1583; EmitGameSoundToAll("Pyro.Death", client); }
				case DEATHSCR_CRIT:
				{ num_low = 1578; num_high = 1580; EmitGameSoundToAll("Pyro.CritDeath", client); }
			}
			strcopy(target_ClassName, sizeof(target_ClassName), "pyro");
		}
		case TFClass_DemoMan: // Demoman
		{
			switch (type)
			{
				case DEATHSCR_EXPLODE:
				{ num_low = 986; num_high = 988; EmitGameSoundToAll("Demoman.ExplosionDeath", client); }
				case DEATHSCR_NORMAL:
				{ num_low = 983; num_high = 985; EmitGameSoundToAll("Demoman.Death", client); }
				case DEATHSCR_CRIT:
				{ num_low = 980; num_high = 982; EmitGameSoundToAll("Demoman.CritDeath", client); }
			}
			strcopy(target_ClassName, sizeof(target_ClassName), "demoman");
		}
		case TFClass_Heavy: // Heavy
		{
			switch (type)
			{
				case DEATHSCR_EXPLODE:
				{ num_low = 300; num_high = 302; EmitGameSoundToAll("Heavy.ExplosionDeath", client); }
				case DEATHSCR_NORMAL:
				{ num_low = 297; num_high = 299; EmitGameSoundToAll("Heavy.Death", client); }
				case DEATHSCR_CRIT:
				{ num_low = 294; num_high = 296; EmitGameSoundToAll("Heavy.CritDeath", client); }
			}
			strcopy(target_ClassName, sizeof(target_ClassName), "heavy");
		}
		case TFClass_Engineer: // Engineer
		{
			switch (type)
			{
				case DEATHSCR_EXPLODE:
				{ num_low = 136; num_high = 138; EmitGameSoundToAll("Engineer.ExplosionDeath", client); }
				case DEATHSCR_NORMAL:
				{ num_low = 133; num_high = 135; EmitGameSoundToAll("Engineer.Death", client); }
				case DEATHSCR_CRIT:
				{ num_low = 130; num_high = 132; EmitGameSoundToAll("Engineer.CritDeath", client); }
			}
			strcopy(target_ClassName, sizeof(target_ClassName), "engineer");
		}
		case TFClass_Medic: // Medic
		{
			switch (type)
			{
				case DEATHSCR_EXPLODE:
				{ num_low = 636; num_high = 638; EmitGameSoundToAll("Medic.ExplosionDeath", client); }
				case DEATHSCR_NORMAL:
				{ num_low = 633; num_high = 635; EmitGameSoundToAll("Medic.Death", client); }
				case DEATHSCR_CRIT:
				{ num_low = 630; num_high = 632; EmitGameSoundToAll("Medic.CritDeath", client); }
			}
			strcopy(target_ClassName, sizeof(target_ClassName), "medic");
		}
		case TFClass_Sniper: // Sniper
		{
			switch (type)
			{
				case DEATHSCR_EXPLODE:
				{ num_low = 1703; num_high = 1705; EmitGameSoundToAll("Sniper.ExplosionDeath", client); }
				case DEATHSCR_NORMAL:
				{ num_low = 1700; num_high = 1702; EmitGameSoundToAll("Sniper.Death", client); }
				case DEATHSCR_CRIT:
				{ num_low = 1697; num_high = 1699; EmitGameSoundToAll("Sniper.CritDeath", client); }
			}
			strcopy(target_ClassName, sizeof(target_ClassName), "sniper");
		}
		case TFClass_Spy: // Spy
		{
			switch (type)
			{
				case DEATHSCR_EXPLODE:
				{ num_low = 806; num_high = 808; EmitGameSoundToAll("Spy.ExplosionDeath", client); }
				case DEATHSCR_NORMAL:
				{ num_low = 803; num_high = 805; EmitGameSoundToAll("Spy.Death", client); }
				case DEATHSCR_CRIT:
				{ num_low = 800; num_high = 802; EmitGameSoundToAll("Spy.CritDeath", client); }
			}
			strcopy(target_ClassName, sizeof(target_ClassName), "spy");
		}
	}
	
	/*switch (type)
	{
		case DEATHSCR_EXPLODE:
		{ EmitGameSoundToAll("Spy.ExplosionDeath", client); }
		case DEATHSCR_NORMAL:
		{ EmitGameSoundToAll("Spy.Death", client); }
		case DEATHSCR_CRIT:
		{ EmitGameSoundToAll("Spy.CritDeath", client); }
	}*/
	
	/*static char name[128];
	//static char prev_name[128] = "";
	GetEntPropString(client, Prop_Data, "m_iName", name, sizeof(name));
	if (name[0])
	{
		prev_name = name;
	}*/
	
	/*for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
	{
		if (!IsValidClient(loopclient)) continue;
		if (loopclient == client) continue;
		static char loopName[128];
		GetEntPropString(loopclient, Prop_Data, "m_iName", loopName, sizeof(loopName));
		if (loopName[0] && strcmp(loopName, target_ClassName, false) == 0)
		{
			//static char new_loopName[128];
			//Format(new_loopName, sizeof(new_loopName), "%s_%i", target_ClassName, GetClientUserId(loopclient));
			//DispatchKeyValue(loopclient, "targetname", new_loopName);
			DispatchKeyValue(loopclient, "targetname", "");
		}
	}
	if (strcmp(target_ClassName, name, false) != 0)
	{ DispatchKeyValue(client, "targetname", target_ClassName); }*/
	
	static char scream_str[64];
	Format(scream_str, sizeof(scream_str), "scenes/Player/%s/low/%i", target_ClassName, GetRandomInt(num_low, num_high));
	PlayScene(client, scream_str);
	
	//return class;
}
// Scene Entity End ^

/* Action ProxyCallback_bAlive(entity, const char[] propname, &iValue, element, client)
{
	if (!IsValidClient(entity) || !IsValidClient(client))
	{ return Plugin_Continue; }
	if (GetClientTeam(entity) != GetClientTeam(client) && !IsClientObserver(client))
	{
		iValue = 0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}*/
TFClassType g_iClassForResource[MAXPLAYERS+1] = {TFClass_Spy};
void Hook_OnThinkPost(int entity)
{
	/*int offset_bAlive = FindSendPropInfo("CTFPlayerResource", "m_bAlive");
	int offset_iPCWK = FindSendPropInfo("CTFPlayerResource", "m_iPlayerClassWhenKilled");
	
	int bClientAlive[MAXPLAYERS+1];
	int bClientPCWK[MAXPLAYERS+1];
	GetEntDataArray(entity, offset_bAlive, bClientAlive, MaxClients+1);
	GetEntDataArray(entity, offset_iPCWK, bClientPCWK, MaxClients+1);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
		{ continue; }
		if (isCloaked[i])
		{
			bClientAlive[i] = 0;
			if (IsDisguisedAsFriendly(i))
			{ bClientPCWK[i] = GetEntProp(i, Prop_Send, "m_nDisguiseClass"); }
			else
			{ bClientPCWK[i] = GetEntProp(i, Prop_Send, "m_iClass"); }
		}
		//if (bClientAlive[i] > 0)
		//{ PrintToChatAll("%i", bClientAlive[i]); }
	}
	
	SetEntDataArray(entity, offset_bAlive, bClientAlive, MaxClients+1);
	SetEntDataArray(entity, offset_iPCWK, bClientPCWK, MaxClients+1);*/
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i, true, true)) continue;
		
		if (isCloaked[i])
		{
			//int class = GetEntProp(i, Prop_Send, "m_iClass");
			//int disguise_class = GetEntProp(i, Prop_Send, "m_nDisguiseClass");
			SetEntProp(entity, Prop_Send, "m_bAlive", 0, _, i);
			SetEntProp(entity, Prop_Send, "m_iPlayerClassWhenKilled", g_iClassForResource[i], _, i);
		}
		//if (bClientAlive[i] > 0)
		//{ PrintToChatAll("%i", bClientAlive[i]); }
	}
}
#if USE_SENDPROXY
Action ProxyCallback_lifestate(const int entity, const char[] propname, int& iValue, const int element, const int client)
{
	if (!IsValidClient(entity, false) || !IsValidClient(client, false) || 
	TF2_IsPlayerInCondition(client, TFCond_OnFire) || 
	TF2_IsPlayerInCondition(client, TFCond_BurningPyro)) return Plugin_Continue;
	if (GetClientTeam(entity) != GetClientTeam(client) && !IsClientObserver(client))
	{
		iValue = 1;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
/*
static float oldOrigins[MAXPLAYERS+1][3];
Action ProxyCallback_vecOrigin(const int entity, const char[] propname, float vecValues[3], const int element, const int client)
{
	if (!IsValidClient(entity, false) || !IsValidClient(client, false) || 
	TF2_IsPlayerInCondition(client, TFCond_OnFire) || 
	TF2_IsPlayerInCondition(client, TFCond_BurningPyro)) return Plugin_Continue;
	if (GetClientTeam(entity) != GetClientTeam(client) && !IsClientObserver(client))
	{
		vecValues = oldOrigins[client];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
*/
#endif

void CheckMap()
{
	isMVM = IsMvM();
}

public void OnMapStart()
{
	CheckMap();
	
	//PrecacheSound(SND, true);
	//AddFileToDownloadsTable("sound/puppet/poof1.wav");
	PrecacheSound(UNCLOAK_SND, true);
	PrecacheSound(STOPWEP_SND, true);
	PrecacheSound(FALLGIB_SND, true);
	
	int ply_manager = GetPlayerResourceEntity();
	if (ply_manager != -1)
	{ SDKHook(ply_manager, THINK_POST_HOOK, Hook_OnThinkPost); }
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (g_fClientWait[client] >= THINK_WAITTIME)
		{
			g_fClientWait[client] = 0.0;
		}
	}
}

#define ACDR_BOX_TARGN "pl_ac_dr_box"
bool removePlayerHurtEv = false, removeRagdoll = true, carriedBuilding = false;
int originalDamage = -1;
public void OnEntityCreated(int entity, const char[] classname)
{
	bool isRagdoll = strcmp(classname, "tf_ragdoll", false) == 0;
	bool isAmmoPack = (g_iExtraEffects & BITFLAG_AMMOPACK && strcmp(classname, "tf_ammo_pack", false) == 0);
	if (
	(classname[0] != 't' || (!isRagdoll && !isAmmoPack))
	) return;
	
	if (carriedBuilding && isAmmoPack)
	{
		AcceptEntityInput(entity, "Kill");
		return;
	}
		
	if (!removeRagdoll)
	{
		if (isRagdoll)
			AcceptEntityInput(entity, "Kill");
		else
		{
			SDKHook(entity, SDKHook_SpawnPost, Hook_SpawnPost);
		}
	}
}

void Hook_SpawnPost(int entity)
{
	static char name[13];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	if (strcmp(name, ACDR_BOX_TARGN, false) != 0)
	{
		SDKHook(entity, SDKHook_Touch, Hook_OnTouch);
		//SetEntPropString(entity, Prop_Data, "m_iName", ACDR_BOX_TARGN);
		
		float origin[3], angles[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Data, "m_angRotation", angles);
		int ammo_box = CreateEntityByName("tf_ammo_pack");
		TeleportEntity(ammo_box, origin, angles, NULL_VECTOR);
		
		SetEntPropString(ammo_box, Prop_Data, "m_iName", ACDR_BOX_TARGN);
		
		static char model[64];
		GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
		DispatchKeyValue(ammo_box, "model", model);
		DispatchKeyValue(ammo_box, "effects", "32"); // 0x020 (EF_NODRAW)
		
		DispatchSpawn(ammo_box);
		ActivateEntity(ammo_box);
		SetEntProp(ammo_box, Prop_Data, "m_CollisionGroup", 1);
		
		SetVariantString("!activator");
		AcceptEntityInput(ammo_box, "SetParent", entity);
		SDKHook(ammo_box, SDKHook_Touch, Hook_OnTouch2);
		
		// Give Metal ammo from the box. Credits to Pelipoika: https://github.com/Pelipoika/TF2_NextBot/blob/master/tfpets.sp#L1558-L1559
		// TF_AMMO_METAL is index 3
		// CTFAmmoPack stores its ammo values in m_iAmmo, which is an array with ammo values for each weapon type.
		int Offset = ((3 * 4) + (FindDataMapInfo(ammo_box, "m_vOriginalSpawnAngles") + 20));
		SetEntData(ammo_box, Offset, 100, _, true);
		
		//SetEntProp(ammo_box, Prop_Send, "m_fEffects", (0x001 + 0x080)); //EF_BONEMERGE + EF_BONEMERGE_FASTCULL
	}
}

Action Hook_OnTouch(int entity, int client)
{
	return Plugin_Handled;
}

Action Hook_OnTouch2(int entity, int client)
{
	if (client > 0 && client <= MaxClients && isCloaked[client]) return Plugin_Handled;
	
	return Plugin_Continue;
}

public void OnEntityDestroyed(int entity)
{
	if (entity == -1) return;
	
	static char classname[13];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (strcmp(classname, "tf_ammo_pack", false) != 0) return;
	
	GetEntPropString(entity, Prop_Data, "m_iName", classname, sizeof(classname));
	if (strcmp(classname, ACDR_BOX_TARGN, false) != 0) return;
	
	int moveparent = GetEntPropEnt(entity, Prop_Send, "moveparent");
	if (moveparent != -1)
		AcceptEntityInput(moveparent, "Kill");
}

/*public void OnClientPutInServer(int client)
{
	if (!ResetACDRStuff(client)) return;
	
	HookThink(client);
}*/

public void OnClientDisconnect(int client)
{
	if (!ResetACDRStuff(client)) return;
	
	HookThink(client, false); // this might be useless or not
}

bool ResetACDRStuff(int client)
{
	can[client]	= true;
	trigger[client]	= false;
	isCloaked[client] = false;
	g_fUncloakTimer[client] = 0.0;
	//g_BoostTimer[client] = 0.0;
	g_fReadyTimer[client] = 0.0;
	
	//RemoveACDRRagdoll(client);
	SDKUnhook(client, CHANGE_DAMAGE_HOOK, Hook_OnTakeDamage);
	return true;
}

Action ACDR_Command(int client, any args)
{
	if (!IsValidClient(client)) return Plugin_Handled;
	TFClassType class = TF2_GetPlayerClass(client);
	if (class == TFClass_Spy && g_bClassRestrictSpy && !trigger[client]) return Plugin_Handled;
	
	if (!shouldTriggerDR(client)) return Plugin_Handled;
	
	TriggerACDR(client, true, false, false, false);
	return Plugin_Handled;
}

#if DEBUG
Action ACDR_Test(int client, int args)
{
	if (!IsValidClient(client) || !IsPlayerAliveNotGhost(client)) return Plugin_Handled;
	
	/*float meter = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
	TFClassType class = TF2_GetPlayerClass(client);
	
	if (TF2_IsPlayerInCondition(client, TFCond_Cloaked))
	{ TF2_RemoveCondition(client, TFCond_Cloaked); }
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 100.0);
	SetEntProp(client, Prop_Send, "m_iClass", TFClass_Spy);
	SetEntProp(client, Prop_Send, "m_bFeignDeathReady", 1);
	SDKHooks_TakeDamage(client, 0, 0, 1.0, DMG_GENERIC, -1);
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", meter);
	if (class != TFClass_Spy) SetEntProp(client, Prop_Send, "m_iClass", view_as<int>(class));
	
	if (!TF2_IsPlayerInCondition(client, TFCond_DeadRingered)) return Plugin_Handled;
	
	TF2_RemoveCondition(client, TFCond_DeadRingered);
	TF2_RemoveCondition(client, TFCond_Cloaked);
	TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
	
	DoClientScream(client, 2);
	
	//int old_rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	for (int i = 0; i < GetMaxEntities(); i++)
	{
		if (!RealValidEntity(i)) continue;
		//if (old_rag == i) continue;
		
		static char classname[PLATFORM_MAX_PATH+1];
		GetEntityClassname(i, classname, sizeof(classname));
		if (classname[0] != 't' || strcmp(classname, "tf_ragdoll", false) != 0) continue;
		PrintToChatAll("ltime: %i", GetEntPropFloat(i, Prop_Data, "m_flLocalTime"));
		float pos[3], ragPos[3];
		GetClientAbsOrigin(client, pos);
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", ragPos);
		
		if (pos[0]!=ragPos[0] || pos[1]!=ragPos[1] || pos[2]!=ragPos[2]) continue;
		
	//	int owner = GetEntPropEnt(i, Prop_Send, "m_hPlayer");
	//	PrintToChatAll("i: %i, owner: %i", i, owner);
	//	if (owner != client) continue;
		
		//bool bFeignDeath = view_as<bool>(GetEntProp(i, Prop_Send, "m_bFeignDeath"));
		//if (!bFeignDeath) continue;
		
		AcceptEntityInput(i, "Kill");
	}*/
	
	TF2_IgnitePlayer(client, client, 15.0);
	TF2_AddCondition(client, TFCond_Bleeding, 15.0);
	
	return Plugin_Handled;
}
#endif

Action ACDR_Force_Command(int client, any args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fd_ply <target>");
		return Plugin_Handled;
	}
	
	static char arg1[128];
	/* Get the first argument */
	GetCmdArg(1, arg1, sizeof(arg1));
	
	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	static char target_name[MAX_TARGET_LENGTH]; target_name[0] = '\0';
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if (!IsValidClient(target_list[i], true, true)) continue;
		
		int trigger_func = TriggerACDR(target_list[i], true, false, false, false);
		if (trigger_func > 0)
		{ ReplyToCommand(client, "[SM] Successfully toggled %N's AC-DR status to active.", target_list[i]); }
		else if (trigger_func == 0)
		{ ReplyToCommand(client, "[SM] Successfully toggled %N's AC-DR status to inactive.", target_list[i]); }
		else
		{ ReplyToCommand(client, "[SM] Could not toggle %N's AC-DR status.", target_list[i]); }
	}
	
	return Plugin_Handled;
}

/*void RemoveACDRRagdoll(int client)
{
	if (RealValidEntity(g_Ragdoll[client]))
	{
		static char classname[PLATFORM_MAX_PATH+1];
		GetEntityClassname(g_Ragdoll[client], classname, sizeof(classname));
		if (strcmp(classname, "tf_ragdoll", false) == 0)
		{
			AcceptEntityInput(g_Ragdoll[client], "Kill");
		}
		//SetEntProp(client, Prop_Send, "m_hRagdoll", -1);
		g_Ragdoll[client] = INVALID_ENT_REFERENCE;
	}
}*/

void DisguiseRagdollFix(int client)
{
	TFTeam team = view_as<TFTeam>(GetClientTeam(client));
	TFTeam disguise_team = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_nDisguiseTeam"));
	TFClassType disguise_class = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
	if (disguise_class > TFClass_Unknown && disguise_class != TFClass_Spy && (!g_bFriendlyDisguise || disguise_team != team))
	{
		SetEntProp(client, Prop_Send, "m_nDisguiseTeam", team);
		SetEntProp(client, Prop_Send, "m_nDisguiseClass", TF2_GetPlayerClass(client));
		//SetEntPropEnt(client, Prop_Send, "m_hDisguiseTarget", client);
		SetEntProp(client, Prop_Send, "m_nDisguiseSkinOverride", GetEntProp(client, Prop_Send, "m_iPlayerSkinOverride"));
		SetEntProp(client, Prop_Send, "m_nMaskClass", TFClass_Spy);
		// ^ The spy disguise assumed will have the Uber skin that could be seen for a milisecond
		// if m_nMaskClass isn't changed to spy here.
		
		DataPack dataP = CreateDataPack();
		dataP.WriteCell(GetClientUserId(client));
		dataP.WriteCell(disguise_class);
		dataP.WriteCell(disguise_team);
		//dataP.WriteCell(GetEntProp(client, Prop_Send, "m_hDisguiseTarget"));
		dataP.WriteCell(GetEntProp(client, Prop_Send, "m_nDisguiseSkinOverride"));
		dataP.WriteCell(GetEntProp(client, Prop_Send, "m_nMaskClass"));
		RequestFrame(DisguiseRagdollFix_ReqFrame, dataP);
	}
}

void DisguiseRagdollFix_ReqFrame(DataPack dataP)
{
	dataP.Reset();
	int client = GetClientOfUserId(dataP.ReadCell());
	TFClassType disguise_class = view_as<TFClassType>(dataP.ReadCell());
	TFTeam disguise_team = view_as<TFTeam>(dataP.ReadCell());
	//int disguise_index = dataP.ReadCell();
	int disguise_skin = dataP.ReadCell();
	int mask_class = dataP.ReadCell();
	if (dataP != null) CloseHandle(dataP);
	
	if (client == 0 || !IsPlayerAliveNotGhost(client) || disguise_class <= TFClass_Unknown) return;
	
	//TF2_AddCondition(client, TFCond_Disguised);
	SetEntProp(client, Prop_Send, "m_nDisguiseTeam", disguise_team);
	SetEntProp(client, Prop_Send, "m_nDisguiseClass", disguise_class);
	//SetEntProp(client, Prop_Send, "m_hDisguiseTarget", disguise_index);
	SetEntProp(client, Prop_Send, "m_nDisguiseSkinOverride", disguise_skin);
	SetEntProp(client, Prop_Send, "m_nMaskClass", mask_class);
}

void SpawnACDRRagdoll(int client, int weapon, const float damage, int damageType, const float damageForce[3], int damagecustom, bool isOnFire = false, bool isSilent = false)
{
	//SDKCall(hCreateRagdollEntity, client);
	
	//RemoveACDRRagdoll(client);
	
	int ragdoll = CreateEntityByName("tf_ragdoll");
	// IMPORTANT NOTICE: The real ragdoll created by the player will bug and stay indefinitely, should the player have created 
	// an AC-DR corpse which gets set as a 'real' ragdoll in m_hRagdoll. Watch out!
	if (ragdoll == -1) return;
	
	float origin[3];
	
	GetClientAbsOrigin(client, origin);
	SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollOrigin", origin);
	SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", damageForce);
	TeleportEntity(ragdoll, origin, NULL_VECTOR, NULL_VECTOR);
	
	//SetEntPropString(ragdoll, Prop_Data, "m_iName", "");
	
	TFClassType class = TF2_GetPlayerClass(client);
	TFTeam team = view_as<TFTeam>(GetClientTeam(client));
	
	TFClassType disguise_class = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
	TFTeam disguise_team = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_nDisguiseTeam"));
	//int disguise_index = GetEntProp(client, Prop_Send, "m_hDisguiseTarget");
	if (IsDisguisedAsFriendly(client))
	{
		SetEntProp(ragdoll, Prop_Send, "m_iClass", disguise_class);
		SetEntProp(ragdoll, Prop_Send, "m_iTeam", disguise_team);
		//SetEntProp(ragdoll, Prop_Send, "m_bFeignDeath", 1);
		SetEntProp(ragdoll, Prop_Send, "m_bWasDisguised", 1); // This makes the ragdoll use the disguise cosmetics instead of the real spy's cosmetics.
	}
	else
	{
		SetEntProp(ragdoll, Prop_Send, "m_iClass", class);
		SetEntProp(ragdoll, Prop_Send, "m_iTeam", team);
	} // NOTE: There's a glitch with disguises where the gibs are the fake class.
	//if (!IsDisguised(client))
	SetEntPropEnt(ragdoll, Prop_Send, "m_hPlayer", client);
	
	// TF_CUSTOM_BURNING accounts for regular flamethrow burn, afterburn, hadouken burn, dragon fury annd some others
	// TF_CUSTOM_BURNING_FLARE accounts for flares including indirect detonation from Detonator but not Scorch direct
	//if ((((damagecustom & TF_CUSTOM_BURNING) && !(damagecustom & TF_CUSTOM_BLEEDING)) || (damagecustom & TF_CUSTOM_BURNING_FLARE)) && 
	//class != TFClass_Pyro && disguise_class != TFClass_Pyro)
	if (isOnFire && class != TFClass_Pyro && disguise_class != TFClass_Pyro)
		SetEntProp(ragdoll, Prop_Send, "m_bBurning", 1);
	
	int skin = GetEntProp(client, Prop_Send, "m_iPlayerSkinOverride"); // Check for Voodoo cosmetics
	if (IsDisguisedAsFriendly(client))
		skin = GetEntProp(client, Prop_Send, "m_nDisguiseSkinOverride");
	
	int wep_index = -1;
	if (RealValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
		wep_index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	bool isClassic = CheckForWeaponType(wep_index, TYPE_CLASSIC);
	
	if
	(
		(
			(
				(damageType & DMG_BLAST)
				|| // or
				isClassic
			)
			&& // and
			(
				damage > 10.0
				|| // or
				(damageType & DMG_CRIT)
			)
			&& // and
			g_iPlayerGib == 1
			|| // or
			g_iPlayerGib >= 2
		)
	)
	{
		if (skin != 1)
		{
			SetEntProp(ragdoll, Prop_Send, "m_bFeignDeath", 1); // This allows creating multiple gib groups but screws up bodygroups
			if (isClassic)
			{
				SetEntProp(ragdoll, Prop_Send, "m_bCritOnHardHit", 1);
				/*float EyePosition[3];
				GetClientEyePosition(client, EyePosition);
				// The Classic's gibbing effect (1098), but how to detect if shot was fully charged? tfc_sniper_mist tfc_sniper_mist2
				int particle = CreateEntityByName("info_particle_system");
				DispatchKeyValue(particle, "effect_name", "tfc_sniper_mist");
				DispatchSpawn(particle);
				ActivateEntity(particle);
				TeleportEntity(particle, EyePosition, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(particle, "Start");
				SetVariantString("OnUser1 !self:Kill::0.1:1");
				AcceptEntityInput(particle, "AddOutput");
				AcceptEntityInput(particle, "FireUser1");*/
			}
		}
		SetEntProp(ragdoll, Prop_Send, "m_bGib", 1);
		//int gibHead = CreateEntityByName("raggib");
		//SetEntPropVector(gibHead, Prop_Send, "m_vecOrigin", origin);
	}
	if (damagecustom) SetEntProp(ragdoll, Prop_Send, "m_iDamageCustom", damagecustom);
	if ((damagecustom & TF_CUSTOM_DECAPITATION) || (damagecustom & TF_CUSTOM_DECAPITATION_BOSS))
	{
		// It looks like decapitations still screw the cosmetics up either way, so set m_bFeignDeath to 1 anyway
		// because further head gibs will not be created if a head gib already exists.
		SetEntProp(ragdoll, Prop_Send, "m_bFeignDeath", 1);
	}
	
	if (RealValidEntity(weapon) && wep_index > -1)
	{
		static char wep_netclass_attacker[24];
		GetEntityClassname(weapon, wep_netclass_attacker, sizeof(wep_netclass_attacker));
		//PrintToChatAll("%s", wep_netclass_attacker); // Debug
		
		if (wep_netclass_attacker[0] && 
		(strncmp(wep_netclass_attacker, "tf_weapon", 9, false) == 0 || strncmp(wep_netclass_attacker, "tf_wearable", 11, false) == 0))
		{
			if (CheckForWeaponType(wep_index, TYPE_NEONLATOR)) // Neon Annihilator (For some reason it's assigned 2 IDs. https://steamcommunity.com/sharedfiles/filedetails/?id=504159631)
			{ SetEntProp(ragdoll, Prop_Send, "m_iDamageCustom", TF_CUSTOM_PLASMA); }
			else if (CheckForWeaponType(wep_index, TYPE_SPYCICLE) && (damagecustom & TF_CUSTOM_BACKSTAB)) // Spy-cicle
			{ SetEntProp(ragdoll, Prop_Send, "m_bIceRagdoll", 1); }
			else if (CheckForWeaponType(wep_index, TYPE_MANMELTER) || 
			CheckForWeaponType(wep_index, TYPE_THIRDDEGREE) || 
			CheckForWeaponType(wep_index, TYPE_PHLOG)) // Manmelter (595) + The Third Degree (593) + Phlogistinator (594)
			{ SetEntProp(ragdoll, Prop_Send, "m_bBecomeAsh", 1); }
			else if (isSilent) // Your Eternal Reward (225) + Wanga Prick (574)
			{ SetEntProp(ragdoll, Prop_Send, "m_bCloaked", 1); }
			else if (CheckForWeaponType(wep_index, TYPE_GOLDWRENCH) || 
			CheckForWeaponType(wep_index, TYPE_GOLDPAN) || 
			CheckForWeaponType(wep_index, TYPE_SAXXY)) // Golden Wrench + Golden Pan + Saxxy (Gold Ragdoll)
			{ SetEntProp(ragdoll, Prop_Send, "m_bGoldRagdoll", 1); }
		}
	}
	
	SetEntProp(ragdoll, Prop_Send, "m_nForceBone", GetEntProp(client, Prop_Send, "m_nForceBone"));
	if (view_as<bool>(GetEntityFlags(client) & FL_ONGROUND))
	{ SetEntProp(ragdoll, Prop_Send, "m_bOnGround", 1); }
	
	SetEntPropFloat(ragdoll, Prop_Send, "m_flHeadScale", GetEntPropFloat(client, Prop_Send, "m_flHeadScale"));
	SetEntPropFloat(ragdoll, Prop_Send, "m_flTorsoScale", GetEntPropFloat(client, Prop_Send, "m_flTorsoScale"));
	SetEntPropFloat(ragdoll, Prop_Send, "m_flHandScale", GetEntPropFloat(client, Prop_Send, "m_flHandScale"));
	
	int old_rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (old_rag != -1)
	{ AcceptEntityInput(old_rag, "Kill"); }
	SetEntPropEnt(client, Prop_Send, "m_hRagdoll", ragdoll);
	
	DispatchSpawn(ragdoll);
	ActivateEntity(ragdoll);
	
	//g_Ragdoll[client] = ragdoll;
}

void ModelIndexToString(int index, char[] model, int size)
{
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
}

void WeaponAttackAvailable(int client, bool boolean)
{
	/*int cl_class = GetEntProp(client, Prop_Send, "m_iClass");
	if (cl_class != 8)
	{
		SetEntProp(client, Prop_Send, "m_bFeignDeathReady", boolean ? 0 : 1);
		return;
	}*/
	float game_time = GetGameTime();
	
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", boolean ? game_time + g_fWeaponTime : game_time + 86400.0);
	int slotP = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	int slotS = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	int slotM = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	int slotO = GetPlayerWeaponSlot(client, TFWeaponSlot_Grenade); // To be honest I don't know why I included this.
	int offset = FindSendPropInfo("CTFWeaponBase", "m_flNextPrimaryAttack");
	int offset2 = FindSendPropInfo("CTFWeaponBase", "m_flNextSecondaryAttack");
	
	if (slotP != -1)
	{
		SetEntPropFloat(slotP, Prop_Data, "m_flNextPrimaryAttack", boolean ? game_time + g_fWeaponTime : game_time + 86400.0);
		SetEntPropFloat(slotP, Prop_Data, "m_flNextSecondaryAttack", boolean ? game_time + g_fWeaponTime : game_time + 86400.0);
		ChangeEdictState(slotP, offset);
		ChangeEdictState(slotP, offset2);
	}
	if (slotS != -1)
	{
		SetEntPropFloat(slotS, Prop_Data, "m_flNextPrimaryAttack", boolean ? game_time + g_fWeaponTime : game_time + 86400.0);
		SetEntPropFloat(slotS, Prop_Data, "m_flNextSecondaryAttack", boolean ? game_time + g_fWeaponTime : game_time + 86400.0);
		ChangeEdictState(slotS, offset);
		ChangeEdictState(slotS, offset2);
	}
	if (slotM != -1)
	{
		SetEntPropFloat(slotM, Prop_Data, "m_flNextPrimaryAttack", boolean ? game_time + g_fWeaponTime : game_time + 86400.0);
		SetEntPropFloat(slotM, Prop_Data, "m_flNextSecondaryAttack", boolean ? game_time + g_fWeaponTime : game_time + 86400.0);
		ChangeEdictState(slotM, offset);
		ChangeEdictState(slotM, offset2);
	}
	if (slotO != -1)
	{
		SetEntPropFloat(slotO, Prop_Data, "m_flNextPrimaryAttack", boolean ? game_time + g_fWeaponTime : game_time + 86400.0);
		SetEntPropFloat(slotO, Prop_Data, "m_flNextSecondaryAttack", boolean ? game_time + g_fWeaponTime : game_time + 86400.0);
		ChangeEdictState(slotO, offset);
		ChangeEdictState(slotO, offset2);
	}
}

/*bool HasSlotWeaponType(int client, int slot, int type)
{
	int slotEnt = GetPlayerWeaponSlot(client, slot);
	
	int wep_index = -1;
	if (HasEntProp(slotEnt, Prop_Send, "m_iItemDefinitionIndex"))
	{ wep_index = GetEntProp(slotEnt, Prop_Send, "m_iItemDefinitionIndex"); }
	
	if (wep_index != -1 && wep_index == type) return true;
	
	return false;
}*/

void AcquireModel(int slotEnt, char[] str, int maxlength)
{
	if (HasEntProp(slotEnt, Prop_Send, "m_iWorldModelIndex"))
	{
		int modelidx = GetEntProp(slotEnt, Prop_Send, "m_iWorldModelIndex");
		ModelIndexToString(modelidx, str, maxlength);
	}
	else
	{
		// demo shield does not have m_iWorldModelIndex
		GetEntPropString(slotEnt, Prop_Data, "m_ModelName", str, maxlength);
	}
	//PrintToServer("Model Name: %s", str);
}

bool CheckForWeaponType(int wep_index, int desiredType)
{
	/*
	if (model[0] == '\0') return false;
	// m_nSkin sadly doesn't work
	switch (desiredType)
	{
		case TYPE_GLOVES:			return (strcmp(model, "models/weapons/c_models/c_boxing_gloves/c_boxing_gloves.mdl"								, false) == 0);
		case TYPE_POWERJACK:		return (strcmp(model, "models/workshop/weapons/c_models/c_powerjack/c_powerjack.mdl"								, false) == 0);
		case TYPE_BEARCLAWS:		return (strcmp(model, "models/workshop/weapons/c_models/c_bear_claw/c_bear_claw.mdl"								, false) == 0);
		case TYPE_ZATOICHI:		return (strcmp(model, "models/workshop_partner/weapons/c_models/c_shogun_katana/c_shogun_katana_soldier.mdl"		, false) == 0);
		case TYPE_CANDYCANE:		return (strcmp(model, "models/workshop/weapons/c_models/c_candy_cane/c_candy_cane.mdl"							, false) == 0);
		case TYPE_CLASSIC:		return (strcmp(model, "models/weapons/c_models/c_tfc_sniperrifle/c_tfc_sniperrifle.mdl"							, false) == 0);
		case TYPE_NEONLATOR:		return (strcmp(model, "models/workshop_partner/weapons/c_models/c_sd_neonsign/c_sd_neonsign.mdl"					, false) == 0);
		case TYPE_SPYCICLE:		return (strcmp(model, "models/workshop/weapons/c_models/c_xms_cold_shoulder/c_xms_cold_shoulder.mdl"				, false) == 0);
		case TYPE_MANMELTER:		return (strcmp(model, "models/workshop/weapons/c_models/c_drg_manmelter/c_drg_manmelter.mdl"						, false) == 0);
		case TYPE_THIRDDEGREE:	return (strcmp(model, "models/workshop/weapons/c_models/c_drg_thirddegree/c_drg_thirddegree.mdl"					, false) == 0);
		case TYPE_PHLOG:			return (strcmp(model, "models/workshop/weapons/c_models/c_drg_phlogistinator/c_drg_phlogistinator.mdl"			, false) == 0);
		case TYPE_EREWARD:		return (strcmp(model, "models/workshop/weapons/c_models/c_eternal_reward/c_eternal_reward.mdl"					, false) == 0);
		case TYPE_WPRICK:			return (strcmp(model, "models/workshop/weapons/c_models/c_voodoo_pin/c_voodoo_pin.mdl"							, false) == 0);
		case TYPE_BEARNER:		return (strcmp(model, "models/workshop/weapons/c_models/c_switchblade/c_switchblade.mdl"							, false) == 0);
		case TYPE_GOLDWRENCH:		return (strcmp(model, "models/weapons/c_models/c_wrench/c_wrench.mdl"														, false) == 0 
		&& wep_index == 169);
		case TYPE_GOLDPAN:		return (strcmp(model, "models/weapons/c_models/c_frying_pan/c_frying_pan.mdl"									, false) == 0 
		&& wep_index == 1071);
		case TYPE_SAXXY:			return (strcmp(model, "models/weapons/c_models/c_saxxy/c_saxxy.mdl"												, false) == 0);
	}*/
	
	switch (desiredType)
	{
		case TYPE_GLOVES:			return wep_index == 43;							// Killing Gloves Of Boxing
		case TYPE_POWERJACK:		return wep_index == 214;							// Powerjack
		case TYPE_BEARCLAWS:		return wep_index == 310;							// Warrior's Spirit
		case TYPE_ZATOICHI:		return wep_index == 357;							// Half-Zatoichi
		case TYPE_CANDYCANE:		return wep_index == 317;							// Candy Cane
		case TYPE_CLASSIC:		return wep_index == 1098;						// Classic
		case TYPE_NEONLATOR:		return wep_index == 813 || wep_index == 834;		// Neon Annihilator
		case TYPE_SPYCICLE:		return wep_index == 649;							// Spy-cicle
		case TYPE_MANMELTER:		return wep_index == 595;							// Manmelter
		case TYPE_THIRDDEGREE:	return wep_index == 593;							// Third Degree
		case TYPE_PHLOG:			return wep_index == 594;							// Phlogistinator
		case TYPE_EREWARD:		return wep_index == 225;							// Your Eternal Reward
		case TYPE_WPRICK:			return wep_index == 574;							// Wanga Prick
		case TYPE_BEARNER:		return wep_index == 461;							// Big Earner
		case TYPE_GOLDWRENCH:		return wep_index == 169;							// Golden Wrench
		case TYPE_GOLDPAN:		return wep_index == 1071;						// Golden Frying Pan
		case TYPE_SAXXY:			return wep_index == 423;							// Saxxy
	}
	return false;
}
/*
int GetWeaponType(int slotEnt)
{
	if (!RealValidEntity(slotEnt)) return -1;
	
	static char model[128];
	//GetEntPropString(slotEnt, Prop_Data, "m_ModelName", model, sizeof(model));
	int modelidx = GetEntProp(slotEnt, Prop_Send, "m_iWorldModelIndex");
	ModelIndexToString(modelidx, model, sizeof(model));
	//PrintToServer("Model Name: %s", model);
	
	if (strcmp(model, "models/weapons/c_models/c_boxing_gloves/c_boxing_gloves.mdl", false) == 0)
	{ return TYPE_GLOVES; }
	else if (strcmp(model, "models/workshop/weapons/c_models/c_powerjack/c_powerjack.mdl", false) == 0)
	{ return TYPE_POWERJACK; }
	else if (strcmp(model, "models/workshop/weapons/c_models/c_bear_claw/c_bear_claw.mdl", false) == 0)
	{ return TYPE_BEARCLAWS; }
	else if (strcmp(model, "models/workshop_partner/weapons/c_models/c_shogun_katana/c_shogun_katana_soldier.mdl", false) == 0)
	{ return TYPE_ZATOICHI; }
	else if (strcmp(model, "models/workshop/weapons/c_models/c_candy_cane/c_candy_cane.mdl", false) == 0)
	{ return TYPE_CANDYCANE; }
	else if (strcmp(model, "models/weapons/c_models/c_tfc_sniperrifle/c_tfc_sniperrifle.mdl", false) == 0)
	{ return TYPE_CLASSIC; }
	else if (strcmp(model, "models/workshop_partner/weapons/c_models/c_sd_neonsign/c_sd_neonsign.mdl", false) == 0)
	{ return TYPE_NEONLATOR; }
	else if (strcmp(model, "models/workshop/weapons/c_models/c_xms_cold_shoulder/c_xms_cold_shoulder.mdl", false) == 0)
	{ return TYPE_SPYCICLE; }
	else if (strcmp(model, "models/workshop/weapons/c_models/c_drg_manmelter/c_drg_manmelter.mdl", false) == 0)
	{ return TYPE_MANMELTER; }
	else if (strcmp(model, "models/workshop/weapons/c_models/c_drg_thirddegree/c_drg_thirddegree.mdl", false) == 0)
	{ return TYPE_THIRDDEGREE; }
	else if (strcmp(model, "models/workshop/weapons/c_models/c_drg_phlogistinator/c_drg_phlogistinator.mdl", false) == 0)
	{ return TYPE_PHLOG; }
	else if (strcmp(model, "models/workshop/weapons/c_models/c_eternal_reward/c_eternal_reward.mdl", false) == 0)
	{ return TYPE_EREWARD; }
	else if (strcmp(model, "models/workshop/weapons/c_models/c_voodoo_pin/c_voodoo_pin.mdl", false) == 0)
	{ return TYPE_WPRICK; }
	
	return -1;
}
*/
void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	//int death_flags = event.GetInt("death_flags", 0);
	//if (death_flags & TF_DEATHFLAG_DEADRINGER) {PrintToChatAll("Flags"); return;}
	
	int userID = event.GetInt("userid", 0);
	int client = GetClientOfUserId(userID);
	if (client == 0) return;
	
	//if (IsPlayerAlive(client)) return;
	
	if (isCloaked[client])
		ACDRUncloak(client);
	else if (trigger[client])
		TriggerACDR(client, true, true, true, false);
	
	if ((g_iBots & BITFLAG_SPAWNTOGGLE) && IsFakeClient(client) && shouldTriggerDR(client))
		TriggerACDR(client, false, true, true, true);
}

Action player_hurt(Event event, const char[] name, bool dontBroadcast) 
{
	if (removePlayerHurtEv) return Plugin_Handled;
	
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	if (client == 0) return Plugin_Continue;
	
	if (trigger[client])
		event.SetInt("health", 0);
	
	if (isCloaked[client])
		event.BroadcastDisabled = true;
	
	if (originalDamage >= 0)
	{
		int setDmg = originalDamage;
		if (event.GetBool("minicrit")) setDmg = RoundToCeil(setDmg * 1.35);
		else if (event.GetBool("crit")) setDmg *= 3;
		event.SetInt("damageamount", setDmg);
	}
	
	return Plugin_Continue;
}

void player_death(Event event, const char[] name, bool dontBroadcast) 
{
	RequestFrame(plyDeath_RF_check, event.GetInt("userid", 0));
}
void plyDeath_RF_check(int client)
{
	client = GetClientOfUserId(client);
	if (client == 0 || client > MaxClients || IsPlayerAliveNotGhost(client)) return;
	
	plyDeath_ResetACDR(client);
}
void plyDeath_ResetACDR(int client)
{
	if (isCloaked[client])
	{ ACDRUncloak(client); }
	else if (trigger[client])
	{ TriggerACDR(client, true, true, true, false); }
	if (isCloaked[client] || !can[client])
	{ Timer_Ready(client); }
	ResetACDRStuff(client);
	
	if ((g_iBots & BITFLAG_SPAWNTOGGLE) && IsFakeClient(client) && shouldTriggerDR(client))
		TriggerACDR(client, false, true, true, true);
}

Action Hook_OnTakeDamage(int client, int& attacker, int& inflictor, float& damage, int& damageType, int& weapon, 
float damageForce[3], float damagePosition[3], int damagecustom)
{
	//PrintToChatAll("%i %i %i %f %i", client, attacker, inflictor, damage, damageType);
	//PrintToChatAll("can: %i trigger: %i isCloaked: %i", can[client], trigger[client], isCloaked[client]);
	if (damage <= 0.0) return Plugin_Continue;
	
	if (client == 0 || !canTriggerDR(client)) return Plugin_Continue;
	/*if (!friendlyfire_cvar.BoolValue && RealValidEntity(attacker))
	{
		if (GetEntProp(attacker, Prop_Data, "m_iTeamNum") == GetClientTeam(client) && attacker != client)
			return Plugin_Continue;
	}*/
	float game_time = GetGameTime();
	
	float old_damage = damage;
	
	float finalResult = damage;
	if (can[client] && trigger[client] || g_fResistTimer[client] > game_time)
	//if (g_fResistTimer[client] > game_time)
	{
		float cloak_time = g_fUncloakTimer[client]-GetGameTime();
		if (trigger[client]) // If client has trigger state then always assume the max
		{ cloak_time = g_fCloakTime; }
		
		if (cloak_time >= 0.0 && g_fDamageRes_Max >= g_fDamageRes_Min)
		{
			float maxMinusMin = g_fDamageRes_Max-g_fDamageRes_Min; // 0.65 - 0.2 = 0.45
			float minAndMMM = maxMinusMin / (cloak_time+1.0);
			// 0.45 / 7.5 = 0.06
			// 0.45 / 7.4 = 0.06[number gibberish, how tf do i condense it to just 0.06?]
			// 0.45 / 1.0 = 0.45
			
			maxMinusMin = g_fDamageRes_Max-minAndMMM;
			// 0.65 - 0.06 = 0.59
			//finalResult = damage*(RoundFloat(maxMinusMin * 100)); // truncate to just 2 decimal numbers (doesn't work)
			finalResult = damage*maxMinusMin;
		}
	}
	
	if (!can[client] || !trigger[client])
	{
		damage = finalResult;
		return Plugin_Changed;
	}
	
	int infl = RealValidEntity(inflictor) ? inflictor : 0;
	int atta = RealValidEntity(attacker) ? attacker : 0;
	
	//bool damageHurts = false;
	//if (damage >= 1.0) damageHurts = true;
	//PrintToServer("damageHurts: %i", damageHurts);
	int old_hp = GetClientHealth(client); // Store the client's old hp.
	SetEntityHealth(client, old_hp+100); // We add an extra 100 to client's health.
	
	//if (damageHurts) // If damage hurts, remove the player_hurt from this damage test
	//	removePlayerHurtEv = true;
	//else // Preserve this player_hurt event instead
	originalDamage = RoundToCeil(damage);
	
	SDKHooks_TakeDamage(client, infl, atta, 5.0, damageType, weapon, damageForce, damagePosition); // Then we do a test of 5 damage.
	originalDamage = -1; damage = 0.0;
	int compare_hp = GetClientHealth(client); // Store the new hp.
	SetEntityHealth(client, old_hp); // Reset health back to oldest health.
	if (compare_hp >= old_hp+100) // If old hp is higher or the same as client's new health, assume we didn't take damage.
		return Plugin_Changed;
	// ^ This is cheese.
	
	removePlayerHurtEv = true;
	SDKHooks_TakeDamage(client, infl, atta, finalResult, damageType, weapon, damageForce, damagePosition);
	removePlayerHurtEv = false;
	
	if (!IsPlayerAliveNotGhost(client))
	{
		plyDeath_ResetACDR(client);
		return Plugin_Changed;
	}
	
	float meter = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
	TFClassType class = TF2_GetPlayerClass(client);
	
	TF2_RemoveCondition(client, TFCond_Cloaked);
	TF2_RemoveCondition(client, TFCond_Taunting);
	
	int disguiseWep = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
	if (!IsDisguisedAsFriendly(client))
	{
		g_iClassForResource[client] = class;
		if (disguiseWep != -1)
			SetEntProp(client, Prop_Send, "m_hDisguiseWeapon", -1);
	}
	else
	{
		g_iClassForResource[client] = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
		disguiseWep = -1;
	}
	
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 100.0);
	SetEntProp(client, Prop_Send, "m_iClass", TFClass_Spy);
	SetEntProp(client, Prop_Send, "m_bFeignDeathReady", 1);
	
	bool isOnFire = (TF2_IsPlayerInCondition(client, TFCond_OnFire) || TF2_IsPlayerInCondition(client, TFCond_BurningPyro));
	
	/*switch (class)
	{
		case TFClass_Scout:		SetVariantString("playerclass:Scout:0.1");
		case TFClass_Sniper:	SetVariantString("playerclass:Sniper:0.1");
		case TFClass_Soldier:	SetVariantString("playerclass:Soldier:0.1");
		case TFClass_DemoMan:	SetVariantString("playerclass:Demoman:0.1");
		case TFClass_Medic:		SetVariantString("playerclass:Medic:0.1");
		case TFClass_Heavy:		SetVariantString("playerclass:Heavy:0.1");
		case TFClass_Pyro:		SetVariantString("playerclass:Pyro:0.1");
		case TFClass_Spy:		SetVariantString("playerclass:Spy:0.1");
		case TFClass_Engineer:	SetVariantString("playerclass:Engineer:0.1");
	}*/
	DisguiseRagdollFix(client);
	DoBuildingFakeDeath(client, atta);
	removeRagdoll = false; removePlayerHurtEv = true;
	old_hp = GetClientHealth(client);
	SetEntityHealth(client, 69420);
	SDKHooks_TakeDamage(client, infl, atta, 1.0, damageType, weapon, damageForce, damagePosition);
	SetEntityHealth(client, old_hp);
	removeRagdoll = true; removePlayerHurtEv = false;
	
	TF2_RemoveCondition(client, TFCond_AfterburnImmune);
	TF2_RemoveCondition(client, TFCond_Slowed);
	TF2_RemoveCondition(client, TFCond_Zoomed);
	/*if (isOnFire)
	{
		TF2_IgnitePlayer(client, atta, 0.1);
	}*/
	//if (isTaunting)
	//{ TF2_AddCondition(client, TFCond_Taunting); }
	
	if (disguiseWep != -1)
	{ SetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon", disguiseWep); }
	
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", meter);
	if (class != TFClass_Spy) SetEntProp(client, Prop_Send, "m_iClass", class);
	
	int wep_index = -1;
	if (RealValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
		wep_index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	bool isSilent = (CheckForWeaponType(wep_index, TYPE_EREWARD) || CheckForWeaponType(wep_index, TYPE_WPRICK));
	
	if (!isSilent)
	{
		if ( ((damageType & DMG_CRIT) || (damageType & DMG_CLUB)) && !(damageType & DMG_BLAST))
		{ DoClientScream(client, 2); }
		else if (damageType & DMG_BLAST)
		{ DoClientScream(client, 0); }
		else if (damageType & DMG_FALL)
		{ DoClientScream(client, 3); }
		else
		{ DoClientScream(client, 1); }
	}
	else
	{ StopScene(client); }
	
	TF2_RemoveCondition(client, TFCond_DeadRingered);
	TF2_RemoveCondition(client, TFCond_Cloaked);
	TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
	
	SpawnACDRRagdoll(client, weapon, old_damage, damageType, damageForce, damagecustom, isOnFire, isSilent);
	
	ACDRCloak(client, atta, weapon, damagecustom, isSilent);
	return Plugin_Changed;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon)
{
	if (client == 0 || !IsPlayerAliveNotGhost(client)) return Plugin_Continue;
	
	if (!isCloaked[client]) return Plugin_Continue;
	
	bool hasChanged = false;
	
	if (buttons & IN_ATTACK)
    {
		buttons &= ~IN_ATTACK;
		hasChanged = true;
	}
	if (buttons & IN_ATTACK2)
    {
		buttons &= ~IN_ATTACK2;
		hasChanged = true;
		if (!g_bUsingM2[client])
		{
			g_fUncloakTimer[client] = GetGameTime();
			Timer_Uncloak(client);
		}
	}
	else if (!(buttons & IN_ATTACK2) && g_bUsingM2[client])
	{
		g_bUsingM2[client] = false;
	}
	
	if (hasChanged)
	{ return Plugin_Changed; }
	return Plugin_Continue;
}

void ACDRCloak(int client, int attacker = -1, int weapon = -1, int damagecustom = 0, bool isSilent = false)
{
	HookThink(client);
	
	float game_time = GetGameTime();
	//{ g_fUncloakTimer[client] = CreateTimer(time, Timer_Uncloak, client); }
	//g_BoostTimer[client] = CreateTimer(3.0, Timer_Boost, client);
	
	g_fUncloakTimer[client] = game_time+g_fCloakTime;
	//g_BoostTimer[client] = game_time+3.0;
	g_fReadyTimer[client] = g_fRechargeTime;
	g_fResistTimer[client] = game_time+3.0;
	
	int buttons = GetEntProp(client, Prop_Data, "m_nButtons");
	if (buttons & IN_ATTACK2)
	{
		g_bUsingM2[client] = true; // For OnPlayerRunCmd
	}
	
	TF2_AddCondition(client, TFCond_StealthedUserBuffFade);
	if (g_fAfterburnImmune > 0.0) TF2_AddCondition(client, TFCond_AfterburnImmune, g_fAfterburnImmune);
	if (g_fSpeedBoost > 0.0) TF2_AddCondition(client, TFCond_SpeedBuffAlly, g_fSpeedBoost);
	
	//SpawnACDRWeaponAmmoBox(client);
	if (g_fCloakTime > 0.0)
	{ WeaponAttackAvailable(client, false); }
	
	FakeClientCommand(client, "dropitem"); FakeClientCommand(client, "dropitem"); FakeClientCommand(client, "dropitem");
	
	TF2_RemoveCondition(client, TFCond_OnFire);
	TF2_RemoveCondition(client, TFCond_Bleeding);
	TF2_RemoveCondition(client, TFCond_BurningPyro);
	TF2_RemoveCondition(client, TFCond_Cloaked);
	//TF2_RemoveCondition(client, TFCond_Taunting);
	
	if (IsValidClient(attacker) && attacker != client)
	{
		TFTeam team = view_as<TFTeam>(GetClientTeam(client));
		if (TF2_IsHolidayActive(TFHoliday_Halloween))
		{
			float EyePosition[3];
			GetClientEyePosition(client, EyePosition);
			int soul = CreateEntityByName("halloween_souls_pack");
			SetEntProp(soul, Prop_Send, "m_iTeamNum", team);
			SetEntPropEnt(soul, Prop_Send, "m_hTarget", attacker);
			
			TeleportEntity(soul, EyePosition, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(soul);
			ActivateEntity(soul);
		}
		
		if (g_iExtraEffects & BITFLAG_EXTRAEFFECT)
		{
			if (isSilent && (damagecustom & TF_CUSTOM_BACKSTAB))
			{ _TF2_ImmediateDisguisePlayer(attacker, team, TF2_GetPlayerClass(client), client); }
			//{ _TF2_ImmediateDisguisePlayer(attacker, client); }
			else
			{
				//PrintToChatAll("%i", wep_index);
				int killcount_last_deploy = GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy");
				SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", killcount_last_deploy + 1);
				// ^ This is to make sure the katana can unsheath again without self damage
				
				int wep_index = -1;
				if (RealValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
					wep_index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				
				// Active Weapon Buffs
				if (CheckForWeaponType(wep_index, TYPE_GLOVES)) // Killing Gloves Of Boxing (5-Second Crit Boost)
				{ TF2_AddCondition(attacker, TFCond_CritOnKill, 5.0); }
				else if (CheckForWeaponType(wep_index, TYPE_POWERJACK)) // Powerjack (Health Boost)
				{ GiveHealth(attacker, 25); }
				else if (CheckForWeaponType(wep_index, TYPE_BEARCLAWS)) // Warrior's Spirit (Health Boost)
				{ GiveHealth(attacker, 50); }
				else if (CheckForWeaponType(wep_index, TYPE_ZATOICHI)) // Half-Zatoichi (Health Boost)
				{
					GiveHealth(attacker, (GetResourceProperty(attacker, Prop_Send, "m_iMaxHealth")/2), true, false);
					//PrintToChatAll("%i", HasEntProp(weapon, Prop_Send, "m_bIsBloody"));
					//if (HasEntProp(weapon, Prop_Send, "m_bIsBloody")) SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
				}
				else if (CheckForWeaponType(wep_index, TYPE_BEARNER)) // The Big Earner (Speed Boost + 30% Cloak)
				{
					TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0);
					float new_cloak = GetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter") + 70.0;
					if (new_cloak > 100.0) new_cloak = 100.0;
					SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", new_cloak);
				}
				
				// Passive Weapon Buffs
				int melee_wep = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee);
				int temp_index = -1;
				if (RealValidEntity(melee_wep) && HasEntProp(melee_wep, Prop_Send, "m_iItemDefinitionIndex"))
					temp_index = GetEntProp(melee_wep, Prop_Send, "m_iItemDefinitionIndex");
				if (CheckForWeaponType(temp_index, TYPE_CANDYCANE)) // Candy Cane (Health-pack Drop)
				{
					float newVel[3];
					newVel[0] = GetRandomInt(-200, 200) + 0.0;
					newVel[1] = GetRandomInt(-200, 200) + 0.0;
					newVel[2] = GetRandomInt(100, 150) + 0.0;
					SpawnPack(client, newVel);
				}
			}
		}
	}
	
	int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if (medigun != -1 && 
	HasEntProp(medigun, Prop_Send, "m_hHealingTarget") && HasEntProp(medigun, Prop_Send, "m_bHealing"))
	{
		int healClient = GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
		if (healClient != -1) TF2_RemoveCondition(healClient, TFCond_Healing);
		SetEntProp(medigun, Prop_Send, "m_hHealingTarget", -1);
		SetEntProp(medigun, Prop_Send, "m_bHealing", 0);
		if (HasEntProp(medigun, Prop_Send, "m_flChargeLevel"))
		{
			float chargeLevel = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
			if (chargeLevel > 90.0)
			{ SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 90.0); }
		}
	}
	
	if (HasEntProp(client, Prop_Send, "m_nNumHealers") && GetEntProp(client, Prop_Send, "m_nNumHealers") > 0)
	{
		for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
		{
			if (!IsValidClient(loopclient, true, true) || !IsPlayerAlive(loopclient)) continue;
			
			int loopmedigun = GetPlayerWeaponSlot(loopclient, TFWeaponSlot_Secondary);
			if (loopmedigun == -1) continue;
			if (!HasEntProp(loopmedigun, Prop_Send, "m_hHealingTarget") || !HasEntProp(loopmedigun, Prop_Send, "m_bHealing"))
				continue;
			
			int healingTarget = GetEntPropEnt(loopmedigun, Prop_Send, "m_hHealingTarget");
			int healingBool = GetEntProp(loopmedigun, Prop_Send, "m_bHealing");
			if (healingBool && healingTarget != -1 && healingTarget == client)
			{
				TF2_RemoveCondition(client, TFCond_Healing);
				SetEntProp(loopmedigun, Prop_Send, "m_hHealingTarget", -1);
				SetEntProp(loopmedigun, Prop_Send, "m_bHealing", 0);
			}
		}
	}
	
	if (IsDisguisedAsFriendly(client))
		g_iClassForResource[client] = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
	else
		g_iClassForResource[client] = TF2_GetPlayerClass(client);
	
	#if USE_SENDPROXY
	//float origin[3];
	//GetClientAbsOrigin(client, origin);
	//oldOrigins[client] = origin;
	SendProxy_Hook(client, "m_lifeState", Prop_Int, ProxyCallback_lifestate);
	//SendProxy_Hook(client, "m_vecOrigin", Prop_Vector, ProxyCallback_vecOrigin);
	#endif
	//Hook_Manager_AliveProp(client);
	
	//PrintToServer("%i", GetEntProp(ply_manager, Prop_Send, "m_bAlive"));
	
	can[client] = false;
	trigger[client] = false;
	isCloaked[client] = true;
	
	PrintHintText(client, "DR activated.");
}

void ACDRUncloak(int client, bool killtimer = true)
{
	if (!IsValidClient(client)) return;
	
	g_bUsingM2[client] = false;
	
	//if (g_fUncloakTimer[client] != null && killtimer)
	//{ KillTimer(g_fUncloakTimer[client]); }
	if (killtimer)
	{ g_fUncloakTimer[client] = 0.0; }
	if (IsPlayerAlive(client))
	{
		//SetEntityRenderColor(client, 255, 255, 255, 255);
		TF2_RemoveCondition(client, TFCond_StealthedUserBuffFade);
		TF2_AddCondition(client, TFCond_Cloaked);
		TF2_RemoveCondition(client, TFCond_Cloaked);
	}
	EmitGameSoundToAll(UNCLOAK_SND, client);
	WeaponAttackAvailable( client, true );
	
	//g_fReadyTimer[client] = CreateTimer(g_fRechargeTime, Timer_Ready, client);
	PrintHintText(client, "DR Uncloaked.");
	
	isCloaked[client] = false;
	
	#if USE_SENDPROXY
	if (SendProxy_IsHooked(client, "m_lifeState"))
		SendProxy_Unhook(client, "m_lifeState", ProxyCallback_lifestate);
	//if (SendProxy_IsHooked(client, "m_vecOrigin"))
	//	SendProxy_Unhook(client, "m_vecOrigin", ProxyCallback_vecOrigin);
	#endif
	//Hook_Manager_AliveProp(client, false);
}

void DoBuildingFakeDeath(int client, int attacker = -1)
{
	if (!(g_iExtraEffects & BITFLAG_BUILDINGDEATH)) return;
	if (!GetEntProp(client, Prop_Send, "m_bCarryingObject")) return;
	
	int orig_object = GetEntPropEnt(client, Prop_Send, "m_hCarriedObject");
	if (orig_object == -1) return;
	
	static char classname[64];
	GetEntityClassname(orig_object, classname, sizeof(classname));
	int fake_obj = CreateEntityByName(classname);
	if (fake_obj == -1) return;
	
	SetVariantString("OnUser1 !self:Kill::0.02:1");
	AcceptEntityInput(fake_obj, "AddOutput");
	AcceptEntityInput(fake_obj, "FireUser1");
	
	float origin[3], angles[3];
	GetEntPropVector(orig_object, Prop_Data, "m_vecOrigin", origin);
	GetEntPropVector(orig_object, Prop_Data, "m_angRotation", angles);
	DispatchKeyValueVector(fake_obj, "origin", origin);
	DispatchKeyValueVector(fake_obj, "angles", angles);
	DispatchKeyValue(fake_obj, "rendermode", "10");
	
	int obj_type = GetEntProp(orig_object, Prop_Send, "m_iObjectType");
	SetEntProp(fake_obj, Prop_Send, "m_iTeamNum", GetEntProp(orig_object, Prop_Send, "m_iTeamNum"));
	SetEntProp(fake_obj, Prop_Send, "m_iObjectType", obj_type);
	SetEntProp(fake_obj, Prop_Send, "m_bMiniBuilding", GetEntProp(orig_object, Prop_Send, "m_bMiniBuilding"));
	SetEntPropFloat(fake_obj, Prop_Send, "m_flPercentageConstructed", GetEntPropFloat(orig_object, Prop_Send, "m_flPercentageConstructed"));
	SetEntProp(fake_obj, Prop_Send, "m_fObjectFlags", GetEntProp(orig_object, Prop_Send, "m_fObjectFlags"));
	SetEntProp(fake_obj, Prop_Send, "m_iUpgradeLevel", GetEntProp(orig_object, Prop_Send, "m_iUpgradeLevel"));
	SetEntProp(fake_obj, Prop_Send, "m_iUpgradeMetal", GetEntProp(orig_object, Prop_Send, "m_iUpgradeMetal"));
	SetEntProp(fake_obj, Prop_Send, "m_iUpgradeMetalRequired", GetEntProp(orig_object, Prop_Send, "m_iUpgradeMetalRequired"));
	SetEntProp(fake_obj, Prop_Send, "m_iObjectMode", GetEntProp(orig_object, Prop_Send, "m_iObjectMode"));
	SetEntProp(fake_obj, Prop_Send, "m_bDisposableBuilding", GetEntProp(orig_object, Prop_Send, "m_bDisposableBuilding"));
	SetEntPropEnt(fake_obj, Prop_Send, "m_hBuilder", GetEntPropEnt(orig_object, Prop_Send, "m_hBuilder"));
	SetEntProp(fake_obj, Prop_Send, "m_bCarried", 1);
	
	DispatchSpawn(fake_obj);
	ActivateEntity(fake_obj);
	
	carriedBuilding = true;
	SDKHooks_TakeDamage(fake_obj, 0, 0, GetEntProp(fake_obj, Prop_Send, "m_iHealth")+0.0, DMG_GENERIC);
	carriedBuilding = false;
	
	Event object_destroyed = CreateEvent("object_destroyed", true);
	object_destroyed.SetInt("userid", GetClientUserId(client));
	if (IsValidClient(attacker))
		object_destroyed.SetInt("attacker", GetClientUserId(attacker));
	object_destroyed.SetString("weapon", "building_carried_destroyed");
	object_destroyed.SetInt("weaponid", 0);
	object_destroyed.SetInt("objecttype", obj_type);
	object_destroyed.SetInt("index", fake_obj);
	
	for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
	{
		if (!IsValidClient(loopclient, true, true)) continue;
		
		int team = GetClientTeam(client);
		int loopteam = GetClientTeam(loopclient);
		if (team == loopteam) continue;
		
		object_destroyed.FireToClient(loopclient);
	}
	
	CloseHandle(object_destroyed);
}

void HookThink(int entity, bool boolean = true)
{
    if (!IsValidClient(entity)) return;
    if (boolean)
    { SDKHook(entity, POST_THINK_HOOK, Hook_Charge_OnThinkPost); g_fClientWait[entity] = 0.0; }
    else
    { SDKUnhook(entity, POST_THINK_HOOK, Hook_Charge_OnThinkPost); }
}

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_fClientWait[i] >= THINK_WAITTIME)
		{
			g_fClientWait[i] = 0.0;
		}
	}
}

void Hook_Charge_OnThinkPost(int client)
{
	if (!IsServerProcessing()) return;
	
	if (IsPlayerAliveNotGhost(client))
	{
		if (GetGameTime() - g_fClientWait[client] >= 0.0)
		{
			UpdateACDRTimers(client);
			g_fClientWait[client] = g_fClientWait[client] + THINK_WAITTIME;
		}
	}
}

void UpdateACDRTimers(int client)
{
	float game_time = GetGameTime();
	
	if (g_fUncloakTimer[client] <= game_time && isCloaked[client])
	{ Timer_Uncloak(client); }
	//if (g_BoostTimer[client] <= game_time)
	//{ Timer_Boost(client); }
	if ((g_fUncloakTimer[client] + g_fReadyTimer[client]) <= game_time && !can[client])
	{ Timer_Ready(client); }
}

void Timer_Uncloak(int client)
{
	ACDRUncloak(client, false);
}
/*void Timer_Boost(int client)
{
	g_BoostTimer[client] = null;
}*/
void Timer_Ready(int client)
{
	HookThink(client, false);
	can[client] = true;
	PrintHintText(client, "DR is ready.");
	if ((g_iBots & BITFLAG_TOGGLEONREADY) && IsFakeClient(client) && shouldTriggerDR(client))
	{ TriggerACDR(client, true, false, true, true); }
	//else if (!IsFakeClient(client))
	//{ TriggerACDR(client, true, false, true, true); }
}

// Timers end

void player_changeclass(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	if (client == 0) return;
	
	RequestFrame(plyDeath_ResetACDR, client);
}

// Stocks //
stock int TriggerACDR(int client, bool hint = true, bool clean = true, bool override = false, bool override_bool = false)
{
	if (!IsValidClient(client)) return -1;
	
	if (IsPlayerAliveNotGhost(client) && can[client] && !trigger[client] && (!override || override_bool))
	{
		trigger[client] = true;
		SDKUnhook(client, CHANGE_DAMAGE_HOOK, Hook_OnTakeDamage); // Make sure hooks don't keep piling up
		SDKHook(client, CHANGE_DAMAGE_HOOK, Hook_OnTakeDamage);
		if (hint)
		{ PrintHintText(client, ACTIVE_STR); }
		if (clean)
		{
			/*if (g_fUncloakTimer[client] != null)
			{ KillTimer(g_fUncloakTimer[client], true); }
			if (g_BoostTimer[client] != null)
			{ KillTimer(g_BoostTimer[client], true); }
			if (g_fReadyTimer[client] != null)
			{ KillTimer(g_fReadyTimer[client], true); }
			g_fUncloakTimer[client] = null;
			g_BoostTimer[client] = null;
			g_fReadyTimer[client] = null;*/
			g_fUncloakTimer[client] = 0.0;
			//g_BoostTimer[client] = 0.0;
			g_fReadyTimer[client] = 0.0;
		}
		return 1;
	}
	else if (can[client] && trigger[client] && (!override || !override_bool))
	{
		trigger[client] = false;
		SDKUnhook(client, CHANGE_DAMAGE_HOOK, Hook_OnTakeDamage);
		if (hint)
		{ PrintHintText(client, INACTIVE_STR); }
		if (clean)
		{
			/*if (g_fUncloakTimer[client] != null)
			{ KillTimer(g_fUncloakTimer[client], true); }
			if (g_BoostTimer[client] != null)
			{ KillTimer(g_BoostTimer[client], true); }
			if (g_fReadyTimer[client] != null)
			{ KillTimer(g_fReadyTimer[client], true); }
			g_fUncloakTimer[client] = null;
			g_BoostTimer[client] = null;
			g_fReadyTimer[client] = null;*/
			//Hook_Manager_AliveProp(client, false);
			g_fUncloakTimer[client] = 0.0;
			//g_BoostTimer[client] = 0.0;
			g_fReadyTimer[client] = 0.0;
		}
		return 0;
	}
	return -1;
}

/*bool IsDisguised(int client)
{
	int disguise_class = GetEntProp(client, Prop_Send, "m_nDisguiseClass");
	int disguise_index = GetEntProp(client, Prop_Send, "m_hDisguiseTarget");
	if (TF2_IsPlayerInCondition(client, TFCond_Disguised) && disguise_index > 0 && disguise_class > 0)
	{
		return true;
	}
	return false;
}*/

stock bool IsDisguisedAsFriendly(int client)
{
	if (!g_bFriendlyDisguise || !TF2_IsPlayerInCondition(client, TFCond_Disguised)) return false;
	
	//int class = GetEntProp(client, Prop_Send, "m_iClass");
	TFTeam team = view_as<TFTeam>(GetClientTeam(client));
	
	if (GetEntProp(client, Prop_Send, "m_hDisguiseTarget") > -1 && 
	view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass")) > TFClass_Unknown && 
	view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_nDisguiseTeam")) == team)
	{
		return true;
	}
	return false;
}

/*bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients || 
	!IsClientInGame(client) || 
	GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}*/
stock bool IsValidClient(int client, bool replaycheck = true, bool isLoop = false)
{
	if ((isLoop || client > 0 && client <= MaxClients) && IsClientInGame(client))
	{
		if (HasEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2, CSGO?
			if (view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsCoaching"))) return false;
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

stock bool IsPlayerAliveNotGhost(int client)
{ return (IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode)); }

stock bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }

bool canTriggerDR(int client)
{
	if (
	GetEntProp(client, Prop_Data, "m_takedamage") <= 0 || 
	TF2_IsPlayerInCondition(client, TFCond_Ubercharged) || 
	TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
	TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) || 
	TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage)// ||
	//TF2_IsPlayerInCondition(client, TFCond_Taunting)
	)
	{ return false; }
	return true;
}

bool shouldTriggerDR(int client)
{
	TFTeam team = view_as<TFTeam>(GetClientTeam(client));
	if (
	((team == TFTeam_Red && !(g_iAllowTeam & BITFLAG_TEAMRED)) || (team == TFTeam_Blue && !(g_iAllowTeam & BITFLAG_TEAMBLUE)))
	// ^ If a team is not allowed to use ACDR...
	&& ((isMVM && (g_iAllowTeam & BITFLAG_AFFECTMVM)) || (!isMVM && (g_iAllowTeam & BITFLAG_AFFECTPVP)))
	// ...and if it's MVM and the cvar is set to affect MVM
	// or if it's not MVM and the cvar is set to affect non-MVM
	)
		return false; // block it.
	
	return true;
}

stock bool IsMvM()
{
	return (view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine")));
}

stock int GetResourceProperty(int client, PropType type, const char[] str, int size = 1)
{
	int ply_manager = GetPlayerResourceEntity();
	if (RealValidEntity(ply_manager))
		return GetEntProp(ply_manager, type, str, size, client);
	return -1;
}

stock void GiveHealth(int client, int total_Heal = 0, bool overheal = false, bool event = true)
{
	if (total_Heal <= 0) return;
	
	int HP = GetClientHealth(client);
	int max_HP = GetResourceProperty(client, Prop_Send, "m_iMaxHealth");
	if (overheal)
	{ max_HP = max_HP+(max_HP/2); }
	
	/*if (total_Heal+HP >= max_HP)
	{ SetEntityHealth(client, max_HP); }
	else
	{ SetEntityHealth(client, total_Heal+HP); }*/
	if (HP < max_HP)
	{
		if (total_Heal+HP >= max_HP)
		{ SetEntityHealth(client, max_HP); }
		else
		{ SetEntityHealth(client, total_Heal+HP); }
	}
	
	if (event)
	{
		Event player_healonhit = CreateEvent("player_healonhit", true);
		player_healonhit.SetInt("amount", total_Heal);
		player_healonhit.SetInt("entindex", EntRefToEntIndex(client));
		player_healonhit.Fire();
	}
}

stock void SpawnPack(int client, const float velocity[3])
{
	int pack = CreateEntityByName("item_healthkit_small");
	DispatchKeyValue(pack, "AutoMaterialize", "0");
	DispatchKeyValue(pack, "velocity", "0.0 0.0 1.0");
	DispatchKeyValue(pack, "basevelocity", "0.0 0.0 1.0");
	//SetEntPropEnt(pack, Prop_Data, "m_hOwner", client);
	
	float cl_pos[3];
	GetClientEyePosition(client, cl_pos);
	
	//float pack_vel[3]; pack_vel = (view_as<float>({0.0, 0.0, -1.0})); // A little bit of velocity is required to wake it up
	
	TeleportEntity(pack, cl_pos, NULL_VECTOR, velocity);
	
	SetEntProp(pack, Prop_Data, "m_bActivateWhenAtRest", 1);
	//SetEntProp(pack, Prop_Data, "m_nNextThinkTick", -1);
	SetEntProp(pack, Prop_Send, "m_ubInterpolationFrame", 0);
	SetEntPropEnt(pack, Prop_Send, "m_hOwnerEntity", client);
	SetEntityGravity(pack, 1.0);
	
	//SetEntProp(pack, Prop_Send, "m_nNextThinkTick", client);
	SetEntProp(pack, Prop_Send, "m_iTeamNum", TFTeam_Spectator); // This helps keep both teams from picking it up prematurely, including the thrower
	CreateTimer(0.5, PreventPickup_Timer, EntIndexToEntRef(pack), TIMER_FLAG_NO_MAPCHANGE);
	
	DispatchSpawn(pack);
	ActivateEntity(pack);
	
	DispatchKeyValue(pack, "nextthink", "0.1"); // The fix to the laggy physics.
	//SetEntProp(pack, Prop_Send, "movetype", MOVETYPE_FLYGRAVITY);
	//SetEntProp(pack, Prop_Data, "m_MoveType", MOVETYPE_FLYGRAVITY);
	
	SetVariantString("OnPlayerTouch !self:Kill::0:1");
	AcceptEntityInput(pack, "AddOutput");
	
	SetVariantString("OnUser1 !self:Kill::30.0:1");
	AcceptEntityInput(pack, "AddOutput");
	AcceptEntityInput(pack, "FireUser1");
	
	RequestFrame(SpawnPack_FrameCallback, pack); // Have to change movetype in a frame callback
}

void SpawnPack_FrameCallback(int pack)
{
	if (!IsValidEntity(pack) || pack < 1) return;
	
	SetEntityMoveType(pack, MOVETYPE_FLYGRAVITY);
	SetEntProp(pack, Prop_Send, "movecollide", 1); // These two are set to MOVECOLLIDE_FLY_BOUNCE...
	SetEntProp(pack, Prop_Data, "m_MoveCollide", 1); // ...which allows the pack to bounce.
}
Action PreventPickup_Timer(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);
	
	if (entity == -1) return Plugin_Continue;
	
	SetEntProp(entity, Prop_Send, "m_iTeamNum", TFTeam_Unassigned);
	return Plugin_Continue;
}

stock void _TF2_ImmediateDisguisePlayer(int client, TFTeam team, TFClassType classType, int target = 0)
{
	TF2_AddCondition(client, TFCond_Disguising, 0.5);
	
	int active_wep = GetPlayerWeaponSlot(target, TFWeaponSlot_Primary);
	if (active_wep == -1)
	{
		active_wep = GetPlayerWeaponSlot(target, TFWeaponSlot_Secondary);
		if (active_wep == -1)
		{
			active_wep = GetPlayerWeaponSlot(target, TFWeaponSlot_Melee);
			if (active_wep == -1)
			{
				active_wep = GetPlayerWeaponSlot(target, TFWeaponSlot_Grenade);
				if (active_wep == -1)
				{
					active_wep = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
				}
			}
		}
	}
	
	bool isValidWep = RealValidEntity(active_wep);
	
	DataPack dataP = CreateDataPack();
	CreateDataTimer(0.25, Timer_DisguisePlayer, dataP, TIMER_FLAG_NO_MAPCHANGE);
	
	dataP.WriteCell(GetClientUserId(client));
	dataP.WriteCell(team);
	dataP.WriteCell(classType);
	dataP.WriteCell(GetClientUserId(target));
	dataP.WriteCell(GetEntProp(target, Prop_Send, "m_nBody"));
	dataP.WriteCell(GetEntProp(target, Prop_Send, "m_nForcedSkin"));
	dataP.WriteCell(GetClientHealth(target));
	dataP.WriteCell(isValidWep ? GetEntProp(active_wep, Prop_Send, "m_iItemDefinitionIndex") : -1);
	dataP.WriteCell(isValidWep ? GetEntProp(active_wep, Prop_Send, "m_iEntityLevel") : -1);
	dataP.WriteCell(isValidWep ? GetEntProp(active_wep, Prop_Send, "m_iEntityQuality") : -1);
	dataP.WriteCell(isValidWep ? GetEntProp(active_wep, Prop_Send, "m_iItemIDHigh") : -1);
	dataP.WriteCell(isValidWep ? GetEntProp(active_wep, Prop_Send, "m_iItemIDLow") : -1);
	dataP.WriteCell(isValidWep ? GetEntProp(active_wep, Prop_Send, "m_iAccountID") : -1);
	dataP.WriteCell(isValidWep ? GetEntProp(active_wep, Prop_Send, "m_bOnlyIterateItemViewAttributes") : 0);
	
	static char wep_str[128];
	GetEntityClassname(active_wep, wep_str, sizeof(wep_str));
	dataP.WriteString(wep_str, false);
	if (isValidWep) AcquireModel(active_wep, wep_str, sizeof(wep_str));
	dataP.WriteString(wep_str, false);
}
Action Timer_DisguisePlayer(Handle timer, DataPack dataP)
{
	dataP.Reset();
	int clientID = dataP.ReadCell();
	TFTeam team = view_as<TFTeam>(dataP.ReadCell());
	TFClassType classType = view_as<TFClassType>(dataP.ReadCell());
	int targetID = dataP.ReadCell();
	int body = dataP.ReadCell();
	int skin = dataP.ReadCell();
	int health = dataP.ReadCell();
	int m_iItemDefinitionIndex = dataP.ReadCell();
	int m_iEntityLevel = dataP.ReadCell();
	int m_iEntityQuality = dataP.ReadCell();
	int m_iItemIDHigh = dataP.ReadCell();
	int m_iItemIDLow = dataP.ReadCell();
	int m_iAccountID = dataP.ReadCell();
	bool m_bOnlyIterateItemViewAttributes = view_as<bool>(dataP.ReadCell());
	static char class_str[128]; static char mdl_str[128];
	dataP.ReadString(class_str, sizeof(class_str));
	dataP.ReadString(mdl_str, sizeof(mdl_str));
	
	int client = GetClientOfUserId(clientID), target = GetClientOfUserId(targetID);
	
/*	TF2_ImmediateDisguisePlayer(client, team, classType, target);
	return Plugin_Continue;
}
void TF2_ImmediateDisguisePlayer(int client, TFTeam team = TFTeam_Unassigned, TFClassType classType = TFClass_Unknown, int target = 0)
{*/
	if (client == 0) return Plugin_Continue;
	
	SetEntProp(client, Prop_Send, "m_nDisguiseTeam", team);
	SetEntProp(client, Prop_Send, "m_nDesiredDisguiseTeam", team);
	SetEntProp(client, Prop_Send, "m_nDisguiseClass", classType);
	SetEntProp(client, Prop_Send, "m_nDesiredDisguiseClass", classType);
	if (classType == TFClass_Spy)
	{
		SetEntProp(client, Prop_Send, "m_nMaskClass", GetRandomInt(view_as<int>(TFClass_Scout), view_as<int>(TFClass_Engineer)));
	}
	
	if (target != 0)
	{
		SetEntProp(client, Prop_Send, "m_iDisguiseBody", body);
		SetEntProp(client, Prop_Send, "m_nDisguiseSkinOverride", skin);
		SetEntProp(client, Prop_Send, "m_hDisguiseTarget", target);
		SetEntProp(client, Prop_Send, "m_iDisguiseHealth", health);
	}
	TF2_AddCondition(client, TFCond_Disguised);
	
	int new_wep = CreateEntityByName(class_str);
	SetEntityModel(new_wep, mdl_str);
	
	SetEntProp(new_wep, Prop_Data, "m_nSkin", (team == TFTeam_Blue) ? 1 : 0);
	
	SetEntProp(new_wep, Prop_Send, "m_bInitialized", 1);
	SetEntProp(new_wep, Prop_Send, "m_bDisguiseWeapon", 1);
	
	SetEntPropEnt(new_wep, Prop_Send, "m_hOwner", client);
	SetEntPropEnt(new_wep, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(new_wep, Prop_Send, "m_CollisionGroup", 11);
	
	SetEntProp(new_wep, Prop_Send, "m_iItemDefinitionIndex", m_iItemDefinitionIndex);
	SetEntProp(new_wep, Prop_Send, "m_iEntityLevel", m_iEntityLevel);
	SetEntProp(new_wep, Prop_Send, "m_iItemIDHigh", m_iItemIDHigh);
	SetEntProp(new_wep, Prop_Send, "m_iItemIDLow", m_iItemIDLow);
	SetEntProp(new_wep, Prop_Send, "m_iAccountID", m_iAccountID);
	SetEntProp(new_wep, Prop_Send, "m_iEntityQuality", m_iEntityQuality);
	SetEntProp(new_wep, Prop_Send, "m_bOnlyIterateItemViewAttributes", m_bOnlyIterateItemViewAttributes);
	SetEntProp(new_wep, Prop_Send, "m_iTeamNumber", team);
	
	float origin[3], angles[3];
	GetClientAbsOrigin(client, origin);
	GetClientAbsAngles(client, angles);
	
	DispatchKeyValueVector(new_wep, "origin", origin);
	DispatchKeyValueVector(new_wep, "angles", angles);
	
	SetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon", new_wep);
	
	DispatchSpawn(new_wep);
	ActivateEntity(new_wep);
	
	SetVariantString("!activator");
	AcceptEntityInput(new_wep, "SetParent", client);
	
	SetEntProp(new_wep, Prop_Send, "m_iState", 2);
	SetEntProp(new_wep, Prop_Send, "m_fEffects", (0x001 + 0x080)); //EF_BONEMERGE + EF_BONEMERGE_FASTCULL
	return Plugin_Continue;
}

/*void FakeFinalHitsound(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client)) return;
	
	Event fakeEvent = CreateEvent("npc_hurt", true);
	fakeEvent.SetInt("attacker_player", GetClientUserId(client));
	//fakeEvent.SetInt("entindex", Ent);
	fakeEvent.SetInt("health", 0);
	fakeEvent.SetInt("damageamount", 1);
	
	FireEvent(fakeEvent);
}*/

/*void Hook_Manager_AliveProp(int client, bool boolean = true)
{
	int ply_manager = GetPlayerResourceEntity();
	if (RealValidEntity(ply_manager))
	{
		//int offset = FindSendPropInfo("CTFPlayerResource", "m_bAlive");
		//if (boolean)
		//{ SendProxy_HookArrayProp(ply_manager, "m_bAlive", 0, Prop_Int, ProxyCallback_bAlive); }
		//else if (SendProxy_IsHookedArrayProp(ply_manager, "m_bAlive", 0))
		//{ SendProxy_UnhookArrayProp(ply_manager, "m_bAlive", 0, Prop_Int, ProxyCallback_bAlive); }
		//if (boolean)
		//{ SetEntProp(ply_manager, Prop_Send, "m_bAlive", client); }
		//else if (SendProxy_IsHookedArrayProp(ply_manager, "m_bAlive", client))
		//{ SendProxy_UnhookArrayProp(ply_manager, "m_bAlive", client, Prop_Int, ProxyCallback_bAlive); }
		if (boolean)
		{ SDKHook(ply_manager, THINK_POST_HOOK, Hook_OnThinkPost); }
		else
		{ SDKUnhook(ply_manager, THINK_POST_HOOK, Hook_OnThinkPost); }
	}
}*/

/*void Hurt(Event event, const char[] name, bool dontBroadcast) 
{
	int damage = event.GetInt("damageamount", 0);
	if (damage < 1) return Plugin_Continue;
	
	int clientID = event.GetInt("userid", 0);
	int client = GetClientOfUserId(clientID);
	int aID = event.GetInt("attacker", 0);
	int a = GetClientOfUserId(aID);
	int wepID = event.GetInt("weaponid", 0);
	int wep = EntIndexToEntRef(wepID);
	int custom = event.GetInt("custom", 0);
	static char wep_netclass_attacker[PLATFORM_MAX_PATH+1];
	if (RealValidEntity(wep))
	{
		GetEntityClassname(wep, wep_netclass_attacker, sizeof(wep_netclass_attacker) );
	}
	
	if (!IsValidClient(client)) 
		return Plugin_Continue;
	
	if (can[client] && trigger[client]) 
	{
		Event event1 = CreateEvent("player_death");
		
		if (event1 != null)
		{
			fakeEvent.SetInt("userid", clientID);
			fakeEvent.SetInt("victim_entindex", EntRefToEntIndex(client));
			fakeEvent.SetInt("inflictor_entindex", EntRefToEntIndex(a));
			fakeEvent.SetInt("attacker", event.GetInt("attacker", 0));
			//fakeEvent.SetInt(event1, "weapon", wep);
			fakeEvent.SetInt("weaponid", event.GetInt("weaponid", 0));
			fakeEvent.SetInt("damagebits", TF_DEATHFLAG_DEADRINGER);
			fakeEvent.SetInt("customkill", custom);
			if (RealValidEntity(wep) && wep_netclass_attacker[1])
			{
				fakeEvent.SetString("weapon", wep_netclass_attacker);
				fakeEvent.SetString("weapon_logclassname", wep_netclass_attacker);
			}
			//if (RealValidEntity(g_wep_netclass_attacker[client]) )
			{
			//fakeEvent.SetInt("weapon_logclassname", g_wep_netclass_attacker[client]);
			//}
			//g_wep_netclass_attacker[client] = -1;
			fakeEvent.SetInt("weapon_def_index", wepID);
			
			bool crit = event.GetBool("crit", false);
			bool minicrit = event.GetBool("minicrit", false);
			if (crit == true) 
			{
				fakeEvent.SetInt("crit_type", 2);
			}
			else 
			{
			if (minicrit == true) fakeEvent.SetInt("crit_type", 1);
			}
			
			FireEvent(event1);
		}
		
		if (IsValidClient(client))
		{
			//SetEntityRenderMode(client,RENDER_GLOW);
			TF2_AddCondition(client, TFCond_StealthedUserBuffFade);
			TF2_AddCondition(client, TFCond_AfterburnImmune);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly);
			//SetEntityRenderColor(client, 255, 255, 255, 0);
			
			//fakeEvent.SetInt("damageamount", damage / 1.5)
			
			AlterACDRRagdoll(client, damage, damageType);
			SpawnACDRWeaponAmmoBox(client);
			
			WeaponAttackAvailable( client, false );
			
			if (TF2_IsPlayerInCondition(client, TFCond_OnFire))
				{ TF2_RemoveCondition(client, TFCond_OnFire); }
			if (TF2_IsPlayerInCondition(client, TFCond_BurningPyro))
				{ TF2_RemoveCondition(client, TFCond_BurningPyro); }
			
			//Hook_Manager_AliveProp(client);
			
			g_fUncloakTimer[client] = CreateTimer(6.5, Timer_Uncloak, client);
			g_BoostTimer[client] = CreateTimer(3.0, Timer_Boost, client);
		}
		can[client] = false;
		trigger[client] = false;
		
		PrintHintText(client, "DR activated.");
		//EmitSoundToAll(SND, g_Ragdoll[client]);
	}
	return Plugin_Continue;
}*/