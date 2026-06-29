#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <freak_fortress_2>

#define MAJOR_REVISION "1"
#define MINOR_REVISION "1"
#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION

public Plugin:myinfo = {
	name = "TF2: Turbotastic Mode",
	author = "Waka Flocka Flame",
	description="OHMERGAWDSOOPLOL",
	version=PLUGIN_VERSION,
};

public OnPluginStart()
{
	LogMessage("TURBOTASTIC MODE INITALIZING (v%s))", PLUGIN_VERSION);
	HookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_PostNoCopy);
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (!IsClientConnected(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

public Action:OnPlayerInventory(Handle:event, const String:name[], bool:dontbroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new boss = FF2_GetBossIndex(client);
	if(boss != -1)
	{
		TF2Attrib_RemoveAll(boss);
		TF2Attrib_RemoveAll(client);
		TF2Attrib_SetByName(boss, "damage force reduction", 0.3);
	}
	
	if(boss == -1 && IsValidClient(client))
	{
		TF2Attrib_SetByName(client, "health regen", 15.0);
		TF2Attrib_SetByName(client, "Reload time decreased", 0.4);
		TF2Attrib_SetByName(client, "max health additive bonus", 50.0);
		TF2Attrib_SetByName(client, "fire rate bonus", 0.5);
		TF2Attrib_SetByName(client, "ammo regen", 100.0);
		TF2Attrib_SetByName(client, "boots falling stomp", 1.0);
		TF2Attrib_SetByName(client,	"rocket jump damage reduction", 0.8);
		TF2Attrib_SetByName(client, "blast dmg to self increased", 0.8);
		
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_DemoMan: TF2Attrib_SetByName(client, "max pipebombs increased", 2.0);
			case TFClass_Engineer: 	TF2Attrib_SetByName(client,	"metal regen", 200.0);
		}
	
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_Scout: TF2Attrib_SetByName(client, "move speed bonus", 1.25);
			case TFClass_Heavy: TF2Attrib_SetByName(client, "move speed bonus", 1.75);
			case TFClass_Soldier: TF2Attrib_SetByName(client, "move speed bonus", 1.75); 
			default: TF2Attrib_SetByName(client, "move speed bonus", 1.50);
		}
	
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		new index=-1;
		if(slot && IsValidEdict(slot))
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Primary));
			index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			switch(index)
			{
				case 405, 608, 1101: 
				{
					// NOOP
				}
				case 730:
				{
					TF2Attrib_SetByName(weapon, "maxammo primary increased", 2.0);
					TF2Attrib_SetByName(weapon, "damage bonus", 1.75);
					TF2Attrib_SetByName(weapon, "clip size bonus", 2.0);
				}
				case 1104:
				{
					TF2Attrib_SetByName(weapon, "clip size bonus", 2.5);
				}
				default:
				{
					TF2Attrib_SetByName(weapon, "maxammo primary increased", 2.0);
					TF2Attrib_SetByName(weapon, "damage bonus", 1.75);
					TF2Attrib_SetByName(weapon, "clip size bonus", 2.0);
				}
			}
		}
		slot=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(slot && IsValidEdict(slot))
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary));
			weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			switch(index)
			{
				case 42, 46, 57, 58, 129, 131, 133, 140, 159, 163, 222, 231, 266, 311, 354, 406, 433, 444, 642, 735, 736, 810, 831, 863, 933, 1001, 1002, 1080, 1083, 1086, 1099, 1101, 1102, 1105, 1121, 1144, 1145:
				{
					// NOOP
				}
				case 29, 211, 35, 411, 663, 796, 805, 885, 894, 903, 912, 961, 970, 998:
				{
					// Mediguns
					TF2Attrib_SetByName(weapon, "generate rage on heal", 50.0);		
				}
				default:
				{
					TF2Attrib_SetByName(weapon, "maxammo secondary increased", 2.0);
					TF2Attrib_SetByName(weapon, "damage bonus", 1.75);	
					TF2Attrib_SetByName(weapon, "clip size bonus", 2.0);			
				}	
			}
		}
		slot=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(slot && IsValidEdict(slot))
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Melee));
			weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			TF2Attrib_SetByName(weapon, "damage bonus", 1.75);	
		}
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Primary));
	}
}
