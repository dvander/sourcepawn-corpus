#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define L4D2 Unstoppable Charger
#define PLUGIN_VERSION "1.2"

#define STRING_LENGHT								56
#define ZOMBIECLASS_CHARGER 						6

static const String:GAMEDATA_FILENAME[] 			= "l4d2_viciousplugins";
static const String:VELOCITY_ENTPROP[]				= "m_vecVelocity";
static const String:CHARGER_WEAPON[]				= "weapon_charger_claw";
static const Float:SLAP_VERTICAL_MULTIPLIER			= 1.5;
static laggedMovementOffset = 0;

// ===========================================
// Charger Setup
// ===========================================

// =================================
// Broken Ribs
// =================================

//Bools
new bool:isBrokenRibs = false;

//Handles
new Handle:cvarBrokenRibs;
new Handle:cvarBrokenRibsChance;
new Handle:cvarBrokenRibsDamage;
new Handle:cvarBrokenRibsDuration;
new Handle:cvarBrokenRibsTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

// =================================
// Extinguishing Wind
// =================================

//Bools
new bool:isExtinguishingWind = false;

//Handles
new Handle:cvarExtinguishingWind;

// =================================
// Intertia Vault
// =================================

//Bools
new bool:isInertiaVault = false;

//Handles
new Handle:cvarInertiaVault;
new Handle:cvarInertiaVaultPower;
new brokenribs[MAXPLAYERS+1];

// =================================
// Locomotive
// =================================

//Bools
new bool:isLocomotive = false;

//Handles
new Handle:cvarLocomotive;
new Handle:cvarLocomotiveDuration;
new Handle:cvarLocomotiveSpeed;

// =================================
// Meteor Fist
// =================================

//Bools
new bool:isMeteorFist = false;

//Handles
new Handle:cvarMeteorFist;
new Handle:cvarMeteorFistPower;
new Handle:cvarMeteorFistCooldown;

//Floats
static Float:lastMeteorFist[MAXPLAYERS+1] = 0.0;

// =================================
// Snapped Leg
// =================================

//Bools
new bool:isSnappedLeg = false;

//Handles
new Handle:cvarSnappedLeg;
new Handle:cvarSnappedLegChance;
new Handle:cvarSnappedLegDuration;
new Handle:cvarSnappedLegTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:cvarSnappedLegSpeed;

// =================================
// Stowaway
// =================================

//Bools
new bool:isStowAway = false;

//Handles
new Handle:cvarStowaway;
new Handle:cvarStowawayDamage;
new Handle:cvarStowawayTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new stowaway[MAXPLAYERS+1];

// =================================
// Survivor Aegis
// =================================

//Bools
new bool:isSurvivorAegis = false;

//Handles
new Handle:cvarSurvivorAegis;
new Handle:cvarSurvivorAegisAmount;
new Handle:cvarSurvivorAegisDamage;

// =================================
// Void Chamber
// =================================

//Bools
new bool:isVoidChamber = false;

//Handles
new Handle:cvarVoidChamber;
new Handle:cvarVoidChamberPower;
new Handle:cvarVoidChamberDamage;
new Handle:cvarVoidChamberRange;


// ===========================================
// Generic Setup
// ===========================================

//Bools
new bool:isCarried[MAXPLAYERS+1] = false;
new bool:isCharging[MAXPLAYERS+1] = false;
new bool:isSlowed[MAXPLAYERS+1] = false;
new bool:buttondelay[MAXPLAYERS+1] = false;

//Handles
new Handle:PluginStartTimer = INVALID_HANDLE;
new Handle:cvarResetDelayTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:sdkCallFling = INVALID_HANDLE;
new Handle:ConfigFile = INVALID_HANDLE;

// ===========================================
// Plugin Info
// ===========================================

public Plugin:myinfo = 
{
    name = "[L4D2] Unstoppable Charger",
    author = "Mortiegama",
    description = "Allows for unique Charger abilities to bring fear to this titan.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2092125#post2092125"
}

	//Special Thanks:
	//AtomicStryker - Boomer Bit** Slap:
	//https://forums.alliedmods.net/showthread.php?t=97952
	
	//AtomicStryker - Damage Mod (SDK Hooks):
	//https://forums.alliedmods.net/showthread.php?p=1184761
	
	//Karma - Tank Skill Roar
	//https://forums.alliedmods.net/showthread.php?t=126919

// ===========================================
// Plugin Start
// ===========================================

public OnPluginStart()
{
	CreateConVar("l4d_ucm_version", PLUGIN_VERSION, "Unstoppable Charger Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);

	// ======================================
	// Charger Ability: Broken Ribs
	// ======================================
	cvarBrokenRibs = CreateConVar("l4d_ucm_brokenribs", "1", "Enables Broken Ribs ability: Due to the Charger's crushing grip, Survivors may have their ribs broken as a result of pummeling. (Def 1)", FCVAR_PLUGIN);
	cvarBrokenRibsChance = CreateConVar("l4d_ucm_brokenribschance", "100", "Chance that after a pummel ends the Survivor takes damage over time (100 = 100%). (Def 100)", FCVAR_PLUGIN);
	cvarBrokenRibsDuration = CreateConVar("l4d_ucm_brokenribsduration", "10", "For how many seconds should the Broken Ribs cause damage. (Def 10)", FCVAR_PLUGIN);
	cvarBrokenRibsDamage = CreateConVar("l4d_ucm_brokenribsdamage", "1", "How much damage is inflicted by Broken Ribs each second. (Def 1)", FCVAR_PLUGIN);

	// ======================================
	// Charger Ability: Extinguishing Wind
	// ======================================
	cvarExtinguishingWind = CreateConVar("l4d_ucm_extinguishingwind", "1", "Enables Extinguish Wind ability: The force of wind the Charger creates while charging is capable of extinguishing flames on his body. (Def 1)", FCVAR_PLUGIN);
	
	// ======================================
	// Charger Ability: Inertia Vault
	// ======================================
	cvarInertiaVault = CreateConVar("l4d_ucm_inertiavault", "1", "Enables Inertia Vault ability: While charging the Charger has the ability to leap into the air and travel a short distance. (Def 1)", FCVAR_PLUGIN);
	cvarInertiaVaultPower = CreateConVar("l4d_ucm_inertiavaultpower", "400.0", "Power behind the Charger's jump. (Def 400.0)", FCVAR_PLUGIN);
	
	// ======================================
	// Charger Ability: Locomotive
	// ======================================
	cvarLocomotive = CreateConVar("l4d_ucm_locomotive", "1", "Enables Locomotive ability: While charging, the Charger is able to increase speed and duration the longer it doesn't hit anything. (Def 1)", FCVAR_PLUGIN);
	cvarLocomotiveSpeed = CreateConVar("l4d_ucm_locomotivespeed", "1.4", "Multiplier for increase in Charger speed. (Def 1.4)", FCVAR_PLUGIN);
	cvarLocomotiveDuration = CreateConVar("l4d_ucm_locomotiveduration", "4.0", "Amount of time for which the Charger continues to run. (Def 4.0)", FCVAR_PLUGIN);

	// ======================================
	// Charger Ability: Meteor Fist
	// ======================================
	cvarMeteorFist = CreateConVar("l4d_ucm_meteorfist", "1", "Enables Meteor Fist ability: Utilizing his overally muscular arm, when the Charger strikes a Survivor while charging or with his fist, they are sent flying. (Def 1)", FCVAR_PLUGIN);
	cvarMeteorFistPower = CreateConVar("l4d_ucm_meteorfistpower", "200.0", "Power behind the Charger's Meteor Fist. (Def 200.0)", FCVAR_PLUGIN);
	cvarMeteorFistCooldown = CreateConVar("l4d_ucm_meteorfistcooldown", "10.0", "Amount of time between Meteor Fists. (Def 10.0)", FCVAR_PLUGIN);
	
	// ======================================
	// Charger Ability: Snapped Leg
	// ======================================
	cvarSnappedLeg = CreateConVar("l4d_ucm_snappedleg", "1", "Enables Snapped Leg ability: When the Charger collides with a Survivor, it snaps their leg causing them to move slower. (Def 1)", FCVAR_PLUGIN);
	cvarSnappedLegChance = CreateConVar("l4d_ucm_snappedlegchance", "100", "Chance that after a charger collision movement speed is reduced. (Def 1)", FCVAR_PLUGIN);
	cvarSnappedLegDuration = CreateConVar("l4d_ucm_snappedlegduration", "5", "For how many seconds will the Snapped Leg reduce movement speed (100 = 100%). (Def 100)", FCVAR_PLUGIN);
	cvarSnappedLegSpeed = CreateConVar("l4d_ucm_snappedlegspeed", "0.5", "How much does Snapped Leg reduce movement speed. (Def 0.5)", FCVAR_PLUGIN);
	
	// ======================================
	// Charger Ability: Stowaway
	// ======================================
	cvarStowaway = CreateConVar("l4d_ucm_stowaway", "1", "Enables Stowaway ability: The longer the Charger has a Survivor, the more damage adds the Charger will deal when the charge comes to an end. (Def 1)", FCVAR_PLUGIN);
	cvarStowawayDamage = CreateConVar("l4d_ucm_stowawaydamage", "5", "How much damage is inflicted by Stowaway for each second carried. (Def 5)", FCVAR_PLUGIN);
	
	// ======================================
	// Charger Ability: Survivor Aegis
	// ======================================
	cvarSurvivorAegis = CreateConVar("l4d_ucm_survivoraegis", "1", "Enables Survivor Aegis ability: While charging, the Charger will use the Survivor as an Aegis to absorb damage it would receive.  (Def 1)", FCVAR_PLUGIN);
	cvarSurvivorAegisAmount = CreateConVar("l4d_ucm_survivoraegisamount", "0.2", "Percent of damage the Charger avoids using a Survivor as an Aegis. (Def 0.2)", FCVAR_PLUGIN);
	cvarSurvivorAegisDamage = CreateConVar("l4d_ucm_survivoraegisdamage", "5", "How much damage is inflicted to the Survivor being used as an Aegis. (Def 5)", FCVAR_PLUGIN);
	
	// ======================================
	// Charger Ability: Void Chamber
	// ======================================
	cvarVoidChamber = CreateConVar("l4d_ucm_voidchamber", "1", "Enables Void Chamber ability: When starting a charge, the force is so powerful it sucks nearby Survivors in the void left behind. (Def 1)", FCVAR_PLUGIN);
	cvarVoidChamberPower = CreateConVar("l4d_ucm_voidchamberpower", "150.0", "Power behind the inner range of Methane Blast. (Def 150.0)", FCVAR_PLUGIN);
	cvarVoidChamberDamage = CreateConVar("l4d_ucm_voidchamberdamage", "10", "Damage the force of the roar causes to nearby survivors. (Def 10)", FCVAR_PLUGIN);
	cvarVoidChamberRange = CreateConVar("l4d_ucm_voidchamberrange", "200.0", "Area around the Tank the bellow will reach. (Def 200.0)", FCVAR_PLUGIN);

	// ======================================
	// Hook Events
	// ======================================
	HookEvent("charger_pummel_end", Event_ChargerPummelEnd);
	HookEvent("charger_impact", Event_ChargerImpact);
	HookEvent("charger_carry_start", Event_ChargerCarryStart);
	HookEvent("charger_carry_end", Event_ChargerCarryEnd);
	HookEvent("charger_charge_start", Event_ChargeStart);
	HookEvent("charger_charge_end", Event_ChargeEnd);	
	
	AutoExecConfig(true, "plugin.L4D2.UnstoppableCharger");
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);

	ConfigFile = LoadGameConfigFile(GAMEDATA_FILENAME);
	
	// ======================================
	// Prep SDK Calls
	// ======================================
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkCallFling = EndPrepSDKCall();
	
	if (sdkCallFling == INVALID_HANDLE)
	{
		SetFailState("Cant initialize Fling SDKCall");
		return;
	}
}

// ===========================================
// Plugin Start Delayed
// ===========================================

public Action:OnPluginStart_Delayed(Handle:timer)
{	
	if (GetConVarInt(cvarBrokenRibs))
	{
		isBrokenRibs = true;
	}
	
	if (GetConVarInt(cvarExtinguishingWind))
	{
		isExtinguishingWind = true;
	}
	
	if (GetConVarInt(cvarInertiaVault))
	{
		isInertiaVault = true;
	}
	
	if (GetConVarInt(cvarLocomotive))
	{
		isLocomotive = true;
		new Float:duration = GetConVarFloat(cvarLocomotiveDuration);
		SetConVarFloat(FindConVar("z_charge_duration"), duration, false, false);
	}
				
	if (GetConVarInt(cvarMeteorFist))
	{
		isMeteorFist = true;
	}
	
	if (GetConVarInt(cvarSnappedLeg))
	{
		isSnappedLeg = true;
	}

	if (GetConVarInt(cvarStowaway))
	{
		isStowAway = true;
	}
	
	if (GetConVarInt(cvarSurvivorAegis))
	{
		isSurvivorAegis = true;
	}
	
	if (GetConVarInt(cvarVoidChamber))
	{
		isVoidChamber = true;
	}
	
	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	
	if(PluginStartTimer != INVALID_HANDLE)
	{
 		KillTimer(PluginStartTimer);
		PluginStartTimer = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

// ====================================================================================================================
// ===========================================                              =========================================== 
// ===========================================           CHARGER            =========================================== 
// ===========================================                              =========================================== 
// ====================================================================================================================

// ===========================================
// Charger Setup Events
// ===========================================

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Event_ChargeStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// =====================================
	// Charger Ability: Extinguishing Wind
	// =====================================
	if (isExtinguishingWind)
	{
		ChargerAbility_ExtinguishingWind(client);
	}

	// =====================================
	// Charger Ability: Locomotive
	// =====================================
	if (isLocomotive)
	{
		ChargerAbility_LocomotiveStart(client);
	}

	// =====================================
	// Charger Ability: Void Chamber
	// =====================================	
	if (isVoidChamber)
	{
		ChargerAbility_VoidChamber(client);
	}
	
	if (IsValidClient(client))
	{
		isCharging[client] = true;
	}
}

public Event_ChargerCarryStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"victim"));
	
	// =====================================
	// Charger Ability: Stow Away
	// =====================================
	if (isStowAway)
	{
		ChargerAbility_StowawayStart(victim);
	}	
}

public Event_ChargerImpact (Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event,"userid"));
	new victim = GetClientOfUserId(GetEventInt(event,"victim"));
	
	// =====================================
	// Charger Ability: Meteor Fist
	// =====================================
	if (isMeteorFist)
	{
		ChargerAbility_MeteorFist(victim, attacker);
	}
	
	// =====================================
	// Charger Ability: Snapped Leg
	// =====================================
	if (isSnappedLeg)
	{
		ChargerAbility_SnappedLeg(victim);
	}
}

public Event_ChargeEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// =====================================
	// Charger Ability: Locomotive
	// =====================================
	if (isLocomotive)
	{
		ChargerAbility_LocomotiveFinish(client);
	}
		
	if (IsValidClient(client))
	{
		isCharging[client] = false;
	}
}

public Event_ChargerCarryEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"victim"));
	new attacker = GetClientOfUserId(GetEventInt(event,"userid"));
	
	// =====================================
	// Charger Ability: Stow Away
	// =====================================
	if (isStowAway)
	{
		ChargerAbility_StowawayFinish(victim, attacker);
	}
}

public Event_ChargerPummelEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"victim"));
	new attacker = GetClientOfUserId(GetEventInt(event,"userid"));

	// =====================================
	// Charger Ability: Broken Ribs
	// =====================================
	if (isBrokenRibs)
	{
		ChargerAbility_BrokenRibs(victim, attacker);
	}	
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	// =====================================
	// Charger Ability: Survivor Aegis
	// =====================================
	if (isSurvivorAegis && IsValidCharger(victim) && IsValidClient(attacker) && isCharging[victim])
	{
		new Float:damagemod = GetConVarFloat(cvarSurvivorAegisAmount);
				
		if (FloatCompare(damagemod, 1.0) != 0)
		{
			damage = damage * damagemod;
		}

		ChargerAbility_SurvivorAegis(victim, attacker);
	}
	
	// =====================================
	// Charger Ability: Meteor Fist
	// =====================================
	if (IsValidCharger(attacker))
	{
		decl String:classname[STRING_LENGHT];
		GetClientWeapon(attacker, classname, sizeof(classname));
		//PrintToChatAll("%s is weapon", classname);
		
		if (isMeteorFist && StrEqual(classname, CHARGER_WEAPON))
		{
			ChargerAbility_MeteorFist(victim, attacker);
			lastMeteorFist[attacker] = GetEngineTime();
		}
	}

	return Plugin_Changed;
}




// ===========================================
// Charger Ability: Broken Ribs
// ===========================================
// Description: Due to the Charger's crushing grip, Survivors may have their ribs broken as a result of pummeling.

public Action:ChargerAbility_BrokenRibs(victim, attacker)
{
	if (IsValidClient(victim) && GetClientTeam(victim) == 2)
	{
		new BrokenRibsChance = GetRandomInt(0, 99);
		new BrokenRibsPercent = (GetConVarInt(cvarBrokenRibsChance));

		if (BrokenRibsChance < BrokenRibsPercent)
		{
			PrintHintText(victim, "The Charger broke your ribs!");
			if(brokenribs[victim] <= 0)
			{
				brokenribs[victim] = (GetConVarInt(cvarBrokenRibsDuration));
				
				new Handle:dataPack = CreateDataPack();
				cvarBrokenRibsTimer[victim] = CreateDataTimer(1.0, Timer_BrokenRibs, dataPack, TIMER_REPEAT);
				WritePackCell(dataPack, victim);
				WritePackCell(dataPack, attacker);
			}
		}
	}
}

public Action:Timer_BrokenRibs(Handle:timer, any:dataPack) 
{
	ResetPack(dataPack);
	new victim = ReadPackCell(dataPack);
	new attacker = ReadPackCell(dataPack);
	
	if (IsValidClient(victim))
	{
		if(brokenribs[victim] <= 0)
		{
			if(cvarBrokenRibsTimer[victim] != INVALID_HANDLE)
			{
				KillTimer(cvarBrokenRibsTimer[victim]);
				cvarBrokenRibsTimer[victim] = INVALID_HANDLE;
			}	
				
			return Plugin_Stop;
		}

		new damage = GetConVarInt(cvarBrokenRibsDamage);
		DamageHook(victim, attacker, damage);
		
		if(brokenribs[victim] > 0) 
		{
			brokenribs[victim] -= 1;
		}
	}
	
	return Plugin_Continue;
}




// ===========================================
// Charger Ability: Extinguishing Wind
// ===========================================
// Description: The force of wind the Charger creates while charging is capable of extinguishing flames on his body.

public Action:ChargerAbility_ExtinguishingWind(client)
{
	if (IsPlayerOnFire(client))
	{
		ExtinguishEntity(client);
	}
}




// ===========================================
// Charger Ability: Inertia Vault
// ===========================================
// Description: While charging the Charger has the ability to leap into the air and travel a short distance.

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_JUMP && IsValidClient(client) && isCharging[client])
	{
		if (isInertiaVault && !buttondelay[client] && IsPlayerOnGround(client))
		{
			buttondelay[client] = true;
			new Float:vec[3];
			new Float:power = GetConVarFloat(cvarInertiaVaultPower);
			vec[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
			vec[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
			vec[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]") + power;
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
			cvarResetDelayTimer[client] = CreateTimer(1.0, ResetDelay, client);
		}
	}
}

public Action:ResetDelay(Handle:timer, any:client)
{
	buttondelay[client] = false;
	
	if (cvarResetDelayTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarResetDelayTimer[client]);
		cvarResetDelayTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}




// ===========================================
// Charger Ability: Locomotive
// ===========================================
// Description: While charging, the Charger is able to increase speed and duration the longer it doesn't hit anything.

public Action:ChargerAbility_LocomotiveStart(client)
{
	if (IsValidCharger(client))
	{
		SetEntDataFloat(client, laggedMovementOffset, 1.0*GetConVarFloat(cvarLocomotiveSpeed), true);
	}
}

public Action:ChargerAbility_LocomotiveFinish(client)
{
	if (IsValidCharger(client))
	{
		SetEntDataFloat(client, laggedMovementOffset, 1.0, true);
	}
}




// ===========================================
// Charger Ability: Meteor Fist
// ===========================================
// Description: Utilizing his overally muscular arm, when the Charger strikes a Survivor while charging or with his fist, they are sent flying.

public Action ChargerAbility_MeteorFist(victim, attacker)
{
	if (IsValidCharger(attacker) && MeteorFist(attacker) && IsValidClient(victim) && GetClientTeam(victim) == 2 && !IsSurvivorPinned(victim))
	{
		new Float:power = GetConVarFloat(cvarMeteorFistPower);
		FlingHook(victim, attacker, Float:power);
	}
}




// ===========================================
// Charger Ability: Snapped Leg
// ===========================================
// Description: When the Charger collides with a Survivor, it snaps their leg causing them to move slower.

public Action:ChargerAbility_SnappedLeg(victim)
{
	if (IsValidClient(victim) && GetClientTeam(victim) == 2 && !isSlowed[victim])
	{
		new SnappedLegChance = GetRandomInt(0, 99);
		new SnappedLegPercent = (GetConVarInt(cvarSnappedLegChance));

		if (SnappedLegChance < SnappedLegPercent)
		{
			isSlowed[victim] = true;
			PrintHintText(victim, "The Charger's impact has broken your leg!");
			SetEntDataFloat(victim, laggedMovementOffset, GetConVarFloat(cvarSnappedLegSpeed), true);
			cvarSnappedLegTimer[victim] = CreateTimer(GetConVarFloat(cvarSnappedLegDuration), Timer_SnappedLeg, victim);
		}
	}
}

public Action:Timer_SnappedLeg(Handle:timer, any:victim)
{
	if (IsValidClient(victim) && GetClientTeam(victim) == 2)
	{
		SetEntDataFloat(victim, laggedMovementOffset, 1.0, true); //sets the survivors speed back to normal
		PrintHintText(victim, "Your leg is starting to feel better.");
		isSlowed[victim] = false;
	}
	
	if(cvarSnappedLegTimer[victim] != INVALID_HANDLE)
	{
		KillTimer(cvarSnappedLegTimer[victim]);
		cvarSnappedLegTimer[victim] = INVALID_HANDLE;
	}	
		
	return Plugin_Stop;	
}




// ===========================================
// Charger Ability: Stowaway
// ===========================================
// Description: The longer the Charger has a Survivor, the more damage adds the Charger will deal when the charge comes to an end.

public Action:ChargerAbility_StowawayStart(victim)
{
	if (IsValidClient(victim) && GetClientTeam(victim) == 2)
	{
		stowaway[victim] = 1;
		isCarried[victim] = true;
		cvarStowawayTimer[victim] = CreateTimer(0.5, Timer_Stowaway, victim, TIMER_REPEAT);
	}
}

public Action:Timer_Stowaway(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
		if (isCarried[client])
		{
			stowaway[client] += 1;
		}
		
		if (!isCarried[client])
		{
			if (cvarStowawayTimer[client] != INVALID_HANDLE)
			{
				KillTimer(cvarStowawayTimer[client]);
				cvarStowawayTimer[client] = INVALID_HANDLE;
			}
		
			return Plugin_Stop;	
		}
	}
	
	return Plugin_Continue;	
}

public Action:ChargerAbility_StowawayFinish(victim, attacker)
{
	if (IsValidClient(victim) && GetClientTeam(victim) == 2)
	{
		isCarried[victim] = false;
		
		new damage = (stowaway[victim] * GetConVarInt(cvarStowawayDamage));
		DamageHook(victim, attacker, damage);
	}
}




// ===========================================
// Charger Ability: Survivor Aegis
// ===========================================
// Description: While charging, the Charger will use the Survivor as an Aegis to absorb damage it would receive. 

public Action:ChargerAbility_SurvivorAegis(victim, attacker)
{
	new aegis = GetEntPropEnt(victim, Prop_Send, "m_carryVictim");
		
	if (IsValidClient(aegis))
	{
		new damage = GetConVarInt(cvarSurvivorAegisDamage);
		DamageHook(aegis, victim, damage);
	}
}




// ===========================================
// Charger Ability: Void Chamber
// ===========================================
// Description: Damages Survivor based upon amount of time carried.

public Action:ChargerAbility_VoidChamber(attacker)
{
	if (IsValidCharger(attacker))
	{
		for (new victim=1; victim<=MaxClients; victim++)
		
		if (IsValidClient(victim) && GetClientTeam(victim) == 2  && !IsSurvivorPinned(victim))
		{
			decl Float:chargerPos[3];
			decl Float:survivorPos[3];
			decl Float:distance;
			new Float:range = GetConVarFloat(cvarVoidChamberRange);
			GetClientEyePosition(attacker, chargerPos);
			GetClientEyePosition(victim, survivorPos);
			distance = GetVectorDistance(survivorPos, chargerPos);
							
			if (distance < range)
			{
				decl String:sRadius[256];
				decl String:sPower[256];
				new magnitude;
				magnitude = GetConVarInt(cvarVoidChamberPower) * -1;
				IntToString(GetConVarInt(cvarVoidChamberRange), sRadius, sizeof(sRadius));
				IntToString(magnitude, sPower, sizeof(sPower));
				new exPhys = CreateEntityByName("env_physexplosion");
				//Set up physics movement explosion
				DispatchKeyValue(exPhys, "radius", sRadius);
				DispatchKeyValue(exPhys, "magnitude", sPower);
				DispatchSpawn(exPhys);
				TeleportEntity(exPhys, chargerPos, NULL_VECTOR, NULL_VECTOR);
				
				//BOOM!
				AcceptEntityInput(exPhys, "Explode");
				decl Float:traceVec[3], Float:resultingVec[3], Float:currentVelVec[3];
				new Float:power = GetConVarFloat(cvarVoidChamberPower);
				MakeVectorFromPoints(chargerPos, survivorPos, traceVec);				// draw a line from car to Survivor
				GetVectorAngles(traceVec, resultingVec);							// get the angles of that line
				
				resultingVec[0] = Cosine(DegToRad(resultingVec[1])) * power;	// use trigonometric magic
				resultingVec[1] = Sine(DegToRad(resultingVec[1])) * power;
				resultingVec[2] = power * SLAP_VERTICAL_MULTIPLIER;
				
				GetEntPropVector(victim, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
				resultingVec[0] += currentVelVec[0];
				resultingVec[1] += currentVelVec[1];
				resultingVec[2] += currentVelVec[2];
				
				resultingVec[0] = resultingVec[0] * -1;
				resultingVec[1] = resultingVec[1] * -1;

				//Fling_VoidChamber(victim, resultingVec, client);
				new Float:incaptime = 3.0;
				SDKCall(sdkCallFling, victim, resultingVec, 76, attacker, incaptime); //76 is the 'got bounced' animation in L4D2
				
				new damage = GetConVarInt(cvarVoidChamberDamage);
				DamageHook(victim, attacker, damage);
			}
		}
	}
}




// ====================================================================================================================
// ===========================================                              =========================================== 
// ===========================================        GENERIC CALLS         =========================================== 
// ===========================================                              =========================================== 
// ====================================================================================================================

public Action:DamageHook(victim, attacker, damage)
{
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
	AcceptEntityInput(entPointHurt, "Hurt", (attacker && attacker < MaxClients && IsClientInGame(attacker)) ? attacker : -1);
	
	// Config, delete point_hurt
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	RemoveEdict(entPointHurt);
}

public Action:FlingHook(victim, attacker, Float:power)
{
	decl Float:HeadingVector[3], Float:AimVector[3];
	
	GetClientEyeAngles(attacker, HeadingVector);
		
	AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , power);
	AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , power);
			
	decl Float:current[3];
	GetEntPropVector(victim, Prop_Data, VELOCITY_ENTPROP, current);
			
	decl Float:resulting[3];
	resulting[0] = FloatAdd(current[0], AimVector[0]);	
	resulting[1] = FloatAdd(current[1], AimVector[1]);
	resulting[2] = power * SLAP_VERTICAL_MULTIPLIER;
	
	new Float:incaptime = 3.0;
	//L4D2_Fling(victim, resulting, attacker);
	SDKCall(sdkCallFling, victim, resulting, 76, attacker, incaptime); //76 is the 'got bounced' animation in L4D2
}

public OnMapEnd()
{
    for (new client=1; client<=MaxClients; client++)
	{
	if (IsValidClient(client))
		{
			isCharging[client] = false;
		}
	}
}




// ====================================================================================================================
// ===========================================                              =========================================== 
// ===========================================          BOOL CALLS          =========================================== 
// ===========================================                              =========================================== 
// ====================================================================================================================

public IsValidClient(client)
{
	if (client <= 0)
		return false;
		
	if (client > MaxClients)
		return false;
		
	if (!IsClientInGame(client))
		return false;
		
	if (!IsPlayerAlive(client))
		return false;

	return true;
}

static bool:MeteorFist(slapper)
{
	return ((GetEngineTime() - lastMeteorFist[slapper]) > GetConVarFloat(cvarMeteorFistCooldown));
}

public IsPlayerOnGround(client)
{
	if (GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND) return true;
		else return false;
}

public IsValidCharger(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		
		if (class == ZOMBIECLASS_CHARGER)
			return true;
		
		return false;
	}
	
	return false;
}

public IsPlayerOnFire(client)
{
	if (IsValidClient(client))
	{
		if (GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONFIRE) return true;
		else return false;
	}
	else return false;
}

public IsSurvivorPinned(client)
{
	new attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	if (attacker > 0 && attacker != client)
		return true;
		
	attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	if (attacker > 0 && attacker != client)
		return true;
		
	attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if (attacker > 0 && attacker != client)
		return true;
		
	attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (attacker > 0 && attacker != client)
		return true;
		
	attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if (attacker > 0 && attacker != client)
		return true;
		
	return false;
}