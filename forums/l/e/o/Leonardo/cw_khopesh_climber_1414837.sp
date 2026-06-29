#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2items>
#include <tf2_stocks>
#define REQUIRE_PLUGIN
#include <tf2autoitems>

public Plugin:myinfo = 
{
	name = "[TF2] CW: Khopesh Climber",
	author = "Mecha The Slag, Leonardo",
	description = "Khopesh Climber's walls climbing",
	version = "1.0.0",
	url = "http://sourcemod.net"
};

public OnPluginStart()
	HookEvent("player_death", Event_PlayerPreDeath,  EventHookMode_Pre);

public Action:Event_PlayerPreDeath(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(iAttacker<=0 || iAttacker>MaxClients || !IsClientConnected(iAttacker) || !IsPlayerAlive(iAttacker))
		return Plugin_Continue;
	
	new iActiveWeapon = GetEntPropEnt(iAttacker, Prop_Send, "m_hActiveWeapon");
	if(GetEventInt(hEvent, "weaponid")!=TF_WEAPON_CLUB || !IsValidEntity(iActiveWeapon))
		return Plugin_Continue;
	
	if(GetEntProp(iActiveWeapon, Prop_Send, "m_iItemDefinitionIndex")==171 && GetEntProp(iActiveWeapon, Prop_Send, "m_iEntityLevel")==-117)
		SetEventString(hEvent, "weapon_logclassname", "khopesh_climber");
	
	return Plugin_Continue;
}

public Action:TF2_CalcIsAttackCritical(iClient, iWeapon, String:sWeaponName[], &bool:bResult)
{
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient) || !IsClientInGame(iClient))
		return Plugin_Continue;
	
	if(StrEqual(sWeaponName, "tf_weapon_club", false) && GetEntProp(iWeapon, Prop_Send, "m_iEntityLevel")==-117 && GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex")==171)
	{
		decl String:sClassName[64];
		decl Float:fVecClientEyePos[3];
		decl Float:fVecClientEyeAng[3];
		GetClientEyePosition(iClient, fVecClientEyePos);	 // Get the position of the player's eyes
		GetClientEyeAngles(iClient, fVecClientEyeAng);	   // Get the angle the player is looking

		//Check for colliding entities
		TR_TraceRayFilter(fVecClientEyePos, fVecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, iClient);

		if (!TR_DidHit(INVALID_HANDLE))
			return Plugin_Continue;
		
		new iTRIndex = TR_GetEntityIndex(INVALID_HANDLE);
		GetEdictClassname(iTRIndex, sClassName, sizeof(sClassName));
		if (!StrEqual(sClassName, "worldspawn"))
			return Plugin_Continue;
		
		decl Float:fNormal[3];
		TR_GetPlaneNormal(INVALID_HANDLE, fNormal);
		GetVectorAngles(fNormal, fNormal);
		
		if (fNormal[0] >= 30.0 && fNormal[0] <= 330.0)
			return Plugin_Continue;
		if (fNormal[0] <= -30.0)
			return Plugin_Continue;

		decl Float:fVecEndPos[3];
		TR_GetEndPosition(fVecEndPos);
		new Float:fDist = GetVectorDistance(fVecClientEyePos, fVecEndPos);
		if(fDist >= 100.0)
			return Plugin_Continue;
		
		new Float:fVelocity[3];
		GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fVelocity);
		fVelocity[2] = 600.0;
		TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, fVelocity);
		ClientCommand(iClient, "playgamesound \"%s\"", "player\\taunt_clip_spin.wav");
	}
	return Plugin_Continue;
}

public bool:TraceRayDontHitSelf(iEntity, iMask, any:iOtherEntity)
	return (iEntity!=iOtherEntity);