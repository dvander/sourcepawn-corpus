#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

/*
	Change me to true to limit effects shown to host by half
*/
#define MANAGEHOST false

#if MANAGEHOST
static bool IsDedicated;
#endif

#define PLUGIN_VERSION "1.0"

static ConVar hCvar_Ragdoll_Max_Count;
static ConVar hCvar_Ragdoll_Per_Sec;
static ConVar hCvar_Deaths_Max_Count;
static ConVar hCvar_Deaths_Per_Sec;
static ConVar hCvar_Max_Deaths_Per_Frame;
static ConVar hCvar_Chance_Blast_FlyToSky;

static float g_fRagdollMaxCount;
static float g_fRagdollCount;
static float g_fRagdollInc;

static float g_fDeathsMaxCount;
static float g_fCurrentDeaths;
static float g_fDeathsInc;
static int g_iMaxDeathsPerFrame;
static int g_iCurrentDeathsFrame;
static int g_iRagdollFlyChance;

enum AlienDeathType
{
	AlienDeathType_Vanish = 0,
	AlienDeathType_Ragdoll,
	AlienDeathType_Gibs,
	AlienDeathType_Heavy_Gibs,
	AlienDeathType_Bleed_To_Heavy_Gibs,
	AlienDeathType_Fly_To_Sky,
	AlienDeathType_Exaggerated_Ragdoll_Force,
	AlienDeathType_Vanish_Again
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_AlienSwarm )
	{
		strcopy(error, err_max, "Plugin only supports Alien Swarm");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "swarm_drone_force_ragdoll",
	author = "Lux",
	description = "Forces alien drones to ragdoll and gibs underheavy load for perf reasons",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=315209"
};


public void OnPluginStart()
{
	CreateConVar("swarm_drone_force_ragdoll_version", PLUGIN_VERSION, _, FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	hCvar_Ragdoll_Max_Count = CreateConVar("swarm_ragdoll_max_count", "30.0", "uppderlimit to amount of drone ragdolls once exceeded will cause aliens to gib instead(perf reasons) see \"swarm_max_shown_deaths\" & \"swarm_shown_deaths_per_sec\"", FCVAR_NOTIFY, true, 1.0);
	hCvar_Ragdoll_Per_Sec = CreateConVar("swarm_ragdoll_per_sec", "5.0", "max ragdolls that can be shown per second while at the upperlimit", FCVAR_NOTIFY, true, 1.0);
	hCvar_Deaths_Max_Count = CreateConVar("swarm_max_shown_deaths", "30.0", "uppderlimit to amount of deaths to show to clients before culling not counted when alien ragdolls", FCVAR_NOTIFY, true, 1.0);
	hCvar_Deaths_Per_Sec = CreateConVar("swarm_shown_deaths_per_sec", "60.0", "max deaths that can be shown per second while at the upperlimit", FCVAR_NOTIFY, true, 1.0);
	hCvar_Max_Deaths_Per_Frame = CreateConVar("swarm_max_shown_deaths_frame", "30", "max amount of deaths to show in 1 server frame", FCVAR_NOTIFY, true, 1.0);
	hCvar_Chance_Blast_FlyToSky = CreateConVar("swarm_chance_to_fly", "30", "percent chance blasts will cause ragdolls to fly up", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	hCvar_Ragdoll_Max_Count.AddChangeHook(eConvarChanged);
	hCvar_Ragdoll_Per_Sec.AddChangeHook(eConvarChanged);
	hCvar_Deaths_Max_Count.AddChangeHook(eConvarChanged);
	hCvar_Deaths_Per_Sec.AddChangeHook(eConvarChanged);
	hCvar_Max_Deaths_Per_Frame.AddChangeHook(eConvarChanged);
	hCvar_Chance_Blast_FlyToSky.AddChangeHook(eConvarChanged);
	
	HookEvent("entity_killed", eEntDeath);
	
	#if MANAGEHOST
	IsDedicated = IsDedicatedServer();
	#endif
	
	AutoExecConfig(true, "swarm_drone_force_ragdoll");
	CvarsChanged();
}

public void eConvarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void CvarsChanged()
{
	float fTickInt = GetTickInterval();
	g_fRagdollMaxCount = hCvar_Ragdoll_Max_Count.FloatValue;
	g_fRagdollInc = fTickInt * hCvar_Ragdoll_Per_Sec.FloatValue;
	g_fDeathsMaxCount = hCvar_Deaths_Max_Count.FloatValue;
	g_fDeathsInc = fTickInt * hCvar_Deaths_Per_Sec.FloatValue;
	g_iMaxDeathsPerFrame = hCvar_Max_Deaths_Per_Frame.IntValue;
	g_iRagdollFlyChance = hCvar_Chance_Blast_FlyToSky.IntValue;
}

public void eEntDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iVictim = hEvent.GetInt("entindex_killed");
	if(iVictim < MaxClients+1 || iVictim > 2048 || !IsValidEntity(iVictim))
		return;
	
	char sNetclass[21];
	GetEntityNetClass(iVictim, sNetclass, sizeof(sNetclass));
	if(!StrEqual(sNetclass, "CASW_Drone_Advanced", false))
		return;
	
	#if MANAGEHOST
	if(!IsDedicated)
	{
		static int skip = 0;
		skip = (skip + 1) % 2;
		if(skip == 0)// hide half the amount of effects for perf reasons
			SDKHook(iVictim, SDKHook_SetTransmit, HideFromHost);
		
	}
	#endif
	
	if(g_iCurrentDeathsFrame >= g_iMaxDeathsPerFrame)
	{
		SDKHook(iVictim, SDKHook_SetTransmit, HideFromClient);
		return;
	}
	
	g_iCurrentDeathsFrame++;
	
	if(g_fRagdollCount >= g_fRagdollMaxCount)
	{
		if(g_fCurrentDeaths < g_fDeathsMaxCount)
		{
			SetEntProp(iVictim, Prop_Send, "m_nDeathStyle", AlienDeathType_Gibs, 1);
			g_fDeathsInc++;
			return;
		}
		SDKHook(iVictim, SDKHook_SetTransmit, HideFromClient);
		return;
	}
	
	if(hEvent.GetInt("damagebits") & DMG_BLAST && GetRandomInt(0, 100) <= g_iRagdollFlyChance)
	{
		SetEntProp(iVictim, Prop_Send, "m_nDeathStyle", AlienDeathType_Fly_To_Sky, 1);
	}
	else
	{
		SetEntProp(iVictim, Prop_Send, "m_nDeathStyle", AlienDeathType_Exaggerated_Ragdoll_Force, 1);
	}
	g_fRagdollCount++;
}

public Action HideFromClient(int iEntity, int iClient)
{
	return Plugin_Handled;
}

#if MANAGEHOST
public Action HideFromHost(int iEntity, int iClient)
{
	if(iClient == 1)// i think the host is always index 1, i could never get any other index
		return Plugin_Handled;
	return Plugin_Continue;
}
#endif
public void OnGameFrame()
{
	g_iCurrentDeathsFrame = 0;
	if(g_fRagdollCount > g_fRagdollInc)
		g_fRagdollCount -= g_fRagdollInc;
	if(g_fCurrentDeaths > g_fDeathsInc)
		g_fCurrentDeaths -= g_fDeathsInc;
}
