#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define L4D2 Destructive Hunter
#define PLUGIN_VERSION "1.13"

#define ZOMBIECLASS_HUNTER 3

static const String:GAMEDATA_FILENAME[]				= "l4d2addresses";
static const String:VELOCITY_ENTPROP[]				= "m_vecVelocity";
static const Float:SLAP_VERTICAL_MULTIPLIER			= 1.5;

new Handle:cvarInfernoClaw;
new Handle:cvarInfernoClawDamage;

new Handle:cvarKevlarSkin;
new Handle:cvarKevlarSkinTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:cvarLashingClaw;
new Handle:cvarLashingClawChance;
new Handle:cvarLashingClawDamage;
new Handle:cvarLashingClawRange;
new Handle:cvarLashingClawPower;
new Handle:cvarLashingClawTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:cvarSledgehammer;
new Handle:cvarSledgehammerCap;
new Handle:cvarSledgehammerMultiplier;

new Handle:cvarShunpo;
new Handle:cvarShunpoAmount;
new Handle:cvarShunpoCooldown;
new Handle:cvarShunpoDuration;
new Handle:cvarShunpoTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:cvarShurikenClaw;
new Handle:cvarShurikenClawCooldown;
new Handle:cvarShurikenClawDamage;
new Handle:cvarShurikenClawRange;

new Handle:cvarShurikenClawIgnite;
new Handle:cvarShurikenClawIgniteChance;
new Handle:cvarShurikenClawIgniteDamage;
new Handle:cvarShurikenClawIgniteDuration;
new Handle:cvarShurikenClawIgniteTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:cvarAnnounce;
new Handle:PluginStartTimer = INVALID_HANDLE;

new bool:isAnnounce = false;
new bool:isSledgehammer = false;
new bool:isShunpo = false;
new bool:isShurikenClaw = false;
new bool:isShurikenClawIgnite = false;
new bool:isLashingClaw = false;
new bool:isInfernoClaw = false;
new bool:isKevlarSkin = false;

new Float:startPosition[MAXPLAYERS+1][3];
new Float:endPosition[MAXPLAYERS+1][3];
new Float:cooldownShunpo[MAXPLAYERS+1] = 0.0;
new Float:cooldownShurikenClaw[MAXPLAYERS+1] = 0.0;

new scignite[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "[L4D2] Destructive Hunter",
    author = "Mortiegama",
    description = "Allows for unique Hunter abilities to the destructive beast.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?p=2097674#post2097674"
}

	//Special Thanks:
	//n3wton - Jockey Pounce Damage:
	//http://forums.alliedmods.net/showthread.php?p=1172322
	
public OnPluginStart()
{
	CreateConVar("l4d_dhm_version", PLUGIN_VERSION, "Destructive Hunter Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarInfernoClaw = CreateConVar("l4d_dhm_infernoclaw", "1", "Enables the ability Inferno Claw which adds extra damage to Survivors when Hunter is on fire. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarInfernoClawDamage = CreateConVar("l4d_dhm_infernoclawdamage", "3", "Amount of extra damage caused by Inferno Claw. (Def 3)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarKevlarSkin = CreateConVar("l4d_dhm_kevlarskin", "1", "Enables the ability Kevlar Skin, which allows the Hunter to take reduced damage from fire. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarLashingClaw = CreateConVar("l4d_dhm_lashingclaw", "1", "Enables the ability for the Hunter to lash at nearby survivors while pounced, sending the breaker flying and hurting them. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarLashingClawChance = CreateConVar("l4d_dhm_lashingclawchance", "15", "Chance that a Survivor will be hit from the Hunter's Lashing Claws. (Def 15)(15 = 15%)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarLashingClawDamage = CreateConVar("l4d_dhm_lashingclawdamage", "7", "Amount of damage the Lashing Claws will cause. (Def 7)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarLashingClawRange = CreateConVar("l4d_dhm_lashingclawrange", "400.0", "Distance the Hunter's Lashing Claws reach while pounced. (Def 400.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarLashingClawPower = CreateConVar("l4d_dhm_lashingclawpower", "200.0", "Power behind the Lashing Claws. (Def 200.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarSledgehammer = CreateConVar("l4d_dhm_sledgehammer", "1", "Enables the ability for the Hunter to inflict damage based on the distance of the pounce. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSledgehammerCap = CreateConVar("l4d_dhm_sledgehammercap", "100", "Maximum amount of damage the Hunter can inflict while pouncing. (Should be Survivor health max). (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSledgehammerMultiplier = CreateConVar("l4d_dhm_sledgehammermultiplier", "1.0", "Amount to multiply the damage dealt by the Hunter when pouncing. (Def 1.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarShunpo = CreateConVar("l4d_dhm_shunpo", "1", "Enables the ability for the Hunter to activate Shunpo when taking damage. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarShunpoAmount = CreateConVar("l4d_dhm_shunpoamount", "0.2", "Percent of damage the Hunter avoids while using Shunpo. (Def 0.2)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarShunpoCooldown = CreateConVar("l4d_dhm_shunpocooldown", "5.0", "Cooldown period after the Shunpo has been used before the next Shunpo. (Def 5.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarShunpoDuration = CreateConVar("l4d_dhm_shunpoduration", "3.0", "Amount of time the Shunpo will last. (Def 3.0)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarShurikenClaw = CreateConVar("l4d_dhm_shurikenclaw", "1", "Enables the ability for the Hunter to throw Shuriken Claws at the Survivor. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarShurikenClawCooldown = CreateConVar("l4d_dhm_shurikenclawcooldown", "1.5", "Amount of time between Shuriken Claw throws. (Def 1.5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarShurikenClawDamage = CreateConVar("l4d_dhm_shurikenclawdamage", "2", "Amount of damage the Shuriken Claws deal to Survivors that are hit. (Def 2)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarShurikenClawRange = CreateConVar("l4d_dhm_shurikenclawrange", "700", "Distance the Hunter is able to throw the Shuriken Claws. (Def 700)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarShurikenClawIgnite = CreateConVar("l4d_vts_shurikenclawignite", "1", "Allows the Hunter to ignite Survivors with Shuriken Claw while on fire. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarShurikenClawIgniteChance = CreateConVar("l4d_vts_shurikenclawignitechance", "50", "Chance that the Shuriken Claw will ignite a Survivor. (50 = 50%). (Def 50)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarShurikenClawIgniteDuration = CreateConVar("l4d_vts_shurikenclawigniteduration", "6", "For how many seconds will the Survivor remain ignited. (Def 6)", FCVAR_PLUGIN, true, 1.0, false, _);
	cvarShurikenClawIgniteDamage = CreateConVar("l4d_vts_shurikenclawignitedamage", "2", "How much damage is by the flames each second. (Def 2)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarAnnounce = CreateConVar("l4d_dhm_announce", "1", "Will annoucements be made to the Survivors?");
	
	HookEvent("lunge_pounce", Event_LungePounce);
	HookEvent("ability_use", Event_AbilityUse);
	HookEvent("player_death", Event_PlayerDeath);
	//HookEvent("pounce_end", Event_PounceEnd);
	
	AutoExecConfig(true, "plugin.L4D2.DestructiveHunter");
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (GetConVarInt(cvarInfernoClaw))
	{
		isInfernoClaw = true;
		PrintToServer("Inferno Claw enabled.");
	}
	
	if (GetConVarInt(cvarKevlarSkin))
	{
		isKevlarSkin= true;
		PrintToServer("Kevlar enabled.");
	}
	
	if (GetConVarInt(cvarLashingClaw))
	{
		isLashingClaw = true;
		PrintToServer("Lashing Claw enabled.");
	}
	
	if (GetConVarInt(cvarShurikenClaw))
	{
		isShurikenClaw = true;
		PrintToServer("Shuriken Claw enabled.");
	}
	
	if (GetConVarInt(cvarShurikenClawIgnite))
	{
		isShurikenClawIgnite = true;
		PrintToServer("Ignite enabled.");
	}
	
	if (GetConVarInt(cvarShunpo))
	{
		isShunpo = true;
		PrintToServer("Shunpo enabled.");
	}
	
	if (GetConVarInt(cvarSledgehammer))
	{
		isSledgehammer = true;
		PrintToServer("Sledgehammer enabled.");
	}

	if (GetConVarInt(cvarAnnounce))
	{
		isAnnounce = true;
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
	PrecacheParticle("fire_small_01");
	PrecacheParticle("fire_small_base");
	PrecacheParticle("fire_small_flameouts");
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

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidDeadHunter(client))
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage_KevlarSkin);
	}
}

public Event_AbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(client))
	{
		decl String:infAbility[24];
		GetEventString(event, "ability", infAbility, 24);
		
		if (StrEqual(infAbility, "ability_lunge", false) == true)
		{
			GetClientAbsOrigin(client, startPosition[client]);
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidHunter(victim))
	{
		if (isShunpo && IsValidClient(attacker) && IsShunpoReady(victim))
		{
			new Float:damagemod = GetConVarFloat(cvarShunpoAmount);
			
			if (FloatCompare(damagemod, 1.0) != 0)
			{
				damage = damage * damagemod;
			}
			
			cvarShunpoTimer[victim] = CreateTimer(GetConVarFloat(cvarShunpoDuration), Timer_Shunpo, victim);
			PrintHintText(victim, "You have activated Shunpo and are taking reduced damage.");
		}
		
		if ((damagetype == 8 || damagetype == 2056 || damagetype == 268435464) && isKevlarSkin)
		{
			damage = 0.0;
			SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
			cvarKevlarSkinTimer[victim] = CreateTimer(0.2, Timer_KevlarSkin, victim);
			
			return Plugin_Handled;
		}
	}
	
	if (IsValidHunter(attacker))
	{
		if (isInfernoClaw && IsPlayerOnFire(attacker) && IsValidClient(victim))
		{
			new Float:damagemod = GetConVarFloat(cvarInfernoClawDamage);
						
			if (FloatCompare(damagemod, 1.0) != 0)
			{
				damage = damage + damagemod;
			}
		}
	}

	return Plugin_Changed;
}

public Action:OnTakeDamage_KevlarSkin(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (damagetype == 8 || damagetype == 2056 || damagetype == 268435464)
	{
		damage = 0.0;

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:Timer_KevlarSkin(Handle:timer, any:victim)
{
	SDKHook(victim, SDKHook_OnTakeDamage, OnTakeDamage_KevlarSkin);
	IgniteEntity(victim, 6000.0);
	
	if (cvarKevlarSkinTimer[victim] != INVALID_HANDLE)
	{
		KillTimer(cvarKevlarSkinTimer[victim]);
		cvarKevlarSkinTimer[victim] = INVALID_HANDLE;
	}
				
	return Plugin_Stop;
}

public Event_LungePounce (Handle:event, const String:name[], bool:dontBrodcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (IsValidClient(client) && IsValidClient(victim))
	{
		if (isSledgehammer)
		{
			Event_Sledgehammer(client, victim);
		}
		
		if (isLashingClaw)
		{
			cvarLashingClawTimer[client] = CreateTimer(1.0, Timer_LashingClaw, client, TIMER_REPEAT);
		}
	}
}

public Action:Timer_LashingClaw(Handle:timer, any:attacker)
{
	if (!IsValidClient(attacker) || GetClientTeam(attacker) != 3 || !IsHunterPounced(attacker))
	{
		if (cvarLashingClawTimer[attacker] != INVALID_HANDLE)
		{
			KillTimer(cvarLashingClawTimer[attacker]);
			cvarLashingClawTimer[attacker] = INVALID_HANDLE;
		}	
	
		return Plugin_Stop;
	}

	for (new victim=1; victim<=MaxClients; victim++)
	
	if (IsValidClient(victim) && IsValidClient(attacker) && GetClientTeam(victim) == 2 && IsHunterPounced(attacker))
	{
		new pouncee = GetEntPropEnt(attacker, Prop_Send, "m_pounceVictim");
		new LashingClawChance = GetRandomInt(0, 99);
		new LashingClawPercent = (GetConVarInt(cvarLashingClawChance));
		
		if (victim != pouncee && LashingClawChance < LashingClawPercent)
		{
			decl Float:v_pos[3];
			GetClientEyePosition(victim, v_pos);		
			decl Float:targetVector[3];
			decl Float:distance;
			new Float:range = GetConVarFloat(cvarLashingClawRange);
			GetClientEyePosition(attacker, targetVector);
			distance = GetVectorDistance(targetVector, v_pos);
			//PrintToChatAll("Distance: %f attacker: %n", distance, victim);
			
			if (distance <= range)
			{
				decl Float:HeadingVector[3], Float:AimVector[3];
				new Float:power = GetConVarFloat(cvarLashingClawPower);
				
				GetClientEyeAngles(attacker, HeadingVector);
				AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , power);
				AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , power);
				
				decl Float:current[3];
				GetEntPropVector(victim, Prop_Data, VELOCITY_ENTPROP, current);
				
				decl Float:resulting[3];
				resulting[0] = FloatAdd(current[0], AimVector[0]);	
				resulting[1] = FloatAdd(current[1], AimVector[1]);
				resulting[2] = power * SLAP_VERTICAL_MULTIPLIER;
				Fling_LashingClaw(victim, resulting, attacker);
			}
		}
	}
	
	return Plugin_Continue;
}

stock Fling_LashingClaw(victim, Float:vector[3], attacker, Float:incaptime = 3.0)
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
	Damage_LashingClaw(attacker, victim);
}

public Action:Damage_LashingClaw(attacker, victim)
{
	new damage = GetConVarInt(cvarLashingClawDamage);
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
	
	if (isAnnounce) 
	{
		PrintHintText(attacker, "Your claw struck a survivor for %i damage.", damage);
		PrintHintText(victim, "You were lashed by the Hunter's claw for %i damage.", damage);
	}
}

public Event_Sledgehammer(client, victim)
{
	GetClientAbsOrigin(client, endPosition[client]);
	new distance = RoundFloat(GetVectorDistance(startPosition[client], endPosition[client]));
	//PrintToChatAll("Distance = %i.", distance);
	new damage = RoundFloat(distance * 0.02);
	new maxdamage = GetConVarInt(cvarSledgehammerCap);
	new Float:multiplier = GetConVarFloat(cvarSledgehammerMultiplier);
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
		PrintHintText(client, "You leaped %i distance onto a Survivor, causing %i damage.", distance, damage);
		PrintHintText(victim, "A Jockey leapt %i distance on you, causing %i damage.", distance, damage);
	}
}

public Action:Timer_Shunpo(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		PrintHintText(client, "Your Shunpo has worn off, you will take full damage.");
		cooldownShunpo[client] = GetEngineTime();
	}
	
	if (cvarShunpoTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarShunpoTimer[client]);
		cvarShunpoTimer[client] = INVALID_HANDLE;
	}
				
	return Plugin_Stop;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_ATTACK2 && IsValidClient(client) && GetClientTeam(client) == 3 && IsValidHunter(client) && !IsPlayerGhost(client))
	{
		if (isShurikenClaw && IsShurikenClawReady(client) && !IsHunterPounced(client))
		{
			new Float:range = GetConVarFloat(cvarShurikenClawRange);
			for (new victim=1; victim<=MaxClients; victim++)
			
			if (IsValidClient(victim) && GetClientTeam(victim) == 2 && ClientViews(client, victim, range))
			{
				decl Float:attackerPos[3];
				decl Float:victimPos[3];
				GetClientEyePosition(client, attackerPos);
				GetClientEyePosition(victim, victimPos);
				ShowParticle(attackerPos, "hunter_claw_child_spray", 3.0);	
				ShowParticle(victimPos, "hunter_claw_child_spray", 3.0);	
				Damage_ShurikenClaw(client, victim);
				cooldownShurikenClaw[client] = GetEngineTime();
				
				if (isShurikenClawIgnite && IsPlayerOnFire(client))
				{
					CreateParticle(victim, "fire_small_01", 10.0);
					Event_ShurikenClawIgnite(victim, client);
				}
			}
		}
	}
}

public Action:Damage_ShurikenClaw(client, victim)
{
	new damage = GetConVarInt(cvarShurikenClawDamage);
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
		PrintHintText(client, "Your Shuriken Claw inflicted %i damage.", damage);
		PrintHintText(victim, "You were hit with Shuriken Claws, causing %i damage.", damage);
	}
}

public Event_ShurikenClawIgnite(victim, attacker)
{
	new ShurikenClawIgniteChance = GetRandomInt(0, 99);
	new ShurikenClawIgnitePercent = (GetConVarInt(cvarShurikenClawIgniteChance));

	if (IsValidClient(victim) && GetClientTeam(victim) == 2 && ShurikenClawIgniteChance < ShurikenClawIgnitePercent)
	{
		if(scignite[victim] <= 0)
		{
			scignite[victim] = (GetConVarInt(cvarShurikenClawIgniteDuration));
			
			new Handle:dataPack = CreateDataPack();
			cvarShurikenClawIgniteTimer[victim] = CreateDataTimer(1.0, Timer_ShurikenClawIgnite, dataPack, TIMER_REPEAT);
			WritePackCell(dataPack, victim);
			WritePackCell(dataPack, attacker);
		}
	}
}

public Action:Timer_ShurikenClawIgnite(Handle:timer, any:dataPack) 
{
	ResetPack(dataPack);
	new victim = ReadPackCell(dataPack);
	new attacker = ReadPackCell(dataPack);

	if (IsValidClient(victim))
	{
		if(scignite[victim] <= 0)
		{
			if (cvarShurikenClawIgniteTimer[victim] != INVALID_HANDLE)
			{
				KillTimer(cvarShurikenClawIgniteTimer[victim]);
				cvarShurikenClawIgniteTimer[victim] = INVALID_HANDLE;
			}
				
			return Plugin_Stop;
		}

		Damage_ShurikenClawIgnite(victim, attacker);
			
		if(scignite[victim] > 0) 
		{
			scignite[victim] -= 1;
		}
	}
	
	return Plugin_Continue;
}

public Action:Damage_ShurikenClawIgnite(victim, attacker)
{
	new damage = GetConVarInt(cvarShurikenClawIgniteDamage);
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

CreateParticle(victim, String:particlename[], Float:time)
{
	new entity = CreateEntityByName("info_particle_system");

	DispatchKeyValue(entity, "effect_name", particlename);
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start");

	// Parent attachment
	SetVariantString("!activator"); 
	AcceptEntityInput(entity, "SetParent", victim);
	SetVariantString("forward");
	AcceptEntityInput(entity, "SetParentAttachment");

	// Position particles
	new Float:vPos[3];
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

	// Refire
	SetVariantString("OnUser1 !self:Stop::2.9:-1");
	AcceptEntityInput(entity, "AddOutput");
	SetVariantString("OnUser1 !self:FireUser2::3:-1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");

	SetVariantString("OnUser2 !self:Start::0:-1");
	AcceptEntityInput(entity, "AddOutput");
	SetVariantString("OnUser2 !self:FireUser1::0:-1");
	AcceptEntityInput(entity, "AddOutput");
	
	time = GetConVarFloat(cvarShurikenClawIgniteDuration);
	
	CreateTimer(time, DeleteParticles, entity, TIMER_FLAG_NO_MAPCHANGE);
	return EntIndexToEntRef(entity);
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

public IsPlayerGhost(client)
{
	if (IsValidClient(client))
	{
		if (GetEntProp(client, Prop_Send, "m_isGhost")) return true;
		else return false;
	}
	else return false;
}

public IsValidHunter(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		
		if (class == ZOMBIECLASS_HUNTER)
			return true;
		
		return false;
	}
	
	return false;
}

public IsValidDeadHunter(client)
{
	if (IsValidDeadClient(client))
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		
		if (class == ZOMBIECLASS_HUNTER)
			return true;
		
		return false;
	}
	
	return false;
}

public IsHunterPounced(client)
{
	new victim = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
	if (victim > 0 && victim != client)
		return true;
		
	return false;
}

public IsShunpoReady(client)
{
	return ((GetEngineTime() - cooldownShunpo[client]) > GetConVarFloat(cvarShunpoCooldown));
}

public IsShurikenClawReady(client)
{
	return ((GetEngineTime() - cooldownShurikenClaw[client]) > GetConVarFloat(cvarShurikenClawCooldown));
}

public IsPlayerOnFire(client)
{
	if (GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONFIRE) return true;
		else return false;
}