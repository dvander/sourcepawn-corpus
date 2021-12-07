#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

Handle DoAnimEvent;

public OnPluginStart()
{
	HookEvent("weapon_reload", reload);
	
	Handle hGamedata = LoadGameConfigFile("pistol_reload_fix");
	
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTerrorPlayer::DoAnimationEvent"))
		SetFailState("unable to find signiture CTerrorPlayer::DoAnimationEvent");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	DoAnimEvent = EndPrepSDKCall();
	
	if(DoAnimEvent == null)
		SetFailState("unable to prep CTerrorPlayer::DoAnimationEvent sdkcall");
	
	delete hGamedata;
}

public void reload(Handle event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(iClient < 1 || !IsPlayerAlive(iClient))
		return;
	
	int iActiveWeapon = Client_GetActiveWeapon(iClient);
	if(iActiveWeapon == INVALID_ENT_REFERENCE)
		return;
	
	static char sWeaponName[32];
	GetClientWeapon(iClient, sWeaponName, sizeof(sWeaponName));
	
	if (strcmp(sWeaponName, "weapon_pistol_magnum", false) == 0 )
	{
		if (GetEntProp(iActiveWeapon, Prop_Send, "m_iClip1") <= 0)
			SDKCall(DoAnimEvent, iClient, 4, 1);
	}
	else if (strcmp(sWeaponName, "weapon_pistol", false) == 0 )
	{
		int pistolclip = GetEntProp(iActiveWeapon, Prop_Send, "m_iClip1");
		if(pistolclip > 1)
			return;
		
		if (GetEntProp(iActiveWeapon, Prop_Send, "m_isDualWielding") > 0)
		{
			if (pistolclip <= 1)
			{
				SDKCall(DoAnimEvent, iClient, 4, 1);
			}
		}
		else if (pistolclip == 0)
		{
			SDKCall(DoAnimEvent, iClient, 4, 1);
		}
	}
}

/**
 * Gets the current/active weapon of a client
 *
 * @param client		Client Index.
 * @return				Weapon Index or INVALID_ENT_REFERENCE if the client has no active weapon.
 */
stock Client_GetActiveWeapon(client)
{
	new weapon =  GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	if (!IsValidEntity(weapon)) {
		return INVALID_ENT_REFERENCE;
	}
	
	return weapon;
}