#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

/*
	Version 1.2:
		Created globals for all the ConVars so calculations/lookups only have to be made once.
		Added hooks to all the convar changes (another reason why they are global).
		Changed the DoT from int time/damage to floats. This allows for more options.
		Added a rate ConVar so you can do damage at 0.1 second intervals or 10 (or more) second intervals.. not just 1 second.
		Created handles to the timers so they can be properly closed as needed.
		Made the plugin cvar not record in the config file.
		Added some color to the messages.
	To Do:
		Make sure the damage is done correctly as it should be.. Currently in testing, I suffer +1 damage from some multi-swipe attacks.
		Not sure if this is because of a float math error or if because of the point_hurt seemingly doing more damage then I tell it to do.
*/

#define	DMG_SIZE	10

new	Handle:	g_hSwipeDuration			=	INVALID_HANDLE;
new	Float:	g_fSwipeDuration;
new	Handle:	g_hSwipeRate				=	INVALID_HANDLE;
new	Float:	g_fSwipeRate;
new	Handle:	g_hSwipeDamage				=	INVALID_HANDLE;
new	Float:	g_fSwipeDamage;
new	Handle:	g_hSwipeStack				=	INVALID_HANDLE;
new	Float:	g_fSwipeStack;

new	Handle:	g_hTimerDoT[MAXPLAYERS+1]			=	{ INVALID_HANDLE, ... };	// This is the timer for doing damage
new	Float:	g_fClientLastDamage[MAXPLAYERS+1]	=	{ 0.0, ... };				// This is the amount of damage the client took on the last timer (rate tick)
new	Float:	g_fClientDoTRemaining[MAXPLAYERS+1]	=	{ 0.0, ... };				// This is how many more times to deal damage to the client (duration/rate)
new			g_iClientAttacker[MAXPLAYERS+1]		=	{ 0, ... };					// This is the spitter who clawed the client (to give credit for the damage).
new			g_iClientDamageCount[MAXPLAYERS+1]	=	{ 0, ... };					// This is to keep track of how many times a client has been told they are in pain (before taking damage)

public Plugin:myinfo = {
	name = "Acid Swipe",
	author = "Oshroth & Dirka_Dirka",
	description = "Spitter claws cause additional acid D.o.T. much like a spit puddle.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=121396"
}

public OnPluginStart() {
	decl String:game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1)
		SetFailState("Acid Swipe will only work with Left 4 Dead 2!");
	
	CreateConVar(
		"sm_acidswipe_version",
		PLUGIN_VERSION,
		"Acid Swipe plugin version.",
		FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD
	);
	
	g_hSwipeDuration = CreateConVar(
		"sm_acidswipe_duration",
		"2.0",
		"Acid damage duration in seconds. Damage will be applied every sm_acidswipe_rate until this time is reached. Use intervals of 0.1 only. eg: 5.6 is good, 5.69 is not (it will be read as 5.6).",
		FCVAR_PLUGIN|FCVAR_NOTIFY,
		true, 0.0
	);
	HookConVarChange(g_hSwipeDuration, ConVarChange_SwipeDuration);
	g_fSwipeDuration = GetConVarFloat(g_hSwipeDuration);
	new temp = RoundToZero(FloatMul(g_fSwipeDuration, 10.0));
	g_fSwipeDuration = FloatDiv(float(temp), 10.0);
	
	g_hSwipeRate = CreateConVar(
		"sm_acidswipe_rate",
		"0.25",
		"Acide damage rate in seconds. Intervals of 0.1 only (eg: 0.99 = 0.91 = 0.9).",
		FCVAR_PLUGIN|FCVAR_NOTIFY,
		true, 0.0
	);
	HookConVarChange(g_hSwipeRate, ConVarChange_SwipeRate);
	g_fSwipeRate = GetConVarFloat(g_hSwipeRate);
	temp = RoundToZero(FloatMul(g_fSwipeRate, 10.0));
	g_fSwipeRate = FloatDiv(float(temp), 10.0);
	
	g_hSwipeDamage = CreateConVar(
		"sm_acidswipe_damage",
		"0.125",
		"Acid damage applied per sm_acidswipe_rate. This damage is multiplied per rate tick (first tick its sm_acidswipe_damage, second tick its sm_acidswipe_damage *2, etc..). **WARNING** using a small rate with a large duration and/or damage value will kill a player quickly.",
		FCVAR_PLUGIN|FCVAR_NOTIFY,
		true, 0.0
	);
	HookConVarChange(g_hSwipeDamage, ConVarChange_SwipeDamage);
	g_fSwipeDamage = GetConVarFloat(g_hSwipeDamage);
	
	g_hSwipeStack = CreateConVar(
		"sm_acidswipe_stack",
		"1.0",
		"Amount of time to add to the duration for each additional swipe. -1 and each swipe resets the duration to sm_acidswipe_duration (and the damage multiplier to 1.0). 0 means multiple swipes are ignored (only count the first one). Anything greater (in intervals of 0.1) gets added to the duration and continues to increase the damage accordingly.",
		FCVAR_PLUGIN|FCVAR_NOTIFY,
		true, -1.0
	);
	HookConVarChange(g_hSwipeStack, ConVarChange_SwipeStack);
	g_fSwipeStack = GetConVarFloat(g_hSwipeStack);
	if (g_fSwipeStack < -0.0) {
		SetConVarFloat(g_hSwipeStack, -1.0);
	} else {
		temp = RoundToZero(FloatMul(g_fSwipeStack, 10.0));
		g_fSwipeStack = FloatDiv(float(temp), 10.0);
	}
		
	AutoExecConfig(true, "plugin.l4d2.acidswipe");
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerStateChange);
	HookEvent("player_team", Event_PlayerStateChange);
}

public ConVarChange_SwipeDuration(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fSwipeDuration = GetConVarFloat(g_hSwipeDuration);
	/*
		This makes sure the timer only runs on 0.1 increments.
		eg: set to 10.975..
		temp = RoundToZero of 109.75 = 109
		result = 10.9
	*/
	new temp = RoundToZero(FloatMul(g_fSwipeDuration, 10.0));
	g_fSwipeDuration = FloatDiv(float(temp), 10.0);
}

public ConVarChange_SwipeRate(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fSwipeRate = GetConVarFloat(g_hSwipeRate);
	new temp = RoundToZero(FloatMul(g_fSwipeRate, 10.0));
	g_fSwipeRate = FloatDiv(float(temp), 10.0);
}

public ConVarChange_SwipeDamage(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fSwipeDamage = GetConVarFloat(g_hSwipeDamage);
}

public ConVarChange_SwipeStack(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fSwipeStack = GetConVarFloat(g_hSwipeStack);
	if (g_fSwipeStack < -1.0) {		// this shouldn't be needed, but anyway..
		g_fSwipeStack = -1.0;
	} else if (g_fSwipeStack > -1.0) {
		if (g_fSwipeStack < 0.0) {	// this fixes values between -1.0 and 0.0 (they can be entered, but shouldn't)
			g_fSwipeStack = 0.0;
		} else {					// this makes sure it is of the format %0.1f
			new temp = RoundToZero(FloatMul(g_fSwipeStack, 10.0));
			g_fSwipeStack = FloatDiv(float(temp), 10.0);
		}
	}
}

public OnClientDisconnect(client) {
	g_iClientAttacker[client] = 0;
	g_fClientDoTRemaining[client] = 0.0;
	g_fClientLastDamage[client] = 0.0;
	g_iClientDamageCount[client] = 0;
	if (g_hTimerDoT[client] != INVALID_HANDLE) {
		KillTimer(g_hTimerDoT[client]);
		g_hTimerDoT[client] = INVALID_HANDLE;
	}
}

public Action:Event_PlayerStateChange(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!(client) || (client > MaxClients)) return;
	
	g_iClientAttacker[client] = 0;
	g_fClientDoTRemaining[client] = 0.0;
	g_fClientLastDamage[client] = 0.0;
	g_iClientDamageCount[client] = 0;
	if (g_hTimerDoT[client] != INVALID_HANDLE) {
		KillTimer(g_hTimerDoT[client]);
		g_hTimerDoT[client] = INVALID_HANDLE;
	}
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	// Ignore any user that isn't a player client
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim || (victim > MaxClients))
		return;
	// Also, if the victim isn't a survivor - don't bother continuing
	if ((GetClientTeam(victim) != 2))
		return;
	
	// Ignore any attacker that isn't a player client
	new spitter = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!spitter || (spitter > MaxClients))
		return;
	
	// Ignore any attack that isn't caused by the spitters claw
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if (!(StrEqual(weapon, "spitter_claw")))
		return;
	
	// Now get down to business..
	if (g_hTimerDoT[victim] == INVALID_HANDLE) {
		g_iClientAttacker[victim] = spitter;
		// Only display this message the first time a spitter claws someone..
		PrintToChatAll("\x03[Acid]\x01 \x04%N\x01 swiped acid all over \x04%N\x01.", spitter, victim);
		g_fClientLastDamage[victim] = g_fSwipeDamage;
		g_fClientDoTRemaining[victim] = g_fSwipeDuration;
		// Damage the client, and start the DoT
		DamageEffect(victim);
		g_hTimerDoT[victim] = CreateTimer(g_fSwipeRate, Acid_Damage, victim, TIMER_FLAG_NO_MAPCHANGE);
	} else {
		KillTimer(g_hTimerDoT[victim]);
		if (g_fSwipeStack == -1.0) {
			g_fClientDoTRemaining[victim] = g_fSwipeDuration;
			g_fClientLastDamage[victim] = g_fSwipeDamage;
		} else {
			if (g_fSwipeStack > 0.0) {			// Only display this message if damage is stacked..
				if (g_iClientAttacker[victim] == spitter) {	// Spitter has added to his damage..
					PrintToChatAll("\x03[Acid]\x01 \x04%N\x01 added acid to the layer already covering \x04%N\x01.", spitter, victim);
				} else {										// A new spitter has taken over..
					PrintToChatAll("\x03[Acid]\x01 \x04%N\x01 added acid to the layer applied by \x05%N\x01, covering \x04%N\x01 even more.", spitter, g_iClientAttacker[victim], victim);
					g_iClientAttacker[victim] = spitter;
				}
			} else {
				if (g_iClientAttacker[victim] != spitter)
					g_iClientAttacker[victim] = spitter;
			}
			g_fClientDoTRemaining[victim] += FloatSub(g_fSwipeStack, g_fSwipeRate);
		}
		DamageEffect(victim);
		g_hTimerDoT[victim] = CreateTimer(g_fSwipeRate, Acid_Damage, victim, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Acid_Damage(Handle:timer, any:client) {
	g_hTimerDoT[client] = INVALID_HANDLE;
	
	g_fClientDoTRemaining[client] -= g_fSwipeRate;
	if (g_fClientDoTRemaining[client] <= 0.0) {
		g_iClientAttacker[client] = 0;
		g_fClientDoTRemaining[client] = 0.0;
		g_fClientLastDamage[client] = 0.0;
		g_iClientDamageCount[client] = 0;
		return;
	}
	
	#if defined DEBUG
	PrintToChatAll("%N is taking acid damage for %0.1f more seconds.", client, g_fClientDoTRemaining[client]);
	#endif
	
	DamageEffect(client);
	g_hTimerDoT[client] = CreateTimer(g_fSwipeRate, Acid_Damage, client, TIMER_FLAG_NO_MAPCHANGE);
	g_fClientLastDamage[client] += g_fSwipeDamage;
}

public Action:DamageEffect(target) {
	g_iClientDamageCount[target]++;
	if (g_fClientLastDamage[target] == 0.0)		// shouldn't ever happen, but just in case, skip it.
		return;
/*
	Damage types:
	Int Val		Bit Val		Damage Type
	0						GENERIC
	1			(1 << 0)	CRUSH
	2			(1 << 1)	BULLET
	4			(1 << 2)	SLASH
	8			(1 << 3)	BURN
	16			(1 << 4)	FREEZE, VEHICLE (?)
	32			(1 << 5)	FALL
	64			(1 << 6)	BLAST
	128			(1 << 7)	CLUB
	256			(1 << 8)	SHOCK
	512			(1 << 9)	SONIC
	1024		(1 << 10)	ENERGYBEAM
	2048		(1 << 11)	PREVENT_PHYSICS_FORCE
	4096		(1 << 12)	NEVERGIB
	8192		(1 << 13)	ALWAYSGIB
	16384		(1 << 14)	DROWN
	32768		(1 << 15)	PARALYSE	// Instant INCAP
	65536		(1 << 16)	NERVEGAS	// Prevents revive??
	131072		(1 << 17)	POISON
	262144		(1 << 18)	RADIATION
	524288		(1 << 19)	DROWNRECOVER
	1048576		(1 << 20)	CHEMICAL, ACID
	2097152		(1 << 21)	SLOWBURN
	4194304		(1 << 22)	SLOWFREEZE, REMOVENORAGDOLL
	
	268435456	(1 << 28)	DIRECT
	536870912	(1 << 29)	BUCKSHOT
*/
	decl String:type[DMG_SIZE], String:SwipeDamage[DMG_SIZE], String:DamageTarget[DMG_SIZE];
	
	new damage = RoundToZero(g_fClientLastDamage[target]);
	if (damage < 1) {		// it seems that point_hurt always does a min of 1 damage
		if (g_iClientDamageCount[target] == 1) {
			PrintToChat(target, "\x03[Acid]\x01 The acid has begun to burn your flesh.");
		}
		new health = GetEntProp(target, Prop_Data, "m_iHealth");
		// for some reason + 1 doesn't cancel out the 1 damage of point_hurt..
		SetEntProp(target, Prop_Data, "m_iHealth", (health + 2));
		
		IntToString((1 << 20), type, DMG_SIZE);
	} else {
		IntToString((1 << 16) | (1 << 20), type, DMG_SIZE);
	}
	IntToString(damage, SwipeDamage, DMG_SIZE);
	Format(DamageTarget, DMG_SIZE, "hurtme%d", target);
	
	new pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt) {
		DispatchKeyValue(target, "targetname", DamageTarget);
		DispatchKeyValue(pointHurt, "Damage", SwipeDamage);
		DispatchKeyValue(pointHurt, "DamageTarget", DamageTarget);
		DispatchKeyValue(pointHurt, "DamageType", type);
		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", (g_iClientAttacker[target] > 0) ? g_iClientAttacker[target] : -1);
		DispatchKeyValue(target, "targetname", "null");
		RemoveEdict(pointHurt);
	}
}