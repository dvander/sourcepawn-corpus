#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION 						  "1.0.7"

#define TEST_DEBUG 		0
#define TEST_DEBUG_LOG 	0


static const Float:CHARGE_CHECKING_INTERVAL	= 0.4;
static const Float:ANGLE_STRAIGHT_DOWN[3]	= { 90.0 , 0.0 , 0.0 };
static const String:SOUND_EFFECT[]			= "./level/loud/climber.wav";

static Handle:cvarisEnabled					= INVALID_HANDLE;
static Handle:triggeringHeight				= INVALID_HANDLE;
static Handle:chargerTimer					= INVALID_HANDLE;
static Handle:karmaTime						= INVALID_HANDLE;
static Handle:cvarNotify					= INVALID_HANDLE;
static Handle:cvarModeSwitch				= INVALID_HANDLE;
static bool:isEnabled						= true;
static Float:lethalHeight					= 475.0;


public Plugin:myinfo = 
{
	name = "L4D2 Karma Charge",
	author = " AtomicStryker",
	description = " Slows down time and displays stuff on Lethal Charges ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1239108"
}

public OnPluginStart()
{
	HookEvent("charger_carry_start", event_ChargerGrab);
	HookEvent("charger_carry_end", event_GrabEnded);
	
	CreateConVar("l4d2_karma_charge_version", 						PLUGIN_VERSION, " L4D2 Karma Charge Plugin Version ", 									FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	triggeringHeight = 	CreateConVar("l4d2_karma_charge_height",	"475.0", 		" What Height is considered karma ", 									FCVAR_PLUGIN|FCVAR_REPLICATED);
	karmaTime =			CreateConVar("l4d2_karma_charge_slowtime", 	"1.5", 			" How long does Time get slowed ", 										FCVAR_PLUGIN|FCVAR_REPLICATED);
	cvarisEnabled = 	CreateConVar("l4d2_karma_charge_enabled", 	"1", 			" Turn Karma Charge on and off ", 										FCVAR_PLUGIN|FCVAR_REPLICATED);
	cvarNotify = 		CreateConVar("l4d2_karma_charge_notify", 	"1", 			" Turn Chat Announcement on and off ", 									FCVAR_PLUGIN|FCVAR_REPLICATED);
	cvarModeSwitch =	CreateConVar("l4d2_karma_charge_slowmode", 	"0", 			" 0 - Entire Server gets slowed, 1 - Only Charger and Survivor do ", 	FCVAR_PLUGIN|FCVAR_REPLICATED);
	
	HookConVarChange(cvarisEnabled, 	_cvarChange);
	HookConVarChange(triggeringHeight, 	_cvarChange);
}

public OnMapStart()
{
	PrefetchSound(SOUND_EFFECT);
	PrecacheSound(SOUND_EFFECT);
	chargerTimer = INVALID_HANDLE;
}

public _cvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	isEnabled = 	GetConVarBool(cvarisEnabled);
	lethalHeight = 	GetConVarFloat(triggeringHeight);
}

public Action:event_ChargerGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!isEnabled
	|| !client
	|| !IsClientInGame(client))
	{
		return;
	}
	
	DebugPrintToAll("Charger Carry event caught, initializing timer");
	
	if (chargerTimer != INVALID_HANDLE)
	{
		CloseHandle(chargerTimer);
		chargerTimer = INVALID_HANDLE;
	}
	
	chargerTimer = CreateTimer(CHARGE_CHECKING_INTERVAL, _timer_Check, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	TriggerTimer(chargerTimer, true);
}

public Action:event_GrabEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (chargerTimer != INVALID_HANDLE)
	{
		CloseHandle(chargerTimer);
		chargerTimer = INVALID_HANDLE;
	}
}

public Action:_timer_Check(Handle:timer, any:client)
{
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		chargerTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if (GetEntityFlags(client) & FL_ONGROUND) return Plugin_Continue;
	
	new Float:height = GetHeightAboveGround(client);
	
	DebugPrintToAll("Karma Check - Charger Height is now: %f", height);
	
	if (height > lethalHeight)
	{
		AnnounceKarmaCharge(client);
		chargerTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

static Float:GetHeightAboveGround(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	// execute Trace straight down
	new Handle:trace = TR_TraceRayFilterEx(pos, ANGLE_STRAIGHT_DOWN, MASK_SHOT, RayType_Infinite, _TraceFilter);
	
	if (!TR_DidHit(trace))
	{
		LogError("Tracer Bug: Trace did not hit anything, WTF");
	}
	
	decl Float:vEnd[3];
	TR_GetEndPosition(vEnd, trace); // retrieve our trace endpoint
	CloseHandle(trace);
	
	return GetVectorDistance(pos, vEnd, false);
}

public bool:_TraceFilter(entity, contentsMask)
{
	if (!entity || !IsValidEntity(entity)) // dont let WORLD, or invalid entities be hit
	{
		return false;
	}
	
	return true;
}

static AnnounceKarmaCharge(client)
{
	EmitSoundToAll(SOUND_EFFECT, client);
	
	new victim = GetCarryVictim(client);
	if (victim == -1) return;
	
	GetConVarBool(cvarModeSwitch) ? SlowChargeCouple(client) : SlowTime();
	
	if (GetConVarBool(cvarNotify))
	{
		PrintToChatAll("\x03%N\x01 Karma Charge'd %N, for great justice!!", client, victim);
	}
}

static SlowChargeCouple(client)
{
	new target = GetCarryVictim(client);
	if (target == -1) return;
	
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 0.2);
	SetEntPropFloat(target, Prop_Send, "m_flLaggedMovementValue", 0.2);
	
	new Handle:data = CreateDataPack();
	WritePackCell(data, client);
	WritePackCell(data, target);
	
	CreateTimer(GetConVarFloat(karmaTime), _revertCoupleTimeSlow, data);
}

public Action:_revertCoupleTimeSlow(Handle:timer, Handle:data)
{
	ResetPack(data);
	new client = ReadPackCell(data);
	new target = ReadPackCell(data);
	CloseHandle(data);

	if (IsClientInGame(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
	}
	
	if (IsClientInGame(target))
	{
		SetEntPropFloat(target, Prop_Send, "m_flLaggedMovementValue", 1.0);
	}
}

static GetCarryVictim(client)
{
	new victim = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
	if (victim < 1
	|| victim > MaxClients
	|| !IsClientInGame(victim))
	{
		return -1;
	}
	
	return victim;
}

stock SlowTime(const String:desiredTimeScale[] = "0.2", const String:re_Acceleration[] = "2.0", const String:minBlendRate[] = "1.0", const String:blendDeltaMultiplier[] = "2.0")
{
	new ent = CreateEntityByName("func_timescale");
	
	DispatchKeyValue(ent, "desiredTimescale", desiredTimeScale);
	DispatchKeyValue(ent, "acceleration", re_Acceleration);
	DispatchKeyValue(ent, "minBlendRate", minBlendRate);
	DispatchKeyValue(ent, "blendDeltaMultiplier", blendDeltaMultiplier);
	
	DispatchSpawn(ent);
	AcceptEntityInput(ent, "Start");
	
	CreateTimer(GetConVarFloat(karmaTime), _revertTimeSlow, ent);
}

public Action:_revertTimeSlow(Handle:timer, any:ent)
{
	if(IsValidEdict(ent))
	{
		AcceptEntityInput(ent, "Stop");
	}
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	decl String:buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[KARMA] %s", buffer);
	PrintToConsole(0, "[KARMA] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}