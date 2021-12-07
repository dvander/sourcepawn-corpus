#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include "include/retakes.inc"

#pragma newdecls required
#pragma semicolon 1

#define	PLUGIN_NAME			"[CS:GO] Retakes AutoPlant"
#define PLUGIN_AUTHOR 		"domino_"
#define PLUGIN_DESCRIPTION	"A plugin which automatically plants the bomb in Retakes"
#define PLUGIN_VERSION 		"0.0.5"
#define PLUGIN_URL			"www.voidrealitygaming.co.uk"

ConVar g_cvPluginEnabled;
ConVar g_cvFreezeTime;

int m_bBombTicking;

bool g_bBombDeleted;
Bombsite g_bsBombsite;

float g_vecPosition[3];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() 
{ 
 	g_cvPluginEnabled = CreateConVar("b3none_ap_enabled", "1", "Enable AutoPlant? (1 Enabled | 0 Disabled)");
	g_cvFreezeTime = FindConVar("mp_freezetime");
	
	m_bBombTicking = FindSendPropInfo("CPlantedC4", "m_bBombTicking");
	
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	if(GetConVarBool(g_cvPluginEnabled))
	{	
		g_bBombDeleted = false;
		for(int iClient = 1; iClient <= MaxClients+1; iClient++)
		{
			if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetPlayerWeaponSlot(iClient, 4) > 0)
			{
				int iBomb = GetPlayerWeaponSlot(iClient, 4);
				g_bBombDeleted = SafeRemoveWeapon(iClient, iBomb);
						
				int iUserid = GetClientUserId(iClient);
				
				GetClientAbsOrigin(iClient, g_vecPosition);
				
				SendBombBegin(iUserid);
				
				CreateTimer(GetConVarFloat(g_cvFreezeTime)+0.1, PlantBomb, iUserid, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action PlantBomb(Handle timer, int iUserid)
{
	if(g_bBombDeleted)
	{
		int Bomb_Ent = CreateEntityByName("planted_c4");
		
		SetEntData(Bomb_Ent, m_bBombTicking, 1, 1, true);
		
		if(DispatchSpawn(Bomb_Ent))
		{
			ActivateEntity(Bomb_Ent);
			TeleportEntity(Bomb_Ent, g_vecPosition, NULL_VECTOR, NULL_VECTOR);
			
			SendBombPlanted(iUserid);
		}
	}
}

public void Retakes_OnSitePicked(Bombsite& site)
{
    g_bsBombsite = site;
}

public void SendBombBegin(int iUserid)
{
	Event event = CreateEvent("bomb_beginplant");
	event.SetInt("userid", iUserid);
	event.SetInt("site", (g_bsBombsite == BombsiteA) ? 0:1);
	event.Fire();
}

public void SendBombPlanted(int iUserid)
{
	Event event = CreateEvent("bomb_planted");
	event.SetInt("userid", iUserid);
	event.SetInt("site", (g_bsBombsite == BombsiteA) ? 0:1);
	event.Fire();
}

stock bool SafeRemoveWeapon(int iClient, int iWeapon)
{
    if (!IsValidEntity(iWeapon) || !IsValidEdict(iWeapon)) {
        return false;
    }
    
    if (!HasEntProp(iWeapon, Prop_Send, "m_hOwnerEntity")) {
        return false;
    }
    
    int iOwnerEntity = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
    
    if (iOwnerEntity != iClient) {
        SetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity", iClient);
    }
    
    CS_DropWeapon(iClient, iWeapon, false);
    
    if (HasEntProp(iWeapon, Prop_Send, "m_hWeaponWorldModel")) {
        int iWorldModel = GetEntPropEnt(iWeapon, Prop_Send, "m_hWeaponWorldModel");
        
        if (IsValidEdict(iWorldModel) && IsValidEntity(iWorldModel)) {
            if (!AcceptEntityInput(iWorldModel, "Kill")) {
                return false;
            }
        }
    }
    
    if (!AcceptEntityInput(iWeapon, "Kill")) {
        return false;
    }
    
    return true;
}