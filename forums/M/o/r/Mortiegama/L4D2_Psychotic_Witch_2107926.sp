#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define L4D2 Psychotic Witch
#define PLUGIN_VERSION "1.2"

#define STRING_LENGHT								56
#define MODEL_PROPANE								"models/props_junk/propanecanister001a.mdl"

static const String:GAMEDATA_FILENAME[] 				= "l4d2_viciousplugins";
static const Float:SLAP_VERTICAL_MULTIPLIER			= 1.5;
static const String:VELOCITY_ENTPROP[]					= "m_vecVelocity";

// ===========================================
// Witch Setup
// ===========================================

// =================================
// Assimilation
// =================================

//Bools
new bool:isAssimilation = false;

//Handles
new Handle:cvarAssimilation;

// =================================
// Death Helmet
// =================================

//Bools
new bool:isDeathHelmet = false;

//Handles
new Handle:cvarDeathHelmet;
new Handle:cvarDeathHelmetAmount;

//Strings
new hitgroup[4097];

// =================================
// Leeching Claw
// =================================

//Bools
new bool:isLeechingClaw = false;

//Handles
new Handle:cvarLeechingClaw;
new Handle:cvarLeechingClawAmount;

// =================================
// Mood Swing
// =================================

//Bools
new bool:isMoodSwing = false;

//Handles
new Handle:cvarMoodSwing;
new Handle:cvarMoodSwingHPMin;
new Handle:cvarMoodSwingHPMax;
new Handle:cvarMoodSwingSpeedMin;
new Handle:cvarMoodSwingSpeedMax;

// =================================
// Nightmare Claw
// =================================

//Bools
new bool:isNightmareClaw = false;

//Handles
new Handle:cvarNightmareClaw;
new Handle:cvarNightmareClawType;

//Strings
new HeartSound[MAXPLAYERS+1];

// =================================
// Psychotic Charge
// =================================

//Bools
new bool:isPsychoticCharge = false;
new bool:isPsychoticWitch[4097] = false;

//Handles
new Handle:cvarPsychoticCharge;
new Handle:cvarPsychoticChargeDamage;
new Handle:cvarPsychoticChargePower;
new Handle:cvarPsychoticChargeRange;
new Handle:cvarPsychoticChargeTimer[4097] = INVALID_HANDLE;

// =================================
// Shameful Cloak
// =================================

//Bools
new bool:isShamefulCloak = false;

//Handles
new Handle:cvarShamefulCloak;
new Handle:cvarShamefulCloakChance;
new Handle:cvarShamefulCloakVisibility;

// =================================
// Slashing Wind
// =================================

//Bools
new bool:isSlashingWind = false;

//Handles
new Handle:cvarSlashingWind;
new Handle:cvarSlashingWindDamage;
new Handle:cvarSlashingWindRange;

// =================================
// Sorrowful Remorse
// =================================

//Bools
new bool:isSorrowfulRemorse = false;

//Handles
new Handle:cvarSorrowfulRemorse;

// =================================
// Support Group
// =================================

//Bools
new bool:isSupportGroup = false;

//Handles
new Handle:cvarSupportGroup;

// =================================
// Unrelenting Spirit
// =================================

//Bools
new bool:isUnrelentingSpirit = false;

//Handles
new Handle:cvarUnrelentingSpirit;
new Handle:cvarUnrelentingSpiritAmount;

// ===========================================
// Generic Setup
// ===========================================

//Bools
new bool:isMapRunning = false;

//Handles
new Handle:PluginStartTimer = INVALID_HANDLE;
static Handle:sdkCallFling			 = 	INVALID_HANDLE;
static Handle:sdkOnStaggered         =  INVALID_HANDLE;

// ===========================================
// Plugin Info
// ===========================================

public Plugin:myinfo = 
{
    name = "[L4D2] Psychotic Witch",
    author = "Mortiegama",
    description = "Brining a new meaning of fear to the most dangerous infected.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2107926#post2107926"
}

	//Special Thanks:
	//AtomicStryker - Boomer Bit** Slap:
	//https://forums.alliedmods.net/showthread.php?t=97952
	
	//AtomicStryker - Damage Mod (SDK Hooks):
	//https://forums.alliedmods.net/showthread.php?p=1184761
	
// ===========================================
// Plugin Start
// ===========================================

public OnPluginStart()
{
	CreateConVar("l4d_pwm_version", PLUGIN_VERSION, "Pscyhotic Witch Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);

	// ======================================
	// Witch Ability: Assimilation
	// ======================================
	cvarAssimilation = CreateConVar("l4d_pwm_assimilation", "1", "Enables Assimilation Ability: When a Survivor is killed by the Witch, she raises them in her image, creating another Witch. (Def 1)");
	
	// ======================================
	// Witch Ability: Death Helmet
	// ======================================
	cvarDeathHelmet = CreateConVar("l4d_pwm_deathhelmet", "1", "Enables Death Helmet Ability: The Witch places a hollowed out propane tank on her head to reduce damage to her brain. (Def 1)");
	cvarDeathHelmetAmount = CreateConVar("l4d_pwm_deathhelmetamount", "0.3", "Percentage that damage to Witch's head is reduced. (Def 0.3)");

	// ======================================
	// Witch Ability: Leeching Claw
	// ======================================
	cvarLeechingClaw = CreateConVar("l4d_pwm_leechingclaw", "1", "Enables Leeching Claw ability: When the Witch incaps a Survivor, she heals herself with some of their stolen life force. (Def 1)");
	cvarLeechingClawAmount = CreateConVar("l4d_pwm_leechingclawamount", "500", "Amount of health to restore to the Witch after Leeching Claw. (Def 500)");

	// ======================================
	// Witch Ability: Mood Swing
	// ======================================
	cvarMoodSwing= CreateConVar("l4d_pwm_moodswing", "1", "Enables Mood Swing ability: With her mood changes, the Witch also has a varied health and speed factor. (Def 1)");
	cvarMoodSwingHPMin= CreateConVar("l4d_pwm_moodswinghpmin", "1000", "Minimum HP for the Witch. (Def 1000)");
	cvarMoodSwingHPMax= CreateConVar("l4d_pwm_moodswinghpmax", "2000", "Maximum HP for the Witch. (Def 2000)");
	cvarMoodSwingSpeedMin= CreateConVar("l4d_pwm_moodswingspeedmin", "0.8", "Minimum speed adjustment for the Witch. (Def 0.8)");
	cvarMoodSwingSpeedMax= CreateConVar("l4d_pwm_moodswingspeedmax", "1.6", "Maximum speed adjustment for the Witch. (Def 1.6)");
	
	// ======================================
	// Witch Ability: Nightmare Claw
	// ======================================
	cvarNightmareClaw = CreateConVar("l4d_pwm_nightmareclaw", "1", "Enables Nightmare Claw ability: When incapped by an enraged Witch the Survivor is either set to B&W or killed. (Def 1)");
	cvarNightmareClawType = CreateConVar("l4d_pwm_nightmareclawtype", "1", "Type of Nightmare Claw: 1 = Survivor is set to B&W, 2 = Survivor is killed.", FCVAR_PLUGIN, true, 1.0, true, 2.0);

	// ======================================
	// Witch Ability: Psychotic Charge
	// ======================================
	cvarPsychoticCharge = CreateConVar("l4d_pwm_psychoticcharge", "1", "Enables Psychotic Charge ability: The Witch will knock back any Survivors in her path while pursuing her victim. (Def 1)");
	cvarPsychoticChargeDamage = CreateConVar("l4d_pwm_psychoticchargedamage", "10", "Amount of damage the Witch causes when she hits a Survivor. (Def 10)");
	cvarPsychoticChargePower = CreateConVar("l4d_pwm_psychoticchargepower", "300", "Power a Survivor is hit with during Psychotic Charge. (Def 300)");
	cvarPsychoticChargeRange = CreateConVar("l4d_pwm_psychoticchargerange", "200", "How close a Survivor has to be to be hit by the Psychotic Charge. (Def 200)");

	// ======================================
	// Witch Ability: Shameful Cloak
	// ======================================
	cvarShamefulCloak = CreateConVar("l4d_pwm_shamefulcloak", "1", "Enables Shameful Cloak ability: Distraught by what she has become, the Witch will try to hide her form from the world. (Def 1)");
	cvarShamefulCloakChance = CreateConVar("l4d_pwm_shamefulcloakchance", "20", "Chance the Witch will use Shameful Cloak when spawned. (Def 20)");
	cvarShamefulCloakVisibility = CreateConVar("l4d_pwm_shamefulcloakvisibility", "0", "Modifies the visibility of the Witch while using Shameful Cloak. (0-255) (Def 0)", FCVAR_PLUGIN, true, 0.0, true, 255.0);

	// ======================================
	// Witch Ability: Slashing Wind
	// ======================================
	cvarSlashingWind = CreateConVar("l4d_pwm_slashingwind", "1", "Enables Slashing Wind ability: When the Witch incaps a Survivor it sends out a shockwave damaging and knocking back all Survivors. (Def 1)");
	cvarSlashingWindDamage = CreateConVar("l4d_pwm_slashingwinddamage", "5", "Amount of damage the Witch caused to Survivors within Slashing Wind range. (Def 5)");
	cvarSlashingWindRange = CreateConVar("l4d_pwm_slashingwindrange", "500", "How close a Survivor has to be to be hit by the Slashing Wind. (Def 600)");

	// ======================================
	// Witch Ability: Sorrowful Remorse
	// ======================================
	cvarSorrowfulRemorse = CreateConVar("l4d_pwm_sorrowfulremorse", "0", "Enables Sorrowful Remorse ability: When a Witch is killed, she leaves behind a Medkit and Defib as repetance for her actions. (Def 0)");

	// ======================================
	// Witch Ability: Support Group
	// ======================================
	cvarSupportGroup = CreateConVar("l4d_pwm_supportgroup", "1", "Enables Support Group ability: When the Witch is angered, her hateful shriek calls down a panic event. (Def 1)");
	
	// ======================================
	// Witch Ability: Unrelenting Spirit
	// ======================================
	cvarUnrelentingSpirit = CreateConVar("l4d_pwm_unrelentingspirit", "1", "Enables Unrelenting Spirit ability: The Witch's spirit allows her to keep attacking despite damage. (Def 1)");
	cvarUnrelentingSpiritAmount = CreateConVar("l4d_pwm_unrelentingspiritamount", "0.7", "Percent of damage to the Witch reduced by Unrelenting Spirit. (Def 0.7)");
	
	// ======================================
	// Hook Events
	// ======================================
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("player_incapacitated", Event_PlayerIncapped);
	HookEvent("witch_harasser_set", Event_WitchHarasserSet);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("player_death", Event_PlayerDeath);
	
	AutoExecConfig(true, "plugin.L4D2.PsychoticWitch");
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
	
	new Handle:ConfigFile = LoadGameConfigFile(GAMEDATA_FILENAME);
	
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
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer::OnStaggered");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	sdkOnStaggered = EndPrepSDKCall();
	if (sdkOnStaggered == INVALID_HANDLE)
	{
		SetFailState("Unable to find the \"CTerrorPlayer::OnStaggered(CBaseEntity *, Vector  const*)\" signature, check the file version!");
	}
	
	CloseHandle(ConfigFile);
}

// ===========================================
// Plugin Start Delayed
// ===========================================

public Action:OnPluginStart_Delayed(Handle:timer)
{	
	if (GetConVarInt(cvarAssimilation))
	{
		isAssimilation = true;
	}
	
	if (GetConVarInt(cvarDeathHelmet))
	{
		isDeathHelmet = true;
	}

	if (GetConVarInt(cvarLeechingClaw))
	{
		isLeechingClaw = true;
	}

	if (GetConVarInt(cvarMoodSwing))
	{
		isMoodSwing = true;
	}

	if (GetConVarInt(cvarNightmareClaw))
	{
		isNightmareClaw = true;
	}
	
	if (GetConVarInt(cvarPsychoticCharge))
	{
		isPsychoticCharge = true;
	}
	
	if (GetConVarInt(cvarShamefulCloak))
	{
		isShamefulCloak = true;
	}
	
	if (GetConVarInt(cvarSlashingWind))
	{
		isSlashingWind = true;
	}
	
	if (GetConVarInt(cvarSorrowfulRemorse))
	{
		isSorrowfulRemorse = true;
	}
	
	if (GetConVarInt(cvarSupportGroup))
	{
		isSupportGroup = true;
	}
	
	if (GetConVarInt(cvarUnrelentingSpirit))
	{
		isUnrelentingSpirit = true;
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
// ===========================================            WITCH             =========================================== 
// ===========================================                              =========================================== 
// ====================================================================================================================

// ===========================================
// Witch Setup Events
// ===========================================

public OnMapStart()
{
	PrecacheModel(MODEL_PROPANE, true);
	isMapRunning = true;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!isMapRunning || IsServerProcessing() == false) return;
	
	if (IsValidWitch(entity))
	{
		CreateTimer(0.5, Timer_WitchSpawn, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_WitchSpawn(Handle:timer, any:ref)
{
	new witch = EntRefToEntIndex(ref);

	if(witch == INVALID_ENT_REFERENCE)
	{
		return Plugin_Stop;
	}
	
	if (!isMapRunning || IsServerProcessing() == false) return Plugin_Stop;
	
	// =====================================
	// Witch Ability: Death Helmet
	// =====================================
	if (isDeathHelmet)
	{
		WitchAbility_DeathHelmet(witch);
	}

	// =====================================
	// Witch Ability: Mood Swing
	// =====================================	
	if (isMoodSwing)
	{
		WitchAbility_MoodSwing(witch);
	}
	
	// =====================================
	// Witch Ability: Shameful Cloak
	// =====================================
	if (isShamefulCloak)
	{
		WitchAbility_ShamefulCloak(witch);
	}
	
	SDKHook(witch, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(witch, SDKHook_TraceAttack, OnHitPoint);
	
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!isMapRunning || IsServerProcessing() == false) return Plugin_Stop;
	
	if (IsValidWitch(victim) && IsValidClient(attacker) && GetClientTeam(attacker) == 2)
	{
		// =====================================
		// Witch Ability: Death Helmet
		// =====================================
		if (hitgroup[victim] == 1 && isDeathHelmet)
		{
			new Float:damagemod = GetConVarFloat(cvarDeathHelmetAmount);
			//PrintToChatAll("Head shot: %f damage times %f mod.", damage, damagemod);
			
			if (FloatCompare(damagemod, 1.0) != 0)
			{
				damage = damage * damagemod;
			}
		}

		// =====================================
		// Witch Ability: Unrelenting Spirit
		// =====================================
		if (hitgroup[victim] != 1 && isUnrelentingSpirit)
		{
			new Float:damagemod = GetConVarFloat(cvarUnrelentingSpiritAmount);
			//PrintToChatAll("Body shot: %f damage times %f mod.", damage, damagemod);
			if (FloatCompare(damagemod, 1.0) != 0)
			{
				damage = damage * damagemod;
			}
		}
	}

	return Plugin_Changed;
}

public Action:OnHitPoint(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup1)
{
	hitgroup[victim] = hitgroup1;
	
	return Plugin_Continue;
}

public Action:Event_WitchHarasserSet(Handle:event, const String:strName[], bool:DontBroadcast)
{
 	new harasser = GetClientOfUserId(GetEventInt(event, "userid"));  
	new witch =  GetEventInt(event, "witchid");
	
	decl String:classname[128];
	GetEdictClassname(witch, classname, 128);
	if (strcmp(classname, "terror_player_manager") == 0) return Plugin_Stop;
	if (strcmp(classname, "instanced_scripted_scene") == 0) return Plugin_Stop;
	
	if (IsValidWitch(witch)){isPsychoticWitch[witch] = true;}
	
	// =====================================
	// Witch Ability: Psychotic Charge
	// =====================================
	if (isPsychoticCharge)
	{
		WitchAbility_PsychoticCharge(harasser, witch);
	}
	
	// =====================================
	// Witch Ability: Support Group
	// =====================================
	if (isSupportGroup)
	{
		WitchAbility_SupportGroup(harasser);
	}
	
	return Plugin_Handled;
}

public Action:Event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"subject"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
		StopBeat(client);
	}
}

public Action:Event_PlayerIncapped(Handle:event, const String:strName[], bool:DontBroadcast)
{
 	new client = GetClientOfUserId(GetEventInt(event, "userid"));  
	new witch =  GetEventInt(event, "attackerentid");  
	
	if (IsValidWitch(witch)){isPsychoticWitch[witch] = false;}
	
	// =====================================
	// Witch Ability: Leeching Claw
	// =====================================	
	if (isLeechingClaw)
	{
		WitchAbility_LeechingClaw(client, witch);
	}
	
	// =====================================
	// Witch Ability: Nightmare Claw
	// =====================================
	if (isNightmareClaw)
	{
		WitchAbility_NightmareClaw(client, witch);
	}
		
	// =====================================
	// Witch Ability: Slashing Wind
	// =====================================
	if (isSlashingWind)
	{
		WitchAbility_SlashingWind(client, witch);
	}
}

public Action:Event_WitchKilled(Handle:event, const String:strName[], bool:DontBroadcast)
{
	new witch =  GetEventInt(event, "witchid");
	
	isPsychoticWitch[witch] = false;

	// =====================================
	// Witch Ability: Sorrowful Remorse
	// =====================================	
	if (isSorrowfulRemorse)
	{
		WitchAbility_SorrowfulRemorse(witch);
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:strName[], bool:DontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new witch =  GetEventInt(event, "attackerentid");
	
	// =====================================
	// Witch Ability: Assimilation
	// =====================================	
	if (isAssimilation)
	{
		WitchAbility_Assimilation(victim, witch);
	}
}




// ===========================================
// Witch Ability: Assimilation
// ===========================================
// Description: When a Survivor is killed by the Witch, she raises them in her image, creating another Witch.

public Action:WitchAbility_Assimilation(victim, witch)
{
	if (IsValidWitch(witch) && IsValidDeadClient(victim) && GetClientTeam(victim) == 2)
	{
		PrintToChatAll("Spawning a Witch!");
		new flags3 = GetCommandFlags("z_spawn_old");
		SetCommandFlags("z_spawn_old", flags3 & ~FCVAR_CHEAT);
		FakeClientCommand(victim, "%s %s", "z_spawn_old", "witch auto");  
		SetCommandFlags("z_spawn_old", flags3|FCVAR_CHEAT);
	}
}
	
	
	
	
// ===========================================
// Witch Ability: Death Helmet
// ===========================================
// Description: The Witch places a hollowed out propane tank on her head to reduce damage to her brain.

public Action:WitchAbility_DeathHelmet(witch)
{
	if (IsValidWitch(witch))
	{
		new propane = CreateEntityByName("prop_dynamic_override");
		SetEntityModel(propane, MODEL_PROPANE);
		DispatchSpawn(propane);
		SetEntPropFloat(propane, Prop_Data, "m_flModelScale", 0.60);

		new random = GetRandomInt(0, 1);
		if( random == 0 )
			SetEntityRenderColor(propane, 0, 0, 0, 255);
		
		// Parent attachment
		SetVariantString("!activator"); 
		AcceptEntityInput(propane, "SetParent", witch);
		SetVariantString("forward");
		AcceptEntityInput(propane, "SetParentAttachment");

		TeleportEntity(propane, Float:{ -5.0,-4.5,-2.0 }, Float:{ 110.0,-10.0,0.0 }, NULL_VECTOR);
	}
}




// ===========================================
// Witch Ability: Leeching Claw
// ===========================================
// Description: When the Witch incaps a Survivor, she heals herself with some of their stolen life force.

public Action:WitchAbility_LeechingClaw(client, witch)
{
	if (IsValidClient(client) && IsValidWitch(witch))
	{
		new iHPRegen = GetConVarInt(cvarLeechingClawAmount);
		new iHP = GetEntProp(witch, Prop_Data, "m_iHealth");
		new iMaxHP = GetEntProp(witch, Prop_Data, "m_iMaxHealth");
				
		//PrintToChatAll("%i and %i to %i.", iHP, iHPRegen, iMaxHP);
		if ((iHPRegen + iHP) <= iMaxHP)
		{
			SetEntProp(witch, Prop_Data, "m_iHealth", iHPRegen + iHP);
		}
		else if ((iHP < iMaxHP) && (iMaxHP < (iHPRegen + iHP)) )
		{
			SetEntProp(witch, Prop_Data, "m_iHealth", iMaxHP);
		}
	}
}




// ===========================================
// Witch Ability: Mood Swing
// ===========================================
// Description: With her mood changes, the Witch also has a varied health and speed factor.

public Action:WitchAbility_MoodSwing(witch)
{
	if (IsValidWitch(witch))
	{
		new wHPMin = GetConVarInt(cvarMoodSwingHPMin);
		new wHPMax = GetConVarInt(cvarMoodSwingHPMax);
		new wHP = GetRandomInt(wHPMin, wHPMax);
		SetEntProp(witch, Prop_Data, "m_iMaxHealth", wHP);//Set max and 
		SetEntProp(witch, Prop_Data, "m_iHealth", wHP); //current health of witch to defined health.
		
		new Float:wSpeedMin = GetConVarFloat(cvarMoodSwingSpeedMin);
		new Float:wSpeedMax = GetConVarFloat(cvarMoodSwingSpeedMax);
		new Float:wSpeed = GetRandomFloat(wSpeedMin, wSpeedMax);
		AcceptEntityInput(witch, "Disable"); 
		SetEntPropFloat(witch, Prop_Data, "m_flSpeed", 1.0*wSpeed);
		AcceptEntityInput(witch, "Enable");
	}
}




// ===========================================
// Witch Ability: Nightmare Claw
// ===========================================
// Description: When incapped by an enraged Witch the Survivor is either set to B&W or killed.

public Action:WitchAbility_NightmareClaw(client, witch)
{
	if (IsValidWitch(witch) && IsValidClient(client))
	{
		new ClawType = GetConVarInt(cvarNightmareClawType);
		
		if (ClawType == 1) 
		{
			new revivemax = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
			SetEntProp(client, Prop_Send, "m_currentReviveCount", revivemax);
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
			EmitSoundToClient(client, "player/heartbeatloop.wav");
			HeartSound[client] = 1;
		}
		
		if (ClawType == 2) 
		{
			ForcePlayerSuicide(client);
			
			if (isAssimilation)
			{
				WitchAbility_Assimilation(client, witch);
			}
		}
	}
}




// ===========================================
// Witch Ability: Psychotic Charge
// ===========================================
// Description: The Witch will knock back any Survivors in her path while pursuing her victim.

public Action:WitchAbility_PsychoticCharge(harasser, witch)
{
	new Handle:dataPack = CreateDataPack();
	cvarPsychoticChargeTimer[witch] = CreateDataTimer(2.0, Timer_PsychoticCharge, dataPack, TIMER_REPEAT);
	WritePackCell(dataPack, harasser);
	WritePackCell(dataPack, witch);
}

public Action:Timer_PsychoticCharge(Handle:timer, any:dataPack)
{
	ResetPack(dataPack);
	new harasser = ReadPackCell(dataPack);
	new witch = ReadPackCell(dataPack);
	
	if (!isPsychoticWitch[witch])
	{
		if (cvarPsychoticChargeTimer[witch] != INVALID_HANDLE)
		{
			KillTimer(cvarPsychoticChargeTimer[witch]);
			cvarPsychoticChargeTimer[witch] = INVALID_HANDLE;
		}	
		
		return Plugin_Stop;
	}
	
	if (IsValidWitch(witch))
	{
		if (IsValidClient(harasser) && GetClientTeam(harasser) == 2)
		{
			for (new victim=1; victim<=MaxClients; victim++)
			
			if (victim != harasser && IsValidClient(victim) && GetClientTeam(victim) == 2)
			{
				decl Float:witchPos[3];
				decl Float:survivorPos[3];
				decl Float:distance;
				new Float:range = GetConVarFloat(cvarPsychoticChargeRange);
				GetEntPropVector(witch, Prop_Send, "m_vecOrigin", witchPos);
				GetClientEyePosition(victim, survivorPos);
				distance = GetVectorDistance(survivorPos, witchPos);
										
				if (distance < range)
				{
					decl String:sRadius[256];
					decl String:sPower[256];
					new magnitude = GetConVarInt(cvarPsychoticChargePower);
					IntToString(GetConVarInt(cvarPsychoticChargeRange), sRadius, sizeof(sRadius));
					IntToString(magnitude, sPower, sizeof(sPower));
					new exPhys = CreateEntityByName("env_physexplosion");
			
					//Set up physics movement explosion
					DispatchKeyValue(exPhys, "radius", sRadius);
					DispatchKeyValue(exPhys, "magnitude", sPower);
					DispatchSpawn(exPhys);
					TeleportEntity(exPhys, witchPos, NULL_VECTOR, NULL_VECTOR);
							
					//BOOM!
					AcceptEntityInput(exPhys, "Explode");
			
					decl Float:traceVec[3], Float:resultingVec[3], Float:currentVelVec[3];
					new Float:power = GetConVarFloat(cvarPsychoticChargePower);
					MakeVectorFromPoints(witchPos, survivorPos, traceVec);				// draw a line from car to Survivor
					GetVectorAngles(traceVec, resultingVec);							// get the angles of that line
							
					resultingVec[0] = Cosine(DegToRad(resultingVec[1])) * power;	// use trigonometric magic
					resultingVec[1] = Sine(DegToRad(resultingVec[1])) * power;
					resultingVec[2] = power * SLAP_VERTICAL_MULTIPLIER;
						
					GetEntPropVector(victim, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
					resultingVec[0] += currentVelVec[0];
					resultingVec[1] += currentVelVec[1];
					resultingVec[2] += currentVelVec[2];
					
					new damage = GetConVarInt(cvarPsychoticChargeDamage);
					DamageHook(victim, witch, damage);
				
					new Float:incaptime = 3.0;
					SDKCall(sdkCallFling, victim, resultingVec, 76, harasser, incaptime); //76 is the 'got bounced' animation in L4D2
				}
			}
		}
	}
	
	return Plugin_Continue;
}




// ===========================================
// Witch Ability: Shameful Cloak
// ===========================================
// Description: Distraught by what she has become, the Witch will try to hide her form from the world.

public Action:WitchAbility_ShamefulCloak(witch)
{
	if (IsValidWitch(witch))
	{
		new ShamefulCloakChance = GetRandomInt(0, 99);
		new ShamefulCloakPercent = (GetConVarInt(cvarShamefulCloakChance));
		
		if (ShamefulCloakChance < ShamefulCloakPercent)
		{
			new Opacity = GetConVarInt(cvarShamefulCloakVisibility);
			SetEntityRenderFx(witch, RENDERFX_HOLOGRAM);
			SetEntityRenderColor(witch, 255, 255, 255, Opacity);
		}
	}
}




// ===========================================
// Witch Ability: Slashing Wind
// ===========================================
// Description: When the Witch incaps a Survivor it sends out a shockwave damaging and knocking back all Survivors.

public Action:WitchAbility_SlashingWind(client, witch)
{
	for (new victim=1; victim<=MaxClients; victim++)
		
	if (victim != client && IsValidClient(victim) && GetClientTeam(victim) == 2)
	{
		decl Float:witchPos[3];
		decl Float:survivorPos[3];
		decl Float:distance;
		new Float:range = GetConVarFloat(cvarSlashingWindRange);
		GetEntPropVector(witch, Prop_Send, "m_vecOrigin", witchPos);
		GetClientEyePosition(victim, survivorPos);
		distance = GetVectorDistance(survivorPos, witchPos);
								
		if (distance < range)
		{
			new Float:vecOrigin[3];
			GetClientAbsOrigin(client, vecOrigin);
			SDKCall(sdkOnStaggered, victim, client, witchPos); 
			
			new damage = GetConVarInt(cvarSlashingWindDamage);
			DamageHook(victim, witch, damage);
		}
	}
}




// ===========================================
// Witch Ability: Sorrowful Remorse
// ===========================================
// Description: When a Witch is killed, she leaves behind a Medkit and Defib as repetance for her actions.

public Action:WitchAbility_SorrowfulRemorse(witch)
{
	decl Float:entityPos[3], Float:entityAng[3];
	new item1 = CreateEntityByName("weapon_first_aid_kit");
	new item2 = CreateEntityByName("weapon_defibrillator"); 
	GetEntPropVector(witch, Prop_Send, "m_vecOrigin", entityPos);
	GetEntPropVector(witch, Prop_Send, "m_angRotation", entityAng);
	
	if (item1 != -1)
	{
		TeleportEntity(item1, entityPos, entityAng, NULL_VECTOR );
		DispatchSpawn(item1);
	}
	
	if (item2 != -1)
	{
		TeleportEntity(item2, entityPos, entityAng, NULL_VECTOR );
		DispatchSpawn(item2);
	}
}




// ===========================================
// Witch Ability: Support Group
// ===========================================
// Description: When the Witch is angered, her hateful shriek calls down a panic event.

public Action:WitchAbility_SupportGroup(harasser)
{
	new flags = GetCommandFlags("z_spawn_old");
	SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
	FakeClientCommand(harasser,"z_spawn_old mob auto");
	SetCommandFlags("z_spawn_old", flags|FCVAR_CHEAT);
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
	SDKCall(sdkCallFling, victim, resulting, 76, attacker, incaptime); //76 is the 'got bounced' animation in L4D2
}

StopBeat(client)
{
	if (HeartSound[client])
	{
		StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
		HeartSound[client] = 0;
	}
}

public OnMapEnd()
{
	isMapRunning = false;
}




// ====================================================================================================================
// ===========================================                              =========================================== 
// ===========================================          BOOL CALLS          =========================================== 
// ===========================================                              =========================================== 
// ====================================================================================================================

IsValidWitch(witch)
{
	if(witch> 32 && IsValidEdict(witch) && IsValidEntity(witch))
	{
		decl String:classname[32];
		GetEdictClassname(witch, classname, sizeof(classname));
		if(StrEqual(classname, "witch"))
		{
			return true;
		}
	}
	
	return false;
}

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