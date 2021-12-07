#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Accessible TF2",
	author = "Jerem Watts",
	description = "Limit weapon loadouts in TF2",
	version = "0.15",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("post_inventory_application", OnPostInventory);
}

public void OnPostInventory(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		TF2_RemoveWeaponSlot(client, 0);
		CreateWeapon(client, "tf_weapon_scattergun", 1103, 6);
		
		TF2_RemoveWeaponSlot(client, 1);		
		CreateWeapon(client, "tf_weapon_lunchbox_drink", 163, 6);
		
		TF2_RemoveWeaponSlot(client, 2);		
		CreateWeapon(client, "tf_weapon_bat", 0, 6);
	}

	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		TF2_RemoveWeaponSlot(client, 0);
		CreateWeapon(client, "tf_weapon_shotgun_primary", 9, 6);
		
		TF2_RemoveWeaponSlot(client, 1);		
		CreateWeapon(client, "tf_weapon_medigun", 411, 6);
		
		TF2_RemoveWeaponSlot(client, 2);		
		CreateWeapon(client, "tf_weapon_bonesaw", 413, 6);
	}

	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		TF2_RemoveWeaponSlot(client, 0);
		CreateWeapon(client, "tf_weapon_shotgun_primary", 1153, 6);
		
		TF2_RemoveWeaponSlot(client, 1);		
		CreateWeapon(client, "tf_weapon_pistol", 61, 6);
		
		TF2_RemoveWeaponSlot(client, 2);		
		CreateWeapon(client, "tf_weapon_robot_arm", 142, 6);
	}

	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		TF2_RemoveWeaponSlot(client, 0);
		CreateWeapon(client, "tf_weapon_sniperrifle_classic", 1098, 6);
		
		TF2_RemoveWeaponSlot(client, 1);		
		CreateWeapon(client, "tf_weapon_jar", 58, 6);
		
		TF2_RemoveWeaponSlot(client, 2);		
		CreateWeapon(client, "tf_weapon_club", 232, 6);
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		TF2_RemoveWeaponSlot(client, 0);
		CreateWeapon(client, "tf_weapon_rocketlauncher", 414, 6);
		
		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 0.00);
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 4, 0);
			SetEntData(Weapon1, FindSendPropInfo("CTFWeaponBase", "m_iClip1"), 2);			
		}		
		
		TF2_RemoveWeaponSlot(client, 1);		
		CreateWeapon(client, "tf_weapon_shotgun_hwg", 425, 6);
		
		TF2_RemoveWeaponSlot(client, 2);		
		CreateWeapon(client, "tf_weapon_stickbomb", 307, 6);

		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_SetByName(Weapon2, "provide on active", 1.0);
			TF2Attrib_SetByName(Weapon2, "move speed bonus", 1.5);			
		}
	}
}

bool CreateWeapon(int client, char[] classname, int itemindex, int quality, int level = 0)
{
	int weapon = CreateEntityByName(classname);

	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", itemindex);	 
	SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);		

	if (level)
	{
		SetEntProp(weapon, Prop_Send, "m_iEntityLevel", level);
	}
	else
	{
		SetEntProp(weapon, Prop_Send, "m_iEntityLevel", GetRandomInt(1,99));
	}

	switch (itemindex)
	{
	case 25, 26:
		{
			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon); 

			return true; 			
		}
	case 735, 736, 810, 933, 1080, 1102:
		{
			SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
			SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
		}	
	case 998:
		{
			SetEntProp(weapon, Prop_Send, "m_nChargeResistType", GetRandomInt(0,2));
		}
	}
	
	DispatchSpawn(weapon);
	EquipPlayerWeapon(client, weapon); 
	
	TF2_SwitchtoSlot(client, 0);
	return true;	
}

stock void TF2_SwitchtoSlot(int client, int slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char wepclassname[64];
		int wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, wepclassname, sizeof(wepclassname)))
		{
			FakeClientCommandEx(client, "use %s", wepclassname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}