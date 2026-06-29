#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define L4D2 Sinister Jockey
#define PLUGIN_VERSION "1.3"

#define ZOMBIECLASS_JOCKEY 5

new Handle:PluginStartTimer = INVALID_HANDLE;

new Handle:cvarBacterialFeet;
new Handle:cvarBacterialFeetRide;
new Handle:cvarBacterialFeetRideSpeed;
new Handle:cvarBacterialFeetSpeed;
new Handle:cvarBacterialFeetTimer[MAXPLAYERS+1];

new Handle:cvarGhostStalker;
new Handle:cvarGhostStalkerVisibility;

new Handle:cvarGravityPounce;
new Handle:cvarGravityPounceCap;
new Handle:cvarGravityPounceMultiplier;

new Handle:cvarHumanShield;
new Handle:cvarHumanShieldAmount;
new Handle:cvarHumanShieldDamage;

new Handle:cvarMarionette;
new Handle:cvarMarionetteCooldown;
new Handle:cvarMarionetteDuration;
new Handle:cvarMarionetteRange;
new Handle:cvarMarionetteTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new marionette[MAXPLAYERS+1];
new Float:cooldownMarionette[MAXPLAYERS+1];

new Handle:cvarRodeoJump;
new Handle:cvarRodeoJumpPower;

new bool:isRiding[MAXPLAYERS + 1] = false;
new bool:isAnnounce = true;
new bool:isBacterialFeet = false;
new bool:isBacterialFeetRide = false;
new bool:isGhostStalker = false;
new bool:isGravityPounce = false;
new bool:isHumanShield = false;
new bool:isMarionette = false;
new bool:isRodeoJump = false;

new Float:startPosition[MAXPLAYERS+1][3];
new Float:endPosition[MAXPLAYERS+1][3];

new Handle:cvarResetDelayTimer[MAXPLAYERS+1];
new bool:buttondelay[MAXPLAYERS+1];
new bool:isMarionetteJockey[MAXPLAYERS+1];
new bool:isMarionetteSurvivor[MAXPLAYERS+1];

static laggedMovementOffset = 0;

public Plugin:myinfo = 
{
    name = "[L4D2] Sinister Jockey",
    author = "Mortiegama",
    description = "Allows for unique Jockey abilities to empower the small tyrant.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?p=2091791#post2091791"
}

	//Special Thanks:
	//n3wton - Jockey Pounce Damage:
	//http://forums.alliedmods.net/showthread.php?p=1172322
	
public OnPluginStart()
{
	CreateConVar("l4d_sjm_version", PLUGIN_VERSION, "Jockey Human Shield Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarBacterialFeet = CreateConVar("l4d_sjm_bacterialfeet", "1", "Enables the Bacterial Feet ability, the slick coating of Bacteria on the Jockeys feet allows it to move faster. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBacterialFeetRide = CreateConVar("l4d_sjm_bacterialfeetride", "1", "Enables the Bacterial Feet Ride ability, the Jockey coats the Survivor with bacteria allowing it to ride faster. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBacterialFeetRideSpeed = CreateConVar("l4d_sjm_bacterialfeetridespeed", "1.5", "Speed increase for the Jockey receives from running. (Def 1.5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBacterialFeetSpeed = CreateConVar("l4d_sjm_bacterialfeetspeed", "1.5", "Speed increase the Jockey receives while riding a Survivor. (Def 1.5)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarGhostStalker = CreateConVar("l4d_sjm_ghoststalker", "1", "Enables the ability for the Jockey to use the Survivor as a human shiled while riding. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarGhostStalkerVisibility = CreateConVar("l4d_sjm_ghoststalkervisibility", "20", "Modifies the opacity of the Jockey to become closer to invisible (0-255) (Def 20)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarGravityPounce = CreateConVar("l4d_sjm_gravitypounce", "1", "Enables the ability for the Jockey to inflict damage based on how far he drops on a Survivor. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarGravityPounceCap = CreateConVar("l4d_sjm_gravitypouncecap", "100", "Maximum amount of damage the Jockey can inflict while dropping (Should be Survivor health max). (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarGravityPounceMultiplier = CreateConVar("l4d_sjm_gravitypouncemultiplier", "1.0", "Amount to multiply the damage dealt by the Jockey when dropping. (Def 1.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarHumanShield = CreateConVar("l4d_sjm_humanshield", "1", "Enables the ability for the Jockey to use the Survivor as a human shiled while riding. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarHumanShieldAmount = CreateConVar("l4d_sjm_humanshieldamount", "0.4", "Percent of damage the Jockey avoids using a Survivor as a shield. (Def 0.4)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarHumanShieldDamage = CreateConVar("l4d_sjm_humanshielddamage", "2", "How much damage is inflicted to the Survivor being used as a Huamn Shield. (Def 2)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarMarionette = CreateConVar("l4d_sjm_marionette", "1", "Enables the Marionette ability: While pressing the Use key, the Survivor becomes immobilized. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMarionetteCooldown = CreateConVar("l4d_sjm_marionettecooldown", "20.0", "Amount of time between Marionette abilities. (Def 20.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMarionetteDuration = CreateConVar("l4d_sjm_marionetteduration", "6.0", "Duration of time the Marionette ability will last. (Def 6.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMarionetteRange = CreateConVar("l4d_sjm_marionetterange", "700.0", "Distance the Jockey is able to Marionette a Survivor. (Def 700.0)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarRodeoJump = CreateConVar("l4d_sjm_rodeojump", "1", "Enables the Rodeo Jump ability, Jockey is able to jump while riding a Survivor. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarRodeoJumpPower = CreateConVar("l4d_sjm_rodeojumppower", "400.0", "Power behind the Jockey's jump. (Def 400.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_jump", Event_JockeyJump);
	HookEvent("jockey_ride", Event_JockeyRideStart);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd);
	
	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	
	AutoExecConfig(true, "plugin.L4D2.SinisterJockey");
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
}
	
public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (GetConVarInt(cvarBacterialFeet))
	{
		isBacterialFeet = true;
	}
	
	if (GetConVarInt(cvarBacterialFeetRide))
	{
		isBacterialFeetRide = true;
	}
	
	if (GetConVarInt(cvarGhostStalker))
	{
		isGhostStalker = true;
	}
	
	if (GetConVarInt(cvarGravityPounce))
	{
		isGravityPounce = true;
	}
	
	if (GetConVarInt(cvarHumanShield))
	{
		isHumanShield = true;
	}
	
	if (GetConVarInt(cvarMarionette))
	{
		isMarionette = true;
	}
	
	if (GetConVarInt(cvarRodeoJump))
	{
		isRodeoJump = true;
	}

	if(PluginStartTimer != INVALID_HANDLE)
	{
 		KillTimer(PluginStartTimer);
		PluginStartTimer = INVALID_HANDLE;
	}	

	return Plugin_Stop;
}

public Event_PlayerSpawn (Handle:event, const String:name[], bool:dontBrodcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidJockey(client))
	{
		PrintHintText(client, "Press and hold only the USE button to activate the Marionette ability.");
		
		if (isGhostStalker)
		{
			new Opacity = GetConVarInt(cvarGhostStalkerVisibility);
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, 255, 255, 255, Opacity);
		}

		if (isBacterialFeet)
		{
				cvarBacterialFeetTimer[client] = CreateTimer(0.5, Event_BacterialFeet, client);
		}
	}
}

public Action:Event_BacterialFeet(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
		PrintHintText(client, "Bacterial Feet has granted you increased movement speed!");
		SetEntDataFloat(client, laggedMovementOffset, 1.0*GetConVarFloat(cvarBacterialFeetSpeed), true);
	}
	
	if(cvarBacterialFeetTimer[client] != INVALID_HANDLE)
	{
 		KillTimer(cvarBacterialFeetTimer[client]);
		cvarBacterialFeetTimer[client] = INVALID_HANDLE;
	}
		
	return Plugin_Stop;	
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidDeadJockey(client))
	{
		isMarionetteJockey[client] = false;
	}
}

public Event_JockeyJump (Handle:event, const String:name[], bool:dontBrodcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidJockey(client) && isGravityPounce)
	{
		GetClientAbsOrigin(client, startPosition[client]);
	}
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (IsValidClient(entity) && StrEqual(classname, "infected", false))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidJockey(victim))
	{
		if (isHumanShield && isRiding[victim] && IsValidClient(attacker))
		{
			new Float:damagemod = GetConVarFloat(cvarHumanShieldAmount);
			
			if (FloatCompare(damagemod, 1.0) != 0)
			{
				damage = damage * damagemod;
			}
			
			new shield = GetEntPropEnt(victim, Prop_Send, "m_jockeyVictim");
			
			if (IsValidClient(shield))
			{
				Damage_HumanShield(victim, shield);
			}
		}
	}

	return Plugin_Changed;
}
	
public Event_JockeyRideStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (IsValidClient(client) && IsValidClient(victim))
	{
		isRiding[client] = true;
		
		if (isGravityPounce)
		{
			GetClientAbsOrigin(client, endPosition[client]);
			new distance = RoundFloat(startPosition[client][2] - endPosition[client][2]);
			new damage = RoundFloat(distance * 0.4);
			//PrintToChatAll("Damage = %i.", damage);
			new maxdamage = GetConVarInt(cvarGravityPounceCap);
			new Float:multiplier = GetConVarFloat(cvarGravityPounceMultiplier);
			damage = RoundFloat(damage * multiplier);
			//PrintToChatAll("Damage = %i.", damage);
			
			if (damage < 0.0){return;}
			if (damage > maxdamage)
			{
				damage = maxdamage;
			}

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
			
			if (isAnnounce) 
			{
				PrintHintText(client, "You dropped %i distance on a Survivor, causing %i damage.", distance, damage);
				PrintHintText(victim, "A Jockey dropped %i distance on you, causing %i damage.", distance, damage);
			}
		}
		
		if (isBacterialFeetRide)
		{
			SetEntDataFloat(victim, laggedMovementOffset, 1.0*GetConVarFloat(cvarBacterialFeetRideSpeed), true);
		}
	}
}

public Event_JockeyRideEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (IsValidClient(client))
	{
		isRiding[client] = false;
	}
	
	if (isBacterialFeetRide && IsValidClient(victim))
	{
		SetEntDataFloat(victim, laggedMovementOffset, 1.0*GetConVarFloat(cvarBacterialFeetRideSpeed), true);
	}
}

public Action:Damage_HumanShield(client, victim)
{
	new damage = GetConVarInt(cvarHumanShieldDamage);
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

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_USE && !isRiding[client] && IsValidClient(client) && GetClientTeam(client) == 3)
	{
		if (isMarionette && IsMarionetteReady(client) && !buttondelay[client])
		{
			new Float:range = GetConVarFloat(cvarMarionetteRange);
			
			for (new victim=1; victim<=MaxClients; victim++)
			if (marionette[victim] <= 0 && IsValidClient(victim) && GetClientTeam(victim) == 2 && ClientViews(client, victim, range))
			{
				Event_MarionetteStart(client, victim);
				marionette[victim] = ((GetConVarInt(cvarMarionetteDuration) + 1));
				
				new Handle:dataPack = CreateDataPack();
				cvarMarionetteTimer[victim] = CreateDataTimer(1.0, Timer_Marionette, dataPack, TIMER_REPEAT);
				WritePackCell(dataPack, victim);
				WritePackCell(dataPack, client);
				
				return Plugin_Stop;
			}
		}
	}
	
	if ((buttons & ~IN_USE || !buttons) && isMarionetteJockey[client])
	{
		isMarionetteJockey[client] = false;
	}
	
	if (buttons & IN_JUMP && isRiding[client] && IsValidClient(client) && GetClientTeam(client) == 3)
	{
		new victim = GetEntPropEnt(victim, Prop_Send, "m_jockeyVictim");
		
		if (isRodeoJump && IsPlayerOnGround(client) && IsValidClient(victim) && !buttondelay[client])
		{
			buttondelay[client] = true;
			new Float:velo[3];
			velo[0] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[0]");
			velo[1] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[1]");
			velo[2] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[2]");
			
			if (vel[2] != 0) return Plugin_Stop;

			new Float:vec[3];
			vec[0] = velo[0];
			vec[1] = velo[1];
			vec[2] = velo[2] + GetConVarFloat(cvarRodeoJumpPower);
			
			cvarResetDelayTimer[client] = CreateTimer(1.0, ResetDelay, client);
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vec);
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_Marionette(Handle:timer, any:dataPack) 
{
	ResetPack(dataPack);
	new victim = ReadPackCell(dataPack);
	new client = ReadPackCell(dataPack);

	if (IsValidClient(victim))
	{
		if(marionette[victim] <= 0 || !isMarionetteJockey[client])
		{
			if (cvarMarionetteTimer[victim] != INVALID_HANDLE)
			{
				KillTimer(cvarMarionetteTimer[victim]);
				cvarMarionetteTimer[victim] = INVALID_HANDLE;
			}
			
			Event_MarionetteStop(client, victim);
			
			return Plugin_Stop;
		}

		if(marionette[victim] > 0) 
		{
			marionette[victim] -= 1;
			
			decl Float:attackerPos[3];
			decl Float:victimPos[3];
			GetClientEyePosition(client, attackerPos);
			GetClientEyePosition(victim, victimPos);
			ShowParticle(attackerPos, "electrical_arc_01_system", 1.0);	
			ShowParticle(victimPos, "electrical_arc_01_system", 1.0);	
		}
	}
			
	return Plugin_Continue;
}

public Event_MarionetteStart(client, victim)
{
	buttondelay[client] = true;
	cvarResetDelayTimer[client] = CreateTimer(1.0, ResetDelay, client);
	
	cooldownMarionette[client] = GetEngineTime();
	isMarionetteJockey[client] = true;
	isMarionetteSurvivor[victim] = true;

	SetEntityMoveType(victim, MOVETYPE_NONE);
	new Float:time = GetConVarFloat(cvarMarionetteDuration);
	SetupProgressBar(client, time);

	decl Float:attackerPos[3];
	decl Float:victimPos[3];
	GetClientEyePosition(client, attackerPos);
	GetClientEyePosition(victim, victimPos);
	ShowParticle(attackerPos, "electrical_arc_01_system", 1.0);	
	ShowParticle(victimPos, "electrical_arc_01_system", 1.0);	

	decl String:playername[64];
	GetClientName(victim, playername, sizeof(playername));
	PrintToChatAll("Player \x05%s \x01has been adjusted.", playername);
}

public Event_MarionetteStop(client, victim)
{
	isMarionetteJockey[client] = false;
	isMarionetteSurvivor[victim] = false;

	KillProgressBar(client);

	SetEntityMoveType(victim, MOVETYPE_WALK); 
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
    for (new client=1; client<=MaxClients; client++)
	{
	if (IsValidClient(client))
		{
			isRiding[client] = false;
			isMarionetteJockey[client] = false;
			isMarionetteSurvivor[client] = false;
			marionette[client] = 0;
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

public IsValidJockey(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		
		if (class == ZOMBIECLASS_JOCKEY)
			return true;
		
		return false;
	}
	
	return false;
}

public IsValidDeadJockey(client)
{
	if (IsValidDeadClient(client))
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		
		if (class == ZOMBIECLASS_JOCKEY)
			return true;
		
		return false;
	}
	
	return false;
}

public IsPlayerOnGround(client)
{
	if (GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND) return true;
		else return false;
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

public IsMarionetteReady(client)
{
	return ((GetEngineTime() - cooldownMarionette[client]) > GetConVarFloat(cvarMarionetteCooldown));
}