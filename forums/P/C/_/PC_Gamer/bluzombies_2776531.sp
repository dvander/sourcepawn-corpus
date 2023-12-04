#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

bool g_bZombie[MAXPLAYERS+1] = {false, ... };
Handle g_hEquipWearable;

public Plugin myinfo = 
{
	name = "BLU Zombies",
	author = "PC Gamer",
	description = "Makes BLU Team Zombies",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/"
}

public void OnPluginStart() 
{
	HookEvent("post_inventory_application", player_inv);
	
	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamedata

	if (!hTF2)
	SetFailState("This plugin is designed for a TF2 dedicated server only.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);    // EquipWearable offset is always behind RemoveWearable, subtract its value by 1
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hEquipWearable = EndPrepSDKCall();

	if (!g_hEquipWearable)
	SetFailState("Failed to create call: CBasePlayer::EquipWearable");

	delete hTF2;
}

public void player_inv(Handle event, const char[] name, bool dontBroadcast) 
{
	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	
	if (GetClientTeam(client) == 3)
	{
		g_bZombie[client] = true;
		Makezombie(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_SwitchtoMelee(client);		
	}
	if (GetClientTeam(client) == 2 && g_bZombie[client])
	{
		Makenozombie(client);
	}
}

public Action Makezombie(int client)
{
	switch(TF2_GetPlayerClass(client))
	{
	case TFClass_Scout: GiveVoodooItem(client, 5617);
	case TFClass_Soldier: GiveVoodooItem(client, 5618);
	case TFClass_Pyro: GiveVoodooItem(client, 5624);
	case TFClass_DemoMan: GiveVoodooItem(client, 5620);
	case TFClass_Heavy: GiveVoodooItem(client, 5619);
	case TFClass_Engineer: GiveVoodooItem(client, 5621);
	case TFClass_Medic: GiveVoodooItem(client, 5622);
	case TFClass_Sniper: GiveVoodooItem(client, 5625);
	case TFClass_Spy: GiveVoodooItem(client, 5623);
	}

	g_bZombie[client] = true;	
	
	CreateTimer(0.1, Timer_Makezombie2, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action Timer_Makezombie2(Handle timer, int client)	
{
	if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)==2 && TF2_GetPlayerClass(client) !=TFClass_Spy)
	{
		TF2Attrib_SetByName(client, "player skin override", 1.0);
		TF2Attrib_SetByName(client, "zombiezombiezombiezombie", 1.0);
		TF2Attrib_SetByName(client, "SPELL: Halloween voice modulation", 1.0);		
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 1);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 4);
	}
	if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)==3 && TF2_GetPlayerClass(client) !=TFClass_Spy)
	{
		TF2Attrib_SetByName(client, "player skin override", 1.0);
		TF2Attrib_SetByName(client, "zombiezombiezombiezombie", 1.0);
		TF2Attrib_SetByName(client, "SPELL: Halloween voice modulation", 1.0);	
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 1);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 5);
	}	
	if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)==2 && TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		TF2Attrib_SetByName(client, "player skin override", 1.0);
		TF2Attrib_SetByName(client, "zombiezombiezombiezombie", 1.0);
		TF2Attrib_SetByName(client, "SPELL: Halloween voice modulation", 1.0);		
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 1);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 22);
	}
	if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)==3 && TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		TF2Attrib_SetByName(client, "player skin override", 1.0);
		TF2Attrib_SetByName(client, "zombiezombiezombiezombie", 1.0);
		TF2Attrib_SetByName(client, "SPELL: Halloween voice modulation", 1.0);		
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 1);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 23);
	}
	
	return Plugin_Handled;
}

public Action Makenozombie(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2Attrib_SetByName(client, "player skin override", 0.0);
		TF2Attrib_SetByName(client, "zombiezombiezombiezombie", 0.0);
		TF2Attrib_SetByName(client, "SPELL: Halloween voice modulation", 0.0);			
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 0);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);		

		g_bZombie[client] = false;
	}
	
	return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

bool GiveVoodooItem(int client, int itemindex)
{
	int soul = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(soul))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(soul, entclass, sizeof(entclass));
	SetEntData(soul, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(soul, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	
	SetEntData(soul, FindSendPropInfo(entclass, "m_iEntityLevel"), 6);
	SetEntData(soul, FindSendPropInfo(entclass, "m_iEntityQuality"), 13);
	SetEntProp(soul, Prop_Send, "m_bValidatedAttachedEntity", 1);		
	
	DispatchSpawn(soul);
	SDKCall(g_hEquipWearable, client, soul);
	return true;
}

public Action TF2_SwitchtoMelee(int client)
{
	char wepclassname[64];
	int wep = GetPlayerWeaponSlot(client, 2);
	if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, wepclassname, sizeof(wepclassname)))
	{
		FakeClientCommandEx(client, "use %s", wepclassname);
	}
	
	return Plugin_Handled;
} 
