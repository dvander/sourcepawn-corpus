#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"
public Plugin:myinfo =
{
	name = "[TF2] Sniper PhysDamage Fix",
	author = "FlaminSarge",
	description = "Makes the Sniper Rifles able to hit things again",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("tf_sniperphysdmg_version", PLUGIN_VERSION, "[TF2] Sniper PhysDamage Fix version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
//	RegAdminCmd("sm_checkdmgs", Check, ADMFLAG_ROOT);
}
/*public Action:Check(client, args)
{
	if (client == 0) return Plugin_Handled;
	decl Float:pos[3], Float:dist;
	new target = GetClientAimEntity3(client, dist, pos);
	if (target > 0) SDKHook(target, SDKHook_OnTakeDamage, OnTakeDamage);
	return Plugin_Handled;
}
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	PrintToChatAll("%d %d %d %.2f %b %d %.2f %.2f %.2f %.2f %.2f %.2f", client, attacker, inflictor, damage, damagetype, weapon, damageForce[0], damageForce[1], damageForce[2], damagePosition[0], damagePosition[1], damagePosition[2]);
}*/
stock IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (IsValidClient(client, false) && IsValidEntity(weapon) && weapon > MaxClients) DoSniperDamageCheck(client, weapon, weaponname);
}

stock DoSniperDamageCheck(client, weapon, String:weaponname[])
{
	if (strncmp(weaponname, "tf_weapon_sniperrifle", 21, false) != 0) return;
	new index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	new Float:chargelevel = GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage");
	new damage = 50 + RoundFloat(chargelevel * 100 / 150);
	if (index == 526 && chargelevel == 150.0) damage = 173;
	decl Float:eyepos[3], Float:pos[3], Float:force[3], Float:dist;
	new target = GetClientAimEntity3(client, dist, pos);
	if (target <= 0 || !IsValidEdict(target)) return;
	if (dist > 8192) return;
	decl String:classname[32];
	GetEdictClassname(target, classname, sizeof(classname));
	if (StrContains(classname, "pumpkin", false) == -1
		&& StrContains(classname, "breakable", false) == -1
		&& StrContains(classname, "physics", false) == -1
		&& StrContains(classname, "physbox", false) == -1
		&& StrContains(classname, "button", false) == -1
	) return;
	GetClientEyePosition(client, eyepos);
	SubtractVectors(eyepos, pos, force);
	NormalizeVector(force, force);
	ScaleVector(force, 2000.0);
	SDKHooks_TakeDamage(target, client, client, float(damage), DMG_BULLET|(TF2_IsPlayerInCondition(client, TFCond_Zoomed) ? DMG_AIRBOAT : 0), client, force, pos);
}

stock GetClientAimEntity3(client, &Float:distancetoentity, Float:endpos[3])	//Javalia
{
	decl Float:cleyepos[3], Float:cleyeangle[3];
	GetClientEyePosition(client, cleyepos);
	GetClientEyeAngles(client, cleyeangle);
	new Handle:traceresulthandle = INVALID_HANDLE;
	traceresulthandle = TR_TraceRayFilterEx(cleyepos, cleyeangle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfOrPlayers, client);
	if (TR_DidHit(traceresulthandle) == true)
	{
		TR_GetEndPosition(endpos, traceresulthandle);
		distancetoentity = GetVectorDistance(cleyepos, endpos);
		new entindextoreturn = TR_GetEntityIndex(traceresulthandle);
		CloseHandle(traceresulthandle);
		return entindextoreturn;
	}
	CloseHandle(traceresulthandle);
	return -1;
}
public bool:TraceRayDontHitSelfOrPlayers(entity, mask, any:data)
{
	return (entity != data && !IsValidClient(entity));
}