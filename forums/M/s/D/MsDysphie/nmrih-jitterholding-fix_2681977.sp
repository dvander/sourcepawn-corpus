#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name        = "[NMRiH] Jitterholding Fix",
	author      = "Dysphie",
	description = "Fix melee weapons retaining their touch damage after a toss",
	version     = "1.0.0",
	url         = ""
};

public void OnEntityCreated(int entity, const char[] classname)
{
	// Hook any CNMRiH_MeleeBase
	if(HasEntProp(entity, Prop_Send, "m_flQuickAttackLimit"))
		SDKHook(entity, SDKHook_UsePost, OnMeleePlayerUse);
}

public void OnMeleePlayerUse(int melee, int activator, int caller, UseType type, float value)
{
	Address pMelee = GetEntityAddress(melee);
	if(pMelee)
	{
		// CNMRiH_WeaponBase->m_bIsThrown = 0
		StoreToAddress(pMelee + view_as<Address>(0x595), 0, NumberType_Int8);		
	}
}