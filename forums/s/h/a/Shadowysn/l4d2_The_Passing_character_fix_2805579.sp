/*====================================================
1.0
	- Initial release
======================================================*/
#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <dhooks>

bool bShouldReturnNonePlayer;
bool bShouldReturnActualPlayer;

Handle hOnActionComplete;

public Plugin myinfo = 
{
	name = "The Passing character fix",
	author = "IA/NanaNana",
	description = "Fixes the bug where players with L4D1 survivors are teleported away or kicked on The Passing.",
	version = "1.0b",
	url = ""
}

public void OnPluginStart()
{
	Handle h = LoadGameConfigFile("l4d2_The_Passing_character_fix"), z;
	
	if(!(z = DHookCreateFromConf(h, "GetPlayerByCharacter")))
		SetFailState("Detour \"GetPlayerByCharacter\" invalid.");
	DHookEnableDetour(z, true, DH_GetPlayerByCharacter);
	
	if(!(z = DHookCreateFromConf(h, "AddSurvivorBot")))
		SetFailState("Detour \"AddSurvivorBot\" invalid.");
	DHookEnableDetour(z, false, DH_AddSurvivorBot);
	DHookEnableDetour(z, true, DH_AddSurvivorBotPost);
	
	Handle hAlt = LoadGameConfigFile("defib_fix");
	if (hAlt != INVALID_HANDLE)
	{
		if(!(hOnActionComplete = DHookCreateFromConf(hAlt, "CItemDefibrillator::OnActionComplete")))
		{
			PrintToServer("[The Passing character fix] Lux's Defib Fix OnActionComplete data not found! Inability to defib L4D1 survivors bug unfixed!");
			return;
		}
	}
	else
	{ PrintToServer("[The Passing character fix] Lux's Defib Fix gamedata not found! Inability to defib L4D1 survivors bug unfixed!"); }
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if (hOnActionComplete == null) return;
	if(sClassname[0] != 'w' || strcmp(sClassname, "weapon_defibrillator", false) != 0)
	 	return;
	
	DHookEntity(hOnActionComplete, false, iEntity, _, OnActionComplete);
	DHookEntity(hOnActionComplete, true, iEntity, _, OnActionCompletePost);
}

MRESReturn OnActionComplete(Handle hReturn, Handle hParams)
{
	bShouldReturnActualPlayer = true;
	return MRES_Ignored;
}

MRESReturn OnActionCompletePost(Handle hReturn, Handle hParams)
{
	bShouldReturnActualPlayer = false;
	return MRES_Ignored;
}

MRESReturn DH_AddSurvivorBot(int pThis, Handle hReturn, Handle hParams)
{
	if(3 < DHookGetParam(hParams, 1) < 8) bShouldReturnNonePlayer = true;
	return MRES_Ignored;
}

MRESReturn DH_AddSurvivorBotPost(int pThis, Handle hReturn, Handle hParams)
{
	bShouldReturnNonePlayer = false;
	return MRES_Ignored;
}

MRESReturn DH_GetPlayerByCharacter(Handle hReturn, Handle hParams)
{
	if(bShouldReturnNonePlayer)
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	if(bShouldReturnActualPlayer)
	{
		return MRES_Ignored;
	}
	int i = DHookGetParam(hParams, 1);
	if(3 < i < 8)
	{
		int a = DHookGetReturn(hReturn);
		if(a < 1 || IsFakeClientInTeam4(a)) return MRES_Ignored;
		Address result;
		for(a = 1;a<=MaxClients;a++)
		{
			if(IsClientInGame(a) && GetClientTeam(a) == 4 && GetEntProp(a, Prop_Send, "m_survivorCharacter") == i)
			{
				result = GetEntityAddress(a);
				break;
			}
		}
		DHookSetReturn(hReturn, result);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

bool IsFakeClientInTeam4(int p)
{
	for(int a = 1;a<=MaxClients;a++)
	{
		if(IsClientInGame(a) && IsFakeClient(a) && GetClientTeam(a) == 4 && view_as<int>(GetEntityAddress(a)) == p) return true;
	}
	return false;
}