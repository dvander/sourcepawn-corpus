#include <sourcemod>
#include <cstrike>
#include <smlib>

#undef REQUIRE_PLUGIN

#pragma semicolon 1



#define MAX_ENTITIES 4096
#define PLUGIN_VERSION "0.5.2"




public Plugin:myinfo = 
{
	name = "Default weaponclips",
	author = "Impact",
	description = "Sets the secondary ammo of weapons to default/defined values upon first use",
	version = PLUGIN_VERSION,
	url = "http://gugyclan.eu"
}




new Handle:g_hVersion;
new bool:g_bWeaponWasUsed[MAX_ENTITIES];
new Handle:g_hTrie;





public OnPluginStart()
{
	g_hVersion = CreateConVar("sm_default_weapon_clips_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY);
	
	HookEvent("item_pickup", OnItemPickup);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	
	
	SetConVarString(g_hVersion, PLUGIN_VERSION, false, false);
	HookConVarChange(g_hVersion, OnCvarChanged);
	
	
	g_hTrie = CreateTrie();
	
	
	// Add or change weapons how you want
	SetTrieValue(g_hTrie, "weapon_galil", 90);
	SetTrieValue(g_hTrie, "weapon_ak47", 90);
	SetTrieValue(g_hTrie, "weapon_scout", 90);
	SetTrieValue(g_hTrie, "weapon_sg552", 90);
	SetTrieValue(g_hTrie, "weapon_awp", 30);
	SetTrieValue(g_hTrie, "weapon_g3sg1", 90);
	SetTrieValue(g_hTrie, "weapon_famas", 90);
	SetTrieValue(g_hTrie, "weapon_m4a1", 90);
	SetTrieValue(g_hTrie, "weapon_aug", 90);
	SetTrieValue(g_hTrie, "weapon_sg550", 90);
	SetTrieValue(g_hTrie, "weapon_glock", 120);
	SetTrieValue(g_hTrie, "weapon_usp", 100);
	SetTrieValue(g_hTrie, "weapon_p228", 52);
	SetTrieValue(g_hTrie, "weapon_deagle", 35);
	SetTrieValue(g_hTrie, "weapon_elite", 120);
	SetTrieValue(g_hTrie, "weapon_fiveseven", 100);
	SetTrieValue(g_hTrie, "weapon_m3", 32);
	SetTrieValue(g_hTrie, "weapon_xm1014",32);
	SetTrieValue(g_hTrie, "weapon_mac10", 100);
	SetTrieValue(g_hTrie, "weapon_tmp", 120);
	SetTrieValue(g_hTrie, "weapon_mp5navy", 120);
	SetTrieValue(g_hTrie, "weapon_ump45", 100);
	SetTrieValue(g_hTrie, "weapon_p90", 100);
	SetTrieValue(g_hTrie, "weapon_m249", 200);
}








public OnCvarChanged(Handle:convar, const String:oldVal[], const String:newVal[])
{
	if(convar == g_hVersion)
	{
		SetConVarString(g_hVersion, PLUGIN_VERSION, false, false);
	}
}






public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetWeapons();
}






public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetWeapons();
}






ResetWeapons()
{
	for(new i; i < MAX_ENTITIES; i++)
	{
		g_bWeaponWasUsed[i] = false;
	}
}






public Action:OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	static client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientValid(client))
	{
		SetClientAmmo(client);
	}
}






SetClientAmmo(client)
{
	static index;

	if( (index = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) ) != -1)
	{
		if(!g_bWeaponWasUsed[index])
		{
			g_bWeaponWasUsed[index] = true;
			ProcessWeapon(client, index);
		}
	}
	if( (index = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) ) != -1)
	{
		if(!g_bWeaponWasUsed[index])
		{
			g_bWeaponWasUsed[index] = true;
			ProcessWeapon(client, index);
		}
	}
}






ProcessWeapon(client, index)
{
	static count;
	static count2;
	static String:clsname[32];
	count = Weapon_GetPrimaryClip(index);
	
	GetEntityClassname(index, clsname, sizeof(clsname));
	
	if(!GetTrieValue(g_hTrie, clsname, count2))
	{
		count2 = count*3;
	}
	
	Client_SetWeaponPlayerAmmoEx(client, index, count2, -1);
}






stock bool:IsClientValid(id)
{
	if(id > 0 && id <= MaxClients && IsClientInGame(id))
	{
		return true;
	}
	
	return false;
}

