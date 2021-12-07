#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

public Plugin myinfo = 
{
	name = "No Weapon Fix",
	author = ".#Zipcore",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

#define LoopIngamePlayers(%1) for(int %1=1;%1<=MaxClients;++%1)\
if(IsClientInGame(%1) && !IsFakeClient(%1))

#define EF_NODRAW 32

int g_iFakeWeaponRef[MAXPLAYERS + 1];
bool g_bWait[MAXPLAYERS + 1];
int g_iViewmodelRef[MAXPLAYERS + 1];

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "predicted_viewmodel", false))
        SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
}

public void OnEntitySpawned(int entity)
{
    int iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
    if ((iOwner > 0) && (iOwner <= MaxClients))
    {
        if (GetEntProp(entity, Prop_Send, "m_nViewModelIndex") == 0)
            g_iViewmodelRef[iOwner] = EntIndexToEntRef(entity);
    }
}

public void OnPluginStart()
{
	LoopIngamePlayers(client)
		OnClientPutInServer(client);
}

public void OnClientPutInServer(int client)
{
	g_iFakeWeaponRef[client] = 0;
	g_bWait[client] = false;
	
	SDKHook(client, SDKHook_WeaponEquip, WeaponSwitch);
	SDKHook(client, SDKHook_WeaponDrop, WeaponDrop);
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public Action WeaponSwitch(int client, int weapon)
{
	g_bWait[client] = false;
	
	int iEntity = EntRefToEntIndex(g_iFakeWeaponRef[client]);
	if(IsValidEntity(weapon) && weapon != iEntity && iEntity > MaxClients && iEntity != INVALID_ENT_REFERENCE)
	{
		RemovePlayerItem(client, iEntity);
		AcceptEntityInput(iEntity, "Kill");
	}
	return Plugin_Continue;
}

public Action WeaponDrop(int client, int weapon)
{
	int iEntity = EntRefToEntIndex(g_iFakeWeaponRef[client]);
	if(IsValidEntity(weapon) && weapon == iEntity)
	{
		AcceptEntityInput(iEntity, "Kill");
	}
	return Plugin_Continue;
}

public void OnPostThinkPost(int client)
{
	int iEntity = EntRefToEntIndex(g_iFakeWeaponRef[client]);
	if (iEntity > MaxClients)
	{
		int iView = EntRefToEntIndex(g_iViewmodelRef[client]);
		if(iView > MaxClients)
		{
			int EntEffects = GetEntProp(g_iViewmodelRef[client], Prop_Send, "m_fEffects");
			EntEffects |= EF_NODRAW;
			SetEntProp(g_iViewmodelRef[client], Prop_Send, "m_fEffects", EntEffects);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	int iEntity = EntRefToEntIndex(g_iFakeWeaponRef[client]);
	if (iEntity > MaxClients)
	{
		float fUnlockTime = GetGameTime() + 0.5;
		
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", fUnlockTime);
		SetEntPropFloat(iEntity, Prop_Send, "m_flNextPrimaryAttack", fUnlockTime);
	}
	
	if(weapon <= 0)
		weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(weapon <= 0 && iEntity <= 0)
	{
		if(g_bWait[client])
		{
			int iWeapon = GivePlayerItem(client, "weapon_decoy");
			
			float fUnlockTime = GetGameTime() + 0.5;
			
			SetEntPropFloat(client, Prop_Send, "m_flNextAttack", fUnlockTime);
			SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", fUnlockTime);
		
			g_iFakeWeaponRef[client] = EntIndexToEntRef(iWeapon);
			g_bWait[client] = false;
			return Plugin_Continue;
		}
		
		g_bWait[client] = true;
	}
  	
  	return Plugin_Continue;
}