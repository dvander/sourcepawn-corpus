#include <sourcemod>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <sdkhooks>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "[CS:GO] Shootable Nades",
	author = "LenHard",
	description = "Able to drop and shoot your nades.",
	version = "1.0",
	url = "http://steamcommunity.com/id/TheOfficalLenHard/"
};

public void OnPluginStart() {
	AddCommandListener(CL_Drop, "drop");
}

public Action CL_Drop(int client, const char[] sName, int args)
{
	if ((0 < client <= MaxClients) && IsClientInGame(client))
	{
		int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (iWeapon != -1)
		{
			char[] sWeapon = new char[32];
			GetEdictClassname(iWeapon, sWeapon, 32);
			
			if (sWeapon[7] == 'h' && sWeapon[8] == 'e' || sWeapon[7] == 'f' && sWeapon[8] == 'l' 
			|| sWeapon[7] == 'i' && sWeapon[8] == 'n' || sWeapon[7] == 'm' && sWeapon[8] == 'o')
			{
				CS_DropWeapon(client, iWeapon, true, false);	
				return Plugin_Handled;				
			}
		}
	}
	return Plugin_Continue;
}

public Action CS_OnCSWeaponDrop(int client, int iWeapon)
{
	if ((0 < client <= MaxClients) && IsClientInGame(client) && iWeapon != -1)
	{
		char[] sWeapon = new char[32];
		GetEdictClassname(iWeapon, sWeapon, 32);
		
		if (sWeapon[7] == 'h' && sWeapon[8] == 'e' || sWeapon[7] == 'f' && sWeapon[8] == 'l' 
		|| sWeapon[7] == 'i' && sWeapon[8] == 'n' || sWeapon[7] == 'm' && sWeapon[8] == 'o')
			SDKHook(iWeapon, SDKHook_OnTakeDamage, OnEntityDamaged);
	}
}

public Action OnEntityDamaged(int iEntity, int &iAttacker, int &iInflictor, float &fDamage, int &fDamagetype) 
{
	if (IsValidEntity(iEntity) && (0 < iInflictor <= MaxClients) && IsClientInGame(iInflictor))	
	{
		char[] sWeapon = new char[32];
		GetEdictClassname(iEntity, sWeapon, 32);
		
		float fPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);
		fPos[2] += 5.0;
		
		AcceptEntityInput(iEntity, "Kill");
		
		int entity = -1;
		
		if (sWeapon[7] == 'f')
			entity = CreateEntityByName("flashbang_projectile");
		else if (sWeapon[7] == 'i' || sWeapon[7] == 'm')
			entity = CreateEntityByName("molotov_projectile");
		else if (sWeapon[7] == 'h')
			entity = CreateEntityByName("hegrenade_projectile");
			
		if (IsValidEntity(entity) && DispatchSpawn(entity))
		{
			AcceptEntityInput(entity, "InitializeSpawnFromWorld");  
			SetEntPropEnt(entity, Prop_Data, "m_hThrower", iInflictor);
			SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(iInflictor));  
			
			if (sWeapon[7] == 'h')
			{
				SetEntPropFloat(entity, Prop_Data, "m_flDamage", 99.0);
				SetEntPropFloat(entity, Prop_Data, "m_DmgRadius", 350.0);  
			}
			
			SetEntProp(entity, Prop_Data, "m_iHealth", 1);
			SetEntProp(entity, Prop_Data, "m_takedamage", 2);
			TeleportEntity(entity, fPos, NULL_VECTOR, NULL_VECTOR);
			RequestFrame(Frame_Kill, entity);
		}
	}
}

public void Frame_Kill(int entity) {
	SDKHooks_TakeDamage(entity, 0, 0, 1.0);
}