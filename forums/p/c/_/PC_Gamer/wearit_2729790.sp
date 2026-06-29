#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <tf2_stocks>
#include <TF2attributes>

#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.6"

Handle g_hWearableEquip;
Cookie g_hClientItems[16];
Cookie g_hClientClass;
bool b_Transmit[MAXPLAYERS + 1] = {false, ...};

public Plugin myinfo = 
{
	name = "Wear It",
	author = "PC Gamer",
	description = "Players can wear any cosmetics. Admins can force wear of any cosmetics.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2729790"
}

public void OnPluginStart() 
{
	LoadTranslations("common.phrases");

	RegConsoleCmd("sm_wearit", Command_Don);
	RegConsoleCmd("sm_showit", Command_ShowPrefs);
	RegConsoleCmd("sm_hidehats", Command_HideHats);	
	RegConsoleCmd("sm_wearit1", Command_Don1);
	RegConsoleCmd("sm_wearit2", Command_Don2);
	RegConsoleCmd("sm_wearit3", Command_Don3);
	
	RegAdminCmd("sm_forcewearit", Command_Force_Don, ADMFLAG_SLAY);
	RegAdminCmd("sm_strip", Command_Strip, ADMFLAG_SLAY);
	
	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamedata

	if (!hTF2)
	SetFailState("This plugin is designed for a TF2 dedicated server only.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);    // EquipWearable offset is always behind RemoveWearable, subtract its value by 1
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWearableEquip = EndPrepSDKCall();

	if (!g_hWearableEquip)
	SetFailState("Failed to create call: CBasePlayer::EquipWearable");

	delete hTF2; 
	
	g_hClientItems[0] = new Cookie("don_item1", "", CookieAccess_Private);
	g_hClientItems[1] = new Cookie("don_item2", "", CookieAccess_Private);	
	g_hClientItems[2] = new Cookie("don_item3", "", CookieAccess_Private);
	g_hClientItems[3] = new Cookie("don_item4", "", CookieAccess_Private);
	g_hClientItems[4] = new Cookie("don_item5", "", CookieAccess_Private);
	g_hClientItems[5] = new Cookie("don_item6", "", CookieAccess_Private);
	g_hClientItems[6] = new Cookie("don_item7", "", CookieAccess_Private);
	
	g_hClientItems[7] = new Cookie("wearit1_index", "", CookieAccess_Private);
	g_hClientItems[8] = new Cookie("wearit1_effect", "", CookieAccess_Private);
	g_hClientItems[9] = new Cookie("wearit1_paint", "", CookieAccess_Private);

	g_hClientItems[10] = new Cookie("wearit2_index", "", CookieAccess_Private);
	g_hClientItems[11] = new Cookie("wearit2_effect", "", CookieAccess_Private);
	g_hClientItems[12] = new Cookie("wearit2_paint", "", CookieAccess_Private);		
	
	g_hClientItems[13] = new Cookie("wearit3_index", "", CookieAccess_Private);
	g_hClientItems[14] = new Cookie("wearit3_effect", "", CookieAccess_Private);
	g_hClientItems[15] = new Cookie("wearit3_paint", "", CookieAccess_Private);	
	
	g_hClientClass = new Cookie("don_class", "", CookieAccess_Private);

	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);	
	HookEvent("player_changeclass", EventChangeClass, EventHookMode_Post);
}

public Action Command_Strip(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		//ServerCommand("tf_models_remove #%d", GetClientUserId(target_list[i]));	
	
		TF2_RemoveAllWearables(target_list[i]);
		
		SetVariantString("");
		AcceptEntityInput(target_list[i], "SetCustomModel");
		SetEntProp(target_list[i], Prop_Send, "m_bCustomModelRotates", 0);
		SetVariantString("ParticleEffectStop");
		AcceptEntityInput(target_list[i], "DispatchEffect");

		g_hClientItems[0].Set(target_list[i], "-1");		
		g_hClientItems[1].Set(target_list[i], "-1");
		g_hClientItems[2].Set(target_list[i], "-1");
		g_hClientItems[3].Set(target_list[i], "-1");
		g_hClientItems[4].Set(target_list[i], "-1");
		g_hClientItems[5].Set(target_list[i], "-1");
		g_hClientItems[6].Set(target_list[i], "-1");
		g_hClientItems[7].Set(target_list[i], "-1");
		g_hClientItems[8].Set(target_list[i], "-1");
		g_hClientItems[9].Set(target_list[i], "-1");
		g_hClientItems[10].Set(target_list[i], "-1");
		g_hClientItems[11].Set(target_list[i], "-1");
		g_hClientItems[12].Set(target_list[i], "-1");
		g_hClientItems[13].Set(target_list[i], "-1");
		g_hClientItems[14].Set(target_list[i], "-1");
		g_hClientItems[15].Set(target_list[i], "-1");		
	}

	return Plugin_Handled;
}

public Action Command_HideHats(int client, int args)
{
	if(!b_Transmit[client])
	{
		PrintToChat(client, "You will no longer see !Wearit cosmetics. To enable hats type !hidehats again.");
		b_Transmit[client] = true;
	}
	else if(b_Transmit[client])
	{
		PrintToChat(client, "You can now see !Wearit cosmetics");
		b_Transmit[client] = false;
	}
	
	return Plugin_Handled;
}

public Action Hook_SetTransmit(int entity, int client)
{
	setFlags(entity);
	if(b_Transmit[client])
	{
		return Plugin_Handled;	
	}
	return Plugin_Continue;
}

void setFlags(int edict)
{
	if (GetEdictFlags(edict) & FL_EDICT_ALWAYS)
	{
		SetEdictFlags(edict, (GetEdictFlags(edict) ^ FL_EDICT_ALWAYS));
	}
} 

public Action Command_ShowPrefs(int client, int args)
{
	PrintToChat(client, "You are wearing the following !wearit items:");
	char strItemsindex[7][32];
	g_hClientItems[0].Get(client, strItemsindex[0], sizeof(strItemsindex[])); //Item 1
	ReplyToCommand(client, "Item1: %s", strItemsindex[0]);
	g_hClientItems[1].Get(client, strItemsindex[1], sizeof(strItemsindex[])); //Item 2
	ReplyToCommand(client, "Item2: %s", strItemsindex[1]);
	g_hClientItems[2].Get(client, strItemsindex[2], sizeof(strItemsindex[])); //Item 3
	ReplyToCommand(client, "Item3: %s", strItemsindex[2]);
	g_hClientItems[3].Get(client, strItemsindex[3], sizeof(strItemsindex[])); //Item 4
	ReplyToCommand(client, "Item4: %s", strItemsindex[3]);
	g_hClientItems[4].Get(client, strItemsindex[4], sizeof(strItemsindex[])); //Item 5
	ReplyToCommand(client, "Item5: %s", strItemsindex[4]);
	g_hClientItems[5].Get(client, strItemsindex[5], sizeof(strItemsindex[])); //Item 6 (effect)
	ReplyToCommand(client, "Item6 (Effect): %s", strItemsindex[5]);	
	g_hClientItems[6].Get(client, strItemsindex[6], sizeof(strItemsindex[])); //Item 7 (Paint)
	ReplyToCommand(client, "Item7 (Paint): %s", strItemsindex[6]);	

	return Plugin_Handled;
}

public Action Command_Don(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: !wearit <item index1>, <item index2>, <item index3>, <item index4>, <item index5>, <effect number>, <paint number 1-29>");
		ReplyToCommand(client, "To Remove Items: !wearit 0");		
		ReplyToCommand(client, "Link to Index Numbers: https://wiki.alliedmods.net/Team_Fortress_2_Item_Definition_Indexes");

		return Plugin_Handled;
	}
	
	char buffer1[32];
	char buffer2[32];
	char buffer3[32];
	char buffer4[32];
	char buffer5[32];
	char buffer6[32];	
	char buffer7[32];
	
	//--- Set Index1
	GetCmdArg(1, buffer1, sizeof(buffer1));
	int itemIndex1 = StringToInt(buffer1);
	if (itemIndex1 == 0)
	{
		TF2_RemoveAllWearables(client);
		g_hClientItems[0].Set(client, "-1");		
		g_hClientItems[1].Set(client, "-1");
		g_hClientItems[2].Set(client, "-1");
		g_hClientItems[3].Set(client, "-1");
		g_hClientItems[4].Set(client, "-1");
		g_hClientItems[5].Set(client, "-1");
		g_hClientItems[6].Set(client, "-1");		
	}

	GetCmdArg(6, buffer6, sizeof(buffer6));
	int itemIndex6 = StringToInt(buffer6);
	
	GetCmdArg(7, buffer7, sizeof(buffer7));
	int itemIndex7 = StringToInt(buffer7);
	if (itemIndex7 > 0)
	{
		g_hClientItems[6].Set(client, buffer7);	
	}
	
	else
	{
		itemIndex7 = 0;
		g_hClientItems[6].Set(client, "-1");		
	}

	if (itemIndex1 > 0 && itemIndex6 > 0)
	{
		TF2_RemoveAllWearables(client);
		CreateHat(client, itemIndex1, 10, 6, itemIndex6, itemIndex7); //First Cosmetic with effect
		g_hClientItems[0].Set(client, buffer1);
		g_hClientItems[5].Set(client, buffer6);	

		char sPlayerClass[32];
		int iPlayerClass = view_as<int>(TF2_GetPlayerClass(client));
		IntToString(iPlayerClass, sPlayerClass, sizeof(sPlayerClass));
		g_hClientClass.Set(client, sPlayerClass);		
	}
	
	if (itemIndex1 > 0 && itemIndex6 < 1)
	{
		TF2_RemoveAllWearables(client);
		CreateHat(client, itemIndex1, 10, 6, 0, itemIndex7); //First Cosmetic and no effect
		g_hClientItems[0].Set(client, buffer1);
		
		char sPlayerClass[32];
		int iPlayerClass = view_as<int>(TF2_GetPlayerClass(client));
		IntToString(iPlayerClass, sPlayerClass, sizeof(sPlayerClass));
		g_hClientClass.Set(client, sPlayerClass);		
	}
	
	//--- Set Index2
	GetCmdArg(2, buffer2, sizeof(buffer2));
	int itemIndex2 = StringToInt(buffer2);
	if (itemIndex2 > 0)
	{
		CreateHat(client, itemIndex2, 10, 6, 0, itemIndex7); //Second Cosmetic
		g_hClientItems[1].Set(client, buffer2);		
	}
	else
	{
		g_hClientItems[1].Set(client, "-1");	
	}

	//--- Set Index3
	GetCmdArg(3, buffer3, sizeof(buffer3));
	int itemIndex3 = StringToInt(buffer3);
	if (itemIndex3 > 0)
	{
		CreateHat(client, itemIndex3, 10, 6, 0, itemIndex7); //Third Cosmetic
		g_hClientItems[2].Set(client, buffer3);		
	}
	else
	{
		g_hClientItems[2].Set(client, "-1");
	}

	//--- Set Index4
	GetCmdArg(4, buffer4, sizeof(buffer4));
	int itemIndex4 = StringToInt(buffer4);
	if (itemIndex4 > 0)
	{
		CreateHat(client, itemIndex4, 10, 6, 0, itemIndex7); //Fourth Cosmetic
		g_hClientItems[3].Set(client, buffer4);		
	}
	else
	{
		g_hClientItems[3].Set(client, "-1");	
	}
	
	//--- Set Index5
	GetCmdArg(5, buffer5, sizeof(buffer5));
	int itemIndex5 = StringToInt(buffer5);
	if (itemIndex5 > 0)
	{
		CreateHat(client, itemIndex5, 10, 6, 0, itemIndex7); //Fifth Cosmetic
		g_hClientItems[4].Set(client, buffer5);		
	}
	else
	{
		g_hClientItems[4].Set(client, "-1");	
	}
	
	//--- Set Index6
	if (itemIndex6 > 0)
	{
		g_hClientItems[5].Set(client, buffer6);		
	}
	else
	{
		g_hClientItems[5].Set(client, "-1");	
	}	
	
	return Plugin_Handled;
}


public Action Command_Don1(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: !wearit1 <item index1>, <effect number>, <paint number 1-29>");
		ReplyToCommand(client, "To Remove Items: !wearit1 0");		
		ReplyToCommand(client, "Link to Index Numbers: https://wiki.alliedmods.net/Team_Fortress_2_Item_Definition_Indexes");

		return Plugin_Handled;
	}
	
	char buffer1[32];
	char buffer2[32];
	char buffer3[32];
	
	//--- Set Index1
	GetCmdArg(1, buffer1, sizeof(buffer1));
	int itemIndex1 = StringToInt(buffer1);
	if (itemIndex1 == 0)
	{
		g_hClientItems[7].Set(client, "-1");		
		g_hClientItems[8].Set(client, "-1");
		g_hClientItems[9].Set(client, "-1");

		PrintToChat(client, "Touch locker to remove item.");
	}
	else
	{
		TF2_RemoveAllWearables(client);
		g_hClientItems[7].Set(client, buffer1);

		char sPlayerClass[32];
		int iPlayerClass = view_as<int>(TF2_GetPlayerClass(client));
		IntToString(iPlayerClass, sPlayerClass, sizeof(sPlayerClass));
		g_hClientClass.Set(client, sPlayerClass);		
	}
	
	GetCmdArg(2, buffer2, sizeof(buffer2)); //effect
	int itemIndex2 = StringToInt(buffer2);
	if (itemIndex2 > 0)
	{
		g_hClientItems[8].Set(client, buffer2);	
	}
	else
	{
		itemIndex2 = 0;
		g_hClientItems[8].Set(client, "-1");		
	}	
	
	GetCmdArg(3, buffer3, sizeof(buffer3)); //paint
	int itemIndex3 = StringToInt(buffer3);
	if (itemIndex3 > 0)
	{
		g_hClientItems[9].Set(client, buffer3);	
	}
	else
	{
		itemIndex3 = 0;
		g_hClientItems[9].Set(client, "-1");		
	}

	if (itemIndex1 > 0 && itemIndex2 > 0)
	{
		TF2_RemoveAllWearables(client);
		CreateHat(client, itemIndex1, 10, 6, itemIndex2, itemIndex3); //First Cosmetic with effect
	}
	
	if (itemIndex1 > 0 && itemIndex2 < 1)
	{
		CreateHat(client, itemIndex1, 10, 6, 0, itemIndex3); //First Cosmetic and no effect
	}
	
	return Plugin_Handled;
}

public Action Command_Don2(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: !wearit2 <item index1>, <effect number>, <paint number 1-29>");
		ReplyToCommand(client, "To Remove Items: !wearit2 0");		
		ReplyToCommand(client, "Link to Index Numbers: https://wiki.alliedmods.net/Team_Fortress_2_Item_Definition_Indexes");

		return Plugin_Handled;
	}
	
	char buffer1[32];
	char buffer2[32];
	char buffer3[32];
	
	//--- Set Index1
	GetCmdArg(1, buffer1, sizeof(buffer1));
	int itemIndex1 = StringToInt(buffer1);
	if (itemIndex1 == 0)
	{
		TF2_RemoveAllWearables(client);
		g_hClientItems[10].Set(client, "-1");		
		g_hClientItems[11].Set(client, "-1");
		g_hClientItems[12].Set(client, "-1");

		PrintToChat(client, "Touch locker to remove item.");
	}
	else
	{
		g_hClientItems[10].Set(client, buffer1);		
	}
	
	GetCmdArg(2, buffer2, sizeof(buffer2)); //effect
	int itemIndex2 = StringToInt(buffer2);
	if (itemIndex2 > 0)
	{
		g_hClientItems[11].Set(client, buffer2);	
	}
	else
	{
		itemIndex2 = 0;
		g_hClientItems[11].Set(client, "-1");		
	}	
	
	GetCmdArg(3, buffer3, sizeof(buffer3)); //paint
	int itemIndex3 = StringToInt(buffer3);
	if (itemIndex3 > 0)
	{
		g_hClientItems[12].Set(client, buffer3);	
	}
	else
	{
		itemIndex3 = 0;
		g_hClientItems[12].Set(client, "-1");		
	}

	if (itemIndex1 > 0 && itemIndex2 > 0)
	{
		CreateHat(client, itemIndex1, 10, 6, itemIndex2, itemIndex3); //Second Cosmetic with effect
	}
	
	if (itemIndex1 > 0 && itemIndex2 < 1)
	{
		CreateHat(client, itemIndex1, 10, 6, 0, itemIndex3); //Second Cosmetic and no effect
	}
	
	return Plugin_Handled;
}

public Action Command_Don3(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: !wearit3 <item index1>, <effect number>, <paint number 1-29>");
		ReplyToCommand(client, "To Remove Items: !wearit3 0");		
		ReplyToCommand(client, "Link to Index Numbers: https://wiki.alliedmods.net/Team_Fortress_2_Item_Definition_Indexes");

		return Plugin_Handled;
	}
	
	char buffer1[32];
	char buffer2[32];
	char buffer3[32];
	
	//--- Set Index1
	GetCmdArg(1, buffer1, sizeof(buffer1));
	int itemIndex1 = StringToInt(buffer1);
	if (itemIndex1 == 0)
	{
		g_hClientItems[13].Set(client, "-1");		
		g_hClientItems[14].Set(client, "-1");
		g_hClientItems[15].Set(client, "-1");

		PrintToChat(client, "Touch locker to remove item.");
	}
	else
	{
		g_hClientItems[13].Set(client, buffer1);		
	}
	
	GetCmdArg(2, buffer2, sizeof(buffer2)); //effect
	int itemIndex2 = StringToInt(buffer2);
	if (itemIndex2 > 0)
	{
		g_hClientItems[14].Set(client, buffer2);	
	}
	else
	{
		itemIndex2 = 0;
		g_hClientItems[14].Set(client, "-1");		
	}	
	
	GetCmdArg(3, buffer3, sizeof(buffer3)); //paint
	int itemIndex3 = StringToInt(buffer3);
	if (itemIndex3 > 0)
	{
		TF2_RemoveAllWearables(client);
		g_hClientItems[15].Set(client, buffer3);	
	}
	else
	{
		itemIndex3 = 0;
		g_hClientItems[15].Set(client, "-1");		
	}

	if (itemIndex1 > 0 && itemIndex2 > 0)
	{
		CreateHat(client, itemIndex1, 10, 6, itemIndex2, itemIndex3); //Third Cosmetic with effect
	}
	
	if (itemIndex1 > 0 && itemIndex2 < 1)
	{
		CreateHat(client, itemIndex1, 10, 6, 0, itemIndex3); //Third Cosmetic and no effect
	}
	
	return Plugin_Handled;
}

public Action Command_Force_Don(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: !forcewearit <target> <item index1>, <item index2>, <item index3>, <item index4>, <item index5>, <effect number>, <paint number 1-29>");
		ReplyToCommand(client, "To Remove Items: !forcewearit 0");		
		ReplyToCommand(client, "Link to Index Numbers: https://wiki.alliedmods.net/Team_Fortress_2_Item_Definition_Indexes");

		return Plugin_Handled;
	}

	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		
		char buffer1[32];
		char buffer2[32];
		char buffer3[32];
		char buffer4[32];
		char buffer5[32];
		char buffer6[32];
		char buffer7[32];
		
		//--- Set Index1
		GetCmdArg(2, buffer1, sizeof(buffer1));
		int itemIndex1 = StringToInt(buffer1);
		if (itemIndex1 == 0)
		{
			TF2_RemoveAllWearables(target_list[i]);
			g_hClientItems[0].Set(target_list[i], "-1");		
			g_hClientItems[1].Set(target_list[i], "-1");
			g_hClientItems[2].Set(target_list[i], "-1");
			g_hClientItems[3].Set(target_list[i], "-1");
			g_hClientItems[4].Set(target_list[i], "-1");
			g_hClientItems[5].Set(target_list[i], "-1");
			g_hClientItems[6].Set(target_list[i], "-1");			
		}

		GetCmdArg(7, buffer6, sizeof(buffer6));
		int itemIndex6 = StringToInt(buffer6);

		GetCmdArg(8, buffer7, sizeof(buffer7));
		int itemIndex7 = StringToInt(buffer7);
		if (itemIndex7 > 0)
		{
			g_hClientItems[6].Set(target_list[i], buffer7);	
		}
		
		else
		{
			itemIndex7 = 0;
			g_hClientItems[6].Set(target_list[i], "-1");		
		}



		if (itemIndex1 > 0 && itemIndex6 > 0)
		{
			TF2_RemoveAllWearables(target_list[i]);
			CreateHat(target_list[i], itemIndex1, 10, 6, itemIndex6, itemIndex7); //First Cosmetic
			g_hClientItems[0].Set(target_list[i], buffer1);
			g_hClientItems[5].Set(target_list[i], buffer6);			
		}
		
		if (itemIndex1 > 0 && itemIndex6 < 1)
		{
			TF2_RemoveAllWearables(target_list[i]);
			CreateHat(target_list[i], itemIndex1, 10, 6, 0, itemIndex7); //First Cosmetic
			g_hClientItems[0].Set(target_list[i], buffer1);
		}		
		
		//--- Set Index2
		GetCmdArg(3, buffer2, sizeof(buffer2));
		int itemIndex2 = StringToInt(buffer2);
		if (itemIndex2 > 0)
		{
			CreateHat(target_list[i], itemIndex2, 10, 6, 0, itemIndex7); //Second Cosmetic
			g_hClientItems[1].Set(target_list[i], buffer2);		
		}

		//--- Set Index3
		GetCmdArg(4, buffer3, sizeof(buffer3));
		int itemIndex3 = StringToInt(buffer3);
		if (itemIndex3 > 0)
		{
			CreateHat(target_list[i], itemIndex3, 10, 6, 0, itemIndex7); //Third Cosmetic
			g_hClientItems[2].Set(target_list[i], buffer3);		
		}

		//--- Set Index4
		GetCmdArg(5, buffer4, sizeof(buffer4));
		int itemIndex4 = StringToInt(buffer4);
		if (itemIndex4 > 0)
		{
			CreateHat(target_list[i], itemIndex4, 10, 6, 0, itemIndex7); //Fourth Cosmetic
			g_hClientItems[3].Set(target_list[i], buffer4);		
		}	

		//--- Set Index5
		GetCmdArg(6, buffer5, sizeof(buffer5));
		int itemIndex5 = StringToInt(buffer5);
		if (itemIndex5 > 0)
		{
			CreateHat(target_list[i], itemIndex5, 10, 6, 0, itemIndex7); //Fifth Cosmetic
			g_hClientItems[4].Set(target_list[i], buffer5);		
		}
		
		//--- Set Index6
		if (itemIndex6 > 0)
		{
			g_hClientItems[5].Set(target_list[i], buffer6);		
		}

		if (itemIndex6 < 1)
		{
			g_hClientItems[5].Set(target_list[i], "-1");	
		}		
	}
	
	return Plugin_Handled;
}

public void EventChangeClass(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && client > 0)
	{
		char sPlayerClass[32];
		g_hClientClass.Get(client, sPlayerClass, 32);
		int iEventPlayerClass = view_as<int>(GetEventInt(event, "class"));
		int iPlayerClass = StringToInt(sPlayerClass);
		if (iPlayerClass > 0 && iPlayerClass!= iEventPlayerClass)
		{
			g_hClientItems[0].Set(client, "-1");		
			g_hClientItems[1].Set(client, "-1");
			g_hClientItems[2].Set(client, "-1");
			g_hClientItems[3].Set(client, "-1");
			g_hClientItems[4].Set(client, "-1");
			g_hClientItems[5].Set(client, "-1");
			g_hClientItems[6].Set(client, "-1");
			g_hClientItems[7].Set(client, "-1");
			g_hClientItems[8].Set(client, "-1");
			g_hClientItems[9].Set(client, "-1");
			g_hClientItems[10].Set(client, "-1");
			g_hClientItems[11].Set(client, "-1");
			g_hClientItems[12].Set(client, "-1");
			g_hClientItems[13].Set(client, "-1");
			g_hClientItems[14].Set(client, "-1");
			g_hClientItems[15].Set(client, "-1");
		}
	}
}

public void EventInventoryApplication(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && client > 0)
	{
		char strItemsindex[16][32];
		int strItem[16];
		strItem[0] = StringToInt(strItemsindex[0]);
		strItem[1] = StringToInt(strItemsindex[1]);
		strItem[2] = StringToInt(strItemsindex[2]);
		strItem[3] = StringToInt(strItemsindex[3]);
		strItem[4] = StringToInt(strItemsindex[4]);
		strItem[5] = StringToInt(strItemsindex[5]);
		strItem[6] = StringToInt(strItemsindex[6]);		
		strItem[7] = StringToInt(strItemsindex[7]);
		strItem[8] = StringToInt(strItemsindex[8]);
		strItem[9] = StringToInt(strItemsindex[9]);	
		strItem[10] = StringToInt(strItemsindex[10]);
		strItem[11] = StringToInt(strItemsindex[11]);
		strItem[12] = StringToInt(strItemsindex[12]);
		strItem[13] = StringToInt(strItemsindex[13]);
		strItem[14] = StringToInt(strItemsindex[14]);
		strItem[15] = StringToInt(strItemsindex[15]);		
		
		g_hClientItems[0].Get(client, strItemsindex[0], 32); //Item 1
		strItem[0] = StringToInt(strItemsindex[0]);	

		g_hClientItems[5].Get(client, strItemsindex[5], 32); //Item 6
		strItem[5] = StringToInt(strItemsindex[5]);
		
		g_hClientItems[6].Get(client, strItemsindex[6], 32); //Item 7
		strItem[6] = StringToInt(strItemsindex[6]);	
		if (strItem[6] < 1)
		{
			strItem[6] = 0;
		}
		
		if (strItem[0] > 0 && strItem[5] > 0)
		{
			TF2_RemoveAllWearables(client);
			CreateHat(client, strItem[0], 10, 6, (strItem[5]), (strItem[6]));
		}
		
		if (strItem[0] > 0 && strItem[5] < 1)
		{
			TF2_RemoveAllWearables(client);
			CreateHat(client, strItem[0], 10, 6, 0, (strItem[6]));
		}		

		g_hClientItems[1].Get(client, strItemsindex[1], 32); //Item 2
		strItem[1] = StringToInt(strItemsindex[1]);		
		if (strItem[1] > 0)
		{
			CreateHat(client, strItem[1], 10, 6, 0, (strItem[6]));
		}

		g_hClientItems[2].Get(client, strItemsindex[2], 32); //Item 3
		strItem[2] = StringToInt(strItemsindex[2]);		
		if (strItem[2] > 0)
		{
			CreateHat(client, strItem[2], 10, 6, 0, (strItem[6]));
		}

		g_hClientItems[3].Get(client, strItemsindex[3], 32); //Item 4
		strItem[3] = StringToInt(strItemsindex[3]);		
		if (strItem[3] > 0)
		{
			CreateHat(client, strItem[3], 10, 6, 0, (strItem[6]));
		}

		g_hClientItems[4].Get(client, strItemsindex[4], 32); //Item 5
		strItem[4] = StringToInt(strItemsindex[4]);		
		if (strItem[4] > 0)
		{
			CreateHat(client, strItem[4], 10, 6, 0, (strItem[6]));
		}

		g_hClientItems[7].Get(client, strItemsindex[7], 32); //Wearit1 Index
		g_hClientItems[8].Get(client, strItemsindex[8], 32); //Wearit1 Effect
		g_hClientItems[9].Get(client, strItemsindex[9], 32); //Wearit1 Paint
		strItem[7] = StringToInt(strItemsindex[7]);	
		strItem[8] = StringToInt(strItemsindex[8]);
		strItem[9] = StringToInt(strItemsindex[9]);		
		if (strItem[7] > 0)
		{
			TF2_RemoveAllWearables(client);
			if (strItem[8] > 0 && strItem[9] > 0)
			{
				CreateHat(client, strItem[7], 10, 6, (strItem[8]), (strItem[9]));			
			}
			else if (strItem[8] > 0 && strItem[9] < 1)
			{
				CreateHat(client, strItem[7], 10, 6, (strItem[8]), 0);			
			}
			else if (strItem[8] < 1 && strItem[9] > 0)
			{
				CreateHat(client, strItem[7], 10, 6, 0, (strItem[9]));			
			}			
			else if (strItem[8] < 1 && strItem[9] < 1)
			{
				CreateHat(client, strItem[7], 10, 6, 0, 0);			
			}
		}
		
		g_hClientItems[10].Get(client, strItemsindex[10], 32); //Wearit2 Index
		g_hClientItems[11].Get(client, strItemsindex[11], 32); //Wearit2 Effect
		g_hClientItems[12].Get(client, strItemsindex[12], 32); //Wearit2 Paint
		strItem[10] = StringToInt(strItemsindex[10]);	
		strItem[11] = StringToInt(strItemsindex[11]);
		strItem[12] = StringToInt(strItemsindex[12]);		
		if (strItem[10] > 0)
		{
			if (strItem[11] > 0 && strItem[12] > 0)
			{
				CreateHat(client, strItem[10], 10, 6, (strItem[11]), (strItem[12]));			
			}
			else if (strItem[11] > 0 && strItem[12] < 1)
			{
				CreateHat(client, strItem[10], 10, 6, (strItem[11]), 0);			
			}
			else if (strItem[11] < 1 && strItem[12] > 0)
			{
				CreateHat(client, strItem[10], 10, 6, 0, (strItem[12]));			
			}			
			else if (strItem[11] < 1 && strItem[12] < 1)
			{
				CreateHat(client, strItem[10], 10, 6, 0, 0);			
			}
		}		

		g_hClientItems[13].Get(client, strItemsindex[13], 32); //Wearit3 Index
		g_hClientItems[14].Get(client, strItemsindex[14], 32); //Wearit3 Effect
		g_hClientItems[15].Get(client, strItemsindex[15], 32); //Wearit3 Paint
		strItem[13] = StringToInt(strItemsindex[13]);	
		strItem[14] = StringToInt(strItemsindex[14]);
		strItem[15] = StringToInt(strItemsindex[15]);		
		if (strItem[13] > 0)
		{
			if (strItem[14] > 0 && strItem[15] > 0)
			{
				CreateHat(client, strItem[13], 10, 6, (strItem[14]), (strItem[15]));			
			}
			else if (strItem[14] > 0 && strItem[15] < 1)
			{
				CreateHat(client, strItem[10], 10, 6, (strItem[14]), 0);			
			}
			else if (strItem[14] < 1 && strItem[15] > 0)
			{
				CreateHat(client, strItem[13], 10, 6, 0, (strItem[15]));			
			}			
			else if (strItem[14] < 1 && strItem[15] < 1)
			{
				CreateHat(client, strItem[13], 10, 6, 0, 0);			
			}
		}
		
	}
}

public void OnClientPostAdminCheck(int client)
{
	char sPlayerClass[32];
	g_hClientClass.Get(client, sPlayerClass, 32);
	int iPlayerClass = StringToInt(sPlayerClass);
	if (iPlayerClass < 1)
	{
		g_hClientItems[0].Set(client, "-1");
		g_hClientItems[1].Set(client, "-1");
		g_hClientItems[2].Set(client, "-1");
		g_hClientItems[3].Set(client, "-1");
		g_hClientItems[4].Set(client, "-1");
		g_hClientItems[5].Set(client, "-1");
		g_hClientItems[6].Set(client, "-1");
		g_hClientItems[7].Set(client, "-1");
		g_hClientItems[8].Set(client, "-1");
		g_hClientItems[9].Set(client, "-1");
		g_hClientItems[10].Set(client, "-1");
		g_hClientItems[11].Set(client, "-1");
		g_hClientItems[12].Set(client, "-1");
		g_hClientItems[13].Set(client, "-1");
		g_hClientItems[14].Set(client, "-1");
		g_hClientItems[15].Set(client, "-1");
	}
}

bool CreateHat(int client, int itemindex, int level = 10, int quality = 1, int effect = 0, int paint = 0)
{
	int hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1);

	
	if (effect > 0)
	{
		TF2Attrib_SetByDefIndex(hat, 134, (effect + 0.0));
	}
	
	if (paint > 0)
	{
		switch(paint)
		{
		case 1:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3100495.0); //A color similar to slate
				TF2Attrib_SetByDefIndex(hat, 261, 3100495.0);
			}
		case 2:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8208497.0); //A deep commitment to purple
				TF2Attrib_SetByDefIndex(hat, 261, 8208497.0);
			}
		case 3:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 1315860.0); //A distinctive lack of hue
				TF2Attrib_SetByDefIndex(hat, 261, 1315860.0);
			}
		case 4:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12377523.0); //A mann's mint
				TF2Attrib_SetByDefIndex(hat, 261, 12377523.0);
			}
		case 5:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 2960676.0); //After eight
				TF2Attrib_SetByDefIndex(hat, 261, 2960676.0);
			}
		case 6:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8289918.0); //Aged Moustache Grey
				TF2Attrib_SetByDefIndex(hat, 261, 8289918.0);
			}
		case 7:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15132390.0); //An Extraordinary abundance of tinge
				TF2Attrib_SetByDefIndex(hat, 261, 15132390.0);
			}
		case 8:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15185211.0); //Australium gold
				TF2Attrib_SetByDefIndex(hat, 261, 15185211.0);
			}
		case 9:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 14204632.0); //Color no 216-190-216
				TF2Attrib_SetByDefIndex(hat, 261, 14204632.0);
			}
		case 10:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15308410.0); //Dark salmon injustice
				TF2Attrib_SetByDefIndex(hat, 261, 15308410.0);
			}
		case 11:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8421376.0); //Drably olive
				TF2Attrib_SetByDefIndex(hat, 261, 8421376.0);
			}
		case 12:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 7511618.0); //Indubitably green
				TF2Attrib_SetByDefIndex(hat, 261, 7511618.0);
			}
		case 13:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 13595446.0); //Mann co orange
				TF2Attrib_SetByDefIndex(hat, 261, 13595446.0);
			}
		case 14:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 10843461.0); //Muskelmannbraun
				TF2Attrib_SetByDefIndex(hat, 261, 10843461.0);
			}
		case 15:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 5322826.0); //Noble hatters violet
				TF2Attrib_SetByDefIndex(hat, 261, 5322826.0);
			}
		case 16:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12955537.0); //Peculiarly drab tincture
				TF2Attrib_SetByDefIndex(hat, 261, 12955537.0);
			}
		case 17:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 16738740.0); //Pink as hell
				TF2Attrib_SetByDefIndex(hat, 261, 16738740.0);
			}
		case 18:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 6901050.0); //Radigan conagher brown
				TF2Attrib_SetByDefIndex(hat, 261, 6901050.0);
			}
		case 19:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3329330.0); //A bitter taste of defeat and lime
				TF2Attrib_SetByDefIndex(hat, 261, 3329330.0);
			}
		case 20:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15787660.0); //The color of a gentlemanns business pants
				TF2Attrib_SetByDefIndex(hat, 261, 15787660.0);
			}
		case 21:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8154199.0); //Ye olde rustic colour
				TF2Attrib_SetByDefIndex(hat, 261, 8154199.0);
			}
		case 22:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 4345659.0); //Zepheniahs greed
				TF2Attrib_SetByDefIndex(hat, 261, 4345659.0);
			}
		case 23:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 6637376.0); //An air of debonair
				TF2Attrib_SetByDefIndex(hat, 261, 2636109.0);
			}
		case 24:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3874595.0); //Balaclavas are forever
				TF2Attrib_SetByDefIndex(hat, 261, 1581885.0);
			}
		case 25:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12807213.0); //Cream spirit
				TF2Attrib_SetByDefIndex(hat, 261, 12091445.0);
			}
		case 26:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 4732984.0); //Operators overalls
				TF2Attrib_SetByDefIndex(hat, 261, 3686984.0);
			}
		case 27:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12073019.0); //Team spirit
				TF2Attrib_SetByDefIndex(hat, 261, 5801378.0);
			}
		case 28:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8400928.0); //The value of teamwork
				TF2Attrib_SetByDefIndex(hat, 261, 2452877.0);
			}
		case 29:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 11049612.0); //Waterlogged lab coat
				TF2Attrib_SetByDefIndex(hat, 261, 8626083.0);
			}
		}
	}
	
	DispatchSpawn(hat);
	SDKCall(g_hWearableEquip, client, hat);

	SDKHookEx(hat, SDKHook_SetTransmit, Hook_SetTransmit);	
	
	return true;
} 

stock void RemoveAllWearables(int client)
{
	int edict = MaxClients+1;
	while((edict = FindEntityByClassname(edict, "tf_wearable")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
			}
		}
	}
}

stock Action TF2_RemoveAllWearables(int client)
{
	RemoveWearable(client, "tf_wearable", "CTFWearable");
	RemoveWearable(client, "tf_powerup_bottle", "CTFPowerupBottle");
	
	return Plugin_Handled;	
}

stock Action RemoveWearable(int client, char[] classname, char[] networkclass)
{
	if (IsPlayerAlive(client))
	{
		int edict = MaxClients+1;
		while((edict = FindEntityByClassname(edict, classname)) != -1)
		{
			char netclass[32];
			if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, networkclass))
			{
				if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
				{
					AcceptEntityInput(edict, "Kill"); 
				}
			}
		}
	}
	
	return Plugin_Handled;	
}