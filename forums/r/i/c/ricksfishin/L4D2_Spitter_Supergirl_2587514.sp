#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define L4D2 Spitter Supergirl
#define PLUGIN_VERSION "1.5"

#define ZOMBIECLASS_SPITTER 4

// ===========================================
// Spitter Setup
// ===========================================

// =================================
// Acidic Bile
// =================================

//Bools
new bool:isAcidicBile = false;

//Handles
new Handle:cvarAcidicBile;
new Handle:cvarAcidicBileChance;

// =================================
// Acidic Slobber
// =================================

//Bools
new bool:isAcidicSlobber = false;

//Handles
new Handle:cvarAcidicSlobber;
new Handle:cvarAcidicSlobberChance;
new Handle:cvarAcidicSlobberDamage;
new Handle:cvarAcidicSlobberRange;
new Handle:cvarAcidicSlobberTimer[MAXPLAYERS+1] = INVALID_HANDLE;

// =================================
// Acidic Pool
// =================================

//Bools
new bool:isAcidicPool = false;
new bool:isAcidicPoolDrop[MAXPLAYERS+1] = false;

//Handles
new Handle:cvarAcidicPool;
new Handle:cvarAcidicPoolCooldown;
new Handle:cvarAcidicPoolTimer[MAXPLAYERS+1] = INVALID_HANDLE;

// =================================
// Acidic Splash
// =================================

//Bools
new bool:isAcidicSplash = false;

//Handles
new Handle:cvarAcidicSplash;
new Handle:cvarAcidicSplashChance;
new Handle:cvarAcidicSplashDamage;
new Handle:cvarAcidicSplashRange;

// =================================
// Acid Swipe
// =================================

//Bools
new bool:isAcidSwipe = false;

//Handles
new Handle:cvarAcidSwipe;
new Handle:cvarAcidSwipeChance;
new Handle:cvarAcidSwipeDamage;
new Handle:cvarAcidSwipeDuration;
new Handle:cvarAcidSwipeTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new acidswipe[MAXPLAYERS+1];

// =================================
// Hydra Strike
// =================================

//Bools
new bool:isHydraStrike = false;
new bool:isHydraStrikeActive[MAXPLAYERS+1] = false;

//Handles
new Handle:cvarHydraStrike;
new Handle:cvarHydraStrikeCooldown;
new Handle:cvarHydraStrikeTimer[MAXPLAYERS+1] = INVALID_HANDLE;

// =================================
// Sticky Goo
// =================================

//Bools
new bool:isStickyGoo = false;
new bool:isStickyGooJump = false;

//Handles
new Handle:cvarStickyGoo;
new Handle:cvarStickyGooDuration;
new Handle:cvarStickyGooSpeed;
new Handle:cvarStickyGooJump;
new Handle:cvarStickyGooTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:cvarAcidDelay[MAXPLAYERS+1] = INVALID_HANDLE;

new stickygoo[MAXPLAYERS+1];
static laggedMovementOffset = 0;

// =================================
// Supergirl
// =================================

//Bools
new bool:isSupergirl = false;
new bool:isSupergirlSpeed = false;

//Handles
new Handle:cvarSupergirl;
new Handle:cvarSupergirlSpeed;
new Handle:cvarSupergirlDuration;
new Handle:cvarSupergirlSpeedDuration;
new Handle:cvarSupergirlTimer[MAXPLAYERS +1];
new Handle:cvarSupergirlSpeedTimer[MAXPLAYERS +1];

new bool:aciddelay[MAXPLAYERS+1] = false;


// ===========================================
// Generic Setup
// ===========================================

static const String:GAMEDATA_FILENAME[] = "l4d2_viciousplugins";

//Handles
new Handle:PluginStartTimer = INVALID_HANDLE;
new Handle:sdkCallDetonateAcid = INVALID_HANDLE;
new Handle:sdkCallFling = INVALID_HANDLE;
new Handle:sdkCallVomitOnPlayer = INVALID_HANDLE;
new Handle:ConfigFile = INVALID_HANDLE;
new g_iAbilityO = -1;
new g_iNextActO = -1;

// ===========================================
// Plugin Info
// ===========================================

public Plugin:myinfo = 
{
    name = "[L4D2] Spitter Supergirl",
    author = "Mortiegama",
    description = "Adds a host of abilities to the Spitter to add Supergirl like powers.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=122802"
}

// ===========================================
// Plugin Start
// ===========================================

public OnPluginStart()
{
	CreateConVar("l4d_ssg_version", PLUGIN_VERSION, "Spitter Supergirl Version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);

	// ======================================
	// Spitter Ability: Acidic Bile
	// ======================================
	cvarAcidicBile = CreateConVar("l4d_ssg_acidicbile", "1", "Enables Acidic Bile ability: Survivors that have wandered into an acid pool have a chance of being splashed with bile and attracting common infected. (Def 1)", FCVAR_NOTIFY);
	cvarAcidicBileChance = CreateConVar("l4d_ssg_acidicbilechance", "5", "Chance that the Survivor will be biled upon when standing in spit. (Def 5)", FCVAR_NOTIFY);

	// ======================================
	// Spitter Ability: Acidic Pool
	// ======================================
	cvarAcidicPool = CreateConVar("l4d_ssg_acidicpool", "1", "Enables Acidic Pool ability: Due to the unstable nature of the Spitter's body, periodically a pool of Spit will leak out beneath her feet. (Def 1)", FCVAR_NOTIFY);
	cvarAcidicPoolCooldown = CreateConVar("l4d_ssg_acidicpoolcooldown", "30.0", "Period of time between Acid Pool drops. (Def 30.0)", FCVAR_NOTIFY);

	// ======================================
	// Spitter Ability: Acidic Slobber
	// ======================================
	cvarAcidicSlobber = CreateConVar("l4d_ssg_acidicslobber", "1", "Enables Acidic Slobber ability: The Spitter is constantly shaking her head which will occasionally cause some of the drooling acid to land on nearby Survivors. (Def 1)", FCVAR_NOTIFY);
	cvarAcidicSlobberChance = CreateConVar("l4d_ssg_acidicslobberchance", "5", "Chance that a Survivor will be hit with Acid from the Spitter's slobber. (Def 5)(5 = 5%)", FCVAR_NOTIFY);
	cvarAcidicSlobberDamage = CreateConVar("l4d_ssg_acidicslobberdamage", "15", "Amount of damage the Acidic Slobber will cause to a Survivor. (Def 15)", FCVAR_NOTIFY);
	cvarAcidicSlobberRange = CreateConVar("l4d_ssg_acidicslobberrange", "500.0", "Distance the Acidic Slobber will travel. (Def 500.0)", FCVAR_NOTIFY);

	// ======================================
	// Spitter Ability: Acidic Splash
	// ======================================	
	cvarAcidicSplash = CreateConVar("l4d_ssg_acidicsplash", "1", "Enables Acid Splash ability: When a Spitter takes damage, the fresh wounds have a chance of splashing acid on any nearby Survivors. (Def 1)", FCVAR_NOTIFY);
	cvarAcidicSplashChance = CreateConVar("l4d_ssg_acidicsplashchance", "50", "Chance that a Survivor will be splashed by the Spitter's acid splash. (Def 50)(50 = 50%)", FCVAR_NOTIFY);
	cvarAcidicSplashDamage = CreateConVar("l4d_ssg_acidicsplashdamage", "6", "Amount of damage the Acidic Splash will cause to a Survivor. (Def 6)", FCVAR_NOTIFY);
	cvarAcidicSplashRange = CreateConVar("l4d_ssg_acidicsplashrange", "500.0", "Distance the Acidic Splash will travel from Spitter. (Def 500.0)", FCVAR_NOTIFY);
	
	// ======================================
	// Spitter Ability: Acid Swipe
	// ======================================
	cvarAcidSwipe = CreateConVar("l4d_ssg_acidswipe", "1", "Enables Acid Swipe ability: The Spitter uses her acid coated fingers to swipe at a Survivor, causing damage over time as the wound burns. (Def 1)", FCVAR_NOTIFY);
	cvarAcidSwipeChance = CreateConVar("l4d_ssg_acidswipechance", "100", "Chance that when a Spitter claws a Survivor they will take damage over time. (100 = 100%). (Def 100)", FCVAR_NOTIFY);
	cvarAcidSwipeDuration = CreateConVar("l4d_ssg_acidswipeduration", "3", "For how many seconds does the Acid Swipe last. (Def 10)", FCVAR_NOTIFY);
	cvarAcidSwipeDamage = CreateConVar("l4d_ssg_acidswipedamage", "1", "How much damage is inflicted by Acid Swipe each second. (Def 1)", FCVAR_NOTIFY);
	
	// ======================================
	// Spitter Ability: Hydra Strike
	// ======================================
	cvarHydraStrike = CreateConVar("l4d_ssg_hydrastrike", "1", "Enables Hydra Strike ability: Allows the Spitter to fire off a second spit rapidly after the first. (Def 1)", FCVAR_NOTIFY);
	cvarHydraStrikeCooldown = CreateConVar("l4d_ssg_hydrastrikecooldown", "0.0", "Additional recharge time before the Hydra Strike allows another spit. (Def 0.0)", FCVAR_NOTIFY);

	// ======================================
	// Spitter Ability: Sticky Goo
	// ======================================
	cvarStickyGoo = CreateConVar("l4d_ssg_stickygoo", "1", "Enables Sticky Goo ability: Any Survivor standing inside a pool of Spit will be stuck in the goo and find it harder to move out quickly. (Def 1)", FCVAR_NOTIFY);
	cvarStickyGooJump = CreateConVar("l4d_ssg_stickygoojump", "1", "Prevents the Survivor from jumping while speed is reduced. (Def 1)", FCVAR_NOTIFY);
	cvarStickyGooDuration = CreateConVar("l4d_ssg_stickygooduration", "3", "For how long after exiting the Sticky Goo will a Survivor be slowed. (Def 3)", FCVAR_NOTIFY);
	cvarStickyGooSpeed = CreateConVar("l4d_ssg_stickygoospeed", "0.5", "Speed reduction to Survivor caused by the Sticky Goo. (Def 0.5)", FCVAR_NOTIFY);

	// ======================================
	// Spitter Ability: Super Girl
	// ======================================
	cvarSupergirl = CreateConVar("l4d_ssg_supergirl", "1", "Enables Super Girl ability: After launching a spit, the Spitter is coated in a protective layer that slowly drips off and reduces all damage until it is gone. (Def 1)", FCVAR_NOTIFY);
	cvarSupergirlDuration = CreateConVar("l4d_ssg_supergirlduration", "4", "How long the Spitter is invulnerable. (Def 4)", FCVAR_NOTIFY);
	
	// ======================================
	// Spitter Ability: Super Girl Speed
	// ======================================
	cvarSupergirlSpeed = CreateConVar("l4d_ssg_supergirlspeed", "1", "Enables Super Girl Speed ability: Works with the Supergirl ability, the spit also coats the Spitters feet increasing movement speed for a brief period after launching a spit. (Def 1)", FCVAR_NOTIFY);
	cvarSupergirlSpeedDuration = CreateConVar("l4d_ssg_supergirlspeedduration", "4", "How long the Spitter is invulnerable. (Def 4)", FCVAR_NOTIFY);
	AutoExecConfig(true, "L4D2_Supergirl");
	
	// ======================================
	// Hook Events
	// ======================================
	HookEvent("spit_burst", Event_SpitBurst);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	// ======================================
	// General Setup
	// ======================================
	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	g_iNextActO			=	FindSendPropInfo("CBaseAbility","m_nextActivationTimer");
	g_iAbilityO			=	FindSendPropInfo("CTerrorPlayer","m_customAbility");
		
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
	
	ConfigFile = LoadGameConfigFile(GAMEDATA_FILENAME);
	
	// ======================================
	// SDK Calls
	// ======================================
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CSpitterProjectile_Detonate");
	sdkCallDetonateAcid = EndPrepSDKCall();
	if(sdkCallDetonateAcid == INVALID_HANDLE)
	{
		LogError("Could not prep the Detonate Acid function");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkCallVomitOnPlayer = EndPrepSDKCall();
	
	if (sdkCallVomitOnPlayer == INVALID_HANDLE)
	{
		SetFailState("Cant initialize OnVomitedUpon SDKCall");
		return;
	}
	
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
	
	CloseHandle(ConfigFile);
}

// ===========================================
// Plugin Start Delayed
// ===========================================

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (GetConVarInt(cvarAcidicBile))
	{
		isAcidicBile = true;
	}
	
	if (GetConVarInt(cvarAcidicSlobber))
	{
		isAcidicSlobber = true;
	}
	
	if (GetConVarInt(cvarAcidicSplash))
	{
		isAcidicSplash = true;
	}
		
	if (GetConVarInt(cvarAcidicPool))
	{
		isAcidicPool = true;
	}
	
	if (GetConVarInt(cvarAcidSwipe))
	{
		isAcidSwipe = true;
	}

	if (GetConVarInt(cvarHydraStrike))
	{
		isHydraStrike = true;
	}
	
	if (GetConVarInt(cvarStickyGoo))
	{
		isStickyGoo = true;
	}
	
	if (GetConVarInt(cvarStickyGooJump))
	{
		isStickyGooJump = true;
	}
	
	if (GetConVarInt(cvarSupergirl))
	{
		isSupergirl = true;
	}
	
	if (GetConVarInt(cvarSupergirlSpeed))
	{
		isSupergirlSpeed = true;
	}
	
	if(PluginStartTimer != INVALID_HANDLE)
	{
 		KillTimer(PluginStartTimer);
		PluginStartTimer = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}




// ====================================================================================================================
// ===========================================                              =========================================== 
// ===========================================           SPITTER            =========================================== 
// ===========================================                              =========================================== 
// ====================================================================================================================

// ===========================================
// Spitter Setup Events
// ===========================================

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:Event_PlayerSpawn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidSpitter(client))
	{
		// =================================
		// Spitter Ability: Acidic Pool
		// =================================
		if (isAcidicPool)
		{
		SpitterAbility_AcidicPool(client);
		}
		
		// =================================
		// Spitter Ability: Acidic Slobber
		// =================================
		if (isAcidicSlobber)
		{
		SpitterAbility_AcidicSlobber(client);
		}
	}
}

public Action:Event_SpitBurst(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	// =================================
	// Spitter Ability: Hydra Strike
	// =================================
	
	if (isHydraStrike)
	{
		SpitterAbility_HydraStrike(client);
	}

	// =================================
	// Spitter Ability: Super Girl
	// =================================
	
	if (isSupergirl)
	{
		SpitterAbility_SuperGirl(client);
	}
	
	// =================================
	// Spitter Ability: Super Girl Speed
	// =================================
	
	if (isSupergirlSpeed)
	{
		SpitterAbility_SuperGirlSpeed(client);
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
        if (IsValidEntity(inflictor) && IsValidClient(victim) && GetClientTeam(victim) == 2)
{	
		decl String:classname[56];
		
		GetEdictClassname(inflictor, classname, sizeof(classname));
    
		if (StrEqual(classname, "insect_swarm"))
		{
			// =================================
			// Spitter Ability: Acidic Bile
			// =================================
			if (isAcidicBile)
			{
				SpitterAbility_AcidicBile(victim, attacker);
			}
			
			// =================================
			// Spitter Ability: Sticky Goo
			// =================================
			if (isStickyGoo)
			{
				SpitterAbility_StickyGoo(victim);
			}
			
			cvarAcidDelay[victim] = CreateTimer(1.0, Timer_AcidDelay, victim);
			aciddelay[victim] = true;
		}
		
		{
			// =================================
			// Spitter Ability: Acid Swipe
			// =================================
			if (isAcidSwipe)
			{
				SpitterAbility_AcidSwipe(victim, attacker);
			}
		}
	}
	
	if (IsValidClient(attacker) && GetClientTeam(attacker) == 2 && IsValidSpitter(victim))
	{
		// =================================
		// Spitter Ability: Acidic Splash
		// =================================
		if(isAcidicSplash)
		{
			SpitterAbility_AcidicSplash(victim);
		}
	}
}

public Action:Timer_AcidDelay(Handle:timer, any:victim)
{
	aciddelay[victim] = false;
	
	if (cvarAcidDelay[victim] != INVALID_HANDLE)
	{
		KillTimer(cvarAcidDelay[victim]);
		cvarAcidDelay[victim] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}



// ===========================================
// Spitter Ability: Acidic Bile
// ===========================================
// Description: Enables the Acidic Bile ability, Survivors who enter a pool of spit will attract infected.
public SpitterAbility_AcidicBile(victim, attacker)
{
	new AcidicBileChance = GetRandomInt(0, 99);
	new AcidicBilePercent = (GetConVarInt(cvarAcidicBileChance));

	if (IsValidClient(victim) && GetClientTeam(victim) == 2 && AcidicBileChance < AcidicBilePercent)
	{
		SDKCall(sdkCallVomitOnPlayer, victim, attacker, true);
	}
}




// ===========================================
// Spitter Ability: Acidic Pool
// ===========================================
// Description: Enables the Acidic Pool ability, the Spitter randomly drops a pool of spit where she stands.

public SpitterAbility_AcidicPool(client)			
{
	cvarAcidicPoolTimer[client] = CreateTimer(GetConVarFloat(cvarAcidicPoolCooldown), Timer_AcidicPool, client, TIMER_REPEAT);
}

public Action:Timer_AcidicPool(Handle:timer, any:client)
{
	if (!IsValidSpitter(client) || IsPlayerGhost(client))
	{
		if (cvarAcidicPoolTimer[client] != INVALID_HANDLE)
		{
			KillTimer(cvarAcidicPoolTimer[client]);
			cvarAcidicPoolTimer[client] = INVALID_HANDLE;
		}	
	
		return Plugin_Stop;
	}
	
	isAcidicPoolDrop[client] = true;
	Create_AcidicPool(client);

	return Plugin_Continue;
}

public Create_AcidicPool(client)
{
	decl Float:vecPos[3];
	GetClientAbsOrigin(client, vecPos);
	vecPos[2]+=16.0;
	
	new iAcid = CreateEntityByName("spitter_projectile");
	if(IsValidEntity(iAcid))
	{
		DispatchSpawn(iAcid);
		SetEntPropFloat(iAcid, Prop_Send, "m_DmgRadius", 1024.0); // Radius of the acid.
		SetEntProp(iAcid, Prop_Send, "m_bIsLive", 1 ); // Without this set to 1, the acid won't make any sound.
		SetEntPropEnt(iAcid, Prop_Send, "m_hThrower", client); // A player who caused the acid to appear.
		TeleportEntity(iAcid, vecPos, NULL_VECTOR, NULL_VECTOR);
		SDKCall(sdkCallDetonateAcid, iAcid);
	}
	
	if (IsValidClient(client))
	{
		isAcidicPoolDrop[client] = false;
	}
}




// ===========================================
// Spitter Ability: Acid Slobber
// ===========================================
// Description: Enables the ability for the Spitter to slobber on Survivors causing them acidic damage.

public SpitterAbility_AcidicSlobber(client)
{
	cvarAcidicSlobberTimer[client] = CreateTimer(0.5, Timer_AcidicSlobber, client, TIMER_REPEAT);
}
			
public Action:Timer_AcidicSlobber(Handle:timer, any:client)
{
	if (!IsValidSpitter(client) || IsPlayerGhost(client))
	{
		if (cvarAcidicSlobberTimer[client] != INVALID_HANDLE)
		{
			KillTimer(cvarAcidicSlobberTimer[client]);
			cvarAcidicSlobberTimer[client] = INVALID_HANDLE;
		}	
	
		return Plugin_Stop;
	}

	for (new victim=1; victim<=MaxClients; victim++)
	
	if (IsValidClient(victim) && IsValidClient(client) && GetClientTeam(victim) == 2)
	{
		new AcidicSlobberChance = GetRandomInt(0, 99);
		new AcidicSlobberPercent = (GetConVarInt(cvarAcidicSlobberChance));
		
		if (AcidicSlobberChance < AcidicSlobberPercent)
		{
			decl Float:v_pos[3];
			GetClientEyePosition(victim, v_pos);		
			decl Float:targetVector[3];
			decl Float:distance;
			new Float:range = GetConVarFloat(cvarAcidicSlobberRange);
			GetClientEyePosition(client, targetVector);
			distance = GetVectorDistance(targetVector, v_pos);
			//PrintToChatAll("Distance: %f Client: %n", distance, victim);
			
			if (distance <= range)
			{
				new damage = GetConVarInt(cvarAcidicSlobberDamage);
				new attacker = client;
				DamageHook(victim, attacker, damage);
			}
		}
	}
	
	return Plugin_Continue;
}




// ===========================================
// Spitter Ability: Acidic Splash
// ===========================================
// Description: Enables the ability Acidic Splash, when hit, the Spitter's acid splashes out at nearby survivors.

public SpitterAbility_AcidicSplash(victim)
{
	for (new survivor=1; survivor<=MaxClients; survivor++)
	
	if (IsValidClient(survivor) && GetClientTeam(survivor) == 2 && IsValidSpitter(victim))
	{
		new AcidicSplashChance = GetRandomInt(0, 99);
		new AcidicSplashPercent = (GetConVarInt(cvarAcidicSplashChance));	

		if (AcidicSplashChance < AcidicSplashPercent)
		{
			decl Float:v_pos[3];
			GetClientEyePosition(survivor, v_pos);		
			decl Float:targetVector[3];
			decl Float:distance;
			new Float:range = GetConVarFloat(cvarAcidicSplashRange);
			GetClientEyePosition(victim, targetVector);
			distance = GetVectorDistance(targetVector, v_pos);
			//PrintToChatAll("Distance: %f victim: %n", distance, survivor);
				
			if (distance <= range)
			{
				new damage = GetConVarInt(cvarAcidicSplashDamage);
				DamageHook(survivor, victim, damage);
			}
		}
	}
}




// ===========================================
// Spitter Ability: Acid Swipe
// ===========================================
// Description: Survivor takes damage over time after being Spitter clawed.

public SpitterAbility_AcidSwipe(victim, attacker)
{
	new AcidSwipeChance = GetRandomInt(0, 99);
	new AcidSwipePercent = (GetConVarInt(cvarAcidSwipeChance));

	if (IsValidClient(victim) && GetClientTeam(victim) == 2 && AcidSwipeChance < AcidSwipePercent)
	{
		PrintHintText(victim, "The Spitter has coated you with corrosive acid!");
		
		if(acidswipe[victim] <= 0)
		{
			acidswipe[victim] = (GetConVarInt(cvarAcidSwipeDuration));
			
			new Handle:dataPack = CreateDataPack();
			cvarAcidSwipeTimer[victim] = CreateDataTimer(1.0, Timer_AcidSwipe, dataPack, TIMER_REPEAT);
			WritePackCell(dataPack, victim);
			WritePackCell(dataPack, attacker);
		}
	}
}

public Action:Timer_AcidSwipe(Handle:timer, any:dataPack) 
{
	ResetPack(dataPack);
	new victim = ReadPackCell(dataPack);
	new attacker = ReadPackCell(dataPack);

	if (IsValidClient(victim))
	{
		if(acidswipe[victim] <= 0)
		{
			if (cvarAcidSwipeTimer[victim] != INVALID_HANDLE)
			{
				KillTimer(cvarAcidSwipeTimer[victim]);
				cvarAcidSwipeTimer[victim] = INVALID_HANDLE;
			}
				
			return Plugin_Stop;
		}

		new damage = GetConVarInt(cvarAcidSwipeDamage);
		DamageHook(victim, attacker, damage);
			
		if(acidswipe[victim] > 0) 
		{
			acidswipe[victim] -= 1;
		}
	}
	
	return Plugin_Continue;
}




// ===========================================
// Spitter Ability: Hydra Strike
// ===========================================
// Description: Allows the Spitter to fire off a second spit rapidly after the first.

public Action:SpitterAbility_HydraStrike(client)
{
	if (IsValidSpitter(client) && !isAcidicPoolDrop[client] && !isHydraStrikeActive[client])
	{
		cvarHydraStrikeTimer[client] = CreateTimer(1.0, Timer_HydraStrike, client);
	}
	
	else
	{
		isHydraStrikeActive[client] = false;
	}
	
	return Plugin_Handled;
}  

public Action:Timer_HydraStrike(Handle:timer, any:client)
{
	if (IsValidSpitter(client))
	{
		new iEntid = GetEntDataEnt2(client,g_iAbilityO);
		new Float:flTimeStamp_ret = GetEntDataFloat(iEntid,g_iNextActO+8);
		new Float:flTimeStamp_calc = flTimeStamp_ret - (flTimeStamp_ret + 1.0) + (GetConVarFloat(cvarHydraStrikeCooldown));
		SetEntDataFloat(iEntid, g_iNextActO+8, flTimeStamp_calc, true);
		
		isHydraStrikeActive[client] = true;
	}
	
	if (cvarHydraStrikeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarHydraStrikeTimer[client]);
		cvarHydraStrikeTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}




// ===========================================
// Spitter Ability: Sticky Goo
// ===========================================
// Description: Any Survivor standing inside a pool of Spit will be stuck in the goo and find it harder to move out quickly.

public SpitterAbility_StickyGoo(victim)
{
	if (stickygoo[victim] <= 0)
	{
		stickygoo[victim] = (GetConVarInt(cvarStickyGooDuration));
		cvarStickyGooTimer[victim] = CreateTimer(1.0, Timer_StickyGoo, victim, TIMER_REPEAT);
		SetEntDataFloat(victim, laggedMovementOffset, GetConVarFloat(cvarStickyGooSpeed), true);

		if (isStickyGooJump)
		{
				SetEntityGravity(victim, 5.0);
		}
			
		PrintHintText(victim, "Standing in the spit is slowing you down!");
	}
			
	if (stickygoo[victim] > 0 && !aciddelay[victim])
	{
		stickygoo[victim]++;
	}
}

public Action:Timer_StickyGoo(Handle:timer, any:victim) 
{
	if (IsValidClient(victim))
	{
		if(stickygoo[victim] <= 0)
		{
			SetEntDataFloat(victim, laggedMovementOffset, 1.0, true); //sets the survivors speed back to normal
			SetEntityGravity(victim, 1.0);
			PrintHintText(victim, "The spit is wearing off!");
			
			if (cvarStickyGooTimer[victim] != INVALID_HANDLE)
				{
					KillTimer(cvarStickyGooTimer[victim]);
					cvarStickyGooTimer[victim] = INVALID_HANDLE;
				}
				
			return Plugin_Stop;
		}

		if(stickygoo[victim] > 0) 
		{
			stickygoo[victim] -= 1;
		}
	}
	
	return Plugin_Continue;
}




// ===========================================
// Spitter Ability: Supergirl
// ===========================================
// Description: After launching a spit, the Spitter is coated in a protective layer that slowly drips off and reduces all damage until it is gone.

public SpitterAbility_SuperGirl(client)
{
	if (IsValidSpitter(client) && !isAcidicPoolDrop[client])
	{
		PrintHintText(client, "You are temporarily invulnerable!");
		cvarSupergirlTimer[client] = CreateTimer(GetConVarFloat(cvarSupergirlDuration), Timer_Supergirl, client);	
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	}
}

public Action:Timer_Supergirl(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		PrintHintText(client, "You are no longer invulnerable!");
	}
		
	if (cvarSupergirlTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarSupergirlTimer[client]);
		cvarSupergirlTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}




// ===========================================
// Spitter Ability: Supergirl Speed
// ===========================================
// Description: Works with the Supergirl ability, the spit also coats the Spitters feet increasing movement speed for a brief period after launching a spit.

public SpitterAbility_SuperGirlSpeed(client)
{
	if (IsValidSpitter(client) && !isAcidicPoolDrop[client])
	{
		cvarSupergirlSpeedTimer[client] = CreateTimer(GetConVarFloat(cvarSupergirlSpeedDuration), Timer_SupergirlSpeed, client);	
		SetEntDataFloat(client, laggedMovementOffset, 1.6, true);
	}
}

public Action:Timer_SupergirlSpeed(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		SetEntDataFloat(client, laggedMovementOffset, 1.0, true);
	}
	
	if (cvarSupergirlSpeedTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarSupergirlSpeedTimer[client]);
		cvarSupergirlSpeedTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
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

public IsValidDeadClient(client)
{
	if (client <= 0)
		return false;
		
	if (client > MaxClients)
		return false;
		
	if (!IsClientInGame(client))
		return false;
		
	if (IsPlayerAlive(client))
		return false;

	return true;
}

public IsValidSpitter(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		
		if (class == ZOMBIECLASS_SPITTER)
			return true;
		
		return false;
	}
	
	return false;
}

public IsPlayerGhost(client)
{
	if (IsValidClient(client))
	{
		if (GetEntProp(client, Prop_Send, "m_isGhost")) return true;
		else return false;
	}
	else return false;
}