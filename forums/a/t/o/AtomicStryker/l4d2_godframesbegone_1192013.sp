#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION										"1.0.7"

#define			STRINGLENGTH									32
#define			STRINGLENGTH_DEBUG							   192

static const 		OUT_SERVER								= 	 1;
static const 		OUT_LOG									= 	 2;
static const 		OUT_CHAT								= 	 4;
static const		L4D2_TEAM_INFECTED					    =    3;
static const		TEMP_HEALTH_ERROR_MARGIN				=    1;
static const		ZOMBIECLASS_SPITTER						=	 4;

static const Float:GOD_FRAME_CHECK_DURATION					=  3.0;
static const Float:DAMAGE_CHECK_DELAY						=  0.1;
static const Float:HEAL_CHECKSTOP_RATIO						=  1.2;

static const String:EVENT_STRING_VICTIM[]					= "victim";
static const String:EVENT_STRING_SUBJECT[]					= "subject";
static const String:EVENT_STRING_USER_ID[]					= "userid";
static const String:CVAR_TEMP_HEALTH_DECAY[]				= "pain_pills_decay_rate";
static const String:ENTPROP_HARD_HEALTH[]					= "m_iHealth";
static const String:ENTPROP_TEMP_HEALTH[]					= "m_healthBuffer";
static const String:ENTPROP_TEMP_HEALTH_DECAY[]				= "m_healthBufferTime";
static const String:ENTPROP_ZOMBIECLASS[]					= "m_zombieClass";


static Handle:cvarEnabled									= INVALID_HANDLE;
static Handle:cvarTempHealthDecay							= INVALID_HANDLE;
static Handle:cvarDebugOut									= INVALID_HANDLE;
static Handle:cvarCommonsEnabled							= INVALID_HANDLE;
static Handle:cvarSpitterOverrides							= INVALID_HANDLE;
static Float:lastSavedGodFrameBegin[MAXPLAYERS+1]			=  0.0;
static bool:justHealed[MAXPLAYERS+1]						= false;
static		LEFT4DEAD										= 0;
static		MaxPlayerClients								= 16;


public Plugin:myinfo =
{
	name = "L4D2 God Frames be gone",
	author = "AtomicStryker",
	description = "Remove invincibility time spans for Survivors",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1192013"
};

public OnPluginStart()
{
	decl String:game_name[STRINGLENGTH];
	GetGameFolderName(game_name, sizeof(game_name));
	if (StrEqual(game_name, "left4dead", false))
	{
		LEFT4DEAD = 1;
	}
	else if (StrEqual(game_name, "left4dead2", false))
	{
		LEFT4DEAD = 2;
	}
	else
	{
		SetFailState("Plugin only supports L4D and L4D2");
	}

	CreateConVar("l4d2_god_frames_be_gone_version", 						PLUGIN_VERSION, "L4D2 God Frames be gone Version", 						FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("l4d2_god_frames_be_gone_enabled", 			"1", "Enable or Disable God Frame Damage Override", 					FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvarCommonsEnabled = CreateConVar("l4d2_god_frames_be_gone_commons", 	"0", "Enable or Disable Common Infected attacks to override", 			FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvarDebugOut = CreateConVar("l4d2_god_frames_be_gone_debug", 			"0", "Sum of debug flags for debug outputs (1-console, 2-log, 4-chat)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvarSpitterOverrides = CreateConVar("l4d2_god_frames_be_gone_4spitter", "1", "Is Spitter damage included in Damage Overriding", 				FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	cvarTempHealthDecay =	FindConVar(CVAR_TEMP_HEALTH_DECAY);

	HookEvent("tongue_grab", 			_GF_CheckForGodFrames);
	HookEvent("tongue_release", 		_GF_CheckForGodFrames);
	HookEvent("lunge_pounce", 			_GF_CheckForGodFrames);
	HookEvent("pounce_stopped", 		_GF_CheckForGodFrames);
	HookEventEx("jockey_ride", 			_GF_CheckForGodFrames);
	HookEventEx("jockey_ride_end", 		_GF_CheckForGodFrames);
	HookEventEx("charger_carry_start",	_GF_CheckForGodFrames);
	HookEventEx("charger_carry_end", 	_GF_CheckForGodFrames);
	HookEventEx("charger_pummel_start", _GF_CheckForGodFrames);
	HookEventEx("charger_pummel_end", 	_GF_CheckForGodFrames);
	
	HookEvent("heal_success", 			_GF_HealEvent);
	HookEvent("pills_used", 			_GF_HealEvent);
	HookEventEx("adrenaline_used",		_GF_HealEvent);
	
	HookEvent("player_incapacitated", 	_GF_IncapEvent); // being incapped 'heals' you from 1 to 300 hard health
}

public OnConfigsExecuted()
{
	new Handle:cvar = FindConVar("l4d_maxplayers");

	if (cvar != INVALID_HANDLE)
	{
		MaxPlayerClients = GetConVarInt(cvar);
		return;
	}
	
	cvar = FindConVar("sv_maxplayers");
	
	if (cvar != INVALID_HANDLE)
	{
		MaxPlayerClients = GetConVarInt(cvar);
	}
	
	if (cvar != INVALID_HANDLE)
	{
		CloseHandle(cvar);
	}
}

public _GF_CheckForGodFrames(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, EVENT_STRING_VICTIM));
	if (!victim) return;
	lastSavedGodFrameBegin[victim] = GetEngineTime();
}

public _GF_HealEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new subject = GetClientOfUserId(GetEventInt(event, EVENT_STRING_SUBJECT));
	justHealed[subject] = true;
	CreateTimer(DAMAGE_CHECK_DELAY * HEAL_CHECKSTOP_RATIO, _GF_timer_ResetHealBool, subject);
}

public _GF_IncapEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new subject = GetClientOfUserId(GetEventInt(event, EVENT_STRING_USER_ID));
	justHealed[subject] = true;
	CreateTimer(DAMAGE_CHECK_DELAY * HEAL_CHECKSTOP_RATIO, _GF_timer_ResetHealBool, subject);
}

public Action:_GF_timer_ResetHealBool(Handle:timer, any:subject)
{
	justHealed[subject] = false;
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	DebugPrintToAll("OnTakeDamage: victim %i attacker %i inflictor %i damage %i type %i", victim, attacker, inflictor, RoundToNearest(damage), damagetype);

	switch (LEFT4DEAD)
	{
		case 1:
		{
			if (!GetConVarBool(cvarEnabled)
			|| !IsValidEdict(victim)
			|| !IsValidEdict(attacker)
			|| victim > MaxPlayerClients
			|| !IsClientInGame(victim)
			|| GetClientTeam(victim) == L4D2_TEAM_INFECTED
			|| (attacker < MaxPlayerClients && IsClientInGame(attacker) && GetClientTeam(attacker) != L4D2_TEAM_INFECTED))
			{
				return Plugin_Continue;													// establish the victim is a valid Survivor attacked by Infected
			}
		}
		case 2:
		{
			if (!GetConVarBool(cvarEnabled)
			|| !IsValidEdict(victim)
			|| !IsValidEdict(attacker)
			|| victim > MaxPlayerClients
			|| !IsClientInGame(victim)
			|| GetClientTeam(victim) == L4D2_TEAM_INFECTED)
			{
				return Plugin_Continue;													// establish the victim is a valid Survivor attacked by Infected
			}
		}
	}
	
	new bool:playerattacker = (attacker > 0
							&& attacker < MaxPlayerClients
							&& IsClientInGame(attacker)
							&& GetClientTeam(attacker) == L4D2_TEAM_INFECTED);

	if (!playerattacker && !GetConVarBool(cvarCommonsEnabled)							// case common override disabled and attacker common
	|| lastSavedGodFrameBegin[victim] == 0.0											// case no god frames on record
	|| GetEngineTime() - lastSavedGodFrameBegin[victim] > GOD_FRAME_CHECK_DURATION)		// case attack not within god frame time window
	{
		return Plugin_Continue;
	}
	
	if (playerattacker && GetEntProp(attacker, Prop_Send, ENTPROP_ZOMBIECLASS) == ZOMBIECLASS_SPITTER && !GetConVarBool(cvarSpitterOverrides))
	{
		return Plugin_Continue;
	}
	
	new hardhealth = GetHardHealth(victim);
	new supposeddamage = RoundToNearest(damage);
	
	new resulthardhealth = hardhealth - supposeddamage;			// damage formula: subtract damage from hard health
	new resulttemphealth = GetAccurateTempHealth(victim);
	
	if (resulthardhealth < 1)									// if negative hard health would result
	{
		supposeddamage = resulthardhealth * -1;					// the negative hard health equals whatever should transition to temp health
		resulthardhealth = 1;									// set expected hard health 1 for now
		
		resulttemphealth -= supposeddamage;						// try to pull the damage from temp health
		if (resulttemphealth < 0)								// if that results in negative too
		{
			resulthardhealth = 0;
			resulttemphealth = 0;								// mark the victim as 'to be killed'
		}
	}
	
	new Handle:data = CreateDataPack();
	WritePackCell(data, victim);
	WritePackCell(data, resulthardhealth);
	WritePackCell(data, resulttemphealth);
	WritePackCell(data, attacker);
	
	CreateTimer(DAMAGE_CHECK_DELAY, _GF_timer_CheckForGodMode, data);
	
	return Plugin_Continue;
}

public Action:_GF_timer_CheckForGodMode(Handle:timer, Handle:data)
{
	ResetPack(data);
	new victim = ReadPackCell(data);
	new targethardhealth = ReadPackCell(data);
	new targettemphealth = ReadPackCell(data);
	new attacker = ReadPackCell(data);
	CloseHandle(data);
	
	if (justHealed[victim] || !IsClientInGame(victim)) return;
	
	new hardhealth = GetHardHealth(victim);
	new temphealth = GetAccurateTempHealth(victim);
	
	if (hardhealth > targethardhealth)
	{
		DebugPrintToAll("HAAAX! God Frames detected, hard health of %N is %i, supposed to be %i", victim, hardhealth, targethardhealth);
		applyDamage(targethardhealth - hardhealth, victim, attacker);
	}
	
	if (temphealth > targettemphealth + TEMP_HEALTH_ERROR_MARGIN)
	{
		DebugPrintToAll("HAAAX! God Frames detected, temp health of %N is %i, supposed to be %i", victim, temphealth, targettemphealth);
		applyDamage(targettemphealth - temphealth, victim, attacker);
	}
}

static GetHardHealth(client)
{
	return GetEntProp(client, Prop_Send, ENTPROP_HARD_HEALTH);
}

static GetAccurateTempHealth(client)
{
	new value = RoundToCeil(GetEntPropFloat(client, Prop_Send, ENTPROP_TEMP_HEALTH) - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, ENTPROP_TEMP_HEALTH_DECAY)) * GetConVarFloat(cvarTempHealthDecay))) - 1;
	
	if (value > 0)
	{
		return value;
	}
	else
	{
		return 0;
	}
}

static DebugPrintToAll(const String:format[], any:...)
{
	new outflags = GetConVarInt(cvarDebugOut);
	if (!outflags) return;
	
	decl String:buffer[STRINGLENGTH_DEBUG];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	if(outflags & OUT_SERVER)
	{
		PrintToConsole(0, "[SM] %s", buffer);
	}
	if(outflags & OUT_CHAT)
	{
		PrintToChatAll("[SM] %s", buffer);
	}
	if(outflags & OUT_LOG)
	{
		LogMessage("%s", buffer);
	}
}

// timer idea by dirtyminuth, damage dealing by pimpinjuice http://forums.alliedmods.net/showthread.php?t=111684
// added some L4D2 specific checks
static applyDamage(damage, victim, attacker)
{ 
	new Handle:dataPack = CreateDataPack();
	WritePackCell(dataPack, damage);  
	WritePackCell(dataPack, victim);
	WritePackCell(dataPack, attacker);
	
	CreateTimer(0.10, timer_stock_applyDamage, dataPack);
}

public Action:timer_stock_applyDamage(Handle:timer, Handle:dataPack)
{
	ResetPack(dataPack);
	new damage = ReadPackCell(dataPack);  
	new victim = ReadPackCell(dataPack);
	new attacker = ReadPackCell(dataPack);
	CloseHandle(dataPack);   

	decl Float:victimPos[3], String:strDamage[16], String:strDamageTarget[16];
	
	GetClientEyePosition(victim, victimPos);
	IntToString(damage, strDamage, sizeof(strDamage));
	Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
	
	new entPointHurt = CreateEntityByName("point_hurt");
	if(!entPointHurt) return;

	// Config, create point_hurt
	DispatchKeyValue(victim, "targetname", strDamageTarget);
	DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
	DispatchKeyValue(entPointHurt, "Damage", strDamage);
	DispatchKeyValue(entPointHurt, "DamageType", "0"); // DMG_GENERIC
	DispatchSpawn(entPointHurt);
	
	// Teleport, activate point_hurt
	TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entPointHurt, "Hurt", (attacker && attacker < MaxPlayerClients && IsClientInGame(attacker)) ? attacker : -1);
	
	// Config, delete point_hurt
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	RemoveEdict(entPointHurt);
}