#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2_direct>


#define PLUGIN_VERSION "1.5"
#define PLUGIN_AUTHOR "dcx2"
#define PLUGIN_NAME "L4D2 Jockey Incap Ride"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY

#define ZOMBIECLASS_JOCKEY		(5)

#define DEBUG_JOCKEYRIDE 		(0x01)
#define DEBUG_JOCKEYRIDEEND 	(0x02)
#define DEBUG_ONTAKEDAMAGE 		(0x04)
#define DEBUG_PLAYERHURT 		(0x08)
#define DEBUG_ONTAKEDAMAGEPOST 	(0x10)

#define ENABLE_HUMAN_RIDES		(0x01)
#define ENABLE_AI_RIDES			(0x02)
#define ENABLE_COMPETITIVE_MODE	(0x04)
#define ENABLE_COOPERATIVE_MODE (0x08)
#define ENABLE_ANNOUNCE_RIDE	(0x10)


#define IS_VALID_CLIENT(%1) 	(%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) 		(GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) 		(GetClientTeam(%1) == 3)

#define IS_VALID_INGAME(%1) 	(IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_VALID_SURVIVOR(%1) 	(IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) 	(IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define IS_SURVIVOR_ALIVE(%1) 	(IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) 	(IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))


#define GET_JOCKEY_ATTACKER(%1) GetEntPropEnt(%1, Prop_Send, "m_jockeyAttacker")
#define GET_ZOMBIE_CLASS(%1) 	GetEntProp(%1, Prop_Send, "m_zombieClass")

#define GET_IS_INCAPPED(%1) 	GetEntProp(%1, Prop_Send, "m_isIncapacitated", 1)
#define GET_REVIVE_COUNT(%1) 	GetEntProp(%1, Prop_Send, "m_currentReviveCount")
#define GET_JOCKEY_VICTIM(%1)	GetEntPropEnt(%1, Prop_Send, "m_jockeyVictim")
#define GET_SURVIVOR_CHARACTER(%1)	GetEntProp(survivor, Prop_Send, "m_survivorCharacter")

#define GET_INFECTED_ABILITY(%1)	GetEntPropEnt(%1, Prop_Send, "m_customAbility")

#define IS_MODE_DISABLED		((g_bIsCompetitive && !(g_fEnabled & ENABLE_COMPETITIVE_MODE)) || (!g_bIsCompetitive && !(g_fEnabled & ENABLE_COOPERATIVE_MODE)))
#define IS_JOCKEY_ALLOWED(%1)	(((g_fEnabled & ENABLE_HUMAN_RIDES) && !IsFakeClient(%1)) || ((g_fEnabled & ENABLE_AI_RIDES) && IsFakeClient(%1)))

new 		g_fEnabled									= 0;
new 		g_fDebug									= 0;
new Float:	g_flIncapRideMultiplier						= 3.0;
new 		g_nSurvivorMaxIncapCount 					= 3;
new bool:	g_bIsCompetitive							= false;
new			g_nSurvivorIncapHealth						= 300;
new	Float:	g_flLeapPostIncapInterval					= 30.0;
new	Float:	g_flLeapPostRideInterval					= 6.0;
// TODO: z_attack_incapacitated_damage for common infected attacks?

new 		g_nJockeyIncapRide[MAXPLAYERS+1]			= { 0, ... };
new 		g_nJockeyIncapRideVictimTemp[MAXPLAYERS+1]	= { 0, ... };
new bool:	g_bIncapRideFirstDmg[MAXPLAYERS+1] 			= { false, ... };
new bool:	g_bIncapPending[MAXPLAYERS+1] 				= { false, ... };

// %1 = current, %2 = last, %3 = mask
#define PRESSING(%1,%2,%3) (((%1 & %3) != (%2 & %3)) && ((%1 & %3) == %3))
#define RELEASING(%1,%2,%3) (((%1 & %3) != (%2 & %3)) && ((%2 & %3) == %3))

new g_lastButtons[MAXPLAYERS+1] = { 0, ... };


public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Allows jockeys to continue riding survivors after they would be incapacitated",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=216739"
};

public OnPluginStart()
{
	new Handle:cvarEnable 			= CreateConVar("l4d2_incap_ride_enable", 	"21", 		"Enable bit flag (add together):\n1=humans can ride, 2=AI can ride, 4=Enabled in competitive modes, 8=Enabled in cooperative modes, 16=Announce incap rides\n31=all, 0=off, 5=default (only humans in competitive modes).", CVAR_FLAGS);
	new Handle:cvarDebug 			= CreateConVar("l4d2_incap_ride_debug", 	"0", 		"Print debug output.", CVAR_FLAGS);
	new Handle:cvarMultiplier 		= CreateConVar("l4d2_incap_ride_multiplier","3.0", 		"Damage done by the jockey during an incap ride will be multiplied by this.", CVAR_FLAGS);
	new Handle:cvarMaxIncap			= FindConVar("survivor_max_incapacitated_count");
	new Handle:gamemode 			= FindConVar("mp_gamemode");
	new Handle:cvarIncapHealth		= FindConVar("survivor_incap_health");
	new Handle:cvarLeapPostIncap	= FindConVar("z_leap_interval_post_incap");
	new Handle:cvarLeapPostRide		= FindConVar("z_leap_interval_post_ride");
	CreateConVar("l4d2_incap_ride_ver", 	PLUGIN_VERSION, PLUGIN_NAME, CVAR_FLAGS|FCVAR_DONTRECORD);
	
	HookConVarChange(cvarEnable, 		OnIncapRideEnableChanged);
	HookConVarChange(cvarDebug, 		OnIncapRideDebugChanged);
	HookConVarChange(cvarMultiplier, 	OnIncapRideMultiplierChanged);
	HookConVarChange(cvarMaxIncap, 		OnMaxIncapChanged);
	HookConVarChange(gamemode, 			OnGameModeChanged);
	HookConVarChange(cvarIncapHealth, 	OnIncapHealthChanged);
	HookConVarChange(cvarLeapPostIncap, OnLeapPostIncapChanged);
	HookConVarChange(cvarLeapPostRide, 	OnLeapPostRideChanged);
	
	g_fEnabled 					= GetConVarInt(cvarEnable);
	g_fDebug 					= GetConVarInt(cvarDebug);
	g_flIncapRideMultiplier 	= GetConVarFloat(cvarMultiplier);
	g_nSurvivorMaxIncapCount 	= GetConVarInt(cvarMaxIncap);
	g_nSurvivorIncapHealth 		= GetConVarInt(cvarIncapHealth);
	g_flLeapPostIncapInterval 	= GetConVarFloat(cvarLeapPostIncap);
	g_flLeapPostRideInterval 	= GetConVarFloat(cvarLeapPostRide);

	decl String:gamemodeString[32];
	GetConVarString(gamemode, gamemodeString, sizeof(gamemodeString));
	g_bIsCompetitive = isGameModeCompetitive(gamemodeString);
	
	HookEvent("jockey_ride", 		Event_JockeyRide);
	HookEvent("jockey_ride_end", 	Event_JockeyRideEnd);
	HookEvent("player_hurt", 		Event_PlayerHurt);
}

public OnIncapRideEnableChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_fEnabled = StringToInt(newVal);

public OnIncapRideDebugChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_fDebug = StringToInt(newVal);

public OnIncapRideMultiplierChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_flIncapRideMultiplier = StringToFloat(newVal);

public OnMaxIncapChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_nSurvivorMaxIncapCount = StringToInt(newVal);

public OnIncapHealthChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_nSurvivorIncapHealth = StringToInt(newVal);

public OnLeapPostIncapChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_flLeapPostIncapInterval = StringToFloat(newVal);

public OnLeapPostRideChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_flLeapPostRideInterval = StringToFloat(newVal);

public OnGameModeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	g_bIsCompetitive = isGameModeCompetitive(newValue);

public bool:isGameModeCompetitive(const String:GameMode[])
	return (StrContains(GameMode, "versus", false) >= 0) || (StrContains(GameMode, "scavenge", false) >= 0);

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public OnAllPluginsLoaded()
{	
	// Account for late loading
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}

// Clear the incap ride accumulator when a ride begins
public Action:Event_JockeyRide(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Must be enabled
	if (IS_MODE_DISABLED)		return Plugin_Continue;

	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	g_nJockeyIncapRide[attacker] = 0;

	if (g_fDebug & DEBUG_JOCKEYRIDE) PrintToServer("JIRJR: %N (Jockey) began riding %N", attacker, victim);

	return Plugin_Continue;
}

// Before client takes damage, if they would go down as a result of this damage, and a jockey is riding them,
// give them health to keep them from going down, and then add that damage total to the incap ride accumulator
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	// Victim must be an alive survivor who will take damage
	if (IS_MODE_DISABLED || !IS_SURVIVOR_ALIVE(victim) || damage < 1.0) return Plugin_Continue;
	
	new dmg = RoundToFloor(damage);
	new bool:changed = false;

	new jockeyAttacker = GET_JOCKEY_ATTACKER(victim);

	// Is the jockeyAttacker a valid infected who is allowed to incap ride?
	if (IS_INFECTED_ALIVE(jockeyAttacker) && GET_ZOMBIE_CLASS(jockeyAttacker) == ZOMBIECLASS_JOCKEY && IS_JOCKEY_ALLOWED(jockeyAttacker))
	{
		new victimPerm = GetClientHealth(victim);
		new victimTemp = L4D_GetPlayerTempHealth(victim);
		new victimTotalHealth = victimPerm + victimTemp;
		
		if (g_fDebug & DEBUG_ONTAKEDAMAGE)
		{
			decl String:victimName[MAX_TARGET_LENGTH];
			decl String:attackerName[MAX_TARGET_LENGTH];
			decl String:weaponName[32];
			decl String:inflictorName[32];
			
			GetClientOrEntityName(victim, victimName, sizeof(victimName));
			GetClientOrEntityName(attacker, attackerName, sizeof(attackerName));
			GetSafeEntityName(weapon, weaponName, sizeof(weaponName));
			GetSafeEntityName(inflictor, inflictorName, sizeof(inflictorName));
			
			PrintToServer("JIROTD: %s hit %s (%d, %d, %d) with %s / %s for %f", attackerName, victimName, victimPerm, victimTemp, g_nJockeyIncapRide[jockeyAttacker], weaponName, inflictorName, damage);
		}
		
		// If this damage would incapacitate (but not kill; hence the Revive Count check) the Survivor
		if (dmg >= victimTotalHealth && GET_REVIVE_COUNT(victim) < g_nSurvivorMaxIncapCount)
		{
			// If we haven't dealt any incap ride damage yet, announce that an incap ride has begun
			g_bIncapRideFirstDmg[jockeyAttacker] = g_nJockeyIncapRide[jockeyAttacker] == 0;
			new Float:flIncapDamage = float(dmg + 1 - victimTotalHealth);	// damage transferred to the incap accumulator
			
			// Jockey attacks during an incap ride should do 12 instead of 4, so that incapped survivors do not take forever to die
			// Most SI do more damage to an incapped Survivor that they are pinning
			if (jockeyAttacker == attacker)
			{
				// Example time!
				// We do 4 damage to a survivor with 4 health
				// incapDamage = 4+1-4=1 damage done to Survivor's incap accumulator, 3 to the health
				// Subtract the 1 incap accumulator damage from the damage done,
				// but then add 3*incapDamage so that incap damage accumulates faster for the jockey, like other SI who pin incapped Survivors
				// Total damage in this case is 6, 3 to perm and 3 to incap accumulator
				// Incap damage is multiplied by 3 as well
				damage = (damage - flIncapDamage);
				flIncapDamage *= g_flIncapRideMultiplier;
				damage += flIncapDamage;
				dmg = RoundToFloor(damage);
				changed = true;
			}
			
			// give the survivor enough health that this attack won't kill them
			SetEntityHealth(victim, dmg+1);
			
			// make sure they don't have any temp health left either
			// However, store the temp health in case this damage isn't actually done
			g_nJockeyIncapRideVictimTemp[jockeyAttacker] = victimTemp;
			L4D_SetPlayerTempHealth(victim, 0);
			
			
			// Add the damage to the incap ride accumulator, compensating for any health the victim has
			g_nJockeyIncapRide[jockeyAttacker] += RoundToFloor(flIncapDamage);
		}
	}
	else
	{
		if (IS_VALID_CLIENT(jockeyAttacker))
		{
			if (!g_bIncapPending[victim])	g_nJockeyIncapRide[jockeyAttacker] = 0;
			g_nJockeyIncapRideVictimTemp[jockeyAttacker] = 0;
		}
	}
	
	if (changed) 	return Plugin_Changed;
	else			return Plugin_Continue;
}

// This is only used for debug purposes, so that we can see how much damage PlayerHurt says we did
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IS_MODE_DISABLED || !(g_fDebug & DEBUG_PLAYERHURT)) return Plugin_Continue;
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IS_VALID_SURVIVOR(victim)) return Plugin_Continue;

	new jockeyAttacker = GET_JOCKEY_ATTACKER(victim);
	if (IS_INFECTED_ALIVE(jockeyAttacker) && GET_ZOMBIE_CLASS(jockeyAttacker) == ZOMBIECLASS_JOCKEY && IS_JOCKEY_ALLOWED(jockeyAttacker))
	{		
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new dmg = GetEventInt(event, "dmg_health");
		new currentPerm = GetEventInt(event, "health");
		
		decl String:weaponName[32];
		GetEventString(event, "weapon", weaponName, sizeof(weaponName));
		
		PrintToServer("JIRPH: vic %N, atk %N, atkent %d, hlth %d, wep %s, dmg %d, arm %d, drm %d, hit %d, type %X", victim, attacker, GetEventInt(event, "attackerentid"), currentPerm, weaponName, dmg, GetEventInt(event, "hitgroup"), GetEventInt(event, "armor"), GetEventInt(event, "dmg_armor"), GetEventInt(event, "type"));
	}
	return Plugin_Continue;
}

// OTDP is used to notice when Jockey Incap Ride damage was not actually delivered to the Survivor
public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype, weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (IS_MODE_DISABLED || !IS_VALID_SURVIVOR(victim)) return;
	
	new jockeyAttacker = GET_JOCKEY_ATTACKER(victim);

	if (IS_INFECTED_ALIVE(jockeyAttacker) && GET_ZOMBIE_CLASS(jockeyAttacker) == ZOMBIECLASS_JOCKEY && IS_JOCKEY_ALLOWED(jockeyAttacker))
	{
		new vicPerm = GetClientHealth(victim);
		new vicTemp = L4D_GetPlayerTempHealth(victim);
		
		if (g_fDebug && DEBUG_ONTAKEDAMAGEPOST)
		{
			decl String:victimName[MAX_TARGET_LENGTH];
			decl String:attackerName[MAX_TARGET_LENGTH];
			decl String:weaponName[32];
			decl String:inflictorName[32];
			
			GetClientOrEntityName(victim, victimName, sizeof(victimName));
			GetClientOrEntityName(attacker, attackerName, sizeof(attackerName));
			GetSafeEntityName(weapon, weaponName, sizeof(weaponName));
			GetSafeEntityName(inflictor, inflictorName, sizeof(inflictorName));
			
			PrintToServer("JIROTDP: %s hit %s (%d, %d, %d) with %s / %s for %f", attackerName, victimName, vicPerm, vicTemp, g_nJockeyIncapRide[jockeyAttacker], weaponName, inflictorName, damage);
		}

		if (g_nJockeyIncapRide[jockeyAttacker] > 0 && vicPerm > 1)
		{
			// OTDP runs *after* the player's health has been reduced
			// So if we're incap riding and the client has >1 health, we must have
			// given them health that was not done in damage
			// The typical example is that you're surrounded by a horde
			// A lot of the common infected attacks are god frame'd
			// So OTD will give them health that isn't removed
			// Particularly tricky is if a god frame was going to make the incap ride begin!
			// So we shall undo that here
			
			new dmg = RoundToFloor(damage);
			if ((dmg+1) > vicPerm)
			{
				// Only some of the damage was blocked?  Weird.  Figure out how much damage was actually done
				// Example: OTD was supposed to do 12.  So we give Survivor 13 health.  In OTDP, they have 10 health.
				// They actually took (12+1)-10 = 3 damage.
				dmg = (dmg+1) - vicPerm;
			}
			
			// Remove damage that was not done from the incap ride accumulator
			g_nJockeyIncapRide[jockeyAttacker] -= dmg;
			
			if (g_nJockeyIncapRide[jockeyAttacker] <= 0)
			{
				// If removing this damage means we are no longer incap riding...
				// Give the survivor their perm/temp health back
				// For example, the incap ride did 12 damage.  The survivor had 3 perm and 3 temp health
				// OTD would give Survivor 13 health and 0 temp, and set ride accumulator to 7
				// All 12 damage is god frame'd, so 12 is removed from the ride accumulator, making it -5
				// This will restore the Survivor's 3 temp health first,
				// and then restore the perm health, 1 - (-5) - 3 = 3 perm
				L4D_SetPlayerTempHealth(victim, g_nJockeyIncapRideVictimTemp[jockeyAttacker]);
				new newhealth = 1-g_nJockeyIncapRide[jockeyAttacker]-g_nJockeyIncapRideVictimTemp[jockeyAttacker];
				
				// In the event that something catastrophic happens, prevent the Survivor from having zero or negative health
				if (newhealth < 1) newhealth = 1;
				SetEntityHealth(victim, newhealth);
				
				if (g_fDebug && DEBUG_ONTAKEDAMAGEPOST) PrintToServer("JIROTDP: Removed %d extra health that was not damaged for %N", g_nJockeyIncapRide[jockeyAttacker], victim);
				
				g_nJockeyIncapRide[jockeyAttacker] = 0;
				g_nJockeyIncapRideVictimTemp[jockeyAttacker] = 0;
			}
			else
			{
				// Removing this damage would not prevent the incap ride from happening
				// So we'll just get rid of whatever unnecessary health we gave the Survivor
				if (g_fDebug && DEBUG_ONTAKEDAMAGEPOST) PrintToServer("JIROTDP: resetting %N health to 1", victim);
				SetEntityHealth(victim, 1);
			}
		}
		
		// print a hint to the jockey so they know how much damage they've done (otherwise they have no idea)
		if (g_nJockeyIncapRide[jockeyAttacker] > 0)
		{
			PrintHintText(jockeyAttacker, "Incap damage %d", g_nJockeyIncapRide[jockeyAttacker]);
		}
		
		// If the jockey deals 300 damage
		if (g_nJockeyIncapRide[jockeyAttacker] >= g_nSurvivorIncapHealth)
		{
			CreateTimer(0.1, KillDelay, victim);	// Delay kill so it doesn't happen in an SDKHook
		}
		
		// An incap ride is always announced (TODO: cvar to disable this announcement?)
		if ((g_fEnabled & ENABLE_ANNOUNCE_RIDE) && g_bIncapRideFirstDmg[jockeyAttacker] && g_nJockeyIncapRide[jockeyAttacker] > 0)
		{
			PrintToChatAll("\x04%N\x01 (\x04Jockey\x01) incap ride", jockeyAttacker);
		}
	}
	else
	{
		if (!g_bIncapPending[victim] && IS_VALID_CLIENT(jockeyAttacker))	g_nJockeyIncapRide[jockeyAttacker] = 0;
	}
}

public Action:KillDelay(Handle:timer, any:victim)
{
	if (IS_SURVIVOR_ALIVE(victim))
	{
		ForcePlayerSuicide(victim);
	}
}

// Catches the end of a jockey ride and ensures that any accumulated incap ride damage is dealt to the incapped Survivor
public Action:Event_JockeyRideEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IS_MODE_DISABLED) 				return Plugin_Continue;

	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!IS_VALID_SURVIVOR(victim))		return Plugin_Continue;	// Survivor may be dead
	
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IS_VALID_INFECTED(attacker) || !IS_JOCKEY_ALLOWED(attacker) || !g_nJockeyIncapRide[attacker]) 	return Plugin_Continue;
	
	if (IsPlayerAlive(victim))
	{
		// player is alive, but they should be incapped (g_nJockeyIncapRide > 0)
		// so set incap state and then set health accordingly
//		SetPlayerIncapState(victim, true);
//		SetEntityHealth(victim, g_nSurvivorIncapHealth - g_nJockeyIncapRide[attacker]);

		// Must do damage instead of setting incap state
		// Otherwise things like getting pistols when you have a melee won't work
//		SDKHooks_TakeDamage(victim, 0, 0, float(GetClientHealth(victim)));
//		DealDamage(victim, GetClientHealth(victim));
//		IncapVictim(victim);

		// Need to transfer damage to the victim first
		// Since we can only pass victim to the IncapDelay
		g_nJockeyIncapRide[victim] = g_nJockeyIncapRide[attacker];
		g_nJockeyIncapRide[attacker] = 0;
		// Can't call TakeDamage from inside JockeyRideEnd?  For some reason, it crashes
		// So call it from a short timer
		CreateTimer(0.1, IncapDelay, victim);
		
		// There's a small chance that the client could take damage before the timer fires
		// So we use IncapPending during this time to prevent losing the IncapRide damage
		g_bIncapPending[victim] = true;
		
		// Announce how much damage was done to everyone? (TODO: cvar to enable announcement?)
//		PrintToChatAll("Jockey incap ride subtracting %d", g_nJockeyIncapRide[attacker]);
	}
	else
	{
		g_nJockeyIncapRide[attacker] = 0;
	}
	
	new Float:flCooldown = 0.0;
	if (g_nJockeyIncapRide[attacker] < g_nSurvivorIncapHealth)
	{
		// victim is incapped, so jockey gets an incap's worth of cool down
		flCooldown = g_flLeapPostIncapInterval;
	}
	else
	{
		// victim has straight up died, much like a black-and-white Survivor, so cool down is reduced
		flCooldown = g_flLeapPostRideInterval;
	}
	
	// CallResetAbility automatically ensures attacker is infected and alive
	CallResetAbility(attacker, flCooldown);

	if (g_fDebug & DEBUG_JOCKEYRIDEEND)	PrintToServer("%N (Jockey) ended riding %N, damage %d, cooldown %f", attacker, victim, g_nJockeyIncapRide[attacker], flCooldown);

	g_nJockeyIncapRide[attacker] = 0;

	return Plugin_Continue;
}

public DealDamage(victim, damage)
{    
	if((damage > 0) && IS_VALID_INGAME(victim) && IsPlayerAlive(victim))
	{
		decl String:strDamage[16];
		decl String:strDamageTarget[16];
		
		IntToString(damage, strDamage, sizeof(strDamage));
		Format(strDamageTarget, sizeof(strDamage), "hurtme%d", victim);  
		
		new entPointHurt = CreateEntityByName("point_hurt");
		if(entPointHurt)
		{
			// Config, create point_hurt
			DispatchKeyValue(victim, "targetname", strDamageTarget);
			DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
			DispatchKeyValue(entPointHurt, "Damage", strDamage);
			DispatchKeyValue(entPointHurt, "DamageType", "0"); // DMG_GENERIC
			DispatchSpawn(entPointHurt);
			
			// activate point_hurt
			AcceptEntityInput(entPointHurt, "Hurt", -1);
			
			// Config, delete point_hurt
			DispatchKeyValue(entPointHurt, "classname", "point_hurt");
			DispatchKeyValue(victim, "targetname", "null");
			RemoveEdict(entPointHurt);
		}
	}
}

public Action:IncapDelay(Handle:timer, any:victim)
{
	IncapVictim(victim);
}

public IncapVictim(any:victim)
{
	if (IS_SURVIVOR_ALIVE(victim))
	{
		if (!L4D_IsPlayerIncapacitated(victim))
		{
			// Immediately after the jockey releases a Survivor, they are temporarily invulnerable
			// We will temporarily disable the invulnerability timer in order to incapacitate them
			new CountdownTimer:InvulnTimer = L4D2Direct_GetInvulnerabilityTimer(victim);
			new Float:InvulnTimerRemaining = CTimer_GetRemainingTime(InvulnTimer);
			if (InvulnTimerRemaining > 0.0)
			{
				CTimer_Invalidate(InvulnTimer);
			}
//			SDKHooks_TakeDamage(victim, 0, 0, float(GetClientHealth(victim)), DMG_DIRECT);
			DealDamage(victim, GetClientHealth(victim));
			if (InvulnTimerRemaining > 0.0)
			{
				CTimer_Start(InvulnTimer, InvulnTimerRemaining);
			}
		}
		if (L4D_IsPlayerIncapacitated(victim))
		{
			SetEntityHealth(victim, g_nSurvivorIncapHealth - g_nJockeyIncapRide[victim]);
		}
	}
	g_nJockeyIncapRide[victim] = 0;
	g_bIncapPending[victim] = false;
}

stock bool:L4D_IsPlayerIncapacitated(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
}

CallResetAbility(client,Float:time)
{
	static Handle:hStartActivationTimer=INVALID_HANDLE;
	if (hStartActivationTimer==INVALID_HANDLE)
	{
		new Handle:hConf = INVALID_HANDLE;
		hConf = LoadGameConfigFile("l4d2_infected_release");

		StartPrepSDKCall(SDKCall_Entity);

		PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CBaseAbility::StartActivationTimer");
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);

		hStartActivationTimer = EndPrepSDKCall();
		CloseHandle(hConf);
		
		if (hStartActivationTimer == INVALID_HANDLE)
		{
			SetFailState("Can't get CBaseAbility::StartActivationTimer SDKCall!");
			return;
		}            
	}
	if (IS_INFECTED_ALIVE(client))
	{
		new AbilityEnt=GET_INFECTED_ABILITY(client);
		if (IsValidEntity(AbilityEnt))
		{
			SDKCall(hStartActivationTimer, AbilityEnt, time, 0.0);
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons)
{
	if (IS_VALID_SURVIVOR(client) && PRESSING(buttons, g_lastButtons[client], IN_SCORE))
	{
		CreateTimer(0.5, IncapRideHint, client, TIMER_REPEAT);
	}
	g_lastButtons[client] = buttons;
}

public Action:IncapRideHint(Handle:timer, any:client)
{
	if (!IS_VALID_SURVIVOR(client))
	{
		return Plugin_Stop;
	}
	if (!(g_lastButtons[client] & IN_SCORE))
	{
		// They let go so clear hint text
		return Plugin_Stop;
	}
	new bool:first = true;
	decl String:TempString[256];
	TempString = "";
	decl String:TempStringCat[128];
	for (new i=1; i<=MaxClients; i++)
	{
		if (IS_INFECTED_ALIVE(i) && g_nJockeyIncapRide[i])
		{
			new survivor = GET_JOCKEY_VICTIM(i);
			if (!IS_SURVIVOR_ALIVE(survivor)) continue;
			if (IsFakeClient(i))
			{
				Format(TempStringCat, sizeof(TempStringCat), "%s%N riding ", first ? "" : "", i);
			}
			else
			{
				Format(TempStringCat, sizeof(TempStringCat), "%s%N (Jockey) riding ", first ? "" : "", i);
			}
			StrCat(TempString, sizeof(TempString), TempStringCat);
			GetSurvivorName(survivor, TempStringCat, sizeof(TempStringCat));
			StrCat(TempString, sizeof(TempString), TempStringCat);
			Format(TempStringCat, sizeof(TempStringCat), "for %d", g_nJockeyIncapRide[i]);
			StrCat(TempString, sizeof(TempString), TempStringCat);
			first = false;
		}
	}
	if (!first)
	{
		// Only print hint text if someone has an incap ride
		PrintHintText(client, TempString);
	}
	return Plugin_Continue;
}

public GetSurvivorName(survivor, String:SurvivorName[], NameSize)
{

	decl String:targetModel[128]; 
	decl String:charName[32];
	
	GetClientModel(survivor, targetModel, sizeof(targetModel));
	
	if (IsFakeClient(survivor))
	{
		strcopy(charName, sizeof(charName), "");
	}
	else if(StrContains(targetModel, "teenangst", false) > 0) 
	{
		strcopy(charName, sizeof(charName), " (Zoey)");
	}
	else if(StrContains(targetModel, "biker", false) > 0)
	{
		strcopy(charName, sizeof(charName), " (Francis)");
	}
	else if(StrContains(targetModel, "manager", false) > 0)
	{
		strcopy(charName, sizeof(charName), " (Louis)");
	}
	else if(StrContains(targetModel, "namvet", false) > 0)
	{
		strcopy(charName, sizeof(charName), " (Bill)");
	}
	else if(StrContains(targetModel, "producer", false) > 0)
	{
		strcopy(charName, sizeof(charName), " (Rochelle)");
	}
	else if(StrContains(targetModel, "mechanic", false) > 0)
	{
		strcopy(charName, sizeof(charName), " (Ellis)");
	}
	else if(StrContains(targetModel, "coach", false) > 0)
	{
		strcopy(charName, sizeof(charName), " (Coach)");
	}
	else if(StrContains(targetModel, "gambler", false) > 0)
	{
		strcopy(charName, sizeof(charName), " (Nick)");
	}
	else
	{
		strcopy(charName, sizeof(charName), " (Unknown)");
	}
	
	Format(SurvivorName, NameSize, "%N%s ", survivor, charName);

}

// ======================= STOCKS =======================

// Gets entity classname, or "Invalid"
stock GetSafeEntityName(entity, String:TheName[], TheNameSize)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		GetEntityClassname(entity, TheName, TheNameSize);
	}
	else
	{
		strcopy(TheName, TheNameSize, "Invalid");
	}
}

// If an entity is a valid client, gets the client name (or "Disconnected"), otherwise gets the entity classname
stock GetClientOrEntityName(entity, String:TheName[], TheNameSize)
{
	if (IS_VALID_CLIENT(entity))
	{
		if (IsClientConnected(entity))
		{
			GetClientName(entity, TheName, TheNameSize);
		}
		else
		{
			strcopy(TheName, TheNameSize, "Disconnected");
		}
	}
	else
	{
		GetSafeEntityName(entity, TheName, TheNameSize);
	}
}

// Most of this stuff below originally came from, uh, I think Mr. Zero, and I've modified it a bit
static Float:flPainPillsDecay = 0.27;
static Handle:cvarPainPillsDecay = INVALID_HANDLE;
public OnPainPillsDecayChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	flPainPillsDecay = StringToFloat(newValue);
#define GET_HEALTH_BUFFER(%1) GetEntPropFloat(client, Prop_Send, "m_healthBuffer")
#define GET_HEALTH_BUFFER_TIME(%1) GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")
stock L4D_GetPlayerTempHealth(client)
{
	if (!IS_VALID_SURVIVOR(client)) return 0;
	
	if (cvarPainPillsDecay == INVALID_HANDLE)
	{
		cvarPainPillsDecay = FindConVar("pain_pills_decay_rate");
		if (cvarPainPillsDecay == INVALID_HANDLE)
		{
			return -1;
		}
		HookConVarChange(cvarPainPillsDecay, OnPainPillsDecayChanged);
		flPainPillsDecay = GetConVarFloat(cvarPainPillsDecay);
	}

	new tempHealth = RoundToCeil(GET_HEALTH_BUFFER(client) - ((GetGameTime() - GET_HEALTH_BUFFER_TIME(client)) * flPainPillsDecay)) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}

stock L4D_SetPlayerTempHealth(client, tempHealth)
{
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(tempHealth));
    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

stock L4D_SetPlayerReviveCount(client, any:count)
{
	SetEntProp(client, Prop_Send, "m_currentReviveCount", count);
}

stock SetPlayerIncapState(client, any:incap)
{
	SetEntProp(client, Prop_Send, "m_isIncapacitated", incap);
}

stock CheatCommand(client, const String:command[], const String:arguments[])
{
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
}
