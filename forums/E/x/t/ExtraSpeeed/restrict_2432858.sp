#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>

public Plugin:myinfo =
{
	name = "Remove Weapons (Based on DeathRun Redux)",
	author = "XaH JoB",
	description = "You can remove custom weapons on your server.",
	version = "1.0",
	url = ""
};

new Handle:g_RestrictedWeps;
new Handle:g_AllClassWeps;

public OnPluginStart()
{
	g_RestrictedWeps = CreateArray(ByteCountToCells(8));
	g_AllClassWeps = CreateArray(ByteCountToCells(8));
	
	HookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_Post);
}

public OnMapStart()
{
	ClearArray(g_RestrictedWeps);
	ClearArray(g_AllClassWeps);

	new Handle:hKeyValues = CreateKeyValues("RestrictedWeapons");
	if(FileToKeyValues(hKeyValues, "addons/sourcemod/configs/restrict.cfg"))
	{
		if(KvJumpToKey(hKeyValues, "RestrictedWeapons") && KvGotoFirstSubKey(hKeyValues, false))
		{
			do
			{
				PushArrayCell(g_RestrictedWeps, KvGetNum(hKeyValues, NULL_STRING));
			}
			while(KvGotoNextKey(hKeyValues, false));
		}
		KvRewind(hKeyValues);
		if(KvJumpToKey(hKeyValues, "AllClassWeapons") && KvGotoFirstSubKey(hKeyValues, false))
		{
			do
			{
				PushArrayCell(g_AllClassWeps, KvGetNum(hKeyValues, NULL_STRING));
			}
			while(KvGotoNextKey(hKeyValues, false));
		}
	}
	else
	{
		SetFailState("Couldn't open file 'addons/sourcemod/configs/restrict.cfg'");
	}
}

public Action:OnPlayerInventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new wepEnt = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	new wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex"); 
	if(FindValueInArray(g_RestrictedWeps, wepIndex) != -1)
	{
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
		new weaponToUse = GetRandomInt(-1, GetArraySize(g_AllClassWeps)-1);
		if(weaponToUse != -1)
		{
			weaponToUse = GetArrayCell(g_AllClassWeps, weaponToUse);
		}

		new Handle:hItem = TF2Items_CreateItem(FORCE_GENERATION | OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);
		
		new TFClassType:iClass = TF2_GetPlayerClass(client);
		switch(iClass)
		{
		case TFClass_Scout:{
				TF2Items_SetClassname(hItem, "tf_weapon_bat");
				if(weaponToUse == -1)
				weaponToUse = 190;
				TF2Items_SetItemIndex(hItem, weaponToUse);
			}
		case TFClass_Sniper:{
				TF2Items_SetClassname(hItem, "tf_weapon_club");
				if(weaponToUse == -1)
				weaponToUse = 190;
				TF2Items_SetItemIndex(hItem, weaponToUse);
				TF2Items_SetItemIndex(hItem, 193);
			}
		case TFClass_Soldier:{
				TF2Items_SetClassname(hItem, "tf_weapon_shovel");
				if(weaponToUse == -1)
				weaponToUse = 196;
				TF2Items_SetItemIndex(hItem, weaponToUse);
			}
		case TFClass_DemoMan:{
				TF2Items_SetClassname(hItem, "tf_weapon_bottle");
				if(weaponToUse == -1)
				weaponToUse = 191;
				TF2Items_SetItemIndex(hItem, weaponToUse);
			}
		case TFClass_Medic:{
				TF2Items_SetClassname(hItem, "tf_weapon_bonesaw");
				if(weaponToUse == -1)
				weaponToUse = 198;
				TF2Items_SetItemIndex(hItem, weaponToUse);
			}
		case TFClass_Heavy:{
				TF2Items_SetClassname(hItem, "tf_weapon_fists");
				if(weaponToUse == -1)
				weaponToUse = 195;
				TF2Items_SetItemIndex(hItem, weaponToUse);
			}
		case TFClass_Pyro:{
				TF2Items_SetClassname(hItem, "tf_weapon_fireaxe");
				if(weaponToUse == -1)
				weaponToUse = 192;
				TF2Items_SetItemIndex(hItem, weaponToUse);
			}
		case TFClass_Spy:{
				TF2Items_SetClassname(hItem, "tf_weapon_knife");
				if(weaponToUse == -1)
				weaponToUse = 194;
				TF2Items_SetItemIndex(hItem, weaponToUse);
			}
		case TFClass_Engineer:{
				TF2Items_SetClassname(hItem, "tf_weapon_wrench");
				if(weaponToUse == -1)
				weaponToUse = 197;
				TF2Items_SetItemIndex(hItem, weaponToUse);
			}
		}
		
		TF2Items_SetLevel(hItem, 69);
		TF2Items_SetQuality(hItem, 6);
		TF2Items_SetAttribute(hItem, 0, 150, 1.0);
		TF2Items_SetNumAttributes(hItem, 1);
		new iWeapon = TF2Items_GiveNamedItem(client, hItem);
		CloseHandle(hItem);
		
		EquipPlayerWeapon(client, iWeapon);
	}
}