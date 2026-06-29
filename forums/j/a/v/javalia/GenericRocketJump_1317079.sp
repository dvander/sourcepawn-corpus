/*
 *descriptions here
 */

new const String:PLUGIN_VERSION[60] = "1.0.0.2";

public Plugin:myinfo = {
	
	name = "GenericRocketJump",
	author = "javalia",
	description = "Customizable Rocket Jump",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
};

//uncomment if u wanna use function of these include file
#include <sourcemod>
#include <sdktools>
//#include <cstrike>
#include "sdkhooks"
//#include "vphysics"
#include "stocklib"

//semicolon!!!!
#pragma semicolon 1

new Handle:g_cvarUnassignedTeamEnable = INVALID_HANDLE;
new Handle:g_cvarBlueTeamEnable = INVALID_HANDLE;
new Handle:g_cvarRedTeamEnable = INVALID_HANDLE;

new Handle:g_cvarRocketJumpWeapons = INVALID_HANDLE;

new Handle:g_cvarRocketJumpDamage = INVALID_HANDLE;

new Handle:g_cvarRocketJumpForce = INVALID_HANDLE;

new Handle:g_cvarRocketJumpTeamMate = INVALID_HANDLE;
new Handle:g_cvarRocketJumpEnemy = INVALID_HANDLE;

public OnPluginStart(){

	CreateConVar("genericrocketjumpmod_version", PLUGIN_VERSION, "plugin info cvar", FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	g_cvarUnassignedTeamEnable = CreateConVar("genericrocketjumpmod_unassignedteam_enable", "1", "1 for enable 0 for disable");
	g_cvarBlueTeamEnable = CreateConVar("genericrocketjumpmod_blueteam_enable", "1", "1 for enable 0 for disable");
	g_cvarRedTeamEnable = CreateConVar("genericrocketjumpmod_redteam_enable", "1", "1 for enable 0 for disable");

	g_cvarRocketJumpWeapons = CreateConVar("genericrocketjumpmod_weapons", "grenade_ar2;rpg_missile;hegrenade_projectile", "weapon list of RocketJump, separate with ;");

	g_cvarRocketJumpDamage = CreateConVar("genericrocketjumpmod_damage", "0.2", "damage reduce by rocketjump weapon");

	g_cvarRocketJumpForce = CreateConVar("genericrocketjumpmod_jumpforce", "10.0", "jump force of rocketjump");

	g_cvarRocketJumpTeamMate = CreateConVar("genericrocketjumpmod_teammate", "0", "allow rocket jump by teammate`s fire?");
	g_cvarRocketJumpEnemy = CreateConVar("genericrocketjumpmod_teammate", "0", "allow rocket jump by enemy`s fire?");
	
	AutoExecConfig();

}

public OnMapStart(){

	AutoExecConfig();

}

public OnClientPutInServer(client){

	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageHook);

}

public Action:OnTakeDamageHook(client, &attacker, &inflictor, &Float:damage, &damagetype){
	
	if(~damagetype & DMG_BLAST){
	
		return Plugin_Continue;
	
	}
	
	if(isClientEffectedByRocketJump(client, attacker) && isRocketJumpWeapon(inflictor)){
		
		//자신의 현재 이동속도와, 폭발로 더할 이동속도를 구한다.
		decl Float:vec_PlayerSpeed[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec_PlayerSpeed);
		
		//폭발물로부터 자신의 위치로의 노말벡터를 구한다
		decl Float:vec_PlayerPos[3], Float:vec_InflcitorPos[3], Float:vec_Direction[3];
		
		GetClientAbsOrigin(client, vec_PlayerPos);
		GetEntPropVector(inflictor, Prop_Send, "m_vecOrigin", vec_InflcitorPos);
		
		MakeVectorFromPoints(vec_InflcitorPos, vec_PlayerPos, vec_Direction);
		NormalizeVector(vec_Direction, vec_Direction);
		
		//데미지에 근거해 노말벡터를 키운다.
		ScaleVector(vec_Direction, damage * GetConVarFloat(g_cvarRocketJumpForce));
		AddVectors(vec_PlayerSpeed, vec_Direction, vec_PlayerSpeed);
		
		//데미지를 줄인다
		damage = damage * GetConVarFloat(g_cvarRocketJumpDamage);
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec_PlayerSpeed);
		
		return Plugin_Changed;
		
	}
	
	return Plugin_Continue;
	
}

bool:isClientEffectedByRocketJump(client, attacker){

	//우선 클라의 팀과 공격자의 팀을 구한다
	new clientteam = GetClientTeam(client);
	new attackerteam = IsClientConnectedIngame(attacker) ? GetClientTeam(attacker) : 0;
	
	//클라의 팀이 로켓 점프가 적용되는 팀인가?
	if((clientteam == 0 && GetConVarBool(g_cvarUnassignedTeamEnable))
		|| (clientteam == 2 && GetConVarBool(g_cvarRedTeamEnable))
		|| (clientteam == 3 && GetConVarBool(g_cvarBlueTeamEnable))){
		
		if((client == attacker) || ((clientteam == attackerteam) && GetConVarBool(g_cvarRocketJumpTeamMate))
			|| ((clientteam != attackerteam) && GetConVarBool(g_cvarRocketJumpEnemy))){
		
			return true;
		
		}
		
	}
	
	return false;

}

bool:isRocketJumpWeapon(inflictor){

	new String:weaponname[32];
	GetEdictClassname(inflictor, weaponname, 32);
	
	decl String:cvarstring[256];
	GetConVarString(g_cvarRocketJumpWeapons, cvarstring, 256);
	
	if(StrContains(cvarstring, weaponname, false) != -1){
		
		return true;
		
	}

	return false;
	
}