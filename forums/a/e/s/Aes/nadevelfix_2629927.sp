#pragma semicolon 1 
#include <sourcemod>
#include <dhooks> 
#include <sdktools> 
#include "dhooks.inc"
Handle hIsInWorldDetour;


public Plugin myinfo = 
{
	name = "CS:GO Grenade Max Velocity Fix",
	author = "Aes, domino_",
	description = "Allows grenades to go faster than 2000u/s",
	version = "0.0.1",
	url = "https://forums.alliedmods.net"
}

public void OnPluginStart() 
{

	Handle hGameData = LoadGameConfigFile("nadevelfix.games");
	if (!hGameData)
	{	
			SetFailState("Failed to load nadevelfix gamedata.");
			return;
	}

	hIsInWorldDetour = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	if (!hIsInWorldDetour)
			SetFailState("Failed to setup detour for IsInWorld");

	if (!DHookSetFromConf(hIsInWorldDetour, hGameData, SDKConf_Signature, "IsInWorld"))
			SetFailState("Failed to load IsInWorld signature from gamedata");
	delete hGameData;

	if (!DHookEnableDetour(hIsInWorldDetour, false, Detour_IsInWorld))
			SetFailState("Failed to detour IsInWorld.");

} 



public MRESReturn Detour_IsInWorld(int entity, Handle hReturn, Handle hParams) 
{
	if(IsValidEntity(entity))
	{
		char sClass[32];
		float position[3];
		GetEdictClassname(entity, sClass, sizeof(sClass));
		if(StrContains(sClass, "_projectile")) 
    { 
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
			if(!TR_PointOutsideWorld(position))
			{
				DHookSetReturn(hReturn, true);
				return MRES_Override;
			}
    } 
	}
	return MRES_Ignored;
}
