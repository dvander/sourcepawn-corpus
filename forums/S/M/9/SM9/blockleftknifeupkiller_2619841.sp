#include <sdktools>
#include <cstrike>

public Plugin myinfo = 
{
	name = "Block Left Knife", 
	author = "Bara, [Updated by The Killer [NL], SM9();]",
	description = "Block Left Knife", 
	version = "2.4", 
	url = "www.bara.in, www.upvotegaming.com"
}

public Action OnPlayerRunCmd(int iClient, int & iButtons, int & iImpulse, float vVelocity[3], float vAngles[3], int & iWeapon)
{
	if (!IsClientInGame(iClient) || !IsPlayerAlive(iClient)) {
		return Plugin_Continue;
	}
	
	int iKnife = GetPlayerWeaponSlot(iClient, CS_SLOT_KNIFE);
	
	if(iKnife == -1 || !IsValidEntity(iKnife)) {
		return Plugin_Continue;
	}
	
	SetEntPropFloat(iKnife, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.0);
	
	if(iKnife != iWeapon) {
		return Plugin_Continue;
	}
	
	iButtons &= ~IN_ATTACK;
	
	return Plugin_Changed;
} 