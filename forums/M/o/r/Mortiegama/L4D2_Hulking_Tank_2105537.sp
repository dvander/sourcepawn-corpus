#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define L4D2 Hulking Tank
#define PLUGIN_VERSION "1.11"

#define STRING_LENGHT								56
#define ZOMBIECLASS_TANK 					    	8

static const String:GAMEDATA_FILENAME[]				= "l4d2addresses";
static const Float:SLAP_VERTICAL_MULTIPLIER			= 1.5;
static laggedMovementOffset 						= 0;
static frustrationOffset							= 0;
static aiTank;

new Handle:cvarBurningRage;
new Handle:cvarBurningRageFist;
new Handle:cvarBurningRageDamage;
new Handle:cvarBurningRageSpeed;

new Handle:cvarHibernation;
new Handle:cvarHibernationCooldown;
new Handle:cvarHibernationDamage;
new Handle:cvarHibernationDuration;
new Handle:cvarHibernationRegen;
new Handle:cvarHibernationTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:cvarHibernationCooldownTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:cvarPhantomTank;
new Handle:cvarPhantomTankDuration;
new Handle:cvarPhantomTankTimer;
new Handle:cvarPhantomTankTimerAI;

new Handle:cvarSmoulderingEarth;
new Handle:cvarSmoulderingEarthDamage;
new Handle:cvarSmoulderingEarthRange;
new Handle:cvarSmoulderingEarthPower;
new Handle:cvarSmoulderingEarthType;

new Handle:cvarTitanFist;
new Handle:cvarTitanFistIncap;
new Handle:cvarTitanFistCooldown;
new Handle:cvarTitanFistDamage;
new Handle:cvarTitanFistPower;
new Handle:cvarTitanFistRange;

new Handle:cvarTitanicBellow;
new Handle:cvarTitanicBellowCooldown;
new Handle:cvarTitanicBellowHealth;
new Handle:cvarTitanicBellowPower;
new Handle:cvarTitanicBellowDamage;
new Handle:cvarTitanicBellowRange;
new Handle:cvarTitanicBellowType;

new Handle:PluginStartTimer = INVALID_HANDLE;
new Handle:cvarResetDelayTimer[MAXPLAYERS+1];

new bool:isBurningRage = false;
new bool:isBurningRageFist = false;
new bool:isFrustrated = false;
new bool:isHibernation = false;
new bool:isPhantomTank = false;
new bool:isSmoulderingEarth = false;
new bool:isTitanFist = false;
new bool:isTitanFistIncap = false;
new bool:isTitanicBellow = false;
new bool:isHibernating[MAXPLAYERS+1] = false;
new bool:isHibernationCooldown[MAXPLAYERS+1] = false;
new bool:buttondelay[MAXPLAYERS+1] = false;
new bool:isMapRunning = false;

new Float:cooldownTitanFist[MAXPLAYERS+1] = 0.0;
new Float:cooldownTitanicBellow[MAXPLAYERS+1] = 0.0;

public Plugin:myinfo = 
{
    name = "[L4D2] Hulking Tank",
    author = "Mortiegama",
    description = "Brings a set of psychotic abilities to the Hulking Tank.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2105537#post2105537"
}

	//Special Thanks:
	//Karma - Tank Skill Roar
	//https://forums.alliedmods.net/showthread.php?t=126919
	
	//panxiaohai - Tank's Burning Rock
	//https://forums.alliedmods.net/showthread.php?t=139691
	
public OnPluginStart()
{
	CreateConVar("l4d_htm_version", PLUGIN_VERSION, "Hulking Tank Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarBurningRage = CreateConVar("l4d_htm_burningrage", "1", "Enables the Burning Rage ability, Tank's movement speed increases when on fire. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBurningRageFist = CreateConVar("l4d_htm_burningragefist", "1", "Enables the Burning Rage Fist ability, Tank deals extra damage when on fire. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBurningRageSpeed = CreateConVar("l4d_htm_burningragespeed", "1.25", "How much of a speed boost does Burning Rage give. (Def 1.25)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBurningRageDamage = CreateConVar("l4d_htm_burningragedamage", "3", "Amount of extra damage done to Survivors while Tank is on fire. (Def 3)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarHibernation = CreateConVar("l4d_htm_hibernation", "1", "Enables the Hibernation ability, Tank stops to hibernate and will regenerate health while taking extra damage. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarHibernationCooldown = CreateConVar("l4d_htm_hibernationcooldown", "120", "Amount of time before the Tank can Hibernate again. (Def 120)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarHibernationDamage = CreateConVar("l4d_htm_hibernationdamage", "2.0", "Multiplier for damage received by Tank while Hibernating. (Def 2.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarHibernationDuration = CreateConVar("l4d_htm_hibernationduration", "10.0", "Amount of time the Hibernation will take before completion. (Def 10.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarHibernationRegen = CreateConVar("l4d_htm_hibernationregen", "6000.0", "Amount of health the Tank will be set to once done Hibernating. (Def 6000.0)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarPhantomTank = CreateConVar("l4d_htm_phantomtank", "1", "Enables the Phanton Tank ability, when spawning the Tank will be immune to damage and fire until a player takes control. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarPhantomTankDuration = CreateConVar("l4d_htm_phantomtankduration", "3.0", "Amount of time after a player takes control of the Tank that the damage and fire immunity ends. (Def 3.0)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarSmoulderingEarth = CreateConVar("l4d_htm_SmoulderingEarth", "1", "Enables the Smouldering Earth ability, Tank is able to throw a burning rock that explodes when hitting the ground. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSmoulderingEarthDamage = CreateConVar("l4d_htm_smoulderingearthdamage", "7", "Damage the exploding rock causes nearby Survivors. (Def 7)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSmoulderingEarthRange = CreateConVar("l4d_htm_smoulderingearthrange", "300.0", "Area around the exploding rock that will reach Survivors. (Def 300.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSmoulderingEarthPower = CreateConVar("l4d_htm_smoulderingearthpower", "200.0", "Amount of power behind the explosion. (Def 200.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSmoulderingEarthType = CreateConVar("l4d_htm_smoulderingearthtype", "2", "Type of rock thrown, 1 = Rock is always on fire, 2 = Rock only on fire if Tank is on fire.", FCVAR_PLUGIN, true, 1.0, true, 2.0);

	cvarTitanFist = CreateConVar("l4d_htm_titanfist", "1", "Enables the Titan Fist ability, Tank is able to send out shockwaves through the air with its fist. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanFistIncap = CreateConVar("l4d_htm_titanfistincap", "1", "Enables the Titan Fist Incap ability, if a Survivor is incapped by the Tank punch they will still be flung. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanFistCooldown = CreateConVar("l4d_htm_titanfistcooldown", "15", "Amount of time before the Tank can send another Titan Fist shockwave. (Def 15)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanFistDamage = CreateConVar("l4d_htm_titanfistdamage", "5", "Amount of damage done to Survivors hit by the Titan Fist shockwave. (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanFistPower = CreateConVar("l4d_htm_titanfistpower", "200.0", "Force behind the Titan Fist shockwave. (Def 200.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanFistRange = CreateConVar("l4d_htm_titanfistrange", "700.0", "Distance the Titan Fist shockwave will travel. (Def 700.0)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarTitanicBellow = CreateConVar("l4d_htm_titanicbellow", "1", "Enables the Titanic Bellow ability, Tank is able to roar and send nearby Survivors flying or pull them to the Tank. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanicBellowCooldown = CreateConVar("l4d_htm_titanicbellowcooldown", "5.0", "Amount of time between Titanic Bellows. (Def 5.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanicBellowHealth = CreateConVar("l4d_htm_titanicbellowhealth", "0", "Amount of health the Tank must be at (or below) to use Titanic Belllow (0 = disabled). (Def 0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanicBellowPower = CreateConVar("l4d_htm_titanicbellowpower", "300.0", "Power behind the inner range of Methane Blast. (Def 300.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanicBellowDamage = CreateConVar("l4d_htm_titanicbellowdamage", "10", "Damage the force of the roar causes to nearby survivors. (Def 10)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanicBellowRange = CreateConVar("l4d_htm_titanicbellowrange", "700.0", "Area around the Tank the bellow will reach. (Def 700.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanicBellowType = CreateConVar("l4d_htm_titanicbellowtype", "1", "Type of roar, 1 = Survivors are pushed away from Tank, 2 = Survivors are pulled towards Tank.", FCVAR_PLUGIN, true, 1.0, true, 2.0);

	HookEvent("player_incapacitated", Event_PlayerIncap);
	HookEvent("tank_spawn", Event_TankSpawned);
	HookEvent("tank_frustrated", Event_TankFrustrated, EventHookMode_Pre);
	
	AutoExecConfig(true, "plugin.L4D2.HulkingTank");
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{	
	if (GetConVarInt(cvarBurningRage))
	{
		isBurningRage = true;
	}
	
	if (GetConVarInt(cvarBurningRageFist))
	{
		isBurningRageFist = true;
	}
	
	if (GetConVarInt(cvarHibernation))
	{
		isHibernation = true;
	}
	
	if (GetConVarInt(cvarPhantomTank))
	{
		isPhantomTank = true;
	}
	
	if (GetConVarInt(cvarSmoulderingEarth))
	{
		isSmoulderingEarth = true;
	}
	
	if (GetConVarInt(cvarTitanFist))
	{
		isTitanFist = true;
	}
	
	if (GetConVarInt(cvarTitanFistIncap))
	{
		isTitanFistIncap = true;
	}
	
	if (GetConVarInt(cvarTitanicBellow))
	{
		isTitanicBellow = true;
	}
	
	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	frustrationOffset = FindSendPropInfo("Tank","m_frustration");
	
	if(PluginStartTimer != INVALID_HANDLE)
	{
 		KillTimer(PluginStartTimer);
		PluginStartTimer = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public OnMapStart()
{
	PrecacheParticle("gas_explosion_pump");
	isMapRunning = true;
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:Event_TankSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new tank = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (isPhantomTank && IsValidClient(tank) && GetClientTeam(tank) == 3)
	{
		if (IsFakeClient(tank) && !isFrustrated)
		{
			SetEntityMoveType(tank, MOVETYPE_NONE);
			SetEntProp(tank, Prop_Data, "m_fFlags", GetEntProp(tank, Prop_Data, "m_fFlags") | FL_GODMODE);
			SetEntityRenderMode(tank, RENDER_TRANSCOLOR);
			SetEntityRenderColor(tank, 255, 255, 255, 0);
			cvarPhantomTankTimerAI = CreateTimer(6.0, Timer_PhantomTankAI);
			aiTank = tank;
		}
		
		if (!IsFakeClient(tank) && !isFrustrated)
		{
			SetEntityMoveType(tank, MOVETYPE_WALK);
			SetEntProp(tank, Prop_Data, "m_fFlags", GetEntProp(tank, Prop_Data, "m_fFlags") | FL_GODMODE);
			cvarPhantomTankTimer = CreateTimer(GetConVarFloat(cvarPhantomTankDuration), Timer_PhantomTank);
			aiTank = 0;
		}
	}
		
	isFrustrated = false;
}

public Action:Event_TankFrustrated(Handle:event, const String:name[], bool:dontBroadcast)
{
	isFrustrated = true;
}

public Action:Timer_PhantomTank(Handle:timer) //extinguishes  a tank, and resets it's health
{
	PhantomTankRemoval();
	
	if (cvarPhantomTankTimer != INVALID_HANDLE)
	{
		KillTimer(cvarPhantomTankTimer);
		cvarPhantomTankTimer = INVALID_HANDLE;
	}

	return Plugin_Stop;
}

public Action:Timer_PhantomTankAI(Handle:timer) //Thaws an AI tank, it will only fire after 5 seconds which means it was not passed to a player.  Either because of no player infected, or being passed to AI
{
	if (!aiTank || !IsValidTank(aiTank) || !IsFakeClient(aiTank))
	{
		aiTank = 0;
		return Plugin_Stop;
	}
	
	PhantomTankRemoval();
	aiTank = 0;
	
	if (IsValidTank(aiTank))
	{
		SetEntityMoveType(aiTank, MOVETYPE_WALK);
	}
	
	if (cvarPhantomTankTimerAI != INVALID_HANDLE)
	{
		KillTimer(cvarPhantomTankTimerAI);
		cvarPhantomTankTimerAI = INVALID_HANDLE;
	}	
	
	return Plugin_Stop;
}

static PhantomTankRemoval()
{
	for (new tank=1; tank<=MaxClients; tank++)
	{
		if (IsValidTank(tank))
		{
			SetEntityMoveType(aiTank, MOVETYPE_WALK);
			SetEntProp(tank, Prop_Data, "m_fFlags", GetEntProp(tank, Prop_Data, "m_fFlags") & ~FL_GODMODE);
			SetEntityRenderColor(tank, 255, 255, 255, 255);
			ExtinguishEntity(tank);
		}
	}
}


// ===========================================
// Tank Ability - Burning Rage
// ===========================================
// Description: When on fire the Tank can move faster and hit harder.

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidTank(victim))
	{
		if (isBurningRage)
		{
			if ((damagetype == 8 || damagetype == 2056 || damagetype == 268435464))
			{
				SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);

				PrintHintText(victim, "You're on fire, your Burning Rage has increased your speed!");
				SetEntDataFloat(victim, laggedMovementOffset, 1.0*GetConVarFloat(cvarBurningRageSpeed), true);
				
				return Plugin_Handled;
			}
		}
		
		if (isHibernating[victim])
		{
			new Float:damagemod = GetConVarFloat(cvarHibernationDamage);
						
			if (FloatCompare(damagemod, 1.0) != 0)
			{
				damage = damage * damagemod;
			}
		}
	}
	
	if (isBurningRageFist && IsValidTank(attacker))
	{
		if (IsPlayerOnFire(attacker) && IsValidClient(victim) && GetClientTeam(victim) == 2)
		{
			new Float:damagemod = GetConVarFloat(cvarBurningRageDamage);
						
			if (FloatCompare(damagemod, 1.0) != 0)
			{
				damage = damage + damagemod;
			}
		}
	}

	return Plugin_Changed;
}

public Action:Timer_Hibernation(Handle:timer, any:client)
{
	Reset_Hibernation(client);
	
	if (IsValidTank(client))
	{
		new TankHP = GetConVarInt(cvarHibernationRegen);
		SetEntProp(client, Prop_Send, "m_iHealth", TankHP, 1);
	}
	
	if (cvarHibernationTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarHibernationTimer[client]);
		cvarHibernationTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public Action:Timer_HibernationCooldown(Handle:timer, any:client)
{
	isHibernationCooldown[client] = false;
	
	if(cvarHibernationCooldownTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarHibernationCooldownTimer[client]);
		cvarHibernationCooldownTimer[client] = INVALID_HANDLE;
	}	

	return Plugin_Stop;	
}

public Reset_Hibernation(client)
{
	KillProgressBar(client);
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntData(client, frustrationOffset, 1);
	isHibernating[client] = false;
}

stock SetupProgressBar(client, Float:time)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
}

stock KillProgressBar(client)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
}				
				
// ===========================================
// Tank Ability - Titan Fist
// ===========================================
// Description: The Tank's swing will also hit any Survivors in range.

public Event_PlayerIncap(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new client = GetClientOfUserId(GetEventInt(event,"attacker"));
	
	decl String:weapon[16];
	GetEventString(event, "weapon", weapon, 16);
	if(!StrEqual(weapon, "tank_claw")){return;}
	
	if(isTitanFistIncap && IsValidTank(client) && !IsPlayerGhost(client))
	{
		if (IsValidClient(victim) && GetClientTeam(victim) == 2  && !IsSurvivorPinned(victim))
		{
			decl Float:tankPos[3];
			decl Float:survivorPos[3];
			GetClientEyePosition(client, tankPos);
			GetClientEyePosition(victim, survivorPos);

			decl String:sRadius[256];
			decl String:sPower[256];
			new magnitude = GetConVarInt(cvarTitanFistPower);
			IntToString(GetConVarInt(cvarTitanFistRange), sRadius, sizeof(sRadius));
			IntToString(magnitude, sPower, sizeof(sPower));
			new exPhys = CreateEntityByName("env_physexplosion");
	
			//Set up physics movement explosion
			DispatchKeyValue(exPhys, "radius", sRadius);
			DispatchKeyValue(exPhys, "magnitude", sPower);
			DispatchSpawn(exPhys);
			TeleportEntity(exPhys, tankPos, NULL_VECTOR, NULL_VECTOR);
					
			//BOOM!
			AcceptEntityInput(exPhys, "Explode");

			decl Float:traceVec[3], Float:resultingVec[3], Float:currentVelVec[3];
			new Float:power = GetConVarFloat(cvarTitanFistPower);
			MakeVectorFromPoints(tankPos, survivorPos, traceVec);				// draw a line from car to Survivor
			GetVectorAngles(traceVec, resultingVec);							// get the angles of that line
			
			resultingVec[0] = Cosine(DegToRad(resultingVec[1])) * power;	// use trigonometric magic
			resultingVec[1] = Sine(DegToRad(resultingVec[1])) * power;
			resultingVec[2] = power * SLAP_VERTICAL_MULTIPLIER;
			
			GetEntPropVector(victim, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
			resultingVec[0] += currentVelVec[0];
			resultingVec[1] += currentVelVec[1];
			resultingVec[2] += currentVelVec[2];
			
			Fling_TitanFist(victim, resultingVec, client);
		}
	}
}

// CTerrorPlayer::Fling(Vector  const&, PlayerAnimEvent_t, CBaseCombatCharacter *, float)
stock Fling_TitanFist(victim, Float:vector[3], attacker, Float:incaptime = 3.0)
{
	new Handle:MySDKCall = INVALID_HANDLE;
	new Handle:ConfigFile = LoadGameConfigFile(GAMEDATA_FILENAME);
	
	StartPrepSDKCall(SDKCall_Player);
	new bool:bFlingFuncLoaded = PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_Fling");
	if(!bFlingFuncLoaded)
	{
		LogError("Could not load the Fling signature");
	}
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);

	MySDKCall = EndPrepSDKCall();
	if(MySDKCall == INVALID_HANDLE)
	{
		LogError("Could not prep the Fling function");
	}
	
	SDKCall(MySDKCall, victim, vector, 76, attacker, incaptime); //76 is the 'got bounced' animation in L4D2
	Damage_TitanFist(attacker, victim);
}

public Action:Damage_TitanFist(attacker, victim)
{
	new damage = GetConVarInt(cvarTitanFistDamage);
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
	
	PrintHintText(attacker, "Your Titan Claw inflicted %i damage.", damage);
	PrintHintText(victim, "You were hit with Titan Claw, causing %i damage and sending you flying.", damage);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_ATTACK && IsValidTank(client) && !IsPlayerGhost(client))
	{
		if (isTitanFist && IsTitanFistReady(client) && !isHibernating[client])
		{
			cooldownTitanFist[client] = GetEngineTime();
			for (new victim=1; victim<=MaxClients; victim++)

			if (IsValidClient(victim) && GetClientTeam(victim) == 2  && !IsSurvivorPinned(victim))
			{
				decl Float:tankPos[3];
				decl Float:survivorPos[3];
				decl Float:distance;
				new Float:range = GetConVarFloat(cvarTitanFistRange);
				GetClientEyePosition(client, tankPos);
				GetClientEyePosition(victim, survivorPos);
				distance = GetVectorDistance(survivorPos, tankPos);
								
				if (distance < range)
				{
					decl String:sRadius[256];
					decl String:sPower[256];
					new magnitude = GetConVarInt(cvarTitanFistPower);
					IntToString(GetConVarInt(cvarTitanFistRange), sRadius, sizeof(sRadius));
					IntToString(magnitude, sPower, sizeof(sPower));
					new exPhys = CreateEntityByName("env_physexplosion");
	
					//Set up physics movement explosion
					DispatchKeyValue(exPhys, "radius", sRadius);
					DispatchKeyValue(exPhys, "magnitude", sPower);
					DispatchSpawn(exPhys);
					TeleportEntity(exPhys, tankPos, NULL_VECTOR, NULL_VECTOR);
					
					//BOOM!
					AcceptEntityInput(exPhys, "Explode");
	
					decl Float:traceVec[3], Float:resultingVec[3], Float:currentVelVec[3];
					new Float:power = GetConVarFloat(cvarTitanFistPower);
					MakeVectorFromPoints(tankPos, survivorPos, traceVec);				// draw a line from car to Survivor
					GetVectorAngles(traceVec, resultingVec);							// get the angles of that line
					
					resultingVec[0] = Cosine(DegToRad(resultingVec[1])) * power;	// use trigonometric magic
					resultingVec[1] = Sine(DegToRad(resultingVec[1])) * power;
					resultingVec[2] = power * SLAP_VERTICAL_MULTIPLIER;
					
					GetEntPropVector(victim, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
					resultingVec[0] += currentVelVec[0];
					resultingVec[1] += currentVelVec[1];
					resultingVec[2] += currentVelVec[2];
					
					Fling_TitanFist(victim, resultingVec, client);
				}
			}
		}
		
		if (isHibernating[client])
		{
			buttons &= ~IN_ATTACK;
		}
	}
	
	if(buttons & IN_ATTACK2 && IsValidTank(client) && isHibernating[client])
	{
		buttons &= ~IN_ATTACK2;
	}
	
	if (buttons & IN_ATTACK2 && aiTank && client == aiTank && IsFakeClient(aiTank) && IsValidTank(aiTank))
	{
		buttons &= ~IN_ATTACK2;
	}
	
	if ((buttons & IN_ZOOM) && IsValidTank(client) && !IsPlayerGhost(client) && !isHibernating[client]) 
	{
		if (isTitanicBellow && IsTitanicBellowReady(client) && !isHibernating[client])
		{
			new ReqHP = GetConVarInt(cvarTitanicBellowHealth);
			new HP = GetClientHealth(client);
			
			if (ReqHP > 0 && HP > ReqHP)
			{
			PrintHintText(client, "Your health must be below %i before you can use Titanic Bellow.", ReqHP);
			return;
			}
			
			cooldownTitanicBellow[client] = GetEngineTime();			
			for (new victim=1; victim<=MaxClients; victim++)

			if (IsValidClient(victim) && GetClientTeam(victim) == 2  && !IsSurvivorPinned(victim))
			{
				decl Float:tankPos[3];
				decl Float:survivorPos[3];
				decl Float:distance;
				new Float:range = GetConVarFloat(cvarTitanicBellowRange);
				GetClientEyePosition(client, tankPos);
				GetClientEyePosition(victim, survivorPos);
				distance = GetVectorDistance(survivorPos, tankPos);
								
				if (distance < range)
				{
					decl String:sRadius[256];
					decl String:sPower[256];
					new RoarType = GetConVarInt(cvarTitanicBellowType);
					new magnitude;
					if (RoarType == 1) magnitude = GetConVarInt(cvarTitanicBellowPower);
					if (RoarType == 2) magnitude = GetConVarInt(cvarTitanicBellowPower) * -1;
					IntToString(GetConVarInt(cvarTitanicBellowRange), sRadius, sizeof(sRadius));
					IntToString(magnitude, sPower, sizeof(sPower));
					new exPhys = CreateEntityByName("env_physexplosion");
	
					//Set up physics movement explosion
					DispatchKeyValue(exPhys, "radius", sRadius);
					DispatchKeyValue(exPhys, "magnitude", sPower);
					DispatchSpawn(exPhys);
					TeleportEntity(exPhys, tankPos, NULL_VECTOR, NULL_VECTOR);
					
					//BOOM!
					AcceptEntityInput(exPhys, "Explode");
	
					decl Float:traceVec[3], Float:resultingVec[3], Float:currentVelVec[3];
					new Float:power = GetConVarFloat(cvarTitanicBellowPower);
					MakeVectorFromPoints(tankPos, survivorPos, traceVec);				// draw a line from car to Survivor
					GetVectorAngles(traceVec, resultingVec);							// get the angles of that line
					
					resultingVec[0] = Cosine(DegToRad(resultingVec[1])) * power;	// use trigonometric magic
					resultingVec[1] = Sine(DegToRad(resultingVec[1])) * power;
					resultingVec[2] = power * SLAP_VERTICAL_MULTIPLIER;
					
					GetEntPropVector(victim, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
					resultingVec[0] += currentVelVec[0];
					resultingVec[1] += currentVelVec[1];
					resultingVec[2] += currentVelVec[2];
					
					if (RoarType == 2)
					{
						resultingVec[0] = resultingVec[0] * -1;
						resultingVec[1] = resultingVec[1] * -1;
					}
					
					Fling_TitanicBellow(victim, resultingVec, client);
				}
			}
		}
	}
	
	if(buttons & IN_USE && isHibernation)
	{
		if (IsValidTank(client) && !isHibernating[client] && !buttondelay[client] && !isHibernationCooldown[client])
		{
			isHibernating[client] = true;
			isHibernationCooldown[client] = true;
			buttondelay[client] = true;
			
			SetEntityMoveType(client, MOVETYPE_NONE);
			SetEntData(client, frustrationOffset, 0);
			SetupProgressBar(client, GetConVarFloat(cvarHibernationDuration));
					
			cvarHibernationCooldownTimer[client] = CreateTimer(GetConVarFloat(cvarHibernationCooldown), Timer_HibernationCooldown, client);
			cvarHibernationTimer[client] = CreateTimer(GetConVarFloat(cvarHibernationDuration), Timer_Hibernation, client);
			cvarResetDelayTimer[client] = CreateTimer(1.0, ResetDelay, client);
			
			PrintHintText(client, "You are Hibernating.");
		}
		
		if (IsValidTank(client) && isHibernating[client] && !buttondelay[client])
		{
			Reset_Hibernation(client);
			buttondelay[client] = true;
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

stock Fling_TitanicBellow(target, Float:vector[3], attacker, Float:incaptime = 3.0)
{
	new Handle:MySDKCall = INVALID_HANDLE;
	new Handle:ConfigFile = LoadGameConfigFile(GAMEDATA_FILENAME);
	
	StartPrepSDKCall(SDKCall_Player);
	new bool:bFlingFuncLoaded = PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_Fling");
	if(!bFlingFuncLoaded)
	{
		LogError("Could not load the Fling signature");
	}
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);

	MySDKCall = EndPrepSDKCall();
	if(MySDKCall == INVALID_HANDLE)
	{
		LogError("Could not prep the Fling function");
	}
	
	SDKCall(MySDKCall, target, vector, 76, attacker, incaptime); //76 is the 'got bounced' animation in L4D2 // 96 95 98 80 81 back  82 84  jump 86 roll 87 88 91 92 jump 93 
	Damage_TitanicBellow(attacker, target);
}

public Action:Damage_TitanicBellow(client, victim)
{
	new damage = 0;
	damage = GetConVarInt(cvarTitanicBellowDamage);
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
	AcceptEntityInput(entPointHurt, "Hurt", (client && client < MaxClients && IsClientInGame(client)) ? client : -1);
	
	// Config, delete point_hurt
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	RemoveEdict(entPointHurt);
}

public OnEntityCreated(entity, const String:classname[])
{
	if(isSmoulderingEarth && StrEqual(classname, "tank_rock", true))
	{
		if(IsValidEntity(entity) && IsValidEdict(entity))
		{
			new RockType = GetConVarInt(cvarSmoulderingEarthType);

			switch(RockType)  
			{	
				case 1:
				{
					IgniteEntity(entity, 100.0);
				}
				case 2:
				{
					new tank = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
			
					if (IsValidTank(tank) && IsPlayerOnFire(tank))
					{
						IgniteEntity(entity, 100.0);
					}
				}
			}
		}
	}
}

public OnEntityDestroyed(entity)
{	
	if(isSmoulderingEarth && isMapRunning)
	{	
		if(IsValidEntity(entity) && IsValidEdict(entity) && IsPlayerOnFire(entity))
		{
			decl String:classname[24];
			GetEdictClassname(entity, classname, 24);
			
			if (StrEqual(classname, "tank_rock", false) == true)
			{
				decl Float:entityPos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
				ShowParticle(entityPos, "gas_explosion_pump", 3.0);
				//PrintToChatAll("Entity Position: %f.", entityPos);

				new tank = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
				
				if (IsValidTank(tank))
				{
					for (new victim=1; victim<=MaxClients; victim++)
			
					if (IsValidClient(victim) && GetClientTeam(victim) == 2)
					{
						decl Float:victimPos[3];
						GetClientEyePosition(victim, victimPos);
						decl Float:distance;
						new Float:range = GetConVarFloat(cvarSmoulderingEarthRange);
						distance = GetVectorDistance(entityPos, victimPos);
						//PrintToChatAll("Distance: %f attacker: %n", distance, victim);
						
						if (distance <= range)
						{
							decl String:sRadius[256];
							decl String:sPower[256];
							new magnitude = GetConVarInt(cvarSmoulderingEarthPower);
							IntToString(GetConVarInt(cvarSmoulderingEarthRange), sRadius, sizeof(sRadius));
							IntToString(magnitude, sPower, sizeof(sPower));
							new exPhys = CreateEntityByName("env_physexplosion");
			
							//Set up physics movement explosion
							DispatchKeyValue(exPhys, "radius", sRadius);
							DispatchKeyValue(exPhys, "magnitude", sPower);
							DispatchSpawn(exPhys);
							TeleportEntity(exPhys, entityPos, NULL_VECTOR, NULL_VECTOR);
							
							//BOOM!
							AcceptEntityInput(exPhys, "Explode");
			
							decl Float:traceVec[3], Float:resultingVec[3], Float:currentVelVec[3];
							new Float:power = GetConVarFloat(cvarSmoulderingEarthPower);
							MakeVectorFromPoints(entityPos, victimPos, traceVec);				// draw a line from car to Survivor
							GetVectorAngles(traceVec, resultingVec);							// get the angles of that line
							
							resultingVec[0] = Cosine(DegToRad(resultingVec[1])) * power;	// use trigonometric magic
							resultingVec[1] = Sine(DegToRad(resultingVec[1])) * power;
							resultingVec[2] = power * SLAP_VERTICAL_MULTIPLIER;
							
							GetEntPropVector(victim, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
							resultingVec[0] += currentVelVec[0];
							resultingVec[1] += currentVelVec[1];
							resultingVec[2] += currentVelVec[2];
							
							Fling_SmoulderingEarth(victim, resultingVec, tank);
						}
					}
				}
			}
		}
	}
}

stock Fling_SmoulderingEarth(victim, Float:vector[3], attacker, Float:incaptime = 3.0)
{
	new Handle:MySDKCall = INVALID_HANDLE;
	new Handle:ConfigFile = LoadGameConfigFile(GAMEDATA_FILENAME);
	
	StartPrepSDKCall(SDKCall_Player);
	new bool:bFlingFuncLoaded = PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_Fling");
	if(!bFlingFuncLoaded)
	{
		LogError("Could not load the Fling signature");
	}
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);

	MySDKCall = EndPrepSDKCall();
	if(MySDKCall == INVALID_HANDLE)
	{
		LogError("Could not prep the Fling function");
	}
	
	SDKCall(MySDKCall, victim, vector, 76, attacker, incaptime); //76 is the 'got bounced' animation in L4D2
	Damage_SmoulderingEarth(attacker, victim);
}

public Action:Damage_SmoulderingEarth(attacker, victim)
{
	new damage = GetConVarInt(cvarSmoulderingEarthDamage);
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

// ----------------------------------------------------------------------------
// ClientViews()
// ----------------------------------------------------------------------------
stock bool:ClientViews(Viewer, Target, Float:fMaxDistance=0.0, Float:fThreshold=0.73)
{
	// Retrieve view and target eyes position
	decl Float:fViewPos[3];   GetClientEyePosition(Viewer, fViewPos);
	decl Float:fViewAng[3];   GetClientEyeAngles(Viewer, fViewAng);
	decl Float:fViewDir[3];
	decl Float:fTargetPos[3]; GetClientEyePosition(Target, fTargetPos);
	decl Float:fTargetDir[3];
	decl Float:fDistance[3];
	new Float:fMinDistance = 100.0;
	
	// Calculate view direction
	fViewAng[0] = fViewAng[2] = 0.0;
	GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
	
	// Calculate distance to viewer to see if it can be seen.
	fDistance[0] = fTargetPos[0]-fViewPos[0];
	fDistance[1] = fTargetPos[1]-fViewPos[1];
	fDistance[2] = 0.0;
	
	if (fMaxDistance != 0.0)
	{
		if (((fDistance[0]*fDistance[0])+(fDistance[1]*fDistance[1])) >= (fMaxDistance*fMaxDistance))
			return false;
	}
	
	if (fMinDistance != -0.0)
	{
		if (((fDistance[0]*fDistance[0])+(fDistance[1]*fDistance[1])) < (fMinDistance*fMinDistance))
			return false;
	}
	
	// Check dot product. If it's negative, that means the viewer is facing
	// backwards to the target.
	NormalizeVector(fDistance, fTargetDir);
	if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;
	
	// Now check if there are no obstacles in between through raycasting
	new Handle:hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
	if (TR_DidHit(hTrace)) { CloseHandle(hTrace); return false; }
	CloseHandle(hTrace);
	
	// Done, it's visible
	return true;
}

// ----------------------------------------------------------------------------
// ClientViewsFilter()
// ----------------------------------------------------------------------------
public bool:ClientViewsFilter(Entity, Mask, any:Junk)
{
	if (Entity >= 1 && Entity <= MaxClients) return false;
	return true;
}
		
public ShowParticle(Float:victimPos[3], String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, victimPos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	} 
}
 
public PrecacheParticle(String:particlename[])
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		decl String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
	}
}

public OnMapEnd()
{
	isMapRunning = false;
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

public IsValidTank(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		
		if (class == ZOMBIECLASS_TANK)
			return true;
		
		return false;
	}
	
	return false;
}

public IsPlayerOnFire(client)
{
	if (GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONFIRE) return true;
		else return false;
}

public IsPlayerGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost")) return true;
		else return false;
}

public IsTitanFistReady(client)
{
	return ((GetEngineTime() - cooldownTitanFist[client]) > GetConVarFloat(cvarTitanFistCooldown));
}

public IsTitanicBellowReady(client)
{
	return ((GetEngineTime() - cooldownTitanicBellow[client]) > GetConVarFloat(cvarTitanicBellowCooldown));
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