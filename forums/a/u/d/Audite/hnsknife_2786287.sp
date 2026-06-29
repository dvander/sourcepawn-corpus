#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <cstrike>
#include <csgocolors>

#pragma newdecls required
#pragma semicolon 1

// PLAYER STORAGE
bool g_bToggleKnife[MAXPLAYERS+1];

// VERSION
#define VERSION "0.0.2"

// KNIFES
char entitiesList[][] =  { "weapon_bayonet", "weapon_melee", "weapon_knifegg", "weapon_knife" };

/*
Changelog
	0.0.2 - Added auto check if the player is holding knife or not
*/

public Plugin myinfo =
{
	name = "hnsknife",
	author = "Audite",
	description = "You can hide and show your knife",
	version = VERSION,
	url = "https://github.com/Leakoni/"
};


public void OnPluginStart()
{
	RegConsoleCmd("sm_hknife", CommandToggleKnife);
	RegConsoleCmd("sm_hk", CommandToggleKnife);
	RegConsoleCmd("sm_hideknife", CommandToggleKnife);

	CreateConVar("hnsknife_version", VERSION, "HNS Knife Toggle Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);

	HookEvent("round_start", Event_RoundStart);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i))
			continue;

		OnClientPutInServer(i);
	}
}

public void OnClientPutInServer(int client){
	SDKHook(client, SDKHook_WeaponSwitch, SDKWeaponCheck);
}

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iLength)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		strcopy(szError, iLength, "This plugin works only on CS:GO.");

		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void ToggleKnife(int client, bool show){
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", show);	
}

public Action SDKWeaponCheck(int client, int weapon){


	char sClassName[64];
	GetEntityClassname(weapon, sClassName, sizeof(sClassName));

	for (int i = 0; i < sizeof(entitiesList); i++)
    {
        if(!strcmp(sClassName, entitiesList[i]))
		{
			if (g_bToggleKnife[client])
			{
				ToggleKnife(client, false);
			}
			else
			{
				ToggleKnife(client, true);
			}
		}else
		{
			ToggleKnife(client, true);
		}
    }

	return Plugin_Continue;
}

public Action CommandToggleKnife(int client, int args){

	if (g_bToggleKnife[client] == false){
		ToggleKnife(client, false);
		g_bToggleKnife[client] = true;
		PrintToChat(client, "\x01[%sHK\x01] Your knife is now %shidden", Color_D, Color_Orange);
	}
	else{
		ToggleKnife(client, true);
		g_bToggleKnife[client] = false;
		PrintToChat(client, "\x01[%sHK\x01] Your knife is now %svisible", Color_D, Color_Lightgreen);
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientConnected(i) || IsFakeClient(i))
				continue;

			if(g_bToggleKnife[i] == true){
				ToggleKnife(i, false);
			}
		}
}
