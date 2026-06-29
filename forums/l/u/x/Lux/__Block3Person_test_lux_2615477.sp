#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

static Handle hCvar_MpGameMode;
static char sCvarCurrentValue[64];

public void OnPluginStart()
{
	hCvar_MpGameMode = FindConVar("mp_gamemode");
	HookConVarChange(hCvar_MpGameMode, eConvarChanged);
	GetConVarString(hCvar_MpGameMode, sCvarCurrentValue, sizeof(sCvarCurrentValue));
}

public void eConvarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	strcopy(sCvarCurrentValue, 64, sNewVal);
}

public void TP_OnThirdPersonChanged(int iClient, bool bIsThirdPerson)
{
	if(bIsThirdPerson)
		SendConVarValue(iClient, hCvar_MpGameMode, "versus");  
	else
		SendConVarValue(iClient, hCvar_MpGameMode, sCvarCurrentValue);
}