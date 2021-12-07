#include <sdktools>
#include <sdkhooks>
#include <cstrike>

public Plugin myinfo = 
{
	name = "Block Left Knife", 
	author = "Bara, [Updated by The Killer [NL], SM9();]", 
	description = "Block Left Knife", 
	version = "2.5", 
	url = "www.bara.in, www.upvotegaming.com"
}

ArrayList g_alActiveKnives = null;

public void OnPluginStart()
{
	g_alActiveKnives = new ArrayList();
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) {
			continue;
		}
		
		OnClientPutInServer(i);
		FindAndAddKnifeInitial(i);
	}
	
	TriggerTimer(CreateTimer(0.5, Timer_UpdateKnives, _, TIMER_REPEAT));
}

public void OnClientPutInServer(int iClient) {
	SDKHookEx(iClient, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public void OnWeaponEquipPost(int iClient, int iWeapon)
{
	if (iWeapon != GetPlayerWeaponSlot(iClient, CS_SLOT_KNIFE)) {
		return;
	}
	
	if(CS_ItemDefIndexToID(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex")) == CSWeapon_TASER) {
		return;
	}
	
	int iEntRef = EntIndexToEntRef(iWeapon);
	
	if (g_alActiveKnives.FindValue(iEntRef) != -1) {
		return;
	}
	
	g_alActiveKnives.Push(iEntRef);
}

public Action Timer_UpdateKnives(Handle hTimer)
{
	int iKnife = -1;
	int iEntRef = INVALID_ENT_REFERENCE;
	
	for (int i = 0; i < g_alActiveKnives.Length; i++) {
		iEntRef = g_alActiveKnives.Get(i);
		
		if(iEntRef == INVALID_ENT_REFERENCE) {
			g_alActiveKnives.Erase(i);
			continue;
		}
		
		iKnife = EntRefToEntIndex(iEntRef);
		
		if (iKnife <= MaxClients || !IsValidEntity(iKnife)) {
			g_alActiveKnives.Erase(i);
			continue;
		}
		
		SetEntPropFloat(iKnife, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 999.0);
	}
}

public void OnEntityDestroyed(int iEntity)
{
	int iEntRef = INVALID_ENT_REFERENCE;
	
	if(iEntity < 0) {
		iEntRef = iEntity;
	} else {
		iEntRef = EntIndexToEntRef(iEntity);
	}
	
	int iKnifeIndex = g_alActiveKnives.FindValue(iEntRef);
	
	if (iKnifeIndex == -1) {
		return;
	}
	
	g_alActiveKnives.Erase(iKnifeIndex);
}

void FindAndAddKnifeInitial(int iClient)
{
	int iWeapon = -1;
	int iEntRef = INVALID_ENT_REFERENCE;
	
	for (int i = 0; i < GetEntPropArraySize(iClient, Prop_Send, "m_hMyWeapons"); i++) {
		iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hMyWeapons", i);
		
		if (iWeapon <= MaxClients || !IsValidEntity(iWeapon)) {
			continue;
		}
		
		if (iWeapon != GetPlayerWeaponSlot(iClient, CS_SLOT_KNIFE)) {
			continue;
		}
		
		if(CS_ItemDefIndexToID(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex")) == CSWeapon_TASER) {
			return;
		}
		
		iEntRef = EntIndexToEntRef(iWeapon);
		
		if (g_alActiveKnives.FindValue(iEntRef) != -1) {
			continue;
		}
		
		g_alActiveKnives.Push(iEntRef);
	}
}