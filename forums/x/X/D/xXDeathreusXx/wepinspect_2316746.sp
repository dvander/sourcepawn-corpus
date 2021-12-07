#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

#define PLUGIN_VERSION		"1.0.5"

public Plugin myinfo = {
	name		= "[TF2] Weapon Inspect",
	author	  	= "Deathreus",
	description = "Grants ability to inspect all weapons",
	version	 	= PLUGIN_VERSION
}

ConVar g_hCvarEnabled;
ConVar g_hCvarFoodThrowBlock;

public void OnPluginStart()
{
	CreateConVar("sm_weapinspect_version", PLUGIN_VERSION, "Inspect Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_PLUGIN);
	g_hCvarEnabled = CreateConVar("sm_weapinspect_enabled", "1", "(0-1)Enable or disable the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarFoodThrowBlock = CreateConVar("sm_weapinspect_fntblock", "1", "(0-1)Block inspection of food or thrown weapons", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HookEvent("player_spawn", Event_InventoryPost);
	HookEvent("post_inventory_application", Event_InventoryPost);
}

public void Event_InventoryPost(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	if (g_hCvarEnabled.BoolValue)
	{
		int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		
		if(IsValidClient(iClient) && CheckCommandAccess(iClient, "inspect_admin", 0))
		{
			int iWeapon[4];
			iWeapon[1] = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
			iWeapon[2] = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary);
			iWeapon[3] = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);

			if(IsValidEntity(iWeapon[1]))
				TF2Attrib_SetByName(iWeapon[1], "weapon_allow_inspect", 1.0);

			if(IsValidEntity(iWeapon[2]))
				if(!g_hCvarFoodThrowBlock.BoolValue || (g_hCvarFoodThrowBlock.BoolValue && !IsFoodOrThrownItem(iWeapon[2])))
					TF2Attrib_SetByName(iWeapon[2], "weapon_allow_inspect", 1.0);
			
			if(IsValidEntity(iWeapon[3]))
				TF2Attrib_SetByName(iWeapon[3], "weapon_allow_inspect", 1.0);
		}
	}
}

stock bool IsFoodOrThrownItem(int iWeapon)
{
	char strClassname[32];
	if(IsValidEdict(iWeapon))
	{
		GetEdictClassname(iWeapon, strClassname, sizeof(strClassname));

		if(!strcmp(strClassname, "tf_weapon_lunchbox_drink", false) || !strcmp(strClassname, "tf_weapon_lunchbox ", false))
			return true;
	
		if(!strcmp(strClassname, "tf_weapon_jar_milk", false) || !strcmp(strClassname, "tf_weapon_cleaver", false) || !strcmp(strClassname, "tf_weapon_jar", false))
			return true;
	}
	
	return false;
}

stock bool IsValidClient(int iClient)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;

	if(IsClientSourceTV(iClient) || IsClientReplay(iClient))
		return false;

	return true;
}