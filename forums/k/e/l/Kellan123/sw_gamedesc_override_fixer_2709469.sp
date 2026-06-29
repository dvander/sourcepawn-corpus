#include <sourcemod>
#include <SteamWorks>

#pragma semicolon 1
#pragma newdecls required

public void OnMapStart()
{
	if(GetFeatureStatus(FeatureType_Native, "SteamWorks_SetGameDescription") == FeatureStatus_Available)
	{
		Handle hCvar = FindConVar("sw_gamedesc_override");
		
		if(hCvar != INVALID_HANDLE)
		{
			char sCvar[64];
			GetConVarString(hCvar, sCvar, sizeof(sCvar));
			
			SteamWorks_SetGameDescription(sCvar);
			
			CloseHandle(hCvar);
		}
	}
}