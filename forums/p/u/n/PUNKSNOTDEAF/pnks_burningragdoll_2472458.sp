#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

/***********************************************************
DEFINES
***********************************************************/

#define PLUGIN_NAME "PNKS! Burning Ragdolls (Moltotov Kill)"


/***********************************************************
INFO
***********************************************************/

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = "punK"
};


/***********************************************************
OnPluginStart Let's Go
***********************************************************/

public void OnPluginStart()
{
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
}


/***********************************************************
Hooks
***********************************************************/

public Action Event_OnPlayerDeath(Event hEvent, const char[] chName, bool bDontBroadcast) {
	int iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	char chWeapon[32];
	GetEventString(hEvent, "weapon", chWeapon, sizeof(chWeapon));


	if(StrEqual(chWeapon, "inferno")){
		int iRagdoll = GetEntPropEnt(iVictim, Prop_Send, "m_hRagdoll");
		AcceptEntityInput(iRagdoll, "Ignite");
	}
}
