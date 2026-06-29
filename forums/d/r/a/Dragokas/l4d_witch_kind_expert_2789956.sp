#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2"

public Plugin myinfo =
{
	name = "[L4D] DragoWitches: Kind expert witch",
	author = "Dragokas",
	description = "Make the witch to be kind on expert difficulty",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas/"
}

/*
	Credits:
	
	 * samuelviveiros a.k.a Dartz8901 - for Pet Witch, partially used in my plugin.
	
	Version history:
	
	 * 1.0 (20-Sep-2020)
	  - First Release.
	  
	 * 1.1
	  - Added more ConVars.
	
	 * 1.2 (20-Apr-2023)
	  - Added even more ConVars.
*/

#define SAFE_RAGE		0.8
#define WITCH_SEQUENCE_RUN_RETREAT  6
#define CVAR_FLAGS	FCVAR_NOTIFY

bool g_bEasy;
bool g_bNormal;
bool g_bHard;
bool g_bExpert;
bool g_bLateload;

#pragma unused g_bEasy, g_bNormal, g_bHard

ConVar g_ConVarDamageToSurvivor;
ConVar g_ConVarDamageToWitch;
ConVar g_ConVarHealthMultiplier;
ConVar g_ConVarSpeedMultiplier;
ConVar g_ConVarPreventAttackFirst;

ConVar g_ConVarDifficulty;
ConVar g_hCvarWitchSpeed;
ConVar g_hCvarWitchHealth;

int g_iWitchSpeedInit;
int g_iWitchHealthInit;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_witch_kind_expert_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);
	
	g_ConVarDamageToSurvivor 	= CreateConVar("l4d_witch_kind_damage_to_survivor", 	"5", 	"Maximum damage the witch can deal to survivor (on expert difficulty)", CVAR_FLAGS);
	g_ConVarDamageToWitch 		= CreateConVar("l4d_witch_kind_damage_to_witch", 	 	"10", 	"Maximum damage survivor can deal to the witch (for each bullet) (on expert difficulty)", CVAR_FLAGS);
	g_ConVarHealthMultiplier 	= CreateConVar("l4d_witch_kind_health_multiplier",  	"3.0", 	"Heath of the witch multiplied with this number (on expert difficulty)", CVAR_FLAGS);
	g_ConVarSpeedMultiplier 	= CreateConVar("l4d_witch_kind_speed_multiplier",   	"2.0", 	"Speed of the witch multiplied with this number (on expert difficulty)", CVAR_FLAGS);
	g_ConVarPreventAttackFirst 	= CreateConVar("l4d_witch_kind_prevent_attack_first",   "1", 	"Prevent witch to attack you first? (0 - No, 1 - Yes)", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d_witch_kind_expert");
	
	g_ConVarDifficulty = FindConVar("z_difficulty");
	g_hCvarWitchSpeed = FindConVar("z_witch_speed");
	g_hCvarWitchHealth = FindConVar("z_witch_health");
	
	HookConVarChange(g_ConVarDifficulty,	ConVarChanged);
	
	if( g_bLateload )
	{
		OnAllPluginsLoaded();
	}
	
	GetCvars();
}

public void OnAllPluginsLoaded()
{
	g_iWitchSpeedInit = g_hCvarWitchSpeed.IntValue;
	g_iWitchHealthInit = g_hCvarWitchHealth.IntValue;
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	RefreshDifficulty();
}

void RefreshDifficulty()
{
	static char sDif[32];
	g_bEasy = false;
	g_bNormal = false;
	g_bHard = false;
	g_bExpert = false;
	
	g_ConVarDifficulty.GetString(sDif, sizeof(sDif));
	if (StrEqual(sDif, "Easy", false)) {
		g_bEasy = true;
	}
	else if (StrEqual(sDif, "Normal", false)) {
		g_bNormal = true;
	}
	else if (StrEqual(sDif, "Hard", false)) {
		g_bHard = true;
	}
	else if (StrEqual(sDif, "Impossible", false)) {
		g_bExpert = true;
	}
	InitHook();
}

void InitHook()
{
	static bool bHooked;
	
	if( g_bExpert ) {
		if( !bHooked ) {
			HookEvent("witch_spawn", 			Event_WitchSpawn);
			HookDamageAll();
			HookWitchesAll();
			WitchSpeed();
			WitchHealth();
			bHooked = true;
		}
	} else {
		if( bHooked ) {
			UnhookEvent("witch_spawn", 			Event_WitchSpawn);
			UnhookDamageAll();
			UnhookWitchesAll();
			WitchSpeed();
			WitchHealth();
			bHooked = false;
		}
	}
}

void WitchSpeed()
{
	if( g_bExpert )
	{
		SetCvarSilent(g_hCvarWitchSpeed, float(g_iWitchSpeedInit) * g_ConVarSpeedMultiplier.FloatValue);
	}
	else {
		SetCvarSilent(g_hCvarWitchSpeed, float(g_iWitchSpeedInit));
	}
}

void WitchHealth()
{
	if( g_bExpert )
	{
		SetCvarSilent(g_hCvarWitchHealth, float(g_iWitchHealthInit) * g_ConVarHealthMultiplier.FloatValue);
	}
	else {
		SetCvarSilent(g_hCvarWitchHealth, float(g_iWitchHealthInit));
	}
}

stock void SetCvarSilent(ConVar cvar, float value)
{
	int flags = cvar.Flags;
	cvar.Flags &= ~FCVAR_NOTIFY;
	cvar.SetFloat(value);
	cvar.Flags = flags;
}

void HookDamageAll()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			OnClientPutInServer(i);
		}
	}
}

void UnhookDamageAll()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

void HookWitchesAll()
{
	int ent = -1;
	while( -1 != (ent = FindEntityByClassname(ent, "witch")))
	{
		SDKHook(ent, SDKHook_ThinkPost, PetWitch_ThinkHandler);
		SDKHook(ent, SDKHook_OnTakeDamage, OnTakeDamageWitch);
	}
}

void UnhookWitchesAll()
{
	int ent = -1;
	while( -1 != (ent = FindEntityByClassname(ent, "witch")))
	{
		SDKUnhook(ent, SDKHook_ThinkPost, PetWitch_ThinkHandler);
		SDKUnhook(ent, SDKHook_OnTakeDamage, OnTakeDamageWitch);
	}
}

public Action Event_WitchSpawn(Event event, const char[] sName, bool bDontBroadcast)
{
	int witch = event.GetInt("witchid");
	
	if( g_ConVarPreventAttackFirst.BoolValue )
	{
		SDKHook(witch, SDKHook_ThinkPost, PetWitch_ThinkHandler);
	}
	SDKHook(witch, SDKHook_OnTakeDamage, OnTakeDamageWitch);
	
	return Plugin_Continue;
}

void PetWitch_ThinkHandler(int witch)
{
	if ( GetEntPropFloat(witch, Prop_Send, "m_rage") > SAFE_RAGE )
	{
		SetEntPropFloat(witch, Prop_Send, "m_rage", SAFE_RAGE);
	}
	if ( GetEntProp(witch, Prop_Send, "m_nSequence") == WITCH_SEQUENCE_RUN_RETREAT )
	{
		SDKUnhook(witch, SDKHook_ThinkPost, PetWitch_ThinkHandler);
	}
}

stock bool IsWitchEntity(int iEntity)
{
	if( iEntity && iEntity != -1 && IsValidEntity(iEntity) )
	{
		static char sClassname[32];
		GetEntityClassname(iEntity, sClassname, sizeof(sClassname));
		return strcmp(sClassname, "witch") == 0;
	}
	return false;
}

public void OnClientPutInServer(int client)
{
	if( g_bExpert )
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if( victim && attacker && victim <= MaxClients && victim > 0 && GetClientTeam(victim) == 2 && IsWitchEntity(attacker) )
	{
		damage = g_ConVarDamageToSurvivor.FloatValue;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action OnTakeDamageWitch(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if( victim && attacker && attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == 2 )
	{
		damage = g_ConVarDamageToWitch.FloatValue;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
