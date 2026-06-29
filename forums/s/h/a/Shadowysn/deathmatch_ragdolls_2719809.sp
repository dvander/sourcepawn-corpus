#define PLUGIN_NAME "[CS:S] Deathmatch Ragdolls"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Converts player ragdolls into ragdolls suited for deathmatch play."
#define PLUGIN_VERSION "1.1.1"
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

#define RAGMANAGE_CLASS "game_ragdoll_manager"
#define TEMPRAG_CLASS "plugin_temp_ragdoll"

#define AUTOEXEC_CFG "deathmatch_ragdolls"

bool g_bFadeRags = false;
int g_iTempRagdoll[MAXPLAYERS+1];

ConVar Ragdoll_Type, Ragdoll_Amount, Ragdoll_AmountDX8;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_CSS)
		return APLRes_Success;
	strcopy(error, err_max, "Plugin only supports Counter-Strike: Source.");
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
	ConVar version_cvar = CreateConVar("sm_"...PLUGIN_NAME_TECH..."_version", PLUGIN_VERSION, PLUGIN_NAME_SHORT..." version.", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	if (version_cvar != null)
		version_cvar.SetString(PLUGIN_VERSION);
	
	Ragdoll_Type = CreateConVar("sm_"...PLUGIN_NAME_TECH..."_ragdoll_type", "0.0", "-1 = Off. 0 = On.", FCVAR_NONE, true, -1.0, true, 0.0);
	
	Ragdoll_Amount = CreateConVar("sm_"...PLUGIN_NAME_TECH..."_amount", "8.0", "Number of ragdolls that must exist at a time.", FCVAR_NONE, true, 0.0, true, 31.0);
	Ragdoll_Amount.AddChangeHook(RagAmountChanged);
	
	Ragdoll_AmountDX8 = CreateConVar("sm_"...PLUGIN_NAME_TECH..."_amount_dx8", "4.0", "Number of ragdolls that must exist at a time, for DirectX 8.0 or below.", FCVAR_NONE, true, 0.0, true, 31.0);
	Ragdoll_AmountDX8.AddChangeHook(RagAmountChanged);
	
	HookEvent("player_spawn", player_spawn, EventHookMode_Post);
	HookEvent("player_death", player_death, EventHookMode_Post);
	HookEvent("round_start", round_start, EventHookMode_Post);
	
	if (IsValidEntity(0))
		UpdateRagdollAmount(8, false, true);
	
	AutoExecConfig(true, AUTOEXEC_CFG);
}

void RagAmountChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue, false) != 0)
	{
		bool isDX8Cvar = false;
		char tempStr[32];
		cvar.GetName(tempStr, sizeof(tempStr));
		
		if (StrContains(tempStr, "dx8", false) >= 0) isDX8Cvar = true;
		
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
	return Plugin_Continue;
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
	
	char tempStr[4];
	if (init)
	{
		IntToString(Ragdoll_Amount.IntValue, tempStr, sizeof(tempStr));
		SetVariantString(tempStr);
		AcceptEntityInput(manager, "SetMaxRagdollCount");
		IntToString(Ragdoll_AmountDX8.IntValue, tempStr, sizeof(tempStr));
		SetVariantString(tempStr);
		AcceptEntityInput(manager, "SetMaxRagdollCountDX8");
	}
	else
	{
		IntToString(newValue, tempStr, sizeof(tempStr));
		SetVariantString(tempStr);
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

void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	if (Ragdoll_Type.IntValue == -1) return;
	
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	if (client == 0) return;
	
	int temprag = g_iTempRagdoll[client];
	if (RealValidEntity(temprag))
	{
		AcceptEntityInput(temprag, "Kill");
		g_iTempRagdoll[client] = INVALID_ENT_REFERENCE;
	}
}

void player_death(Event event, const char[] name, bool dontBroadcast)
{
	if (Ragdoll_Type.IntValue == -1) return;
	
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	if (client == 0) return;
	//int attacker = GetClientOfUserId(event.GetInt("attacker", 0));
	
	int prev_ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!RealValidEntity(prev_ragdoll)) return;
	
	float vecForce[3];
	GetEntPropVector(prev_ragdoll, Prop_Send, "m_vecForce", vecForce);
	int nForceBone = GetEntProp(prev_ragdoll, Prop_Send, "m_nForceBone");
	int iDeathPose = GetEntProp(prev_ragdoll, Prop_Send, "m_iDeathPose");
	int iDeathFrame = GetEntProp(prev_ragdoll, Prop_Send, "m_iDeathFrame");
	
	AcceptEntityInput(prev_ragdoll, "Kill");
	
	CreateDisconRagdoll(client, /*attacker,*/ vecForce, nForceBone, iDeathPose, iDeathFrame);
}

void CreateDisconRagdoll(int client, /*int attacker = -1,*/ const float vecForce[3], int nForceBone = 0, int iDeathPose = -1, int iDeathFrame = -1)
{
	if (iDeathPose < 0)
	{ iDeathPose = GetEntProp(client, Prop_Send, "m_nSequence"); }
	if (iDeathFrame < 0)
	{ iDeathFrame = GetEntProp(client, Prop_Send, "m_flAnimTime"); }
	
	int body = CreateEntityByName("scripted_target");
	if (!RealValidEntity(body)) return;
	
	SetVariantString("OnUser1 !self:Kill::1.0:1");
	AcceptEntityInput(body, "AddOutput");
	AcceptEntityInput(body, "FireUser1");
	
	g_iTempRagdoll[client] = body;
	
	//int health = GetClientHealth(client);
	
	char tempStr[64];
	
	IntToString(GetEntProp(client, Prop_Data, "m_iMaxHealth"), tempStr, sizeof(tempStr));
	DispatchKeyValue(body, "max_health", tempStr);
	
	//IntToString(health, tempStr, sizeof(tempStr));
	//DispatchKeyValue(body, "health", tempStr);
	DispatchKeyValue(body, "health", "1");
	
	//DispatchKeyValue(body, "hull_name", "Human");
	DispatchKeyValue(body, "solid", "0");
	
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
	
	DispatchSpawn(body);
	ActivateEntity(body);
	
	DispatchKeyValue(body, "nextthink", "0");
	
	TeleportEntity(body, origin, angles, NULL_VECTOR);
	//SetEdictFlags(body, FL_EDICT_ALWAYS);
	
	GetClientModel(client, tempStr, sizeof(tempStr));
	PrecacheModel(tempStr);
	SetEntityModel(body, tempStr);
	
	strcopy(tempStr, sizeof(tempStr), TEMPRAG_CLASS);
	SetEntPropString(body, Prop_Data, "m_iClassname", tempStr);
	
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
	
	SetEntProp(body, Prop_Data, "m_takedamage", 0);
	AcceptEntityInput(body, "BecomeRagdoll");
	
	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	
	float velfloat[3];
	velfloat[0] = vecForce[0]; velfloat[1] = vecForce[1]; velfloat[2] = vecForce[2];
	velfloat[0] += velocity[0];
	velfloat[1] += velocity[1];
	velfloat[2] += velocity[2];
	
	SetEntPropVector(body, Prop_Send, "m_vecForce", velfloat);
	SetEntProp(body, Prop_Send, "m_nForceBone", nForceBone);
	
	//SetEntPropEnt(client, Prop_Send, "m_hRagdoll", body);
}

stock bool RealValidEntity(int entity)
{
	return (entity > 0 && IsValidEntity(entity));
}