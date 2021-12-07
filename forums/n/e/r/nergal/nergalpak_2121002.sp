#pragma semicolon 1
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <customweaponstf>
#include <tf2items>
#include <tf2attributes>

#define PLUGIN_VERSION "beta 1"

public Plugin:myinfo = {
    name = "Custom Weapons: NergalPak",
    author = "Nergal/Assyrian",
    description = "Attributes <3 from Nergal :3",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=236242"
};

/* *** Attributes In This Plugin ***
No Damage Falloff
No Damage Rampup
Reducing Victim's Ammo on hit
Giving Ammo from Metal via wrench.
*/

new bool:HasAttribute[2049];
new bool:HasAttribClient[MAXPLAYERS+1];

new bool:NoDamageFallOff[2049];
new Float:NoDamageFallOffMaxDist[2049] = {1024.0, ...}; //To get the farthest distance for fall off, divide 512 by fall off percentage.
//rocket launcher fall off = 0.53 or 53%; 512/0.53 = 966.04. for guns with 50% fall off, dist is 1024.0

new bool:NoDamageRampUp[2049];
new Float:NoDamageRampUpMinDist[2049] = {341.33, ...};//To get the min distance for fall off, divide 512 with the rampup.
//rocket launcher rampup = 1.25 or 125%; 512/1.25 = 409.6. For guns with 150% rampup, the dist is 341.33

new Float:ReduceAmmoOnHitVal[2049] = {1.0, ...}; //percentage, poot lower than 1.0 to reduce ammo, 1.0+ for increased ammo (lol?)
new bool:ReduceAmmoOnHit[2049];

new bool:AmmoFromWrench[2049];
new Float:AmmoFromWrenchAmount[2049] = {1.0, ...}; //percentage, put higher than 1.0 to give ammo and lose metal
//reverse to GET metal and troll teammates? hmmm....

new bool:ShootsMultiRockets[2049]; //props to [E]c
new RocketAmount[2049] = {1, ...};

new bool:MeleeDmgResist[MAXPLAYERS+1];
new Float:MeleeDmgResistAmount[MAXPLAYERS+1] = {1.0, ...};

new bool:MadMilk[2049];
new Float:MadMilkDuration[2049] = {0.0, ...};

new bool:ReverseDamageFallOff[2049];
new Float:ReverseDamageFallOffDist[2049] = {1024.0, ...};

new bool:EngineerHaulSpeed[MAXPLAYERS+1];
new Float:EngineerHaulSpeedAmount[MAXPLAYERS+1] = {1.0, ...};

new AmmoTable[MAXPLAYERS+1][6];

public OnPluginStart()
{
	HookEvent("player_spawn", event_player_spawn);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		OnClientPutInServer(i);
	}
	//These goodies are for later :3

	/*new m_bCarryingObject = FindSendPropInfo("CTFPlayer", "m_bCarryingObject");
	m_flMaxspeed = FindSendPropInfo("CTFPlayer", "m_flMaxspeed");
	g_jumpOffset = FindSendPropInfo("CTFPlayer", "m_iAirDash");
	g_cloakOffset = FindSendPropInfo("CTFPlayer", "m_flCloakMeter");
	m_iStunFlags = FindSendPropInfo("CTFPlayer","m_iStunFlags");
	m_iMovementStunAmount = FindSendPropInfo("CTFPlayer","m_iMovementStunAmount");
	m_hHealingTarget = FindSendPropInfo("CWeaponMedigun", "m_hHealingTarget");
	m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond");
	m_nDisguiseTeam = FindSendPropInfo("CTFPlayer","m_nDisguiseTeam");
	m_nDisguiseClass = FindSendPropInfo("CTFPlayer","m_nDisguiseClass");
	m_nWaterLevel = FindSendPropOffs("CBasePlayer", "m_nWaterLevel");
	m_hOwnerEntity = FindSendPropOffs("CTFWearable", "m_hOwnerEntity");
	m_fFlags = FindSendPropOffs("CBasePlayer", "m_fFlags");
	g_oFOV = FindSendPropOffs("CBasePlayer", "m_iFOV");
	g_oDefFOV = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
	m_bCarried = FindSendPropInfo("CBaseObject", "m_bCarried");*/
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	SDKHook(client, SDKHook_PreThink, OnPreThink);
}
public OnClientDisconnect(client)
{
	EngineerHaulSpeed[client] = false;
	MeleeDmgResist[client] = false;
	EngineerHaulSpeedAmount[client] = 1.0;
}
public OnEntityDestroyed(Ent)
{
	if (Ent <= 0 || Ent > 2048) return;
	HasAttribute[Ent] = false;
	ShootsMultiRockets[Ent] = false;
	RocketAmount[Ent] = 1;
	AmmoFromWrench[Ent] = false;
	AmmoFromWrenchAmount[Ent] = 1.0;
	ReduceAmmoOnHit[Ent] = false;
	NoDamageRampUp[Ent] = false;
	NoDamageFallOff[Ent] = false;
	MadMilk[Ent] = false;
	ReverseDamageFallOff[Ent] = false;
}
public Action:CustomWeaponsTF_OnAddAttribute(weapon, client, const String:attrib[], const String:plugin[], const String:value[])
{
	if (!StrEqual(plugin, "nergalpak")) return Plugin_Continue;
	new Action:action;
	if (StrEqual(attrib, "no damage falloff"))
	{
		NoDamageFallOffMaxDist[weapon] = StringToFloat(value);
		NoDamageFallOff[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "no damage rampup"))
	{
		NoDamageRampUpMinDist[weapon] = StringToFloat(value);
		NoDamageRampUp[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "reduce victim ammo on hit"))
	{
		ReduceAmmoOnHitVal[weapon] = StringToFloat(value); //percentage
		ReduceAmmoOnHit[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "ammo from wrench"))
	{
		AmmoFromWrenchAmount[weapon] = StringToFloat(value); //Combine with other attribs that deal with metal
		AmmoFromWrench[weapon] = true;
		action = Plugin_Handled; //percentage of metal is taken and becomes ammo for teammate.
	}
	else if (StrEqual(attrib, "shoots multirockets"))
	{
		RocketAmount[weapon] = StringToInt(value);
		ShootsMultiRockets[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "damage from melee"))
	{
		MeleeDmgResistAmount[client] = StringToFloat(value); //lower value for less damage, opp. for higher
		MeleeDmgResist[client] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "mad milk hit"))
	{
		MadMilkDuration[weapon] = StringToFloat(value);
		MadMilk[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "reverse damage falloff"))
	{
		ReverseDamageFallOffDist[weapon] = StringToFloat(value);
		ReverseDamageFallOff[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "engie haul speed"))
	{
		EngineerHaulSpeedAmount[client] = StringToFloat(value); //255 (hauling speed) multiplied by client variable
		EngineerHaulSpeed[client] = true;
		action = Plugin_Handled;
	}
	if (!HasAttribute[weapon]) HasAttribute[weapon] = bool:action;
	if (!HasAttribClient[client]) HasAttribClient[client] = bool:action;
	return action;
}
public OnPreThink(client) //ܩܕܡ ܚܫܘܒܐ ;<---- This is Syriac :3 ; props to mecha
{
	if (!IsValidClient(client)) return;
	if (!HasAttribClient[client]) return;

	if (EngineerHaulSpeed[client] && TF2_GetPlayerClass(client) == TFClass_Engineer && GetEntProp(client, Prop_Send, "m_bCarryingObject"))
	{
		new Float:fSpeed = EngineerHaulSpeedAmount[client]*225.0;
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", fSpeed);
	}
	return;
}
public Action:TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	new weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if (!IsValidClient(attacker)) return Plugin_Continue; // Attacker isn't valid, so the weapon won't be either.
	if (weapon == -1) return Plugin_Continue; // Weapon is invalid, so it won't be custom.
	if (!HasAttribute[weapon]) return Plugin_Continue; // Weapon is valid, but doesn't have one of our attributes. We don't care!

	if (AmmoFromWrench[weapon] && IsValidClient(victim))
	{
		if (GetClientTeam(attacker) == GetClientTeam(victim))
		{
			if (TF2_GetPlayerClass(attacker) == TFClass_Engineer)
			{
				new iCurrentMetal = GetEntProp(attacker, Prop_Data, "m_iAmmo", 4, 3);
				new Float:percent = AmmoFromWrenchAmount[weapon]-1.0;
				new OnHitAmmo;

				new pool[2];
				pool[0] = GetAmmo(victim, 0);
				pool[1] = GetAmmo(victim, 1);

				new String:clname[64];
				if (IsValidEdict(weapon)) GetEdictClassname(weapon, clname, sizeof(clname));
				
				if (StrEqual(clname, "tf_weapon_wrench", false) || StrEqual(clname, "tf_weapon_robot_arm", false))
				{
					for (new i = 0; i <= 1; i++)
					{
						if (pool[i] < AmmoTable[victim][i]) //checks all weapons
						{
							OnHitAmmo = RoundFloat(percent*(AmmoTable[victim][i])); //10
							OnHitAmmo = (iCurrentMetal < OnHitAmmo) ? iCurrentMetal : OnHitAmmo; //10 still
							OnHitAmmo = (AmmoTable[victim][i]-pool[i] < OnHitAmmo) ? AmmoTable[victim][i]-pool[i] : OnHitAmmo; // 200-100 = 100 < 10? nope, still 10 :3
							SetAmmo(victim, i, GetAmmo(victim, i)+OnHitAmmo); //100+10 :3
						}
					}
					new iNewMetal = iCurrentMetal-(OnHitAmmo/2); 
					SetEntProp(attacker, Prop_Data, "m_iAmmo", iNewMetal, 4, 3);
				}
			}
		}
		else return Plugin_Continue;
	}
	return Plugin_Continue;
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (!IsValidClient(attacker)) return Plugin_Continue; // Attacker isn't valid, so the weapon won't be either.
	if (weapon == -1) return Plugin_Continue; // Weapon is invalid, so it won't be custom.
	if (!HasAttribute[weapon]) return Plugin_Continue; // Weapon is valid, but doesn't have one of our attributes. We don't care!

	// If we've gotten this far, we might need to take "action" c:
	// But, seriously, we might. Our "action" will be set to Plugin_Changed if we
	// change anything about this damage.
	new Action:action;

	new wepcache[2];
	decl Float:Pos[3];
	decl Float:Pos2[3];
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", Pos);//Spot of attacker
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", Pos2); //Spot of victim
	new Float:dist = GetVectorDistance(Pos, Pos2, false); //Calculates the distance between target and attacker
	new Float:min = 512.0;
	new String:classname[64];
	new String:strEntname[32];
	if (IsValidEdict(inflictor)) GetEntityClassname(inflictor, strEntname, sizeof(strEntname));
	if (IsValidEdict(weapon)) GetEdictClassname(weapon, classname, sizeof(classname));

	if (NoDamageFallOff[weapon] && IsValidClient(victim) && !(damagetype & DMG_CRIT))
	{
		dist = (dist > NoDamageFallOffMaxDist[weapon]) ? NoDamageFallOffMaxDist[weapon] : dist;
		damage *= (dist/min);
		action = Plugin_Changed;
	}
	if (NoDamageRampUp[weapon] && IsValidClient(victim) && !(damagetype & DMG_CRIT))
	{
		dist = (dist < NoDamageRampUpMinDist[weapon]) ? NoDamageRampUpMinDist[weapon] : dist;
		damage *= (dist/min);
		action = Plugin_Changed;
	}
	if (ReverseDamageFallOff[weapon] && IsValidClient(victim) && attacker != victim)
	{
		dist = (dist > ReverseDamageFallOffDist[weapon]) ? ReverseDamageFallOffDist[weapon] : dist;
		dist *= 0.003;
		damage *= dist;
		action = Plugin_Changed;
	}
	if (ReduceAmmoOnHit[weapon] && IsValidClient(victim))
	{
		wepcache[0] = GetAmmo(victim, 0);
		wepcache[1] = GetAmmo(victim, 1);	
		for (new g = 0; g <= 1; g++)
		{
			new gunlaws = RoundFloat(wepcache[g]*(ReduceAmmoOnHitVal[weapon]/1.0));
			new ammoe = (wepcache[g]-gunlaws < 1) ? 0 : wepcache[g]-gunlaws;
			SetAmmo(victim, g, ammoe);
		}
	}
	if (MadMilk[weapon] && IsValidClient(victim) && attacker != victim && GetClientTeam(attacker) != GetClientTeam(victim))
	{
		TF2_AddCondition(victim, TFCond_Milked, MadMilkDuration[weapon]);
	}
	if (MeleeDmgResist[victim] && IsValidClient(victim) && attacker != victim)
	{
		if (weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee)) damage *= MeleeDmgResistAmount[victim];
		//PrintToConsole(victim, "[NergalPak-TEST] Damage = | %f |", damage);
		//PrintToConsole(attacker, "[NergalPak-TEST] Damage = | %f |", damage);
		action = Plugin_Changed;
	}
	return action;
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!HasAttribute[weapon]) return Plugin_Continue;
	if (ShootsMultiRockets[weapon])
	{
		new Float:vAngles[3], Float:vAngles2[3], Float:vPosition[3], Float:vPosition2[3];
		new Float:Axis = (0.0-(RocketAmount[weapon]*2.5));

		GetClientEyeAngles(client, vAngles2);
		GetClientEyePosition(client, vPosition2);
		new counter = 0;

		vPosition[0] = vPosition2[0];
		vPosition[1] = vPosition2[1];
		vPosition[2] = vPosition2[2];
		for (new i = 0; i <= RocketAmount[weapon]; i++)
		{
			vAngles[0] = vAngles2[0];
			vAngles[1] = vAngles2[1]+Axis;
			Axis += 5.0;
			// avoid unwanted collision
			new i2 = i%4;
			switch (i2)
			{
				case 0:
				{
					counter++;
					vPosition[0] = vPosition2[0] + counter;
				}
				case 1: vPosition[1] = vPosition2[1] + counter;
				case 2: vPosition[0] = vPosition2[0] - counter;
				case 3: vPosition[1] = vPosition2[1] - counter;
			}
			ShootProjectile(client, vPosition, vAngles, "tf_projectile_rocket", 1100.0, 90.0);//too static for my custom taste :3
		}
	}
	return Plugin_Continue;
}
public Action:event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client, false))
		return Plugin_Continue;

	for (new i = 0; i < 5; i++)
	{
		AmmoTable[client][i] = GetAmmo(client, i);
	}
	return Plugin_Continue;
}
ShootProjectile(client, Float:vPosition[3], Float:vAngles[3] = NULL_VECTOR, String:strEntname[], Float:Speed, Float:dmg)
{
	//new String:strEntname[45] = "tf_projectile_spellfireball";
	/*switch (spell)
	{
		case FIREBALL: 		strEntname = "tf_projectile_spellfireball";
		case LIGHTNING: 	strEntname = "tf_projectile_lightningorb";
		case PUMPKIN: 		strEntname = "tf_projectile_spellmirv";
		case PUMPKIN2: 		strEntname = "tf_projectile_spellpumpkin";
		case BATS: 			strEntname = "tf_projectile_spellbats";
		case METEOR: 		strEntname = "tf_projectile_spellmeteorshower";
		case TELE: 			strEntname = "tf_projectile_spelltransposeteleport";
		case BOSS:			strEntname = "tf_projectile_spellspawnboss";
		case ZOMBIEH:		strEntname = "tf_projectile_spellspawnhorde";
		case ZOMBIE:		strEntname = "tf_projectile_spellspawnzombie";
	}
	switch(spell)
	{
		//These spells have arcs.
		case BATS, METEOR, TELE:
		{
			vVelocity[2] += 32.0;
		}
	}

CTFGrenadePipebombProjectile m_bCritical
CTFProjectile_Rocket m_bCritical
CTFProjectile_SentryRocket m_bCritical
CTFWeaponBaseGrenadeProj m_bCritical
CTFMinigun m_bCritShot
CTFFlameThrower m_bCritFire
CTFProjectile_Syringe
CTFPlayer m_iCritMult
SetEntPropFloat(iProjectile, Prop_Send, "m_flDamage", dmg);
	}*/
	new iTeam = GetClientTeam(client);
	new iProjectile = CreateEntityByName(strEntname);
	
	if (!IsValidEntity(iProjectile))
		return -1;
	
	decl Float:vVelocity[3];
	decl Float:vBuffer[3];
	
	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	
	vVelocity[0] = vBuffer[0]*Speed;
	vVelocity[1] = vBuffer[1]*Speed;
	vVelocity[2] = vBuffer[2]*Speed;
	
	SetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity", client);
	if (IsCritBoosted(client)) SetEntProp(iProjectile, Prop_Send, "m_bCritical", 1);
	else SetEntProp(iProjectile, Prop_Send, "m_bCritical", 0);
	SetEntProp(iProjectile,    Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iProjectile,    Prop_Send, "m_nSkin", (iTeam-2));

	SetVariantInt(iTeam);
	AcceptEntityInput(iProjectile, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iProjectile, "SetTeam", -1, -1, 0);
	if (strcmp(strEntname, "tf_projectile_rocket", false) == 0) SetEntDataFloat(iProjectile, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected")+4, dmg, true);
	else SetEntPropFloat(iProjectile, Prop_Send, "m_flDamage", dmg);
	TeleportEntity(iProjectile, vPosition, vAngles, vVelocity); 
	DispatchSpawn(iProjectile);
	return iProjectile;
}
stock GetAmmo(client, slot)
{
	if (!IsValidClient(client)) return 0;
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		return GetEntData(client, iAmmoTable+iOffset);
	}
	return 0;
}
stock SetAmmo(client, slot, ammo)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}
stock bool:IsCritBoosted(client)
{
	if (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, TFCond_CritCanteen) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph) || TF2_IsPlayerInCondition(client, TFCond_CritOnDamage))
	{
		return true;
	}
	return false;
}
stock bool:IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}
stock ClearTimer(&Handle:Timer)
{
	if (Timer != INVALID_HANDLE)
	{
		CloseHandle(Timer);
		Timer = INVALID_HANDLE;
	}
}
