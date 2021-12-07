#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define L4D2 Hulking Tank
#define PLUGIN_VERSION "1.0"

#define STRING_LENGHT								56
#define ZOMBIECLASS_TANK 					    	8

static const String:GAMEDATA_FILENAME[]				= "l4d2addresses";
static const String:VELOCITY_ENTPROP[]				= "m_vecVelocity";
static const Float:SLAP_VERTICAL_MULTIPLIER			= 1.5;

new Handle:cvarSmoulderingEarth;
new Handle:cvarSmoulderingEarthDamage;
new Handle:cvarSmoulderingEarthRange;
new Handle:cvarSmoulderingEarthPower;
new Handle:cvarSmoulderingEarthType;

new Handle:cvarTitanicBellow;
new Handle:cvarTitanicBellowCooldown;
new Handle:cvarTitanicBellowPower;
new Handle:cvarTitanicBellowDamage;
new Handle:cvarTitanicBellowRange;
new Handle:cvarTitanicBellowType;

new Handle:PluginStartTimer = INVALID_HANDLE;
new TankThrower[MAXPLAYERS+1];

new bool:isSmoulderingEarth;
new bool:isTitanicBellow;
new bool:TankThrow[MAXPLAYERS+1] = false;

new Float:cooldownTitanicBellow[MAXPLAYERS+1] = 0.0;

public Plugin:myinfo = 
{
    name = "[L4D2] Hulking Tank",
    author = "Mortiegama",
    description = "Brings a set of psychotic abilities to the Hulking Tank.",
    version = PLUGIN_VERSION,
    url = ""
}

	//Special Thanks:
	//Karma - Tank Skill Roar
	//https://forums.alliedmods.net/showthread.php?t=126919
	
	//panxiaohai - Tank's Burning Rock
	//https://forums.alliedmods.net/showthread.php?t=139691
	
public OnPluginStart()
{
	CreateConVar("l4d_htm_version", PLUGIN_VERSION, "Unstoppable Charger Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarSmoulderingEarth = CreateConVar("l4d_htm_SmoulderingEarth", "1", "Enables the Smouldering Earth ability, Tank is able to throw a burning rock that explodes when hitting the ground. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSmoulderingEarthDamage = CreateConVar("l4d_htm_smoulderingearthdamage", "7", "Damage the exploding rock causes nearby Survivors. (Def 7)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSmoulderingEarthRange = CreateConVar("l4d_htm_smoulderingearthrange", "300.0", "Area around the exploding rock that will reach Survivors. (Def 300.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSmoulderingEarthPower = CreateConVar("l4d_htm_smoulderingearthpower", "200.0", "Amount of power behind the explosion. (Def 200.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSmoulderingEarthType = CreateConVar("l4d_htm_smoulderingearthtype", "2", "Type of rock thrown, 1 = Rock is always on fire, 2 = Rock only on fire if Tank is on fire.", FCVAR_PLUGIN, true, 1.0, true, 2.0);

	cvarTitanicBellow = CreateConVar("l4d_htm_titanicbellow", "1", "Enables the Titanic Bellow ability, Tank is able to roar and send nearby Survivors flying or pull them to the Tank. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanicBellowCooldown = CreateConVar("l4d_htm_titanicbellowcooldown", "5.0", "Amount of time between Titanic Bellows. (Def 5.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanicBellowPower = CreateConVar("l4d_htm_titanicbellowpower", "300.0", "Power behind the inner range of Methane Blast. (Def 300.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanicBellowDamage = CreateConVar("l4d_htm_titanicbellowdamage", "10", "Damage the force of the roar causes to nearby survivors. (Def 10)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanicBellowRange = CreateConVar("l4d_htm_titanicbellowrange", "700.0", "Area around the Tank the bellow will reach. (Def 700.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTitanicBellowType = CreateConVar("l4d_htm_titanicbellowtype", "1", "Type of roar, 1 = Survivors are pushed away from Tank, 2 = Survivors are pulled towards Tank.", FCVAR_PLUGIN, true, 1.0, true, 2.0);

	HookEvent("ability_use", Event_AbilityUse);
	
	AutoExecConfig(true, "plugin.L4D2.HulkingTank");
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{	
	if (GetConVarInt(cvarSmoulderingEarth))
	{
		isSmoulderingEarth = true;
	}
	
	if (GetConVarInt(cvarTitanicBellow))
	{
		isTitanicBellow = true;
	}
	
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
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((buttons & IN_ZOOM) && isTitanicBellow && IsValidTank(client) && IsTitanicBellowReady(client)) 
	{
		cooldownTitanicBellow[client] = GetEngineTime();
		
		for (new victim=1; victim<=MaxClients; victim++)
		{
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
					PrintToChatAll("sPower: %s.", sPower);
					new exPhys = CreateEntityByName("env_physexplosion");
	
					//Set up physics movement explosion
					DispatchKeyValue(exPhys, "radius", sRadius);
					DispatchKeyValue(exPhys, "magnitude", sPower);
					PrintToChatAll("sPower: %s.", sPower);
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
					
					PrintToChatAll("Here's the vector %f.", resultingVec);
					
					Fling_TitanicBellow(victim, resultingVec, client);
				}
			}
		}
	}
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

public Event_AbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidTank(client))
	{
		decl String:infAbility[24];
		GetEventString(event, "ability", infAbility, 24);
		
		if (StrEqual(infAbility, "ability_throw", false) == true)
		{
			TankThrow[client] = true;
		}
	}
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
					for (new tank=1; tank<=MaxClients; tank++)
			
					if (IsValidTank(tank) && TankThrow[tank] && IsPlayerOnFire(tank))
					{
						IgniteEntity(entity, 100.0);
						TankThrow[tank] = false;
						TankThrower[entity] = tank;
					}
				}
			}
		}
	}
}

public OnEntityDestroyed(entity)
{	
	if(isSmoulderingEarth && IsValidEntity(entity) && IsValidEdict(entity) && IsPlayerOnFire(entity))
	{
		decl String:classname[24];
		GetEdictClassname(entity, classname, 24);
		
		if (StrEqual(classname, "tank_rock", false) == true)
		{
			decl Float:entityPos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
			ShowParticle(entityPos, "gas_explosion_pump", 3.0);
			PrintToChatAll("Entity Position: %f.", entityPos);

			for (new victim=1; victim<=MaxClients; victim++)
	
			if (IsValidClient(victim) && GetClientTeam(victim) == 2)
			{
				decl Float:victimPos[3];
				GetClientEyePosition(victim, victimPos);
				PrintToChatAll("Survivor Position: %f.", victimPos);				
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
					PrintToChatAll("sPower: %s.", sPower);
					new exPhys = CreateEntityByName("env_physexplosion");
	
					//Set up physics movement explosion
					DispatchKeyValue(exPhys, "radius", sRadius);
					DispatchKeyValue(exPhys, "magnitude", sPower);
					PrintToChatAll("sPower: %s.", sPower);
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
					
					Fling_SmoulderingEarth(victim, resultingVec, victim);
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