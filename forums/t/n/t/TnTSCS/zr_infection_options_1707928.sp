/* Zombie:Reloaded Infect Options
* 
* 	DESCRIPTION
* 		This plugin works with Zombie:Reloaded and will allow admins to set different options
* 		that will be applied to newly infected zombies (and optional mother zombie).
* 
* 	VERSIONS and ChangeLog
* 
* 		0.0.1.0	*	Initial Beta Release
* 
* 		0.0.1.1	*	Added teleport timer so you can define the amount of time to use the teleport feature so you
* 					don't send players to spawn on infection if the map you're on uses spawn killers.  You define the time.
* 
* 		0.0.1.2	*	+ Added ignite and speed options for newly infected zombies.
* 					* Fixed bug with disarm infection option always being true.
* 					+ Added _DEBUG features if they're ever needed.
* 					* Updated myinfo:name to ZR Infection Options
* 
* 	TO DO List
* 		Add more options (suggest some)
* 
* 	KNOWN ISSUES
* 		None that I could find during my testing
* 
* 	REQUESTS
* 		Suggest something
* 
* 	CREDITS
* 		Richard and Greyscale for Zombie:Reloaded stuff
* 		berni for SMLib
* 		SDKHooks developers
*/
#pragma semicolon 1

// ===================================================================================================================================
// Includes
// ===================================================================================================================================
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <smlib\clients>
#include <zombiereloaded>

// ===================================================================================================================================
// Defines
// ===================================================================================================================================
#define 	PLUGIN_VERSION 		"0.0.1.2"

#define		_DEBUG				0	// Set to 1 for debug log spew
#define		_DEBUG_CHAT			0	// Set to 1 for debug chat spew when _DEBUG is 1

// ===================================================================================================================================
// Client Variables
// ===================================================================================================================================
new Handle:FreezeTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:DisarmTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:SpeedTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new Float:g_vecZTeleSpawn[MAXPLAYERS+1][3];

new Float:PlayerOldSpeed[MAXPLAYERS+1];

// ===================================================================================================================================
// CVar Variables
// ===================================================================================================================================
new bool:UseFreeze = false;
new Float:FreezeTime;

new bool:UseDisarm = false;
new Float:DisarmTime;

new bool:UseIgnite = false;
new Float:IgniteTime;

new bool:UseSpeed = false;
new Float:SpeedAmount;
new Float:SpeedTime;

new bool:UseTeleport = false;
new Float:TeleportTime;
new bool:TeleportExpired = false;
new Handle:TeleportTimer = INVALID_HANDLE;

new bool:ApplyToMotherZombie = false;

new zrio_options = 0;

#if _DEBUG
new String:DebugMsg[256];
#endif

public Plugin:myinfo = 
{
	name = "ZR Infection Options",
	author = "TnTSCS aka ClarkKent",
	description = "Add options to newly infected zombies",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	new Handle:hRandom; // KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_zrio_version", PLUGIN_VERSION, 
	"Version of 'Zombie:Reloaded Infection Options'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_zrio_freezetime", "3", 
	"How long you want the newly infected to be frozen for.", _, true, 0.1, true, 25.0)), OnFreezeTimeChanged);
	FreezeTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zrio_disarmtime", "3", 
	"How long you want the newly infected to be without their claws (knives).", _, true, 0.1, true, 25.0)), OnDisarmTimeChanged);
	DisarmTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zrio_teleporttime", "0", 
	"Number of seconds to use the teleport feature.  Helpful so you don't send zombies back to spawn when maps enable spawn killing\n0 = Use all the time\n1+ = Only use teleport feature for this many seconds after round starts", _, true, 0.0)), OnTeleportTimeChanged);
	TeleportTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zrio_ignitetime", "3", 
	"How long you want the newly infected to be ignited for.", _, true, 0.0)), OnIgniteTimeChanged);
	IgniteTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zrio_speedtime", "3", 
	"How long you want the newly infected to have their speed altered.", _, true, 0.0)), OnSpeedTimeChanged);
	IgniteTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zrio_speed", ".50", 
	"Speed to set the newly infected at (.50 is half speed).", _, true, 0.0)), OnSpeedChanged);
	SpeedAmount = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_zrio_options", "0", 
	"Sepcifies the infection options which should be used.  Add up the values below to get the functionality you want.\n1: Teleport all newly infected zombies back to their spawn\n2: Use sm_zrio_teleporttime\n4: Disarm all newly infected zombies (remove their claws)\n8: Only disarm zombies after teleport time expires\n16: Freeze all newly infected zombies\n32: Only freeze zombies after teleport time expires\n64: Apply these infection options to Mother Zombies\n128: Ignite all newly infected zombies\n256: Only ignite zombies after teleport time expires?\n512: Set speed on newly infected zombies\n1024: Only alter speed after teleport time expires?", _, true, 0.0)), OnOptionsChanged);
	zrio_options = GetConVarInt(hRandom);
		/*
		* 1: Teleport all newly infected zombies back to their spawn
		* 2: Use sm_zrio_teleporttime
		* 4: Disarm all newly infected zombies (remove their claws) (set time with sm_zrio_disarmtime)
		* 8: Only disarm zombies after teleport time expires?
		* 16: Freeze all newly infected zombies (set time with sm_zrio_freezetime)
		* 32: Only freeze zombies after teleport time expires?
		* 64: Apply these infection options to Mother Zombies
		* 128: Ignite all newly infected zombies (set time with sm_zrio_ignitetime)
		* 256: Only ignite zombies after teleport time expires?
		* 512: Set speed on newly infected zombies (set speed with sm_zrio_speed and time with sm_zrio_speedtime)
		* 1024: Only alter speed after teleport time expires?
		*/
	
	CloseHandle(hRandom); // KyleS HATES Handles
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	
	AutoExecConfig(true);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	GetClientAbsOrigin(client, g_vecZTeleSpawn[client]);
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "%L spawned at %f %f %f", client, g_vecZTeleSpawn[client][0], g_vecZTeleSpawn[client][1], g_vecZTeleSpawn[client][2]);
	DebugSpew(DebugMsg);
	#endif
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if _DEBUG
	DebugSpew("Event_RoundStart fired...");
	#endif
	
	TeleportExpired = false;
	
	if (UseTeleport && TeleportTime > 0)
	{
		#if _DEBUG
		Format(DebugMsg, sizeof(DebugMsg), "... Setting teleport timer to %f", TeleportTime);
		DebugSpew(DebugMsg);
		#endif
		
		ClearTimer(TeleportTimer);
		
		TeleportTimer = CreateTimer(TeleportTime, Timer_DisallowTeleport);
	}
}

public OnMapEnd()
{
	ClearTimer(TeleportTimer);
}

public Action:Timer_DisallowTeleport(Handle:timer, any:client)
{
	TeleportTimer = INVALID_HANDLE;
	
	TeleportExpired = true;
	
	#if _DEBUG
	DebugSpew("Teleport Timer expired");
	#endif
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	#if _DEBUG
	DebugSpew("Received ZR_OnClientInfected");
	#endif
	
	if (zrio_options == 0 || (motherInfect && !ApplyToMotherZombie) || !IsPlayerAlive(client) || !IsClientInGame(client))
	{
		#if _DEBUG
		Format(DebugMsg, sizeof(DebugMsg), "Not applying infection options because: sm_zrio_options %i, ApplyToMotherZombie?%b, IsPlayerAlive?%b, IsClientInGame?%b", zrio_options, ApplyToMotherZombie, IsPlayerAlive(client), IsClientInGame(client));
		DebugSpew(DebugMsg);
		#endif
		
		return;
	}
	
	if (UseTeleport && !TeleportExpired)
	{
		#if _DEBUG
		Format(DebugMsg, sizeof(DebugMsg), "Teleporting %L back to spawn (%f %f %f)", client, g_vecZTeleSpawn[client][0], g_vecZTeleSpawn[client][1], g_vecZTeleSpawn[client][2]);
		DebugSpew(DebugMsg);
		#endif
		
		TeleportEntity(client, g_vecZTeleSpawn[client], NULL_VECTOR, Float:{0.0, 0.0, 0.0});
	}
	
	if (UseFreeze)
	{
		#if _DEBUG
		DebugSpew("UseFreeze is set to True...");
		#endif
		
		if (zrio_options & 32 && !TeleportExpired)
		{
			#if _DEBUG
			Format(DebugMsg, sizeof(DebugMsg), "...Teleport timer is being enforced but hasn't expired yet, not freezing %L", client);
			DebugSpew(DebugMsg);
			#endif
		}
		else
		{
			#if _DEBUG
			Format(DebugMsg, sizeof(DebugMsg), "... About to freeze %L for %f seconds", client, FreezeTime);
			DebugSpew(DebugMsg);
			#endif
			
			FreezePlayer(client);
			
			ClearTimer(FreezeTimer[client]);
			FreezeTimer[client] = CreateTimer(FreezeTime, Timer_Unfreeze, client);
		}
	}
	
	if (UseDisarm)
	{
		#if _DEBUG
		DebugSpew("UseDisarm is set to True...");
		#endif
		
		if (zrio_options & 8 && !TeleportExpired)
		{
			#if _DEBUG
			Format(DebugMsg, sizeof(DebugMsg), "... Teleport timer is being enforced but hasn't expired yet, not disarming %L", client);
			DebugSpew(DebugMsg);
			#endif
		}
		else
		{
			#if _DEBUG
			Format(DebugMsg, sizeof(DebugMsg), "... Disarming %L for %f seconds", client, DisarmTime);
			DebugSpew(DebugMsg);
			#endif
			
			Client_RemoveAllWeapons(client);
			
			SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_BlockWeapon);
			SDKHook(client, SDKHook_WeaponEquip, Hook_BlockWeapon);
			SDKHook(client, SDKHook_WeaponCanUse, Hook_BlockWeapon);
			
			ClearTimer(DisarmTimer[client]);
			
			DisarmTimer[client] = CreateTimer(DisarmTime, Timer_ReArm, client);
		}
	}
	
	if (UseIgnite)
	{
		#if _DEBUG
		DebugSpew("UseIgnite is set to True...");
		#endif
		
		if (zrio_options & 256 && !TeleportExpired)
		{
			#if _DEBUG
			Format(DebugMsg, sizeof(DebugMsg), "... Teleport timer is being enforced but hasn't expired yet, not igniting %L", client);
			DebugSpew(DebugMsg);
			#endif
		}
		else
		{
			IgniteEntity(client, IgniteTime);
			
			#if _DEBUG
			Format(DebugMsg, sizeof(DebugMsg), "... Ignited %L for %f seconds", client, IgniteTime);
			DebugSpew(DebugMsg);
			#endif
		}
	}
	
	if (UseSpeed)
	{
		#if _DEBUG
		DebugSpew("UseSpeed is set to True...");
		#endif
		
		if (zrio_options & 1024 && !TeleportExpired)
		{
			#if _DEBUG
			Format(DebugMsg, sizeof(DebugMsg), "... Teleport timer is being enforced but hasn't expired yet, not changing speed of %L", client);
			DebugSpew(DebugMsg);
			#endif
		}
		else
		{
			#if _DEBUG
			Format(DebugMsg, sizeof(DebugMsg), "... About to set speed of %L to %f for %f seconds", client, SpeedAmount, SpeedTime);
			DebugSpew(DebugMsg);
			#endif
			
			SetPlayerSpeed(client, SpeedAmount);
			
			ClearTimer(SpeedTimer[client]);
			
			SpeedTimer[client] = CreateTimer(SpeedTime, Timer_ResetSpeed, client);
		}
	}
}

public Action:Hook_BlockWeapon(client, weapon)
{
	return Plugin_Handled;
}

public Action:Timer_Unfreeze(Handle:timer, any:client)
{
	FreezeTimer[client] = INVALID_HANDLE;
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "About to unfreeze %L", client);
	DebugSpew(DebugMsg);
	#endif
	
	UnFreezePlayer(client);
}

public Action:Timer_ReArm(Handle:timer, any:client)
{
	DisarmTimer[client] = INVALID_HANDLE;
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "About to re-arm %L (give knife)", client);
	DebugSpew(DebugMsg);
	#endif
	
	SDKUnhook(client, SDKHook_WeaponCanSwitchTo, Hook_BlockWeapon);
	SDKUnhook(client, SDKHook_WeaponEquip, Hook_BlockWeapon);
	SDKUnhook(client, SDKHook_WeaponCanUse, Hook_BlockWeapon);
	
	Client_GiveWeapon(client, "weapon_knife", true);
}

public Action:Timer_ResetSpeed(Handle:timer, any:client)
{
	SpeedTimer[client] = INVALID_HANDLE;
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "About to set %L speed back to %f", client, PlayerOldSpeed[client]);
	DebugSpew(DebugMsg);
	#endif
	
	SetPlayerSpeed(client, PlayerOldSpeed[client]);
}

public OnClientDisconnect(client)
{
	#if _DEBUG
	DebugSpew("A client disconnected...");
	#endif
	
	if (IsClientInGame(client))
	{
		#if _DEBUG
		Format(DebugMsg, sizeof(DebugMsg), "... it was %L, resetting all variables and timers.", client);
		DebugSpew(DebugMsg);
		#endif
		
		SDKUnhook(client, SDKHook_WeaponCanSwitchTo, Hook_BlockWeapon);
		SDKUnhook(client, SDKHook_WeaponEquip, Hook_BlockWeapon);
		SDKUnhook(client, SDKHook_WeaponCanUse, Hook_BlockWeapon);
		
		PlayerOldSpeed[client] = 0.0;
		
		ClearTimer(FreezeTimer[client]);
		ClearTimer(DisarmTimer[client]);
		ClearTimer(SpeedTimer[client]);
	}
}

FreezePlayer(client)
{
	if (!IsClientInGame(client))
	{
		#if _DEBUG
		DebugSpew("Player left before they could be frozen");
		#endif
		
		return;
	}
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 192);
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "Froze %L", client);
	DebugSpew(DebugMsg);
	#endif
}

UnFreezePlayer(client)
{
	if (!IsClientInGame(client))
	{
		#if _DEBUG
		DebugSpew("Player left before they could be unfrozen");
		#endif
		
		return;
	}
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "Unfroze %L", client);
	DebugSpew(DebugMsg);
	#endif
}

SetPlayerSpeed(client, Float:amount)
{
	PlayerOldSpeed[client] = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "Setting %L PlayerOldSpeed to %f", client, PlayerOldSpeed[client]);
	DebugSpew(DebugMsg);
	#endif
	
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", amount);
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "Set %L speed to %f", client, amount);
	DebugSpew(DebugMsg);
	#endif
}

ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

#if _DEBUG
DebugSpew(const String:msg[])
{
	LogMessage("[ZRIO DEBUG] %s", msg);
	
	#if _DEBUG_CHAT
	PrintToChatAll("[ZRIO DEBUG] %s", msg);
	#endif
}
#endif

// ===================================================================================================================================
// CVar Change Functions
// ===================================================================================================================================
public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	// Make sure the version number is what is set in the compiled plugin, not a config file or changed CVar
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnTeleportTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	TeleportTime = GetConVarFloat(cvar);
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "TeleportTime changed from %s to %s", oldVal, newVal);
	DebugSpew(DebugMsg);
	#endif
}

public OnFreezeTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	FreezeTime = GetConVarFloat(cvar);
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "FreezeTime changed from %s to %s", oldVal, newVal);
	DebugSpew(DebugMsg);
	#endif
}

public OnDisarmTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DisarmTime = GetConVarFloat(cvar);
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "DisarmTime changed from %s to %s", oldVal, newVal);
	DebugSpew(DebugMsg);
	#endif
}

public OnIgniteTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	IgniteTime = GetConVarFloat(cvar);
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "IgniteTime changed from %s to %s", oldVal, newVal);
	DebugSpew(DebugMsg);
	#endif
}

public OnSpeedTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SpeedTime = GetConVarFloat(cvar);
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "SpeedTime changed from %s to %s", oldVal, newVal);
	DebugSpew(DebugMsg);
	#endif
}

public OnSpeedChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SpeedAmount = GetConVarFloat(cvar);
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "SpeedAmount changed from %s to %s", oldVal, newVal);
	DebugSpew(DebugMsg);
	#endif
}

public OnOptionsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	zrio_options = GetConVarInt(cvar);
	
	#if _DEBUG
	Format(DebugMsg, sizeof(DebugMsg), "zrio_options changed from %s to %s", oldVal, newVal);
	DebugSpew(DebugMsg);
	#endif
	
	if (zrio_options & 512)
	{
		UseSpeed = true;
	}
	else
	{
		UseSpeed = false;
	}
	
	if (zrio_options & 128)
	{
		UseIgnite = true;
	}
	else
	{
		UseIgnite = false;
	}
	
	if (zrio_options & 64)
	{
		ApplyToMotherZombie = true;
	}
	else
	{
		ApplyToMotherZombie = false;
	}
	
	if (zrio_options & 16)
	{
		UseFreeze = true;
	}
	else
	{
		UseFreeze = false;
	}
	
	if (zrio_options & 4)
	{
		UseDisarm = true;
	}
	else
	{
		UseDisarm = false;
	}
	
	if (zrio_options & 1)
	{
		UseTeleport = true;
	}
	else
	{
		UseTeleport = false;
	}
}