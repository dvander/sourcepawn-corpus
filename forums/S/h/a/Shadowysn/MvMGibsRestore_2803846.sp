#define PLUGIN_NAME "[TF2] MvM Gibs Restore"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Restore gibbing for Mann and/or Machines."
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=342654"
#define PLUGIN_NAME_SHORT "MvM Gibs Restore"
#define PLUGIN_NAME_TECH "mvm_gibs"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <adminmenu>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define AUTOEXEC_CFG "mvm_gibs_restore"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

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

ConVar cVar_Enabled, cVar_AllowTeam;
bool g_bEnabled;
int g_iPlayerGib, g_iAllowTeam;
ConVar playergib_cvar;

#define BITFLAG_TEAMRED		(1 << 0)
#define BITFLAG_TEAMBLUE		(1 << 1)

bool g_bIsGibbing, g_bCurrentlyMvM;

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_bIsGibbing) return;
	if (classname[0] != 't' || strcmp(classname, "tf_ragdoll", false) != 0) return;
	//PrintToServer("ragdoll found: %i", entity);
	AcceptEntityInput(entity, "Kill");
	g_bIsGibbing = false;
}

public void OnPluginStart()
{
	ConVar version_cvar = CreateConVar("sm_"...PLUGIN_NAME_TECH..."_version", PLUGIN_VERSION, PLUGIN_NAME_SHORT..." version.", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	if (version_cvar != null)
		version_cvar.SetString(PLUGIN_VERSION);
	
	// TODO: Redundant ConVar? Teams ConVar already functions as disabling at 0
	cVar_Enabled = CreateConVar("sm_"...PLUGIN_NAME_TECH..."_enable", "1.0", "Enable the "...PLUGIN_NAME_SHORT..." plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	cVar_Enabled.AddChangeHook(CC_MvMGib_Enable);
	
	cVar_AllowTeam = CreateConVar("sm_"...PLUGIN_NAME_TECH..."_teams", "3.0", 
	"Choose which team in MvM can gib. (BITFLAGS)\n1 = RED (MANN) can gib.\n2 = BLU (MACHINE) can gib.", FCVAR_NONE, true, 0.0, true, 3.0);
	cVar_AllowTeam.AddChangeHook(CC_MvMGib_AllowTeam);
	
	HookEvent("player_death", player_death, EventHookMode_Post);
	
	playergib_cvar = FindConVar("tf_playergib");
	playergib_cvar.AddChangeHook(CC_playergib_cvar);
	
	// TODO: Hard-code or ConVars to exclude classes from each team from gibbing
	// Engineer, Medic, Sniper and Spy bots have missing gibs, the last 3 only have head gib
	
	AutoExecConfig(true, AUTOEXEC_CFG);
	SetCvarValues();
	
	if (g_bLateLoad)
	{ g_bCurrentlyMvM = IsMvM(); }
	
	// Use common.phrases for ReplyToTargetError
	LoadTranslations("common.phrases");
}

public void OnMapStart()
{
	g_bCurrentlyMvM = IsMvM();
}

void CC_MvMGib_Enable(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_bEnabled =		convar.BoolValue;	}
void CC_MvMGib_AllowTeam(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_iAllowTeam =		convar.IntValue;	}
void SetCvarValues()
{
	CC_MvMGib_Enable(cVar_Enabled, "", "");
	CC_MvMGib_AllowTeam(cVar_AllowTeam, "", "");
	CC_playergib_cvar(playergib_cvar, "", "");
}
void CC_playergib_cvar(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iPlayerGib =	convar.IntValue;	}

public void OnPluginEnd()
{
	UnhookEvent("player_death", player_death, EventHookMode_Post);
}

void player_death(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnabled || !g_bCurrentlyMvM) return;
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	if (client == 0) return;
	
	TFTeam team = view_as<TFTeam>(GetClientTeam(client));
	if (team == TFTeam_Red && !(g_iAllowTeam & BITFLAG_TEAMRED) || 
	team == TFTeam_Blue && !(g_iAllowTeam & BITFLAG_TEAMBLUE)) return;
	
	int damageType = event.GetInt("damagebits", 0);
	int suicideFlags = GetEntProp(client, Prop_Data, "m_iSuicideCustomKillFlags");
	
	if (g_iPlayerGib != 1 || // playergib 2 still works in mvm
	GetEntProp(client, Prop_Send, "m_iPlayerSkinOverride") == 1 || 
	damageType == 0 || !(damageType & DMG_BLAST) || 
	(!(damageType & DMG_CRIT) && !(suicideFlags & TF_CUSTOM_SUICIDE) && GetClientHealth(client) > -10)) return;
	
	SpawnGibsDoll(client, (TF2_IsPlayerInCondition(client, TFCond_OnFire) || TF2_IsPlayerInCondition(client, TFCond_BurningPyro)));
	
	// there's a meaty sound that plays from non-suicide gib deaths but idk what the name exactly is
	// the way this one's played is too quiet
	if (team == TFTeam_Red && !IsFakeClient(client))
		EmitSoundToClient(client, "physics/body/body_medium_impact_soft4.wav", 
		SOUND_FROM_PLAYER, 
		SNDCHAN_BODY);
}

void ResetGibbing()
{ g_bIsGibbing = false; }

// NOTE: head gib may not be visible on decapitation kills
void SpawnGibsDoll(int client, /*int damageType, int damagecustom,*/ bool isOnFire = false)
{
	int ragdoll = CreateEntityByName("tf_ragdoll"); 
	// as soon as it's CreateEntityByName'd, OnEntityCreated fires on it
	// might be best to just use RequestFrame'd g_bIsGibbing
	if (ragdoll == -1) return;
	g_bIsGibbing = true;
	RequestFrame(ResetGibbing);
	
	float origin[3], force[3];
	GetClientAbsOrigin(client, origin);
	SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollOrigin", origin);
	GetEntPropVector(client, Prop_Send, "m_vecForce", force);
	SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", force);
	SetEntPropVector(ragdoll, Prop_Data, "m_vecOrigin", origin);
	
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
	
	if (isOnFire && class != TFClass_Pyro && disguise_class != TFClass_Pyro)
		SetEntProp(ragdoll, Prop_Send, "m_bBurning", 1);
	
	//SetEntProp(ragdoll, Prop_Send, "m_bFeignDeath", 1); // This allows creating multiple gib groups but screws up bodygroups
	SetEntProp(ragdoll, Prop_Send, "m_bGib", 1);
	
	SetEntProp(ragdoll, Prop_Send, "m_nForceBone", GetEntProp(client, Prop_Send, "m_nForceBone"));
	if (view_as<bool>(GetEntityFlags(client) & FL_ONGROUND))
	{ SetEntProp(ragdoll, Prop_Send, "m_bOnGround", 1); }
	
	SetEntPropFloat(ragdoll, Prop_Send, "m_flHeadScale", GetEntPropFloat(client, Prop_Send, "m_flHeadScale"));
	SetEntPropFloat(ragdoll, Prop_Send, "m_flTorsoScale", GetEntPropFloat(client, Prop_Send, "m_flTorsoScale"));
	SetEntPropFloat(ragdoll, Prop_Send, "m_flHandScale", GetEntPropFloat(client, Prop_Send, "m_flHandScale"));
	
	// The game will delete our spawned ragdoll if we set it to m_hRagdoll before
	// the game spawns the intended ragdoll that gets removed, so delay it by a tick or something
	DataPack dataP = CreateDataPack();
	CreateDataTimer(0.0, DelayRagdollAssign, dataP, TIMER_FLAG_NO_MAPCHANGE);
	dataP.WriteCell(EntIndexToEntRef(ragdoll));
	dataP.WriteCell(GetClientUserId(client));
	
	DispatchSpawn(ragdoll);
	ActivateEntity(ragdoll);
}
Action DelayRagdollAssign(Handle timer, DataPack dataP)
{
	dataP.Reset();
	int ragdoll = EntRefToEntIndex(dataP.ReadCell());
	int client = GetClientOfUserId(dataP.ReadCell());
	if (client == 0 || ragdoll == -1) return Plugin_Continue;
	
	int old_rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (old_rag != -1)
	{ AcceptEntityInput(old_rag, "Kill"); }
	SetEntPropEnt(client, Prop_Send, "m_hRagdoll", ragdoll);
	return Plugin_Continue;
}

stock bool IsMvM()
{
	return (view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine")));
}

stock bool IsDisguisedAsFriendly(int client)
{
	if (!TF2_IsPlayerInCondition(client, TFCond_Disguised)) return false;
	
	TFTeam team = view_as<TFTeam>(GetClientTeam(client));
	
	if (GetEntProp(client, Prop_Send, "m_hDisguiseTarget") > -1 && 
	view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass")) > TFClass_Unknown && 
	view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_nDisguiseTeam")) == team)
	{
		return true;
	}
	return false;
}