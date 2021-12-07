#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION						 "1.0.0"

/*
static const STATE_ROUNDHASNTSTARTED		= 2;
static const STATE_CANBESEEN				= 128;
*/

static Handle:cvarEnabled					= INVALID_HANDLE;
static Handle:cvarRangeSetting				= INVALID_HANDLE;

static const STATE_SPAWNREADY				= 0;
static const STATE_TOOCLOSE					= 256;

static propinfoghost						= -1;
static cvarEnabledValue						= 1;
static bool:isFinale						= false;
static Float:cvarRangeValue					= 150.0;

new survivorCount							= 0;
new survivorIndex[MAXPLAYERS+1]				= 0;
static const Float:	INDEX_REBUILD_DELAY		= 0.3;

#define FOR_EACH_ALIVE_SURVIVOR_INDEXED(%1)									\
	for(new %1 = 0, indexnumber = 1; indexnumber <= survivorCount; indexnumber++)	\
		if(((%1 = survivorIndex[indexnumber])) || true)		

public Plugin:myinfo = 
{
	name = "L4D2 Finale Ghost Range Mod",
	author = "AtomicStryker",
	description = " Revert Valves Stupid Range Decision ",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	RequireL4D2();
	
	CreateConVar("l4d2_finaleghost_rangemod_version", PLUGIN_VERSION, " Version of L4D2 Finale Ghost Range Mod on this Server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	
	cvarEnabled = CreateConVar("l4d2_finaleghost_rangemod_enabled", "1", " Turn the Range Mod on or off ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	cvarRangeSetting = CreateConVar("l4d2_finaleghost_rangemod_range", "150.0", " How close to the Survivors are you allowed to spawn ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	HookConVarChange(cvarEnabled, RM_ConvarsChanged);
	HookConVarChange(cvarRangeSetting, RM_ConvarsChanged);
	
	HookEvent("round_start", SI_TempStop_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", SI_TempStop_Event, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_death", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("bot_player_replace", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("defibrillator_used", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_team", SI_DelayedIndexRebuild_Event, EventHookMode_PostNoCopy);
	
	HookEvent("round_start", RM_Round_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", RM_Round_Event, EventHookMode_PostNoCopy);
	HookEvent("finale_start", RM_FinaleStart_Event, EventHookMode_PostNoCopy);
}

public RM_ConvarsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	cvarEnabledValue = GetConVarBool(cvarEnabled);
	cvarRangeValue = GetConVarFloat(cvarRangeSetting);
}

public Action:RM_Round_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	isFinale = false;
}

public Action:RM_FinaleStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	isFinale = true;
}

public OnClientPostAdminCheck(client)
{
    SDKHook(client, SDKHook_PreThinkPost, HookCallback);
}

public HookCallback(client)
{
	if (!cvarEnabledValue || !isFinale) return;
	if (GetClientTeam(client) != 3) return;
	if (!IsPlayerAlive(client)) return;
	if (!IsPlayerSpawnGhost(client)) return;

	if (GetEntProp(client, Prop_Send, "m_ghostSpawnState") == STATE_TOOCLOSE)
	{
		if (GetDistanceToNearestSurvivor(client) >= cvarRangeValue)
		{
			SetEntProp(client, Prop_Send, "m_ghostSpawnState", STATE_SPAWNREADY);
		}
	}
}

Float:GetDistanceToNearestSurvivor(client)
{
	decl Float:infectedorigin[3], Float:survivororigin[3], Float:vector[3];
	GetClientAbsOrigin(client, infectedorigin);

	new Float:distance;
	decl Float:comparevalue;
	FOR_EACH_ALIVE_SURVIVOR_INDEXED(i)
	{
		GetClientAbsOrigin(i, survivororigin);
		MakeVectorFromPoints(infectedorigin, survivororigin, vector);
		
		comparevalue = GetVectorLength(vector);
		
		if (distance > comparevalue || distance == 0.0)
		{
			distance = comparevalue;
		}
	}
	
	if (distance == 0.0) return 9999.9;
	else return distance;
}

stock RequireL4D2()
{
	decl String:gameName[24];
	GetGameFolderName(gameName, sizeof(gameName));
	if (!StrEqual(gameName, "left4dead2", .caseSensitive = false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
}

stock bool:IsPlayerSpawnGhost(client)
{
	if (GetEntData(client, propinfoghost, 1))
	{
		return true;
	}
	
	return false;
}

public OnMapStart()
{
	survivorCount = 0;
}

public OnMapEnd()
{
	survivorCount = 0;
}

public SI_DelayedIndexRebuild_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(INDEX_REBUILD_DELAY, SI_RebuildIndex_Timer);
}

public Action:SI_RebuildIndex_Timer(Handle:timer)
{
	SurvivorIndex_Rebuild();
}

public SI_TempStop_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	survivorCount = 0;	// to get rid of GetEntProp Entity errors before and after Mapchange
	CreateTimer(INDEX_REBUILD_DELAY, SI_RebuildIndex_Timer);
}

public RebuildIndex_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	SurvivorIndex_Rebuild();
}

SurvivorIndex_Rebuild()
{
	if (!IsServerProcessing()) return;

	survivorCount = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) !=2) continue;
		if (!IsPlayerAlive(i)) continue;
		
		survivorCount++;
		survivorIndex[survivorCount] = i;
	}
}