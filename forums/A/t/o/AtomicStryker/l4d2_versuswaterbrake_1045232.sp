#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1.1"
#define DEFAULT_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY

static const 		FRAMESKIP 				= 3;	// Our OnGameFrame function will only trigger every third Frame
static const		JUMPFLAG				= IN_JUMP;
static const		WATERFLAG				= FL_INWATER;
static const 		Float:FULL_SPEED		= 1.0;
static const 		Float:JUMP_PENALTY		= 0.25;	// gets added to the velocitymodifier on jumping
static const Float:	INDEX_REBUILD_DELAY		= 0.3;

static const String:LIMP_HEALTH_CONVAR[]	= "survivor_limp_health";
static const String:PLAYER_CLASSNAME[]		= "CTerrorPlayer";
static const String:MOVE_SPEED_ENTPROP[]	= "m_flLaggedMovementValue";
static const String:SPEED_MODIFY_ENTPROP[]	= "m_flVelocityModifier";
static const String:CONVAR_GAMEMODE[]		= "mp_gamemode";
 
static bool:isSlowedDown[MAXPLAYERS+1]		= false;
static bool:isJockeyed[MAXPLAYERS+1]		= false;
static bool:isAllowedMode					= false;

static enableBrake 							= 1;
static enableLowHealthBrake					= 0;
static lowHealthLimitLimp					= 40;
static Float:slowSetting 					= 0.75;
static everyXFrame							= 0;
static laggedMovementOffset					= 0;
static velocityModifierOffset				= 0;

static Handle:cvarEnabled 					= INVALID_HANDLE;
static Handle:cvarWaterSlow 				= INVALID_HANDLE;
static Handle:cvarJockeySlow 				= INVALID_HANDLE;
static Handle:cvarLowHealthSlow				= INVALID_HANDLE;
static Handle:cvarLimpHealth				= INVALID_HANDLE;
static Handle:cvarGameMode					= INVALID_HANDLE;
static Handle:cvarGameModeActive			= INVALID_HANDLE;

new survivorCount							= 0;
new survivorIndex[MAXPLAYERS+1]				= 0;

#define FOR_EACH_ALIVE_SURVIVOR_INDEXED(%1)									\
	for(new %1 = 0, indexnumber = 1; indexnumber <= survivorCount; indexnumber++)	\
		if(((%1 = survivorIndex[indexnumber])) || true)			

public Plugin:myinfo = 
{
	name = "L4D2 Versus Waterbrake",
	author = "AtomicStryker",
	description = " Allows slowing down Survivors in Water for Versus ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1045232"
}

public OnPluginStart()
{
	RequireL4D2();
	
	CreateConVar("l4d2_vswaterbrake_version", PLUGIN_VERSION, " Version of L4D2 Versus Water Brake on this Server ", DEFAULT_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	cvarEnabled = CreateConVar("l4d2_vswaterbrake_enabled", "1", " Turn Water Brake on or off ", DEFAULT_FLAGS);
	
	cvarWaterSlow = CreateConVar("l4d2_vswaterbrake_slow", "0.7", " How much slower will a Survivor be in water - 0.75 equals 75% speed ", DEFAULT_FLAGS);
	
	cvarJockeySlow = CreateConVar("l4d2_vswaterbrake_jockeyslow", "0", " Will a Jockeyed Survivor also be slowed down? ", DEFAULT_FLAGS);
	
	cvarLowHealthSlow = CreateConVar("l4d2_vswaterbrake_at_low_health", "0", " Enable or Disable Water Brake for low Health Survivors ", DEFAULT_FLAGS);
	
	cvarGameModeActive = CreateConVar("l4d2_vswaterbrake_gamemodeactive", "versus,teamversus,scavenge,teamscavenge,mutation12,mutation13", " Set the game mode for which the plugin should be activated (same usage as sv_gametypes, i.e. add all game modes where you want it active separated by comma) ");
	cvarGameMode = FindConVar(CONVAR_GAMEMODE);
	
	cvarLimpHealth = FindConVar(LIMP_HEALTH_CONVAR);
	laggedMovementOffset = FindSendPropInfo(PLAYER_CLASSNAME, MOVE_SPEED_ENTPROP);
	velocityModifierOffset = FindSendPropInfo(PLAYER_CLASSNAME, SPEED_MODIFY_ENTPROP);
	
	HookConVarChange(cvarEnabled, WB_ConvarsChanged);
	HookConVarChange(cvarWaterSlow, WB_ConvarsChanged);
	HookConVarChange(cvarLimpHealth, WB_ConvarsChanged);
	HookConVarChange(cvarLowHealthSlow, WB_ConvarsChanged);
	HookConVarChange(cvarGameMode, WB_ConvarsChanged);
	
	WB_OnPluginEnabled();
}

public WB_ConvarsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	enableBrake = GetConVarBool(cvarEnabled);
	slowSetting = GetConVarFloat(cvarWaterSlow);
	lowHealthLimitLimp = GetConVarInt(cvarLimpHealth);
	enableLowHealthBrake = GetConVarBool(cvarLowHealthSlow);
	CheckAllowedGameMode();
	
	if (enableBrake)
	{
		WB_OnPluginEnabled();
	}
	else
	{
		WB_OnPluginDisabled();
	}
}

static WB_OnPluginEnabled()
{
	HookEvent("round_start", WB_RoundStart_Event);
	HookEvent("round_end", WB_RoundEnd_Event);
	HookEvent("jockey_ride", WB_PlayerJockeyed_Event);
	HookEvent("jockey_ride_end", WB_JockeyRideEnd_Event);
	
	HookEvent("round_start", SI_TempStop_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", SI_TempStop_Event, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_death", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("bot_player_replace", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("defibrillator_used", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_team", SI_DelayedIndexRebuild_Event, EventHookMode_PostNoCopy);
}

static WB_OnPluginDisabled()
{
	UnhookEvent("round_start", WB_RoundStart_Event);
	UnhookEvent("round_end", WB_RoundEnd_Event);
	UnhookEvent("jockey_ride", WB_PlayerJockeyed_Event);
	UnhookEvent("jockey_ride_end", WB_JockeyRideEnd_Event);
	
	FOR_EACH_ALIVE_SURVIVOR_INDEXED(i)
	{
		if (isSlowedDown[i])
		{
			isSlowedDown[i] = false;
			SetEntDataFloat(i, laggedMovementOffset, FULL_SPEED, true);
		}
	}
}

static CheckAllowedGameMode()
{
	decl String:gamemode[64], String:gamemodeactive[64];
	GetConVarString(cvarGameMode, gamemode, sizeof(gamemode));
	GetConVarString(cvarGameModeActive, gamemodeactive, sizeof(gamemodeactive));
	isAllowedMode = (StrContains(gamemodeactive, gamemode) != -1);
}

public WB_RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	CheckAllowedGameMode();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		isJockeyed[i] = false;
	}
}

public WB_RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	isAllowedMode = false;
}

public WB_PlayerJockeyed_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarJockeySlow)) return; // if its disabled, it wont ever set the isJockeyed bool true

	new victimId = GetEventInt(event, "victim");
	if (!victimId || victimId > MAXPLAYERS) return;
	
	isJockeyed[victimId] = true;
	
	if (isSlowedDown[victimId]) // if a slow was in effect already
	{
		isSlowedDown[victimId] = false;
		SetEntDataFloat(victimId, laggedMovementOffset, FULL_SPEED, true); // reset plugin saved status and ingame speed
	}
}

public WB_JockeyRideEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "victim");
	if (!victimId || victimId > MAXPLAYERS) return;
	
	isJockeyed[victimId] = false;
}

public OnGameFrame()
{
	if (!IsServerProcessing()) return;

	if (!isAllowedMode || !enableBrake) return;
	
	if (!survivorCount) return;
	
	everyXFrame++;
	if (everyXFrame >= FRAMESKIP)
	{
		everyXFrame = 1;
		
		FOR_EACH_ALIVE_SURVIVOR_INDEXED(i)
		{
			if (!IsValidEntity(i)) continue;
			
			new flags = GetEntityFlags(i);
			
			if (flags & WATERFLAG) // case Survivor in water
			{
				if (!isSlowedDown[i] && !isJockeyed[i]) // and not jockeyed and not yet slowed
				{
					if (!enableLowHealthBrake && GetClientHealth(i) < lowHealthLimitLimp) return; // if Survivor Health is low and Low Health Brake not enabled return
					
					isSlowedDown[i] = true;
					SetEntDataFloat(i, laggedMovementOffset, slowSetting, true); // tell the plugin the Survivor is now slow and apply it
				}
				
				else if (isSlowedDown[i] && isJockeyed[i]) // is slowed but got jockeyed (now)
				{
					isSlowedDown[i] = false;
					SetEntDataFloat(i, laggedMovementOffset, FULL_SPEED, true); // remove slowdown
				}
			}
			
			else if (isSlowedDown[i]) // case Survivor not in water but slowed
			{
				isSlowedDown[i] = false;
				SetEntDataFloat(i, laggedMovementOffset, FULL_SPEED, true); // remove slowdown
				
				if (flags & JUMPFLAG) // if the survivor is jumping aswell
				{
					SetEntDataFloat(i, velocityModifierOffset, slowSetting - JUMP_PENALTY, true);	// apply velocity modifier with penalty so bunny hopping wont make you faster
																									// note: does not take effect until you touch ground again. pretty realistic actually.
					
					// also note: i could make Water Brake work with the velocity modifier entirely, but it causes microstuttering. laggedMovement is smooth
					// fun fact: whenever youre hit by a zombie you actually get microstuttering, valve covers it up by shaking your view
				}
			}
		}
	}
}

public OnMapStart()
{
	survivorCount = 0;
}

public OnMapEnd()
{
	survivorCount = 0;
}

public OnClientDisconnect()
{
	SurvivorIndex_Rebuild();
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
		if (GetClientTeam(i)!=2) continue;
		if (!IsPlayerAlive(i)) continue;
		
		survivorCount++;
		survivorIndex[survivorCount] = i;
	}
}

stock bool:IsVersus()
{
	decl String:gameMode[24];
	GetConVarString(FindConVar("mp_gamemode"), gameMode, sizeof(gameMode));
	
	return StrContains(gameMode, "versus", false) > -1;
}

static RequireL4D2()
{
	decl String:gameName[64];
	GetGameFolderName(gameName, sizeof(gameName));
	if (!StrEqual(gameName, "left4dead2", .caseSensitive = false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
}