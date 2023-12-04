
/*
	14.02.2023
	- Looked signatures "IsInWorld" to Windows and Linux
	- ...Changed code to fancy modern SourceMod DHooks. Require SM 1.11 to compile
	- GetEdictClassname -> GetEntityClassname (because it is me, Bacardi)
*/


#pragma semicolon 1
#include <sourcemod>
#include <dhooks>
#include <sdktools>
//#include "dhooks.inc"
DynamicDetour hIsInWorldDetour;


public Plugin myinfo =
{
	name = "CS:GO Grenade Max Velocity Fix",
	author = "Aes, domino_",
	description = "Allows grenades to go faster than 2000u/s",
	version = "0.0.2",
	url = "https://forums.alliedmods.net"
}

public void OnPluginStart()
{

	GameData hGameData = new GameData("nadevelfix.games");
	if (hGameData == null)
	{
			SetFailState("Failed to load nadevelfix gamedata.");
			return;
	}

	hIsInWorldDetour = new DynamicDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);

	//if (hIsInWorldDetour)	// there is no return
	//		SetFailState("Failed to setup detour for IsInWorld");

	if (!hIsInWorldDetour.SetFromConf(hGameData, SDKConf_Signature, "IsInWorld"))
			SetFailState("Failed to load IsInWorld signature from gamedata");

	delete hGameData;

	if (!hIsInWorldDetour.Enable(Hook_Pre, Detour_IsInWorld))
			SetFailState("Failed to detour IsInWorld.");

}



public MRESReturn Detour_IsInWorld(int entity, Handle hReturn, Handle hParams)
{
	if(IsValidEntity(entity))
	{
		char sClass[32];
		float position[3];
		GetEntityClassname(entity, sClass, sizeof(sClass));

		//PrintToServer("sClass %s", sClass);	// debug  it works

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
