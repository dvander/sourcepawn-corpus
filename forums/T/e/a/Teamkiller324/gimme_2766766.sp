#pragma semicolon 1
#include <tf_econ_data>
#include <tf2attributes>

#pragma newdecls required

#define PLUGIN_VERSION "1.4"

public const int allowedWeps[45] = { 
	37, 172, 194, 197, 199, 200, 201, 202, 
	203, 205, 206, 207, 208, 209, 210, 211,
	214, 215, 220, 221, 228, 304, 305, 308,
	312, 326, 327, 329, 351, 401, 402, 404, 
	415, 424, 425, 447, 448, 449, 740, 996, 
	997, 1104, 1151, 1153, 1178 };

public Plugin myinfo =
{
	name = "[TF2] Gimme",
	author = "PC Gamer",
	description = "Give yourself or others an item",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

Handle g_hEquipWearable;
StringMap g_hItemInfoTrie;
ConVar g_hWeaponEffects;
ConVar g_hEnforceClassWeapons;
ConVar g_hEnforceClassCosmetics;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	g_hWeaponEffects = CreateConVar("sm_gimme_effects_enabled", "0", "Enables/disables unusual effects on gimme weapons", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hEnforceClassWeapons = CreateConVar("sm_gimme_enforce_class_weapons", "1", "Enables/disables enforcement of class specific weapons", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hEnforceClassCosmetics = CreateConVar("sm_gimme_enforce_class_cosmetics", "1", "Enables/disables enforcement of class specific cosmetics", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	RegAdminCmd("sm_gimme", Command_GetItem, ADMFLAG_SLAY, "Give me a weapon");
	RegAdminCmd("sm_giveitem", Command_GiveItem, ADMFLAG_SLAY, "Give target player a weapon");
	RegConsoleCmd("sm_index", Command_ShowIndex, "Gives Index URL" );	

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
	
	if (g_hItemInfoTrie != null)
	{
		delete g_hItemInfoTrie;
	}
	g_hItemInfoTrie = new StringMap();
	char strBuffer[256];
	BuildPath(Path_SM, strBuffer, sizeof(strBuffer), "configs/tf2items.givecustom.txt");
	if (FileExists(strBuffer))
	{
		CustomItemsTrieSetup(g_hItemInfoTrie);
	}
}

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iErrMax) 
{
	CreateNative("giveitem", Native_GiveItem);
	CreateNative("givewp", Native_GiveWP);	
	RegPluginLibrary("gimme");
	return APLRes_Success;
}

stock int Native_GiveItem(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int itemindex = GetNativeCell(2);
	if (!IsValidClient(client) || !IsPlayerAlive(client)) 
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "[Gimme] Target %N is invalid or dead at the moment", client);		
	}
	int trieweaponSlot;
	char formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", itemindex, "slot");
	bool isValidItem = GetTrieValue(g_hItemInfoTrie, formatBuffer, trieweaponSlot);
	if(isValidItem)
	{
		GiveWeaponCustom(client, itemindex);
		
		return true;
	}	
	else if(TF2Econ_IsValidItemDefinition(itemindex))	
	{
		EquipItemByItemIndex(client, itemindex);
		
		return true;
	}
	else
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "[Gimme] Invalid item index (%d)", itemindex);
	}
}

stock int Native_GiveWP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int itemindex = GetNativeCell(2);
	int warpaint = GetNativeCell(3);	
	if (!IsValidClient(client) || !IsPlayerAlive(client)) 
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "[Gimme] Target %N is invalid or dead at the moment", client);		
	}
	if (!FindInDef(itemindex))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "[Gimme] Weapon %i is not able to be Warpainted", itemindex);		
	}	
	if ((warpaint < 200) || (warpaint > 391) || (warpaint >297 && warpaint < 300) || (warpaint >310 && warpaint <390))
	{	
		return ThrowNativeError(SP_ERROR_NATIVE, "[Gimme] Warpaint ID of  %i is invalid", warpaint);		
	}
	EquipItemByItemIndex(client, itemindex, warpaint);
	return true;
}
public Action Command_GetItem(int client, int args)
{
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int itemindex = StringToInt(arg1);	

	char arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));
	int wpaint = StringToInt(arg2);	
	
	if (args < 1)
	{
		ReplyToCommand(client, "gimme <index number>");
		ReplyToCommand(client, "or gimme <warpaintable weapon id> <warpaint id>");		
		ReplyToCommand(client, "examples: !gimmme 205  or  !gimme 666  or  !gimme 205 200"); 
		ReplyToCommand(client, "for list of index numbers type: !index"); 

		return Plugin_Handled; 		
	}
	
	int trieweaponSlot;
	char formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", itemindex, "slot");
	bool isValidItem = g_hItemInfoTrie.GetValue(formatBuffer, trieweaponSlot);
	if(isValidItem)
	{
		GiveWeaponCustom(client, itemindex);
		
		return Plugin_Handled;
	}	

	if (!TF2Econ_IsValidItemDefinition(itemindex))
	{
		ReplyToCommand(client, "Unknown item index number: %i", itemindex);
		ReplyToCommand(client, "For list of index numbers type: !index"); 	
		
		return Plugin_Handled; 		
	}

	int itemSlot = TF2Econ_GetItemDefaultLoadoutSlot(itemindex);	

	if (itemSlot < 5 && g_hEnforceClassWeapons.BoolValue)
	{	
		if (TF2Econ_GetItemLoadoutSlot(itemindex, TF2_GetPlayerClass(client)) < 0)
		{
			PrintToChat(client, "Item %d is an invalid weapon for your current class", itemindex);
			PrintToChat(client, "For list of valid index numbers by class type: !index"); 

			return Plugin_Handled; 			
		}
	}

	if (itemSlot > 4 && g_hEnforceClassCosmetics.BoolValue)
	{	
		if (TF2Econ_GetItemLoadoutSlot(itemindex, TF2_GetPlayerClass(client)) < 0)
		{
			PrintToChat(client, "Item %d is an invalid weapon for your current class", itemindex);
			PrintToChat(client, "For list of valid index numbers by class type: !index");

			return Plugin_Handled;  			
		}
	}

	if (args > 1)
	{
		if (!FindInDef(itemindex))
		{
			ReplyToCommand(client, "that weapon is not able to be warpainted. Try another.");
			ReplyToCommand(client, "example: !gimme 205 300");

			return Plugin_Handled; 		
		}
		if ((wpaint < 200) || (wpaint > 391) || (wpaint >297 && wpaint < 300) || (wpaint >310 && wpaint <390))
		{
			ReplyToCommand(client, "valid warpaint ids: 200-297, 300-310, 390, 391"); 
			ReplyToCommand(client, "example: !wp 205 300");

			return Plugin_Handled; 		
		}
		else
		{
			EquipItemByItemIndex(client, itemindex, wpaint);
		}
		
		return Plugin_Handled;		
	}	
	else
	{
		EquipItemByItemIndex(client, itemindex);
	}
	
	return Plugin_Handled;
}

public Action Command_ShowIndex(int client, int args)
{
	ReplyToCommand(client, "https://wiki.alliedmods.net/Team_fortress_2_item_definition_indexes");
	
	return Plugin_Handled;
}

public Action Command_GiveItem(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "giveitem <target> <item index number>");
		ReplyToCommand(client, "or giveitem <target> <warpaintable weapon index number> <warpaint id>");		
	}
	
	char arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));
	int itemindex = StringToInt(arg2);
	
	char arg3[32];
	GetCmdArg(3, arg3, sizeof(arg3));
	int wpaint = StringToInt(arg3);	

	int trieweaponSlot;
	char formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", itemindex, "slot");
	bool isValidItem = g_hItemInfoTrie.GetValue(formatBuffer, trieweaponSlot);
	if(!isValidItem)
	{
		if (!TF2Econ_IsValidItemDefinition(itemindex))
		{
			ReplyToCommand(client, "Unknown item index number: %i", itemindex);
			ReplyToCommand(client, "For list of index numbers type: !index"); 	
			
			return Plugin_Handled; 
		}
	}

	if (args > 2)
	{
		if (!FindInDef(itemindex))
		{
			ReplyToCommand(client, "that weapon is not able to be warpainted. Try another.");
			ReplyToCommand(client, "example: !gimme 205 300");

			return Plugin_Handled; 		
		}

		if ((wpaint < 200) || (wpaint > 391) || (wpaint >297 && wpaint < 300) || (wpaint >310 && wpaint <390))
		{
			ReplyToCommand(client, "valid warpaint ids: 200-297, 300-310, 390, 391"); 
			ReplyToCommand(client, "example: !wp 205 300");

			return Plugin_Handled; 		
		}		
		
	}

	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if(isValidItem)
		{
			GiveWeaponCustom(target_list[i], itemindex);
			LogAction(client, target_list[i], "\"%L\" gave \"%L\" Custom Item %i", client, target_list[i], itemindex);
		}
		else if(wpaint > 0)
		{
			EquipItemByItemIndex(target_list[i], itemindex, wpaint);
			LogAction(client, target_list[i], "\"%L\" gave \"%L\" weapon %i with warpaint %i", client, target_list[i], itemindex, wpaint);
			ReplyToCommand(client, "gave %N weapon %i with warpaint %i", target_list[i], itemindex, wpaint);
		}
		else
		{
			EquipItemByItemIndex(target_list[i], itemindex);
			LogAction(client, target_list[i], "\"%L\" gave \"%L\" Item %i", client, target_list[i], itemindex);
			ReplyToCommand(client, "gave %N item number %i", target_list[i], itemindex);
		}
	}
	
	return Plugin_Handled;
}

void EquipItemByItemIndex(int client, int itemindex, int warpaint = 0)
{
	if (!TF2Econ_IsValidItemDefinition(itemindex))
	{
		PrintToChat(client, "Unknown item index number: %i", itemindex);
		PrintToChat(client, "For list of index numbers type: !index"); 	
		return;
	}

	int itemSlot = TF2Econ_GetItemDefaultLoadoutSlot(itemindex);
	
	int itemQuality = 6;

	char itemClassname[64];
	TF2Econ_GetItemClassName(itemindex, itemClassname, sizeof(itemClassname));
	TF2Econ_TranslateWeaponEntForClass(itemClassname, sizeof(itemClassname), TF2_GetPlayerClass(client));
	int itemLevel = GetRandomUInt(1, 100);
	
	char itemname[64];
	TF2Econ_GetItemName(itemindex, itemname, sizeof(itemname));
	PrintToChat(client, "%N received item %d (%s)", client, itemindex, itemname);

	Items_CreateNamedItem(client, itemindex, itemClassname, itemLevel, itemQuality, itemSlot, warpaint);
	
	return;
}

int Items_CreateNamedItem(int client, int itemindex, const char[] classname, int level, int quality, int weaponSlot, int warpaint)
{
	int newitem = CreateEntityByName(classname);
	
	if (!IsValidEntity(newitem))
	{
		return -1;
	}

	if (StrEqual(classname, "tf_weapon_invis"))
	{
		weaponSlot = 4;
	}
	
	if (itemindex == 735 || itemindex == 736 || StrEqual(classname, "tf_weapon_sapper"))
	{
		weaponSlot = 1;
	}
	
	if (StrEqual(classname, "tf_weapon_revolver"))
	{
		weaponSlot = 0;
	}	

	if(weaponSlot < 6)
	{
		TF2_RemoveWeaponSlot(client, weaponSlot);		
	}
	
	char entclass[64];

	GetEntityNetClass(newitem, entclass, sizeof(entclass));	
	SetEntData(newitem, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(newitem, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(newitem, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	if (level > 0)
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomUInt(1,99));
	}

	switch (itemindex)
	{
	case 735, 736, 810, 831, 933, 1080, 1102:
		{
			SetEntProp(newitem, Prop_Send, "m_iObjectType", 3);
			SetEntProp(newitem, Prop_Data, "m_iSubType", 3);
			SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
			SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
			SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
			SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
		}
	case 998:
		{
			SetEntData(newitem, FindSendPropInfo(entclass, "m_nChargeResistType"), GetRandomInt(0,2));
		}
	case 1071:
		{
			TF2Attrib_SetByName(newitem, "item style override", 0.0);
			TF2Attrib_SetByName(newitem, "loot rarity", 1.0);		
			TF2Attrib_SetByName(newitem, "turn to gold", 1.0);

			DispatchSpawn(newitem);
			EquipPlayerWeapon(client, newitem);
			
			return newitem; 
		}		
	}

	if(quality == 9) //self made quality
	{
		TF2Attrib_SetByName(newitem, "is australium item", 1.0);
		TF2Attrib_SetByName(newitem, "item style override", 1.0);
	}

	if (warpaint > 0)
	{
		TF2Attrib_SetByDefIndex(newitem, 834, view_as<float>(warpaint));
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 15);		
	}

	if(itemindex == 200 || itemindex == 220 || itemindex == 448 || itemindex == 15002 || itemindex == 15015 || itemindex == 15021 || itemindex == 15029 || itemindex == 15036 || itemindex == 15053 || itemindex == 15065 || itemindex == 15069 || itemindex == 15106 || itemindex == 15107 || itemindex == 15108 || itemindex == 15131 || itemindex == 15151 || itemindex == 15157 || itemindex == 449 || itemindex == 15013 || itemindex == 15018 || itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101
			|| itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 44 || itemindex == 221 || itemindex == 205 || itemindex == 228 || itemindex == 1104 || itemindex == 15006 || itemindex == 15014 || itemindex == 15028 || itemindex == 15043 || itemindex == 15052 || itemindex == 15057 || itemindex == 15081 || itemindex == 15104 || itemindex == 15105 || itemindex == 15129 || itemindex == 15130 || itemindex == 15150 || itemindex == 196 || itemindex == 447 || itemindex == 208 || itemindex == 215 || itemindex == 1178 || itemindex == 15005 || itemindex == 15017 || itemindex == 15030 || itemindex == 15034
			|| itemindex == 15049 || itemindex == 15054 || itemindex == 15066 || itemindex == 15067 || itemindex == 15068 || itemindex == 15089 || itemindex == 15090 || itemindex == 15115 || itemindex == 15141 || itemindex == 351 || itemindex == 740 || itemindex == 192 || itemindex == 214 || itemindex == 326 || itemindex == 206 || itemindex == 308 || itemindex == 996 || itemindex == 1151 || itemindex == 15077 || itemindex == 15079 || itemindex == 15091 || itemindex == 15092 || itemindex == 15116 || itemindex == 15117 || itemindex == 15142 || itemindex == 15158 || itemindex == 207 || itemindex == 130 || itemindex == 15009
			|| itemindex == 15012 || itemindex == 15024 || itemindex == 15038 || itemindex == 15045 || itemindex == 15048 || itemindex == 15082 || itemindex == 15083 || itemindex == 15084 || itemindex == 15113 || itemindex == 15137 || itemindex == 15138 || itemindex == 15155 || itemindex == 172 || itemindex == 327 || itemindex == 404 || itemindex == 202 || itemindex == 41 || itemindex == 312 || itemindex == 424 || itemindex == 15004 || itemindex == 15020 || itemindex == 15026 || itemindex == 15031 || itemindex == 15040 || itemindex == 15055 || itemindex == 15086 || itemindex == 15087 || itemindex == 15088 || itemindex == 15098
			|| itemindex == 15099 || itemindex == 15123 || itemindex == 15124 || itemindex == 15125 || itemindex == 15147 || itemindex == 425 || itemindex == 997 || itemindex == 197 || itemindex == 329 || itemindex == 15073 || itemindex == 15074 || itemindex == 15075 || itemindex == 15139 || itemindex == 15140 || itemindex == 15114 || itemindex == 15156 || itemindex == 305 || itemindex == 211 || itemindex == 15008 || itemindex == 15010 || itemindex == 15025 || itemindex == 15039 || itemindex == 15050 || itemindex == 15078 || itemindex == 15097 || itemindex == 15121 || itemindex == 15122 || itemindex == 15123 || itemindex == 15145
			|| itemindex == 15146 || itemindex == 35 || itemindex == 411 || itemindex == 37 || itemindex == 304 || itemindex == 201 || itemindex == 402 || itemindex == 15000 || itemindex == 15007 || itemindex == 15019 || itemindex == 15023 || itemindex == 15033 || itemindex == 15059 || itemindex == 15070 || itemindex == 15071 || itemindex == 15072 || itemindex == 15111 || itemindex == 15112 || itemindex == 15135 || itemindex == 15136 || itemindex == 15154 || itemindex == 203 || itemindex == 15001 || itemindex == 15022 || itemindex == 15032 || itemindex == 15037 || itemindex == 15058 || itemindex == 15076 || itemindex == 15110
			|| itemindex == 15134 || itemindex == 15153 || itemindex == 193 || itemindex == 401 || itemindex == 210 || itemindex == 15011 || itemindex == 15027 || itemindex == 15042 || itemindex == 15051 || itemindex == 15062 || itemindex == 15063 || itemindex == 15064 || itemindex == 15103 || itemindex == 15128 || itemindex == 15129 || itemindex == 15149 || itemindex == 194 || itemindex == 649 || itemindex == 15062 || itemindex == 15094 || itemindex == 15095 || itemindex == 15096 || itemindex == 15118 || itemindex == 15119 || itemindex == 15143 || itemindex == 15144 || itemindex == 209 || itemindex == 15013 || itemindex == 15018
			|| itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101 || itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 415 || itemindex == 15003 || itemindex == 15016 || itemindex == 15044 || itemindex == 15047 || itemindex == 15085 || itemindex == 15109 || itemindex == 15132 || itemindex == 15133 || itemindex == 15152 || itemindex == 1153)
	{
		if(GetRandomInt(1,30) == 1) //festive check
		{
			TF2Attrib_SetByDefIndex(newitem, 2053, 1.0);
		}
	}
	
	if(quality == 11) //strange quality
	{
		if (GetRandomInt(1,10) == 1)
		{
			TF2Attrib_SetByDefIndex(newitem, 2025, 1.0);
		}
		else if (GetRandomInt(1,10) == 2)
		{
			TF2Attrib_SetByDefIndex(newitem, 2025, 2.0);
			TF2Attrib_SetByDefIndex(newitem, 2014, GetRandomInt(1,7) + 0.0);
		}
		else if (GetRandomInt(1,10) == 3)
		{
			TF2Attrib_SetByDefIndex(newitem, 2025, 3.0);
			TF2Attrib_SetByDefIndex(newitem, 2014, GetRandomInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(newitem, 2013, GetRandomInt(2002,2008) + 0.0);
		}
		TF2Attrib_SetByDefIndex(newitem, 214, view_as<float>(GetRandomInt(0, 9000)));
	}
	
	if (quality == 15)
	{
		switch(itemindex)
		{
		case 30665, 30666, 30667, 30668:
			{
				TF2Attrib_RemoveByDefIndex(newitem, 725);
			}
		default:
			{
				TF2Attrib_SetByDefIndex(newitem, 725, GetRandomFloat(0.0,1.0));
			}
		}
	}
	
	if(weaponSlot < 2)
	{
		TF2Attrib_SetByDefIndex(newitem, 725, 0.0);
	}

	DispatchSpawn(newitem);
	
	if (StrContains(classname, "tf_wearable", false) !=-1)
	{
		RemoveConflictWearables(client, itemindex);

		SDKCall(g_hEquipWearable, client, newitem);
	}	
	else
	{
		EquipPlayerWeapon(client, newitem);
	}
	
	
	if (g_hWeaponEffects.BoolValue)
	{
		if (itemindex == 13
				|| itemindex == 200
				|| itemindex == 23
				|| itemindex == 209
				|| itemindex == 18
				|| itemindex == 205
				|| itemindex == 10
				|| itemindex == 199
				|| itemindex == 21
				|| itemindex == 208
				|| itemindex == 12
				|| itemindex == 19
				|| itemindex == 206
				|| itemindex == 20
				|| itemindex == 207
				|| itemindex == 15
				|| itemindex == 202
				|| itemindex == 11
				|| itemindex == 9
				|| itemindex == 22
				|| itemindex == 29
				|| itemindex == 211
				|| itemindex == 14
				|| itemindex == 201
				|| itemindex == 16
				|| itemindex == 203
				|| itemindex == 24
				|| itemindex == 4
				|| itemindex == 194				
				|| itemindex == 210)	
		{
			SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
			TF2_SwitchtoSlot(client, weaponSlot);
			int iRand = GetRandomUInt(1,4);
			if (iRand == 1)
			{
				TF2Attrib_SetByDefIndex(newitem, 134, 701.0);	
			}
			else if (iRand == 2)
			{
				TF2Attrib_SetByDefIndex(newitem, 134, 702.0);	
			}	
			else if (iRand == 3)
			{
				TF2Attrib_SetByDefIndex(newitem, 134, 703.0);	
			}
			else if (iRand == 4)
			{
				TF2Attrib_SetByDefIndex(newitem, 134, 704.0);	
			}
		}
	}

	TF2_SwitchtoSlot(client, 0);	
	
	return newitem;
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

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}

bool FindInDef(const int def)
{
	for(int i = 0; i < sizeof(allowedWeps); i++)
	{
		if(allowedWeps[i] == def)
		return true;
	}

	return false;
}

bool RemoveConflictWearables(int client, int newindex)
{
	int wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if(GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity") == client)
		{
			int oldindex = GetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex");
			
			if(oldindex >1 && oldindex !=65535)
			{
				if(TF2Econ_GetItemEquipRegionMask(oldindex) & TF2Econ_GetItemEquipRegionMask(newindex) > 0)
				{
					TF2_RemoveWearable (client, wearable);			
				}
			}
		}
	}
}

stock int CustomItemsTrieSetup(StringMap trie)
{
	char strBuffer[256], strBuffer2[256], strBuffer3[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, strBuffer, sizeof(strBuffer), "configs/tf2items.givecustom.txt");
	KeyValues kv = new KeyValues("Gimme");
	if(FileToKeyValues(kv, strBuffer) == true)
	{
		kv.GetSectionName(strBuffer, sizeof(strBuffer));
		if (StrEqual("custom_give_weapons_vlolz", strBuffer) == true)
		{
			if (kv.GotoFirstSubKey())
			{
				do
				{
					kv.GetSectionName(strBuffer, sizeof(strBuffer));
					if (strBuffer[0] != '*')
					{
						Format(strBuffer2, 32, "%s_%s", strBuffer, "classname");
						kv.GetString("classname", strBuffer3, sizeof(strBuffer3));
						trie.SetString(strBuffer2, strBuffer3);
						Format(strBuffer2, 32, "%s_%s", strBuffer, "index");
						trie.SetValue(strBuffer2, kv.GetNum("index"));
						Format(strBuffer2, 32, "%s_%s", strBuffer, "slot");
						trie.SetValue(strBuffer2, kv.GetNum("slot"));
						Format(strBuffer2, 32, "%s_%s", strBuffer, "quality");
						trie.SetValue(strBuffer2, kv.GetNum("quality"));
						Format(strBuffer2, 32, "%s_%s", strBuffer, "level");
						trie.SetValue(strBuffer2, kv.GetNum("level"));
						Format(strBuffer2, 256, "%s_%s", strBuffer, "attribs");
						kv.GetString("attribs", strBuffer3, sizeof(strBuffer3));
						trie.SetString(strBuffer2, strBuffer3);
						Format(strBuffer2, 32, "%s_%s", strBuffer, "ammo");
						trie.SetValue(strBuffer2, kv.GetNum("ammo", -1));
					}
				}
				while (kv.GotoNextKey());
				kv.GoBack();
			}
		}
	}
	delete kv;
}

public int GiveWeaponCustom(int client, int configindex)
{
	int index;
	int slot;
	int quality;
	int level;
	int ammo;
	char weaponClass[64];
	char attribs[256];
	char formatBuffer[64];
	
	Format(formatBuffer, 32, "%d_%s", configindex, "classname");
	g_hItemInfoTrie.GetString(formatBuffer, weaponClass, sizeof(weaponClass));
	Format(formatBuffer, 32, "%d_%s", configindex, "index");
	g_hItemInfoTrie.GetValue(formatBuffer, index);
	Format(formatBuffer, 32, "%d_%s", configindex, "slot");
	g_hItemInfoTrie.GetValue(formatBuffer, slot);
	Format(formatBuffer, 32, "%d_%s", configindex, "quality");
	g_hItemInfoTrie.GetValue(formatBuffer, quality);	
	Format(formatBuffer, 32, "%d_%s", configindex, "level");
	g_hItemInfoTrie.GetValue(formatBuffer, level);	
	Format(formatBuffer, 32, "%d_%s", configindex, "ammo");
	g_hItemInfoTrie.GetValue(formatBuffer, ammo);
	Format(formatBuffer, 32, "%d_%s", configindex, "attribs");
	g_hItemInfoTrie.GetString(formatBuffer, attribs, sizeof(attribs));
	char weaponAttribsArray[32][32];
	int attribCount = ExplodeString(attribs, " ; ", weaponAttribsArray, 32, 32);

	if(StrEqual(weaponClass, "tf_weapon_shotgun"))
	{
		TFClassType class = TF2_GetPlayerClass(client);
		if(class == TFClass_Unknown || class == TFClass_Scout || class == TFClass_Sniper || class == TFClass_DemoMan || class == TFClass_Medic || class == TFClass_Spy)
		{
			strcopy(weaponClass, 64, "tf_weapon_shotgun_primary");
		}
		else if(class == TFClass_Soldier) strcopy(weaponClass, 64, "tf_weapon_shotgun_soldier");
		else if(class == TFClass_Heavy) strcopy(weaponClass, 64, "tf_weapon_shotgun_hwg");
		else if(class == TFClass_Pyro) strcopy(weaponClass, 64, "tf_weapon_shotgun_pyro");
		else if(class == TFClass_Engineer) strcopy(weaponClass, 64, "tf_weapon_shotgun_primary");
	}
	if(StrEqual(weaponClass, "saxxy"))
	{
		TFClassType class = TF2_GetPlayerClass(client);
		switch(class)
		{
		case TFClass_Scout: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_bat");
		case TFClass_Sniper: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_club");
		case TFClass_Soldier: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_shovel");
		case TFClass_DemoMan: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_bottle");
		case TFClass_Engineer: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_wrench");
		case TFClass_Pyro: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_fireaxe");
		case TFClass_Heavy: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_fireaxe");
		case TFClass_Spy: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_knife");
		case TFClass_Medic: strcopy(weaponClass, sizeof(weaponClass), "tf_weapon_bonesaw");
		}
	}

	int newitem = CreateEntityByName(weaponClass);	
	
	if (!IsValidEntity(newitem))
	{
		return -1;
	}

	if (StrEqual(weaponClass, "tf_weapon_invis"))
	{
		slot = 4;
	}
	
	if (index == 735 || index == 736 || StrEqual(weaponClass, "tf_weapon_sapper"))
	{
		slot = 1;
	}
	
	if (StrEqual(weaponClass, "tf_weapon_revolver"))
	{
		slot = 0;
	}	

	if(slot < 6)
	{
		TF2_RemoveWeaponSlot(client, slot);		
	}	
	
	char entclass[64];

	GetEntityNetClass(newitem, entclass, sizeof(entclass));	
	SetEntData(newitem, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), index);
	SetEntData(newitem, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntProp(newitem, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	if (level > 0)
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		level = GetRandomUInt(1,99);
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}

	if (quality > 0)
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	}
	else
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);
	}	

	if (index == 735 || index == 736 || StrEqual(weaponClass, "tf_weapon_sapper"))
	{
		SetEntProp(newitem, Prop_Send, "m_iObjectType", 3);
		SetEntProp(newitem, Prop_Data, "m_iSubType", 3);
		SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
		SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
		SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
		SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
	}
	
	DispatchSpawn(newitem);

	if (attribCount > 1) 
	{
		int attrIdx;
		float attrVal;
		int i2 = 0;
		for (int i = 0; i < attribCount; i+=2) {
			attrIdx = StringToInt(weaponAttribsArray[i]);
			if (attrIdx <= 0)
			{
				LogError("Tried to set attribute index to %d on item index %d, attrib string was '%s', count was %d", attrIdx, index, attribs, attribCount);
				continue;
			}
			switch (attrIdx)
			{
			case 133, 143, 147, 152, 184, 185, 186, 192, 193, 194, 198, 211, 214, 227, 228, 229, 262, 294, 302, 372, 373, 374, 379, 381, 383, 403, 420:
				{
					attrVal = float(StringToInt(weaponAttribsArray[i+1]));
				}
			default:
				{
					attrVal = StringToFloat(weaponAttribsArray[i+1]);
				}
			}
			TF2Attrib_SetByDefIndex(newitem, attrIdx, attrVal);
			i2++;
		}
	}

	if (StrContains(weaponClass, "tf_wearable", false) !=-1)
	{
		RemoveConflictWearables(client, index);

		SDKCall(g_hEquipWearable, client, newitem);
	}	
	else
	{
		EquipPlayerWeapon(client, newitem);
	}
	
	if (ammo > 0)
	{
		SetNewAmmo(client, slot, ammo);
	}	

	char itemname[64];
	TF2Econ_GetItemName(index, itemname, sizeof(itemname));
	PrintToChat(client, "%N received custom item %i (%s)", client, index, itemname);

	return newitem;
}

stock void SetNewAmmo(int client, int wepslot, int newAmmo)
{
	int weapon = GetPlayerWeaponSlot(client, wepslot);
	if (!IsValidEntity(weapon)) return;
	int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (type < 0 || type > 31) return;
	SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, type);	
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}