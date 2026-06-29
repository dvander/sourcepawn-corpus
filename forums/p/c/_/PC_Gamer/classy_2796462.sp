#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <tf2_stocks>
#include <TF2attributes>

#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.1"

Handle g_hWearableEquip;
Cookie g_hClassy[9];
bool b_Transmit[MAXPLAYERS + 1] = {false, ...};

public Plugin myinfo = 
{
	name = "[TF2] Classy",
	author = "PC Gamer",
	description = "Players can wear any cosmetics. Admins can force wear of any cosmetics.",
	version = PLUGIN_VERSION,
	url = "www.alliedmods.net"
}

public void OnPluginStart() 
{
	LoadTranslations("common.phrases");

	RegConsoleCmd("sm_classyset", Command_ClassySet);
	RegConsoleCmd("sm_classystrip", Command_ClassyStrip);
	RegConsoleCmd("sm_classyshow", Command_ShowPrefs);
	RegConsoleCmd("sm_classycookie", Command_ShowCookie);
	RegConsoleCmd("sm_classyhide", Command_HideHats);
	
	RegAdminCmd("sm_makeclassy", Command_MakeClassy, ADMFLAG_SLAY);

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
	
	g_hClassy[0] = new Cookie("classy_scout", "", CookieAccess_Private);
	g_hClassy[1] = new Cookie("classy_sniper", "", CookieAccess_Private);	
	g_hClassy[2] = new Cookie("classy_soldier", "", CookieAccess_Private);
	g_hClassy[3] = new Cookie("classy_demoman", "", CookieAccess_Private);
	g_hClassy[4] = new Cookie("classy_medic", "", CookieAccess_Private);
	g_hClassy[5] = new Cookie("classy_heavy", "", CookieAccess_Private);
	g_hClassy[6] = new Cookie("classy_pyro", "", CookieAccess_Private);
	g_hClassy[7] = new Cookie("classy_spy", "", CookieAccess_Private);
	g_hClassy[8] = new Cookie("classy_engineer", "", CookieAccess_Private);
	
	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);	
	HookEvent("player_changeclass", EventInventoryApplication, EventHookMode_Post);
}

public Action Command_ClassySet(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: !classyset <item1 index>, <item1 paint>, <item1 effect>, <item1 style>, <item2 index>, <item2 paint>, <item2 effect> <item2 style>, etc. (up to 5 items)");
		ReplyToCommand(client, "Use 0 for none. Use 999 for random paint. Use 999 for random effect.");
		ReplyToCommand(client, "Example: !classyset (31058, 0, 13, 0, 31060, 0, 13, 0, 31061, 0, 13, 0)");		
		ReplyToCommand(client, "To remove use !classyset 0 or !classystrip");
		
		return Plugin_Handled;
	}
	
	char buffer1[32];
	GetCmdArg(1, buffer1, sizeof(buffer1));
	int item1Index = StringToInt(buffer1);
	if (item1Index == 0)
	{
		TF2_RemoveAllWearables(client);
		
		if (TF2_GetPlayerClass(client) == TFClass_Scout)
		{
			g_hClassy[0].Set(client, "-1");
		}
		
		if (TF2_GetPlayerClass(client) == TFClass_Sniper)
		{
			g_hClassy[1].Set(client, "-1");
		}
		
		if (TF2_GetPlayerClass(client) == TFClass_Soldier)
		{
			g_hClassy[2].Set(client, "-1");
		}	

		if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
		{
			g_hClassy[3].Set(client, "-1");
		}
		
		if (TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			g_hClassy[4].Set(client, "-1");
		}

		if (TF2_GetPlayerClass(client) == TFClass_Heavy)
		{
			g_hClassy[5].Set(client, "-1");
		}	

		if (TF2_GetPlayerClass(client) == TFClass_Pyro)
		{
			g_hClassy[6].Set(client, "-1");
		}	
		
		if (TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			g_hClassy[7].Set(client, "-1");
		}
		
		if (TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			g_hClassy[8].Set(client, "-1");
		}
		
		return Plugin_Handled;
	}

	char buffer2[32];
	char buffer3[32];
	char buffer4[32];
	char buffer5[32];
	char buffer6[32];	
	char buffer7[32];
	char buffer8[32];
	char buffer9[32];	
	char buffer10[32];
	char buffer11[32];
	char buffer12[32];
	char buffer13[32];
	char buffer14[32];
	char buffer15[32];
	char buffer16[32];
	char buffer17[32];
	char buffer18[32];
	char buffer19[32];
	char buffer20[32];	
	
	GetCmdArg(2, buffer2, sizeof(buffer2));
	int item1Paint = StringToInt(buffer2);
	
	GetCmdArg(3, buffer3, sizeof(buffer3));
	int item1Effect = StringToInt(buffer3);
	
	GetCmdArg(4, buffer4, sizeof(buffer4));
	int item1Style = StringToInt(buffer4);

	GetCmdArg(5, buffer5, sizeof(buffer5));
	int item2Index = StringToInt(buffer5);

	GetCmdArg(6, buffer6, sizeof(buffer6));
	int item2Paint = StringToInt(buffer6);
	
	GetCmdArg(7, buffer7, sizeof(buffer7));
	int item2Effect = StringToInt(buffer7);		
	
	GetCmdArg(8, buffer8, sizeof(buffer8));
	int item2Style = StringToInt(buffer8);

	GetCmdArg(9, buffer9, sizeof(buffer9));
	int item3Index = StringToInt(buffer9);	

	GetCmdArg(10, buffer10, sizeof(buffer10));
	int item3Paint = StringToInt(buffer10);
	
	GetCmdArg(11, buffer11, sizeof(buffer11));
	int item3Effect = StringToInt(buffer11);		

	GetCmdArg(12, buffer12, sizeof(buffer12));
	int item3Style = StringToInt(buffer12);	
	
	GetCmdArg(13, buffer13, sizeof(buffer13));
	int item4Index = StringToInt(buffer13);	

	GetCmdArg(14, buffer14, sizeof(buffer14));
	int item4Paint = StringToInt(buffer14);
	
	GetCmdArg(15, buffer15, sizeof(buffer15));
	int item4Effect = StringToInt(buffer15);		

	GetCmdArg(16, buffer16, sizeof(buffer16));
	int item4Style = StringToInt(buffer16);		
	
	GetCmdArg(17, buffer17, sizeof(buffer17));
	int item5Index = StringToInt(buffer17);	

	GetCmdArg(18, buffer18, sizeof(buffer18));
	int item5Paint = StringToInt(buffer18);
	
	GetCmdArg(19, buffer19, sizeof(buffer19));
	int item5Effect = StringToInt(buffer19);
	
	GetCmdArg(20, buffer20, sizeof(buffer20));
	int item5Style = StringToInt(buffer20);	
	
	char bufferoutfit[256];
	Format(bufferoutfit, sizeof(bufferoutfit), "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", buffer1, buffer2, buffer3, buffer4, buffer5, buffer6, buffer7, buffer8, buffer9, buffer10, buffer11, buffer12, buffer13, buffer14, buffer15, buffer16, buffer17, buffer18, buffer19, buffer20);

	PrintToChat(client, "Setting your Classy items to these values:");
	PrintToChat(client, "Item 1 Index: %i Paint: %i Effect: %i Style: %i", item1Index, item1Paint, item1Effect, item1Style);
	PrintToChat(client, "Item 2 Index: %i Paint: %i Effect: %i Style: %i", item2Index, item2Paint, item2Effect, item2Style);	
	PrintToChat(client, "Item 3 Index: %i Paint: %i Effect: %i Style: %i", item3Index, item3Paint, item3Effect, item3Style);		
	PrintToChat(client, "Item 4 Index: %i Paint: %i Effect: %i Style: %i", item4Index, item4Paint, item4Effect, item4Style);
	PrintToChat(client, "Item 5 Index: %i Paint: %i Effect: %i Style: %i", item5Index, item5Paint, item5Effect, item5Style);
	
	if (TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		g_hClassy[0].Set(client, bufferoutfit);
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		g_hClassy[1].Set(client, bufferoutfit);
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		g_hClassy[2].Set(client, bufferoutfit);
	}	

	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		g_hClassy[3].Set(client, bufferoutfit);
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		g_hClassy[4].Set(client, bufferoutfit);
	}

	if (TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		g_hClassy[5].Set(client, bufferoutfit);
	}	

	if (TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		g_hClassy[6].Set(client, bufferoutfit);
	}	
	
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		g_hClassy[7].Set(client, bufferoutfit);
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		g_hClassy[8].Set(client, bufferoutfit);
	}

	if (item1Index > 1)
	{
		TF2_RemoveAllWearables(client);
		
		CreateHat(client, item1Index, 10, 6, item1Paint, item1Effect, item1Style);
	}

	if (item2Index > 1)
	{
		CreateHat(client, item2Index, 10, 6, item2Paint, item2Effect, item2Style);
	}
	
	if (item3Index > 1)
	{
		CreateHat(client, item3Index, 10, 6, item3Paint, item3Effect, item3Style);
	}

	if (item4Index > 1)
	{
		CreateHat(client, item4Index, 10, 6, item4Paint, item4Effect, item4Style);
	}
	
	if (item5Index > 1)
	{
		CreateHat(client, item5Index, 10, 6, item5Paint, item5Effect, item5Style);
	}		
	
	return Plugin_Handled;
}

public Action Command_MakeClassy(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: !makeclassy <target(s)> <item1 index>, <item1 paint>, <item1 effect>, <item1 style>, <item2 index>, <item2 paint>, <item2 effect>, <item2 style>, etc. (up to 5 items)");
		ReplyToCommand(client, "Use 999 for random paint. Use 999 for random effect.");
		ReplyToCommand(client, "Example: !makeclassy Robert 666, 999, 999, 0, 30975, 999, 0, 0");		
		ReplyToCommand(client, "To remove use !classyset <target> 0");
		
		return Plugin_Handled;
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
		char buffer1[32];
		char buffer2[32];
		char buffer3[32];
		char buffer4[32];
		char buffer5[32];
		char buffer6[32];	
		char buffer7[32];
		char buffer8[32];
		char buffer9[32];	
		char buffer10[32];
		char buffer11[32];
		char buffer12[32];
		char buffer13[32];
		char buffer14[32];
		char buffer15[32];
		char buffer16[32];
		char buffer17[32];
		char buffer18[32];
		char buffer19[32];
		char buffer20[32];	
		char bufferoutfit[128];
		
		GetCmdArg(2, buffer1, sizeof(buffer1));
		int item1Index = StringToInt(buffer1);
		if (item1Index == 0)
		{
			TF2_RemoveAllWearables(target_list[i]);
			
			if (TF2_GetPlayerClass(target_list[i]) == TFClass_Scout)
			{
				g_hClassy[0].Set(target_list[i], "-1");
			}
			
			if (TF2_GetPlayerClass(target_list[i]) == TFClass_Sniper)
			{
				g_hClassy[1].Set(target_list[i], "-1");
			}
			
			if (TF2_GetPlayerClass(target_list[i]) == TFClass_Soldier)
			{
				g_hClassy[2].Set(target_list[i], "-1");
			}	

			if (TF2_GetPlayerClass(target_list[i]) == TFClass_DemoMan)
			{
				g_hClassy[3].Set(target_list[i], "-1");
			}
			
			if (TF2_GetPlayerClass(target_list[i]) == TFClass_Medic)
			{
				g_hClassy[4].Set(target_list[i], "-1");
			}

			if (TF2_GetPlayerClass(target_list[i]) == TFClass_Heavy)
			{
				g_hClassy[5].Set(target_list[i], "-1");
			}	

			if (TF2_GetPlayerClass(target_list[i]) == TFClass_Pyro)
			{
				g_hClassy[6].Set(target_list[i], "-1");
			}	
			
			if (TF2_GetPlayerClass(target_list[i]) == TFClass_Spy)
			{
				g_hClassy[7].Set(target_list[i], "-1");
			}
			
			if (TF2_GetPlayerClass(target_list[i]) == TFClass_Engineer)
			{
				g_hClassy[8].Set(target_list[i], "-1");
			}
			
			return Plugin_Handled;
		}

		GetCmdArg(3, buffer2, sizeof(buffer2));
		int item1Paint = StringToInt(buffer2);
		
		GetCmdArg(4, buffer3, sizeof(buffer3));
		int item1Effect = StringToInt(buffer3);
		
		GetCmdArg(5, buffer4, sizeof(buffer4));
		int item1Style = StringToInt(buffer4);

		GetCmdArg(6, buffer5, sizeof(buffer5));
		int item2Index = StringToInt(buffer5);

		GetCmdArg(7, buffer6, sizeof(buffer6));
		int item2Paint = StringToInt(buffer6);
		
		GetCmdArg(8, buffer7, sizeof(buffer7));
		int item2Effect = StringToInt(buffer7);		
		
		GetCmdArg(9, buffer8, sizeof(buffer8));
		int item2Style = StringToInt(buffer8);

		GetCmdArg(10, buffer9, sizeof(buffer9));
		int item3Index = StringToInt(buffer9);	

		GetCmdArg(11, buffer10, sizeof(buffer10));
		int item3Paint = StringToInt(buffer10);
		
		GetCmdArg(12, buffer11, sizeof(buffer11));
		int item3Effect = StringToInt(buffer11);		

		GetCmdArg(13, buffer12, sizeof(buffer12));
		int item3Style = StringToInt(buffer12);	
		
		GetCmdArg(14, buffer13, sizeof(buffer13));
		int item4Index = StringToInt(buffer13);	

		GetCmdArg(15, buffer14, sizeof(buffer14));
		int item4Paint = StringToInt(buffer14);
		
		GetCmdArg(16, buffer15, sizeof(buffer15));
		int item4Effect = StringToInt(buffer15);		

		GetCmdArg(17, buffer16, sizeof(buffer16));
		int item4Style = StringToInt(buffer16);		
		
		GetCmdArg(18, buffer17, sizeof(buffer17));
		int item5Index = StringToInt(buffer17);	

		GetCmdArg(19, buffer18, sizeof(buffer18));
		int item5Paint = StringToInt(buffer18);
		
		GetCmdArg(20, buffer19, sizeof(buffer19));
		int item5Effect = StringToInt(buffer19);
		
		GetCmdArg(21, buffer20, sizeof(buffer20));
		int item5Style = StringToInt(buffer20);	
		
		Format(bufferoutfit, sizeof(bufferoutfit), "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", buffer1, buffer2, buffer3, buffer4, buffer5, buffer6, buffer7, buffer8, buffer9, buffer10, buffer11, buffer12, buffer13, buffer14, buffer15, buffer16, buffer17, buffer18, buffer19, buffer20);

		if (TF2_GetPlayerClass(target_list[i]) == TFClass_Scout)
		{
			g_hClassy[0].Set(target_list[i], bufferoutfit);
		}
		
		if (TF2_GetPlayerClass(target_list[i]) == TFClass_Sniper)
		{
			g_hClassy[1].Set(target_list[i], bufferoutfit);
		}
		
		if (TF2_GetPlayerClass(target_list[i]) == TFClass_Soldier)
		{
			g_hClassy[2].Set(target_list[i], bufferoutfit);
		}	

		if (TF2_GetPlayerClass(target_list[i]) == TFClass_DemoMan)
		{
			g_hClassy[3].Set(target_list[i], bufferoutfit);
		}
		
		if (TF2_GetPlayerClass(target_list[i]) == TFClass_Medic)
		{
			g_hClassy[4].Set(target_list[i], bufferoutfit);
		}

		if (TF2_GetPlayerClass(target_list[i]) == TFClass_Heavy)
		{
			g_hClassy[5].Set(target_list[i], bufferoutfit);
		}	

		if (TF2_GetPlayerClass(target_list[i]) == TFClass_Pyro)
		{
			g_hClassy[6].Set(target_list[i], bufferoutfit);
		}	
		
		if (TF2_GetPlayerClass(target_list[i]) == TFClass_Spy)
		{
			g_hClassy[7].Set(target_list[i], bufferoutfit);
		}
		
		if (TF2_GetPlayerClass(target_list[i]) == TFClass_Engineer)
		{
			g_hClassy[8].Set(target_list[i], bufferoutfit);
		}

		if (item1Index > 1)
		{
			TF2_RemoveAllWearables(target_list[i]);
			
			CreateHat(target_list[i], item1Index, 10, 6, item1Paint, item1Effect, item1Style);
		}

		if (item2Index > 1)
		{
			CreateHat(target_list[i], item2Index, 10, 6, item2Paint, item2Effect, item2Style);
		}
		
		if (item3Index > 1)
		{
			CreateHat(target_list[i], item3Index, 10, 6, item3Paint, item3Effect, item3Style);
		}

		if (item4Index > 1)
		{
			CreateHat(target_list[i], item4Index, 10, 6, item4Paint, item4Effect, item4Style);
		}
		
		if (item5Index > 1)
		{
			CreateHat(target_list[i], item5Index, 10, 6, item5Paint, item5Effect, item5Style);
		}		
		
		return Plugin_Handled;
	}

	ReplyToCommand(client, "Targets were made Classy!");

	return Plugin_Handled;
}

public void EventInventoryApplication(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		char strItemOutfit[256];
		
		if (TF2_GetPlayerClass(client) == TFClass_Scout)
		{
			g_hClassy[0].Get(client, strItemOutfit, 256);
		}
		
		if (TF2_GetPlayerClass(client) == TFClass_Sniper)
		{
			g_hClassy[1].Get(client, strItemOutfit, 256);
		}
		
		if (TF2_GetPlayerClass(client) == TFClass_Soldier)
		{
			g_hClassy[2].Get(client, strItemOutfit, 256);
		}	

		if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
		{
			g_hClassy[3].Get(client, strItemOutfit, 256);
		}
		
		if (TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			g_hClassy[4].Get(client, strItemOutfit, 256);
		}

		if (TF2_GetPlayerClass(client) == TFClass_Heavy)
		{
			g_hClassy[5].Get(client, strItemOutfit, 256);
		}	

		if (TF2_GetPlayerClass(client) == TFClass_Pyro)
		{
			g_hClassy[6].Get(client, strItemOutfit, 256);
		}	
		
		if (TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			g_hClassy[7].Get(client, strItemOutfit, 256);
		}
		
		if (TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			g_hClassy[8].Get(client, strItemOutfit, 256);
		}
		
		int strItem[20];
		char strItemRaw[20][32];
		ExplodeString(strItemOutfit, ",", strItemRaw, 20, 32);
		
		strItem[0] = StringToInt(strItemRaw[0]);	
		strItem[1] = StringToInt(strItemRaw[1]);
		strItem[2] = StringToInt(strItemRaw[2]);
		strItem[3] = StringToInt(strItemRaw[3]);
		strItem[4] = StringToInt(strItemRaw[4]);		
		strItem[5] = StringToInt(strItemRaw[5]);
		strItem[6] = StringToInt(strItemRaw[6]);
		strItem[7] = StringToInt(strItemRaw[7]);
		strItem[8] = StringToInt(strItemRaw[8]);
		strItem[9] = StringToInt(strItemRaw[9]);
		strItem[10] = StringToInt(strItemRaw[10]);
		strItem[11] = StringToInt(strItemRaw[11]);
		strItem[12] = StringToInt(strItemRaw[12]);		
		strItem[13] = StringToInt(strItemRaw[13]);		
		strItem[14] = StringToInt(strItemRaw[14]);
		strItem[15] = StringToInt(strItemRaw[15]);
		strItem[16] = StringToInt(strItemRaw[16]);
		strItem[17] = StringToInt(strItemRaw[17]);		
		strItem[18] = StringToInt(strItemRaw[18]);		
		strItem[19] = StringToInt(strItemRaw[19]);		
		
		if (strItem[0] > 1)
		{
			TF2_RemoveAllWearables(client);
			
			CreateHat(client, strItem[0], 10, 6, strItem[1], strItem[2], strItem[3]);


			if (strItem[4] > 1)
			{
				CreateHat(client, strItem[4], 10, 6, strItem[5], strItem[6], strItem[7]);
			}
			
			if (strItem[8] > 1)
			{
				CreateHat(client, strItem[8], 10, 6, strItem[9], strItem[10], strItem[11]);
			}

			if (strItem[12] > 1)
			{
				CreateHat(client, strItem[12], 10, 6, strItem[13], strItem[14], strItem[15]);
			}
			
			if (strItem[16] > 1)
			{
				CreateHat(client, strItem[16], 10, 6, strItem[17], strItem[18], strItem[19]);
			}
		}
	}
}

public Action Command_ShowPrefs(int client, int args)
{
	char strItemOutfit[256];
	
	if (TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		g_hClassy[0].Get(client, strItemOutfit, 256);
	}

	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		g_hClassy[1].Get(client, strItemOutfit, 256);
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		g_hClassy[2].Get(client, strItemOutfit, 256);
	}	

	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		g_hClassy[3].Get(client, strItemOutfit, 256);
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		g_hClassy[4].Get(client, strItemOutfit, 256);
	}

	if (TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		g_hClassy[5].Get(client, strItemOutfit, 256);
	}	

	if (TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		g_hClassy[6].Get(client, strItemOutfit, 256);
	}	
	
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		g_hClassy[7].Get(client, strItemOutfit, 256);
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		g_hClassy[8].Get(client, strItemOutfit, 256);
	}
	
	int strItem[20];
	char strItemRaw[20][32];
	ExplodeString(strItemOutfit, ",", strItemRaw, 20, 32);
	
	strItem[0] = StringToInt(strItemRaw[0]);	
	strItem[1] = StringToInt(strItemRaw[1]);
	strItem[2] = StringToInt(strItemRaw[2]);
	strItem[3] = StringToInt(strItemRaw[3]);
	strItem[4] = StringToInt(strItemRaw[4]);		
	strItem[5] = StringToInt(strItemRaw[5]);
	strItem[6] = StringToInt(strItemRaw[6]);
	strItem[7] = StringToInt(strItemRaw[7]);
	strItem[8] = StringToInt(strItemRaw[8]);
	strItem[9] = StringToInt(strItemRaw[9]);
	strItem[10] = StringToInt(strItemRaw[10]);
	strItem[11] = StringToInt(strItemRaw[11]);
	strItem[12] = StringToInt(strItemRaw[12]);		
	strItem[13] = StringToInt(strItemRaw[13]);		
	strItem[14] = StringToInt(strItemRaw[14]);
	strItem[15] = StringToInt(strItemRaw[15]);
	strItem[16] = StringToInt(strItemRaw[16]);
	strItem[17] = StringToInt(strItemRaw[17]);		
	strItem[18] = StringToInt(strItemRaw[18]);		
	strItem[19] = StringToInt(strItemRaw[19]);	
	
	PrintToChat(client, "You have the following Classy items:");
	PrintToChat(client, "Item 1 Index: %i Paint: %i Effect: %i Style: %i", strItem[0], strItem[1], strItem[2], strItem[3]);
	PrintToChat(client, "Item 2 Index: %i Paint: %i Effect: %i Style: %i", strItem[4], strItem[5], strItem[6], strItem[7]);
	PrintToChat(client, "Item 3 Index: %i Paint: %i Effect: %i Style: %i", strItem[8], strItem[9], strItem[10], strItem[11]);
	PrintToChat(client, "Item 4 Index: %i Paint: %i Effect: %i Style: %i", strItem[12], strItem[13], strItem[14], strItem[15]);
	PrintToChat(client, "Item 5 Index: %i Paint: %i Effect: %i Style: %i", strItem[16], strItem[17], strItem[18], strItem[19]);

	return Plugin_Handled;
}

public Action Command_ShowCookie(int client, int args)
{
	char strItemOutfit[256];
	
	if (TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		g_hClassy[0].Get(client, strItemOutfit, 256);
	}

	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		g_hClassy[1].Get(client, strItemOutfit, 256);
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		g_hClassy[2].Get(client, strItemOutfit, 256);
	}	

	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		g_hClassy[3].Get(client, strItemOutfit, 256);
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		g_hClassy[4].Get(client, strItemOutfit, 256);
	}

	if (TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		g_hClassy[5].Get(client, strItemOutfit, 256);
	}	

	if (TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		g_hClassy[6].Get(client, strItemOutfit, 256);
	}	
	
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		g_hClassy[7].Get(client, strItemOutfit, 256);
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		g_hClassy[8].Get(client, strItemOutfit, 256);
	}
	
	PrintToChat(client, "Classy Cookie: %s", strItemOutfit);

	return Plugin_Handled;
}
bool CreateHat(int client, int itemindex, int level = 10, int quality = 6, int paint = 0, int effect = 0, int style = 0)
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
	SetEntProp(hat, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
	SetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity", client);
	
	if (style > 0)
	{
		TF2Attrib_SetByName(hat, "item style override", style + 0.0);
	}

	if (effect > 0)
	{
		if (effect == 999)
		{
			effect = GetRandomInt(1,278);			
			{
				TF2Attrib_SetByName(hat, "particle effect use head origin", 1.0);
				SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
				TF2Attrib_SetByDefIndex(hat, 134, (effect + 0.0));
			}
		}
		else
		{
			TF2Attrib_SetByName(hat, "particle effect use head origin", 1.0);
			SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
			TF2Attrib_SetByDefIndex(hat, 134, (effect + 0.0));				
		}
	}
	
	if (paint > 0)
	{
		if (paint == 999)
		{
			paint = GetRandomInt(1,29);
		}

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

public Action Command_ClassyStrip(int client, int args)
{
	TF2_RemoveAllWearables(client);

	if (TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		g_hClassy[0].Set(client, "-1");
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		g_hClassy[1].Set(client, "-1");
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		g_hClassy[2].Set(client, "-1");
	}	

	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		g_hClassy[3].Set(client, "-1");
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		g_hClassy[4].Set(client, "-1");
	}

	if (TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		g_hClassy[5].Set(client, "-1");
	}	

	if (TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		g_hClassy[6].Set(client, "-1");
	}	
	
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		g_hClassy[7].Set(client, "-1");
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		g_hClassy[8].Set(client, "-1");
	}	
	
	return Plugin_Handled;
}

stock void TF2_RemoveAllWearables(int client)
{
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
	SetVariantString("ParticleEffectStop");
	AcceptEntityInput(client, "DispatchEffect");

	int wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
	
	while((wearable = FindEntityByClassname(wearable, "tf_weapon_grapplinghook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
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

public Action Command_HideHats(int client, int args)
{
	if(!b_Transmit[client])
	{
		PrintToChat(client, "You will no longer see Classy cosmetics. To enable hats type !classyhide again.");
		b_Transmit[client] = true;
	}
	else if(b_Transmit[client])
	{
		PrintToChat(client, "You can now see Classy cosmetics");
		b_Transmit[client] = false;
	}
	
	return Plugin_Handled;
}	