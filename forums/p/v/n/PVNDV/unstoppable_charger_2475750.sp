#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define L4D2 Unstoppable Charger
#define PLUGIN_VERSION "1.11"

#define STRING_LENGHT								56
#define ZOMBIECLASS_CHARGER 						6

#define PUSH_COUNT "m_iHealth"

#define TEAM_INFECTED 3
#define PROP_CAR (1<<0)
#define PROP_CAR_ALARM (1<<1)
#define PROP_CONTAINER	(1<<2)
#define PROP_TRUCK (1<<3)

static const String:GAMEDATA_FILENAME[]				= "l4d2addresses";
static const String:VELOCITY_ENTPROP[]				= "m_vecVelocity";
static const String:CHARGER_WEAPON[]				= "weapon_charger_claw";
static const Float:SLAP_VERTICAL_MULTIPLIER			= 1.5;
static laggedMovementOffset = 0;

new Handle:cvarInertiaVault;
new Handle:cvarInertiaVaultPower;

new Handle:cvarLocomotive;
new Handle:cvarLocomotiveDuration;
new Handle:cvarLocomotiveSpeed;

new Handle:cvarMeteorFist;
new Handle:cvarMeteorFistPower;
new Handle:cvarMeteorFistCooldown;

new Handle:cvarSurvivorAegis;
new Handle:cvarSurvivorAegisAmount;
new Handle:cvarSurvivorAegisDamage;

new Handle:cvarChargerPower;
new Handle:cvarChargerCarry;
new Handle:cvarObjects;
new Handle:cvarPushLimit;
new Handle:cvarRemoveObject;
new Handle:cvarChargerDamage;

new Handle:PluginStartTimer = INVALID_HANDLE;
new Handle:cvarResetDelayTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new bool:isCharging[MAXPLAYERS+1] = false;
new bool:buttondelay[MAXPLAYERS+1] = false;
new bool:isInertiaVault = false;
new bool:isLocomotive = false;
new bool:isMeteorFist = false;
new bool:isSurvivorAegis = false;

static Float:lastMeteorFist[MAXPLAYERS+1]				= 0.0;

public Plugin:myinfo = 
{
    name = "[L4D2] Unstoppable Charger & Charger Power",
    author = "Mortiegama, DJ_WEST",
    description = "Allows for unique Charger abilities to bring fear to this titan.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2092125#post2092125"
}

public OnPluginStart()
{
	CreateConVar("l4d_ucm_version", PLUGIN_VERSION, "Unstoppable Charger Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cvarInertiaVault = CreateConVar("l4d_ucm_inertiavault", "1", "Enables the ability Inertia Vault, allows the Charger to jump while charging. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarInertiaVaultPower = CreateConVar("l4d_ucm_inertiavaultpower", "400.0", "Power behind the Charger's jump. (Def 400.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarLocomotive = CreateConVar("l4d_ucm_locomotive", "1", "Enables the ability for the Charger to run faster and further. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarLocomotiveSpeed = CreateConVar("l4d_ucm_locomotivespeed", "1.3", "Multiplier for increase in Charger speed. (Def 1.3)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarLocomotiveDuration = CreateConVar("l4d_ucm_locomotiveduration", "4.0", "Amount of time for which the Charger continues to run. (Def 4.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarMeteorFist = CreateConVar("l4d_ucm_meteorfist", "1", "Enables the ability for the Charger to pummel a Survivor with its fist, sending them flying. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMeteorFistPower = CreateConVar("l4d_ucm_meteorfistpower", "200.0", "Power behind the Charger's Meteor Fist. (Def 200.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMeteorFistCooldown = CreateConVar("l4d_ucm_meteorfistcooldown", "10.0", "Amount of time between Meteor Fists. (Def 10.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarSurvivorAegis = CreateConVar("l4d_ucm_survivoraegis", "1", "Enables the ability for the Charger to use the Survivor as an Aegis while charging. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSurvivorAegisAmount = CreateConVar("l4d_ucm_survivoraegisamount", "0.2", "Percent of damage the Charger avoids using a Survivor as an Aegis. (Def 0.2)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSurvivorAegisDamage = CreateConVar("l4d_ucm_survivoraegisdamage", "5", "How much damage is inflicted to the Survivor being used as an Aegis. (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarChargerPower = CreateConVar("l4d2_charger_power", "500.0", "Charger hit power", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 5000.0);
	cvarChargerCarry = CreateConVar("l4d2_charger_power_carry", "1", "Can move objects if charger carry the player", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarObjects = CreateConVar("l4d2_charger_power_objects", "15", "Can move objects this type (1 - car, 2 - car alarm, 4 - container, 8 - truck)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 15.0);
	cvarPushLimit = CreateConVar("l4d2_charger_power_push_limit", "3", "How many times object can be moved", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 100.0);
	cvarRemoveObject = CreateConVar("l4d2_charger_power_remove", "0", "Remove moved object after some time (in seconds)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	cvarChargerDamage = CreateConVar("l4d2_charger_power_damage", "10", "Additional damage to charger from moving objects", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	
	HookEvent("charger_charge_start", Event_ChargeStart);
	HookEvent("charger_charge_end", Event_ChargeEnd);
	
	AutoExecConfig(true, "plugin.L4D2.UnstoppableCharger");
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
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
	
	if (GetConVarInt(cvarSurvivorAegis))
	{
		isSurvivorAegis = true;
	}
	
	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	
	if(PluginStartTimer != INVALID_HANDLE)
	{
 		KillTimer(PluginStartTimer);
		PluginStartTimer = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public Event_ChargeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client))
	{
		isCharging[client] = true;
		
		if (isLocomotive)
		{
			SetEntDataFloat(client, laggedMovementOffset, 1.0*GetConVarFloat(cvarLocomotiveSpeed), true);
		}
	}
}

public Event_ChargeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl Float:origin[3];
	decl Float:angles[3];
	decl Float:endorigin[3];
	decl Float:velocity[3];
	decl Float:power;
	decl Handle:trace;
	decl Handle:pack;
	decl String:classname[16];
	decl String:modelname[64];
	decl target;
	decl type;
	decl pushcount;
	decl health;
	decl damage;
	decl removetime;
	
	if (IsValidClient(client))
	{
		isCharging[client] = false;
		
		if (isLocomotive)
		{
			SetEntDataFloat(client, laggedMovementOffset, 1.0, true);
		}
	}
	
	if (!client || !IsClientInGame(client))
	{
		return;
	}
	
	if (!GetConVarInt(cvarChargerCarry) && GetEntProp(client, Prop_Send, "m_carryVictim") > 0)
	{
		return;
	}
	
	GetClientAbsOrigin(client, origin);
	GetClientAbsAngles(client, angles);
	origin[2] += 20.0;

	trace = TR_TraceRayFilterEx(origin, angles, MASK_ALL, RayType_Infinite, TraceFilterClients, client);
	
	if (TR_DidHit(trace))
	{
		target = TR_GetEntityIndex(trace);
		TR_GetEndPosition(endorigin, trace);
			
		if (target && IsValidEdict(target) && GetVectorDistance(origin, endorigin) <= 100.0)
		{
			if (GetEntityMoveType(target) != MOVETYPE_VPHYSICS)
			{
				return;
			}
			
			pushcount = GetEntProp(target, Prop_Data, PUSH_COUNT);
			
			if (pushcount >= GetConVarInt(cvarPushLimit))
			{
				return;
			}
			
			type = GetConVarInt(cvarObjects);
			
			GetEdictClassname(target, classname, sizeof(classname));
			GetEntPropString(target, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
			if (StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_car_alarm"))
			{
				if (StrEqual(classname, "prop_car_alarm") && !(type & PROP_CAR_ALARM))
				{
					return;
				}
				else if ((StrContains(modelname, "car") != -1 && !(type & PROP_CAR) && !(type & PROP_CAR_ALARM)) || 
				(StrContains(modelname, "dumpster") != -1 && !(type & PROP_CONTAINER)) || 
				(StrContains(modelname, "forklift") != -1 && !(type & PROP_TRUCK)))
				{
					return;
				}
			}
			
			pushcount++;
			SetEntProp(target, Prop_Data, PUSH_COUNT, pushcount);
			
			GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
			power = GetConVarFloat(cvarChargerPower);
			velocity[0] *= power;
			velocity[1] *= power;
			velocity[2] *= power;
			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, velocity);
			
			pack = CreateDataPack();
			WritePackCell(pack, target);
			WritePackFloat(pack, endorigin[0]);
			CreateTimer(0.5, CheckEntity, pack);
			
			damage = GetConVarInt(cvarChargerDamage);
			if (damage)
			{
				health = GetClientHealth(client);
				health -= damage;
					
				if (health > 0) 
				{
					SetEntityHealth(client, health);
				}
				else
				{
					ForcePlayerSuicide(client);
				}
			}
			
			removetime = GetConVarInt(cvarRemoveObject);
			if (removetime)
			{
				CreateTimer(float(removetime), RemoveEntity, target, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	CloseHandle(trace);
}


public Action:RemoveEntity(Handle:timer, any:ent)
{
	if (IsValidEnt(ent))
	{
		RemoveEdict(ent);
	}
}

public bool:TraceFilterClients(entity, mask, any:data)
{
 	return entity != data && entity > MaxClients;
}

public Action:CheckEntity(Handle:timer, Handle:pack)
{
	decl ent;
	decl Float:origin[3];
	decl Float:lastorigin;
	decl Handle:newpack;
	
	ResetPack(pack, false);
	ent = ReadPackCell(pack);
	lastorigin = ReadPackFloat(pack);
	CloseHandle(pack);
	
	if (IsValidEdict(ent))
	{
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", origin);
		
		if (origin[0] != lastorigin)
		{
			newpack = CreateDataPack();
			WritePackCell(newpack, ent);
			WritePackFloat(newpack, origin[0]);
			CreateTimer(0.1, CheckEntity, newpack);
		}
		else
		{
			TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
		}
	}
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidCharger(victim))
	{
		if (isSurvivorAegis && IsValidClient(attacker) && isCharging[victim])
		{
			new Float:damagemod = GetConVarFloat(cvarSurvivorAegisAmount);
			
			if (FloatCompare(damagemod, 1.0) != 0)
			{
				damage = damage * damagemod;
			}
			
			new aegis = GetEntPropEnt(victim, Prop_Send, "m_carryVictim");
			
			if (IsValidClient(aegis))
			{
				Damage_SurvivorAegis(victim, aegis);
			}
		}
	}
	
	if (IsValidCharger(attacker) && IsValidClient(victim))
	{
		decl String:classname[STRING_LENGHT];
		GetClientWeapon(attacker, classname, sizeof(classname));
		
		if (StrEqual(classname, CHARGER_WEAPON) && isMeteorFist && MeteorFist(attacker))
		{
			decl Float:HeadingVector[3], Float:AimVector[3];
			new Float:power = GetConVarFloat(cvarMeteorFistPower);
			
			GetClientEyeAngles(attacker, HeadingVector);
			
			AimVector[0] = FloatMul(Cosine(DegToRad(HeadingVector[1])), power);
			AimVector[1] = FloatMul(Sine(DegToRad(HeadingVector[1])), power);
			
			decl Float:current[3];
			GetEntPropVector(victim, Prop_Data, VELOCITY_ENTPROP, current);
			
			decl Float:resulting[3];
			resulting[0] = FloatAdd(current[0], AimVector[0]);	
			resulting[1] = FloatAdd(current[1], AimVector[1]);
			resulting[2] = power * SLAP_VERTICAL_MULTIPLIER;
			
			L4D2_Fling(victim, resulting, attacker);
			
			lastMeteorFist[attacker] = GetEngineTime();
		}
	}

	return Plugin_Changed;
}

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

stock L4D2_Fling(target, Float:vector[3], attacker, Float:incaptime = 3.0)
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
	
	SDKCall(MySDKCall, target, vector, 76, attacker, incaptime); //76 is the 'got bounced' animation in L4D2
}

public Action:Damage_SurvivorAegis(client, victim)
{
	new damage = GetConVarInt(cvarSurvivorAegisDamage);
	decl Float:victimPos[3], String:strDamage[16], String:strDamageTarget[16];
	
	GetClientEyePosition(victim, victimPos);
	IntToString(damage, strDamage, sizeof(strDamage));
	Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
	
	new entPointHurt = CreateEntityByName("point_hurt");
	if(!entPointHurt) return;
	
	DispatchKeyValue(victim, "targetname", strDamageTarget);
	DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
	DispatchKeyValue(entPointHurt, "Damage", strDamage);
	DispatchKeyValue(entPointHurt, "DamageType", "0"); // DMG_GENERIC
	DispatchSpawn(entPointHurt);
	
	TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entPointHurt, "Hurt", (client && client < MaxClients && IsClientInGame(client)) ? client : -1);
	
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	RemoveEdict(entPointHurt);
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

public IsValidClient(client)
{
	if (client <= 0)
	{
		return false;
	}
	
	if (client > MaxClients)
	{
		return false;
	}
	
	if (!IsClientInGame(client))
	{
		return false;
	}
	
	if (!IsPlayerAlive(client))
	{
		return false;
	}
	
	return true;
}

stock IsValidEnt(ent)
{
	return (IsValidEdict(ent) && IsValidEntity(ent));
}

static bool:MeteorFist(slapper)
{
	return ((GetEngineTime() - lastMeteorFist[slapper]) > GetConVarFloat(cvarMeteorFistCooldown));
}

public IsPlayerOnGround(client)
{
	if (GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND)
	{
		return true;
	}
	
	else return false;
}

public IsValidCharger(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		
		if (class == ZOMBIECLASS_CHARGER)
		{
			return true;
		}
		
		return false;
	}
	
	return false;
}