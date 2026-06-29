#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

new Handle:g_hCvarEnabled,			bool:g_bCvarEnabled;
new Handle:g_hCvarRemoveSlot1,		bool:g_bCvarRemoveSlot1;
new Handle:g_hCvarRemoveSlot2,		bool:g_bCvarRemoveSlot2;
new Handle:g_hCvarFairySize,		Float:g_flCvarFairySize;

#define ITEM_CROWN    932
#define ITEM_DRESS    930
#define ITEM_WINGS    931

public Plugin:myinfo = 
{
	name = "[TF2] TinyFairy",
	author = "Pelipoika",
	description = "Heavy feel funny",
	version = "1.2.0",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	HookConVarChange(g_hCvarEnabled = CreateConVar("sm_fairy_enabled", "1.0", "Enable Small Fairy Heavies\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0), OnConVarChange);
	HookConVarChange(g_hCvarRemoveSlot1 = CreateConVar("sm_fairy_removeslot1", "1.0", "Remove Fairy Heavies Slot1 (Minigun)\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0), OnConVarChange);
	HookConVarChange(g_hCvarRemoveSlot2 = CreateConVar("sm_fairy_removeslot2", "0.0", "Remove Fairy Heavies Slot2 (Shotgun/Sandvich)\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0), OnConVarChange);
	HookConVarChange(g_hCvarFairySize = CreateConVar("sm_fairy_size", "0.6", _, FCVAR_PLUGIN, true, 0.0), OnConVarChange);
	
	HookEvent("player_spawn", OnPostInventoryApplicationAndPlayerSpawn);
	HookEvent("post_inventory_application", OnPostInventoryApplicationAndPlayerSpawn);
	
	AutoExecConfig(true);
}

public OnConfigsExecuted()
{
	g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	g_bCvarRemoveSlot1 = GetConVarBool(g_hCvarRemoveSlot1);
	g_bCvarRemoveSlot2 = GetConVarBool(g_hCvarRemoveSlot2);
	g_flCvarFairySize = GetConVarFloat(g_hCvarFairySize);
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	OnConfigsExecuted();
}

public Action:OnPostInventoryApplicationAndPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new iEnt = -1;
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
	
	if (IsClientInGame(client) && IsPlayerAlive(client) &&  TF2_GetPlayerClass(client) == TFClass_Heavy) 
	{
		if(!g_bCvarEnabled) 
			return Plugin_Continue;
		
		new bool:bCrownPresent = false;
		new bool:bDressPresent = false;
		new bool:bWingsPresent = false;
		
		while ((iEnt = FindEntityByClassname(iEnt, "tf_wearable")) != -1) 
		{		
			if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") == client)
			{
				new iItemIndex = GetEntProp(iEnt, Prop_Send, "m_iItemDefinitionIndex");
				
				if (iItemIndex == ITEM_CROWN) bCrownPresent = true;
				if (iItemIndex == ITEM_DRESS) bDressPresent = true;
				if (iItemIndex == ITEM_WINGS) bWingsPresent = true;
			}
		}

		if (bCrownPresent && bDressPresent && bWingsPresent) 
		{
			new weapon = GetPlayerWeaponSlot(client, 2);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);  
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_flCvarFairySize);
			
			if(g_bCvarRemoveSlot1)
			{
				TF2_RemoveWeaponSlot(client, 0);
			}
			if(g_bCvarRemoveSlot2)
			{
				TF2_RemoveWeaponSlot(client, 1);
			}
		}
	}
	return 0;
}

//vo\heavy_fairyprincess01.wav - 19