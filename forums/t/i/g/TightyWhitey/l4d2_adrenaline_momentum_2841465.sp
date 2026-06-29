#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#define CVARFLAGS FCVAR_NOTIFY

#define PLUGIN_VERSION "1.0"

#if !defined DMG_CLUB
#define DMG_CLUB (1 << 7)
#endif
#if !defined DMG_BLAST
#define DMG_BLAST (1 << 6)
#endif

ConVar g_hCvarAllow;

ConVar g_hCvarModes;
ConVar g_hCvarMPGameMode;
bool g_bMapStarted;
bool g_bLateLoad;
bool g_bEnabled;
ConVar g_hCvarProtectTime;
ConVar g_hCvarSmoker;
ConVar g_hCvarBoomer;
ConVar g_hCvarHunter;
ConVar g_hCvarSpitter;
ConVar g_hCvarJockey;
ConVar g_hCvarCharger;
ConVar g_hCvarTank;
ConVar g_hCvarWitch;

ConVar g_hCvarMomentumEnable;
ConVar g_hCvarMomentumGap;
ConVar g_hCvarMomentumBreakOnPin;

ConVar g_hCvarAdrDuration;

bool  g_bCvarAllow;
float g_fCvarProtectTime;
bool  g_bSmoker;
bool  g_bBoomer;
bool  g_bHunter;
bool  g_bSpitter;
bool  g_bJockey;
bool  g_bCharger;
bool  g_bTank;
bool  g_bWitch;

bool  g_bMomentumEnabled;
float g_fMomentumGap;
bool  g_bMomentumBreakOnPin;

int   g_iProtFromInfected[MAXPLAYERS + 1];
float g_fProtUntil     [MAXPLAYERS + 1];

bool  g_bMomentumTracking [MAXPLAYERS + 1];
bool  g_bMomentumExtending[MAXPLAYERS + 1];
float g_fLastDamageTime   [MAXPLAYERS + 1];
float g_fAdrEndTime       [MAXPLAYERS + 1];

bool  g_bAnyMomentumTracking;

public Plugin myinfo =
{
	name        = "[L4D2] Adrenaline Momentum",
	author      = "Tighty-Whitey",
	description = "Adrenaline melee staggers infected and grants brief protection; optional momentum extends adrenaline while player keeps dealing damage.",
	version     = "1.0",
	url         = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if ( GetEngineVersion() != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "This plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow               = CreateConVar("l4d2_adrenaline_momentum_allow", "1", "Enable plugin (0/1).", CVARFLAGS);
	g_hCvarModes               = CreateConVar("l4d2_adrenaline_momentum_modes", "", "Enable in these modes (comma list). Empty = all.", CVARFLAGS);
	g_hCvarProtectTime         = CreateConVar("l4d2_adrenaline_momentum_protect", "1.0", "Protection window after stagger (seconds). (Tank's damage)", CVARFLAGS);

	g_hCvarSmoker              = CreateConVar("l4d2_adrenaline_momentum_smoker", "1", "Stagger/block Smoker (0/1).", CVARFLAGS);
	g_hCvarBoomer              = CreateConVar("l4d2_adrenaline_momentum_boomer", "1", "Stagger/block Boomer (0/1).", CVARFLAGS);
	g_hCvarHunter              = CreateConVar("l4d2_adrenaline_momentum_hunter", "1", "Stagger/block Hunter (0/1).", CVARFLAGS);
	g_hCvarSpitter             = CreateConVar("l4d2_adrenaline_momentum_spitter", "1", "Stagger/block Spitter (0/1).", CVARFLAGS);
	g_hCvarJockey              = CreateConVar("l4d2_adrenaline_momentum_jockey", "1", "Stagger/block Jockey (0/1).", CVARFLAGS);
	g_hCvarCharger             = CreateConVar("l4d2_adrenaline_momentum_charger", "1", "Stagger/block Charger (0/1).", CVARFLAGS);
	g_hCvarTank                = CreateConVar("l4d2_adrenaline_momentum_tank", "1", "Stagger/block Tank (0/1).", CVARFLAGS);
	g_hCvarWitch               = CreateConVar("l4d2_adrenaline_momentum_witch", "1", "Flinch/block Witch (0/1).", CVARFLAGS);

	g_hCvarMomentumEnable      = CreateConVar("l4d2_adrenaline_momentum_momentum", "1", "Enable momentum extension (0/1).", CVARFLAGS);
	g_hCvarMomentumGap         = CreateConVar("l4d2_adrenaline_momentum_gap", "15.0", "Max seconds between damage to keep momentum.", CVARFLAGS);
	g_hCvarMomentumBreakOnPin  = CreateConVar("l4d2_adrenaline_momentum_break_on_pin", "1", "Pin cancels momentum extension (0/1).", CVARFLAGS);
	g_hCvarAdrDuration = FindConVar("adrenaline_duration");

	AutoExecConfig(true, "l4d2_adrenaline_momentum");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	if ( g_hCvarMPGameMode != null ) g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);

	GetCvars();

	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarProtectTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSmoker.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarBoomer.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHunter.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpitter.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarJockey.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarCharger.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTank.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWitch.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMomentumEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMomentumGap.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMomentumBreakOnPin.AddChangeHook(ConVarChanged_Cvars);

	if ( g_bLateLoad )
	    g_bMapStarted = true;

	for ( int i = 1; i <= MaxClients; i++ )
	{
	    ResetClientState(i);

	    if ( IsClientInGame(i) )
	        OnClientPutInServer(i);
	}
}

public void OnConfigsExecuted()
{
	GetCvars();
	IsAllowed();
}

public void OnMapStart()
{
	g_bMapStarted = true;

	if ( g_bEnabled )
	    HookExistingWitches();
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
	IsAllowed();
}

void HookEvents(bool hook)
{
	static bool hooked;

	if ( !hooked && hook )
	{
	    hooked = true;

	    HookEvent("witch_spawn", Event_WitchSpawn);
	    HookEvent("adrenaline_used", Event_AdrenalineUsed);

	    HookEvent("lunge_pounce", Event_Pinned, EventHookMode_Post);
	    HookEvent("tongue_grab", Event_Pinned, EventHookMode_Post);
	    HookEvent("jockey_ride", Event_Pinned, EventHookMode_Post);
	    HookEvent("charger_carry_start", Event_Pinned, EventHookMode_Post);
	    HookEvent("charger_pummel_start", Event_Pinned, EventHookMode_Post);

	    HookEvent("player_incapacitated", Event_PlayerIncapacitated, EventHookMode_Post);
	}
	else if ( hooked && !hook )
	{
	    hooked = false;

	    UnhookEvent("witch_spawn", Event_WitchSpawn);
	    UnhookEvent("adrenaline_used", Event_AdrenalineUsed);

	    UnhookEvent("lunge_pounce", Event_Pinned);
	    UnhookEvent("tongue_grab", Event_Pinned);
	    UnhookEvent("jockey_ride", Event_Pinned);
	    UnhookEvent("charger_carry_start", Event_Pinned);
	    UnhookEvent("charger_pummel_start", Event_Pinned);

	    UnhookEvent("player_incapacitated", Event_PlayerIncapacitated);
	}
}

bool IsAllowedGameMode()
{
	if ( g_hCvarMPGameMode == null )
	    return false;

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if ( sGameModes[0] )
	{
	    Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
	    if ( StrContains(sGameModes, sGameMode, false) == -1 )
	        return false;
	}

	return true;
}

void IsAllowed()
{
	bool allow = g_bCvarAllow && IsAllowedGameMode();

	if ( allow && !g_bEnabled )
	{
	    g_bEnabled = true;

	    HookEvents(true);

	    for ( int i = 1; i <= MaxClients; i++ )
	    {
	        if ( IsClientInGame(i) )
	        {
	            SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	        }
	    }

	    if ( g_bMapStarted )
	        HookExistingWitches();
	}
	else if ( !allow && g_bEnabled )
	{
	    g_bEnabled = false;

	    HookEvents(false);

	    for ( int i = 1; i <= MaxClients; i++ )
	    {
	        if ( IsClientInGame(i) )
	        {
	            SDKUnhook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	            ResetClientState(i);
	        }
	    }

	    UnhookExistingWitches();

	    g_bAnyMomentumTracking = false;
	}
}

void UnhookExistingWitches()
{
	int ent = -1;
	while ( (ent = FindEntityByClassname(ent, "witch")) != INVALID_ENT_REFERENCE )
	{
	    if ( IsValidEntity(ent) )
	        SDKUnhook(ent, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	}
}

void ResetClientState(int client)
{
	g_iProtFromInfected[client] = 0;
	g_fProtUntil[client]        = -9999.0;

	g_bMomentumTracking[client]  = false;
	g_bMomentumExtending[client] = false;
	g_fLastDamageTime[client]    = -9999.0;
	g_fAdrEndTime[client]        = -9999.0;
}

void RecomputeAnyMomentumTracking()
{
	g_bAnyMomentumTracking = false;

	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( g_bMomentumTracking[i] )
		{
			g_bAnyMomentumTracking = true;
			return;
		}
	}
}

void HookExistingWitches()
{
	if ( !g_bEnabled )
	    return;

	int ent = -1;
	while ( (ent = FindEntityByClassname(ent, "witch")) != INVALID_ENT_REFERENCE )
	{
		if ( IsValidEntity(ent) )
		{
			SDKHook(ent, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if ( StrEqual(classname, "infected", false) )
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageCommon);
	}
}

public Action OnTakeDamageCommon(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if ( !g_bEnabled || !g_bMomentumEnabled )
		return Plugin_Continue;

	if ( attacker >= 1 && attacker <= MaxClients && IsSurvivor(attacker) && g_bMomentumTracking[attacker] )
	{
		g_fLastDamageTime[attacker] = GetGameTime();
	}

	return Plugin_Continue;
}

public void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int witch = event.GetInt("witchid");
	if ( witch > 0 && IsValidEntity(witch) )
	{
		SDKHook(witch, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	}
}

public void Event_AdrenalineUsed(Event event, const char[] name, bool dontBroadcast)
{
	if ( !g_bEnabled || !g_bMomentumEnabled )
	    return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if ( !IsSurvivor(client) )
		return;

	float now = GetGameTime();

	g_bMomentumTracking[client]  = true;
	g_bMomentumExtending[client] = false;
	g_fLastDamageTime[client]    = now;

	float baseDur = 15.0;
	if ( g_hCvarAdrDuration != null )
		baseDur = g_hCvarAdrDuration.FloatValue;

	g_fAdrEndTime[client] = now + baseDur;

	g_bAnyMomentumTracking = true;
}

public void Event_Pinned(Event event, const char[] name, bool dontBroadcast)
{
	if ( !g_bEnabled || !g_bMomentumEnabled || !g_bMomentumBreakOnPin )
		return;

	int victim = GetClientOfUserId(event.GetInt("victim"));
	if ( victim <= 0 || victim > MaxClients || !IsSurvivor(victim) )
		return;

	if ( !g_bMomentumTracking[victim] )
		return;

	float now = GetGameTime();

	if ( now <= g_fAdrEndTime[victim] )
		return;

	if ( g_bMomentumExtending[victim] )
	{
		SetEntProp(victim, Prop_Send, "m_bAdrenalineActive", 0); // cancel extended adrenaline.
	}

	g_bMomentumTracking[victim]  = false;
	g_bMomentumExtending[victim] = false;
	g_fLastDamageTime[victim]    = -9999.0;
	g_fAdrEndTime[victim]        = -9999.0;

	RecomputeAnyMomentumTracking();
}

public void Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	if ( !g_bEnabled || !g_bMomentumEnabled )
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if ( client <= 0 || client > MaxClients || !IsSurvivor(client) )
		return;

	if ( !g_bMomentumTracking[client] )
		return;

	float now = GetGameTime();

	if ( now > g_fAdrEndTime[client] && g_bMomentumExtending[client] )
	{
		SetEntProp(client, Prop_Send, "m_bAdrenalineActive", 0);
	}

	g_bMomentumTracking[client]  = false;
	g_bMomentumExtending[client] = false;
	g_fLastDamageTime[client]    = -9999.0;
	g_fAdrEndTime[client]        = -9999.0;

	RecomputeAnyMomentumTracking();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarAllow       = g_hCvarAllow.BoolValue;
	g_fCvarProtectTime = g_hCvarProtectTime.FloatValue;
	if ( g_fCvarProtectTime < 0.0 )
		g_fCvarProtectTime = 0.0;

	g_bSmoker  = g_hCvarSmoker.BoolValue;
	g_bBoomer  = g_hCvarBoomer.BoolValue;
	g_bHunter  = g_hCvarHunter.BoolValue;
	g_bSpitter = g_hCvarSpitter.BoolValue;
	g_bJockey  = g_hCvarJockey.BoolValue;
	g_bCharger = g_hCvarCharger.BoolValue;
	g_bTank    = g_hCvarTank.BoolValue;
	g_bWitch   = g_hCvarWitch.BoolValue;

	g_bMomentumEnabled   = g_hCvarMomentumEnable.BoolValue;
	g_fMomentumGap       = g_hCvarMomentumGap.FloatValue;
	if ( g_fMomentumGap < 0.0 )
		g_fMomentumGap = 0.0;

	g_bMomentumBreakOnPin = g_hCvarMomentumBreakOnPin.BoolValue;

	if ( !g_bMomentumEnabled )
	{
		g_bAnyMomentumTracking = false;
	}
}

public void OnClientPutInServer(int client)
{
	if ( g_bEnabled )
	    SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	ResetClientState(client);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	ResetClientState(client);
	RecomputeAnyMomentumTracking();
}

bool IsSurvivor(int client)
{
	return (client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& GetClientTeam(client) == 2);
}

bool IsInfectedClient(int client)
{
	return (client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& GetClientTeam(client) == 3);
}

bool IsWitchEnt(int ent)
{
	if ( ent <= MaxClients || !IsValidEntity(ent) )
		return false;

	char classname[16];
	GetEdictClassname(ent, classname, sizeof(classname));
	return StrEqual(classname, "witch", false);
}

bool IsClassAllowed(int client)
{
	int zclass = GetEntProp(client, Prop_Send, "m_zombieClass"); // 1=Smoker,...,8=Tank.

	switch( zclass )
	{
		case 1: return g_bSmoker;
		case 2: return g_bBoomer;
		case 3: return g_bHunter;
		case 4: return g_bSpitter;
		case 5: return g_bJockey;
		case 6: return g_bCharger;
		case 8: return g_bTank;
	}

	return false;
}

bool IsAdrenalineActiveNet(int client)
{
	if ( !IsSurvivor(client) )
		return false;

	return (GetEntProp(client, Prop_Send, "m_bAdrenalineActive") != 0);
}

bool IsMeleeHit(int attacker, int inflictor, int damagetype)
{
	if ( damagetype & DMG_CLUB )
		return true;

	if ( inflictor > MaxClients && IsValidEntity(inflictor) )
	{
		char classname[32];
		GetEdictClassname(inflictor, classname, sizeof(classname));

		if ( StrEqual(classname, "weapon_melee") )
		{
			return true;
		}
	}

	return false;
}

void ClearPlayerStagger(int client)
{
	if ( client > 0 && client <= MaxClients && IsClientInGame(client) )
	{
		SetEntPropFloat(client, Prop_Send, "m_staggerTimer", -1.0, 1);
	}
}

public Action Timer_RestoreState(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if ( client <= 0 || !IsClientInGame(client) )
		return Plugin_Stop;

	ClearPlayerStagger(client);

	float origin[3], angles[3], vel[3] = { 0.0, 0.0, 0.0 };
	GetClientAbsOrigin(client, origin);
	GetClientEyeAngles(client, angles);
	TeleportEntity(client, origin, angles, vel);

	float now = GetGameTime();

	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", now - 0.01); // survivor attack cooldown.

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if ( weapon > MaxClients && IsValidEntity(weapon) )
	{
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", now - 0.01); // weapon cooldown.
	}

	return Plugin_Stop;
}

public void OnGameFrame()
{
	if ( !g_bEnabled || !g_bMomentumEnabled || !g_bAnyMomentumTracking )
		return;

	float now = GetGameTime();

	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( !g_bMomentumTracking[i] )
			continue;

		if ( !IsSurvivor(i) )
		{
			g_bMomentumTracking[i]  = false;
			g_bMomentumExtending[i] = false;
			continue;
		}

		if ( now <= g_fAdrEndTime[i] )
			continue;

		float gap = now - g_fLastDamageTime[i];

		if ( !g_bMomentumExtending[i] )
		{
			if ( gap <= g_fMomentumGap )
			{
				g_bMomentumExtending[i] = true;
				SetEntProp(i, Prop_Send, "m_bAdrenalineActive", 1);
			}
			else
			{
				g_bMomentumTracking[i] = false;
				RecomputeAnyMomentumTracking();
			}

			continue;
		}

		if ( gap <= g_fMomentumGap )
		{
			SetEntProp(i, Prop_Send, "m_bAdrenalineActive", 1);
		}
		else
		{
			SetEntProp(i, Prop_Send, "m_bAdrenalineActive", 0);
			g_bMomentumTracking[i]  = false;
			g_bMomentumExtending[i] = false;
			RecomputeAnyMomentumTracking();
		}
	}
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if ( !g_bEnabled )
		return Plugin_Continue;

	float now = GetGameTime();

	if ( g_bMomentumEnabled && attacker >= 1 && attacker <= MaxClients && IsSurvivor(attacker) && g_bMomentumTracking[attacker] )
	{
		g_fLastDamageTime[attacker] = now;
	}

	if ( IsSurvivor(victim) )
	{
		int surv = victim;

		if ( attacker > 0
		 && attacker == g_iProtFromInfected[surv]
		 && now <= g_fProtUntil[surv] )
		{
			ClearPlayerStagger(surv);
			damage = 0.0;

			CreateTimer(0.0, Timer_RestoreState, GetClientUserId(surv), TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Handled;
		}
	}

	bool bInfectedClient = IsInfectedClient(victim);
	bool bWitch          = IsWitchEnt(victim);

	if ( !bInfectedClient && !bWitch )
		return Plugin_Continue;

	if ( attacker < 1 || attacker > MaxClients )
		return Plugin_Continue;

	if ( !IsSurvivor(attacker) )
		return Plugin_Continue;

	int surv2 = attacker;

	if ( !IsAdrenalineActiveNet(surv2) && !(g_bMomentumEnabled && g_bMomentumExtending[surv2]) )
		return Plugin_Continue;

	if ( !IsMeleeHit(surv2, inflictor, damagetype) )
		return Plugin_Continue;

	if ( bWitch )
	{
		if ( !g_bWitch )
			return Plugin_Continue;

		SDKHooks_TakeDamage(victim, surv2, surv2, 1.0, DMG_BLAST);
	}
	else
	{
		if ( !IsClassAllowed(victim) )
			return Plugin_Continue;

		float srcPos[3];
		GetClientAbsOrigin(surv2, srcPos);
		StaggerFromPosition(GetClientUserId(victim), srcPos);
	}

	g_iProtFromInfected[surv2] = victim;
	g_fProtUntil[surv2]        = now + g_fCvarProtectTime;

	return Plugin_Continue;
}

void StaggerFromPosition(int userid, const float worldPos[3])
{
	int logic = CreateEntityByName("logic_script");
	if ( logic == -1 || !IsValidEntity(logic) )
	{
		LogError("Failed to create logic_script for stagger.");
		return;
	}

	DispatchSpawn(logic);

	char script[192];

	int x = RoundFloat(worldPos[0]);
	int y = RoundFloat(worldPos[1]);
	int z = RoundFloat(worldPos[2]);

	Format(script, sizeof(script),
		"local p = GetPlayerFromUserID(%d); if (p != null) p.Stagger(Vector(%d,%d,%d));",
		userid, x, y, z);

	SetVariantString(script);
	AcceptEntityInput(logic, "RunScriptCode");

	RemoveEntity(logic);
}
