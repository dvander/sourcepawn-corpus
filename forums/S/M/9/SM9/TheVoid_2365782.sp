/****************************************************************************************************
[ANY] THE VOID - AS SEEN IN MINECRAFT
*****************************************************************************************************/

/****************************************************************************************************
CHANGELOG
*****************************************************************************************************
*
* 0.1          -
*
*                 First Release.
*
* 0.2          -
*
*                 Improved Hooks, safety & efficiency.
* 0.3         -
*
*                 Code improvements, ignore everything but weapons.
* 0.4         -
*
*                 Fix error spam.
*/

#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.4"

#pragma newdecls required
#pragma semicolon 1

bool g_bIsEntityHooked[2048];

public Plugin myinfo = 
{
	name = "The Void", 
	author = "SM9 (xCoderx) - FragDeluxe.com", 
	description = "Removes weapons that fall outside the world.", 
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=275163"
};

public void OnPluginStart() {
	CreateConVar("sm_thevoid_version", PLUGIN_VERSION, "The Void", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
}

public void OnEntityCreated(int iEntity, const char[] chEntity)
{
	if(iEntity <= -1) {
		return; 
	}
	
	if (g_bIsEntityHooked[iEntity] || StrContains("weapon_", chEntity, false) == -1) {
		return;
	}
	
	SDKHookEx(iEntity, SDKHook_SpawnPost, OnEntitySpawnPost);
}

public Action OnEntitySpawnPost(int iEntity) 
{
	if(!IsEntityValid(iEntity)) {
		if(iEntity > -1) {
			g_bIsEntityHooked[iEntity] = false;
		}
		
		return;
	}
	
	g_bIsEntityHooked[iEntity] = SDKHookEx(iEntity, SDKHook_VPhysicsUpdate, OnEntityMove);
}

public void OnEntityDestroyed(int iEntity) 
{
	if(iEntity > -1) {
		g_bIsEntityHooked[iEntity] = false;
	}
}

public Action OnEntityMove(int iEntity) 
{
	if (IsEntityOutsideWorld(iEntity)) {
		KillEntity(iEntity);
	}
}

stock bool IsEntityValid(int iEntity)
{
	if (iEntity <= MaxClients || !IsValidEntity(iEntity) || !IsValidEdict(iEntity)) {
		return false;
	}
	
	char chEntity[64]; GetEntityClassname(iEntity, chEntity, 64); 
	
	return StrContains(chEntity, "weapon_", false) != -1;
}

stock bool IsEntityOutsideWorld(int iEntity)
{
	float fPosition[3]; GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fPosition);
	
	if (TR_PointOutsideWorld(fPosition)) {
		return true;
	}
	
	return false;
}

stock void KillEntity(int iEntity)
{
	if(!AcceptEntityInput(iEntity, "Kill")) {
		RemoveEdict(iEntity);
	}
}