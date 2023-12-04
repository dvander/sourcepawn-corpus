#define PLUGIN_NAME "[CS:S/CS:GO] Deathmatch Ragdolls"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Converts player ragdolls into ragdolls suited for deathmatch play."
#define PLUGIN_VERSION "1.1.0"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=327641"
#define PLUGIN_NAME_SHORT "Deathmatch Ragdolls"
#define PLUGIN_NAME_TECH "dm_ragdolls"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define TEAM_T 2
#define TEAM_CT 3

#define GAME_CSS 0
#define GAME_CSGO 1
static int gameVar = GAME_CSS;

#define RAGMANAGE_CLASS "game_ragdoll_manager"
#define TEMPRAG_CLASS "plugin_temp_ragdoll"

#define AUTOEXEC_CFG "deathmatch_ragdolls"

#define SF_PHYSPROP_PREVENT_PICKUP		(1 << 9)
#define EFL_DONTBLOCKLOS				(1 << 25)

//#define k_EHostageStates_BeingUntied		1
//#define k_EHostageStates_GettingPickedUp	2
#define k_EHostageStates_Rescued			6
//#define k_EHostageStates_Dead				7

static bool g_bFadeRags = false;
static int g_iTempRagdoll[MAXPLAYERS+1] = INVALID_ENT_REFERENCE;

ConVar version_cvar;
ConVar Ragdoll_UseHostage;
ConVar Ragdoll_Amount;
ConVar Ragdoll_AmountDX8;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_CSGO)
	{
		gameVar = GAME_CSGO;
		return APLRes_Success;
	}
	else if (GetEngineVersion() == Engine_CSS)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Counter-Strike: Source and CS:GO.");
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
	char version_str[128];
	Format(version_str, sizeof(version_str), "%s version.", PLUGIN_NAME_SHORT);
	char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, version_str, 0|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_ragdoll_type", PLUGIN_NAME_TECH);
	Ragdoll_UseHostage = CreateConVar(cmd_str, "0.0", "-1 = Off. 0 = NPC. 1 = Hostage. (Experimental, Use for CS:GO)", FCVAR_NONE, true, -1.0, true, 1.0);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_amount", PLUGIN_NAME_TECH);
	Ragdoll_Amount = CreateConVar(cmd_str, "64.0", "Number of ragdolls that must exist at a time.", FCVAR_NONE, true, 0.0, true, 64.0);
	HookConVarChange(Ragdoll_Amount, RagAmountChanged);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_amount_dx8", PLUGIN_NAME_TECH);
	Ragdoll_AmountDX8 = CreateConVar(cmd_str, "64.0", "Number of ragdolls that must exist at a time, for DirectX 8.0 or below.", FCVAR_NONE, true, 0.0, true, 64.0);
	HookConVarChange(Ragdoll_AmountDX8, RagAmountChanged);
	
	HookEvent("player_spawn", player_spawn, EventHookMode_Post);
	HookEvent("player_death", player_death, EventHookMode_Post);
	HookEvent("round_start", round_start, EventHookMode_Post);
	if (gameVar == GAME_CSGO)
	{
		HookEvent("player_use", player_use, EventHookMode_Post);
	}
	
	if (IsValidEntity(0))
	{ UpdateRagdollAmount(8, false, true); }
	
	AutoExecConfig(true, AUTOEXEC_CFG);
}

public void OnMapStart()
{
	//PrecacheScriptSound("Hostage.Rescued");
}

void RagAmountChanged(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (!StrEqual(oldValue, newValue, false))
	{
		bool isDX8Cvar = false;
		char temp_str[32];
		GetConVarName(cvar, temp_str, sizeof(temp_str));
		
		if (StrContains(temp_str, "dx8", false) >= 0) isDX8Cvar = true;
		
		UpdateRagdollAmount(StringToInt(newValue), isDX8Cvar);
	}
}

void round_start(Event event, const char[] name, bool dontBroadcast)
{
	UpdateRagdollAmount(0, false);
	UpdateRagdollAmount(0, true);
	g_bFadeRags = true;
	CreateTimer(1.0, Timer_UpdateRagdollAmount, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_UpdateRagdollAmount(Handle timer)
{
	g_bFadeRags = false;
	UpdateRagdollAmount(8, false, true);
}

void UpdateRagdollAmount(int newValue, bool isDX8Cvar = false, bool init = false)
{
	if (g_bFadeRags) return;
	
	int manager = FindEntityByClassname(-1, RAGMANAGE_CLASS);
	if (!RealValidEntity(manager))
	{
		manager = CreateEntityByName(RAGMANAGE_CLASS);
		if (!RealValidEntity(manager)) return;
		DispatchKeyValue(manager, "MaxRagdollCount", "8");
		DispatchKeyValue(manager, "MaxRagdollCountDX8", "4");
		DispatchSpawn(manager);
		ActivateEntity(manager);
	}
	
	char temp_str[4];
	if (init)
	{
		int rag_amount = GetConVarInt(Ragdoll_Amount);
		int rag_amount_dx8 = GetConVarInt(Ragdoll_AmountDX8);
		
		IntToString(rag_amount, temp_str, sizeof(temp_str));
		SetVariantString(temp_str);
		AcceptEntityInput(manager, "SetMaxRagdollCount");
		IntToString(rag_amount_dx8, temp_str, sizeof(temp_str));
		SetVariantString(temp_str);
		AcceptEntityInput(manager, "SetMaxRagdollCountDX8");
	}
	else
	{
		IntToString(newValue, temp_str, sizeof(temp_str));
		SetVariantString(temp_str);
		if (isDX8Cvar)
		{
			AcceptEntityInput(manager, "SetMaxRagdollCountDX8");
		}
		else
		{
			AcceptEntityInput(manager, "SetMaxRagdollCount");
		}
	}
}

// v Potentially unstable
void player_use(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) return;
	int entity = GetEventInt(event, "entity");
	if (!RealValidEntity(entity)) return;
	
	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (!StrEqual(classname, TEMPRAG_CLASS, false)) return;
	
	SetEntProp(entity, Prop_Send, "m_nHostageState", k_EHostageStates_Rescued);
	SetEntProp(client, Prop_Send, "m_bIsGrabbingHostage", false);
	SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
	
	// v Playing a sound to get rid of the defuser cutting noise just... crashes it all instead.
	//EmitGameSoundToAll("Hostage.Rescued", entity);
}

void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarInt(Ragdoll_UseHostage) < 0) return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) return;
	
	int temprag = g_iTempRagdoll[client];
	if (RealValidEntity(temprag))
	{
		AcceptEntityInput(temprag, "Kill");
		g_iTempRagdoll[client] = INVALID_ENT_REFERENCE;
	}
}

void player_death(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarInt(Ragdoll_UseHostage) < 0) return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) return;
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	int prev_ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!RealValidEntity(prev_ragdoll)) return;
	
	float vecForce[3];
	GetEntPropVector(prev_ragdoll, Prop_Send, "m_vecForce", vecForce);
	int nForceBone = GetEntProp(prev_ragdoll, Prop_Send, "m_nForceBone");
	int iDeathPose = GetEntProp(prev_ragdoll, Prop_Send, "m_iDeathPose");
	int iDeathFrame = GetEntProp(prev_ragdoll, Prop_Send, "m_iDeathFrame");
	
	AcceptEntityInput(prev_ragdoll, "Kill");
	
	CreateDisconRagdoll(client, attacker, vecForce, nForceBone, iDeathPose, iDeathFrame);
}

void CreateDisconRagdoll(int client, int attacker = -1, const float[3] vecForce, int nForceBone = 0, int iDeathPose = -1, int iDeathFrame = -1)
{
	if (iDeathPose < 0)
	{ iDeathPose = GetEntProp(client, Prop_Send, "m_nSequence"); }
	if (iDeathFrame < 0)
	{ iDeathFrame = GetEntProp(client, Prop_Send, "m_flAnimTime"); }
	
	int rag_type = GetConVarInt(Ragdoll_UseHostage);
	
	int body = -1;
	switch (rag_type)
	{
		case 0: body = CreateEntityByName("scripted_target");
		case 1: body = CreateEntityByName("hostage_entity");
	}
	if (!RealValidEntity(body))
	{ return; }
	
	SetVariantString("OnUser1 !self:Kill::1.0:1");
	AcceptEntityInput(body, "AddOutput");
	AcceptEntityInput(body, "FireUser1");
	
	g_iTempRagdoll[client] = body;
	
	//int health = GetClientHealth(client);
	
	char temp_str[64];
	
	IntToString(GetEntProp(client, Prop_Data, "m_iMaxHealth"), temp_str, sizeof(temp_str));
	DispatchKeyValue(body, "max_health", temp_str);
	
	//IntToString(health, temp_str, sizeof(temp_str));
	//DispatchKeyValue(body, "health", temp_str);
	DispatchKeyValue(body, "health", "1");
	
	//DispatchKeyValue(body, "hull_name", "Human");
	DispatchKeyValue(body, "solid", "0");
	if (gameVar == GAME_CSGO)
	{
		DispatchKeyValue(body, "HostageSpawnRandomFactor", "0");
	}
	
	float origin[3];
	float angles[3];
	GetClientAbsOrigin(client, origin);
	GetClientEyeAngles(client, angles);
	if (!IsPlayerAlive(client))
	{
		float vecMaxs[3];
		GetEntPropVector(client, Prop_Send, "m_vecMaxs", vecMaxs);
		origin[2] -= vecMaxs[2];
	}
	angles[0] = 0.0; angles[2] = 0.0;
	
	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	
	DispatchSpawn(body);
	ActivateEntity(body);
	
	DispatchKeyValue(body, "nextthink", "0");
	
	TeleportEntity(body, origin, angles, velocity);
	//SetEdictFlags(body, FL_EDICT_ALWAYS);
	
	GetClientModel(client, temp_str, sizeof(temp_str));
	PrecacheModel(temp_str);
	SetEntityModel(body, temp_str);
	
	strcopy(temp_str, sizeof(temp_str), TEMPRAG_CLASS);
	SetEntPropString(body, Prop_Data, "m_iClassname", temp_str);
	
	SetEntProp(body, Prop_Send, "m_nBody", GetEntProp(client, Prop_Send, "m_nBody"));
	SetEntProp(body, Prop_Send, "m_nSkin", GetEntProp(client, Prop_Send, "m_nSkin"));
	
	//SetEdictFlags(body, GetEdictFlags(body) & FL_EDICT_ALWAYS);
	if (HasEntProp(body, Prop_Send, "m_bFadeCorpse"))
	SetEntProp(body, Prop_Send, "m_bFadeCorpse", true);
	
	SetEntProp(body, Prop_Send, "m_nSequence", GetEntProp(client, Prop_Send, "m_nSequence"));
	SetEntPropFloat(body, Prop_Send, "m_flCycle", GetEntPropFloat(client, Prop_Send, "m_flCycle"));
	SetEntProp(body, Prop_Send, "m_flAnimTime", GetEntProp(client, Prop_Send, "m_flAnimTime"));
	SetEntProp(body, Prop_Send, "m_flSimulationTime", GetEntProp(client, Prop_Send, "m_flSimulationTime"));
	SetEntPropFloat(body, Prop_Send, "m_flPlaybackRate", 1.0);
	
	if (HasEntProp(body, Prop_Send, "m_iDeathPose"))
	SetEntProp(body, Prop_Send, "m_iDeathPose", iDeathPose);
	if (HasEntProp(body, Prop_Send, "m_iDeathFrame"))
	SetEntProp(body, Prop_Send, "m_iDeathFrame", iDeathFrame);
	
	SetEntProp(body, Prop_Send, "m_usSolidFlags", 0);
	
	//SetEntProp(body, Prop_Send, "m_lifeState", 1); // LIFE_DEAD
	
	if (HasEntProp(body, Prop_Send, "m_isRescued"))
	SetEntProp(body, Prop_Send, "m_isRescued", true);
	
	if (gameVar == GAME_CSGO && rag_type == 1)
	{
		//SetEntProp(body, Prop_Send, "m_fFlags", (GetEntProp(body, Prop_Send, "m_fFlags") & ~FL_OBJECT));
		
		SetEntProp(body, Prop_Send, "m_nHostageState", k_EHostageStates_Rescued);
		//SetEntPropFloat(body, Prop_Send, "m_flGrabSuccessTime", GetGameTime()-100.0);
	}
	
	SetEntProp(body, Prop_Data, "m_takedamage", 0);
	AcceptEntityInput(body, "BecomeRagdoll");
	//DoDamage(body, attacker, 100);
	//CreateTimer(0.2, ReqFrameTest, body);
	
//	float velfloat[3];
//	GetEntPropVector(client, Prop_Send, "m_vecForce", velfloat);
//	
//	velfloat[0] += (velocity[0]*2);
//	velfloat[1] += (velocity[1]*2);
//	velfloat[2] += (velocity[2]*2);
//	//velfloat[0] *= 60.0;
//	//velfloat[1] *= 60.0;
//	//velfloat[2] *= 60.0;
//	
//	SetEntPropVector(body, Prop_Send, "m_vecForce", velfloat);
//	
//	SetEntProp(body, Prop_Send, "m_nForceBone", GetEntProp(client, Prop_Send, "m_nForceBone"));
	
//	float velfloat[3];
//	velfloat[0] = vecForce[0]; velfloat[1] = vecForce[1]; velfloat[2] = vecForce[2];
//	velfloat[0] += (velocity[0]*2);
//	velfloat[1] += (velocity[1]*2);
//	velfloat[2] += (velocity[2]*2);
	
	SetEntPropVector(body, Prop_Send, "m_vecForce", vecForce);
	SetEntProp(body, Prop_Send, "m_nForceBone", nForceBone);
	
	//SetEntPropEnt(client, Prop_Send, "m_hRagdoll", body);
}

/*Action ReqFrameTest(Handle timer, int body)
{
	if (!RealValidEntity(body)) return;
	DoDamage(body, -1, 100);
}*/

/*void DoDamage(int client, int sender, int damage, int damageType = 0)
{
	int iDmgEntity = CreateEntityByName("point_hurt");
	if (!RealValidEntity(iDmgEntity)) return;
	
	float spos[3];
	if (RealValidEntity(sender))
	{ GetEntPropVector(sender, Prop_Data, "m_vecOrigin", spos); }
	else
	{ GetEntPropVector(client, Prop_Data, "m_vecOrigin", spos); }
	
	TeleportEntity(iDmgEntity, spos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(iDmgEntity, "DamageTarget", "!activator");
	
	char temp_str[32];
	
	IntToString(damage, temp_str, sizeof(temp_str));
	DispatchKeyValue(iDmgEntity, "Damage", temp_str);
	IntToString(damageType, temp_str, sizeof(temp_str));
	DispatchKeyValue(iDmgEntity, "DamageType", temp_str);
	
	DispatchSpawn(iDmgEntity);
	ActivateEntity(iDmgEntity);
	AcceptEntityInput(iDmgEntity, "Hurt", client);
	AcceptEntityInput(iDmgEntity, "Kill");
}*/

bool RealValidEntity(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity)) return false;
	return true;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	//if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}