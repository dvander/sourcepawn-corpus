#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION  "1.0"

new Handle:TauntDist;
new Handle:DamageExplode;
new Handle:DamageBroken;
new Handle:RadiusDist;
new Handle:RadiusDmg;
new Handle:RadiusSelfDmg;
new Handle:HitDelay;

public Plugin:myinfo = {
	name = "Caber Taunt Kill",
	author = "MasterOfTheXP",
	description = "I'm gointa liquify ya.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

new caberDmg = 0;

public OnPluginStart()
{
	TauntDist = CreateConVar("sm_cabertaunt_dist","150.0","Maximum range on the Ullapool Caber taunt kill.", FCVAR_NONE, true, 0.0);
	DamageExplode = CreateConVar("sm_cabertaunt_explode","600","Damage to deal on taunt kill with an un-exploded Caber.", FCVAR_NONE, true, 0.0);
	DamageBroken = CreateConVar("sm_cabertaunt_broken","500","Damage to deal on taunt kill with a broken Caber.", FCVAR_NONE, true, 0.0);
	RadiusDist = CreateConVar("sm_cabertaunt_radiusdist","150.0","To be caught within the explosion of the Caber taunt kill, you must be this close to the attacking Demoman.", FCVAR_NONE, true, 0.0);
	RadiusDmg = CreateConVar("sm_cabertaunt_radiusdmg","200","Damage to deal when caught within the explosion of the Caber taunt kill.", FCVAR_NONE, true, 0.0);
	RadiusSelfDmg = CreateConVar("sm_cabertaunt_radiusselfdmg","50","Damage to deal to the Demoman when the Caber explodes, due to the taunt kill.", FCVAR_NONE, true, 0.0);
	HitDelay = CreateConVar("sm_cabertaunt_hitdelay","3.8","How long it takes for the actual attack after the Caber's taunt is started.", FCVAR_NONE, true, 0.0);
	AddCommandListener(Command_taunt, "taunt");
	AddCommandListener(Command_taunt, "+taunt");
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action:Command_taunt(client, const String:command[], args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	if (!IsPlayerAlive(client)) return Plugin_Continue;
	if (TF2_GetPlayerClass(client) != TFClass_DemoMan) return Plugin_Continue;
	if (TF2_IsPlayerInCondition(client, TFCond_Taunting)) return Plugin_Continue;
	new wepEnt, meleeWeapon;
	if ((wepEnt = GetPlayerWeaponSlot(client, 2))!=-1) meleeWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
	if (meleeWeapon == 307) CreateTimer(GetConVarFloat(HitDelay), CaberTauntKill, client);
	return Plugin_Continue;
}

public Action:CaberTauntKill(Handle:timer, any:client)
{
	if (!IsValidClient(client)) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	if (TF2_GetPlayerClass(client) != TFClass_DemoMan) return Plugin_Handled;
	if (!TF2_IsPlayerInCondition(client, TFCond_Taunting)) return Plugin_Handled;
	new wepEnt, meleeWeapon;
	if ((wepEnt = GetPlayerWeaponSlot(client, 2))!=-1) meleeWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
	if (meleeWeapon != 307) return Plugin_Handled;
	new String:cls[64];
	new Float:vecClientEyePos[3];
	new Float:vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);

	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	// Most of this traceray stuff is from the Khopesh Climber code found in Give Weapon
	if (!TR_DidHit(INVALID_HANDLE)) return Plugin_Handled;

	new target = TR_GetEntityIndex(INVALID_HANDLE);
	GetEdictClassname(target, cls, sizeof(cls));
	if (!StrEqual(cls, "player")) return Plugin_Handled;

	new Float:fNormal[3];
	TR_GetPlaneNormal(INVALID_HANDLE, fNormal);
	GetVectorAngles(fNormal, fNormal);

	if (fNormal[0] >= 30.0 && fNormal[0] <= 330.0) return Plugin_Handled;
	if (fNormal[0] <= -30.0) return Plugin_Handled;

	new Float:pos[3];
	TR_GetEndPosition(pos);
	new Float:distance = GetVectorDistance(vecClientEyePos, pos);

	if (distance >= GetConVarFloat(TauntDist)) return Plugin_Handled;
	if (!IsPlayerAlive(target)) return Plugin_Handled;
	new bool:FF = GetConVarBool(FindConVar("mp_friendlyfire"));
	if (GetClientTeam(target) == GetClientTeam(client) && !FF) return Plugin_Handled;
	new String:snd[50];
	Format(snd, 50, "weapons/bottle_hit_flesh%i.wav", GetRandomInt(1,3));
	PrecacheSound(snd);
	EmitSoundToAll(snd, client);
	if (GetEntProp(wepEnt, Prop_Send, "m_iDetonated"))
	{
		caberDmg = 1;
		DoDamage(client, target, GetConVarInt(DamageBroken));
	}
	else
	{
		caberDmg = 2;
		DoDamage(client, target, GetConVarInt(DamageExplode));
		DoDamage(client, client, GetConVarInt(RadiusSelfDmg));
		SetEntProp(wepEnt, Prop_Send, "m_bBroken", 1);
		SetEntProp(wepEnt, Prop_Send, "m_iDetonated", 1);
		new explosion = CreateEntityByName("env_explosion");
		new Float:clientPos[3];
		GetClientAbsOrigin(client, clientPos);
		if (explosion)
		{
			DispatchSpawn(explosion);
			TeleportEntity(explosion, clientPos, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(explosion, "Explode", -1, -1, 0);
			RemoveEdict(explosion);
		}
		for (new z = 1; z <= MaxClients; z++)
		{
			if (!IsValidClient(z)) continue;
			if (!IsPlayerAlive(z)) continue;
			if (GetClientTeam(z) == GetClientTeam(client) && !FF) continue;
			new Float:zPos[3];
			GetClientAbsOrigin(z, zPos);
			new Float:Dist = GetVectorDistance(clientPos, zPos);
			if (Dist > GetConVarFloat(RadiusDist)) continue;
			caberDmg = 2;
			DoDamage(client, z,GetConVarInt(RadiusDmg));
		}
	}
	return Plugin_Handled;
}

stock DoDamage(client, target, amount)
{
	new pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt)
	{
		DispatchKeyValue(target, "targetname", "explodeme");
		DispatchKeyValue(pointHurt, "DamageTarget", "explodeme");
		new String:dmg[15];
		Format(dmg, 15, "%i", amount);
		DispatchKeyValue(pointHurt, "Damage", dmg);
		DispatchKeyValue(pointHurt, "DamageType", "0");

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", client);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(target, "targetname", "");
		RemoveEdict(pointHurt);
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (caberDmg == 0) return Plugin_Continue;
	if (caberDmg == 1) SetEventString(event, "weapon", "ullapool_caber");
	if (caberDmg == 2) SetEventString(event, "weapon", "ullapool_caber_explosion");
	if (caberDmg == 1) SetEventString(event, "weapon_logclassname", "taunt_caber");
	if (caberDmg == 2) SetEventString(event, "weapon_logclassname", "taunt_caber");
	caberDmg = 0;
	return Plugin_Continue;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return (entity != data);
}